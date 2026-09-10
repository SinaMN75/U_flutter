import "package:u/utilities.dart";

enum UPdfTool { select, highlight, underline, strikeOut, ink, eraser, note, textBox, rectangle, ellipse, arrow, redact }

class UPdfEditController extends ChangeNotifier {
  UPdfEditController({required this.viewer});

  final UPdfController viewer;

  UPdfEdit? _edit;
  UPdfTool _tool = UPdfTool.select;
  Color _color = const Color(0xFFFFEB3B);
  Color _inkColor = const Color(0xFFE53935);
  double _strokeWidth = 2.5;
  double _opacity = 0.4;
  double _fontSize = 14;
  String _author = "";
  final List<int> _undoStack = <int>[];
  final Map<int, List<Offset>> _liveStrokes = <int, List<Offset>>{};

  UPdfTool get tool => _tool;

  Color get color => _color;

  Color get inkColor => _inkColor;

  double get strokeWidth => _strokeWidth;

  double get opacity => _opacity;

  double get fontSize => _fontSize;

  String get author => _author;

  bool get isDrawing => _tool == UPdfTool.ink || _tool == UPdfTool.rectangle || _tool == UPdfTool.ellipse || _tool == UPdfTool.arrow || _tool == UPdfTool.redact;

  bool get hasChanges => _edit?.hasChanges ?? false;

  bool get canUndo => _undoStack.isNotEmpty;

  UPdfEdit? get edit => _edit;

  List<Offset> liveStroke(int pageIndex) => _liveStrokes[pageIndex] ?? const <Offset>[];

  void attach() {
    final UPdfDocument? document = viewer.document;
    if (document == null) return;
    _edit ??= UPdfEdit(document);
  }

  void setTool(UPdfTool tool) {
    _tool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setInkColor(Color color) {
    _inkColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setOpacity(double opacity) {
    _opacity = opacity.clamp(0.05, 1).toDouble();
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(6, 96).toDouble();
    notifyListeners();
  }

  void setAuthor(String author) {
    _author = author;
    notifyListeners();
  }

  Offset devicePointToPdf(UDocPageInfo info, Offset point) {
    final Rect box = info.cropBox ?? Rect.fromLTWH(0, 0, info.size.width, info.size.height);
    final List<double> matrix = uPdfInvert(uPdfBaseMatrix(box, info.rotation, 1));
    return uPdfApply(matrix, point.dx, point.dy);
  }

  Rect deviceRectToPdf(UDocPageInfo info, Rect rect) {
    final Offset a = devicePointToPdf(info, rect.topLeft);
    final Offset b = devicePointToPdf(info, rect.bottomRight);
    return Rect.fromLTRB(min(a.dx, b.dx), min(a.dy, b.dy), max(a.dx, b.dx), max(a.dy, b.dy));
  }

  void beginStroke(int pageIndex, Offset devicePoint) {
    _liveStrokes[pageIndex] = <Offset>[devicePoint];
    notifyListeners();
  }

  void extendStroke(int pageIndex, Offset devicePoint) {
    final List<Offset>? points = _liveStrokes[pageIndex];
    if (points == null) return;
    if (points.isNotEmpty && (points.last - devicePoint).distance < 1.5) return;
    points.add(devicePoint);
    notifyListeners();
  }

  Future<void> endStroke(int pageIndex) async {
    final List<Offset>? points = _liveStrokes.remove(pageIndex);
    notifyListeners();
    if (points == null || points.length < 2) return;
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return;
    final UDocPageInfo info = viewer.pageInfo(pageIndex);
    final List<Offset> converted = points.map((Offset point) => devicePointToPdf(info, point)).toList();
    double left = converted.first.dx;
    double right = converted.first.dx;
    double top = converted.first.dy;
    double bottom = converted.first.dy;
    for (final Offset point in converted) {
      left = min(left, point.dx);
      right = max(right, point.dx);
      top = min(top, point.dy);
      bottom = max(bottom, point.dy);
    }
    final Rect bounds = Rect.fromLTRB(left, top, right, bottom).inflate(_strokeWidth + 2);
    int number = -1;
    switch (_tool) {
      case UPdfTool.ink:
        number = await edit.addAnnotation(
          pageIndex,
          UPdfAnnotationSpec(style: UPdfAnnotationStyle.ink, rect: bounds, inkPaths: <List<Offset>>[converted], color: _inkColor, borderColor: _inkColor, borderWidth: _strokeWidth, author: _author),
        );
        break;
      case UPdfTool.rectangle:
        number = await edit.addAnnotation(
          pageIndex,
          UPdfAnnotationSpec(style: UPdfAnnotationStyle.square, rect: bounds, color: const Color(0x00000000), borderColor: _inkColor, borderWidth: _strokeWidth, author: _author),
        );
        break;
      case UPdfTool.ellipse:
        number = await edit.addAnnotation(
          pageIndex,
          UPdfAnnotationSpec(style: UPdfAnnotationStyle.circle, rect: bounds, color: const Color(0x00000000), borderColor: _inkColor, borderWidth: _strokeWidth, author: _author),
        );
        break;
      case UPdfTool.arrow:
        number = await edit.addAnnotation(
          pageIndex,
          UPdfAnnotationSpec(
            style: UPdfAnnotationStyle.arrow,
            rect: Rect.fromPoints(converted.first, converted.last),
            color: _inkColor,
            borderColor: _inkColor,
            borderWidth: _strokeWidth,
            author: _author,
          ),
        );
        break;
      case UPdfTool.redact:
        number = await edit.addAnnotation(pageIndex, UPdfAnnotationSpec(style: UPdfAnnotationStyle.redact, rect: bounds, color: const Color(0xFF000000), author: _author));
        break;
      case UPdfTool.select:
      case UPdfTool.highlight:
      case UPdfTool.underline:
      case UPdfTool.strikeOut:
      case UPdfTool.eraser:
      case UPdfTool.note:
      case UPdfTool.textBox:
        return;
    }
    if (number > 0) _undoStack.add(number);
    viewer.invalidatePage(pageIndex);
    notifyListeners();
  }

  Future<bool> annotateSelection(UDocSelection selection, UDocTextPage text) async {
    if (selection.isEmpty) return false;
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final UDocPageInfo info = viewer.pageInfo(selection.pageIndex);
    final List<Rect> quads = selection.rects.map((Rect rect) => deviceRectToPdf(info, rect)).toList();
    if (quads.isEmpty) return false;
    Rect bounds = quads.first;
    for (final Rect quad in quads) {
      bounds = bounds.expandToInclude(quad);
    }
    final UPdfAnnotationStyle style;
    switch (_tool) {
      case UPdfTool.underline:
        style = UPdfAnnotationStyle.underline;
        break;
      case UPdfTool.strikeOut:
        style = UPdfAnnotationStyle.strikeOut;
        break;
      case UPdfTool.redact:
        style = UPdfAnnotationStyle.redact;
        break;
      default:
        style = UPdfAnnotationStyle.highlight;
        break;
    }
    final int number = await edit.addAnnotation(
      selection.pageIndex,
      UPdfAnnotationSpec(style: style, rect: bounds.inflate(1), quads: quads, color: _color, opacity: _opacity, contents: selection.text, author: _author, rtl: UDocText.isRtl(selection.text)),
    );
    if (number > 0) _undoStack.add(number);
    viewer.invalidatePage(selection.pageIndex);
    notifyListeners();
    return number > 0;
  }

  Future<bool> addNote(int pageIndex, Offset devicePoint, String contents) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final UDocPageInfo info = viewer.pageInfo(pageIndex);
    final Offset origin = devicePointToPdf(info, devicePoint);
    final int number = await edit.addAnnotation(
      pageIndex,
      UPdfAnnotationSpec(style: UPdfAnnotationStyle.note, rect: Rect.fromLTWH(origin.dx, origin.dy - 22, 22, 22), color: _color, contents: contents, author: _author),
    );
    if (number > 0) _undoStack.add(number);
    viewer.invalidatePage(pageIndex);
    notifyListeners();
    return number > 0;
  }

  Future<bool> addTextBox(int pageIndex, Offset devicePoint, String contents, {double width = 200, double height = 60}) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final UDocPageInfo info = viewer.pageInfo(pageIndex);
    final Offset origin = devicePointToPdf(info, devicePoint);
    final int number = await edit.addAnnotation(
      pageIndex,
      UPdfAnnotationSpec(
        style: UPdfAnnotationStyle.freeText,
        rect: Rect.fromLTWH(origin.dx, origin.dy - height, width, height),
        color: const Color(0x00FFFFFF),
        borderColor: _inkColor,
        borderWidth: 1,
        contents: contents,
        fontSize: _fontSize,
        author: _author,
        rtl: UDocText.isRtl(contents),
      ),
    );
    if (number > 0) _undoStack.add(number);
    viewer.invalidatePage(pageIndex);
    notifyListeners();
    return number > 0;
  }

  Future<bool> eraseAt(int pageIndex, Offset devicePoint) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final UDocPageInfo info = viewer.pageInfo(pageIndex);
    final Offset point = devicePointToPdf(info, devicePoint);
    final List<UPdfAnnotationInfo> list = await edit.annotations(pageIndex);
    for (final UPdfAnnotationInfo annotation in list.reversed) {
      if (annotation.rect.inflate(2).contains(point)) {
        final bool removed = await edit.removeAnnotation(pageIndex, annotation.objectNumber);
        if (removed) {
          _undoStack.remove(annotation.objectNumber);
          viewer.invalidatePage(pageIndex);
          notifyListeners();
        }
        return removed;
      }
    }
    return false;
  }

  Future<void> undo() async {
    final UPdfEdit? edit = _edit;
    if (edit == null || _undoStack.isEmpty) return;
    final int number = _undoStack.removeLast();
    for (int page = 0; page < viewer.pageCount; page++) {
      final List<UPdfAnnotationInfo> list = await edit.annotations(page);
      if (list.any((UPdfAnnotationInfo info) => info.objectNumber == number)) {
        await edit.removeAnnotation(page, number);
        viewer.invalidatePage(page);
        break;
      }
    }
    notifyListeners();
  }

  Future<bool> rotatePage(int pageIndex, int degrees) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    await edit.rotatePage(pageIndex, degrees);
    viewer.invalidateAll();
    notifyListeners();
    return true;
  }

  Future<bool> deletePage(int pageIndex) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final bool done = await edit.deletePages(<int>[pageIndex]);
    if (done) viewer.invalidateAll();
    notifyListeners();
    return done;
  }

  Future<bool> duplicatePage(int pageIndex) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final bool done = await edit.duplicatePage(pageIndex);
    if (done) viewer.invalidateAll();
    notifyListeners();
    return done;
  }

  Future<bool> movePage(int from, int to) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final bool done = await edit.movePage(from, to);
    if (done) viewer.invalidateAll();
    notifyListeners();
    return done;
  }

  Future<bool> insertBlankPage(int at) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final bool done = await edit.insertBlankPage(at);
    if (done) viewer.invalidateAll();
    notifyListeners();
    return done;
  }

  Future<List<UPdfAnnotationInfo>> annotationsOn(int pageIndex) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return const <UPdfAnnotationInfo>[];
    return edit.annotations(pageIndex);
  }

  Future<List<UPdfAnnotationInfo>> allAnnotations() async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return const <UPdfAnnotationInfo>[];
    final List<UPdfAnnotationInfo> out = <UPdfAnnotationInfo>[];
    for (int page = 0; page < viewer.pageCount; page++) {
      out.addAll(await edit.annotations(page));
    }
    return out;
  }

  Future<UPdfAnnotationInfo?> annotationAt(int pageIndex, Offset devicePoint) async {
    final List<UPdfAnnotationInfo> list = await annotationsOn(pageIndex);
    final UDocPageInfo info = viewer.pageInfo(pageIndex);
    final Offset point = devicePointToPdf(info, devicePoint);
    for (final UPdfAnnotationInfo annotation in list.reversed) {
      if (annotation.rect.inflate(3).contains(point)) return annotation;
    }
    return null;
  }

  Future<bool> updateAnnotation(int pageIndex, int objectNumber, {Rect? rect, Color? color, double? opacity, String? contents}) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final bool done = await edit.updateAnnotation(pageIndex, objectNumber, rect: rect, color: color, opacity: opacity, contents: contents);
    if (done) {
      viewer.invalidatePage(pageIndex);
      notifyListeners();
    }
    return done;
  }

  Future<bool> deleteAnnotation(int pageIndex, int objectNumber) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final bool done = await edit.removeAnnotation(pageIndex, objectNumber);
    if (done) {
      _undoStack.remove(objectNumber);
      viewer.invalidatePage(pageIndex);
      notifyListeners();
    }
    return done;
  }

  Future<int> applyRedactions(int pageIndex, List<Rect> areas) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return 0;
    final int removed = await UPdfRedactor(edit).apply(pageIndex, areas);
    viewer.invalidatePage(pageIndex);
    notifyListeners();
    return removed;
  }

  Future<int> applyPendingRedactions() async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return 0;
    int removed = 0;
    for (int page = 0; page < viewer.pageCount; page++) {
      final List<UPdfAnnotationInfo> list = await edit.annotations(page);
      final List<Rect> areas = list.where((UPdfAnnotationInfo info) => info.subtype == "Square" && info.color == const Color(0xFF000000)).map((UPdfAnnotationInfo info) => info.rect).toList();
      if (areas.isEmpty) continue;
      for (final UPdfAnnotationInfo info in list.where((UPdfAnnotationInfo info) => info.subtype == "Square" && info.color == const Color(0xFF000000))) {
        await edit.removeAnnotation(page, info.objectNumber);
      }
      removed += await UPdfRedactor(edit).apply(page, areas);
      viewer.invalidatePage(page);
    }
    notifyListeners();
    return removed;
  }

  Future<int> flatten({bool widgetsOnly = false}) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return 0;
    final int count = await edit.flattenAnnotations(widgetsOnly: widgetsOnly);
    viewer.invalidateAll();
    notifyListeners();
    return count;
  }

  Future<bool> addWatermark(String text, {double fontSize = 48, Color color = const Color(0x33000000), double rotation = 45}) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    await edit.addTextWatermark(text, fontSize: fontSize, color: color, rotation: rotation);
    viewer.invalidateAll();
    notifyListeners();
    return true;
  }

  Future<bool> addPageNumbers({double fontSize = 10, int startAt = 1, bool rightAligned = true}) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    await edit.addPageNumbers(fontSize: fontSize, startAt: startAt, rightAligned: rightAligned);
    viewer.invalidateAll();
    notifyListeners();
    return true;
  }

  Future<bool> setMetadata(UDocMetadata metadata) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    await edit.setMetadata(metadata);
    notifyListeners();
    return true;
  }

  Future<bool> setCrop(int pageIndex, Rect box) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    await edit.setCropBox(pageIndex, box);
    viewer.invalidateAll();
    notifyListeners();
    return true;
  }

  Future<bool> mergeFile(String path) async {
    attach();
    final UPdfEdit? edit = _edit;
    final UPdfDocument? target = viewer.document;
    if (edit == null || target == null) return false;
    try {
      final UPdfDocument other = await UPdfDocument.open(path: path);
      final UPdfComposer composer = UPdfComposer();
      for (int i = 0; i < target.pageCount; i++) {
        await composer.addPage(target, i);
      }
      for (int i = 0; i < other.pageCount; i++) {
        await composer.addPage(other, i);
      }
      await other.close();
      final Uint8List bytes = composer.build(metadata: await target.metadata());
      await viewer.reopenWith(bytes);
      _edit = null;
      _undoStack.clear();
      attach();
      notifyListeners();
      return true;
    } on Object {
      return false;
    }
  }

  Future<Uint8List?> exportPages(List<int> indices) async {
    final UPdfDocument? target = viewer.document;
    if (target == null) return null;
    return UPdfOps.extractPages(target, indices);
  }

  Future<bool> saveOptimized(String path) async {
    attach();
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    return edit.saveOptimizedTo(path);
  }

  Future<bool> saveTo(String path) async {
    final UPdfEdit? edit = _edit;
    if (edit == null) return false;
    final bool saved = await edit.saveIncrementalTo(path);
    if (saved) {
      _undoStack.clear();
      notifyListeners();
    }
    return saved;
  }

  Future<Uint8List?> saveToBytes() async => _edit?.saveToBytes();
}

class UPdfEditorPage extends StatefulWidget {
  const UPdfEditorPage({
    this.filePath,
    this.bytes,
    this.url,
    this.asset,
    this.base64Pdf,
    this.password = "",
    this.author = "",
    this.savePath,
    this.onSaved,
    super.key,
  });

  final String? filePath;
  final Uint8List? bytes;
  final String? url;
  final String? asset;
  final String? base64Pdf;
  final String password;
  final String author;
  final String? savePath;
  final void Function(String path)? onSaved;

  @override
  State<UPdfEditorPage> createState() => _UPdfEditorPageState();
}

class _UPdfEditorPageState extends State<UPdfEditorPage> {
  final UPdfController _viewer = UPdfController();
  late final UPdfEditController _editor = UPdfEditController(viewer: _viewer);
  final GlobalKey<UPdfViewerState> _viewerKey = GlobalKey<UPdfViewerState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _editor.setAuthor(widget.author);
    _editor.addListener(_refresh);
    unawaited(_load());
  }

  Future<void> _load() async {
    await _viewer.open(
      path: widget.filePath,
      url: widget.url,
      bytes: widget.bytes ?? widget.base64Pdf?.toBytesFromBase64(),
      asset: widget.asset,
      password: widget.password,
    );
    _editor.attach();
    if (mounted) setState(() {});
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _editor.removeListener(_refresh);
    _editor.dispose();
    _viewer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String? path = widget.savePath ?? widget.filePath;
    if (path == null) {
      final Uint8List? bytes = await _editor.saveToBytes();
      if (bytes == null) {
        UToast.errorToast(message: U.s.couldNotOpenTheDocument);
        return;
      }
      await UShare.bytes(bytes: bytes, fileName: "document.pdf", mimeType: "application/pdf");
      return;
    }
    setState(() => _saving = true);
    final bool saved = await _editor.saveTo(path);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      UToast.successToast(message: U.s.saved);
      widget.onSaved?.call(path);
    } else {
      UToast.errorToast(message: U.s.couldNotOpenTheDocument);
    }
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    body: SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: UPdfViewer(
              key: _viewerKey,
              controller: _viewer,
              editController: _editor,
            ),
          ),
          _buildToolbar(),
        ],
      ),
    ),
  );

  Widget _buildToolbar() => Material(
    elevation: 6,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: <Widget>[
            _toolButton(UPdfTool.select, Icons.pan_tool_alt_outlined, U.s.select),
            _toolButton(UPdfTool.highlight, Icons.format_color_fill_rounded, U.s.highlight),
            _toolButton(UPdfTool.underline, Icons.format_underlined_rounded, U.s.underline),
            _toolButton(UPdfTool.strikeOut, Icons.format_strikethrough_rounded, U.s.strikeThrough),
            _toolButton(UPdfTool.ink, Icons.draw_rounded, U.s.draw),
            _toolButton(UPdfTool.rectangle, Icons.crop_square_rounded, U.s.rectangle),
            _toolButton(UPdfTool.ellipse, Icons.circle_outlined, U.s.ellipse),
            _toolButton(UPdfTool.arrow, Icons.north_east_rounded, U.s.arrow),
            _toolButton(UPdfTool.note, Icons.sticky_note_2_outlined, U.s.note),
            _toolButton(UPdfTool.textBox, Icons.title_rounded, U.s.textBox),
            _toolButton(UPdfTool.redact, Icons.hide_source_rounded, U.s.redact),
            _toolButton(UPdfTool.eraser, Icons.cleaning_services_rounded, U.s.erase),
            const VerticalDivider(width: 16),
            IconButton(icon: const Icon(Icons.palette_outlined), tooltip: U.s.color, onPressed: _pickColor),
            IconButton(icon: const Icon(Icons.undo_rounded), tooltip: U.s.undo, onPressed: _editor.canUndo ? () => unawaited(_editor.undo()) : null),
            IconButton(icon: const Icon(Icons.auto_stories_rounded), tooltip: U.s.pages, onPressed: () => unawaited(_openPageManager())),
            IconButton(icon: const Icon(Icons.list_alt_rounded), tooltip: U.s.forms, onPressed: () => unawaited(_openForms())),
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(icon: const Icon(Icons.save_rounded), tooltip: U.s.save, onPressed: _editor.hasChanges ? () => unawaited(_save()) : null),
          ],
        ),
      ),
    ),
  );

  Widget _toolButton(UPdfTool tool, IconData icon, String label) {
    final bool selected = _editor.tool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: label,
        isSelected: selected,
        icon: Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : null),
        onPressed: () => _editor.setTool(selected ? UPdfTool.select : tool),
      ),
    );
  }

  Future<void> _pickColor() async {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UTextTitleMedium(U.s.color),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: palette
                    .map(
                      (Color color) => InkWell(
                        onTap: () {
                          _editor.setColor(color);
                          _editor.setInkColor(color);
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
              const SizedBox(height: 16),
              UTextBodyMedium(U.s.thickness),
              Slider(value: _editor.strokeWidth, min: 1, max: 12, onChanged: _editor.setStrokeWidth),
              UTextBodyMedium(U.s.opacity),
              Slider(value: _editor.opacity, onChanged: _editor.setOpacity),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPageManager() async {
    await UNavigator.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: UPdfPageManager(viewer: _viewer, editor: _editor),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openForms() async {
    _editor.attach();
    final UPdfEdit? edit = _editor.edit;
    if (edit == null) return;
    final List<UPdfFormField> fields = await edit.formFields();
    if (!mounted) return;
    if (fields.isEmpty) {
      UToast.toast(message: U.s.noResults);
      return;
    }
    await UNavigator.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: UPdfFormPanel(edit: edit, fields: fields, onChanged: _viewer.invalidatePage),
      ),
    );
    if (mounted) setState(() {});
  }
}

class UPdfPageManager extends StatefulWidget {
  const UPdfPageManager({required this.viewer, required this.editor, super.key});

  final UPdfController viewer;
  final UPdfEditController editor;

  @override
  State<UPdfPageManager> createState() => _UPdfPageManagerState();
}

class _UPdfPageManagerState extends State<UPdfPageManager> {
  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(child: UTextTitleMedium(U.s.pages)),
            TextButton.icon(
              onPressed: () async {
                await widget.editor.insertBlankPage(widget.viewer.pageCount);
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.add_rounded),
              label: UTextBodySmall(U.s.add),
            ),
          ],
        ),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, childAspectRatio: 0.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: widget.viewer.pageCount,
          itemBuilder: (BuildContext context, int index) => Column(
            children: <Widget>[
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    color: const Color(0xFFFFFFFF),
                  ),
                  child: UPdfThumbnail(controller: widget.viewer, pageIndex: index),
                ),
              ),
              SizedBox(
                height: 34,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.rotate_right_rounded),
                      onPressed: () async {
                        await widget.editor.rotatePage(index, 90);
                        if (mounted) setState(() {});
                      },
                    ),
                    IconButton(
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () async {
                        await widget.editor.duplicatePage(index);
                        if (mounted) setState(() {});
                      },
                    ),
                    IconButton(
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        await widget.editor.deletePage(index);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              UTextBodySmall("${index + 1}"),
            ],
          ),
        ),
      ),
    ],
  );
}

class UPdfFormPanel extends StatefulWidget {
  const UPdfFormPanel({required this.edit, required this.fields, required this.onChanged, super.key});

  final UPdfEdit edit;
  final List<UPdfFormField> fields;
  final void Function(int pageIndex) onChanged;

  @override
  State<UPdfFormPanel> createState() => _UPdfFormPanelState();
}

class _UPdfFormPanelState extends State<UPdfFormPanel> {
  final Map<int, TextEditingController> _controllers = <int, TextEditingController>{};
  final Map<int, bool> _checks = <int, bool>{};

  @override
  void initState() {
    super.initState();
    for (final UPdfFormField field in widget.fields) {
      if (field.kind == UDocFieldKind.checkBox || field.kind == UDocFieldKind.radioButton) {
        _checks[field.objectNumber] = field.displayValue != "Off" && field.displayValue.isNotEmpty;
      } else {
        _controllers[field.objectNumber] = TextEditingController(text: field.displayValue);
      }
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Padding(padding: const EdgeInsets.all(16), child: UTextTitleMedium(U.s.forms)),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.fields.length,
          itemBuilder: (BuildContext context, int index) {
            final UPdfFormField field = widget.fields[index];
            if (field.kind == UDocFieldKind.checkBox || field.kind == UDocFieldKind.radioButton) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _checks[field.objectNumber] ?? false,
                title: UTextBodyMedium(field.name.isEmpty ? "${U.s.field} ${index + 1}" : field.name),
                onChanged: field.readOnly
                    ? null
                    : (bool next) async {
                        setState(() => _checks[field.objectNumber] = next);
                        await widget.edit.setFieldValue(field, next);
                        widget.onChanged(field.pageIndex);
                      },
              );
            }
            if (field.kind == UDocFieldKind.comboBox && field.options.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: DropdownButtonFormField<String>(
                  initialValue: field.options.contains(field.displayValue) ? field.displayValue : null,
                  decoration: InputDecoration(labelText: field.name, border: const OutlineInputBorder()),
                  items: field.options.map((String option) => DropdownMenuItem<String>(value: option, child: UTextBodyMedium(option))).toList(),
                  onChanged: field.readOnly
                      ? null
                      : (String? next) async {
                          await widget.edit.setFieldValue(field, next);
                          widget.onChanged(field.pageIndex);
                        },
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: _controllers[field.objectNumber],
                readOnly: field.readOnly,
                maxLength: field.maxLength > 0 ? field.maxLength : null,
                decoration: InputDecoration(labelText: field.name.isEmpty ? "${U.s.field} ${index + 1}" : field.name, border: const OutlineInputBorder()),
                onChanged: (String next) => unawaited(widget.edit.setFieldValue(field, next)),
                onEditingComplete: () => widget.onChanged(field.pageIndex),
              ),
            );
          },
        ),
      ),
    ],
  );
}
