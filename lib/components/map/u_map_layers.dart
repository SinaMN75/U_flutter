import "dart:math" as math;
import "dart:ui" as ui;

import "package:u/utilities.dart";

/// Paints in map space (rotates with the map); [paint] gets each point's pixel offset from the camera.
class _MapPaint extends StatelessWidget {
  const _MapPaint({required this.painter});

  final CustomPainter painter;

  @override
  Widget build(BuildContext context) => MobileLayerTransformer(child: IgnorePointer(child: CustomPaint(size: Size.infinite, painter: painter)));
}

List<Color> _palette(List<Color> stops, int n) => List<Color>.generate(n, (int i) {
  final double t = i / (n - 1) * (stops.length - 1);
  final int k = t.floor().clamp(0, stops.length - 2);
  return Color.lerp(stops[k], stops[k + 1], t - k)!;
});

/// Default heat colours (transparent blue → cyan → lime → yellow → red).
const List<Color> uHeatColors = <Color>[Color(0x000000FF), Color(0xFF00BFFF), Color(0xFF00FF7F), Color(0xFFFFFF00), Color(0xFFFF8C00), Color(0xFFFF0000)];

/// Default sequential colours for choropleths and hexbins (light yellow → dark red).
const List<Color> uSequentialColors = <Color>[Color(0xFFFFFFCC), Color(0xFFFED976), Color(0xFFFD8D3C), Color(0xFFE31A1C), Color(0xFF800026)];

// ------------------------------------------------------------------------------------------------ heatmap

/// Heatmap (kernel density) of points with optional weights; recomputed as you pan/zoom, smooth while gesturing.
class UMapHeatmapLayer extends StatefulWidget {
  const UMapHeatmapLayer({required this.points, this.weights, this.radius = 28, this.colors = uHeatColors, this.opacity = 0.75, this.maxIntensity, super.key});

  final List<LatLng> points;

  /// Same length as [points]; 1 each when null.
  final List<double>? weights;

  /// Kernel radius in pixels.
  final double radius;
  final List<Color> colors;
  final double opacity;

  /// Intensity that maps to the hottest colour (auto when null).
  final double? maxIntensity;

  @override
  State<UMapHeatmapLayer> createState() => _UMapHeatmapLayerState();
}

class _UMapHeatmapLayerState extends State<UMapHeatmapLayer> {
  static const double _cell = 4;
  ui.Image? _image;
  LatLng? _origin;
  double _zoom = 0;
  Timer? _timer;
  String _key = "";
  late List<Color> _colors = _palette(widget.colors, 256);

  @override
  void didUpdateWidget(UMapHeatmapLayer old) {
    super.didUpdateWidget(old);
    if (old.colors != widget.colors) _colors = _palette(widget.colors, 256);
    if (!identical(old.points, widget.points) || old.radius != widget.radius) _key = "";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _image?.dispose();
    super.dispose();
  }

  void _schedule(MapCamera camera) {
    final String key = "${camera.center.latitude.toStringAsFixed(6)}|${camera.center.longitude.toStringAsFixed(6)}|${camera.zoom.toStringAsFixed(3)}|${camera.size}";
    if (key == _key) return;
    _key = key;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 80), () => _render(camera));
  }

  Future<void> _render(MapCamera camera) async {
    final Size size = camera.size;
    final int w = (size.width / _cell).ceil() + 2;
    final int h = (size.height / _cell).ceil() + 2;
    if (w <= 2 || h <= 2) return;
    final Float32List grid = Float32List(w * h);
    final double r = widget.radius / _cell;
    final int ri = r.ceil();
    for (int i = 0; i < widget.points.length; i++) {
      final Offset o = camera.getOffsetFromOrigin(widget.points[i]);
      final double gx = o.dx / _cell;
      final double gy = o.dy / _cell;
      if (gx < -ri || gy < -ri || gx > w + ri || gy > h + ri) continue;
      final double weight = widget.weights == null ? 1 : widget.weights![i];
      for (int y = math.max(0, (gy - ri).floor()); y <= math.min(h - 1, (gy + ri).ceil()); y++) {
        for (int x = math.max(0, (gx - ri).floor()); x <= math.min(w - 1, (gx + ri).ceil()); x++) {
          final double d2 = ((x - gx) * (x - gx) + (y - gy) * (y - gy)) / (r * r);
          if (d2 >= 1) continue;
          final double k = 1 - d2;
          grid[y * w + x] += weight * k * k;
        }
      }
    }
    double max = widget.maxIntensity ?? 0;
    if (widget.maxIntensity == null) {
      for (final double v in grid) {
        if (v > max) max = v;
      }
    }
    if (max <= 0) max = 1;
    final Uint8List rgba = Uint8List(w * h * 4);
    for (int i = 0; i < grid.length; i++) {
      final double t = (grid[i] / max).clamp(0, 1);
      if (t <= 0.004) continue;
      final Color c = _colors[(t * 255).round()];
      rgba[i * 4] = (c.r * 255).round();
      rgba[i * 4 + 1] = (c.g * 255).round();
      rgba[i * 4 + 2] = (c.b * 255).round();
      rgba[i * 4 + 3] = (math.min(1, t * 1.6) * c.a * widget.opacity * 255).round();
    }
    final Completer<ui.Image> done = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, done.complete);
    final ui.Image image = await done.future;
    if (!mounted) return image.dispose();
    setState(() {
      _image?.dispose();
      _image = image;
      _origin = camera.unprojectAtZoom(camera.pixelOrigin);
      _zoom = camera.zoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    _schedule(camera);
    if (_image == null || _origin == null) return const SizedBox.shrink();
    final double scale = math.pow(2, camera.zoom - _zoom).toDouble();
    return _MapPaint(painter: _ImagePainter(_image!, camera.getOffsetFromOrigin(_origin!), _cell * scale));
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.image, this.topLeft, this.cell);

  final ui.Image image;
  final Offset topLeft;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(topLeft.dx, topLeft.dy, image.width * cell, image.height * cell),
    Paint()..filterQuality = FilterQuality.medium,
  );

  @override
  bool shouldRepaint(_ImagePainter old) => old.image != image || old.topLeft != topLeft || old.cell != cell;
}

// ------------------------------------------------------------------------------------------------ hexbin

/// Points aggregated into screen hexagons coloured by count (or summed weight), optionally with numbers.
class UMapHexbinLayer extends StatelessWidget {
  const UMapHexbinLayer({required this.points, this.weights, this.radius = 22, this.colors = uSequentialColors, this.opacity = 0.75, this.showCounts = false, super.key});

  final List<LatLng> points;
  final List<double>? weights;

  /// Hexagon radius in pixels.
  final double radius;
  final List<Color> colors;
  final double opacity;
  final bool showCounts;

  @override
  Widget build(BuildContext context) => _MapPaint(painter: _HexPainter(this, MapCamera.of(context)));
}

class _HexPainter extends CustomPainter {
  _HexPainter(this.layer, this.camera);

  final UMapHexbinLayer layer;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = layer.radius;
    final double w = math.sqrt(3) * r;
    final Map<(int, int), double> bins = <(int, int), double>{};
    final Rect view = Rect.fromLTWH(-r * 2, -r * 2, size.width + r * 4, size.height + r * 4);
    for (int i = 0; i < layer.points.length; i++) {
      final Offset p = camera.getOffsetFromOrigin(layer.points[i]);
      if (!view.contains(p)) continue;
      final double q = (math.sqrt(3) / 3 * p.dx - p.dy / 3) / r;
      final double rr = (2 / 3 * p.dy) / r;
      final (int qi, int ri) = _round(q, rr);
      bins[(qi, ri)] = (bins[(qi, ri)] ?? 0) + (layer.weights == null ? 1 : layer.weights![i]);
    }
    if (bins.isEmpty) return;
    final double max = bins.values.reduce(math.max);
    final List<Color> palette = _palette(layer.colors, 64);
    for (final MapEntry<(int, int), double> b in bins.entries) {
      final Offset c = Offset(w * (b.key.$1 + b.key.$2 / 2), 1.5 * r * b.key.$2);
      final Path hex = Path();
      for (int k = 0; k < 6; k++) {
        final double a = math.pi / 180 * (60 * k - 30);
        final Offset v = c + Offset(math.cos(a), math.sin(a)) * (r - 1);
        k == 0 ? hex.moveTo(v.dx, v.dy) : hex.lineTo(v.dx, v.dy);
      }
      hex.close();
      final Color color = palette[((b.value / max) * 63).round()];
      canvas.drawPath(hex, Paint()..color = color.withValues(alpha: layer.opacity));
      if (layer.showCounts) {
        final TextPainter tp = TextPainter(
          text: TextSpan(text: b.value.round().toString(), style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas
          ..save()
          ..translate(c.dx, c.dy)
          ..rotate(-camera.rotationRad);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  static (int, int) _round(double q, double r) {
    final double s = -q - r;
    int rq = q.round();
    int rr = r.round();
    final int rs = s.round();
    final double dq = (rq - q).abs();
    final double dr = (rr - r).abs();
    final double ds = (rs - s).abs();
    if (dq > dr && dq > ds) {
      rq = -rr - rs;
    } else if (dr > ds) {
      rr = -rq - rs;
    }
    return (rq, rr);
  }

  @override
  bool shouldRepaint(_HexPainter old) => true;
}

// ------------------------------------------------------------------------------------------------ choropleth & GeoJSON

/// Polygons coloured by a value (population, sales…) with tap support; pair with [UMapLegend].
class UMapChoroplethLayer extends StatelessWidget {
  const UMapChoroplethLayer({required this.features, required this.valueOf, this.colors = uSequentialColors, this.min, this.max, this.opacity = 0.7, this.borderColor = Colors.white, this.onTap, super.key});

  final UGeoFeatureCollection features;
  final double? Function(UGeoFeature feature) valueOf;
  final List<Color> colors;
  final double? min;
  final double? max;
  final double opacity;
  final Color borderColor;
  final void Function(UGeoFeature feature)? onTap;

  /// Colour of a value given the range.
  static Color colorFor(double value, double min, double max, List<Color> colors) {
    final double t = max == min ? 0 : ((value - min) / (max - min)).clamp(0, 1);
    return _palette(colors, 64)[(t * 63).round()];
  }

  @override
  Widget build(BuildContext context) {
    final List<double> values = features.features.map(valueOf).whereType<double>().toList();
    final double lo = min ?? (values.isEmpty ? 0 : values.reduce(math.min));
    final double hi = max ?? (values.isEmpty ? 1 : values.reduce(math.max));
    return UMapGeoJsonLayer(
      data: features,
      onTap: onTap,
      polygonStyle: (UGeoFeature f) {
        final double? v = valueOf(f);
        return (v == null ? Colors.grey.withValues(alpha: 0.3) : colorFor(v, lo, hi, colors).withValues(alpha: opacity), borderColor, 1.0);
      },
    );
  }
}

/// Draws GeoJSON / KML / GPX features (simplestyle properties: stroke, fill, stroke-width, marker-color) with per-feature styling and taps.
class UMapGeoJsonLayer extends StatefulWidget {
  const UMapGeoJsonLayer({required this.data, this.onTap, this.polygonStyle, this.lineStyle, this.pointBuilder, this.defaultColor = const Color(0xFF3388FF), super.key});

  final UGeoFeatureCollection data;
  final void Function(UGeoFeature feature)? onTap;

  /// (fill, border, border width) per polygon feature.
  final (Color fill, Color border, double width) Function(UGeoFeature feature)? polygonStyle;

  /// (colour, width) per line feature.
  final (Color color, double width) Function(UGeoFeature feature)? lineStyle;

  /// Widget for point features (defaults to a coloured dot).
  final Widget Function(UGeoFeature feature)? pointBuilder;
  final Color defaultColor;

  @override
  State<UMapGeoJsonLayer> createState() => _UMapGeoJsonLayerState();
}

class _UMapGeoJsonLayerState extends State<UMapGeoJsonLayer> {
  final LayerHitNotifier<UGeoFeature> _polyHit = ValueNotifier<LayerHitResult<UGeoFeature>?>(null);
  final LayerHitNotifier<UGeoFeature> _lineHit = ValueNotifier<LayerHitResult<UGeoFeature>?>(null);

  static Color? _color(Object? hex, [Object? opacity]) {
    final Color? c = UMapStyleExpr.color(hex?.toString());
    if (c == null) return null;
    return opacity is num ? c.withValues(alpha: opacity.toDouble()) : c;
  }

  Iterable<List<List<LatLng>>> _polygons(UGeoGeometry g) sync* {
    switch (g) {
      case UGeoPolygon():
        yield g.rings;
      case UGeoMultiPolygon():
        yield* g.polygons;
      case UGeoCollection():
        for (final UGeoGeometry x in g.geometries) {
          yield* _polygons(x);
        }
      default:
    }
  }

  Iterable<List<LatLng>> _lines(UGeoGeometry g) sync* {
    switch (g) {
      case UGeoLine():
        yield g.points;
      case UGeoMultiLine():
        yield* g.lines;
      case UGeoCollection():
        for (final UGeoGeometry x in g.geometries) {
          yield* _lines(x);
        }
      default:
    }
  }

  Iterable<LatLng> _points(UGeoGeometry g) sync* {
    switch (g) {
      case UGeoPoint():
        yield g.point;
      case UGeoMultiPoint():
        yield* g.points;
      case UGeoCollection():
        for (final UGeoGeometry x in g.geometries) {
          yield* _points(x);
        }
      default:
    }
  }

  @override
  void dispose() {
    _polyHit.dispose();
    _lineHit.dispose();
    super.dispose();
  }

  void _tap(LayerHitNotifier<UGeoFeature> n) {
    final UGeoFeature? f = n.value?.hitValues.firstOrNull;
    if (f != null) widget.onTap?.call(f);
  }

  @override
  Widget build(BuildContext context) {
    final List<Polygon<UGeoFeature>> polygons = <Polygon<UGeoFeature>>[];
    final List<Polyline<UGeoFeature>> lines = <Polyline<UGeoFeature>>[];
    final List<Marker> markers = <Marker>[];
    for (final UGeoFeature f in widget.data.features) {
      final Map<String, dynamic> p = f.properties;
      for (final List<List<LatLng>> rings in _polygons(f.geometry)) {
        final (Color, Color, double) s =
            widget.polygonStyle?.call(f) ??
            (
              _color(p["fill"], p["fill-opacity"] ?? 0.3) ?? widget.defaultColor.withValues(alpha: 0.25),
              _color(p["stroke"], p["stroke-opacity"]) ?? widget.defaultColor,
              (p["stroke-width"] as num?)?.toDouble() ?? 2,
            );
        polygons.add(Polygon<UGeoFeature>(points: rings.first, holePointsList: rings.length > 1 ? rings.sublist(1) : null, color: s.$1, borderColor: s.$2, borderStrokeWidth: s.$3, hitValue: f));
      }
      for (final List<LatLng> l in _lines(f.geometry)) {
        final (Color, double) s = widget.lineStyle?.call(f) ?? (_color(p["stroke"], p["stroke-opacity"]) ?? widget.defaultColor, (p["stroke-width"] as num?)?.toDouble() ?? 3);
        lines.add(Polyline<UGeoFeature>(points: l, color: s.$1, strokeWidth: s.$2, hitValue: f));
      }
      for (final LatLng pt in _points(f.geometry)) {
        markers.add(
          Marker(
            point: pt,
            width: 28,
            height: 28,
            child: GestureDetector(
              onTap: widget.onTap == null ? null : () => widget.onTap!(f),
              child:
                  widget.pointBuilder?.call(f) ??
                  Semantics(
                    label: f.name,
                    child: Icon(Icons.location_on, color: _color(p["marker-color"]) ?? widget.defaultColor, size: 28),
                  ),
            ),
          ),
        );
      }
    }
    return Stack(
      children: <Widget>[
        if (polygons.isNotEmpty)
          GestureDetector(
            onTap: () => _tap(_polyHit),
            child: PolygonLayer<UGeoFeature>(polygons: polygons, hitNotifier: widget.onTap == null ? null : _polyHit),
          ),
        if (lines.isNotEmpty)
          GestureDetector(
            onTap: () => _tap(_lineHit),
            child: PolylineLayer<UGeoFeature>(polylines: lines, hitNotifier: widget.onTap == null ? null : _lineHit),
          ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}

// ------------------------------------------------------------------------------------------------ flows

/// One origin → destination flow.
class UMapFlow {
  const UMapFlow({required this.from, required this.to, this.weight = 1, this.color});

  final LatLng from;
  final LatLng to;
  final double weight;
  final Color? color;
}

/// Curved origin–destination arcs with moving particles (migration, deliveries, flights).
class UMapFlowLayer extends StatefulWidget {
  const UMapFlowLayer({required this.flows, this.color = const Color(0xFFFF6D00), this.maxWidth = 6, this.curvature = 0.25, this.animate = true, super.key});

  final List<UMapFlow> flows;
  final Color color;
  final double maxWidth;
  final double curvature;
  final bool animate;

  @override
  State<UMapFlowLayer> createState() => _UMapFlowLayerState();
}

class _UMapFlowLayerState extends State<UMapFlowLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    return AnimatedBuilder(animation: _c, builder: (BuildContext context, _) => _MapPaint(painter: _FlowPainter(widget, camera, _c.value)));
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(this.layer, this.camera, this.t);

  final UMapFlowLayer layer;
  final MapCamera camera;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (layer.flows.isEmpty) return;
    final double maxW = layer.flows.map((UMapFlow f) => f.weight).reduce(math.max);
    for (int i = 0; i < layer.flows.length; i++) {
      final UMapFlow f = layer.flows[i];
      final Offset a = camera.getOffsetFromOrigin(f.from);
      final Offset b = camera.getOffsetFromOrigin(f.to);
      final Offset mid = (a + b) / 2;
      final Offset d = b - a;
      final Offset ctrl = mid + Offset(-d.dy, d.dx) * layer.curvature;
      final Color color = f.color ?? layer.color;
      final double width = 1 + (layer.maxWidth - 1) * f.weight / maxW;
      final Path path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(a, b, <Color>[color.withValues(alpha: 0.15), color.withValues(alpha: 0.8)])
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      if (layer.animate) {
        for (int k = 0; k < 3; k++) {
          final double s = (t + k / 3 + i * 0.137) % 1;
          final double u = 1 - s;
          final Offset p = a * (u * u) + ctrl * (2 * u * s) + b * (s * s);
          canvas.drawCircle(p, width * 0.8 + 1, Paint()..color = Colors.white.withValues(alpha: 0.9));
          canvas.drawCircle(p, width * 0.6 + 0.5, Paint()..color = color);
        }
      }
      canvas.drawCircle(b, width + 1.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) => true;
}

// ------------------------------------------------------------------------------------------------ decorated lines

/// A styled line: casing, gradient by values, arrows, marching-ants animation.
class UMapStyledLine {
  const UMapStyledLine({required this.points, this.color = const Color(0xFF1A73E8), this.width = 6, this.casing, this.arrows = false, this.arrowSpacing = 80, this.dashed = false, this.marching = false, this.values, this.gradient});

  final List<LatLng> points;
  final Color color;
  final double width;

  /// Darker outline colour around the line.
  final Color? casing;

  /// Direction arrows every [arrowSpacing] pixels.
  final bool arrows;
  final double arrowSpacing;
  final bool dashed;

  /// Animated dashes moving along the line.
  final bool marching;

  /// One value per point (e.g. speed); coloured with [gradient].
  final List<double>? values;
  final List<Color>? gradient;
}

/// Lines with arrows, casing, speed-coloured gradients and marching ants (routes, traffic, tracks).
class UMapStyledLineLayer extends StatefulWidget {
  const UMapStyledLineLayer({required this.lines, super.key});

  final List<UMapStyledLine> lines;

  @override
  State<UMapStyledLineLayer> createState() => _UMapStyledLineLayerState();
}

class _UMapStyledLineLayerState extends State<UMapStyledLineLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    if (widget.lines.any((UMapStyledLine l) => l.marching)) _c.repeat();
  }

  @override
  void didUpdateWidget(UMapStyledLineLayer old) {
    super.didUpdateWidget(old);
    if (widget.lines.any((UMapStyledLine l) => l.marching)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    return AnimatedBuilder(animation: _c, builder: (BuildContext context, _) => _MapPaint(painter: _StyledLinePainter(widget.lines, camera, _c.value)));
  }
}

class _StyledLinePainter extends CustomPainter {
  _StyledLinePainter(this.lines, this.camera, this.phase);

  final List<UMapStyledLine> lines;
  final MapCamera camera;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    for (final UMapStyledLine l in lines) {
      if (l.points.length < 2) continue;
      final List<Offset> pts = l.points.map(camera.getOffsetFromOrigin).toList();
      final Path path = Path()..addPolygon(pts, false);
      if (l.casing != null) {
        canvas.drawPath(
          path,
          Paint()
            ..color = l.casing!
            ..strokeWidth = l.width + 3
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
      if (l.values != null && l.values!.length == pts.length) {
        final List<Color> palette = _palette(l.gradient ?? const <Color>[Color(0xFFE53935), Color(0xFFFFB300), Color(0xFF43A047)], 64);
        final double lo = l.values!.reduce(math.min);
        final double hi = l.values!.reduce(math.max);
        for (int i = 1; i < pts.length; i++) {
          final double v = (l.values![i] + l.values![i - 1]) / 2;
          canvas.drawLine(
            pts[i - 1],
            pts[i],
            Paint()
              ..color = palette[hi == lo ? 0 : ((v - lo) / (hi - lo) * 63).round()]
              ..strokeWidth = l.width
              ..strokeCap = StrokeCap.round,
          );
        }
      } else {
        final Paint paint = Paint()
          ..color = l.color
          ..strokeWidth = l.width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        if (l.dashed || l.marching) {
          final double dash = l.width * 2.5;
          for (final ui.PathMetric m in path.computeMetrics()) {
            for (double d = (l.marching ? phase * dash * 2 : 0) - dash * 2; d < m.length; d += dash * 2) {
              canvas.drawPath(m.extractPath(math.max(0, d), math.max(0, d + dash)), paint);
            }
          }
        } else {
          canvas.drawPath(path, paint);
        }
      }
      if (l.arrows) {
        final Paint arrow = Paint()..color = Colors.white;
        for (final ui.PathMetric m in path.computeMetrics()) {
          for (double d = l.arrowSpacing / 2; d < m.length; d += l.arrowSpacing) {
            final ui.Tangent? tan = m.getTangentForOffset(d);
            if (tan == null) continue;
            final double a = -tan.angle;
            final double s = l.width * 0.7;
            final Offset p = tan.position;
            final Path tri = Path()
              ..moveTo(p.dx + math.cos(a) * s, p.dy + math.sin(a) * s)
              ..lineTo(p.dx + math.cos(a + 2.5) * s, p.dy + math.sin(a + 2.5) * s)
              ..lineTo(p.dx + math.cos(a - 2.5) * s, p.dy + math.sin(a - 2.5) * s)
              ..close();
            canvas.drawPath(tri, arrow);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StyledLinePainter old) => true;
}

/// A line that draws itself from start to end (route reveal); [progress] lets you drive it yourself.
class UMapAnimatedLine extends StatelessWidget {
  const UMapAnimatedLine({required this.points, this.duration = const Duration(milliseconds: 1500), this.color = const Color(0xFF1A73E8), this.width = 6, this.progress, super.key});

  final List<LatLng> points;
  final Duration duration;
  final Color color;
  final double width;

  /// 0..1; animates automatically when null.
  final double? progress;

  List<LatLng> _part(double t) {
    if (t >= 1) return points;
    final double total = UGeoMath.length(points);
    return UGeoMath.slice(points, 0, total * t);
  }

  @override
  Widget build(BuildContext context) {
    Widget line(double t) {
      final List<LatLng> part = _part(t);
      return PolylineLayer<Object>(
        polylines: <Polyline<Object>>[if (part.length > 1) Polyline<Object>(points: part, color: color, strokeWidth: width)],
      );
    }

    if (progress != null) return line(progress!);
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(Object.hashAll(points)),
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (BuildContext context, double t, _) => line(t),
    );
  }
}

// ------------------------------------------------------------------------------------------------ pattern fills

/// Fill pattern of a polygon.
enum UMapFillPattern { hatch, crossHatch, dots, vertical, horizontal }

/// A polygon with a pattern fill (restricted zones, construction, flood risk).
class UMapPatternPolygon {
  const UMapPatternPolygon({required this.points, this.holes = const <List<LatLng>>[], this.pattern = UMapFillPattern.hatch, this.color = const Color(0xFFE53935), this.spacing = 10, this.borderWidth = 2});

  final List<LatLng> points;
  final List<List<LatLng>> holes;
  final UMapFillPattern pattern;
  final Color color;

  /// Pixels between pattern lines.
  final double spacing;
  final double borderWidth;
}

/// Polygons filled with hatches, cross-hatches, dots or stripes.
class UMapPatternPolygonLayer extends StatelessWidget {
  const UMapPatternPolygonLayer({required this.polygons, super.key});

  final List<UMapPatternPolygon> polygons;

  @override
  Widget build(BuildContext context) => _MapPaint(painter: _PatternPainter(polygons, MapCamera.of(context)));
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.polygons, this.camera);

  final List<UMapPatternPolygon> polygons;
  final MapCamera camera;

  @override
  void paint(Canvas canvas, Size size) {
    for (final UMapPatternPolygon p in polygons) {
      final Path path = Path()..fillType = PathFillType.evenOdd;
      path.addPolygon(p.points.map(camera.getOffsetFromOrigin).toList(), true);
      for (final List<LatLng> h in p.holes) {
        path.addPolygon(h.map(camera.getOffsetFromOrigin).toList(), true);
      }
      final Rect b = path.getBounds();
      final Paint line = Paint()
        ..color = p.color.withValues(alpha: 0.7)
        ..strokeWidth = 1.5;
      canvas
        ..save()
        ..clipPath(path);
      final double s = p.spacing;
      switch (p.pattern) {
        case UMapFillPattern.hatch:
        case UMapFillPattern.crossHatch:
          for (double x = b.left - b.height; x < b.right; x += s) {
            canvas.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), line);
            if (p.pattern == UMapFillPattern.crossHatch) canvas.drawLine(Offset(x, b.top), Offset(x + b.height, b.bottom), line);
          }
        case UMapFillPattern.dots:
          for (double y = b.top; y < b.bottom; y += s) {
            for (double x = b.left + (((y - b.top) ~/ s).isOdd ? s / 2 : 0); x < b.right; x += s) {
              canvas.drawCircle(Offset(x, y), 1.6, line);
            }
          }
        case UMapFillPattern.vertical:
          for (double x = b.left; x < b.right; x += s) {
            canvas.drawLine(Offset(x, b.top), Offset(x, b.bottom), line);
          }
        case UMapFillPattern.horizontal:
          for (double y = b.top; y < b.bottom; y += s) {
            canvas.drawLine(Offset(b.left, y), Offset(b.right, y), line);
          }
      }
      canvas
        ..restore()
        ..drawPath(
          path,
          Paint()
            ..color = p.color
            ..strokeWidth = p.borderWidth
            ..style = PaintingStyle.stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => true;
}

// ------------------------------------------------------------------------------------------------ text along paths

/// Text that follows a line (street names, river names), kept readable (never upside down). Right-to-left text follows the straightest part.
class UMapPathText {
  const UMapPathText({required this.points, required this.text, this.style = const TextStyle(fontSize: 13, color: Color(0xFF333333), fontWeight: FontWeight.w600), this.repeat = 0});

  final List<LatLng> points;
  final String text;
  final TextStyle style;

  /// Pixels between repeats along long lines (0 = once).
  final double repeat;
}

/// Layer of [UMapPathText].
class UMapPathTextLayer extends StatelessWidget {
  const UMapPathTextLayer({required this.items, this.halo = Colors.white, super.key});

  final List<UMapPathText> items;
  final Color? halo;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _PathTextPainter(items, MapCamera.of(context), halo)));
}

class _PathTextPainter extends CustomPainter {
  _PathTextPainter(this.items, this.camera, this.halo);

  final List<UMapPathText> items;
  final MapCamera camera;
  final Color? halo;

  static final RegExp _rtl = RegExp("[֐-ࣿ]");

  @override
  void paint(Canvas canvas, Size size) {
    for (final UMapPathText item in items) {
      List<Offset> pts = item.points.map(camera.latLngToScreenOffset).toList();
      if (pts.length < 2) continue;
      if (pts.last.dx < pts.first.dx) pts = pts.reversed.toList();
      final Path path = Path()..addPolygon(pts, false);
      final ui.PathMetric? metric = path.computeMetrics().firstOrNull;
      if (metric == null) continue;
      final bool rtl = _rtl.hasMatch(item.text);
      final TextPainter whole = TextPainter(
        text: TextSpan(text: item.text, style: item.style),
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      )..layout();
      if (whole.width > metric.length * 0.95) continue;
      final List<double> starts = item.repeat > 0
          ? <double>[for (double s = item.repeat / 2; s + whole.width < metric.length; s += item.repeat + whole.width) s]
          : <double>[(metric.length - whole.width) / 2];
      for (final double start in starts) {
        if (rtl) {
          final ui.Tangent? t = metric.getTangentForOffset(start + whole.width / 2);
          if (t == null) continue;
          double angle = -t.angle;
          if (angle > math.pi / 2) angle -= math.pi;
          if (angle < -math.pi / 2) angle += math.pi;
          canvas
            ..save()
            ..translate(t.position.dx, t.position.dy)
            ..rotate(angle);
          _haloPaint(canvas, item, whole, Offset(-whole.width / 2, -whole.height / 2), rtl);
          canvas.restore();
          continue;
        }
        double offset = start;
        for (final int rune in item.text.runes) {
          final String ch = String.fromCharCode(rune);
          final TextPainter tp = TextPainter(
            text: TextSpan(text: ch, style: item.style),
            textDirection: TextDirection.ltr,
          )..layout();
          final ui.Tangent? t = metric.getTangentForOffset(offset + tp.width / 2);
          if (t == null) break;
          canvas
            ..save()
            ..translate(t.position.dx, t.position.dy)
            ..rotate(-t.angle);
          _haloPaint(canvas, item, tp, Offset(-tp.width / 2, -tp.height / 2), false);
          canvas.restore();
          offset += tp.width;
        }
      }
    }
  }

  void _haloPaint(Canvas canvas, UMapPathText item, TextPainter tp, Offset o, bool rtl) {
    if (halo != null) {
      TextPainter(
          text: TextSpan(
            text: (tp.text! as TextSpan).text,
            style: UMapLabelLayer.haloStyle(item.style, halo!, 3),
          ),
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, o);
    }
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(_PathTextPainter old) => true;
}

// ------------------------------------------------------------------------------------------------ track playback

/// Replays a timed track: the part travelled so far plus a moving marker at the [UMapPlaybackController]'s time.
class UMapTrackPlayback extends StatelessWidget {
  const UMapTrackPlayback({required this.track, required this.controller, this.color = const Color(0xFF1A73E8), this.marker, super.key});

  /// Points with times.
  final List<UGeoTrackPoint> track;
  final UMapPlaybackController controller;
  final Color color;
  final Widget? marker;

  (List<LatLng>, LatLng?, double) _at(DateTime t) {
    final List<LatLng> done = <LatLng>[];
    for (int i = 0; i < track.length; i++) {
      final UGeoTrackPoint p = track[i];
      if (p.time == null || !p.time!.isAfter(t)) {
        done.add(p.point);
        continue;
      }
      if (i == 0 || track[i - 1].time == null) break;
      final UGeoTrackPoint a = track[i - 1];
      final double f = t.difference(a.time!).inMilliseconds / p.time!.difference(a.time!).inMilliseconds;
      final LatLng here = UGeoMath.interpolate(a.point, p.point, f.clamp(0, 1));
      done.add(here);
      return (done, here, UGeoMath.bearing(a.point, p.point));
    }
    return (done, done.isEmpty ? null : done.last, done.length > 1 ? UGeoMath.bearing(done[done.length - 2], done.last) : 0);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (BuildContext context, _) {
      final (List<LatLng> done, LatLng? here, double heading) = _at(controller.time);
      return Stack(
        children: <Widget>[
          PolylineLayer<Object>(
            polylines: <Polyline<Object>>[
              Polyline<Object>(points: track.map((UGeoTrackPoint p) => p.point).toList(), color: color.withValues(alpha: 0.25), strokeWidth: 4),
              if (done.length > 1) Polyline<Object>(points: done, color: color, strokeWidth: 5),
            ],
          ),
          if (here != null)
            UMapMovingMarkersLayer(
              duration: const Duration(milliseconds: 60),
              markers: <UMapMovingMarker>[
                UMapMovingMarker(id: "playback", point: here, heading: heading, child: marker ?? Icon(Icons.navigation, color: color, size: 32)),
              ],
            ),
        ],
      );
    },
  );
}

// ------------------------------------------------------------------------------------------------ accessibility

/// Screen-reader helper: when the map stops moving it announces what is near the centre ("3 places nearby: Azadi Tower 200 m north…").
class UMapAnnouncer extends StatefulWidget {
  const UMapAnnouncer({required this.places, this.maxItems = 3, this.persian = false, super.key});

  /// (point, name) of things worth announcing.
  final List<(LatLng, String)> places;
  final int maxItems;
  final bool persian;

  @override
  State<UMapAnnouncer> createState() => _UMapAnnouncerState();
}

class _UMapAnnouncerState extends State<UMapAnnouncer> {
  Timer? _timer;
  String _last = "";

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _announce(MapCamera camera) {
    final LatLng c = camera.center;
    final List<(LatLng, String)> near = widget.places.where(((LatLng, String) p) => camera.visibleBounds.contains(p.$1)).toList()
      ..sort(((LatLng, String) a, (LatLng, String) b) => UGeoMath.distance(c, a.$1).compareTo(UGeoMath.distance(c, b.$1)));
    final String text = near.isEmpty
        ? (widget.persian ? "چیزی در این محدوده نیست" : "Nothing in view")
        : "${widget.persian ? "${near.length} مکان: " : "${near.length} places: "}${near.take(widget.maxItems).map(((LatLng, String) p) => "${p.$2} ${UMapFormat.distance(UGeoMath.distance(c, p.$1), persian: widget.persian)} ${UMapFormat.compass(UGeoMath.bearing(c, p.$1), persian: widget.persian)}").join("، ")}";
    if (text == _last) return;
    _last = text;
    unawaited(SemanticsService.sendAnnouncement(View.of(context), text, widget.persian ? TextDirection.rtl : TextDirection.ltr));
  }

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    if (MediaQuery.maybeAccessibleNavigationOf(context) ?? false) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) _announce(camera);
      });
    }
    return const SizedBox.shrink();
  }
}
