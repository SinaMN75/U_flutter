import "dart:math" as math;

import "package:u/utilities.dart";

/// What tapping/dragging on the map does while drawing.
enum UMapDrawMode { none, select, point, line, polygon, rectangle, circle, freehand, measureDistance, measureArea }

/// Kind of a drawn shape.
enum UMapShapeKind { point, line, polygon, circle }

/// A drawn shape.
class UMapShape {
  const UMapShape({required this.id, required this.kind, required this.points, this.radius = 0, this.color = const Color(0xFF1A73E8), this.label, this.measure = false});

  final String id;
  final UMapShapeKind kind;

  /// Vertices (circle: its centre).
  final List<LatLng> points;

  /// Circle radius in metres.
  final double radius;
  final Color color;
  final String? label;

  /// Drawn by a measure tool (shows its length/area).
  final bool measure;

  UMapShape copyWith({List<LatLng>? points, double? radius, Color? color, String? label}) =>
      UMapShape(id: id, kind: kind, points: points ?? this.points, radius: radius ?? this.radius, color: color ?? this.color, label: label ?? this.label, measure: measure);

  /// Length (lines) or perimeter in metres.
  double get length => kind == UMapShapeKind.circle ? 2 * math.pi * radius : (kind == UMapShapeKind.polygon ? UGeoMath.perimeter(points) : UGeoMath.length(points));

  /// Area in m² (polygons and circles).
  double get area => kind == UMapShapeKind.circle ? math.pi * radius * radius : (kind == UMapShapeKind.polygon ? UGeoMath.ringArea(points) : 0);

  /// As a GeoJSON-style feature.
  UGeoFeature toFeature() => UGeoFeature(
    id: id,
    geometry: switch (kind) {
      UMapShapeKind.point => UGeoPoint(points.first),
      UMapShapeKind.line => UGeoLine(points),
      UMapShapeKind.polygon => UGeoPolygon.simple(points),
      UMapShapeKind.circle => UGeoPolygon.simple(UGeoMath.circle(points.first, radius)),
    },
    properties: <String, dynamic>{
      "stroke": "#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, "0")}",
      "fill": "#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, "0")}",
      "name": ?label,
      if (kind == UMapShapeKind.circle) "radius": radius,
      if (kind == UMapShapeKind.circle) "center": <double>[points.first.longitude, points.first.latitude],
    },
  );
}

/// State of the drawing tools: mode, shapes, the shape being drawn, selection, undo/redo. Give it to UMap(drawController:).
class UMapDrawController extends ChangeNotifier {
  UMapDrawController({this.color = const Color(0xFF1A73E8)});

  /// Colour for new shapes.
  Color color;

  UMapDrawMode _mode = UMapDrawMode.none;
  List<UMapShape> _shapes = <UMapShape>[];
  final List<LatLng> _draft = <LatLng>[];
  String? _selected;
  final List<List<UMapShape>> _undo = <List<UMapShape>>[];
  final List<List<UMapShape>> _redo = <List<UMapShape>>[];
  bool _dragging = false;
  int _ids = 0;

  UMapDrawMode get mode => _mode;

  /// Every finished shape.
  List<UMapShape> get shapes => List<UMapShape>.unmodifiable(_shapes);

  /// Points of the shape being drawn.
  List<LatLng> get draft => List<LatLng>.unmodifiable(_draft);

  /// The selected shape.
  UMapShape? get selected => _shapes.where((UMapShape s) => s.id == _selected).firstOrNull;

  bool get canUndo => _undo.isNotEmpty;

  bool get canRedo => _redo.isNotEmpty;

  /// True when one-finger drags draw instead of panning (UMap turns map dragging off).
  bool get capturesDrag => _dragging || <UMapDrawMode>[UMapDrawMode.rectangle, UMapDrawMode.circle, UMapDrawMode.freehand].contains(_mode);

  /// Live length of the draft (metres).
  double get draftLength => UGeoMath.length(_draft);

  /// Live area of the draft (m²).
  double get draftArea => _draft.length < 3 ? 0 : UGeoMath.ringArea(_draft);

  /// Changes the tool (finishes any shape in progress).
  set mode(UMapDrawMode m) {
    if (_draft.isNotEmpty) finish();
    _mode = m;
    if (m != UMapDrawMode.select) _selected = null;
    notifyListeners();
  }

  void _snapshot() {
    _undo.add(List<UMapShape>.of(_shapes));
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
  }

  String _id() => "shape_${DateTime.now().microsecondsSinceEpoch}_${_ids++}";

  /// Handles a map tap; returns true when the tap was used for drawing.
  bool handleTap(LatLng p) {
    switch (_mode) {
      case UMapDrawMode.none:
        return false;
      case UMapDrawMode.select:
        final UMapShape? hit = _shapes.reversed.where((UMapShape s) => _hits(s, p)).firstOrNull;
        _selected = hit?.id;
        notifyListeners();
        return hit != null;
      case UMapDrawMode.point:
        _snapshot();
        _shapes = <UMapShape>[..._shapes, UMapShape(id: _id(), kind: UMapShapeKind.point, points: <LatLng>[p], color: color)];
        notifyListeners();
        return true;
      case UMapDrawMode.line:
      case UMapDrawMode.polygon:
      case UMapDrawMode.measureDistance:
      case UMapDrawMode.measureArea:
        _draft.add(p);
        notifyListeners();
        return true;
      case UMapDrawMode.rectangle:
      case UMapDrawMode.circle:
      case UMapDrawMode.freehand:
        return true;
    }
  }

  bool _hits(UMapShape s, LatLng p) => switch (s.kind) {
    UMapShapeKind.point => UGeoMath.distance(s.points.first, p) < 30,
    UMapShapeKind.line => UGeoMath.distanceToLine(p, s.points) < 25,
    UMapShapeKind.polygon => UGeoMath.ringContains(s.points, p),
    UMapShapeKind.circle => UGeoMath.distance(s.points.first, p) <= s.radius,
  };

  /// Saves the shape in progress (lines need 2 points, polygons 3).
  void finish() {
    final bool polygon = _mode == UMapDrawMode.polygon || _mode == UMapDrawMode.measureArea;
    if (_draft.length >= (polygon ? 3 : 2)) {
      _snapshot();
      _shapes = <UMapShape>[
        ..._shapes,
        UMapShape(
          id: _id(),
          kind: polygon ? UMapShapeKind.polygon : UMapShapeKind.line,
          points: List<LatLng>.of(_draft),
          color: color,
          measure: _mode == UMapDrawMode.measureArea || _mode == UMapDrawMode.measureDistance,
        ),
      ];
    }
    _draft.clear();
    notifyListeners();
  }

  /// Drops the shape in progress.
  void cancel() {
    _draft.clear();
    notifyListeners();
  }

  /// Removes the last draft point.
  void removeLastPoint() {
    if (_draft.isNotEmpty) _draft.removeLast();
    notifyListeners();
  }

  /// Starts a drag shape (rectangle/circle/freehand) — used by UMapDrawLayer.
  void dragStart(LatLng p) {
    _draft
      ..clear()
      ..add(p);
    notifyListeners();
  }

  /// Continues a drag shape.
  void dragUpdate(LatLng p) {
    if (_draft.isEmpty) return;
    if (_mode == UMapDrawMode.freehand) {
      _draft.add(p);
    } else if (_draft.length == 1) {
      _draft.add(p);
    } else {
      _draft[1] = p;
    }
    notifyListeners();
  }

  /// Finishes a drag shape.
  void dragEnd() {
    if (_draft.length < 2) return cancel();
    _snapshot();
    final LatLng a = _draft.first;
    final LatLng b = _draft.last;
    final UMapShape shape = switch (_mode) {
      UMapDrawMode.rectangle => UMapShape(id: _id(), kind: UMapShapeKind.polygon, points: UGeoMath.boundsRing(LatLngBounds(a, b)), color: color),
      UMapDrawMode.circle => UMapShape(id: _id(), kind: UMapShapeKind.circle, points: <LatLng>[a], radius: UGeoMath.distance(a, b), color: color),
      _ => UMapShape(id: _id(), kind: UMapShapeKind.line, points: UGeoMath.simplify(UGeoMath.smooth(List<LatLng>.of(_draft), iterations: 1), 2), color: color),
    };
    _shapes = <UMapShape>[..._shapes, shape];
    _draft.clear();
    notifyListeners();
  }

  /// Starts moving a vertex of the selected shape (one undo step per drag).
  void vertexDragStart() {
    _dragging = true;
    _snapshot();
    notifyListeners();
  }

  /// Moves vertex [index] of shape [id].
  void moveVertex(String id, int index, LatLng p) {
    _shapes = _shapes.map((UMapShape s) {
      if (s.id != id) return s;
      if (s.kind == UMapShapeKind.circle) return index == 0 ? s.copyWith(points: <LatLng>[p]) : s.copyWith(radius: UGeoMath.distance(s.points.first, p));
      final List<LatLng> pts = List<LatLng>.of(s.points);
      final bool closed = s.kind == UMapShapeKind.polygon && pts.length > 1 && pts.first == pts.last;
      pts[index] = p;
      if (closed && index == 0) pts[pts.length - 1] = p;
      return s.copyWith(points: pts);
    }).toList();
    notifyListeners();
  }

  /// Ends a vertex drag.
  void vertexDragEnd() {
    _dragging = false;
    notifyListeners();
  }

  /// Inserts a vertex after [index] (from a midpoint handle).
  void insertVertex(String id, int index, LatLng p) {
    _snapshot();
    _shapes = _shapes.map((UMapShape s) => s.id == id ? s.copyWith(points: List<LatLng>.of(s.points)..insert(index + 1, p)) : s).toList();
    notifyListeners();
  }

  /// Removes a vertex (keeps at least 2 for lines, 3 for polygons).
  void removeVertex(String id, int index) {
    final UMapShape? s = _shapes.where((UMapShape x) => x.id == id).firstOrNull;
    if (s == null || s.points.length <= (s.kind == UMapShapeKind.polygon ? 4 : 2)) return;
    _snapshot();
    _shapes = _shapes.map((UMapShape x) => x.id == id ? x.copyWith(points: List<LatLng>.of(x.points)..removeAt(index)) : x).toList();
    notifyListeners();
  }

  /// Deletes the selected shape.
  void deleteSelected() {
    if (_selected == null) return;
    _snapshot();
    _shapes = _shapes.where((UMapShape s) => s.id != _selected).toList();
    _selected = null;
    notifyListeners();
  }

  /// Deletes everything.
  void clear() {
    _snapshot();
    _shapes = <UMapShape>[];
    _draft.clear();
    _selected = null;
    notifyListeners();
  }

  /// Undoes the last change.
  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_shapes);
    _shapes = _undo.removeLast();
    notifyListeners();
  }

  /// Redoes an undone change.
  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_shapes);
    _shapes = _redo.removeLast();
    notifyListeners();
  }

  /// Replaces all shapes (e.g. loaded from storage).
  void setShapes(List<UMapShape> shapes) {
    _snapshot();
    _shapes = List<UMapShape>.of(shapes);
    notifyListeners();
  }

  /// Shapes as GeoJSON text.
  String toGeoJson() => UGeoJsonCodec.encode(UGeoFeatureCollection(_shapes.map((UMapShape s) => s.toFeature()).toList()));

  /// Loads shapes from GeoJSON (points, lines, polygons; circles saved by [toGeoJson] come back as circles).
  void loadGeoJson(String text) {
    final List<UMapShape> loaded = <UMapShape>[];
    for (final UGeoFeature f in UGeoJsonCodec.decode(text).features) {
      final Color c = UMapStyleExpr.color(f.properties["stroke"]?.toString()) ?? color;
      final UGeoGeometry g = f.geometry;
      final List<dynamic>? center = f.properties["center"] as List<dynamic>?;
      if (center != null && f.properties["radius"] is num) {
        loaded.add(UMapShape(id: _id(), kind: UMapShapeKind.circle, points: <LatLng>[LatLng((center[1] as num).toDouble(), (center[0] as num).toDouble())], radius: (f.properties["radius"] as num).toDouble(), color: c));
      } else if (g is UGeoPoint) {
        loaded.add(UMapShape(id: _id(), kind: UMapShapeKind.point, points: <LatLng>[g.point], color: c, label: f.name));
      } else if (g is UGeoLine) {
        loaded.add(UMapShape(id: _id(), kind: UMapShapeKind.line, points: g.points, color: c, label: f.name));
      } else if (g is UGeoPolygon) {
        loaded.add(UMapShape(id: _id(), kind: UMapShapeKind.polygon, points: g.outer, color: c, label: f.name));
      }
    }
    setShapes(loaded);
  }

  /// Selects a shape by id (null clears).
  void select(String? id) {
    _selected = id;
    notifyListeners();
  }
}

/// Draws a [UMapDrawController]'s shapes, the shape in progress, editing handles and live measurements. UMap adds it for you.
class UMapDrawLayer extends StatelessWidget {
  const UMapDrawLayer({required this.controller, this.persian = false, super.key});

  final UMapDrawController controller;
  final bool persian;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (BuildContext context, _) {
      final MapCamera camera = MapCamera.of(context);
      final List<UMapShape> shapes = controller.shapes;
      final UMapShape? sel = controller.selected;
      final List<LatLng> draft = controller.draft;
      final UMapDrawMode mode = controller.mode;
      final Color color = controller.color;
      final List<UMapLabel> labels = <UMapLabel>[
        for (final UMapShape s in shapes.where((UMapShape s) => s.measure))
          UMapLabel(
            point: s.kind == UMapShapeKind.polygon ? UGeoMath.polylabel(<List<LatLng>>[s.points]) : s.points.last,
            text: s.kind == UMapShapeKind.polygon ? UMapFormat.area(s.area, persian: persian) : UMapFormat.distance(s.length, persian: persian),
            priority: 10,
            background: Colors.white.withValues(alpha: 0.9),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        if (draft.length > 1 && mode != UMapDrawMode.freehand)
          UMapLabel(
            point: draft.last,
            offset: const Offset(0, -24),
            text: switch (mode) {
              UMapDrawMode.circle => UMapFormat.distance(UGeoMath.distance(draft.first, draft.last), persian: persian),
              UMapDrawMode.polygon || UMapDrawMode.measureArea || UMapDrawMode.rectangle =>
                "${UMapFormat.area(mode == UMapDrawMode.rectangle ? UGeoMath.ringArea(UGeoMath.boundsRing(LatLngBounds(draft.first, draft.last))) : controller.draftArea, persian: persian)} · ${UMapFormat.distance(controller.draftLength, persian: persian)}",
              _ => UMapFormat.distance(controller.draftLength, persian: persian),
            },
            priority: 20,
            background: Colors.black.withValues(alpha: 0.75),
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
      ];
      return Stack(
        children: <Widget>[
          PolygonLayer<Object>(
            polygons: <Polygon<Object>>[
              for (final UMapShape s in shapes)
                if (s.kind == UMapShapeKind.polygon || s.kind == UMapShapeKind.circle)
                  Polygon<Object>(
                    points: s.kind == UMapShapeKind.circle ? UGeoMath.circle(s.points.first, s.radius) : s.points,
                    color: s.color.withValues(alpha: s.id == sel?.id ? 0.3 : 0.18),
                    borderColor: s.color,
                    borderStrokeWidth: s.id == sel?.id ? 3 : 2,
                  ),
              if (draft.length > 2 && (mode == UMapDrawMode.polygon || mode == UMapDrawMode.measureArea))
                Polygon<Object>(points: draft, color: color.withValues(alpha: 0.12), borderColor: color, borderStrokeWidth: 2, pattern: const StrokePattern.dotted()),
              if (draft.length > 1 && mode == UMapDrawMode.rectangle) Polygon<Object>(points: UGeoMath.boundsRing(LatLngBounds(draft.first, draft.last)), color: color.withValues(alpha: 0.15), borderColor: color, borderStrokeWidth: 2),
              if (draft.length > 1 && mode == UMapDrawMode.circle)
                Polygon<Object>(points: UGeoMath.circle(draft.first, UGeoMath.distance(draft.first, draft.last)), color: color.withValues(alpha: 0.15), borderColor: color, borderStrokeWidth: 2),
            ],
          ),
          PolylineLayer<Object>(
            polylines: <Polyline<Object>>[
              for (final UMapShape s in shapes)
                if (s.kind == UMapShapeKind.line) Polyline<Object>(points: s.points, color: s.color, strokeWidth: s.id == sel?.id ? 6 : 4),
              if (draft.length > 1 && <UMapDrawMode>[UMapDrawMode.line, UMapDrawMode.measureDistance, UMapDrawMode.freehand].contains(mode))
                Polyline<Object>(points: draft, color: color, strokeWidth: 4, pattern: mode == UMapDrawMode.freehand ? const StrokePattern.solid() : StrokePattern.dashed(segments: const <double>[10, 6])),
            ],
          ),
          MarkerLayer(
            markers: <Marker>[
              for (final UMapShape s in shapes.where((UMapShape s) => s.kind == UMapShapeKind.point))
                Marker(point: s.points.first, width: 36, height: 36, alignment: Alignment.topCenter, child: Icon(Icons.location_on, color: s.color, size: 36)),
              for (final LatLng p in draft.length < 300 && mode != UMapDrawMode.freehand ? draft : const <LatLng>[])
                Marker(
                  point: p,
                  width: 14,
                  height: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
                  ),
                ),
            ],
          ),
          if (labels.isNotEmpty) UMapLabelLayer(labels: labels),
          if (sel != null && mode == UMapDrawMode.select && sel.kind != UMapShapeKind.point) _Handles(controller: controller, shape: sel),
          if (controller.capturesDrag && mode != UMapDrawMode.select)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (DragStartDetails d) => controller.dragStart(camera.screenOffsetToLatLng(d.localPosition)),
              onPanUpdate: (DragUpdateDetails d) => controller.dragUpdate(camera.screenOffsetToLatLng(d.localPosition)),
              onPanEnd: (_) => controller.dragEnd(),
              child: const SizedBox.expand(),
            ),
        ],
      );
    },
  );
}

class _Handles extends StatelessWidget {
  const _Handles({required this.controller, required this.shape});

  final UMapDrawController controller;
  final UMapShape shape;

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    final bool closed = shape.kind == UMapShapeKind.polygon && shape.points.length > 1 && shape.points.first == shape.points.last;
    final List<LatLng> vertices = shape.kind == UMapShapeKind.circle
        ? <LatLng>[shape.points.first, UGeoMath.destination(shape.points.first, shape.radius, 90)]
        : (closed ? shape.points.sublist(0, shape.points.length - 1) : shape.points);
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    LatLng toLatLng(Offset global) => camera.screenOffsetToLatLng(box?.globalToLocal(global) ?? global);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (int i = 0; i < vertices.length; i++)
          UMapPinned(
            point: vertices[i],
            size: const Size(28, 28),
            child: GestureDetector(
              onPanStart: (_) => controller.vertexDragStart(),
              onPanUpdate: (DragUpdateDetails d) => controller.moveVertex(shape.id, i, toLatLng(d.globalPosition)),
              onPanEnd: (_) => controller.vertexDragEnd(),
              onLongPress: shape.kind == UMapShapeKind.circle ? null : () => controller.removeVertex(shape.id, i),
              child: Center(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: shape.color, width: 3)),
                ),
              ),
            ),
          ),
        if (shape.kind != UMapShapeKind.circle)
          for (int i = 0; i < vertices.length - (closed ? 0 : 1); i++)
            UMapPinned(
              point: UGeoMath.midpoint(vertices[i], vertices[(i + 1) % vertices.length]),
              size: const Size(24, 24),
              child: GestureDetector(
                onTap: () => controller.insertVertex(shape.id, i, UGeoMath.midpoint(vertices[i], vertices[(i + 1) % vertices.length])),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: shape.color.withValues(alpha: 0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Toolbar for a [UMapDrawController]: tools, finish, undo/redo, delete, with the live measurement.
class UMapDrawToolbar extends StatelessWidget {
  const UMapDrawToolbar({
    required this.controller,
    this.tools = const <UMapDrawMode>[
      UMapDrawMode.select,
      UMapDrawMode.point,
      UMapDrawMode.line,
      UMapDrawMode.polygon,
      UMapDrawMode.rectangle,
      UMapDrawMode.circle,
      UMapDrawMode.freehand,
      UMapDrawMode.measureDistance,
      UMapDrawMode.measureArea,
    ],
    this.persian = false,
    super.key,
  });

  final UMapDrawController controller;
  final List<UMapDrawMode> tools;
  final bool persian;

  static IconData icon(UMapDrawMode m) => switch (m) {
    UMapDrawMode.none => Icons.pan_tool_outlined,
    UMapDrawMode.select => Icons.near_me_outlined,
    UMapDrawMode.point => Icons.add_location_alt_outlined,
    UMapDrawMode.line => Icons.timeline,
    UMapDrawMode.polygon => Icons.pentagon_outlined,
    UMapDrawMode.rectangle => Icons.crop_square,
    UMapDrawMode.circle => Icons.circle_outlined,
    UMapDrawMode.freehand => Icons.gesture,
    UMapDrawMode.measureDistance => Icons.straighten,
    UMapDrawMode.measureArea => Icons.square_foot,
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (BuildContext context, _) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      final bool drafting = controller.draft.isNotEmpty;
      return Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: "Pan",
                isSelected: controller.mode == UMapDrawMode.none,
                icon: Icon(icon(UMapDrawMode.none)),
                onPressed: () => controller.mode = UMapDrawMode.none,
              ),
              for (final UMapDrawMode m in tools)
                IconButton(
                  tooltip: m.name,
                  isSelected: controller.mode == m,
                  color: controller.mode == m ? scheme.primary : null,
                  icon: Icon(icon(m)),
                  onPressed: () => controller.mode = m,
                ),
              const SizedBox(height: 32, child: VerticalDivider()),
              if (drafting) IconButton(tooltip: "Finish", icon: const Icon(Icons.check), onPressed: controller.finish),
              if (drafting) IconButton(tooltip: "Remove last point", icon: const Icon(Icons.backspace_outlined), onPressed: controller.removeLastPoint),
              IconButton(tooltip: "Undo", icon: const Icon(Icons.undo), onPressed: controller.canUndo ? controller.undo : null),
              IconButton(tooltip: "Redo", icon: const Icon(Icons.redo), onPressed: controller.canRedo ? controller.redo : null),
              IconButton(tooltip: "Delete", icon: const Icon(Icons.delete_outline), onPressed: controller.selected == null ? null : controller.deleteSelected),
            ],
          ),
        ),
      );
    },
  );
}

/// Draw arrows, pen strokes and text on a map screenshot, then export it (share a marked-up map).
class UMapAnnotator extends StatefulWidget {
  const UMapAnnotator({required this.image, this.onDone, super.key});

  /// PNG bytes (e.g. from UMap(captureController:).capture()).
  final Uint8List image;

  /// Gets the annotated PNG.
  final void Function(Uint8List png)? onDone;

  @override
  State<UMapAnnotator> createState() => _UMapAnnotatorState();
}

enum _Tool { pen, arrow, text }

class _UMapAnnotatorState extends State<UMapAnnotator> {
  final List<(_Tool, List<Offset>, Color, String?)> _items = <(_Tool, List<Offset>, Color, String?)>[];
  final UWidgetToImageController _capture = UWidgetToImageController();
  _Tool _tool = _Tool.arrow;
  Color _color = const Color(0xFFE53935);

  Future<void> _addText(Offset at) async {
    final TextEditingController t = TextEditingController();
    final String? text = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: TextField(controller: t, autofocus: true),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(context).pop(t.text), child: const Text("OK"))],
      ),
    );
    t.dispose();
    if (text != null && text.isNotEmpty) setState(() => _items.add((_Tool.text, <Offset>[at], _color, text)));
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Expanded(
        child: UWidgetToImage(
          controller: _capture,
          child: GestureDetector(
            onTapUp: _tool == _Tool.text ? (TapUpDetails d) => _addText(d.localPosition) : null,
            onPanStart: _tool == _Tool.text ? null : (DragStartDetails d) => setState(() => _items.add((_tool, <Offset>[d.localPosition], _color, null))),
            onPanUpdate: _tool == _Tool.text ? null : (DragUpdateDetails d) => setState(() => _items.last.$2.add(d.localPosition)),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.memory(widget.image, fit: BoxFit.contain),
                CustomPaint(painter: _AnnotationPainter(List<(_Tool, List<Offset>, Color, String?)>.of(_items))),
              ],
            ),
          ),
        ),
      ),
      Material(
        elevation: 3,
        child: Row(
          children: <Widget>[
            IconButton(isSelected: _tool == _Tool.arrow, icon: const Icon(Icons.north_east), onPressed: () => setState(() => _tool = _Tool.arrow)),
            IconButton(isSelected: _tool == _Tool.pen, icon: const Icon(Icons.edit), onPressed: () => setState(() => _tool = _Tool.pen)),
            IconButton(isSelected: _tool == _Tool.text, icon: const Icon(Icons.text_fields), onPressed: () => setState(() => _tool = _Tool.text)),
            for (final Color c in const <Color>[Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047), Colors.black])
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: _color == c ? Colors.amber : Colors.white, width: 3)),
                ),
              ),
            const Spacer(),
            IconButton(icon: const Icon(Icons.undo), onPressed: _items.isEmpty ? null : () => setState(_items.removeLast)),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                final Uint8List? png = await _capture.capture();
                if (png != null) widget.onDone?.call(png);
              },
            ),
          ],
        ),
      ),
    ],
  );
}

class _AnnotationPainter extends CustomPainter {
  _AnnotationPainter(this.items);

  final List<(_Tool, List<Offset>, Color, String?)> items;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (_Tool tool, List<Offset> pts, Color color, String? text) in items) {
      final Paint p = Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      switch (tool) {
        case _Tool.pen:
          canvas.drawPath(Path()..addPolygon(pts, false), p);
        case _Tool.arrow:
          if (pts.length < 2) continue;
          final Offset a = pts.first;
          final Offset b = pts.last;
          canvas.drawLine(a, b, p);
          final double angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
          for (final double s in <double>[2.6, -2.6]) {
            canvas.drawLine(b, b + Offset(math.cos(angle + s), math.sin(angle + s)) * 18, p);
          }
        case _Tool.text:
          final TextPainter tp = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700, shadows: const <Shadow>[Shadow(color: Colors.white, blurRadius: 4)]),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, pts.first);
      }
    }
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}
