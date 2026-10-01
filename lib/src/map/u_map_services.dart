import "dart:math" as math;

import "package:u/utilities.dart";

/// A place from search, reverse geocoding, nearby POIs or your own index.
class UMapPlace {
  const UMapPlace({required this.name, required this.point, this.displayName, this.bounds, this.category, this.type, this.address = const <String, String>{}, this.osmId, this.source = "", this.tags = const <String, String>{}});

  factory UMapPlace.fromJson(Map<String, dynamic> j) => UMapPlace(
    name: j["name"]?.toString() ?? "",
    point: LatLng((j["lat"] as num).toDouble(), (j["lng"] as num).toDouble()),
    displayName: j["display"]?.toString(),
    category: j["category"]?.toString(),
    type: j["type"]?.toString(),
    address: Map<String, String>.from((j["address"] as Map<dynamic, dynamic>?)?.map((dynamic k, dynamic v) => MapEntry<String, String>("$k", "$v")) ?? <String, String>{}),
    osmId: j["osm"]?.toString(),
    source: j["source"]?.toString() ?? "",
  );

  final String name;
  final LatLng point;
  final String? displayName;
  final LatLngBounds? bounds;
  final String? category;
  final String? type;
  final Map<String, String> address;

  /// "node/123", "way/456"…
  final String? osmId;

  /// Where it came from: nominatim, photon, overpass, offline…
  final String source;

  /// Raw OSM tags (opening_hours, phone, website…) when known.
  final Map<String, String> tags;

  /// Best one-line label.
  String get label => name.isNotEmpty ? name : (displayName ?? "${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}");

  Map<String, dynamic> toJson() => <String, dynamic>{
    "name": name,
    "lat": point.latitude,
    "lng": point.longitude,
    "display": ?displayName,
    "category": ?category,
    "type": ?type,
    if (address.isNotEmpty) "address": address,
    "osm": ?osmId,
    "source": source,
  };
}

/// Point-of-interest categories for nearby search (OpenStreetMap tags) with English and Persian names.
enum UMapPoiCategory {
  restaurant("amenity", "restaurant", "Restaurant", "رستوران", Icons.restaurant),
  cafe("amenity", "cafe", "Café", "کافه", Icons.local_cafe),
  fastFood("amenity", "fast_food", "Fast food", "فست‌فود", Icons.fastfood),
  fuel("amenity", "fuel", "Gas station", "پمپ بنزین", Icons.local_gas_station),
  charging("amenity", "charging_station", "EV charging", "شارژ خودرو", Icons.ev_station),
  atm("amenity", "atm", "ATM", "خودپرداز", Icons.atm),
  bank("amenity", "bank", "Bank", "بانک", Icons.account_balance),
  hospital("amenity", "hospital", "Hospital", "بیمارستان", Icons.local_hospital),
  pharmacy("amenity", "pharmacy", "Pharmacy", "داروخانه", Icons.local_pharmacy),
  parking("amenity", "parking", "Parking", "پارکینگ", Icons.local_parking),
  hotel("tourism", "hotel", "Hotel", "هتل", Icons.hotel),
  supermarket("shop", "supermarket", "Supermarket", "سوپرمارکت", Icons.local_grocery_store),
  bakery("shop", "bakery", "Bakery", "نانوایی", Icons.bakery_dining),
  school("amenity", "school", "School", "مدرسه", Icons.school),
  mosque("amenity", "place_of_worship", "Place of worship", "عبادتگاه", Icons.mosque),
  police("amenity", "police", "Police", "پلیس", Icons.local_police),
  toilets("amenity", "toilets", "Toilets", "سرویس بهداشتی", Icons.wc),
  busStop("highway", "bus_stop", "Bus stop", "ایستگاه اتوبوس", Icons.directions_bus),
  subway("railway", "station", "Station", "ایستگاه", Icons.subway),
  museum("tourism", "museum", "Museum", "موزه", Icons.museum),
  park("leisure", "park", "Park", "پارک", Icons.park),
  gym("leisure", "fitness_centre", "Gym", "باشگاه", Icons.fitness_center);

  const UMapPoiCategory(this.key, this.value, this.english, this.persian, this.icon);

  final String key;
  final String value;
  final String english;
  final String persian;
  final IconData icon;
}

/// A turn-by-turn step.
class UMapRouteStep {
  const UMapRouteStep({required this.type, required this.instruction, required this.distance, required this.duration, required this.location, this.modifier, this.name, this.exit, this.bearingAfter = 0, this.points = const <LatLng>[]});

  /// depart, turn, new name, merge, roundabout, fork, end of road, continue, arrive…
  final String type;
  final String? modifier;
  final String instruction;
  final String? name;
  final int? exit;
  final double distance;
  final Duration duration;
  final LatLng location;
  final double bearingAfter;
  final List<LatLng> points;

  /// Material icon for this step.
  IconData get icon => UMapFormat.maneuverIcon(type, modifier);
}

/// A route: path, length, time and steps.
class UMapRoute {
  const UMapRoute({required this.points, required this.distance, required this.duration, this.steps = const <UMapRouteStep>[], this.summary = "", this.legs = const <(double, Duration)>[]});

  final List<LatLng> points;

  /// Metres.
  final double distance;
  final Duration duration;
  final List<UMapRouteStep> steps;
  final String summary;

  /// Distance and time of each leg between waypoints.
  final List<(double, Duration)> legs;

  /// Box around the route.
  LatLngBounds get bounds => LatLngBounds.fromPoints(points);
}

/// Travel mode.
enum UMapRouteProfile { car, bike, foot }

/// Online map services on free/open servers (Nominatim, Photon, Overpass, OSRM, Valhalla). Change the URLs to your own servers for production — see MAP_SERVICES.md.
abstract final class UMapServices {
  /// Forward/reverse geocoding (1 request/second, no autocomplete on the public server).
  static String nominatimUrl = "https://nominatim.openstreetmap.org";

  /// Search-as-you-type geocoder.
  static String photonUrl = "https://photon.komoot.io";

  /// POI queries; when one server is busy the next mirror is tried.
  static List<String> overpassUrls = <String>["https://overpass-api.de/api/interpreter", "https://overpass.private.coffee/api/interpreter", "https://maps.mail.ru/osm/tools/overpass/api/interpreter"];

  /// OSRM servers per profile (FOSSGIS public servers; demo use only).
  static Map<UMapRouteProfile, String> osrmUrls = <UMapRouteProfile, String>{
    UMapRouteProfile.car: "https://routing.openstreetmap.de/routed-car",
    UMapRouteProfile.bike: "https://routing.openstreetmap.de/routed-bike",
    UMapRouteProfile.foot: "https://routing.openstreetmap.de/routed-foot",
  };

  /// Valhalla server (isochrones).
  static String valhallaUrl = "https://valhalla1.openstreetmap.de";

  /// Contact e-mail sent to Nominatim (recommended by its policy).
  static String? email;

  /// Default language for names (fa, en…); null uses the server default.
  static String? language;

  static final Client _client = Client();
  static final Map<String, DateTime> _lastCall = <String, DateTime>{};

  static Map<String, String> get _headers => <String, String>{if (!kIsWeb) "User-Agent": UMapTiles.userAgent, "Accept-Language": ?language};

  /// Waits so one host gets at most one request per [gap].
  static Future<void> _polite(String host, Duration gap) async {
    final DateTime? last = _lastCall[host];
    final DateTime now = DateTime.now();
    if (last != null && now.difference(last) < gap) await Future<void>.delayed(gap - now.difference(last));
    _lastCall[host] = DateTime.now();
  }

  static Future<dynamic> _getJson(Uri uri, {Duration gap = Duration.zero}) async {
    if (gap > Duration.zero) await _polite(uri.host, gap);
    final Response r = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) throw HttpException("HTTP ${r.statusCode}: ${r.body.length > 200 ? r.body.substring(0, 200) : r.body}", uri: uri);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  // ---------------------------------------------------------------------------------------------- geocoding

  static UMapPlace _nominatim(Map<String, dynamic> j) {
    final List<dynamic>? bb = j["boundingbox"] as List<dynamic>?;
    return UMapPlace(
      name: j["name"]?.toString() ?? (j["display_name"]?.toString().split(",").first ?? ""),
      displayName: j["display_name"]?.toString(),
      point: LatLng(double.parse("${j["lat"]}"), double.parse("${j["lon"]}")),
      bounds: bb == null || bb.length < 4 ? null : LatLngBounds(LatLng(double.parse("${bb[0]}"), double.parse("${bb[2]}")), LatLng(double.parse("${bb[1]}"), double.parse("${bb[3]}"))),
      category: j["category"]?.toString() ?? j["class"]?.toString(),
      type: j["type"]?.toString(),
      address: (j["address"] as Map<dynamic, dynamic>?)?.map((dynamic k, dynamic v) => MapEntry<String, String>("$k", "$v")) ?? <String, String>{},
      osmId: j["osm_type"] == null ? null : "${j["osm_type"]}/${j["osm_id"]}",
      source: "nominatim",
    );
  }

  /// Address/place search (Nominatim). [near] biases results; [countryCodes] like "ir".
  static Future<List<UMapPlace>> search(String query, {LatLng? near, int limit = 10, String? countryCodes, LatLngBounds? viewbox, String? lang}) async {
    if (query.trim().isEmpty) return <UMapPlace>[];
    final LatLngBounds? box = viewbox ?? (near == null ? null : LatLngBounds(UGeoMath.destination(near, 50000, 225), UGeoMath.destination(near, 50000, 45)));
    final Uri uri = Uri.parse("$nominatimUrl/search").replace(
      queryParameters: <String, String>{
        "q": query,
        "format": "jsonv2",
        "addressdetails": "1",
        "limit": "$limit",
        "countrycodes": ?countryCodes,
        if (box != null) "viewbox": "${box.west},${box.north},${box.east},${box.south}",
        "accept-language": ?(lang ?? language),
        "email": ?email,
      },
    );
    final dynamic json = await _getJson(uri, gap: const Duration(milliseconds: 1100));
    return (json as List<dynamic>).whereType<Map<String, dynamic>>().map(_nominatim).toList();
  }

  /// Address of a point (Nominatim). [zoom] 18 = building, 10 = city.
  static Future<UMapPlace?> reverse(LatLng p, {int zoom = 18, String? lang}) async {
    final Uri uri = Uri.parse("$nominatimUrl/reverse").replace(
      queryParameters: <String, String>{
        "lat": "${p.latitude}",
        "lon": "${p.longitude}",
        "format": "jsonv2",
        "zoom": "$zoom",
        "addressdetails": "1",
        "accept-language": ?(lang ?? language),
        "email": ?email,
      },
    );
    final dynamic json = await _getJson(uri, gap: const Duration(milliseconds: 1100));
    if (json is! Map<String, dynamic> || json.containsKey("error")) return null;
    return _nominatim(json);
  }

  /// Search-as-you-type suggestions (Photon). Debounce calls (~300 ms).
  static Future<List<UMapPlace>> autocomplete(String query, {LatLng? near, int limit = 8, String? lang}) async {
    if (query.trim().length < 2) return <UMapPlace>[];
    final String? l = lang ?? language;
    final Uri uri = Uri.parse("$photonUrl/api/").replace(
      queryParameters: <String, String>{
        "q": query,
        "limit": "$limit",
        if (near != null) "lat": "${near.latitude}",
        if (near != null) "lon": "${near.longitude}",
        if (l != null && <String>["en", "de", "fr", "it"].contains(l)) "lang": l,
      },
    );
    final dynamic json = await _getJson(uri, gap: const Duration(milliseconds: 300));
    final List<dynamic> features = (json as Map<String, dynamic>)["features"] as List<dynamic>? ?? <dynamic>[];
    return features.whereType<Map<String, dynamic>>().map((Map<String, dynamic> f) {
      final Map<String, dynamic> p = f["properties"] as Map<String, dynamic>? ?? <String, dynamic>{};
      final List<dynamic> c = (f["geometry"] as Map<String, dynamic>)["coordinates"] as List<dynamic>;
      final List<String> parts = <String>[for (final String k in <String>["street", "district", "city", "state", "country"]) if (p[k] != null) "${p[k]}"];
      final List<dynamic>? ext = p["extent"] as List<dynamic>?;
      return UMapPlace(
        name: p["name"]?.toString() ?? parts.firstOrNull ?? "",
        displayName: parts.join("، "),
        point: LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        bounds: ext == null || ext.length < 4
            ? null
            : LatLngBounds(LatLng((ext[3] as num).toDouble(), (ext[0] as num).toDouble()), LatLng((ext[1] as num).toDouble(), (ext[2] as num).toDouble())),
        category: p["osm_key"]?.toString(),
        type: p["osm_value"]?.toString(),
        address: <String, String>{for (final String k in <String>["street", "housenumber", "postcode", "city", "district", "state", "country"]) if (p[k] != null) k: "${p[k]}"},
        osmId: p["osm_type"] == null ? null : "${p["osm_type"] == "N" ? "node" : (p["osm_type"] == "W" ? "way" : "relation")}/${p["osm_id"]}",
        source: "photon",
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------------------------- overpass

  /// Runs a raw Overpass QL query and returns its "elements" (tries each mirror in [overpassUrls] until one answers).
  static Future<List<Map<String, dynamic>>> overpass(String query) async {
    Object? lastError;
    for (final String url in overpassUrls) {
      try {
        await _polite(Uri.parse(url).host, const Duration(seconds: 1));
        final Response r = await _client.post(Uri.parse(url), headers: _headers, body: <String, String>{"data": query}).timeout(const Duration(seconds: 40));
        if (r.statusCode != 200 || !r.body.trimLeft().startsWith("{")) {
          lastError = HttpException("Overpass HTTP ${r.statusCode}", uri: Uri.parse(url));
          continue;
        }
        final Map<String, dynamic> json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
        if (json["remark"]?.toString().contains("runtime error") ?? false) {
          lastError = StateError(json["remark"].toString());
          continue;
        }
        return (json["elements"] as List<dynamic>? ?? <dynamic>[]).whereType<Map<String, dynamic>>().toList();
      } on Object catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? StateError("No Overpass server answered");
  }

  /// Places of some categories around a point (closest first).
  static Future<List<UMapPlace>> nearby(LatLng center, List<UMapPoiCategory> categories, {double radius = 1500, int limit = 60, bool persianNames = false}) async {
    final String lat = center.latitude.toStringAsFixed(6);
    final String lng = center.longitude.toStringAsFixed(6);
    final String parts = categories.map((UMapPoiCategory c) => "nwr[\"${c.key}\"=\"${c.value}\"](around:${radius.round()},$lat,$lng);").join();
    final List<Map<String, dynamic>> elements = await overpass("[out:json][timeout:25];($parts);out center $limit;");
    final List<UMapPlace> places = <UMapPlace>[];
    for (final Map<String, dynamic> e in elements) {
      final Map<String, String> tags = (e["tags"] as Map<String, dynamic>? ?? <String, dynamic>{}).map((String k, dynamic v) => MapEntry<String, String>(k, "$v"));
      final double? la = (e["lat"] as num?)?.toDouble() ?? ((e["center"] as Map<String, dynamic>?)?["lat"] as num?)?.toDouble();
      final double? lo = (e["lon"] as num?)?.toDouble() ?? ((e["center"] as Map<String, dynamic>?)?["lon"] as num?)?.toDouble();
      if (la == null || lo == null) continue;
      final UMapPoiCategory? cat = categories.where((UMapPoiCategory c) => tags[c.key] == c.value).firstOrNull;
      places.add(
        UMapPlace(
          name: (persianNames ? tags["name:fa"] : null) ?? tags["name"] ?? (persianNames ? cat?.persian : cat?.english) ?? "",
          point: LatLng(la, lo),
          category: cat?.name,
          type: cat?.value,
          osmId: "${e["type"]}/${e["id"]}",
          source: "overpass",
          tags: tags,
          address: <String, String>{for (final MapEntry<String, String> t in tags.entries) if (t.key.startsWith("addr:")) t.key.substring(5): t.value},
        ),
      );
    }
    places.sort((UMapPlace a, UMapPlace b) => UGeoMath.distance(center, a.point).compareTo(UGeoMath.distance(center, b.point)));
    return places;
  }

  /// Posted speed limit (km/h) of the road at a point, from OSM "maxspeed" tags; null when unknown.
  static Future<int?> speedLimitAt(LatLng p, {double radius = 25}) async {
    final List<Map<String, dynamic>> el = await overpass("[out:json][timeout:10];way(around:${radius.round()},${p.latitude},${p.longitude})[highway][maxspeed];out tags 1;");
    final String? raw = (el.firstOrNull?["tags"] as Map<String, dynamic>?)?["maxspeed"]?.toString();
    if (raw == null) return null;
    final int? n = int.tryParse(RegExp(r"\d+").firstMatch(raw)?.group(0) ?? "");
    if (n == null) return null;
    return raw.contains("mph") ? (n * 1.609344).round() : n;
  }

  // ---------------------------------------------------------------------------------------------- routing (OSRM)

  static String _coords(List<LatLng> pts) => pts.map((LatLng p) => "${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}").join(";");

  /// Routes through [waypoints] (2 or more); [alternatives] asks for other options. Instructions in Persian when [persian].
  static Future<List<UMapRoute>> route(List<LatLng> waypoints, {UMapRouteProfile profile = UMapRouteProfile.car, bool alternatives = false, bool persian = false}) async {
    if (waypoints.length < 2) return <UMapRoute>[];
    final Uri uri = Uri.parse("${osrmUrls[profile]}/route/v1/driving/${_coords(waypoints)}").replace(
      queryParameters: <String, String>{"overview": "full", "geometries": "polyline6", "steps": "true", "alternatives": "$alternatives"},
    );
    final Map<String, dynamic> json = await _getJson(uri, gap: const Duration(milliseconds: 500)) as Map<String, dynamic>;
    if (json["code"] != "Ok") throw StateError("Routing failed: ${json["code"]} ${json["message"] ?? ""}");
    return (json["routes"] as List<dynamic>).whereType<Map<String, dynamic>>().map((Map<String, dynamic> r) => _osrmRoute(r, persian)).toList();
  }

  static UMapRoute _osrmRoute(Map<String, dynamic> r, bool persian) {
    final List<UMapRouteStep> steps = <UMapRouteStep>[];
    final List<(double, Duration)> legs = <(double, Duration)>[];
    final List<String> names = <String>[];
    for (final dynamic leg in r["legs"] as List<dynamic>? ?? <dynamic>[]) {
      final Map<String, dynamic> l = leg as Map<String, dynamic>;
      legs.add(((l["distance"] as num).toDouble(), Duration(milliseconds: ((l["duration"] as num) * 1000).round())));
      if ((l["summary"]?.toString() ?? "").isNotEmpty) names.add(l["summary"].toString());
      for (final dynamic s in l["steps"] as List<dynamic>? ?? <dynamic>[]) {
        final Map<String, dynamic> st = s as Map<String, dynamic>;
        final Map<String, dynamic> m = st["maneuver"] as Map<String, dynamic>;
        final List<dynamic> loc = m["location"] as List<dynamic>;
        final String type = m["type"]?.toString() ?? "turn";
        final String? modifier = m["modifier"]?.toString();
        final String name = st["name"]?.toString() ?? "";
        final int? exit = (m["exit"] as num?)?.toInt();
        steps.add(
          UMapRouteStep(
            type: type,
            modifier: modifier,
            name: name,
            exit: exit,
            instruction: UMapFormat.instruction(type, modifier, street: name, exit: exit, persian: persian),
            distance: (st["distance"] as num).toDouble(),
            duration: Duration(milliseconds: ((st["duration"] as num) * 1000).round()),
            location: LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble()),
            bearingAfter: (m["bearing_after"] as num?)?.toDouble() ?? 0,
            points: st["geometry"] is String ? UGeoCodes.decodePolyline(st["geometry"] as String, precision: 6) : const <LatLng>[],
          ),
        );
      }
    }
    return UMapRoute(
      points: UGeoCodes.decodePolyline(r["geometry"] as String, precision: 6),
      distance: (r["distance"] as num).toDouble(),
      duration: Duration(milliseconds: ((r["duration"] as num) * 1000).round()),
      steps: steps,
      summary: names.join(" · "),
      legs: legs,
    );
  }

  /// The nearest point on the road network (snap a dropped pin to a road).
  static Future<LatLng?> snapToRoad(LatLng p, {UMapRouteProfile profile = UMapRouteProfile.car}) async {
    final Uri uri = Uri.parse("${osrmUrls[profile]}/nearest/v1/driving/${_coords(<LatLng>[p])}");
    final Map<String, dynamic> json = await _getJson(uri, gap: const Duration(milliseconds: 300)) as Map<String, dynamic>;
    final List<dynamic>? w = json["waypoints"] as List<dynamic>?;
    if (w == null || w.isEmpty) return null;
    final List<dynamic> loc = (w.first as Map<String, dynamic>)["location"] as List<dynamic>;
    return LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
  }

  /// Road distance (metres) and time matrix between points (for delivery planning / [UGeoTsp]).
  static Future<(List<List<double>> meters, List<List<double>> seconds)> matrix(List<LatLng> points, {UMapRouteProfile profile = UMapRouteProfile.car}) async {
    final Uri uri = Uri.parse("${osrmUrls[profile]}/table/v1/driving/${_coords(points)}").replace(queryParameters: <String, String>{"annotations": "distance,duration"});
    final Map<String, dynamic> json = await _getJson(uri, gap: const Duration(milliseconds: 500)) as Map<String, dynamic>;
    List<List<double>> grid(String key) => (json[key] as List<dynamic>).map((dynamic row) => (row as List<dynamic>).map((dynamic v) => (v as num?)?.toDouble() ?? double.infinity).toList()).toList();
    return (grid("distances"), grid("durations"));
  }

  /// Snaps a noisy GPS track to roads (map matching); returns the matched path. Max ~100 points per call on public servers.
  static Future<List<LatLng>> matchTrack(List<LatLng> track, {UMapRouteProfile profile = UMapRouteProfile.car}) async {
    if (track.length < 2) return List<LatLng>.of(track);
    final List<LatLng> pts = track.length > 100 ? UGeoMath.visvalingam(track, 100) : track;
    final Uri uri = Uri.parse("${osrmUrls[profile]}/match/v1/driving/${_coords(pts)}").replace(queryParameters: <String, String>{"overview": "full", "geometries": "polyline6"});
    final Map<String, dynamic> json = await _getJson(uri, gap: const Duration(milliseconds: 500)) as Map<String, dynamic>;
    final List<dynamic> m = json["matchings"] as List<dynamic>? ?? <dynamic>[];
    return m.expand((dynamic x) => UGeoCodes.decodePolyline((x as Map<String, dynamic>)["geometry"] as String, precision: 6)).toList();
  }

  // ---------------------------------------------------------------------------------------------- isochrones (Valhalla)

  /// Areas reachable within each of [minutes] (e.g. [5, 10, 15]) — one outline ring per value, largest first.
  static Future<List<(int minutes, List<LatLng> ring)>> isochrones(LatLng center, List<int> minutes, {UMapRouteProfile profile = UMapRouteProfile.car}) async {
    final String costing = switch (profile) {
      UMapRouteProfile.car => "auto",
      UMapRouteProfile.bike => "bicycle",
      UMapRouteProfile.foot => "pedestrian",
    };
    final Map<String, dynamic> body = <String, dynamic>{
      "locations": <Map<String, double>>[
        <String, double>{"lat": center.latitude, "lon": center.longitude},
      ],
      "costing": costing,
      "contours": minutes.map((int m) => <String, int>{"time": m}).toList(),
      "polygons": true,
    };
    final Uri uri = Uri.parse("$valhallaUrl/isochrone").replace(queryParameters: <String, String>{"json": jsonEncode(body)});
    final Map<String, dynamic> json = await _getJson(uri, gap: const Duration(seconds: 1)) as Map<String, dynamic>;
    final UGeoFeatureCollection fc = UGeoJsonCodec.decode(json);
    final List<(int, List<LatLng>)> out = <(int, List<LatLng>)>[];
    for (final UGeoFeature f in fc.features) {
      final int m = (f.properties["contour"] as num?)?.toInt() ?? 0;
      final UGeoGeometry g = f.geometry;
      if (g is UGeoPolygon) out.add((m, g.outer));
      if (g is UGeoMultiPolygon) {
        for (final List<List<LatLng>> p in g.polygons) {
          out.add((m, p.first));
        }
      }
    }
    out.sort(((int, List<LatLng>) a, (int, List<LatLng>) b) => b.$1.compareTo(a.$1));
    return out;
  }
}

/// Links to share a location and a parser for links people paste (geo:, OpenStreetMap, Google, Apple, Waze, Neshan, plus codes, raw coordinates).
abstract final class UMapLinks {
  /// geo: URI that opens the default maps app on Android / many desktop apps.
  static String geo(LatLng p, {String? label, int zoom = 16}) =>
      "geo:${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}?z=$zoom${label == null ? "" : "&q=${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}(${Uri.encodeComponent(label)})"}";

  /// OpenStreetMap web link with a marker.
  static String openStreetMap(LatLng p, {int zoom = 16}) =>
      "https://www.openstreetmap.org/?mlat=${p.latitude.toStringAsFixed(6)}&mlon=${p.longitude.toStringAsFixed(6)}#map=$zoom/${p.latitude.toStringAsFixed(6)}/${p.longitude.toStringAsFixed(6)}";

  /// Google Maps link (opens the app when installed).
  static String google(LatLng p) => "https://www.google.com/maps/search/?api=1&query=${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}";

  /// Google Maps directions link to a destination.
  static String googleDirections(LatLng to, {LatLng? from, String mode = "driving"}) =>
      "https://www.google.com/maps/dir/?api=1&destination=${to.latitude},${to.longitude}${from == null ? "" : "&origin=${from.latitude},${from.longitude}"}&travelmode=$mode";

  /// Apple Maps link.
  static String apple(LatLng p, {String? label}) => "https://maps.apple.com/?ll=${p.latitude},${p.longitude}${label == null ? "" : "&q=${Uri.encodeComponent(label)}"}";

  /// Waze navigation link.
  static String waze(LatLng p) => "https://waze.com/ul?ll=${p.latitude},${p.longitude}&navigate=yes";

  /// Neshan link (popular in Iran).
  static String neshan(LatLng p) => "https://neshan.org/maps/@${p.latitude},${p.longitude},16z";

  /// Short shareable text: name, coordinates, Plus Code and an OSM link.
  static String shareText(LatLng p, {String? label}) => <String>[
    ?label,
    "${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}",
    UGeoCodes.plusCode(p),
    openStreetMap(p),
  ].join("\n");

  /// Point and zoom found in a link or text (geo:, osm.org, google.com/maps, maps.apple.com, waze, neshan, Plus Code, "lat, lng", DMS); null when none.
  static (LatLng point, double? zoom)? parse(String text, {LatLng? reference}) {
    final String s = text.trim();
    RegExpMatch? m = RegExp(r"geo:(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)(?:.*[?&]z=(\d+(?:\.\d+)?))?").firstMatch(s);
    if (m != null) return (LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!)), double.tryParse(m.group(3) ?? ""));
    m = RegExp(r"mlat=(-?\d+(?:\.\d+)?)&mlon=(-?\d+(?:\.\d+)?)").firstMatch(s);
    if (m != null) return (LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!)), double.tryParse(RegExp(r"#map=(\d+)").firstMatch(s)?.group(1) ?? ""));
    m = RegExp(r"#map=(\d+(?:\.\d+)?)/(-?\d+(?:\.\d+)?)/(-?\d+(?:\.\d+)?)").firstMatch(s);
    if (m != null) return (LatLng(double.parse(m.group(2)!), double.parse(m.group(3)!)), double.parse(m.group(1)!));
    m = RegExp(r"@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)(?:,(\d+(?:\.\d+)?)z)?").firstMatch(s);
    if (m != null) return (LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!)), double.tryParse(m.group(3) ?? ""));
    m = RegExp(r"[?&](?:q|query|ll|destination|daddr)=(-?\d+(?:\.\d+)?)(?:,|%2C)(-?\d+(?:\.\d+)?)").firstMatch(s);
    if (m != null) return (LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!)), double.tryParse(RegExp(r"[?&]z=(\d+)").firstMatch(s)?.group(1) ?? ""));
    final RegExpMatch? plus = RegExp(r"\b([23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{0,3})\b", caseSensitive: false).firstMatch(s);
    if (plus != null) {
      final LatLng? c = UGeoCodes.plusCodeCenter(plus.group(1)!.toUpperCase(), reference: reference);
      if (c != null) return (c, 17);
    }
    final LatLng? p = UGeoCodes.parse(s);
    return p == null ? null : (p, null);
  }

  /// Bearing-free straight-line ("as the crow flies") distance text between two points.
  static String crowDistance(LatLng a, LatLng b, {bool persian = false}) => UMapFormat.distance(UGeoMath.distance(a, b), persian: persian);

  /// Helper for tests and debugging: a random point within [meters] of [center].
  static LatLng randomNear(LatLng center, double meters, [math.Random? random]) {
    final math.Random r = random ?? math.Random();
    return UGeoMath.destination(center, meters * math.sqrt(r.nextDouble()), r.nextDouble() * 360);
  }
}
