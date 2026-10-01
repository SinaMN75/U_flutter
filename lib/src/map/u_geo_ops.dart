import "dart:math" as math;

import "package:u/utilities.dart";

/// Kind of polygon boolean operation.
enum UGeoBoolean { union, intersection, difference, xor }

/// A Delaunay triangulation: [triangles] holds 3 indexes into [points] per triangle.
class UGeoTriangulation {
  const UGeoTriangulation(this.points, this.triangles);

  final List<LatLng> points;
  final List<int> triangles;

  /// Number of triangles.
  int get count => triangles.length ~/ 3;

  /// Triangle [i] as a closed ring.
  List<LatLng> triangle(int i) => <LatLng>[points[triangles[3 * i]], points[triangles[3 * i + 1]], points[triangles[3 * i + 2]], points[triangles[3 * i]]];

  /// Every unique edge as index pairs.
  Set<(int, int)> get edges {
    final Set<(int, int)> out = <(int, int)>{};
    for (int i = 0; i < triangles.length; i += 3) {
      for (int k = 0; k < 3; k++) {
        final int a = triangles[i + k];
        final int b = triangles[i + (k + 1) % 3];
        out.add(a < b ? (a, b) : (b, a));
      }
    }
    return out;
  }
}

/// Shape operations: union/intersection/difference, buffer, hulls, Delaunay, Voronoi, clustering, grids (pure Dart). Use it through [UGeo].
abstract final class UGeoOps {
  // ---------------------------------------------------------------------------------------------- boolean operations

  /// Union / intersection / difference / xor of two polygons (each a list of rings, outline first). Returns polygons (rings).
  static List<List<List<LatLng>>> boolean(List<List<LatLng>> a, List<List<LatLng>> b, UGeoBoolean op) {
    if (a.isEmpty || a.first.length < 3) return op == UGeoBoolean.intersection || op == UGeoBoolean.difference ? <List<List<LatLng>>>[] : <List<List<LatLng>>>[if (b.isNotEmpty) b];
    if (b.isEmpty || b.first.length < 3) return op == UGeoBoolean.intersection ? <List<List<LatLng>>>[] : <List<List<LatLng>>>[a];
    switch (op) {
      case UGeoBoolean.xor:
        return <List<List<LatLng>>>[...boolean(a, b, UGeoBoolean.difference), ...boolean(b, a, UGeoBoolean.difference)];
      case UGeoBoolean.intersection:
        // (outerA ∩ outerB) minus every hole of both.
        List<List<List<LatLng>>> result = _ringOp(a.first, b.first, UGeoBoolean.intersection);
        for (final List<LatLng> hole in <List<LatLng>>[...a.skip(1), ...b.skip(1)]) {
          result = result.expand((List<List<LatLng>> p) => _subtractRing(p, hole)).toList();
        }
        return result;
      case UGeoBoolean.difference:
        // (A − outerB) minus A's holes, plus the parts of A that sit inside B's holes.
        List<List<List<LatLng>>> result = _ringOp(a.first, b.first, UGeoBoolean.difference);
        for (final List<LatLng> hole in a.skip(1)) {
          result = result.expand((List<List<LatLng>> p) => _subtractRing(p, hole)).toList();
        }
        for (final List<LatLng> hole in b.skip(1)) {
          result.addAll(boolean(a, <List<LatLng>>[hole], UGeoBoolean.intersection));
        }
        return result;
      case UGeoBoolean.union:
        final List<List<List<LatLng>>> merged = _ringOp(a.first, b.first, UGeoBoolean.union);
        // Holes survive where the other shape does not cover them.
        final List<List<LatLng>> holes = <List<LatLng>>[
          for (final List<LatLng> h in a.skip(1)) ...boolean(<List<LatLng>>[h], <List<LatLng>>[b.first], UGeoBoolean.difference).map((List<List<LatLng>> p) => p.first),
          for (final List<LatLng> h in b.skip(1)) ...boolean(<List<LatLng>>[h], <List<LatLng>>[a.first], UGeoBoolean.difference).map((List<List<LatLng>> p) => p.first),
        ];
        return merged.map((List<List<LatLng>> p) => <List<LatLng>>[...p, ...holes.where((List<LatLng> h) => h.isNotEmpty && UGeoMath.ringContains(p.first, UGeoMath.centroid(h)))]).toList();
    }
  }

  /// Union of many polygons.
  static List<List<List<LatLng>>> unionAll(List<List<List<LatLng>>> polygons) {
    final List<List<List<LatLng>>> result = <List<List<LatLng>>>[];
    for (final List<List<LatLng>> p in polygons) {
      List<List<LatLng>> current = p;
      bool merged = true;
      while (merged) {
        merged = false;
        for (int i = 0; i < result.length; i++) {
          if (UGeoMath.polygonsIntersect(result[i].first, current.first)) {
            final List<List<List<LatLng>>> u = boolean(result[i], current, UGeoBoolean.union);
            if (u.length == 1) {
              current = u.first;
              result.removeAt(i);
              merged = true;
              break;
            }
          }
        }
      }
      result.add(current);
    }
    return result;
  }

  /// Cuts one ring out of a polygon, keeping the polygon's own holes (no recursion).
  static List<List<List<LatLng>>> _subtractRing(List<List<LatLng>> polygon, List<LatLng> ring) {
    final List<List<List<LatLng>>> pieces = _ringOp(polygon.first, ring, UGeoBoolean.difference);
    for (final List<LatLng> hole in polygon.skip(1)) {
      if (hole.isEmpty) continue;
      final LatLng probe = hole.first;
      for (final List<List<LatLng>> piece in pieces) {
        if (UGeoMath.ringContains(piece.first, probe)) {
          piece.add(hole);
          break;
        }
      }
    }
    return pieces;
  }

  /// Greiner–Hormann clipping of two simple rings in Web Mercator metres.
  static List<List<List<LatLng>>> _ringOp(List<LatLng> subjectRing, List<LatLng> clipRing, UGeoBoolean op) {
    final List<Offset> s = _open(subjectRing.map(UGeoMath.toMercator).toList());
    List<Offset> c = _open(clipRing.map(UGeoMath.toMercator).toList());
    if (s.length < 3 || c.length < 3) return <List<List<LatLng>>>[];
    List<List<Offset>>? result;
    for (int attempt = 0; attempt < 6 && result == null; attempt++) {
      if (attempt > 0) {
        // Escape degenerate cases (shared vertices / shared edges) by scaling the clip ring a hair about its centre:
        // growing for union merges touching shapes, shrinking for the others drops zero-area touches.
        final Offset center = c.reduce((Offset x, Offset y) => x + y) / c.length.toDouble();
        final double k = 1 + (op == UGeoBoolean.union ? 1 : -1) * 1e-7 * attempt * attempt;
        c = <Offset>[for (final Offset p in c) center + (p - center) * k];
      }
      result = _greinerHormann(s, c, op);
    }
    result ??= <List<Offset>>[];
    final List<List<List<LatLng>>> out = <List<List<LatLng>>>[];
    final List<List<Offset>> outers = <List<Offset>>[];
    final List<List<Offset>> inners = <List<Offset>>[];
    for (final List<Offset> ring in result) {
      if (ring.length < 3) continue;
      // Rings inside another result ring are holes (happens for containment cases).
      final bool isHole = result.any((List<Offset> other) => !identical(other, ring) && other.length >= 3 && _planarContains(other, ring.first) && _planarArea(other).abs() > _planarArea(ring).abs());
      (isHole ? inners : outers).add(ring);
    }
    for (final List<Offset> outer in outers) {
      out.add(<List<LatLng>>[
        _close(outer.map(UGeoMath.fromMercator).toList()),
        for (final List<Offset> h in inners) if (_planarContains(outer, h.first)) _close(h.map(UGeoMath.fromMercator).toList()),
      ]);
    }
    return out;
  }

  static List<Offset> _open(List<Offset> ring) => ring.length > 1 && ring.first == ring.last ? ring.sublist(0, ring.length - 1) : ring;

  static List<LatLng> _close(List<LatLng> ring) => ring.isEmpty || ring.first == ring.last ? ring : <LatLng>[...ring, ring.first];

  static double _planarArea(List<Offset> ring) {
    double a = 0;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      a += (ring[j].dx + ring[i].dx) * (ring[j].dy - ring[i].dy);
    }
    return a / 2;
  }

  static bool _planarContains(List<Offset> ring, Offset p) {
    bool inside = false;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final Offset a = ring[i];
      final Offset b = ring[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) && p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) inside = !inside;
    }
    return inside;
  }

  /// Returns null when a degenerate intersection was met (caller perturbs and retries).
  static List<List<Offset>>? _greinerHormann(List<Offset> subject, List<Offset> clip, UGeoBoolean op) {
    final _GhPolygon sp = _GhPolygon(subject);
    final _GhPolygon cp = _GhPolygon(clip);
    bool degenerate = false;
    // Phase 1: intersections.
    _GhVertex sv = sp.first;
    do {
      if (!sv.intersect) {
        _GhVertex cv = cp.first;
        do {
          if (!cv.intersect) {
            final _GhVertex sNext = sp.nextNonIntersection(sv.next);
            final _GhVertex cNext = cp.nextNonIntersection(cv.next);
            if (_collinearOverlap(sv.p, sNext.p, cv.p, cNext.p)) degenerate = true;
            final (double, double)? hit = _segmentHit(sv.p, sNext.p, cv.p, cNext.p);
            if (hit != null) {
              final (double ta, double tb) = hit;
              const double eps = 1e-9;
              if (ta < eps || ta > 1 - eps || tb < eps || tb > 1 - eps) {
                degenerate = true;
              } else {
                final Offset point = Offset(sv.p.dx + ta * (sNext.p.dx - sv.p.dx), sv.p.dy + ta * (sNext.p.dy - sv.p.dy));
                final _GhVertex i1 = _GhVertex(point, alpha: ta, intersect: true);
                final _GhVertex i2 = _GhVertex(point, alpha: tb, intersect: true);
                i1.neighbor = i2;
                i2.neighbor = i1;
                sp.insertBetween(i1, sv, sNext);
                cp.insertBetween(i2, cv, cNext);
              }
            }
          }
          cv = cv.next;
        } while (!identical(cv, cp.first));
      }
      sv = sv.next;
    } while (!identical(sv, sp.first));
    if (degenerate) return null;

    final bool sInC = _planarContains(clip, subject.first);
    final bool cInS = _planarContains(subject, clip.first);
    if (!sp.hasIntersections) {
      // No crossings: one inside the other, or apart.
      switch (op) {
        case UGeoBoolean.union:
          if (sInC) return <List<Offset>>[clip];
          if (cInS) return <List<Offset>>[subject];
          return <List<Offset>>[subject, clip];
        case UGeoBoolean.intersection:
          if (sInC) return <List<Offset>>[subject];
          if (cInS) return <List<Offset>>[clip];
          return <List<Offset>>[];
        case UGeoBoolean.difference:
          if (sInC) return <List<Offset>>[];
          if (cInS) return <List<Offset>>[subject, clip];
          return <List<Offset>>[subject];
        case UGeoBoolean.xor:
          return <List<Offset>>[subject, clip];
      }
    }

    // Phase 2: entry/exit flags (union: back/back, intersection: forward/forward, difference: back/forward).
    bool sourceForwards = op == UGeoBoolean.intersection;
    bool clipForwards = op != UGeoBoolean.union;
    sourceForwards ^= sInC;
    clipForwards ^= cInS;
    _markEntries(sp, sourceForwards);
    _markEntries(cp, clipForwards);

    // Phase 3: trace.
    final List<List<Offset>> out = <List<Offset>>[];
    while (true) {
      _GhVertex? start;
      _GhVertex v = sp.first;
      do {
        if (v.intersect && !v.visited) {
          start = v;
          break;
        }
        v = v.next;
      } while (!identical(v, sp.first));
      if (start == null) break;
      final List<Offset> ring = <Offset>[];
      _GhVertex current = start;
      int guard = 0;
      do {
        current.visited = true;
        current.neighbor?.visited = true;
        if (current.entry) {
          do {
            current = current.next;
            ring.add(current.p);
            current.visited = true;
          } while (!current.intersect && guard++ < 100000);
        } else {
          do {
            current = current.prev;
            ring.add(current.p);
            current.visited = true;
          } while (!current.intersect && guard++ < 100000);
        }
        current.visited = true;
        current = current.neighbor!;
      } while (!current.visited && guard++ < 100000);
      if (ring.length >= 3) out.add(ring);
    }
    return out;
  }

  static void _markEntries(_GhPolygon poly, bool firstIsEntry) {
    bool entry = firstIsEntry;
    _GhVertex v = poly.first;
    do {
      if (v.intersect) {
        v.entry = entry;
        entry = !entry;
      }
      v = v.next;
    } while (!identical(v, poly.first));
  }

  /// True when two segments lie on the same line and share more than a point (shared edges).
  static bool _collinearOverlap(Offset a1, Offset a2, Offset b1, Offset b2) {
    final Offset d = a2 - a1;
    final double len = d.distance;
    if (len == 0) return false;
    double cross(Offset p) => ((p.dx - a1.dx) * d.dy - (p.dy - a1.dy) * d.dx).abs() / len;
    const double eps = 1e-6;
    if (cross(b1) > eps || cross(b2) > eps) return false;
    double t(Offset p) => ((p.dx - a1.dx) * d.dx + (p.dy - a1.dy) * d.dy) / (len * len);
    final double t1 = t(b1);
    final double t2 = t(b2);
    return math.max(0, math.min(1, math.max(t1, t2)) - math.max(0, math.min(t1, t2))) > 1e-9;
  }

  static (double, double)? _segmentHit(Offset a1, Offset a2, Offset b1, Offset b2) {
    final double d = (b2.dy - b1.dy) * (a2.dx - a1.dx) - (b2.dx - b1.dx) * (a2.dy - a1.dy);
    if (d == 0) return null;
    final double ta = ((b2.dx - b1.dx) * (a1.dy - b1.dy) - (b2.dy - b1.dy) * (a1.dx - b1.dx)) / d;
    final double tb = ((a2.dx - a1.dx) * (a1.dy - b1.dy) - (a2.dy - a1.dy) * (a1.dx - b1.dx)) / d;
    if (ta < 0 || ta > 1 || tb < 0 || tb > 1) return null;
    return (ta, tb);
  }

  // ---------------------------------------------------------------------------------------------- buffer

  /// Area within [meters] of a point, as a closed ring.
  static List<LatLng> bufferPoint(LatLng center, double meters, {int segments = 48}) => UGeoMath.circle(center, meters, segments: segments);

  /// Outline of the area within [meters] of a path (round ends and joins). Draw it with a non-zero fill.
  static List<LatLng> bufferLine(List<LatLng> points, double meters, {int arcSegments = 8}) {
    if (points.isEmpty) return <LatLng>[];
    if (points.length == 1) return bufferPoint(points.first, meters);
    final LatLng o = UGeoMath.origin(points);
    final List<Offset> xy = _dedupe(points.map((LatLng p) => UGeoMath.toLocal(p, o)).toList());
    if (xy.length == 1) return bufferPoint(points.first, meters);
    final List<Offset> left = _offsetSide(xy, meters, arcSegments);
    final List<Offset> right = _offsetSide(xy.reversed.toList(), meters, arcSegments);
    final List<Offset> ring = <Offset>[
      ...left,
      ..._arc(xy.last, _normalAngle(xy[xy.length - 2], xy.last) , -math.pi, meters, arcSegments * 2),
      ...right,
      ..._arc(xy.first, _normalAngle(xy[1], xy.first), -math.pi, meters, arcSegments * 2),
    ];
    final List<LatLng> out = ring.map((Offset m) => UGeoMath.fromLocal(m, o)).toList();
    return <LatLng>[...out, out.first];
  }

  /// Outline grown by [meters] (shrunk when negative) with round corners.
  static List<LatLng> bufferPolygon(List<LatLng> ring, double meters, {int arcSegments = 8}) {
    final LatLng o = UGeoMath.origin(ring);
    List<Offset> xy = _dedupe(_open(ring.map((LatLng p) => UGeoMath.toLocal(p, o)).toList()));
    if (xy.length < 3) return List<LatLng>.of(ring);
    if (_planarArea(xy) < 0) xy = xy.reversed.toList();
    // Ring is now clockwise in (x east, y north) → left side of travel is outward.
    final List<Offset> out = <Offset>[];
    final int n = xy.length;
    for (int i = 0; i < n; i++) {
      final Offset prev = xy[(i - 1 + n) % n];
      final Offset cur = xy[i];
      final Offset next = xy[(i + 1) % n];
      final double a1 = _normalAngle(prev, cur) ;
      final double a2 = _normalAngle(cur, next);
      if (meters > 0) {
        double sweep = a2 - a1;
        while (sweep > math.pi) {
          sweep -= 2 * math.pi;
        }
        while (sweep < -math.pi) {
          sweep += 2 * math.pi;
        }
        if (sweep < 0) {
          out.addAll(_arc(cur, a1, sweep, meters, arcSegments));
        } else {
          out.add(cur + Offset(math.cos(a1), math.sin(a1)) * meters);
          out.add(cur + Offset(math.cos(a2), math.sin(a2)) * meters);
        }
      } else {
        final Offset n1 = Offset(math.cos(a1), math.sin(a1));
        final Offset n2 = Offset(math.cos(a2), math.sin(a2));
        final Offset bisector = n1 + n2;
        final double len = bisector.distance;
        if (len < 1e-9) continue;
        final double cosHalf = (n1.dx * n2.dx + n1.dy * n2.dy + 1) / 2;
        final double scale = meters / math.sqrt(math.max(cosHalf, 0.05));
        out.add(cur + bisector / len * scale);
      }
    }
    final List<LatLng> result = out.map((Offset m) => UGeoMath.fromLocal(m, o)).toList();
    return result.isEmpty ? result : <LatLng>[...result, result.first];
  }

  /// Buffer of any geometry as polygons (rings).
  static List<List<List<LatLng>>> buffer(UGeoGeometry g, double meters) => switch (g) {
    UGeoPoint() => <List<List<LatLng>>>[<List<LatLng>>[bufferPoint(g.point, meters)]],
    UGeoMultiPoint() => g.points.map((LatLng p) => <List<LatLng>>[bufferPoint(p, meters)]).toList(),
    UGeoLine() => <List<List<LatLng>>>[<List<LatLng>>[bufferLine(g.points, meters)]],
    UGeoMultiLine() => g.lines.map((List<LatLng> l) => <List<LatLng>>[bufferLine(l, meters)]).toList(),
    UGeoPolygon() => <List<List<LatLng>>>[<List<LatLng>>[bufferPolygon(g.outer, meters)]],
    UGeoMultiPolygon() => g.polygons.map((List<List<LatLng>> p) => <List<LatLng>>[bufferPolygon(p.first, meters)]).toList(),
    UGeoCollection() => g.geometries.expand((UGeoGeometry x) => buffer(x, meters)).toList(),
  };

  static List<Offset> _dedupe(List<Offset> pts) {
    final List<Offset> out = <Offset>[];
    for (final Offset p in pts) {
      if (out.isEmpty || (out.last - p).distance > 1e-6) out.add(p);
    }
    return out;
  }

  /// Angle of the left-hand normal of segment a→b (x east, y north).
  static double _normalAngle(Offset a, Offset b) => math.atan2(b.dy - a.dy, b.dx - a.dx) + math.pi / 2;

  static List<Offset> _arc(Offset c, double start, double sweep, double r, int segments) =>
      <Offset>[for (int i = 0; i <= segments; i++) c + Offset(math.cos(start + sweep * i / segments), math.sin(start + sweep * i / segments)) * r];

  static List<Offset> _offsetSide(List<Offset> xy, double d, int arcSegments) {
    final List<Offset> out = <Offset>[];
    for (int i = 0; i < xy.length - 1; i++) {
      final double a = _normalAngle(xy[i], xy[i + 1]);
      final Offset n = Offset(math.cos(a), math.sin(a)) * d;
      if (i > 0) {
        final double prevA = _normalAngle(xy[i - 1], xy[i]);
        double sweep = a - prevA;
        while (sweep > math.pi) {
          sweep -= 2 * math.pi;
        }
        while (sweep < -math.pi) {
          sweep += 2 * math.pi;
        }
        if (sweep > 0) out.addAll(_arc(xy[i], prevA, sweep, d, arcSegments));
      }
      out.add(xy[i] + n);
      out.add(xy[i + 1] + n);
    }
    return out;
  }

  // ---------------------------------------------------------------------------------------------- hulls

  /// Smallest convex ring around points (monotone chain), closed.
  static List<LatLng> convexHull(List<LatLng> points) {
    if (points.length < 3) return List<LatLng>.of(points);
    final List<LatLng> sorted = List<LatLng>.of(points)..sort((LatLng a, LatLng b) => a.longitude != b.longitude ? a.longitude.compareTo(b.longitude) : a.latitude.compareTo(b.latitude));
    double cross(LatLng o, LatLng a, LatLng b) => (a.longitude - o.longitude) * (b.latitude - o.latitude) - (a.latitude - o.latitude) * (b.longitude - o.longitude);
    final List<LatLng> lower = <LatLng>[];
    for (final LatLng p in sorted) {
      while (lower.length >= 2 && cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final List<LatLng> upper = <LatLng>[];
    for (final LatLng p in sorted.reversed) {
      while (upper.length >= 2 && cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }
    final List<LatLng> hull = <LatLng>[...lower.sublist(0, lower.length - 1), ...upper.sublist(0, upper.length - 1)];
    return <LatLng>[...hull, hull.first];
  }

  /// Tight outline around points: Delaunay edges longer than [maxEdge] metres are peeled from the border (χ-shape), closed.
  static List<LatLng> concaveHull(List<LatLng> points, {required double maxEdge}) {
    final List<LatLng> unique = points.toSet().toList();
    if (unique.length < 4) return convexHull(unique);
    final UGeoTriangulation t = delaunay(unique);
    if (t.count == 0) return convexHull(unique);
    final Map<(int, int), List<int>> edgeTriangles = <(int, int), List<int>>{};
    (int, int) key(int a, int b) => a < b ? (a, b) : (b, a);
    for (int i = 0; i < t.count; i++) {
      for (int k = 0; k < 3; k++) {
        edgeTriangles.putIfAbsent(key(t.triangles[3 * i + k], t.triangles[3 * i + (k + 1) % 3]), () => <int>[]).add(i);
      }
    }
    final Set<int> removed = <int>{};
    final Set<int> boundaryVertices = <int>{};
    final UGeoHeap<(double, (int, int))> heap = UGeoHeap<(double, (int, int))>(((double, (int, int)) a, (double, (int, int)) b) => b.$1.compareTo(a.$1));
    for (final MapEntry<(int, int), List<int>> e in edgeTriangles.entries) {
      if (e.value.length == 1) {
        boundaryVertices
          ..add(e.key.$1)
          ..add(e.key.$2);
        heap.push((UGeoMath.distance(unique[e.key.$1], unique[e.key.$2]), e.key));
      }
    }
    while (heap.isNotEmpty) {
      final (double length, (int, int) edge) = heap.pop();
      if (length <= maxEdge) break;
      final List<int> alive = edgeTriangles[edge]!.where((int tri) => !removed.contains(tri)).toList();
      if (alive.length != 1) continue;
      final int tri = alive.first;
      final int third = <int>[t.triangles[3 * tri], t.triangles[3 * tri + 1], t.triangles[3 * tri + 2]].firstWhere((int v) => v != edge.$1 && v != edge.$2);
      if (boundaryVertices.contains(third)) continue;
      removed.add(tri);
      boundaryVertices.add(third);
      for (final (int, int) e in <(int, int)>[key(edge.$1, third), key(third, edge.$2)]) {
        heap.push((UGeoMath.distance(unique[e.$1], unique[e.$2]), e));
      }
    }
    final Map<int, List<int>> adjacency = <int, List<int>>{};
    for (final MapEntry<(int, int), List<int>> e in edgeTriangles.entries) {
      if (e.value.where((int tri) => !removed.contains(tri)).length == 1) {
        adjacency.putIfAbsent(e.key.$1, () => <int>[]).add(e.key.$2);
        adjacency.putIfAbsent(e.key.$2, () => <int>[]).add(e.key.$1);
      }
    }
    if (adjacency.isEmpty) return convexHull(unique);
    final int start = adjacency.keys.first;
    final List<int> ring = <int>[start];
    int prev = -1;
    int current = start;
    for (int i = 0; i < adjacency.length + 2; i++) {
      final List<int> next = adjacency[current]!.where((int v) => v != prev).toList();
      if (next.isEmpty) break;
      prev = current;
      current = next.first;
      if (current == start) break;
      ring.add(current);
    }
    final List<LatLng> out = ring.map((int i) => unique[i]).toList();
    return <LatLng>[...out, out.first];
  }

  // ---------------------------------------------------------------------------------------------- Delaunay & Voronoi

  /// Delaunay triangulation (Bowyer–Watson) of points; good up to a few thousand points.
  static UGeoTriangulation delaunay(List<LatLng> points) {
    final int n = points.length;
    if (n < 3) return UGeoTriangulation(points, const <int>[]);
    final LatLng o = UGeoMath.origin(points);
    final List<Offset> xy = <Offset>[for (final LatLng p in points) UGeoMath.toLocal(p, o)];
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    for (final Offset p in xy) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    final double d = math.max(maxX - minX, maxY - minY) * 20 + 1;
    final double mx = (minX + maxX) / 2;
    final double my = (minY + maxY) / 2;
    xy
      ..add(Offset(mx - d, my - d))
      ..add(Offset(mx, my + d))
      ..add(Offset(mx + d, my - d));
    List<_Tri> tris = <_Tri>[_Tri(n, n + 1, n + 2, xy)];
    final List<int> order = List<int>.generate(n, (int i) => i)..sort((int a, int b) => xy[a].dx.compareTo(xy[b].dx));
    for (final int i in order) {
      final Offset p = xy[i];
      final List<_Tri> bad = <_Tri>[];
      final List<_Tri> keep = <_Tri>[];
      for (final _Tri t in tris) {
        (t.inCircle(p) ? bad : keep).add(t);
      }
      final Map<(int, int), int> edgeCount = <(int, int), int>{};
      for (final _Tri t in bad) {
        for (final (int, int) e in t.edges) {
          final (int, int) key = e.$1 < e.$2 ? e : (e.$2, e.$1);
          edgeCount[key] = (edgeCount[key] ?? 0) + 1;
        }
      }
      for (final _Tri t in bad) {
        for (final (int, int) e in t.edges) {
          final (int, int) key = e.$1 < e.$2 ? e : (e.$2, e.$1);
          if (edgeCount[key] == 1) keep.add(_Tri(e.$1, e.$2, i, xy));
        }
      }
      tris = keep;
    }
    final List<int> out = <int>[];
    for (final _Tri t in tris) {
      if (t.a < n && t.b < n && t.c < n) out.addAll(<int>[t.a, t.b, t.c]);
    }
    return UGeoTriangulation(points, out);
  }

  /// Voronoi cells (the area closest to each point), clipped to [bounds] (defaults to the points' box plus 10%). Same order as [points].
  static List<List<LatLng>> voronoi(List<LatLng> points, {LatLngBounds? bounds}) {
    if (points.isEmpty) return <List<LatLng>>[];
    final LatLngBounds box = bounds ?? _padded(LatLngBounds.fromPoints(points), 0.1);
    final LatLng o = box.center;
    final Rect clip = Rect.fromPoints(UGeoMath.toLocal(box.southWest, o), UGeoMath.toLocal(box.northEast, o));
    final double far = clip.longestSide * 10 + 1;
    final List<LatLng> withFrame = <LatLng>[
      ...points,
      UGeoMath.fromLocal(Offset(-far, -far), o),
      UGeoMath.fromLocal(Offset(far, -far), o),
      UGeoMath.fromLocal(Offset(far, far), o),
      UGeoMath.fromLocal(Offset(-far, far), o),
    ];
    final UGeoTriangulation t = delaunay(withFrame);
    final List<Offset> xy = withFrame.map((LatLng p) => UGeoMath.toLocal(p, o)).toList();
    final Map<int, List<Offset>> centers = <int, List<Offset>>{};
    for (int i = 0; i < t.count; i++) {
      final int a = t.triangles[3 * i];
      final int b = t.triangles[3 * i + 1];
      final int c = t.triangles[3 * i + 2];
      final Offset? cc = _circumcenter(xy[a], xy[b], xy[c]);
      if (cc == null) continue;
      for (final int v in <int>[a, b, c]) {
        centers.putIfAbsent(v, () => <Offset>[]).add(cc);
      }
    }
    final List<List<LatLng>> cells = <List<LatLng>>[];
    for (int i = 0; i < points.length; i++) {
      final List<Offset> cc = centers[i] ?? <Offset>[];
      final Offset site = xy[i];
      cc.sort((Offset p, Offset q) => math.atan2(p.dy - site.dy, p.dx - site.dx).compareTo(math.atan2(q.dy - site.dy, q.dx - site.dx)));
      final List<Offset> clipped = _clipRect(cc, clip);
      final List<LatLng> ring = clipped.map((Offset m) => UGeoMath.fromLocal(m, o)).toList();
      cells.add(ring.isEmpty ? ring : <LatLng>[...ring, ring.first]);
    }
    return cells;
  }

  static LatLngBounds _padded(LatLngBounds b, double ratio) {
    final double dLat = math.max((b.north - b.south) * ratio, 0.001);
    final double dLng = math.max((b.east - b.west) * ratio, 0.001);
    return LatLngBounds(UGeoMath.safe(b.south - dLat, b.west - dLng), UGeoMath.safe(b.north + dLat, b.east + dLng));
  }

  static Offset? _circumcenter(Offset a, Offset b, Offset c) {
    final double d = 2 * (a.dx * (b.dy - c.dy) + b.dx * (c.dy - a.dy) + c.dx * (a.dy - b.dy));
    if (d.abs() < 1e-12) return null;
    final double a2 = a.dx * a.dx + a.dy * a.dy;
    final double b2 = b.dx * b.dx + b.dy * b.dy;
    final double c2 = c.dx * c.dx + c.dy * c.dy;
    return Offset((a2 * (b.dy - c.dy) + b2 * (c.dy - a.dy) + c2 * (a.dy - b.dy)) / d, (a2 * (c.dx - b.dx) + b2 * (a.dx - c.dx) + c2 * (b.dx - a.dx)) / d);
  }

  /// Sutherland–Hodgman clip of a convex polygon to a rectangle.
  static List<Offset> _clipRect(List<Offset> poly, Rect r) {
    List<Offset> out = poly;
    final List<(bool Function(Offset), Offset Function(Offset, Offset))> edges = <(bool Function(Offset), Offset Function(Offset, Offset))>[
      ((Offset p) => p.dx >= r.left, (Offset a, Offset b) => _lerpX(a, b, r.left)),
      ((Offset p) => p.dx <= r.right, (Offset a, Offset b) => _lerpX(a, b, r.right)),
      ((Offset p) => p.dy >= r.top, (Offset a, Offset b) => _lerpY(a, b, r.top)),
      ((Offset p) => p.dy <= r.bottom, (Offset a, Offset b) => _lerpY(a, b, r.bottom)),
    ];
    for (final (bool Function(Offset) inside, Offset Function(Offset, Offset) cut) in edges) {
      if (out.isEmpty) break;
      final List<Offset> input = out;
      out = <Offset>[];
      for (int i = 0; i < input.length; i++) {
        final Offset cur = input[i];
        final Offset prev = input[(i - 1 + input.length) % input.length];
        if (inside(cur)) {
          if (!inside(prev)) out.add(cut(prev, cur));
          out.add(cur);
        } else if (inside(prev)) {
          out.add(cut(prev, cur));
        }
      }
    }
    return out;
  }

  static Offset _lerpX(Offset a, Offset b, double x) => Offset(x, a.dy + (b.dy - a.dy) * (x - a.dx) / (b.dx - a.dx));

  static Offset _lerpY(Offset a, Offset b, double y) => Offset(a.dx + (b.dx - a.dx) * (y - a.dy) / (b.dy - a.dy), y);

  // ---------------------------------------------------------------------------------------------- clustering

  /// DBSCAN: groups points closer than [radius] metres with at least [minPoints] neighbours. Returns a cluster id per point (−1 = noise).
  static List<int> dbscan(List<LatLng> points, {required double radius, int minPoints = 3}) {
    final List<int> labels = List<int>.filled(points.length, -2);
    final UGeoKdIndex<int> index = UGeoKdIndex<int>(List<int>.generate(points.length, (int i) => i), (int i) => points[i]);
    int cluster = 0;
    for (int i = 0; i < points.length; i++) {
      if (labels[i] != -2) continue;
      final List<int> neighbors = index.within(points[i], radius);
      if (neighbors.length < minPoints) {
        labels[i] = -1;
        continue;
      }
      labels[i] = cluster;
      final List<int> queue = List<int>.of(neighbors);
      for (int q = 0; q < queue.length; q++) {
        final int j = queue[q];
        if (labels[j] == -1) labels[j] = cluster;
        if (labels[j] != -2) continue;
        labels[j] = cluster;
        final List<int> more = index.within(points[j], radius);
        if (more.length >= minPoints) queue.addAll(more);
      }
      cluster++;
    }
    return labels;
  }

  /// K-means: splits points into [k] groups. Returns a group index per point.
  static List<int> kMeans(List<LatLng> points, int k, {int iterations = 50, int seed = 7}) {
    if (points.isEmpty || k <= 0) return <int>[];
    final math.Random random = math.Random(seed);
    final List<LatLng> centers = List<LatLng>.generate(math.min(k, points.length), (_) => points[random.nextInt(points.length)]);
    final List<int> labels = List<int>.filled(points.length, 0);
    for (int it = 0; it < iterations; it++) {
      bool changed = false;
      for (int i = 0; i < points.length; i++) {
        int best = 0;
        double bestD = double.infinity;
        for (int c = 0; c < centers.length; c++) {
          final double d = UGeoMath.distance(points[i], centers[c]);
          if (d < bestD) {
            bestD = d;
            best = c;
          }
        }
        if (labels[i] != best) changed = true;
        labels[i] = best;
      }
      for (int c = 0; c < centers.length; c++) {
        final List<LatLng> members = <LatLng>[for (int i = 0; i < points.length; i++) if (labels[i] == c) points[i]];
        if (members.isNotEmpty) centers[c] = UGeoMath.centroid(members);
      }
      if (!changed && it > 0) break;
    }
    return labels;
  }

  // ---------------------------------------------------------------------------------------------- grids

  /// Flat-top hexagon cell (as a closed ring) of size [meters] (centre to corner) that contains [p]; Web Mercator grid, stable ids.
  static (String id, List<LatLng> ring) hexCell(LatLng p, double meters) {
    final Offset m = UGeoMath.toMercator(p);
    final double scale = 1 / math.cos(p.latitude * math.pi / 180);
    final double size = meters * scale;
    final double q = (2 / 3 * m.dx) / size;
    final double r = (-1 / 3 * m.dx + math.sqrt(3) / 3 * m.dy) / size;
    final (int qi, int ri) = _hexRound(q, r);
    final Offset center = Offset(size * 1.5 * qi, size * math.sqrt(3) * (ri + qi / 2));
    final List<LatLng> ring = <LatLng>[for (int i = 0; i <= 6; i++) UGeoMath.fromMercator(center + Offset(math.cos(math.pi / 3 * (i % 6)), math.sin(math.pi / 3 * (i % 6))) * size)];
    return ("${meters.round()}:$qi:$ri", ring);
  }

  static (int, int) _hexRound(double q, double r) {
    final double s = -q - r;
    int rq = q.round();
    int rr = r.round();
    final int rs = s.round();
    final double dq = (rq - q).abs();
    final double dr = (rr - r).abs();
    final double ds = (rs - s).abs();
    if (dq > dr && dq > ds) {
      rq = -rr - rs;
    } else if (dr > ds) {
      rr = -rq - rs;
    }
    return (rq, rr);
  }

  /// Square grid cells of [meters] covering a box, as closed rings.
  static List<List<LatLng>> squareGrid(LatLngBounds bounds, double meters) {
    final List<List<LatLng>> out = <List<LatLng>>[];
    final LatLng o = bounds.southWest;
    final Offset ne = UGeoMath.toLocal(bounds.northEast, o);
    for (double x = 0; x < ne.dx; x += meters) {
      for (double y = 0; y < ne.dy; y += meters) {
        final List<LatLng> ring = <Offset>[Offset(x, y), Offset(x + meters, y), Offset(x + meters, y + meters), Offset(x, y + meters), Offset(x, y)].map((Offset m) => UGeoMath.fromLocal(m, o)).toList();
        out.add(ring);
      }
    }
    return out;
  }
}

class _Tri {
  _Tri(this.a, this.b, this.c, List<Offset> xy) {
    final Offset pa = xy[a];
    final Offset pb = xy[b];
    final Offset pc = xy[c];
    final double d = 2 * (pa.dx * (pb.dy - pc.dy) + pb.dx * (pc.dy - pa.dy) + pc.dx * (pa.dy - pb.dy));
    if (d.abs() < 1e-12) {
      cx = pa.dx;
      cy = pa.dy;
      r2 = double.infinity;
    } else {
      final double a2 = pa.dx * pa.dx + pa.dy * pa.dy;
      final double b2 = pb.dx * pb.dx + pb.dy * pb.dy;
      final double c2 = pc.dx * pc.dx + pc.dy * pc.dy;
      cx = (a2 * (pb.dy - pc.dy) + b2 * (pc.dy - pa.dy) + c2 * (pa.dy - pb.dy)) / d;
      cy = (a2 * (pc.dx - pb.dx) + b2 * (pa.dx - pc.dx) + c2 * (pb.dx - pa.dx)) / d;
      r2 = (pa.dx - cx) * (pa.dx - cx) + (pa.dy - cy) * (pa.dy - cy);
    }
  }

  final int a;
  final int b;
  final int c;
  late final double cx;
  late final double cy;
  late final double r2;

  bool inCircle(Offset p) => (p.dx - cx) * (p.dx - cx) + (p.dy - cy) * (p.dy - cy) <= r2 * (1 + 1e-12);

  List<(int, int)> get edges => <(int, int)>[(a, b), (b, c), (c, a)];
}

class _GhVertex {
  _GhVertex(this.p, {this.alpha = 0, this.intersect = false});

  final Offset p;
  final double alpha;
  final bool intersect;
  bool entry = false;
  bool visited = false;
  _GhVertex? neighbor;
  late _GhVertex next;
  late _GhVertex prev;
}

class _GhPolygon {
  _GhPolygon(List<Offset> points) {
    final List<_GhVertex> v = points.map(_GhVertex.new).toList();
    for (int i = 0; i < v.length; i++) {
      v[i].next = v[(i + 1) % v.length];
      v[i].prev = v[(i - 1 + v.length) % v.length];
    }
    first = v.first;
  }

  late _GhVertex first;
  bool hasIntersections = false;

  _GhVertex nextNonIntersection(_GhVertex v) {
    _GhVertex c = v;
    while (c.intersect) {
      c = c.next;
    }
    return c;
  }

  void insertBetween(_GhVertex vertex, _GhVertex start, _GhVertex end) {
    hasIntersections = true;
    _GhVertex c = start;
    while (!identical(c, end) && c.alpha < vertex.alpha) {
      c = c.next;
    }
    // Insert before c, but never before [start] itself.
    if (identical(c, start)) c = start.next;
    vertex.next = c;
    vertex.prev = c.prev;
    c.prev.next = vertex;
    c.prev = vertex;
  }
}
