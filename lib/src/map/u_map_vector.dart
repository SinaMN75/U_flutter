import "dart:math" as math;
import "dart:ui" as ui;

import "package:u/utilities.dart";

// ================================================================================================ MVT decoding

/// One feature of a vector tile: geometry in tile units (0..extent), type 1 point / 2 line / 3 polygon, and properties.
class UMvtFeature {
  const UMvtFeature(this.type, this.geometry, this.properties, this.id);

  final int type;
  final List<List<Offset>> geometry;
  final Map<String, Object?> properties;
  final int? id;

  /// "Point", "LineString" or "Polygon" (style-spec names).
  String get typeName => type == 1 ? "Point" : (type == 2 ? "LineString" : "Polygon");
}

/// One layer of a vector tile (e.g. "water", "transportation").
class UMvtLayer {
  const UMvtLayer(this.name, this.extent, this.features);

  final String name;
  final int extent;
  final List<UMvtFeature> features;
}

/// A decoded Mapbox Vector Tile.
class UMvtTile {
  const UMvtTile(this.layers);

  final Map<String, UMvtLayer> layers;

  /// Rough memory use, for caches.
  int get weight => layers.values.fold<int>(0, (int s, UMvtLayer l) => s + l.features.fold<int>(64, (int t, UMvtFeature f) => t + 48 + f.geometry.fold<int>(0, (int u, List<Offset> r) => u + r.length * 16)));
}

/// Pure-Dart protobuf decoder for Mapbox Vector Tiles (spec v2).
abstract final class UMvtDecoder {
  /// Decodes tile bytes (gzip is detected and inflated).
  static UMvtTile decode(Uint8List raw) {
    final Uint8List bytes = UMapTiles.gunzip(raw);
    final _Pbf p = _Pbf(bytes);
    final Map<String, UMvtLayer> layers = <String, UMvtLayer>{};
    while (p.pos < p.end) {
      final int tag = p.varint();
      if (tag >> 3 == 3 && tag & 7 == 2) {
        final int len = p.varint();
        final UMvtLayer layer = _layer(_Pbf(bytes, p.pos, p.pos + len));
        layers[layer.name] = layer;
        p.pos += len;
      } else {
        p.skip(tag & 7);
      }
    }
    return UMvtTile(layers);
  }

  static UMvtLayer _layer(_Pbf p) {
    String name = "";
    int extent = 4096;
    final List<String> keys = <String>[];
    final List<Object?> values = <Object?>[];
    final List<(int, int)> featureRanges = <(int, int)>[];
    while (p.pos < p.end) {
      final int tag = p.varint();
      switch (tag >> 3) {
        case 1:
          name = p.string();
        case 2:
          final int len = p.varint();
          featureRanges.add((p.pos, p.pos + len));
          p.pos += len;
        case 3:
          keys.add(p.string());
        case 4:
          final int len = p.varint();
          values.add(_value(_Pbf(p.bytes, p.pos, p.pos + len)));
          p.pos += len;
        case 5:
          extent = p.varint();
        default:
          p.skip(tag & 7);
      }
    }
    final List<UMvtFeature> features = <UMvtFeature>[for (final (int s, int e) in featureRanges) _feature(_Pbf(p.bytes, s, e), keys, values)];
    return UMvtLayer(name, extent, features);
  }

  static Object? _value(_Pbf p) {
    Object? v;
    while (p.pos < p.end) {
      final int tag = p.varint();
      switch (tag >> 3) {
        case 1:
          v = p.string();
        case 2:
          v = p.float32();
        case 3:
          v = p.float64();
        case 4:
        case 5:
          v = p.varint();
        case 6:
          final int z = p.varint();
          v = (z >> 1) ^ -(z & 1);
        case 7:
          v = p.varint() != 0;
        default:
          p.skip(tag & 7);
      }
    }
    return v;
  }

  static UMvtFeature _feature(_Pbf p, List<String> keys, List<Object?> values) {
    int? id;
    int type = 0;
    final Map<String, Object?> props = <String, Object?>{};
    List<int> geometry = const <int>[];
    while (p.pos < p.end) {
      final int tag = p.varint();
      switch (tag >> 3) {
        case 1:
          id = p.varint();
        case 2:
          final List<int> tags = p.packed();
          for (int i = 0; i + 1 < tags.length; i += 2) {
            if (tags[i] < keys.length && tags[i + 1] < values.length) props[keys[tags[i]]] = values[tags[i + 1]];
          }
        case 3:
          type = p.varint();
        case 4:
          geometry = p.packed();
        default:
          p.skip(tag & 7);
      }
    }
    return UMvtFeature(type, _geometry(geometry, type), props, id);
  }

  static List<List<Offset>> _geometry(List<int> cmds, int type) {
    final List<List<Offset>> out = <List<Offset>>[];
    List<Offset>? current;
    int x = 0;
    int y = 0;
    int i = 0;
    while (i < cmds.length) {
      final int c = cmds[i++];
      final int id = c & 7;
      final int count = c >> 3;
      if (id == 1 || id == 2) {
        for (int k = 0; k < count && i + 1 < cmds.length; k++) {
          final int dx = cmds[i++];
          final int dy = cmds[i++];
          x += (dx >> 1) ^ -(dx & 1);
          y += (dy >> 1) ^ -(dy & 1);
          if (id == 1 && (type != 1 || current == null)) {
            current = <Offset>[];
            out.add(current);
          }
          current!.add(Offset(x.toDouble(), y.toDouble()));
        }
      } else if (id == 7) {
        if (current != null && current.isNotEmpty) current.add(current.first);
      }
    }
    return out;
  }
}

class _Pbf {
  _Pbf(this.bytes, [this.pos = 0, int? end]) : end = end ?? bytes.length;

  final Uint8List bytes;
  int pos;
  final int end;

  int varint() {
    int result = 0;
    int shift = 0;
    while (pos < end) {
      final int b = bytes[pos++];
      if (shift < 28) {
        result |= (b & 0x7f) << shift;
      } else {
        result += (b & 0x7f) * math.pow(2, shift).toInt();
      }
      if (b < 0x80) return result;
      shift += 7;
    }
    return result;
  }

  String string() {
    final int len = varint();
    final String s = utf8.decode(Uint8List.sublistView(bytes, pos, pos + len), allowMalformed: true);
    pos += len;
    return s;
  }

  double float32() {
    final double v = ByteData.sublistView(bytes, pos, pos + 4).getFloat32(0, Endian.little);
    pos += 4;
    return v;
  }

  double float64() {
    final double v = ByteData.sublistView(bytes, pos, pos + 8).getFloat64(0, Endian.little);
    pos += 8;
    return v;
  }

  List<int> packed() {
    final int len = varint();
    final int stop = pos + len;
    final List<int> out = <int>[];
    while (pos < stop) {
      out.add(varint());
    }
    return out;
  }

  void skip(int wire) {
    switch (wire) {
      case 0:
        varint();
      case 1:
        pos += 8;
      case 2:
        pos += varint();
      case 5:
        pos += 4;
      default:
        pos = end;
    }
  }
}

// ================================================================================================ style

/// A style layer (Mapbox GL / MapLibre style-spec subset: background, fill, line, symbol text, circle, fill-extrusion).
class UMapStyleLayer {
  UMapStyleLayer({required this.id, required this.type, this.source, this.sourceLayer, this.minZoom = 0, this.maxZoom = 24, this.filter, Map<String, dynamic>? paint, Map<String, dynamic>? layout})
    : paint = paint ?? <String, dynamic>{},
      layout = layout ?? <String, dynamic>{};

  factory UMapStyleLayer.fromJson(Map<String, dynamic> j) => UMapStyleLayer(
    id: j["id"]?.toString() ?? "",
    type: j["type"]?.toString() ?? "",
    source: j["source"]?.toString(),
    sourceLayer: j["source-layer"]?.toString(),
    minZoom: (j["minzoom"] as num?)?.toDouble() ?? 0,
    maxZoom: (j["maxzoom"] as num?)?.toDouble() ?? 24,
    filter: j["filter"],
    paint: j["paint"] is Map ? Map<String, dynamic>.from(j["paint"] as Map<dynamic, dynamic>) : null,
    layout: j["layout"] is Map ? Map<String, dynamic>.from(j["layout"] as Map<dynamic, dynamic>) : null,
  );

  final String id;
  final String type;
  final String? source;
  final String? sourceLayer;
  final double minZoom;
  final double maxZoom;
  final Object? filter;
  final Map<String, dynamic> paint;
  final Map<String, dynamic> layout;

  bool get visible => layout["visibility"] != "none";
}

/// A vector map style: ordered layers plus background. Load OpenFreeMap / MapLibre styles with [fromUrl], or use the built-in [light] / [dark].
class UMapVectorStyle {
  UMapVectorStyle({required this.id, required this.layers, this.sourceName, this.sourceUrl, this.language});

  /// Parses style JSON (style-spec v8). Layers of other sources (raster, hillshade) are skipped; icons/sprites are not drawn.
  factory UMapVectorStyle.fromJson(Map<String, dynamic> json, {String? id, String? language}) {
    String? sourceName;
    String? sourceUrl;
    final Map<String, dynamic> sources = Map<String, dynamic>.from(json["sources"] as Map<dynamic, dynamic>? ?? <String, dynamic>{});
    for (final MapEntry<String, dynamic> e in sources.entries) {
      final Map<dynamic, dynamic> s = e.value as Map<dynamic, dynamic>;
      if (s["type"] == "vector") {
        sourceName = e.key;
        sourceUrl = s["url"]?.toString() ?? (s["tiles"] as List<dynamic>?)?.first.toString();
        break;
      }
    }
    return UMapVectorStyle(
      id: id ?? json["name"]?.toString() ?? "style",
      layers: (json["layers"] as List<dynamic>? ?? <dynamic>[]).whereType<Map<dynamic, dynamic>>().map((Map<dynamic, dynamic> l) => UMapStyleLayer.fromJson(Map<String, dynamic>.from(l))).toList(),
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      language: language,
    );
  }

  /// Downloads a style JSON (e.g. https://tiles.openfreemap.org/styles/liberty).
  static Future<UMapVectorStyle> fromUrl(String url, {String? language}) async {
    final Response r = await Client().get(Uri.parse(url));
    return UMapVectorStyle.fromJson(jsonDecode(r.body) as Map<String, dynamic>, id: url, language: language);
  }

  /// Built-in light style for OpenMapTiles data (OpenFreeMap, planetiler, tilemaker output). No network needed for the style itself.
  factory UMapVectorStyle.light({String? language}) => UMapVectorStyle.fromJson(_builtIn(dark: false), id: "u-light", language: language);

  /// Built-in dark style for OpenMapTiles data.
  factory UMapVectorStyle.dark({String? language}) => UMapVectorStyle.fromJson(_builtIn(dark: true), id: "u-dark", language: language);

  /// Only place, road and water names on a transparent background — draw it above satellite imagery (free OpenFreeMap data).
  factory UMapVectorStyle.labels({String? language, bool dark = false}) {
    final Map<String, dynamic> json = _builtIn(dark: dark);
    json["layers"] = (json["layers"] as List<Map<String, dynamic>>).where((Map<String, dynamic> l) => l["type"] == "symbol").map((Map<String, dynamic> l) {
      final Map<String, dynamic> paint = Map<String, dynamic>.from(l["paint"] as Map<String, dynamic>);
      paint["text-color"] = dark ? "#ffffff" : "#111111";
      paint["text-halo-color"] = dark ? "#000000" : "#ffffff";
      paint["text-halo-width"] = 2;
      return <String, dynamic>{...l, "paint": paint};
    }).toList();
    return UMapVectorStyle.fromJson(json, id: "u-labels-$dark", language: language);
  }

  final String id;
  final List<UMapStyleLayer> layers;

  /// Name of the vector source in the style ("openmaptiles").
  final String? sourceName;

  /// TileJSON or tile template of that source.
  final String? sourceUrl;

  /// Label language code (fa, en, ar…): labels prefer `name:<language>`, then name.
  final String? language;

  /// Same style with labels in another language.
  UMapVectorStyle withLanguage(String? code) => UMapVectorStyle(id: id, layers: layers, sourceName: sourceName, sourceUrl: sourceUrl, language: code);

  /// The tile source the style asks for (OpenFreeMap when the style names it).
  UMapTileSource get tileSource =>
      sourceUrl == null ? UMapTileSource.openFreeMap : UMapTileSource.openFreeMap.copyWith(id: "vector_${sourceUrl.hashCode.toUnsigned(32)}", url: sourceUrl, name: "Vector");

  /// Cache identity.
  String get key => "$id|${language ?? ""}";

  static Map<String, dynamic> _builtIn({required bool dark}) {
    final String bg = dark ? "#1b1d22" : "#f2efe9";
    final String water = dark ? "#0e2433" : "#aad3df";
    final String park = dark ? "#1d2b22" : "#cdebb0";
    final String wood = dark ? "#1a2a1e" : "#add19e";
    final String residential = dark ? "#22252b" : "#e9e5df";
    final String building = dark ? "#2c2f36" : "#d9d0c9";
    final String road = dark ? "#3a3d45" : "#ffffff";
    final String casing = dark ? "#111214" : "#c9c2b8";
    final String major = dark ? "#5a4a2a" : "#fcd6a4";
    final String motorway = dark ? "#6b4b2a" : "#e892a2";
    final String text = dark ? "#d7d7d7" : "#333333";
    final String halo = dark ? "#1b1d22" : "#ffffff";
    final String boundary = dark ? "#6d6d7d" : "#9e9cab";
    Map<String, dynamic> lineWidth(double base, List<List<num>> stops) => <String, dynamic>{"base": base, "stops": stops};
    return <String, dynamic>{
      "version": 8,
      "name": dark ? "u dark" : "u light",
      "sources": <String, dynamic>{
        "openmaptiles": <String, dynamic>{"type": "vector", "url": "https://tiles.openfreemap.org/planet"},
      },
      "layers": <Map<String, dynamic>>[
        <String, dynamic>{
          "id": "background",
          "type": "background",
          "paint": <String, dynamic>{"background-color": bg},
        },
        <String, dynamic>{
          "id": "landuse-residential",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "landuse",
          "filter": <dynamic>["in", "class", "residential", "suburb", "neighbourhood"],
          "paint": <String, dynamic>{"fill-color": residential},
        },
        <String, dynamic>{
          "id": "landcover-wood",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "landcover",
          "filter": <dynamic>["==", "class", "wood"],
          "paint": <String, dynamic>{"fill-color": wood, "fill-opacity": 0.6},
        },
        <String, dynamic>{
          "id": "landcover-grass",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "landcover",
          "filter": <dynamic>["in", "class", "grass", "farmland"],
          "paint": <String, dynamic>{"fill-color": park, "fill-opacity": 0.5},
        },
        <String, dynamic>{
          "id": "park",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "park",
          "paint": <String, dynamic>{"fill-color": park, "fill-opacity": 0.7},
        },
        <String, dynamic>{
          "id": "water",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "water",
          "paint": <String, dynamic>{"fill-color": water},
        },
        <String, dynamic>{
          "id": "waterway",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "waterway",
          "paint": <String, dynamic>{
            "line-color": water,
            "line-width": lineWidth(1.3, <List<num>>[
              <num>[8, 0.5],
              <num>[20, 6],
            ]),
          },
        },
        <String, dynamic>{
          "id": "aeroway",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "aeroway",
          "minzoom": 11,
          "paint": <String, dynamic>{"fill-color": residential},
        },
        <String, dynamic>{
          "id": "building",
          "type": "fill",
          "source": "openmaptiles",
          "source-layer": "building",
          "minzoom": 13,
          "paint": <String, dynamic>{"fill-color": building, "fill-outline-color": casing},
        },
        <String, dynamic>{
          "id": "road-casing",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 12,
          "filter": <dynamic>["in", "class", "motorway", "trunk", "primary", "secondary", "tertiary", "minor"],
          "layout": <String, dynamic>{"line-cap": "round", "line-join": "round"},
          "paint": <String, dynamic>{
            "line-color": casing,
            "line-width": lineWidth(1.2, <List<num>>[
              <num>[12, 1.5],
              <num>[20, 26],
            ]),
          },
        },
        <String, dynamic>{
          "id": "road-minor",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": <dynamic>["in", "class", "minor", "service", "track"],
          "layout": <String, dynamic>{"line-cap": "round", "line-join": "round"},
          "paint": <String, dynamic>{
            "line-color": road,
            "line-width": lineWidth(1.2, <List<num>>[
              <num>[12, 0.5],
              <num>[20, 20],
            ]),
          },
        },
        <String, dynamic>{
          "id": "road-path",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "minzoom": 14,
          "filter": <dynamic>["==", "class", "path"],
          "paint": <String, dynamic>{
            "line-color": casing,
            "line-width": 1,
            "line-dasharray": <num>[2, 2],
          },
        },
        <String, dynamic>{
          "id": "road-major",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": <dynamic>["in", "class", "primary", "secondary", "tertiary"],
          "layout": <String, dynamic>{"line-cap": "round", "line-join": "round"},
          "paint": <String, dynamic>{
            "line-color": major,
            "line-width": lineWidth(1.2, <List<num>>[
              <num>[8, 0.5],
              <num>[20, 24],
            ]),
          },
        },
        <String, dynamic>{
          "id": "road-motorway",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": <dynamic>["in", "class", "motorway", "trunk"],
          "layout": <String, dynamic>{"line-cap": "round", "line-join": "round"},
          "paint": <String, dynamic>{
            "line-color": motorway,
            "line-width": lineWidth(1.2, <List<num>>[
              <num>[5, 0.5],
              <num>[20, 28],
            ]),
          },
        },
        <String, dynamic>{
          "id": "rail",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "transportation",
          "filter": <dynamic>["==", "class", "rail"],
          "paint": <String, dynamic>{
            "line-color": boundary,
            "line-width": 1.2,
            "line-dasharray": <num>[3, 3],
          },
        },
        <String, dynamic>{
          "id": "boundary-country",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "boundary",
          "filter": <dynamic>[
            "all",
            <dynamic>["==", "admin_level", 2],
            <dynamic>["!=", "maritime", 1],
          ],
          "paint": <String, dynamic>{
            "line-color": boundary,
            "line-width": lineWidth(1.3, <List<num>>[
              <num>[3, 0.8],
              <num>[12, 3],
            ]),
          },
        },
        <String, dynamic>{
          "id": "boundary-state",
          "type": "line",
          "source": "openmaptiles",
          "source-layer": "boundary",
          "minzoom": 4,
          "filter": <dynamic>["==", "admin_level", 4],
          "paint": <String, dynamic>{
            "line-color": boundary,
            "line-width": 1,
            "line-dasharray": <num>[3, 2],
          },
        },
        <String, dynamic>{
          "id": "water-name",
          "type": "symbol",
          "source": "openmaptiles",
          "source-layer": "water_name",
          "layout": <String, dynamic>{"text-field": "{name}", "text-size": 12, "text-font": <String>["Italic"]},
          "paint": <String, dynamic>{"text-color": dark ? "#6c9ab8" : "#4a7896", "text-halo-color": halo, "text-halo-width": 1},
        },
        <String, dynamic>{
          "id": "road-name",
          "type": "symbol",
          "source": "openmaptiles",
          "source-layer": "transportation_name",
          "minzoom": 13,
          "layout": <String, dynamic>{"text-field": "{name}", "text-size": 11, "symbol-placement": "line"},
          "paint": <String, dynamic>{"text-color": text, "text-halo-color": halo, "text-halo-width": 1.5},
        },
        <String, dynamic>{
          "id": "poi",
          "type": "symbol",
          "source": "openmaptiles",
          "source-layer": "poi",
          "minzoom": 15,
          "filter": <dynamic>["<=", "rank", 20],
          "layout": <String, dynamic>{"text-field": "{name}", "text-size": 11, "text-max-width": 8},
          "paint": <String, dynamic>{"text-color": dark ? "#b49a77" : "#7a5b3a", "text-halo-color": halo, "text-halo-width": 1.2},
        },
        <String, dynamic>{
          "id": "place-minor",
          "type": "symbol",
          "source": "openmaptiles",
          "source-layer": "place",
          "minzoom": 11,
          "filter": <dynamic>["in", "class", "suburb", "neighbourhood", "quarter", "village", "hamlet"],
          "layout": <String, dynamic>{"text-field": "{name}", "text-size": 12, "text-max-width": 8},
          "paint": <String, dynamic>{"text-color": text, "text-halo-color": halo, "text-halo-width": 1.5},
        },
        <String, dynamic>{
          "id": "place-town",
          "type": "symbol",
          "source": "openmaptiles",
          "source-layer": "place",
          "filter": <dynamic>["==", "class", "town"],
          "layout": <String, dynamic>{
            "text-field": "{name}",
            "text-size": <String, dynamic>{
              "stops": <List<num>>[
                <num>[8, 11],
                <num>[14, 16],
              ],
            },
          },
          "paint": <String, dynamic>{"text-color": text, "text-halo-color": halo, "text-halo-width": 1.5},
        },
        <String, dynamic>{
          "id": "place-city",
          "type": "symbol",
          "source": "openmaptiles",
          "source-layer": "place",
          "filter": <dynamic>["==", "class", "city"],
          "layout": <String, dynamic>{
            "text-field": "{name}",
            "text-font": <String>["Bold"],
            "text-size": <String, dynamic>{
              "stops": <List<num>>[
                <num>[4, 11],
                <num>[12, 20],
              ],
            },
          },
          "paint": <String, dynamic>{"text-color": text, "text-halo-color": halo, "text-halo-width": 2},
        },
        <String, dynamic>{
          "id": "place-country",
          "type": "symbol",
          "source": "openmaptiles",
          "source-layer": "place",
          "maxzoom": 8,
          "filter": <dynamic>["==", "class", "country"],
          "layout": <String, dynamic>{"text-field": "{name}", "text-font": <String>["Bold"], "text-size": 13, "text-transform": "uppercase", "text-max-width": 6},
          "paint": <String, dynamic>{"text-color": dark ? "#9a9aa8" : "#555566", "text-halo-color": halo, "text-halo-width": 2},
        },
      ],
    };
  }
}

/// Evaluates style-spec values: literals, legacy stop functions, legacy filters and expressions (get, match, case, step, interpolate, coalesce…).
abstract final class UMapStyleExpr {
  /// Value of a style property for a feature at a zoom.
  static Object? eval(Object? e, double zoom, UMvtFeature? f) {
    if (e is Map) {
      if (e.containsKey("stops")) return _stops(Map<String, dynamic>.from(e), zoom, f);
      return e;
    }
    if (e is! List || e.isEmpty || e.first is! String) return e;
    final String op = e.first as String;
    Object? a(int i) => i < e.length ? eval(e[i], zoom, f) : null;
    switch (op) {
      case "literal":
        return e.length > 1 ? e[1] : null;
      case "get":
        return f?.properties[a(1)];
      case "has":
        return f?.properties.containsKey(a(1)) ?? false;
      case "!has":
        return !(f?.properties.containsKey(a(1)) ?? false);
      case "zoom":
        return zoom;
      case "geometry-type":
        return f?.typeName;
      case "id":
        return f?.id;
      case "==":
        return _eq(a(1), a(2));
      case "!=":
        return !_eq(a(1), a(2));
      case "<":
      case ">":
      case "<=":
      case ">=":
        final Object? x = a(1);
        final Object? y = a(2);
        if (x is num && y is num) return op == "<" ? x < y : (op == ">" ? x > y : (op == "<=" ? x <= y : x >= y));
        if (x is String && y is String) {
          final int c = x.compareTo(y);
          return op == "<" ? c < 0 : (op == ">" ? c > 0 : (op == "<=" ? c <= 0 : c >= 0));
        }
        return false;
      case "!":
        return a(1) != true;
      case "all":
        for (int i = 1; i < e.length; i++) {
          if (a(i) != true) return false;
        }
        return true;
      case "any":
        for (int i = 1; i < e.length; i++) {
          if (a(i) == true) return true;
        }
        return false;
      case "none":
        for (int i = 1; i < e.length; i++) {
          if (a(i) == true) return false;
        }
        return true;
      case "in":
        final Object? needle = a(1);
        final Object? hay = a(2);
        if (hay is List) return hay.any((Object? v) => _eq(v, needle));
        if (hay is String && needle != null) return hay.contains(needle.toString());
        return false;
      case "match":
        final Object? input = a(1);
        for (int i = 2; i + 1 < e.length - 1; i += 2) {
          final Object? label = e[i];
          if (label is List ? label.any((Object? v) => _eq(v, input)) : _eq(label, input)) return a(i + 1);
        }
        return a(e.length - 1);
      case "case":
        for (int i = 1; i + 1 < e.length; i += 2) {
          if (a(i) == true) return a(i + 1);
        }
        return e.length.isEven ? a(e.length - 1) : null;
      case "coalesce":
        for (int i = 1; i < e.length; i++) {
          final Object? v = a(i);
          if (v != null && v != "") return v;
        }
        return null;
      case "step":
        final num input = (a(1) as num?) ?? 0;
        Object? out = a(2);
        for (int i = 3; i + 1 < e.length; i += 2) {
          final num stop = (a(i) as num?) ?? 0;
          if (input >= stop) {
            out = a(i + 1);
          } else {
            break;
          }
        }
        return out;
      case "interpolate":
      case "interpolate-hcl":
      case "interpolate-lab":
        final List<dynamic> kind = e[1] as List<dynamic>;
        final double base = kind.first == "exponential" ? ((kind[1] as num?)?.toDouble() ?? 1) : 1;
        final double input = ((a(2) as num?) ?? 0).toDouble();
        final List<(double, Object?)> stops = <(double, Object?)>[for (int i = 3; i + 1 < e.length; i += 2) (((a(i) as num?) ?? 0).toDouble(), a(i + 1))];
        return _interpolate(stops, input, base);
      case "concat":
        return <String>[for (int i = 1; i < e.length; i++) "${a(i) ?? ""}"].join();
      case "format":
        final StringBuffer b = StringBuffer();
        for (int i = 1; i < e.length; i++) {
          final Object? v = e[i] is Map ? null : a(i);
          if (v != null && v is! Map) b.write(v);
        }
        return b.toString();
      case "to-string":
        final Object? v = a(1);
        return v == null ? "" : (v is double && v == v.roundToDouble() ? v.toInt().toString() : v.toString());
      case "number-format":
        final Object? v = a(1);
        return v is num ? (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1)) : "$v";
      case "to-number":
        final Object? v = a(1);
        return v is num ? v : num.tryParse("$v") ?? 0;
      case "to-boolean":
        final Object? v = a(1);
        return v != null && v != false && v != 0 && v != "";
      case "upcase":
        return "${a(1) ?? ""}".toUpperCase();
      case "downcase":
        return "${a(1) ?? ""}".toLowerCase();
      case "length":
        final Object? v = a(1);
        return v is String ? v.length : (v is List ? v.length : 0);
      case "at":
        final Object? list = a(2);
        final Object? index = a(1);
        return list is List && index is num && index >= 0 && index < list.length ? list[index.toInt()] : null;
      case "+":
        return <num>[for (int i = 1; i < e.length; i++) (a(i) as num?) ?? 0].fold<num>(0, (num s, num v) => s + v);
      case "*":
        return <num>[for (int i = 1; i < e.length; i++) (a(i) as num?) ?? 0].fold<num>(1, (num s, num v) => s * v);
      case "-":
        return e.length == 2 ? -((a(1) as num?) ?? 0) : ((a(1) as num?) ?? 0) - ((a(2) as num?) ?? 0);
      case "/":
        final num d = (a(2) as num?) ?? 1;
        return d == 0 ? 0 : ((a(1) as num?) ?? 0) / d;
      case "%":
        final num d = (a(2) as num?) ?? 1;
        return d == 0 ? 0 : ((a(1) as num?) ?? 0) % d;
      case "^":
        return math.pow((a(1) as num?) ?? 0, (a(2) as num?) ?? 1);
      case "min":
        return <num>[for (int i = 1; i < e.length; i++) (a(i) as num?) ?? 0].reduce(math.min);
      case "max":
        return <num>[for (int i = 1; i < e.length; i++) (a(i) as num?) ?? 0].reduce(math.max);
      case "number":
      case "string":
      case "boolean":
      case "to-color":
      case "image":
        return a(1);
    }
    return e;
  }

  static bool _eq(Object? a, Object? b) {
    if (a is num && b is num) return a == b;
    return a == b;
  }

  static Object? _stops(Map<String, dynamic> fn, double zoom, UMvtFeature? f) {
    final List<dynamic> raw = fn["stops"] as List<dynamic>? ?? <dynamic>[];
    if (raw.isEmpty) return null;
    final String? property = fn["property"]?.toString();
    final Object? input = property == null ? zoom : f?.properties[property];
    final String type = fn["type"]?.toString() ?? (raw.first is List && (raw.first as List<dynamic>)[1] is String && !_isColor((raw.first as List<dynamic>)[1] as String) ? "interval" : "exponential");
    if (type == "categorical") {
      for (final dynamic s in raw) {
        if (_eq((s as List<dynamic>)[0], input)) return s[1];
      }
      return fn["default"];
    }
    if (type == "identity") return input;
    final double x = (input as num?)?.toDouble() ?? 0;
    final List<(double, Object?)> stops = <(double, Object?)>[
      for (final dynamic s in raw)
        if (s is List && s.length > 1) ((s[0] is Map ? ((s[0] as Map<dynamic, dynamic>)["zoom"] as num?) ?? 0 : (s[0] as num? ?? 0)).toDouble(), s[1]),
    ];
    if (type == "interval") {
      Object? out = stops.first.$2;
      for (final (double z, Object? v) in stops) {
        if (x >= z) out = v;
      }
      return out;
    }
    return _interpolate(stops, x, (fn["base"] as num?)?.toDouble() ?? 1);
  }

  static bool _isColor(String s) => s.startsWith("#") || s.startsWith("rgb") || s.startsWith("hsl");

  static Object? _interpolate(List<(double, Object?)> stops, double x, double base) {
    if (stops.isEmpty) return null;
    if (x <= stops.first.$1) return stops.first.$2;
    if (x >= stops.last.$1) return stops.last.$2;
    for (int i = 1; i < stops.length; i++) {
      if (x <= stops[i].$1) {
        final (double z0, Object? v0) = stops[i - 1];
        final (double z1, Object? v1) = stops[i];
        final double range = z1 - z0;
        final double t = range == 0 ? 0 : (base == 1 ? (x - z0) / range : (math.pow(base, x - z0) - 1) / (math.pow(base, range) - 1));
        if (v0 is num && v1 is num) return v0 + (v1 - v0) * t;
        final Color? c0 = color(v0);
        final Color? c1 = color(v1);
        if (c0 != null && c1 != null) return Color.lerp(c0, c1, t);
        if (v0 is List && v1 is List && v0.length == v1.length) {
          return <num>[for (int k = 0; k < v0.length; k++) (v0[k] as num) + ((v1[k] as num) - (v0[k] as num)) * t];
        }
        return t < 0.5 ? v0 : v1;
      }
    }
    return stops.last.$2;
  }

  /// True when a legacy-or-expression filter passes.
  static bool filter(Object? f, double zoom, UMvtFeature feature) {
    if (f == null) return true;
    if (f is! List || f.isEmpty) return true;
    if (_isLegacy(f)) return _legacy(f, feature);
    return eval(f, zoom, feature) == true;
  }

  static bool _isLegacy(List<dynamic> f) {
    final Object? op = f.first;
    switch (op) {
      case "==":
      case "!=":
      case "<":
      case ">":
      case "<=":
      case ">=":
      case "in":
      case "!in":
        return f.length > 1 && f[1] is String;
      case "!has":
      case "none":
        return true;
      case "has":
        return f.length > 1 && f[1] is String;
      case "all":
      case "any":
        return f.skip(1).any((dynamic c) => c is List && c.isNotEmpty && _isLegacy(c));
    }
    return false;
  }

  static bool _legacy(List<dynamic> f, UMvtFeature feature) {
    final String op = f.first.toString();
    Object? value(String key) => key == r"$type" ? feature.typeName : (key == r"$id" ? feature.id : feature.properties[key]);
    switch (op) {
      case "all":
        return f.skip(1).every((dynamic c) => c is List && _legacyOrExpr(c, feature));
      case "any":
        return f.skip(1).any((dynamic c) => c is List && _legacyOrExpr(c, feature));
      case "none":
        return !f.skip(1).any((dynamic c) => c is List && _legacyOrExpr(c, feature));
      case "has":
        return feature.properties.containsKey(f[1]);
      case "!has":
        return !feature.properties.containsKey(f[1]);
      case "in":
        final Object? v = value(f[1] as String);
        return f.skip(2).any((dynamic x) => _eq(x, v));
      case "!in":
        final Object? v = value(f[1] as String);
        return !f.skip(2).any((dynamic x) => _eq(x, v));
      default:
        final Object? v = value(f[1] as String);
        final Object? target = f.length > 2 ? f[2] : null;
        if (op == "==") return _eq(v, target);
        if (op == "!=") return !_eq(v, target);
        if (v is num && target is num) return op == "<" ? v < target : (op == ">" ? v > target : (op == "<=" ? v <= target : v >= target));
        if (v is String && target is String) {
          final int c = v.compareTo(target);
          return op == "<" ? c < 0 : (op == ">" ? c > 0 : (op == "<=" ? c <= 0 : c >= 0));
        }
        return false;
    }
  }

  static bool _legacyOrExpr(List<dynamic> f, UMvtFeature feature) => _isLegacy(f) ? _legacy(f, feature) : eval(f, 0, feature) == true;

  static final Map<String, Color?> _colors = <String, Color?>{};

  /// A style colour ("#rgb", "#rrggbb(aa)", rgb(), rgba(), hsl(), hsla(), a few names) or a Color.
  static Color? color(Object? v) {
    if (v is Color) return v;
    if (v is! String) return null;
    return _colors.putIfAbsent(v, () => _parseColor(v.trim().toLowerCase()));
  }

  static Color? _parseColor(String s) {
    const Map<String, int> named = <String, int>{"black": 0xff000000, "white": 0xffffffff, "transparent": 0x00000000, "red": 0xffff0000, "green": 0xff008000, "blue": 0xff0000ff, "gray": 0xff808080, "grey": 0xff808080, "yellow": 0xffffff00};
    if (named.containsKey(s)) return Color(named[s]!);
    if (s.startsWith("#")) {
      String h = s.substring(1);
      if (h.length == 3 || h.length == 4) h = h.split("").map((String c) => "$c$c").join();
      final int? v = int.tryParse(h, radix: 16);
      if (v == null) return null;
      if (h.length == 6) return Color(0xff000000 | v);
      if (h.length == 8) return Color(((v & 0xff) << 24) | (v >> 8));
      return null;
    }
    final RegExpMatch? m = RegExp(r"^(rgba?|hsla?)\(([^)]*)\)$").firstMatch(s);
    if (m == null) return null;
    final List<double> n = m.group(2)!.split(RegExp(r"[,\s/]+")).where((String x) => x.isNotEmpty).map((String x) => double.tryParse(x.replaceAll("%", "")) ?? 0).toList();
    if (n.length < 3) return null;
    final double alpha = n.length > 3 ? n[3] : 1;
    if (m.group(1)!.startsWith("rgb")) return Color.fromRGBO(n[0].round().clamp(0, 255), n[1].round().clamp(0, 255), n[2].round().clamp(0, 255), alpha.clamp(0, 1));
    return HSLColor.fromAHSL(alpha.clamp(0, 1), n[0] % 360, (n[1] / 100).clamp(0, 1), (n[2] / 100).clamp(0, 1)).toColor();
  }
}

// ================================================================================================ rendering

class _Label {
  _Label(this.painter, this.halo, this.anchor, this.angle, this.priority);

  final TextPainter painter;
  final TextPainter? halo;
  final Offset anchor;
  final double angle;
  final double priority;

  Rect get box {
    final double w = painter.width;
    final double h = painter.height;
    if (angle == 0) return Rect.fromCenter(center: anchor, width: w, height: h);
    final double c = math.cos(angle).abs();
    final double s = math.sin(angle).abs();
    return Rect.fromCenter(center: anchor, width: w * c + h * s, height: w * s + h * c);
  }
}

/// Renders vector tiles with a [UMapVectorStyle] into images (overzoom beyond the source's max zoom stays crisp).
abstract final class UMapVectorRenderer {
  static final ULruCache<String, UMvtTile> _decoded = ULruCache<String, UMvtTile>(maxBytes: 64 * 1024 * 1024, sizeOf: (UMvtTile t) => t.weight);
  static final Map<String, Future<UMvtTile?>> _decoding = <String, Future<UMvtTile?>>{};

  /// Decoded data tile (cached), decoding off the UI thread where supported.
  static Future<UMvtTile?> data(UMapTileSource source, int z, int x, int y, {bool offlineOnly = false}) {
    final String key = "${source.id}/$z/$x/$y";
    final UMvtTile? hot = _decoded.get(key);
    if (hot != null) return SynchronousFuture<UMvtTile?>(hot);
    return _decoding[key] ??= () async {
      try {
        final Uint8List? bytes = await UMapTiles.load(source, z, x, y, offlineOnly: offlineOnly);
        if (bytes == null || bytes.isEmpty) return null;
        final UMvtTile tile = bytes.length > 20000 ? await compute(UMvtDecoder.decode, bytes) : UMvtDecoder.decode(bytes);
        _decoded.put(key, tile);
        return tile;
      } on Object {
        return null;
      } finally {
        unawaited(_decoding.remove(key));
      }
    }();
  }

  /// Renders tile z/x/y (style zoom = z) into a square image of [size] pixels; [pixelRatio] scales strokes and text.
  static Future<ui.Image> render(UMapTileSource source, UMapVectorStyle style, int z, int x, int y, {double size = 512, double pixelRatio = 1, bool offlineOnly = false}) async {
    final int dataZ = math.min(z, source.maxNativeZoom);
    final int shift = z - dataZ;
    final int scale = 1 << shift;
    final int dx = x >> shift;
    final int dy = y >> shift;
    final UMvtTile? tile = await data(source, dataZ, dx, dy, offlineOnly: offlineOnly);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    canvas.clipRect(Rect.fromLTWH(0, 0, size, size));
    final double zoom = z.toDouble();
    final List<_Label> labels = <_Label>[];
    for (int li = 0; li < style.layers.length; li++) {
      final UMapStyleLayer layer = style.layers[li];
      if (!layer.visible || zoom < layer.minZoom || zoom >= layer.maxZoom) continue;
      if (layer.type == "background") {
        final Color? c = UMapStyleExpr.color(UMapStyleExpr.eval(layer.paint["background-color"], zoom, null));
        final double o = ((UMapStyleExpr.eval(layer.paint["background-opacity"], zoom, null) as num?) ?? 1).toDouble();
        if (c != null) canvas.drawColor(c.withValues(alpha: c.a * o), BlendMode.srcOver);
        continue;
      }
      if (tile == null || layer.sourceLayer == null) continue;
      if (style.sourceName != null && layer.source != null && layer.source != style.sourceName) continue;
      final UMvtLayer? data = tile.layers[layer.sourceLayer];
      if (data == null) continue;
      final double unit = size * scale / data.extent;
      final double ox = (x - dx * scale) * data.extent / scale;
      final double oy = (y - dy * scale) * data.extent / scale;
      Offset px(Offset p) => Offset((p.dx - ox) * unit, (p.dy - oy) * unit);
      for (final UMvtFeature f in data.features) {
        if (!UMapStyleExpr.filter(layer.filter, zoom, f)) continue;
        switch (layer.type) {
          case "fill":
          case "fill-extrusion":
            if (f.type != 3) continue;
            final String prefix = layer.type == "fill" ? "fill" : "fill-extrusion";
            if (layer.paint["$prefix-pattern"] != null && layer.paint["$prefix-color"] == null) continue;
            final Color? c = UMapStyleExpr.color(UMapStyleExpr.eval(layer.paint["$prefix-color"] ?? "#000000", zoom, f));
            if (c == null) continue;
            final double o = ((UMapStyleExpr.eval(layer.paint["$prefix-opacity"], zoom, f) as num?) ?? 1).toDouble();
            final Path path = Path()..fillType = PathFillType.evenOdd;
            for (final List<Offset> ring in f.geometry) {
              if (ring.length > 2) path.addPolygon(ring.map(px).toList(), true);
            }
            canvas.drawPath(path, Paint()..color = c.withValues(alpha: c.a * o));
            final Color? outline = UMapStyleExpr.color(UMapStyleExpr.eval(layer.paint["fill-outline-color"], zoom, f));
            if (outline != null) {
              canvas.drawPath(
                path,
                Paint()
                  ..color = outline.withValues(alpha: outline.a * o)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = pixelRatio * 0.7,
              );
            }
          case "line":
            if (f.type == 1) continue;
            final Color? c = UMapStyleExpr.color(UMapStyleExpr.eval(layer.paint["line-color"] ?? "#000000", zoom, f));
            if (c == null) continue;
            final double o = ((UMapStyleExpr.eval(layer.paint["line-opacity"], zoom, f) as num?) ?? 1).toDouble();
            final double w = ((UMapStyleExpr.eval(layer.paint["line-width"], zoom, f) as num?) ?? 1).toDouble() * pixelRatio;
            final double gap = ((UMapStyleExpr.eval(layer.paint["line-gap-width"], zoom, f) as num?) ?? 0).toDouble() * pixelRatio;
            final Object? dash = UMapStyleExpr.eval(layer.paint["line-dasharray"], zoom, f);
            final String cap = UMapStyleExpr.eval(layer.layout["line-cap"], zoom, f)?.toString() ?? "butt";
            final String join = UMapStyleExpr.eval(layer.layout["line-join"], zoom, f)?.toString() ?? "miter";
            final Paint paint = Paint()
              ..color = c.withValues(alpha: c.a * o)
              ..style = PaintingStyle.stroke
              ..strokeWidth = gap > 0 ? gap + w * 2 : w
              ..strokeCap = cap == "round" ? StrokeCap.round : (cap == "square" ? StrokeCap.square : StrokeCap.butt)
              ..strokeJoin = join == "round" ? StrokeJoin.round : (join == "bevel" ? StrokeJoin.bevel : StrokeJoin.miter);
            for (final List<Offset> line in f.geometry) {
              if (line.length < 2) continue;
              final Path path = Path()..addPolygon(line.map(px).toList(), false);
              canvas.drawPath(dash is List && dash.length >= 2 ? _dashed(path, dash.map((dynamic d) => ((d as num?) ?? 1).toDouble() * w).toList()) : path, paint);
            }
          case "circle":
            if (f.type != 1) continue;
            final Color? c = UMapStyleExpr.color(UMapStyleExpr.eval(layer.paint["circle-color"] ?? "#000000", zoom, f));
            final double r = ((UMapStyleExpr.eval(layer.paint["circle-radius"], zoom, f) as num?) ?? 5).toDouble() * pixelRatio;
            final double o = ((UMapStyleExpr.eval(layer.paint["circle-opacity"], zoom, f) as num?) ?? 1).toDouble();
            final double sw = ((UMapStyleExpr.eval(layer.paint["circle-stroke-width"], zoom, f) as num?) ?? 0).toDouble() * pixelRatio;
            final Color? sc = UMapStyleExpr.color(UMapStyleExpr.eval(layer.paint["circle-stroke-color"], zoom, f));
            for (final List<Offset> pts in f.geometry) {
              for (final Offset p in pts) {
                if (c != null) canvas.drawCircle(px(p), r, Paint()..color = c.withValues(alpha: c.a * o));
                if (sw > 0 && sc != null) {
                  canvas.drawCircle(
                    px(p),
                    r,
                    Paint()
                      ..color = sc
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = sw,
                  );
                }
              }
            }
          case "symbol":
            final _Label? l = _label(layer, f, zoom, pixelRatio, style.language, li, px);
            if (l != null) labels.add(l);
        }
      }
    }
    // Labels: higher layers and lower sort keys first; skip collisions and tile-edge cuts.
    labels.sort((_Label a, _Label b) => a.priority.compareTo(b.priority));
    final List<Rect> placed = <Rect>[];
    final Rect inside = Rect.fromLTWH(2, 2, size - 4, size - 4);
    for (final _Label l in labels) {
      final Rect box = l.box;
      if (!inside.contains(box.topLeft) || !inside.contains(box.bottomRight)) continue;
      if (placed.any((Rect r) => r.overlaps(box.inflate(2 * pixelRatio)))) continue;
      placed.add(box);
      canvas
        ..save()
        ..translate(l.anchor.dx, l.anchor.dy)
        ..rotate(l.angle);
      final Offset o = Offset(-l.painter.width / 2, -l.painter.height / 2);
      l.halo?.paint(canvas, o);
      l.painter.paint(canvas, o);
      canvas.restore();
    }
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.round(), size.round());
    picture.dispose();
    return image;
  }

  static String? _text(UMapStyleLayer layer, UMvtFeature f, double zoom, String? language) {
    Object? field = layer.layout["text-field"];
    if (field == null) return null;
    if (language != null && (field is String && field.contains("{name") || field is List)) {
      final Object? localized = f.properties["name:$language"];
      if (localized != null && "$localized".isNotEmpty) return "$localized";
    }
    field = UMapStyleExpr.eval(field, zoom, f);
    if (field == null) return null;
    String text = field is List ? field.whereType<String>().join() : field.toString();
    text = text.replaceAllMapped(RegExp(r"\{([^}]+)\}"), (Match m) => "${f.properties[m.group(1)] ?? ""}").trim();
    final String transform = UMapStyleExpr.eval(layer.layout["text-transform"], zoom, f)?.toString() ?? "none";
    if (transform == "uppercase") text = text.toUpperCase();
    if (transform == "lowercase") text = text.toLowerCase();
    return text.isEmpty ? null : text;
  }

  static _Label? _label(UMapStyleLayer layer, UMvtFeature f, double zoom, double ratio, String? language, int layerIndex, Offset Function(Offset) px) {
    final String? text = _text(layer, f, zoom, language);
    if (text == null) return null;
    final double size = ((UMapStyleExpr.eval(layer.layout["text-size"], zoom, f) as num?) ?? 16).toDouble() * ratio;
    final Color color = UMapStyleExpr.color(UMapStyleExpr.eval(layer.paint["text-color"] ?? "#000000", zoom, f)) ?? Colors.black;
    final double opacity = ((UMapStyleExpr.eval(layer.paint["text-opacity"], zoom, f) as num?) ?? 1).toDouble();
    final Color? haloColor = UMapStyleExpr.color(UMapStyleExpr.eval(layer.paint["text-halo-color"], zoom, f));
    final double haloWidth = ((UMapStyleExpr.eval(layer.paint["text-halo-width"], zoom, f) as num?) ?? 0).toDouble() * ratio;
    final Object? font = UMapStyleExpr.eval(layer.layout["text-font"], zoom, f);
    final String fontName = font is List ? font.join(" ") : "${font ?? ""}";
    final FontWeight weight = fontName.contains("Bold") ? FontWeight.w700 : (fontName.contains("Medium") || fontName.contains("Semibold") ? FontWeight.w500 : FontWeight.w400);
    final FontStyle fontStyle = fontName.contains("Italic") ? FontStyle.italic : FontStyle.normal;
    final double maxWidth = ((UMapStyleExpr.eval(layer.layout["text-max-width"], zoom, f) as num?) ?? 10).toDouble() * size;
    final String placement = UMapStyleExpr.eval(layer.layout["symbol-placement"], zoom, f)?.toString() ?? "point";
    final bool alongLine = placement != "point" && f.type == 2;
    final TextDirection dir = RegExp("[؀-ۿ֐-׿]").hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
    TextPainter make(TextStyle s) => TextPainter(
      text: TextSpan(text: text, style: s),
      textDirection: dir,
      textAlign: TextAlign.center,
      maxLines: alongLine ? 1 : 3,
    )..layout(maxWidth: alongLine ? double.infinity : maxWidth);
    final TextPainter painter = make(TextStyle(fontSize: size, color: color.withValues(alpha: color.a * opacity), fontWeight: weight, fontStyle: fontStyle, height: 1.1));
    final TextPainter? halo = haloColor == null || haloWidth <= 0
        ? null
        : make(
            TextStyle(
              fontSize: size,
              fontWeight: weight,
              fontStyle: fontStyle,
              height: 1.1,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = haloWidth * 2
                ..strokeJoin = StrokeJoin.round
                ..color = haloColor.withValues(alpha: haloColor.a * opacity),
            ),
          );
    final double sortKey = ((UMapStyleExpr.eval(layer.layout["symbol-sort-key"], zoom, f) as num?) ?? (f.properties["rank"] as num?) ?? 0).toDouble();
    final double priority = -layerIndex * 1000.0 + sortKey;
    if (alongLine) {
      // Middle of the longest segment that fits the text.
      Offset? best;
      double bestLen = 0;
      double angle = 0;
      for (final List<Offset> line in f.geometry) {
        for (int i = 1; i < line.length; i++) {
          final Offset a = px(line[i - 1]);
          final Offset b = px(line[i]);
          final double len = (b - a).distance;
          if (len > bestLen) {
            bestLen = len;
            best = (a + b) / 2;
            angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
          }
        }
      }
      if (best == null || bestLen < painter.width * 1.05) return null;
      if (angle > math.pi / 2) angle -= math.pi;
      if (angle < -math.pi / 2) angle += math.pi;
      return _Label(painter, halo, best, angle, priority);
    }
    Offset anchor;
    if (f.type == 3) {
      final List<Offset> ring = f.geometry.reduce((List<Offset> a, List<Offset> b) => a.length >= b.length ? a : b);
      double sx = 0;
      double sy = 0;
      for (final Offset p in ring) {
        sx += p.dx;
        sy += p.dy;
      }
      anchor = px(Offset(sx / ring.length, sy / ring.length));
    } else if (f.type == 2) {
      final List<Offset> line = f.geometry.first;
      anchor = px(line[line.length ~/ 2]);
    } else {
      if (f.geometry.isEmpty || f.geometry.first.isEmpty) return null;
      anchor = px(f.geometry.first.first);
    }
    final Object? offset = UMapStyleExpr.eval(layer.layout["text-offset"], zoom, f);
    if (offset is List && offset.length == 2) anchor += Offset(((offset[0] as num?) ?? 0) * size, ((offset[1] as num?) ?? 0) * size);
    return _Label(painter, halo, anchor, 0, priority);
  }

  static Path _dashed(Path source, List<double> pattern) {
    final Path out = Path();
    if (pattern.every((double d) => d <= 0)) return source;
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      int i = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = math.max(0.5, pattern[i % pattern.length]);
        if (draw) out.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += len;
        draw = !draw;
        i++;
      }
    }
    return out;
  }

  /// Features under a point (top layer first): name, class and every property — for "what is here" taps on vector maps.
  static Future<List<(String layer, Map<String, Object?> properties)>> featuresAt(UMapTileSource source, LatLng point, int zoom, {double tolerancePx = 6}) async {
    final int z = math.min(zoom, source.maxNativeZoom);
    final UTileId t = UGeoCodes.tileOf(point, z);
    final UMvtTile? tile = await data(source, z, t.x, t.y);
    if (tile == null) return <(String, Map<String, Object?>)>[];
    final List<(String, Map<String, Object?>)> out = <(String, Map<String, Object?>)>[];
    for (final UMvtLayer layer in tile.layers.values.toList().reversed) {
      final LatLng nw = UGeoCodes.tileCorner(z, t.x, t.y);
      final LatLng se = UGeoCodes.tileCorner(z, t.x + 1, t.y + 1);
      final Offset m0 = UGeoMath.toMercator(nw);
      final Offset m1 = UGeoMath.toMercator(se);
      final Offset mp = UGeoMath.toMercator(point);
      final Offset q = Offset((mp.dx - m0.dx) / (m1.dx - m0.dx) * layer.extent, (mp.dy - m0.dy) / (m1.dy - m0.dy) * layer.extent);
      final double tol = tolerancePx * layer.extent / 256;
      for (final UMvtFeature f in layer.features) {
        bool hit = false;
        if (f.type == 3) {
          int crossings = 0;
          for (final List<Offset> ring in f.geometry) {
            for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
              if ((ring[i].dy > q.dy) != (ring[j].dy > q.dy) && q.dx < (ring[j].dx - ring[i].dx) * (q.dy - ring[i].dy) / (ring[j].dy - ring[i].dy) + ring[i].dx) crossings++;
            }
          }
          hit = crossings.isOdd;
        } else {
          for (final List<Offset> part in f.geometry) {
            for (int i = 0; i < part.length && !hit; i++) {
              if ((part[i] - q).distance <= tol) hit = true;
              if (f.type == 2 && i > 0 && UGeoMath.planarPolygonDistance(q.dx, q.dy, <List<Offset>>[<Offset>[part[i - 1], part[i]]]).abs() <= tol) hit = true;
            }
          }
        }
        if (hit) out.add((layer.name, f.properties));
      }
    }
    return out;
  }
}

/// flutter_map tile provider that draws vector tiles with a style (use with tileDimension 512 and zoomOffset −1; see [UMapVectorTiles.layer]).
class UMapVectorTileProvider extends TileProvider {
  UMapVectorTileProvider(this.source, this.style, {this.offlineOnly = false});

  final UMapTileSource source;
  final UMapVectorStyle style;
  final bool offlineOnly;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final double ratio = (ui.PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1).clamp(1, 3);
    return UMapVectorTileImage(source, style, coordinates.z + options.zoomOffset.round(), coordinates.x, coordinates.y, ratio, offlineOnly: offlineOnly);
  }
}

/// Image of one rendered vector tile.
@immutable
class UMapVectorTileImage extends ImageProvider<UMapVectorTileImage> {
  const UMapVectorTileImage(this.source, this.style, this.z, this.x, this.y, this.pixelRatio, {this.offlineOnly = false});

  final UMapTileSource source;
  final UMapVectorStyle style;
  final int z;
  final int x;
  final int y;
  final double pixelRatio;
  final bool offlineOnly;

  @override
  Future<UMapVectorTileImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture<UMapVectorTileImage>(this);

  @override
  ImageStreamCompleter loadImage(UMapVectorTileImage key, ImageDecoderCallback decode) => OneFrameImageStreamCompleter(_load());

  Future<ImageInfo> _load() async {
    if (z < 0) throw StateError("bad zoom");
    final ui.Image image = await UMapVectorRenderer.render(source, style, z, x, y, size: 512 * pixelRatio, pixelRatio: pixelRatio, offlineOnly: offlineOnly);
    return ImageInfo(image: image, scale: pixelRatio);
  }

  @override
  bool operator ==(Object other) => other is UMapVectorTileImage && other.source.id == source.id && other.style.key == style.key && other.z == z && other.x == x && other.y == y && other.pixelRatio == pixelRatio;

  @override
  int get hashCode => Object.hash(source.id, style.key, z, x, y, pixelRatio);
}

/// Vector map layer helpers.
abstract final class UMapVectorTiles {
  /// A TileLayer drawing [style] from [source] (defaults to the style's own source, OpenFreeMap for the built-ins).
  static TileLayer layer(UMapVectorStyle style, {UMapTileSource? source, bool offlineOnly = false}) {
    final UMapTileSource s = source ?? style.tileSource;
    return TileLayer(
      tileProvider: UMapVectorTileProvider(s, style, offlineOnly: offlineOnly),
      tileDimension: 512,
      zoomOffset: -1,
      minNativeZoom: 1,
      maxNativeZoom: 23,
      maxZoom: 22,
      tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 120)),
      evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
      userAgentPackageName: UMapTiles.userAgent,
    );
  }
}
