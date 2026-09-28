import "dart:ui" as ui;

import "package:u/utilities.dart";

/// Free drawing and shapes layered over a page, an EPUB paragraph or a video frame.
enum UDocShapeKind { pen, highlighter, line, arrow, doubleArrow, rectangle, roundedRectangle, ellipse, areaHighlight, textBox, stickyNote }

/// Active tool of a [UDocShapeLayer]. [none] leaves the surface to the reader.
enum UDocDrawTool { none, select, pen, highlighter, line, arrow, doubleArrow, rectangle, roundedRectangle, ellipse, areaHighlight, textBox, stickyNote, eraser }

/// How shape coordinates are normalised. [box] divides x by width and y by
/// height (fixed-aspect surfaces: PDF pages, video frames); [width] divides
/// both by width (reflowable EPUB paragraphs whose height changes).
enum UDocShapeSpace { box, width }

UDocShapeKind? uDocShapeKindOf(UDocDrawTool tool) {
  switch (tool) {
    case UDocDrawTool.pen:
      return UDocShapeKind.pen;
    case UDocDrawTool.highlighter:
      return UDocShapeKind.highlighter;
    case UDocDrawTool.line:
      return UDocShapeKind.line;
    case UDocDrawTool.arrow:
      return UDocShapeKind.arrow;
    case UDocDrawTool.doubleArrow:
      return UDocShapeKind.doubleArrow;
    case UDocDrawTool.rectangle:
      return UDocShapeKind.rectangle;
    case UDocDrawTool.roundedRectangle:
      return UDocShapeKind.roundedRectangle;
    case UDocDrawTool.ellipse:
      return UDocShapeKind.ellipse;
    case UDocDrawTool.areaHighlight:
      return UDocShapeKind.areaHighlight;
    case UDocDrawTool.textBox:
      return UDocShapeKind.textBox;
    case UDocDrawTool.stickyNote:
      return UDocShapeKind.stickyNote;
    case UDocDrawTool.none:
    case UDocDrawTool.select:
    case UDocDrawTool.eraser:
      return null;
  }
}

String _shapeId() => "s${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}";

double _r4(double value) => (value * 10000).roundToDouble() / 10000;

/// One drawn shape. Geometry is normalised (see [UDocShapeSpace]) so it
/// survives zoom, window resizes and EPUB re-flow.
@immutable
class UDocShape {
  const UDocShape({
    required this.id,
    required this.kind,
    required this.points,
    required this.strokeColor,
    required this.createdAt,
    required this.updatedAt,
    this.pageIndex = -1,
    this.blockIndex = -1,
    this.fillColor,
    this.strokeWidth = 0.004,
    this.opacity = 1,
    this.dashed = false,
    this.text = "",
    this.fontSize = 0.028,
    this.bold = false,
    this.startMs,
    this.endMs,
  });

  factory UDocShape.create({
    required UDocShapeKind kind,
    required List<Offset> points,
    required Color strokeColor,
    int pageIndex = -1,
    int blockIndex = -1,
    Color? fillColor,
    double strokeWidth = 0.004,
    double opacity = 1,
    bool dashed = false,
    String text = "",
    double fontSize = 0.028,
    bool bold = false,
    int? startMs,
    int? endMs,
  }) {
    final DateTime now = DateTime.now();
    return UDocShape(
      id: _shapeId(),
      kind: kind,
      points: points,
      strokeColor: strokeColor,
      pageIndex: pageIndex,
      blockIndex: blockIndex,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      opacity: opacity,
      dashed: dashed,
      text: text,
      fontSize: fontSize,
      bold: bold,
      startMs: startMs,
      endMs: endMs,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UDocShape.fromJson(Map<String, Object?> json) {
    final List<Object?> raw = (json["pts"] as List<Object?>?) ?? const <Object?>[];
    final List<Offset> points = <Offset>[];
    for (int i = 0; i + 1 < raw.length; i += 2) {
      points.add(Offset((raw[i] as num?)?.toDouble() ?? 0, (raw[i + 1] as num?)?.toDouble() ?? 0));
    }
    UDocShapeKind kind = UDocShapeKind.pen;
    for (final UDocShapeKind value in UDocShapeKind.values) {
      if (value.name == json["kind"]) kind = value;
    }
    return UDocShape(
      id: (json["id"] as String?) ?? _shapeId(),
      kind: kind,
      points: points,
      pageIndex: (json["page"] as num?)?.toInt() ?? -1,
      blockIndex: (json["block"] as num?)?.toInt() ?? -1,
      strokeColor: Color((json["stroke"] as num?)?.toInt() ?? 0xFFE53935),
      fillColor: json["fill"] == null ? null : Color((json["fill"]! as num).toInt()),
      strokeWidth: (json["w"] as num?)?.toDouble() ?? 0.004,
      opacity: (json["o"] as num?)?.toDouble() ?? 1,
      dashed: json["dash"] == true,
      text: (json["text"] as String?) ?? "",
      fontSize: (json["fs"] as num?)?.toDouble() ?? 0.028,
      bold: json["bold"] == true,
      startMs: (json["start"] as num?)?.toInt(),
      endMs: (json["end"] as num?)?.toInt(),
      createdAt: DateTime.tryParse((json["created"] as String?) ?? "") ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json["updated"] as String?) ?? "") ?? DateTime.now(),
    );
  }

  final String id;
  final UDocShapeKind kind;

  /// Freehand points, or two corners / end points for everything else.
  final List<Offset> points;
  final int pageIndex;
  final int blockIndex;
  final Color strokeColor;
  final Color? fillColor;

  /// Stroke width as a fraction of the surface width.
  final double strokeWidth;
  final double opacity;
  final bool dashed;
  final String text;

  /// Font size as a fraction of the surface width.
  final double fontSize;
  final bool bold;

  /// Visible time range on video surfaces (null = always).
  final int? startMs;
  final int? endMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isFreehand => kind == UDocShapeKind.pen || kind == UDocShapeKind.highlighter;

  bool get hasText => text.trim().isNotEmpty;

  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    double left = points.first.dx;
    double top = points.first.dy;
    double right = left;
    double bottom = top;
    for (final Offset point in points) {
      left = min(left, point.dx);
      top = min(top, point.dy);
      right = max(right, point.dx);
      bottom = max(bottom, point.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  bool visibleAt(Duration position) {
    final int ms = position.inMilliseconds;
    if (startMs != null && ms < startMs! - 50) return false;
    if (endMs != null && ms > endMs! + 50) return false;
    return true;
  }

  UDocShape copyWith({
    List<Offset>? points,
    Color? strokeColor,
    Color? fillColor,
    bool clearFill = false,
    double? strokeWidth,
    double? opacity,
    bool? dashed,
    String? text,
    double? fontSize,
    bool? bold,
    int? startMs,
    int? endMs,
    UDocShapeKind? kind,
  }) => UDocShape(
    id: id,
    kind: kind ?? this.kind,
    points: points ?? this.points,
    pageIndex: pageIndex,
    blockIndex: blockIndex,
    strokeColor: strokeColor ?? this.strokeColor,
    fillColor: clearFill ? null : (fillColor ?? this.fillColor),
    strokeWidth: strokeWidth ?? this.strokeWidth,
    opacity: opacity ?? this.opacity,
    dashed: dashed ?? this.dashed,
    text: text ?? this.text,
    fontSize: fontSize ?? this.fontSize,
    bold: bold ?? this.bold,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  /// Stamps where the shape lives; [copy] gives it a fresh id.
  UDocShape placed({int? pageIndex, int? blockIndex, int? startMs, int? endMs, bool clearTime = false, bool copy = false}) {
    final DateTime now = DateTime.now();
    return UDocShape(
      id: copy ? _shapeId() : id,
      kind: kind,
      points: points,
      pageIndex: pageIndex ?? this.pageIndex,
      blockIndex: blockIndex ?? this.blockIndex,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      opacity: opacity,
      dashed: dashed,
      text: text,
      fontSize: fontSize,
      bold: bold,
      startMs: clearTime ? null : (startMs ?? this.startMs),
      endMs: clearTime ? null : (endMs ?? this.endMs),
      createdAt: copy ? now : createdAt,
      updatedAt: now,
    );
  }

  UDocShape translated(Offset delta) => copyWith(points: points.map((Offset point) => point + delta).toList());

  /// Scales the shape so its bounds become [target].
  UDocShape fitted(Rect target) {
    final Rect from = bounds;
    final double sx = from.width.abs() < 1e-6 ? 1 : target.width / from.width;
    final double sy = from.height.abs() < 1e-6 ? 1 : target.height / from.height;
    return copyWith(points: points.map((Offset point) => Offset(target.left + (point.dx - from.left) * sx, target.top + (point.dy - from.top) * sy)).toList());
  }

  Map<String, Object?> toJson() => <String, Object?>{
    "id": id,
    "kind": kind.name,
    if (pageIndex >= 0) "page": pageIndex,
    if (blockIndex >= 0) "block": blockIndex,
    "pts": <double>[
      for (final Offset point in points) ...<double>[_r4(point.dx), _r4(point.dy)],
    ],
    "stroke": strokeColor.toARGB32(),
    if (fillColor != null) "fill": fillColor!.toARGB32(),
    "w": _r4(strokeWidth),
    if (opacity != 1) "o": _r4(opacity),
    if (dashed) "dash": true,
    if (text.isNotEmpty) "text": text,
    if (kind == UDocShapeKind.textBox) "fs": _r4(fontSize),
    if (bold) "bold": true,
    if (startMs != null) "start": startMs,
    if (endMs != null) "end": endMs,
    "created": createdAt.toIso8601String(),
    "updated": updatedAt.toIso8601String(),
  };
}

/// Tool and style state shared by the toolbar and every [UDocShapeLayer].
class UDocDrawController extends ChangeNotifier {
  UDocDrawController({
    this._tool = UDocDrawTool.none,
    this._strokeColor = const Color(0xFFE53935),
    this._fillColor,
    this._strokeWidth = 3,
    this._opacity = 1,
    this._fontSize = 18,
  });

  UDocDrawTool _tool;
  UDocDrawTool _lastShape = UDocDrawTool.rectangle;
  Color _strokeColor;
  Color? _fillColor;
  double _strokeWidth;
  double _opacity;
  double _fontSize;
  bool _dashed = false;
  bool _bold = false;
  bool _constrain = false;
  String? _selectedId;
  Duration _videoDuration = const Duration(seconds: 5);

  UDocDrawTool get tool => _tool;

  /// The shape the toolbar's shape button selects (the last one used).
  UDocDrawTool get lastShape => _lastShape;

  static const List<UDocDrawTool> shapeTools = <UDocDrawTool>[
    UDocDrawTool.rectangle,
    UDocDrawTool.roundedRectangle,
    UDocDrawTool.ellipse,
    UDocDrawTool.line,
    UDocDrawTool.arrow,
    UDocDrawTool.doubleArrow,
  ];

  bool get isActive => _tool != UDocDrawTool.none;

  Color get strokeColor => _strokeColor;

  Color? get fillColor => _fillColor;

  /// Logical pixels at 100 % zoom.
  double get strokeWidth => _strokeWidth;

  double get opacity => _opacity;

  /// Logical pixels at 100 % zoom.
  double get fontSize => _fontSize;

  bool get dashed => _dashed;

  bool get bold => _bold;

  /// Squares / circles / 45° lines (also while Shift is held).
  bool get constrain => _constrain;

  String? get selectedId => _selectedId;

  /// How long a drawing stays on a video frame.
  Duration get videoDuration => _videoDuration;

  set tool(UDocDrawTool value) {
    _tool = value;
    if (shapeTools.contains(value)) _lastShape = value;
    if (value != UDocDrawTool.select) _selectedId = null;
    notifyListeners();
  }

  set strokeColor(Color value) {
    _strokeColor = value;
    notifyListeners();
  }

  set fillColor(Color? value) {
    _fillColor = value;
    notifyListeners();
  }

  set strokeWidth(double value) {
    _strokeWidth = value.clamp(0.5, 40).toDouble();
    notifyListeners();
  }

  set opacity(double value) {
    _opacity = value.clamp(0.1, 1).toDouble();
    notifyListeners();
  }

  set fontSize(double value) {
    _fontSize = value.clamp(8, 96).toDouble();
    notifyListeners();
  }

  set dashed(bool value) {
    _dashed = value;
    notifyListeners();
  }

  set bold(bool value) {
    _bold = value;
    notifyListeners();
  }

  set constrain(bool value) {
    _constrain = value;
    notifyListeners();
  }

  set selectedId(String? value) {
    _selectedId = value;
    notifyListeners();
  }

  set videoDuration(Duration value) {
    _videoDuration = value;
    notifyListeners();
  }

  void toggle(UDocDrawTool value) => tool = _tool == value ? UDocDrawTool.none : value;

  /// True while a text field has keyboard focus, so viewer hotkeys (space, arrows…) must stand aside.
  static bool get isTyping {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.widget is EditableText || context.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}

/// Converts normalised shape geometry to pixels on a surface of [size].
class UDocShapeGeometry {
  const UDocShapeGeometry(this.size, this.space, {this.origin = Offset.zero});

  final Size size;
  final UDocShapeSpace space;

  /// Where this surface starts inside the full one (an EPUB paragraph continued on a later page).
  final Offset origin;

  double get _yUnit => space == UDocShapeSpace.box ? size.height : size.width;

  Offset toPixels(Offset point) => Offset(point.dx * size.width, point.dy * _yUnit) - origin;

  Offset toNormal(Offset pixel) => Offset(size.width <= 0 ? 0 : (pixel.dx + origin.dx) / size.width, _yUnit <= 0 ? 0 : (pixel.dy + origin.dy) / _yUnit);

  Rect rectToPixels(Rect rect) => Rect.fromPoints(toPixels(rect.topLeft), toPixels(rect.bottomRight));

  /// A vector (no origin shift) in normalised units.
  Offset deltaToNormal(Offset pixels) => Offset(size.width <= 0 ? 0 : pixels.dx / size.width, _yUnit <= 0 ? 0 : pixels.dy / _yUnit);

  double lengthToPixels(double value) => value * size.width;

  double lengthToNormal(double pixels) => size.width <= 0 ? 0 : pixels / size.width;
}

abstract final class UDocShapePainter {
  static void paint(Canvas canvas, UDocShape shape, UDocShapeGeometry geometry, {bool selected = false, bool hideText = false}) {
    if (shape.points.isEmpty) return;
    final List<Offset> points = shape.points.map(geometry.toPixels).toList();
    final double width = max(0.8, geometry.lengthToPixels(shape.strokeWidth));
    final bool layered = shape.opacity < 1;
    if (layered) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, shape.opacity));
    final Paint stroke = Paint()
      ..color = shape.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final Rect box = points.length >= 2 ? Rect.fromPoints(points.first, points.last) : Rect.fromCenter(center: points.first, width: 1, height: 1);
    switch (shape.kind) {
      case UDocShapeKind.pen:
        _stroke(canvas, _smooth(points), stroke, dashed: shape.dashed);
        break;
      case UDocShapeKind.highlighter:
        stroke
          ..color = shape.strokeColor.withValues(alpha: shape.strokeColor.a * 0.38)
          ..strokeCap = StrokeCap.square
          ..blendMode = BlendMode.multiply;
        _stroke(canvas, _smooth(points), stroke);
        break;
      case UDocShapeKind.line:
      case UDocShapeKind.arrow:
      case UDocShapeKind.doubleArrow:
        if (points.length < 2) break;
        _stroke(
          canvas,
          Path()
            ..moveTo(points.first.dx, points.first.dy)
            ..lineTo(points.last.dx, points.last.dy),
          stroke,
          dashed: shape.dashed,
        );
        if (shape.kind != UDocShapeKind.line) _arrowHead(canvas, points.first, points.last, width, shape.strokeColor);
        if (shape.kind == UDocShapeKind.doubleArrow) _arrowHead(canvas, points.last, points.first, width, shape.strokeColor);
        break;
      case UDocShapeKind.rectangle:
      case UDocShapeKind.roundedRectangle:
      case UDocShapeKind.ellipse:
        final Path path = shape.kind == UDocShapeKind.ellipse
            ? (Path()..addOval(box))
            : (Path()..addRRect(RRect.fromRectAndRadius(box, Radius.circular(shape.kind == UDocShapeKind.roundedRectangle ? min(box.shortestSide * 0.25, 24) : 0))));
        final Color? fill = shape.fillColor;
        if (fill != null) canvas.drawPath(path, Paint()..color = fill);
        if (shape.strokeWidth > 0 && shape.strokeColor.a > 0) _stroke(canvas, path, stroke, dashed: shape.dashed);
        break;
      case UDocShapeKind.areaHighlight:
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(3)),
          Paint()
            ..color = (shape.fillColor ?? shape.strokeColor).withValues(alpha: 0.32)
            ..blendMode = BlendMode.multiply,
        );
        break;
      case UDocShapeKind.textBox:
        final Color? fill = shape.fillColor;
        if (fill != null) canvas.drawRRect(RRect.fromRectAndRadius(box.inflate(4), const Radius.circular(6)), Paint()..color = fill);
        if (shape.dashed) {
          final Paint border = Paint()
            ..color = shape.strokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
          _stroke(canvas, Path()..addRRect(RRect.fromRectAndRadius(box.inflate(4), const Radius.circular(6))), border, dashed: true);
        }
        if (!hideText) {
          final TextPainter text = textPainter(shape, geometry, box.width);
          text.paint(canvas, box.topLeft);
          text.dispose();
        }
        break;
      case UDocShapeKind.stickyNote:
        final double size = stickySize(geometry);
        UDocMarkupPainter.badge(canvas, points.first + Offset(size / 2, size / 2), shape.strokeColor, size);
        break;
    }
    if (layered) canvas.restore();
    if (selected) {
      final Rect outline = pixelBounds(shape, geometry).inflate(6);
      canvas.drawRect(
        outline,
        Paint()
          ..color = const Color(0xFF1E88E5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  static double stickySize(UDocShapeGeometry geometry) => (geometry.size.width * 0.035).clamp(16, 30).toDouble();

  static TextPainter textPainter(UDocShape shape, UDocShapeGeometry geometry, double maxWidth) => TextPainter(
    text: TextSpan(
      text: shape.text,
      style: TextStyle(
        color: shape.strokeColor,
        fontSize: max(6, geometry.lengthToPixels(shape.fontSize)),
        fontWeight: shape.bold ? FontWeight.w700 : FontWeight.w400,
        fontFamily: "Vazir",
        package: "u",
        height: 1.35,
      ),
    ),
    textDirection: UDocText.isRtl(shape.text) ? TextDirection.rtl : TextDirection.ltr,
  )..layout(minWidth: max(0, maxWidth), maxWidth: max(20, maxWidth));

  /// Bounds in pixels, including text that grew beyond the drawn box.
  static Rect pixelBounds(UDocShape shape, UDocShapeGeometry geometry) {
    final List<Offset> points = shape.points.map(geometry.toPixels).toList();
    if (points.isEmpty) return Rect.zero;
    if (shape.kind == UDocShapeKind.stickyNote) {
      final double size = stickySize(geometry);
      return Rect.fromLTWH(points.first.dx, points.first.dy, size, size);
    }
    Rect rect = geometry.rectToPixels(shape.bounds);
    if (shape.kind == UDocShapeKind.textBox) {
      final TextPainter text = textPainter(shape, geometry, rect.width);
      rect = Rect.fromLTWH(rect.left, rect.top, rect.width, max(rect.height, text.height));
      text.dispose();
    }
    final double pad = max(0.8, geometry.lengthToPixels(shape.strokeWidth)) / 2;
    return rect.inflate(pad);
  }

  /// Whether [pixel] touches [shape].
  static bool hitTest(UDocShape shape, UDocShapeGeometry geometry, Offset pixel, {double slop = 8}) {
    final List<Offset> points = shape.points.map(geometry.toPixels).toList();
    if (points.isEmpty) return false;
    final double tolerance = slop + max(0.8, geometry.lengthToPixels(shape.strokeWidth)) / 2;
    switch (shape.kind) {
      case UDocShapeKind.pen:
      case UDocShapeKind.highlighter:
        for (int i = 1; i < points.length; i++) {
          if (_segmentDistance(pixel, points[i - 1], points[i]) <= tolerance) return true;
        }
        return points.length == 1 && (points.first - pixel).distance <= tolerance;
      case UDocShapeKind.line:
      case UDocShapeKind.arrow:
      case UDocShapeKind.doubleArrow:
        return points.length >= 2 && _segmentDistance(pixel, points.first, points.last) <= tolerance;
      case UDocShapeKind.ellipse:
        final Rect box = Rect.fromPoints(points.first, points.last);
        if (box.width < 1 || box.height < 1) return box.inflate(tolerance).contains(pixel);
        final double nx = (pixel.dx - box.center.dx) / (box.width / 2);
        final double ny = (pixel.dy - box.center.dy) / (box.height / 2);
        final double value = sqrt(nx * nx + ny * ny);
        return shape.fillColor != null ? value <= 1.05 : (value - 1).abs() * min(box.width, box.height) / 2 <= tolerance;
      case UDocShapeKind.rectangle:
      case UDocShapeKind.roundedRectangle:
        final Rect box = Rect.fromPoints(points.first, points.last);
        if (shape.fillColor != null) return box.inflate(tolerance).contains(pixel);
        return box.inflate(tolerance).contains(pixel) && !box.deflate(tolerance).contains(pixel);
      case UDocShapeKind.areaHighlight:
      case UDocShapeKind.textBox:
      case UDocShapeKind.stickyNote:
        return pixelBounds(shape, geometry).inflate(slop / 2).contains(pixel);
    }
  }

  static double _segmentDistance(Offset p, Offset a, Offset b) {
    final Offset ab = b - a;
    final double length = ab.distanceSquared;
    if (length == 0) return (p - a).distance;
    final double t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / length).clamp(0, 1).toDouble();
    return (p - (a + ab * t)).distance;
  }

  static Path _smooth(List<Offset> points) {
    final Path path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      path.lineTo(points.first.dx + 0.01, points.first.dy);
      return path;
    }
    for (int i = 1; i < points.length - 1; i++) {
      final Offset middle = (points[i] + points[i + 1]) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, middle.dx, middle.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  static void _stroke(Canvas canvas, Path path, Paint paint, {bool dashed = false}) {
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    final double dash = max(4, paint.strokeWidth * 3);
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, min(distance + dash, metric.length)), paint);
        distance += dash * 1.8;
      }
    }
  }

  static void _arrowHead(Canvas canvas, Offset from, Offset to, double width, Color color) {
    final Offset direction = to - from;
    if (direction.distance < 1) return;
    final double size = max(8, width * 4);
    final double angle = atan2(direction.dy, direction.dx);
    final Path head = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - size * cos(angle - 0.45), to.dy - size * sin(angle - 0.45))
      ..lineTo(to.dx - size * cos(angle + 0.45), to.dy - size * sin(angle + 0.45))
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }
}

class _UDocShapesPainter extends CustomPainter {
  _UDocShapesPainter({required this.shapes, required this.space, required this.origin, required this.selectedId, required this.editingId, this.draft});

  final List<UDocShape> shapes;
  final UDocShapeSpace space;
  final Offset origin;
  final String? selectedId;
  final String? editingId;
  final UDocShape? draft;

  @override
  void paint(Canvas canvas, Size size) {
    final UDocShapeGeometry geometry = UDocShapeGeometry(size, space, origin: origin);
    for (final UDocShape shape in shapes) {
      UDocShapePainter.paint(canvas, shape, geometry, selected: shape.id == selectedId, hideText: shape.id == editingId);
    }
    final UDocShape? pending = draft;
    if (pending != null) UDocShapePainter.paint(canvas, pending, geometry);
  }

  @override
  bool shouldRepaint(_UDocShapesPainter oldDelegate) =>
      oldDelegate.shapes != shapes ||
      oldDelegate.draft != draft ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.editingId != editingId ||
      oldDelegate.space != space ||
      oldDelegate.origin != origin;
}

/// Paints [shapes] and, when a tool is active, lets the user draw, type,
/// select, move, resize and erase them. Sized by its parent.
class UDocShapeLayer extends StatefulWidget {
  const UDocShapeLayer({
    required this.shapes,
    required this.tools,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
    this.prepare,
    this.space = UDocShapeSpace.box,
    this.origin = Offset.zero,
    this.enabled = true,
    this.zoom = 1,
    super.key,
  });

  final List<UDocShape> shapes;
  final UDocDrawController tools;
  final void Function(UDocShape shape) onAdd;
  final void Function(UDocShape shape) onUpdate;
  final void Function(String id) onRemove;

  /// Stamps host data (page, block, time range) on new shapes.
  final UDocShape Function(UDocShape shape)? prepare;
  final UDocShapeSpace space;

  /// Pixel offset of this layer inside the full surface (see [UDocShapeGeometry.origin]).
  final Offset origin;
  final bool enabled;

  /// Display zoom; stroke width and font size are chosen at 100 % and scaled with the surface.
  final double zoom;

  @override
  State<UDocShapeLayer> createState() => _UDocShapeLayerState();
}

class _UDocShapeLayerState extends State<UDocShapeLayer> {
  UDocShape? _draft;
  Offset? _start;
  String? _editingId;
  final TextEditingController _textField = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  _UDocDragMode _drag = _UDocDragMode.none;
  UDocShape? _dragOrigin;
  Offset _dragAnchor = Offset.zero;
  Size _size = Size.zero;

  UDocShapeGeometry get _geometry => UDocShapeGeometry(_size, widget.space, origin: widget.origin);

  UDocDrawController get _tools => widget.tools;

  @override
  void initState() {
    super.initState();
    _tools.addListener(_onTools);
    _textFocus.addListener(() {
      if (!_textFocus.hasFocus) _commitText();
    });
  }

  @override
  void didUpdateWidget(UDocShapeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tools != widget.tools) {
      oldWidget.tools.removeListener(_onTools);
      widget.tools.addListener(_onTools);
    }
  }

  @override
  void dispose() {
    _tools.removeListener(_onTools);
    _textField.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _onTools() {
    if (mounted) setState(() {});
  }

  bool get _drawing => widget.enabled && _tools.isActive;

  double get _zoom => widget.zoom <= 0 ? 1 : widget.zoom;

  UDocShape _stamp(UDocShape shape) => widget.prepare?.call(shape) ?? shape;

  UDocShape? _hit(Offset pixel) {
    for (int i = widget.shapes.length - 1; i >= 0; i--) {
      if (UDocShapePainter.hitTest(widget.shapes[i], _geometry, pixel)) return widget.shapes[i];
    }
    return null;
  }

  UDocShape? get _selected {
    final String? id = _tools.selectedId;
    if (id == null) return null;
    for (final UDocShape shape in widget.shapes) {
      if (shape.id == id) return shape;
    }
    return null;
  }

  Offset _constrained(Offset start, Offset end, UDocShapeKind kind) {
    final bool constrain = _tools.constrain || HardwareKeyboard.instance.isShiftPressed;
    if (!constrain) return end;
    final Offset delta = end - start;
    if (kind == UDocShapeKind.line || kind == UDocShapeKind.arrow || kind == UDocShapeKind.doubleArrow) {
      final double angle = (atan2(delta.dy, delta.dx) / (pi / 4)).round() * (pi / 4);
      return start + Offset(cos(angle), sin(angle)) * delta.distance;
    }
    final double side = max(delta.dx.abs(), delta.dy.abs());
    return start + Offset(side * delta.dx.sign, side * delta.dy.sign);
  }

  UDocShape _newShape(UDocShapeKind kind, List<Offset> pixels) {
    final UDocShapeGeometry geometry = _geometry;
    final bool highlighter = kind == UDocShapeKind.highlighter;
    return UDocShape.create(
      kind: kind,
      points: pixels.map(geometry.toNormal).toList(),
      strokeColor: _tools.strokeColor,
      fillColor: kind == UDocShapeKind.areaHighlight
          ? (_tools.fillColor ?? _tools.strokeColor)
          : (kind == UDocShapeKind.pen || highlighter || kind == UDocShapeKind.line || kind == UDocShapeKind.arrow || kind == UDocShapeKind.doubleArrow ? null : _tools.fillColor),
      strokeWidth: geometry.lengthToNormal((highlighter ? max(_tools.strokeWidth * 4, 14) : _tools.strokeWidth) * _zoom),
      opacity: _tools.opacity,
      dashed: _tools.dashed,
      fontSize: geometry.lengthToNormal(_tools.fontSize * _zoom),
      bold: _tools.bold,
    );
  }

  // ───────── gestures ─────────

  void _onPanStart(DragStartDetails details) {
    final Offset point = details.localPosition;
    final UDocDrawTool tool = _tools.tool;
    if (tool == UDocDrawTool.select) {
      final UDocShape? selected = _selected;
      if (selected != null) {
        final Rect bounds = UDocShapePainter.pixelBounds(selected, _geometry);
        if ((point - bounds.bottomRight).distance <= 22) {
          _drag = _UDocDragMode.resize;
          _dragOrigin = selected;
          return;
        }
        if (bounds.inflate(8).contains(point)) {
          _drag = _UDocDragMode.move;
          _dragOrigin = selected;
          _dragAnchor = point;
          return;
        }
      }
      final UDocShape? hit = _hit(point);
      _tools.selectedId = hit?.id;
      if (hit != null) {
        _drag = _UDocDragMode.move;
        _dragOrigin = hit;
        _dragAnchor = point;
      }
      return;
    }
    if (tool == UDocDrawTool.eraser) {
      _erase(point);
      return;
    }
    final UDocShapeKind? kind = uDocShapeKindOf(tool);
    if (kind == null || kind == UDocShapeKind.stickyNote) return;
    _start = point;
    setState(() => _draft = _newShape(kind, <Offset>[point, point]));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final Offset point = details.localPosition;
    final UDocDrawTool tool = _tools.tool;
    if (tool == UDocDrawTool.select) {
      final UDocShape? origin = _dragOrigin;
      if (origin == null) return;
      if (_drag == _UDocDragMode.move) {
        final Offset delta = _geometry.deltaToNormal(point - _dragAnchor);
        widget.onUpdate(origin.translated(delta));
      } else if (_drag == _UDocDragMode.resize) {
        final Rect from = origin.bounds;
        final Offset corner = _geometry.toNormal(point);
        final Rect target = Rect.fromLTRB(from.left, from.top, max(from.left + 0.01, corner.dx), max(from.top + 0.005, corner.dy));
        widget.onUpdate(origin.fitted(target));
      }
      return;
    }
    if (tool == UDocDrawTool.eraser) {
      _erase(point);
      return;
    }
    final UDocShape? draft = _draft;
    final Offset? start = _start;
    if (draft == null || start == null) return;
    if (draft.isFreehand) {
      final Offset normal = _geometry.toNormal(point);
      if ((point - _geometry.toPixels(draft.points.last)).distance < 1.2) return;
      setState(() => _draft = draft.copyWith(points: <Offset>[...draft.points, normal]));
    } else {
      final Offset end = _constrained(start, point, draft.kind);
      setState(() => _draft = draft.copyWith(points: <Offset>[_geometry.toNormal(start), _geometry.toNormal(end)]));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_tools.tool == UDocDrawTool.select) {
      _drag = _UDocDragMode.none;
      _dragOrigin = null;
      return;
    }
    final UDocShape? draft = _draft;
    _start = null;
    if (draft == null) return;
    setState(() => _draft = null);
    final Rect bounds = UDocShapePainter.pixelBounds(draft, _geometry);
    final bool tiny = !draft.isFreehand && bounds.width < 4 && bounds.height < 4;
    if (tiny && draft.kind != UDocShapeKind.textBox) return;
    if (draft.kind == UDocShapeKind.textBox) {
      _openTextEditor(tiny ? _defaultTextBox(bounds.topLeft) : draft);
      return;
    }
    widget.onAdd(_stamp(draft.isFreehand ? draft.copyWith(points: _simplify(draft.points)) : draft));
  }

  void _onTapUp(TapUpDetails details) {
    final Offset point = details.localPosition;
    switch (_tools.tool) {
      case UDocDrawTool.select:
        final UDocShape? hit = _hit(point);
        // A second tap on a selected text box / note edits it.
        if (hit != null && hit.id == _tools.selectedId) {
          if (hit.kind == UDocShapeKind.textBox) _openTextEditor(hit, existing: true);
          if (hit.kind == UDocShapeKind.stickyNote) unawaited(_editSticky(hit));
          break;
        }
        _tools.selectedId = hit?.id;
        break;
      case UDocDrawTool.eraser:
        _erase(point);
        break;
      case UDocDrawTool.textBox:
        // The tap that ends typing only commits the text.
        if (DateTime.now().difference(_committedAt) < const Duration(milliseconds: 500)) break;
        final UDocShape? hit = _hit(point);
        if (hit != null && hit.kind == UDocShapeKind.textBox) {
          _openTextEditor(hit, existing: true);
        } else {
          _openTextEditor(_defaultTextBox(point));
        }
        break;
      case UDocDrawTool.stickyNote:
        unawaited(_addSticky(point));
        break;
      default:
        final UDocShapeKind? kind = uDocShapeKindOf(_tools.tool);
        if (kind == UDocShapeKind.pen || kind == UDocShapeKind.highlighter) widget.onAdd(_stamp(_newShape(kind!, <Offset>[point])));
        break;
    }
  }

  void _erase(Offset point) {
    final UDocShape? hit = _hit(point);
    if (hit != null) widget.onRemove(hit.id);
  }

  List<Offset> _simplify(List<Offset> points) {
    if (points.length < 4) return points;
    final List<Offset> out = <Offset>[points.first];
    final double minStep = _geometry.lengthToNormal(1.5);
    for (int i = 1; i < points.length - 1; i++) {
      if ((points[i] - out.last).distance >= minStep) out.add(points[i]);
    }
    out.add(points.last);
    return out;
  }

  UDocShape _defaultTextBox(Offset point) {
    final double width = min(max(160, _size.width * 0.32), _size.width - point.dx - 4);
    final double height = _tools.fontSize * _zoom * 1.5;
    return _newShape(UDocShapeKind.textBox, <Offset>[point, point + Offset(max(60, width), height)]);
  }

  // ───────── text boxes ─────────

  UDocShape? _textDraft;
  bool _textExisting = false;
  DateTime _committedAt = DateTime.fromMillisecondsSinceEpoch(0);

  void _openTextEditor(UDocShape shape, {bool existing = false}) {
    _commitText();
    _textDraft = shape;
    _textExisting = existing;
    _textField.text = shape.text;
    setState(() => _editingId = shape.id);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _textFocus.requestFocus();
    });
  }

  void _commitText() {
    final UDocShape? draft = _textDraft;
    if (draft == null) return;
    _textDraft = null;
    _committedAt = DateTime.now();
    final String text = _textField.text;
    if (mounted) setState(() => _editingId = null);
    if (text.trim().isEmpty) {
      if (_textExisting) widget.onRemove(draft.id);
      return;
    }
    final UDocShapeGeometry geometry = _geometry;
    final Rect box = geometry.rectToPixels(draft.bounds);
    final TextPainter painter = UDocShapePainter.textPainter(draft.copyWith(text: text), geometry, box.width);
    final double height = max(box.height, painter.height);
    painter.dispose();
    final UDocShape updated = draft.copyWith(text: text, points: <Offset>[geometry.toNormal(box.topLeft), geometry.toNormal(Offset(box.right, box.top + height))]);
    if (_textExisting) {
      widget.onUpdate(updated);
    } else {
      widget.onAdd(_stamp(updated));
    }
  }

  Future<void> _addSticky(Offset point) async {
    final String? note = await UDocNoteEditor.show();
    if (note == null || note.trim().isEmpty) return;
    final UDocShape shape = _newShape(UDocShapeKind.stickyNote, <Offset>[point]).copyWith(text: note);
    widget.onAdd(_stamp(shape));
  }

  Future<void> _editSticky(UDocShape shape) async {
    final String? note = await UDocNoteEditor.show(initial: shape.text);
    if (note == null) return;
    if (note.trim().isEmpty) {
      widget.onRemove(shape.id);
    } else {
      widget.onUpdate(shape.copyWith(text: note));
    }
  }

  // ───────── build ─────────

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      _size = constraints.biggest;
      final UDocShape? selected = _drawing && _tools.tool == UDocDrawTool.select ? _selected : null;
      final Widget painted = CustomPaint(
        size: _size,
        painter: _UDocShapesPainter(shapes: widget.shapes, space: widget.space, origin: widget.origin, selectedId: selected?.id, editingId: _editingId, draft: _draft),
      );
      final List<Widget> layers = <Widget>[
        Positioned.fill(child: IgnorePointer(child: painted)),
        if (_drawing)
          Positioned.fill(
            child: MouseRegion(
              cursor: _tools.tool == UDocDrawTool.select ? SystemMouseCursors.basic : (_tools.tool == UDocDrawTool.textBox ? SystemMouseCursors.text : SystemMouseCursors.precise),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTapUp: _onTapUp,
              ),
            ),
          )
        else
          // Sticky notes and text boxes stay tappable while reading.
          ...widget.shapes.where((UDocShape shape) => shape.kind == UDocShapeKind.stickyNote).map((UDocShape shape) {
            final Rect bounds = UDocShapePainter.pixelBounds(shape, _geometry);
            return Positioned.fromRect(
              rect: bounds.inflate(6),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(_editSticky(shape)),
                child: Tooltip(message: shape.text, child: const SizedBox.expand()),
              ),
            );
          }),
        if (selected != null) ..._selectionChrome(context, selected),
        if (_editingId != null && _textDraft != null) _textEditor(context, _textDraft!),
      ];
      return Stack(clipBehavior: Clip.none, children: layers);
    },
  );

  Widget _textEditor(BuildContext context, UDocShape shape) {
    final UDocShapeGeometry geometry = _geometry;
    final Rect box = geometry.rectToPixels(shape.bounds);
    final double fontSize = max(6, geometry.lengthToPixels(shape.fontSize));
    return Positioned(
      left: box.left,
      top: box.top,
      width: max(80, box.width),
      child: Material(
        color: shape.fillColor ?? const Color(0x00000000),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1E88E5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _textField,
            focusNode: _textFocus,
            maxLines: null,
            minLines: 1,
            textDirection: UDocText.isRtl(_textField.text) ? TextDirection.rtl : null,
            onChanged: (String _) => setState(() {}),
            onTapOutside: (PointerDownEvent event) => _textFocus.unfocus(),
            style: TextStyle(color: shape.strokeColor, fontSize: fontSize, fontWeight: shape.bold ? FontWeight.w700 : FontWeight.w400, fontFamily: "Vazir", package: "u", height: 1.35),
            decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
          ),
        ),
      ),
    );
  }

  List<Widget> _selectionChrome(BuildContext context, UDocShape shape) {
    final Rect bounds = UDocShapePainter.pixelBounds(shape, _geometry);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool resizable = shape.kind != UDocShapeKind.stickyNote;
    final double barTop = bounds.top - 48 < 0 ? bounds.bottom + 10 : bounds.top - 48;
    return <Widget>[
      if (resizable)
        Positioned(
          left: bounds.right - 9,
          top: bounds.bottom - 9,
          width: 18,
          height: 18,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
              ),
            ),
          ),
        ),
      Positioned(
        left: max(0, min(bounds.left, _size.width - 260)),
        top: barTop,
        child: Material(
          color: scheme.inverseSurface,
          elevation: 4,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UDocColorBar(
                selected: shape.strokeColor,
                size: 16,
                onDark: true,
                colors: UDocPalette.colors.take(6).toList(),
                onSelected: (Color color) => widget.onUpdate(
                  shape.copyWith(
                    strokeColor: color,
                    fillColor: shape.fillColor == null ? null : color.withValues(alpha: shape.fillColor!.a),
                  ),
                ),
              ),
              if (shape.kind == UDocShapeKind.textBox || shape.kind == UDocShapeKind.stickyNote)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: U.s.edit,
                  icon: Icon(Icons.edit_rounded, size: 18, color: scheme.onInverseSurface),
                  onPressed: () => shape.kind == UDocShapeKind.textBox ? _openTextEditor(shape, existing: true) : unawaited(_editSticky(shape)),
                ),
              if (shape.kind == UDocShapeKind.rectangle || shape.kind == UDocShapeKind.roundedRectangle || shape.kind == UDocShapeKind.ellipse || shape.kind == UDocShapeKind.textBox)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: U.s.fill,
                  icon: Icon(shape.fillColor == null ? Icons.format_color_fill_rounded : Icons.format_color_reset_rounded, size: 18, color: scheme.onInverseSurface),
                  onPressed: () => widget.onUpdate(shape.fillColor == null ? shape.copyWith(fillColor: shape.strokeColor.withValues(alpha: 0.25)) : shape.copyWith(clearFill: true)),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: U.s.delete,
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: scheme.errorContainer),
                onPressed: () {
                  _tools.selectedId = null;
                  widget.onRemove(shape.id);
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

enum _UDocDragMode { none, move, resize }

/// Tool palette + style controls for [UDocShapeLayer]s.
class UDocDrawToolbar extends StatelessWidget {
  const UDocDrawToolbar({
    required this.tools,
    this.onUndo,
    this.onRedo,
    this.onDone,
    this.available = const <UDocDrawTool>[
      UDocDrawTool.select,
      UDocDrawTool.pen,
      UDocDrawTool.highlighter,
      UDocDrawTool.areaHighlight,
      UDocDrawTool.line,
      UDocDrawTool.arrow,
      UDocDrawTool.doubleArrow,
      UDocDrawTool.rectangle,
      UDocDrawTool.roundedRectangle,
      UDocDrawTool.ellipse,
      UDocDrawTool.textBox,
      UDocDrawTool.stickyNote,
      UDocDrawTool.eraser,
    ],
    this.showVideoDuration = false,
    this.dark = false,
    super.key,
  });

  final UDocDrawController tools;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onDone;
  final List<UDocDrawTool> available;
  final bool showVideoDuration;
  final bool dark;

  static IconData iconOf(UDocDrawTool tool) {
    switch (tool) {
      case UDocDrawTool.none:
        return Icons.touch_app_rounded;
      case UDocDrawTool.select:
        return Icons.near_me_rounded;
      case UDocDrawTool.pen:
        return Icons.edit_rounded;
      case UDocDrawTool.highlighter:
        return Icons.brush_rounded;
      case UDocDrawTool.line:
        return Icons.horizontal_rule_rounded;
      case UDocDrawTool.arrow:
        return Icons.north_east_rounded;
      case UDocDrawTool.doubleArrow:
        return Icons.open_in_full_rounded;
      case UDocDrawTool.rectangle:
        return Icons.crop_square_rounded;
      case UDocDrawTool.roundedRectangle:
        return Icons.rounded_corner_rounded;
      case UDocDrawTool.ellipse:
        return Icons.circle_outlined;
      case UDocDrawTool.areaHighlight:
        return Icons.highlight_alt_rounded;
      case UDocDrawTool.textBox:
        return Icons.text_fields_rounded;
      case UDocDrawTool.stickyNote:
        return Icons.sticky_note_2_outlined;
      case UDocDrawTool.eraser:
        return Icons.auto_fix_normal_rounded;
    }
  }

  static String labelOf(UDocDrawTool tool) {
    switch (tool) {
      case UDocDrawTool.none:
        return U.s.read;
      case UDocDrawTool.select:
        return U.s.select;
      case UDocDrawTool.pen:
        return U.s.pen;
      case UDocDrawTool.highlighter:
        return U.s.highlighterPen;
      case UDocDrawTool.line:
        return U.s.line;
      case UDocDrawTool.arrow:
        return U.s.arrow;
      case UDocDrawTool.doubleArrow:
        return U.s.doubleArrow;
      case UDocDrawTool.rectangle:
        return U.s.rectangle;
      case UDocDrawTool.roundedRectangle:
        return U.s.roundedRectangle;
      case UDocDrawTool.ellipse:
        return U.s.ellipse;
      case UDocDrawTool.areaHighlight:
        return U.s.areaHighlight;
      case UDocDrawTool.textBox:
        return U.s.textBox;
      case UDocDrawTool.stickyNote:
        return U.s.note;
      case UDocDrawTool.eraser:
        return U.s.erase;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: tools,
    builder: (BuildContext context, Widget? child) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      final Color foreground = dark ? const Color(0xFFFFFFFF) : scheme.onSurface;
      final Color accent = dark ? const Color(0xFF90CAF9) : scheme.primary;
      Widget tool(UDocDrawTool value) {
        final bool selected = tools.tool == value;
        return Tooltip(
          message: labelOf(value),
          child: InkResponse(
            onTap: () => tools.toggle(value),
            radius: 22,
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(color: selected ? accent.withValues(alpha: 0.18) : null, borderRadius: BorderRadius.circular(10)),
              child: Icon(iconOf(value), size: 20, color: selected ? accent : foreground),
            ),
          ),
        );
      }

      final List<UDocDrawTool> shapes = available.where(UDocDrawController.shapeTools.contains).toList();
      final List<Widget> toolButtons = <Widget>[];
      for (final UDocDrawTool value in available) {
        if (shapes.length > 1 && shapes.contains(value)) {
          if (value == shapes.first) toolButtons.add(_shapesButton(context, shapes, foreground, accent));
        } else {
          toolButtons.add(tool(value));
        }
      }
      return Row(
        children: <Widget>[
          Expanded(
            child: ScrollConfiguration(
              // Mouse users can drag the row when it does not fit.
              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet(), scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: <Widget>[
                    _colorButton(context, U.s.color, tools.strokeColor, (Color color) => tools.strokeColor = color, foreground),
                    _fillButton(context, foreground),
                    _styleButton(context, foreground),
                    _divider(foreground),
                    ...toolButtons,
                  ],
                ),
              ),
            ),
          ),
          _divider(foreground),
          IconButton(
            tooltip: U.s.undo,
            onPressed: onUndo,
            icon: Icon(Icons.undo_rounded, color: onUndo == null ? foreground.withValues(alpha: 0.35) : foreground),
          ),
          IconButton(
            tooltip: U.s.redo,
            onPressed: onRedo,
            icon: Icon(Icons.redo_rounded, color: onRedo == null ? foreground.withValues(alpha: 0.35) : foreground),
          ),
          if (onDone != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 2, end: 8),
              child: IconButton.filledTonal(tooltip: U.s.done, onPressed: onDone, icon: const Icon(Icons.check_rounded)),
            ),
        ],
      );
    },
  );

  /// One button for every shape: tap selects the last shape, tap again (or long-press) lists them all.
  Widget _shapesButton(BuildContext context, List<UDocDrawTool> shapes, Color foreground, Color accent) {
    final UDocDrawTool current = shapes.contains(tools.tool) ? tools.tool : (shapes.contains(tools.lastShape) ? tools.lastShape : shapes.first);
    final bool selected = shapes.contains(tools.tool);
    return MenuAnchor(
      menuChildren: shapes
          .map(
            (UDocDrawTool value) => MenuItemButton(
              leadingIcon: Icon(iconOf(value), color: value == tools.tool ? accent : null),
              onPressed: () => tools.tool = value,
              child: Text(labelOf(value)),
            ),
          )
          .toList(),
      builder: (BuildContext context, MenuController controller, Widget? child) => Tooltip(
        message: "${labelOf(current)} · ${U.s.shapes}",
        child: InkResponse(
          radius: 22,
          onTap: () {
            if (selected) {
              controller.isOpen ? controller.close() : controller.open();
            } else {
              tools.tool = current;
            }
          },
          onLongPress: controller.open,
          onSecondaryTap: controller.open,
          child: Container(
            width: 44,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: selected ? accent.withValues(alpha: 0.18) : null, borderRadius: BorderRadius.circular(10)),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(iconOf(current), size: 20, color: selected ? accent : foreground),
                PositionedDirectional(end: 0, bottom: 2, child: Icon(Icons.arrow_drop_down_rounded, size: 16, color: selected ? accent : foreground.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(Color color) => Container(width: 1, height: 26, margin: const EdgeInsets.symmetric(horizontal: 6), color: color.withValues(alpha: 0.2));

  Widget _colorButton(BuildContext context, String tooltip, Color color, ValueChanged<Color> onSelected, Color foreground) => MenuAnchor(
    menuChildren: <Widget>[
      Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 220,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Color>[...UDocPalette.colors, const Color(0xFFFFFFFF), const Color(0xFF795548), const Color(0xFF009688)]
                .map(
                  (Color option) => InkResponse(
                    onTap: () => onSelected(option),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: option,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: option.toARGB32() == color.toARGB32() ? Theme.of(context).colorScheme.primary : const Color(0x33000000),
                          width: option.toARGB32() == color.toARGB32() ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ],
    builder: (BuildContext context, MenuController controller, Widget? child) => IconButton(
      tooltip: tooltip,
      onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      icon: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: foreground.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    ),
  );

  Widget _fillButton(BuildContext context, Color foreground) {
    final Color? fill = tools.fillColor;
    return MenuAnchor(
      menuChildren: <Widget>[
        MenuItemButton(leadingIcon: const Icon(Icons.format_color_reset_rounded), onPressed: () => tools.fillColor = null, child: Text(U.s.noFill)),
        MenuItemButton(leadingIcon: const Icon(Icons.opacity_rounded), onPressed: () => tools.fillColor = tools.strokeColor.withValues(alpha: 0.25), child: Text(U.s.lightFill)),
        MenuItemButton(leadingIcon: const Icon(Icons.format_color_fill_rounded), onPressed: () => tools.fillColor = tools.strokeColor, child: Text(U.s.solidFill)),
        MenuItemButton(leadingIcon: const Icon(Icons.crop_din_rounded), onPressed: () => tools.fillColor = const Color(0xFFFFFFFF), child: Text(U.s.whiteFill)),
      ],
      builder: (BuildContext context, MenuController controller, Widget? child) => IconButton(
        tooltip: U.s.fill,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        icon: fill == null
            ? Icon(Icons.format_color_reset_rounded, color: foreground)
            : Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: foreground.withValues(alpha: 0.5), width: 1.5),
                ),
              ),
      ),
    );
  }

  Widget _styleButton(BuildContext context, Color foreground) => MenuAnchor(
    menuChildren: <Widget>[
      SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AnimatedBuilder(
            animation: tools,
            builder: (BuildContext context, Widget? child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _slider(U.s.thickness, tools.strokeWidth, 0.5, 24, (double value) => tools.strokeWidth = value),
                _slider(U.s.opacity, tools.opacity, 0.1, 1, (double value) => tools.opacity = value, percent: true),
                _slider(U.s.fontSize, tools.fontSize, 8, 72, (double value) => tools.fontSize = value),
                SwitchListTile(dense: true, contentPadding: EdgeInsets.zero, value: tools.dashed, title: Text(U.s.dashed), onChanged: (bool value) => tools.dashed = value),
                SwitchListTile(dense: true, contentPadding: EdgeInsets.zero, value: tools.bold, title: Text(U.s.bold), onChanged: (bool value) => tools.bold = value),
                SwitchListTile(dense: true, contentPadding: EdgeInsets.zero, value: tools.constrain, title: Text(U.s.keepProportions), onChanged: (bool value) => tools.constrain = value),
                if (showVideoDuration) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(U.s.showFor, style: Theme.of(context).textTheme.labelLarge),
                  Wrap(
                    spacing: 6,
                    children: <int>[2, 5, 10, 30, 0]
                        .map(
                          (int seconds) => ChoiceChip(
                            label: Text(seconds == 0 ? "∞" : "${seconds}s"),
                            selected: tools.videoDuration.inSeconds == seconds,
                            onSelected: (bool _) => tools.videoDuration = Duration(seconds: seconds),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
    builder: (BuildContext context, MenuController controller, Widget? child) => IconButton(
      tooltip: U.s.settings,
      onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      icon: Icon(Icons.line_weight_rounded, color: foreground),
    ),
  );

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, {bool percent = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(percent ? "${(value * 100).round()}%" : value.toStringAsFixed(value < 10 ? 1 : 0)),
        ],
      ),
      Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
    ],
  );
}
