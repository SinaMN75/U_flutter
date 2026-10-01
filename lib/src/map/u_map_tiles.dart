import "dart:math" as math;
import "dart:ui" as ui;

import "package:u/utilities.dart";

/// What a tile server returns.
enum UMapTileFormat { raster, vector, terrarium }

/// The terms a tile server is offered under (see MAP_SERVICES.md in the package root).
enum UMapTilePolicy {
  /// Open data, no key, no stated limit.
  free,

  /// Free with a fair-use policy: fine for development and small apps, may block heavy traffic.
  fairUse,

  /// Free for non-commercial use only.
  nonCommercial,

  /// Needs an account / API key (usually with a free tier).
  apiKey,

  /// Your own server or file: no third-party terms.
  selfHosted,
}

/// A map tile source: URL template, zooms, attribution and usage terms. Presets cover free servers; [UMapTileSource.custom] takes any URL.
class UMapTileSource {
  const UMapTileSource({
    required this.id,
    required this.name,
    required this.url,
    this.subdomains = const <String>[],
    this.minZoom = 0,
    this.maxNativeZoom = 19,
    this.attribution = "",
    this.format = UMapTileFormat.raster,
    this.policy = UMapTilePolicy.fairUse,
    this.bulkDownload = false,
    this.note,
    this.headers = const <String, String>{},
    this.tms = false,
    this.overlay = false,
    this.dark = false,
    this.pmtiles,
    this.averageTileBytes = 20000,
  });

  /// Stable id used for the cache folder.
  final String id;
  final String name;

  /// Template with {z} {x} {y}, optional {s} (subdomain), {r} ("@2x" on retina screens) and {key}. A TileJSON URL (no {z}) is resolved on first use.
  final String url;
  final List<String> subdomains;
  final int minZoom;

  /// Highest zoom the server has; deeper zooms scale these tiles up.
  final int maxNativeZoom;
  final String attribution;
  final UMapTileFormat format;
  final UMapTilePolicy policy;

  /// True when the provider allows downloading regions for offline use.
  final bool bulkDownload;

  /// One line about the terms.
  final String? note;
  final Map<String, String> headers;
  final bool tms;

  /// True for transparent overlays (labels) drawn above a base map.
  final bool overlay;

  /// True when the style is dark (for picking a matching UI).
  final bool dark;

  /// A local or remote .pmtiles archive to read tiles from instead of [url].
  final UPmTiles? pmtiles;

  /// Typical tile size in bytes, used to estimate offline downloads.
  final int averageTileBytes;

  /// URL of one tile.
  String urlFor(int z, int x, int y, {bool retina = false, String? template}) {
    String s = template ?? url;
    final int yy = tms ? (1 << z) - 1 - y : y;
    s = s.replaceAll("{z}", "$z").replaceAll("{x}", "$x").replaceAll("{y}", "$yy").replaceAll("{r}", retina ? "@2x" : "");
    if (subdomains.isNotEmpty) s = s.replaceAll("{s}", subdomains[(x + y) % subdomains.length]);
    if (s.contains("{q}")) s = s.replaceAll("{q}", UGeoCodes.quadkey(UTileId(z, x, y)));
    return s;
  }

  /// Same source with some parts replaced.
  UMapTileSource copyWith({String? id, String? name, String? url, int? maxNativeZoom, String? attribution, UMapTilePolicy? policy, bool? bulkDownload, Map<String, String>? headers}) =>
      UMapTileSource(
        id: id ?? this.id,
        name: name ?? this.name,
        url: url ?? this.url,
        subdomains: subdomains,
        minZoom: minZoom,
        maxNativeZoom: maxNativeZoom ?? this.maxNativeZoom,
        attribution: attribution ?? this.attribution,
        format: format,
        policy: policy ?? this.policy,
        bulkDownload: bulkDownload ?? this.bulkDownload,
        note: note,
        headers: headers ?? this.headers,
        tms: tms,
        overlay: overlay,
        dark: dark,
        pmtiles: pmtiles,
        averageTileBytes: averageTileBytes,
      );

  /// Same source with {key} in the URL replaced by an API key.
  UMapTileSource withKey(String key) => copyWith(url: url.replaceAll("{key}", key));

  // ---------------------------------------------------------------------------------------------- free presets

  /// OpenStreetMap standard tiles. Free under a fair-use policy; offline bulk download is forbidden.
  static const UMapTileSource openStreetMap = UMapTileSource(
    id: "osm",
    name: "OpenStreetMap",
    url: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution: "© OpenStreetMap contributors",
    note: "OSMF tile usage policy: light use only, set a real User-Agent, no bulk/offline downloading.",
  );

  /// Humanitarian OSM style (OSM France). Fair use, no bulk download.
  static const UMapTileSource humanitarian = UMapTileSource(
    id: "osm_hot",
    name: "Humanitarian",
    url: "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
    subdomains: <String>["a", "b", "c"],
    attribution: "© OpenStreetMap contributors, tiles by HOT / OSM France",
    note: "Run by volunteers; light use only.",
  );

  /// OpenTopoMap terrain with contour lines (max zoom 17). Fair use, no bulk download.
  static const UMapTileSource openTopoMap = UMapTileSource(
    id: "opentopomap",
    name: "OpenTopoMap",
    url: "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
    subdomains: <String>["a", "b", "c"],
    maxNativeZoom: 17,
    attribution: "© OpenStreetMap contributors, SRTM | © OpenTopoMap (CC-BY-SA)",
    note: "Volunteer server; light use only.",
  );

  /// CARTO Positron (light). Needs a CARTO API key now (tiles say API KEY REQUIRED without one); use UMapVectorStyle.light() for a free light map.
  static const UMapTileSource cartoLight = UMapTileSource(
    id: "carto_light",
    name: "Light",
    url: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
    subdomains: <String>["a", "b", "c", "d"],
    maxNativeZoom: 20,
    attribution: "© OpenStreetMap contributors © CARTO",
    policy: UMapTilePolicy.apiKey,
    note: "CARTO basemaps now need an API key (carto.com/basemaps/apikey); without one every tile says API KEY REQUIRED.",
  );

  /// CARTO Dark Matter (dark). Needs a CARTO API key; use UMapVectorStyle.dark() for a free dark map.
  static const UMapTileSource cartoDark = UMapTileSource(
    id: "carto_dark",
    name: "Dark",
    url: "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
    subdomains: <String>["a", "b", "c", "d"],
    maxNativeZoom: 20,
    attribution: "© OpenStreetMap contributors © CARTO",
    policy: UMapTilePolicy.apiKey,
    dark: true,
    note: "CARTO basemaps now need an API key (carto.com/basemaps/apikey); without one every tile says API KEY REQUIRED.",
  );

  /// CARTO Voyager (colourful). Needs a CARTO API key.
  static const UMapTileSource cartoVoyager = UMapTileSource(
    id: "carto_voyager",
    name: "Voyager",
    url: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
    subdomains: <String>["a", "b", "c", "d"],
    maxNativeZoom: 20,
    attribution: "© OpenStreetMap contributors © CARTO",
    policy: UMapTilePolicy.apiKey,
    note: "CARTO basemaps now need an API key (carto.com/basemaps/apikey); without one every tile says API KEY REQUIRED.",
  );

  /// Transparent CARTO labels for satellite imagery. Needs a CARTO API key; UMapVectorStyle.labels() is the free alternative.
  static const UMapTileSource cartoLabels = UMapTileSource(
    id: "carto_labels",
    name: "Labels",
    url: "https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png",
    subdomains: <String>["a", "b", "c", "d"],
    maxNativeZoom: 20,
    attribution: "© OpenStreetMap contributors © CARTO",
    policy: UMapTilePolicy.apiKey,
    overlay: true,
    note: "CARTO basemaps now need an API key (carto.com/basemaps/apikey); without one every tile says API KEY REQUIRED.",
  );

  /// Esri World Imagery (satellite). Free to try; production apps need an ArcGIS account and must follow Esri's terms.
  static const UMapTileSource esriSatellite = UMapTileSource(
    id: "esri_imagery",
    name: "Satellite",
    url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    attribution: "Tiles © Esri — Esri, Maxar, Earthstar Geographics, GIS User Community",
    policy: UMapTilePolicy.apiKey,
    averageTileBytes: 30000,
    note: "Esri terms: development use is free; production needs an ArcGIS Location Platform account (has a free tier).",
  );

  /// Sentinel-2 cloudless 2016 satellite mosaic by EOX (CC BY 4.0, ~10 m resolution, max zoom 15). Truly free imagery.
  static const UMapTileSource sentinel2 = UMapTileSource(
    id: "s2cloudless_2016",
    name: "Sentinel-2",
    url: "https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless_3857/default/g/{z}/{y}/{x}.jpg",
    maxNativeZoom: 15,
    attribution: "Sentinel-2 cloudless – s2maps.eu by EOX IT Services GmbH (contains modified Copernicus Sentinel data 2016)",
    policy: UMapTilePolicy.free,
    averageTileBytes: 25000,
    note: "The 2016 layer is CC BY 4.0 (commercial use OK with attribution); newer years are CC BY-NC-SA.",
  );

  /// OpenFreeMap vector tiles (OpenMapTiles schema). Free, no key, no view limits; render with UMapVectorStyle.
  static const UMapTileSource openFreeMap = UMapTileSource(
    id: "openfreemap",
    name: "OpenFreeMap",
    url: "https://tiles.openfreemap.org/planet",
    maxNativeZoom: 14,
    attribution: "OpenFreeMap © OpenMapTiles Data from OpenStreetMap",
    format: UMapTileFormat.vector,
    policy: UMapTilePolicy.free,
    averageTileBytes: 45000,
    note: "Free with no limits on views; for offline packs download their full planet file or self-host instead of scraping.",
  );

  /// Terrain elevation (Terrarium PNG) from the AWS open-data registry, max zoom 15. Used for hillshade, contours and elevation.
  static const UMapTileSource terrarium = UMapTileSource(
    id: "terrarium",
    name: "Terrain",
    url: "https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png",
    maxNativeZoom: 15,
    attribution: "Terrain: Mapzen, AWS Open Data (SRTM, GMTED, ETOPO1 and others)",
    format: UMapTileFormat.terrarium,
    policy: UMapTilePolicy.free,
    bulkDownload: true,
    averageTileBytes: 60000,
  );

  /// Every keyless preset, for a style picker.
  static const List<UMapTileSource> freePresets = <UMapTileSource>[openStreetMap, humanitarian, openTopoMap, sentinel2, esriSatellite];

  // ---------------------------------------------------------------------------------------------- keyed providers

  /// Mapbox raster style ([style] like streets-v12, satellite-streets-v12); needs a Mapbox token (free tier, then billed).
  factory UMapTileSource.mapbox(String token, {String style = "streets-v12"}) => UMapTileSource(
    id: "mapbox_$style",
    name: "Mapbox",
    url: "https://api.mapbox.com/styles/v1/mapbox/$style/tiles/256/{z}/{x}/{y}{r}?access_token=$token",
    maxNativeZoom: 22,
    attribution: "© Mapbox © OpenStreetMap contributors",
    policy: UMapTilePolicy.apiKey,
    note: "Mapbox: free tier, then billed per use.",
  );

  /// Stadia Maps / Stamen styles (stamen_terrain, stamen_toner, stamen_watercolor, alidade_smooth…); needs a Stadia API key.
  factory UMapTileSource.stadia(String apiKey, {String style = "stamen_terrain"}) => UMapTileSource(
    id: "stadia_$style",
    name: "Stadia $style",
    url: "https://tiles.stadiamaps.com/tiles/$style/{z}/{x}/{y}{r}.png?api_key=$apiKey",
    maxNativeZoom: 20,
    attribution: "© Stadia Maps © Stamen Design © OpenMapTiles © OpenStreetMap contributors",
    policy: UMapTilePolicy.apiKey,
  );

  /// Thunderforest styles (cycle, transport, outdoors, landscape…); needs an API key.
  factory UMapTileSource.thunderforest(String apiKey, {String style = "cycle"}) => UMapTileSource(
    id: "thunderforest_$style",
    name: "Thunderforest $style",
    url: "https://{s}.tile.thunderforest.com/$style/{z}/{x}/{y}{r}.png?apikey=$apiKey",
    subdomains: const <String>["a", "b", "c"],
    maxNativeZoom: 22,
    attribution: "Maps © Thunderforest, Data © OpenStreetMap contributors",
    policy: UMapTilePolicy.apiKey,
  );

  /// MapTiler raster styles (streets-v2, satellite, topo-v2…); needs an API key.
  factory UMapTileSource.mapTiler(String apiKey, {String style = "streets-v2"}) => UMapTileSource(
    id: "maptiler_$style",
    name: "MapTiler $style",
    url: "https://api.maptiler.com/maps/$style/256/{z}/{x}/{y}{r}.png?key=$apiKey",
    maxNativeZoom: 22,
    attribution: "© MapTiler © OpenStreetMap contributors",
    policy: UMapTilePolicy.apiKey,
  );

  /// Any tile server (your own, a WMTS, a GeoServer XYZ endpoint…).
  factory UMapTileSource.custom(
    String url, {
    String id = "custom",
    String name = "Custom",
    String attribution = "",
    int maxNativeZoom = 19,
    List<String> subdomains = const <String>[],
    UMapTileFormat format = UMapTileFormat.raster,
    Map<String, String> headers = const <String, String>{},
    bool tms = false,
    bool overlay = false,
  }) => UMapTileSource(
    id: id,
    name: name,
    url: url,
    subdomains: subdomains,
    maxNativeZoom: maxNativeZoom,
    attribution: attribution,
    format: format,
    policy: UMapTilePolicy.selfHosted,
    bulkDownload: true,
    headers: headers,
    tms: tms,
    overlay: overlay,
  );

  /// Tiles read from a .pmtiles archive (a file you generated, bundled, or a URL on any static host with range requests).
  factory UMapTileSource.pmtiles(UPmTiles archive, {String id = "pmtiles", String name = "Offline", String attribution = "© OpenStreetMap contributors"}) => UMapTileSource(
    id: id,
    name: name,
    url: "",
    maxNativeZoom: archive.header.maxZoom,
    minZoom: archive.header.minZoom,
    attribution: attribution,
    format: archive.header.tileType == 1 ? UMapTileFormat.vector : UMapTileFormat.raster,
    policy: UMapTilePolicy.selfHosted,
    bulkDownload: true,
    pmtiles: archive,
  );
}

/// Disk cache of map tiles: native platforms keep plain files under app storage (no index), the web uses u's storage.
abstract final class UMapTileStore {
  /// Browsing-cache size limit; the oldest tiles are deleted past it.
  static int maxCacheBytes = 300 * 1024 * 1024;

  /// Cached tiles older than this are refreshed when online (still used offline).
  static Duration maxAge = const Duration(days: 30);

  static Directory? _cacheDir;
  static Directory? _offlineDir;
  static int _writes = 0;

  static Future<Directory> _dir(bool offline) async {
    if (offline) return _offlineDir ??= Directory(uJoinPath((await getApplicationSupportDirectory()).path, "u_map_tiles"));
    return _cacheDir ??= Directory(uJoinPath((await getApplicationCacheDirectory()).path, "u_map_tiles"));
  }

  static String _key(bool offline, String source, int z, int x, int y) => "umap_tiles/${offline ? "offline" : "cache"}/$source/$z/$x/$y";

  static Future<File> _file(bool offline, String source, int z, int x, int y) async => File(uJoinPath((await _dir(offline)).path, "$source/$z/$x/$y"));

  /// Bytes of a stored tile (offline packs first, then the browsing cache), with whether it is stale.
  static Future<(Uint8List, bool stale)?> read(String source, int z, int x, int y) async {
    if (kIsWeb) {
      final Uint8List? off = await UFileStorage.getBytes(_key(true, source, z, x, y));
      if (off != null) return (off, false);
      final Uint8List? cached = await UFileStorage.getBytes(_key(false, source, z, x, y), bucket: UStorageBucket.cache);
      return cached == null ? null : (cached, false);
    }
    for (final bool offline in <bool>[true, false]) {
      try {
        final File f = await _file(offline, source, z, x, y);
        final Uint8List bytes = await f.readAsBytes();
        final bool stale = !offline && DateTime.now().difference(f.lastModifiedSync()) > maxAge;
        return (bytes, stale);
      } on Object {
        continue;
      }
    }
    return null;
  }

  /// True when a tile is stored.
  static Future<bool> has(String source, int z, int x, int y, {bool offline = true}) async {
    if (kIsWeb) return UFileStorage.contains(_key(offline, source, z, x, y), bucket: offline ? UStorageBucket.support : UStorageBucket.cache);
    return (await _file(offline, source, z, x, y)).existsSync();
  }

  /// Saves a tile to the browsing cache, or permanently when [offline].
  static Future<void> write(String source, int z, int x, int y, Uint8List bytes, {bool offline = false}) async {
    if (kIsWeb) {
      await UFileStorage.setBytes(_key(offline, source, z, x, y), bytes, bucket: offline ? UStorageBucket.support : UStorageBucket.cache, expireIn: offline ? null : maxAge * 3);
      return;
    }
    try {
      final File f = await _file(offline, source, z, x, y);
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes, flush: offline);
    } on Object {
      return;
    }
    if (!offline && ++_writes % 300 == 0) unawaited(trim());
  }

  /// Deletes one offline tile.
  static Future<void> deleteTile(String source, int z, int x, int y) async {
    if (kIsWeb) return UFileStorage.remove(_key(true, source, z, x, y));
    try {
      await (await _file(true, source, z, x, y)).delete();
    } on Object {
      return;
    }
  }

  /// Bytes used by the browsing cache (or offline packs).
  static Future<int> usage({bool offline = false, String? source}) async {
    if (kIsWeb) {
      final String prefix = "umap_tiles/${offline ? "offline" : "cache"}/${source ?? ""}";
      return UFileStorage.entries(bucket: offline ? UStorageBucket.support : UStorageBucket.cache).where((UStorageEntry e) => e.key.startsWith(prefix)).fold<int>(0, (int s, UStorageEntry e) => s + e.size);
    }
    final Directory d = await _dir(offline);
    final Directory target = source == null ? d : Directory(uJoinPath(d.path, source));
    if (!target.existsSync()) return 0;
    int total = 0;
    await for (final FileSystemEntity e in target.list(recursive: true, followLinks: false)) {
      if (e is File) total += e.lengthSync();
    }
    return total;
  }

  /// Empties the browsing cache (or every offline pack) for one source or all.
  static Future<void> clear({bool offline = false, String? source}) async {
    if (kIsWeb) {
      final String prefix = "umap_tiles/${offline ? "offline" : "cache"}/${source ?? ""}";
      final UStorageBucket bucket = offline ? UStorageBucket.support : UStorageBucket.cache;
      for (final String k in UFileStorage.keys(bucket: bucket).where((String k) => k.startsWith(prefix))) {
        await UFileStorage.remove(k, bucket: bucket);
      }
      return;
    }
    final Directory d = await _dir(offline);
    final Directory target = source == null ? d : Directory(uJoinPath(d.path, source));
    if (target.existsSync()) await target.delete(recursive: true);
  }

  /// Deletes the oldest cached tiles until the cache fits [maxCacheBytes].
  static Future<void> trim() async {
    if (kIsWeb) return UFileStorage.trimCache();
    final Directory d = await _dir(false);
    if (!d.existsSync()) return;
    final List<(File, int, DateTime)> files = <(File, int, DateTime)>[];
    int total = 0;
    await for (final FileSystemEntity e in d.list(recursive: true, followLinks: false)) {
      if (e is File) {
        final FileStat s = e.statSync();
        files.add((e, s.size, s.modified));
        total += s.size;
      }
    }
    if (total <= maxCacheBytes) return;
    files.sort(((File, int, DateTime) a, (File, int, DateTime) b) => a.$3.compareTo(b.$3));
    for (final (File f, int size, DateTime _) in files) {
      if (total <= maxCacheBytes * 0.8) break;
      try {
        await f.delete();
        total -= size;
      } on Object {
        continue;
      }
    }
  }
}

/// Loads tiles: memory → offline packs → browsing cache → .pmtiles → network (then cached). Shared by every map layer.
abstract final class UMapTiles {
  /// User-Agent sent with tile requests (OSM requires a real one: set it to your app id).
  static String userAgent = "u-flutter-map/3 (+https://pub.dev/packages/u)";

  /// When true no network requests are made (everything comes from offline packs and cache).
  static bool offline = false;

  static final Client _client = Client();
  static final ULruCache<String, Uint8List> _memory = ULruCache<String, Uint8List>(maxBytes: 48 * 1024 * 1024, sizeOf: (Uint8List b) => b.length);
  static final Map<String, Future<String>> _templates = <String, Future<String>>{};
  static final Map<String, Future<Uint8List?>> _inflight = <String, Future<Uint8List?>>{};

  /// The real URL template of a source (fetches TileJSON once when the URL has no {z}).
  static Future<String> template(UMapTileSource source) {
    if (source.url.contains("{z}") || source.pmtiles != null) return Future<String>.value(source.url);
    return _templates[source.id] ??= () async {
      final Response r = await _client.get(Uri.parse(source.url), headers: <String, String>{if (!kIsWeb) "User-Agent": userAgent, ...source.headers});
      final Map<String, dynamic> json = jsonDecode(r.body) as Map<String, dynamic>;
      final List<dynamic> tiles = json["tiles"] as List<dynamic>? ?? <dynamic>[];
      if (tiles.isEmpty) throw StateError("TileJSON at ${source.url} lists no tiles");
      return tiles.first.toString();
    }();
  }

  /// Raw bytes of one tile (null when missing or offline). [retina] asks for "@2x" where the server supports it.
  static Future<Uint8List?> load(UMapTileSource source, int z, int x, int y, {bool retina = false, bool offlineOnly = false, bool store = true}) {
    final String key = "${source.id}/$z/$x/$y${retina ? "@2x" : ""}";
    final Uint8List? hot = _memory.get(key);
    if (hot != null) return SynchronousFuture<Uint8List?>(hot);
    return _inflight[key] ??= _load(source, z, x, y, retina: retina, offlineOnly: offlineOnly || offline, store: store).then((Uint8List? b) {
      unawaited(_inflight.remove(key));
      if (b != null) _memory.put(key, b);
      return b;
    });
  }

  static Future<Uint8List?> _load(UMapTileSource source, int z, int x, int y, {required bool retina, required bool offlineOnly, required bool store}) async {
    if (source.pmtiles != null) return source.pmtiles!.tile(z, x, y);
    final (Uint8List, bool)? stored = await UMapTileStore.read(source.id, z, x, y);
    if (stored != null && (!stored.$2 || offlineOnly)) return stored.$1;
    if (offlineOnly) return null;
    try {
      final String url = source.urlFor(z, x, y, retina: retina, template: await template(source));
      final Response r = await _client.get(Uri.parse(url), headers: <String, String>{if (!kIsWeb) "User-Agent": userAgent, ...source.headers}).timeout(const Duration(seconds: 20));
      if (r.statusCode == 404 || r.statusCode == 204) return null;
      if (r.statusCode != 200) return stored?.$1;
      final Uint8List bytes = r.bodyBytes;
      if (store) await UMapTileStore.write(source.id, z, x, y, bytes);
      return bytes;
    } on Object {
      return stored?.$1;
    }
  }

  /// Puts tile bytes in memory (tiles you bundled or generated) so layers use them without a request.
  static void put(UMapTileSource source, int z, int x, int y, Uint8List bytes, {bool retina = false}) => _memory.put("${source.id}/$z/$x/$y${retina ? "@2x" : ""}", bytes);

  /// Drops tiles held in memory (call after changing style or clearing the cache).
  static void clearMemory() => _memory.clear();

  /// Builds a flutter_map TileLayer for a source (raster tiles; use UMapVectorTiles / UMapTerrain for the others).
  static TileLayer layer(UMapTileSource source, {bool retina = true, bool offlineOnly = false, TileDisplay display = const TileDisplay.fadeIn(), int keepBuffer = 2, int panBuffer = 1}) => TileLayer(
    tileProvider: UMapCachedTileProvider(source, retina: retina, offlineOnly: offlineOnly),
    minNativeZoom: source.minZoom,
    maxNativeZoom: source.maxNativeZoom,
    maxZoom: 22,
    keepBuffer: keepBuffer,
    panBuffer: panBuffer,
    tileDisplay: display,
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
    userAgentPackageName: userAgent,
  );

  /// Decompresses gzip bytes (pass-through when not gzip). Pure Dart on the web.
  static Uint8List gunzip(Uint8List bytes) {
    if (bytes.length < 18 || bytes[0] != 0x1f || bytes[1] != 0x8b) return bytes;
    if (!kIsWeb) {
      try {
        return Uint8List.fromList(gzip.decode(bytes));
      } on Object {
        // Fall through to the Dart inflater.
      }
    }
    final int flags = bytes[3];
    int pos = 10;
    if (flags & 4 != 0) pos += 2 + (bytes[pos] | (bytes[pos + 1] << 8));
    if (flags & 8 != 0) {
      while (pos < bytes.length && bytes[pos] != 0) {
        pos++;
      }
      pos++;
    }
    if (flags & 16 != 0) {
      while (pos < bytes.length && bytes[pos] != 0) {
        pos++;
      }
      pos++;
    }
    if (flags & 2 != 0) pos += 2;
    return UPdfInflater(bytes, start: pos).run();
  }
}

/// flutter_map tile provider backed by [UMapTiles] (cache, offline packs, pmtiles, retina).
class UMapCachedTileProvider extends TileProvider {
  UMapCachedTileProvider(this.source, {this.retina = true, this.offlineOnly = false});

  final UMapTileSource source;
  final bool retina;
  final bool offlineOnly;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final bool hiDpi = retina && source.url.contains("{r}") && (ui.PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1) > 1.5;
    return UMapTileImage(source, coordinates.z, coordinates.x, coordinates.y, retina: hiDpi, offlineOnly: offlineOnly);
  }
}

/// Image of one raster tile loaded through [UMapTiles].
@immutable
class UMapTileImage extends ImageProvider<UMapTileImage> {
  const UMapTileImage(this.source, this.z, this.x, this.y, {this.retina = false, this.offlineOnly = false});

  final UMapTileSource source;
  final int z;
  final int x;
  final int y;
  final bool retina;
  final bool offlineOnly;

  @override
  Future<UMapTileImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture<UMapTileImage>(this);

  @override
  ImageStreamCompleter loadImage(UMapTileImage key, ImageDecoderCallback decode) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final Uint8List? bytes = await UMapTiles.load(source, z, x, y, retina: retina, offlineOnly: offlineOnly);
    if (bytes == null || bytes.isEmpty) throw StateError("Tile $z/$x/$y unavailable");
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is UMapTileImage && other.source.id == source.id && other.z == z && other.x == x && other.y == y && other.retina == retina;

  @override
  int get hashCode => Object.hash(source.id, z, x, y, retina);
}

// ------------------------------------------------------------------------------------------------ offline regions

/// A saved offline area: a box or polygon, zoom range and the source it was downloaded from.
class UMapRegion {
  UMapRegion({required this.id, required this.name, required this.sourceId, required this.minZoom, required this.maxZoom, this.bounds, this.polygon, DateTime? created, this.tiles = 0, this.bytes = 0, this.complete = false})
    : created = created ?? DateTime.now();

  factory UMapRegion.fromJson(Map<String, dynamic> j) => UMapRegion(
    id: j["id"] as String,
    name: j["name"] as String,
    sourceId: j["source"] as String,
    minZoom: (j["minZoom"] as num).toInt(),
    maxZoom: (j["maxZoom"] as num).toInt(),
    bounds: j["bounds"] == null
        ? null
        : LatLngBounds(LatLng((j["bounds"][0] as num).toDouble(), (j["bounds"][1] as num).toDouble()), LatLng((j["bounds"][2] as num).toDouble(), (j["bounds"][3] as num).toDouble())),
    polygon: (j["polygon"] as List<dynamic>?)?.map((dynamic p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList(),
    created: DateTime.tryParse(j["created"]?.toString() ?? ""),
    tiles: (j["tiles"] as num?)?.toInt() ?? 0,
    bytes: (j["bytes"] as num?)?.toInt() ?? 0,
    complete: j["complete"] == true,
  );

  final String id;
  final String name;
  final String sourceId;
  final int minZoom;
  final int maxZoom;
  final LatLngBounds? bounds;

  /// Optional outline (e.g. a buffer around a route); tiles outside it are skipped.
  final List<LatLng>? polygon;
  final DateTime created;
  int tiles;
  int bytes;
  bool complete;

  /// Box of the region.
  LatLngBounds get box => bounds ?? LatLngBounds.fromPoints(polygon!);

  Map<String, dynamic> toJson() => <String, dynamic>{
    "id": id,
    "name": name,
    "source": sourceId,
    "minZoom": minZoom,
    "maxZoom": maxZoom,
    if (bounds != null) "bounds": <double>[bounds!.south, bounds!.west, bounds!.north, bounds!.east],
    if (polygon != null) "polygon": polygon!.map((LatLng p) => <double>[p.latitude, p.longitude]).toList(),
    "created": created.toIso8601String(),
    "tiles": tiles,
    "bytes": bytes,
    "complete": complete,
  };

  /// Every tile this region covers.
  Iterable<UTileId> tileIds() sync* {
    for (int z = minZoom; z <= maxZoom; z++) {
      for (final UTileId t in UGeoCodes.tilesIn(box, z)) {
        if (polygon == null || _tileTouches(t, polygon!)) yield t;
      }
    }
  }

  /// Number of tiles (exact for boxes, an upper bound for polygons until counted).
  int get tileCount => polygon == null ? UGeoCodes.tileCount(box, minZoom, maxZoom) : tileIds().length;

  static bool _tileTouches(UTileId t, List<LatLng> polygon) {
    final LatLngBounds b = UGeoCodes.tileBounds(t);
    if (UGeoMath.ringContains(polygon, b.center)) return true;
    if (polygon.any(b.contains)) return true;
    return UGeoMath.linesIntersect(UGeoMath.boundsRing(b), polygon);
  }
}

/// Progress of an offline download.
class UMapDownloadProgress {
  const UMapDownloadProgress({required this.done, required this.total, required this.failed, required this.bytes, required this.skipped, required this.elapsed});

  final int done;
  final int total;
  final int failed;
  final int skipped;
  final int bytes;
  final Duration elapsed;

  /// 0..1
  double get fraction => total == 0 ? 1 : done / total;

  /// Rough time left.
  Duration get remaining => done == 0 ? Duration.zero : Duration(milliseconds: (elapsed.inMilliseconds / done * (total - done)).round());

  bool get finished => done >= total;
}

/// Downloads a region's tiles for offline use with pause/resume/cancel; refuses sources whose terms forbid bulk download unless [allowRestricted].
class UMapRegionDownload {
  UMapRegionDownload({required this.source, required this.region, this.concurrency = 4, this.retries = 2, this.allowRestricted = false});

  final UMapTileSource source;
  final UMapRegion region;
  final int concurrency;
  final int retries;
  final bool allowRestricted;

  final StreamController<UMapDownloadProgress> _progress = StreamController<UMapDownloadProgress>.broadcast();
  Completer<void>? _resume;
  bool _cancelled = false;

  /// Progress events while downloading.
  Stream<UMapDownloadProgress> get progress => _progress.stream;

  /// True while paused.
  bool get isPaused => _resume != null;

  /// Pauses after the tiles in flight finish.
  void pause() => _resume ??= Completer<void>();

  /// Continues a paused download.
  void resume() {
    _resume?.complete();
    _resume = null;
  }

  /// Stops; downloaded tiles are kept.
  void cancel() {
    _cancelled = true;
    resume();
  }

  /// Runs the download and saves the region; already-stored tiles are skipped (so it also resumes after a restart).
  Future<UMapRegion> start() async {
    if (!source.bulkDownload && !allowRestricted) {
      throw StateError("${source.name} does not allow bulk downloading (${source.note ?? "see its usage policy"}). Use your own tiles (UMapTileSource.custom / pmtiles) or pass allowRestricted: true at your own risk.");
    }
    final List<UTileId> tiles = region.tileIds().toList();
    final Stopwatch watch = Stopwatch()..start();
    int done = 0;
    int failed = 0;
    int skipped = 0;
    int bytes = 0;
    int next = 0;
    void report() {
      if (!_progress.isClosed) _progress.add(UMapDownloadProgress(done: done, total: tiles.length, failed: failed, bytes: bytes, skipped: skipped, elapsed: watch.elapsed));
    }

    Future<void> worker() async {
      while (!_cancelled) {
        if (_resume != null) await _resume!.future;
        if (_cancelled || next >= tiles.length) return;
        final UTileId t = tiles[next++];
        if (await UMapTileStore.has(source.id, t.z, t.x, t.y)) {
          skipped++;
          done++;
          report();
          continue;
        }
        Uint8List? data;
        for (int attempt = 0; attempt <= retries && data == null; attempt++) {
          data = await UMapTiles.load(source, t.z, t.x, t.y, store: false);
        }
        if (data != null) {
          await UMapTileStore.write(source.id, t.z, t.x, t.y, data, offline: true);
          bytes += data.length;
        } else {
          failed++;
        }
        done++;
        if (done % 5 == 0 || done == tiles.length) report();
      }
    }

    await Future.wait(List<Future<void>>.generate(math.max(1, concurrency), (_) => worker()));
    region
      ..tiles = done - failed
      ..bytes += bytes
      ..complete = !_cancelled && failed == 0;
    await UMapRegions.save(region);
    report();
    await _progress.close();
    return region;
  }
}

/// Saved offline regions: list, estimate, delete.
abstract final class UMapRegions {
  static const String _key = "umap_regions.json";

  /// Every saved region.
  static Future<List<UMapRegion>> all() async {
    final dynamic json = await UFileStorage.getJson(_key);
    if (json is! List) return <UMapRegion>[];
    return json.whereType<Map<dynamic, dynamic>>().map((Map<dynamic, dynamic> m) => UMapRegion.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  /// Saves (adds or replaces) a region.
  static Future<void> save(UMapRegion region) async {
    final List<UMapRegion> list = (await all()).where((UMapRegion r) => r.id != region.id).toList()..add(region);
    await UFileStorage.setJson(_key, list.map((UMapRegion r) => r.toJson()).toList());
  }

  /// Estimated download size in bytes.
  static int estimateBytes(UMapRegion region, UMapTileSource source) => region.tileCount * source.averageTileBytes;

  /// True when a point at a zoom is inside some saved region of a source.
  static Future<bool> covers(String sourceId, LatLng point, int zoom) async =>
      (await all()).any((UMapRegion r) => r.sourceId == sourceId && zoom >= r.minZoom && zoom <= r.maxZoom && (r.polygon == null ? r.box.contains(point) : UGeoMath.ringContains(r.polygon!, point)));

  /// Deletes a region and the tiles no other region uses.
  static Future<void> delete(String id) async {
    final List<UMapRegion> list = await all();
    final UMapRegion? region = list.where((UMapRegion r) => r.id == id).firstOrNull;
    if (region == null) return;
    final List<UMapRegion> others = list.where((UMapRegion r) => r.id != id && r.sourceId == region.sourceId).toList();
    final Set<UTileId> keep = <UTileId>{for (final UMapRegion o in others) ...o.tileIds()};
    for (final UTileId t in region.tileIds()) {
      if (!keep.contains(t)) await UMapTileStore.deleteTile(region.sourceId, t.z, t.x, t.y);
    }
    await UFileStorage.setJson(_key, list.where((UMapRegion r) => r.id != id).map((UMapRegion r) => r.toJson()).toList());
  }
}

// ------------------------------------------------------------------------------------------------ PMTiles

/// Header of a PMTiles v3 archive.
class UPmTilesHeader {
  const UPmTilesHeader({
    required this.rootOffset,
    required this.rootLength,
    required this.metadataOffset,
    required this.metadataLength,
    required this.leafOffset,
    required this.dataOffset,
    required this.internalCompression,
    required this.tileCompression,
    required this.tileType,
    required this.minZoom,
    required this.maxZoom,
    required this.bounds,
    required this.center,
    required this.centerZoom,
  });

  final int rootOffset;
  final int rootLength;
  final int metadataOffset;
  final int metadataLength;
  final int leafOffset;
  final int dataOffset;

  /// 1 none, 2 gzip, 3 brotli, 4 zstd (only 1 and 2 are supported).
  final int internalCompression;
  final int tileCompression;

  /// 1 mvt, 2 png, 3 jpeg, 4 webp, 5 avif.
  final int tileType;
  final int minZoom;
  final int maxZoom;
  final LatLngBounds bounds;
  final LatLng center;
  final int centerZoom;
}

class _PmEntry {
  const _PmEntry(this.tileId, this.offset, this.length, this.runLength);

  final int tileId;
  final int offset;
  final int length;
  final int runLength;
}

/// Reads tiles from a PMTiles v3 archive (one file holding a whole tile set): bundled asset, downloaded file or a URL on any static host.
class UPmTiles {
  UPmTiles._(this._source, this.header);

  final UDocByteSource _source;
  final UPmTilesHeader header;
  final ULruCache<int, List<_PmEntry>> _dirs = ULruCache<int, List<_PmEntry>>(maxBytes: 4000000, sizeOf: (List<_PmEntry> l) => l.length * 32);

  /// Opens an archive from bytes (e.g. `rootBundle.load`).
  static Future<UPmTiles> fromBytes(Uint8List bytes) => open(UMemoryByteSource(bytes, id: "pmtiles:${bytes.length}"));

  /// Opens an archive file on disk (not on the web).
  static Future<UPmTiles> fromFile(String path) async => open(UCachedByteSource(await UFileByteSource.open(path)));

  /// Opens an archive by URL using HTTP range requests (any static host / CDN works).
  static Future<UPmTiles> fromUrl(String url, {Map<String, String>? headers}) async => open(UCachedByteSource(await UHttpRangeByteSource.open(url, headers: headers)));

  /// Opens an archive from any byte source.
  static Future<UPmTiles> open(UDocByteSource source) async {
    final Uint8List h = await source.read(0, 127);
    if (h.length < 127 || String.fromCharCodes(h.sublist(0, 7)) != "PMTiles" || h[7] != 3) throw const FormatException("Not a PMTiles v3 archive");
    final ByteData d = ByteData.sublistView(h);
    int u64(int o) => d.getUint32(o, Endian.little) + d.getUint32(o + 4, Endian.little) * 4294967296;
    double e7(int o) => d.getInt32(o, Endian.little) / 1e7;
    final UPmTilesHeader header = UPmTilesHeader(
      rootOffset: u64(8),
      rootLength: u64(16),
      metadataOffset: u64(24),
      metadataLength: u64(32),
      leafOffset: u64(40),
      dataOffset: u64(56),
      internalCompression: h[97],
      tileCompression: h[98],
      tileType: h[99],
      minZoom: h[100],
      maxZoom: h[101],
      bounds: LatLngBounds(UGeoMath.safe(e7(106), e7(102)), UGeoMath.safe(e7(114), e7(110))),
      centerZoom: h[118],
      center: UGeoMath.safe(e7(123), e7(119)),
    );
    return UPmTiles._(source, header);
  }

  Uint8List _decompress(Uint8List b, int compression) {
    if (compression == 2) return UMapTiles.gunzip(b);
    if (compression <= 1) return b;
    throw UnsupportedError("PMTiles compression $compression (brotli/zstd) is not supported; rebuild with gzip");
  }

  /// The archive's JSON metadata.
  Future<Map<String, dynamic>> metadata() async {
    final Uint8List raw = await _source.read(header.metadataOffset, header.metadataLength);
    return jsonDecode(utf8.decode(_decompress(raw, header.internalCompression))) as Map<String, dynamic>;
  }

  Future<List<_PmEntry>> _directory(int offset, int length) async {
    final List<_PmEntry>? cached = _dirs.get(offset);
    if (cached != null) return cached;
    final Uint8List bytes = _decompress(await _source.read(offset, length), header.internalCompression);
    int pos = 0;
    int varint() {
      int result = 0;
      int shift = 0;
      while (pos < bytes.length) {
        final int b = bytes[pos++];
        result += (b & 0x7f) * math.pow(2, shift).toInt();
        if (b < 0x80) break;
        shift += 7;
      }
      return result;
    }

    final int n = varint();
    final List<int> ids = List<int>.filled(n, 0);
    int last = 0;
    for (int i = 0; i < n; i++) {
      last += varint();
      ids[i] = last;
    }
    final List<int> runs = List<int>.generate(n, (_) => varint());
    final List<int> lengths = List<int>.generate(n, (_) => varint());
    final List<int> offsets = List<int>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final int v = varint();
      offsets[i] = v == 0 && i > 0 ? offsets[i - 1] + lengths[i - 1] : v - 1;
    }
    final List<_PmEntry> entries = <_PmEntry>[for (int i = 0; i < n; i++) _PmEntry(ids[i], offsets[i], lengths[i], runs[i])];
    _dirs.put(offset, entries);
    return entries;
  }

  /// Hilbert tile id of z/x/y.
  static int tileId(int z, int x, int y) {
    int acc = 0;
    for (int i = 0; i < z; i++) {
      acc += (1 << i) * (1 << i);
    }
    int d = 0;
    int tx = x;
    int ty = y;
    for (int s = (1 << z) ~/ 2; s > 0; s ~/= 2) {
      final int rx = (tx & s) > 0 ? 1 : 0;
      final int ry = (ty & s) > 0 ? 1 : 0;
      d += s * s * ((3 * rx) ^ ry);
      if (ry == 0) {
        if (rx == 1) {
          tx = s - 1 - tx;
          ty = s - 1 - ty;
        }
        final int t = tx;
        tx = ty;
        ty = t;
      }
    }
    return acc + d;
  }

  static _PmEntry? _find(List<_PmEntry> entries, int id) {
    int m = 0;
    int n = entries.length - 1;
    while (m <= n) {
      final int k = (n + m) >> 1;
      final int c = id - entries[k].tileId;
      if (c > 0) {
        m = k + 1;
      } else if (c < 0) {
        n = k - 1;
      } else {
        return entries[k];
      }
    }
    if (n >= 0) {
      if (entries[n].runLength == 0) return entries[n];
      if (id - entries[n].tileId < entries[n].runLength) return entries[n];
    }
    return null;
  }

  /// Bytes of one tile (decompressed), or null when the archive has none there.
  Future<Uint8List?> tile(int z, int x, int y) async {
    if (z < header.minZoom || z > header.maxZoom) return null;
    final int id = tileId(z, x, y);
    int offset = header.rootOffset;
    int length = header.rootLength;
    for (int depth = 0; depth < 4; depth++) {
      final _PmEntry? e = _find(await _directory(offset, length), id);
      if (e == null) return null;
      if (e.runLength > 0) return _decompress(await _source.read(header.dataOffset + e.offset, e.length), header.tileCompression);
      offset = header.leafOffset + e.offset;
      length = e.length;
    }
    return null;
  }

  /// Closes the underlying file or connection.
  Future<void> close() => _source.close();
}
