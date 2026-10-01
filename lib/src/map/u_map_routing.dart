import "dart:math" as math;
import "dart:typed_data";

import "package:u/utilities.dart";

/// Offline road network for routing without a server: build it from OSM XML or GeoJSON road lines once, save it as compact bytes, bundle it.
class UMapRoadGraph {
  UMapRoadGraph._(this.profile, this._lat, this._lng, this._start, this._to, this._meters, this._speed, this._name, this.names) {
    _index = UGeoKdIndex<int>(List<int>.generate(_lat.length, (int i) => i), (int i) => LatLng(_lat[i], _lng[i]));
    for (final int s in _speed) {
      _maxSpeed = math.max(_maxSpeed, s.toDouble());
    }
  }

  final UMapRouteProfile profile;
  final Float64List _lat;
  final Float64List _lng;
  final Uint32List _start;
  final Uint32List _to;
  final Float32List _meters;
  final Uint8List _speed;
  final Int32List _name;

  /// Street names referenced by edges.
  final List<String> names;
  late final UGeoKdIndex<int> _index;
  double _maxSpeed = 5;

  /// Number of junctions/vertices.
  int get nodeCount => _lat.length;

  /// Number of directed edges.
  int get edgeCount => _to.length;

  /// Location of a node.
  LatLng node(int i) => LatLng(_lat[i], _lng[i]);

  // ---------------------------------------------------------------------------------------------- building

  static const Map<String, (int car, bool bike, bool foot)> _highways = <String, (int, bool, bool)>{
    "motorway": (100, false, false),
    "motorway_link": (50, false, false),
    "trunk": (80, false, false),
    "trunk_link": (40, false, false),
    "primary": (60, true, true),
    "primary_link": (40, true, true),
    "secondary": (50, true, true),
    "secondary_link": (35, true, true),
    "tertiary": (40, true, true),
    "tertiary_link": (30, true, true),
    "unclassified": (30, true, true),
    "residential": (25, true, true),
    "living_street": (10, true, true),
    "service": (15, true, true),
    "road": (30, true, true),
    "track": (0, true, true),
    "cycleway": (0, true, true),
    "path": (0, true, true),
    "footway": (0, false, true),
    "pedestrian": (0, true, true),
    "steps": (0, false, true),
  };

  /// Road graph from ways: each way is (points, tags) with OSM tags (highway, oneway, maxspeed, name, junction).
  factory UMapRoadGraph.fromWays(Iterable<(List<LatLng>, Map<String, String>)> ways, {UMapRouteProfile profile = UMapRouteProfile.car, String? nameLanguage}) {
    final Map<int, int> ids = <int, int>{};
    final List<double> lat = <double>[];
    final List<double> lng = <double>[];
    final List<List<(int, double, int, int)>> adj = <List<(int, double, int, int)>>[];
    final List<String> names = <String>[];
    final Map<String, int> nameIds = <String, int>{};
    int nodeOf(LatLng p) {
      final int key = Object.hash((p.latitude * 1e7).round(), (p.longitude * 1e7).round());
      return ids.putIfAbsent(key, () {
        lat.add(p.latitude);
        lng.add(p.longitude);
        adj.add(<(int, double, int, int)>[]);
        return lat.length - 1;
      });
    }

    for (final (List<LatLng> points, Map<String, String> tags) in ways) {
      final String highway = tags["highway"] ?? "";
      final (int, bool, bool)? kind = _highways[highway];
      if (kind == null || points.length < 2) continue;
      int speed;
      switch (profile) {
        case UMapRouteProfile.car:
          speed = kind.$1;
          final int? max = int.tryParse(RegExp(r"\d+").firstMatch(tags["maxspeed"] ?? "")?.group(0) ?? "");
          if (speed > 0 && max != null) speed = math.min(speed, max);
        case UMapRouteProfile.bike:
          speed = kind.$2 ? 16 : 0;
        case UMapRouteProfile.foot:
          speed = kind.$3 ? 5 : 0;
      }
      if (tags["access"] == "no" || tags["access"] == "private") speed = 0;
      if (speed <= 0) continue;
      final String oneway = tags["oneway"] ?? (tags["junction"] == "roundabout" || highway == "motorway" ? "yes" : "no");
      final bool forwardOnly = profile != UMapRouteProfile.foot && (oneway == "yes" || oneway == "true" || oneway == "1") && !(profile == UMapRouteProfile.bike && tags["oneway:bicycle"] == "no");
      final bool backwardOnly = profile != UMapRouteProfile.foot && oneway == "-1";
      final String name = (nameLanguage == null ? null : tags["name:$nameLanguage"]) ?? tags["name"] ?? tags["ref"] ?? "";
      final int nameId = name.isEmpty ? -1 : nameIds.putIfAbsent(name, () {
        names.add(name);
        return names.length - 1;
      });
      for (int i = 1; i < points.length; i++) {
        final int a = nodeOf(points[i - 1]);
        final int b = nodeOf(points[i]);
        if (a == b) continue;
        final double d = UGeoMath.distance(points[i - 1], points[i]);
        if (!backwardOnly) adj[a].add((b, d, speed, nameId));
        if (!forwardOnly) adj[b].add((a, d, speed, nameId));
      }
    }
    final Uint32List start = Uint32List(lat.length + 1);
    int total = 0;
    for (int i = 0; i < adj.length; i++) {
      start[i] = total;
      total += adj[i].length;
    }
    start[lat.length] = total;
    final Uint32List to = Uint32List(total);
    final Float32List meters = Float32List(total);
    final Uint8List speeds = Uint8List(total);
    final Int32List nameIdx = Int32List(total);
    int k = 0;
    for (final List<(int, double, int, int)> edges in adj) {
      for (final (int b, double d, int s, int n) in edges) {
        to[k] = b;
        meters[k] = d;
        speeds[k] = s.clamp(1, 255);
        nameIdx[k] = n;
        k++;
      }
    }
    return UMapRoadGraph._(profile, Float64List.fromList(lat), Float64List.fromList(lng), start, to, meters, speeds, nameIdx, names);
  }

  /// Road graph from GeoJSON lines whose properties hold OSM tags (export of an OSM extract, e.g. from osmium/ogr2ogr/Overpass).
  factory UMapRoadGraph.fromGeoJson(UGeoFeatureCollection roads, {UMapRouteProfile profile = UMapRouteProfile.car, String? nameLanguage}) => UMapRoadGraph.fromWays(<(List<LatLng>, Map<String, String>)>[
    for (final UGeoFeature f in roads.features)
      ...switch (f.geometry) {
        final UGeoLine l => <List<LatLng>>[l.points],
        final UGeoMultiLine m => m.lines,
        _ => <List<LatLng>>[],
      }.map((List<LatLng> pts) => (pts, f.properties.map((String k, dynamic v) => MapEntry<String, String>(k, "$v")))),
  ], profile: profile, nameLanguage: nameLanguage);

  /// Road graph from OSM XML (.osm from the OSM export button, Overpass or osmium).
  factory UMapRoadGraph.fromOsmXml(String xml, {UMapRouteProfile profile = UMapRouteProfile.car, String? nameLanguage}) {
    final UEpubNode? root = UEpubXml.parse(xml);
    final Map<String, LatLng> nodes = <String, LatLng>{};
    final List<(List<LatLng>, Map<String, String>)> ways = <(List<LatLng>, Map<String, String>)>[];
    for (final UEpubNode n in root?.findAll("node") ?? const <UEpubNode>[]) {
      final double? la = double.tryParse(n.attributes["lat"] ?? "");
      final double? lo = double.tryParse(n.attributes["lon"] ?? "");
      if (la != null && lo != null) nodes[n.attributes["id"] ?? ""] = LatLng(la, lo);
    }
    for (final UEpubNode w in root?.findAll("way") ?? const <UEpubNode>[]) {
      final Map<String, String> tags = <String, String>{for (final UEpubNode t in w.children.where((UEpubNode c) => c.tag == "tag")) t.attributes["k"] ?? "": t.attributes["v"] ?? ""};
      if (!tags.containsKey("highway")) continue;
      final List<LatLng> pts = <LatLng>[for (final UEpubNode nd in w.children.where((UEpubNode c) => c.tag == "nd")) ?nodes[nd.attributes["ref"]]];
      ways.add((pts, tags));
    }
    return UMapRoadGraph.fromWays(ways, profile: profile, nameLanguage: nameLanguage);
  }

  /// Downloads roads in a box from Overpass and builds a graph (for small areas; bundle bigger graphs with [toBytes]).
  static Future<UMapRoadGraph> fromOverpass(LatLngBounds box, {UMapRouteProfile profile = UMapRouteProfile.car, String? nameLanguage}) async {
    final List<Map<String, dynamic>> el = await UMapServices.overpass("[out:json][timeout:60];way[highway](${box.south},${box.west},${box.north},${box.east});out tags geom;");
    return UMapRoadGraph.fromWays(<(List<LatLng>, Map<String, String>)>[
      for (final Map<String, dynamic> w in el)
        (
          (w["geometry"] as List<dynamic>? ?? <dynamic>[]).map((dynamic g) => LatLng(((g as Map<String, dynamic>)["lat"] as num).toDouble(), (g["lon"] as num).toDouble())).toList(),
          (w["tags"] as Map<String, dynamic>? ?? <String, dynamic>{}).map((String k, dynamic v) => MapEntry<String, String>(k, "$v")),
        ),
    ], profile: profile, nameLanguage: nameLanguage);
  }

  // ---------------------------------------------------------------------------------------------- bytes

  /// Compact binary of the graph (bundle it as an asset; load with [fromBytes]).
  Uint8List toBytes() {
    final BytesBuilder b = BytesBuilder();
    void u32(int v) => b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
    b.add(ascii.encode("UMRG"));
    u32(1);
    u32(profile.index);
    u32(nodeCount);
    u32(edgeCount);
    u32(names.length);
    for (final String n in names) {
      final List<int> s = utf8.encode(n);
      u32(s.length);
      b.add(s);
    }
    final ByteData nodes = ByteData(nodeCount * 8);
    for (int i = 0; i < nodeCount; i++) {
      nodes
        ..setInt32(i * 8, (_lat[i] * 1e7).round(), Endian.little)
        ..setInt32(i * 8 + 4, (_lng[i] * 1e7).round(), Endian.little);
    }
    b
      ..add(nodes.buffer.asUint8List())
      ..add(Uint8List.view(Uint32List.fromList(_start).buffer))
      ..add(Uint8List.view(Uint32List.fromList(_to).buffer))
      ..add(Uint8List.view(Float32List.fromList(_meters).buffer))
      ..add(_speed)
      ..add(Uint8List.view(Int32List.fromList(_name).buffer));
    return b.takeBytes();
  }

  /// Graph from [toBytes] output.
  factory UMapRoadGraph.fromBytes(Uint8List bytes) {
    final ByteData d = ByteData.sublistView(bytes);
    if (ascii.decode(bytes.sublist(0, 4)) != "UMRG") throw const FormatException("Not a u road graph");
    int o = 8;
    int u32() {
      final int v = d.getUint32(o, Endian.little);
      o += 4;
      return v;
    }

    final UMapRouteProfile profile = UMapRouteProfile.values[u32()];
    final int n = u32();
    final int e = u32();
    final int nn = u32();
    final List<String> names = <String>[];
    for (int i = 0; i < nn; i++) {
      final int len = u32();
      names.add(utf8.decode(bytes.sublist(o, o + len)));
      o += len;
    }
    final Float64List lat = Float64List(n);
    final Float64List lng = Float64List(n);
    for (int i = 0; i < n; i++) {
      lat[i] = d.getInt32(o, Endian.little) / 1e7;
      lng[i] = d.getInt32(o + 4, Endian.little) / 1e7;
      o += 8;
    }
    Uint8List take(int count) {
      final Uint8List s = Uint8List.fromList(bytes.sublist(o, o + count));
      o += count;
      return s;
    }

    final Uint32List start = take((n + 1) * 4).buffer.asUint32List();
    final Uint32List to = take(e * 4).buffer.asUint32List();
    final Float32List meters = take(e * 4).buffer.asFloat32List();
    final Uint8List speed = take(e);
    final Int32List name = take(e * 4).buffer.asInt32List();
    return UMapRoadGraph._(profile, lat, lng, start, to, meters, speed, name, names);
  }

  // ---------------------------------------------------------------------------------------------- search

  /// Closest node to a point.
  int? nearestNode(LatLng p, {double maxMeters = 2000}) => _index.nearest(p, maxMeters: maxMeters).firstOrNull;

  /// Fastest route between two points (A*); null when unreachable or too far from roads.
  UMapRoute? route(LatLng from, LatLng to, {bool persian = false, bool shortest = false}) {
    final int? a = nearestNode(from);
    final int? b = nearestNode(to);
    if (a == null || b == null) return null;
    final List<int>? nodes = _astar(a, b, shortest: shortest);
    if (nodes == null) return null;
    return _build(<LatLng>[from], nodes, <LatLng>[to], persian: persian);
  }

  /// Route through several stops in order.
  UMapRoute? routeVia(List<LatLng> stops, {bool persian = false}) {
    if (stops.length < 2) return null;
    final List<LatLng> points = <LatLng>[];
    final List<UMapRouteStep> steps = <UMapRouteStep>[];
    final List<(double, Duration)> legs = <(double, Duration)>[];
    double distance = 0;
    Duration duration = Duration.zero;
    for (int i = 1; i < stops.length; i++) {
      final UMapRoute? leg = route(stops[i - 1], stops[i], persian: persian);
      if (leg == null) return null;
      points.addAll(i == 1 ? leg.points : leg.points.skip(1));
      steps.addAll(i == stops.length - 1 ? leg.steps : leg.steps.where((UMapRouteStep s) => s.type != "arrive"));
      legs.add((leg.distance, leg.duration));
      distance += leg.distance;
      duration += leg.duration;
    }
    return UMapRoute(points: points, distance: distance, duration: duration, steps: steps, legs: legs);
  }

  double _cost(int e, bool shortest) => shortest ? _meters[e] : _meters[e] / (_speed[e] / 3.6);

  List<int>? _astar(int source, int target, {required bool shortest}) {
    final int n = nodeCount;
    final Float64List g = Float64List(n)..fillRange(0, n, double.infinity);
    final Int32List prev = Int32List(n)..fillRange(0, n, -1);
    final Uint8List closed = Uint8List(n);
    final LatLng goal = node(target);
    double h(int i) => shortest ? UGeoMath.distance(node(i), goal) : UGeoMath.distance(node(i), goal) / (_maxSpeed / 3.6);
    final UGeoHeap<(double, int)> open = UGeoHeap<(double, int)>(((double, int) x, (double, int) y) => x.$1.compareTo(y.$1));
    g[source] = 0;
    open.push((h(source), source));
    while (open.isNotEmpty) {
      final (double _, int u) = open.pop();
      if (closed[u] == 1) continue;
      if (u == target) break;
      closed[u] = 1;
      for (int e = _start[u]; e < _start[u + 1]; e++) {
        final int v = _to[e];
        if (closed[v] == 1) continue;
        final double cost = g[u] + _cost(e, shortest);
        if (cost < g[v]) {
          g[v] = cost;
          prev[v] = u;
          open.push((cost + h(v), v));
        }
      }
    }
    if (source != target && prev[target] < 0) return null;
    final List<int> path = <int>[target];
    while (path.last != source) {
      path.add(prev[path.last]);
    }
    return path.reversed.toList();
  }

  int _edge(int a, int b) {
    for (int e = _start[a]; e < _start[a + 1]; e++) {
      if (_to[e] == b) return e;
    }
    return -1;
  }

  UMapRoute _build(List<LatLng> head, List<int> nodes, List<LatLng> tail, {required bool persian}) {
    final List<LatLng> points = <LatLng>[...head, ...nodes.map(node), ...tail];
    double distance = UGeoMath.distance(head.last, node(nodes.first)) + UGeoMath.distance(node(nodes.last), tail.first);
    double seconds = distance / 1.4;
    final List<(int edge, double meters, double secs)> edges = <(int, double, double)>[];
    for (int i = 1; i < nodes.length; i++) {
      final int e = _edge(nodes[i - 1], nodes[i]);
      if (e < 0) continue;
      final double s = _meters[e] / (_speed[e] / 3.6);
      edges.add((e, _meters[e].toDouble(), s));
      distance += _meters[e];
      seconds += s;
    }
    // Steps: group edges until a real turn or a street-name change.
    final List<UMapRouteStep> steps = <UMapRouteStep>[];
    String nameOf(int e) => _name[e] < 0 ? "" : names[_name[e]];
    int i = 0;
    String type = "depart";
    String? modifier;
    while (i < edges.length) {
      final int first = i;
      final String name = nameOf(edges[i].$1);
      double meters = 0;
      double secs = 0;
      while (i < edges.length) {
        meters += edges[i].$2;
        secs += edges[i].$3;
        i++;
        if (i >= edges.length) break;
        final double turn = _turn(nodes[i - 1], nodes[i], nodes[i + 1]);
        final bool junction = _start[nodes[i] + 1] - _start[nodes[i]] > 2;
        if (nameOf(edges[i].$1) != name || (junction && turn.abs() > 30)) break;
      }
      final LatLng at = node(nodes[first]);
      steps.add(
        UMapRouteStep(
          type: type,
          modifier: modifier,
          name: name,
          instruction: UMapFormat.instruction(type, modifier, street: name, persian: persian),
          distance: meters,
          duration: Duration(milliseconds: (secs * 1000).round()),
          location: at,
          bearingAfter: first + 1 < nodes.length ? UGeoMath.bearing(at, node(nodes[first + 1])) : 0,
          points: <LatLng>[for (int k = first; k <= math.min(i, nodes.length - 1); k++) node(nodes[k])],
        ),
      );
      if (i < edges.length) {
        final double turn = _turn(nodes[i - 1], nodes[i], nodes[i + 1]);
        modifier = _modifier(turn);
        type = modifier == "straight" ? "new name" : "turn";
      }
    }
    steps.add(
      UMapRouteStep(
        type: "arrive",
        instruction: UMapFormat.instruction("arrive", null, persian: persian),
        distance: 0,
        duration: Duration.zero,
        location: tail.first,
      ),
    );
    return UMapRoute(points: points, distance: distance, duration: Duration(milliseconds: (seconds * 1000).round()), steps: steps);
  }

  /// Signed turn angle at b (−180..180, positive = right).
  double _turn(int a, int b, int c) {
    final double t = UGeoMath.bearing(node(b), node(c)) - UGeoMath.bearing(node(a), node(b));
    return ((t + 540) % 360) - 180;
  }

  static String _modifier(double turn) {
    final double a = turn.abs();
    final String side = turn > 0 ? "right" : "left";
    if (a < 25) return "straight";
    if (a < 55) return "slight $side";
    if (a < 130) return side;
    if (a < 165) return "sharp $side";
    return "uturn";
  }

  /// Seconds needed to reach every node within [maxTime] (Dijkstra), keyed by node.
  Map<int, double> reachable(LatLng from, Duration maxTime) {
    final int? s = nearestNode(from);
    if (s == null) return <int, double>{};
    final double limit = maxTime.inMilliseconds / 1000;
    final Map<int, double> best = <int, double>{s: 0};
    final UGeoHeap<(double, int)> open = UGeoHeap<(double, int)>(((double, int) x, (double, int) y) => x.$1.compareTo(y.$1));
    open.push((0, s));
    while (open.isNotEmpty) {
      final (double t, int u) = open.pop();
      if (t > (best[u] ?? double.infinity)) continue;
      for (int e = _start[u]; e < _start[u + 1]; e++) {
        final double nt = t + _cost(e, false);
        if (nt > limit) continue;
        final int v = _to[e];
        if (nt < (best[v] ?? double.infinity)) {
          best[v] = nt;
          open.push((nt, v));
        }
      }
    }
    return best;
  }

  /// Outline of the area reachable within [maxTime] (offline isochrone, concave hull of reached roads).
  List<LatLng> isochrone(LatLng from, Duration maxTime, {double? maxEdgeMeters}) {
    final List<LatLng> pts = reachable(from, maxTime).keys.map(node).toList();
    if (pts.length < 4) return UGeoOps.convexHull(pts);
    final double edge = maxEdgeMeters ?? math.max(150, UGeoMath.distance(from, pts.reduce((LatLng a, LatLng b) => UGeoMath.distance(from, a) > UGeoMath.distance(from, b) ? a : b)) / 6);
    return UGeoOps.concaveHull(pts.length > 3000 ? UGeoMath.visvalingam(pts, 3000) : pts, maxEdge: edge);
  }
}

/// Travelling-salesman ordering for delivery stops: nearest neighbour + 2-opt (pure Dart).
abstract final class UGeoTsp {
  /// Best visiting order (indexes into [points]); [roundTrip] returns to the start; [start]/[end] pin the first/last stop.
  /// [cost] lets you pass road distances (e.g. from UMapServices.matrix); straight-line metres by default.
  static List<int> solve(List<LatLng> points, {bool roundTrip = false, int start = 0, int? end, double Function(int a, int b)? cost, int maxIterations = 2000}) {
    final int n = points.length;
    if (n <= 2) return List<int>.generate(n, (int i) => i);
    final List<List<double>> d = List<List<double>>.generate(n, (int a) => List<double>.generate(n, (int b) => cost?.call(a, b) ?? UGeoMath.distance(points[a], points[b])));
    final List<int> order = <int>[start];
    final Set<int> left = <int>{for (int i = 0; i < n; i++) if (i != start && i != end) i};
    while (left.isNotEmpty) {
      final int last = order.last;
      final int next = left.reduce((int a, int b) => d[last][a] <= d[last][b] ? a : b);
      order.add(next);
      left.remove(next);
    }
    if (end != null && end != start) order.add(end);
    double length(List<int> o) {
      double s = 0;
      for (int i = 1; i < o.length; i++) {
        s += d[o[i - 1]][o[i]];
      }
      return roundTrip ? s + d[o.last][o.first] : s;
    }

    bool improved = true;
    int iterations = 0;
    final int lastMovable = end != null || !roundTrip ? order.length - 2 : order.length - 1;
    while (improved && iterations++ < maxIterations) {
      improved = false;
      for (int i = 1; i < lastMovable; i++) {
        for (int k = i + 1; k <= lastMovable; k++) {
          final List<int> candidate = <int>[...order.sublist(0, i), ...order.sublist(i, k + 1).reversed, ...order.sublist(k + 1)];
          if (length(candidate) + 1e-9 < length(order)) {
            order
              ..clear()
              ..addAll(candidate);
            improved = true;
          }
        }
      }
    }
    return order;
  }

  /// Total length of an order in metres (straight lines).
  static double length(List<LatLng> points, List<int> order, {bool roundTrip = false}) {
    double s = 0;
    for (int i = 1; i < order.length; i++) {
      s += UGeoMath.distance(points[order[i - 1]], points[order[i]]);
    }
    return roundTrip && order.length > 1 ? s + UGeoMath.distance(points[order.last], points[order.first]) : s;
  }
}

/// Live navigation state.
class UMapNavigationState {
  const UMapNavigationState({
    required this.position,
    required this.snapped,
    required this.progress,
    required this.remainingDistance,
    required this.remainingTime,
    required this.stepIndex,
    required this.distanceToManeuver,
    required this.offRoute,
    required this.arrived,
    this.speed,
    this.heading,
  });

  final LatLng position;

  /// Position moved onto the route line.
  final LatLng snapped;

  /// Metres travelled along the route.
  final double progress;
  final double remainingDistance;
  final Duration remainingTime;

  /// Index of the step being driven (the next maneuver is stepIndex + 1).
  final int stepIndex;
  final double distanceToManeuver;
  final bool offRoute;
  final bool arrived;

  /// m/s
  final double? speed;
  final double? heading;
}

/// Turn-by-turn navigation over a route: snaps positions, tracks progress, ETA and next maneuver, detects off-route and reroutes, emits voice texts.
class UMapNavigation extends ChangeNotifier {
  UMapNavigation({required this._route, this.reroute, this.offRouteMeters = 40, this.arriveMeters = 25, this.announceAt = const <double>[600, 200, 40], this.persian = false}) {
    _prepare();
  }

  /// Called with the current position when the driver leaves the route; return a new route (e.g. UMapServices.route) or null.
  final Future<UMapRoute?> Function(LatLng from)? reroute;
  final double offRouteMeters;
  final double arriveMeters;

  /// Distances (m) before a maneuver at which an announcement is emitted.
  final List<double> announceAt;
  final bool persian;

  UMapRoute _route;
  late List<double> _stepStarts;
  UMapNavigationState? _state;
  int _offCount = 0;
  bool _rerouting = false;
  final Set<String> _spoken = <String>{};
  final StreamController<String> _voice = StreamController<String>.broadcast();
  StreamSubscription<UPosition>? _sub;

  /// The route being followed (changes after a reroute).
  UMapRoute get route => _route;

  /// Latest state, null before the first position.
  UMapNavigationState? get state => _state;

  /// Spoken-style texts ("In 200 m, turn left onto…"); plug a text-to-speech engine here.
  Stream<String> get announcements => _voice.stream;

  /// Current step, if any.
  UMapRouteStep? get currentStep => _state == null || _route.steps.isEmpty ? null : _route.steps[_state!.stepIndex.clamp(0, _route.steps.length - 1)];

  /// The upcoming maneuver, if any.
  UMapRouteStep? get nextStep => _state == null || _state!.stepIndex + 1 >= _route.steps.length ? null : _route.steps[_state!.stepIndex + 1];

  void _prepare() {
    _stepStarts = _route.steps.map((UMapRouteStep s) => UGeoMath.nearestOnLine(_route.points, s.location).along).toList();
    _spoken.clear();
    _offCount = 0;
  }

  /// Follows live GPS from [ULocation] (or any position stream).
  void start([Stream<UPosition>? positions]) {
    _sub?.cancel();
    _sub = (positions ?? ULocation.stream(const ULocationSettings(distanceFilter: 3))).listen(
      (UPosition p) => update(LatLng(p.latitude, p.longitude), speed: p.speed, heading: p.heading),
    );
  }

  /// Stops following GPS.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Feeds one position (from GPS or a simulation).
  void update(LatLng position, {double? speed, double? heading}) {
    final UGeoNearest near = UGeoMath.nearestOnLine(_route.points, position);
    final bool off = near.distance > offRouteMeters;
    _offCount = off ? _offCount + 1 : 0;
    final double progress = near.along;
    final double remaining = math.max(0, _route.distance - progress);
    final double rate = _route.distance <= 0 ? 0 : _route.duration.inMilliseconds / _route.distance;
    int step = 0;
    for (int i = 0; i < _stepStarts.length; i++) {
      if (_stepStarts[i] <= progress + 1) step = i;
    }
    final double toManeuver = step + 1 < _stepStarts.length ? math.max(0, _stepStarts[step + 1] - progress) : remaining;
    final bool arrived = UGeoMath.distance(position, _route.points.last) <= arriveMeters || remaining <= arriveMeters;
    _state = UMapNavigationState(
      position: position,
      snapped: near.point,
      progress: progress,
      remainingDistance: remaining,
      remainingTime: Duration(milliseconds: (remaining * rate).round()),
      stepIndex: step,
      distanceToManeuver: toManeuver,
      offRoute: off,
      arrived: arrived,
      speed: speed,
      heading: heading,
    );
    _announce(step, toManeuver, arrived);
    notifyListeners();
    if (_offCount >= 3 && reroute != null && !_rerouting) unawaited(_reroute(position));
  }

  void _announce(int step, double toManeuver, bool arrived) {
    if (arrived) {
      if (_spoken.add("arrived")) _voice.add(UMapFormat.instruction("arrive", null, persian: persian));
      return;
    }
    final UMapRouteStep? next = step + 1 < _route.steps.length ? _route.steps[step + 1] : null;
    if (next == null) return;
    for (final double at in announceAt) {
      if (toManeuver <= at && _spoken.add("${step + 1}@$at")) {
        final String distance = UMapFormat.distance(toManeuver, persian: persian);
        _voice.add(at <= 50 ? next.instruction : (persian ? "در $distance، ${next.instruction}" : "In $distance, ${next.instruction[0].toLowerCase()}${next.instruction.substring(1)}"));
        break;
      }
    }
  }

  Future<void> _reroute(LatLng from) async {
    _rerouting = true;
    try {
      final UMapRoute? fresh = await reroute!(from);
      if (fresh != null) {
        _route = fresh;
        _prepare();
        _voice.add(persian ? "مسیر دوباره محاسبه شد" : "Rerouting");
        notifyListeners();
      }
    } finally {
      _rerouting = false;
    }
  }

  /// Replays the route at [speed] m/s (for demos and testing without GPS).
  Stream<LatLng> simulate({double speed = 14, Duration tick = const Duration(milliseconds: 500)}) async* {
    double travelled = 0;
    while (travelled <= _route.distance) {
      final LatLng p = UGeoMath.along(_route.points, travelled);
      update(p, speed: speed, heading: UGeoMath.bearingAlong(_route.points, travelled));
      yield p;
      await Future<void>.delayed(tick);
      travelled += speed * tick.inMilliseconds / 1000;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _voice.close();
    super.dispose();
  }
}
