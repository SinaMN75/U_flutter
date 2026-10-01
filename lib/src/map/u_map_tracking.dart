import "dart:math" as math;

import "package:u/utilities.dart";

/// Smooths GPS jitter with a Kalman filter (position + accuracy); feed raw fixes, read smoothed points.
class UGeoKalman {
  UGeoKalman({this.processNoise = 3});

  /// Expected movement noise in metres per second (higher = follows raw GPS more closely).
  final double processNoise;

  double? _lat;
  double? _lng;
  double _variance = -1;
  int _time = 0;

  /// Forgets the state.
  void reset() {
    _lat = null;
    _lng = null;
    _variance = -1;
  }

  /// Smoothed point for a new fix with [accuracy] metres at [time].
  LatLng filter(LatLng p, {double accuracy = 10, DateTime? time}) {
    final double acc = math.max(1, accuracy);
    final int t = (time ?? DateTime.now()).millisecondsSinceEpoch;
    if (_variance < 0 || _lat == null) {
      _lat = p.latitude;
      _lng = p.longitude;
      _variance = acc * acc;
      _time = t;
      return p;
    }
    final int dt = t - _time;
    if (dt > 0) {
      _variance += dt * processNoise * processNoise / 1000;
      _time = t;
    }
    final double k = _variance / (_variance + acc * acc);
    _lat = _lat! + k * (p.latitude - _lat!);
    _lng = _lng! + k * (p.longitude - _lng!);
    _variance = (1 - k) * _variance;
    return LatLng(_lat!, _lng!);
  }

  /// Estimated accuracy (metres) of the smoothed point.
  double get accuracy => _variance < 0 ? double.infinity : math.sqrt(_variance);
}

/// Statistics of a recorded track.
class UTrackStats {
  const UTrackStats({
    required this.distance,
    required this.duration,
    required this.movingTime,
    required this.maxSpeed,
    required this.elevationGain,
    required this.elevationLoss,
    this.minElevation,
    this.maxElevation,
  });

  /// Metres.
  final double distance;
  final Duration duration;
  final Duration movingTime;

  /// m/s
  final double maxSpeed;
  final double elevationGain;
  final double elevationLoss;
  final double? minElevation;
  final double? maxElevation;

  /// Average speed over moving time (m/s).
  double get averageSpeed => movingTime.inMilliseconds == 0 ? 0 : distance / (movingTime.inMilliseconds / 1000);

  /// Statistics of any list of track points.
  static UTrackStats of(List<UGeoTrackPoint> points, {double movingSpeed = 0.5}) {
    double distance = 0;
    double maxSpeed = 0;
    double gain = 0;
    double loss = 0;
    double? low;
    double? high;
    int moving = 0;
    double? lastEle;
    for (int i = 0; i < points.length; i++) {
      final UGeoTrackPoint p = points[i];
      if (p.elevation != null) {
        low = math.min(low ?? p.elevation!, p.elevation!);
        high = math.max(high ?? p.elevation!, p.elevation!);
        if (lastEle != null && (p.elevation! - lastEle).abs() >= 3) {
          if (p.elevation! > lastEle) {
            gain += p.elevation! - lastEle;
          } else {
            loss += lastEle - p.elevation!;
          }
          lastEle = p.elevation;
        }
        lastEle ??= p.elevation;
      }
      if (i == 0) continue;
      final UGeoTrackPoint q = points[i - 1];
      final double d = UGeoMath.distance(q.point, p.point);
      distance += d;
      if (p.time != null && q.time != null) {
        final int ms = p.time!.difference(q.time!).inMilliseconds;
        final double v = p.speed ?? (ms > 0 ? d / (ms / 1000) : 0);
        if (v >= movingSpeed && ms < 60000) moving += ms;
        if (v < 80) maxSpeed = math.max(maxSpeed, v);
      }
    }
    final Duration total = points.length > 1 && points.first.time != null && points.last.time != null ? points.last.time!.difference(points.first.time!) : Duration.zero;
    return UTrackStats(
      distance: distance,
      duration: total,
      movingTime: Duration(milliseconds: moving),
      maxSpeed: maxSpeed,
      elevationGain: gain,
      elevationLoss: loss,
      minElevation: low,
      maxElevation: high,
    );
  }
}

/// Records a GPS track (walk, run, ride, drive): pause/resume, Kalman smoothing, live stats, speed alerts, GPX export.
class UTrackRecorder extends ChangeNotifier {
  UTrackRecorder({this.smooth = true, this.minDistance = 3, this.maxAccuracy = 50, this.speedLimit, this.onOverSpeed});

  /// Smooth positions with [UGeoKalman].
  final bool smooth;

  /// Skip fixes closer than this to the last kept point (metres).
  final double minDistance;

  /// Ignore fixes less accurate than this (metres).
  final double maxAccuracy;

  /// Speed limit (m/s) for [onOverSpeed]; null = off.
  double? speedLimit;

  /// Called when the speed passes [speedLimit].
  final void Function(double speed)? onOverSpeed;

  final List<List<UGeoTrackPoint>> _segments = <List<UGeoTrackPoint>>[];
  final UGeoKalman _kalman = UGeoKalman();
  StreamSubscription<UPosition>? _sub;
  bool _paused = false;
  bool _overSpeed = false;

  /// Segments (a new one starts after each resume).
  List<List<UGeoTrackPoint>> get segments => _segments;

  /// Every point.
  List<UGeoTrackPoint> get points => _segments.expand((List<UGeoTrackPoint> s) => s).toList();

  /// Every point as LatLng (for a polyline / breadcrumb).
  List<LatLng> get path => points.map((UGeoTrackPoint p) => p.point).toList();

  bool get isRecording => _sub != null && !_paused;

  bool get isPaused => _paused;

  /// Live statistics.
  UTrackStats get stats => UTrackStats.of(points);

  /// Last speed (m/s).
  double get speed => points.isEmpty ? 0 : (points.last.speed ?? 0);

  /// Starts recording from [ULocation] (or a given stream). [background] keeps going with the screen off (Android/iOS; needs `permission add location-always`).
  Future<void> start({Stream<UPosition>? positions, bool background = false}) async {
    await _sub?.cancel();
    _paused = false;
    _segments.add(<UGeoTrackPoint>[]);
    _sub = (positions ?? ULocation.stream(ULocationSettings(distanceFilter: minDistance, background: background, activity: ULocationActivity.fitness))).listen(add);
    notifyListeners();
  }

  /// Pauses (fixes are ignored until [resume]).
  void pause() {
    _paused = true;
    notifyListeners();
  }

  /// Resumes in a new segment.
  void resume() {
    _paused = false;
    _segments.add(<UGeoTrackPoint>[]);
    _kalman.reset();
    notifyListeners();
  }

  /// Stops listening; the track is kept.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    notifyListeners();
  }

  /// Clears the track.
  void clear() {
    _segments.clear();
    _kalman.reset();
    notifyListeners();
  }

  /// Adds one fix (used by [start]; call it yourself for custom sources or simulations).
  void add(UPosition p) {
    if (_paused) return;
    if (p.accuracy != null && p.accuracy! > maxAccuracy) return;
    if (_segments.isEmpty) _segments.add(<UGeoTrackPoint>[]);
    LatLng point = LatLng(p.latitude, p.longitude);
    if (smooth) point = _kalman.filter(point, accuracy: p.accuracy ?? 10, time: p.time);
    final List<UGeoTrackPoint> seg = _segments.last;
    if (seg.isNotEmpty && UGeoMath.distance(seg.last.point, point) < minDistance) return;
    double? speed = p.speed;
    if ((speed == null || speed < 0) && seg.isNotEmpty && seg.last.time != null) {
      final int ms = p.time.difference(seg.last.time!).inMilliseconds;
      if (ms > 0) speed = UGeoMath.distance(seg.last.point, point) / (ms / 1000);
    }
    seg.add(UGeoTrackPoint(point, elevation: p.altitude, time: p.time, speed: speed, heading: p.heading, accuracy: p.accuracy));
    if (speedLimit != null && speed != null) {
      final bool over = speed > speedLimit!;
      if (over && !_overSpeed) onOverSpeed?.call(speed);
      _overSpeed = over;
    }
    notifyListeners();
  }

  /// The track as GPX text.
  String toGpx({String name = "Track"}) => UGpxCodec.encode(UGpx(name: name, time: DateTime.now(), tracks: <UGpxPath>[UGpxPath(name: name, segments: _segments.where((List<UGeoTrackPoint> s) => s.isNotEmpty).toList())]));

  /// Saves the track on the device under [key].
  Future<void> save(String key) => UFileStorage.setJson("umap_track_$key", points.map((UGeoTrackPoint p) => p.toJson()).toList());

  /// Loads a saved track's points.
  static Future<List<UGeoTrackPoint>> load(String key) async {
    final dynamic json = await UFileStorage.getJson("umap_track_$key");
    if (json is! List) return <UGeoTrackPoint>[];
    return json.whereType<Map<dynamic, dynamic>>().map((Map<dynamic, dynamic> m) => UGeoTrackPoint.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// A watched zone: a circle or any polygon, with optional dwell time.
class UMapZone {
  const UMapZone.circle({required this.id, required LatLng this.center, required double this.radius, this.dwell, this.data}) : polygon = null;

  const UMapZone.polygon({required this.id, required List<LatLng> this.polygon, this.dwell, this.data}) : center = null, radius = null;

  final String id;
  final LatLng? center;
  final double? radius;
  final List<LatLng>? polygon;

  /// Fires a dwell event after staying inside this long.
  final Duration? dwell;

  /// Anything you want back with the event (a process id, a message…).
  final Object? data;

  /// True when a point is inside.
  bool contains(LatLng p) => polygon != null ? UGeoMath.ringContains(polygon!, p) : UGeoMath.distance(center!, p) <= radius!;

  /// Outline ring (for drawing).
  List<LatLng> get outline => polygon ?? UGeoMath.circle(center!, radius!);
}

/// Kind of zone event.
enum UMapZoneTransition { enter, exit, dwell }

/// A zone event.
class UMapZoneEvent {
  const UMapZoneEvent(this.zone, this.transition, this.position, this.time);

  final UMapZone zone;
  final UMapZoneTransition transition;
  final LatLng position;
  final DateTime time;
}

/// Polygon and circle geofences evaluated in Dart on a position stream (enter / exit / dwell) — any shape, any count, every platform.
/// For background wake-ups use ULocation.addGeofence (native circles).
class UMapGeofencer {
  UMapGeofencer([List<UMapZone> zones = const <UMapZone>[]]) {
    zones.forEach(add);
  }

  final Map<String, UMapZone> _zones = <String, UMapZone>{};
  final Map<String, DateTime> _inside = <String, DateTime>{};
  final Set<String> _dwelled = <String>{};
  final StreamController<UMapZoneEvent> _events = StreamController<UMapZoneEvent>.broadcast();
  StreamSubscription<UPosition>? _sub;

  /// Every zone.
  List<UMapZone> get zones => _zones.values.toList();

  /// Ids of zones the last position was inside.
  Set<String> get insideIds => _inside.keys.toSet();

  /// Enter / exit / dwell events.
  Stream<UMapZoneEvent> get events => _events.stream;

  /// Adds or replaces a zone.
  void add(UMapZone zone) => _zones[zone.id] = zone;

  /// Removes a zone.
  void remove(String id) {
    _zones.remove(id);
    _inside.remove(id);
    _dwelled.remove(id);
  }

  /// Listens to [ULocation] (or any stream).
  void start([Stream<UPosition>? positions]) {
    _sub?.cancel();
    _sub = (positions ?? ULocation.stream(const ULocationSettings(distanceFilter: 10))).listen((UPosition p) => update(LatLng(p.latitude, p.longitude), time: p.time));
  }

  /// Stops listening.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Checks one position.
  void update(LatLng p, {DateTime? time}) {
    final DateTime now = time ?? DateTime.now();
    for (final UMapZone z in _zones.values) {
      final bool inside = z.contains(p);
      final bool was = _inside.containsKey(z.id);
      if (inside && !was) {
        _inside[z.id] = now;
        _events.add(UMapZoneEvent(z, UMapZoneTransition.enter, p, now));
      } else if (!inside && was) {
        _inside.remove(z.id);
        _dwelled.remove(z.id);
        _events.add(UMapZoneEvent(z, UMapZoneTransition.exit, p, now));
      } else if (inside && z.dwell != null && !_dwelled.contains(z.id) && now.difference(_inside[z.id]!) >= z.dwell!) {
        _dwelled.add(z.id);
        _events.add(UMapZoneEvent(z, UMapZoneTransition.dwell, p, now));
      }
    }
  }

  /// Stops and closes the event stream.
  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}

/// One participant of a live map session.
class UMapPeer {
  const UMapPeer({required this.id, required this.point, required this.updated, this.name, this.heading, this.speed, this.eta, this.remainingMeters, this.color, this.data});

  factory UMapPeer.fromJson(Map<String, dynamic> j) => UMapPeer(
    id: j["id"].toString(),
    point: LatLng((j["lat"] as num).toDouble(), (j["lng"] as num).toDouble()),
    updated: DateTime.fromMillisecondsSinceEpoch((j["t"] as num?)?.toInt() ?? 0),
    name: j["name"]?.toString(),
    heading: (j["heading"] as num?)?.toDouble(),
    speed: (j["speed"] as num?)?.toDouble(),
    eta: j["eta"] == null ? null : DateTime.fromMillisecondsSinceEpoch((j["eta"] as num).toInt()),
    remainingMeters: (j["left"] as num?)?.toDouble(),
    color: j["color"] == null ? null : Color((j["color"] as num).toInt()),
    data: j["data"],
  );

  final String id;
  final LatLng point;
  final DateTime updated;
  final String? name;
  final double? heading;
  final double? speed;

  /// Shared arrival time (live ETA sharing).
  final DateTime? eta;
  final double? remainingMeters;
  final Color? color;
  final Object? data;

  Map<String, dynamic> toJson() => <String, dynamic>{
    "id": id,
    "lat": point.latitude,
    "lng": point.longitude,
    "t": updated.millisecondsSinceEpoch,
    "name": ?name,
    "heading": ?heading,
    "speed": ?speed,
    if (eta != null) "eta": eta!.millisecondsSinceEpoch,
    "left": ?remainingMeters,
    if (color != null) "color": color!.toARGB32(),
    "data": ?data,
  };
}

/// Shared live map (friends, couriers, a convoy) and live ETA sharing over YOUR backend: [send] gets JSON to forward
/// (WebSocket, Firebase, MQTT…); call [receive] with what others sent. Peers silent for [timeout] disappear.
class UMapLiveSession extends ChangeNotifier {
  UMapLiveSession({required this.me, required this.send, this.name, this.timeout = const Duration(minutes: 2), this.minInterval = const Duration(seconds: 2)});

  /// Your participant id.
  final String me;
  final String? name;

  /// Forwards a message to the other participants (your transport).
  final FutureOr<void> Function(String json) send;
  final Duration timeout;

  /// Throttle for position updates.
  final Duration minInterval;

  final Map<String, UMapPeer> _peers = <String, UMapPeer>{};
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  StreamSubscription<UPosition>? _sub;
  UMapNavigation? _nav;

  /// Everyone else, newest first.
  List<UMapPeer> get peers {
    final DateTime now = DateTime.now();
    return _peers.values.where((UMapPeer p) => now.difference(p.updated) < timeout).toList()..sort((UMapPeer a, UMapPeer b) => b.updated.compareTo(a.updated));
  }

  /// Shares your position (and ETA when [navigation] is set).
  Future<void> share(LatLng p, {double? heading, double? speed, Color? color, Object? data, bool force = false}) async {
    final DateTime now = DateTime.now();
    if (!force && now.difference(_lastSent) < minInterval) return;
    _lastSent = now;
    final UMapNavigationState? s = _nav?.state;
    final UMapPeer peer = UMapPeer(
      id: me,
      name: name,
      point: p,
      updated: now,
      heading: heading,
      speed: speed,
      color: color,
      data: data,
      eta: s == null ? null : now.add(s.remainingTime),
      remainingMeters: s?.remainingDistance,
    );
    await send(jsonEncode(<String, dynamic>{"type": "pos", "peer": peer.toJson()}));
  }

  /// Shares the device GPS continuously (Needs `permission add location`); pass a navigation to share its ETA.
  void start({UMapNavigation? navigation, Stream<UPosition>? positions}) {
    _nav = navigation;
    _sub?.cancel();
    _sub = (positions ?? ULocation.stream(const ULocationSettings(distanceFilter: 10))).listen((UPosition p) => share(LatLng(p.latitude, p.longitude), heading: p.heading, speed: p.speed));
  }

  /// Stops sharing and tells the others.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await send(jsonEncode(<String, dynamic>{"type": "leave", "id": me}));
  }

  /// Feeds a message received from your transport.
  void receive(String json) {
    final Object? msg = jsonDecode(json);
    if (msg is! Map) return;
    switch (msg["type"]) {
      case "pos":
        final UMapPeer peer = UMapPeer.fromJson(Map<String, dynamic>.from(msg["peer"] as Map<dynamic, dynamic>));
        if (peer.id == me) return;
        _peers[peer.id] = peer;
      case "leave":
        _peers.remove(msg["id"]?.toString());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
