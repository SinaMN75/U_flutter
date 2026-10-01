import "package:u/utilities.dart";

/// Kind of a [UGeoGeometry].
enum UGeoType { point, multiPoint, line, multiLine, polygon, multiPolygon, collection }

/// A geometry in latitude/longitude: point, line, polygon, their multi versions or a collection (GeoJSON model).
sealed class UGeoGeometry {
  const UGeoGeometry();

  /// The kind of geometry.
  UGeoType get type;

  /// Every coordinate, flattened.
  Iterable<LatLng> get coordinates;

  /// Box around every coordinate, or null when empty.
  LatLngBounds? get bounds {
    final List<LatLng> all = coordinates.toList();
    return all.isEmpty ? null : LatLngBounds.fromPoints(all);
  }
}

/// One point, with an optional altitude in metres.
class UGeoPoint extends UGeoGeometry {
  const UGeoPoint(this.point, {this.altitude});

  final LatLng point;
  final double? altitude;

  @override
  UGeoType get type => UGeoType.point;

  @override
  Iterable<LatLng> get coordinates => <LatLng>[point];
}

/// Several unconnected points.
class UGeoMultiPoint extends UGeoGeometry {
  const UGeoMultiPoint(this.points);

  final List<LatLng> points;

  @override
  UGeoType get type => UGeoType.multiPoint;

  @override
  Iterable<LatLng> get coordinates => points;
}

/// A line through [points]; [altitudes] is parallel to points when known.
class UGeoLine extends UGeoGeometry {
  const UGeoLine(this.points, {this.altitudes});

  final List<LatLng> points;
  final List<double?>? altitudes;

  @override
  UGeoType get type => UGeoType.line;

  @override
  Iterable<LatLng> get coordinates => points;
}

/// Several lines.
class UGeoMultiLine extends UGeoGeometry {
  const UGeoMultiLine(this.lines);

  final List<List<LatLng>> lines;

  @override
  UGeoType get type => UGeoType.multiLine;

  @override
  Iterable<LatLng> get coordinates => lines.expand((List<LatLng> l) => l);
}

/// A polygon: the first ring is the outline, the others are holes.
class UGeoPolygon extends UGeoGeometry {
  const UGeoPolygon(this.rings);

  /// A polygon without holes.
  UGeoPolygon.simple(List<LatLng> outline) : rings = <List<LatLng>>[outline];

  final List<List<LatLng>> rings;

  /// The outline ring.
  List<LatLng> get outer => rings.isEmpty ? const <LatLng>[] : rings.first;

  /// The hole rings.
  List<List<LatLng>> get holes => rings.length < 2 ? const <List<LatLng>>[] : rings.sublist(1);

  @override
  UGeoType get type => UGeoType.polygon;

  @override
  Iterable<LatLng> get coordinates => rings.expand((List<LatLng> r) => r);
}

/// Several polygons, each a list of rings (outline first).
class UGeoMultiPolygon extends UGeoGeometry {
  const UGeoMultiPolygon(this.polygons);

  final List<List<List<LatLng>>> polygons;

  @override
  UGeoType get type => UGeoType.multiPolygon;

  @override
  Iterable<LatLng> get coordinates => polygons.expand((List<List<LatLng>> p) => p.expand((List<LatLng> r) => r));
}

/// A mix of geometries.
class UGeoCollection extends UGeoGeometry {
  const UGeoCollection(this.geometries);

  final List<UGeoGeometry> geometries;

  @override
  UGeoType get type => UGeoType.collection;

  @override
  Iterable<LatLng> get coordinates => geometries.expand((UGeoGeometry g) => g.coordinates);
}

/// A geometry with an id and properties (one GeoJSON Feature, one KML Placemark, one CSV row).
class UGeoFeature {
  UGeoFeature({required this.geometry, this.id, Map<String, dynamic>? properties}) : properties = properties ?? <String, dynamic>{};

  final Object? id;
  final UGeoGeometry geometry;
  final Map<String, dynamic> properties;

  /// The "name" property, when present.
  String? get name => properties["name"]?.toString();

  /// Same feature with some parts replaced.
  UGeoFeature copyWith({Object? id, UGeoGeometry? geometry, Map<String, dynamic>? properties}) =>
      UGeoFeature(id: id ?? this.id, geometry: geometry ?? this.geometry, properties: properties ?? Map<String, dynamic>.of(this.properties));
}

/// A list of features (one GeoJSON FeatureCollection, one KML document).
class UGeoFeatureCollection {
  UGeoFeatureCollection([List<UGeoFeature>? features]) : features = features ?? <UGeoFeature>[];

  final List<UGeoFeature> features;

  /// Box around every feature, or null when empty.
  LatLngBounds? get bounds {
    final List<LatLng> all = features.expand((UGeoFeature f) => f.geometry.coordinates).toList();
    return all.isEmpty ? null : LatLngBounds.fromPoints(all);
  }
}

/// A recorded or imported position: point plus optional elevation, time, speed (m/s), heading and accuracy (m).
class UGeoTrackPoint {
  const UGeoTrackPoint(this.point, {this.elevation, this.time, this.speed, this.heading, this.accuracy});

  final LatLng point;
  final double? elevation;
  final DateTime? time;
  final double? speed;
  final double? heading;
  final double? accuracy;

  Map<String, dynamic> toJson() => <String, dynamic>{
    "lat": point.latitude,
    "lng": point.longitude,
    if (elevation != null) "ele": elevation,
    if (time != null) "time": time!.toUtc().toIso8601String(),
    if (speed != null) "speed": speed,
    if (heading != null) "heading": heading,
    if (accuracy != null) "acc": accuracy,
  };

  factory UGeoTrackPoint.fromJson(Map<String, dynamic> json) => UGeoTrackPoint(
    LatLng((json["lat"] as num).toDouble(), (json["lng"] as num).toDouble()),
    elevation: (json["ele"] as num?)?.toDouble(),
    time: json["time"] == null ? null : DateTime.tryParse(json["time"].toString()),
    speed: (json["speed"] as num?)?.toDouble(),
    heading: (json["heading"] as num?)?.toDouble(),
    accuracy: (json["acc"] as num?)?.toDouble(),
  );
}

/// A GPX waypoint.
class UGpxWaypoint {
  const UGpxWaypoint(this.point, {this.elevation, this.time, this.name, this.description, this.symbol, this.type});

  final LatLng point;
  final double? elevation;
  final DateTime? time;
  final String? name;
  final String? description;
  final String? symbol;
  final String? type;
}

/// A GPX track or route: name plus one or more segments of points.
class UGpxPath {
  UGpxPath({this.name, this.description, this.type, List<List<UGeoTrackPoint>>? segments}) : segments = segments ?? <List<UGeoTrackPoint>>[];

  final String? name;
  final String? description;
  final String? type;
  final List<List<UGeoTrackPoint>> segments;

  /// Every point of every segment.
  List<UGeoTrackPoint> get points => segments.expand((List<UGeoTrackPoint> s) => s).toList();
}

/// A whole GPX file: waypoints, routes and tracks.
class UGpx {
  UGpx({this.name, this.description, this.time, this.creator = "u", List<UGpxWaypoint>? waypoints, List<UGpxPath>? routes, List<UGpxPath>? tracks})
    : waypoints = waypoints ?? <UGpxWaypoint>[],
      routes = routes ?? <UGpxPath>[],
      tracks = tracks ?? <UGpxPath>[];

  final String? name;
  final String? description;
  final DateTime? time;
  final String creator;
  final List<UGpxWaypoint> waypoints;
  final List<UGpxPath> routes;
  final List<UGpxPath> tracks;
}

/// A nearest-point answer: the [point] on the line, the segment [index], the [distance] to it and how far [along] the line it is (metres).
class UGeoNearest {
  const UGeoNearest({required this.point, required this.index, required this.distance, required this.along});

  final LatLng point;
  final int index;
  final double distance;
  final double along;
}
