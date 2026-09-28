import "dart:ui" as ui;

import "package:u/utilities.dart";

/// Builds extra widgets on top of a page (sized to the displayed page).
typedef UPdfPageOverlayBuilder = Widget Function(BuildContext context, int pageIndex, Size pageSize, double scale);

enum _UPdfSidebarTab { thumbnails, outline, annotations, bookmarks, search }

class UPdfViewer extends StatefulWidget {
  const UPdfViewer({
    this.base64Pdf,
    this.bytes,
    this.url,
    this.filePath,
    this.asset,
    this.controller,
    this.editController,
    this.annotations,
    this.password = "",
    this.initialPage = 0,
    this.title,
    this.showToolbar = true,
    this.showBottomBar = true,
    this.showSidebar = true,
    this.showScrollThumb = true,
    this.showBackButton = false,
    this.allowSelection = true,
    this.allowCopy = true,
    this.allowShare = true,
    this.enableMarkup = true,
    this.enableAnnotations = false,
    this.enableDrawing = true,
    this.drawController,
    this.markupKinds = UDocMarkupKind.values,
    this.annotationData,
    this.annotationStorageKey,
    this.persistAnnotations = true,
    this.onAnnotationsChanged,
    this.noteDisplay = UDocNoteDisplay.badge,
    this.textGeometry = UDocTextGeometry.auto,
    this.savePath,
    this.scrollMode = UDocScrollMode.verticalContinuous,
    this.spread = UDocSpread.none,
    this.direction,
    this.colorMode = UDocColorMode.normal,
    this.headers,
    this.watermark,
    this.pageOverlayBuilder,
    this.secure = false,
    this.actions = const <Widget>[],
    this.onControllerReady,
    this.onPageChanged,
    this.onLinkTapped,
    this.onBack,
    super.key,
  }) : assert(base64Pdf != null || bytes != null || url != null || filePath != null || asset != null || controller != null, "Provide one PDF source");

  final String? base64Pdf;
  final Uint8List? bytes;
  final String? url;
  final String? filePath;
  final String? asset;
  final UPdfController? controller;

  /// Writes real PDF annotations into the file (ink, shapes, stamps…).
  final UPdfEditController? editController;

  /// Overlay highlights, notes and bookmarks. Created internally when null.
  final UDocAnnotationController? annotations;
  final String password;
  final int initialPage;
  final String? title;
  final bool showToolbar;
  final bool showBottomBar;
  final bool showSidebar;
  final bool showScrollThumb;
  final bool showBackButton;
  final bool allowSelection;

  /// When false the text can still be highlighted but never copied or shared.
  final bool allowCopy;
  final bool allowShare;
  final bool enableMarkup;
  final bool enableAnnotations;

  /// Pen, highlighter, shapes, text boxes and sticky notes drawn over the
  /// pages. They are saved in the annotation string with the highlights.
  final bool enableDrawing;

  /// Tool/style state for drawing. Created internally when null; pass one
  /// with an active tool to open the viewer in drawing mode.
  final UDocDrawController? drawController;
  final List<UDocMarkupKind> markupKinds;

  /// Previously exported annotations (e.g. from a server); the newest of this and the local copy wins.
  final String? annotationData;
  final String? annotationStorageKey;
  final bool persistAnnotations;

  /// Called with [UDocAnnotationController.export] after every change.
  final void Function(String data)? onAnnotationsChanged;
  final UDocNoteDisplay noteDisplay;
  final UDocTextGeometry textGeometry;
  final String? savePath;
  final UDocScrollMode scrollMode;
  final UDocSpread spread;
  final UDocDirection? direction;
  final UDocColorMode colorMode;
  final Map<String, String>? headers;
  final UDocWatermark? watermark;
  final UPdfPageOverlayBuilder? pageOverlayBuilder;

  /// Blocks screenshots and screen recording while the viewer is visible.
  final bool secure;
  final List<Widget> actions;
  final void Function(UPdfController controller)? onControllerReady;
  final void Function(int pageIndex)? onPageChanged;
  final void Function(UDocLink link)? onLinkTapped;
  final VoidCallback? onBack;

  @override
  State<UPdfViewer> createState() => UPdfViewerState();
}

class UPdfViewerState extends State<UPdfViewer> {
  late UPdfController _controller;
  bool _ownsController = false;
  late UDocAnnotationController _markup;
  bool _ownsMarkup = false;
  late UDocDrawController _draw;
  bool _ownsDraw = false;
  bool _drawOpen = false;

  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();
  final Map<int, List<UDocLink>> _links = <int, List<UDocLink>>{};
  final TextEditingController _searchField = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: "UPdfViewer");
  final Set<int> _resolving = <int>{};

  UPdfEditController? _internalEditor;
  PageController? _pageController;
  double _zoom = 1;
  double _baseScale = 1;
  double _gestureScale = 1;
  Offset _gestureFocal = Offset.zero;
  double _pinchStartZoom = 1;
  double _viewportWidth = 0;
  double _viewportHeight = 0;
  int _visiblePage = 0;
  bool _searchOpen = false;
  bool _chromeVisible = true;
  bool _toolsOpen = false;
  bool _saving = false;
  bool _sidebarOpen = false;
  bool _sidebarPinned = true;
  bool _wholeWord = false;
  bool _matchCase = false;
  bool _indicatorVisible = false;
  bool _thumbDragging = false;
  _UPdfSidebarTab _tab = _UPdfSidebarTab.thumbnails;
  UDocSelection _selection = UDocSelection.none;
  int _anchorOffset = -1;
  UDocMarkup? _activeMarkup;
  UPdfAnnotationInfo? _selectedAnnotation;
  Rect? _annotationDraft;
  Timer? _progressTimer;
  Timer? _indicatorTimer;
  List<List<int>> _rows = <List<int>>[];
  List<double> _rowOffsets = <double>[];

  /// Markups whose rects were computed with older text geometry are re-placed from their text.
  static const String geometryKey = "gv";
  static const int geometryVersion = 2;

  static bool _needsPlacement(UDocMarkup markup) => !markup.isPlaced || markup.extra[geometryKey] != geometryVersion;

  UPdfController get controller => _controller;

  UDocAnnotationController get annotations => _markup;

  UPdfEditController? get editor => widget.editController ?? _internalEditor;

  UDocDrawController get drawing => _draw;

  bool get _drawingEnabled => widget.enableDrawing && widget.enableMarkup;

  /// A drawing tool owns single-finger drags (scrolling stays on wheel, trackpad and the scroll thumb).
  bool get _drawActive => _drawingEnabled && _drawOpen && _draw.isActive;

  /// Opens or closes the drawing toolbar.
  void toggleDrawing([bool? open]) {
    final bool next = open ?? !_drawOpen;
    if (next && _toolsOpen) {
      _toolsOpen = false;
      editor?.setTool(UPdfTool.select);
    }
    if (next && !_draw.isActive) _draw.tool = UDocDrawTool.pen;
    if (!next) _draw.tool = UDocDrawTool.none;
    _clearSelection();
    applyState(() {
      _drawOpen = next;
      _activeMarkup = null;
    });
  }

  int get currentPage => _visiblePage;

  void applyState(VoidCallback action) {
    if (mounted) setState(action);
  }

  @override
  void initState() {
    super.initState();
    final UPdfController? provided = widget.controller;
    _controller = provided ?? UPdfController();
    _ownsController = provided == null;
    _controller.addListener(_onControllerChanged);
    _controller.updateSettings(
      _controller.settings.copyWith(
        scrollMode: widget.scrollMode,
        colorMode: widget.colorMode,
        spread: widget.spread,
        textGeometry: widget.textGeometry,
        direction: widget.direction ?? _controller.settings.direction,
      ),
    );
    final UDocAnnotationController? markup = widget.annotations;
    _markup = markup ?? UDocAnnotationController(onChanged: _notifyAnnotations);
    _ownsMarkup = markup == null;
    _markup.addListener(_onMarkupChanged);
    final UDocDrawController? draw = widget.drawController;
    _draw = draw ?? UDocDrawController();
    _ownsDraw = draw == null;
    _draw.addListener(_onControllerChanged);
    _drawOpen = _draw.isActive && _drawingEnabled;
    if (widget.editController == null && widget.enableAnnotations) _internalEditor = UPdfEditController(viewer: _controller);
    _internalEditor?.addListener(_onControllerChanged);
    _vertical.addListener(_onScroll);
    if (_ownsController) {
      unawaited(_open());
    } else {
      _visiblePage = _controller.value.pageIndex;
      unawaited(_prepareAnnotations());
      widget.onControllerReady?.call(_controller);
    }
    _progressTimer = Timer.periodic(const Duration(seconds: 20), (Timer timer) => _controller.saveProgress());
  }

  @override
  void didUpdateWidget(UPdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool sourceChanged =
        oldWidget.url != widget.url || oldWidget.filePath != widget.filePath || oldWidget.asset != widget.asset || oldWidget.bytes != widget.bytes || oldWidget.base64Pdf != widget.base64Pdf;
    if (sourceChanged && _ownsController) {
      _resolving.clear();
      _links.clear();
      _selection = UDocSelection.none;
      unawaited(_open());
    }
    if (oldWidget.textGeometry != widget.textGeometry) _controller.updateSettings(_controller.settings.copyWith(textGeometry: widget.textGeometry));
  }

  void _notifyAnnotations(UDocAnnotationController controller) => widget.onAnnotationsChanged?.call(controller.export());

  Future<void> _open() async {
    await _controller.open(
      path: widget.filePath,
      url: widget.url,
      bytes: widget.bytes ?? widget.base64Pdf?.toBytesFromBase64(),
      asset: widget.asset,
      headers: widget.headers,
      password: widget.password,
    );
    if (!mounted) return;
    if (widget.initialPage > 0) _controller.goToPage(widget.initialPage);
    _visiblePage = _controller.value.pageIndex;
    editor?.attach();
    widget.onControllerReady?.call(_controller);
    if (_controller.value.state == UDocState.error && _controller.value.error?.needsPassword == true) await _askPassword();
    await _prepareAnnotations();
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _jumpToPage(_controller.value.pageIndex, animated: false));
  }

  Future<void> _prepareAnnotations() async {
    if (!_controller.value.isReady) return;
    if (_ownsMarkup && widget.persistAnnotations) await _markup.attachStorage(widget.annotationStorageKey ?? "u_doc_markup_${_controller.documentId}");
    final String? remote = widget.annotationData;
    if (remote != null && remote.trim().isNotEmpty) {
      final String local = _markup.isEmpty ? "" : _markup.export();
      final String newest = UDocAnnotationController.pickNewest(local, remote);
      if (newest != local) _markup.import(newest);
    }
  }

  Future<void> _askPassword() async {
    final TextEditingController field = TextEditingController();
    final String? password = await UNavigator.dialog<String>(
      AlertDialog(
        title: UTextTitleMedium(U.s.documentPassword),
        content: TextField(
          controller: field,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(hintText: U.s.enterThePasswordToOpenThisDocument),
          onSubmitted: UNavigator.back<String>,
        ),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back<String>, child: UTextBodyMedium(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back<String>(field.text), child: UTextBodyMedium(U.s.open)),
        ],
      ),
    );
    field.dispose();
    if (password == null || password.isEmpty) return;
    await _controller.open(
      path: widget.filePath,
      url: widget.url,
      bytes: widget.bytes ?? widget.base64Pdf?.toBytesFromBase64(),
      asset: widget.asset,
      headers: widget.headers,
      password: password,
    );
    await _prepareAnnotations();
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onMarkupChanged() {
    if (!mounted) return;
    final UDocMarkup? active = _activeMarkup;
    if (active != null && _markup.byId(active.id) == null) _activeMarkup = null;
    setState(() {});
  }

  // ───────────────────────── layout ─────────────────────────

  double _totalWidth = 0;

  bool get _wide => _totalWidth >= 900;

  double get _sidebarWidth => 300;

  double get _scale => _baseScale * _zoom;

  UDocSpread get _effectiveSpread {
    final UDocViewSettings settings = _controller.settings;
    if (settings.isHorizontal) return UDocSpread.none;
    if (settings.spread == UDocSpread.auto) return _viewportWidth > _viewportHeight * 1.15 && _viewportWidth > 900 ? UDocSpread.coverFirst : UDocSpread.none;
    return settings.spread;
  }

  void _ensureRows() {
    final int count = _controller.pageCount;
    final UDocSpread spread = _effectiveSpread;
    final List<List<int>> rows = <List<int>>[];
    if (spread == UDocSpread.none) {
      for (int i = 0; i < count; i++) {
        rows.add(<int>[i]);
      }
    } else {
      int i = 0;
      if (spread == UDocSpread.coverFirst && count > 0) {
        rows.add(<int>[0]);
        i = 1;
      }
      while (i < count) {
        rows.add(i + 1 < count ? <int>[i, i + 1] : <int>[i]);
        i += 2;
      }
    }
    _rows = rows;
  }

  int _rowOf(int pageIndex) {
    for (int i = 0; i < _rows.length; i++) {
      if (_rows[i].contains(pageIndex)) return i;
    }
    return 0;
  }

  Size _rowSize(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= _rows.length) return const Size(612, 792);
    double width = 0;
    double height = 0;
    final List<int> row = _rows[rowIndex];
    for (final int page in row) {
      final Size size = _controller.pageInfo(page).rotatedSize;
      width += size.width;
      if (size.height > height) height = size.height;
    }
    return Size(width + (row.length - 1) * _controller.settings.pageGap / max(_scale, 0.01), height);
  }

  double _rowExtent(int rowIndex) {
    final Size size = _rowSize(rowIndex);
    final bool horizontal = _controller.settings.isHorizontal;
    return (horizontal ? size.width : size.height) * _scale + _controller.settings.pageGap;
  }

  void _ensureOffsets() {
    final List<double> offsets = List<double>.filled(_rows.length + 1, 0);
    for (int i = 0; i < _rows.length; i++) {
      offsets[i + 1] = offsets[i] + _rowExtent(i);
    }
    _rowOffsets = offsets;
  }

  int _rowAtOffset(double offset) {
    if (_rows.isEmpty) return 0;
    int low = 0;
    int high = _rows.length - 1;
    while (low < high) {
      final int mid = (low + high + 1) >> 1;
      if (_rowOffsets[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  void _computeBaseScale() {
    if (_controller.pageCount == 0 || _viewportWidth <= 0) return;
    final Size size = _rowSize(_rowOf(_visiblePage));
    if (size.width <= 0 || size.height <= 0) return;
    const double padding = 16;
    switch (_controller.settings.fit) {
      case UDocFit.width:
        _baseScale = (_viewportWidth - padding) / size.width;
        break;
      case UDocFit.page:
        _baseScale = min((_viewportWidth - padding) / size.width, (_viewportHeight - padding) / size.height);
        break;
      case UDocFit.height:
        _baseScale = (_viewportHeight - padding) / size.height;
        break;
      case UDocFit.actual:
        _baseScale = 1;
        break;
      case UDocFit.visible:
      case UDocFit.custom:
        if (_baseScale <= 0) _baseScale = (_viewportWidth - padding) / size.width;
        break;
    }
    if (_baseScale <= 0 || !_baseScale.isFinite) _baseScale = 1;
  }

  // ───────────────────────── navigation ─────────────────────────

  void _onScroll() {
    if (!_vertical.hasClients || _controller.pageCount == 0 || _rowOffsets.isEmpty) return;
    final bool horizontal = _controller.settings.isHorizontal;
    final int row = _rowAtOffset(_vertical.offset - (horizontal ? 0 : _topPad) + (horizontal ? _viewportWidth : _viewportHeight) / 3);
    final int page = _rows.isEmpty ? 0 : _rows[row.clamp(0, _rows.length - 1)].first;
    _showIndicator();
    if (page != _visiblePage) {
      _visiblePage = page;
      _controller.goToPage(page);
      widget.onPageChanged?.call(page);
    }
  }

  void _showIndicator() {
    if (!_indicatorVisible) setState(() => _indicatorVisible = true);
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && !_thumbDragging) setState(() => _indicatorVisible = false);
    });
  }

  /// Scrolls to [pageIndex]; [pageY] is an optional offset inside the page in page units.
  void jumpToPage(int pageIndex, {bool animated = true, double? pageY}) => _jumpToPage(pageIndex, animated: animated, pageY: pageY);

  void _jumpToPage(int index, {bool animated = true, double? pageY}) {
    if (!mounted) return;
    if (_controller.pageCount == 0) return;
    final int target = index.clamp(0, _controller.pageCount - 1);
    if (_controller.settings.isPaged) {
      final int row = _rowOf(target);
      if (_pageController?.hasClients == true) {
        if (animated) {
          unawaited(_pageController!.animateToPage(row, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic));
        } else {
          _pageController!.jumpToPage(row);
        }
      }
      _setVisible(target);
      return;
    }
    if (!_vertical.hasClients || _rowOffsets.isEmpty) {
      _setVisible(target);
      return;
    }
    final int row = _rowOf(target);
    double offset = _rowOffsets[row.clamp(0, _rowOffsets.length - 1)];
    if (pageY != null && !_controller.settings.isHorizontal) offset += max(0, pageY * _scale - _viewportHeight * 0.3);
    final double clamped = offset.clamp(0, _vertical.position.maxScrollExtent).toDouble();
    if (animated && (clamped - _vertical.offset).abs() < _viewportHeight * 6) {
      unawaited(_vertical.animateTo(clamped, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic));
    } else {
      _vertical.jumpTo(clamped);
    }
    _setVisible(target);
  }

  void _setVisible(int page) {
    if (page == _visiblePage) return;
    _visiblePage = page;
    _controller.goToPage(page);
    widget.onPageChanged?.call(page);
  }

  void _jumpToRect(int pageIndex, Rect? normalized) {
    final Size size = _controller.pageInfo(pageIndex).rotatedSize;
    _jumpToPage(pageIndex, pageY: normalized == null ? null : normalized.top * size.height);
  }

  void _jumpToDestination(UDocDestination destination) {
    final UDocPageInfo info = _controller.pageInfo(destination.pageIndex);
    final double? top = destination.top;
    if (top == null) {
      _jumpToPage(destination.pageIndex);
      return;
    }
    final Offset device = _pdfPointToDevice(Offset(destination.left ?? 0, top), info);
    _jumpToPage(destination.pageIndex, pageY: device.dy);
  }

  void nextPage() => _jumpToPage(_controller.settings.isPaged ? (_rows.isEmpty ? _visiblePage + 1 : (_rows[min(_rowOf(_visiblePage) + 1, _rows.length - 1)].first)) : _visiblePage + 1);

  void previousPage() => _jumpToPage(_controller.settings.isPaged ? (_rows.isEmpty ? _visiblePage - 1 : (_rows[max(_rowOf(_visiblePage) - 1, 0)].first)) : _visiblePage - 1);

  void setZoom(double zoom) => _setZoom(zoom);

  void _setZoom(double next, {Offset? focal}) {
    if (!mounted) return;
    final UDocViewSettings settings = _controller.settings;
    final double clamped = next.clamp(settings.minZoom, settings.maxZoom).toDouble();
    if ((clamped - _zoom).abs() < 0.001) return;
    final double previous = _zoom;
    setState(() {
      _zoom = clamped;
      _controller.updateSettings(settings.copyWith(zoom: clamped));
    });
    final double ratio = clamped / previous;
    final Offset anchor = focal ?? Offset(_viewportWidth / 2, _viewportHeight / 2);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (_vertical.hasClients) {
        final bool horizontal = _controller.settings.isHorizontal;
        final double along = horizontal ? anchor.dx : anchor.dy;
        _vertical.jumpTo(((_vertical.offset + along) * ratio - along).clamp(0, _vertical.position.maxScrollExtent).toDouble());
      }
      if (_horizontal.hasClients) {
        _horizontal.jumpTo(((_horizontal.offset + anchor.dx) * ratio - anchor.dx).clamp(0, _horizontal.position.maxScrollExtent).toDouble());
      }
    });
  }

  void _setFit(UDocFit fit) {
    if (!mounted) return;
    setState(() {
      _zoom = 1;
      _controller.updateSettings(_controller.settings.copyWith(fit: fit, zoom: 1));
    });
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _jumpToPage(_visiblePage, animated: false));
  }

  // ───────────────────────── geometry helpers ─────────────────────────

  Rect _pdfRectToDevice(Rect rect, UDocPageInfo info) {
    final Rect box = info.cropBox ?? Rect.fromLTWH(0, 0, info.size.width, info.size.height);
    final List<double> matrix = uPdfBaseMatrix(box, info.rotation, 1);
    final Offset a = uPdfApply(matrix, rect.left, rect.top);
    final Offset b = uPdfApply(matrix, rect.right, rect.bottom);
    return Rect.fromLTRB(min(a.dx, b.dx), min(a.dy, b.dy), max(a.dx, b.dx), max(a.dy, b.dy));
  }

  Offset _pdfPointToDevice(Offset point, UDocPageInfo info) {
    final Rect box = info.cropBox ?? Rect.fromLTWH(0, 0, info.size.width, info.size.height);
    return uPdfApply(uPdfBaseMatrix(box, info.rotation, 1), point.dx, point.dy);
  }

  Size _pageSize(int pageIndex) => _controller.pageInfo(pageIndex).rotatedSize;

  Rect _normalize(Rect rect, Size size) =>
      size.width <= 0 || size.height <= 0 ? Rect.zero : Rect.fromLTRB(rect.left / size.width, rect.top / size.height, rect.right / size.width, rect.bottom / size.height);

  UDocTextGeometry get _geometry => _controller.settings.textGeometry;

  // ───────────────────────── taps, selection & markup ─────────────────────────

  Future<List<UDocLink>> _linksFor(int index) async {
    final List<UDocLink>? cached = _links[index];
    if (cached != null) return cached;
    final List<UDocLink> links = await _controller.links(index);
    _links[index] = links;
    return links;
  }

  UDocMarkup? _markupAt(int pageIndex, Offset pagePoint) {
    final Size size = _pageSize(pageIndex);
    if (size.width <= 0 || size.height <= 0) return null;
    final Offset normalized = Offset(pagePoint.dx / size.width, pagePoint.dy / size.height);
    final double slop = 14 / (_scale * size.width);
    final List<UDocMarkup> markups = _markup.markupsOn(pageIndex);
    for (int i = markups.length - 1; i >= 0; i--) {
      final UDocMarkup markup = markups[i];
      if (markup.hitTest(normalized, slop: slop)) return markup;
      final Rect? bounds = markup.bounds;
      if (bounds != null && (markup.hasNote || markup.kind == UDocMarkupKind.note)) {
        final Rect badge = Rect.fromCenter(center: Offset(bounds.right, bounds.top), width: slop * 4, height: slop * 4 * size.width / size.height);
        if (badge.contains(normalized)) return markup;
      }
    }
    return null;
  }

  Future<void> _handleTap(int pageIndex, Offset pagePoint, {bool mouse = false}) async {
    _focus.requestFocus();
    final List<UDocLink> links = await _linksFor(pageIndex);
    final UDocPageInfo info = _controller.pageInfo(pageIndex);
    for (final UDocLink link in links) {
      if (!_pdfRectToDevice(link.rect, info).contains(pagePoint)) continue;
      widget.onLinkTapped?.call(link);
      final String? uri = link.uri;
      if (uri != null) {
        await ULaunch.url(uri);
      } else if (link.destination != null) {
        _jumpToDestination(link.destination!);
      }
      return;
    }
    if (_selection.isNotEmpty) {
      if (mouse && HardwareKeyboard.instance.isShiftPressed && _selection.pageIndex == pageIndex) {
        await _extendSelection(pageIndex, pagePoint);
        return;
      }
      _clearSelection();
      return;
    }
    final UDocMarkup? hit = widget.enableMarkup ? _markupAt(pageIndex, pagePoint) : null;
    if (hit != null) {
      setState(() => _activeMarkup = _activeMarkup?.id == hit.id ? null : hit);
      return;
    }
    if (_activeMarkup != null) {
      setState(() => _activeMarkup = null);
      return;
    }
    final UPdfEditController? target = editor;
    if (target != null && target.tool == UPdfTool.select && (_toolsOpen || widget.editController != null)) {
      final UPdfAnnotationInfo? annotation = await target.annotationAt(pageIndex, pagePoint);
      if (annotation != null || _selectedAnnotation != null) {
        setState(() {
          _selectedAnnotation = annotation;
          _annotationDraft = null;
        });
        return;
      }
    }
    if (!mouse) setState(() => _chromeVisible = !_chromeVisible);
  }

  void _clearSelection() {
    _anchorOffset = -1;
    setState(() => _selection = UDocSelection.none);
    _controller.clearSelection();
  }

  void _setSelection(int pageIndex, UDocTextPage text, int start, int end) {
    final int from = min(start, end).clamp(0, text.text.length);
    final int to = max(start, end).clamp(0, text.text.length);
    if (to <= from) return;
    final UDocSelection selection = UDocSelection(
      pageIndex: pageIndex,
      start: from,
      end: to,
      text: text.textFor(from, to),
      rects: text.rectsForRange(from, to, geometry: _geometry),
    );
    setState(() {
      _selection = selection;
      _activeMarkup = null;
    });
    _controller.setSelection(selection);
  }

  Future<void> _selectWordAt(int pageIndex, Offset pagePoint) async {
    if (!widget.allowSelection) return;
    final UDocTextPage text = await _controller.textPage(pageIndex);
    final int? offset = text.offsetAt(pagePoint);
    if (offset == null || !mounted) return;
    final (int, int)? word = text.wordAround(offset);
    if (word == null) return;
    _anchorOffset = word.$1;
    _setSelection(pageIndex, text, word.$1, word.$2);
  }

  Future<void> _selectLineAt(int pageIndex, Offset pagePoint) async {
    if (!widget.allowSelection) return;
    final UDocTextPage text = await _controller.textPage(pageIndex);
    final int? offset = text.offsetAt(pagePoint);
    if (offset == null || !mounted) return;
    final (int, int)? line = text.lineAround(offset);
    if (line == null) return;
    _anchorOffset = line.$1;
    _setSelection(pageIndex, text, line.$1, line.$2);
  }

  Future<void> _beginDragSelection(int pageIndex, Offset pagePoint) async {
    if (!widget.allowSelection) return;
    final UDocTextPage text = await _controller.textPage(pageIndex);
    final int? offset = text.offsetAt(pagePoint);
    if (offset == null || !mounted) return;
    _anchorOffset = offset;
    setState(() {
      _selection = UDocSelection(pageIndex: pageIndex, start: offset, end: offset, text: "");
      _activeMarkup = null;
    });
  }

  Future<void> _extendSelection(int pageIndex, Offset pagePoint) async {
    if (_selection.pageIndex != pageIndex || _anchorOffset < 0) return;
    final UDocTextPage text = await _controller.textPage(pageIndex);
    final int? offset = text.offsetAt(pagePoint, maxDistance: 400);
    if (offset == null || !mounted) return;
    final int end = offset >= _anchorOffset ? offset + 1 : offset;
    _setSelection(pageIndex, text, _anchorOffset, end);
  }

  Future<void> _adjustSelection(int pageIndex, bool isStart, Offset pagePoint) async {
    if (_selection.isEmpty || _selection.pageIndex != pageIndex) return;
    final UDocTextPage text = await _controller.textPage(pageIndex);
    final int? offset = text.offsetAt(pagePoint, maxDistance: 400);
    if (offset == null || !mounted) return;
    final int start = isStart ? offset : _selection.start;
    final int end = isStart ? _selection.end : offset + 1;
    _anchorOffset = isStart ? _selection.end : _selection.start;
    _setSelection(pageIndex, text, start, end);
  }

  Future<void> _copySelection() async {
    if (_selection.isEmpty || !widget.allowCopy) return;
    await UClipboard.set(_selection.text);
    if (!mounted) return;
    UToast.toast(message: U.s.copied);
    _clearSelection();
  }

  Future<void> _applyMarkup(UDocMarkupKind kind) async {
    final UDocSelection selection = _selection;
    if (selection.isEmpty) return;
    String note = "";
    if (kind == UDocMarkupKind.note) {
      final String? value = await UDocNoteEditor.show(quote: selection.text);
      if (value == null) return;
      note = value;
    }
    final Size size = _pageSize(selection.pageIndex);
    _markup.kind = kind;
    _markup.add(
      UDocMarkup.create(
        kind: kind,
        pageIndex: selection.pageIndex,
        color: _markup.color,
        start: selection.start,
        end: selection.end,
        text: selection.text,
        rects: selection.rects.map((Rect rect) => _normalize(rect, size)).toList(),
        note: note,
        extra: const <String, Object?>{UPdfViewerState.geometryKey: UPdfViewerState.geometryVersion},
      ),
    );
    if (mounted) _clearSelection();
  }

  /// Places markups that only carry text offsets (imported/legacy data) once the page text is known.
  Future<void> _resolvePage(int pageIndex) async {
    if (_resolving.contains(pageIndex)) return;
    _resolving.add(pageIndex);
    final List<UDocMarkup> pending = _markup.markupsOn(pageIndex).where(_needsPlacement).toList();
    if (pending.isEmpty) return;
    final UDocTextPage text = await _controller.textPage(pageIndex);
    if (!mounted || text.isEmpty) return;
    final Size size = text.size.isEmpty ? _pageSize(pageIndex) : text.size;
    for (final UDocMarkup markup in pending) {
      (int, int)? range;
      final bool offsetsMatch = markup.end > markup.start && markup.end <= text.text.length && UDocText.forSearch(text.textFor(markup.start, markup.end)) == UDocText.forSearch(markup.text);
      if (offsetsMatch) range = (markup.start, markup.end);
      range ??= text.locate(markup.text, near: markup.start);
      if (range == null && markup.text.trim().isEmpty && markup.end > markup.start && markup.end <= text.text.length) range = (markup.start, markup.end);
      if (range == null) continue;
      final List<Rect> rects = text.rectsForRange(range.$1, range.$2, geometry: _geometry).map((Rect rect) => _normalize(rect, size)).toList();
      if (rects.isNotEmpty) _markup.resolvePlacement(markup.id, rects, start: range.$1, end: range.$2, extra: const <String, Object?>{geometryKey: geometryVersion});
    }
  }

  // ───────────────────────── PDF-embedded annotation editing ─────────────────────────

  Widget _annotationOverlay(UPdfAnnotationInfo annotation, UDocPageInfo info, double scale) {
    final Rect device = _annotationDraft ?? _pdfRectToDevice(annotation.rect, info);
    final Rect box = Rect.fromLTWH(device.left * scale, device.top * scale, device.width * scale, device.height * scale);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Stack(
      children: <Widget>[
        Positioned.fromRect(
          rect: box,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (DragUpdateDetails details) {
              final Rect current = _annotationDraft ?? _pdfRectToDevice(annotation.rect, info);
              setState(() => _annotationDraft = current.shift(Offset(details.delta.dx / scale, details.delta.dy / scale)));
            },
            onPanEnd: (DragEndDetails details) => unawaited(_commitAnnotationRect(annotation, info)),
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: scheme.primary, width: 2)),
            ),
          ),
        ),
        Positioned(
          left: box.right - 14,
          top: box.bottom - 14,
          width: 28,
          height: 28,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (DragUpdateDetails details) {
              final Rect current = _annotationDraft ?? _pdfRectToDevice(annotation.rect, info);
              final double width = (current.width + details.delta.dx / scale).clamp(8, 4000).toDouble();
              final double height = (current.height + details.delta.dy / scale).clamp(8, 4000).toDouble();
              setState(() => _annotationDraft = Rect.fromLTWH(current.left, current.top, width, height));
            },
            onPanEnd: (DragEndDetails details) => unawaited(_commitAnnotationRect(annotation, info)),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: box.left,
          top: box.top - 44 < 0 ? box.bottom + 6 : box.top - 44,
          child: Material(
            color: scheme.inverseSurface,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  iconSize: 18,
                  icon: Icon(Icons.palette_outlined, color: scheme.onInverseSurface),
                  onPressed: () => unawaited(_recolourAnnotation(annotation)),
                ),
                IconButton(
                  iconSize: 18,
                  icon: Icon(Icons.edit_note_rounded, color: scheme.onInverseSurface),
                  onPressed: () => unawaited(_editAnnotationNote(annotation)),
                ),
                IconButton(
                  iconSize: 18,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.onInverseSurface),
                  onPressed: () => unawaited(_deleteSelectedAnnotation(annotation)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _commitAnnotationRect(UPdfAnnotationInfo annotation, UDocPageInfo info) async {
    final Rect? draft = _annotationDraft;
    final UPdfEditController? target = editor;
    if (draft == null || target == null) return;
    await target.updateAnnotation(annotation.pageIndex, annotation.objectNumber, rect: target.deviceRectToPdf(info, draft));
    if (!mounted) return;
    setState(() {
      _annotationDraft = null;
      _selectedAnnotation = null;
    });
  }

  Future<void> _recolourAnnotation(UPdfAnnotationInfo annotation) async {
    final Color? picked = await UNavigator.colorPicker(defaultColor: annotation.color ?? UDocPalette.colors.first, colors: UDocPalette.colors);
    if (picked == null) return;
    await editor?.updateAnnotation(annotation.pageIndex, annotation.objectNumber, color: picked);
    if (mounted) setState(() => _selectedAnnotation = null);
  }

  Future<void> _editAnnotationNote(UPdfAnnotationInfo annotation) async {
    final String? value = await UDocNoteEditor.show(initial: annotation.contents);
    if (value == null) return;
    await editor?.updateAnnotation(annotation.pageIndex, annotation.objectNumber, contents: value);
    if (mounted) setState(() => _selectedAnnotation = null);
  }

  Future<void> _deleteSelectedAnnotation(UPdfAnnotationInfo annotation) async {
    await editor?.deleteAnnotation(annotation.pageIndex, annotation.objectNumber);
    if (mounted) setState(() => _selectedAnnotation = null);
  }

  Future<void> _applyPdfMarkup() async {
    final UPdfEditController? target = editor;
    if (target == null || _selection.isEmpty) return;
    final UDocTextPage text = await _controller.textPage(_selection.pageIndex);
    await target.annotateSelection(_selection, text);
    if (mounted) _clearSelection();
  }

  Future<void> _askAnnotationText(UPdfEditController editor, int pageIndex, Offset point, {required bool freeText}) async {
    final String? value = await UDocNoteEditor.show();
    if (value == null || value.trim().isEmpty) return;
    if (freeText) {
      await editor.addTextBox(pageIndex, point, value);
    } else {
      await editor.addNote(pageIndex, point, value);
    }
    if (mounted) setState(() {});
  }

  // ───────────────────────── keyboard & pointer ─────────────────────────

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (UDocDrawController.isTyping) return KeyEventResult.ignored;
    final bool command = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final bool shift = HardwareKeyboard.instance.isShiftPressed;
    final LogicalKeyboardKey key = event.logicalKey;
    if (command && key == LogicalKeyboardKey.keyC) {
      unawaited(_copySelection());
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyF) {
      _openSearch();
      return KeyEventResult.handled;
    }
    if (command && (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd)) {
      _setZoom(_zoom * 1.2);
      return KeyEventResult.handled;
    }
    if (command && (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract)) {
      _setZoom(_zoom / 1.2);
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.digit0) {
      _setFit(UDocFit.width);
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyZ && widget.enableMarkup) {
      if (shift) {
        _markup.redo();
      } else {
        _markup.undo();
      }
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyB && widget.enableMarkup) {
      _toggleBookmark();
      return KeyEventResult.handled;
    }
    if (_drawActive && _draw.selectedId != null && (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace)) {
      _markup.removeShape(_draw.selectedId!);
      _draw.selectedId = null;
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyD && _drawActive && _draw.selectedId != null) {
      final UDocShape? copy = _markup.duplicateShape(_draw.selectedId!);
      if (copy != null) _draw.selectedId = copy.id;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_drawOpen) {
        if (_draw.selectedId != null) {
          _draw.selectedId = null;
        } else {
          toggleDrawing(false);
        }
        return KeyEventResult.handled;
      }
      if (_selection.isNotEmpty || _activeMarkup != null) {
        _clearSelection();
        setState(() => _activeMarkup = null);
        return KeyEventResult.handled;
      }
      if (_searchOpen) {
        _toggleSearch();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.pageDown || (key == LogicalKeyboardKey.arrowRight && !command) || (key == LogicalKeyboardKey.space && !shift)) {
      if (!_controller.settings.isPaged && key == LogicalKeyboardKey.space && _vertical.hasClients) {
        unawaited(
          _vertical.animateTo((_vertical.offset + _viewportHeight * 0.85).clamp(0, _vertical.position.maxScrollExtent).toDouble(), duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
        );
      } else {
        _controller.settings.isRtl && key == LogicalKeyboardKey.arrowRight ? previousPage() : nextPage();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp || (key == LogicalKeyboardKey.arrowLeft && !command) || (key == LogicalKeyboardKey.space && shift)) {
      if (!_controller.settings.isPaged && key == LogicalKeyboardKey.space && _vertical.hasClients) {
        unawaited(
          _vertical.animateTo((_vertical.offset - _viewportHeight * 0.85).clamp(0, _vertical.position.maxScrollExtent).toDouble(), duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
        );
      } else {
        _controller.settings.isRtl && key == LogicalKeyboardKey.arrowLeft ? nextPage() : previousPage();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _jumpToPage(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _jumpToPage(_controller.pageCount - 1);
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) && !_controller.settings.isPaged && _vertical.hasClients) {
      final double delta = key == LogicalKeyboardKey.arrowDown ? 60 : -60;
      _vertical.jumpTo((_vertical.offset + delta).clamp(0, _vertical.position.maxScrollExtent).toDouble());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final bool command = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    if (!command) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent resolved) {
      final double delta = (resolved as PointerScrollEvent).scrollDelta.dy;
      _setZoom(delta < 0 ? _zoom * 1.1 : _zoom / 1.1, focal: resolved.localPosition);
    });
  }

  void _beginVisualZoom(Offset focal) {
    _pinchStartZoom = _zoom;
    _gestureFocal = focal;
  }

  void _updateVisualZoom(double scale, Offset focal) {
    final UDocViewSettings settings = _controller.settings;
    final double target = (_pinchStartZoom * scale).clamp(settings.minZoom, settings.maxZoom).toDouble();
    setState(() {
      _gestureScale = target / _zoom;
      _gestureFocal = focal;
    });
  }

  void _endVisualZoom() {
    final double target = _zoom * _gestureScale;
    final Offset focal = _gestureFocal;
    setState(() => _gestureScale = 1);
    if ((target - _zoom).abs() > 0.001) _setZoom(target, focal: focal);
  }

  // ───────────────────────── actions ─────────────────────────

  void _toggleBookmark() {
    if (!widget.enableMarkup) return;
    final bool existed = _markup.isBookmarked(_visiblePage);
    _markup.toggleBookmark(_visiblePage, title: _outlineTitleFor(_visiblePage));
    UToast.toast(message: existed ? U.s.removeBookmark : U.s.bookmarkPage);
  }

  String _outlineTitleFor(int pageIndex) {
    String title = "";
    void walk(List<UDocOutlineNode> nodes) {
      for (final UDocOutlineNode node in nodes) {
        final int? target = node.destination?.pageIndex;
        if (target != null && target <= pageIndex) title = node.title;
        if (node.hasChildren) walk(node.children);
      }
    }

    walk(_controller.outline);
    return title;
  }

  void _openSearch() {
    if (widget.showSidebar) {
      _openSidebar(_UPdfSidebarTab.search);
    } else {
      setState(() => _searchOpen = true);
    }
  }

  void _openSidebar(_UPdfSidebarTab tab) {
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

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchField.clear();
      _controller.clearSearch();
    }
  }

  Future<void> _runSearch(String query) async {
    final List<UDocSearchHit> hits = await _controller.search(
      query,
      options: UDocSearchOptions(caseSensitive: _matchCase, wholeWord: _wholeWord, normalizePersian: !_matchCase),
    );
    if (!mounted || hits.isEmpty) return;
    _goToHit(0);
  }

  void _goToHit(int index) {
    final List<UDocSearchHit> hits = _controller.value.searchHits;
    if (index < 0 || index >= hits.length) return;
    final UDocSearchHit hit = hits[index];
    _controller.emit(_controller.value.copyWith(searchHitIndex: index, pageIndex: hit.pageIndex));
    _jumpToPage(hit.pageIndex, pageY: hit.rects.isEmpty ? null : hit.bounds.top);
  }

  Future<void> _saveDocument(UPdfEditController target) async {
    final String? path = widget.savePath ?? widget.filePath;
    setState(() => _saving = true);
    bool saved = false;
    if (path != null) {
      saved = await target.saveTo(path);
    } else {
      final Uint8List? bytes = await target.saveToBytes();
      if (bytes != null) {
        await UShare.bytes(bytes: bytes, fileName: "document.pdf", mimeType: "application/pdf");
        saved = true;
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      UToast.successToast(message: U.s.saved);
    } else {
      UToast.errorToast(message: U.s.couldNotOpenTheDocument);
    }
  }

  Future<void> _askPageNumber() async {
    final TextEditingController field = TextEditingController(text: "${_visiblePage + 1}");
    final String? result = await UNavigator.dialog<String>(
      AlertDialog(
        title: UTextTitleMedium(U.s.goToPage),
        content: TextField(
          controller: field,
          keyboardType: TextInputType.number,
          autofocus: true,
          onSubmitted: UNavigator.back<String>,
          decoration: InputDecoration(suffixText: "/ ${_controller.pageCount}", border: const OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back<String>, child: UTextBodyMedium(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back<String>(field.text), child: UTextBodyMedium(U.s.goToPage)),
        ],
      ),
    );
    field.dispose();
    final int? page = int.tryParse((result ?? "").toLatinNumber().trim());
    if (page != null) _jumpToPage(page - 1);
  }

  Future<void> _onMenu(String action) async {
    switch (action) {
      case "annotations":
        _openSidebar(_UPdfSidebarTab.annotations);
        break;
      case "bookmarks":
        _openSidebar(_UPdfSidebarTab.bookmarks);
        break;
      case "exportNotes":
        await UShare.text(text: _markup.toMarkdown(title: _title));
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
      case "clearDrawings":
        final int page = _visiblePage;
        final bool clear = await UNavigator.confirmAsync(title: U.s.clearDrawings, message: U.s.clearDrawingsConfirm, destructive: true);
        if (clear) _markup.clearShapes(pageIndex: page);
        break;
      case "clearAll":
        final bool confirmed = await UNavigator.confirmAsync(title: U.s.clearAnnotations, message: U.s.areYouSureYouWantToDeleteThisItem(U.s.annotations), destructive: true);
        if (confirmed) _markup.clear();
        break;
      case "pdfAnnotations":
        final UPdfEditController? target = editor;
        if (target == null) return;
        await UNavigator.bottomSheet<void>(
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: UPdfAnnotationsPanel(editor: target, onJump: _jumpToPage),
          ),
        );
        break;
      case "pages":
        final UPdfEditController? target = editor;
        if (target == null) return;
        await UNavigator.bottomSheet<void>(
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: UPdfPageManagerPanel(viewer: _controller, editor: target, onJump: _jumpToPage),
          ),
        );
        break;
      case "tools":
        final UPdfEditController? target = editor;
        if (target == null) return;
        await UNavigator.bottomSheet<void>(
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: UPdfDocumentToolsPanel(viewer: _controller, editor: target),
          ),
        );
        break;
      case "info":
        await _openSettings();
        break;
    }
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    await UNavigator.bottomSheet<void>(
      UPdfSettingsPanel(
        controller: _controller,
        onChanged: () {
          if (mounted) setState(() {});
        },
        onFit: _setFit,
      ),
    );
  }

  String get _title {
    final String custom = widget.title ?? "";
    if (custom.isNotEmpty) return custom;
    final String meta = _controller.value.metadata.displayTitle;
    return meta.isEmpty ? "${U.s.page} ${_visiblePage + 1}" : meta;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _indicatorTimer?.cancel();
    _internalEditor?.removeListener(_onControllerChanged);
    _internalEditor?.dispose();
    _controller.removeListener(_onControllerChanged);
    _markup.removeListener(_onMarkupChanged);
    if (_ownsMarkup) _markup.dispose();
    _draw.removeListener(_onControllerChanged);
    if (_ownsDraw) _draw.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    _pageController?.dispose();
    _searchField.dispose();
    _focus.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final UDocValue value = _controller.value;
    final UDocViewSettings settings = _controller.settings;
    return USecureArea(
      enabled: widget.secure,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: ColoredBox(
          color: UDocColorFilters.surfaceBackground(settings.colorMode),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              _totalWidth = constraints.maxWidth;
              final bool pinned = widget.showSidebar && _wide && _sidebarPinned && value.isReady;
              final Widget main = _buildMain(value, settings);
              return Row(
                children: <Widget>[
                  if (pinned)
                    SizedBox(
                      width: _sidebarWidth,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BorderDirectional(end: BorderSide(color: Theme.of(context).dividerColor)),
                        child: SafeArea(right: false, child: _buildSidebar(value)),
                      ),
                    ),
                  Expanded(child: main),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMain(UDocValue value, UDocViewSettings settings) {
    final bool overlaySidebar = widget.showSidebar && !_wide && _sidebarOpen && value.isReady;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _buildBody(value, settings)),
        if (settings.dim > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: settings.dim)),
            ),
          ),
        if (widget.showScrollThumb && value.isReady && !settings.isPaged && !settings.isHorizontal) _buildScrollThumb(value),
        if (value.isReady && _indicatorVisible) _buildPageIndicator(value),
        if (widget.showToolbar && _chromeVisible) Positioned(left: 0, right: 0, top: 0, child: _buildToolbar(value)),
        if (widget.showBottomBar && _chromeVisible && value.isReady) Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar(value)),
        if (_selection.isNotEmpty) _buildSelectionMenu(),
        if (_activeMarkup != null && _selection.isEmpty) _buildMarkupMenu(_activeMarkup!),
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
            width: min(_sidebarWidth + 40, _viewportWidth * 0.88),
            child: Material(elevation: 8, child: SafeArea(right: false, child: _buildSidebar(value))),
          ),
        ],
      ],
    );
  }

  double get _toolbarInset => widget.showToolbar && _chromeVisible ? 56 + MediaQuery.paddingOf(context).top + (_searchOpen ? 52 : 0) + (_toolsOpen && editor != null ? 52 : 0) + (_drawOpen ? 52 : 0) : 0;

  double get _bottomInset => widget.showBottomBar && _chromeVisible ? 60 + MediaQuery.paddingOf(context).bottom : 0;

  /// Fixed list padding so showing/hiding the chrome never shifts the pages.
  double get _topPad => widget.showToolbar ? 56 + MediaQuery.paddingOf(context).top : 0;

  double get _bottomPad => widget.showBottomBar ? 60 + MediaQuery.paddingOf(context).bottom : 0;

  Widget _buildBody(UDocValue value, UDocViewSettings settings) {
    if (value.state == UDocState.opening || value.state == UDocState.idle) return const Center(child: CircularProgressIndicator());
    if (value.hasError) return _buildError(value);
    if (value.pageCount == 0) return Center(child: UTextBodyMedium(U.s.noResults));
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _viewportWidth = constraints.maxWidth;
        _viewportHeight = constraints.maxHeight;
        _ensureRows();
        _computeBaseScale();
        _ensureOffsets();
        Widget content = settings.isPaged ? _buildPaged(settings) : _buildContinuous(settings);
        if (_drawActive) {
          content = ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: const <PointerDeviceKind>{PointerDeviceKind.trackpad}),
            child: content,
          );
        }
        final Widget scaled = _gestureScale == 1
            ? content
            : Transform.scale(
                scale: _gestureScale,
                alignment: Alignment.topLeft,
                origin: _gestureFocal,
                child: content,
              );
        return Listener(
          onPointerSignal: _onPointerSignal,
          onPointerPanZoomStart: (PointerPanZoomStartEvent event) => _beginVisualZoom(event.localPosition),
          onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
            if ((event.scale - 1).abs() > 0.01) _updateVisualZoom(event.scale, event.localPosition);
          },
          onPointerPanZoomEnd: (PointerPanZoomEndEvent event) => _endVisualZoom(),
          child: GestureDetector(
            supportedDevices: _drawActive ? const <PointerDeviceKind>{} : const <PointerDeviceKind>{PointerDeviceKind.touch, PointerDeviceKind.stylus},
            onScaleStart: (ScaleStartDetails details) => _beginVisualZoom(details.localFocalPoint),
            onScaleUpdate: (ScaleUpdateDetails details) {
              if (details.pointerCount >= 2) _updateVisualZoom(details.scale, details.localFocalPoint);
            },
            onScaleEnd: (ScaleEndDetails details) => _endVisualZoom(),
            onDoubleTapDown: (TapDownDetails details) => _setZoom(_zoom > 1.2 ? 1 : 2.5, focal: details.localPosition),
            onDoubleTap: () {},
            child: scaled,
          ),
        );
      },
    );
  }

  Widget _buildError(UDocValue value) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 42),
          const SizedBox(height: 12),
          UTextBodyMedium(value.error?.needsPassword == true ? U.s.documentPassword : U.s.couldNotOpenTheDocument, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => unawaited(value.error?.needsPassword == true ? _askPassword() : _open()),
            child: UTextBodyMedium(value.error?.needsPassword == true ? U.s.open : U.s.retry),
          ),
        ],
      ),
    ),
  );

  Widget _buildContinuous(UDocViewSettings settings) {
    final bool horizontal = settings.isHorizontal;
    double widest = 0;
    if (!horizontal) {
      final int limit = min(_rows.length, 64);
      for (int i = 0; i < limit; i++) {
        final double width = _rowSize(i).width;
        if (width > widest) widest = width;
      }
    }
    final double contentWidth = widest * _scale + 16;
    final Widget list = ListView.builder(
      controller: _vertical,
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      reverse: horizontal && settings.isRtl,
      scrollCacheExtent: const ScrollCacheExtent.viewport(1.2),
      padding: EdgeInsets.only(top: horizontal ? 0 : _topPad, bottom: horizontal ? 0 : _bottomPad),
      itemCount: _rows.length,
      itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) => index < _rows.length ? _rowExtent(index) : null,
      itemBuilder: (BuildContext context, int index) => _buildRow(index, settings),
    );
    if (horizontal || contentWidth <= _viewportWidth) return list;
    return Scrollbar(
      controller: _horizontal,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: contentWidth, height: _viewportHeight, child: list),
      ),
    );
  }

  Widget _buildPaged(UDocViewSettings settings) {
    _pageController ??= PageController(initialPage: _rowOf(_controller.value.pageIndex));
    return PageView.builder(
      controller: _pageController,
      scrollDirection: settings.scrollMode == UDocScrollMode.pagedVertical ? Axis.vertical : Axis.horizontal,
      reverse: settings.scrollMode != UDocScrollMode.pagedVertical && settings.isRtl,
      itemCount: _rows.length,
      onPageChanged: (int index) {
        if (index < _rows.length) _setVisible(_rows[index].first);
      },
      itemBuilder: (BuildContext context, int index) => Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(child: _buildRow(index, settings)),
        ),
      ),
    );
  }

  Widget _buildRow(int rowIndex, UDocViewSettings settings) {
    if (rowIndex >= _rows.length) return const SizedBox.shrink();
    final List<int> pages = settings.isRtl ? _rows[rowIndex].reversed.toList() : _rows[rowIndex];
    final double gap = settings.pageGap;
    final bool horizontal = settings.isHorizontal;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < pages.length; i++) {
      if (i > 0) children.add(SizedBox(width: gap));
      children.add(_buildPageTile(pages[i], settings));
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: horizontal ? 0 : gap / 2, horizontal: horizontal ? gap / 2 : 0),
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  Widget _buildPageTile(int index, UDocViewSettings settings) {
    final UDocPageInfo info = _controller.pageInfo(index);
    final Size size = info.rotatedSize;
    final double scale = _scale;
    final Size display = Size(size.width * scale, size.height * scale);
    final List<UDocSearchHit> hits = _controller.value.searchHits.where((UDocSearchHit hit) => hit.pageIndex == index).toList();
    final List<UDocMarkup> markups = widget.enableMarkup ? _markup.markupsOn(index) : const <UDocMarkup>[];
    if (markups.any(_needsPlacement)) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) => unawaited(_resolvePage(index)));
    }
    final UPdfEditController? pageEditor = editor;
    final UPdfAnnotationInfo? selectedAnnotation = _selectedAnnotation?.pageIndex == index ? _selectedAnnotation : null;
    final bool editing = pageEditor != null && pageEditor.tool != UPdfTool.select;
    final UDocWatermark? watermark = widget.watermark;
    final Color accent = Theme.of(context).colorScheme.primary;
    final List<Widget> layers = <Widget>[
      UPdfPageView(
        controller: _controller,
        pageIndex: index,
        displayScale: scale,
        colorMode: settings.colorMode,
        highlights: hits,
        activeHit: _controller.value.currentHit?.pageIndex == index ? _controller.value.currentHit : null,
        selectionRects: _selection.pageIndex == index ? _selection.rects : const <Rect>[],
        selectionColor: accent.withValues(alpha: 0.28),
        onTap: (Offset point) => unawaited(_handleTap(index, point)),
        onMouseTap: (int count, Offset point) {
          if (count >= 3) {
            unawaited(_selectLineAt(index, point));
          } else if (count == 2) {
            unawaited(_selectWordAt(index, point));
          } else {
            unawaited(_handleTap(index, point, mouse: true));
          }
        },
        onLongPress: (Offset point) => unawaited(_selectWordAt(index, point)),
        onDragSelect: (Offset point) => unawaited(_extendSelection(index, point)),
        onSelectStart: (Offset point) => unawaited(_beginDragSelection(index, point)),
        onSelectUpdate: (Offset point) => unawaited(_extendSelection(index, point)),
        onHandleDrag: (bool isStart, Offset point) => unawaited(_adjustSelection(index, isStart, point)),
        showHandles: widget.allowSelection,
        selectable: widget.allowSelection && !editing,
      ),
      if (markups.isNotEmpty)
        IgnorePointer(
          child: CustomPaint(
            size: display,
            painter: _UPdfMarkupPainter(markups: markups, size: display, activeId: _activeMarkup?.id, showBadges: widget.noteDisplay != UDocNoteDisplay.hidden),
          ),
        ),
      if (widget.noteDisplay == UDocNoteDisplay.bubble) ...markups.where((UDocMarkup markup) => markup.hasNote && markup.isPlaced).map((UDocMarkup markup) => _noteBubble(markup, display)),
      if (watermark != null)
        Positioned.fill(
          child: UDocWatermarkLayer(watermark: watermark, pageIndex: index, scale: scale),
        ),
      if (_drawingEnabled)
        Positioned.fill(
          child: UDocShapeLayer(
            key: ValueKey<String>("shapes$index"),
            shapes: _markup.shapesOn(index),
            tools: _draw,
            enabled: _drawOpen,
            zoom: _zoom,
            prepare: (UDocShape shape) => shape.placed(pageIndex: index),
            onAdd: _markup.addShape,
            onUpdate: _markup.updateShape,
            onRemove: _markup.removeShape,
          ),
        ),
      if (widget.pageOverlayBuilder != null) Positioned.fill(child: widget.pageOverlayBuilder!(context, index, display, scale)),
      if (widget.enableMarkup && _markup.isBookmarked(index))
        Positioned(
          right: 10,
          top: 0,
          child: IgnorePointer(
            child: Icon(Icons.bookmark_rounded, color: _markup.bookmarkOn(index)!.color, size: max(18, 26 * scale.clamp(0.6, 1.4).toDouble())),
          ),
        ),
      if (selectedAnnotation != null) Positioned.fill(child: _annotationOverlay(selectedAnnotation, info, scale)),
      if (editing)
        Positioned.fill(
          child: _UPdfEditLayer(
            editor: pageEditor,
            pageIndex: index,
            displayScale: scale,
            onNoteRequested: (Offset point) => unawaited(_askAnnotationText(pageEditor, index, point, freeText: false)),
            onTextRequested: (Offset point) => unawaited(_askAnnotationText(pageEditor, index, point, freeText: true)),
          ),
        ),
    ];
    return SizedBox(
      width: display.width,
      height: display.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: UDocColorFilters.pageBackground(settings.colorMode),
          boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: layers),
      ),
    );
  }

  Widget _noteBubble(UDocMarkup markup, Size display) {
    final Rect bounds = markup.rectsIn(display).reduce((Rect a, Rect b) => a.expandToInclude(b));
    const double width = 170;
    final bool placeRight = bounds.right + width + 8 < display.width || bounds.left - width - 8 < 0;
    return Positioned(
      left: placeRight ? min(bounds.right + 6, display.width - width) : max(0, bounds.left - width - 6),
      top: max(0, bounds.top - 4),
      width: width,
      child: GestureDetector(
        onTap: () => setState(() => _activeMarkup = markup),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color.lerp(markup.color, const Color(0xFFFFFFFF), 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: markup.color, width: 1.2),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 4)],
          ),
          child: Text(
            markup.note,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            textDirection: UDocText.isRtl(markup.note) ? TextDirection.rtl : TextDirection.ltr,
            style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A), height: 1.3),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollThumb(UDocValue value) {
    const double thumbHeight = 34;
    final double top = _toolbarInset + 4;
    final double bottom = _bottomInset + 4;
    return PositionedDirectional(
      end: 0,
      top: top,
      bottom: bottom,
      width: 72,
      child: AnimatedBuilder(
        animation: _vertical,
        builder: (BuildContext context, Widget? child) {
          if (!_vertical.hasClients || !_vertical.position.hasContentDimensions) return const SizedBox.shrink();
          final double maxExtent = _vertical.position.maxScrollExtent;
          final double track = _viewportHeight - top - bottom - thumbHeight;
          if (maxExtent <= 0 || track <= 40) return const SizedBox.shrink();
          final double fraction = (_vertical.offset / maxExtent).clamp(0, 1).toDouble();
          final bool visible = _indicatorVisible || _thumbDragging || !UApp.isMobile;
          return Stack(
            children: <Widget>[
              PositionedDirectional(
                end: 0,
                top: track * fraction,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onVerticalDragStart: (DragStartDetails details) => applyState(() => _thumbDragging = true),
                    onVerticalDragUpdate: (DragUpdateDetails details) {
                      final double next = ((_vertical.offset / maxExtent) + details.delta.dy / track).clamp(0, 1).toDouble();
                      _vertical.jumpTo(next * maxExtent);
                    },
                    onVerticalDragEnd: (DragEndDetails details) {
                      applyState(() => _thumbDragging = false);
                      _showIndicator();
                    },
                    child: Container(
                      height: thumbHeight,
                      constraints: const BoxConstraints(minWidth: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.85),
                        borderRadius: const BorderRadiusDirectional.horizontal(start: Radius.circular(17)),
                      ),
                      child: UTextLabelMedium("${_visiblePage + 1}", color: Theme.of(context).colorScheme.onInverseSurface, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator(UDocValue value) => Positioned(
    left: 0,
    right: 0,
    top: _toolbarInset + 10,
    child: IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xB3000000), borderRadius: BorderRadius.circular(16)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: UTextLabelMedium("${_visiblePage + 1} / ${value.pageCount}", color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );

  Widget _buildSelectionMenu() => Positioned(
    left: 12,
    right: 12,
    bottom: _bottomInset + 12,
    child: Center(
      child: ExcludeFocus(
        child: UDocSelectionMenu(
          color: _markup.color,
          kinds: widget.enableMarkup ? widget.markupKinds : const <UDocMarkupKind>[],
          onColor: (Color color) => _markup.color = color,
          onMarkup: (UDocMarkupKind kind) => unawaited(_applyMarkup(kind)),
          onCopy: widget.allowCopy ? () => unawaited(_copySelection()) : null,
          onShare: widget.allowCopy && widget.allowShare ? () => unawaited(UShare.text(text: _selection.text)) : null,
          onSearch: () {
            final String query = _selection.text;
            _clearSelection();
            _searchField.text = query;
            _openSearch();
            unawaited(_runSearch(query));
          },
          onClose: _clearSelection,
        ),
      ),
    ),
  );

  Widget _buildMarkupMenu(UDocMarkup markup) => Positioned(
    left: 12,
    right: 12,
    bottom: _bottomInset + 12,
    child: Center(
      child: UDocMarkupMenu(
        markup: markup,
        controller: _markup,
        allowCopy: widget.allowCopy,
        kinds: widget.markupKinds,
        onDone: () => setState(() => _activeMarkup = null),
      ),
    ),
  );
}

extension _UPdfViewerChrome on UPdfViewerState {
  Widget _buildToolbar(UDocValue value) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool compact = _viewportWidth < 520;
    final bool bookmarked = widget.enableMarkup && _markup.isBookmarked(_visiblePage);
    final UPdfEditController? target = editor;
    return Material(
      color: scheme.surface.withValues(alpha: 0.96),
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
                  if (widget.showSidebar && value.isReady) IconButton(icon: const Icon(Icons.view_sidebar_outlined), tooltip: U.s.thumbnails, onPressed: _toggleSidebar),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: UTextTitleSmall(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  ...widget.actions,
                  if (value.isReady)
                    IconButton(icon: Icon(_searchOpen ? Icons.search_off_rounded : Icons.search_rounded), tooltip: U.s.search, onPressed: widget.showSidebar ? _openSearch : _toggleSearch),
                  if (value.isReady && widget.enableMarkup)
                    IconButton(
                      icon: Icon(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_outlined, color: bookmarked ? _markup.bookmarkOn(_visiblePage)?.color : null),
                      tooltip: bookmarked ? U.s.removeBookmark : U.s.bookmarkPage,
                      onPressed: _toggleBookmark,
                    ),
                  if (value.isReady && widget.enableMarkup && !compact) IconButton(icon: const Icon(Icons.undo_rounded), tooltip: U.s.undo, onPressed: _markup.canUndo ? _markup.undo : null),
                  if (value.isReady && widget.enableMarkup && !compact) IconButton(icon: const Icon(Icons.redo_rounded), tooltip: U.s.redo, onPressed: _markup.canRedo ? _markup.redo : null),
                  if (_drawingEnabled && value.isReady)
                    IconButton(
                      icon: Icon(_drawOpen ? Icons.draw_rounded : Icons.draw_outlined, color: _drawOpen ? scheme.primary : null),
                      tooltip: U.s.draw,
                      isSelected: _drawOpen,
                      onPressed: toggleDrawing,
                    ),
                  if (target != null && value.isReady)
                    IconButton(
                      icon: Icon(_toolsOpen ? Icons.edit_off_rounded : Icons.edit_rounded),
                      tooltip: U.s.edit,
                      isSelected: _toolsOpen,
                      onPressed: () {
                        target.attach();
                        if (!_toolsOpen && _drawOpen) toggleDrawing(false);
                        applyState(() {
                          _toolsOpen = !_toolsOpen;
                          if (!_toolsOpen) target.setTool(UPdfTool.select);
                        });
                      },
                    ),
                  if (value.isReady) IconButton(icon: const Icon(Icons.tune_rounded), tooltip: U.s.settings, onPressed: () => unawaited(_openSettings())),
                  if (value.isReady)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      tooltip: U.s.more,
                      onSelected: (String action) => unawaited(_onMenu(action)),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        if (widget.enableMarkup) ...<PopupMenuEntry<String>>[
                          _menuItem("annotations", Icons.sticky_note_2_outlined, U.s.annotations),
                          _menuItem("bookmarks", Icons.bookmarks_outlined, U.s.bookmarks),
                          _menuItem("exportNotes", Icons.ios_share_rounded, U.s.exportAnnotations),
                          _menuItem("exportData", Icons.data_object_rounded, U.s.export),
                          _menuItem("importData", Icons.download_rounded, U.s.importAnnotations),
                          if (_drawingEnabled && _markup.shapesOn(_visiblePage).isNotEmpty) _menuItem("clearDrawings", Icons.layers_clear_outlined, U.s.clearDrawings),
                          _menuItem("clearAll", Icons.delete_sweep_outlined, U.s.clearAnnotations),
                        ],
                        if (target != null) ...<PopupMenuEntry<String>>[
                          const PopupMenuDivider(),
                          _menuItem("pdfAnnotations", Icons.draw_outlined, U.s.annotations),
                          _menuItem("pages", Icons.auto_stories_outlined, U.s.pages),
                          _menuItem("tools", Icons.handyman_outlined, U.s.tools),
                        ],
                        const PopupMenuDivider(),
                        _menuItem("info", Icons.info_outline_rounded, U.s.documentInfo),
                      ],
                    ),
                ],
              ),
            ),
            if (_searchOpen) _buildSearchBar(value),
            if (_toolsOpen && target != null) _buildToolsRow(target),
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

  Widget _buildToolsRow(UPdfEditController target) => SizedBox(
    height: 52,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          _toolChip(target, UPdfTool.highlight, Icons.format_color_fill_rounded, U.s.highlight),
          _toolChip(target, UPdfTool.underline, Icons.format_underlined_rounded, U.s.underline),
          _toolChip(target, UPdfTool.strikeOut, Icons.format_strikethrough_rounded, U.s.strikeThrough),
          _toolChip(target, UPdfTool.ink, Icons.draw_rounded, U.s.draw),
          _toolChip(target, UPdfTool.rectangle, Icons.crop_square_rounded, U.s.rectangle),
          _toolChip(target, UPdfTool.ellipse, Icons.circle_outlined, U.s.ellipse),
          _toolChip(target, UPdfTool.arrow, Icons.north_east_rounded, U.s.arrow),
          _toolChip(target, UPdfTool.note, Icons.sticky_note_2_outlined, U.s.note),
          _toolChip(target, UPdfTool.textBox, Icons.title_rounded, U.s.textBox),
          _toolChip(target, UPdfTool.redact, Icons.hide_source_rounded, U.s.redact),
          _toolChip(target, UPdfTool.eraser, Icons.cleaning_services_rounded, U.s.erase),
          const VerticalDivider(width: 12),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: U.s.color,
            onPressed: () async {
              final Color? color = await UNavigator.colorPicker(defaultColor: target.color, colors: UDocPalette.colors);
              if (color == null) return;
              target.setColor(color);
              target.setInkColor(color);
            },
          ),
          IconButton(icon: const Icon(Icons.undo_rounded), tooltip: U.s.undo, onPressed: target.canUndo ? () => unawaited(target.undo()) : null),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(icon: const Icon(Icons.save_rounded), tooltip: U.s.save, onPressed: target.hasChanges ? () => unawaited(_saveDocument(target)) : null),
        ],
      ),
    ),
  );

  Widget _toolChip(UPdfEditController target, UPdfTool tool, IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: IconButton(
      tooltip: label,
      isSelected: target.tool == tool,
      icon: Icon(icon, color: target.tool == tool ? Theme.of(context).colorScheme.primary : null),
      onPressed: () {
        target.setTool(target.tool == tool ? UPdfTool.select : tool);
        applyState(() {});
        if (_selection.isNotEmpty && (tool == UPdfTool.highlight || tool == UPdfTool.underline || tool == UPdfTool.strikeOut)) unawaited(_applyPdfMarkup());
      },
    ),
  );

  Widget _buildSearchBar(UDocValue value) => SizedBox(
    height: 52,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _searchField,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(isDense: true, hintText: U.s.search, border: const OutlineInputBorder()),
              onSubmitted: (String query) => unawaited(_runSearch(query)),
            ),
          ),
          const SizedBox(width: 8),
          if (value.isSearching) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          if (!value.isSearching && value.searchHits.isNotEmpty) UTextBodySmall("${value.searchHitIndex + 1}/${value.searchHits.length}"),
          if (!value.isSearching && value.searchHits.isEmpty && value.searchQuery.isNotEmpty) UTextBodySmall(U.s.noResults),
          IconButton(icon: const Icon(Icons.keyboard_arrow_up_rounded), onPressed: () => _goToHit((value.searchHitIndex - 1 + value.searchHits.length) % max(1, value.searchHits.length))),
          IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded), onPressed: () => _goToHit((value.searchHitIndex + 1) % max(1, value.searchHits.length))),
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: _toggleSearch),
        ],
      ),
    ),
  );

  Widget _buildBottomBar(UDocValue value) {
    final bool compact = _viewportWidth < 520;
    final int zoomPercent = (_zoom * 100).round();
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
      elevation: 2,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: <Widget>[
                IconButton(icon: const Icon(Icons.chevron_left_rounded), tooltip: U.s.previousPage, onPressed: _visiblePage > 0 ? previousPage : null),
                IconButton(icon: const Icon(Icons.zoom_out_rounded), tooltip: U.s.zoomOut, onPressed: () => _setZoom(_zoom / 1.25)),
                if (!compact)
                  PopupMenuButton<UDocFit>(
                    tooltip: U.s.fitWidth,
                    onSelected: _setFit,
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<UDocFit>>[
                      PopupMenuItem<UDocFit>(value: UDocFit.width, child: UTextBodyMedium(U.s.fitWidth)),
                      PopupMenuItem<UDocFit>(value: UDocFit.page, child: UTextBodyMedium(U.s.fitPage)),
                      PopupMenuItem<UDocFit>(value: UDocFit.actual, child: UTextBodyMedium(U.s.actualSize)),
                    ],
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: UTextLabelMedium("$zoomPercent%")),
                  ),
                IconButton(icon: const Icon(Icons.zoom_in_rounded), tooltip: U.s.zoomIn, onPressed: () => _setZoom(_zoom * 1.25)),
                Expanded(
                  child: value.pageCount <= 1
                      ? const SizedBox.shrink()
                      : Slider(
                          value: (_visiblePage + 1).toDouble().clamp(1, value.pageCount.toDouble()),
                          min: 1,
                          max: value.pageCount.toDouble(),
                          onChanged: (double next) => _jumpToPage(next.round() - 1, animated: false),
                        ),
                ),
                TextButton(
                  onPressed: () => unawaited(_askPageNumber()),
                  child: Directionality(textDirection: TextDirection.ltr, child: UTextBodySmall("${_visiblePage + 1} / ${value.pageCount}")),
                ),
                IconButton(icon: const Icon(Icons.chevron_right_rounded), tooltip: U.s.nextPage, onPressed: _visiblePage < value.pageCount - 1 ? nextPage : null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(UDocValue value) {
    final List<(_UPdfSidebarTab, IconData, String)> tabs = <(_UPdfSidebarTab, IconData, String)>[
      (_UPdfSidebarTab.thumbnails, Icons.grid_view_rounded, U.s.thumbnails),
      (_UPdfSidebarTab.outline, Icons.format_list_bulleted_rounded, U.s.outline),
      if (widget.enableMarkup) (_UPdfSidebarTab.annotations, Icons.sticky_note_2_outlined, U.s.annotations),
      if (widget.enableMarkup) (_UPdfSidebarTab.bookmarks, Icons.bookmarks_outlined, U.s.bookmarks),
      (_UPdfSidebarTab.search, Icons.search_rounded, U.s.search),
    ];
    if (!tabs.any(((_UPdfSidebarTab, IconData, String) tab) => tab.$1 == _tab)) _tab = tabs.first.$1;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: Row(
            children: <Widget>[
              for (final (_UPdfSidebarTab, IconData, String) tab in tabs)
                Expanded(
                  child: IconButton(
                    tooltip: tab.$3,
                    isSelected: _tab == tab.$1,
                    color: _tab == tab.$1 ? Theme.of(context).colorScheme.primary : null,
                    icon: Icon(tab.$2),
                    onPressed: () => applyState(() => _tab = tab.$1),
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
      case _UPdfSidebarTab.thumbnails:
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: value.pageCount,
          itemBuilder: (BuildContext context, int index) {
            final bool current = index == _visiblePage;
            final UDocBookmark? bookmark = widget.enableMarkup ? _markup.bookmarkOn(index) : null;
            final int notes = widget.enableMarkup ? _markup.markupsOn(index).length : 0;
            final double ratio = _controller.pageInfo(index).aspectRatio;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  _closeSidebarIfOverlay();
                  _jumpToPage(index);
                },
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 150,
                            height: 150 / (ratio <= 0 ? 0.7 : ratio),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              border: Border.all(color: current ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor, width: current ? 2.5 : 1),
                            ),
                            child: UPdfThumbnail(controller: _controller, pageIndex: index),
                          ),
                        ),
                        if (bookmark != null) PositionedDirectional(end: 60, top: 0, child: Icon(Icons.bookmark_rounded, color: bookmark.color, size: 20)),
                        if (notes > 0)
                          PositionedDirectional(
                            start: 62,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                              child: UTextLabelSmall("$notes", color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    UTextBodySmall("${index + 1}", fontWeight: current ? FontWeight.w700 : null),
                  ],
                ),
              ),
            );
          },
        );
      case _UPdfSidebarTab.outline:
        return UPdfOutlinePanel(
          controller: _controller,
          embedded: true,
          currentPage: _visiblePage,
          onSelected: (UDocDestination destination) {
            _closeSidebarIfOverlay();
            _jumpToDestination(destination);
          },
        );
      case _UPdfSidebarTab.annotations:
        return UDocAnnotationsPanel(
          controller: _markup,
          allowCopy: widget.allowCopy,
          onOpen: (UDocMarkup markup) {
            _closeSidebarIfOverlay();
            applyState(() => _activeMarkup = markup);
            _jumpToRect(markup.pageIndex, markup.bounds);
          },
        );
      case _UPdfSidebarTab.bookmarks:
        return UDocBookmarksPanel(
          controller: _markup,
          onOpen: (UDocBookmark bookmark) {
            _closeSidebarIfOverlay();
            _jumpToPage(bookmark.pageIndex);
          },
        );
      case _UPdfSidebarTab.search:
        return _buildSearchPanel(value);
    }
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
          decoration: InputDecoration(
            isDense: true,
            hintText: U.s.search,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchField.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchField.clear();
                      _controller.clearSearch();
                      applyState(() {});
                    },
                  ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: <Widget>[
            FilterChip(label: const UTextBodySmall("Aa"), selected: _matchCase, onSelected: (bool next) => applyState(() => _matchCase = next)),
            const SizedBox(width: 6),
            FilterChip(label: const UTextBodySmall("\"ab\""), selected: _wholeWord, onSelected: (bool next) => applyState(() => _wholeWord = next)),
            const Spacer(),
            if (value.isSearching) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            if (value.searchHits.isNotEmpty) ...<Widget>[
              UTextBodySmall("${value.searchHitIndex + 1}/${value.searchHits.length}"),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                onPressed: () => _goToHit((value.searchHitIndex - 1 + value.searchHits.length) % value.searchHits.length),
              ),
              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.keyboard_arrow_down_rounded), onPressed: () => _goToHit((value.searchHitIndex + 1) % value.searchHits.length)),
            ],
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: ValueListenableBuilder<List<UDocSearchHit>>(
          valueListenable: _controller.liveHits,
          builder: (BuildContext context, List<UDocSearchHit> live, Widget? child) {
            final List<UDocSearchHit> hits = value.searchHits.isNotEmpty ? value.searchHits : live;
            if (hits.isEmpty) return Center(child: UTextBodySmall(value.searchQuery.isEmpty || value.isSearching ? "" : U.s.noResults));
            return ListView.builder(
              itemCount: hits.length,
              itemBuilder: (BuildContext context, int index) {
                final UDocSearchHit hit = hits[index];
                final bool header = index == 0 || hits[index - 1].pageIndex != hit.pageIndex;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (header)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        child: UTextLabelLarge("${U.s.page} ${hit.pageIndex + 1}", fontWeight: FontWeight.w700),
                      ),
                    Material(
                      color: index == value.searchHitIndex ? Theme.of(context).colorScheme.primaryContainer : const Color(0x00000000),
                      child: InkWell(
                        onTap: () {
                          _closeSidebarIfOverlay();
                          _goToHit(index);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: _snippet(hit),
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

  Widget _snippet(UDocSearchHit hit) {
    final String snippet = hit.snippet;
    final String query = _controller.value.searchQuery;
    // Match on normalised text, then map back so ZWNJ/diacritics don't shift the highlight.
    final UDocNormalizedText normalized = UDocNormalizedText.build(snippet);
    final String needle = UDocText.normalize(query.trim());
    final int found = needle.isEmpty ? -1 : normalized.text.indexOf(needle);
    final TextStyle? base = Theme.of(context).textTheme.bodySmall;
    final bool rtl = UDocText.isRtl(snippet);
    if (found < 0) return Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis, style: base, textDirection: rtl ? TextDirection.rtl : TextDirection.ltr);
    final int at = normalized.sourceAt(found);
    final int end = min(snippet.length, normalized.sourceAt(found + needle.length - 1) + 1);
    return Text.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          TextSpan(text: snippet.substring(0, min(at, snippet.length))),
          TextSpan(
            text: snippet.substring(min(at, snippet.length), end),
            style: const TextStyle(backgroundColor: Color(0x99FFC107), fontWeight: FontWeight.w700),
          ),
          TextSpan(text: snippet.substring(end)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}

class _UPdfMarkupPainter extends CustomPainter {
  const _UPdfMarkupPainter({required this.markups, required this.size, required this.activeId, required this.showBadges});

  final List<UDocMarkup> markups;
  final Size size;
  final String? activeId;
  final bool showBadges;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (final UDocMarkup markup in markups) {
      if (!markup.isPlaced) continue;
      UDocMarkupPainter.paint(
        canvas,
        markup.kind,
        markup.rectsIn(size),
        markup.color,
        selected: markup.id == activeId,
        hasNote: showBadges && markup.hasNote,
        rtl: UDocText.isRtl(markup.text),
      );
    }
  }

  @override
  bool shouldRepaint(_UPdfMarkupPainter oldDelegate) => oldDelegate.markups != markups || oldDelegate.size != size || oldDelegate.activeId != activeId || oldDelegate.showBadges != showBadges;
}

class UPdfPageView extends StatefulWidget {
  const UPdfPageView({
    required this.controller,
    required this.pageIndex,
    required this.displayScale,
    this.colorMode = UDocColorMode.normal,
    this.highlights = const <UDocSearchHit>[],
    this.activeHit,
    this.selectionRects = const <Rect>[],
    this.selectionColor = const Color(0x472196F3),
    this.showHandles = true,
    this.selectable = true,
    this.onTap,
    this.onMouseTap,
    this.onLongPress,
    this.onDragSelect,
    this.onSelectStart,
    this.onSelectUpdate,
    this.onSelectEnd,
    this.onHandleDrag,
    super.key,
  });

  final UPdfController controller;
  final int pageIndex;
  final double displayScale;
  final UDocColorMode colorMode;
  final List<UDocSearchHit> highlights;
  final UDocSearchHit? activeHit;
  final List<Rect> selectionRects;
  final Color selectionColor;
  final bool showHandles;
  final bool selectable;
  final void Function(Offset point)? onTap;

  /// Mouse clicks with their click count (1 = click, 2 = double, 3 = triple).
  final void Function(int count, Offset point)? onMouseTap;
  final void Function(Offset point)? onLongPress;
  final void Function(Offset point)? onDragSelect;
  final void Function(Offset point)? onSelectStart;
  final void Function(Offset point)? onSelectUpdate;
  final VoidCallback? onSelectEnd;
  final void Function(bool isStart, Offset point)? onHandleDrag;

  @override
  State<UPdfPageView> createState() => _UPdfPageViewState();
}

class _UPdfPageViewState extends State<UPdfPageView> {
  static const Set<PointerDeviceKind> _pointerDevices = <PointerDeviceKind>{PointerDeviceKind.mouse, PointerDeviceKind.trackpad};
  static const Set<PointerDeviceKind> _touchDevices = <PointerDeviceKind>{PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.invertedStylus};

  ui.Picture? _picture;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(UPdfPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.pageIndex != widget.pageIndex || oldWidget.controller != widget.controller) {
      _picture = null;
      _failed = false;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final ui.Picture? cached = UDocPictureCache.instance.get(UDocPictureCache.key(widget.controller.documentId, widget.pageIndex, 1));
    if (cached == null && _picture != null) {
      _picture = null;
      _failed = false;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    final ui.Picture? picture = await widget.controller.renderPage(widget.pageIndex);
    _loading = false;
    if (!mounted) return;
    setState(() {
      _picture = picture;
      _failed = picture == null;
    });
  }

  Offset _toPagePoint(Offset local) => Offset(local.dx / widget.displayScale, local.dy / widget.displayScale);

  Offset? get _startHandle {
    if (widget.selectionRects.isEmpty) return null;
    Rect first = widget.selectionRects.first;
    for (final Rect rect in widget.selectionRects) {
      if (rect.top < first.top - 1 || ((rect.top - first.top).abs() <= 1 && rect.left < first.left)) first = rect;
    }
    return Offset(first.left * widget.displayScale, first.bottom * widget.displayScale);
  }

  Offset? get _endHandle {
    if (widget.selectionRects.isEmpty) return null;
    Rect last = widget.selectionRects.last;
    for (final Rect rect in widget.selectionRects) {
      if (rect.bottom > last.bottom + 1 || ((rect.bottom - last.bottom).abs() <= 1 && rect.right > last.right)) last = rect;
    }
    return Offset(last.right * widget.displayScale, last.bottom * widget.displayScale);
  }

  Widget _handle({required bool isStart, required Offset position}) => Positioned(
    left: position.dx - 18,
    top: position.dy - 6,
    width: 36,
    height: 36,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (DragUpdateDetails details) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        widget.onHandleDrag?.call(isStart, _toPagePoint(box.globalToLocal(details.globalPosition)));
      },
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ui.Picture? picture = _picture;
    final Widget content = picture == null
        ? Center(
            child: _failed
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: UTextBodySmall(U.s.thisPageCouldNotBeRendered, textAlign: TextAlign.center),
                  )
                : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : RepaintBoundary(
            child: CustomPaint(
              painter: _UPdfPagePainter(picture: picture, scale: widget.displayScale),
              isComplex: true,
              size: Size.infinite,
            ),
          );
    final ColorFilter? filter = UDocColorFilters.forMode(widget.colorMode);
    final Widget filtered = filter == null ? content : ColorFiltered(colorFilter: filter, child: content);
    final Widget overlays = CustomPaint(
      foregroundPainter: _UPdfHighlightPainter(
        scale: widget.displayScale,
        highlights: widget.highlights,
        activeHit: widget.activeHit,
        selectionRects: widget.selectionRects,
        highlightColor: const Color(0x66FFC107),
        activeColor: const Color(0x99FF9800),
        selectionColor: widget.selectionColor,
      ),
      child: filtered,
    );
    final Offset? start = _startHandle;
    final Offset? end = _endHandle;
    final Widget gestures = RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(supportedDevices: _touchDevices),
          (TapGestureRecognizer instance) {
            instance.onTapUp = (TapUpDetails details) => widget.onTap?.call(_toPagePoint(details.localPosition));
          },
        ),
        SerialTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<SerialTapGestureRecognizer>(
          () => SerialTapGestureRecognizer(supportedDevices: _pointerDevices),
          (SerialTapGestureRecognizer instance) {
            instance.onSerialTapUp = (SerialTapUpDetails details) {
              final Offset point = _toPagePoint(details.localPosition);
              if (widget.onMouseTap != null) {
                widget.onMouseTap!(details.count, point);
              } else if (details.count == 1) {
                widget.onTap?.call(point);
              }
            };
          },
        ),
        if (widget.selectable)
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(supportedDevices: _touchDevices),
            (LongPressGestureRecognizer instance) {
              instance.onLongPressStart = (LongPressStartDetails details) => widget.onLongPress?.call(_toPagePoint(details.localPosition));
              instance.onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) => widget.onDragSelect?.call(_toPagePoint(details.localPosition));
              instance.onLongPressEnd = (LongPressEndDetails details) => widget.onSelectEnd?.call();
            },
          ),
        if (widget.selectable)
          PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(supportedDevices: _pointerDevices)..dragStartBehavior = DragStartBehavior.down,
            (PanGestureRecognizer instance) {
              instance.onStart = (DragStartDetails details) => widget.onSelectStart?.call(_toPagePoint(details.localPosition));
              instance.onUpdate = (DragUpdateDetails details) => widget.onSelectUpdate?.call(_toPagePoint(details.localPosition));
              instance.onEnd = (DragEndDetails details) => widget.onSelectEnd?.call();
            },
          ),
      },
      child: overlays,
    );
    return MouseRegion(
      cursor: widget.selectable ? SystemMouseCursors.text : SystemMouseCursors.basic,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          gestures,
          if (widget.showHandles && start != null) _handle(isStart: true, position: start),
          if (widget.showHandles && end != null) _handle(isStart: false, position: end),
        ],
      ),
    );
  }
}

class _UPdfPagePainter extends CustomPainter {
  const _UPdfPagePainter({required this.picture, required this.scale});

  final ui.Picture picture;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(scale);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_UPdfPagePainter oldDelegate) => oldDelegate.picture != picture || oldDelegate.scale != scale;
}

class _UPdfHighlightPainter extends CustomPainter {
  const _UPdfHighlightPainter({
    required this.scale,
    required this.highlights,
    required this.activeHit,
    required this.selectionRects,
    required this.highlightColor,
    required this.activeColor,
    required this.selectionColor,
  });

  final double scale;
  final List<UDocSearchHit> highlights;
  final UDocSearchHit? activeHit;
  final List<Rect> selectionRects;
  final Color highlightColor;
  final Color activeColor;
  final Color selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (highlights.isEmpty && selectionRects.isEmpty) return;
    canvas.save();
    canvas.scale(scale);
    final Paint highlightPaint = Paint()..color = highlightColor;
    for (final UDocSearchHit hit in highlights) {
      for (final Rect rect in hit.rects) {
        canvas.drawRect(rect.inflate(1), highlightPaint);
      }
    }
    final UDocSearchHit? active = activeHit;
    if (active != null) {
      final Paint activePaint = Paint()..color = activeColor;
      for (final Rect rect in active.rects) {
        canvas.drawRect(rect.inflate(1), activePaint);
      }
    }
    if (selectionRects.isNotEmpty) {
      final Paint selectionPaint = Paint()..color = selectionColor;
      for (final Rect rect in selectionRects) {
        canvas.drawRect(rect.inflate(0.5), selectionPaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_UPdfHighlightPainter oldDelegate) =>
      oldDelegate.scale != scale ||
      oldDelegate.highlights != highlights ||
      oldDelegate.activeHit != activeHit ||
      oldDelegate.selectionRects != selectionRects ||
      oldDelegate.selectionColor != selectionColor;
}

class UPdfOutlinePanel extends StatelessWidget {
  const UPdfOutlinePanel({required this.controller, required this.onSelected, this.embedded = false, this.currentPage = -1, super.key});

  final UPdfController controller;
  final void Function(UDocDestination destination) onSelected;
  final bool embedded;
  final int currentPage;

  List<Widget> _build(BuildContext context, List<UDocOutlineNode> nodes, int depth) {
    final List<Widget> widgets = <Widget>[];
    for (final UDocOutlineNode node in nodes) {
      final int? page = node.destination?.pageIndex;
      widgets.add(
        ListTile(
          dense: true,
          selected: page != null && page == currentPage,
          contentPadding: EdgeInsetsDirectional.only(start: 16 + depth * 16, end: 16),
          title: Text(
            node.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: UDocText.isRtl(node.title) ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(fontWeight: node.bold ? FontWeight.bold : null, fontStyle: node.italic ? FontStyle.italic : null, fontSize: 13),
          ),
          trailing: page == null ? null : UTextBodySmall("${page + 1}"),
          onTap: () {
            final UDocDestination? destination = node.destination;
            if (destination != null) onSelected(destination);
            final String? uri = node.uri;
            if (uri != null) unawaited(ULaunch.url(uri));
          },
        ),
      );
      if (node.hasChildren) widgets.addAll(_build(context, node.children, depth + 1));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final List<UDocOutlineNode> nodes = controller.outline;
    final Widget list = nodes.isEmpty ? Center(child: UTextBodyMedium(U.s.noResults)) : ListView(children: _build(context, nodes, 0));
    if (embedded) return list;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: <Widget>[
          Padding(padding: const EdgeInsets.all(16), child: UTextTitleMedium(U.s.outline)),
          Expanded(child: list),
        ],
      ),
    );
  }
}

class UPdfThumbnailPanel extends StatelessWidget {
  const UPdfThumbnailPanel({required this.controller, required this.currentPage, required this.onSelected, super.key});

  final UPdfController controller;
  final int currentPage;
  final void Function(int pageIndex) onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.7,
    child: Column(
      children: <Widget>[
        Padding(padding: const EdgeInsets.all(16), child: UTextTitleMedium(U.s.thumbnails)),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 140, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: controller.pageCount,
            itemBuilder: (BuildContext context, int index) => InkWell(
              onTap: () => onSelected(index),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: index == currentPage ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor, width: index == currentPage ? 2 : 1),
                        color: const Color(0xFFFFFFFF),
                      ),
                      child: UPdfThumbnail(controller: controller, pageIndex: index),
                    ),
                  ),
                  const SizedBox(height: 4),
                  UTextBodySmall("${index + 1}"),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class UPdfThumbnail extends StatefulWidget {
  const UPdfThumbnail({required this.controller, required this.pageIndex, this.maxSize = 220, super.key});

  final UPdfController controller;
  final int pageIndex;
  final int maxSize;

  @override
  State<UPdfThumbnail> createState() => _UPdfThumbnailState();
}

class _UPdfThumbnailState extends State<UPdfThumbnail> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(UPdfThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex || oldWidget.controller != widget.controller) {
      _image = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final ui.Image? image = await widget.controller.renderThumbnail(widget.pageIndex, maxSize: widget.maxSize);
    if (!mounted) return;
    setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    final ui.Image? image = _image;
    if (image == null) return const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)));
    return RawImage(image: image, fit: BoxFit.contain);
  }
}

class UPdfSettingsPanel extends StatefulWidget {
  const UPdfSettingsPanel({required this.controller, required this.onChanged, this.onFit, super.key});

  final UPdfController controller;
  final VoidCallback onChanged;
  final void Function(UDocFit fit)? onFit;

  @override
  State<UPdfSettingsPanel> createState() => _UPdfSettingsPanelState();
}

class _UPdfSettingsPanelState extends State<UPdfSettingsPanel> {
  void _update(UDocViewSettings settings) {
    widget.controller.updateSettings(settings);
    widget.onChanged();
    setState(() {});
  }

  String _scrollLabel(UDocScrollMode mode) {
    switch (mode) {
      case UDocScrollMode.verticalContinuous:
        return U.s.continuous;
      case UDocScrollMode.horizontalContinuous:
        return U.s.horizontal;
      case UDocScrollMode.pagedVertical:
        return "${U.s.paged} ↕";
      case UDocScrollMode.pagedHorizontal:
        return "${U.s.paged} ↔";
      case UDocScrollMode.singlePage:
        return U.s.singlePage;
    }
  }

  String _colorLabel(UDocColorMode mode) {
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

  String _spreadLabel(UDocSpread spread) {
    switch (spread) {
      case UDocSpread.none:
        return U.s.singlePage;
      case UDocSpread.two:
        return U.s.twoPages;
      case UDocSpread.coverFirst:
        return U.s.coverPage;
      case UDocSpread.auto:
        return U.s.auto;
    }
  }

  String _geometryLabel(UDocTextGeometry geometry) {
    switch (geometry) {
      case UDocTextGeometry.auto:
        return U.s.auto;
      case UDocTextGeometry.precise:
        return U.s.precise;
      case UDocTextGeometry.box:
        return U.s.lineBox;
    }
  }

  Widget _chips<T>(List<T> values, T selected, String Function(T value) label, void Function(T value) onSelected) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: values.map((T value) => ChoiceChip(selected: value == selected, label: UTextBodySmall(label(value)), onSelected: (bool _) => onSelected(value))).toList(),
  );

  @override
  Widget build(BuildContext context) {
    final UDocViewSettings settings = widget.controller.settings;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleMedium(U.s.readingMode),
            const SizedBox(height: 8),
            _chips<UDocScrollMode>(
              const <UDocScrollMode>[UDocScrollMode.verticalContinuous, UDocScrollMode.horizontalContinuous, UDocScrollMode.pagedHorizontal, UDocScrollMode.pagedVertical],
              settings.scrollMode,
              _scrollLabel,
              (UDocScrollMode mode) => _update(settings.copyWith(scrollMode: mode)),
            ),
            const SizedBox(height: 16),
            UTextTitleMedium(U.s.spread),
            const SizedBox(height: 8),
            _chips<UDocSpread>(UDocSpread.values, settings.spread, _spreadLabel, (UDocSpread spread) => _update(settings.copyWith(spread: spread))),
            if (widget.onFit != null) ...<Widget>[
              const SizedBox(height: 16),
              UTextTitleMedium(U.s.fitWidth),
              const SizedBox(height: 8),
              _chips<UDocFit>(
                const <UDocFit>[UDocFit.width, UDocFit.page, UDocFit.actual],
                settings.fit,
                (UDocFit fit) => fit == UDocFit.width ? U.s.fitWidth : (fit == UDocFit.page ? U.s.fitPage : U.s.actualSize),
                (UDocFit fit) {
                  widget.onFit!(fit);
                  setState(() {});
                },
              ),
            ],
            const SizedBox(height: 16),
            UTextTitleMedium(U.s.theme),
            const SizedBox(height: 8),
            _chips<UDocColorMode>(
              const <UDocColorMode>[UDocColorMode.normal, UDocColorMode.night, UDocColorMode.sepia, UDocColorMode.grayscale, UDocColorMode.highContrast],
              settings.colorMode,
              _colorLabel,
              (UDocColorMode mode) => _update(settings.copyWith(colorMode: mode)),
            ),
            const SizedBox(height: 16),
            UTextTitleMedium(U.s.pageDirection),
            const SizedBox(height: 8),
            _chips<UDocDirection>(
              UDocDirection.values,
              settings.direction,
              (UDocDirection direction) => direction == UDocDirection.rtl ? U.s.rightToLeft : U.s.leftToRight,
              (UDocDirection direction) => _update(settings.copyWith(direction: direction)),
            ),
            const SizedBox(height: 16),
            UTextTitleMedium(U.s.selectionAccuracy),
            const SizedBox(height: 8),
            _chips<UDocTextGeometry>(UDocTextGeometry.values, settings.textGeometry, _geometryLabel, (UDocTextGeometry geometry) => _update(settings.copyWith(textGeometry: geometry))),
            const SizedBox(height: 16),
            UTextTitleMedium(U.s.brightness),
            Slider(
              value: 1 - settings.dim,
              min: 0.15,
              onChanged: (double next) => _update(settings.copyWith(dim: 1 - next)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.showAnnotations,
              title: UTextBodyMedium(U.s.showAnnotations),
              onChanged: (bool next) {
                widget.controller.invalidateAll();
                _update(settings.copyWith(showAnnotations: next));
              },
            ),
            const SizedBox(height: 8),
            UTextTitleMedium(U.s.documentInfo),
            const SizedBox(height: 8),
            _infoRow(U.s.title, widget.controller.value.metadata.displayTitle),
            _infoRow(U.s.author, widget.controller.value.metadata.author ?? ""),
            _infoRow(U.s.pages, "${widget.controller.value.pageCount}"),
            _infoRow("PDF", widget.controller.value.metadata.version ?? ""),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: 110, child: UTextBodySmall(label)),
        Expanded(child: UTextBodySmall(value.isEmpty ? "—" : value)),
      ],
    ),
  );
}

abstract class UPdf {
  static Future<void> show({String? base64Pdf, Uint8List? bytes, String? url, String? filePath, String? asset, String password = "", int initialPage = 0, String? title}) =>
      UNavigator.bottomSheet<void>(
        UScaffold(
          body: SizedBox(
            width: MediaQuery.sizeOf(navigatorKey.currentContext!).width,
            height: MediaQuery.sizeOf(navigatorKey.currentContext!).height * 0.92,
            child: UPdfViewer(base64Pdf: base64Pdf, bytes: bytes, url: url, filePath: filePath, asset: asset, password: password, initialPage: initialPage, title: title),
          ),
        ),
      );

  /// Pushes a full-screen reader with every feature enabled.
  static Future<void> open({
    String? base64Pdf,
    Uint8List? bytes,
    String? url,
    String? filePath,
    String? asset,
    String password = "",
    int initialPage = 0,
    String? title,
    String? annotationData,
    void Function(String data)? onAnnotationsChanged,
    bool allowCopy = true,
    bool secure = false,
    UDocWatermark? watermark,
  }) => UNavigator.push<void>(
    UScaffold(
      body: UPdfViewer(
        base64Pdf: base64Pdf,
        bytes: bytes,
        url: url,
        filePath: filePath,
        asset: asset,
        password: password,
        initialPage: initialPage,
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

  static Future<String> extractText({String? filePath, Uint8List? bytes, String? url, String password = "", int startPage = 0, int endPage = -1}) async {
    final UPdfDocument document = await UPdfDocument.open(path: filePath, bytes: bytes, url: url, password: password);
    final UPdfPageRenderer renderer = UPdfPageRenderer(document);
    final StringBuffer buffer = StringBuffer();
    final int last = endPage < 0 ? document.pageCount : endPage;
    for (int i = startPage; i < last && i < document.pageCount; i++) {
      final UPdfPage? page = await document.page(i);
      if (page == null) continue;
      buffer.writeln((await renderer.extractText(page)).text);
    }
    await document.close();
    return buffer.toString();
  }

  static Future<UDocMetadata?> info({String? filePath, Uint8List? bytes, String? url, String password = ""}) async {
    try {
      final UPdfDocument document = await UPdfDocument.open(path: filePath, bytes: bytes, url: url, password: password);
      final UDocMetadata metadata = await document.metadata();
      await document.close();
      return metadata;
    } on Object {
      return null;
    }
  }
}

class _UPdfEditLayer extends StatefulWidget {
  const _UPdfEditLayer({required this.editor, required this.pageIndex, required this.displayScale, required this.onNoteRequested, required this.onTextRequested});

  final UPdfEditController editor;
  final int pageIndex;
  final double displayScale;
  final void Function(Offset point) onNoteRequested;
  final void Function(Offset point) onTextRequested;

  @override
  State<_UPdfEditLayer> createState() => _UPdfEditLayerState();
}

class _UPdfEditLayerState extends State<_UPdfEditLayer> {
  Offset _toPage(Offset local) => Offset(local.dx / widget.displayScale, local.dy / widget.displayScale);

  @override
  void initState() {
    super.initState();
    widget.editor.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.editor.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final UPdfTool tool = widget.editor.tool;
    if (tool == UPdfTool.note || tool == UPdfTool.textBox || tool == UPdfTool.eraser) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          final Offset point = _toPage(details.localPosition);
          if (tool == UPdfTool.note) {
            widget.onNoteRequested(point);
          } else if (tool == UPdfTool.textBox) {
            widget.onTextRequested(point);
          } else {
            unawaited(widget.editor.eraseAt(widget.pageIndex, point));
          }
        },
      );
    }
    if (!widget.editor.isDrawing) return const SizedBox.shrink();
    final List<Offset> stroke = widget.editor.liveStroke(widget.pageIndex);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (DragStartDetails details) => widget.editor.beginStroke(widget.pageIndex, _toPage(details.localPosition)),
      onPanUpdate: (DragUpdateDetails details) => widget.editor.extendStroke(widget.pageIndex, _toPage(details.localPosition)),
      onPanEnd: (DragEndDetails details) => unawaited(widget.editor.endStroke(widget.pageIndex)),
      child: CustomPaint(
        painter: _UPdfStrokePainter(points: stroke, scale: widget.displayScale, color: widget.editor.inkColor, width: widget.editor.strokeWidth, tool: tool),
        size: Size.infinite,
      ),
    );
  }
}

class _UPdfStrokePainter extends CustomPainter {
  const _UPdfStrokePainter({required this.points, required this.scale, required this.color, required this.width, required this.tool});

  final List<Offset> points;
  final double scale;
  final Color color;
  final double width;
  final UPdfTool tool;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    canvas.save();
    canvas.scale(scale);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    if (tool == UPdfTool.ink) {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    } else {
      final Rect rect = Rect.fromPoints(points.first, points.last);
      if (tool == UPdfTool.rectangle) canvas.drawRect(rect, paint);
      if (tool == UPdfTool.ellipse) canvas.drawOval(rect, paint);
      if (tool == UPdfTool.arrow) canvas.drawLine(points.first, points.last, paint);
      if (tool == UPdfTool.redact) canvas.drawRect(rect, Paint()..color = const Color(0xCC000000));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_UPdfStrokePainter oldDelegate) => oldDelegate.points.length != points.length || oldDelegate.tool != tool || oldDelegate.color != color;
}
