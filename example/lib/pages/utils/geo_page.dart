import "package:u/utilities.dart";

import "../../demo/demo.dart";

const LatLng _tehran = LatLng(35.6997, 51.3380);
const LatLng _isfahan = LatLng(32.6546, 51.6680);

const String _gpx = """<?xml version="1.0"?><gpx version="1.1" creator="demo"><wpt lat="35.7" lon="51.4"><name>Start</name></wpt>
<trk><name>Walk</name><trkseg><trkpt lat="35.700" lon="51.400"><ele>1190</ele><time>2026-09-01T08:00:00Z</time></trkpt>
<trkpt lat="35.702" lon="51.402"><ele>1195</ele><time>2026-09-01T08:02:00Z</time></trkpt></trkseg></trk></gpx>""";

const String _kml = """<kml><Document><Style id="r"><LineStyle><color>ff0000ff</color><width>4</width></LineStyle></Style>
<Placemark><name>Route</name><styleUrl>#r</styleUrl><LineString><coordinates>51.40,35.70 51.42,35.71</coordinates></LineString></Placemark></Document></kml>""";

/// UGeo (pure geometry, codes, formats) and UMaps (online services, offline, links, formatting).
class GeoPage extends StatelessWidget {
  const GeoPage({super.key});

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Geo & maps",
    intro: "UGeo works offline on every platform. UMaps online calls use free public servers (Nominatim, Photon, Overpass, OSRM, Valhalla, AWS terrain) — read MAP_SERVICES.md before shipping.",
    children: <Widget>[
      DemoGroup("Distance & direction", <Widget>[
        Fn("UGeo.distance(tehran, isfahan)", () => UGeo.distance(_tehran, _isfahan)),
        Fn("UGeo.vincenty(tehran, isfahan)", () => UGeo.vincenty(_tehran, _isfahan), note: "WGS84 ellipsoid, millimetre accurate"),
        Fn("UGeo.bearing(tehran, isfahan)", () => UGeo.bearing(_tehran, _isfahan)),
        Fn("UGeo.destination(tehran, 1000, 90)", () => UGeo.destination(_tehran, 1000, 90)),
        Fn("UGeo.midpoint(tehran, isfahan)", () => UGeo.midpoint(_tehran, _isfahan)),
        Fn("UGeo.greatCircle(tehran, london).length", () => UGeo.greatCircle(_tehran, const LatLng(51.5, -0.12)).length),
      ]),
      DemoGroup("Shapes & areas", <Widget>[
        Fn("UGeo.area([UGeo.circle(p, 1000)])", () => UGeo.area(<List<LatLng>>[UGeo.circle(_tehran, 1000)]), note: "≈ π km² = 3,141,593 m²"),
        Fn("UGeo.contains([circle], p)", () => UGeo.contains(<List<LatLng>>[UGeo.circle(_tehran, 1000)], UGeo.destination(_tehran, 500, 30))),
        Fn("UGeo.labelPoint([L-shape])", () => UGeo.labelPoint(<List<LatLng>>[const <LatLng>[LatLng(0, 0), LatLng(0, 3), LatLng(1, 3), LatLng(1, 1), LatLng(3, 1), LatLng(3, 0), LatLng(0, 0)]])),
        Fn("UGeo.simplify(circle 360 pts, 20 m).length", () => UGeo.simplify(UGeo.circle(_tehran, 1000, segments: 360), 20).length),
        Fn("UGeo.union([a], [b]) area", () {
          final List<LatLng> a = UGeo.circle(_tehran, 1000);
          final List<LatLng> b = UGeo.circle(UGeo.destination(_tehran, 1000, 90), 1000);
          return UGeo.union(<List<LatLng>>[a], <List<LatLng>>[b]).map(UGeo.area).toList();
        }),
        Fn("UGeo.intersection([a], [b]) area", () {
          final List<LatLng> a = UGeo.circle(_tehran, 1000);
          final List<LatLng> b = UGeo.circle(UGeo.destination(_tehran, 1000, 90), 1000);
          return UGeo.intersection(<List<LatLng>>[a], <List<LatLng>>[b]).map(UGeo.area).toList();
        }),
        Fn("UGeo.bufferLine(path, 100).length", () => UGeo.bufferLine(<LatLng>[_tehran, UGeo.destination(_tehran, 2000, 45)], 100).length),
        Fn("UGeo.convexHull(points)", () => UGeo.convexHull(List<LatLng>.generate(30, (int i) => UGeo.destination(_tehran, 100.0 * (i % 7), i * 37.0))).length),
        Fn("UGeo.voronoi(5 points).length", () => UGeo.voronoi(List<LatLng>.generate(5, (int i) => UGeo.destination(_tehran, 1000, i * 72.0))).length),
        Fn("UGeo.dbscan(points, radius: 300)", () => UGeo.dbscan(<LatLng>[_tehran, UGeo.destination(_tehran, 100, 0), UGeo.destination(_tehran, 200, 0), _isfahan], radius: 300, minPoints: 2)),
        Fn("UGeo.bestOrder(stops, roundTrip: true)", () => UGeo.bestOrder(List<LatLng>.generate(8, (int i) => UGeo.destination(_tehran, 1000, (i * 137) % 360.0)), roundTrip: true)),
      ]),
      DemoGroup("Coordinate codes", <Widget>[
        Fn("UGeo.plusCode(tehran)", () => UGeo.plusCode(_tehran)),
        Fn("UGeo.geohash(tehran)", () => UGeo.geohash(_tehran)),
        Fn("UGeo.toUtm(tehran)", () => UGeo.toUtm(_tehran).toString()),
        Fn("UGeo.toMgrs(tehran)", () => UGeo.toMgrs(_tehran)),
        Fn("UGeo.toDms(tehran, persian: true)", () => UGeo.toDms(_tehran, persian: true)),
        Fn('UGeo.parse("۳۵°۴۱\'۵۹" شمالی…")', () => UGeo.parse("35°41'59\"N 51°20'17\"E")),
        Fn('UGeo.parse("۳۵٫۷، ۵۱٫۴")', () => UGeo.parse("۳۵٫۷، ۵۱٫۴")),
        Fn("UGeo.encodePolyline([…])", () => UGeo.encodePolyline(const <LatLng>[LatLng(38.5, -120.2), LatLng(40.7, -120.95)])),
        Fn("UGeo.tileOf(tehran, 15)", () => UGeo.tileOf(_tehran, 15).toString()),
      ]),
      DemoGroup("File formats", <Widget>[
        Fn("UGeo.readGpx(gpx).tracks.first.points.length", () => UGeo.readGpx(_gpx).tracks.first.points.length),
        Fn("UGeo.readKml(kml).features.first.properties", () => UGeo.readKml(_kml).features.first.properties),
        Fn("UGeo.writeKmz(features).length", () => UGeo.writeKmz(UGeo.readKml(_kml)).length),
        Fn("UGeo.writeGeoJson(UGeo.readKml(kml))", () => UGeo.writeGeoJson(UGeo.readKml(_kml))),
        Fn('UGeo.readWkt("POLYGON ((…))")', () => UGeo.area(<List<LatLng>>[(UGeo.readWkt("POLYGON ((51.40 35.70, 51.41 35.70, 51.41 35.71, 51.40 35.70))")! as UGeoPolygon).outer])),
        Fn("UGeo.readWkbHex(PostGIS point)", () => UGeo.writeWkt(UGeo.readWkbHex("0101000020E6100000000000000000F03F0000000000000040")!)),
        Fn("UGeo.readCsv(\"name,lat,lng…\")", () => UGeo.readCsv("name,lat,lng\nA,35.7,51.4\nB,35.8,51.5").features.length),
      ]),
      DemoGroup("Online services (free servers)", <Widget>[
        Fn('await UMaps.search("Azadi Tower")', () async => (await UMaps.search("Azadi Tower")).map((UMapPlace p) => p.label).toList()),
        Fn('await UMaps.autocomplete("ازادی")', () async => (await UMaps.autocomplete("ازادی", near: _tehran)).map((UMapPlace p) => p.label).toList()),
        Fn("await UMaps.reverse(tehran)", () async => (await UMaps.reverse(_tehran))?.displayName),
        Fn("await UMaps.nearby(tehran, [fuel])", () async => (await UMaps.nearby(_tehran, <UMapPoiCategory>[UMapPoiCategory.fuel])).length),
        Fn("await UMaps.route([tehran, milad])", () async {
          final UMapRoute r = (await UMaps.route(<LatLng>[_tehran, const LatLng(35.7448, 51.3753)])).first;
          return "${UMaps.formatDistance(r.distance)} · ${UMaps.formatDuration(r.duration)} · ${r.steps.length} steps";
        }),
        Fn("await UMaps.snapToRoad(tehran)", () => UMaps.snapToRoad(_tehran)),
        Fn("await UMaps.isochrones(tehran, [10])", () async => (await UMaps.isochrones(_tehran, <int>[10])).map(((int, List<LatLng>) e) => "${e.$1} min: ${UMapFormat.area(UGeo.area(<List<LatLng>>[e.$2]))}").toList()),
        Fn("await UMaps.elevation(Damavand)", () => UMaps.elevation(const LatLng(35.9556, 52.1100)), note: "≈ 5,600 m"),
        Fn("await UMaps.speedLimitAt(p)", () => UMaps.speedLimitAt(const LatLng(35.7570, 51.4060))),
      ]),
      DemoGroup("Links, sharing, formatting", <Widget>[
        Fn("UMaps.link(tehran)", () => UMaps.link(_tehran)),
        Fn('UMaps.parseLink("https://maps.google.com/?q=35.7,51.4")', () => UMaps.parseLink("https://maps.google.com/?q=35.7,51.4")),
        Fn("UMaps.share(tehran, label: 'Azadi')", () => UMaps.share(_tehran, label: "Azadi")),
        Fn("UMaps.openInMapsApp(tehran)", () => UMaps.openInMapsApp(_tehran)),
        Fn("UMaps.formatDistance(1234, persian: true)", () => UMaps.formatDistance(1234, persian: true)),
        Fn("UMaps.formatDuration(135 min, persian: true)", () => UMaps.formatDuration(const Duration(minutes: 135), persian: true)),
        Fn("UMapFormat.instruction('turn', 'left', street: 'ولیعصر', persian: true)", () => UMapFormat.instruction("turn", "left", street: "ولیعصر", persian: true)),
      ]),
      DemoGroup("Offline & cache", <Widget>[
        Fn("UMaps.estimate(sentinel2, Tehran, 10, 15)", () => UMaps.estimate(UMapTileSource.sentinel2, LatLngBounds(const LatLng(35.55, 51.1), const LatLng(35.85, 51.65)), 10, 15)),
        Fn("await UMaps.regions()", () async => (await UMaps.regions()).map((UMapRegion r) => r.name).toList()),
        Fn("await UMaps.cacheSize()", UMaps.cacheSize),
        Fn("await UMaps.clearCache()", UMaps.clearCache),
      ]),
    ],
  );
}
