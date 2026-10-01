import "package:u/utilities.dart";

import "maps_page.dart";

enum _Tab { live, record, geofence, playback, shared }

/// Blue dot and follow modes, track recording, polygon geofences, speed alerts and playback.
class LocationDemo extends StatefulWidget {
  const LocationDemo({super.key});

  @override
  State<LocationDemo> createState() => _LocationDemoState();
}

class _LocationDemoState extends State<LocationDemo> {
  final MapController _map = MapController();
  final ValueNotifier<UMapFollowMode> _follow = ValueNotifier<UMapFollowMode>(UMapFollowMode.none);
  late final UTrackRecorder _recorder = UTrackRecorder(speedLimit: 50 / 3.6, onOverSpeed: (double v) => UToast.warning(message: "Over 50 km/h: ${UMaps.formatSpeed(v)}"));
  final UMapGeofencer _fences = UMapGeofencer(<UMapZone>[
    UMapZone.polygon(id: "Azadi square", polygon: UGeo.circle(kTehran, 600, segments: 6), dwell: const Duration(seconds: 20)),
    UMapZone.circle(id: "Milad tower", center: const LatLng(35.7448, 51.3753), radius: 500),
  ]);
  final List<String> _events = <String>[];
  StreamSubscription<UMapZoneEvent>? _fenceSub;
  _Tab _tab = _Tab.live;
  bool _simulate = true;
  StreamController<UPosition>? _fake;
  Timer? _fakeTimer;
  UMapPlaybackController? _playback;
  List<UGeoTrackPoint> _playTrack = <UGeoTrackPoint>[];
  UMapLiveSession? _mine;
  UMapLiveSession? _friend;
  Timer? _friendTimer;

  @override
  void initState() {
    super.initState();
    _fenceSub = _fences.events.listen((UMapZoneEvent e) => setState(() => _events.insert(0, "${e.transition.name} · ${e.zone.id} · ${e.time.toIso8601String().substring(11, 19)}")));
  }

  /// Two sessions wired back-to-back (in a real app `send` goes to your WebSocket/Firebase and `receive` is fed from it).
  void _startShared() {
    _friendTimer?.cancel();
    _mine?.dispose();
    _friend?.dispose();
    late final UMapLiveSession mine;
    late final UMapLiveSession friend;
    mine = UMapLiveSession(me: "me", name: "Me", send: (String json) => friend.receive(json));
    friend = UMapLiveSession(me: "sara", name: "Sara", send: (String json) => mine.receive(json));
    _mine = mine;
    _friend = friend;
    double t = 0;
    _friendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      t += 1;
      final LatLng p = UGeo.destination(const LatLng(35.7448, 51.3753), 1500 - t * 20, 200);
      unawaited(friend.share(p, heading: 20, speed: 9, color: Colors.pink, force: true));
      unawaited(mine.share(UGeo.destination(kTehran, t * 15, 40), heading: 40, force: true));
    });
    setState(() {});
  }

  @override
  void dispose() {
    _friendTimer?.cancel();
    _mine?.dispose();
    _friend?.dispose();
    _fenceSub?.cancel();
    _fakeTimer?.cancel();
    _fake?.close();
    _recorder.dispose();
    unawaited(_fences.dispose());
    _playback?.dispose();
    _follow.dispose();
    _map.dispose();
    super.dispose();
  }

  /// A fake GPS walking around Azadi square, so the demo works on desktop/web without GPS.
  Stream<UPosition> _fakePositions() {
    _fake?.close();
    _fakeTimer?.cancel();
    _fake = StreamController<UPosition>.broadcast();
    double angle = 0;
    _fakeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      angle += 6;
      final LatLng p = UGeo.destination(kTehran, 900, angle);
      _fake?.add(UPosition(latitude: p.latitude + (Random().nextDouble() - 0.5) * 0.0002, longitude: p.longitude, time: DateTime.now(), accuracy: 12, speed: 15, heading: (angle + 90) % 360, altitude: 1200 + angle / 10));
    });
    return _fake!.stream;
  }

  Future<void> _startRecording() async {
    if (_simulate) {
      await _recorder.start(positions: _fakePositions());
    } else {
      final ULocationError? e = await ULocation.ensureReady();
      if (e != null) return UToast.error(message: "Location: ${e.name}");
      await _recorder.start();
    }
    _fences.start(_simulate ? _fake!.stream : null);
  }

  void _preparePlayback() {
    final DateTime t0 = DateTime(2026, 9, 1, 8);
    final List<LatLng> loop = <LatLng>[for (int i = 0; i <= 120; i++) UGeo.destination(kTehran, 1200 + 400 * sin(i / 10), i * 3.0)];
    _playTrack = <UGeoTrackPoint>[for (int i = 0; i < loop.length; i++) UGeoTrackPoint(loop[i], time: t0.add(Duration(seconds: i * 30)))];
    _playback?.dispose();
    _playback = UMapPlaybackController(start: _playTrack.first.time!, end: _playTrack.last.time!, speed: 300);
  }

  @override
  Widget build(BuildContext context) => MapDemoScaffold(
    title: "Location & tracking",
    map: ListenableBuilder(
      listenable: _recorder,
      builder: (BuildContext context, _) => UMap(
        controller: _map,
        center: kTehran,
        zoom: 14,
        currentLocationLayer: false,
        myLocationButton: false,
        layers: <Widget>[
          PolygonLayer<Object>(
            polygons: <Polygon<Object>>[
              for (final UMapZone z in _fences.zones)
                Polygon<Object>(points: z.outline, color: (_fences.insideIds.contains(z.id) ? Colors.green : Colors.orange).withValues(alpha: 0.2), borderColor: Colors.orange, borderStrokeWidth: 2),
            ],
          ),
          if (_recorder.path.length > 1) UMapStyledLineLayer(lines: <UMapStyledLine>[UMapStyledLine(points: _recorder.path, casing: Colors.white, arrows: true)]),
          UMapLocationLayer(follow: _follow, positions: _simulate ? (_fake?.stream ?? _fakePositions()) : null, trail: true),
          if (_tab == _Tab.playback && _playback != null) UMapTrackPlayback(track: _playTrack, controller: _playback!),
          if (_tab == _Tab.shared && _mine != null)
            ListenableBuilder(
              listenable: _mine!,
              builder: (BuildContext context, _) => UMapMovingMarkersLayer(
                markers: <UMapMovingMarker>[
                  for (final UMapPeer p in _mine!.peers)
                    UMapMovingMarker(
                      id: p.id,
                      point: p.point,
                      heading: p.heading,
                      label: p.name,
                      child: Icon(Icons.navigation, color: p.color ?? Colors.pink, size: 30),
                    ),
                ],
              ),
            ),
        ],
        controls: <Widget>[
          PositionedDirectional(bottom: 16, start: 16, child: UMapLocateButton(follow: _follow, controller: _map, heroTag: "loc_demo")),
          if (_tab == _Tab.playback && _playback != null) Positioned(left: 70, right: 70, bottom: 12, child: UMapTimeSlider(controller: _playback!, persian: true)),
        ],
      ),
    ),
    panel: ListenableBuilder(
      listenable: _recorder,
      builder: (BuildContext context, _) {
        final UTrackStats s = _recorder.stats;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: <Widget>[
            MapChips<_Tab>(
              values: _Tab.values,
              selected: _tab,
              label: (_Tab t) => t.name,
              onSelected: (_Tab t) => setState(() {
                _tab = t;
                if (t == _Tab.playback) _preparePlayback();
                if (t == _Tab.shared) _startShared();
              }),
            ),
            SwitchListTile(
              dense: true,
              title: const Text("Simulated GPS (desktop/web friendly)"),
              subtitle: const Text("Off = real GPS, needs `dart run u:app permission add location`"),
              value: _simulate,
              onChanged: (bool v) => setState(() => _simulate = v),
            ),
            if (_tab == _Tab.live) const Text("Tap the locate button: centre → follow → follow with heading (map turns). Dragging the map stops following.", style: TextStyle(fontSize: 12)),
            if (_tab == _Tab.record) ...<Widget>[
              Wrap(
                spacing: 6,
                children: <Widget>[
                  if (!_recorder.isRecording && !_recorder.isPaused) FilledButton.icon(icon: const Icon(Icons.fiber_manual_record), label: const Text("Record"), onPressed: _startRecording),
                  if (_recorder.isRecording) OutlinedButton.icon(icon: const Icon(Icons.pause), label: const Text("Pause"), onPressed: _recorder.pause),
                  if (_recorder.isPaused) OutlinedButton.icon(icon: const Icon(Icons.play_arrow), label: const Text("Resume"), onPressed: _recorder.resume),
                  OutlinedButton.icon(icon: const Icon(Icons.stop), label: const Text("Stop"), onPressed: _recorder.stop),
                  OutlinedButton.icon(icon: const Icon(Icons.ios_share), label: const Text("GPX"), onPressed: () => UShare.bytes(utf8.encode(_recorder.toGpx()), name: "track.gpx", mimeType: "application/gpx+xml")),
                ],
              ),
              Text(
                "${UMaps.formatDistance(s.distance, persian: true)} · ${UMaps.formatDuration(s.duration, persian: true)} · avg ${UMaps.formatSpeed(s.averageSpeed)} · max ${UMaps.formatSpeed(s.maxSpeed)} · pace ${UMapFormat.pace(s.averageSpeed)} · ↑${s.elevationGain.round()} m",
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (_tab == _Tab.geofence) ...<Widget>[
              const Text("Polygon + circle zones checked in Dart on every fix (enter / exit / dwell after 20 s). Start recording to feed positions.", style: TextStyle(fontSize: 12)),
              for (final String e in _events.take(6)) Text(e, style: const TextStyle(fontSize: 12)),
            ],
            if (_tab == _Tab.shared && _mine != null)
              ListenableBuilder(
                listenable: _mine!,
                builder: (BuildContext context, _) => Text(
                  _mine!.peers.isEmpty
                      ? "Waiting for friends…"
                      : _mine!.peers.map((UMapPeer p) => "${p.name}: ${UMaps.formatDistance(UGeo.distance(kTehran, p.point), persian: true)} away, ${UMaps.formatSpeed(p.speed ?? 0, persian: true)}").join("\n"),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (_tab == _Tab.playback) const Text("A timed track replayed at 300×; drag the slider or change speed. Dates are Jalali.", style: TextStyle(fontSize: 12)),
          ],
        );
      },
    ),
  );
}
