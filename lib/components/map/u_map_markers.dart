import "dart:math" as math;
import "dart:ui" as ui;

import "package:u/utilities.dart";

/// Tween between two map points.
class ULatLngTween extends Tween<LatLng> {
  ULatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) => LatLng(begin!.latitude + (end!.latitude - begin!.latitude) * t, begin!.longitude + (end!.longitude - begin!.longitude) * t);
}

/// Places [child] of [size] at a map point in screen space (stays upright when the map rotates). [anchor] (0..1) is the point on the child that sits on the location.
class UMapPinned extends StatelessWidget {
  const UMapPinned({required this.point, required this.child, this.size = const Size(40, 40), this.anchor = const Offset(0.5, 0.5), super.key});

  final LatLng point;
  final Size size;
  final Offset anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Offset p = MapCamera.of(context).latLngToScreenOffset(point);
    return Positioned(left: p.dx - size.width * anchor.dx, top: p.dy - size.height * anchor.dy, width: size.width, height: size.height, child: child);
  }
}

// ------------------------------------------------------------------------------------------------ clustering

/// Clustered markers with split/merge animation: tap a cluster to zoom into it (thousands of items, all platforms).
/// `UMapClusterLayer<Shop>(items: shops, pointOf: (s) => s.location, markerBuilder: (c, s) => const Icon(Icons.store))`
class UMapClusterLayer<T> extends StatefulWidget {
  const UMapClusterLayer({
    required this.items,
    required this.pointOf,
    required this.markerBuilder,
    this.clusterBuilder,
    this.markerSize = const Size(40, 40),
    this.anchor = const Offset(0.5, 0.5),
    this.radius = 60,
    this.maxZoom = 17,
    this.onTap,
    this.onClusterTap,
    this.animate = true,
    this.color,
    super.key,
  });

  final List<T> items;
  final LatLng Function(T item) pointOf;
  final Widget Function(BuildContext context, T item) markerBuilder;

  /// Cluster bubble; defaults to a circle with the count.
  final Widget Function(BuildContext context, UMapCluster<T> cluster)? clusterBuilder;
  final Size markerSize;
  final Offset anchor;

  /// Cluster radius in pixels.
  final double radius;

  /// Zoom above which nothing is clustered.
  final int maxZoom;
  final void Function(T item)? onTap;

  /// Defaults to zooming into the cluster.
  final void Function(UMapCluster<T> cluster, List<T> items)? onClusterTap;
  final bool animate;
  final Color? color;

  @override
  State<UMapClusterLayer<T>> createState() => _UMapClusterLayerState<T>();
}

class _UMapClusterLayerState<T> extends State<UMapClusterLayer<T>> {
  late UMapClusterIndex<T> _index = _build();
  Map<int, LatLng> _previous = <int, LatLng>{};
  int _previousZoom = -1;

  UMapClusterIndex<T> _build() => UMapClusterIndex<T>(widget.items, widget.pointOf, radius: widget.radius, maxZoom: widget.maxZoom);

  @override
  void didUpdateWidget(UMapClusterLayer<T> old) {
    super.didUpdateWidget(old);
    if (!identical(old.items, widget.items) || old.radius != widget.radius || old.maxZoom != widget.maxZoom) _index = _build();
  }

  Widget _bubble(BuildContext context, UMapCluster<T> c) {
    final Color color = widget.color ?? Theme.of(context).colorScheme.primary;
    final double s = (30 + math.log(c.count) * 6).clamp(30, 64);
    return Center(
      child: Container(
        width: s,
        height: s,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.85),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Text(c.count >= 1000 ? "${(c.count / 1000).toStringAsFixed(1)}k" : "${c.count}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    final LatLngBounds view = camera.visibleBounds;
    final double padLat = (view.north - view.south) * 0.2;
    final double padLng = (view.east - view.west) * 0.2;
    final LatLngBounds padded = LatLngBounds(UGeoMath.safe(view.south - padLat, view.west - padLng), UGeoMath.safe(view.north + padLat, view.east + padLng));
    final List<UMapCluster<T>> clusters = _index.clusters(padded, camera.zoom);
    final int zoom = camera.zoom.floor();
    final bool zoomChanged = zoom != _previousZoom;
    final Map<int, LatLng> before = _previous;
    final Map<int, LatLng> now = <int, LatLng>{for (final UMapCluster<T> c in clusters) c.id: c.point};
    _previous = now;
    _previousZoom = zoom;
    final Size bubble = Size(widget.markerSize.width * 1.6, widget.markerSize.height * 1.6);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final UMapCluster<T> c in clusters)
          _AnimatedPin(
            key: ValueKey<int>(c.id),
            from: widget.animate && zoomChanged && !before.containsKey(c.id) && c.parentId != null ? before[c.parentId] : null,
            to: c.point,
            size: c.isCluster ? bubble : widget.markerSize,
            anchor: c.isCluster ? const Offset(0.5, 0.5) : widget.anchor,
            child: GestureDetector(
              onTap: () {
                if (c.isCluster) {
                  final List<T> leaves = _index.leaves(c.id);
                  if (widget.onClusterTap != null) {
                    widget.onClusterTap!(c, leaves);
                  } else {
                    MapController.of(context).fitPoints(leaves.map(widget.pointOf).toList(), maxZoom: c.expansionZoom.toDouble() + 0.5);
                  }
                } else {
                  widget.onTap?.call(c.item as T);
                }
              },
              child: c.isCluster ? (widget.clusterBuilder?.call(context, c) ?? _bubble(context, c)) : widget.markerBuilder(context, c.item as T),
            ),
          ),
      ],
    );
  }
}

class _AnimatedPin extends StatelessWidget {
  const _AnimatedPin({required this.to, required this.size, required this.anchor, required this.child, this.from, super.key});

  final LatLng? from;
  final LatLng to;
  final Size size;
  final Offset anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<LatLng>(
    tween: ULatLngTween(begin: from ?? to, end: to),
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
    builder: (BuildContext context, LatLng p, Widget? c) => UMapPinned(point: p, size: size, anchor: anchor, child: c!),
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 260),
      builder: (BuildContext context, double s, Widget? c) => Transform.scale(scale: s, child: c),
      child: child,
    ),
  );
}

// ------------------------------------------------------------------------------------------------ moving markers

/// A marker that glides to new positions (vehicles, couriers, friends) and turns to its heading.
class UMapMovingMarker {
  const UMapMovingMarker({required this.id, required this.point, required this.child, this.heading, this.size = const Size(40, 40), this.rotate = true, this.label});

  final Object id;
  final LatLng point;

  /// Degrees from north; null keeps the child upright.
  final double? heading;
  final Widget child;
  final Size size;

  /// Turn the child with [heading] (relative to the map).
  final bool rotate;

  /// Screen-reader label.
  final String? label;
}

/// Layer of [UMapMovingMarker]s: when a marker's point/heading changes it animates there over [duration] (shortest turn).
class UMapMovingMarkersLayer extends StatefulWidget {
  const UMapMovingMarkersLayer({required this.markers, this.duration = const Duration(milliseconds: 900), this.onTap, super.key});

  final List<UMapMovingMarker> markers;
  final Duration duration;
  final void Function(UMapMovingMarker marker)? onTap;

  @override
  State<UMapMovingMarkersLayer> createState() => _UMapMovingMarkersLayerState();
}

class _UMapMovingMarkersLayerState extends State<UMapMovingMarkersLayer> {
  final Map<Object, double> _continuous = <Object, double>{};

  double _unwrap(Object id, double heading) {
    final double? last = _continuous[id];
    if (last == null) return _continuous[id] = heading;
    double h = heading;
    while (h - last > 180) {
      h -= 360;
    }
    while (h - last < -180) {
      h += 360;
    }
    return _continuous[id] = h;
  }

  @override
  Widget build(BuildContext context) {
    final double mapRotation = MapCamera.of(context).rotation;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final UMapMovingMarker m in widget.markers)
          TweenAnimationBuilder<LatLng>(
            key: ValueKey<Object>(m.id),
            tween: ULatLngTween(begin: m.point, end: m.point),
            duration: widget.duration,
            builder: (BuildContext context, LatLng p, Widget? child) => UMapPinned(point: p, size: m.size, child: child!),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: m.heading == null ? 0 : _unwrap(m.id, m.heading!)),
              duration: widget.duration,
              builder: (BuildContext context, double h, Widget? child) => Transform.rotate(angle: m.rotate && m.heading != null ? (h + mapRotation) * math.pi / 180 : 0, child: child),
              child: Semantics(
                label: m.label,
                child: GestureDetector(onTap: widget.onTap == null ? null : () => widget.onTap!(m), child: m.child),
              ),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------------------------------------ marker effects

/// Pulsing ring behind a marker (live / selected).
class UMapPulse extends StatefulWidget {
  const UMapPulse({required this.child, this.color = const Color(0xFF1A73E8), this.size = 60, super.key});

  final Widget child;
  final Color color;
  final double size;

  @override
  State<UMapPulse> createState() => _UMapPulseState();
}

class _UMapPulseState extends State<UMapPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (BuildContext context, Widget? child) => Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: widget.size * _c.value,
          height: widget.size * _c.value,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: (1 - _c.value) * 0.45)),
        ),
        child!,
      ],
    ),
    child: widget.child,
  );
}

/// Drops a marker in from above with a bounce when it first appears.
class UMapDropIn extends StatelessWidget {
  const UMapDropIn({required this.child, this.height = 40, super.key});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 1, end: 0),
    duration: const Duration(milliseconds: 650),
    curve: Curves.bounceOut,
    builder: (BuildContext context, double v, Widget? c) => Transform.translate(offset: Offset(0, -height * v), child: Opacity(opacity: (1 - v * 0.8).clamp(0, 1), child: c)),
    child: child,
  );
}

/// Keeps a marker bouncing (e.g. the selected one).
class UMapBounce extends StatefulWidget {
  const UMapBounce({required this.child, this.height = 10, super.key});

  final Widget child;
  final double height;

  @override
  State<UMapBounce> createState() => _UMapBounceState();
}

class _UMapBounceState extends State<UMapBounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (BuildContext context, Widget? c) => Transform.translate(offset: Offset(0, -widget.height * Curves.easeOut.transform(_c.value)), child: c),
    child: widget.child,
  );
}

// ------------------------------------------------------------------------------------------------ labels

/// A text label on the map.
class UMapLabel {
  const UMapLabel({required this.point, required this.text, this.style, this.priority = 0, this.minZoom = 0, this.maxZoom = 30, this.offset = Offset.zero, this.background});

  final LatLng point;
  final String text;
  final TextStyle? style;

  /// Higher wins when labels overlap.
  final double priority;
  final double minZoom;
  final double maxZoom;
  final Offset offset;
  final Color? background;
}

/// Labels that never overlap: higher priority wins, the rest hide until there is room (upright, halo, zoom ranges).
class UMapLabelLayer extends StatelessWidget {
  const UMapLabelLayer({required this.labels, this.halo = true, super.key});

  final List<UMapLabel> labels;
  final bool halo;

  /// Same text style drawn as an outline of [color] (a halo behind map text).
  static TextStyle haloStyle(TextStyle s, Color color, double width) => TextStyle(
    fontSize: s.fontSize,
    fontWeight: s.fontWeight,
    fontStyle: s.fontStyle,
    fontFamily: s.fontFamily,
    letterSpacing: s.letterSpacing,
    height: s.height,
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..color = color,
  );

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    return IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _LabelPainter(labels, camera, halo, Theme.of(context).colorScheme.onSurface, Directionality.of(context))));
  }
}

class _LabelPainter extends CustomPainter {
  _LabelPainter(this.labels, this.camera, this.halo, this.color, this.direction);

  final List<UMapLabel> labels;
  final MapCamera camera;
  final bool halo;
  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final List<UMapLabel> sorted = labels.where((UMapLabel l) => camera.zoom >= l.minZoom && camera.zoom <= l.maxZoom).toList()..sort((UMapLabel a, UMapLabel b) => b.priority.compareTo(a.priority));
    final List<Rect> placed = <Rect>[];
    final Rect screen = Offset.zero & size;
    for (final UMapLabel l in sorted) {
      final Offset p = camera.latLngToScreenOffset(l.point) + l.offset;
      if (!screen.inflate(50).contains(p)) continue;
      final TextStyle style = (l.style ?? TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)).copyWith(height: 1.1);
      final TextPainter tp = TextPainter(
        text: TextSpan(text: l.text, style: style),
        textDirection: direction,
      )..layout(maxWidth: 160);
      final Rect box = Rect.fromCenter(center: p, width: tp.width + 6, height: tp.height + 4);
      if (placed.any((Rect r) => r.overlaps(box))) continue;
      placed.add(box);
      final Offset o = Offset(box.left + 3, box.top + 2);
      if (l.background != null) canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)), Paint()..color = l.background!);
      if (halo && l.background == null) {
        TextPainter(
            text: TextSpan(
              text: l.text,
              style: UMapLabelLayer.haloStyle(style, Colors.white, 3),
            ),
            textDirection: direction,
          )
          ..layout(maxWidth: 160)
          ..paint(canvas, o);
      }
      tp.paint(canvas, o);
    }
  }

  @override
  bool shouldRepaint(_LabelPainter old) => true;
}

// ------------------------------------------------------------------------------------------------ popups

/// The open popup: a point and what to show there.
class UMapPopup {
  const UMapPopup({required this.point, required this.builder, this.offset = 44});

  final LatLng point;
  final WidgetBuilder builder;

  /// Pixels above the point (marker height).
  final double offset;
}

/// Opens/closes popups (info windows) on a [UMapPopupLayer].
class UMapPopupController extends ValueNotifier<UMapPopup?> {
  UMapPopupController() : super(null);

  /// Shows a popup above a point.
  void show(LatLng point, WidgetBuilder builder, {double offset = 44}) => value = UMapPopup(point: point, builder: builder, offset: offset);

  /// Hides the popup.
  void hide() => value = null;
}

/// Info windows anchored to the map that follow pans and zooms.
class UMapPopupLayer extends StatelessWidget {
  const UMapPopupLayer({required this.controller, super.key});

  final UMapPopupController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMapPopup?>(
    valueListenable: controller,
    builder: (BuildContext context, UMapPopup? popup, _) {
      if (popup == null) return const SizedBox.shrink();
      final Offset p = MapCamera.of(context).latLngToScreenOffset(popup.point);
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: p.dx,
            top: p.dy - popup.offset,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -1),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                builder: (BuildContext context, double s, Widget? c) => Transform.scale(scale: s, alignment: Alignment.bottomCenter, child: c),
                child: Builder(builder: popup.builder),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Ready-made info window: title, subtitle, actions and a pointer arrow.
class UMapInfoWindow extends StatelessWidget {
  const UMapInfoWindow({required this.title, this.subtitle, this.actions = const <Widget>[], this.onClose, this.leading, this.maxWidth = 260, super.key});

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final Widget? leading;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: scheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (leading != null) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: leading),
                      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
                      if (onClose != null) IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close, size: 18), onPressed: onClose),
                    ],
                  ),
                  if (subtitle != null) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: Text(subtitle!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
                  if (actions.isNotEmpty) Wrap(spacing: 4, children: actions),
                ],
              ),
            ),
          ),
        ),
        CustomPaint(size: const Size(18, 9), painter: _ArrowPainter(scheme.surface)),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

// ------------------------------------------------------------------------------------------------ draggable markers

/// A marker the user can drag.
class UMapDraggableMarker {
  const UMapDraggableMarker({required this.id, required this.point, required this.child, this.size = const Size(44, 44), this.anchor = const Offset(0.5, 1)});

  final Object id;
  final LatLng point;
  final Widget child;
  final Size size;

  /// Point of the child that sits on the location (pins: bottom centre).
  final Offset anchor;
}

/// Markers you can drag (long-press then drag by default, like Google Maps); [snap] can move the drop onto a road (e.g. UMapServices.snapToRoad).
class UMapDraggableMarkersLayer extends StatefulWidget {
  const UMapDraggableMarkersLayer({required this.markers, required this.onDragEnd, this.onDragUpdate, this.snap, this.longPress = true, super.key});

  final List<UMapDraggableMarker> markers;
  final void Function(Object id, LatLng point) onDragEnd;
  final void Function(Object id, LatLng point)? onDragUpdate;
  final Future<LatLng?> Function(LatLng point)? snap;

  /// Long-press to start dragging (false: drag immediately).
  final bool longPress;

  @override
  State<UMapDraggableMarkersLayer> createState() => _UMapDraggableMarkersLayerState();
}

class _UMapDraggableMarkersLayerState extends State<UMapDraggableMarkersLayer> {
  Object? _dragging;
  LatLng? _dragPoint;
  final GlobalKey _area = GlobalKey();

  LatLng _toLatLng(Offset global, UMapDraggableMarker m) {
    final RenderBox box = _area.currentContext!.findRenderObject()! as RenderBox;
    final Offset local = box.globalToLocal(global) + Offset(m.size.width * (m.anchor.dx - 0.5), m.size.height * (m.anchor.dy - 0.5));
    return MapCamera.of(context).screenOffsetToLatLng(local);
  }

  void _start(UMapDraggableMarker m) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _dragging = m.id;
      _dragPoint = m.point;
    });
  }

  void _move(UMapDraggableMarker m, Offset global) {
    final LatLng p = _toLatLng(global, m);
    setState(() => _dragPoint = p);
    widget.onDragUpdate?.call(m.id, p);
  }

  Future<void> _end(UMapDraggableMarker m) async {
    LatLng p = _dragPoint ?? m.point;
    if (widget.snap != null) {
      try {
        p = await widget.snap!(p) ?? p;
      } on Object {
        // Keep the raw drop point when snapping fails (offline).
      }
    }
    if (!mounted) return;
    setState(() {
      _dragging = null;
      _dragPoint = null;
    });
    widget.onDragEnd(m.id, p);
  }

  @override
  Widget build(BuildContext context) => Stack(
    key: _area,
    clipBehavior: Clip.none,
    children: <Widget>[
      for (final UMapDraggableMarker m in widget.markers)
        UMapPinned(
          key: ValueKey<Object>(m.id),
          point: m.id == _dragging ? _dragPoint ?? m.point : m.point,
          size: m.size,
          anchor: m.anchor,
          child: GestureDetector(
            onLongPressStart: widget.longPress ? (_) => _start(m) : null,
            onLongPressMoveUpdate: widget.longPress ? (LongPressMoveUpdateDetails d) => _move(m, d.globalPosition) : null,
            onLongPressEnd: widget.longPress ? (_) => _end(m) : null,
            onPanStart: widget.longPress ? null : (_) => _start(m),
            onPanUpdate: widget.longPress ? null : (DragUpdateDetails d) => _move(m, d.globalPosition),
            onPanEnd: widget.longPress ? null : (_) => _end(m),
            child: AnimatedScale(scale: m.id == _dragging ? 1.25 : 1, duration: const Duration(milliseconds: 150), alignment: Alignment.bottomCenter, child: m.child),
          ),
        ),
    ],
  );
}

// ------------------------------------------------------------------------------------------------ fast icon markers

/// Marker images for [UMapIconMarkersLayer], drawn once and cached.
abstract final class UMapMarkerIcon {
  static final Map<String, ui.Image> _cache = <String, ui.Image>{};

  /// A teardrop pin with an icon inside.
  static ui.Image pin(IconData icon, {Color color = const Color(0xFFE53935), Color iconColor = Colors.white, double size = 40, double pixelRatio = 3}) {
    final String key = "pin:${icon.codePoint}:${color.toARGB32()}:${iconColor.toARGB32()}:$size:$pixelRatio";
    return _cache[key] ??= _draw(Size(size, size * 1.25), pixelRatio, (Canvas c, Size s) {
      final double r = s.width / 2;
      final Path p = Path()
        ..moveTo(r, s.height)
        ..quadraticBezierTo(r * 0.15, s.height * 0.62, r * 0.05, r)
        ..arcToPoint(Offset(s.width - r * 0.05, r), radius: Radius.circular(r * 0.95))
        ..quadraticBezierTo(s.width - r * 0.15, s.height * 0.62, r, s.height)
        ..close();
      c
        ..drawShadow(p, Colors.black, 3, false)
        ..drawPath(p, Paint()..color = color)
        ..drawCircle(Offset(r, r), r * 0.62, Paint()..color = Colors.white.withValues(alpha: 0.18));
      _icon(c, icon, Offset(r, r), r * 1.05, iconColor);
    });
  }

  /// A round badge with an icon.
  static ui.Image circle(IconData icon, {Color color = const Color(0xFF1E88E5), Color iconColor = Colors.white, double size = 32, double pixelRatio = 3}) {
    final String key = "circle:${icon.codePoint}:${color.toARGB32()}:${iconColor.toARGB32()}:$size:$pixelRatio";
    return _cache[key] ??= _draw(Size(size, size), pixelRatio, (Canvas c, Size s) {
      final Offset ctr = s.center(Offset.zero);
      c
        ..drawCircle(ctr, s.width / 2, Paint()..color = Colors.white)
        ..drawCircle(ctr, s.width / 2 - 2, Paint()..color = color);
      _icon(c, icon, ctr, s.width * 0.6, iconColor);
    });
  }

  static void _icon(Canvas c, IconData icon, Offset center, double size, Color color) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  static ui.Image _draw(Size size, double ratio, void Function(Canvas, Size) paint) {
    final ui.PictureRecorder r = ui.PictureRecorder();
    final Canvas c = Canvas(r)..scale(ratio);
    paint(c, size);
    final ui.Picture picture = r.endRecording();
    final ui.Image image = picture.toImageSync((size.width * ratio).ceil(), (size.height * ratio).ceil());
    picture.dispose();
    return image;
  }

  /// Renders any widget to an image once (custom marker art) — `await UMapMarkerIcon.fromWidget(const FlutterLogo())`.
  static Future<ui.Image> fromWidget(Widget widget, {Size size = const Size(48, 48), double pixelRatio = 3}) async {
    final RenderRepaintBoundary boundary = RenderRepaintBoundary();
    final ui.FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    final RenderView renderView = RenderView(
      view: view,
      child: RenderPositionedBox(child: boundary),
      configuration: ViewConfiguration(logicalConstraints: BoxConstraints.tight(size), physicalConstraints: BoxConstraints.tight(size * pixelRatio), devicePixelRatio: pixelRatio),
    );
    final PipelineOwner pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();
    final BuildOwner build = BuildOwner(focusManager: FocusManager());
    final RenderObjectToWidgetElement<RenderBox> root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: Directionality(textDirection: TextDirection.ltr, child: MediaQuery(data: MediaQueryData(size: size, devicePixelRatio: pixelRatio), child: widget)),
    ).attachToRenderTree(build);
    build
      ..buildScope(root)
      ..finalizeTree();
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    return boundary.toImage(pixelRatio: pixelRatio);
  }
}

/// One canvas-drawn marker.
class UMapIconMarker {
  const UMapIconMarker({required this.point, required this.image, this.rotation = 0, this.scale = 1, this.anchor = const Offset(0.5, 1), this.data});

  final LatLng point;
  final ui.Image image;

  /// Degrees.
  final double rotation;
  final double scale;
  final Offset anchor;
  final Object? data;
}

/// Thousands of image markers painted in one canvas pass (no widget per marker); [onTap] gets the tapped one.
class UMapIconMarkersLayer extends StatelessWidget {
  const UMapIconMarkersLayer({required this.markers, this.onTap, this.pixelRatio = 3, super.key});

  final List<UMapIconMarker> markers;
  final void Function(UMapIconMarker marker)? onTap;

  /// Ratio the images were drawn at.
  final double pixelRatio;

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    final Widget paint = CustomPaint(size: Size.infinite, painter: _IconPainter(markers, camera, pixelRatio));
    if (onTap == null) return IgnorePointer(child: paint);
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapUp: (TapUpDetails d) {
        for (final UMapIconMarker m in markers.reversed) {
          if (_rect(m, camera, pixelRatio).inflate(4).contains(d.localPosition)) return onTap!(m);
        }
      },
      child: paint,
    );
  }

  static Rect _rect(UMapIconMarker m, MapCamera camera, double ratio) {
    final Offset p = camera.latLngToScreenOffset(m.point);
    final double w = m.image.width / ratio * m.scale;
    final double h = m.image.height / ratio * m.scale;
    return Rect.fromLTWH(p.dx - w * m.anchor.dx, p.dy - h * m.anchor.dy, w, h);
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.markers, this.camera, this.ratio);

  final List<UMapIconMarker> markers;
  final MapCamera camera;
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect screen = (Offset.zero & size).inflate(60);
    final Paint paint = Paint()..filterQuality = FilterQuality.medium;
    for (final UMapIconMarker m in markers) {
      final Rect r = UMapIconMarkersLayer._rect(m, camera, ratio);
      if (!screen.overlaps(r)) continue;
      if (m.rotation == 0) {
        canvas.drawImageRect(m.image, Rect.fromLTWH(0, 0, m.image.width.toDouble(), m.image.height.toDouble()), r, paint);
      } else {
        final Offset anchor = Offset(r.left + r.width * m.anchor.dx, r.top + r.height * m.anchor.dy);
        canvas
          ..save()
          ..translate(anchor.dx, anchor.dy)
          ..rotate((m.rotation + camera.rotation) * math.pi / 180)
          ..translate(-anchor.dx, -anchor.dy)
          ..drawImageRect(m.image, Rect.fromLTWH(0, 0, m.image.width.toDouble(), m.image.height.toDouble()), r, paint)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) => true;
}

// ------------------------------------------------------------------------------------------------ lasso selection

/// Freehand lasso: drag to circle things on the map; [onSelected] gets the outline (test points with UGeo.contains). Turn off map dragging while it is enabled.
class UMapLassoLayer extends StatefulWidget {
  const UMapLassoLayer({required this.onSelected, this.enabled = true, this.color = const Color(0xFF1A73E8), super.key});

  final void Function(List<LatLng> polygon) onSelected;
  final bool enabled;
  final Color color;

  @override
  State<UMapLassoLayer> createState() => _UMapLassoLayerState();
}

class _UMapLassoLayerState extends State<UMapLassoLayer> {
  final List<Offset> _screen = <Offset>[];

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    final MapCamera camera = MapCamera.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (DragStartDetails d) => setState(() => _screen
        ..clear()
        ..add(d.localPosition)),
      onPanUpdate: (DragUpdateDetails d) => setState(() => _screen.add(d.localPosition)),
      onPanEnd: (_) {
        final List<LatLng> polygon = _screen.map(camera.screenOffsetToLatLng).toList();
        setState(_screen.clear);
        if (polygon.length > 2) widget.onSelected(<LatLng>[...polygon, polygon.first]);
      },
      child: CustomPaint(size: Size.infinite, painter: _LassoPainter(List<Offset>.of(_screen), widget.color)),
    );
  }
}

class _LassoPainter extends CustomPainter {
  _LassoPainter(this.points, this.color);

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final Path p = Path()..addPolygon(points, true);
    canvas
      ..drawPath(p, Paint()..color = color.withValues(alpha: 0.15))
      ..drawPath(
        p,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
  }

  @override
  bool shouldRepaint(_LassoPainter old) => true;
}
