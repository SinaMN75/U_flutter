import "dart:math" as math;

import "package:flutter/scheduler.dart";
import "package:u/utilities.dart";

/// Map tiles: openStreetMap, mapBox, openTopoMap… (online). Kept for older code; prefer [UMap.source] with a [UMapTileSource].
enum UMapTileProvider {
  openStreetMap,
  mapBox,
  openTopoMap,
  stamenTerrain,
}

/// Colour treatment for raster tiles (dark mode, grayscale…).
enum UMapColorFilter {
  none,
  dark,
  grayscale,
  sepia,
  invert,
  night;

  /// The ColorFilter, or null for [none].
  ColorFilter? get filter => switch (this) {
    UMapColorFilter.none => null,
    UMapColorFilter.dark => const ColorFilter.matrix(<double>[-0.2126, -0.7152, -0.0722, 0, 255, -0.2126, -0.7152, -0.0722, 0, 255, -0.2126, -0.7152, -0.0722, 0, 255, 0, 0, 0, 1, 0]),
    UMapColorFilter.grayscale => const ColorFilter.matrix(<double>[0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]),
    UMapColorFilter.sepia => const ColorFilter.matrix(<double>[0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0]),
    UMapColorFilter.invert => const ColorFilter.matrix(<double>[-1, 0, 0, 0, 255, 0, -1, 0, 0, 255, 0, 0, -1, 0, 255, 0, 0, 0, 1, 0]),
    UMapColorFilter.night => const ColorFilter.matrix(<double>[-0.18, -0.6, -0.06, 0, 210, -0.2, -0.65, -0.06, 0, 215, -0.22, -0.7, -0.08, 0, 235, 0, 0, 0, 1, 0]),
  };
}

/// Map widget on flutter_map with everything wired: raster or vector styles, offline cache, terrain, location with follow modes, compass, scale bar,
/// mini-map, tilt, camera memory, bounds lock, drawing and snapshots (all platforms). `UMap(center: const LatLng(35.7, 51.4), zoom: 12)`
/// Location features need `dart run u:app permission add location`.
class UMap extends StatefulWidget {
  const UMap({
    this.controller,
    this.center = const LatLng(51.509364, -0.128928),
    this.zoom = 10.0,
    this.minZoom = 3.0,
    this.maxZoom = 18.0,
    this.rotation = 0,
    this.tileProvider = UMapTileProvider.openStreetMap,
    this.source,
    this.vectorStyle,
    this.vectorSource,
    this.overlays = const <UMapTileSource>[],
    this.vectorOverlay,
    this.colorFilter = UMapColorFilter.none,
    this.hillshade = false,
    this.contours = false,
    this.markers = const <Marker>[],
    this.polylines = const <Polyline<Object>>[],
    this.polygons = const <Polygon<Object>>[],
    this.circles = const <CircleMarker<Object>>[],
    this.layers = const <Widget>[],
    this.topLayers = const <Widget>[],
    this.controls = const <Widget>[],
    this.centerWidget,
    this.zoomButtons = true,
    this.myLocationButton = true,
    this.currentLocationLayer = true,
    this.initOnUserLocation = false,
    this.initialFollow = UMapFollowMode.none,
    this.showAttribution = true,
    this.compass = true,
    this.scaleBar = false,
    this.miniMap = false,
    this.tilt = 0,
    this.rotate = true,
    this.interactive = true,
    this.maxBounds,
    this.fitPoints,
    this.persistKey,
    this.offlineOnly = false,
    this.persianDigits = false,
    this.imperial = false,
    this.drawController,
    this.captureController,
    this.crs = const Epsg3857(),
    this.backgroundColor,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onPositionChanged,
    this.onPointerUp,
    this.onMapReady,
    this.onMapEvent,
    this.mapBoxAccessToken,
    this.apiKey,
    super.key,
  });

  /// Controls the camera; one is made when null (reach it with `MapController.of(context)` inside layers).
  final MapController? controller;

  /// The initial center of the map.
  final LatLng center;

  /// The initial zoom level.
  final double zoom;

  /// The minimum zoom level.
  final double minZoom;

  /// The maximum zoom level (vector maps stay sharp to 22).
  final double maxZoom;

  /// Initial rotation in degrees.
  final double rotation;

  /// Older tile choice; ignored when [source] or [vectorStyle] is set.
  final UMapTileProvider tileProvider;

  /// Raster tiles to draw (presets like UMapTileSource.openTopoMap or sentinel2, a pmtiles archive, your own server).
  final UMapTileSource? source;

  /// Vector map style (UMapVectorStyle.light(), .dark(), or a downloaded MapLibre style); wins over [source].
  final UMapVectorStyle? vectorStyle;

  /// Where [vectorStyle]'s tiles come from (your .pmtiles via UMapTileSource.pmtiles); defaults to the style's own source (OpenFreeMap).
  final UMapTileSource? vectorSource;

  /// Transparent raster tile layers above the base (your own overlays, weather, etc.).
  final List<UMapTileSource> overlays;

  /// Vector style drawn above the base (e.g. UMapVectorStyle.labels() for free street names over satellite).
  final UMapVectorStyle? vectorOverlay;

  /// Dark / grayscale / sepia treatment of raster tiles.
  final UMapColorFilter colorFilter;

  /// Shaded relief from elevation tiles.
  final bool hillshade;

  /// Contour lines from elevation tiles (zoom 10+).
  final bool contours;

  /// List of markers to display on the map.
  final List<Marker> markers;

  /// List of polylines to display on the map.
  final List<Polyline<Object>> polylines;

  /// List of polygons to display on the map.
  final List<Polygon<Object>> polygons;

  /// Circles (set useRadiusInMeter for true metres).
  final List<CircleMarker<Object>> circles;

  /// Extra layers between shapes and markers (heatmap, clusters, GeoJSON…).
  final List<Widget> layers;

  /// Layers above markers and location (popups, labels, draw tools…).
  final List<Widget> topLayers;

  /// Widgets over the map that do not rotate (banners, search bars…); position them with Align/Positioned.
  final List<Widget> controls;

  /// Widget to display at the map's center.
  final Widget? centerWidget;

  /// Whether to show zoom buttons.
  final bool zoomButtons;

  /// Whether to show a button to center on (and follow) the user's location.
  final bool myLocationButton;

  /// Whether to show the user's current location as a layer.
  final bool currentLocationLayer;

  /// Whether to initialize the map centered on the user's location.
  final bool initOnUserLocation;

  /// Follow mode at start.
  final UMapFollowMode initialFollow;

  /// Whether to show attribution for the tile provider.
  final bool showAttribution;

  /// Compass that appears when rotated; tap to face north.
  final bool compass;

  /// Distance scale bar.
  final bool scaleBar;

  /// Small overview map in a corner.
  final bool miniMap;

  /// Pseudo-3D tilt in degrees (0–60). Visual only: taps are approximate while tilted.
  final double tilt;

  /// Allow two-finger rotation.
  final bool rotate;

  /// Allow panning/zooming at all.
  final bool interactive;

  /// Keep the camera inside this box (a city, a country).
  final LatLngBounds? maxBounds;

  /// Open fitted to these points instead of [center]/[zoom].
  final List<LatLng>? fitPoints;

  /// Remembers the camera under this key and restores it next time.
  final String? persistKey;

  /// Never touch the network (offline packs and cache only).
  final bool offlineOnly;

  /// Persian digits in the scale bar and readouts.
  final bool persianDigits;

  /// Miles/feet in the scale bar.
  final bool imperial;

  /// Drawing / measuring tools on this map.
  final UMapDrawController? drawController;

  /// Lets you capture the map as PNG (`await controller.capture()`).
  final UWidgetToImageController? captureController;

  /// Projection (EPSG:3857 default; Epsg4326 for plate carrée data).
  final Crs crs;

  /// Colour behind tiles.
  final Color? backgroundColor;

  /// Callback for tap events on the map.
  final void Function(TapPosition, LatLng)? onTap;

  /// Callback for long press events on the map.
  final void Function(TapPosition, LatLng)? onLongPress;

  /// Right-click / secondary tap.
  final void Function(TapPosition, LatLng)? onSecondaryTap;

  /// Callback for when the map's position changes.
  final void Function(MapCamera, bool)? onPositionChanged;

  /// Callback for pointer up events on the map.
  final void Function(PointerUpEvent, LatLng)? onPointerUp;

  /// Called once the map is laid out and the controller can be used.
  final VoidCallback? onMapReady;

  /// Every map event (move start/end, rotate, fling…).
  final void Function(MapEvent)? onMapEvent;

  /// MapBox access token (required for MapBox tile provider).
  final String? mapBoxAccessToken;

  /// Stadia Maps key for [UMapTileProvider.stamenTerrain].
  final String? apiKey;

  /// The tile source this map draws.
  UMapTileSource get resolvedSource {
    if (source != null) return source!;
    return switch (tileProvider) {
      UMapTileProvider.openStreetMap => UMapTileSource.openStreetMap,
      UMapTileProvider.openTopoMap => UMapTileSource.openTopoMap,
      UMapTileProvider.stamenTerrain => UMapTileSource.stadia(apiKey ?? ""),
      UMapTileProvider.mapBox => UMapTileSource.mapbox(mapBoxAccessToken ?? (throw Exception("MapBox access token is required for MapBox tile provider"))),
    };
  }

  @override
  State<UMap> createState() => _UMapState();
}

class _UMapState extends State<UMap> {
  MapController? _own;
  late final ValueNotifier<UMapFollowMode> _follow = ValueNotifier<UMapFollowMode>(widget.initialFollow);
  Timer? _persist;
  bool _ready = false;

  MapController get _controller => widget.controller ?? (_own ??= MapController());

  @override
  void initState() {
    super.initState();
    widget.drawController?.addListener(_redraw);
    if (widget.initOnUserLocation) _centerOnUserLocation();
  }

  @override
  void didUpdateWidget(UMap old) {
    super.didUpdateWidget(old);
    if (old.drawController != widget.drawController) {
      old.drawController?.removeListener(_redraw);
      widget.drawController?.addListener(_redraw);
    }
  }

  @override
  void dispose() {
    widget.drawController?.removeListener(_redraw);
    _persist?.cancel();
    _follow.dispose();
    _own?.dispose();
    super.dispose();
  }

  void _redraw() => setState(() {});

  Future<void> _centerOnUserLocation() async {
    try {
      final UPosition? position = await ULocation.position();
      if (!mounted || position == null) return;
      if (_ready) {
        await _controller.flyTo(LatLng(position.latitude, position.longitude), zoom: math.max(_controller.camera.zoom, 15));
      } else {
        _pendingCenter = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Error getting user location: $e");
    }
  }

  LatLng? _pendingCenter;

  late final (LatLng, double, double)? _restored = _readCamera();

  (LatLng, double, double)? _readCamera() {
    if (widget.persistKey == null) return null;
    try {
      final String? raw = ULocalStorage.getString("umap_camera_${widget.persistKey}");
      final List<double>? v = raw?.split(",").map((String s) => double.tryParse(s) ?? 0).toList();
      if (v == null || v.length < 4) return null;
      return (LatLng(v[0].clamp(-90, 90), v[1].clamp(-180, 180)), v[2], v[3]);
    } on Object {
      return null;
    }
  }

  void _onPosition(MapCamera camera, bool gesture) {
    widget.onPositionChanged?.call(camera, gesture);
    if (widget.persistKey != null) {
      _persist?.cancel();
      _persist = Timer(const Duration(milliseconds: 600), () {
        try {
          ULocalStorage.set("umap_camera_${widget.persistKey}", "${camera.center.latitude},${camera.center.longitude},${camera.zoom},${camera.rotation}");
        } on Object catch (e) {
          debugPrint("UMap: camera not saved ($e)");
        }
      });
    }
  }

  int get _flags {
    if (!widget.interactive) return InteractiveFlag.none;
    int flags = InteractiveFlag.all;
    if (!widget.rotate) flags &= ~InteractiveFlag.rotate;
    if (widget.drawController?.capturesDrag ?? false) flags &= ~(InteractiveFlag.drag | InteractiveFlag.flingAnimation | InteractiveFlag.doubleTapDragZoom);
    return flags;
  }

  List<Widget> _tiles(UMapTileSource base) {
    final ColorFilter? filter = widget.colorFilter.filter;
    Widget wrap(Widget layer) => filter == null ? layer : ColorFiltered(colorFilter: filter, child: layer);
    return <Widget>[
      if (widget.vectorStyle != null) wrap(UMapVectorTiles.layer(widget.vectorStyle!, source: widget.vectorSource, offlineOnly: widget.offlineOnly)) else wrap(UMapTiles.layer(base, offlineOnly: widget.offlineOnly)),
      if (widget.hillshade) UMapTerrain.hillshadeLayer(),
      if (widget.contours) UMapTerrain.contourLayer(),
      for (final UMapTileSource o in widget.overlays) UMapTiles.layer(o, offlineOnly: widget.offlineOnly),
      if (widget.vectorOverlay != null) UMapVectorTiles.layer(widget.vectorOverlay!, offlineOnly: widget.offlineOnly),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final UMapTileSource base = widget.vectorStyle == null ? widget.resolvedSource : (widget.vectorSource ?? widget.vectorStyle!.tileSource);
    final (LatLng, double, double)? restored = _restored;
    final List<String> attributions = <String>[
      base.attribution,
      for (final UMapTileSource o in widget.overlays) o.attribution,
      if (widget.vectorOverlay != null) widget.vectorOverlay!.tileSource.attribution,
      if (widget.hillshade || widget.contours) UMapTerrain.source.attribution,
    ].where((String a) => a.isNotEmpty).toSet().toList();
    Widget map = FlutterMap(
      mapController: _controller,
      options: MapOptions(
        crs: widget.crs,
        initialCenter: restored?.$1 ?? widget.center,
        initialZoom: restored?.$2 ?? widget.zoom,
        initialRotation: restored?.$3 ?? widget.rotation,
        initialCameraFit: restored == null && widget.fitPoints != null && widget.fitPoints!.length > 1
            ? CameraFit.coordinates(coordinates: widget.fitPoints!, padding: const EdgeInsets.all(48), maxZoom: 17)
            : null,
        minZoom: widget.minZoom,
        maxZoom: widget.maxZoom,
        backgroundColor: widget.backgroundColor ?? (widget.vectorStyle != null || widget.colorFilter != UMapColorFilter.none ? Theme.of(context).colorScheme.surfaceContainerHighest : const Color(0xFFE0E0E0)),
        cameraConstraint: widget.maxBounds == null ? const CameraConstraint.unconstrained() : CameraConstraint.contain(bounds: widget.maxBounds!),
        interactionOptions: InteractionOptions(flags: _flags),
        onTap: (TapPosition p, LatLng l) {
          if (widget.drawController != null && widget.drawController!.handleTap(l)) return;
          widget.onTap?.call(p, l);
        },
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        onPositionChanged: _onPosition,
        onPointerUp: widget.onPointerUp,
        onMapEvent: (MapEvent e) {
          if (e is MapEventMoveStart && e.source == MapEventSource.dragStart) _follow.value = UMapFollowMode.none;
          widget.onMapEvent?.call(e);
        },
        onMapReady: () {
          _ready = true;
          if (_pendingCenter != null) unawaited(_controller.flyTo(_pendingCenter!, zoom: 15));
          widget.onMapReady?.call();
        },
      ),
      children: <Widget>[
        ..._tiles(base),
        if (widget.polygons.isNotEmpty) PolygonLayer<Object>(polygons: widget.polygons),
        if (widget.polylines.isNotEmpty) PolylineLayer<Object>(polylines: widget.polylines),
        if (widget.circles.isNotEmpty) CircleLayer<Object>(circles: widget.circles),
        ...widget.layers,
        if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),
        if (widget.currentLocationLayer) UMapLocationLayer(follow: _follow),
        if (widget.drawController != null) UMapDrawLayer(controller: widget.drawController!, persian: widget.persianDigits),
        ...widget.topLayers,
        if (widget.compass) const Align(alignment: AlignmentDirectional.topEnd, child: Padding(padding: EdgeInsets.all(12), child: UMapCompass())),
        if (widget.scaleBar) Align(alignment: AlignmentDirectional.bottomStart, child: Padding(padding: const EdgeInsets.fromLTRB(72, 0, 12, 22), child: UMapScaleBar(persian: widget.persianDigits, imperial: widget.imperial))),
        if (widget.miniMap) Align(alignment: AlignmentDirectional.topStart, child: Padding(padding: const EdgeInsets.all(12), child: UMapMiniMap(source: base))),
        if (widget.showAttribution) Align(alignment: AlignmentDirectional.bottomEnd, child: UMapAttribution(attributions)),
      ],
    );
    if (widget.tilt > 0) {
      final double t = widget.tilt.clamp(0, 60) * math.pi / 180;
      final Widget flat = map;
      map = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) => ClipRect(
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(t),
            child: OverflowBox(alignment: Alignment.bottomCenter, maxHeight: c.maxHeight * (1 + t * 1.2), minHeight: c.maxHeight * (1 + t * 1.2), child: flat),
          ),
        ),
      );
    }
    final Widget stack = Stack(
      children: <Widget>[
        Positioned.fill(child: map),
        if (widget.myLocationButton)
          PositionedDirectional(
            bottom: 16,
            start: 16,
            child: UMapLocateButton(controller: _controller, follow: _follow, heroTag: "UMapFab1"),
          ),
        if (widget.zoomButtons)
          PositionedDirectional(
            bottom: 16,
            end: 16,
            child: UMapZoomButtons(controller: _controller),
          ),
        if (widget.centerWidget != null) Align(child: widget.centerWidget),
        ...widget.controls,
      ],
    );
    return widget.captureController == null ? stack : UWidgetToImage(controller: widget.captureController!, child: stack);
  }
}

/// Animated camera moves on any MapController: `controller.flyTo(point, zoom: 15)`, `controller.animateTo(zoom: 12)`, `controller.fitPoints(points)`.
extension UMapControllerAnimation on MapController {
  static final Expando<(Ticker, Completer<void>)> _running = Expando<(Ticker, Completer<void>)>();

  Future<void> _animate(Duration duration, void Function(double t) apply) {
    final (Ticker, Completer<void>)? old = _running[this];
    if (old != null) {
      old.$1.dispose();
      if (!old.$2.isCompleted) old.$2.complete();
    }
    final Completer<void> done = Completer<void>();
    late final Ticker ticker;
    ticker = Ticker((Duration elapsed) {
      final double t = duration.inMicroseconds == 0 ? 1 : (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
      try {
        apply(t);
      } on Object {
        // The map is not laid out yet; stop quietly.
        ticker.dispose();
        _running[this] = null;
        if (!done.isCompleted) done.complete();
        return;
      }
      if (t >= 1) {
        ticker.dispose();
        _running[this] = null;
        if (!done.isCompleted) done.complete();
      }
    });
    _running[this] = (ticker, done);
    ticker.start();
    return done.future;
  }

  /// Smoothly moves/zooms/rotates to a camera. `controller.animateTo(center: p, zoom: 14)`
  Future<void> animateTo({LatLng? center, double? zoom, double? rotation, Duration duration = const Duration(milliseconds: 450), Curve curve = Curves.easeInOutCubic}) {
    final MapCamera c = camera;
    final LatLng c0 = c.center;
    final LatLng c1 = center ?? c0;
    final double z0 = c.zoom;
    final double z1 = zoom ?? z0;
    final double r0 = c.rotation;
    double r1 = rotation ?? r0;
    while (r1 - r0 > 180) {
      r1 -= 360;
    }
    while (r1 - r0 < -180) {
      r1 += 360;
    }
    return _animate(duration, (double t) {
      final double e = curve.transform(t);
      moveAndRotate(LatLng(c0.latitude + (c1.latitude - c0.latitude) * e, c0.longitude + (c1.longitude - c0.longitude) * e), z0 + (z1 - z0) * e, r0 + (r1 - r0) * e);
    });
  }

  /// Google-Earth-style flight: zooms out, travels and zooms in along an optimal path (van Wijk & Nuij). `controller.flyTo(p, zoom: 15)`
  Future<void> flyTo(LatLng target, {double? zoom, double? rotation, Duration? duration, double curvature = 1.42}) {
    final MapCamera c = camera;
    final double z0 = c.zoom;
    final double z1 = zoom ?? z0;
    final Offset p0 = c.projectAtZoom(c.center, z0);
    final Offset p1 = c.projectAtZoom(target, z0);
    final double w0 = math.max(c.size.width, c.size.height);
    final double w1 = w0 / math.pow(2, z1 - z0);
    final double u1 = (p1 - p0).distance;
    final double rho = curvature;
    final double rho2 = rho * rho;
    double sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
    double cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;
    double tanh(double x) => sinh(x) / cosh(x);
    double r(int i) {
      final double b = (w1 * w1 - w0 * w0 + (i == 0 ? 1 : -1) * rho2 * rho2 * u1 * u1) / (2 * (i == 0 ? w0 : w1) * rho2 * u1);
      return math.log(math.sqrt(b * b + 1) - b);
    }

    final bool still = u1.abs() < 1e-6;
    final double r0 = still ? 0 : r(0);
    final double s = still ? (math.log(w1 / w0).abs() / rho) : (r(1) - r0) / rho;
    final Duration time = duration ?? Duration(milliseconds: (s / 1.2 * 1000).clamp(400, 3500).round());
    final double rot0 = c.rotation;
    final double rot1 = rotation ?? rot0;
    return _animate(time, (double t) {
      final double e = Curves.easeInOut.transform(t);
      final double sv = e * s;
      final double w = still ? math.exp((w1 < w0 ? -1 : 1) * rho * sv) : cosh(r0) / cosh(r0 + rho * sv);
      final double u = still ? 0 : w0 * ((cosh(r0) * tanh(r0 + rho * sv) - sinh(r0)) / rho2) / u1;
      final Offset p = Offset.lerp(p0, p1, u.clamp(0.0, 1.0))!;
      moveAndRotate(c.unprojectAtZoom(p, z0), (z0 + math.log(1 / w) / math.ln2).clamp(0, 24), rot0 + (rot1 - rot0) * e);
    });
  }

  /// Fits the camera to points (animated). `controller.fitPoints(route.points)`
  Future<void> fitPoints(List<LatLng> points, {EdgeInsets padding = const EdgeInsets.all(48), double maxZoom = 17, bool animate = true}) async {
    if (points.isEmpty) return;
    if (points.length == 1) return animate ? flyTo(points.first, zoom: math.min(maxZoom, 16)) : Future<void>.sync(() => move(points.first, math.min(maxZoom, 16)));
    final MapCamera fitted = CameraFit.coordinates(coordinates: points, padding: padding, maxZoom: maxZoom).fit(camera);
    if (!animate) {
      move(fitted.center, fitted.zoom);
      return;
    }
    return flyTo(fitted.center, zoom: fitted.zoom);
  }

  /// Fits the camera to a box (animated).
  Future<void> fitBoundsAnimated(LatLngBounds bounds, {EdgeInsets padding = const EdgeInsets.all(48)}) => fitPoints(<LatLng>[bounds.southWest, bounds.northEast], padding: padding);

  /// Turns the map back to north-up.
  Future<void> resetNorth() => animateTo(rotation: 0);

  /// Zooms in one step (animated).
  Future<void> zoomInAnimated() => animateTo(zoom: camera.zoom + 1, duration: const Duration(milliseconds: 250));

  /// Zooms out one step (animated).
  Future<void> zoomOutAnimated() => animateTo(zoom: camera.zoom - 1, duration: const Duration(milliseconds: 250));
}

/// A ready demo map to try UMap quickly.
class UDemoMap extends StatelessWidget {
  const UDemoMap({super.key});

  @override
  Widget build(BuildContext context) {
    final MapController controller = MapController();

    final List<Marker> markers = <Marker>[
      const Marker(
        point: LatLng(51.509364, -0.128928),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40,
        ),
      ),
      const Marker(
        point: LatLng(51.514364, -0.133928),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_pin,
          color: Colors.blue,
          size: 40,
        ),
      ),
    ];

    final List<Polyline<Object>> polylines = <Polyline<Object>>[
      Polyline<Object>(
        points: <LatLng>[
          const LatLng(51.509364, -0.128928),
          const LatLng(51.514364, -0.133928),
          const LatLng(51.510364, -0.138928),
        ],
        color: Colors.blue,
        strokeWidth: 4,
      ),
    ];

    final List<Polygon<Object>> polygons = <Polygon<Object>>[
      Polygon<Object>(
        points: <LatLng>[
          const LatLng(51.505364, -0.125928),
          const LatLng(51.507364, -0.130928),
          const LatLng(51.503364, -0.130928),
        ],
        color: Colors.green.withValues(alpha: 0.3),
        borderColor: Colors.green,
        borderStrokeWidth: 2,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Map Demo")),
      body: UMap(
        controller: controller,
        zoom: 12,
        markers: markers,
        polylines: polylines,
        polygons: polygons,
        centerWidget: const Icon(
          Icons.center_focus_strong,
          color: Colors.red,
          size: 24,
        ),
        onTap: (TapPosition position, LatLng point) {
          debugPrint("Tapped at: $point");
        },
        onLongPress: (TapPosition position, LatLng point) {
          debugPrint("Long pressed at: $point");
        },
        onPositionChanged: (MapCamera camera, bool hasGesture) {
          debugPrint("Map moved to: ${camera.center}, zoom: ${camera.zoom}");
        },
      ),
    );
  }
}
