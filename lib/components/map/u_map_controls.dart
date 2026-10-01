import "dart:math" as math;

import "package:flutter/scheduler.dart";
import "package:u/utilities.dart";

/// Compass that shows while the map is rotated; tap to face north. Put it inside a FlutterMap/UMap layer list.
class UMapCompass extends StatelessWidget {
  const UMapCompass({this.alwaysVisible = false, this.size = 40, super.key});

  final bool alwaysVisible;
  final double size;

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    final bool rotated = camera.rotation.abs() % 360 > 0.5;
    return AnimatedOpacity(
      opacity: rotated || alwaysVisible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !rotated && !alwaysVisible,
        child: Semantics(
          button: true,
          label: "Compass, reset to north",
          child: Material(
            elevation: 3,
            shape: const CircleBorder(),
            color: Theme.of(context).colorScheme.surface,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => MapController.of(context).resetNorth(),
              child: SizedBox.square(
                dimension: size,
                child: Transform.rotate(angle: camera.rotationRad, child: CustomPaint(painter: _CompassPainter(Theme.of(context).colorScheme.onSurface))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width * 0.32;
    final Path north = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.32, c.dy)
      ..lineTo(c.dx - r * 0.32, c.dy)
      ..close();
    final Path south = Path()
      ..moveTo(c.dx, c.dy + r)
      ..lineTo(c.dx + r * 0.32, c.dy)
      ..lineTo(c.dx - r * 0.32, c.dy)
      ..close();
    canvas
      ..drawPath(north, Paint()..color = const Color(0xFFE53935))
      ..drawPath(south, Paint()..color = color.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.color != color;
}

/// Animated + / − buttons.
class UMapZoomButtons extends StatelessWidget {
  const UMapZoomButtons({required this.controller, super.key});

  final MapController controller;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FloatingActionButton(heroTag: "UMapFab2", mini: true, tooltip: "Zoom in", onPressed: controller.zoomInAnimated, child: const Icon(Icons.add)),
      const SizedBox(height: 8),
      FloatingActionButton(heroTag: "UMapFab3", mini: true, tooltip: "Zoom out", onPressed: controller.zoomOutAnimated, child: const Icon(Icons.remove)),
    ],
  );
}

/// Distance scale bar (metric or imperial, Persian digits). Put it inside a FlutterMap/UMap layer list.
class UMapScaleBar extends StatelessWidget {
  const UMapScaleBar({this.imperial = false, this.persian = false, this.maxWidth = 110, super.key});

  final bool imperial;
  final bool persian;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final MapCamera camera = MapCamera.of(context);
    final double metersPerPixel = UGeoCodes.metersPerPixel(camera.center.latitude, camera.zoom);
    final double maxMeters = metersPerPixel * maxWidth;
    final double unit = imperial ? 0.3048 : 1;
    final double maxUnits = maxMeters / unit;
    final double pow10 = math.pow(10, (math.log(maxUnits) / math.ln10).floor()).toDouble();
    final double nice = <double>[1, 2, 5].map((double f) => f * pow10).lastWhere((double v) => v <= maxUnits, orElse: () => pow10);
    final double meters = nice * unit;
    final double width = meters / metersPerPixel;
    final String label = UMapFormat.distance(meters, persian: persian, imperial: imperial);
    final Color color = Theme.of(context).colorScheme.onSurface;
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 11, color: color, shadows: const <Shadow>[Shadow(color: Colors.white, blurRadius: 3)])),
          CustomPaint(size: Size(width, 6), painter: _ScalePainter(color)),
        ],
      ),
    );
  }
}

class _ScalePainter extends CustomPainter {
  _ScalePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint halo = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final Paint line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final Path p = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0);
    canvas
      ..drawPath(p, halo)
      ..drawPath(p, line);
  }

  @override
  bool shouldRepaint(_ScalePainter old) => old.color != color;
}

/// Small overview map following the main map with its visible area outlined; tap to jump. Put it inside a FlutterMap/UMap layer list.
class UMapMiniMap extends StatefulWidget {
  const UMapMiniMap({this.source, this.size = const Size(130, 100), this.zoomOffset = 4, super.key});

  final UMapTileSource? source;
  final Size size;
  final double zoomOffset;

  @override
  State<UMapMiniMap> createState() => _UMapMiniMapState();
}

class _UMapMiniMapState extends State<UMapMiniMap> {
  final MapController _mini = MapController();
  bool _ready = false;

  @override
  void dispose() {
    _mini.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MapCamera main = MapCamera.of(context);
    final MapController mainController = MapController.of(context);
    final double zoom = math.max(0, main.zoom - widget.zoomOffset);
    if (_ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mini.move(main.center, zoom);
      });
    }
    final LatLngBounds b = main.visibleBounds;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.fromSize(
        size: widget.size,
        child: FlutterMap(
          mapController: _mini,
          options: MapOptions(
            initialCenter: main.center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            onMapReady: () => _ready = true,
            onTap: (TapPosition _, LatLng p) => mainController.flyTo(p),
          ),
          children: <Widget>[
            UMapTiles.layer(widget.source ?? UMapTileSource.openStreetMap, retina: false),
            PolygonLayer<Object>(
              polygons: <Polygon<Object>>[
                Polygon<Object>(points: UGeoMath.boundsRing(b), color: Colors.blue.withValues(alpha: 0.15), borderColor: Colors.blue, borderStrokeWidth: 1.5),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small attribution text (required by OSM and most providers); tap to expand.
class UMapAttribution extends StatefulWidget {
  const UMapAttribution(this.attributions, {super.key});

  final List<String> attributions;

  @override
  State<UMapAttribution> createState() => _UMapAttributionState();
}

class _UMapAttributionState extends State<UMapAttribution> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.attributions.isEmpty) return const SizedBox.shrink();
    final String text = _open ? widget.attributions.join("\n") : widget.attributions.first.split(",").first;
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: const BorderRadius.only(topLeft: Radius.circular(6))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.black87)),
        ),
      ),
    );
  }
}

/// A map style picker sheet: free presets plus your own sources; returns the picked source.
abstract final class UMapStylePicker {
  /// Shows a bottom sheet of styles. `final s = await UMapStylePicker.show(context);`
  static Future<UMapTileSource?> show(BuildContext context, {List<UMapTileSource> sources = UMapTileSource.freePresets, UMapTileSource? selected}) => showModalBottomSheet<UMapTileSource>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => SafeArea(
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: <Widget>[
          for (final UMapTileSource s in sources)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).pop(s),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: s.id == selected?.id ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image(image: UMapTileImage(s, 10, 652, 404), fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Before/after swipe between two maps that move together (e.g. 2016 satellite vs today, light vs dark).
class UMapCompare extends StatefulWidget {
  const UMapCompare({required this.left, required this.right, this.center = const LatLng(35.7, 51.4), this.zoom = 12, super.key});

  /// Layers of each side (usually a tile layer each).
  final List<Widget> left;
  final List<Widget> right;
  final LatLng center;
  final double zoom;

  @override
  State<UMapCompare> createState() => _UMapCompareState();
}

class _UMapCompareState extends State<UMapCompare> {
  final MapController _a = MapController();
  final MapController _b = MapController();
  double _split = 0.5;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints c) => Stack(
      children: <Widget>[
        FlutterMap(
          mapController: _a,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            onPositionChanged: (MapCamera cam, bool gesture) {
              if (gesture) _b.move(cam.center, cam.zoom);
            },
          ),
          children: widget.left,
        ),
        ClipRect(
          clipper: _SplitClipper(_split),
          child: IgnorePointer(
            child: FlutterMap(
              mapController: _b,
              options: MapOptions(initialCenter: widget.center, initialZoom: widget.zoom),
              children: widget.right,
            ),
          ),
        ),
        Positioned(
          left: c.maxWidth * _split - 18,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onHorizontalDragUpdate: (DragUpdateDetails d) => setState(() => _split = (_split + d.delta.dx / c.maxWidth).clamp(0.02, 0.98)),
            child: SizedBox(
              width: 36,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(width: 3, color: Colors.white),
                  const CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.compare_arrows, size: 18, color: Colors.black87)),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SplitClipper extends CustomClipper<Rect> {
  _SplitClipper(this.split);

  final double split;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(size.width * split, 0, size.width, size.height);

  @override
  bool shouldReclip(_SplitClipper old) => old.split != split;
}

/// Play/pause time controller for animated data (track playback, time-based layers).
class UMapPlaybackController extends ChangeNotifier {
  UMapPlaybackController({required this.start, required this.end, this.speed = 60});

  final DateTime start;
  final DateTime end;

  /// Seconds of data time per real second.
  double speed;
  DateTime? _time;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  /// Current data time.
  DateTime get time => _time ?? start;

  /// 0..1 position.
  double get fraction => end.difference(start).inMilliseconds == 0 ? 0 : time.difference(start).inMilliseconds / end.difference(start).inMilliseconds;

  bool get isPlaying => _ticker?.isActive ?? false;

  /// Jumps to a time.
  void seek(DateTime t) {
    _time = t.isBefore(start) ? start : (t.isAfter(end) ? end : t);
    notifyListeners();
  }

  /// Jumps to a fraction 0..1.
  void seekFraction(double f) => seek(start.add(Duration(milliseconds: (end.difference(start).inMilliseconds * f.clamp(0, 1)).round())));

  /// Starts playing.
  void play() {
    if (time == end) seek(start);
    _ticker ??= Ticker((Duration elapsed) {
      final Duration dt = elapsed - _lastTick;
      _lastTick = elapsed;
      seek(time.add(Duration(microseconds: (dt.inMicroseconds * speed).round())));
      if (time == end) pause();
    });
    _lastTick = Duration.zero;
    if (!_ticker!.isActive) _ticker!.start();
    notifyListeners();
  }

  /// Pauses.
  void pause() {
    _ticker?.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

/// Time slider with play/pause and speed for a [UMapPlaybackController]; [persian] shows Jalali dates.
class UMapTimeSlider extends StatelessWidget {
  const UMapTimeSlider({required this.controller, this.persian = false, super.key});

  final UMapPlaybackController controller;
  final bool persian;

  String _label(DateTime t) {
    final String hm = "${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}:${t.second.toString().padLeft(2, "0")}";
    if (!persian) return "${t.year}-${t.month.toString().padLeft(2, "0")}-${t.day.toString().padLeft(2, "0")} $hm";
    final UJalali j = UJalali.fromDateTime(t);
    return "${j.year}/${j.month}/${j.day} $hm".toPersianNumber();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (BuildContext context, _) => Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: <Widget>[
            IconButton(icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow), onPressed: controller.isPlaying ? controller.pause : controller.play),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Slider(value: controller.fraction.clamp(0, 1), onChanged: controller.seekFraction),
                  Text(_label(controller.time), style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            PopupMenuButton<double>(
              tooltip: "Speed",
              initialValue: controller.speed,
              onSelected: (double v) => controller.speed = v,
              itemBuilder: (_) => <double>[1, 10, 60, 300, 1800].map((double v) => PopupMenuItem<double>(value: v, child: Text("${v.toInt()}×"))).toList(),
              child: Padding(padding: const EdgeInsets.all(8), child: Text("${controller.speed.toInt()}×")),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Search box with live suggestions (Photon by default, or your own function), recent searches and coordinate/link/Plus Code input.
class UMapSearchBar extends StatefulWidget {
  const UMapSearchBar({required this.onSelected, this.search, this.near, this.hint = "Search places", this.recent = true, this.debounce = const Duration(milliseconds: 350), super.key});

  final void Function(UMapPlace place) onSelected;

  /// Suggestions for a text; defaults to UMapServices.autocomplete.
  final Future<List<UMapPlace>> Function(String text)? search;

  /// Bias results near this point.
  final LatLng? near;
  final String hint;

  /// Show and remember recent picks.
  final bool recent;
  final Duration debounce;

  @override
  State<UMapSearchBar> createState() => _UMapSearchBarState();
}

class _UMapSearchBarState extends State<UMapSearchBar> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<UMapPlace> _results = <UMapPlace>[];
  Timer? _timer;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() async {
      if (_focus.hasFocus && _text.text.isEmpty && widget.recent) {
        final List<UMapPlace> r = await UMapPlaces.recent();
        if (mounted) setState(() => _results = r);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String q) {
    _timer?.cancel();
    final (LatLng, double?)? link = UMapLinks.parse(q, reference: widget.near);
    if (link != null) {
      setState(() => _results = <UMapPlace>[UMapPlace(name: q.trim(), point: link.$1, displayName: UGeoCodes.toDms(link.$1), source: "coordinates")]);
      return;
    }
    _timer = Timer(widget.debounce, () async {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final List<UMapPlace> r = await (widget.search?.call(q) ?? UMapServices.autocomplete(q, near: widget.near));
        if (mounted && _text.text == q) setState(() => _results = r);
      } on Object catch (e) {
        if (mounted) setState(() => _error = "$e");
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _pick(UMapPlace p) {
    _focus.unfocus();
    setState(() {
      _text.text = p.label;
      _results = <UMapPlace>[];
    });
    if (widget.recent) unawaited(UMapPlaces.addRecent(p));
    widget.onSelected(p);
  }

  @override
  Widget build(BuildContext context) => Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(28),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: _text,
          focusNode: _focus,
          onChanged: _changed,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _loading
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                : (_text.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _text.clear();
                            _results = <UMapPlace>[];
                          }),
                        )),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
        if (_results.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: <Widget>[
                for (final UMapPlace p in _results)
                  ListTile(
                    dense: true,
                    leading: Icon(p.source == "coordinates" ? Icons.pin_drop : Icons.place_outlined),
                    title: Text(p.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: p.displayName == null ? null : Text(p.displayName!, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: widget.near == null ? null : Text(UMapFormat.distance(UGeoMath.distance(widget.near!, p.point)), style: const TextStyle(fontSize: 11)),
                    onTap: () => _pick(p),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Elevation chart along a route; drag on it to see where on the map ([onHover] gives the point).
class UMapElevationProfile extends StatefulWidget {
  const UMapElevationProfile({required this.profile, this.path, this.onHover, this.height = 120, this.persian = false, this.color, super.key});

  /// (distance, elevation) pairs, e.g. from UMapTerrain.profile.
  final List<(double, double)> profile;

  /// The path the profile belongs to (for [onHover]).
  final List<LatLng>? path;
  final void Function(LatLng? point)? onHover;
  final double height;
  final bool persian;
  final Color? color;

  @override
  State<UMapElevationProfile> createState() => _UMapElevationProfileState();
}

class _UMapElevationProfileState extends State<UMapElevationProfile> {
  double? _x;

  void _hover(double? x, double width) {
    setState(() => _x = x);
    if (widget.path == null || widget.onHover == null || widget.profile.isEmpty) return;
    if (x == null) return widget.onHover!(null);
    final double d = widget.profile.last.$1 * (x / width).clamp(0, 1);
    widget.onHover!(UGeoMath.along(widget.path!, d));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile.length < 2) return SizedBox(height: widget.height);
    final ({double gain, double loss, double min, double max}) s = UMapTerrain.stats(widget.profile);
    final Color color = widget.color ?? Theme.of(context).colorScheme.primary;
    String m(double v) => widget.persian ? "${v.round()}".toPersianNumber() : "${v.round()}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text("↑ ${m(s.gain)} m  ↓ ${m(s.loss)} m  ·  ${m(s.min)}–${m(s.max)} m", style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) => GestureDetector(
            onHorizontalDragUpdate: (DragUpdateDetails d) => _hover(d.localPosition.dx, c.maxWidth),
            onHorizontalDragEnd: (_) => _hover(null, c.maxWidth),
            onTapDown: (TapDownDetails d) => _hover(d.localPosition.dx, c.maxWidth),
            child: CustomPaint(size: Size(c.maxWidth, widget.height), painter: _ProfilePainter(widget.profile, color, _x, Theme.of(context).colorScheme.onSurface)),
          ),
        ),
      ],
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter(this.profile, this.color, this.x, this.text);

  final List<(double, double)> profile;
  final Color color;
  final double? x;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    final double maxD = profile.last.$1;
    double lo = profile.map(((double, double) p) => p.$2).reduce(math.min);
    double hi = profile.map(((double, double) p) => p.$2).reduce(math.max);
    if (hi - lo < 20) {
      hi += 10;
      lo -= 10;
    }
    Offset at((double, double) p) => Offset(p.$1 / maxD * size.width, size.height - (p.$2 - lo) / (hi - lo) * (size.height - 8) - 4);
    final Path line = Path()..moveTo(at(profile.first).dx, at(profile.first).dy);
    for (final (double, double) p in profile.skip(1)) {
      line.lineTo(at(p).dx, at(p).dy);
    }
    final Path fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(fill, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[color.withValues(alpha: 0.4), color.withValues(alpha: 0.02)]).createShader(Offset.zero & size))
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    if (x != null) {
      canvas.drawLine(
        Offset(x!, 0),
        Offset(x!, size.height),
        Paint()
          ..color = text.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
      final double d = maxD * (x! / size.width).clamp(0, 1);
      final (double, double) near = profile.reduce(((double, double) a, (double, double) b) => (a.$1 - d).abs() < (b.$1 - d).abs() ? a : b);
      final TextPainter tp = TextPainter(
        text: TextSpan(text: "${near.$2.round()} m", style: TextStyle(fontSize: 11, color: text)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((x! + 4).clamp(0, size.width - tp.width), 0));
    }
  }

  @override
  bool shouldRepaint(_ProfilePainter old) => old.x != x || old.profile != profile || old.color != color;
}

/// Turn-by-turn banner for a [UMapNavigation]: next maneuver icon, distance, street, then ETA, time and distance left.
class UMapNavigationBanner extends StatelessWidget {
  const UMapNavigationBanner({required this.navigation, this.persian = false, this.onClose, super.key});

  final UMapNavigation navigation;
  final bool persian;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: navigation,
    builder: (BuildContext context, _) {
      final UMapNavigationState? s = navigation.state;
      final UMapRouteStep? next = navigation.nextStep ?? navigation.currentStep;
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: s?.offRoute ?? false ? scheme.error : const Color(0xFF0B6E4F),
            borderRadius: BorderRadius.circular(16),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Icon(next?.icon ?? Icons.navigation, color: Colors.white, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s == null ? "" : UMapFormat.distance(s.distanceToManeuver, persian: persian),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          s?.offRoute ?? false ? (persian ? "خارج از مسیر" : "Off route") : (next?.instruction ?? ""),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (s != null) const SizedBox(height: 8),
          if (s != null)
            Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Text(UMapFormat.eta(s.remainingTime, persian: persian), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0B6E4F))),
                    const SizedBox(width: 12),
                    Expanded(child: Text("${UMapFormat.duration(s.remainingTime, persian: persian)} · ${UMapFormat.distance(s.remainingDistance, persian: persian)}")),
                    if (s.speed != null) Text(UMapFormat.speed(s.speed!, persian: persian), style: const TextStyle(fontSize: 12)),
                    if (onClose != null) IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Colour legend for choropleths, heatmaps and hexbins.
class UMapLegend extends StatelessWidget {
  const UMapLegend({required this.colors, required this.min, required this.max, this.title, this.persian = false, this.width = 180, super.key});

  final List<Color> colors;
  final double min;
  final double max;
  final String? title;
  final bool persian;
  final double width;

  @override
  Widget build(BuildContext context) {
    String n(double v) {
      final String s = v.abs() >= 100 ? v.round().toString() : v.toStringAsFixed(1);
      return persian ? s.toPersianNumber() : s;
    }

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (title != null) Text(title!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                height: 10,
                decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(3)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[Text(n(min), style: const TextStyle(fontSize: 10)), Text(n((min + max) / 2), style: const TextStyle(fontSize: 10)), Text(n(max), style: const TextStyle(fontSize: 10))],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
