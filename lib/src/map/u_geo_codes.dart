import "dart:math" as math;

import "package:u/utilities.dart";

/// A UTM coordinate: zone 1–60, latitude band letter, easting/northing in metres.
class UUtm {
  const UUtm({required this.zone, required this.band, required this.easting, required this.northing});

  final int zone;
  final String band;
  final double easting;
  final double northing;

  /// True for the northern hemisphere.
  bool get isNorth => band.compareTo("N") >= 0;

  @override
  String toString() => "$zone$band ${easting.toStringAsFixed(0)} ${northing.toStringAsFixed(0)}";
}

/// A map tile address (slippy-map z/x/y).
class UTileId {
  const UTileId(this.z, this.x, this.y);

  final int z;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) => other is UTileId && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  String toString() => "$z/$x/$y";
}

/// Coordinate encodings: Google polylines, geohash, Plus Codes, UTM, MGRS, DMS text and tile math (pure Dart). Use it through [UGeo].
abstract final class UGeoCodes {
  static const double _d2r = math.pi / 180;

  // ---------------------------------------------------------------------------------------------- encoded polyline

  /// Google encoded polyline text of points ([precision] 5 for Google/OSRM, 6 for Valhalla).
  static String encodePolyline(List<LatLng> points, {int precision = 5}) {
    final double factor = math.pow(10, precision).toDouble();
    final StringBuffer out = StringBuffer();
    int lastLat = 0;
    int lastLng = 0;
    void write(int value) {
      int v = value < 0 ? ~(value << 1) : value << 1;
      while (v >= 0x20) {
        out.writeCharCode((0x20 | (v & 0x1f)) + 63);
        v >>= 5;
      }
      out.writeCharCode(v + 63);
    }

    for (final LatLng p in points) {
      final int lat = (p.latitude * factor).round();
      final int lng = (p.longitude * factor).round();
      write(lat - lastLat);
      write(lng - lastLng);
      lastLat = lat;
      lastLng = lng;
    }
    return out.toString();
  }

  /// Points of a Google encoded polyline text.
  static List<LatLng> decodePolyline(String encoded, {int precision = 5}) {
    final double factor = math.pow(10, precision).toDouble();
    final List<LatLng> out = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;
    int read() {
      int shift = 0;
      int result = 0;
      int b;
      do {
        if (index >= encoded.length) return 0;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    }

    while (index < encoded.length) {
      lat += read();
      lng += read();
      out.add(UGeoMath.safe(lat / factor, lng / factor));
    }
    return out;
  }

  // ---------------------------------------------------------------------------------------------- geohash

  static const String _base32 = "0123456789bcdefghjkmnpqrstuvwxyz";

  /// Geohash text of a point; 9 characters ≈ 5 m.
  static String geohash(LatLng p, {int precision = 9}) {
    double minLat = -90;
    double maxLat = 90;
    double minLng = -180;
    double maxLng = 180;
    final StringBuffer out = StringBuffer();
    bool even = true;
    int bit = 0;
    int ch = 0;
    while (out.length < precision) {
      if (even) {
        final double mid = (minLng + maxLng) / 2;
        if (p.longitude >= mid) {
          ch = (ch << 1) | 1;
          minLng = mid;
        } else {
          ch <<= 1;
          maxLng = mid;
        }
      } else {
        final double mid = (minLat + maxLat) / 2;
        if (p.latitude >= mid) {
          ch = (ch << 1) | 1;
          minLat = mid;
        } else {
          ch <<= 1;
          maxLat = mid;
        }
      }
      even = !even;
      if (++bit == 5) {
        out.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return out.toString();
  }

  /// The box a geohash covers.
  static LatLngBounds geohashBounds(String hash) {
    double minLat = -90;
    double maxLat = 90;
    double minLng = -180;
    double maxLng = 180;
    bool even = true;
    for (final int code in hash.toLowerCase().codeUnits) {
      final int value = _base32.indexOf(String.fromCharCode(code));
      if (value < 0) break;
      for (int bit = 4; bit >= 0; bit--) {
        final bool on = (value >> bit) & 1 == 1;
        if (even) {
          final double mid = (minLng + maxLng) / 2;
          if (on) {
            minLng = mid;
          } else {
            maxLng = mid;
          }
        } else {
          final double mid = (minLat + maxLat) / 2;
          if (on) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        even = !even;
      }
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  /// Centre point of a geohash.
  static LatLng geohashCenter(String hash) => geohashBounds(hash).center;

  /// The 8 geohashes around one (N, NE, E, SE, S, SW, W, NW).
  static List<String> geohashNeighbors(String hash) {
    final LatLngBounds b = geohashBounds(hash);
    final double h = b.north - b.south;
    final double w = b.east - b.west;
    final LatLng c = b.center;
    final List<(int, int)> steps = <(int, int)>[(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)];
    return steps.map(((int, int) s) => geohash(UGeoMath.safe(c.latitude + s.$1 * h, c.longitude + s.$2 * w), precision: hash.length)).toList();
  }

  // ---------------------------------------------------------------------------------------------- plus codes

  static const String _olc = "23456789CFGHJMPQRVWX";

  /// Open Location Code (Plus Code) of a point, e.g. "8HJ7PFPQ+X2"; 10 digits ≈ 14 m, 11 ≈ 3 m.
  static String plusCode(LatLng p, {int length = 10}) {
    final int codeLength = length.clamp(2, 15);
    double lat = p.latitude.clamp(-90.0, 90.0);
    final double lng = ((p.longitude + 180) % 360 + 360) % 360 - 180;
    if (lat == 90) lat -= _latPrecision(codeLength);
    int latVal = ((lat + 90) * 25000000).floor();
    int lngVal = ((lng + 180) * 8192000).floor();
    String code = "";
    if (codeLength > 10) {
      for (int i = 0; i < 5; i++) {
        final int latDigit = latVal % 5;
        final int lngDigit = lngVal % 4;
        code = _olc[latDigit * 4 + lngDigit] + code;
        latVal ~/= 5;
        lngVal ~/= 4;
      }
    } else {
      latVal ~/= 3125;
      lngVal ~/= 1024;
    }
    for (int i = 0; i < 5; i++) {
      code = _olc[lngVal % 20] + code;
      code = _olc[latVal % 20] + code;
      latVal ~/= 20;
      lngVal ~/= 20;
    }
    code = "${code.substring(0, 8)}+${code.substring(8)}";
    if (codeLength < 8) return "${code.substring(0, codeLength)}${"0" * (8 - codeLength)}+";
    return code.substring(0, math.max(codeLength + 1, 9));
  }

  static double _latPrecision(int length) => length <= 10 ? math.pow(20, (length ~/ -2) + 2).toDouble() : math.pow(20, -3) / math.pow(5, length - 10);

  /// The box a full Plus Code covers (null when invalid or short — use [recoverPlusCode] first).
  static LatLngBounds? plusCodeBounds(String code) {
    final String clean = code.toUpperCase().replaceAll("+", "").replaceAll("0", "");
    if (clean.length < 2 || code.indexOf("+") != 8) return null;
    double lat = -90;
    double lng = -180;
    double place = 20;
    int i = 0;
    for (; i < math.min(clean.length, 10); i += 2) {
      final int a = _olc.indexOf(clean[i]);
      final int b = i + 1 < clean.length ? _olc.indexOf(clean[i + 1]) : 0;
      if (a < 0 || b < 0) return null;
      lat += a * place;
      lng += b * place;
      place /= 20;
    }
    double latRes = place * 20;
    double lngRes = place * 20;
    if (clean.length > 10) {
      double latPlace = 0.000125 / 5;
      double lngPlace = 0.000125 / 4;
      for (i = 10; i < clean.length; i++) {
        final int idx = _olc.indexOf(clean[i]);
        if (idx < 0) return null;
        lat += (idx ~/ 4) * latPlace;
        lng += (idx % 4) * lngPlace;
        latRes = latPlace;
        lngRes = lngPlace;
        latPlace /= 5;
        lngPlace /= 4;
      }
    }
    return LatLngBounds(UGeoMath.safe(lat, lng), UGeoMath.safe(math.min(90, lat + latRes), math.min(180, lng + lngRes)));
  }

  /// Centre of a Plus Code; short codes like "PFPQ+X2" need a nearby [reference].
  static LatLng? plusCodeCenter(String code, {LatLng? reference}) {
    final String full = code.indexOf("+") < 8 && reference != null ? recoverPlusCode(code, reference) : code;
    return plusCodeBounds(full)?.center;
  }

  /// Short Plus Code (drops the first 4 digits) when [reference] is close enough.
  static String shortenPlusCode(String code, LatLng reference) {
    final LatLng? c = plusCodeCenter(code);
    if (c == null || code.indexOf("+") != 8) return code;
    final double range = math.max((c.latitude - reference.latitude).abs(), (c.longitude - reference.longitude).abs());
    if (range < 0.05 * 0.3) return code.substring(6);
    if (range < 1 * 0.3) return code.substring(4);
    return code;
  }

  /// Full Plus Code from a short one and a nearby point.
  static String recoverPlusCode(String shortCode, LatLng reference) {
    final String code = shortCode.toUpperCase();
    final int separator = code.indexOf("+");
    if (separator >= 8 || separator < 0) return code;
    final int padding = 8 - separator;
    final double resolution = math.pow(20, 2 - padding / 2).toDouble();
    final double half = resolution / 2;
    final String prefix = plusCode(reference).substring(0, padding);
    final String full = prefix + code;
    final LatLng? center = plusCodeBounds(full)?.center;
    if (center == null) return full;
    double lat = center.latitude;
    double lng = center.longitude;
    if (reference.latitude + half < lat && lat - resolution >= -90) {
      lat -= resolution;
    } else if (reference.latitude - half > lat && lat + resolution <= 90) {
      lat += resolution;
    }
    if (reference.longitude + half < lng) {
      lng -= resolution;
    } else if (reference.longitude - half > lng) {
      lng += resolution;
    }
    final String fixed = plusCode(UGeoMath.safe(lat, lng), length: full.replaceAll("+", "").length);
    return fixed;
  }

  // ---------------------------------------------------------------------------------------------- UTM & MGRS

  static const double _a = 6378137;
  static const double _f = 1 / 298.257223563;
  static const double _k0 = 0.9996;

  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

  static double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;

  static double _atanh(double x) => 0.5 * math.log((1 + x) / (1 - x));

  static double _asinh(double x) => math.log(x + math.sqrt(x * x + 1));

  /// UTM zone, band, easting and northing of a point (latitudes −80…84).
  static UUtm toUtm(LatLng p, {int? forceZone}) {
    final double lat = p.latitude;
    final double lng = p.longitude;
    int zone = forceZone ?? ((lng + 180) / 6).floor() + 1;
    if (forceZone == null) {
      if (lat >= 56 && lat < 64 && lng >= 3 && lng < 12) zone = 32;
      if (lat >= 72 && lat < 84) {
        if (lng >= 0 && lng < 9) {
          zone = 31;
        } else if (lng >= 9 && lng < 21) {
          zone = 33;
        } else if (lng >= 21 && lng < 33) {
          zone = 35;
        } else if (lng >= 33 && lng < 42) {
          zone = 37;
        }
      }
    }
    zone = zone.clamp(1, 60);
    final double lng0 = (zone - 1) * 6 - 180 + 3;
    const double n = _f / (2 - _f);
    const double bigA = _a / (1 + n) * (1 + n * n / 4 + n * n * n * n / 64);
    final List<double> alpha = <double>[n / 2 - 2 / 3 * n * n + 5 / 16 * n * n * n, 13 / 48 * n * n - 3 / 5 * n * n * n, 61 / 240 * n * n * n];
    final double phi = lat * _d2r;
    final double dl = (lng - lng0) * _d2r;
    final double c = 2 * math.sqrt(n) / (1 + n);
    final double t = _sinh(_atanh(math.sin(phi)) - c * _atanh(c * math.sin(phi)));
    final double xiP = math.atan2(t, math.cos(dl));
    final double etaP = _atanh(math.sin(dl) / math.sqrt(1 + t * t));
    double e = etaP;
    double nn = xiP;
    for (int j = 1; j <= 3; j++) {
      e += alpha[j - 1] * math.cos(2 * j * xiP) * _sinh(2 * j * etaP);
      nn += alpha[j - 1] * math.sin(2 * j * xiP) * _cosh(2 * j * etaP);
    }
    final double easting = 500000 + _k0 * bigA * e;
    double northing = _k0 * bigA * nn;
    if (lat < 0) northing += 10000000;
    return UUtm(zone: zone, band: _band(lat), easting: easting, northing: northing);
  }

  static String _band(double lat) {
    const String bands = "CDEFGHJKLMNPQRSTUVWXX";
    final int i = ((lat + 80) / 8).floor().clamp(0, bands.length - 1);
    return bands[i];
  }

  /// Point of a UTM coordinate.
  static LatLng fromUtm(UUtm utm) => fromUtmParts(utm.zone, utm.isNorth, utm.easting, utm.northing);

  /// Point of UTM zone, hemisphere, easting and northing.
  static LatLng fromUtmParts(int zone, bool north, double easting, double northing) {
    const double n = _f / (2 - _f);
    const double bigA = _a / (1 + n) * (1 + n * n / 4 + n * n * n * n / 64);
    final List<double> beta = <double>[n / 2 - 2 / 3 * n * n + 37 / 96 * n * n * n, 1 / 48 * n * n + 1 / 15 * n * n * n, 17 / 480 * n * n * n];
    final List<double> delta = <double>[2 * n - 2 / 3 * n * n - 2 * n * n * n, 7 / 3 * n * n - 8 / 5 * n * n * n, 56 / 15 * n * n * n];
    final double xi = (northing - (north ? 0 : 10000000)) / (_k0 * bigA);
    final double eta = (easting - 500000) / (_k0 * bigA);
    double xiP = xi;
    double etaP = eta;
    for (int j = 1; j <= 3; j++) {
      xiP -= beta[j - 1] * math.sin(2 * j * xi) * _cosh(2 * j * eta);
      etaP -= beta[j - 1] * math.cos(2 * j * xi) * _sinh(2 * j * eta);
    }
    final double chi = math.asin(math.sin(xiP) / _cosh(etaP));
    double phi = chi;
    for (int j = 1; j <= 3; j++) {
      phi += delta[j - 1] * math.sin(2 * j * chi);
    }
    final double lng0 = (zone - 1) * 6 - 180 + 3;
    final double lambda = lng0 * _d2r + math.atan2(_sinh(etaP), math.cos(xiP));
    return UGeoMath.safe(phi / _d2r, lambda / _d2r);
  }

  static const List<String> _mgrsColumns = <String>["ABCDEFGH", "JKLMNPQR", "STUVWXYZ"];
  static const String _mgrsRows = "ABCDEFGHJKLMNPQRSTUV";

  /// MGRS (military grid) text, e.g. "39SWV 33972 49960"; [digits] 1–5 per axis (5 = 1 m).
  static String toMgrs(LatLng p, {int digits = 5}) {
    final UUtm u = toUtm(p);
    final String column = _mgrsColumns[(u.zone - 1) % 3][((u.easting / 100000).floor() - 1).clamp(0, 7)];
    final int rowIndex = ((u.northing / 100000).floor() + (u.zone.isEven ? 5 : 0)) % 20;
    final String row = _mgrsRows[rowIndex];
    final int d = digits.clamp(1, 5);
    final int divisor = math.pow(10, 5 - d).toInt();
    final String e = ((u.easting % 100000) ~/ divisor).toString().padLeft(d, "0");
    final String nn = ((u.northing % 100000) ~/ divisor).toString().padLeft(d, "0");
    return "${u.zone}${u.band}$column$row $e $nn";
  }

  /// Point of an MGRS text (spaces optional).
  static LatLng? fromMgrs(String text) {
    final RegExpMatch? m = RegExp(r"^(\d{1,2})([C-HJ-NP-X])([A-HJ-NP-Z])([A-HJ-NP-V])(\d*)$").firstMatch(text.toUpperCase().replaceAll(RegExp(r"\s"), ""));
    if (m == null) return null;
    final int zone = int.parse(m.group(1)!);
    final String band = m.group(2)!;
    final String digits = m.group(5)!;
    if (digits.length.isOdd) return null;
    final int half = digits.length ~/ 2;
    final double scale = half == 0 ? 0 : math.pow(10, 5 - half).toDouble();
    final double e = half == 0 ? 0 : double.parse(digits.substring(0, half)) * scale;
    final double n = half == 0 ? 0 : double.parse(digits.substring(half)) * scale;
    final int col = _mgrsColumns[(zone - 1) % 3].indexOf(m.group(3)!);
    final int rowLetter = _mgrsRows.indexOf(m.group(4)!);
    if (col < 0 || rowLetter < 0) return null;
    final double easting = (col + 1) * 100000 + e;
    final int rowIndex = (rowLetter - (zone.isEven ? 5 : 0) + 20) % 20;
    double northing = rowIndex * 100000 + n;
    final bool north = band.compareTo("N") >= 0;
    const String bands = "CDEFGHJKLMNPQRSTUVWX";
    final double bandLat = -80 + bands.indexOf(band) * 8.0;
    final double minNorthing = toUtm(LatLng(bandLat, (zone - 1) * 6 - 180 + 3), forceZone: zone).northing;
    while (northing < minNorthing - 100000) {
      northing += 2000000;
    }
    return fromUtmParts(zone, north, easting, northing);
  }

  // ---------------------------------------------------------------------------------------------- DMS text

  /// Degrees-minutes-seconds text, e.g. 35°41'59.0"N 51°23'20.0"E; [persian] uses Persian digits.
  static String toDms(LatLng p, {int decimals = 1, bool persian = false}) {
    String part(double value, String pos, String neg) {
      final double v = value.abs();
      int d = v.floor();
      int m = ((v - d) * 60).floor();
      double s = ((v - d) * 60 - m) * 60;
      if (double.parse(s.toStringAsFixed(decimals)) >= 60) {
        s = 0;
        m++;
      }
      if (m >= 60) {
        m = 0;
        d++;
      }
      return "$d°$m'${s.toStringAsFixed(decimals)}\"${value >= 0 ? pos : neg}";
    }

    final String text = "${part(p.latitude, "N", "S")} ${part(p.longitude, "E", "W")}";
    return persian ? text.toPersianNumber() : text;
  }

  /// Degrees and decimal minutes text, e.g. N35°41.983' E51°23.333'.
  static String toDdm(LatLng p, {int decimals = 3}) {
    String part(double value, String pos, String neg) {
      final double v = value.abs();
      final int d = v.floor();
      return "${value >= 0 ? pos : neg}$d°${((v - d) * 60).toStringAsFixed(decimals)}'";
    }

    return "${part(p.latitude, "N", "S")} ${part(p.longitude, "E", "W")}";
  }

  /// Reads coordinates typed in any common form: "35.7, 51.4", DMS, DDM, N/S/E/W, Persian/Arabic digits. Null when not coordinates.
  static LatLng? parse(String text) {
    String s = text.trim();
    const String persian = "۰۱۲۳۴۵۶۷۸۹";
    const String arabic = "٠١٢٣٤٥٦٧٨٩";
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(persian[i], "$i").replaceAll(arabic[i], "$i");
    }
    s = s.replaceAll("٫", ".").replaceAll("،", ",").replaceAll("’", "'").replaceAll("″", "\"").replaceAll("′", "'").toUpperCase();
    final RegExp hemi = RegExp("[NSEW]");
    if (hemi.hasMatch(s)) {
      final List<String> halves = <String>[];
      final StringBuffer current = StringBuffer();
      bool hadNumber = false;
      for (int i = 0; i < s.length; i++) {
        final String ch = s[i];
        current.write(ch);
        if (RegExp(r"\d").hasMatch(ch)) hadNumber = true;
        if (hemi.hasMatch(ch) && hadNumber) {
          halves.add(current.toString());
          current.clear();
          hadNumber = false;
        }
      }
      if (current.toString().trim().isNotEmpty && halves.length == 1) {
        if (halves.first.contains(RegExp(r"\d"))) {
          halves.add(current.toString());
        } else {
          halves[0] = halves[0] + current.toString();
        }
      } else if (halves.isEmpty && current.isNotEmpty) {
        // Hemisphere letters lead the numbers (e.g. "N35 41.5 E51 24.2").
        final List<RegExpMatch> letters = hemi.allMatches(s).toList();
        if (letters.length == 2) {
          halves.add(s.substring(0, letters[1].start));
          halves.add(s.substring(letters[1].start));
        }
      }
      if (halves.length != 2) return null;
      double? lat;
      double? lng;
      for (final String h in halves) {
        final double? v = _angle(h);
        if (v == null) return null;
        if (h.contains("N") || h.contains("S")) {
          lat = h.contains("S") ? -v.abs() : v.abs();
        } else {
          lng = h.contains("W") ? -v.abs() : v.abs();
        }
      }
      if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) return null;
      return LatLng(lat, lng);
    }
    final List<double> numbers = RegExp(r"-?\d+(?:\.\d+)?").allMatches(s).map((RegExpMatch m) => double.parse(m.group(0)!)).toList();
    double? lat;
    double? lng;
    if (numbers.length == 2) {
      lat = numbers[0];
      lng = numbers[1];
    } else if (numbers.length == 4) {
      lat = numbers[0].sign * (numbers[0].abs() + numbers[1] / 60);
      lng = numbers[2].sign * (numbers[2].abs() + numbers[3] / 60);
    } else if (numbers.length == 6) {
      lat = numbers[0].sign * (numbers[0].abs() + numbers[1] / 60 + numbers[2] / 3600);
      lng = numbers[3].sign * (numbers[3].abs() + numbers[4] / 60 + numbers[5] / 3600);
    }
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  static double? _angle(String part) {
    final List<double> n = RegExp(r"\d+(?:\.\d+)?").allMatches(part).map((RegExpMatch m) => double.parse(m.group(0)!)).toList();
    if (n.isEmpty || n.length > 3) return null;
    double v = n[0];
    if (n.length > 1) v += n[1] / 60;
    if (n.length > 2) v += n[2] / 3600;
    return part.trim().startsWith("-") ? -v : v;
  }

  // ---------------------------------------------------------------------------------------------- tiles

  /// Tile containing a point at zoom [z].
  static UTileId tileOf(LatLng p, int z) {
    final int n = 1 << z;
    final double lat = p.latitude.clamp(-85.05112878, 85.05112878) * _d2r;
    final int x = ((p.longitude + 180) / 360 * n).floor().clamp(0, n - 1);
    final int y = ((1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * n).floor().clamp(0, n - 1);
    return UTileId(z, x, y);
  }

  /// North-west corner of a tile.
  static LatLng tileCorner(int z, int x, int y) {
    final int n = 1 << z;
    final double lng = x / n * 360 - 180;
    final double lat = math.atan(_sinh(math.pi * (1 - 2 * y / n))) / _d2r;
    return LatLng(lat, lng);
  }

  /// The box a tile covers.
  static LatLngBounds tileBounds(UTileId t) => LatLngBounds(tileCorner(t.z, t.x, t.y + 1), tileCorner(t.z, t.x + 1, t.y));

  /// Every tile covering a box at zoom [z].
  static Iterable<UTileId> tilesIn(LatLngBounds b, int z) sync* {
    final UTileId nw = tileOf(b.northWest, z);
    final UTileId se = tileOf(b.southEast, z);
    for (int x = nw.x; x <= se.x; x++) {
      for (int y = nw.y; y <= se.y; y++) {
        yield UTileId(z, x, y);
      }
    }
  }

  /// How many tiles cover a box between two zooms.
  static int tileCount(LatLngBounds b, int minZoom, int maxZoom) {
    int total = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final UTileId nw = tileOf(b.northWest, z);
      final UTileId se = tileOf(b.southEast, z);
      total += (se.x - nw.x + 1) * (se.y - nw.y + 1);
    }
    return total;
  }

  /// Bing-style quadkey of a tile.
  static String quadkey(UTileId t) {
    final StringBuffer out = StringBuffer();
    for (int i = t.z; i > 0; i--) {
      int digit = 0;
      final int mask = 1 << (i - 1);
      if ((t.x & mask) != 0) digit++;
      if ((t.y & mask) != 0) digit += 2;
      out.write(digit);
    }
    return out.toString();
  }

  /// Tile of a quadkey.
  static UTileId fromQuadkey(String key) {
    int x = 0;
    int y = 0;
    final int z = key.length;
    for (int i = z; i > 0; i--) {
      final int mask = 1 << (i - 1);
      switch (key[z - i]) {
        case "1":
          x |= mask;
        case "2":
          y |= mask;
        case "3":
          x |= mask;
          y |= mask;
      }
    }
    return UTileId(z, x, y);
  }

  /// Ground metres per screen pixel at a latitude and zoom (256-px tiles).
  static double metersPerPixel(double latitude, double zoom) => 156543.03392 * math.cos(latitude * _d2r) / math.pow(2, zoom);

  /// Inverse hyperbolic sine, exposed for tile math users.
  static double asinh(double x) => _asinh(x);
}
