import "dart:math" as math;

import "package:u/utilities.dart";

/// One search hit with its score (higher is better) and distance from the search point when given.
class UMapSearchHit<T> {
  const UMapSearchHit(this.item, this.score, this.point, {this.distance});

  final T item;
  final double score;
  final LatLng point;
  final double? distance;
}

/// Offline place search over your own data: Persian/Arabic-aware normalisation, typo tolerance, prefix matching and distance ranking.
class UMapSearchIndex<T> {
  UMapSearchIndex();

  final List<(T item, LatLng point, List<String> names, String category)> _items = <(T, LatLng, List<String>, String)>[];
  final Map<String, Set<int>> _trigrams = <String, Set<int>>{};
  final List<List<String>> _tokens = <List<String>>[];

  /// Number of items.
  int get length => _items.length;

  /// Adds a searchable item with its names (first is the main one; add aliases, English/Persian names…).
  void add(T item, LatLng point, List<String> names, {String category = ""}) {
    final int id = _items.length;
    final List<String> norm = names.map(normalize).where((String n) => n.isNotEmpty).toList();
    _items.add((item, point, norm, normalize(category)));
    final List<String> tokens = <String>{for (final String n in norm) ...n.split(" ")}.where((String t) => t.isNotEmpty).toList();
    _tokens.add(tokens);
    for (final String t in tokens) {
      for (final String g in _grams(t)) {
        _trigrams.putIfAbsent(g, () => <int>{}).add(id);
      }
    }
  }

  /// Adds every feature of a collection using a property as its name (points use their location, shapes their centre).
  void addFeatures(UGeoFeatureCollection features, T Function(UGeoFeature f) itemOf, {String nameKey = "name", List<String> aliasKeys = const <String>["name:fa", "name:en", "alt_name"]}) {
    for (final UGeoFeature f in features.features) {
      final String? name = f.properties[nameKey]?.toString();
      if (name == null || name.isEmpty) continue;
      final LatLng p = f.geometry is UGeoPoint ? (f.geometry as UGeoPoint).point : UGeoMath.centroid(f.geometry.coordinates.toList());
      add(itemOf(f), p, <String>[name, for (final String k in aliasKeys) if (f.properties[k] != null) "${f.properties[k]}"], category: "${f.properties["category"] ?? f.properties["amenity"] ?? ""}");
    }
  }

  /// Removes everything.
  void clear() {
    _items.clear();
    _trigrams.clear();
    _tokens.clear();
  }

  static Iterable<String> _grams(String t) sync* {
    final String s = " $t ";
    for (int i = 0; i + 3 <= s.length; i++) {
      yield s.substring(i, i + 3);
    }
  }

  /// Search text in a comparable form: Arabic → Persian letters (ي→ی, ك→ک, ة→ه, أإآ→ا), no diacritics/tatweel, Persian/Arabic digits → Latin, ZWNJ → space, lower case.
  static String normalize(String text) {
    final StringBuffer b = StringBuffer();
    for (final int c in text.runes) {
      switch (c) {
        case 0x064A || 0x0649:
          b.write("ی");
        case 0x0643:
          b.write("ک");
        case 0x0629 || 0x06C0:
          b.write("ه");
        case 0x0623 || 0x0625 || 0x0622 || 0x0671:
          b.write("ا");
        case 0x0624:
          b.write("و");
        case 0x200C || 0x200D || 0x00A0 || 0x2009 || 0x202F || 0x060C || 0x061B || 0x002C || 0x002E || 0x002D || 0x005F || 0x002F:
          b.write(" ");
        case 0x0640:
          break;
        default:
          if (c >= 0x064B && c <= 0x065F || c == 0x0670) break;
          if (c >= 0x06F0 && c <= 0x06F9) {
            b.writeCharCode(0x30 + c - 0x06F0);
          } else if (c >= 0x0660 && c <= 0x0669) {
            b.writeCharCode(0x30 + c - 0x0660);
          } else {
            b.writeCharCode(c);
          }
      }
    }
    return b.toString().toLowerCase().replaceAll(RegExp(r"\s+"), " ").trim();
  }

  /// Edit distance between two short strings (stops early past [max]).
  static int levenshtein(String a, String b, {int max = 3}) {
    if ((a.length - b.length).abs() > max) return max + 1;
    List<int> prev = List<int>.generate(b.length + 1, (int i) => i);
    for (int i = 1; i <= a.length; i++) {
      final List<int> cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      int best = cur[0];
      for (int j = 1; j <= b.length; j++) {
        cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + (a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1));
        best = math.min(best, cur[j]);
      }
      if (best > max) return max + 1;
      prev = cur;
    }
    return prev[b.length];
  }

  /// Best matches for [query]; [near] boosts closer items; [category] filters.
  List<UMapSearchHit<T>> search(String query, {LatLng? near, int limit = 20, String? category, double maxDistance = double.infinity}) {
    final String q = normalize(query);
    if (q.isEmpty) return <UMapSearchHit<T>>[];
    final List<String> words = q.split(" ");
    final Map<int, int> votes = <int, int>{};
    for (final String w in words) {
      for (final String g in _grams(w)) {
        for (final int id in _trigrams[g] ?? const <int>{}) {
          votes[id] = (votes[id] ?? 0) + 1;
        }
      }
    }
    final String? cat = category == null ? null : normalize(category);
    final List<UMapSearchHit<T>> hits = <UMapSearchHit<T>>[];
    for (final MapEntry<int, int> v in votes.entries) {
      final (T item, LatLng point, List<String> names, String itemCategory) = _items[v.key];
      if (cat != null && itemCategory != cat) continue;
      final double? distance = near == null ? null : UGeoMath.distance(near, point);
      if (distance != null && distance > maxDistance) continue;
      double score = 0;
      for (final String w in words) {
        double best = 0;
        for (final String t in _tokens[v.key]) {
          if (t == w) {
            best = math.max(best, 1);
          } else if (t.startsWith(w)) {
            best = math.max(best, 0.85);
          } else if (t.contains(w)) {
            best = math.max(best, 0.6);
          } else if (w.length > 3) {
            final int d = levenshtein(w, t, max: w.length > 6 ? 2 : 1);
            if (d <= (w.length > 6 ? 2 : 1)) best = math.max(best, 0.7 - d * 0.15);
          }
        }
        score += best;
      }
      score /= words.length;
      if (names.isNotEmpty && names.first == q) score += 0.5;
      if (names.any((String n) => n.startsWith(q))) score += 0.25;
      if (score < 0.3) continue;
      if (distance != null) score += 0.3 / (1 + distance / 2000);
      hits.add(UMapSearchHit<T>(item, score, point, distance: distance));
    }
    hits.sort((UMapSearchHit<T> a, UMapSearchHit<T> b) => b.score.compareTo(a.score));
    return hits.take(limit).toList();
  }
}

/// Saved places in lists (favourites, home, work…) with colours, plus recent searches — stored on the device.
abstract final class UMapPlaces {
  static const String _placesKey = "umap_saved_places.json";
  static const String _recentKey = "umap_recent_searches.json";

  /// Every saved place as (list name, colour, place).
  static Future<List<(String list, Color color, UMapPlace place)>> all() async {
    final dynamic json = await UFileStorage.getJson(_placesKey);
    if (json is! List) return <(String, Color, UMapPlace)>[];
    return json.whereType<Map<dynamic, dynamic>>().map((Map<dynamic, dynamic> m) {
      final Map<String, dynamic> j = Map<String, dynamic>.from(m);
      return (j["list"]?.toString() ?? "Saved", Color((j["color"] as num?)?.toInt() ?? 0xFFE53935), UMapPlace.fromJson(Map<String, dynamic>.from(j["place"] as Map<dynamic, dynamic>)));
    }).toList();
  }

  /// Saves a place into a list (replaces the same point in the same list).
  static Future<void> save(UMapPlace place, {String list = "Saved", Color color = const Color(0xFFE53935)}) async {
    final List<(String, Color, UMapPlace)> current = (await all()).where(((String, Color, UMapPlace) e) => !(e.$1 == list && e.$3.point == place.point)).toList()..add((list, color, place));
    await _write(current);
  }

  /// Removes a place from a list.
  static Future<void> remove(UMapPlace place, {String list = "Saved"}) async => _write((await all()).where(((String, Color, UMapPlace) e) => !(e.$1 == list && e.$3.point == place.point)).toList());

  /// Names of every list.
  static Future<List<String>> lists() async => <String>{for (final (String l, Color _, UMapPlace _) in await all()) l}.toList();

  static Future<void> _write(List<(String, Color, UMapPlace)> items) => UFileStorage.setJson(
    _placesKey,
    items.map(((String, Color, UMapPlace) e) => <String, dynamic>{"list": e.$1, "color": e.$2.toARGB32(), "place": e.$3.toJson()}).toList(),
  );

  /// Recent searches, newest first.
  static Future<List<UMapPlace>> recent() async {
    final dynamic json = await UFileStorage.getJson(_recentKey);
    if (json is! List) return <UMapPlace>[];
    return json.whereType<Map<dynamic, dynamic>>().map((Map<dynamic, dynamic> m) => UMapPlace.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  /// Remembers a picked search result (keeps the last [max]).
  static Future<void> addRecent(UMapPlace place, {int max = 20}) async {
    final List<UMapPlace> list = (await recent()).where((UMapPlace p) => p.point != place.point).toList()..insert(0, place);
    await UFileStorage.setJson(_recentKey, list.take(max).map((UMapPlace p) => p.toJson()).toList());
  }

  /// Forgets recent searches.
  static Future<void> clearRecent() => UFileStorage.remove(_recentKey);
}
