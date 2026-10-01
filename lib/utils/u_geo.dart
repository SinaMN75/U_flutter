import "package:u/utilities.dart";

/// Geometry on latitude/longitude in pure Dart (every platform, offline): distances, areas, shapes, boolean ops, hulls, Voronoi, clustering, coordinate codes and file formats. `UGeo.distance(a, b)`
abstract final class UGeo {
  // ---------------------------------------------------------------------------------------------- distance & direction

  /// Great-circle distance in metres. `UGeo.distance(const LatLng(35.7, 51.4), const LatLng(32.65, 51.67))`
  static double distance(LatLng a, LatLng b) => UGeoMath.distance(a, b);

  /// Millimetre-accurate WGS84 (Vincenty) distance in metres. `UGeo.vincenty(a, b)`
  static double vincenty(LatLng a, LatLng b) => UGeoMath.vincenty(a, b);

  /// Direction from a to b in degrees (0 = north). `UGeo.bearing(a, b)`
  static double bearing(LatLng a, LatLng b) => UGeoMath.bearing(a, b);

  /// Point [meters] away towards [bearing] degrees. `UGeo.destination(p, 500, 90)`
  static LatLng destination(LatLng from, double meters, double bearing) => UGeoMath.destination(from, meters, bearing);

  /// Halfway point on the great circle. `UGeo.midpoint(a, b)`
  static LatLng midpoint(LatLng a, LatLng b) => UGeoMath.midpoint(a, b);

  /// Point at [fraction] (0..1) of the way from a to b. `UGeo.interpolate(a, b, 0.25)`
  static LatLng interpolate(LatLng a, LatLng b, double fraction) => UGeoMath.interpolate(a, b, fraction);

  /// Curved flight-path line between two points. `Polyline(points: UGeo.greatCircle(tehran, london))`
  static List<LatLng> greatCircle(LatLng a, LatLng b, {int segments = 64}) => UGeoMath.greatCircle(a, b, segments: segments);

  /// Length of a path in metres. `UGeo.length(route.points)`
  static double length(List<LatLng> points) => UGeoMath.length(points);

  // ---------------------------------------------------------------------------------------------- areas & containment

  /// Area of a polygon in m² (outline first, then holes). `UGeo.area([outline])`
  static double area(List<List<LatLng>> rings) => UGeoMath.area(rings);

  /// Perimeter of a ring in metres. `UGeo.perimeter(outline)`
  static double perimeter(List<LatLng> ring) => UGeoMath.perimeter(ring);

  /// Average point. `UGeo.centroid(points)`
  static LatLng centroid(List<LatLng> points) => UGeoMath.centroid(points);

  /// Best label spot deep inside a polygon (pole of inaccessibility). `UGeo.labelPoint([outline])`
  static LatLng labelPoint(List<List<LatLng>> rings) => UGeoMath.polylabel(rings);

  /// Box around points (null when empty). `UGeo.bounds(points)`
  static LatLngBounds? bounds(Iterable<LatLng> points) => UGeoMath.boundsOf(points);

  /// True when a point is inside a polygon (outline + optional holes). `UGeo.contains([outline], p)`
  static bool contains(List<List<LatLng>> rings, LatLng p) => UGeoMath.polygonContains(rings, p);

  /// Points inside a polygon (lasso selection). `UGeo.inside(shops, lasso)`
  static List<LatLng> inside(List<LatLng> points, List<LatLng> polygon) => points.where((LatLng p) => UGeoMath.ringContains(polygon, p)).toList();

  /// True when a point is on/inside any geometry (lines/points within [tolerance] metres). `UGeo.hits(feature.geometry, tap)`
  static bool hits(UGeoGeometry geometry, LatLng p, {double tolerance = 10}) => UGeoMath.geometryContains(geometry, p, tolerance: tolerance);

  /// Metres from a point to the nearest part of a path. `UGeo.distanceToLine(me, route.points)`
  static double distanceToLine(LatLng p, List<LatLng> path) => UGeoMath.distanceToLine(p, path);

  /// Closest point of a path, its segment and how far along it is. `UGeo.nearestOnLine(route.points, me).along`
  static UGeoNearest nearestOnLine(List<LatLng> path, LatLng p) => UGeoMath.nearestOnLine(path, p);

  /// Point [meters] along a path. `UGeo.along(route.points, 1200)`
  static LatLng along(List<LatLng> path, double meters) => UGeoMath.along(path, meters);

  /// Part of a path between two distances from its start. `UGeo.slice(path, 0, 500)`
  static List<LatLng> slice(List<LatLng> path, double start, double end) => UGeoMath.slice(path, start, end);

  /// Every crossing of two paths. `UGeo.intersections(lineA, lineB)`
  static List<LatLng> intersections(List<LatLng> a, List<LatLng> b) => UGeoMath.lineIntersections(a, b);

  /// Places where a path or polygon crosses itself. `UGeo.selfIntersections(ring)`
  static List<LatLng> selfIntersections(List<LatLng> points) => UGeoMath.kinks(points);

  // ---------------------------------------------------------------------------------------------- shapes

  /// Circle of true metres as a ring. `Polygon(points: UGeo.circle(p, 500))`
  static List<LatLng> circle(LatLng center, double meters, {int segments = 64}) => UGeoMath.circle(center, meters, segments: segments);

  /// Pie slice between two bearings. `UGeo.sector(p, 300, 30, 90)`
  static List<LatLng> sector(LatLng center, double meters, double fromBearing, double toBearing) => UGeoMath.sector(center, meters, fromBearing, toBearing);

  /// Ellipse with semi-axes in metres. `UGeo.ellipse(p, 800, 300, rotation: 45)`
  static List<LatLng> ellipse(LatLng center, double semiMajor, double semiMinor, {double rotation = 0}) => UGeoMath.ellipse(center, semiMajor, semiMinor, rotation: rotation);

  /// Fewer points, same shape (Douglas–Peucker, [tolerance] metres). `UGeo.simplify(track, 5)`
  static List<LatLng> simplify(List<LatLng> points, double tolerance) => UGeoMath.simplify(points, tolerance);

  /// Keep only the [keep] most important points (Visvalingam). `UGeo.simplifyTo(track, 200)`
  static List<LatLng> simplifyTo(List<LatLng> points, int keep) => UGeoMath.visvalingam(points, keep);

  /// Rounder path (Chaikin). `UGeo.smooth(freehand)`
  static List<LatLng> smooth(List<LatLng> points, {int iterations = 2, bool closed = false}) => UGeoMath.smooth(points, iterations: iterations, closed: closed);

  /// Adds points so no segment is longer than [maxSegment] metres. `UGeo.densify(line, 100)`
  static List<LatLng> densify(List<LatLng> points, double maxSegment) => UGeoMath.densify(points, maxSegment);

  // ---------------------------------------------------------------------------------------------- polygon operations

  /// Union of two polygons (lists of rings). `UGeo.union([a], [b])`
  static List<List<List<LatLng>>> union(List<List<LatLng>> a, List<List<LatLng>> b) => UGeoOps.boolean(a, b, UGeoBoolean.union);

  /// Overlap of two polygons. `UGeo.intersection([a], [b])`
  static List<List<List<LatLng>>> intersection(List<List<LatLng>> a, List<List<LatLng>> b) => UGeoOps.boolean(a, b, UGeoBoolean.intersection);

  /// a minus b. `UGeo.difference([zone], [lake])`
  static List<List<List<LatLng>>> difference(List<List<LatLng>> a, List<List<LatLng>> b) => UGeoOps.boolean(a, b, UGeoBoolean.difference);

  /// Parts in exactly one of the two. `UGeo.xor([a], [b])`
  static List<List<List<LatLng>>> xor(List<List<LatLng>> a, List<List<LatLng>> b) => UGeoOps.boolean(a, b, UGeoBoolean.xor);

  /// Union of many polygons. `UGeo.unionAll(zones)`
  static List<List<List<LatLng>>> unionAll(List<List<List<LatLng>>> polygons) => UGeoOps.unionAll(polygons);

  /// Area within [meters] of a path (outline ring). `UGeo.bufferLine(route.points, 200)`
  static List<LatLng> bufferLine(List<LatLng> path, double meters) => UGeoOps.bufferLine(path, meters);

  /// Polygon grown (or shrunk when negative) by [meters]. `UGeo.bufferPolygon(outline, 50)`
  static List<LatLng> bufferPolygon(List<LatLng> ring, double meters) => UGeoOps.bufferPolygon(ring, meters);

  /// Buffer of any geometry. `UGeo.buffer(feature.geometry, 100)`
  static List<List<List<LatLng>>> buffer(UGeoGeometry geometry, double meters) => UGeoOps.buffer(geometry, meters);

  /// Smallest convex outline around points. `UGeo.convexHull(points)`
  static List<LatLng> convexHull(List<LatLng> points) => UGeoOps.convexHull(points);

  /// Tight outline around points (edges ≤ [maxEdge] metres are kept). `UGeo.concaveHull(points, maxEdge: 500)`
  static List<LatLng> concaveHull(List<LatLng> points, {required double maxEdge}) => UGeoOps.concaveHull(points, maxEdge: maxEdge);

  /// Delaunay triangles of points. `UGeo.delaunay(points).triangle(0)`
  static UGeoTriangulation delaunay(List<LatLng> points) => UGeoOps.delaunay(points);

  /// Voronoi cells (area closest to each point), same order as points. `UGeo.voronoi(stations)`
  static List<List<LatLng>> voronoi(List<LatLng> points, {LatLngBounds? bounds}) => UGeoOps.voronoi(points, bounds: bounds);

  /// DBSCAN cluster id per point (−1 = noise). `UGeo.dbscan(points, radius: 300)`
  static List<int> dbscan(List<LatLng> points, {required double radius, int minPoints = 3}) => UGeoOps.dbscan(points, radius: radius, minPoints: minPoints);

  /// K-means group per point. `UGeo.kMeans(customers, 5)`
  static List<int> kMeans(List<LatLng> points, int k) => UGeoOps.kMeans(points, k);

  /// Hexagon grid cell (stable id + ring) of [meters] size containing a point. `UGeo.hexCell(p, 500).$1`
  static (String id, List<LatLng> ring) hexCell(LatLng p, double meters) => UGeoOps.hexCell(p, meters);

  /// Square grid of [meters] cells covering a box. `UGeo.squareGrid(bounds, 1000)`
  static List<List<LatLng>> squareGrid(LatLngBounds bounds, double meters) => UGeoOps.squareGrid(bounds, meters);

  /// Best order to visit stops (nearest neighbour + 2-opt); [cost] can use road distances. `UGeo.bestOrder(stops, roundTrip: true)`
  static List<int> bestOrder(List<LatLng> stops, {bool roundTrip = false, int start = 0, int? end, double Function(int a, int b)? cost}) =>
      UGeoTsp.solve(stops, roundTrip: roundTrip, start: start, end: end, cost: cost);

  // ---------------------------------------------------------------------------------------------- indexes

  /// Fast static point index (box, radius and nearest queries). `UGeo.pointIndex(shops, (s) => s.point).nearest(me, k: 5)`
  static UGeoKdIndex<T> pointIndex<T>(List<T> items, LatLng Function(T item) pointOf) => UGeoKdIndex<T>(items, pointOf);

  /// R-tree of shapes ("what is under this tap"). `UGeo.shapeIndex(features, (f) => f.geometry.bounds!).at(tap)`
  static UGeoRTree<T> shapeIndex<T>(List<T> items, LatLngBounds Function(T item) boundsOf) => UGeoRTree<T>(items, boundsOf);

  /// Growable point index for live data (vehicles). `final q = UGeo.liveIndex<String>()..add("bus7", p);`
  static UGeoQuadtree<T> liveIndex<T>() => UGeoQuadtree<T>();

  // ---------------------------------------------------------------------------------------------- coordinate codes

  /// Google encoded polyline text. `UGeo.encodePolyline(points)`
  static String encodePolyline(List<LatLng> points, {int precision = 5}) => UGeoCodes.encodePolyline(points, precision: precision);

  /// Points of a Google encoded polyline. `UGeo.decodePolyline("_p~iF~ps|U_ulLnnqC")`
  static List<LatLng> decodePolyline(String text, {int precision = 5}) => UGeoCodes.decodePolyline(text, precision: precision);

  /// Geohash (9 chars ≈ 5 m). `UGeo.geohash(p)`
  static String geohash(LatLng p, {int precision = 9}) => UGeoCodes.geohash(p, precision: precision);

  /// Box of a geohash. `UGeo.geohashBounds("tq7z")`
  static LatLngBounds geohashBounds(String hash) => UGeoCodes.geohashBounds(hash);

  /// The 8 geohashes around one. `UGeo.geohashNeighbors("tq7z")`
  static List<String> geohashNeighbors(String hash) => UGeoCodes.geohashNeighbors(hash);

  /// Plus Code (Open Location Code), e.g. "8HJ7PFPQ+X2". `UGeo.plusCode(p)`
  static String plusCode(LatLng p, {int length = 10}) => UGeoCodes.plusCode(p, length: length);

  /// Centre of a Plus Code (short codes need a nearby [reference]). `UGeo.fromPlusCode("PFPQ+X2", reference: tehran)`
  static LatLng? fromPlusCode(String code, {LatLng? reference}) => UGeoCodes.plusCodeCenter(code, reference: reference);

  /// UTM coordinate. `UGeo.toUtm(p).toString()` → "39S 535197 3949547"
  static UUtm toUtm(LatLng p) => UGeoCodes.toUtm(p);

  /// Point of a UTM coordinate. `UGeo.fromUtm(const UUtm(zone: 39, band: "S", easting: 535197, northing: 3949547))`
  static LatLng fromUtm(UUtm utm) => UGeoCodes.fromUtm(utm);

  /// MGRS military grid text. `UGeo.toMgrs(p)`
  static String toMgrs(LatLng p, {int digits = 5}) => UGeoCodes.toMgrs(p, digits: digits);

  /// Point of an MGRS text. `UGeo.fromMgrs("39SWV 35196 49546")`
  static LatLng? fromMgrs(String text) => UGeoCodes.fromMgrs(text);

  /// Degrees-minutes-seconds text (Persian digits optional). `UGeo.toDms(p, persian: true)`
  static String toDms(LatLng p, {bool persian = false}) => UGeoCodes.toDms(p, persian: persian);

  /// Reads typed coordinates in any common form (decimal, DMS, Persian digits). `UGeo.parse("۳۵٫۷، ۵۱٫۴")`
  static LatLng? parse(String text) => UGeoCodes.parse(text);

  /// Map tile containing a point. `UGeo.tileOf(p, 15)`
  static UTileId tileOf(LatLng p, int zoom) => UGeoCodes.tileOf(p, zoom);

  /// Ground metres per pixel at a latitude and zoom. `UGeo.metersPerPixel(35.7, 15)`
  static double metersPerPixel(double latitude, double zoom) => UGeoCodes.metersPerPixel(latitude, zoom);

  // ---------------------------------------------------------------------------------------------- file formats

  /// Features of GeoJSON text (FeatureCollection, Feature or geometry). `UGeo.readGeoJson(text).features`
  static UGeoFeatureCollection readGeoJson(String text) => UGeoJsonCodec.decode(text);

  /// GeoJSON text. `UGeo.writeGeoJson(collection)`
  static String writeGeoJson(UGeoFeatureCollection features, {bool pretty = false}) => UGeoJsonCodec.encode(features, pretty: pretty);

  /// A GPX file (tracks, routes, waypoints). `UGeo.readGpx(text).tracks.first.points`
  static UGpx readGpx(String text) => UGpxCodec.decode(text);

  /// GPX text. `UGeo.writeGpx(gpx)`
  static String writeGpx(UGpx gpx) => UGpxCodec.encode(gpx);

  /// Features of KML text (styles become stroke/fill properties). `UGeo.readKml(text)`
  static UGeoFeatureCollection readKml(String text) => UKmlCodec.decode(text);

  /// KML text. `UGeo.writeKml(collection)`
  static String writeKml(UGeoFeatureCollection features, {String name = "u map"}) => UKmlCodec.encode(features, name: name);

  /// Features of a KMZ (zipped KML). `await UGeo.readKmz(bytes)`
  static Future<UGeoFeatureCollection> readKmz(Uint8List bytes) => UKmlCodec.decodeKmz(bytes);

  /// KMZ bytes. `UGeo.writeKmz(collection)`
  static Uint8List writeKmz(UGeoFeatureCollection features, {String name = "u map"}) => UKmlCodec.encodeKmz(features, name: name);

  /// Geometry of WKT text. `UGeo.readWkt("POINT (51.4 35.7)")`
  static UGeoGeometry? readWkt(String text) => UWktCodec.decode(text);

  /// WKT text. `UGeo.writeWkt(geometry)`
  static String writeWkt(UGeoGeometry geometry) => UWktCodec.encode(geometry);

  /// Geometry of WKB bytes (or hex with [readWkbHex]). `UGeo.readWkb(bytes)`
  static UGeoGeometry? readWkb(Uint8List bytes) => UWkbCodec.decode(bytes);

  /// Geometry of hex WKB (as PostGIS prints it). `UGeo.readWkbHex("0101000000…")`
  static UGeoGeometry? readWkbHex(String hex) => UWkbCodec.decodeHex(hex);

  /// WKB bytes. `UGeo.writeWkb(geometry)`
  static Uint8List writeWkb(UGeoGeometry geometry) => UWkbCodec.encode(geometry);

  /// Point features from CSV (lat/lng columns found by name, Persian names too). `UGeo.readCsv(text)`
  static UGeoFeatureCollection readCsv(String text, {String? latColumn, String? lngColumn}) => UGeoCsvCodec.decode(text, latColumn: latColumn, lngColumn: lngColumn);

  /// CSV text of features. `UGeo.writeCsv(collection)`
  static String writeCsv(UGeoFeatureCollection features) => UGeoCsvCodec.encode(features);

  /// Reads any supported file by extension (geojson, json, gpx, kml, kmz, csv, wkt). `await UGeo.readFile("trip.gpx", bytes)`
  static Future<UGeoFeatureCollection> readFile(String name, Uint8List bytes) async {
    final String ext = name.toLowerCase().split(".").last;
    final String text = ext == "kmz" ? "" : utf8.decode(bytes, allowMalformed: true);
    return switch (ext) {
      "gpx" => UGpxCodec.toFeatures(UGpxCodec.decode(text)),
      "kml" => UKmlCodec.decode(text),
      "kmz" => await UKmlCodec.decodeKmz(bytes),
      "csv" || "tsv" || "txt" => UGeoCsvCodec.decode(text),
      "wkt" => UGeoFeatureCollection(<UGeoFeature>[if (UWktCodec.decode(text) != null) UGeoFeature(geometry: UWktCodec.decode(text)!)]),
      _ => UGeoJsonCodec.decode(text),
    };
  }
}
