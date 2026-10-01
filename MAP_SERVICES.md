# Maps in `u`: what is free and what you must do before shipping

Every map feature in `u` is pure Dart code that you own. Nothing in the code costs money. What can cost
money, or break your app if you ignore it, is the data some features download from servers on the internet.

This document lists each of those servers, its terms, and what to do for a production app. It was checked
against the live servers on 2026-10-02. Terms change, so re-check the links before you launch.

---

## 1. At a glance

| Feature | Default server | Free? | Before shipping |
|---|---|---|---|
| Geometry, drawing, clustering, heatmaps, file formats, offline search, Kalman, geofencing, TSP | none (on device) | ✅ always | nothing |
| Offline routing (`UMapRoadGraph`) | none (your bundled graph) | ✅ always | build the graph once (see §8) |
| GPS, compass, background tracking | your device (u's native engine) | ✅ always | `dart run u:app permission add location` (and `location-always` for background) |
| Street map tiles | `tile.openstreetmap.org` | ⚠️ fair use | set a User-Agent; **no offline packs**; move to your own tiles when you grow |
| Topographic tiles | OpenTopoMap | ⚠️ fair use | same as OSM |
| Satellite (2016, ~10 m) | EOX Sentinel‑2 cloudless | ✅ CC BY 4.0 | keep the attribution |
| Satellite (sharp) | Esri World Imagery | 🔑 account for production | sign up for ArcGIS Location Platform, or don't ship it |
| Vector maps | OpenFreeMap | ✅ free, no view limits | don't bulk-scrape; self-host for offline packs |
| Elevation, hillshade, contours | AWS Terrain Tiles | ✅ open data | nothing (keep attribution) |
| CARTO styles (`cartoLight/Dark/Voyager/Labels`) | CARTO | 🔑 **now needs an API key** | use the vector styles instead, or get a key |
| Search / reverse geocoding | Nominatim (OSMF) | ⚠️ 1 request/s, no autocomplete | self-host or use a paid geocoder |
| Search-as-you-type | Photon (komoot) | ⚠️ fair use | self-host Photon for real traffic |
| Nearby places, speed limits | Overpass API | ⚠️ fair use, often busy | self-host or precompute (see §5) |
| Online routing, snap-to-road, matrix, map matching | OSRM on `routing.openstreetmap.de` (FOSSGIS) | ⚠️ demo / fair use | self-host OSRM or use offline routing |
| Isochrones | Valhalla on `valhalla1.openstreetmap.de` (FOSSGIS) | ⚠️ fair use | self-host Valhalla, or `UMapRoadGraph.isochrone` offline |
| Mapbox / Stadia / Thunderforest / MapTiler | their servers | 🔑 key, free tier then paid | only if you choose them |
| Live map sharing, live ETA sharing | **your backend** | your server cost | connect `UMapLiveSession.send/receive` to your socket |
| Voice guidance | — | — | add a text-to-speech engine (§9) |
| Live traffic, Street View, lane guidance, reviews/photos | not included | ❌ | see §10 |

Legend: ✅ free with no action, ⚠️ free with limits (fine for development, risky for production),
🔑 needs an account or key.

---

## 2. Things to do in every app (5 minutes)

```dart
// 1. Identify your app. OSM and Nominatim block anonymous traffic. Not settable on the web, where the browser sends its own.
UMaps.setUserAgent("com.yourcompany.yourapp/1.0 (+https://yourapp.com)");

// 2. Nominatim asks for a contact e-mail on heavy use.
UMapServices.email = "maps@yourapp.com";

// 3. Language for names and search results.
UMaps.language = "fa";
```

- Keep `showAttribution: true` on `UMap` (the default). OpenStreetMap data is free under the **ODbL**,
  but the licence **requires** the visible credit "© OpenStreetMap contributors". Most tile providers
  require their own credit too, and `UMap` shows the right text for each source.
- Location: run `dart run u:app permission add location`. Add `location-always` only if you use
  background tracking. On iOS and Google Play you will have to justify background location in review.

---

## 3. Map tiles (the pictures of the map)

### Free sources in `UMapTileSource.freePresets`

| Preset | Terms | Offline packs (`UMapRegionDownload`) |
|---|---|---|
| `openStreetMap` | [OSMF tile policy](https://operations.osmfoundation.org/policies/tiles/): light use, real User-Agent, **bulk download forbidden** | ❌ refused by `u` |
| `humanitarian` | run by volunteers (OSM France), light use | ❌ |
| `openTopoMap` | volunteer server, light use | ❌ |
| `sentinel2` | EOX s2cloudless **2016** layer, CC BY 4.0. Commercial use is OK with attribution. Newer years are CC BY‑NC‑SA (non-commercial only). | ✅ allowed by `u`, but be gentle |
| `esriSatellite` | Esri terms: development is free, production needs an ArcGIS Location Platform account (it has a free tier) | ❌ |
| `openFreeMap` (vector) | free, no key, no view limits; for offline use they ask you to download their planet file instead of scraping | ❌ by default |
| `terrarium` (elevation) | AWS open data registry, free | ✅ |

`UMapRegionDownload.start()` **refuses** sources whose terms forbid bulk downloading, and explains
why. You can override with `allowRestricted: true`, but you risk your users' IPs or your app getting
blocked.

### CARTO changed its terms

`cartoLight`, `cartoDark`, `cartoVoyager` and `cartoLabels` used to be free for small apps. **They now
return a watermark "API KEY REQUIRED" on every tile** (verified while building this). Options:

- Free: use `UMapVectorStyle.light()`, `.dark()` or `.labels()`. These are drawn by `u` itself from
  free OpenFreeMap data and look similar.
- Paid: get a key at carto.com/basemaps and use `UMapTileSource.custom(...)` with their keyed URL.

### Keyed providers (only if you want their look)

- `UMapTileSource.mapbox(token)`: free tier, then billed per map load.
- `UMapTileSource.stadia(key)`: Stamen styles (terrain, toner, watercolor). The old `tile.stamen.com`
  URL is dead, so `UMapTileProvider.stamenTerrain` now goes to Stadia and needs `UMap(apiKey:)`.
- `UMapTileSource.thunderforest(key)` and `UMapTileSource.mapTiler(key)`: free tiers, then paid.

### The zero-cost production setup for tiles (recommended)

Make your own tile file once and host it anywhere. No server, no per-view cost.

1. Download your region's OSM data for free from [Geofabrik](https://download.geofabrik.de/)
   (e.g. `iran-latest.osm.pbf`, a few hundred MB).
2. Turn it into a vector tile archive with [planetiler](https://github.com/onthegomap/planetiler)
   (free, one command, OpenMapTiles schema):
   ```bash
   java -Xmx8g -jar planetiler.jar --osm-path=iran-latest.osm.pbf --output=iran.pmtiles
   ```
   If you get an `.mbtiles` file instead, convert it with the free `pmtiles` CLI: `pmtiles convert iran.mbtiles iran.pmtiles`.
   Use **gzip** compression (the default). `u` does not decode brotli or zstd.
3. Put `iran.pmtiles` on any static host that supports HTTP range requests (Cloudflare R2, S3, GitHub
   Releases, your own nginx), or ship it inside the app.
4. Use it:
   ```dart
   final archive = await UMaps.pmtilesFromUrl("https://cdn.yourapp.com/iran.pmtiles"); // or pmtilesFromFile / pmtilesFromBytes
   UMap(vectorStyle: UMapVectorStyle.light(language: "fa"), vectorSource: UMapTileSource.pmtiles(archive))
   // A raster .pmtiles (satellite, scanned maps): UMap(source: UMapTileSource.pmtiles(archive))
   ```
   Offline packs of your own source are allowed (`bulkDownload` is true for `custom`/`pmtiles`).

   The built-in `light`/`dark`/`labels` styles expect the **OpenMapTiles** layer names (planetiler,
   tilemaker and OpenFreeMap use them). Archives in the **Protomaps** schema (`earth`, `roads`,
   `places`…) need a Protomaps MapLibre style JSON. Load it with `UMaps.vectorStyle(url)`.

Satellite imagery can't be made this way. Use Sentinel‑2 2016 (free) or pay for Esri, Mapbox or MapTiler imagery.

---

## 4. Search and addresses

| Call | Server | Limits |
|---|---|---|
| `UMaps.search`, `UMaps.reverse` | Nominatim | **1 request per second** (u waits automatically), no autocomplete, no bulk geocoding, User-Agent required ([policy](https://operations.osmfoundation.org/policies/nominatim/)) |
| `UMaps.autocomplete`, `UMapSearchBar` | Photon by komoot | fair use; please don't send heavy production traffic |
| `ULocation.addressOf` / `find` | the phone's OS geocoder (Android/iOS/macOS) | free, no key, but not available on web/Windows/Linux |

What to do for production:

- **Self-host** Photon (one Java jar plus a prebuilt index; country extracts are small) and/or Nominatim
  (Docker image). Then: `UMaps.useServers(photon: "https://geo.yourapp.com", nominatim: "https://nominatim.yourapp.com")`.
- Or use a paid geocoder with a free tier (LocationIQ, MapTiler, OpenCage, Geoapify) and pass your own
  function to `UMapSearchBar(search: ...)`.
- For your own places (shops, branches) you don't need any server. Use `UMaps.searchIndex()`. It works
  offline, tolerates typos and treats Persian and Arabic letter forms as the same.

---

## 5. Nearby places and speed limits (Overpass)

`UMaps.nearby` and `UMaps.speedLimitAt` use the public Overpass API. While building this feature,
**both the main server and a mirror answered "too busy"** for several minutes. That is normal for a
free shared service. `u` already tries three mirrors in turn (`UMapServices.overpassUrls`).

For production:

- Self-host Overpass for your country (Docker), then `UMaps.useServers(overpass: ["https://overpass.yourapp.com/api/interpreter"])`.
- Or don't query live at all. Extract the POIs once (osmium or Overpass), ship them as GeoJSON, and
  use `UMaps.searchIndex()` plus `UGeo.pointIndex()`. That is free and works offline.

---

## 6. Routing, snap-to-road, distance matrix, isochrones

| Call | Server | Notes |
|---|---|---|
| `UMaps.route`, `snapToRoad`, `matrix`, `matchTrack`, `optimizeStops` | OSRM at routing.openstreetmap.de (car / bike / foot) | run by FOSSGIS for the openstreetmap.org website; demo and fair use only |
| `UMaps.isochrones` | Valhalla at valhalla1.openstreetmap.de | fair use |
| `UMaps.navigate` (rerouting) | same OSRM | |

For production, choose one of:

1. **Offline routing, free with no server** (built into `u`):
   ```dart
   // Once, at build time (or download from your server):
   final graph = UMapRoadGraph.fromOsmXml(xml);   // or fromGeoJson / fromOverpass for small areas
   File("assets/tehran_car.graph").writeAsBytesSync(graph.toBytes());
   // In the app:
   final graph = UMapRoadGraph.fromBytes(bytes);
   final route = graph.route(from, to, persian: true);
   final area  = graph.isochrone(from, const Duration(minutes: 10));
   ```
   It uses A* over OSM roads with speeds per road type, one-way streets and street-name instructions.
   It is good for a city or a province. For a whole country, routes take longer to compute, because
   there are no contraction hierarchies. A country graph is a few tens of MB.
2. **Self-host OSRM** (Docker; one `osrm-extract`/`osrm-contract` run on your Geofabrik extract), then
   `UMaps.useServers(osrmCar: "https://route.yourapp.com")`. A single country runs on a small VPS.
3. **Paid APIs** (GraphHopper, Mapbox Directions, HERE, TomTom). Not wired in. Call them and build a
   `UMapRoute` from the result.

---

## 7. Elevation, hillshade, contours

`UMapTerrain` and `UMaps.elevation` read Terrarium PNG tiles from the AWS Open Data registry. They are
free with no key, and offline packs are allowed. Nothing to do except keep the attribution. To host
them yourself, copy the tiles you need (or build your own from SRTM) and set `UMapTerrain.source`.

---

## 8. Offline maps: what each piece needs

| Piece | How to get it free |
|---|---|
| Base map | your own `.pmtiles` (§3) or `UMapRegionDownload` of a source that allows it |
| Satellite | Sentinel‑2 2016 region download (allowed), or nothing |
| Search | `UMaps.searchIndex()` filled from a GeoJSON of places |
| Routing | `UMapRoadGraph` bundled bytes (§6) |
| Elevation | `UMapRegionDownload(source: UMapTileSource.terrarium, …)` |
| Everything | `UMaps.offline = true` or `UMap(offlineOnly: true)` stops all network use |

---

## 9. Voice guidance (text-to-speech)

`UMapNavigation.announcements` gives you ready sentences in English or Persian ("In 200 m, turn left
onto…" or "در ۲۰۰ متر، به چپ بپیچید…"). **`u` has no text-to-speech engine yet**, so nothing is spoken.
Options:

- Add a native TTS engine to `u` (free: Android `TextToSpeech`, iOS/macOS `AVSpeechSynthesizer`,
  Windows SAPI, Linux speech-dispatcher, web `speechSynthesis`). This is a separate feature you can ask for.
- Or use any TTS package and `navigation.announcements.listen(tts.speak)`.

Persian voices depend on what the user's device has installed.

---

## 10. Things that are not included, and what they would cost

| Feature | Why not free | Options |
|---|---|---|
| Live traffic colours | needs live speed data from millions of phones | paid: TomTom, HERE, Mapbox Traffic tiles (`UMapTileSource.custom` with their URL). Or collect speeds from your own fleet via `UMapLiveSession` and colour roads with `UMapStyledLine(values:)`. |
| Street View / 360° photos | needs imagery | **Mapillary** is free (CC BY‑SA) with a free token; use their API and show images in a viewer. Google Street View is paid. |
| Lane guidance, junction views | lane data is sparse in OSM | HERE and TomTom (paid) |
| Business hours, phones, websites | partly free | OSM tags come back in `UMapPlace.tags` (`opening_hours`, `phone`, `website`) where mappers added them |
| Reviews, photos, popularity | crowd data | Google Places or Foursquare (paid), or collect your own |
| Photorealistic 3D buildings | photogrammetry | not possible for free; `UMap(tilt:)` gives a 2.5D feel |

---

## 11. Your own backend (required for these)

- **Live shared map / live ETA sharing**: `UMapLiveSession` handles the map side. You provide the
  transport: a WebSocket server, Firebase Realtime Database, Supabase Realtime or MQTT. Pass its
  send function as `send`, and call `receive(json)` with incoming messages. The server cost is yours.
- **Saving users' drawings or tracks to the cloud**: `UMapDrawController.toGeoJson()` and
  `UTrackRecorder.toGpx()` give you the data. Upload it with `UHttpClient`.

---

## 12. Checklist before release

- [ ] `UMaps.setUserAgent(...)` set to your app id
- [ ] No `openStreetMap`, `humanitarian` or `openTopoMap` tiles for heavy traffic. Moved to your own `.pmtiles` or a paid provider.
- [ ] No CARTO presets without a key
- [ ] Esri satellite only with an ArcGIS account (or removed)
- [ ] Search, routing and Overpass point at your own servers, or use the offline engines, if you expect real traffic
- [ ] Attribution visible (`showAttribution: true`)
- [ ] Location permissions added, and background location justified in store review if used
- [ ] Offline region downloads only from sources that allow it (`u` enforces this unless you pass `allowRestricted`)
