import "package:u/utilities.dart";

enum _UEpubSidebarTab { contents, annotations, bookmarks, search }

/// Builds the exact [TextSpan] a block is rendered with, so pagination,
/// highlight painting and hit-testing all agree on the same layout.
abstract final class UEpubTextStyler {
  static Color foreground(BuildContext context, UDocColorMode mode) {
    switch (mode) {
      case UDocColorMode.night:
        return const Color(0xFFE6E6E6);
      case UDocColorMode.sepia:
        return const Color(0xFF3E3226);
      case UDocColorMode.highContrast:
        return const Color(0xFF000000);
      case UDocColorMode.grayscale:
      case UDocColorMode.custom:
      case UDocColorMode.normal:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  static Color background(BuildContext context, UDocColorMode mode) => mode == UDocColorMode.normal ? Theme.of(context).colorScheme.surface : UDocColorFilters.pageBackground(mode);

  static double headingScale(int level) {
    switch (level) {
      case 1:
        return 1.7;
      case 2:
        return 1.45;
      case 3:
        return 1.28;
      case 4:
        return 1.15;
      case 5:
        return 1.08;
      default:
        return 1;
    }
  }

  static TextAlign align(UEpubBlock block, UEpubTypography typography) =>
      block.align ?? (block.kind == UEpubBlockKind.heading ? TextAlign.start : (typography.justify ? TextAlign.justify : TextAlign.start));

  static TextDirection direction(UEpubBlock block) => block.rtl || UDocText.isMostlyRtl(block.text) ? TextDirection.rtl : TextDirection.ltr;

  static TextSpan span(
    BuildContext context,
    UEpubBlock block,
    UEpubTypography typography,
    UDocColorMode mode, {
    int start = 0,
    int end = -1,
    void Function(String href)? onLink,
  }) {
    final double base = typography.baseFontSize * (block.kind == UEpubBlockKind.heading ? headingScale(block.level) : 1);
    final Color text = foreground(context, mode);
    final Color link = Theme.of(context).colorScheme.primary;
    final String? family = typography.fontFamily;
    final List<UEpubSpan> spans = end < 0 && start == 0 ? block.spans : block.sliceSpans(start, end < 0 ? block.text.length : end);
    final List<InlineSpan> children = <InlineSpan>[];
    for (final UEpubSpan span in spans) {
      final String? href = span.href;
      final TextStyle style = TextStyle(
        fontSize: base * span.sizeFactor * (span.superscript || span.subscript ? 0.72 : 1),
        fontWeight: span.bold || block.kind == UEpubBlockKind.heading ? FontWeight.w700 : FontWeight.w400,
        fontStyle: span.italic ? FontStyle.italic : FontStyle.normal,
        decoration: href != null || span.underline ? TextDecoration.underline : (span.strike ? TextDecoration.lineThrough : TextDecoration.none),
        decorationColor: href != null ? link.withValues(alpha: 0.5) : null,
        color: href != null ? link : (mode == UDocColorMode.normal ? (span.color ?? text) : text),
        backgroundColor: mode == UDocColorMode.normal ? span.background : null,
        fontFamily: span.monospace ? "monospace" : null,
        fontFeatures: span.superscript ? const <FontFeature>[FontFeature.superscripts()] : (span.subscript ? const <FontFeature>[FontFeature.subscripts()] : null),
      );
      children.add(
        TextSpan(
          text: span.text,
          style: style,
          recognizer: href == null || onLink == null ? null : (TapGestureRecognizer()..onTap = () => onLink(href)),
        ),
      );
    }
    return TextSpan(
      style: DefaultTextStyle.of(context).style.merge(
        TextStyle(
          fontSize: base,
          color: text,
          height: typography.lineHeight,
          letterSpacing: typography.letterSpacing,
          wordSpacing: typography.wordSpacing,
          fontFamily: family,
          package: family == "Vazir" ? "u" : null,
          fontWeight: block.kind == UEpubBlockKind.heading ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      children: children,
    );
  }

  static TextPainter painter(BuildContext context, UEpubBlock block, UEpubTypography typography, UDocColorMode mode, double width, {int start = 0, int end = -1}) => TextPainter(
    text: span(context, block, typography, mode, start: start, end: end),
    textAlign: align(block, typography),
    textDirection: direction(block),
    textScaler: MediaQuery.textScalerOf(context),
    textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
  )..layout(minWidth: width, maxWidth: width);

  /// One rectangle per visual line for `[start, end)`, trimmed of the spaces at
  /// line wraps and shrunk from the full line height to the glyph band, so
  /// highlights look the same as in the PDF viewer.
  static List<Rect> lineRects(TextPainter painter, String text, int start, int end, {required double fontSize}) {
    final List<Rect> rects = <Rect>[];
    final int length = text.length;
    int position = start.clamp(0, length);
    final int stop = end.clamp(0, length);
    int guard = 0;
    bool isSpace(int index) => index >= 0 && index < length && (text.codeUnitAt(index) == 0x20 || text.codeUnitAt(index) == 0x0A || text.codeUnitAt(index) == 0x09 || text.codeUnitAt(index) == 0xA0);
    while (position < stop && guard++ < 10000) {
      final TextRange line = painter.getLineBoundary(TextPosition(offset: position));
      final int lineEnd = line.end <= position ? stop : min(line.end, stop);
      int a = position;
      int b = lineEnd;
      while (a < b && isSpace(a)) {
        a++;
      }
      while (b > a && isSpace(b - 1)) {
        b--;
      }
      if (b > a) {
        Rect? union;
        for (final TextBox box in painter.getBoxesForSelection(TextSelection(baseOffset: a, extentOffset: b))) {
          final Rect rect = box.toRect();
          if (rect.width <= 0.5) continue;
          union = union == null ? rect : union.expandToInclude(rect);
        }
        if (union != null) {
          final double band = fontSize * 1.3;
          if (union.height > band) {
            final double center = union.center.dy + fontSize * 0.04;
            union = Rect.fromLTRB(union.left, center - band / 2, union.right, center + band / 2);
          }
          rects.add(union);
        }
      }
      position = max(lineEnd, position + 1);
      while (position < stop && text.codeUnitAt(position) == 0x0A) {
        position++;
      }
    }
    return rects;
  }
}

class UEpubReader extends StatefulWidget {
  const UEpubReader({
    this.filePath,
    this.bytes,
    this.url,
    this.asset,
    this.controller,
    this.annotations,
    this.initialChapter = 0,
    this.title,
    this.showToolbar = true,
    this.showBottomBar = true,
    this.showSidebar = true,
    this.showBackButton = false,
    this.allowSelection = true,
    this.allowCopy = true,
    this.allowShare = true,
    this.enableMarkup = true,
    this.enableDrawing = true,
    this.drawController,
    this.markupKinds = UDocMarkupKind.values,
    this.annotationData,
    this.annotationStorageKey,
    this.persistAnnotations = true,
    this.onAnnotationsChanged,
    this.noteDisplay = UDocNoteDisplay.badge,
    this.watermark,
    this.secure = false,
    this.restorePosition = true,
    this.actions = const <Widget>[],
    this.onChapterChanged,
    this.onBack,
    super.key,
  }) : assert(filePath != null || bytes != null || url != null || asset != null || controller != null, "Provide one EPUB source");

  final String? filePath;
  final Uint8List? bytes;
  final String? url;
  final String? asset;
  final UEpubController? controller;
  final UDocAnnotationController? annotations;
  final int initialChapter;
  final String? title;
  final bool showToolbar;
  final bool showBottomBar;
  final bool showSidebar;
  final bool showBackButton;
  final bool allowSelection;
  final bool allowCopy;
  final bool allowShare;
  final bool enableMarkup;

  /// Pen, highlighter, shapes, text boxes and notes drawn over paragraphs;
  /// saved in the annotation string.
  final bool enableDrawing;
  final UDocDrawController? drawController;
  final List<UDocMarkupKind> markupKinds;
  final String? annotationData;
  final String? annotationStorageKey;
  final bool persistAnnotations;
  final void Function(String data)? onAnnotationsChanged;
  final UDocNoteDisplay noteDisplay;
  final UDocWatermark? watermark;
  final bool secure;
  final bool restorePosition;
  final List<Widget> actions;
  final void Function(int chapterIndex)? onChapterChanged;
  final VoidCallback? onBack;

  @override
  State<UEpubReader> createState() => UEpubReaderState();
}

class _UEpubSelectionRange {
  const _UEpubSelectionRange(this.blockIndex, this.start, this.end);

  final int blockIndex;
  final int start;
  final int end;
}

class UEpubReaderState extends State<UEpubReader> {
  late UEpubController _controller;
  bool _ownsController = false;
  late UDocAnnotationController _markup;
  bool _ownsMarkup = false;
  late final UDocDrawController _draw = widget.drawController ?? UDocDrawController();
  late final bool _ownsDraw = widget.drawController == null;
  bool _drawOpen = false;

  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchField = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: "UEpubReader");
  final GlobalKey<SelectionAreaState> _selectionKey = GlobalKey<SelectionAreaState>();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<String, (UEpubSlice, SelectionListenerNotifier)> _registry = <String, (UEpubSlice, SelectionListenerNotifier)>{};
  final Map<int, GlobalKey> _blockKeys = <int, GlobalKey>{};

  UEpubChapter? _chapter;
  PageController? _pageController;
  List<UEpubPage> _pages = <UEpubPage>[];
  String _pagesKey = "";
  int _pageInChapter = 0;
  int _visibleBlock = 0;
  bool _chromeVisible = true;
  bool _loading = true;
  bool _sidebarOpen = false;
  bool _sidebarPinned = true;
  bool _wholeWord = false;
  double _totalWidth = 0;
  _UEpubSidebarTab _tab = _UEpubSidebarTab.contents;
  List<_UEpubSelectionRange> _selection = <_UEpubSelectionRange>[];

  /// Copy taken when the user presses a menu button, in case the region clears first.
  List<_UEpubSelectionRange> _frozenSelection = <_UEpubSelectionRange>[];
  UDocMarkup? _activeMarkup;
  UEpubSearchHit? _flash;
  Timer? _progressTimer;
  Timer? _visibleTimer;
  Offset? _pointerDown;
  DateTime _pointerDownAt = DateTime.now();
  bool _markupTapped = false;
  bool _linkTapped = false;
  bool _selectionAtDown = false;
  List<double>? _estimates;
  String _estimatesKey = "";

  UEpubController get controller => _controller;

  UDocAnnotationController get annotations => _markup;

  UEpubChapter? get chapter => _chapter;

  void applyState(VoidCallback action) {
    if (mounted) setState(action);
  }

  bool get _paged => _controller.settings.isPaged;

  bool get _wide => _totalWidth >= 900;

  @override
  void initState() {
    super.initState();
    final UEpubController? provided = widget.controller;
    _controller = provided ?? UEpubController();
    _ownsController = provided == null;
    _controller.addListener(_onChanged);
    final UDocAnnotationController? markup = widget.annotations;
    _markup = markup ?? UDocAnnotationController(onChanged: (UDocAnnotationController controller) => widget.onAnnotationsChanged?.call(controller.export()));
    _ownsMarkup = markup == null;
    _markup.addListener(_onChanged);
    _draw.addListener(_onChanged);
    _drawOpen = _draw.isActive && _drawingEnabled;
    _scroll.addListener(_onScroll);
    unawaited(_start());
    _progressTimer = Timer.periodic(const Duration(seconds: 12), (Timer timer) => _saveProgress());
  }

  Future<void> _start() async {
    await _controller.loadTypography();
    final bool hasSource = widget.filePath != null || widget.url != null || widget.bytes != null || widget.asset != null;
    if (_ownsController || (hasSource && !_controller.value.isReady && _controller.value.state != UDocState.opening)) {
      await _controller.open(path: widget.filePath, url: widget.url, bytes: widget.bytes, asset: widget.asset);
    }
    if (!mounted || !_controller.value.isReady) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    await _prepareAnnotations();
    final UEpubPosition? saved = widget.restorePosition ? _controller.savedPosition : null;
    if (widget.initialChapter > 0) {
      await _loadChapter(widget.initialChapter);
    } else if (saved != null && saved.spineIndex < _controller.pageCount) {
      await _loadChapter(saved.spineIndex, block: saved.blockIndex, offset: saved.charOffset);
    } else {
      await _loadChapter(_controller.value.pageIndex);
    }
  }

  Future<void> _prepareAnnotations() async {
    if (_ownsMarkup && widget.persistAnnotations) await _markup.attachStorage(widget.annotationStorageKey ?? "u_doc_markup_${_controller.documentId}");
    final String? remote = widget.annotationData;
    if (remote != null && remote.trim().isNotEmpty) {
      final String local = _markup.isEmpty ? "" : _markup.export();
      final String newest = UDocAnnotationController.pickNewest(local, remote);
      if (newest != local) _markup.import(newest);
    }
  }


  Future<void> _loadChapter(int index, {String? anchor, int? block, int? offset, bool atEnd = false}) async {
    if (_controller.pageCount == 0) {
      setState(() => _loading = false);
      return;
    }
    final int target = index.clamp(0, _controller.pageCount - 1);
    final bool same = _chapter?.spineIndex == target;
    if (!same) setState(() => _loading = true);
    final UEpubChapter chapter = await _controller.chapter(target);
    if (!mounted) return;
    _clearSelection();
    if (!same) {
      _controller.goToPage(target);
      widget.onChapterChanged?.call(target);
    }
    int blockIndex = block ?? 0;
    if (anchor != null) {
      final int found = chapter.anchorBlock(anchor);
      if (found >= 0) blockIndex = found;
    }
    setState(() {
      _chapter = chapter;
      _loading = false;
      _blockKeys.clear();
      _estimates = null;
      _visibleBlock = blockIndex;
      if (!same) {
        _pages = <UEpubPage>[];
        _pagesKey = "";
        _pageController?.dispose();
        _pageController = null;
        _pageInChapter = atEnd ? 1 << 20 : 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) return;
      if (_paged) {
        if (atEnd) {
          _goToPageInChapter(_pages.length - 1, animate: false);
        } else if (blockIndex > 0 || (offset ?? 0) > 0) {
          _goToBlock(blockIndex, offset: offset ?? 0, animate: false);
        } else if (!same) {
          _goToPageInChapter(0, animate: false);
        }
        return;
      }
      if (atEnd && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else if (blockIndex > 0) {
        _goToBlock(blockIndex, animate: false);
      } else if (!same && _scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    });
  }

  void _onChanged() {
    if (!mounted) return;
    final UDocMarkup? active = _activeMarkup;
    if (active != null && _markup.byId(active.id) == null) _activeMarkup = null;
    setState(() {});
  }

  void _onScroll() {
    _visibleTimer?.cancel();
    _visibleTimer = Timer(const Duration(milliseconds: 120), _updateVisibleBlock);
  }

  void _updateVisibleBlock() {
    if (!mounted || _paged) return;
    final RenderObject? viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox) return;
    int best = _visibleBlock;
    double bestTop = double.infinity;
    for (final MapEntry<int, GlobalKey> entry in _blockKeys.entries) {
      final RenderObject? box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final double top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      final double bottom = top + box.size.height;
      if (bottom < 60) continue;
      if (top < bestTop) {
        bestTop = top;
        best = entry.key;
      }
    }
    if (best != _visibleBlock) setState(() => _visibleBlock = best);
  }

  double _chapterFraction() {
    final UEpubChapter? chapter = _chapter;
    if (chapter == null || chapter.blocks.isEmpty) return 0;
    if (_paged) return _pages.length <= 1 ? 1 : (_pageInChapter / (_pages.length - 1)).clamp(0, 1).toDouble();
    if (!_scroll.hasClients || _scroll.position.maxScrollExtent <= 0) return 0;
    return (_scroll.position.pixels / _scroll.position.maxScrollExtent).clamp(0, 1).toDouble();
  }

  double _percent() {
    if (_controller.pageCount == 0) return 0;
    return ((_controller.value.pageIndex + _chapterFraction()) / _controller.pageCount).clamp(0, 1).toDouble();
  }

  int _minutesLeftInChapter() {
    final UEpubChapter? chapter = _chapter;
    if (chapter == null) return 0;
    int remaining = 0;
    final int from = _paged ? (_pages.isEmpty ? 0 : _pages[_pageInChapter.clamp(0, _pages.length - 1)].startBlock) : _visibleBlock;
    for (int i = from; i < chapter.blocks.length; i++) {
      remaining += chapter.blocks[i].text.length;
    }
    return (remaining / 1100).ceil();
  }

  void _saveProgress() {
    final UEpubChapter? chapter = _chapter;
    if (chapter == null) return;
    final int block = _paged && _pages.isNotEmpty ? _pages[_pageInChapter.clamp(0, _pages.length - 1)].startBlock : _visibleBlock;
    _controller.saveProgress(
      percent: _percent(),
      position: UEpubPosition(spineIndex: chapter.spineIndex, blockIndex: block).encode(),
    );
  }

  // ───────────────────────── navigation ─────────────────────────

  void _goToPageInChapter(int page, {bool animate = true}) {
    if (_pages.isEmpty) return;
    final int target = page.clamp(0, _pages.length - 1);
    final int item = target + (_hasPreviousChapter ? 1 : 0);
    if (_pageController?.hasClients == true) {
      if (animate) {
        unawaited(_pageController!.animateToPage(item, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic));
      } else {
        _pageController!.jumpToPage(item);
      }
    }
    setState(() => _pageInChapter = target);
  }

  void _goToBlock(int blockIndex, {int offset = 0, bool animate = true}) {
    if (_paged) {
      for (int i = 0; i < _pages.length; i++) {
        if (_pages[i].contains(blockIndex, offset) || _pages[i].slices.any((UEpubSlice slice) => slice.blockIndex > blockIndex)) {
          _goToPageInChapter(i, animate: animate);
          return;
        }
      }
      return;
    }
    _visibleBlock = blockIndex;
    _ensureBlockVisible(blockIndex, animate: animate, attempts: 4);
  }

  void _ensureBlockVisible(int blockIndex, {required bool animate, required int attempts}) {
    final BuildContext? target = _blockKeys[blockIndex]?.currentContext;
    if (target != null) {
      unawaited(Scrollable.ensureVisible(target, alignment: 0.12, duration: animate ? const Duration(milliseconds: 280) : Duration.zero, curve: Curves.easeOutCubic));
      return;
    }
    if (attempts <= 0 || !_scroll.hasClients) return;
    final List<double> estimates = _estimateOffsets();
    if (blockIndex < estimates.length) _scroll.jumpTo(estimates[blockIndex].clamp(0, _scroll.position.maxScrollExtent).toDouble());
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _ensureBlockVisible(blockIndex, animate: false, attempts: attempts - 1);
    });
  }

  /// Approximate scroll offset of every block, measured with the real text style.
  List<double> _estimateOffsets() {
    final UEpubChapter? chapter = _chapter;
    final RenderObject? viewport = _viewportKey.currentContext?.findRenderObject();
    if (chapter == null || viewport is! RenderBox) return const <double>[];
    final UEpubTypography typography = _controller.typography;
    final double width = viewport.size.width - typography.horizontalMargin * 2;
    final String key = "${chapter.spineIndex}|$width|${typography.toJson()}";
    if (_estimatesKey == key && _estimates != null) return _estimates!;
    final List<double> offsets = <double>[];
    double total = _topPad + typography.verticalMargin;
    for (final UEpubBlock block in chapter.blocks) {
      offsets.add(total);
      double height = block.marginTop + block.marginBottom + typography.paragraphSpacing / 2;
      if (block.isText) {
        final TextPainter painter = UEpubTextStyler.painter(context, block, typography, _controller.settings.colorMode, max(40, width - block.indent));
        height += painter.height;
        painter.dispose();
      } else if (block.kind == UEpubBlockKind.image) {
        height += viewport.size.height * 0.5;
      } else {
        height += 24;
      }
      total += height;
    }
    _estimates = offsets;
    _estimatesKey = key;
    return offsets;
  }

  bool get _hasPreviousChapter => _controller.value.pageIndex > 0;

  bool get _hasNextChapter => _controller.value.pageIndex < _controller.pageCount - 1;

  void nextPage() {
    if (_paged) {
      if (_pageInChapter < _pages.length - 1) {
        _goToPageInChapter(_pageInChapter + 1);
      } else if (_hasNextChapter) {
        unawaited(_loadChapter(_controller.value.pageIndex + 1));
      }
      return;
    }
    if (!_scroll.hasClients) return;
    final double viewport = _scroll.position.viewportDimension;
    if (_scroll.offset >= _scroll.position.maxScrollExtent - 2) {
      if (_hasNextChapter) unawaited(_loadChapter(_controller.value.pageIndex + 1));
      return;
    }
    unawaited(_scroll.animateTo((_scroll.offset + viewport * 0.85).clamp(0, _scroll.position.maxScrollExtent).toDouble(), duration: const Duration(milliseconds: 240), curve: Curves.easeOut));
  }

  void previousPage() {
    if (_paged) {
      if (_pageInChapter > 0) {
        _goToPageInChapter(_pageInChapter - 1);
      } else if (_hasPreviousChapter) {
        unawaited(_loadChapter(_controller.value.pageIndex - 1, atEnd: true));
      }
      return;
    }
    if (!_scroll.hasClients) return;
    if (_scroll.offset <= 2) {
      if (_hasPreviousChapter) unawaited(_loadChapter(_controller.value.pageIndex - 1, atEnd: true));
      return;
    }
    final double viewport = _scroll.position.viewportDimension;
    unawaited(_scroll.animateTo((_scroll.offset - viewport * 0.85).clamp(0, _scroll.position.maxScrollExtent).toDouble(), duration: const Duration(milliseconds: 240), curve: Curves.easeOut));
  }

  Future<void> _handleLink(String href) async {
    _linkTapped = true;
    final UEpubBook? book = _controller.book;
    if (book == null) return;
    if (href.startsWith("http://") || href.startsWith("https://") || href.startsWith("mailto:")) {
      await ULaunch.url(href);
      return;
    }
    final UEpubChapter? chapter = _chapter;
    final String base = chapter?.href ?? "";
    final String directory = base.contains("/") ? base.substring(0, base.lastIndexOf("/") + 1) : "";
    final String path = href.startsWith("#") ? "$base$href" : (href.startsWith("/") ? href.substring(1) : "$directory$href");
    final int hash = path.indexOf("#");
    final String target = _normalizePath(hash < 0 ? path : path.substring(0, hash));
    final String? anchor = hash < 0 ? null : path.substring(hash + 1);
    final int index = book.spineIndexFor(target);
    if (index < 0 || index == chapter?.spineIndex) {
      if (anchor != null && chapter != null) {
        final int blockIndex = chapter.anchorBlock(anchor);
        if (blockIndex >= 0) _goToBlock(blockIndex);
      }
      return;
    }
    await _loadChapter(index, anchor: anchor);
  }

  String _normalizePath(String path) {
    final List<String> parts = <String>[];
    for (final String part in path.split("/")) {
      if (part == "..") {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (part.isNotEmpty && part != ".") {
        parts.add(part);
      }
    }
    return parts.join("/");
  }

  // ───────────────────────── selection & markup ─────────────────────────

  void _register(String key, UEpubSlice slice, SelectionListenerNotifier notifier) => _registry[key] = (slice, notifier);

  void _unregister(String key, SelectionListenerNotifier notifier) {
    final (UEpubSlice, SelectionListenerNotifier)? existing = _registry[key];
    if (existing != null && identical(existing.$2, notifier)) _registry.remove(key);
  }

  void _onSelectionChanged(SelectedContent? content) {
    final List<_UEpubSelectionRange> ranges = <_UEpubSelectionRange>[];
    for (final (UEpubSlice, SelectionListenerNotifier) entry in _registry.values) {
      final SelectionListenerNotifier notifier = entry.$2;
      if (!notifier.registered) continue;
      final SelectionDetails details = notifier.selection;
      if (details.status != SelectionStatus.uncollapsed) continue;
      final SelectedContentRange? range = details.range;
      if (range == null) continue;
      final int start = min(range.startOffset, range.endOffset);
      final int end = max(range.startOffset, range.endOffset);
      if (end <= start) continue;
      ranges.add(_UEpubSelectionRange(entry.$1.blockIndex, entry.$1.start + start, entry.$1.start + end));
    }
    ranges.sort((_UEpubSelectionRange a, _UEpubSelectionRange b) => a.blockIndex != b.blockIndex ? a.blockIndex.compareTo(b.blockIndex) : a.start.compareTo(b.start));
    final List<_UEpubSelectionRange> merged = <_UEpubSelectionRange>[];
    for (final _UEpubSelectionRange range in ranges) {
      if (merged.isNotEmpty && merged.last.blockIndex == range.blockIndex && merged.last.end >= range.start) {
        merged[merged.length - 1] = _UEpubSelectionRange(range.blockIndex, merged.last.start, max(merged.last.end, range.end));
      } else {
        merged.add(range);
      }
    }
    if (merged.isEmpty && _selection.isEmpty) return;
    setState(() {
      _selection = merged;
      if (merged.isNotEmpty) _activeMarkup = null;
    });
  }

  List<_UEpubSelectionRange> get _activeSelection => _selection.isNotEmpty ? _selection : _frozenSelection;

  String get _selectedText {
    final UEpubChapter? chapter = _chapter;
    if (chapter == null) return "";
    return _activeSelection
        .map(
          (_UEpubSelectionRange range) =>
              chapter.blocks[range.blockIndex].text.substring(range.start.clamp(0, chapter.blocks[range.blockIndex].text.length), range.end.clamp(0, chapter.blocks[range.blockIndex].text.length)),
        )
        .join("\n");
  }

  void _clearSelection() {
    try {
      _selectionKey.currentState?.selectableRegion.clearSelection();
    } on Object {
      // The selection area may not be mounted yet.
    }
    _frozenSelection = <_UEpubSelectionRange>[];
    if (_selection.isNotEmpty && mounted) setState(() => _selection = <_UEpubSelectionRange>[]);
  }

  Future<void> _applyMarkup(UDocMarkupKind kind) async {
    final UEpubChapter? chapter = _chapter;
    if (chapter == null || _activeSelection.isEmpty) return;
    final List<_UEpubSelectionRange> ranges = List<_UEpubSelectionRange>.from(_activeSelection);
    final String quote = _selectedText;
    String note = "";
    if (kind == UDocMarkupKind.note) {
      final String? value = await UDocNoteEditor.show(quote: quote);
      if (value == null) return;
      note = value;
    }
    final String group = ranges.length > 1 ? "g${DateTime.now().microsecondsSinceEpoch}" : "";
    _markup.kind = kind;
    _markup.addAll(
      ranges
          .map(
            (_UEpubSelectionRange range) => UDocMarkup.create(
              kind: kind,
              pageIndex: chapter.spineIndex,
              blockIndex: range.blockIndex,
              start: range.start,
              end: range.end,
              groupId: group,
              text: chapter.blocks[range.blockIndex].text.substring(range.start, min(range.end, chapter.blocks[range.blockIndex].text.length)),
              color: _markup.color,
              note: note,
            ),
          )
          .toList(),
    );
    _clearSelection();
  }

  bool _onMarkupHit(UDocMarkup markup) {
    _markupTapped = true;
    setState(() => _activeMarkup = _activeMarkup?.id == markup.id ? null : markup);
    return true;
  }

  // ───────────────────────── actions ─────────────────────────

  List<UDocBookmark> get _currentBookmarks {
    final UEpubChapter? chapter = _chapter;
    if (chapter == null) return const <UDocBookmark>[];
    final (int, int) range = _visibleRange();
    return _markup.bookmarksOn(chapter.spineIndex).where((UDocBookmark bookmark) => bookmark.blockIndex >= range.$1 && bookmark.blockIndex <= range.$2).toList();
  }

  (int, int) _visibleRange() {
    if (_paged && _pages.isNotEmpty) {
      final UEpubPage page = _pages[_pageInChapter.clamp(0, _pages.length - 1)];
      return (page.slices.isEmpty ? page.startBlock : page.slices.first.blockIndex, page.slices.isEmpty ? page.startBlock : page.slices.last.blockIndex);
    }
    return (_visibleBlock, _visibleBlock + 2);
  }

  void _toggleBookmark() {
    final UEpubChapter? chapter = _chapter;
    if (chapter == null || !widget.enableMarkup) return;
    final List<UDocBookmark> existing = _currentBookmarks;
    if (existing.isNotEmpty) {
      for (final UDocBookmark bookmark in existing) {
        _markup.removeBookmark(bookmark.id);
      }
      UToast.toast(message: U.s.removeBookmark);
      return;
    }
    final int block = _visibleRange().$1;
    final String preview = chapter.blocks.isEmpty ? "" : chapter.blocks[block.clamp(0, chapter.blocks.length - 1)].text.trim();
    _markup.addBookmark(
      pageIndex: chapter.spineIndex,
      blockIndex: block,
      progress: _percent(),
      title: chapter.title.isNotEmpty ? chapter.title : "${U.s.chapter} ${chapter.spineIndex + 1}",
      note: preview.length > 90 ? "${preview.substring(0, 90)}…" : preview,
    );
    UToast.toast(message: U.s.bookmarkPosition);
  }

  void _openSidebar(_UEpubSidebarTab tab) {
    setState(() {
      _tab = tab;
      if (_wide) {
        _sidebarPinned = true;
      } else {
        _sidebarOpen = true;
      }
    });
  }

  void _toggleSidebar() {
    setState(() {
      if (_wide) {
        _sidebarPinned = !_sidebarPinned;
      } else {
        _sidebarOpen = !_sidebarOpen;
      }
    });
  }

  void _closeSidebarIfOverlay() {
    if (!_wide && _sidebarOpen) setState(() => _sidebarOpen = false);
  }

  Future<void> _runSearch(String query) async {
    await _controller.searchBlocks(query, options: UDocSearchOptions(wholeWord: _wholeWord));
    if (mounted) setState(() {});
  }

  Future<void> _openHit(UEpubSearchHit hit) async {
    _closeSidebarIfOverlay();
    final int index = _controller.value.searchHits.indexOf(hit);
    if (index >= 0) _controller.emit(_controller.value.copyWith(searchHitIndex: index));
    setState(() => _flash = hit);
    if (_chapter?.spineIndex != hit.pageIndex) {
      await _loadChapter(hit.pageIndex, block: hit.blockIndex, offset: hit.start);
    } else {
      _goToBlock(hit.blockIndex, offset: hit.start);
    }
  }

  void _stepHit(int delta) {
    final List<UDocSearchHit> hits = _controller.value.searchHits;
    if (hits.isEmpty) return;
    final int next = (_controller.value.searchHitIndex + delta + hits.length) % hits.length;
    final UDocSearchHit hit = hits[next];
    if (hit is UEpubSearchHit) unawaited(_openHit(hit));
  }

  Future<void> _openMarkup(UDocMarkup markup) async {
    _closeSidebarIfOverlay();
    if (_chapter?.spineIndex != markup.pageIndex) {
      await _loadChapter(markup.pageIndex, block: markup.blockIndex, offset: markup.start);
    } else {
      _goToBlock(markup.blockIndex, offset: markup.start);
    }
    if (mounted) setState(() => _activeMarkup = markup);
  }

  Future<void> _openBookmark(UDocBookmark bookmark) async {
    _closeSidebarIfOverlay();
    if (_chapter?.spineIndex != bookmark.pageIndex) {
      await _loadChapter(bookmark.pageIndex, block: max(0, bookmark.blockIndex));
    } else {
      _goToBlock(max(0, bookmark.blockIndex));
    }
  }

  void _changeFont(double delta) {
    final UEpubTypography typography = _controller.typography;
    _controller.setTypography(typography.copyWith(fontScale: (typography.fontScale + delta).clamp(0.7, 2.6).toDouble()));
  }

  Future<void> _onMenu(String action) async {
    switch (action) {
      case "annotations":
        _openSidebar(_UEpubSidebarTab.annotations);
        break;
      case "bookmarks":
        _openSidebar(_UEpubSidebarTab.bookmarks);
        break;
      case "exportNotes":
        await UShare.text(
          _markup.toMarkdown(title: _title, pageLabel: _chapterLabel),
        );
        break;
      case "exportData":
        await UClipboard.set(_markup.export());
        UToast.toast(message: U.s.copied);
        break;
      case "importData":
        final String? data = await UNavigator.inputDialog(title: U.s.importAnnotations, hint: U.s.importAnnotations);
        if (data == null || data.trim().isEmpty) return;
        if (!_markup.import(data, merge: true)) UToast.errorToast(message: U.s.thisFieldIsInvalid);
        break;
      case "clearAll":
        final bool confirmed = await UNavigator.confirmAsync(title: U.s.clearAnnotations, message: U.s.areYouSureYouWantToDeleteThisItem(U.s.annotations), destructive: true);
        if (confirmed) _markup.clear();
        break;
    }
  }

  Future<void> _openSettings() async {
    await UNavigator.bottomSheet<void>(
      UEpubSettingsPanel(
        controller: _controller,
        onChanged: () {
          _pagesKey = "";
          _estimates = null;
          if (mounted) setState(() {});
        },
      ),
    );
  }

  String _chapterLabel(int spineIndex) {
    final String title = _titleForSpine(spineIndex);
    return title.isEmpty ? "${U.s.chapter} ${spineIndex + 1}" : title;
  }

  String _titleForSpine(int spineIndex) {
    String title = "";
    void walk(List<UDocOutlineNode> nodes) {
      for (final UDocOutlineNode node in nodes) {
        if (title.isNotEmpty) return;
        if (node.destination?.pageIndex == spineIndex) title = node.title;
        if (node.hasChildren) walk(node.children);
      }
    }

    walk(_controller.outline);
    return title;
  }

  String get _title {
    final String custom = widget.title ?? "";
    if (custom.isNotEmpty) return custom;
    final String meta = _controller.value.metadata.displayTitle;
    return meta.isNotEmpty ? meta : (_chapter?.title ?? "");
  }

  Future<void> _showImage(String href) async {
    final Uint8List? bytes = await _controller.image(href);
    if (bytes == null) return;
    await UNavigator.dialog<void>(
      Dialog.fullscreen(
        backgroundColor: const Color(0xF0000000),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 8,
                child: Center(child: href.toLowerCase().endsWith(".svg") ? SvgPicture.memory(bytes) : Image.memory(bytes, fit: BoxFit.contain)),
              ),
            ),
            const PositionedDirectional(
              top: 12,
              end: 12,
              child: SafeArea(
                child: IconButton(
                  onPressed: UNavigator.back,
                  icon: Icon(Icons.close_rounded, color: Color(0xFFFFFFFF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── keyboard & taps ─────────────────────────

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (UDocDrawController.isTyping) return KeyEventResult.ignored;
    final bool command = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final bool shift = HardwareKeyboard.instance.isShiftPressed;
    final LogicalKeyboardKey key = event.logicalKey;
    if (_drawOpen) {
      final String? selected = _draw.selectedId;
      if (key == LogicalKeyboardKey.escape) {
        selected != null ? _draw.selectedId = null : toggleDrawing(false);
        return KeyEventResult.handled;
      }
      if (selected != null && (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace)) {
        _draw.selectedId = null;
        _markup.removeShape(selected);
        return KeyEventResult.handled;
      }
    }
    final bool rtl = _controller.settings.isRtl;
    if (command && key == LogicalKeyboardKey.keyF) {
      _openSidebar(_UEpubSidebarTab.search);
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyB) {
      _toggleBookmark();
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyZ && widget.enableMarkup) {
      shift ? _markup.redo() : _markup.undo();
      return KeyEventResult.handled;
    }
    if (command && (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd)) {
      _changeFont(0.1);
      return KeyEventResult.handled;
    }
    if (command && (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract)) {
      _changeFont(-0.1);
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.arrowRight) {
      if (rtl ? _hasPreviousChapter : _hasNextChapter) unawaited(_loadChapter(_controller.value.pageIndex + (rtl ? -1 : 1)));
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.arrowLeft) {
      if (rtl ? _hasNextChapter : _hasPreviousChapter) unawaited(_loadChapter(_controller.value.pageIndex + (rtl ? 1 : -1)));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_selection.isNotEmpty || _activeMarkup != null) {
        _clearSelection();
        setState(() => _activeMarkup = null);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.pageDown || (key == LogicalKeyboardKey.space && !shift) || (_paged && key == (rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight))) {
      nextPage();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp || (key == LogicalKeyboardKey.space && shift) || (_paged && key == (rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft))) {
      previousPage();
      return KeyEventResult.handled;
    }
    if (!_paged && (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) && _scroll.hasClients) {
      _scroll.jumpTo((_scroll.offset + (key == LogicalKeyboardKey.arrowDown ? 60 : -60)).clamp(0, _scroll.position.maxScrollExtent).toDouble());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  UDocDrawController get drawing => _draw;

  bool get _drawingEnabled => widget.enableDrawing && widget.enableMarkup;

  bool get _drawActive => _drawingEnabled && _drawOpen && _draw.isActive;

  /// Opens or closes the drawing toolbar.
  void toggleDrawing([bool? open]) {
    final bool next = open ?? !_drawOpen;
    if (next && !_draw.isActive) _draw.tool = UDocDrawTool.pen;
    if (!next) _draw.tool = UDocDrawTool.none;
    _clearSelection();
    setState(() {
      _drawOpen = next;
      _activeMarkup = null;
      _chromeVisible = true;
    });
  }

  void _onTap(Offset position, Size size) {
    if (_drawActive) return;
    if (_markupTapped || _linkTapped) {
      _markupTapped = false;
      _linkTapped = false;
      return;
    }
    if (_selectionAtDown || _selection.isNotEmpty || _frozenSelection.isNotEmpty) {
      _clearSelection();
      return;
    }
    if (_activeMarkup != null) {
      setState(() => _activeMarkup = null);
      return;
    }
    final double x = position.dx / max(1, size.width);
    if (_paged && x < 0.22) {
      _controller.settings.isRtl ? nextPage() : previousPage();
    } else if (_paged && x > 0.78) {
      _controller.settings.isRtl ? previousPage() : nextPage();
    } else {
      setState(() => _chromeVisible = !_chromeVisible);
    }
  }

  @override
  void dispose() {
    _saveProgress();
    _progressTimer?.cancel();
    _visibleTimer?.cancel();
    _controller.removeListener(_onChanged);
    _markup.removeListener(_onChanged);
    if (_ownsMarkup) _markup.dispose();
    _draw.removeListener(_onChanged);
    if (_ownsDraw) _draw.dispose();
    _scroll.dispose();
    _pageController?.dispose();
    _searchField.dispose();
    _focus.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  // ───────────────────────── build ─────────────────────────

  double get _topPad => widget.showToolbar ? 56 + MediaQuery.paddingOf(context).top : 0;

  double get _bottomPad => widget.showBottomBar ? 64 + MediaQuery.paddingOf(context).bottom : 0;

  @override
  Widget build(BuildContext context) {
    final UDocValue value = _controller.value;
    final UDocColorMode mode = _controller.settings.colorMode;
    final Color background = UEpubTextStyler.background(context, mode);
    return USecureArea(
      enabled: widget.secure,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: ColoredBox(
          color: background,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              _totalWidth = constraints.maxWidth;
              final bool pinned = widget.showSidebar && _wide && _sidebarPinned && value.isReady;
              return Row(
                children: <Widget>[
                  if (pinned)
                    SizedBox(
                      width: 300,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BorderDirectional(end: BorderSide(color: Theme.of(context).dividerColor)),
                        child: SafeArea(right: false, child: _buildSidebar(value)),
                      ),
                    ),
                  Expanded(child: _buildMain(value, background)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMain(UDocValue value, Color background) {
    final bool overlaySidebar = widget.showSidebar && !_wide && _sidebarOpen && value.isReady;
    final UDocWatermark? watermark = widget.watermark;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _buildBody(value, background)),
        if (watermark != null && value.isReady)
          Positioned.fill(
            child: UDocWatermarkLayer(watermark: watermark, pageIndex: _controller.value.pageIndex * 97 + _pageInChapter),
          ),
        if (_controller.settings.dim > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: _controller.settings.dim)),
            ),
          ),
        if (widget.showToolbar && _chromeVisible) Positioned(left: 0, right: 0, top: 0, child: _buildToolbar(value)),
        if (widget.showBottomBar && _chromeVisible && value.isReady)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(animation: _scroll, builder: (BuildContext context, Widget? child) => _buildBottomBar(value)),
          ),
        if (_activeSelection.isNotEmpty) _buildSelectionMenu(),
        if (_activeMarkup != null && _activeSelection.isEmpty) _buildMarkupMenu(_activeMarkup!),
        if (overlaySidebar) ...<Widget>[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _sidebarOpen = false),
              child: const ColoredBox(color: Color(0x66000000)),
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: min(340, _totalWidth * 0.88),
            child: Material(elevation: 8, child: SafeArea(right: false, child: _buildSidebar(value))),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(UDocValue value, Color background) {
    if (value.state == UDocState.opening || value.state == UDocState.idle || (_loading && _chapter == null)) return const Center(child: CircularProgressIndicator());
    if (value.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              UTextBodyMedium(U.s.couldNotOpenTheDocument, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => unawaited(_start()), child: UTextBodyMedium(U.s.retry)),
            ],
          ),
        ),
      );
    }
    final UEpubChapter? chapter = _chapter;
    if (chapter == null) return const SizedBox.shrink();
    final bool rtl = _controller.settings.isRtl;
    final Widget content = LayoutBuilder(
      key: _viewportKey,
      builder: (BuildContext context, BoxConstraints constraints) {
        if (_controller.book?.fixedLayout ?? false) return _buildFixedLayout(chapter);
        final Widget view = _paged ? _buildPaged(chapter, constraints) : _buildContinuous(chapter);
        // A drawing tool owns single-finger drags; wheel and trackpad still scroll.
        return ScrollConfiguration(
          behavior: _drawActive ? ScrollConfiguration.of(context).copyWith(dragDevices: const <PointerDeviceKind>{PointerDeviceKind.trackpad}) : ScrollConfiguration.of(context),
          child: view,
        );
      },
    );
    final Widget selectable = SelectionArea(
      key: _selectionKey,
      onSelectionChanged: _onSelectionChanged,
      contextMenuBuilder: (BuildContext context, SelectableRegionState state) => const SizedBox.shrink(),
      child: Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: content),
    );
    final Widget guarded = widget.allowCopy
        ? selectable
        : Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.keyC, control: true): DoNothingAndStopPropagationIntent(),
              SingleActivator(LogicalKeyboardKey.keyC, meta: true): DoNothingAndStopPropagationIntent(),
              SingleActivator(LogicalKeyboardKey.keyX, control: true): DoNothingAndStopPropagationIntent(),
              SingleActivator(LogicalKeyboardKey.keyX, meta: true): DoNothingAndStopPropagationIntent(),
            },
            child: selectable,
          );
    // Raw pointer events: SelectableRegion wins the tap gesture arena, so an
    // ancestor GestureDetector would never see taps on the text.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (PointerDownEvent event) {
          _pointerDown = event.position;
          _pointerDownAt = DateTime.now();
          _markupTapped = false;
          _linkTapped = false;
          _selectionAtDown = _selection.isNotEmpty;
        },
        onPointerUp: (PointerUpEvent event) {
          if (!_isShortTap(event.position)) return;
          final Offset local = event.localPosition;
          final Size size = constraints.biggest;
          Timer(const Duration(milliseconds: 40), () {
            if (mounted) _onTap(local, size);
          });
        },
        child: widget.allowSelection ? guarded : Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: content),
      ),
    );
  }

  bool _isShortTap(Offset position) {
    final Offset? down = _pointerDown;
    return down != null && (position - down).distance < 12 && DateTime.now().difference(_pointerDownAt) < const Duration(milliseconds: 350);
  }

  Widget _buildFixedLayout(UEpubChapter chapter) {
    final UEpubBlock? image = chapter.blocks.where((UEpubBlock block) => block.kind == UEpubBlockKind.image).firstOrNull;
    if (image != null) {
      return InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: UEpubImageView(controller: _controller, href: image.imageHref ?? ""),
        ),
      );
    }
    return _buildContinuous(chapter);
  }

  Widget _buildContinuous(UEpubChapter chapter) {
    final UEpubTypography typography = _controller.typography;
    return Scrollbar(
      controller: _scroll,
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(typography.horizontalMargin, typography.verticalMargin + _topPad, typography.horizontalMargin, typography.verticalMargin + _bottomPad),
        itemCount: chapter.blocks.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == chapter.blocks.length) return _buildChapterFooter();
          final GlobalKey key = _blockKeys[index] ??= GlobalKey(debugLabel: "block-$index");
          return KeyedSubtree(
            key: key,
            child: _buildBlock(chapter, UEpubSlice(blockIndex: index)),
          );
        },
      ),
    );
  }

  Widget _buildPaged(UEpubChapter chapter, BoxConstraints constraints) {
    final UEpubTypography typography = _controller.typography;
    final double contentHeight = constraints.maxHeight - _topPad - _bottomPad;
    final Size size = Size(constraints.maxWidth, contentHeight);
    final String key = "${chapter.spineIndex}|${size.width.round()}x${size.height.round()}|${typography.toJson()}|${_controller.settings.colorMode.name}|${MediaQuery.textScalerOf(context).scale(10)}";
    if (key != _pagesKey || _pages.isEmpty) {
      _pagesKey = key;
      final UDocColorMode mode = _controller.settings.colorMode;
      _pages = UEpubPaginator(typography: typography, size: size, textScaler: MediaQuery.textScalerOf(context)).paginateSlices(
        chapter,
        painterFor: (UEpubBlock block, double width) => UEpubTextStyler.painter(context, block, typography, mode, width),
        measureOther: (UEpubBlock block, double width) => block.kind == UEpubBlockKind.image ? contentHeight * 0.55 : 32,
      );
      _pageInChapter = _pageInChapter.clamp(0, _pages.length - 1);
      _pageController?.dispose();
      _pageController = PageController(initialPage: _pageInChapter + (_hasPreviousChapter ? 1 : 0));
    }
    final int leading = _hasPreviousChapter ? 1 : 0;
    final int trailing = _hasNextChapter ? 1 : 0;
    return PageView.builder(
      controller: _pageController,
      reverse: _controller.settings.isRtl,
      itemCount: _pages.length + leading + trailing,
      onPageChanged: (int item) {
        if (leading == 1 && item == 0) {
          unawaited(_loadChapter(_controller.value.pageIndex - 1, atEnd: true));
          return;
        }
        if (trailing == 1 && item == _pages.length + leading) {
          unawaited(_loadChapter(_controller.value.pageIndex + 1));
          return;
        }
        _clearSelection();
        setState(() => _pageInChapter = item - leading);
      },
      itemBuilder: (BuildContext context, int item) {
        final int page = item - leading;
        if (page < 0 || page >= _pages.length) return const Center(child: CircularProgressIndicator());
        return Padding(
          padding: EdgeInsets.fromLTRB(typography.horizontalMargin, typography.verticalMargin + _topPad, typography.horizontalMargin, typography.verticalMargin + _bottomPad),
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: _pages[page].slices.map((UEpubSlice slice) => _buildBlock(chapter, slice)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlock(UEpubChapter chapter, UEpubSlice slice) {
    final UEpubBlock block = chapter.blocks[slice.blockIndex];
    final int sliceEnd = slice.endIn(block);
    final List<UDocMarkup> markups = widget.enableMarkup
        ? _markup.markupsOn(chapter.spineIndex).where((UDocMarkup markup) => markup.blockIndex == slice.blockIndex && markup.end > slice.start && markup.start < sliceEnd).toList()
        : const <UDocMarkup>[];
    final List<(int, int)> hits = <(int, int)>[];
    (int, int)? activeHit;
    for (final UDocSearchHit hit in _controller.value.searchHits) {
      if (hit is! UEpubSearchHit || hit.pageIndex != chapter.spineIndex || hit.blockIndex != slice.blockIndex) continue;
      if (hit.end <= slice.start || hit.start >= sliceEnd) continue;
      hits.add((hit.start, hit.end));
      if (identical(hit, _flash) || hit == _controller.value.currentHit) activeHit = (hit.start, hit.end);
    }
    return UEpubBlockView(
      key: ValueKey<String>("${chapter.spineIndex}:${slice.blockIndex}:${slice.start}"),
      block: block,
      blockIndex: slice.blockIndex,
      sliceStart: slice.start,
      sliceEnd: slice.end,
      typography: _controller.typography,
      colorMode: _controller.settings.colorMode,
      controller: _controller,
      onLinkTapped: _handleLink,
      markups: markups,
      activeMarkupId: _activeMarkup?.id,
      searchRanges: hits,
      activeSearch: activeHit,
      noteDisplay: widget.noteDisplay,
      onMarkupTap: (UDocMarkup markup, Offset position) {
        if (!_isShortTap(position)) return false;
        return _onMarkupHit(markup);
      },
      onImageTap: (String href) => unawaited(_showImage(href)),
      onRegister: _register,
      onUnregister: _unregister,
      shapes: _drawingEnabled ? _markup.shapesOnBlock(chapter.spineIndex, slice.blockIndex) : const <UDocShape>[],
      drawTools: _drawingEnabled ? _draw : null,
      drawing: _drawOpen,
      onShapeAdd: (UDocShape shape) => _markup.addShape(shape.placed(pageIndex: chapter.spineIndex, blockIndex: slice.blockIndex)),
      onShapeUpdate: _markup.updateShape,
      onShapeRemove: _markup.removeShape,
    );
  }

  Widget _buildChapterFooter() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        TextButton.icon(
          onPressed: _hasPreviousChapter ? () => unawaited(_loadChapter(_controller.value.pageIndex - 1)) : null,
          icon: const Icon(Icons.chevron_left_rounded),
          label: UTextBodySmall(U.s.previousChapter),
        ),
        TextButton.icon(
          onPressed: _hasNextChapter ? () => unawaited(_loadChapter(_controller.value.pageIndex + 1)) : null,
          icon: const Icon(Icons.chevron_right_rounded),
          label: UTextBodySmall(U.s.nextChapter),
        ),
      ],
    ),
  );

  Widget _buildSelectionMenu() => Positioned(
    left: 12,
    right: 12,
    bottom: (widget.showBottomBar && _chromeVisible ? _bottomPad : MediaQuery.paddingOf(context).bottom) + 12,
    child: Center(
      // Buttons must not take focus: SelectableRegion clears its selection when it loses focus.
      child: Listener(
        onPointerDown: (PointerDownEvent event) => _frozenSelection = List<_UEpubSelectionRange>.from(_selection),
        child: ExcludeFocus(
          child: UDocSelectionMenu(
            color: _markup.color,
            kinds: widget.enableMarkup ? widget.markupKinds : const <UDocMarkupKind>[],
            onColor: (Color color) => _markup.color = color,
            onMarkup: (UDocMarkupKind kind) => unawaited(_applyMarkup(kind)),
            onCopy: widget.allowCopy
                ? () {
                    unawaited(UClipboard.set(_selectedText));
                    UToast.toast(message: U.s.copied);
                    _clearSelection();
                  }
                : null,
            onShare: widget.allowCopy && widget.allowShare ? () => unawaited(UShare.text(_selectedText)) : null,
            onSearch: () {
              final String query = _selectedText.split("\n").first;
              _clearSelection();
              _searchField.text = query;
              _openSidebar(_UEpubSidebarTab.search);
              unawaited(_runSearch(query));
            },
            onClose: _clearSelection,
          ),
        ),
      ),
    ),
  );

  Widget _buildMarkupMenu(UDocMarkup markup) => Positioned(
    left: 12,
    right: 12,
    bottom: (widget.showBottomBar && _chromeVisible ? _bottomPad : MediaQuery.paddingOf(context).bottom) + 12,
    child: Center(
      child: UDocMarkupMenu(markup: markup, controller: _markup, allowCopy: widget.allowCopy, kinds: widget.markupKinds, onDone: () => setState(() => _activeMarkup = null)),
    ),
  );

  Widget _buildToolbar(UDocValue value) {
    final bool compact = _totalWidth < 520;
    final bool bookmarked = widget.enableMarkup && _currentBookmarks.isNotEmpty;
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 56,
              child: Row(
                children: <Widget>[
                  if (widget.showBackButton) IconButton(icon: const BackButtonIcon(), tooltip: U.s.back, onPressed: widget.onBack ?? () => Navigator.of(context).maybePop()),
                  if (widget.showSidebar && value.isReady) IconButton(icon: const Icon(Icons.view_sidebar_outlined), tooltip: U.s.contents, onPressed: _toggleSidebar),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        UTextTitleSmall(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if ((_chapter?.title ?? "").isNotEmpty && _chapter!.title != _title) UTextBodySmall(_chapter!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  ...widget.actions,
                  if (value.isReady) IconButton(icon: const Icon(Icons.search_rounded), tooltip: U.s.search, onPressed: () => _openSidebar(_UEpubSidebarTab.search)),
                  if (value.isReady && widget.enableMarkup)
                    IconButton(
                      icon: Icon(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_outlined, color: bookmarked ? _currentBookmarks.first.color : null),
                      tooltip: bookmarked ? U.s.removeBookmark : U.s.bookmarkPosition,
                      onPressed: _toggleBookmark,
                    ),
                  if (value.isReady && widget.enableMarkup && !compact) IconButton(icon: const Icon(Icons.undo_rounded), tooltip: U.s.undo, onPressed: _markup.canUndo ? _markup.undo : null),
                  if (value.isReady && _drawingEnabled)
                    IconButton(
                      icon: Icon(_drawOpen ? Icons.draw_rounded : Icons.draw_outlined, color: _drawOpen ? Theme.of(context).colorScheme.primary : null),
                      tooltip: U.s.draw,
                      isSelected: _drawOpen,
                      onPressed: toggleDrawing,
                    ),
                  if (value.isReady) IconButton(icon: const Icon(Icons.text_fields_rounded), tooltip: U.s.readingMode, onPressed: () => unawaited(_openSettings())),
                  if (value.isReady && widget.enableMarkup)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      tooltip: U.s.more,
                      onSelected: (String action) => unawaited(_onMenu(action)),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        _menuItem("annotations", Icons.sticky_note_2_outlined, U.s.annotations),
                        _menuItem("bookmarks", Icons.bookmarks_outlined, U.s.bookmarks),
                        _menuItem("exportNotes", Icons.ios_share_rounded, U.s.exportAnnotations),
                        _menuItem("exportData", Icons.data_object_rounded, U.s.export),
                        _menuItem("importData", Icons.download_rounded, U.s.importAnnotations),
                        _menuItem("clearAll", Icons.delete_sweep_outlined, U.s.clearAnnotations),
                      ],
                    ),
                ],
              ),
            ),
            if (_drawOpen)
              SizedBox(
                height: 52,
                child: UDocDrawToolbar(
                  tools: _draw,
                  onUndo: _markup.canUndo ? _markup.undo : null,
                  onRedo: _markup.canRedo ? _markup.redo : null,
                  onDone: () => toggleDrawing(false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) => PopupMenuItem<String>(
    value: value,
    child: Row(children: <Widget>[Icon(icon, size: 20), const SizedBox(width: 12), UTextBodyMedium(label)]),
  );

  Widget _buildBottomBar(UDocValue value) {
    final int minutes = _minutesLeftInChapter();
    final String location = _paged && _pages.isNotEmpty ? "${_pageInChapter + 1}/${_pages.length}" : "${value.pageIndex + 1}/${value.pageCount}";
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
      elevation: 2,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: <Widget>[
                IconButton(icon: const Icon(Icons.skip_previous_rounded), tooltip: U.s.previousChapter, onPressed: _hasPreviousChapter ? () => unawaited(_loadChapter(value.pageIndex - 1)) : null),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        height: 30,
                        child: value.pageCount <= 1
                            ? const SizedBox.shrink()
                            : Slider(
                                value: value.pageIndex.toDouble().clamp(0, (value.pageCount - 1).toDouble()),
                                max: (value.pageCount - 1).toDouble(),
                                divisions: value.pageCount - 1,
                                label: _chapterLabel(value.pageIndex),
                                onChanged: (double next) => unawaited(_loadChapter(next.round())),
                              ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          UTextLabelSmall("${(_percent() * 100).round()}%"),
                          if (minutes > 0) UTextLabelSmall(U.s.minutesLeftInChapter("$minutes")),
                          UTextLabelSmall(location),
                        ],
                      ).pSymmetric(horizontal: 16),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.skip_next_rounded), tooltip: U.s.nextChapter, onPressed: _hasNextChapter ? () => unawaited(_loadChapter(value.pageIndex + 1)) : null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(UDocValue value) {
    final List<(_UEpubSidebarTab, IconData, String)> tabs = <(_UEpubSidebarTab, IconData, String)>[
      (_UEpubSidebarTab.contents, Icons.format_list_bulleted_rounded, U.s.contents),
      if (widget.enableMarkup) (_UEpubSidebarTab.annotations, Icons.sticky_note_2_outlined, U.s.annotations),
      if (widget.enableMarkup) (_UEpubSidebarTab.bookmarks, Icons.bookmarks_outlined, U.s.bookmarks),
      (_UEpubSidebarTab.search, Icons.search_rounded, U.s.search),
    ];
    if (!tabs.any(((_UEpubSidebarTab, IconData, String) tab) => tab.$1 == _tab)) _tab = tabs.first.$1;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: Row(
            children: <Widget>[
              for (final (_UEpubSidebarTab, IconData, String) tab in tabs)
                Expanded(
                  child: IconButton(
                    tooltip: tab.$3,
                    isSelected: _tab == tab.$1,
                    color: _tab == tab.$1 ? Theme.of(context).colorScheme.primary : null,
                    icon: Icon(tab.$2),
                    onPressed: () => setState(() => _tab = tab.$1),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _sidebarContent(value)),
      ],
    );
  }

  Widget _sidebarContent(UDocValue value) {
    switch (_tab) {
      case _UEpubSidebarTab.contents:
        return _buildContents(value);
      case _UEpubSidebarTab.annotations:
        return UDocAnnotationsPanel(
          controller: _markup,
          allowCopy: widget.allowCopy,
          pageLabel: (UDocMarkup markup) => _chapterLabel(markup.pageIndex),
          onOpen: (UDocMarkup markup) => unawaited(_openMarkup(markup)),
        );
      case _UEpubSidebarTab.bookmarks:
        return UDocBookmarksPanel(controller: _markup, pageLabel: (UDocBookmark bookmark) => _chapterLabel(bookmark.pageIndex), onOpen: (UDocBookmark bookmark) => unawaited(_openBookmark(bookmark)));
      case _UEpubSidebarTab.search:
        return _buildSearchPanel(value);
    }
  }

  Widget _buildContents(UDocValue value) {
    final List<UDocOutlineNode> outline = _controller.outline;
    if (outline.isEmpty) {
      return ListView.builder(
        itemCount: _controller.pageCount,
        itemBuilder: (BuildContext context, int index) => ListTile(
          dense: true,
          selected: index == value.pageIndex,
          title: UTextBodyMedium("${U.s.chapter} ${index + 1}"),
          onTap: () {
            _closeSidebarIfOverlay();
            unawaited(_loadChapter(index));
          },
        ),
      );
    }
    final List<Widget> items = <Widget>[];
    void walk(List<UDocOutlineNode> nodes, int depth) {
      for (final UDocOutlineNode node in nodes) {
        final UDocDestination? destination = node.destination;
        items.add(
          ListTile(
            dense: true,
            selected: destination?.pageIndex == value.pageIndex,
            contentPadding: EdgeInsetsDirectional.only(start: 16 + depth * 16, end: 12),
            title: Text(
              node.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: UDocText.isRtl(node.title) ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () {
              _closeSidebarIfOverlay();
              if (destination != null) unawaited(_loadChapter(destination.pageIndex, anchor: destination.anchor));
            },
          ),
        );
        if (node.hasChildren) walk(node.children, depth + 1);
      }
    }

    walk(outline, 0);
    return ListView(children: items);
  }

  Widget _buildSearchPanel(UDocValue value) => Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: TextField(
          controller: _searchField,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (String query) => unawaited(_runSearch(query)),
          decoration: InputDecoration(isDense: true, hintText: U.s.search, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.search_rounded, size: 20)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: <Widget>[
            FilterChip(label: const UTextBodySmall("\"ab\""), selected: _wholeWord, onSelected: (bool next) => setState(() => _wholeWord = next)),
            const Spacer(),
            if (value.isSearching) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            if (value.searchHits.isNotEmpty) ...<Widget>[
              UTextBodySmall("${value.searchHitIndex + 1}/${value.searchHits.length}"),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.keyboard_arrow_up_rounded), onPressed: () => _stepHit(-1)),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.keyboard_arrow_down_rounded), onPressed: () => _stepHit(1)),
            ],
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: ValueListenableBuilder<List<UDocSearchHit>>(
          valueListenable: _controller.liveHits,
          builder: (BuildContext context, List<UDocSearchHit> live, Widget? child) {
            final List<UEpubSearchHit> hits = (value.searchHits.isNotEmpty ? value.searchHits : live).whereType<UEpubSearchHit>().toList();
            if (hits.isEmpty) return Center(child: UTextBodySmall(value.searchQuery.isEmpty || value.isSearching ? "" : U.s.noResults));
            return ListView.builder(
              itemCount: hits.length,
              itemBuilder: (BuildContext context, int index) {
                final UEpubSearchHit hit = hits[index];
                final bool header = index == 0 || hits[index - 1].pageIndex != hit.pageIndex;
                final bool rtl = UDocText.isRtl(hit.snippet);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (header)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: UTextLabelLarge(_chapterLabel(hit.pageIndex), fontWeight: FontWeight.w700, maxLines: 1),
                      ),
                    Material(
                      color: index == value.searchHitIndex ? Theme.of(context).colorScheme.primaryContainer : const Color(0x00000000),
                      child: InkWell(
                        onTap: () => unawaited(_openHit(hit)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            hit.snippet,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

/// One EPUB block (or the part of it on the current page) with markups painted in.
class UEpubBlockView extends StatefulWidget {
  const UEpubBlockView({
    required this.block,
    required this.typography,
    required this.colorMode,
    required this.controller,
    required this.onLinkTapped,
    this.blockIndex = 0,
    this.sliceStart = 0,
    this.sliceEnd = -1,
    this.markups = const <UDocMarkup>[],
    this.activeMarkupId,
    this.searchRanges = const <(int, int)>[],
    this.activeSearch,
    this.noteDisplay = UDocNoteDisplay.badge,
    this.onMarkupTap,
    this.onImageTap,
    this.onRegister,
    this.onUnregister,
    this.shapes = const <UDocShape>[],
    this.drawTools,
    this.drawing = false,
    this.onShapeAdd,
    this.onShapeUpdate,
    this.onShapeRemove,
    super.key,
  });

  final UEpubBlock block;
  final UEpubTypography typography;
  final UDocColorMode colorMode;
  final UEpubController controller;
  final Future<void> Function(String href) onLinkTapped;
  final int blockIndex;
  final int sliceStart;
  final int sliceEnd;
  final List<UDocMarkup> markups;
  final String? activeMarkupId;
  final List<(int, int)> searchRanges;
  final (int, int)? activeSearch;
  final UDocNoteDisplay noteDisplay;
  final bool Function(UDocMarkup markup, Offset globalPosition)? onMarkupTap;
  final void Function(String href)? onImageTap;
  final void Function(String key, UEpubSlice slice, SelectionListenerNotifier notifier)? onRegister;
  final void Function(String key, SelectionListenerNotifier notifier)? onUnregister;

  /// Drawings anchored to this paragraph (x and y normalised by its width).
  final List<UDocShape> shapes;

  /// Enables the drawing layer; keep it constant for the widget's lifetime.
  final UDocDrawController? drawTools;
  final bool drawing;
  final void Function(UDocShape shape)? onShapeAdd;
  final void Function(UDocShape shape)? onShapeUpdate;
  final void Function(String id)? onShapeRemove;

  @override
  State<UEpubBlockView> createState() => _UEpubBlockViewState();
}

class _UEpubBlockViewState extends State<UEpubBlockView> {
  final SelectionListenerNotifier _notifier = SelectionListenerNotifier();
  final GlobalKey _textKey = GlobalKey();

  String get _registryKey => "${widget.blockIndex}:${widget.sliceStart}";

  @override
  void initState() {
    super.initState();
    widget.onRegister?.call(_registryKey, UEpubSlice(blockIndex: widget.blockIndex, start: widget.sliceStart, end: widget.sliceEnd), _notifier);
  }

  @override
  void didUpdateWidget(UEpubBlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blockIndex != widget.blockIndex || oldWidget.sliceStart != widget.sliceStart || oldWidget.sliceEnd != widget.sliceEnd) {
      oldWidget.onUnregister?.call("${oldWidget.blockIndex}:${oldWidget.sliceStart}", _notifier);
      widget.onRegister?.call(_registryKey, UEpubSlice(blockIndex: widget.blockIndex, start: widget.sliceStart, end: widget.sliceEnd), _notifier);
    }
  }

  @override
  void dispose() {
    widget.onUnregister?.call(_registryKey, _notifier);
    _notifier.dispose();
    super.dispose();
  }

  Color get _foreground => UEpubTextStyler.foreground(context, widget.colorMode);

  void _onPointerUp(PointerUpEvent event) {
    final RenderObject? box = _textKey.currentContext?.findRenderObject();
    if (box is! RenderBox || widget.markups.isEmpty || widget.onMarkupTap == null) return;
    final Offset local = box.globalToLocal(event.position);
    final TextPainter painter = UEpubTextStyler.painter(context, widget.block, widget.typography, widget.colorMode, box.size.width, start: widget.sliceStart, end: widget.sliceEnd);
    final int offset = painter.getPositionForOffset(local).offset + widget.sliceStart;
    final Rect bounds = Offset.zero & painter.size;
    painter.dispose();
    if (!bounds.inflate(4).contains(local)) return;
    for (final UDocMarkup markup in widget.markups.reversed) {
      if (offset >= markup.start && offset <= markup.end) {
        widget.onMarkupTap!(markup, event.position);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final UDocDrawController? tools = widget.drawTools;
    final Widget content = _buildContent(context);
    if (tools == null) return content;
    // Always the same Stack so the SelectionListener below never re-registers.
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        content,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => UDocShapeLayer(
              shapes: widget.shapes,
              tools: tools,
              enabled: widget.drawing,
              space: UDocShapeSpace.width,
              origin: Offset(0, _sliceTop(context, constraints.maxWidth)),
              onAdd: (UDocShape shape) => widget.onShapeAdd?.call(shape),
              onUpdate: (UDocShape shape) => widget.onShapeUpdate?.call(shape),
              onRemove: (String id) => widget.onShapeRemove?.call(id),
            ),
          ),
        ),
      ],
    );
  }

  /// Top of this slice inside the whole paragraph, so drawings stay put when a
  /// paragraph is split across pages.
  double _sliceTop(BuildContext context, double width) {
    if (widget.sliceStart <= 0 || (widget.shapes.isEmpty && !widget.drawing)) return 0;
    final UEpubBlock block = widget.block;
    double textWidth = width - max(0, block.indent);
    if (block.kind == UEpubBlockKind.listItem) textWidth -= 32;
    if (block.kind == UEpubBlockKind.blockquote) textWidth -= 27;
    if (block.kind == UEpubBlockKind.preformatted) textWidth -= 20;
    final TextPainter painter = UEpubTextStyler.painter(context, block, widget.typography, widget.colorMode, max(20, textWidth));
    final double top = painter.getOffsetForCaret(TextPosition(offset: widget.sliceStart), Rect.zero).dy;
    painter.dispose();
    return block.marginTop + top;
  }

  Widget _buildContent(BuildContext context) {
    final UEpubBlock block = widget.block;
    if (block.kind == UEpubBlockKind.rule) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: max(8, block.marginTop)),
        child: Divider(color: _foreground.withValues(alpha: 0.3)),
      );
    }
    if (block.kind == UEpubBlockKind.pageBreak) return const SizedBox(height: 8);
    if (block.kind == UEpubBlockKind.image) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: max(4, block.marginTop)),
        child: GestureDetector(
          onTap: widget.onImageTap == null ? null : () => widget.onImageTap!(block.imageHref ?? ""),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
              child: UEpubImageView(controller: widget.controller, href: block.imageHref ?? ""),
            ),
          ),
        ),
      );
    }
    if (block.kind == UEpubBlockKind.tableRow) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: block.marginTop),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.cells
              .map(
                (List<UEpubSpan> cell) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(border: Border.all(color: _foreground.withValues(alpha: 0.25))),
                    child: Text(
                      cell.map((UEpubSpan span) => span.text).join(),
                      style: TextStyle(fontSize: widget.typography.baseFontSize * 0.92, color: _foreground, height: widget.typography.lineHeight),
                      textDirection: block.rtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
    if (block.spans.isEmpty) return const SizedBox.shrink();
    final TextSpan span = UEpubTextStyler.span(
      context,
      block,
      widget.typography,
      widget.colorMode,
      start: widget.sliceStart,
      end: widget.sliceEnd,
      onLink: (String href) => unawaited(widget.onLinkTapped(href)),
    );
    final TextAlign align = UEpubTextStyler.align(block, widget.typography);
    final TextDirection direction = UEpubTextStyler.direction(block);
    final List<_UEpubRange> ranges = <_UEpubRange>[
      ...widget.searchRanges.map(((int, int) range) => _UEpubRange(range.$1 - widget.sliceStart, range.$2 - widget.sliceStart, search: true, active: range == widget.activeSearch)),
      ...widget.markups.map((UDocMarkup markup) => _UEpubRange(markup.start - widget.sliceStart, markup.end - widget.sliceStart, markup: markup, active: markup.id == widget.activeMarkupId)),
    ];
    Widget text = Text.rich(
      span,
      key: _textKey,
      textAlign: align,
      textDirection: direction,
      textScaler: MediaQuery.textScalerOf(context),
    );
    // The tree shape must never change between builds: a new SelectionListener
    // element would register the same notifier twice and assert.
    final double fontSize = MediaQuery.textScalerOf(context).scale(widget.typography.baseFontSize * (block.kind == UEpubBlockKind.heading ? UEpubTextStyler.headingScale(block.level) : 1));
    text = Listener(
      onPointerUp: ranges.isEmpty ? null : _onPointerUp,
      child: CustomPaint(
        painter: ranges.isEmpty
            ? null
            : _UEpubRangePainter(context: context, span: span, align: align, direction: direction, ranges: ranges, foreground: false, noteDisplay: widget.noteDisplay, fontSize: fontSize),
        foregroundPainter: ranges.isEmpty
            ? null
            : _UEpubRangePainter(context: context, span: span, align: align, direction: direction, ranges: ranges, foreground: true, noteDisplay: widget.noteDisplay, fontSize: fontSize),
        child: SelectionListener(selectionNotifier: _notifier, child: text),
      ),
    );
    Widget content = text;
    if (block.kind == UEpubBlockKind.listItem) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 32,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8, top: 2),
              child: Text(
                widget.sliceStart == 0 ? block.listMarker : "",
                textAlign: TextAlign.end,
                style: TextStyle(color: _foreground, fontSize: widget.typography.baseFontSize),
              ),
            ),
          ),
          Expanded(child: text),
        ],
      );
    }
    if (block.kind == UEpubBlockKind.blockquote) {
      content = Container(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 12),
        decoration: BoxDecoration(
          border: BorderDirectional(start: BorderSide(color: _foreground.withValues(alpha: 0.35), width: 3)),
        ),
        child: text,
      );
    }
    if (block.kind == UEpubBlockKind.preformatted) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        color: _foreground.withValues(alpha: 0.06),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: text),
      );
    }
    final bool first = widget.sliceStart == 0;
    final bool last = widget.sliceEnd < 0;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: first ? block.marginTop : 0, bottom: last ? block.marginBottom + widget.typography.paragraphSpacing / 2 : 0, start: block.indent > 0 ? block.indent : 0),
      child: content,
    );
  }
}

class _UEpubRange {
  const _UEpubRange(this.start, this.end, {this.markup, this.search = false, this.active = false});

  final int start;
  final int end;
  final UDocMarkup? markup;
  final bool search;
  final bool active;
}

class _UEpubRangePainter extends CustomPainter {
  _UEpubRangePainter({
    required this.context,
    required this.span,
    required this.align,
    required this.direction,
    required this.ranges,
    required this.foreground,
    required this.noteDisplay,
    required this.fontSize,
  });

  final BuildContext context;
  final TextSpan span;
  final TextAlign align;
  final TextDirection direction;
  final List<_UEpubRange> ranges;
  final bool foreground;
  final UDocNoteDisplay noteDisplay;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter painter = TextPainter(
      text: span,
      textAlign: align,
      textDirection: direction,
      textScaler: MediaQuery.textScalerOf(context),
      textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
    )..layout(minWidth: size.width, maxWidth: size.width);
    final String plain = span.toPlainText(includeSemanticsLabels: false);
    for (final _UEpubRange range in ranges) {
      final List<Rect> rects = UEpubTextStyler.lineRects(painter, plain, range.start, range.end, fontSize: fontSize);
      if (rects.isEmpty) continue;
      if (range.search) {
        if (foreground) continue;
        final Paint paint = Paint()..color = range.active ? const Color(0x99FF9800) : const Color(0x66FFC107);
        for (final Rect rect in rects) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
        }
        continue;
      }
      final UDocMarkup? markup = range.markup;
      if (markup == null) continue;
      final bool fill = markup.kind == UDocMarkupKind.highlight || markup.kind == UDocMarkupKind.note;
      if (!foreground) {
        if (fill) UDocMarkupPainter.paint(canvas, markup.kind, rects, markup.color, drawBadge: false);
        continue;
      }
      if (fill) {
        if (range.active) UDocMarkupPainter.outline(canvas, rects);
      } else {
        UDocMarkupPainter.paint(canvas, markup.kind, rects, markup.color, selected: range.active, drawBadge: false);
      }
      if ((markup.hasNote || markup.kind == UDocMarkupKind.note) && noteDisplay != UDocNoteDisplay.hidden) _badge(canvas, rects, markup.color);
    }
    painter.dispose();
  }

  void _badge(Canvas canvas, List<Rect> rects, Color color) {
    final bool rtl = direction == TextDirection.rtl;
    final Rect anchor = rects.last;
    final double size = (fontSize * 0.9).clamp(10, 20).toDouble();
    UDocMarkupPainter.badge(canvas, Offset(rtl ? anchor.left - size * 0.2 : anchor.right + size * 0.2, anchor.top - size * 0.1), color, size);
  }

  @override
  bool shouldRepaint(_UEpubRangePainter oldDelegate) =>
      oldDelegate.span != span || oldDelegate.ranges != ranges || oldDelegate.align != align || oldDelegate.direction != direction || oldDelegate.fontSize != fontSize;
}

class UEpubImageView extends StatefulWidget {
  const UEpubImageView({required this.controller, required this.href, super.key});

  final UEpubController controller;
  final String href;

  @override
  State<UEpubImageView> createState() => _UEpubImageViewState();
}

class _UEpubImageViewState extends State<UEpubImageView> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final Uint8List? bytes = await widget.controller.image(widget.href);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _failed = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final Uint8List? bytes = _bytes;
    if (bytes == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (widget.href.toLowerCase().endsWith(".svg")) return SvgPicture.memory(bytes);
    return Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (BuildContext context, Object error, StackTrace? stack) => const SizedBox.shrink());
  }
}

class UEpubSettingsPanel extends StatefulWidget {
  const UEpubSettingsPanel({required this.controller, required this.onChanged, super.key});

  final UEpubController controller;
  final VoidCallback onChanged;

  @override
  State<UEpubSettingsPanel> createState() => _UEpubSettingsPanelState();
}

class _UEpubSettingsPanelState extends State<UEpubSettingsPanel> {
  static const List<String?> _fonts = <String?>[null, "Vazir", "serif", "sans-serif", "monospace"];

  void _apply(UEpubTypography typography) {
    widget.controller.setTypography(typography);
    widget.onChanged();
    setState(() {});
  }

  void _settings(VoidCallback action) {
    action();
    widget.onChanged();
    setState(() {});
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, {String Function(double value)? format}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(child: UTextTitleSmall(label)),
          UTextLabelSmall(format?.call(value) ?? value.toStringAsFixed(1)),
        ],
      ),
      Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final UEpubTypography typography = widget.controller.typography;
    final UDocViewSettings settings = widget.controller.settings;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: UTextTitleMedium(U.s.fontSize)),
                IconButton.filledTonal(
                  icon: const Icon(Icons.text_decrease_rounded),
                  onPressed: () => _apply(typography.copyWith(fontScale: (typography.fontScale - 0.1).clamp(0.7, 2.6).toDouble())),
                ),
                SizedBox(width: 56, child: UTextBodyMedium("${(typography.fontScale * 100).round()}%", textAlign: TextAlign.center)),
                IconButton.filledTonal(
                  icon: const Icon(Icons.text_increase_rounded),
                  onPressed: () => _apply(typography.copyWith(fontScale: (typography.fontScale + 0.1).clamp(0.7, 2.6).toDouble())),
                ),
              ],
            ),
            const SizedBox(height: 12),
            UTextTitleSmall(U.s.fontFamily),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _fonts
                  .map(
                    (String? family) => ChoiceChip(
                      selected: typography.fontFamily == family,
                      label: Text(
                        family ?? U.s.defaultFont,
                        style: TextStyle(fontFamily: family, package: family == "Vazir" ? "u" : null),
                      ),
                      onSelected: (bool _) => _apply(
                        UEpubTypography(
                          fontScale: typography.fontScale,
                          lineHeight: typography.lineHeight,
                          fontFamily: family,
                          horizontalMargin: typography.horizontalMargin,
                          verticalMargin: typography.verticalMargin,
                          justify: typography.justify,
                          paragraphSpacing: typography.paragraphSpacing,
                          letterSpacing: typography.letterSpacing,
                          wordSpacing: typography.wordSpacing,
                          hyphenate: typography.hyphenate,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            _slider(U.s.lineSpacing, typography.lineHeight, 1.1, 2.6, (double next) => _apply(typography.copyWith(lineHeight: next))),
            _slider(U.s.paragraphSpacing, typography.paragraphSpacing, 0, 40, (double next) => _apply(typography.copyWith(paragraphSpacing: next)), format: (double value) => value.round().toString()),
            _slider(U.s.margins, typography.horizontalMargin, 0, 96, (double next) => _apply(typography.copyWith(horizontalMargin: next)), format: (double value) => value.round().toString()),
            _slider(U.s.letterSpacing, typography.letterSpacing, -1, 4, (double next) => _apply(typography.copyWith(letterSpacing: next))),
            _slider(U.s.wordSpacing, typography.wordSpacing, -2, 10, (double next) => _apply(typography.copyWith(wordSpacing: next))),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: typography.justify,
              title: UTextBodyMedium(U.s.justify),
              onChanged: (bool next) => _apply(typography.copyWith(justify: next)),
            ),
            UTextTitleSmall(U.s.readingMode),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <UDocScrollMode>[UDocScrollMode.verticalContinuous, UDocScrollMode.pagedHorizontal]
                  .map(
                    (UDocScrollMode mode) => ChoiceChip(
                      selected: settings.scrollMode == mode,
                      label: UTextBodySmall(mode == UDocScrollMode.verticalContinuous ? U.s.continuous : U.s.paged),
                      onSelected: (bool _) => _settings(() => widget.controller.setScrollMode(mode)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            UTextTitleSmall(U.s.theme),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <UDocColorMode>[UDocColorMode.normal, UDocColorMode.night, UDocColorMode.sepia, UDocColorMode.highContrast]
                  .map(
                    (UDocColorMode mode) => ChoiceChip(
                      selected: settings.colorMode == mode,
                      label: UTextBodySmall(_label(mode)),
                      onSelected: (bool _) => _settings(() => widget.controller.setColorMode(mode)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            UTextTitleSmall(U.s.pageDirection),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: UDocDirection.values
                  .map(
                    (UDocDirection direction) => ChoiceChip(
                      selected: settings.direction == direction,
                      label: UTextBodySmall(direction == UDocDirection.rtl ? U.s.rightToLeft : U.s.leftToRight),
                      onSelected: (bool _) => _settings(() => widget.controller.setDirection(direction)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            UTextTitleSmall(U.s.brightness),
            Slider(value: 1 - settings.dim, min: 0.15, onChanged: (double next) => _settings(() => widget.controller.setDim(1 - next))),
          ],
        ),
      ),
    );
  }

  String _label(UDocColorMode mode) {
    switch (mode) {
      case UDocColorMode.normal:
        return U.s.normal;
      case UDocColorMode.night:
        return U.s.night;
      case UDocColorMode.sepia:
        return U.s.sepia;
      case UDocColorMode.grayscale:
        return U.s.grayscale;
      case UDocColorMode.highContrast:
        return U.s.highContrast;
      case UDocColorMode.custom:
        return U.s.custom;
    }
  }
}

abstract class UEpub {
  /// Pushes a full-screen reader with every feature enabled.
  static Future<void> show({
    String? filePath,
    Uint8List? bytes,
    String? url,
    String? asset,
    int initialChapter = 0,
    String? title,
    String? annotationData,
    void Function(String data)? onAnnotationsChanged,
    bool allowCopy = true,
    bool secure = false,
    UDocWatermark? watermark,
  }) => UNavigator.push<void>(
    UScaffold(
      body: UEpubReader(
        filePath: filePath,
        bytes: bytes,
        url: url,
        asset: asset,
        initialChapter: initialChapter,
        title: title,
        showBackButton: true,
        annotationData: annotationData,
        onAnnotationsChanged: onAnnotationsChanged,
        allowCopy: allowCopy,
        allowShare: allowCopy,
        secure: secure,
        watermark: watermark,
      ),
    ),
  );

  static Future<UDocMetadata?> info({String? filePath, Uint8List? bytes, String? url}) async {
    try {
      final UEpubBook book = await UEpubBook.open(path: filePath, bytes: bytes, url: url);
      final UDocMetadata metadata = book.metadata;
      await book.close();
      return metadata;
    } on Object {
      return null;
    }
  }

  static Future<Uint8List?> cover({String? filePath, Uint8List? bytes, String? url}) async {
    try {
      final UEpubBook book = await UEpubBook.open(path: filePath, bytes: bytes, url: url);
      final String? href = book.coverHref;
      final Uint8List? data = href == null ? null : await book.resource(href);
      await book.close();
      return data == null || data.isEmpty ? null : data;
    } on Object {
      return null;
    }
  }

  static Future<String> extractText({String? filePath, Uint8List? bytes, String? url}) async {
    final UEpubBook book = await UEpubBook.open(path: filePath, bytes: bytes, url: url);
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < book.chapterCount; i++) {
      buffer.writeln((await book.chapter(i)).text);
    }
    await book.close();
    return buffer.toString();
  }
}
