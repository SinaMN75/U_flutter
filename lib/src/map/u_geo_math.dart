import "dart:math" as math;

import "package:u/utilities.dart";

/// Geometry engine on latitude/longitude (pure Dart, every platform). Use it through [UGeo].
abstract final class UGeoMath {
  /// Mean earth radius in metres.
  static const double earthRadius = 6371008.8;

  /// Web Mercator sphere radius in metres.
  static const double mercatorRadius = 6378137;

  static const double _d2r = math.pi / 180;
  static const double _r2d = 180 / math.pi;

  static double _rad(double d) => d * _d2r;

  static double _deg(double r) => r * _r2d;

  static double _wrapLng(double lng) => ((lng + 540) % 360) - 180;

  static double _clampLat(double lat) => lat.clamp(-90.0, 90.0);

  /// LatLng that never trips latlong2's range asserts.
  static LatLng safe(double lat, double lng) => LatLng(_clampLat(lat), lng < -180 || lng > 180 ? _wrapLng(lng) : lng);

  // ---------------------------------------------------------------------------------------------- distance & direction

  /// Great-circle (haversine) distance in metres.
  static double distance(LatLng a, LatLng b) {
    final double dLat = _rad(b.latitude - a.latitude);
    final double dLng = _rad(b.longitude - a.longitude);
    final double h = math.pow(math.sin(dLat / 2), 2) + math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Ellipsoid (WGS84, Vincenty) distance in metres, accurate to millimetres; falls back to haversine for near-antipodal points.
  static double vincenty(LatLng p1, LatLng p2) {
    const double a = 6378137;
    const double f = 1 / 298.257223563;
    const double b = a * (1 - f);
    final double l = _rad(p2.longitude - p1.longitude);
    final double u1 = math.atan((1 - f) * math.tan(_rad(p1.latitude)));
    final double u2 = math.atan((1 - f) * math.tan(_rad(p2.latitude)));
    final double sinU1 = math.sin(u1);
    final double cosU1 = math.cos(u1);
    final double sinU2 = math.sin(u2);
    final double cosU2 = math.cos(u2);
    double lambda = l;
    double sinSigma = 0;
    double cosSigma = 0;
    double sigma = 0;
    double cosSqAlpha = 0;
    double cos2SigmaM = 0;
    for (int i = 0; i < 200; i++) {
      final double sinLambda = math.sin(lambda);
      final double cosLambda = math.cos(lambda);
      sinSigma = math.sqrt(math.pow(cosU2 * sinLambda, 2) + math.pow(cosU1 * sinU2 - sinU1 * cosU2 * cosLambda, 2));
      if (sinSigma == 0) return 0;
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = math.atan2(sinSigma, cosSigma);
      final double sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM = cosSqAlpha == 0 ? 0 : cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
      final double c = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
      final double previous = lambda;
      lambda = l + (1 - c) * f * sinAlpha * (sigma + c * sinSigma * (cos2SigmaM + c * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
      if ((lambda - previous).abs() < 1e-12) {
        final double uSq = cosSqAlpha * (a * a - b * b) / (b * b);
        final double bigA = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
        final double bigB = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
        final double deltaSigma =
            bigB *
            sinSigma *
            (cos2SigmaM + bigB / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - bigB / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)));
        return b * bigA * (sigma - deltaSigma);
      }
    }
    return distance(p1, p2);
  }

  /// Initial bearing in degrees (0 = north, clockwise) from [a] to [b].
  static double bearing(LatLng a, LatLng b) {
    final double y = math.sin(_rad(b.longitude - a.longitude)) * math.cos(_rad(b.latitude));
    final double x = math.cos(_rad(a.latitude)) * math.sin(_rad(b.latitude)) - math.sin(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * math.cos(_rad(b.longitude - a.longitude));
    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  /// Bearing when arriving at [b].
  static double finalBearing(LatLng a, LatLng b) => (bearing(b, a) + 180) % 360;

  /// Point [meters] away from [from] towards [bearingDegrees] on the great circle.
  static LatLng destination(LatLng from, double meters, double bearingDegrees) {
    final double delta = meters / earthRadius;
    final double theta = _rad(bearingDegrees);
    final double phi1 = _rad(from.latitude);
    final double lambda1 = _rad(from.longitude);
    final double phi2 = math.asin(math.sin(phi1) * math.cos(delta) + math.cos(phi1) * math.sin(delta) * math.cos(theta));
    final double lambda2 = lambda1 + math.atan2(math.sin(theta) * math.sin(delta) * math.cos(phi1), math.cos(delta) - math.sin(phi1) * math.sin(phi2));
    return safe(_deg(phi2), _wrapLng(_deg(lambda2)));
  }

  /// Halfway point on the great circle.
  static LatLng midpoint(LatLng a, LatLng b) => interpolate(a, b, 0.5);

  /// Point at [fraction] (0..1) of the way from [a] to [b] on the great circle.
  static LatLng interpolate(LatLng a, LatLng b, double fraction) {
    final double d = distance(a, b) / earthRadius;
    if (d < 1e-12) return a;
    final double phi1 = _rad(a.latitude);
    final double lambda1 = _rad(a.longitude);
    final double phi2 = _rad(b.latitude);
    final double lambda2 = _rad(b.longitude);
    final double sa = math.sin((1 - fraction) * d) / math.sin(d);
    final double sb = math.sin(fraction * d) / math.sin(d);
    final double x = sa * math.cos(phi1) * math.cos(lambda1) + sb * math.cos(phi2) * math.cos(lambda2);
    final double y = sa * math.cos(phi1) * math.sin(lambda1) + sb * math.cos(phi2) * math.sin(lambda2);
    final double z = sa * math.sin(phi1) + sb * math.sin(phi2);
    return safe(_deg(math.atan2(z, math.sqrt(x * x + y * y))), _deg(math.atan2(y, x)));
  }

  /// Great-circle arc between two points (flight paths), [segments] pieces.
  static List<LatLng> greatCircle(LatLng a, LatLng b, {int segments = 64}) =>
      <LatLng>[for (int i = 0; i <= segments; i++) interpolate(a, b, i / segments)];

  /// Distance in metres along a constant-bearing (rhumb) line.
  static double rhumbDistance(LatLng a, LatLng b) {
    final double phi1 = _rad(a.latitude);
    final double phi2 = _rad(b.latitude);
    final double dPhi = phi2 - phi1;
    double dLambda = _rad((b.longitude - a.longitude).abs());
    if (dLambda > math.pi) dLambda -= 2 * math.pi;
    final double dPsi = math.log(math.tan(phi2 / 2 + math.pi / 4) / math.tan(phi1 / 2 + math.pi / 4));
    final double q = dPsi.abs() > 1e-12 ? dPhi / dPsi : math.cos(phi1);
    return math.sqrt(dPhi * dPhi + q * q * dLambda * dLambda) * earthRadius;
  }

  /// Constant bearing (rhumb line) from [a] to [b] in degrees.
  static double rhumbBearing(LatLng a, LatLng b) {
    final double phi1 = _rad(a.latitude);
    final double phi2 = _rad(b.latitude);
    double dLambda = _rad(b.longitude - a.longitude);
    if (dLambda.abs() > math.pi) dLambda = dLambda > 0 ? -(2 * math.pi - dLambda) : 2 * math.pi + dLambda;
    final double dPsi = math.log(math.tan(phi2 / 2 + math.pi / 4) / math.tan(phi1 / 2 + math.pi / 4));
    return (_deg(math.atan2(dLambda, dPsi)) + 360) % 360;
  }

  /// Total length of a path in metres.
  static double length(List<LatLng> points) {
    double sum = 0;
    for (int i = 1; i < points.length; i++) {
      sum += distance(points[i - 1], points[i]);
    }
    return sum;
  }

  /// Distance from the start to every vertex (metres), same length as [points].
  static List<double> cumulative(List<LatLng> points) {
    final List<double> out = List<double>.filled(points.length, 0);
    for (int i = 1; i < points.length; i++) {
      out[i] = out[i - 1] + distance(points[i - 1], points[i]);
    }
    return out;
  }

  // ---------------------------------------------------------------------------------------------- projections

  /// Web Mercator metres (EPSG:3857) of a point.
  static Offset toMercator(LatLng p) {
    final double lat = p.latitude.clamp(-85.05112878, 85.05112878);
    return Offset(mercatorRadius * _rad(p.longitude), mercatorRadius * math.log(math.tan(math.pi / 4 + _rad(lat) / 2)));
  }

  /// Point of Web Mercator metres.
  static LatLng fromMercator(Offset m) => safe(_deg(2 * math.atan(math.exp(m.dy / mercatorRadius)) - math.pi / 2), _deg(m.dx / mercatorRadius));

  /// Local flat metres around [origin] (x east, y north); accurate for a few hundred kilometres.
  static Offset toLocal(LatLng p, LatLng origin) =>
      Offset(_rad(p.longitude - origin.longitude) * earthRadius * math.cos(_rad(origin.latitude)), _rad(p.latitude - origin.latitude) * earthRadius);

  /// Inverse of [toLocal].
  static LatLng fromLocal(Offset m, LatLng origin) =>
      safe(origin.latitude + _deg(m.dy / earthRadius), origin.longitude + _deg(m.dx / (earthRadius * math.cos(_rad(origin.latitude)))));

  /// Centre of the box around [points], used as a local origin.
  static LatLng origin(Iterable<LatLng> points) {
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;
    for (final LatLng p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    if (minLat > maxLat) return const LatLng(0, 0);
    return LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  }

  // ---------------------------------------------------------------------------------------------- areas & centres

  /// Signed spherical area of a ring in m² (positive = counter-clockwise).
  static double signedArea(List<LatLng> ring) {
    final int n = ring.length;
    if (n < 3) return 0;
    double total = 0;
    for (int i = 0; i < n; i++) {
      final LatLng p1 = ring[i];
      final LatLng p2 = ring[(i + 1) % n];
      final LatLng p3 = ring[(i + 2) % n];
      total += (_rad(p3.longitude) - _rad(p1.longitude)) * math.sin(_rad(p2.latitude));
    }
    return -total * earthRadius * earthRadius / 2;
  }

  /// Area of a ring in m².
  static double ringArea(List<LatLng> ring) => signedArea(ring).abs();

  /// Area of a polygon (outline minus holes) in m².
  static double area(List<List<LatLng>> rings) {
    if (rings.isEmpty) return 0;
    double total = ringArea(rings.first);
    for (int i = 1; i < rings.length; i++) {
      total -= ringArea(rings[i]);
    }
    return math.max(0, total);
  }

  /// Perimeter of a ring in metres (closing edge included).
  static double perimeter(List<LatLng> ring) {
    if (ring.length < 2) return 0;
    return length(ring) + (ring.first == ring.last ? 0 : distance(ring.last, ring.first));
  }

  /// True when the ring runs clockwise (on a north-up map).
  static bool isClockwise(List<LatLng> ring) {
    double sum = 0;
    for (int i = 0; i < ring.length; i++) {
      final LatLng a = ring[i];
      final LatLng b = ring[(i + 1) % ring.length];
      sum += (b.longitude - a.longitude) * (b.latitude + a.latitude);
    }
    return sum > 0;
  }

  /// Average of the points (closing duplicate ignored).
  static LatLng centroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    final List<LatLng> list = points.length > 1 && points.first == points.last ? points.sublist(0, points.length - 1) : points;
    double lat = 0;
    double lng = 0;
    for (final LatLng p in list) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / list.length, lng / list.length);
  }

  /// Area-weighted centre of a ring (may fall outside concave shapes; use [polylabel] for labels).
  static LatLng polygonCentroid(List<LatLng> ring) {
    if (ring.length < 3) return centroid(ring);
    final LatLng o = origin(ring);
    double a = 0;
    double cx = 0;
    double cy = 0;
    for (int i = 0; i < ring.length; i++) {
      final Offset p = toLocal(ring[i], o);
      final Offset q = toLocal(ring[(i + 1) % ring.length], o);
      final double cross = p.dx * q.dy - q.dx * p.dy;
      a += cross;
      cx += (p.dx + q.dx) * cross;
      cy += (p.dy + q.dy) * cross;
    }
    if (a.abs() < 1e-9) return centroid(ring);
    return fromLocal(Offset(cx / (3 * a), cy / (3 * a)), o);
  }

  /// The point deepest inside a polygon (pole of inaccessibility) — best spot for a label. [precision] in metres.
  static LatLng polylabel(List<List<LatLng>> rings, {double precision = 1}) {
    if (rings.isEmpty || rings.first.length < 3) return centroid(rings.isEmpty ? const <LatLng>[] : rings.first);
    final LatLng o = origin(rings.first);
    final List<List<Offset>> poly = rings.map((List<LatLng> r) => r.map((LatLng p) => toLocal(p, o)).toList()).toList();
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    for (final Offset p in poly.first) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    final double width = maxX - minX;
    final double height = maxY - minY;
    final double cellSize = math.min(width, height);
    if (cellSize == 0) return fromLocal(Offset(minX, minY), o);
    double h = cellSize / 2;
    final UGeoHeap<_Cell> queue = UGeoHeap<_Cell>((_Cell a, _Cell b) => b.max.compareTo(a.max));
    for (double x = minX; x < maxX; x += cellSize) {
      for (double y = minY; y < maxY; y += cellSize) {
        queue.push(_Cell(x + h, y + h, h, poly));
      }
    }
    _Cell best = _Cell(_planarCentroid(poly.first).dx, _planarCentroid(poly.first).dy, 0, poly);
    final _Cell boxCell = _Cell(minX + width / 2, minY + height / 2, 0, poly);
    if (boxCell.d > best.d) best = boxCell;
    int guard = 0;
    while (queue.isNotEmpty && guard++ < 100000) {
      final _Cell cell = queue.pop();
      if (cell.d > best.d) best = cell;
      if (cell.max - best.d <= precision) continue;
      h = cell.h / 2;
      queue.push(_Cell(cell.x - h, cell.y - h, h, poly));
      queue.push(_Cell(cell.x + h, cell.y - h, h, poly));
      queue.push(_Cell(cell.x - h, cell.y + h, h, poly));
      queue.push(_Cell(cell.x + h, cell.y + h, h, poly));
    }
    return fromLocal(Offset(best.x, best.y), o);
  }

  static Offset _planarCentroid(List<Offset> ring) {
    double a = 0;
    double cx = 0;
    double cy = 0;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final Offset p = ring[i];
      final Offset q = ring[j];
      final double f = p.dx * q.dy - q.dx * p.dy;
      cx += (p.dx + q.dx) * f;
      cy += (p.dy + q.dy) * f;
      a += f * 3;
    }
    if (a == 0) return ring.first;
    return Offset(cx / a, cy / a);
  }

  /// Signed distance (metres, positive inside) from a local point to a planar polygon; used by [polylabel].
  static double planarPolygonDistance(double x, double y, List<List<Offset>> polygon) {
    bool inside = false;
    double minSq = double.infinity;
    for (final List<Offset> ring in polygon) {
      for (int i = 0, len = ring.length, j = len - 1; i < len; j = i++) {
        final Offset a = ring[i];
        final Offset b = ring[j];
        if ((a.dy > y) != (b.dy > y) && x < (b.dx - a.dx) * (y - a.dy) / (b.dy - a.dy) + a.dx) inside = !inside;
        minSq = math.min(minSq, _segDistSq(x, y, a, b));
      }
    }
    return (inside ? 1 : -1) * math.sqrt(minSq);
  }

  static double _segDistSq(double px, double py, Offset a, Offset b) {
    double x = a.dx;
    double y = a.dy;
    double dx = b.dx - x;
    double dy = b.dy - y;
    if (dx != 0 || dy != 0) {
      final double t = ((px - x) * dx + (py - y) * dy) / (dx * dx + dy * dy);
      if (t > 1) {
        x = b.dx;
        y = b.dy;
      } else if (t > 0) {
        x += dx * t;
        y += dy * t;
      }
    }
    dx = px - x;
    dy = py - y;
    return dx * dx + dy * dy;
  }

  /// Box around points, or null when empty.
  static LatLngBounds? boundsOf(Iterable<LatLng> points) {
    final List<LatLng> list = points.toList();
    return list.isEmpty ? null : LatLngBounds.fromPoints(list);
  }

  /// The four corners of a box as a closed ring.
  static List<LatLng> boundsRing(LatLngBounds b) => <LatLng>[b.southWest, b.southEast, b.northEast, b.northWest, b.southWest];

  // ---------------------------------------------------------------------------------------------- containment

  /// True when [p] is inside the ring (ray casting; edges count as inside-ish).
  static bool ringContains(List<LatLng> ring, LatLng p) {
    bool inside = false;
    final double x = p.longitude;
    final double y = p.latitude;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final double xi = ring[i].longitude;
      final double yi = ring[i].latitude;
      final double xj = ring[j].longitude;
      final double yj = ring[j].latitude;
      if (((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) inside = !inside;
    }
    return inside;
  }

  /// True when [p] is inside the polygon's outline and outside its holes.
  static bool polygonContains(List<List<LatLng>> rings, LatLng p) {
    if (rings.isEmpty || !ringContains(rings.first, p)) return false;
    for (int i = 1; i < rings.length; i++) {
      if (ringContains(rings[i], p)) return false;
    }
    return true;
  }

  /// True when [p] is inside any part of a geometry (points/lines use [tolerance] metres).
  static bool geometryContains(UGeoGeometry g, LatLng p, {double tolerance = 10}) => switch (g) {
    UGeoPoint() => distance(g.point, p) <= tolerance,
    UGeoMultiPoint() => g.points.any((LatLng q) => distance(q, p) <= tolerance),
    UGeoLine() => distanceToLine(p, g.points) <= tolerance,
    UGeoMultiLine() => g.lines.any((List<LatLng> l) => distanceToLine(p, l) <= tolerance),
    UGeoPolygon() => polygonContains(g.rings, p),
    UGeoMultiPolygon() => g.polygons.any((List<List<LatLng>> r) => polygonContains(r, p)),
    UGeoCollection() => g.geometries.any((UGeoGeometry x) => geometryContains(x, p, tolerance: tolerance)),
  };

  /// Distance in metres from [p] to the segment a–b.
  static double distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final Offset pa = toLocal(a, p);
    final Offset pb = toLocal(b, p);
    return math.sqrt(_segDistSq(0, 0, pa, pb));
  }

  /// Distance in metres from [p] to the nearest point of a path.
  static double distanceToLine(LatLng p, List<LatLng> points) {
    if (points.isEmpty) return double.infinity;
    if (points.length == 1) return distance(p, points.first);
    double best = double.infinity;
    for (int i = 1; i < points.length; i++) {
      best = math.min(best, distanceToSegment(p, points[i - 1], points[i]));
    }
    return best;
  }

  /// Nearest point of a path to [p], with segment index, distance and position along the path.
  static UGeoNearest nearestOnLine(List<LatLng> points, LatLng p) {
    if (points.length < 2) {
      final LatLng only = points.isEmpty ? p : points.first;
      return UGeoNearest(point: only, index: 0, distance: distance(p, only), along: 0);
    }
    double bestDistance = double.infinity;
    LatLng bestPoint = points.first;
    int bestIndex = 0;
    double bestAlong = 0;
    double walked = 0;
    for (int i = 1; i < points.length; i++) {
      final LatLng a = points[i - 1];
      final LatLng b = points[i];
      final Offset la = toLocal(a, p);
      final Offset lb = toLocal(b, p);
      final double dx = lb.dx - la.dx;
      final double dy = lb.dy - la.dy;
      final double lenSq = dx * dx + dy * dy;
      double t = lenSq == 0 ? 0 : (-la.dx * dx - la.dy * dy) / lenSq;
      t = t.clamp(0.0, 1.0);
      final Offset q = Offset(la.dx + dx * t, la.dy + dy * t);
      final double d = q.distance;
      final double segment = distance(a, b);
      if (d < bestDistance) {
        bestDistance = d;
        bestPoint = fromLocal(q, p);
        bestIndex = i - 1;
        bestAlong = walked + segment * t;
      }
      walked += segment;
    }
    return UGeoNearest(point: bestPoint, index: bestIndex, distance: bestDistance, along: bestAlong);
  }

  /// Point [meters] along a path (clamped to its ends).
  static LatLng along(List<LatLng> points, double meters) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (meters <= 0) return points.first;
    double walked = 0;
    for (int i = 1; i < points.length; i++) {
      final double segment = distance(points[i - 1], points[i]);
      if (walked + segment >= meters) return segment == 0 ? points[i] : interpolate(points[i - 1], points[i], (meters - walked) / segment);
      walked += segment;
    }
    return points.last;
  }

  /// Direction of travel (degrees) at [meters] along a path.
  static double bearingAlong(List<LatLng> points, double meters) {
    if (points.length < 2) return 0;
    double walked = 0;
    for (int i = 1; i < points.length; i++) {
      final double segment = distance(points[i - 1], points[i]);
      if (walked + segment >= meters && segment > 0) return bearing(points[i - 1], points[i]);
      walked += segment;
    }
    return bearing(points[points.length - 2], points.last);
  }

  /// The part of a path between two distances from its start (metres).
  static List<LatLng> slice(List<LatLng> points, double start, double end) {
    if (points.length < 2 || end <= start) return <LatLng>[];
    final List<LatLng> out = <LatLng>[along(points, start)];
    double walked = 0;
    for (int i = 1; i < points.length; i++) {
      walked += distance(points[i - 1], points[i]);
      if (walked > start && walked < end) out.add(points[i]);
      if (walked >= end) break;
    }
    out.add(along(points, end));
    return out;
  }

  // ---------------------------------------------------------------------------------------------- intersections

  /// Crossing point of segments a1–a2 and b1–b2, or null (flat-earth math; fine for short segments).
  static LatLng? segmentIntersection(LatLng a1, LatLng a2, LatLng b1, LatLng b2) {
    final double x1 = a1.longitude;
    final double y1 = a1.latitude;
    final double x2 = a2.longitude;
    final double y2 = a2.latitude;
    final double x3 = b1.longitude;
    final double y3 = b1.latitude;
    final double x4 = b2.longitude;
    final double y4 = b2.latitude;
    final double denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
    if (denom == 0) return null;
    final double ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom;
    final double ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom;
    if (ua < 0 || ua > 1 || ub < 0 || ub > 1) return null;
    return LatLng(y1 + ua * (y2 - y1), x1 + ua * (x2 - x1));
  }

  /// Every point where two paths cross.
  static List<LatLng> lineIntersections(List<LatLng> a, List<LatLng> b) {
    final List<LatLng> out = <LatLng>[];
    for (int i = 1; i < a.length; i++) {
      for (int j = 1; j < b.length; j++) {
        final LatLng? x = segmentIntersection(a[i - 1], a[i], b[j - 1], b[j]);
        if (x != null && !out.contains(x)) out.add(x);
      }
    }
    return out;
  }

  /// Points where a path or ring crosses itself.
  static List<LatLng> kinks(List<LatLng> points) {
    final List<LatLng> out = <LatLng>[];
    for (int i = 1; i < points.length; i++) {
      for (int j = i + 2; j < points.length; j++) {
        if (i == 1 && j == points.length - 1 && points.first == points.last) continue;
        final LatLng? x = segmentIntersection(points[i - 1], points[i], points[j - 1], points[j]);
        if (x != null) out.add(x);
      }
    }
    return out;
  }

  /// True when two paths cross or touch.
  static bool linesIntersect(List<LatLng> a, List<LatLng> b) {
    for (int i = 1; i < a.length; i++) {
      for (int j = 1; j < b.length; j++) {
        if (segmentIntersection(a[i - 1], a[i], b[j - 1], b[j]) != null) return true;
      }
    }
    return false;
  }

  /// True when two polygons overlap (shared area, crossing edges or one inside the other).
  static bool polygonsIntersect(List<LatLng> a, List<LatLng> b) =>
      linesIntersect(a, b) || (b.isNotEmpty && ringContains(a, b.first)) || (a.isNotEmpty && ringContains(b, a.first));

  // ---------------------------------------------------------------------------------------------- shapes

  /// A circle of [radius] metres as a closed ring (true metres, not pixels).
  static List<LatLng> circle(LatLng center, double radius, {int segments = 64}) =>
      <LatLng>[for (int i = 0; i <= segments; i++) destination(center, radius, 360 * i / segments)];

  /// A pie slice of a circle between two bearings, as a closed ring.
  static List<LatLng> sector(LatLng center, double radius, double fromBearing, double toBearing, {int segments = 32}) {
    double sweep = (toBearing - fromBearing) % 360;
    if (sweep <= 0) sweep += 360;
    return <LatLng>[center, for (int i = 0; i <= segments; i++) destination(center, radius, fromBearing + sweep * i / segments), center];
  }

  /// An ellipse with semi-axes in metres, rotated by [rotation] degrees.
  static List<LatLng> ellipse(LatLng center, double semiMajor, double semiMinor, {double rotation = 0, int segments = 64}) {
    final List<LatLng> out = <LatLng>[];
    for (int i = 0; i <= segments; i++) {
      final double t = 2 * math.pi * i / segments;
      final double x = semiMajor * math.cos(t);
      final double y = semiMinor * math.sin(t);
      final double r = _rad(-rotation);
      out.add(fromLocal(Offset(x * math.cos(r) - y * math.sin(r), x * math.sin(r) + y * math.cos(r)), center));
    }
    return out;
  }

  // ---------------------------------------------------------------------------------------------- simplify & smooth

  /// Fewer points, same shape: Douglas–Peucker with [tolerance] metres.
  static List<LatLng> simplify(List<LatLng> points, double tolerance) {
    if (points.length < 3) return List<LatLng>.of(points);
    final LatLng o = origin(points);
    final List<Offset> xy = points.map((LatLng p) => toLocal(p, o)).toList();
    final List<bool> keep = List<bool>.filled(points.length, false);
    keep[0] = true;
    keep[points.length - 1] = true;
    final List<(int, int)> stack = <(int, int)>[(0, points.length - 1)];
    final double tolSq = tolerance * tolerance;
    while (stack.isNotEmpty) {
      final (int first, int last) = stack.removeLast();
      double maxSq = 0;
      int index = -1;
      for (int i = first + 1; i < last; i++) {
        final double d = _segDistSq(xy[i].dx, xy[i].dy, xy[first], xy[last]);
        if (d > maxSq) {
          maxSq = d;
          index = i;
        }
      }
      if (index >= 0 && maxSq > tolSq) {
        keep[index] = true;
        stack.add((first, index));
        stack.add((index, last));
      }
    }
    return <LatLng>[for (int i = 0; i < points.length; i++) if (keep[i]) points[i]];
  }

  /// Fewer points by removing the least important ones (Visvalingam–Whyatt) until [keep] remain.
  static List<LatLng> visvalingam(List<LatLng> points, int keep) {
    if (points.length <= math.max(2, keep)) return List<LatLng>.of(points);
    final LatLng o = origin(points);
    final List<Offset> xy = points.map((LatLng p) => toLocal(p, o)).toList();
    final List<int> prev = List<int>.generate(points.length, (int i) => i - 1);
    final List<int> next = List<int>.generate(points.length, (int i) => i + 1);
    final List<double> areas = List<double>.filled(points.length, double.infinity);
    double triangle(int i) {
      final Offset a = xy[prev[i]];
      final Offset b = xy[i];
      final Offset c = xy[next[i]];
      return ((a.dx - c.dx) * (b.dy - a.dy) - (a.dx - b.dx) * (c.dy - a.dy)).abs() / 2;
    }

    final UGeoHeap<(double, int)> heap = UGeoHeap<(double, int)>(((double, int) a, (double, int) b) => a.$1.compareTo(b.$1));
    for (int i = 1; i < points.length - 1; i++) {
      areas[i] = triangle(i);
      heap.push((areas[i], i));
    }
    final List<bool> removed = List<bool>.filled(points.length, false);
    int remaining = points.length;
    while (remaining > keep && heap.isNotEmpty) {
      final (double area, int i) = heap.pop();
      if (removed[i] || area != areas[i]) continue;
      removed[i] = true;
      remaining--;
      final int p = prev[i];
      final int n = next[i];
      next[p] = n;
      prev[n] = p;
      for (final int j in <int>[p, n]) {
        if (j > 0 && j < points.length - 1) {
          areas[j] = math.max(triangle(j), area);
          heap.push((areas[j], j));
        }
      }
    }
    return <LatLng>[for (int i = 0; i < points.length; i++) if (!removed[i]) points[i]];
  }

  /// Rounder path (Chaikin corner cutting), ends kept; [iterations] 1–4.
  static List<LatLng> smooth(List<LatLng> points, {int iterations = 2, bool closed = false}) {
    List<LatLng> current = points;
    for (int k = 0; k < iterations && current.length > 2; k++) {
      final List<LatLng> out = <LatLng>[if (!closed) current.first];
      final int n = closed ? current.length : current.length - 1;
      for (int i = 0; i < n; i++) {
        final LatLng a = current[i];
        final LatLng b = current[(i + 1) % current.length];
        out.add(LatLng(a.latitude * 0.75 + b.latitude * 0.25, a.longitude * 0.75 + b.longitude * 0.25));
        out.add(LatLng(a.latitude * 0.25 + b.latitude * 0.75, a.longitude * 0.25 + b.longitude * 0.75));
      }
      if (!closed) out.add(current.last);
      current = out;
    }
    return current;
  }

  /// Adds points so no segment is longer than [maxSegment] metres (great-circle).
  static List<LatLng> densify(List<LatLng> points, double maxSegment) {
    if (points.length < 2 || maxSegment <= 0) return List<LatLng>.of(points);
    final List<LatLng> out = <LatLng>[points.first];
    for (int i = 1; i < points.length; i++) {
      final double d = distance(points[i - 1], points[i]);
      final int pieces = (d / maxSegment).ceil();
      for (int k = 1; k <= pieces; k++) {
        out.add(k == pieces ? points[i] : interpolate(points[i - 1], points[i], k / pieces));
      }
    }
    return out;
  }
}

class _Cell {
  _Cell(this.x, this.y, this.h, List<List<Offset>> polygon) : d = UGeoMath.planarPolygonDistance(x, y, polygon) {
    max = d + h * math.sqrt2;
  }

  final double x;
  final double y;
  final double h;
  final double d;
  late final double max;
}

/// Small binary min-heap used by the map engines (smallest by [compare] pops first).
class UGeoHeap<T> {
  UGeoHeap(this.compare);

  final int Function(T a, T b) compare;
  final List<T> _items = <T>[];

  int get length => _items.length;

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  T get peek => _items.first;

  void push(T value) {
    _items.add(value);
    int i = _items.length - 1;
    while (i > 0) {
      final int parent = (i - 1) >> 1;
      if (compare(_items[i], _items[parent]) >= 0) break;
      final T tmp = _items[i];
      _items[i] = _items[parent];
      _items[parent] = tmp;
      i = parent;
    }
  }

  T pop() {
    final T top = _items.first;
    final T last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      int i = 0;
      while (true) {
        final int l = 2 * i + 1;
        final int r = l + 1;
        int smallest = i;
        if (l < _items.length && compare(_items[l], _items[smallest]) < 0) smallest = l;
        if (r < _items.length && compare(_items[r], _items[smallest]) < 0) smallest = r;
        if (smallest == i) break;
        final T tmp = _items[i];
        _items[i] = _items[smallest];
        _items[smallest] = tmp;
        i = smallest;
      }
    }
    return top;
  }
}
