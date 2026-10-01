import "package:u/utilities.dart";

import "maps_page.dart";

enum _Task { route, isochrone, stops, offline }

/// Routes, alternatives, steps, elevation, navigation simulation, isochrones, stop ordering and an offline router.
class RoutingDemo extends StatefulWidget {
  const RoutingDemo({super.key});

  @override
  State<RoutingDemo> createState() => _RoutingDemoState();
}

class _RoutingDemoState extends State<RoutingDemo> {
  final MapController _map = MapController();
  _Task _task = _Task.route;
  UMapRouteProfile _profile = UMapRouteProfile.car;
  LatLng _from = kTehran;
  LatLng _to = const LatLng(35.7448, 51.3753);
  List<UMapRoute> _routes = <UMapRoute>[];
  int _picked = 0;
  List<(double, double)> _profileData = <(double, double)>[];
  LatLng? _hover;
  UMapNavigation? _nav;
  StreamSubscription<LatLng>? _sim;
  StreamSubscription<String>? _voice;
  String _lastVoice = "";
  List<(int, List<LatLng>)> _isochrones = <(int, List<LatLng>)>[];
  final List<LatLng> _stops = <LatLng>[];
  List<int> _order = <int>[];
  UMapRoadGraph? _graph;
  bool _persian = true;
  bool _busy = false;

  @override
  void dispose() {
    _stopNav();
    _map.dispose();
    super.dispose();
  }

  void _stopNav() {
    _sim?.cancel();
    _voice?.cancel();
    _nav?.dispose();
    _nav = null;
  }

  Future<void> _route() async {
    setState(() => _busy = true);
    final List<UMapRoute>? r = await tryMap(() => UMaps.route(<LatLng>[_from, _to], profile: _profile, alternatives: true, persian: _persian));
    setState(() {
      _busy = false;
      _routes = r ?? <UMapRoute>[];
      _picked = 0;
      _profileData = <(double, double)>[];
    });
    if (_routes.isEmpty) return;
    unawaited(_map.fitPoints(_routes.first.points, padding: const EdgeInsets.all(60)));
    final List<(double, double)>? elevation = await tryMap(() => UMaps.elevationProfile(_routes.first.points, samples: 60));
    if (mounted && elevation != null) setState(() => _profileData = elevation);
  }

  void _simulate() {
    _stopNav();
    final UMapNavigation nav = UMaps.navigate(_routes[_picked], persian: _persian);
    _voice = nav.announcements.listen((String s) => setState(() => _lastVoice = s));
    _sim = nav.simulate(speed: 25, tick: const Duration(milliseconds: 300)).listen((LatLng p) => _map.move(p, 17));
    setState(() => _nav = nav);
  }

  Future<void> _isochrone() async {
    setState(() => _busy = true);
    final List<(int, List<LatLng>)>? r = await tryMap(() => UMaps.isochrones(_from, <int>[5, 10, 15], profile: _profile));
    setState(() {
      _busy = false;
      _isochrones = r ?? <(int, List<LatLng>)>[];
    });
  }

  Future<void> _optimize({required bool roads}) async {
    if (_stops.length < 3) return UToast.info(message: "Tap at least 3 stops");
    final List<int>? order = roads ? await tryMap(() => UMaps.optimizeStops(_stops, roundTrip: true)) : UGeo.bestOrder(_stops, roundTrip: true);
    if (order != null) setState(() => _order = order);
  }

  Future<void> _offlineGraph() async {
    setState(() => _busy = true);
    final LatLng c = _map.camera.center;
    final UMapRoadGraph? g = await tryMap(() => UMaps.roadGraph(LatLngBounds(UGeo.destination(c, 2500, 225), UGeo.destination(c, 2500, 45)), profile: _profile));
    setState(() {
      _busy = false;
      _graph = g;
    });
    if (g != null) UToast.info(message: "Offline graph: ${g.nodeCount} nodes, ${(g.toBytes().length / 1024).round()} KB — now tap two points");
  }

  void _tap(LatLng p) {
    switch (_task) {
      case _Task.route:
        setState(() {
          _from = _to;
          _to = p;
        });
        unawaited(_route());
      case _Task.isochrone:
        setState(() => _from = p);
        unawaited(_isochrone());
      case _Task.stops:
        setState(() {
          _stops.add(p);
          _order = <int>[];
        });
      case _Task.offline:
        if (_graph == null) return;
        setState(() {
          _from = _to;
          _to = p;
          final UMapRoute? r = _graph!.route(_from, _to, persian: _persian);
          _routes = r == null ? <UMapRoute>[] : <UMapRoute>[r];
          _picked = 0;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final UMapRoute? route = _routes.isEmpty ? null : _routes[_picked];
    final List<Color> isoColors = <Color>[Colors.red, Colors.orange, Colors.yellow];
    return MapDemoScaffold(
      title: "Routing & navigation",
      map: UMap(
        controller: _map,
        center: kTehran,
        zoom: 13,
        onTap: (_, LatLng p) => _tap(p),
        layers: <Widget>[
          if (_task == _Task.isochrone)
            PolygonLayer<Object>(
              polygons: <Polygon<Object>>[
                for (int i = 0; i < _isochrones.length; i++)
                  Polygon<Object>(points: _isochrones[i].$2, color: isoColors[i % 3].withValues(alpha: 0.25), borderColor: isoColors[i % 3], borderStrokeWidth: 2),
              ],
            ),
          if (_task == _Task.offline && _graph != null) PolygonLayer<Object>(polygons: <Polygon<Object>>[Polygon<Object>(points: _graph!.isochrone(_from, const Duration(minutes: 3)), color: Colors.teal.withValues(alpha: 0.15), borderColor: Colors.teal)]),
          if (route != null)
            PolylineLayer<Object>(
              polylines: <Polyline<Object>>[
                for (int i = 0; i < _routes.length; i++)
                  if (i != _picked) Polyline<Object>(points: _routes[i].points, color: Colors.grey, strokeWidth: 6, borderColor: Colors.white, borderStrokeWidth: 1),
              ],
            ),
          if (route != null) UMapStyledLineLayer(lines: <UMapStyledLine>[UMapStyledLine(points: route.points, casing: const Color(0xFF0D47A1), arrows: true)]),
          if (_task == _Task.stops && _stops.isNotEmpty) ...<Widget>[
            if (_order.isNotEmpty) PolylineLayer<Object>(polylines: <Polyline<Object>>[Polyline<Object>(points: <LatLng>[for (final int i in _order) _stops[i], _stops[_order.first]], color: Colors.deepPurple, strokeWidth: 4)]),
            UMapLabelLayer(labels: <UMapLabel>[for (int k = 0; k < _stops.length; k++) UMapLabel(point: _stops[k], text: _order.isEmpty ? "${k + 1}" : "${_order.indexOf(k) + 1}", background: Colors.deepPurple, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]),
          ],
          MarkerLayer(
            markers: <Marker>[
              if (_task != _Task.stops) Marker(point: _from, width: 30, height: 30, child: const Icon(Icons.trip_origin, color: Colors.green)),
              if (_task == _Task.route || _task == _Task.offline) Marker(point: _to, width: 36, height: 36, alignment: Alignment.topCenter, child: const Icon(Icons.location_on, color: Colors.red, size: 36)),
              if (_hover != null) Marker(point: _hover!, width: 16, height: 16, child: const DecoratedBox(decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle))),
            ],
          ),
          if (_nav?.state != null) UMapMovingMarkersLayer(duration: const Duration(milliseconds: 300), markers: <UMapMovingMarker>[UMapMovingMarker(id: "me", point: _nav!.state!.snapped, heading: _nav!.state!.heading, child: const Icon(Icons.navigation, color: Color(0xFF1A73E8), size: 34))]),
        ],
        controls: <Widget>[
          if (_nav != null) Positioned(left: 12, right: 12, top: 12, child: UMapNavigationBanner(navigation: _nav!, persian: _persian, onClose: () => setState(_stopNav))),
        ],
      ),
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: <Widget>[
          MapChips<_Task>(values: _Task.values, selected: _task, label: (_Task t) => t.name, onSelected: (_Task t) => setState(() => _task = t)),
          Row(
            children: <Widget>[
              Expanded(child: MapChips<UMapRouteProfile>(values: UMapRouteProfile.values, selected: _profile, label: (UMapRouteProfile p) => p.name, onSelected: (UMapRouteProfile p) => setState(() => _profile = p))),
              FilterChip(label: const Text("فارسی"), selected: _persian, onSelected: (bool v) => setState(() => _persian = v)),
              if (_busy) const Padding(padding: EdgeInsets.all(8), child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ],
          ),
          if (_task == _Task.route) ...<Widget>[
            const Text("Tap the map to set a new destination (the old one becomes the start).", style: TextStyle(fontSize: 12)),
            if (route != null)
              Wrap(
                spacing: 6,
                children: <Widget>[
                  for (int i = 0; i < _routes.length; i++)
                    ChoiceChip(
                      label: Text("${UMaps.formatDuration(_routes[i].duration, persian: _persian)} · ${UMaps.formatDistance(_routes[i].distance, persian: _persian)}"),
                      selected: i == _picked,
                      onSelected: (_) => setState(() => _picked = i),
                    ),
                  FilledButton.icon(icon: const Icon(Icons.navigation), label: const Text("Simulate"), onPressed: _simulate),
                  OutlinedButton(onPressed: () => UMaps.openDirections(_to, from: _from), child: const Text("Google Maps")),
                ],
              ),
            if (_lastVoice.isNotEmpty) Text("🔊 $_lastVoice", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            if (_profileData.length > 1) UMapElevationProfile(profile: _profileData, path: route?.points, height: 70, persian: _persian, onHover: (LatLng? p) => setState(() => _hover = p)),
            if (route != null) for (final UMapRouteStep s in route.steps.take(8)) ListTile(dense: true, leading: Icon(s.icon), title: Text(s.instruction), trailing: Text(UMaps.formatDistance(s.distance, persian: _persian))),
          ],
          if (_task == _Task.isochrone) const Text("Tap a start point: areas reachable in 5 / 10 / 15 minutes (Valhalla).", style: TextStyle(fontSize: 12)),
          if (_task == _Task.stops)
            Wrap(
              spacing: 6,
              children: <Widget>[
                Text("${_stops.length} stops — tap to add.", style: const TextStyle(fontSize: 12)),
                OutlinedButton(onPressed: () => _optimize(roads: false), child: const Text("Best order (offline)")),
                OutlinedButton(onPressed: () => _optimize(roads: true), child: const Text("Best order (road distances)")),
                TextButton(onPressed: () => setState(() => _stops.clear()), child: const Text("Clear")),
              ],
            ),
          if (_task == _Task.offline)
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const Text("Downloads the roads around the centre once (Overpass), then routes with A* fully offline. Teal = 3-minute reach.", style: TextStyle(fontSize: 12)),
                FilledButton(onPressed: _offlineGraph, child: Text(_graph == null ? "Download road graph" : "Rebuild here")),
              ],
            ),
        ],
      ),
    );
  }
}
