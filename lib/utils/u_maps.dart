import "package:u/utilities.dart";

/// Map services and offline: search, places, routing, navigation, elevation, offline regions/tile cache, share links (online parts use free servers by default — see MAP_SERVICES.md). `await UMaps.route([a, b])`
abstract final class UMaps {
  // ---------------------------------------------------------------------------------------------- setup

  /// Identify your app to tile/geocoding servers (OSM and Nominatim require it; not settable on the web). `UMaps.setUserAgent("com.example.app/1.0")`
  static void setUserAgent(String value) => UMapTiles.userAgent = value;

  /// Point every service at your own servers (null keeps the current one). `UMaps.useServers(nominatim: "https://geo.example.com")`
  static void useServers({String? nominatim, String? photon, List<String>? overpass, String? osrmCar, String? osrmBike, String? osrmFoot, String? valhalla}) {
    if (nominatim != null) UMapServices.nominatimUrl = nominatim;
    if (photon != null) UMapServices.photonUrl = photon;
    if (overpass != null) UMapServices.overpassUrls = overpass;
    if (osrmCar != null) UMapServices.osrmUrls[UMapRouteProfile.car] = osrmCar;
    if (osrmBike != null) UMapServices.osrmUrls[UMapRouteProfile.bike] = osrmBike;
    if (osrmFoot != null) UMapServices.osrmUrls[UMapRouteProfile.foot] = osrmFoot;
    if (valhalla != null) UMapServices.valhallaUrl = valhalla;
  }

  /// Language for place names and search results (fa, en…). `UMaps.language = "fa";`
  static set language(String? code) => UMapServices.language = code;

  /// When true maps use only offline packs and cache (no network). `UMaps.offline = true;`
  static set offline(bool value) => UMapTiles.offline = value;

  // ---------------------------------------------------------------------------------------------- search & places

  /// Address/place search (Nominatim, 1 request/s). `await UMaps.search("Azadi Tower", near: me)`
  static Future<List<UMapPlace>> search(String query, {LatLng? near, int limit = 10, String? countryCodes}) => UMapServices.search(query, near: near, limit: limit, countryCodes: countryCodes);

  /// Suggestions while typing (Photon); debounce your calls. `await UMaps.autocomplete("ازادی")`
  static Future<List<UMapPlace>> autocomplete(String text, {LatLng? near, int limit = 8}) => UMapServices.autocomplete(text, near: near, limit: limit);

  /// Address of a point (Nominatim). `(await UMaps.reverse(p))?.displayName`
  static Future<UMapPlace?> reverse(LatLng p, {int zoom = 18}) => UMapServices.reverse(p, zoom: zoom);

  /// Places of some categories nearby (Overpass). `await UMaps.nearby(me, [UMapPoiCategory.fuel])`
  static Future<List<UMapPlace>> nearby(LatLng center, List<UMapPoiCategory> categories, {double radius = 1500, bool persianNames = false}) =>
      UMapServices.nearby(center, categories, radius: radius, persianNames: persianNames);

  /// Posted speed limit (km/h) at a point from OSM tags, null when unknown. `await UMaps.speedLimitAt(me)`
  static Future<int?> speedLimitAt(LatLng p) => UMapServices.speedLimitAt(p);

  /// An offline, typo-tolerant, Persian-aware search index over your own places. `UMaps.searchIndex<String>()..add("id", p, ["کافه نادری"])`
  static UMapSearchIndex<T> searchIndex<T>() => UMapSearchIndex<T>();

  /// Saves a place in a list (favourites, home, work…) on the device. `await UMaps.savePlace(place, list: "Home")`
  static Future<void> savePlace(UMapPlace place, {String list = "Saved", Color color = const Color(0xFFE53935)}) => UMapPlaces.save(place, list: list, color: color);

  /// Every saved place as (list, colour, place). `await UMaps.savedPlaces()`
  static Future<List<(String, Color, UMapPlace)>> savedPlaces() => UMapPlaces.all();

  /// Removes a saved place. `await UMaps.removePlace(place)`
  static Future<void> removePlace(UMapPlace place, {String list = "Saved"}) => UMapPlaces.remove(place, list: list);

  /// Recent searches, newest first. `await UMaps.recentSearches()`
  static Future<List<UMapPlace>> recentSearches() => UMapPlaces.recent();

  // ---------------------------------------------------------------------------------------------- routing & navigation

  /// Routes through waypoints with turn-by-turn steps (OSRM). `final r = (await UMaps.route([a, b])).first;`
  static Future<List<UMapRoute>> route(List<LatLng> waypoints, {UMapRouteProfile profile = UMapRouteProfile.car, bool alternatives = false, bool persian = false}) =>
      UMapServices.route(waypoints, profile: profile, alternatives: alternatives, persian: persian);

  /// Nearest point on a road. `await UMaps.snapToRoad(pin)`
  static Future<LatLng?> snapToRoad(LatLng p, {UMapRouteProfile profile = UMapRouteProfile.car}) => UMapServices.snapToRoad(p, profile: profile);

  /// Road distance/time matrix between stops (feed it to UGeo.bestOrder). `final (m, s) = await UMaps.matrix(stops);`
  static Future<(List<List<double>>, List<List<double>>)> matrix(List<LatLng> stops, {UMapRouteProfile profile = UMapRouteProfile.car}) => UMapServices.matrix(stops, profile: profile);

  /// Delivery order for stops using real road distances. `await UMaps.optimizeStops(stops, roundTrip: true)`
  static Future<List<int>> optimizeStops(List<LatLng> stops, {bool roundTrip = false, UMapRouteProfile profile = UMapRouteProfile.car}) async {
    final (List<List<double>> meters, List<List<double>> _) = await UMapServices.matrix(stops, profile: profile);
    return UGeoTsp.solve(stops, roundTrip: roundTrip, cost: (int a, int b) => meters[a][b]);
  }

  /// Snaps a noisy GPS track onto roads. `await UMaps.matchTrack(recorder.path)`
  static Future<List<LatLng>> matchTrack(List<LatLng> track, {UMapRouteProfile profile = UMapRouteProfile.car}) => UMapServices.matchTrack(track, profile: profile);

  /// Areas reachable in N minutes (Valhalla). `await UMaps.isochrones(me, [5, 10, 15])`
  static Future<List<(int, List<LatLng>)>> isochrones(LatLng center, List<int> minutes, {UMapRouteProfile profile = UMapRouteProfile.car}) =>
      UMapServices.isochrones(center, minutes, profile: profile);

  /// Turn-by-turn session (snapping, ETA, off-route rerouting, voice texts); call `.start()` for live GPS. Needs `permission add location`. `UMaps.navigate(route)..start()`
  static UMapNavigation navigate(UMapRoute route, {bool persian = false, bool autoReroute = true, UMapRouteProfile profile = UMapRouteProfile.car}) {
    final LatLng destination = route.points.last;
    return UMapNavigation(
      route: route,
      persian: persian,
      reroute: autoReroute ? (LatLng from) async => (await UMapServices.route(<LatLng>[from, destination], profile: profile, persian: persian)).firstOrNull : null,
    );
  }

  /// Offline road graph of an area downloaded from Overpass (save with toBytes, load with UMapRoadGraph.fromBytes). `final g = await UMaps.roadGraph(bounds);`
  static Future<UMapRoadGraph> roadGraph(LatLngBounds area, {UMapRouteProfile profile = UMapRouteProfile.car}) => UMapRoadGraph.fromOverpass(area, profile: profile);

  // ---------------------------------------------------------------------------------------------- tracking & sharing

  /// GPS track recorder (pause/resume, Kalman smoothing, stats, speed alert, GPX). Needs `permission add location`. `final r = UMaps.recorder()..start();`
  static UTrackRecorder recorder({double? speedLimitKmh, void Function(double speed)? onOverSpeed}) =>
      UTrackRecorder(speedLimit: speedLimitKmh == null ? null : speedLimitKmh / 3.6, onOverSpeed: onOverSpeed);

  /// Polygon/circle geofences with enter/exit/dwell evaluated in Dart (any shape, every platform). `UMaps.geofencer([UMapZone.polygon(id: "site", polygon: ring)])..start()`
  static UMapGeofencer geofencer(List<UMapZone> zones) => UMapGeofencer(zones);

  /// Live shared map + ETA sharing through your own transport (WebSocket, Firebase…). `UMaps.liveSession(me: userId, send: socket.add)..start()`
  static UMapLiveSession liveSession({required String me, required FutureOr<void> Function(String json) send, String? name}) => UMapLiveSession(me: me, send: send, name: name);

  // ---------------------------------------------------------------------------------------------- elevation

  /// Ground elevation in metres (free terrain tiles). `await UMaps.elevation(p)`
  static Future<double?> elevation(LatLng p) => UMapTerrain.elevationAt(p);

  /// Elevation profile along a path as (distance, elevation). `await UMaps.elevationProfile(route.points)`
  static Future<List<(double, double)>> elevationProfile(List<LatLng> path, {int samples = 120}) => UMapTerrain.profile(path, samples: samples);

  // ---------------------------------------------------------------------------------------------- offline

  /// Prepares an offline download of a box (start(), pause(), resume(), cancel(), progress). Refuses sources that forbid bulk download. `UMaps.downloadRegion(source: s, bounds: b, maxZoom: 16).start()`
  static UMapRegionDownload downloadRegion({required UMapTileSource source, required LatLngBounds bounds, String? name, int minZoom = 10, int maxZoom = 16, bool allowRestricted = false}) => UMapRegionDownload(
    source: source,
    allowRestricted: allowRestricted,
    region: UMapRegion(id: "region_${DateTime.now().millisecondsSinceEpoch}", name: name ?? "Offline area", sourceId: source.id, minZoom: minZoom, maxZoom: maxZoom, bounds: bounds),
  );

  /// Offline download of a corridor along a route ([width] metres each side). `UMaps.downloadAlongRoute(source: s, route: r.points).start()`
  static UMapRegionDownload downloadAlongRoute({required UMapTileSource source, required List<LatLng> route, double width = 1000, int minZoom = 10, int maxZoom = 16, bool allowRestricted = false}) => UMapRegionDownload(
    source: source,
    allowRestricted: allowRestricted,
    region: UMapRegion(
      id: "route_${DateTime.now().millisecondsSinceEpoch}",
      name: "Route",
      sourceId: source.id,
      minZoom: minZoom,
      maxZoom: maxZoom,
      polygon: UGeoOps.convexHull(UGeoOps.bufferLine(UGeoMath.simplify(route, width / 4), width)),
    ),
  );

  /// Tiles and estimated bytes of a download before starting it. `UMaps.estimate(source, bounds, 10, 16)`
  static (int tiles, int bytes) estimate(UMapTileSource source, LatLngBounds bounds, int minZoom, int maxZoom) {
    final int tiles = UGeoCodes.tileCount(bounds, minZoom, maxZoom);
    return (tiles, tiles * source.averageTileBytes);
  }

  /// Saved offline regions. `await UMaps.regions()`
  static Future<List<UMapRegion>> regions() => UMapRegions.all();

  /// Deletes a saved region and its tiles. `await UMaps.deleteRegion(id)`
  static Future<void> deleteRegion(String id) => UMapRegions.delete(id);

  /// Bytes used by the browsing tile cache. `await UMaps.cacheSize()`
  static Future<int> cacheSize() => UMapTileStore.usage();

  /// Empties the browsing tile cache (offline regions stay). `await UMaps.clearCache()`
  static Future<void> clearCache() async {
    await UMapTileStore.clear();
    UMapTiles.clearMemory();
  }

  /// Opens a .pmtiles archive by URL (any static host), file or bytes for offline/self-hosted maps. `UMapTileSource.pmtiles(await UMaps.pmtilesFromUrl(url))`
  static Future<UPmTiles> pmtilesFromUrl(String url) => UPmTiles.fromUrl(url);

  /// Opens a .pmtiles file on disk (not on the web). `await UMaps.pmtilesFromFile(path)`
  static Future<UPmTiles> pmtilesFromFile(String path) => UPmTiles.fromFile(path);

  /// Opens .pmtiles bytes (e.g. a bundled asset). `await UMaps.pmtilesFromBytes((await rootBundle.load("assets/city.pmtiles")).buffer.asUint8List())`
  static Future<UPmTiles> pmtilesFromBytes(Uint8List bytes) => UPmTiles.fromBytes(bytes);

  /// Downloads a MapLibre/Mapbox GL style for vector maps. `UMap(vectorStyle: await UMaps.vectorStyle("https://tiles.openfreemap.org/styles/liberty"))`
  static Future<UMapVectorStyle> vectorStyle(String url, {String? language}) => UMapVectorStyle.fromUrl(url, language: language);

  // ---------------------------------------------------------------------------------------------- sharing & links

  /// Shares a location as text (name, coordinates, Plus Code, link). `await UMaps.share(p, label: "Meet here")`
  static Future<UShareResult> share(LatLng p, {String? label}) => UShare.text(UMapLinks.shareText(p, label: label));

  /// Link that opens a point on OpenStreetMap. `UMaps.link(p)`
  static String link(LatLng p, {int zoom = 16}) => UMapLinks.openStreetMap(p, zoom: zoom);

  /// Reads a point from a pasted link/text (geo:, Google, Apple, OSM, Waze, Neshan, Plus Code, coordinates). `UMaps.parseLink(text)?.$1`
  static (LatLng, double?)? parseLink(String text, {LatLng? reference}) => UMapLinks.parse(text, reference: reference);

  /// Opens turn-by-turn in Google Maps (or the web). `await UMaps.openDirections(dest)`
  static Future<bool> openDirections(LatLng to, {LatLng? from}) => ULaunch.url(UMapLinks.googleDirections(to, from: from));

  /// Opens the point in the device's default maps app (geo: URI; Apple Maps link on iOS/macOS). `await UMaps.openInMapsApp(p)`
  static Future<bool> openInMapsApp(LatLng p, {String? label}) =>
      ULaunch.url(!kIsWeb && (Platform.isIOS || Platform.isMacOS) ? UMapLinks.apple(p, label: label) : UMapLinks.geo(p, label: label));

  // ---------------------------------------------------------------------------------------------- formatting

  /// "850 m" / "۸۵۰ متر" / "0.5 mi". `UMaps.formatDistance(1234, persian: true)`
  static String formatDistance(double meters, {bool persian = false, bool imperial = false}) => UMapFormat.distance(meters, persian: persian, imperial: imperial);

  /// "45 min" / "۴۵ دقیقه". `UMaps.formatDuration(route.duration, persian: true)`
  static String formatDuration(Duration d, {bool persian = false}) => UMapFormat.duration(d, persian: persian);

  /// "54 km/h" from m/s. `UMaps.formatSpeed(position.speed!)`
  static String formatSpeed(double metersPerSecond, {bool persian = false, bool imperial = false}) => UMapFormat.speed(metersPerSecond, persian: persian, imperial: imperial);
}
