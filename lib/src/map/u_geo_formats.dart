import "package:u/utilities.dart";

/// GeoJSON read/write (RFC 7946). Use it through [UGeo].
abstract final class UGeoJsonCodec {
  /// Reads a FeatureCollection, a Feature or a bare geometry (text or decoded JSON).
  static UGeoFeatureCollection decode(Object source) {
    final Object? json = source is String ? jsonDecode(source) : source;
    if (json is! Map) return UGeoFeatureCollection();
    final Map<String, dynamic> map = Map<String, dynamic>.from(json);
    switch (map["type"]) {
      case "FeatureCollection":
        return UGeoFeatureCollection(<UGeoFeature>[
          for (final dynamic f in (map["features"] as List<dynamic>? ?? <dynamic>[]))
            if (f is Map) ?featureFromJson(Map<String, dynamic>.from(f)),
        ]);
      case "Feature":
        final UGeoFeature? f = featureFromJson(map);
        return UGeoFeatureCollection(<UGeoFeature>[?f]);
      default:
        final UGeoGeometry? g = geometryFromJson(map);
        return UGeoFeatureCollection(<UGeoFeature>[if (g != null) UGeoFeature(geometry: g)]);
    }
  }

  /// One Feature object, or null when it has no usable geometry.
  static UGeoFeature? featureFromJson(Map<String, dynamic> json) {
    final Object? g = json["geometry"];
    final UGeoGeometry? geometry = g is Map ? geometryFromJson(Map<String, dynamic>.from(g)) : null;
    if (geometry == null) return null;
    final Object? props = json["properties"];
    return UGeoFeature(id: json["id"], geometry: geometry, properties: props is Map ? Map<String, dynamic>.from(props) : <String, dynamic>{});
  }

  static LatLng _pos(dynamic c) {
    final List<dynamic> l = c as List<dynamic>;
    return UGeoMath.safe((l[1] as num).toDouble(), (l[0] as num).toDouble());
  }

  static List<LatLng> _line(dynamic c) => (c as List<dynamic>).map(_pos).toList();

  static List<List<LatLng>> _rings(dynamic c) => (c as List<dynamic>).map(_line).toList();

  /// One geometry object.
  static UGeoGeometry? geometryFromJson(Map<String, dynamic> json) {
    final dynamic c = json["coordinates"];
    try {
      switch (json["type"]) {
        case "Point":
          final List<dynamic> l = c as List<dynamic>;
          return UGeoPoint(_pos(l), altitude: l.length > 2 ? (l[2] as num).toDouble() : null);
        case "MultiPoint":
          return UGeoMultiPoint(_line(c));
        case "LineString":
          final List<dynamic> l = c as List<dynamic>;
          final bool hasZ = l.isNotEmpty && (l.first as List<dynamic>).length > 2;
          return UGeoLine(_line(c), altitudes: hasZ ? l.map((dynamic p) => ((p as List<dynamic>).length > 2 ? (p[2] as num).toDouble() : null)).toList() : null);
        case "MultiLineString":
          return UGeoMultiLine((c as List<dynamic>).map(_line).toList());
        case "Polygon":
          return UGeoPolygon(_rings(c));
        case "MultiPolygon":
          return UGeoMultiPolygon((c as List<dynamic>).map(_rings).toList());
        case "GeometryCollection":
          return UGeoCollection(<UGeoGeometry>[
            for (final dynamic g in (json["geometries"] as List<dynamic>? ?? <dynamic>[]))
              if (g is Map) ?geometryFromJson(Map<String, dynamic>.from(g)),
          ]);
      }
    } on Object {
      return null;
    }
    return null;
  }

  static List<double> _c(LatLng p, [double? alt]) => <double>[p.longitude, p.latitude, ?alt];

  static List<List<double>> _cl(List<LatLng> l) => l.map(_c).toList();

  /// GeoJSON object of a geometry.
  static Map<String, dynamic> geometryToJson(UGeoGeometry g) => switch (g) {
    UGeoPoint() => <String, dynamic>{"type": "Point", "coordinates": _c(g.point, g.altitude)},
    UGeoMultiPoint() => <String, dynamic>{"type": "MultiPoint", "coordinates": _cl(g.points)},
    UGeoLine() => <String, dynamic>{
      "type": "LineString",
      "coordinates": <List<double>>[for (int i = 0; i < g.points.length; i++) _c(g.points[i], g.altitudes != null && i < g.altitudes!.length ? g.altitudes![i] : null)],
    },
    UGeoMultiLine() => <String, dynamic>{"type": "MultiLineString", "coordinates": g.lines.map(_cl).toList()},
    UGeoPolygon() => <String, dynamic>{"type": "Polygon", "coordinates": g.rings.map(_closed).map(_cl).toList()},
    UGeoMultiPolygon() => <String, dynamic>{"type": "MultiPolygon", "coordinates": g.polygons.map((List<List<LatLng>> p) => p.map(_closed).map(_cl).toList()).toList()},
    UGeoCollection() => <String, dynamic>{"type": "GeometryCollection", "geometries": g.geometries.map(geometryToJson).toList()},
  };

  static List<LatLng> _closed(List<LatLng> r) => r.isEmpty || r.first == r.last ? r : <LatLng>[...r, r.first];

  /// GeoJSON Feature object.
  static Map<String, dynamic> featureToJson(UGeoFeature f) => <String, dynamic>{
    "type": "Feature",
    if (f.id != null) "id": f.id,
    "geometry": geometryToJson(f.geometry),
    "properties": f.properties,
  };

  /// GeoJSON text of features.
  static String encode(UGeoFeatureCollection collection, {bool pretty = false}) {
    final Map<String, dynamic> json = <String, dynamic>{"type": "FeatureCollection", "features": collection.features.map(featureToJson).toList()};
    return pretty ? const JsonEncoder.withIndent("  ").convert(json) : jsonEncode(json);
  }
}

/// GPX 1.1 read/write (tracks, routes, waypoints). Use it through [UGeo].
abstract final class UGpxCodec {
  static String _text(UEpubNode? n) => n?.textContent.trim() ?? "";

  static UEpubNode? _child(UEpubNode n, String tag) {
    for (final UEpubNode c in n.children) {
      if (c.tag == tag) return c;
    }
    return null;
  }

  static String? _opt(UEpubNode n, String tag) {
    final String t = _text(_child(n, tag));
    return t.isEmpty ? null : t;
  }

  static UGeoTrackPoint? _point(UEpubNode n) {
    final double? lat = double.tryParse(n.attributes["lat"] ?? "");
    final double? lon = double.tryParse(n.attributes["lon"] ?? "");
    if (lat == null || lon == null) return null;
    final UEpubNode? ext = _child(n, "extensions");
    String? speed = _opt(n, "speed");
    String? course = _opt(n, "course");
    if (ext != null) {
      for (final UEpubNode e in ext.findAll("speed")) {
        speed ??= _text(e);
      }
      for (final UEpubNode e in ext.findAll("course")) {
        course ??= _text(e);
      }
    }
    return UGeoTrackPoint(
      UGeoMath.safe(lat, lon),
      elevation: double.tryParse(_opt(n, "ele") ?? ""),
      time: DateTime.tryParse(_opt(n, "time") ?? ""),
      speed: double.tryParse(speed ?? ""),
      heading: double.tryParse(course ?? ""),
      accuracy: double.tryParse(_opt(n, "hdop") ?? ""),
    );
  }

  /// Reads GPX text.
  static UGpx decode(String xml) {
    final UEpubNode? root = UEpubXml.parse(xml);
    final UEpubNode? gpx = root?.findAll("gpx").firstOrNull;
    if (gpx == null) return UGpx();
    final UEpubNode? meta = _child(gpx, "metadata");
    final List<UGpxWaypoint> waypoints = <UGpxWaypoint>[];
    for (final UEpubNode w in gpx.children.where((UEpubNode c) => c.tag == "wpt")) {
      final UGeoTrackPoint? p = _point(w);
      if (p == null) continue;
      waypoints.add(UGpxWaypoint(p.point, elevation: p.elevation, time: p.time, name: _opt(w, "name"), description: _opt(w, "desc"), symbol: _opt(w, "sym"), type: _opt(w, "type")));
    }
    UGpxPath path(UEpubNode n, List<List<UGeoTrackPoint>> segments) => UGpxPath(name: _opt(n, "name"), description: _opt(n, "desc"), type: _opt(n, "type"), segments: segments);
    final List<UGpxPath> routes = <UGpxPath>[
      for (final UEpubNode r in gpx.children.where((UEpubNode c) => c.tag == "rte"))
        path(r, <List<UGeoTrackPoint>>[
          <UGeoTrackPoint>[for (final UEpubNode p in r.children.where((UEpubNode c) => c.tag == "rtept")) ?_point(p)],
        ]),
    ];
    final List<UGpxPath> tracks = <UGpxPath>[
      for (final UEpubNode t in gpx.children.where((UEpubNode c) => c.tag == "trk"))
        path(t, <List<UGeoTrackPoint>>[
          for (final UEpubNode s in t.children.where((UEpubNode c) => c.tag == "trkseg"))
            <UGeoTrackPoint>[for (final UEpubNode p in s.children.where((UEpubNode c) => c.tag == "trkpt")) ?_point(p)],
        ]),
    ];
    return UGpx(
      name: meta == null ? null : _opt(meta, "name"),
      description: meta == null ? null : _opt(meta, "desc"),
      time: meta == null ? null : DateTime.tryParse(_opt(meta, "time") ?? ""),
      creator: gpx.attributes["creator"] ?? "",
      waypoints: waypoints,
      routes: routes,
      tracks: tracks,
    );
  }

  static String esc(String s) => s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("\"", "&quot;");

  static void _writePoint(StringBuffer b, String tag, LatLng p, {double? ele, DateTime? time, String? name, String? desc, String? sym, String? type, double? speed, double? course, String indent = "  "}) {
    b.write("$indent<$tag lat=\"${p.latitude.toStringAsFixed(7)}\" lon=\"${p.longitude.toStringAsFixed(7)}\">");
    if (ele != null) b.write("<ele>${ele.toStringAsFixed(1)}</ele>");
    if (time != null) b.write("<time>${time.toUtc().toIso8601String()}</time>");
    if (course != null) b.write("<course>${course.toStringAsFixed(1)}</course>");
    if (speed != null) b.write("<speed>${speed.toStringAsFixed(2)}</speed>");
    if (name != null) b.write("<name>${esc(name)}</name>");
    if (desc != null) b.write("<desc>${esc(desc)}</desc>");
    if (sym != null) b.write("<sym>${esc(sym)}</sym>");
    if (type != null) b.write("<type>${esc(type)}</type>");
    b.writeln("</$tag>");
  }

  /// GPX text.
  static String encode(UGpx gpx) {
    final StringBuffer b = StringBuffer()
      ..writeln("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
      ..writeln("<gpx version=\"1.1\" creator=\"${esc(gpx.creator)}\" xmlns=\"http://www.topografix.com/GPX/1/1\">");
    if (gpx.name != null || gpx.description != null || gpx.time != null) {
      b.write("  <metadata>");
      if (gpx.name != null) b.write("<name>${esc(gpx.name!)}</name>");
      if (gpx.description != null) b.write("<desc>${esc(gpx.description!)}</desc>");
      if (gpx.time != null) b.write("<time>${gpx.time!.toUtc().toIso8601String()}</time>");
      b.writeln("</metadata>");
    }
    for (final UGpxWaypoint w in gpx.waypoints) {
      _writePoint(b, "wpt", w.point, ele: w.elevation, time: w.time, name: w.name, desc: w.description, sym: w.symbol, type: w.type);
    }
    for (final UGpxPath r in gpx.routes) {
      b.write("  <rte>");
      if (r.name != null) b.write("<name>${esc(r.name!)}</name>");
      b.writeln();
      for (final UGeoTrackPoint p in r.points) {
        _writePoint(b, "rtept", p.point, ele: p.elevation, time: p.time, indent: "    ");
      }
      b.writeln("  </rte>");
    }
    for (final UGpxPath t in gpx.tracks) {
      b.write("  <trk>");
      if (t.name != null) b.write("<name>${esc(t.name!)}</name>");
      if (t.type != null) b.write("<type>${esc(t.type!)}</type>");
      b.writeln();
      for (final List<UGeoTrackPoint> s in t.segments) {
        b.writeln("    <trkseg>");
        for (final UGeoTrackPoint p in s) {
          _writePoint(b, "trkpt", p.point, ele: p.elevation, time: p.time, speed: p.speed, course: p.heading, indent: "      ");
        }
        b.writeln("    </trkseg>");
      }
      b.writeln("  </trk>");
    }
    b.writeln("</gpx>");
    return b.toString();
  }

  /// GPX as map features: waypoints become points, routes and tracks become lines.
  static UGeoFeatureCollection toFeatures(UGpx gpx) => UGeoFeatureCollection(<UGeoFeature>[
    for (final UGpxWaypoint w in gpx.waypoints) UGeoFeature(geometry: UGeoPoint(w.point, altitude: w.elevation), properties: <String, dynamic>{"name": ?w.name, "description": ?w.description, "kind": "waypoint"}),
    for (final UGpxPath r in gpx.routes) UGeoFeature(geometry: UGeoLine(r.points.map((UGeoTrackPoint p) => p.point).toList()), properties: <String, dynamic>{"name": ?r.name, "kind": "route"}),
    for (final UGpxPath t in gpx.tracks)
      for (final List<UGeoTrackPoint> s in t.segments)
        UGeoFeature(
          geometry: UGeoLine(s.map((UGeoTrackPoint p) => p.point).toList(), altitudes: s.map((UGeoTrackPoint p) => p.elevation).toList()),
          properties: <String, dynamic>{"name": ?t.name, "kind": "track"},
        ),
  ]);
}

/// KML/KMZ read/write with styles mapped to simplestyle properties (stroke, fill, marker-color…). Use it through [UGeo].
abstract final class UKmlCodec {
  static String _text(UEpubNode? n) => n?.textContent.trim() ?? "";

  static UEpubNode? _child(UEpubNode n, String tag) => n.children.where((UEpubNode c) => c.tag == tag).firstOrNull;

  static List<LatLng> _coords(String text) {
    final List<LatLng> out = <LatLng>[];
    for (final String tuple in text.trim().split(RegExp(r"\s+"))) {
      final List<String> parts = tuple.split(",");
      if (parts.length < 2) continue;
      final double? lng = double.tryParse(parts[0]);
      final double? lat = double.tryParse(parts[1]);
      if (lat != null && lng != null) out.add(UGeoMath.safe(lat, lng));
    }
    return out;
  }

  /// KML colour (aabbggrr) as (#rrggbb, opacity).
  static (String, double) _color(String kml) {
    final String c = kml.trim().replaceAll("#", "");
    if (c.length != 8) return ("#3388ff", 1);
    final int a = int.tryParse(c.substring(0, 2), radix: 16) ?? 255;
    return ("#${c.substring(6, 8)}${c.substring(4, 6)}${c.substring(2, 4)}", a / 255);
  }

  static String _kmlColor(String? hex, double? opacity) {
    final String h = (hex ?? "#3388ff").replaceAll("#", "").padLeft(6, "0");
    final String a = ((opacity ?? 1) * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, "0");
    return "$a${h.substring(4, 6)}${h.substring(2, 4)}${h.substring(0, 2)}";
  }

  static Map<String, dynamic> _style(UEpubNode style) {
    final Map<String, dynamic> p = <String, dynamic>{};
    final UEpubNode? line = _child(style, "linestyle");
    if (line != null) {
      final String color = _text(_child(line, "color"));
      if (color.isNotEmpty) {
        final (String hex, double op) = _color(color);
        p["stroke"] = hex;
        p["stroke-opacity"] = op;
      }
      final double? w = double.tryParse(_text(_child(line, "width")));
      if (w != null) p["stroke-width"] = w;
    }
    final UEpubNode? poly = _child(style, "polystyle");
    if (poly != null) {
      final String color = _text(_child(poly, "color"));
      if (color.isNotEmpty) {
        final (String hex, double op) = _color(color);
        p["fill"] = hex;
        p["fill-opacity"] = op;
      }
      if (_text(_child(poly, "fill")) == "0") p["fill-opacity"] = 0.0;
    }
    final UEpubNode? icon = _child(style, "iconstyle");
    if (icon != null) {
      final String color = _text(_child(icon, "color"));
      if (color.isNotEmpty) p["marker-color"] = _color(color).$1;
      final UEpubNode? i = _child(icon, "icon");
      final String href = i == null ? "" : _text(_child(i, "href"));
      if (href.isNotEmpty) p["icon"] = href;
    }
    return p;
  }

  static UGeoGeometry? _geometry(UEpubNode n) {
    switch (n.tag) {
      case "point":
        final List<LatLng> c = _coords(_text(_child(n, "coordinates")));
        return c.isEmpty ? null : UGeoPoint(c.first);
      case "linestring":
        return UGeoLine(_coords(_text(_child(n, "coordinates"))));
      case "linearring":
        return UGeoPolygon.simple(_coords(_text(_child(n, "coordinates"))));
      case "polygon":
        final List<List<LatLng>> rings = <List<LatLng>>[];
        for (final UEpubNode b in n.children.where((UEpubNode c) => c.tag == "outerboundaryis")) {
          rings.insert(0, _coords(_text(b.findAll("coordinates").firstOrNull)));
        }
        for (final UEpubNode b in n.children.where((UEpubNode c) => c.tag == "innerboundaryis")) {
          for (final UEpubNode ring in b.findAll("coordinates")) {
            rings.add(_coords(_text(ring)));
          }
        }
        return rings.isEmpty ? null : UGeoPolygon(rings);
      case "track":
        final List<LatLng> pts = <LatLng>[];
        for (final UEpubNode c in n.children.where((UEpubNode c) => c.tag == "coord")) {
          final List<double> v = _text(c).split(RegExp(r"\s+")).map((String s) => double.tryParse(s) ?? double.nan).toList();
          if (v.length >= 2 && !v[0].isNaN && !v[1].isNaN) pts.add(UGeoMath.safe(v[1], v[0]));
        }
        return UGeoLine(pts);
      case "multigeometry":
      case "multitrack":
        final List<UGeoGeometry> parts = <UGeoGeometry>[for (final UEpubNode c in n.children) ?_geometry(c)];
        return parts.isEmpty ? null : UGeoCollection(parts);
    }
    return null;
  }

  /// Reads KML text: placemarks with name, description, ExtendedData, folder and style.
  static UGeoFeatureCollection decode(String xml) {
    final UEpubNode? root = UEpubXml.parse(xml);
    if (root == null) return UGeoFeatureCollection();
    final Map<String, Map<String, dynamic>> styles = <String, Map<String, dynamic>>{};
    for (final UEpubNode s in root.findAll("style")) {
      if (s.id.isNotEmpty) styles[s.id] = _style(s);
    }
    for (final UEpubNode m in root.findAll("stylemap")) {
      for (final UEpubNode pair in m.findAll("pair")) {
        if (_text(_child(pair, "key")) == "normal") {
          final String url = _text(_child(pair, "styleurl")).replaceAll("#", "");
          if (styles.containsKey(url)) styles[m.id] = styles[url]!;
        }
      }
    }
    final List<UGeoFeature> features = <UGeoFeature>[];
    for (final UEpubNode pm in root.findAll("placemark")) {
      UGeoGeometry? geometry;
      for (final UEpubNode c in pm.children) {
        geometry ??= _geometry(c);
      }
      if (geometry == null) continue;
      final Map<String, dynamic> props = <String, dynamic>{};
      final String name = _text(_child(pm, "name"));
      if (name.isNotEmpty) props["name"] = name;
      final String desc = _text(_child(pm, "description"));
      if (desc.isNotEmpty) props["description"] = desc;
      final String styleUrl = _text(_child(pm, "styleurl")).replaceAll("#", "");
      if (styles.containsKey(styleUrl)) props.addAll(styles[styleUrl]!);
      final UEpubNode? inline = _child(pm, "style");
      if (inline != null) props.addAll(_style(inline));
      for (final UEpubNode d in pm.findAll("data")) {
        props[d.attributes["name"] ?? ""] = _text(_child(d, "value"));
      }
      for (final UEpubNode d in pm.findAll("simpledata")) {
        props[d.attributes["name"] ?? ""] = _text(d);
      }
      UEpubNode? parent = pm.parent;
      while (parent != null && parent.tag != "folder") {
        parent = parent.parent;
      }
      if (parent != null) props["folder"] = _text(_child(parent, "name"));
      features.add(UGeoFeature(id: pm.id.isEmpty ? null : pm.id, geometry: geometry, properties: props));
    }
    return UGeoFeatureCollection(features);
  }

  /// Reads a KMZ (zipped KML) file's bytes.
  static Future<UGeoFeatureCollection> decodeKmz(Uint8List bytes) async {
    final UEpubArchive zip = await UEpubArchive.open(UCachedByteSource(UMemoryByteSource(bytes)));
    final List<String> names = zip.entries.keys.where((String n) => n.toLowerCase().endsWith(".kml")).toList()
      ..sort((String a, String b) => (a.toLowerCase() == "doc.kml" ? 0 : 1).compareTo(b.toLowerCase() == "doc.kml" ? 0 : 1));
    if (names.isEmpty) return UGeoFeatureCollection();
    return decode(await zip.readText(names.first));
  }

  static String _coordText(List<LatLng> pts) => pts.map((LatLng p) => "${p.longitude.toStringAsFixed(7)},${p.latitude.toStringAsFixed(7)}").join(" ");

  static void _writeGeometry(StringBuffer b, UGeoGeometry g) {
    switch (g) {
      case UGeoPoint():
        b.write("<Point><coordinates>${_coordText(<LatLng>[g.point])}</coordinates></Point>");
      case UGeoMultiPoint():
        b.write("<MultiGeometry>");
        for (final LatLng p in g.points) {
          b.write("<Point><coordinates>${_coordText(<LatLng>[p])}</coordinates></Point>");
        }
        b.write("</MultiGeometry>");
      case UGeoLine():
        b.write("<LineString><tessellate>1</tessellate><coordinates>${_coordText(g.points)}</coordinates></LineString>");
      case UGeoMultiLine():
        b.write("<MultiGeometry>");
        for (final List<LatLng> l in g.lines) {
          _writeGeometry(b, UGeoLine(l));
        }
        b.write("</MultiGeometry>");
      case UGeoPolygon():
        b.write("<Polygon>");
        for (int i = 0; i < g.rings.length; i++) {
          final List<LatLng> r = g.rings[i].isNotEmpty && g.rings[i].first != g.rings[i].last ? <LatLng>[...g.rings[i], g.rings[i].first] : g.rings[i];
          final String tag = i == 0 ? "outerBoundaryIs" : "innerBoundaryIs";
          b.write("<$tag><LinearRing><coordinates>${_coordText(r)}</coordinates></LinearRing></$tag>");
        }
        b.write("</Polygon>");
      case UGeoMultiPolygon():
        b.write("<MultiGeometry>");
        for (final List<List<LatLng>> p in g.polygons) {
          _writeGeometry(b, UGeoPolygon(p));
        }
        b.write("</MultiGeometry>");
      case UGeoCollection():
        b.write("<MultiGeometry>");
        for (final UGeoGeometry x in g.geometries) {
          _writeGeometry(b, x);
        }
        b.write("</MultiGeometry>");
    }
  }

  /// KML text of features (simplestyle properties become KML styles).
  static String encode(UGeoFeatureCollection collection, {String name = "u map"}) {
    final StringBuffer b = StringBuffer()
      ..writeln("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
      ..writeln("<kml xmlns=\"http://www.opengis.net/kml/2.2\"><Document><name>${UGpxCodec.esc(name)}</name>");
    for (final UGeoFeature f in collection.features) {
      final Map<String, dynamic> p = f.properties;
      b.write("<Placemark>");
      if (f.name != null) b.write("<name>${UGpxCodec.esc(f.name!)}</name>");
      if (p["description"] != null) b.write("<description>${UGpxCodec.esc("${p["description"]}")}</description>");
      b.write("<Style>");
      b.write("<LineStyle><color>${_kmlColor(p["stroke"]?.toString(), (p["stroke-opacity"] as num?)?.toDouble())}</color><width>${(p["stroke-width"] as num?) ?? 2}</width></LineStyle>");
      b.write("<PolyStyle><color>${_kmlColor(p["fill"]?.toString() ?? p["stroke"]?.toString(), (p["fill-opacity"] as num?)?.toDouble() ?? 0.3)}</color></PolyStyle>");
      if (p["marker-color"] != null) b.write("<IconStyle><color>${_kmlColor(p["marker-color"].toString(), 1)}</color></IconStyle>");
      b.write("</Style>");
      final Iterable<MapEntry<String, dynamic>> extra = p.entries.where((MapEntry<String, dynamic> e) => !_styleKeys.contains(e.key));
      if (extra.isNotEmpty) {
        b.write("<ExtendedData>");
        for (final MapEntry<String, dynamic> e in extra) {
          b.write("<Data name=\"${UGpxCodec.esc(e.key)}\"><value>${UGpxCodec.esc("${e.value}")}</value></Data>");
        }
        b.write("</ExtendedData>");
      }
      _writeGeometry(b, f.geometry);
      b.writeln("</Placemark>");
    }
    b.writeln("</Document></kml>");
    return b.toString();
  }

  static const Set<String> _styleKeys = <String>{"name", "description", "stroke", "stroke-opacity", "stroke-width", "fill", "fill-opacity", "marker-color", "icon"};

  /// KMZ bytes (zip with doc.kml, stored) of features.
  static Uint8List encodeKmz(UGeoFeatureCollection collection, {String name = "u map"}) => UZipWriter.store(<String, Uint8List>{"doc.kml": utf8.encode(encode(collection, name: name))});
}

/// Minimal zip writer (stored entries, CRC-32) used for KMZ export.
abstract final class UZipWriter {
  static final List<int> _table = List<int>.generate(256, (int n) {
    int c = n;
    for (int k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });

  /// CRC-32 of bytes.
  static int crc32(List<int> bytes) {
    int c = 0xFFFFFFFF;
    for (final int b in bytes) {
      c = _table[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  /// Zip file bytes with every entry stored uncompressed.
  static Uint8List store(Map<String, Uint8List> files) {
    final BytesBuilder out = BytesBuilder();
    final BytesBuilder central = BytesBuilder();
    void u16(BytesBuilder b, int v) => b.add(<int>[v & 0xFF, (v >> 8) & 0xFF]);
    void u32(BytesBuilder b, int v) => b.add(<int>[v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
    for (final MapEntry<String, Uint8List> f in files.entries) {
      final List<int> name = utf8.encode(f.key);
      final int crc = crc32(f.value);
      final int offset = out.length;
      u32(out, 0x04034b50);
      u16(out, 20);
      u16(out, 0x0800);
      u16(out, 0);
      u16(out, 0);
      u16(out, 0x21);
      u32(out, crc);
      u32(out, f.value.length);
      u32(out, f.value.length);
      u16(out, name.length);
      u16(out, 0);
      out
        ..add(name)
        ..add(f.value);
      u32(central, 0x02014b50);
      u16(central, 20);
      u16(central, 20);
      u16(central, 0x0800);
      u16(central, 0);
      u16(central, 0);
      u16(central, 0x21);
      u32(central, crc);
      u32(central, f.value.length);
      u32(central, f.value.length);
      u16(central, name.length);
      u16(central, 0);
      u16(central, 0);
      u16(central, 0);
      u16(central, 0);
      u32(central, 0);
      u32(central, offset);
      central.add(name);
    }
    final int centralOffset = out.length;
    final Uint8List dir = central.takeBytes();
    out.add(dir);
    u32(out, 0x06054b50);
    u16(out, 0);
    u16(out, 0);
    u16(out, files.length);
    u16(out, files.length);
    u32(out, dir.length);
    u32(out, centralOffset);
    u16(out, 0);
    return out.takeBytes();
  }
}

/// WKT (well-known text) read/write. Use it through [UGeo].
abstract final class UWktCodec {
  /// Geometry of a WKT text such as "POINT (51.4 35.7)" (x = longitude), or null.
  static UGeoGeometry? decode(String wkt) {
    final _WktReader r = _WktReader(wkt.trim().toUpperCase().replaceFirst(RegExp(r"^SRID=\d+;"), ""));
    try {
      return r.geometry();
    } on Object {
      return null;
    }
  }

  static String _pt(LatLng p) => "${_num(p.longitude)} ${_num(p.latitude)}";

  static String _num(double v) {
    final String s = v.toStringAsFixed(8);
    return s.contains(".") ? s.replaceFirst(RegExp(r"0+$"), "").replaceFirst(RegExp(r"\.$"), "") : s;
  }

  static String _list(List<LatLng> l) => "(${l.map(_pt).join(", ")})";

  static String _rings(List<List<LatLng>> r) => "(${r.map((List<LatLng> ring) => _list(ring.isNotEmpty && ring.first != ring.last ? <LatLng>[...ring, ring.first] : ring)).join(", ")})";

  /// WKT text of a geometry.
  static String encode(UGeoGeometry g) => switch (g) {
    UGeoPoint() => "POINT (${_pt(g.point)})",
    UGeoMultiPoint() => g.points.isEmpty ? "MULTIPOINT EMPTY" : "MULTIPOINT (${g.points.map((LatLng p) => "(${_pt(p)})").join(", ")})",
    UGeoLine() => g.points.isEmpty ? "LINESTRING EMPTY" : "LINESTRING ${_list(g.points)}",
    UGeoMultiLine() => "MULTILINESTRING (${g.lines.map(_list).join(", ")})",
    UGeoPolygon() => g.rings.isEmpty ? "POLYGON EMPTY" : "POLYGON ${_rings(g.rings)}",
    UGeoMultiPolygon() => "MULTIPOLYGON (${g.polygons.map(_rings).join(", ")})",
    UGeoCollection() => "GEOMETRYCOLLECTION (${g.geometries.map(encode).join(", ")})",
  };
}

class _WktReader {
  _WktReader(this.s);

  final String s;
  int i = 0;

  void _ws() {
    while (i < s.length && " \t\r\n".contains(s[i])) {
      i++;
    }
  }

  String _word() {
    _ws();
    final int start = i;
    while (i < s.length && RegExp("[A-Z]").hasMatch(s[i])) {
      i++;
    }
    return s.substring(start, i);
  }

  bool _peek(String c) {
    _ws();
    return i < s.length && s[i] == c;
  }

  void _expect(String c) {
    _ws();
    if (i >= s.length || s[i] != c) throw FormatException("Expected $c at $i");
    i++;
  }

  double _number() {
    _ws();
    final int start = i;
    while (i < s.length && RegExp("[-+0-9.E]").hasMatch(s[i])) {
      i++;
    }
    return double.parse(s.substring(start, i));
  }

  LatLng _point() {
    final double x = _number();
    final double y = _number();
    while (!_peek(",") && !_peek(")")) {
      _number();
    }
    return UGeoMath.safe(y, x);
  }

  List<LatLng> _points() {
    _expect("(");
    final List<LatLng> out = <LatLng>[];
    do {
      if (_peek(",")) i++;
      if (_peek("(")) {
        i++;
        out.add(_point());
        _expect(")");
      } else {
        out.add(_point());
      }
    } while (_peek(","));
    _expect(")");
    return out;
  }

  List<List<LatLng>> _lists() {
    _expect("(");
    final List<List<LatLng>> out = <List<LatLng>>[];
    do {
      if (_peek(",")) i++;
      out.add(_points());
    } while (_peek(","));
    _expect(")");
    return out;
  }

  bool _empty() {
    final int save = i;
    if (_word() == "EMPTY") return true;
    i = save;
    return false;
  }

  UGeoGeometry geometry() {
    final String type = _word();
    String dims = _word();
    if (dims != "Z" && dims != "M" && dims != "ZM") {
      i -= dims.length;
      dims = "";
    }
    if (_empty()) {
      return switch (type) {
        "POINT" || "MULTIPOINT" => const UGeoMultiPoint(<LatLng>[]),
        "LINESTRING" => const UGeoLine(<LatLng>[]),
        "POLYGON" => const UGeoPolygon(<List<LatLng>>[]),
        _ => const UGeoCollection(<UGeoGeometry>[]),
      };
    }
    switch (type) {
      case "POINT":
        _expect("(");
        final LatLng p = _point();
        _expect(")");
        return UGeoPoint(p);
      case "MULTIPOINT":
        return UGeoMultiPoint(_points());
      case "LINESTRING":
        return UGeoLine(_points());
      case "MULTILINESTRING":
        return UGeoMultiLine(_lists());
      case "POLYGON":
        return UGeoPolygon(_lists());
      case "MULTIPOLYGON":
        _expect("(");
        final List<List<List<LatLng>>> polys = <List<List<LatLng>>>[];
        do {
          if (_peek(",")) i++;
          polys.add(_lists());
        } while (_peek(","));
        _expect(")");
        return UGeoMultiPolygon(polys);
      case "GEOMETRYCOLLECTION":
        _expect("(");
        final List<UGeoGeometry> parts = <UGeoGeometry>[];
        do {
          if (_peek(",")) i++;
          parts.add(geometry());
        } while (_peek(","));
        _expect(")");
        return UGeoCollection(parts);
    }
    throw FormatException("Unknown WKT type $type");
  }
}

/// WKB (well-known binary, ISO and PostGIS EWKB) read/write. Use it through [UGeo].
abstract final class UWkbCodec {
  /// Geometry of WKB bytes, or null.
  static UGeoGeometry? decode(Uint8List bytes) {
    try {
      return _WkbReader(ByteData.sublistView(bytes)).geometry();
    } on Object {
      return null;
    }
  }

  /// Hex WKB text (as PostGIS prints it) to a geometry.
  static UGeoGeometry? decodeHex(String hex) {
    final String h = hex.trim();
    if (h.length.isOdd) return null;
    return decode(Uint8List.fromList(<int>[for (int i = 0; i < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16)]));
  }

  /// Little-endian 2-D WKB bytes of a geometry.
  static Uint8List encode(UGeoGeometry g) {
    final BytesBuilder b = BytesBuilder();
    _write(b, g);
    return b.takeBytes();
  }

  static void _u32(BytesBuilder b, int v) => b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());

  static void _pt(BytesBuilder b, LatLng p) {
    final ByteData d = ByteData(16)
      ..setFloat64(0, p.longitude, Endian.little)
      ..setFloat64(8, p.latitude, Endian.little);
    b.add(d.buffer.asUint8List());
  }

  static void _list(BytesBuilder b, List<LatLng> l) {
    _u32(b, l.length);
    for (final LatLng p in l) {
      _pt(b, p);
    }
  }

  static void _write(BytesBuilder b, UGeoGeometry g) {
    b.addByte(1);
    switch (g) {
      case UGeoPoint():
        _u32(b, 1);
        _pt(b, g.point);
      case UGeoLine():
        _u32(b, 2);
        _list(b, g.points);
      case UGeoPolygon():
        _u32(b, 3);
        _u32(b, g.rings.length);
        for (final List<LatLng> r in g.rings) {
          _list(b, r);
        }
      case UGeoMultiPoint():
        _u32(b, 4);
        _u32(b, g.points.length);
        for (final LatLng p in g.points) {
          _write(b, UGeoPoint(p));
        }
      case UGeoMultiLine():
        _u32(b, 5);
        _u32(b, g.lines.length);
        for (final List<LatLng> l in g.lines) {
          _write(b, UGeoLine(l));
        }
      case UGeoMultiPolygon():
        _u32(b, 6);
        _u32(b, g.polygons.length);
        for (final List<List<LatLng>> p in g.polygons) {
          _write(b, UGeoPolygon(p));
        }
      case UGeoCollection():
        _u32(b, 7);
        _u32(b, g.geometries.length);
        for (final UGeoGeometry x in g.geometries) {
          _write(b, x);
        }
    }
  }
}

class _WkbReader {
  _WkbReader(this.d);

  final ByteData d;
  int o = 0;

  UGeoGeometry geometry() {
    final Endian e = d.getUint8(o++) == 1 ? Endian.little : Endian.big;
    int type = d.getUint32(o, e);
    o += 4;
    bool z = false;
    bool m = false;
    if (type & 0x80000000 != 0) z = true;
    if (type & 0x40000000 != 0) m = true;
    if (type & 0x20000000 != 0) o += 4;
    type &= 0x0FFFFFFF;
    if (type >= 3000) {
      z = true;
      m = true;
      type -= 3000;
    } else if (type >= 2000) {
      m = true;
      type -= 2000;
    } else if (type >= 1000) {
      z = true;
      type -= 1000;
    }
    final int extra = (z ? 1 : 0) + (m ? 1 : 0);
    LatLng pt() {
      final double x = d.getFloat64(o, e);
      final double y = d.getFloat64(o + 8, e);
      o += 16 + 8 * extra;
      return UGeoMath.safe(y, x);
    }

    int count() {
      final int n = d.getUint32(o, e);
      o += 4;
      return n;
    }

    List<LatLng> list() => List<LatLng>.generate(count(), (_) => pt());
    switch (type) {
      case 1:
        return UGeoPoint(pt());
      case 2:
        return UGeoLine(list());
      case 3:
        return UGeoPolygon(List<List<LatLng>>.generate(count(), (_) => list()));
      case 4:
        return UGeoMultiPoint(List<LatLng>.generate(count(), (_) => (geometry() as UGeoPoint).point));
      case 5:
        return UGeoMultiLine(List<List<LatLng>>.generate(count(), (_) => (geometry() as UGeoLine).points));
      case 6:
        return UGeoMultiPolygon(List<List<List<LatLng>>>.generate(count(), (_) => (geometry() as UGeoPolygon).rings));
      case 7:
        return UGeoCollection(List<UGeoGeometry>.generate(count(), (_) => geometry()));
    }
    throw FormatException("Unknown WKB type $type");
  }
}

/// CSV with latitude/longitude columns ↔ point features. Use it through [UGeo].
abstract final class UGeoCsvCodec {
  static const List<String> _latNames = <String>["lat", "latitude", "y", "عرض", "عرض جغرافیایی", "lat_deg"];
  static const List<String> _lngNames = <String>["lng", "lon", "long", "longitude", "x", "طول", "طول جغرافیایی", "lon_deg"];

  /// Rows of CSV text (quotes, escaped quotes and newlines in quotes supported; delimiter auto-detected).
  static List<List<String>> rows(String text, {String? delimiter}) {
    final String d = delimiter ?? _detect(text);
    final List<List<String>> out = <List<String>>[];
    List<String> row = <String>[];
    final StringBuffer cell = StringBuffer();
    bool quoted = false;
    for (int i = 0; i < text.length; i++) {
      final String c = text[i];
      if (quoted) {
        if (c == "\"") {
          if (i + 1 < text.length && text[i + 1] == "\"") {
            cell.write("\"");
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(c);
        }
      } else if (c == "\"") {
        quoted = true;
      } else if (c == d) {
        row.add(cell.toString());
        cell.clear();
      } else if (c == "\n" || c == "\r") {
        if (c == "\r" && i + 1 < text.length && text[i + 1] == "\n") i++;
        row.add(cell.toString());
        cell.clear();
        if (row.any((String v) => v.isNotEmpty)) out.add(row);
        row = <String>[];
      } else {
        cell.write(c);
      }
    }
    row.add(cell.toString());
    if (row.any((String v) => v.isNotEmpty)) out.add(row);
    return out;
  }

  static String _detect(String text) {
    final String first = text.split("\n").first;
    final Map<String, int> counts = <String, int>{for (final String d in <String>[",", ";", "\t", "|"]) d: d.allMatches(first).length};
    return counts.entries.reduce((MapEntry<String, int> a, MapEntry<String, int> b) => b.value > a.value ? b : a).key;
  }

  /// Point features from CSV text; latitude/longitude columns are found by name (lat, latitude, y, عرض…) unless given.
  static UGeoFeatureCollection decode(String text, {String? latColumn, String? lngColumn, String? delimiter}) {
    final List<List<String>> all = rows(text, delimiter: delimiter);
    if (all.length < 2) return UGeoFeatureCollection();
    final List<String> header = all.first.map((String h) => h.trim()).toList();
    final List<String> lower = header.map((String h) => h.toLowerCase()).toList();
    final int latIndex = latColumn != null ? header.indexOf(latColumn) : lower.indexWhere(_latNames.contains);
    final int lngIndex = lngColumn != null ? header.indexOf(lngColumn) : lower.indexWhere(_lngNames.contains);
    final List<UGeoFeature> out = <UGeoFeature>[];
    for (final List<String> row in all.skip(1)) {
      LatLng? p;
      if (latIndex >= 0 && lngIndex >= 0 && latIndex < row.length && lngIndex < row.length) {
        final double? lat = double.tryParse(row[latIndex].trim());
        final double? lng = double.tryParse(row[lngIndex].trim());
        if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) p = LatLng(lat, lng);
      } else {
        p = row.map(UGeoCodes.parse).whereType<LatLng>().firstOrNull;
      }
      if (p == null) continue;
      out.add(UGeoFeature(geometry: UGeoPoint(p), properties: <String, dynamic>{for (int i = 0; i < header.length && i < row.length; i++) if (i != latIndex && i != lngIndex) header[i]: row[i]}));
    }
    return UGeoFeatureCollection(out);
  }

  /// CSV text of features (points use their location; other shapes their centre), with every property as a column.
  static String encode(UGeoFeatureCollection collection) {
    final List<String> keys = <String>{for (final UGeoFeature f in collection.features) ...f.properties.keys}.toList();
    String q(Object? v) {
      final String s = v?.toString() ?? "";
      return s.contains(RegExp("[\",\n]")) ? "\"${s.replaceAll("\"", "\"\"")}\"" : s;
    }

    final StringBuffer b = StringBuffer()..writeln(<String>["latitude", "longitude", ...keys].map(q).join(","));
    for (final UGeoFeature f in collection.features) {
      final LatLng p = f.geometry is UGeoPoint ? (f.geometry as UGeoPoint).point : UGeoMath.centroid(f.geometry.coordinates.toList());
      b.writeln(<Object?>[p.latitude, p.longitude, ...keys.map((String k) => f.properties[k])].map(q).join(","));
    }
    return b.toString();
  }
}
