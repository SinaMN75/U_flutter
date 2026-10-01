import "dart:math" as math;

import "package:u/utilities.dart";

/// How the camera follows the user.
enum UMapFollowMode {
  /// Free camera.
  none,

  /// Keeps the user centred.
  follow,

  /// Keeps the user centred and turns the map to the direction of travel.
  heading,
}

/// Blue dot with accuracy circle and heading cone, Kalman smoothing, follow modes and a breadcrumb trail (all platforms). Asks for nothing:
/// it shows once location permission is granted (UMapLocateButton asks). Needs `dart run u:app permission add location`.
class UMapLocationLayer extends StatefulWidget {
  const UMapLocationLayer({
    this.follow,
    this.positions,
    this.smooth = true,
    this.trail = false,
    this.trailLength = 300,
    this.color,
    this.followZoom,
    this.showAccuracy = true,
    this.onPosition,
    super.key,
  });

  /// Shared follow mode (UMap passes its own; the locate button cycles it).
  final ValueNotifier<UMapFollowMode>? follow;

  /// Positions to show instead of the device GPS (simulations, other users).
  final Stream<UPosition>? positions;

  /// Kalman-smooth jittery fixes.
  final bool smooth;

  /// Draw where the user has been.
  final bool trail;
  final int trailLength;
  final Color? color;

  /// Zoom used when following starts (keeps the current zoom when null).
  final double? followZoom;
  final bool showAccuracy;

  /// Every (smoothed) position.
  final void Function(UPosition position, LatLng smoothed)? onPosition;

  @override
  State<UMapLocationLayer> createState() => _UMapLocationLayerState();
}

class _UMapLocationLayerState extends State<UMapLocationLayer> {
  StreamSubscription<UPosition>? _positions;
  StreamSubscription<UHeading>? _compass;
  final UGeoKalman _kalman = UGeoKalman();
  LatLng? _point;
  double _accuracy = 0;
  double? _heading;
  final List<LatLng> _trail = <LatLng>[];

  @override
  void initState() {
    super.initState();
    widget.follow?.addListener(_onFollow);
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _listen();
    } on Object catch (e) {
      debugPrint("UMapLocationLayer: location unavailable ($e)");
    }
  }

  Future<void> _listen() async {
    if (widget.positions == null) {
      if (!await ULocation.isReady()) {
        // Start once the locate button gets permission.
        widget.follow?.addListener(_retry);
        return;
      }
    }
    await _positions?.cancel();
    _positions = (widget.positions ?? ULocation.stream(const ULocationSettings(distanceFilter: 2))).listen(_onPosition);
    if (widget.positions == null) {
      _compass = ULocation.heading().listen(
        (UHeading h) {
          if (!mounted) return;
          final double? speedHeading = _speedHeading;
          if (speedHeading == null) setState(() => _heading = h.trueNorth ?? h.magnetic);
        },
        onError: (Object _) {},
      );
    }
  }

  double? _lastSpeed;
  double? _lastCourse;

  double? get _speedHeading => (_lastSpeed ?? 0) > 1.5 ? _lastCourse : null;

  void _retry() {
    if (widget.follow?.value != UMapFollowMode.none) {
      widget.follow?.removeListener(_retry);
      unawaited(_start());
    }
  }

  void _onPosition(UPosition p) {
    if (!mounted) return;
    final LatLng raw = LatLng(p.latitude, p.longitude);
    final LatLng point = widget.smooth ? _kalman.filter(raw, accuracy: p.accuracy ?? 10, time: p.time) : raw;
    _lastSpeed = p.speed;
    _lastCourse = p.heading;
    setState(() {
      _point = point;
      _accuracy = p.accuracy ?? 0;
      if (_speedHeading != null) _heading = _speedHeading;
      if (widget.trail) {
        _trail.add(point);
        if (_trail.length > widget.trailLength) _trail.removeAt(0);
      }
    });
    widget.onPosition?.call(p, point);
    _applyFollow(animate: true);
  }

  void _onFollow() => _applyFollow(animate: true, starting: true);

  void _applyFollow({required bool animate, bool starting = false}) {
    final UMapFollowMode mode = widget.follow?.value ?? UMapFollowMode.none;
    final LatLng? p = _point;
    if (mode == UMapFollowMode.none || p == null) return;
    final MapController? controller = MapController.maybeOf(context);
    if (controller == null) return;
    final double zoom = starting ? (widget.followZoom ?? math.max(controller.camera.zoom, 16)) : controller.camera.zoom;
    final double rotation = mode == UMapFollowMode.heading && _heading != null ? -_heading! : (starting && mode == UMapFollowMode.follow ? controller.camera.rotation : controller.camera.rotation);
    unawaited(controller.animateTo(center: p, zoom: zoom, rotation: rotation, duration: Duration(milliseconds: starting ? 600 : 350)));
  }

  @override
  void dispose() {
    widget.follow?.removeListener(_onFollow);
    widget.follow?.removeListener(_retry);
    _positions?.cancel();
    _compass?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? p = _point;
    if (p == null) return const SizedBox.shrink();
    final Color color = widget.color ?? const Color(0xFF1A73E8);
    return Stack(
      children: <Widget>[
        if (widget.trail && _trail.length > 1)
          PolylineLayer<Object>(
            polylines: <Polyline<Object>>[Polyline<Object>(points: List<LatLng>.of(_trail), color: color.withValues(alpha: 0.5), strokeWidth: 4, pattern: const StrokePattern.dotted())],
          ),
        if (widget.showAccuracy && _accuracy > 3)
          CircleLayer<Object>(
            circles: <CircleMarker<Object>>[
              CircleMarker<Object>(point: p, radius: _accuracy, useRadiusInMeter: true, color: color.withValues(alpha: 0.12), borderColor: color.withValues(alpha: 0.35), borderStrokeWidth: 1),
            ],
          ),
        MarkerLayer(
          markers: <Marker>[
            Marker(
              point: p,
              width: 72,
              height: 72,
              child: Semantics(
                label: "Your location",
                child: CustomPaint(painter: _DotPainter(color, _heading == null ? null : _heading! * math.pi / 180)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.color, this.heading);

  final Color color;
  final double? heading;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    if (heading != null) {
      final Rect arc = Rect.fromCircle(center: c, radius: size.width / 2);
      canvas.drawArc(
        arc,
        heading! - math.pi / 2 - 0.45,
        0.9,
        true,
        Paint()
          ..shader = RadialGradient(colors: <Color>[color.withValues(alpha: 0.45), color.withValues(alpha: 0)]).createShader(arc),
      );
    }
    canvas
      ..drawCircle(c, 10, Paint()..color = Colors.black.withValues(alpha: 0.18))
      ..drawCircle(c, 9, Paint()..color = Colors.white)
      ..drawCircle(c, 6.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.color != color || old.heading != heading;
}

/// Locate button: first tap asks permission and centres, then follow, then follow with heading (like Google Maps). Needs `permission add location`.
class UMapLocateButton extends StatelessWidget {
  const UMapLocateButton({required this.follow, this.controller, this.heroTag, super.key});

  final ValueNotifier<UMapFollowMode> follow;
  final MapController? controller;
  final Object? heroTag;

  Future<void> _tap(BuildContext context) async {
    final ULocationError? error = await ULocation.ensureReady();
    if (error != null) {
      if (context.mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text("Location unavailable: ${error.name}")));
      return;
    }
    follow.value = switch (follow.value) {
      UMapFollowMode.none => UMapFollowMode.follow,
      UMapFollowMode.follow => UMapFollowMode.heading,
      UMapFollowMode.heading => UMapFollowMode.none,
    };
    if (follow.value == UMapFollowMode.none) unawaited(controller?.resetNorth());
    if (follow.value == UMapFollowMode.follow && controller != null) {
      final UPosition? p = await ULocation.lastKnown() ?? await ULocation.position();
      if (p != null) unawaited(controller!.flyTo(LatLng(p.latitude, p.longitude), zoom: math.max(controller!.camera.zoom, 16)));
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMapFollowMode>(
    valueListenable: follow,
    builder: (BuildContext context, UMapFollowMode mode, _) => FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      tooltip: "My location",
      onPressed: () => _tap(context),
      child: Icon(switch (mode) {
        UMapFollowMode.none => Icons.my_location,
        UMapFollowMode.follow => Icons.gps_fixed,
        UMapFollowMode.heading => Icons.navigation,
      }, color: mode == UMapFollowMode.none ? null : Theme.of(context).colorScheme.primary),
    ),
  );
}
