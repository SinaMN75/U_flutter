import "package:u/utilities.dart";
import "dart:ui" as ui;

class USignaturePoint {
  const USignaturePoint(this.offset, this.width);

  final Offset offset;
  final double width;
}

class USignatureStroke {
  USignatureStroke({required this.color, required this.points});

  final Color color;
  final List<USignaturePoint> points;
}

/// Controls and holds the state of a [USignaturePadRaw]. Strokes get a
/// velocity-variable width for a natural pen feel, and can be undone, redone,
/// cleared and exported to a PNG.
class USignatureController extends ChangeNotifier {
  USignatureController({this._penColor = const Color(0xFF1A1A1A), this.minWidth = 1.5, this.maxWidth = 4.5, this.velocityScale = 1.6});

  Color _penColor;
  double minWidth;
  double maxWidth;

  /// Pen velocity (logical px/ms) at which the stroke reaches [minWidth].
  final double velocityScale;

  final List<USignatureStroke> _strokes = <USignatureStroke>[];
  final List<USignatureStroke> _redo = <USignatureStroke>[];
  USignatureStroke? _active;
  double _lastWidth = 0;
  Size canvasSize = Size.zero;

  Color get penColor => _penColor;

  set penColor(Color value) {
    if (value == _penColor) return;
    _penColor = value;
    notifyListeners();
  }

  List<USignatureStroke> get strokes => _strokes;
  USignatureStroke? get activeStroke => _active;
  bool get isEmpty => _strokes.isEmpty && _active == null;
  bool get isNotEmpty => !isEmpty;
  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void beginStroke(Offset point) {
    _redo.clear();
    _lastWidth = (minWidth + maxWidth) / 2;
    _active = USignatureStroke(color: _penColor, points: <USignaturePoint>[USignaturePoint(point, _lastWidth)]);
    notifyListeners();
  }

  void extendStroke(Offset point, double speed) {
    final USignatureStroke? stroke = _active;
    if (stroke == null) return;
    final double factor = (speed / velocityScale).clamp(0.0, 1.0);
    final double target = maxWidth - (maxWidth - minWidth) * factor;
    _lastWidth += (target - _lastWidth) * 0.4;
    stroke.points.add(USignaturePoint(point, _lastWidth));
    notifyListeners();
  }

  void commitStroke() {
    final USignatureStroke? stroke = _active;
    if (stroke == null) return;
    _strokes.add(stroke);
    _active = null;
    notifyListeners();
  }

  void clear() {
    if (isEmpty) return;
    _strokes.clear();
    _redo.clear();
    _active = null;
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _redo.add(_strokes.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _strokes.add(_redo.removeLast());
    notifyListeners();
  }

  Future<Uint8List?> toPngBytes({double pixelRatio = 3, Color? background}) async {
    if (canvasSize.isEmpty) return null;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(pixelRatio);
    if (background != null) canvas.drawRect(Offset.zero & canvasSize, Paint()..color = background);
    for (final USignatureStroke stroke in _strokes) {
      _USignaturePainter.paintStroke(canvas, stroke);
    }
    final ui.Image image = await recorder.endRecording().toImage((canvasSize.width * pixelRatio).round(), (canvasSize.height * pixelRatio).round());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}

class _USignaturePainter extends CustomPainter {
  _USignaturePainter(this.controller, {this.baselineColor}) : super(repaint: controller);

  final USignatureController controller;
  final Color? baselineColor;

  static void paintStroke(Canvas canvas, USignatureStroke stroke) {
    final List<USignaturePoint> points = stroke.points;
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawCircle(points.first.offset, points.first.width / 2, Paint()..color = stroke.color..isAntiAlias = true);
      return;
    }
    final Paint paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    for (int i = 0; i < points.length - 1; i++) {
      paint.strokeWidth = (points[i].width + points[i + 1].width) / 2;
      canvas.drawLine(points[i].offset, points[i + 1].offset, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    controller.canvasSize = size;
    if (baselineColor != null) {
      final double y = size.height * 0.8;
      final Paint dash = Paint()
        ..color = baselineColor!
        ..strokeWidth = 1;
      for (double x = 16; x < size.width - 16; x += 12) {
        canvas.drawLine(Offset(x, y), Offset(x + 6, y), dash);
      }
    }
    for (final USignatureStroke stroke in controller.strokes) {
      paintStroke(canvas, stroke);
    }
    final USignatureStroke? active = controller.activeStroke;
    if (active != null) paintStroke(canvas, active);
  }

  @override
  bool shouldRepaint(covariant _USignaturePainter old) => old.controller != controller || old.baselineColor != baselineColor;
}

/// The bare drawing surface: captures pointer input and paints the strokes.
class USignaturePadRaw extends StatefulWidget {
  const USignaturePadRaw({required this.controller, this.baselineColor, this.onStrokeStart, this.onStrokeEnd, super.key});

  final USignatureController controller;
  final Color? baselineColor;
  final VoidCallback? onStrokeStart;
  final VoidCallback? onStrokeEnd;

  @override
  State<USignaturePadRaw> createState() => _USignaturePadRawState();
}

class _USignaturePadRawState extends State<USignaturePadRaw> {
  Offset? _lastPos;
  Duration? _lastTime;

  void _start(Offset p, Duration t) {
    _lastPos = p;
    _lastTime = t;
    widget.controller.beginStroke(p);
    widget.onStrokeStart?.call();
  }

  void _update(Offset p, Duration t) {
    double speed = 0;
    if (_lastPos != null) {
      final double distance = (p - _lastPos!).distance;
      final double dt = _lastTime == null ? 16 : (t - _lastTime!).inMicroseconds / 1000.0;
      speed = distance / (dt <= 0 ? 16 : dt);
    }
    _lastPos = p;
    _lastTime = t;
    widget.controller.extendStroke(p, speed);
  }

  void _end() {
    widget.controller.commitStroke();
    widget.onStrokeEnd?.call();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: GestureDetector(
      onPanStart: (DragStartDetails d) => _start(d.localPosition, d.sourceTimeStamp ?? Duration.zero),
      onPanUpdate: (DragUpdateDetails d) => _update(d.localPosition, d.sourceTimeStamp ?? Duration.zero),
      onPanEnd: (DragEndDetails _) => _end(),
      child: CustomPaint(
        painter: _USignaturePainter(widget.controller, baselineColor: widget.baselineColor),
        size: Size.infinite,
      ),
    ),
  );
}

/// A fully featured, pure-Dart signature pad: velocity-variable strokes, undo /
/// redo / clear, an optional colour picker and width slider, and PNG export.
/// Fires [onSave] with the captured PNG whenever a stroke completes.
class USignaturePad extends StatefulWidget {
  const USignaturePad({
    required this.onSave,
    super.key,
    this.onDraw,
    this.saveButtonText,
    this.clearButtonText,
    this.emptyMessage,
    this.controller,
    this.backgroundColor,
    this.strokeColor,
    this.penColors,
    this.minWidth = 1.5,
    this.maxWidth = 4.5,
    this.height = 220,
    this.showToolbar = true,
    this.showColorPicker = true,
    this.showWidthSlider = false,
    this.showBaseline = true,
    this.exportPixelRatio = 3,
    this.exportBackground,
  });

  final Function(FileData) onSave;
  final Function(FileData)? onDraw;
  final String? saveButtonText;
  final String? clearButtonText;
  final String? emptyMessage;
  final USignatureController? controller;
  final Color? backgroundColor;
  final Color? strokeColor;
  final List<Color>? penColors;
  final double minWidth;
  final double maxWidth;
  final double height;
  final bool showToolbar;
  final bool showColorPicker;
  final bool showWidthSlider;
  final bool showBaseline;
  final double exportPixelRatio;
  final Color? exportBackground;

  @override
  State<USignaturePad> createState() => _USignaturePadState();
}

class _USignaturePadState extends State<USignaturePad> {
  late USignatureController _controller;
  bool _ownsController = false;
  bool _themedPen = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? USignatureController(penColor: widget.strokeColor ?? const Color(0xFF1A1A1A), minWidth: widget.minWidth, maxWidth: widget.maxWidth);
    _ownsController = widget.controller == null;
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ownsController && widget.strokeColor == null && !_themedPen) {
      _controller.penColor = Theme.of(context).colorScheme.onSurface;
      _themedPen = true;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    if (_controller.isEmpty) return;
    final Uint8List? bytes = await _controller.toPngBytes(pixelRatio: widget.exportPixelRatio, background: widget.exportBackground);
    if (bytes == null) return;
    final FileData file = FileData(bytes: bytes, extension: "png");
    widget.onSave(file);
    widget.onDraw?.call(file);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color background = widget.backgroundColor ?? scheme.surface;
    final List<Color> palette = widget.penColors ?? <Color>[scheme.onSurface, Colors.blue.shade700, Colors.red.shade700];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(color: background),
              child: USignaturePadRaw(
                controller: _controller,
                baselineColor: widget.showBaseline ? scheme.onSurface.withValues(alpha: 0.18) : null,
                onStrokeEnd: _capture,
              ),
            ),
          ),
        ),
        if (widget.showToolbar) _toolbar(scheme, palette),
      ],
    );
  }

  Widget _toolbar(ColorScheme scheme, List<Color> palette) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: <Widget>[
        if (widget.showColorPicker)
          for (final Color c in palette)
            Tooltip(
              message: U.s.penColor,
              child: InkResponse(
                onTap: () => _controller.penColor = c,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: _controller.penColor == c ? scheme.primary : scheme.outlineVariant, width: _controller.penColor == c ? 3 : 1),
                  ),
                ),
              ),
            ),
        if (widget.showWidthSlider)
          Expanded(
            child: Slider(
              value: _controller.maxWidth,
              min: 2,
              max: 10,
              label: U.s.strokeWidth,
              onChanged: (double v) => setState(() {
                _controller.maxWidth = v;
                _controller.minWidth = (v * 0.35).clamp(0.5, v);
              }),
            ),
          )
        else
          const Spacer(),
        IconButton(icon: const Icon(Icons.undo_rounded), tooltip: U.s.undo, onPressed: _controller.canUndo ? _undo : null),
        IconButton(icon: const Icon(Icons.redo_rounded), tooltip: U.s.redo, onPressed: _controller.canRedo ? _redo : null),
        IconButton(icon: const Icon(Icons.delete_outline_rounded), tooltip: widget.clearButtonText ?? U.s.clear, onPressed: _controller.isEmpty ? null : _clear),
      ],
    ),
  );

  void _undo() {
    _controller.undo();
    _capture();
  }

  void _redo() {
    _controller.redo();
    _capture();
  }

  void _clear() => _controller.clear();
}
