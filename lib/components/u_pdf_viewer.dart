import "dart:ui" as ui;

import "package:u/utilities.dart";

class UPdfViewer extends StatefulWidget {
  const UPdfViewer({
    this.base64Pdf,
    this.bytes,
    this.url,
    this.filePath,
    this.asset,
    this.controller,
    this.editController,
    this.password = "",
    this.initialPage = 0,
    this.showToolbar = true,
    this.showBottomBar = true,
    this.allowSelection = true,
    this.enableAnnotations = true,
    this.savePath,
    this.scrollMode = UDocScrollMode.verticalContinuous,
    this.direction,
    this.colorMode = UDocColorMode.normal,
    this.headers,
    this.onControllerReady,
    this.onPageChanged,
    this.onLinkTapped,
    super.key,
  }) : assert(base64Pdf != null || bytes != null || url != null || filePath != null || asset != null || controller != null, "Provide one PDF source");

  final String? base64Pdf;
  final Uint8List? bytes;
  final String? url;
  final String? filePath;
  final String? asset;
  final UPdfController? controller;
  final UPdfEditController? editController;
  final String password;
  final int initialPage;
  final bool showToolbar;
  final bool showBottomBar;
  final bool allowSelection;
  final bool enableAnnotations;
  final String? savePath;
  final UDocScrollMode scrollMode;
  final UDocDirection? direction;
  final UDocColorMode colorMode;
  final Map<String, String>? headers;
  final void Function(UPdfController controller)? onControllerReady;
  final void Function(int pageIndex)? onPageChanged;
  final void Function(UDocLink link)? onLinkTapped;

  @override
  State<UPdfViewer> createState() => UPdfViewerState();
}

class UPdfViewerState extends State<UPdfViewer> {
  late UPdfController _controller;
  bool _ownsController = false;

  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();
  final Map<int, List<UDocLink>> _links = <int, List<UDocLink>>{};
  final Map<int, UDocTextPage> _texts = <int, UDocTextPage>{};
  final TextEditingController _searchField = TextEditingController();
  final GlobalKey _viewportKey = GlobalKey();

  UPdfEditController? _internalEditor;
  PageController? _pageController;
  double _zoom = 1;
  double _baseScale = 1;
  double _pinchStart = 1;
  double _viewportWidth = 0;
  double _viewportHeight = 0;
  int _visiblePage = 0;
  bool _searchOpen = false;
  bool _chromeVisible = true;
  UDocSelection _selection = UDocSelection.none;
  Offset? _selectionAnchor;
  bool _toolsOpen = false;
  bool _saving = false;
  UPdfAnnotationInfo? _selectedAnnotation;
  Rect? _annotationDraft;
  Timer? _progressTimer;

  UPdfController get controller => _controller;

  UPdfEditController? get editor => widget.editController ?? _internalEditor;

  void applyState(VoidCallback action) => setState(action);

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
        direction: widget.direction ?? _controller.settings.direction,
      ),
    );
    if (widget.editController == null && widget.enableAnnotations) _internalEditor = UPdfEditController(viewer: _controller);
    _internalEditor?.addListener(_onControllerChanged);
    _vertical.addListener(_onScroll);
    if (_ownsController) unawaited(_open());
    if (!_ownsController) {
      _visiblePage = _controller.value.pageIndex;
      widget.onControllerReady?.call(_controller);
    }
    _progressTimer = Timer.periodic(const Duration(seconds: 20), (Timer timer) => _controller.saveProgress());
  }

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
    if (mounted) setState(() {});
    _jumpToPage(_controller.value.pageIndex, animated: false);
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
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onScroll() {
    if (!_vertical.hasClients || _controller.pageCount == 0) return;
    final int page = _pageAtOffset(_vertical.offset + _viewportHeight / 2);
    if (page != _visiblePage) {
      _visiblePage = page;
      _controller.goToPage(page);
      widget.onPageChanged?.call(page);
    }
  }

  double _pageExtent(int index) {
    final UDocPageInfo info = _controller.pageInfo(index);
    final Size size = info.rotatedSize;
    final double scale = _baseScale * _zoom;
    final bool horizontal = _controller.settings.isHorizontal;
    return (horizontal ? size.width : size.height) * scale + _controller.settings.pageGap;
  }

  int _pageAtOffset(double offset) {
    double total = 0;
    for (int i = 0; i < _controller.pageCount; i++) {
      total += _pageExtent(i);
      if (offset < total) return i;
    }
    return _controller.pageCount == 0 ? 0 : _controller.pageCount - 1;
  }

  double _offsetForPage(int index) {
    double total = 0;
    for (int i = 0; i < index && i < _controller.pageCount; i++) {
      total += _pageExtent(i);
    }
    return total;
  }

  void _computeBaseScale() {
    if (_controller.pageCount == 0) return;
    final UDocPageInfo info = _controller.pageInfo(_visiblePage);
    final Size size = info.rotatedSize;
    if (size.width <= 0 || size.height <= 0) return;
    final UDocViewSettings settings = _controller.settings;
    const double horizontalPadding = 16;
    switch (settings.fit) {
      case UDocFit.width:
        _baseScale = (_viewportWidth - horizontalPadding) / size.width;
        break;
      case UDocFit.page:
        _baseScale = min((_viewportWidth - horizontalPadding) / size.width, (_viewportHeight - horizontalPadding) / size.height);
        break;
      case UDocFit.height:
        _baseScale = (_viewportHeight - horizontalPadding) / size.height;
        break;
      case UDocFit.actual:
        _baseScale = 1;
        break;
      case UDocFit.visible:
      case UDocFit.custom:
        if (_baseScale <= 0) _baseScale = (_viewportWidth - horizontalPadding) / size.width;
        break;
    }
    if (_baseScale <= 0 || !_baseScale.isFinite) _baseScale = 1;
  }

  void _jumpToPage(int index, {bool animated = true}) {
    final int target = index.clamp(0, _controller.pageCount == 0 ? 0 : _controller.pageCount - 1);
    if (_controller.settings.isPaged) {
      _pageController?.jumpToPage(target);
      return;
    }
    if (!_vertical.hasClients) return;
    final double offset = _offsetForPage(target);
    if (animated) {
      unawaited(_vertical.animateTo(offset, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic));
    } else {
      _vertical.jumpTo(offset.clamp(0, _vertical.position.maxScrollExtent));
    }
  }

  void _setZoom(double next, {Offset? focal}) {
    final UDocViewSettings settings = _controller.settings;
    final double clamped = next.clamp(settings.minZoom, settings.maxZoom).toDouble();
    if ((clamped - _zoom).abs() < 0.001) return;
    final double previous = _zoom;
    setState(() {
      _zoom = clamped;
      _controller.updateSettings(settings.copyWith(zoom: clamped, fit: UDocFit.custom));
    });
    if (_vertical.hasClients) {
      final double ratio = clamped / previous;
      final double anchor = focal?.dy ?? _viewportHeight / 2;
      final double target = (_vertical.offset + anchor) * ratio - anchor;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (_vertical.hasClients) _vertical.jumpTo(target.clamp(0, _vertical.position.maxScrollExtent));
      });
    }
  }

  Future<UDocTextPage> _textFor(int index) async {
    final UDocTextPage? cached = _texts[index];
    if (cached != null) return cached;
    final UDocTextPage text = await _controller.textPage(index);
    if (!mounted) return text;
    _texts[index] = text;
    return text;
  }

  Future<List<UDocLink>> _linksFor(int index) async {
    final List<UDocLink>? cached = _links[index];
    if (cached != null) return cached;
    final List<UDocLink> links = await _controller.links(index);
    if (!mounted) return links;
    _links[index] = links;
    return links;
  }

  Future<void> _handleTap(int pageIndex, Offset pagePoint) async {
    final List<UDocLink> links = await _linksFor(pageIndex);
    final UDocPageInfo info = _controller.pageInfo(pageIndex);
    for (final UDocLink link in links) {
      final Rect device = _pdfRectToDevice(link.rect, info);
      if (device.contains(pagePoint)) {
        widget.onLinkTapped?.call(link);
        final String? uri = link.uri;
        if (uri != null) {
          await ULaunch.url(uri);
        } else if (link.destination != null) {
          _jumpToPage(link.destination!.pageIndex);
        }
        return;
      }
    }
    if (_selection.isNotEmpty) {
      setState(() => _selection = UDocSelection.none);
      return;
    }
    final UPdfEditController? target = editor;
    if (target != null && target.tool == UPdfTool.select) {
      final UPdfAnnotationInfo? hit = await target.annotationAt(pageIndex, pagePoint);
      if (hit != null) {
        setState(() {
          _selectedAnnotation = hit;
          _annotationDraft = null;
        });
        return;
      }
      if (_selectedAnnotation != null) {
        setState(() {
          _selectedAnnotation = null;
          _annotationDraft = null;
        });
        return;
      }
    }
    setState(() => _chromeVisible = !_chromeVisible);
  }

  Rect _pdfRectToDevice(Rect rect, UDocPageInfo info) {
    final Rect box = info.cropBox ?? Rect.fromLTWH(0, 0, info.size.width, info.size.height);
    final List<double> matrix = uPdfBaseMatrix(box, info.rotation, 1);
    final Offset a = uPdfApply(matrix, rect.left, rect.top);
    final Offset b = uPdfApply(matrix, rect.right, rect.bottom);
    return Rect.fromLTRB(min(a.dx, b.dx), min(a.dy, b.dy), max(a.dx, b.dx), max(a.dy, b.dy));
  }

  Future<void> _selectWordAt(int pageIndex, Offset pagePoint) async {
    if (!widget.allowSelection) return;
    final UDocTextPage text = await _textFor(pageIndex);
    final int? offset = _offsetAt(text, pagePoint);
    if (offset == null) return;
    final String raw = text.text;
    int start = offset;
    int end = offset;
    while (start > 0 && !_isBreak(raw.codeUnitAt(start - 1))) {
      start--;
    }
    while (end < raw.length && !_isBreak(raw.codeUnitAt(end))) {
      end++;
    }
    if (end <= start) return;
    setState(() {
      _selectionAnchor = pagePoint;
      _selection = UDocSelection(pageIndex: pageIndex, start: start, end: end, text: raw.substring(start, end), rects: text.rectsForRange(start, end));
      _controller.setSelection(_selection);
    });
  }

  bool _isBreak(int code) => code == 0x20 || code == 0x0A || code == 0x09 || code == 0x0D;

  Future<void> _beginDragSelection(int pageIndex, Offset pagePoint) async {
    if (!widget.allowSelection) return;
    final UDocTextPage text = await _textFor(pageIndex);
    final int? offset = _offsetAt(text, pagePoint);
    if (offset == null) return;
    setState(() {
      _selectionAnchor = pagePoint;
      _selection = UDocSelection(
        pageIndex: pageIndex,
        start: offset,
        end: offset + 1,
        text: text.text.substring(offset, offset + 1 > text.text.length ? offset : offset + 1),
        rects: text.rectsForRange(offset, offset + 1),
      );
    });
  }

  Future<void> _adjustSelection(int pageIndex, bool isStart, Offset pagePoint) async {
    if (_selection.isEmpty || _selection.pageIndex != pageIndex) return;
    final UDocTextPage text = await _textFor(pageIndex);
    final int? offset = _offsetAt(text, pagePoint);
    if (offset == null) return;
    int start = isStart ? offset : _selection.start;
    int end = isStart ? _selection.end : offset;
    if (end < start) {
      final int swap = start;
      start = end;
      end = swap;
    }
    if (end <= start) return;
    setState(() {
      _selection = UDocSelection(pageIndex: pageIndex, start: start, end: end, text: text.text.substring(start, end), rects: text.rectsForRange(start, end));
      _controller.setSelection(_selection);
    });
  }

  Future<void> _extendSelection(int pageIndex, Offset pagePoint) async {
    if (_selection.isEmpty || _selection.pageIndex != pageIndex) return;
    final UDocTextPage text = await _textFor(pageIndex);
    final int? offset = _offsetAt(text, pagePoint);
    if (offset == null) return;
    final Offset anchor = _selectionAnchor ?? pagePoint;
    final int? anchorOffset = _offsetAt(text, anchor);
    final int base = anchorOffset ?? _selection.start;
    final int start = base < offset ? base : offset;
    final int end = base < offset ? offset : base;
    if (end <= start) return;
    setState(() {
      _selection = UDocSelection(pageIndex: pageIndex, start: start, end: end, text: text.text.substring(start, end), rects: text.rectsForRange(start, end));
      _controller.setSelection(_selection);
    });
  }

  int? _offsetAt(UDocTextPage text, Offset point) {
    int cursor = 0;
    int? best;
    double bestDistance = double.infinity;
    for (final UDocTextRun run in text.runs) {
      for (int i = 0; i < run.glyphs.length; i++) {
        final Rect rect = run.glyphs[i].rect;
        if (rect.contains(point)) return cursor + i;
        final double distance = (rect.center - point).distanceSquared;
        if (distance < bestDistance) {
          bestDistance = distance;
          best = cursor + i;
        }
      }
      cursor += run.text.length + 1;
    }
    return bestDistance < 40000 ? best : null;
  }

  Future<void> _copySelection() async {
    if (_selection.isEmpty) return;
    await UClipboard.set(_selection.text);
    if (!mounted) return;
    UToast.toast(message: U.s.copied);
    setState(() => _selection = UDocSelection.none);
  }

  Widget _annotationOverlay(UPdfAnnotationInfo annotation, UDocPageInfo info, double scale) {
    final Rect device = _annotationDraft ?? _pdfRectToDevice(annotation.rect, info);
    final Rect box = Rect.fromLTWH(device.left * scale, device.top * scale, device.width * scale, device.height * scale);
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
              decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2)),
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
                  color: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context).colorScheme.inverseSurface,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  iconSize: 18,
                  icon: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.onInverseSurface),
                  onPressed: () => unawaited(_recolourAnnotation(annotation)),
                ),
                IconButton(
                  iconSize: 18,
                  icon: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.onInverseSurface),
                  onPressed: () => unawaited(_editAnnotationNote(annotation)),
                ),
                IconButton(
                  iconSize: 18,
                  icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.onInverseSurface),
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
    final Rect pdfRect = target.deviceRectToPdf(info, draft);
    await target.updateAnnotation(annotation.pageIndex, annotation.objectNumber, rect: pdfRect);
    if (!mounted) return;
    setState(() {
      _annotationDraft = null;
      _selectedAnnotation = null;
    });
  }

  Future<void> _recolourAnnotation(UPdfAnnotationInfo annotation) async {
    const List<Color> palette = <Color>[Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFE91E63), Color(0xFFFF9800), Color(0xFF000000)];
    final Color? picked = await UNavigator.bottomSheet<Color>(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: palette
                .map(
                  (Color color) => InkWell(
                    onTap: () => UNavigator.back<Color>(color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (picked == null) return;
    await editor?.updateAnnotation(annotation.pageIndex, annotation.objectNumber, color: picked);
    if (mounted) setState(() => _selectedAnnotation = null);
  }

  Future<void> _editAnnotationNote(UPdfAnnotationInfo annotation) async {
    final TextEditingController field = TextEditingController(text: annotation.contents);
    final String? value = await UNavigator.dialog<String>(
      AlertDialog(
        title: UTextTitleMedium(U.s.note),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back<String>, child: UTextBodyMedium(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back<String>(field.text), child: UTextBodyMedium(U.s.save)),
        ],
      ),
    );
    field.dispose();
    if (value == null) return;
    await editor?.updateAnnotation(annotation.pageIndex, annotation.objectNumber, contents: value);
    if (mounted) setState(() => _selectedAnnotation = null);
  }

  Future<void> _deleteSelectedAnnotation(UPdfAnnotationInfo annotation) async {
    await editor?.deleteAnnotation(annotation.pageIndex, annotation.objectNumber);
    if (mounted) setState(() => _selectedAnnotation = null);
  }

  Future<void> _applyMarkup() async {
    final UPdfEditController? target = editor;
    if (target == null || _selection.isEmpty) return;
    final UDocTextPage text = await _textFor(_selection.pageIndex);
    await target.annotateSelection(_selection, text);
    if (!mounted) return;
    setState(() => _selection = UDocSelection.none);
  }

  Future<void> _askAnnotationText(UPdfEditController editor, int pageIndex, Offset point, {required bool freeText}) async {
    final TextEditingController field = TextEditingController();
    final String? value = await UNavigator.dialog<String>(
      AlertDialog(
        title: UTextTitleMedium(freeText ? U.s.textBox : U.s.note),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back<String>, child: UTextBodyMedium(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back<String>(field.text), child: UTextBodyMedium(U.s.save)),
        ],
      ),
    );
    field.dispose();
    if (value == null || value.trim().isEmpty) return;
    if (freeText) {
      await editor.addTextBox(pageIndex, point, value);
    } else {
      await editor.addNote(pageIndex, point, value);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _internalEditor?.removeListener(_onControllerChanged);
    _internalEditor?.dispose();
    _controller.removeListener(_onControllerChanged);
    _vertical.dispose();
    _horizontal.dispose();
    _pageController?.dispose();
    _searchField.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UDocValue value = _controller.value;
    final UDocViewSettings settings = _controller.settings;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () => unawaited(_copySelection()),
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true): () => unawaited(_copySelection()),
        const SingleActivator(LogicalKeyboardKey.escape): () => setState(() => _selection = UDocSelection.none),
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: UDocColorFilters.surfaceBackground(settings.colorMode),
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: _buildBody(value, settings)),
              if (settings.dim > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: settings.dim)),
                  ),
                ),
              if (widget.showToolbar && _chromeVisible) Positioned(left: 0, right: 0, top: 0, child: _buildToolbar(value)),
              if (widget.showBottomBar && _chromeVisible && value.isReady) Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar(value)),
              if (_selection.isNotEmpty) _buildSelectionToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(UDocValue value, UDocViewSettings settings) {
    if (value.state == UDocState.opening || value.state == UDocState.idle) return const Center(child: CircularProgressIndicator());
    if (value.hasError) return _buildError(value);
    if (value.pageCount == 0) return Center(child: UTextBodyMedium(U.s.noResults));
    return LayoutBuilder(
      key: _viewportKey,
      builder: (BuildContext context, BoxConstraints constraints) {
        _viewportWidth = constraints.maxWidth;
        _viewportHeight = constraints.maxHeight;
        _computeBaseScale();
        return GestureDetector(
          onScaleStart: (ScaleStartDetails details) => _pinchStart = _zoom,
          onScaleUpdate: (ScaleUpdateDetails details) {
            if (details.pointerCount < 2) return;
            _setZoom(_pinchStart * details.scale, focal: details.localFocalPoint);
          },
          onDoubleTapDown: (TapDownDetails details) => _setZoom(_zoom > 1.2 ? 1 : 2.5, focal: details.localPosition),
          onDoubleTap: () {},
          child: settings.isPaged ? _buildPaged(settings) : _buildContinuous(settings),
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
    final double contentWidth = _maxPageWidth();
    final Widget list = ListView.builder(
      controller: _vertical,
      scrollDirection: settings.isHorizontal ? Axis.horizontal : Axis.vertical,
      reverse: settings.isHorizontal && settings.isRtl,
      padding: EdgeInsets.symmetric(vertical: settings.isHorizontal ? 0 : settings.pageGap, horizontal: settings.isHorizontal ? settings.pageGap : 0),
      itemCount: _controller.pageCount,
      itemBuilder: (BuildContext context, int index) => _buildPageTile(index, settings),
    );
    if (settings.isHorizontal || contentWidth <= _viewportWidth) return list;
    return SingleChildScrollView(
      controller: _horizontal,
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: contentWidth, height: _viewportHeight, child: list),
    );
  }

  double _maxPageWidth() {
    double widest = 0;
    final int limit = _controller.pageCount < 64 ? _controller.pageCount : 64;
    for (int i = 0; i < limit; i++) {
      final double width = _controller.pageInfo(i).rotatedSize.width;
      if (width > widest) widest = width;
    }
    return widest * _baseScale * _zoom + 16;
  }

  Widget _buildPaged(UDocViewSettings settings) {
    _pageController ??= PageController(initialPage: _controller.value.pageIndex);
    return PageView.builder(
      controller: _pageController,
      scrollDirection: settings.scrollMode == UDocScrollMode.pagedHorizontal ? Axis.horizontal : Axis.vertical,
      reverse: settings.scrollMode == UDocScrollMode.pagedHorizontal && settings.isRtl,
      itemCount: _controller.pageCount,
      onPageChanged: (int index) {
        _visiblePage = index;
        _controller.goToPage(index);
        widget.onPageChanged?.call(index);
      },
      itemBuilder: (BuildContext context, int index) => Center(child: _buildPageTile(index, settings)),
    );
  }

  Widget _buildPageTile(int index, UDocViewSettings settings) {
    final UDocPageInfo info = _controller.pageInfo(index);
    final Size size = info.rotatedSize;
    final double scale = _baseScale * _zoom;
    final double width = size.width * scale;
    final double height = size.height * scale;
    final List<UDocSearchHit> hits = _controller.value.searchHits.where((UDocSearchHit hit) => hit.pageIndex == index).toList();
    final UPdfEditController? pageEditor = editor;
    final Widget page = UPdfPageView(
      controller: _controller,
      pageIndex: index,
      displayScale: scale,
      colorMode: settings.colorMode,
      highlights: hits,
      activeHit: _controller.value.currentHit?.pageIndex == index ? _controller.value.currentHit : null,
      selectionRects: _selection.pageIndex == index ? _selection.rects : const <Rect>[],
      onTap: (Offset point) => unawaited(_handleTap(index, point)),
      onLongPress: (Offset point) => unawaited(_selectWordAt(index, point)),
      onDragSelect: (Offset point) => unawaited(_extendSelection(index, point)),
      onSelectStart: (Offset point) => unawaited(_beginDragSelection(index, point)),
      onSelectUpdate: (Offset point) => unawaited(_extendSelection(index, point)),
      onHandleDrag: (bool isStart, Offset point) => unawaited(_adjustSelection(index, isStart, point)),
      showHandles: widget.allowSelection,
    );
    final UPdfAnnotationInfo? selectedAnnotation = _selectedAnnotation?.pageIndex == index ? _selectedAnnotation : null;
    final bool editing = pageEditor != null && pageEditor.tool != UPdfTool.select;
    final Widget layered = selectedAnnotation != null
        ? Stack(fit: StackFit.expand, children: <Widget>[page, _annotationOverlay(selectedAnnotation, info, scale)])
        : !editing
        ? page
        : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              page,
              _UPdfEditLayer(
                editor: pageEditor,
                pageIndex: index,
                displayScale: scale,
                onNoteRequested: (Offset point) => unawaited(_askAnnotationText(pageEditor, index, point, freeText: false)),
                onTextRequested: (Offset point) => unawaited(_askAnnotationText(pageEditor, index, point, freeText: true)),
              ),
            ],
          );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: settings.isHorizontal ? 0 : settings.pageGap / 2, horizontal: settings.isHorizontal ? settings.pageGap / 2 : 0),
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: UDocColorFilters.pageBackground(settings.colorMode),
              boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: layered,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar() => Positioned(
    left: 16,
    right: 16,
    bottom: 96,
    child: Center(
      child: Material(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextButton.icon(
                onPressed: () => unawaited(_copySelection()),
                icon: Icon(Icons.copy_rounded, size: 18, color: Theme.of(context).colorScheme.onInverseSurface),
                label: UTextBodySmall(U.s.copy, color: Theme.of(context).colorScheme.onInverseSurface),
              ),
              TextButton.icon(
                onPressed: () => unawaited(UShare.text(text: _selection.text)),
                icon: Icon(Icons.share_rounded, size: 18, color: Theme.of(context).colorScheme.onInverseSurface),
                label: UTextBodySmall(U.s.share, color: Theme.of(context).colorScheme.onInverseSurface),
              ),
              if (editor != null)
                TextButton.icon(
                  onPressed: () => unawaited(_applyMarkup()),
                  icon: Icon(Icons.format_color_fill_rounded, size: 18, color: Theme.of(context).colorScheme.onInverseSurface),
                  label: UTextBodySmall(U.s.highlight, color: Theme.of(context).colorScheme.onInverseSurface),
                ),
              TextButton.icon(
                onPressed: () {
                  _searchField.text = _selection.text;
                  setState(() {
                    _searchOpen = true;
                    _selection = UDocSelection.none;
                  });
                  unawaited(_controller.search(_searchField.text));
                },
                icon: Icon(Icons.search_rounded, size: 18, color: Theme.of(context).colorScheme.onInverseSurface),
                label: UTextBodySmall(U.s.search, color: Theme.of(context).colorScheme.onInverseSurface),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

extension _UPdfViewerChrome on UPdfViewerState {
  Widget _buildToolbar(UDocValue value) => Material(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
    elevation: 2,
    child: SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(icon: const Icon(Icons.menu_book_rounded), tooltip: U.s.outline, onPressed: () => unawaited(_openOutline())),
              IconButton(icon: const Icon(Icons.grid_view_rounded), tooltip: U.s.thumbnails, onPressed: () => unawaited(_openThumbnails())),
              Expanded(
                child: UTextTitleSmall(
                  value.metadata.displayTitle.isEmpty ? "${U.s.page} ${_visiblePage + 1}" : value.metadata.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded), tooltip: U.s.search, onPressed: _toggleSearch),
              if (editor != null)
                IconButton(
                  icon: Icon(_toolsOpen ? Icons.edit_off_rounded : Icons.edit_rounded),
                  tooltip: U.s.edit,
                  isSelected: _toolsOpen,
                  onPressed: () {
                    editor?.attach();
                    applyState(() {
                      _toolsOpen = !_toolsOpen;
                      if (!_toolsOpen) editor?.setTool(UPdfTool.select);
                    });
                  },
                ),
              IconButton(icon: const Icon(Icons.tune_rounded), tooltip: U.s.settings, onPressed: () => unawaited(_openSettings())),
              if (editor != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: U.s.tools,
                  onSelected: (String value) {
                    if (value == "annotations") unawaited(_openAnnotations());
                    if (value == "pages") unawaited(_openPages());
                    if (value == "tools") unawaited(_openTools());
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: "annotations", child: UTextBodyMedium(U.s.annotations)),
                    PopupMenuItem<String>(value: "pages", child: UTextBodyMedium(U.s.pages)),
                    PopupMenuItem<String>(value: "tools", child: UTextBodyMedium(U.s.tools)),
                  ],
                ),
            ],
          ),
          if (_searchOpen) _buildSearchBar(value),
          if (_toolsOpen && editor != null) _buildToolsRow(editor!),
        ],
      ),
    ),
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
          IconButton(icon: const Icon(Icons.palette_outlined), tooltip: U.s.color, onPressed: () => unawaited(_pickAnnotationColor(target))),
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
      onPressed: () => target.setTool(target.tool == tool ? UPdfTool.select : tool),
    ),
  );

  Future<void> _pickAnnotationColor(UPdfEditController target) async {
    const List<Color> palette = <Color>[
      Color(0xFFFFEB3B),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFE91E63),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFFE53935),
      Color(0xFF000000),
    ];
    await UNavigator.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: palette
                .map(
                  (Color color) => InkWell(
                    onTap: () {
                      target.setColor(color);
                      target.setInkColor(color);
                      UNavigator.back<void>();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x33000000)),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDocument(UPdfEditController target) async {
    final String? path = widget.savePath ?? widget.filePath;
    applyState(() => _saving = true);
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
    applyState(() => _saving = false);
    if (saved) {
      UToast.successToast(message: U.s.saved);
    } else {
      UToast.errorToast(message: U.s.couldNotOpenTheDocument);
    }
  }

  void _toggleSearch() {
    applyState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchField.clear();
      _controller.clearSearch();
    }
  }

  Widget _buildSearchBar(UDocValue value) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _searchField,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(isDense: true, hintText: U.s.search, border: const OutlineInputBorder()),
            onSubmitted: (String query) => unawaited(_controller.search(query)),
          ),
        ),
        const SizedBox(width: 8),
        if (value.isSearching) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        if (!value.isSearching && value.searchHits.isNotEmpty) UTextBodySmall("${value.searchHitIndex + 1}/${value.searchHits.length}"),
        if (!value.isSearching && value.searchHits.isEmpty && value.searchQuery.isNotEmpty) UTextBodySmall(U.s.noResults),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          onPressed: () {
            _controller.previousHit();
            _jumpToPage(_controller.value.currentHit?.pageIndex ?? _visiblePage);
          },
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () {
            _controller.nextHit();
            _jumpToPage(_controller.value.currentHit?.pageIndex ?? _visiblePage);
          },
        ),
      ],
    ),
  );

  Widget _buildBottomBar(UDocValue value) => Material(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
    elevation: 2,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: <Widget>[
            IconButton(icon: const Icon(Icons.zoom_out_rounded), tooltip: U.s.zoomOut, onPressed: () => _setZoom(_zoom / 1.25)),
            IconButton(icon: const Icon(Icons.zoom_in_rounded), tooltip: U.s.zoomIn, onPressed: () => _setZoom(_zoom * 1.25)),
            Expanded(
              child: Slider(
                value: (_visiblePage + 1).toDouble().clamp(1, value.pageCount.toDouble()),
                min: 1,
                max: value.pageCount.toDouble() < 1 ? 1 : value.pageCount.toDouble(),
                onChanged: (double next) {
                  applyState(() => _visiblePage = next.round() - 1);
                  _jumpToPage(_visiblePage, animated: false);
                },
              ),
            ),
            TextButton(onPressed: () => unawaited(_askPageNumber(value)), child: UTextBodySmall("${_visiblePage + 1} / ${value.pageCount}")),
          ],
        ),
      ),
    ),
  );

  Future<void> _askPageNumber(UDocValue value) async {
    final TextEditingController field = TextEditingController(text: "${_visiblePage + 1}");
    final String? result = await UNavigator.dialog<String>(
      AlertDialog(
        title: UTextTitleMedium(U.s.goToPage),
        content: TextField(controller: field, keyboardType: TextInputType.number, autofocus: true, onSubmitted: UNavigator.back<String>),
        actions: <Widget>[
          TextButton(onPressed: UNavigator.back<String>, child: UTextBodyMedium(U.s.cancel)),
          TextButton(onPressed: () => UNavigator.back<String>(field.text), child: UTextBodyMedium(U.s.goToPage)),
        ],
      ),
    );
    field.dispose();
    final int? page = int.tryParse((result ?? "").toLatinNumber().trim());
    if (page == null) return;
    _jumpToPage(page - 1);
  }

  Future<void> _openOutline() async {
    await UNavigator.bottomSheet<void>(
      UPdfOutlinePanel(
        controller: _controller,
        onSelected: (UDocDestination destination) {
          UNavigator.back<void>();
          _jumpToPage(destination.pageIndex);
        },
      ),
    );
  }

  Future<void> _openThumbnails() async {
    await UNavigator.bottomSheet<void>(
      UPdfThumbnailPanel(
        controller: _controller,
        currentPage: _visiblePage,
        onSelected: (int index) {
          UNavigator.back<void>();
          _jumpToPage(index);
        },
      ),
    );
  }

  Future<void> _openAnnotations() async {
    final UPdfEditController? target = editor;
    if (target == null) return;
    await UNavigator.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: UPdfAnnotationsPanel(editor: target, onJump: _jumpToPage),
      ),
    );
    applyState(() {});
  }

  Future<void> _openPages() async {
    final UPdfEditController? target = editor;
    if (target == null) return;
    await UNavigator.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: UPdfPageManagerPanel(viewer: _controller, editor: target, onJump: _jumpToPage),
      ),
    );
    applyState(() {});
  }

  Future<void> _openTools() async {
    final UPdfEditController? target = editor;
    if (target == null) return;
    await UNavigator.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: UPdfDocumentToolsPanel(viewer: _controller, editor: target),
      ),
    );
    applyState(() {});
  }

  Future<void> _openSettings() async {
    await UNavigator.bottomSheet<void>(
      UPdfSettingsPanel(
        controller: _controller,
        onChanged: () {
          if (mounted) applyState(() {});
        },
      ),
    );
  }
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
    this.showHandles = true,
    this.onTap,
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
  final bool showHandles;
  final void Function(Offset point)? onTap;
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
  static const Set<PointerDeviceKind> _pointerDevices = <PointerDeviceKind>{PointerDeviceKind.mouse, PointerDeviceKind.stylus, PointerDeviceKind.trackpad, PointerDeviceKind.invertedStylus};
  static const Set<PointerDeviceKind> _touchDevices = <PointerDeviceKind>{PointerDeviceKind.touch, PointerDeviceKind.stylus};

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
    final Rect first = widget.selectionRects.first;
    return Offset(first.left * widget.displayScale, first.bottom * widget.displayScale);
  }

  Offset? get _endHandle {
    if (widget.selectionRects.isEmpty) return null;
    final Rect last = widget.selectionRects.last;
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
        : CustomPaint(
            painter: _UPdfPagePainter(
              picture: picture,
              scale: widget.displayScale,
              highlights: widget.highlights,
              activeHit: widget.activeHit,
              selectionRects: widget.selectionRects,
              highlightColor: const Color(0x66FFC107),
              activeColor: const Color(0x99FF9800),
              selectionColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
            ),
            isComplex: true,
            size: Size.infinite,
          );
    final ColorFilter? filter = UDocColorFilters.forMode(widget.colorMode);
    final Widget filtered = filter == null ? content : ColorFiltered(colorFilter: filter, child: content);
    final Offset? start = _startHandle;
    final Offset? end = _endHandle;
    final Widget gestures = RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          TapGestureRecognizer.new,
          (TapGestureRecognizer instance) {
            instance.onTapUp = (TapUpDetails details) => widget.onTap?.call(_toPagePoint(details.localPosition));
          },
        ),
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(supportedDevices: _touchDevices),
          (LongPressGestureRecognizer instance) {
            instance.onLongPressStart = (LongPressStartDetails details) => widget.onLongPress?.call(_toPagePoint(details.localPosition));
            instance.onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) => widget.onDragSelect?.call(_toPagePoint(details.localPosition));
            instance.onLongPressEnd = (LongPressEndDetails details) => widget.onSelectEnd?.call();
          },
        ),
        PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(supportedDevices: _pointerDevices),
          (PanGestureRecognizer instance) {
            instance.onStart = (DragStartDetails details) => widget.onSelectStart?.call(_toPagePoint(details.localPosition));
            instance.onUpdate = (DragUpdateDetails details) => widget.onSelectUpdate?.call(_toPagePoint(details.localPosition));
            instance.onEnd = (DragEndDetails details) => widget.onSelectEnd?.call();
          },
        ),
      },
      child: filtered,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.text,
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
  const _UPdfPagePainter({
    required this.picture,
    required this.scale,
    required this.highlights,
    required this.activeHit,
    required this.selectionRects,
    required this.highlightColor,
    required this.activeColor,
    required this.selectionColor,
  });

  final ui.Picture picture;
  final double scale;
  final List<UDocSearchHit> highlights;
  final UDocSearchHit? activeHit;
  final List<Rect> selectionRects;
  final Color highlightColor;
  final Color activeColor;
  final Color selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(scale);
    canvas.drawPicture(picture);
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
  bool shouldRepaint(_UPdfPagePainter oldDelegate) =>
      oldDelegate.picture != picture ||
      oldDelegate.scale != scale ||
      oldDelegate.highlights.length != highlights.length ||
      oldDelegate.activeHit != activeHit ||
      oldDelegate.selectionRects.length != selectionRects.length;
}

class UPdfOutlinePanel extends StatelessWidget {
  const UPdfOutlinePanel({required this.controller, required this.onSelected, super.key});

  final UPdfController controller;
  final void Function(UDocDestination destination) onSelected;

  List<Widget> _build(BuildContext context, List<UDocOutlineNode> nodes, int depth) {
    final List<Widget> widgets = <Widget>[];
    for (final UDocOutlineNode node in nodes) {
      widgets.add(
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: 16 + depth * 16, right: 16),
          title: UTextBodyMedium(node.title, maxLines: 2, overflow: TextOverflow.ellipsis, fontWeight: node.bold ? FontWeight.bold : null, fontStyle: node.italic ? FontStyle.italic : null),
          trailing: node.destination == null ? null : UTextBodySmall("${node.destination!.pageIndex + 1}"),
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
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: <Widget>[
          Padding(padding: const EdgeInsets.all(16), child: UTextTitleMedium(U.s.outline)),
          Expanded(
            child: nodes.isEmpty ? Center(child: UTextBodyMedium(U.s.noResults)) : ListView(children: _build(context, nodes, 0)),
          ),
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
  const UPdfSettingsPanel({required this.controller, required this.onChanged, super.key});

  final UPdfController controller;
  final VoidCallback onChanged;

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
      case UDocScrollMode.pagedHorizontal:
        return U.s.paged;
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
            Wrap(
              spacing: 8,
              children: <UDocScrollMode>[UDocScrollMode.verticalContinuous, UDocScrollMode.horizontalContinuous, UDocScrollMode.pagedHorizontal, UDocScrollMode.pagedVertical]
                  .map(
                    (UDocScrollMode mode) => ChoiceChip(
                      selected: settings.scrollMode == mode,
                      label: UTextBodySmall(_scrollLabel(mode)),
                      onSelected: (bool _) => _update(settings.copyWith(scrollMode: mode)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            UTextTitleMedium(U.s.theme),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <UDocColorMode>[UDocColorMode.normal, UDocColorMode.night, UDocColorMode.sepia, UDocColorMode.grayscale, UDocColorMode.highContrast]
                  .map(
                    (UDocColorMode mode) => ChoiceChip(
                      selected: settings.colorMode == mode,
                      label: UTextBodySmall(_colorLabel(mode)),
                      onSelected: (bool _) => _update(settings.copyWith(colorMode: mode)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            UTextTitleMedium(U.s.pageDirection),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <UDocDirection>[UDocDirection.ltr, UDocDirection.rtl]
                  .map(
                    (UDocDirection direction) => ChoiceChip(
                      selected: settings.direction == direction,
                      label: UTextBodySmall(direction == UDocDirection.rtl ? U.s.rightToLeft : U.s.leftToRight),
                      onSelected: (bool _) => _update(settings.copyWith(direction: direction)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            UTextTitleMedium(U.s.brightness),
            Slider(
              value: 1 - settings.dim,
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.cropMargins,
              title: UTextBodyMedium(U.s.cropMargins),
              onChanged: (bool next) => _update(settings.copyWith(cropMargins: next)),
            ),
            const SizedBox(height: 8),
            UTextTitleMedium(U.s.documentInfo),
            const SizedBox(height: 8),
            _infoRow(U.s.title, widget.controller.value.metadata.displayTitle),
            _infoRow(U.s.author, widget.controller.value.metadata.author ?? ""),
            _infoRow(U.s.pages, "${widget.controller.value.pageCount}"),
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
  static Future<void> show({String? base64Pdf, Uint8List? bytes, String? url, String? filePath, String? asset, String password = "", int initialPage = 0}) => UNavigator.bottomSheet<void>(
    UScaffold(
      body: SizedBox(
        width: MediaQuery.sizeOf(navigatorKey.currentContext!).width,
        height: MediaQuery.sizeOf(navigatorKey.currentContext!).height * 0.92,
        child: UPdfViewer(base64Pdf: base64Pdf, bytes: bytes, url: url, filePath: filePath, asset: asset, password: password, initialPage: initialPage),
      ),
    ),
  );

  static Future<void> open({String? base64Pdf, Uint8List? bytes, String? url, String? filePath, String? asset, String password = "", int initialPage = 0}) => UNavigator.push<void>(
    UScaffold(
      body: UPdfViewer(base64Pdf: base64Pdf, bytes: bytes, url: url, filePath: filePath, asset: asset, password: password, initialPage: initialPage),
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
