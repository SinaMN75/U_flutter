import "package:u/components/u_barcode.dart" as barcode;
import "package:u/utilities.dart";

// =============================================================================
// u_code_decoder — self-contained, dependency-free barcode/QR decoding engine.
//
// Replaces the ML Kit / ZXing native decoders that `mobile_scanner` bundled, so
// the package ships zero native decoding libraries and zero downloadable models
// on every one of the six platforms. Everything below is pure Dart: it runs on
// camera frames, on still images, and inside an isolate.
//
// Nothing in this file is meant to be read while using the package — the public
// surface is [UCodeReader], [UCodeScanOptions] and [UCode].
// =============================================================================

enum UCodeFormat {
  qr,
  microQr,
  dataMatrix,
  aztec,
  pdf417,
  code128,
  code39,
  code93,
  codabar,
  itf,
  ean13,
  ean8,
  upcA,
  upcE,
  unknown,
}

extension UCodeFormatX on UCodeFormat {
  bool get isMatrix =>
      this == UCodeFormat.qr || this == UCodeFormat.microQr || this == UCodeFormat.dataMatrix || this == UCodeFormat.aztec || this == UCodeFormat.pdf417;

  bool get isLinear => !isMatrix && this != UCodeFormat.unknown;

  String get label {
    switch (this) {
      case UCodeFormat.qr:
        return "QR Code";
      case UCodeFormat.microQr:
        return "Micro QR Code";
      case UCodeFormat.dataMatrix:
        return "Data Matrix";
      case UCodeFormat.aztec:
        return "Aztec";
      case UCodeFormat.pdf417:
        return "PDF417";
      case UCodeFormat.code128:
        return "Code 128";
      case UCodeFormat.code39:
        return "Code 39";
      case UCodeFormat.code93:
        return "Code 93";
      case UCodeFormat.codabar:
        return "Codabar";
      case UCodeFormat.itf:
        return "ITF";
      case UCodeFormat.ean13:
        return "EAN-13";
      case UCodeFormat.ean8:
        return "EAN-8";
      case UCodeFormat.upcA:
        return "UPC-A";
      case UCodeFormat.upcE:
        return "UPC-E";
      case UCodeFormat.unknown:
        return "Unknown";
    }
  }
}

/// Where a decode came from, so callers can tell the Dart engine apart from a
/// zero-cost platform decoder (Apple Vision, the browser BarcodeDetector).
enum UCodeSource { dart, platform }

/// Type of payload a QR code carries, derived from the decoded text.
enum UCodeValueType { text, url, email, phone, sms, wifi, geo, calendar, contact, product, isbn, iban, upiPayment, unknown }

class UCodeStructuredAppend {
  const UCodeStructuredAppend({required this.index, required this.total, required this.parity});

  final int index;
  final int total;
  final int parity;
}

/// One decoded symbol.
class UCode {
  const UCode({
    required this.format,
    required this.text,
    required this.bytes,
    this.corners = const <Offset>[],
    this.eci,
    this.source = UCodeSource.dart,
    this.inverted = false,
    this.structuredAppend,
    this.errorCorrectionLevel,
    this.version,
    this.mask,
  });

  final UCodeFormat format;
  final String text;
  final Uint8List bytes;

  /// Symbol outline in source-image pixels, clockwise from the top-left.
  final List<Offset> corners;
  final int? eci;
  final UCodeSource source;
  final bool inverted;
  final UCodeStructuredAppend? structuredAppend;
  final String? errorCorrectionLevel;
  final int? version;
  final int? mask;

  Rect get rect {
    if (corners.isEmpty) return Rect.zero;
    double left = corners.first.dx;
    double top = corners.first.dy;
    double right = left;
    double bottom = top;
    for (final Offset point in corners) {
      if (point.dx < left) left = point.dx;
      if (point.dx > right) right = point.dx;
      if (point.dy < top) top = point.dy;
      if (point.dy > bottom) bottom = point.dy;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Offset get center {
    if (corners.isEmpty) return Offset.zero;
    double x = 0;
    double y = 0;
    for (final Offset point in corners) {
      x += point.dx;
      y += point.dy;
    }
    return Offset(x / corners.length, y / corners.length);
  }

  /// Rotation of the symbol in the source image, in degrees.
  double get angle {
    if (corners.length < 2) return 0;
    final Offset delta = corners[1] - corners[0];
    return atan2(delta.dy, delta.dx) * 180 / pi;
  }

  UCodeValueType get valueType => UCodeValue.typeOf(text, format);

  Map<String, String> get parsed => UCodeValue.parse(text, format);

  UCode translated(double dx, double dy) => UCode(
    format: format,
    text: text,
    bytes: bytes,
    corners: corners.map((Offset o) => Offset(o.dx + dx, o.dy + dy)).toList(growable: false),
    eci: eci,
    source: source,
    inverted: inverted,
    structuredAppend: structuredAppend,
    errorCorrectionLevel: errorCorrectionLevel,
    version: version,
    mask: mask,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    "format": format.name,
    "text": text,
    "bytes": bytes,
    "corners": corners.map((Offset o) => <double>[o.dx, o.dy]).toList(growable: false),
    "eci": eci,
    "inverted": inverted,
    "version": version,
  };

  static UCode fromMap(Map<Object?, Object?> map) {
    final Object? rawCorners = map["corners"];
    final List<Offset> corners = <Offset>[];
    if (rawCorners is List<Object?>) {
      for (final Object? entry in rawCorners) {
        if (entry is List<Object?> && entry.length >= 2) {
          corners.add(Offset(((entry[0] as num?) ?? 0).toDouble(), ((entry[1] as num?) ?? 0).toDouble()));
        }
      }
    }
    final Object? rawBytes = map["bytes"];
    return UCode(
      format: UCodeFormat.values.firstWhere((UCodeFormat f) => f.name == map["format"], orElse: () => UCodeFormat.unknown),
      text: (map["text"] as String?) ?? "",
      bytes: rawBytes is Uint8List ? rawBytes : Uint8List(0),
      corners: corners,
      eci: (map["eci"] as num?)?.toInt(),
      source: UCodeSource.platform,
      inverted: map["inverted"] == true,
      version: (map["version"] as num?)?.toInt(),
    );
  }

  @override
  String toString() => "UCode(${format.name}): $text";
}

/// Classifies and splits common QR payload conventions.
abstract class UCodeValue {
  static UCodeValueType typeOf(String text, UCodeFormat format) {
    if (format == UCodeFormat.ean13 || format == UCodeFormat.ean8 || format == UCodeFormat.upcA || format == UCodeFormat.upcE) {
      if (text.startsWith("978") || text.startsWith("979")) return UCodeValueType.isbn;
      return UCodeValueType.product;
    }
    final String upper = text.toUpperCase();
    if (upper.startsWith("HTTP://") || upper.startsWith("HTTPS://") || upper.startsWith("WWW.")) return UCodeValueType.url;
    if (upper.startsWith("MAILTO:") || upper.startsWith("MATMSG:")) return UCodeValueType.email;
    if (upper.startsWith("TEL:")) return UCodeValueType.phone;
    if (upper.startsWith("SMSTO:") || upper.startsWith("SMS:")) return UCodeValueType.sms;
    if (upper.startsWith("WIFI:")) return UCodeValueType.wifi;
    if (upper.startsWith("GEO:")) return UCodeValueType.geo;
    if (upper.startsWith("BEGIN:VEVENT")) return UCodeValueType.calendar;
    if (upper.startsWith("BEGIN:VCARD") || upper.startsWith("MECARD:")) return UCodeValueType.contact;
    if (upper.startsWith("UPI://")) return UCodeValueType.upiPayment;
    return UCodeValueType.text;
  }

  static Map<String, String> parse(String text, UCodeFormat format) {
    final UCodeValueType type = typeOf(text, format);
    switch (type) {
      case UCodeValueType.wifi:
        return _fields(text.substring(5), <String, String>{"S": "ssid", "T": "security", "P": "password", "H": "hidden"});
      case UCodeValueType.contact:
        if (text.toUpperCase().startsWith("MECARD:")) {
          return _fields(text.substring(7), <String, String>{"N": "name", "TEL": "phone", "EMAIL": "email", "ADR": "address", "URL": "url", "NOTE": "note"});
        }
        return _vcard(text);
      case UCodeValueType.geo:
        final List<String> parts = text.substring(4).split(RegExp("[,?]"));
        return <String, String>{
          if (parts.isNotEmpty) "latitude": parts[0],
          if (parts.length > 1) "longitude": parts[1],
          if (parts.length > 2) "altitude": parts[2],
        };
      case UCodeValueType.phone:
        return <String, String>{"number": text.substring(4)};
      case UCodeValueType.email:
        if (text.toUpperCase().startsWith("MAILTO:")) return <String, String>{"address": text.substring(7)};
        return _fields(text.substring(7), <String, String>{"TO": "address", "SUB": "subject", "BODY": "body"});
      case UCodeValueType.sms:
        final List<String> parts = text.split(":");
        return <String, String>{
          if (parts.length > 1) "number": parts[1],
          if (parts.length > 2) "message": parts.sublist(2).join(":"),
        };
      case UCodeValueType.url:
        return <String, String>{"url": text};
      case UCodeValueType.product:
      case UCodeValueType.isbn:
        return <String, String>{"code": text};
      case UCodeValueType.text:
      case UCodeValueType.calendar:
      case UCodeValueType.iban:
      case UCodeValueType.upiPayment:
      case UCodeValueType.unknown:
        return <String, String>{"text": text};
    }
  }

  static Map<String, String> _fields(String body, Map<String, String> keys) {
    final Map<String, String> out = <String, String>{};
    final StringBuffer token = StringBuffer();
    final List<String> segments = <String>[];
    for (int i = 0; i < body.length; i++) {
      final String ch = body[i];
      if (ch == r"\" && i + 1 < body.length) {
        token.write(body[i + 1]);
        i++;
        continue;
      }
      if (ch == ";") {
        segments.add(token.toString());
        token.clear();
        continue;
      }
      token.write(ch);
    }
    if (token.isNotEmpty) segments.add(token.toString());
    for (final String segment in segments) {
      final int separator = segment.indexOf(":");
      if (separator <= 0) continue;
      final String key = segment.substring(0, separator).toUpperCase();
      final String? name = keys[key];
      if (name != null) out[name] = segment.substring(separator + 1);
    }
    return out;
  }

  static Map<String, String> _vcard(String text) {
    final Map<String, String> out = <String, String>{};
    for (final String line in const LineSplitter().convert(text)) {
      final int separator = line.indexOf(":");
      if (separator <= 0) continue;
      final String key = line.substring(0, separator).split(";").first.toUpperCase();
      final String value = line.substring(separator + 1);
      switch (key) {
        case "FN":
        case "N":
          out.putIfAbsent("name", () => value.replaceAll(";", " ").trim());
          break;
        case "TEL":
          out.putIfAbsent("phone", () => value);
          break;
        case "EMAIL":
          out.putIfAbsent("email", () => value);
          break;
        case "ORG":
          out.putIfAbsent("organization", () => value);
          break;
        case "TITLE":
          out.putIfAbsent("title", () => value);
          break;
        case "ADR":
          out.putIfAbsent("address", () => value.replaceAll(";", " ").trim());
          break;
        case "URL":
          out.putIfAbsent("url", () => value);
          break;
      }
    }
    return out;
  }
}

class UCodeDecodeException implements Exception {
  const UCodeDecodeException(this.message);

  final String message;

  @override
  String toString() => "UCodeDecodeException: $message";
}

// =============================================================================
// Luminance + binarization
// =============================================================================

/// An 8-bit grayscale view over a frame or image, with cheap crop/rotate/scale.
class UGrayImage {
  UGrayImage(this.data, this.width, this.height, {this.rowStride = 0, this.left = 0, this.top = 0, this.sourceWidth = 0, this.sourceHeight = 0});

  final Uint8List data;
  final int width;
  final int height;

  /// Distance in bytes between the start of two rows. Zero means [width].
  final int rowStride;

  /// Offset of this view inside the original frame, used to map results back.
  final int left;
  final int top;
  final int sourceWidth;
  final int sourceHeight;

  int get stride => rowStride == 0 ? width : rowStride;

  bool get isEmpty => width <= 0 || height <= 0;

  int at(int x, int y) => data[y * stride + x];

  /// Copies one row into [into] (allocated when null).
  Uint8List row(int y, [Uint8List? into]) {
    final Uint8List out = into != null && into.length >= width ? into : Uint8List(width);
    final int offset = y * stride;
    for (int x = 0; x < width; x++) {
      out[x] = data[offset + x];
    }
    return out;
  }

  UGrayImage crop(int x, int y, int w, int h) {
    final int cx = x.clamp(0, width);
    final int cy = y.clamp(0, height);
    final int cw = w.clamp(0, width - cx);
    final int ch = h.clamp(0, height - cy);
    final Uint8List out = Uint8List(cw * ch);
    for (int row = 0; row < ch; row++) {
      final int src = (cy + row) * stride + cx;
      out.setRange(row * cw, row * cw + cw, data, src);
    }
    return UGrayImage(out, cw, ch, left: left + cx, top: top + cy, sourceWidth: sourceWidth == 0 ? width : sourceWidth, sourceHeight: sourceHeight == 0 ? height : sourceHeight);
  }

  /// Nearest-neighbour downscale by an integer [factor]; 1 returns this.
  UGrayImage downscale(int factor) {
    if (factor <= 1) return this;
    final int w = width ~/ factor;
    final int h = height ~/ factor;
    if (w <= 0 || h <= 0) return this;
    final Uint8List out = Uint8List(w * h);
    for (int y = 0; y < h; y++) {
      final int src = y * factor * stride;
      final int dst = y * w;
      for (int x = 0; x < w; x++) {
        out[dst + x] = data[src + x * factor];
      }
    }
    return UGrayImage(out, w, h, left: left, top: top, sourceWidth: sourceWidth == 0 ? width : sourceWidth, sourceHeight: sourceHeight == 0 ? height : sourceHeight);
  }

  UGrayImage rotate90() {
    final Uint8List out = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      final int src = y * stride;
      for (int x = 0; x < width; x++) {
        out[x * height + (height - 1 - y)] = data[src + x];
      }
    }
    return UGrayImage(out, height, width, left: left, top: top, sourceWidth: sourceWidth, sourceHeight: sourceHeight);
  }

  UGrayImage rotate180() {
    final Uint8List out = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      final int src = y * stride;
      final int dst = (height - 1 - y) * width;
      for (int x = 0; x < width; x++) {
        out[dst + (width - 1 - x)] = data[src + x];
      }
    }
    return UGrayImage(out, width, height, left: left, top: top, sourceWidth: sourceWidth, sourceHeight: sourceHeight);
  }

  UGrayImage rotate270() => rotate90().rotate180();

  UGrayImage inverted() {
    final Uint8List out = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      final int src = y * stride;
      final int dst = y * width;
      for (int x = 0; x < width; x++) {
        out[dst + x] = 255 - data[src + x];
      }
    }
    return UGrayImage(out, width, height, left: left, top: top, sourceWidth: sourceWidth, sourceHeight: sourceHeight);
  }

  /// Wraps the Y plane of a YUV420/NV21 frame without copying when possible.
  static UGrayImage fromLuminance(Uint8List plane, int width, int height, {int rowStride = 0}) => UGrayImage(plane, width, height, rowStride: rowStride);

  /// Builds a grayscale image from packed 32-bit pixels.
  static UGrayImage fromPacked(Uint8List pixels, int width, int height, {bool bgra = true, int rowStride = 0}) {
    final int stride = rowStride == 0 ? width * 4 : rowStride;
    final Uint8List out = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      int src = y * stride;
      final int dst = y * width;
      for (int x = 0; x < width; x++) {
        final int b = bgra ? pixels[src] : pixels[src + 2];
        final int g = pixels[src + 1];
        final int r = bgra ? pixels[src + 2] : pixels[src];
        out[dst + x] = (r * 77 + g * 151 + b * 28) >> 8;
        src += 4;
      }
    }
    return UGrayImage(out, width, height);
  }
}

/// A 1-bit image. `true` means a dark module.
class UBitMatrix {
  UBitMatrix(this.width, this.height) : bits = Uint8List(width * height);

  UBitMatrix.fromBits(this.width, this.height, this.bits);

  final int width;
  final int height;
  final Uint8List bits;

  bool get(int x, int y) => x >= 0 && y >= 0 && x < width && y < height && bits[y * width + x] != 0;

  void set(int x, int y, [bool value = true]) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    bits[y * width + x] = value ? 1 : 0;
  }

  void flip(int x, int y) => set(x, y, !get(x, y));

  UBitMatrix copy() => UBitMatrix.fromBits(width, height, Uint8List.fromList(bits));

  UBitMatrix rotate90() {
    final UBitMatrix out = UBitMatrix(height, width);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (get(x, y)) out.set(height - 1 - y, x);
      }
    }
    return out;
  }

  UBitMatrix rotate180() {
    final UBitMatrix out = UBitMatrix(width, height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (get(x, y)) out.set(width - 1 - x, height - 1 - y);
      }
    }
    return out;
  }

  /// Bounding box of the dark modules, or null when the matrix is blank.
  List<int>? enclosingRectangle() {
    int left = width;
    int top = height;
    int right = -1;
    int bottom = -1;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!get(x, y)) continue;
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
    if (right < left || bottom < top) return null;
    return <int>[left, top, right - left + 1, bottom - top + 1];
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        buffer.write(get(x, y) ? "##" : "  ");
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}

/// Converts grayscale to 1-bit. Hybrid uses local thresholds so it survives
/// uneven lighting; the global histogram path is used per-row for 1D symbols.
abstract class UBinarizer {
  static const int _blockSize = 8;
  static const int _blockShift = 3;
  static const int _minDynamicRange = 24;

  static UBitMatrix hybrid(UGrayImage image) {
    if (image.width < 40 || image.height < 40) return global(image);
    final int subWidth = (image.width + _blockSize - 1) >> _blockShift;
    final int subHeight = (image.height + _blockSize - 1) >> _blockShift;
    final Uint8List averages = Uint8List(subWidth * subHeight);

    for (int by = 0; by < subHeight; by++) {
      int yOffset = by << _blockShift;
      if (yOffset + _blockSize > image.height) yOffset = image.height - _blockSize;
      for (int bx = 0; bx < subWidth; bx++) {
        int xOffset = bx << _blockShift;
        if (xOffset + _blockSize > image.width) xOffset = image.width - _blockSize;
        int sum = 0;
        int min = 255;
        int max = 0;
        for (int y = 0; y < _blockSize; y++) {
          final int rowStart = (yOffset + y) * image.stride + xOffset;
          for (int x = 0; x < _blockSize; x++) {
            final int pixel = image.data[rowStart + x];
            sum += pixel;
            if (pixel < min) min = pixel;
            if (pixel > max) max = pixel;
          }
        }
        int average = sum >> (_blockShift * 2);
        if (max - min <= _minDynamicRange) {
          average = min ~/ 2;
          if (by > 0 && bx > 0) {
            final int neighbours = (averages[(by - 1) * subWidth + bx] + 2 * averages[by * subWidth + bx - 1] + averages[(by - 1) * subWidth + bx - 1]) ~/ 4;
            if (min < neighbours) average = neighbours;
          }
        }
        averages[by * subWidth + bx] = average;
      }
    }

    final UBitMatrix matrix = UBitMatrix(image.width, image.height);
    for (int by = 0; by < subHeight; by++) {
      int yOffset = by << _blockShift;
      if (yOffset + _blockSize > image.height) yOffset = image.height - _blockSize;
      final int top = _clampBlock(by, subHeight);
      for (int bx = 0; bx < subWidth; bx++) {
        int xOffset = bx << _blockShift;
        if (xOffset + _blockSize > image.width) xOffset = image.width - _blockSize;
        final int leftBlock = _clampBlock(bx, subWidth);
        int sum = 0;
        for (int dy = -2; dy <= 2; dy++) {
          final int rowStart = (top + dy) * subWidth;
          sum += averages[rowStart + leftBlock - 2] +
              averages[rowStart + leftBlock - 1] +
              averages[rowStart + leftBlock] +
              averages[rowStart + leftBlock + 1] +
              averages[rowStart + leftBlock + 2];
        }
        final int threshold = sum ~/ 25;
        for (int y = 0; y < _blockSize; y++) {
          final int rowStart = (yOffset + y) * image.stride + xOffset;
          for (int x = 0; x < _blockSize; x++) {
            if (image.data[rowStart + x] <= threshold) matrix.set(xOffset + x, yOffset + y);
          }
        }
      }
    }
    return matrix;
  }

  static int _clampBlock(int index, int count) {
    if (index < 2) return 2;
    final int limit = count - 3;
    return index > limit ? limit : index;
  }

  static UBitMatrix global(UGrayImage image) {
    final int threshold = globalThreshold(image);
    final UBitMatrix matrix = UBitMatrix(image.width, image.height);
    for (int y = 0; y < image.height; y++) {
      final int rowStart = y * image.stride;
      for (int x = 0; x < image.width; x++) {
        if (image.data[rowStart + x] <= threshold) matrix.set(x, y);
      }
    }
    return matrix;
  }

  /// Otsu-style two-peak estimate over a 32-bucket histogram.
  static int globalThreshold(UGrayImage image) {
    final Int32List buckets = Int32List(32);
    final int step = image.height > 64 ? image.height ~/ 32 : 1;
    for (int y = 0; y < image.height; y += step) {
      final int rowStart = y * image.stride;
      for (int x = 0; x < image.width; x++) {
        buckets[image.data[rowStart + x] >> 3]++;
      }
    }
    return _estimate(buckets) << 3;
  }

  /// Threshold for a single row of samples, used by the 1D readers.
  static int rowThreshold(Uint8List row, int length) {
    final Int32List buckets = Int32List(32);
    for (int x = 0; x < length; x++) {
      buckets[row[x] >> 3]++;
    }
    return _estimate(buckets) << 3;
  }

  static int _estimate(Int32List buckets) {
    int maxBucketCount = 0;
    int firstPeak = 0;
    int firstPeakSize = 0;
    for (int x = 0; x < buckets.length; x++) {
      if (buckets[x] > firstPeakSize) {
        firstPeak = x;
        firstPeakSize = buckets[x];
      }
      if (buckets[x] > maxBucketCount) maxBucketCount = buckets[x];
    }

    int secondPeak = 0;
    int secondPeakScore = 0;
    for (int x = 0; x < buckets.length; x++) {
      final int distance = x - firstPeak;
      final int score = buckets[x] * distance * distance;
      if (score > secondPeakScore) {
        secondPeak = x;
        secondPeakScore = score;
      }
    }

    int low = firstPeak;
    int high = secondPeak;
    if (low > high) {
      final int swap = low;
      low = high;
      high = swap;
    }
    if (high - low <= buckets.length ~/ 16) return 15;

    int bestValley = high - 1;
    int bestValleyScore = -1;
    for (int x = high - 1; x > low; x--) {
      final int fromFirst = x - low;
      final int score = fromFirst * fromFirst * (high - x) * (maxBucketCount - buckets[x]);
      if (score > bestValleyScore) {
        bestValley = x;
        bestValleyScore = score;
      }
    }
    return bestValley;
  }
}

// =============================================================================
// Galois fields and Reed-Solomon error correction
// =============================================================================

class UGaloisField {
  UGaloisField(this.size, int primitive, this.generatorBase)
    : _exp = Int32List(size),
      _log = Int32List(size) {
    int x = 1;
    for (int i = 0; i < size - 1; i++) {
      _exp[i] = x;
      x <<= 1;
      if (x >= size) x = (x ^ primitive) & (size - 1);
    }
    _exp[size - 1] = _exp[0];
    for (int i = 0; i < size - 1; i++) {
      _log[_exp[i]] = i;
    }
  }

  final int size;
  final int generatorBase;
  final Int32List _exp;
  final Int32List _log;

  static final UGaloisField qr = UGaloisField(256, 0x011D, 0);
  static final UGaloisField dataMatrix = UGaloisField(256, 0x012D, 1);
  static final UGaloisField pdf417 = UGaloisField(929, 0, 1);
  static final UGaloisField aztecParam = UGaloisField(16, 0x13, 1);
  static final UGaloisField aztec6 = UGaloisField(64, 0x43, 1);
  static final UGaloisField aztec8 = UGaloisField(256, 0x012D, 1);
  static final UGaloisField aztec10 = UGaloisField(1024, 0x409, 1);
  static final UGaloisField aztec12 = UGaloisField(4096, 0x1069, 1);

  int exp(int a) => _exp[a % (size - 1)];

  int log(int a) {
    if (a == 0) throw const UCodeDecodeException("log(0)");
    return _log[a];
  }

  int inverse(int a) => _exp[size - 1 - log(a)];

  int multiply(int a, int b) {
    if (a == 0 || b == 0) return 0;
    return _exp[(_log[a] + _log[b]) % (size - 1)];
  }

  static int addOrSubtract(int a, int b) => a ^ b;
}

/// Reed-Solomon over a power-of-two field (QR, Data Matrix, Aztec).
class UGfPoly {
  UGfPoly(this.field, Int32List coefficients) : _coefficients = _trim(field, coefficients);

  final UGaloisField field;
  final Int32List _coefficients;

  static Int32List _trim(UGaloisField field, Int32List coefficients) {
    if (coefficients.isEmpty) throw const UCodeDecodeException("Empty polynomial");
    if (coefficients.length > 1 && coefficients[0] == 0) {
      int first = 1;
      while (first < coefficients.length && coefficients[first] == 0) {
        first++;
      }
      if (first == coefficients.length) return Int32List.fromList(<int>[0]);
      return Int32List.fromList(coefficients.sublist(first));
    }
    return coefficients;
  }

  Int32List get coefficients => _coefficients;

  int get degree => _coefficients.length - 1;

  bool get isZero => _coefficients[0] == 0;

  int coefficient(int degree) => _coefficients[_coefficients.length - 1 - degree];

  int evaluate(int a) {
    if (a == 0) return coefficient(0);
    if (a == 1) {
      int result = 0;
      for (final int coefficient in _coefficients) {
        result = UGaloisField.addOrSubtract(result, coefficient);
      }
      return result;
    }
    int result = _coefficients[0];
    for (int i = 1; i < _coefficients.length; i++) {
      result = UGaloisField.addOrSubtract(field.multiply(a, result), _coefficients[i]);
    }
    return result;
  }

  UGfPoly addOrSubtract(UGfPoly other) {
    if (isZero) return other;
    if (other.isZero) return this;
    Int32List smaller = _coefficients;
    Int32List larger = other._coefficients;
    if (smaller.length > larger.length) {
      final Int32List swap = smaller;
      smaller = larger;
      larger = swap;
    }
    final Int32List sum = Int32List(larger.length);
    final int difference = larger.length - smaller.length;
    sum.setRange(0, difference, larger);
    for (int i = difference; i < larger.length; i++) {
      sum[i] = UGaloisField.addOrSubtract(smaller[i - difference], larger[i]);
    }
    return UGfPoly(field, sum);
  }

  UGfPoly multiply(UGfPoly other) {
    if (isZero || other.isZero) return UGfPoly(field, Int32List.fromList(<int>[0]));
    final Int32List a = _coefficients;
    final Int32List b = other._coefficients;
    final Int32List product = Int32List(a.length + b.length - 1);
    for (int i = 0; i < a.length; i++) {
      final int scale = a[i];
      for (int j = 0; j < b.length; j++) {
        product[i + j] = UGaloisField.addOrSubtract(product[i + j], field.multiply(scale, b[j]));
      }
    }
    return UGfPoly(field, product);
  }

  UGfPoly multiplyScalar(int scalar) {
    if (scalar == 0) return UGfPoly(field, Int32List.fromList(<int>[0]));
    if (scalar == 1) return this;
    final Int32List product = Int32List(_coefficients.length);
    for (int i = 0; i < _coefficients.length; i++) {
      product[i] = field.multiply(_coefficients[i], scalar);
    }
    return UGfPoly(field, product);
  }

  UGfPoly multiplyByMonomial(int degree, int coefficient) {
    if (degree < 0) throw const UCodeDecodeException("Negative monomial degree");
    if (coefficient == 0) return UGfPoly(field, Int32List.fromList(<int>[0]));
    final Int32List product = Int32List(_coefficients.length + degree);
    for (int i = 0; i < _coefficients.length; i++) {
      product[i] = field.multiply(_coefficients[i], coefficient);
    }
    return UGfPoly(field, product);
  }

  List<UGfPoly> divide(UGfPoly other) {
    if (other.isZero) throw const UCodeDecodeException("Divide by zero");
    UGfPoly quotient = UGfPoly(field, Int32List.fromList(<int>[0]));
    UGfPoly remainder = this;
    final int denominatorLeadingTerm = other.coefficient(other.degree);
    final int inverseDenominatorLeadingTerm = field.inverse(denominatorLeadingTerm);
    while (remainder.degree >= other.degree && !remainder.isZero) {
      final int degreeDifference = remainder.degree - other.degree;
      final int scale = field.multiply(remainder.coefficient(remainder.degree), inverseDenominatorLeadingTerm);
      final UGfPoly term = other.multiplyByMonomial(degreeDifference, scale);
      quotient = quotient.addOrSubtract(UGfPoly.monomial(field, degreeDifference, scale));
      remainder = remainder.addOrSubtract(term);
    }
    return <UGfPoly>[quotient, remainder];
  }

  static UGfPoly monomial(UGaloisField field, int degree, int coefficient) {
    if (degree < 0) throw const UCodeDecodeException("Negative monomial degree");
    if (coefficient == 0) return UGfPoly(field, Int32List.fromList(<int>[0]));
    final Int32List coefficients = Int32List(degree + 1);
    coefficients[0] = coefficient;
    return UGfPoly(field, coefficients);
  }

  static UGfPoly zero(UGaloisField field) => UGfPoly(field, Int32List.fromList(<int>[0]));

  static UGfPoly one(UGaloisField field) => UGfPoly(field, Int32List.fromList(<int>[1]));
}

/// Berlekamp-Massey / Chien search decoder shared by QR, Data Matrix and Aztec.
abstract class UReedSolomon {
  static void decode(UGaloisField field, Int32List received, int twoS) {
    final UGfPoly poly = UGfPoly(field, received);
    final Int32List syndromes = Int32List(twoS);
    bool noError = true;
    for (int i = 0; i < twoS; i++) {
      final int evaluated = poly.evaluate(field.exp(i + field.generatorBase));
      syndromes[twoS - 1 - i] = evaluated;
      if (evaluated != 0) noError = false;
    }
    if (noError) return;

    final UGfPoly syndrome = UGfPoly(field, syndromes);
    final List<UGfPoly> sigmaOmega = _euclidean(field, UGfPoly.monomial(field, twoS, 1), syndrome, twoS);
    final UGfPoly sigma = sigmaOmega[0];
    final UGfPoly omega = sigmaOmega[1];
    final Int32List positions = _findErrorLocations(field, sigma);
    final Int32List magnitudes = _findErrorMagnitudes(field, omega, positions);
    for (int i = 0; i < positions.length; i++) {
      final int position = received.length - 1 - field.log(positions[i]);
      if (position < 0) throw const UCodeDecodeException("Bad error location");
      received[position] = UGaloisField.addOrSubtract(received[position], magnitudes[i]);
    }
  }

  static List<UGfPoly> _euclidean(UGaloisField field, UGfPoly a, UGfPoly b, int limit) {
    UGfPoly rLast = a;
    UGfPoly r = b;
    UGfPoly tLast = UGfPoly.zero(field);
    UGfPoly t = UGfPoly.one(field);

    if (rLast.degree < r.degree) {
      final UGfPoly swapR = rLast;
      rLast = r;
      r = swapR;
      final UGfPoly swapT = tLast;
      tLast = t;
      t = swapT;
    }

    while (r.degree >= limit ~/ 2) {
      final UGfPoly rLastLast = rLast;
      final UGfPoly tLastLast = tLast;
      rLast = r;
      tLast = t;
      if (rLast.isZero) throw const UCodeDecodeException("Reed-Solomon failure");
      r = rLastLast;
      UGfPoly q = UGfPoly.zero(field);
      final int denominatorLeadingTerm = rLast.coefficient(rLast.degree);
      final int dltInverse = field.inverse(denominatorLeadingTerm);
      while (r.degree >= rLast.degree && !r.isZero) {
        final int degreeDifference = r.degree - rLast.degree;
        final int scale = field.multiply(r.coefficient(r.degree), dltInverse);
        q = q.addOrSubtract(UGfPoly.monomial(field, degreeDifference, scale));
        r = r.addOrSubtract(rLast.multiplyByMonomial(degreeDifference, scale));
      }
      t = q.multiply(tLast).addOrSubtract(tLastLast);
      if (r.degree >= rLast.degree) throw const UCodeDecodeException("Division algorithm failed");
    }

    final int sigmaTildeAtZero = t.coefficient(0);
    if (sigmaTildeAtZero == 0) throw const UCodeDecodeException("sigmaTilde(0) was zero");
    final int inverse = field.inverse(sigmaTildeAtZero);
    return <UGfPoly>[t.multiplyScalar(inverse), r.multiplyScalar(inverse)];
  }

  static Int32List _findErrorLocations(UGaloisField field, UGfPoly errorLocator) {
    final int errorCount = errorLocator.degree;
    if (errorCount == 1) return Int32List.fromList(<int>[errorLocator.coefficient(1)]);
    final Int32List result = Int32List(errorCount);
    int found = 0;
    for (int i = 1; i < field.size && found < errorCount; i++) {
      if (errorLocator.evaluate(i) == 0) {
        result[found] = field.inverse(i);
        found++;
      }
    }
    if (found != errorCount) throw const UCodeDecodeException("Error locator degree mismatch");
    return result;
  }

  static Int32List _findErrorMagnitudes(UGaloisField field, UGfPoly errorEvaluator, Int32List errorLocations) {
    final int count = errorLocations.length;
    final Int32List result = Int32List(count);
    for (int i = 0; i < count; i++) {
      final int xiInverse = field.inverse(errorLocations[i]);
      int denominator = 1;
      for (int j = 0; j < count; j++) {
        if (i == j) continue;
        final int term = field.multiply(errorLocations[j], xiInverse);
        denominator = field.multiply(denominator, (term & 0x1) == 0 ? term | 1 : term & ~1);
      }
      result[i] = field.multiply(errorEvaluator.evaluate(xiInverse), field.inverse(denominator));
      if (field.generatorBase != 0) result[i] = field.multiply(result[i], xiInverse);
    }
    return result;
  }
}

/// Modulo-929 Reed-Solomon used by PDF417, which is not a binary field.
abstract class UModulusPoly {
  static const int _modulus = 929;
  static final Int32List _exp = _buildExp();
  static final Int32List _log = _buildLog();

  static Int32List _buildExp() {
    final Int32List table = Int32List(_modulus);
    int x = 1;
    for (int i = 0; i < _modulus; i++) {
      table[i] = x;
      x = (x * 3) % _modulus;
    }
    return table;
  }

  static Int32List _buildLog() {
    final Int32List table = Int32List(_modulus);
    for (int i = 0; i < _modulus - 1; i++) {
      table[_exp[i]] = i;
    }
    return table;
  }

  static int exp(int a) => _exp[a % (_modulus - 1)];

  static int log(int a) {
    if (a == 0) throw const UCodeDecodeException("log(0) mod 929");
    return _log[a];
  }

  static int inverse(int a) => exp(_modulus - 1 - log(a));

  static int multiply(int a, int b) => (a * b) % _modulus;

  static int add(int a, int b) => (a + b) % _modulus;

  static int subtract(int a, int b) => (a - b + _modulus) % _modulus;

  static Int32List trim(Int32List coefficients) {
    if (coefficients.length > 1 && coefficients[0] == 0) {
      int first = 1;
      while (first < coefficients.length && coefficients[first] == 0) {
        first++;
      }
      if (first == coefficients.length) return Int32List.fromList(<int>[0]);
      return Int32List.fromList(coefficients.sublist(first));
    }
    return coefficients;
  }

  static int degreeOf(Int32List poly) => poly.length - 1;

  static bool isZero(Int32List poly) => poly[0] == 0;

  static int coefficientOf(Int32List poly, int degree) => poly[poly.length - 1 - degree];

  static int evaluate(Int32List poly, int a) {
    if (a == 0) return coefficientOf(poly, 0);
    if (a == 1) {
      int result = 0;
      for (final int coefficient in poly) {
        result = add(result, coefficient);
      }
      return result;
    }
    int result = poly[0];
    for (int i = 1; i < poly.length; i++) {
      result = add(multiply(a, result), poly[i]);
    }
    return result;
  }

  static Int32List addPoly(Int32List a, Int32List b) {
    if (isZero(a)) return b;
    if (isZero(b)) return a;
    Int32List smaller = a;
    Int32List larger = b;
    if (smaller.length > larger.length) {
      final Int32List swap = smaller;
      smaller = larger;
      larger = swap;
    }
    final Int32List sum = Int32List(larger.length);
    final int difference = larger.length - smaller.length;
    sum.setRange(0, difference, larger);
    for (int i = difference; i < larger.length; i++) {
      sum[i] = add(smaller[i - difference], larger[i]);
    }
    return trim(sum);
  }

  static Int32List subtractPoly(Int32List a, Int32List b) => addPoly(a, negatePoly(b));

  static Int32List negatePoly(Int32List poly) {
    final Int32List out = Int32List(poly.length);
    for (int i = 0; i < poly.length; i++) {
      out[i] = subtract(0, poly[i]);
    }
    return trim(out);
  }

  static Int32List multiplyPoly(Int32List a, Int32List b) {
    if (isZero(a) || isZero(b)) return Int32List.fromList(<int>[0]);
    final Int32List product = Int32List(a.length + b.length - 1);
    for (int i = 0; i < a.length; i++) {
      final int scale = a[i];
      for (int j = 0; j < b.length; j++) {
        product[i + j] = add(product[i + j], multiply(scale, b[j]));
      }
    }
    return trim(product);
  }

  static Int32List multiplyScalarPoly(Int32List poly, int scalar) {
    if (scalar == 0) return Int32List.fromList(<int>[0]);
    if (scalar == 1) return poly;
    final Int32List out = Int32List(poly.length);
    for (int i = 0; i < poly.length; i++) {
      out[i] = multiply(poly[i], scalar);
    }
    return trim(out);
  }

  static Int32List monomial(int degree, int coefficient) {
    if (coefficient == 0) return Int32List.fromList(<int>[0]);
    final Int32List out = Int32List(degree + 1);
    out[0] = coefficient;
    return out;
  }

  static Int32List multiplyByMonomialPoly(Int32List poly, int degree, int coefficient) {
    if (coefficient == 0) return Int32List.fromList(<int>[0]);
    final Int32List out = Int32List(poly.length + degree);
    for (int i = 0; i < poly.length; i++) {
      out[i] = multiply(poly[i], coefficient);
    }
    return trim(out);
  }

  /// Corrects [received] in place; returns the number of errors fixed.
  static int decode(Int32List received, int numEcCodewords, Int32List erasures) {
    final Int32List poly = Int32List.fromList(received);
    final Int32List syndromes = Int32List(numEcCodewords);
    bool error = false;
    for (int i = numEcCodewords; i > 0; i--) {
      final int evaluated = evaluate(poly, exp(i));
      syndromes[numEcCodewords - i] = evaluated;
      if (evaluated != 0) error = true;
    }
    if (!error) return 0;

    Int32List knownErrors = Int32List.fromList(<int>[1]);
    for (final int erasure in erasures) {
      final int b = exp(received.length - 1 - erasure);
      knownErrors = multiplyPoly(knownErrors, Int32List.fromList(<int>[subtract(0, b), 1]));
    }

    final Int32List syndromePoly = trim(syndromes);
    final List<Int32List> sigmaOmega = _runEuclidean(monomial(numEcCodewords, 1), syndromePoly, numEcCodewords);
    final Int32List sigma = sigmaOmega[0];
    final Int32List omega = sigmaOmega[1];
    final Int32List positions = _errorLocations(sigma);
    final Int32List magnitudes = _errorMagnitudes(omega, sigma, positions);

    for (int i = 0; i < positions.length; i++) {
      final int position = received.length - 1 - log(positions[i]);
      if (position < 0) throw const UCodeDecodeException("Bad PDF417 error location");
      received[position] = subtract(received[position], magnitudes[i]);
    }
    return positions.length;
  }

  static List<Int32List> _runEuclidean(Int32List a, Int32List b, int limit) {
    Int32List rLast = a;
    Int32List r = b;
    Int32List tLast = Int32List.fromList(<int>[0]);
    Int32List t = Int32List.fromList(<int>[1]);

    if (degreeOf(rLast) < degreeOf(r)) {
      final Int32List swapR = rLast;
      rLast = r;
      r = swapR;
      final Int32List swapT = tLast;
      tLast = t;
      t = swapT;
    }

    while (degreeOf(r) >= limit ~/ 2) {
      final Int32List rLastLast = rLast;
      final Int32List tLastLast = tLast;
      rLast = r;
      tLast = t;
      if (isZero(rLast)) throw const UCodeDecodeException("PDF417 Reed-Solomon failure");
      r = rLastLast;
      Int32List q = Int32List.fromList(<int>[0]);
      final int denominatorLeadingTerm = coefficientOf(rLast, degreeOf(rLast));
      final int dltInverse = inverse(denominatorLeadingTerm);
      while (degreeOf(r) >= degreeOf(rLast) && !isZero(r)) {
        final int degreeDifference = degreeOf(r) - degreeOf(rLast);
        final int scale = multiply(coefficientOf(r, degreeOf(r)), dltInverse);
        q = addPoly(q, monomial(degreeDifference, scale));
        r = subtractPoly(r, multiplyByMonomialPoly(rLast, degreeDifference, scale));
      }
      t = subtractPoly(multiplyPoly(q, tLast), tLastLast);
      t = negatePoly(t);
    }

    final int sigmaTildeAtZero = coefficientOf(t, 0);
    if (sigmaTildeAtZero == 0) throw const UCodeDecodeException("sigmaTilde(0) was zero");
    final int inv = inverse(sigmaTildeAtZero);
    return <Int32List>[multiplyScalarPoly(t, inv), multiplyScalarPoly(r, inv)];
  }

  static Int32List _errorLocations(Int32List errorLocator) {
    final int errorCount = degreeOf(errorLocator);
    final Int32List result = Int32List(errorCount);
    int found = 0;
    for (int i = 1; i < _modulus && found < errorCount; i++) {
      if (evaluate(errorLocator, i) == 0) {
        result[found] = inverse(i);
        found++;
      }
    }
    if (found != errorCount) throw const UCodeDecodeException("PDF417 error locator mismatch");
    return result;
  }

  static Int32List _errorMagnitudes(Int32List errorEvaluator, Int32List errorLocator, Int32List errorLocations) {
    final int errorLocatorDegree = degreeOf(errorLocator);
    if (errorLocatorDegree < 1) return Int32List(0);
    final Int32List formalDerivative = Int32List(errorLocatorDegree);
    for (int i = 1; i <= errorLocatorDegree; i++) {
      formalDerivative[errorLocatorDegree - i] = multiply(i, coefficientOf(errorLocator, i));
    }
    final Int32List derivative = trim(formalDerivative);

    final Int32List result = Int32List(errorLocations.length);
    for (int i = 0; i < errorLocations.length; i++) {
      final int xiInverse = inverse(errorLocations[i]);
      final int numerator = subtract(0, evaluate(errorEvaluator, xiInverse));
      final int denominator = inverse(evaluate(derivative, xiInverse));
      result[i] = multiply(numerator, denominator);
    }
    return result;
  }
}

// =============================================================================
// Geometry: perspective transform and grid sampling
// =============================================================================

class UPerspectiveTransform {
  const UPerspectiveTransform(this.a11, this.a21, this.a31, this.a12, this.a22, this.a32, this.a13, this.a23, this.a33);

  final double a11;
  final double a21;
  final double a31;
  final double a12;
  final double a22;
  final double a32;
  final double a13;
  final double a23;
  final double a33;

  static UPerspectiveTransform quadrilateralToQuadrilateral(
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    double x0p,
    double y0p,
    double x1p,
    double y1p,
    double x2p,
    double y2p,
    double x3p,
    double y3p,
  ) {
    final UPerspectiveTransform toSquare = _squareToQuadrilateral(x0, y0, x1, y1, x2, y2, x3, y3).buildAdjoint();
    final UPerspectiveTransform fromSquare = _squareToQuadrilateral(x0p, y0p, x1p, y1p, x2p, y2p, x3p, y3p);
    return fromSquare.times(toSquare);
  }

  static UPerspectiveTransform _squareToQuadrilateral(double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3) {
    final double dx3 = x0 - x1 + x2 - x3;
    final double dy3 = y0 - y1 + y2 - y3;
    if (dx3 == 0.0 && dy3 == 0.0) {
      return UPerspectiveTransform(x1 - x0, x2 - x1, x0, y1 - y0, y2 - y1, y0, 0, 0, 1);
    }
    final double dx1 = x1 - x2;
    final double dx2 = x3 - x2;
    final double dy1 = y1 - y2;
    final double dy2 = y3 - y2;
    final double denominator = dx1 * dy2 - dx2 * dy1;
    final double a13 = (dx3 * dy2 - dx2 * dy3) / denominator;
    final double a23 = (dx1 * dy3 - dx3 * dy1) / denominator;
    return UPerspectiveTransform(x1 - x0 + a13 * x1, x3 - x0 + a23 * x3, x0, y1 - y0 + a13 * y1, y3 - y0 + a23 * y3, y0, a13, a23, 1);
  }

  UPerspectiveTransform buildAdjoint() => UPerspectiveTransform(
    a22 * a33 - a23 * a32,
    a23 * a31 - a21 * a33,
    a21 * a32 - a22 * a31,
    a13 * a32 - a12 * a33,
    a11 * a33 - a13 * a31,
    a12 * a31 - a11 * a32,
    a12 * a23 - a13 * a22,
    a13 * a21 - a11 * a23,
    a11 * a22 - a12 * a21,
  );

  UPerspectiveTransform times(UPerspectiveTransform other) => UPerspectiveTransform(
    a11 * other.a11 + a21 * other.a12 + a31 * other.a13,
    a11 * other.a21 + a21 * other.a22 + a31 * other.a23,
    a11 * other.a31 + a21 * other.a32 + a31 * other.a33,
    a12 * other.a11 + a22 * other.a12 + a32 * other.a13,
    a12 * other.a21 + a22 * other.a22 + a32 * other.a23,
    a12 * other.a31 + a22 * other.a32 + a32 * other.a33,
    a13 * other.a11 + a23 * other.a12 + a33 * other.a13,
    a13 * other.a21 + a23 * other.a22 + a33 * other.a23,
    a13 * other.a31 + a23 * other.a32 + a33 * other.a33,
  );

  void transform(Float64List points) {
    for (int i = 0; i < points.length; i += 2) {
      final double x = points[i];
      final double y = points[i + 1];
      final double denominator = a13 * x + a23 * y + a33;
      points[i] = (a11 * x + a21 * y + a31) / denominator;
      points[i + 1] = (a12 * x + a22 * y + a32) / denominator;
    }
  }

  Offset mapPoint(double x, double y) {
    final double denominator = a13 * x + a23 * y + a33;
    return Offset((a11 * x + a21 * y + a31) / denominator, (a12 * x + a22 * y + a32) / denominator);
  }
}

abstract class UGridSampler {
  static UBitMatrix sample(UBitMatrix image, int dimensionX, int dimensionY, UPerspectiveTransform transform) {
    if (dimensionX <= 0 || dimensionY <= 0) throw const UCodeDecodeException("Bad sampling dimension");
    final UBitMatrix output = UBitMatrix(dimensionX, dimensionY);
    final Float64List points = Float64List(dimensionX * 2);
    for (int y = 0; y < dimensionY; y++) {
      final double sampleY = y + 0.5;
      for (int x = 0; x < dimensionX; x++) {
        points[x * 2] = x + 0.5;
        points[x * 2 + 1] = sampleY;
      }
      transform.transform(points);
      for (int x = 0; x < dimensionX; x++) {
        final int px = points[x * 2].toInt();
        final int py = points[x * 2 + 1].toInt();
        if (px < 0 || py < 0 || px >= image.width || py >= image.height) continue;
        if (image.get(px, py)) output.set(x, y);
      }
    }
    return output;
  }
}

// =============================================================================
// QR Code
// =============================================================================

class UQrEcb {
  const UQrEcb(this.count, this.dataCodewords);

  final int count;
  final int dataCodewords;
}

class UQrEcBlocks {
  const UQrEcBlocks(this.ecCodewordsPerBlock, this.blocks);

  final int ecCodewordsPerBlock;
  final List<UQrEcb> blocks;

  int get numBlocks {
    int total = 0;
    for (final UQrEcb block in blocks) {
      total += block.count;
    }
    return total;
  }

  int get totalEcCodewords => ecCodewordsPerBlock * numBlocks;
}

class UQrVersion {
  const UQrVersion(this.number, this.alignmentPatternCenters, this.ecBlocks);

  final int number;
  final List<int> alignmentPatternCenters;

  /// Indexed by error-correction level: L, M, Q, H.
  final List<UQrEcBlocks> ecBlocks;

  int get dimension => 17 + 4 * number;

  int get totalCodewords {
    final UQrEcBlocks level = ecBlocks[0];
    int total = 0;
    for (final UQrEcb block in level.blocks) {
      total += block.count * (block.dataCodewords + level.ecCodewordsPerBlock);
    }
    return total;
  }

  static UQrVersion forNumber(int number) {
    if (number < 1 || number > 40) throw const UCodeDecodeException("Bad QR version");
    return _versions[number - 1];
  }

  static UQrVersion? forDimension(int dimension) {
    if (dimension % 4 != 1 || dimension < 21 || dimension > 177) return null;
    return forNumber((dimension - 17) ~/ 4);
  }

  static const List<int> _versionDecodeInfo = <int>[
    0x07C94, 0x085BC, 0x09A99, 0x0A4D3, 0x0BBF6, 0x0C762, 0x0D847, 0x0E60D, 0x0F928, 0x10B78,
    0x1145D, 0x12A17, 0x13532, 0x149A6, 0x15683, 0x168C9, 0x177EC, 0x18EC4, 0x191E1, 0x1AFAB,
    0x1B08E, 0x1CC1A, 0x1D33F, 0x1ED75, 0x1F250, 0x209D5, 0x216F0, 0x228BA, 0x2379F, 0x24B0B,
    0x2542E, 0x26A64, 0x27541, 0x28C69,
  ];

  static UQrVersion? decodeVersionInformation(int versionBits) {
    int bestDifference = 1 << 30;
    int bestVersion = 0;
    for (int i = 0; i < _versionDecodeInfo.length; i++) {
      final int target = _versionDecodeInfo[i];
      if (target == versionBits) return forNumber(i + 7);
      final int difference = _bitDifference(versionBits, target);
      if (difference < bestDifference) {
        bestVersion = i + 7;
        bestDifference = difference;
      }
    }
    if (bestDifference <= 3) return forNumber(bestVersion);
    return null;
  }

  static int _bitDifference(int a, int b) {
    int value = a ^ b;
    int count = 0;
    while (value != 0) {
      count += value & 1;
      value >>= 1;
    }
    return count;
  }

  UBitMatrix buildFunctionPattern() {
    final int dimension = this.dimension;
    final UBitMatrix matrix = UBitMatrix(dimension, dimension);
    _fill(matrix, 0, 0, 9, 9);
    _fill(matrix, dimension - 8, 0, 8, 9);
    _fill(matrix, 0, dimension - 8, 9, 8);

    final int max = alignmentPatternCenters.length;
    for (int x = 0; x < max; x++) {
      final int i = alignmentPatternCenters[x] - 2;
      for (int y = 0; y < max; y++) {
        if ((x == 0 && (y == 0 || y == max - 1)) || (x == max - 1 && y == 0)) continue;
        _fill(matrix, alignmentPatternCenters[y] - 2, i, 5, 5);
      }
    }

    _fill(matrix, 6, 9, 1, dimension - 17);
    _fill(matrix, 9, 6, dimension - 17, 1);

    if (number > 6) {
      _fill(matrix, dimension - 11, 0, 3, 6);
      _fill(matrix, 0, dimension - 11, 6, 3);
    }
    return matrix;
  }

  static void _fill(UBitMatrix matrix, int left, int top, int width, int height) {
    for (int y = top; y < top + height; y++) {
      for (int x = left; x < left + width; x++) {
        matrix.set(x, y);
      }
    }
  }

  static final List<UQrVersion> _versions = <UQrVersion>[
    const UQrVersion(1, <int>[], <UQrEcBlocks>[
      UQrEcBlocks(7, <UQrEcb>[UQrEcb(1, 19)]),
      UQrEcBlocks(10, <UQrEcb>[UQrEcb(1, 16)]),
      UQrEcBlocks(13, <UQrEcb>[UQrEcb(1, 13)]),
      UQrEcBlocks(17, <UQrEcb>[UQrEcb(1, 9)]),
    ]),
    const UQrVersion(2, <int>[6, 18], <UQrEcBlocks>[
      UQrEcBlocks(10, <UQrEcb>[UQrEcb(1, 34)]),
      UQrEcBlocks(16, <UQrEcb>[UQrEcb(1, 28)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(1, 22)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(1, 16)]),
    ]),
    const UQrVersion(3, <int>[6, 22], <UQrEcBlocks>[
      UQrEcBlocks(15, <UQrEcb>[UQrEcb(1, 55)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(1, 44)]),
      UQrEcBlocks(18, <UQrEcb>[UQrEcb(2, 17)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(2, 13)]),
    ]),
    const UQrVersion(4, <int>[6, 26], <UQrEcBlocks>[
      UQrEcBlocks(20, <UQrEcb>[UQrEcb(1, 80)]),
      UQrEcBlocks(18, <UQrEcb>[UQrEcb(2, 32)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(2, 24)]),
      UQrEcBlocks(16, <UQrEcb>[UQrEcb(4, 9)]),
    ]),
    const UQrVersion(5, <int>[6, 30], <UQrEcBlocks>[
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(1, 108)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(2, 43)]),
      UQrEcBlocks(18, <UQrEcb>[UQrEcb(2, 15), UQrEcb(2, 16)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(2, 11), UQrEcb(2, 12)]),
    ]),
    const UQrVersion(6, <int>[6, 34], <UQrEcBlocks>[
      UQrEcBlocks(18, <UQrEcb>[UQrEcb(2, 68)]),
      UQrEcBlocks(16, <UQrEcb>[UQrEcb(4, 27)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(4, 19)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(4, 15)]),
    ]),
    const UQrVersion(7, <int>[6, 22, 38], <UQrEcBlocks>[
      UQrEcBlocks(20, <UQrEcb>[UQrEcb(2, 78)]),
      UQrEcBlocks(18, <UQrEcb>[UQrEcb(4, 31)]),
      UQrEcBlocks(18, <UQrEcb>[UQrEcb(2, 14), UQrEcb(4, 15)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(4, 13), UQrEcb(1, 14)]),
    ]),
    const UQrVersion(8, <int>[6, 24, 42], <UQrEcBlocks>[
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(2, 97)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(2, 38), UQrEcb(2, 39)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(4, 18), UQrEcb(2, 19)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(4, 14), UQrEcb(2, 15)]),
    ]),
    const UQrVersion(9, <int>[6, 26, 46], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(2, 116)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(3, 36), UQrEcb(2, 37)]),
      UQrEcBlocks(20, <UQrEcb>[UQrEcb(4, 16), UQrEcb(4, 17)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(4, 12), UQrEcb(4, 13)]),
    ]),
    const UQrVersion(10, <int>[6, 28, 50], <UQrEcBlocks>[
      UQrEcBlocks(18, <UQrEcb>[UQrEcb(2, 68), UQrEcb(2, 69)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(4, 43), UQrEcb(1, 44)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(6, 19), UQrEcb(2, 20)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(6, 15), UQrEcb(2, 16)]),
    ]),
    const UQrVersion(11, <int>[6, 30, 54], <UQrEcBlocks>[
      UQrEcBlocks(20, <UQrEcb>[UQrEcb(4, 81)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(1, 50), UQrEcb(4, 51)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(4, 22), UQrEcb(4, 23)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(3, 12), UQrEcb(8, 13)]),
    ]),
    const UQrVersion(12, <int>[6, 32, 58], <UQrEcBlocks>[
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(2, 92), UQrEcb(2, 93)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(6, 36), UQrEcb(2, 37)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(4, 20), UQrEcb(6, 21)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(7, 14), UQrEcb(4, 15)]),
    ]),
    const UQrVersion(13, <int>[6, 34, 62], <UQrEcBlocks>[
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(4, 107)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(8, 37), UQrEcb(1, 38)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(8, 20), UQrEcb(4, 21)]),
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(12, 11), UQrEcb(4, 12)]),
    ]),
    const UQrVersion(14, <int>[6, 26, 46, 66], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(3, 115), UQrEcb(1, 116)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(4, 40), UQrEcb(5, 41)]),
      UQrEcBlocks(20, <UQrEcb>[UQrEcb(11, 16), UQrEcb(5, 17)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(11, 12), UQrEcb(5, 13)]),
    ]),
    const UQrVersion(15, <int>[6, 26, 48, 70], <UQrEcBlocks>[
      UQrEcBlocks(22, <UQrEcb>[UQrEcb(5, 87), UQrEcb(1, 88)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(5, 41), UQrEcb(5, 42)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(5, 24), UQrEcb(7, 25)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(11, 12), UQrEcb(7, 13)]),
    ]),
    const UQrVersion(16, <int>[6, 26, 50, 74], <UQrEcBlocks>[
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(5, 98), UQrEcb(1, 99)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(7, 45), UQrEcb(3, 46)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(15, 19), UQrEcb(2, 20)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(3, 15), UQrEcb(13, 16)]),
    ]),
    const UQrVersion(17, <int>[6, 30, 54, 78], <UQrEcBlocks>[
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(1, 107), UQrEcb(5, 108)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(10, 46), UQrEcb(1, 47)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(1, 22), UQrEcb(15, 23)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(2, 14), UQrEcb(17, 15)]),
    ]),
    const UQrVersion(18, <int>[6, 30, 56, 82], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(5, 120), UQrEcb(1, 121)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(9, 43), UQrEcb(4, 44)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(17, 22), UQrEcb(1, 23)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(2, 14), UQrEcb(19, 15)]),
    ]),
    const UQrVersion(19, <int>[6, 30, 58, 86], <UQrEcBlocks>[
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(3, 113), UQrEcb(4, 114)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(3, 44), UQrEcb(11, 45)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(17, 21), UQrEcb(4, 22)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(9, 13), UQrEcb(16, 14)]),
    ]),
    const UQrVersion(20, <int>[6, 34, 62, 90], <UQrEcBlocks>[
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(3, 107), UQrEcb(5, 108)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(3, 41), UQrEcb(13, 42)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(15, 24), UQrEcb(5, 25)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(15, 15), UQrEcb(10, 16)]),
    ]),
    const UQrVersion(21, <int>[6, 28, 50, 72, 94], <UQrEcBlocks>[
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(4, 116), UQrEcb(4, 117)]),
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(17, 42)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(17, 22), UQrEcb(6, 23)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(19, 16), UQrEcb(6, 17)]),
    ]),
    const UQrVersion(22, <int>[6, 26, 50, 74, 98], <UQrEcBlocks>[
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(2, 111), UQrEcb(7, 112)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(17, 46)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(7, 24), UQrEcb(16, 25)]),
      UQrEcBlocks(24, <UQrEcb>[UQrEcb(34, 13)]),
    ]),
    const UQrVersion(23, <int>[6, 30, 54, 78, 102], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(4, 121), UQrEcb(5, 122)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(4, 47), UQrEcb(14, 48)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(11, 24), UQrEcb(14, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(16, 15), UQrEcb(14, 16)]),
    ]),
    const UQrVersion(24, <int>[6, 28, 54, 80, 106], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(6, 117), UQrEcb(4, 118)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(6, 45), UQrEcb(14, 46)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(11, 24), UQrEcb(16, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(30, 16), UQrEcb(2, 17)]),
    ]),
    const UQrVersion(25, <int>[6, 32, 58, 84, 110], <UQrEcBlocks>[
      UQrEcBlocks(26, <UQrEcb>[UQrEcb(8, 106), UQrEcb(4, 107)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(8, 47), UQrEcb(13, 48)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(7, 24), UQrEcb(22, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(22, 15), UQrEcb(13, 16)]),
    ]),
    const UQrVersion(26, <int>[6, 30, 58, 86, 114], <UQrEcBlocks>[
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(10, 114), UQrEcb(2, 115)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(19, 46), UQrEcb(4, 47)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(28, 22), UQrEcb(6, 23)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(33, 16), UQrEcb(4, 17)]),
    ]),
    const UQrVersion(27, <int>[6, 34, 62, 90, 118], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(8, 122), UQrEcb(4, 123)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(22, 45), UQrEcb(3, 46)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(8, 23), UQrEcb(26, 24)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(12, 15), UQrEcb(28, 16)]),
    ]),
    const UQrVersion(28, <int>[6, 26, 50, 74, 98, 122], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(3, 117), UQrEcb(10, 118)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(3, 45), UQrEcb(23, 46)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(4, 24), UQrEcb(31, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(11, 15), UQrEcb(31, 16)]),
    ]),
    const UQrVersion(29, <int>[6, 30, 54, 78, 102, 126], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(7, 116), UQrEcb(7, 117)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(21, 45), UQrEcb(7, 46)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(1, 23), UQrEcb(37, 24)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(19, 15), UQrEcb(26, 16)]),
    ]),
    const UQrVersion(30, <int>[6, 26, 52, 78, 104, 130], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(5, 115), UQrEcb(10, 116)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(19, 47), UQrEcb(10, 48)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(15, 24), UQrEcb(25, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(23, 15), UQrEcb(25, 16)]),
    ]),
    const UQrVersion(31, <int>[6, 30, 56, 82, 108, 134], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(13, 115), UQrEcb(3, 116)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(2, 46), UQrEcb(29, 47)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(42, 24), UQrEcb(1, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(23, 15), UQrEcb(28, 16)]),
    ]),
    const UQrVersion(32, <int>[6, 34, 60, 86, 112, 138], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(17, 115)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(10, 46), UQrEcb(23, 47)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(10, 24), UQrEcb(35, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(19, 15), UQrEcb(35, 16)]),
    ]),
    const UQrVersion(33, <int>[6, 30, 58, 86, 114, 142], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(17, 115), UQrEcb(1, 116)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(14, 46), UQrEcb(21, 47)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(29, 24), UQrEcb(19, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(11, 15), UQrEcb(46, 16)]),
    ]),
    const UQrVersion(34, <int>[6, 34, 62, 90, 118, 146], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(13, 115), UQrEcb(6, 116)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(14, 46), UQrEcb(23, 47)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(44, 24), UQrEcb(7, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(59, 16), UQrEcb(1, 17)]),
    ]),
    const UQrVersion(35, <int>[6, 30, 54, 78, 102, 126, 150], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(12, 121), UQrEcb(7, 122)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(12, 47), UQrEcb(26, 48)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(39, 24), UQrEcb(14, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(22, 15), UQrEcb(41, 16)]),
    ]),
    const UQrVersion(36, <int>[6, 24, 50, 76, 102, 128, 154], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(6, 121), UQrEcb(14, 122)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(6, 47), UQrEcb(34, 48)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(46, 24), UQrEcb(10, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(2, 15), UQrEcb(64, 16)]),
    ]),
    const UQrVersion(37, <int>[6, 28, 54, 80, 106, 132, 158], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(17, 122), UQrEcb(4, 123)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(29, 46), UQrEcb(14, 47)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(49, 24), UQrEcb(10, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(24, 15), UQrEcb(46, 16)]),
    ]),
    const UQrVersion(38, <int>[6, 32, 58, 84, 110, 136, 162], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(4, 122), UQrEcb(18, 123)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(13, 46), UQrEcb(32, 47)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(48, 24), UQrEcb(14, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(42, 15), UQrEcb(32, 16)]),
    ]),
    const UQrVersion(39, <int>[6, 26, 54, 82, 110, 138, 166], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(20, 117), UQrEcb(4, 118)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(40, 47), UQrEcb(7, 48)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(43, 24), UQrEcb(22, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(10, 15), UQrEcb(67, 16)]),
    ]),
    const UQrVersion(40, <int>[6, 30, 58, 86, 114, 142, 170], <UQrEcBlocks>[
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(19, 118), UQrEcb(6, 119)]),
      UQrEcBlocks(28, <UQrEcb>[UQrEcb(18, 47), UQrEcb(31, 48)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(34, 24), UQrEcb(34, 25)]),
      UQrEcBlocks(30, <UQrEcb>[UQrEcb(20, 15), UQrEcb(61, 16)]),
    ]),
  ];
}

enum UQrEcLevel { l, m, q, h }

class UQrFormatInformation {
  const UQrFormatInformation(this.errorCorrectionLevel, this.dataMask);

  final UQrEcLevel errorCorrectionLevel;
  final int dataMask;

  static const int _formatInfoMaskQr = 0x5412;

  static const List<List<int>> _decodeLookup = <List<int>>[
    <int>[0x5412, 0x00], <int>[0x5125, 0x01], <int>[0x5E7C, 0x02], <int>[0x5B4B, 0x03],
    <int>[0x45F9, 0x04], <int>[0x40CE, 0x05], <int>[0x4F97, 0x06], <int>[0x4AA0, 0x07],
    <int>[0x77C4, 0x08], <int>[0x72F3, 0x09], <int>[0x7DAA, 0x0A], <int>[0x789D, 0x0B],
    <int>[0x662F, 0x0C], <int>[0x6318, 0x0D], <int>[0x6C41, 0x0E], <int>[0x6976, 0x0F],
    <int>[0x1689, 0x10], <int>[0x13BE, 0x11], <int>[0x1CE7, 0x12], <int>[0x19D0, 0x13],
    <int>[0x0762, 0x14], <int>[0x0255, 0x15], <int>[0x0D0C, 0x16], <int>[0x083B, 0x17],
    <int>[0x355F, 0x18], <int>[0x3068, 0x19], <int>[0x3F31, 0x1A], <int>[0x3A06, 0x1B],
    <int>[0x24B4, 0x1C], <int>[0x2183, 0x1D], <int>[0x2EDA, 0x1E], <int>[0x2BED, 0x1F],
  ];

  static UQrFormatInformation? decode(int maskedFormatInfo1, int maskedFormatInfo2) =>
      _doDecode(maskedFormatInfo1, maskedFormatInfo2) ?? _doDecode(maskedFormatInfo1 ^ _formatInfoMaskQr, maskedFormatInfo2 ^ _formatInfoMaskQr);

  static UQrFormatInformation? _doDecode(int maskedFormatInfo1, int maskedFormatInfo2) {
    int bestDifference = 1 << 30;
    int bestFormatInfo = 0;
    for (final List<int> entry in _decodeLookup) {
      final int targetInfo = entry[0];
      if (targetInfo == maskedFormatInfo1 || targetInfo == maskedFormatInfo2) return _build(entry[1]);
      int difference = UQrVersion._bitDifference(maskedFormatInfo1, targetInfo);
      if (difference < bestDifference) {
        bestFormatInfo = entry[1];
        bestDifference = difference;
      }
      if (maskedFormatInfo1 != maskedFormatInfo2) {
        difference = UQrVersion._bitDifference(maskedFormatInfo2, targetInfo);
        if (difference < bestDifference) {
          bestFormatInfo = entry[1];
          bestDifference = difference;
        }
      }
    }
    if (bestDifference <= 3) return _build(bestFormatInfo);
    return null;
  }

  static UQrFormatInformation _build(int formatInfo) {
    const List<UQrEcLevel> order = <UQrEcLevel>[UQrEcLevel.m, UQrEcLevel.l, UQrEcLevel.h, UQrEcLevel.q];
    return UQrFormatInformation(order[(formatInfo >> 3) & 0x03], formatInfo & 0x07);
  }

  int get levelIndex {
    switch (errorCorrectionLevel) {
      case UQrEcLevel.l:
        return 0;
      case UQrEcLevel.m:
        return 1;
      case UQrEcLevel.q:
        return 2;
      case UQrEcLevel.h:
        return 3;
    }
  }

  String get levelName => errorCorrectionLevel.name.toUpperCase();
}

abstract class UQrDataMask {
  static bool isMasked(int mask, int i, int j) {
    switch (mask) {
      case 0:
        return ((i + j) & 0x01) == 0;
      case 1:
        return (i & 0x01) == 0;
      case 2:
        return j % 3 == 0;
      case 3:
        return (i + j) % 3 == 0;
      case 4:
        return (((i ~/ 2) + (j ~/ 3)) & 0x01) == 0;
      case 5:
        return (i * j) % 6 == 0;
      case 6:
        return ((i * j) % 6) < 3;
      case 7:
        return ((i + j + ((i * j) % 3)) & 0x01) == 0;
      default:
        return false;
    }
  }

  static void unmask(UBitMatrix bits, int mask, int dimension) {
    for (int i = 0; i < dimension; i++) {
      for (int j = 0; j < dimension; j++) {
        if (isMasked(mask, i, j)) bits.flip(j, i);
      }
    }
  }
}

class UQrBitMatrixParser {
  UQrBitMatrixParser(this._bits) {
    final int dimension = _bits.height;
    if (dimension < 21 || (dimension & 0x03) != 1) throw const UCodeDecodeException("Bad QR dimension");
  }

  final UBitMatrix _bits;
  UQrVersion? _version;
  UQrFormatInformation? _formatInfo;
  bool _mirrored = false;

  bool get mirrored => _mirrored;

  void remask() {
    final UQrFormatInformation? info = _formatInfo;
    if (info == null) return;
    UQrDataMask.unmask(_bits, info.dataMask, _bits.height);
  }

  void mirror() {
    for (int x = 0; x < _bits.width; x++) {
      for (int y = x + 1; y < _bits.height; y++) {
        if (_bits.get(x, y) != _bits.get(y, x)) {
          _bits.flip(y, x);
          _bits.flip(x, y);
        }
      }
    }
    _mirrored = !_mirrored;
    _version = null;
    _formatInfo = null;
  }

  UQrFormatInformation readFormatInformation() {
    final UQrFormatInformation? cached = _formatInfo;
    if (cached != null) return cached;

    int formatInfoBits1 = 0;
    for (int i = 0; i < 6; i++) {
      formatInfoBits1 = _copyBit(i, 8, formatInfoBits1);
    }
    formatInfoBits1 = _copyBit(7, 8, formatInfoBits1);
    formatInfoBits1 = _copyBit(8, 8, formatInfoBits1);
    formatInfoBits1 = _copyBit(8, 7, formatInfoBits1);
    for (int j = 5; j >= 0; j--) {
      formatInfoBits1 = _copyBit(8, j, formatInfoBits1);
    }

    final int dimension = _bits.height;
    int formatInfoBits2 = 0;
    final int jMin = dimension - 7;
    for (int j = dimension - 1; j >= jMin; j--) {
      formatInfoBits2 = _copyBit(8, j, formatInfoBits2);
    }
    for (int i = dimension - 8; i < dimension; i++) {
      formatInfoBits2 = _copyBit(i, 8, formatInfoBits2);
    }

    final UQrFormatInformation? parsed = UQrFormatInformation.decode(formatInfoBits1, formatInfoBits2);
    if (parsed == null) throw const UCodeDecodeException("Unreadable QR format information");
    _formatInfo = parsed;
    return parsed;
  }

  UQrVersion readVersion() {
    final UQrVersion? cached = _version;
    if (cached != null) return cached;

    final int dimension = _bits.height;
    final int provisional = (dimension - 17) ~/ 4;
    if (provisional <= 6) {
      final UQrVersion version = UQrVersion.forNumber(provisional);
      _version = version;
      return version;
    }

    int versionBits = 0;
    final int ijMin = dimension - 11;
    for (int j = 5; j >= 0; j--) {
      for (int i = dimension - 9; i >= ijMin; i--) {
        versionBits = _copyBit(i, j, versionBits);
      }
    }
    UQrVersion? version = UQrVersion.decodeVersionInformation(versionBits);
    if (version != null && version.dimension == dimension) {
      _version = version;
      return version;
    }

    versionBits = 0;
    for (int i = 5; i >= 0; i--) {
      for (int j = dimension - 9; j >= ijMin; j--) {
        versionBits = _copyBit(i, j, versionBits);
      }
    }
    version = UQrVersion.decodeVersionInformation(versionBits);
    if (version != null && version.dimension == dimension) {
      _version = version;
      return version;
    }
    throw const UCodeDecodeException("Unreadable QR version information");
  }

  int _copyBit(int i, int j, int versionBits) {
    final bool bit = _mirrored ? _bits.get(j, i) : _bits.get(i, j);
    return bit ? (versionBits << 1) | 0x1 : versionBits << 1;
  }

  Uint8List readCodewords() {
    final UQrFormatInformation formatInfo = readFormatInformation();
    final UQrVersion version = readVersion();
    final UBitMatrix functionPattern = version.buildFunctionPattern();

    bool readingUp = true;
    final Uint8List result = Uint8List(version.totalCodewords);
    int resultOffset = 0;
    int currentByte = 0;
    int bitsRead = 0;
    final int dimension = _bits.height;

    for (int j = dimension - 1; j > 0; j -= 2) {
      if (j == 6) j--;
      for (int count = 0; count < dimension; count++) {
        final int i = readingUp ? dimension - 1 - count : count;
        for (int col = 0; col < 2; col++) {
          final int x = j - col;
          if (functionPattern.get(x, i)) continue;
          bitsRead++;
          currentByte <<= 1;
          bool bit = _bits.get(x, i);
          if (UQrDataMask.isMasked(formatInfo.dataMask, i, x)) bit = !bit;
          if (bit) currentByte |= 1;
          if (bitsRead == 8) {
            if (resultOffset < result.length) result[resultOffset++] = currentByte;
            bitsRead = 0;
            currentByte = 0;
          }
        }
      }
      readingUp = !readingUp;
    }
    if (resultOffset != version.totalCodewords) throw const UCodeDecodeException("QR codeword count mismatch");
    return result;
  }
}

class UQrDataBlock {
  UQrDataBlock(this.numDataCodewords, this.codewords);

  final int numDataCodewords;
  final Uint8List codewords;

  static List<UQrDataBlock> split(Uint8List rawCodewords, UQrVersion version, UQrFormatInformation formatInfo) {
    if (rawCodewords.length != version.totalCodewords) throw const UCodeDecodeException("Codeword length mismatch");
    final UQrEcBlocks ecBlocks = version.ecBlocks[formatInfo.levelIndex];

    final List<UQrDataBlock> result = <UQrDataBlock>[];
    for (final UQrEcb block in ecBlocks.blocks) {
      for (int i = 0; i < block.count; i++) {
        result.add(UQrDataBlock(block.dataCodewords, Uint8List(ecBlocks.ecCodewordsPerBlock + block.dataCodewords)));
      }
    }
    final int numResultBlocks = result.length;

    final int shorterBlocksTotalCodewords = result.first.codewords.length;
    int longerBlocksStartAt = numResultBlocks - 1;
    while (longerBlocksStartAt >= 0) {
      if (result[longerBlocksStartAt].codewords.length == shorterBlocksTotalCodewords) break;
      longerBlocksStartAt--;
    }
    longerBlocksStartAt++;

    final int shorterBlocksNumDataCodewords = shorterBlocksTotalCodewords - ecBlocks.ecCodewordsPerBlock;
    int rawCodewordsOffset = 0;
    for (int i = 0; i < shorterBlocksNumDataCodewords; i++) {
      for (int j = 0; j < numResultBlocks; j++) {
        result[j].codewords[i] = rawCodewords[rawCodewordsOffset++];
      }
    }
    for (int j = longerBlocksStartAt; j < numResultBlocks; j++) {
      result[j].codewords[shorterBlocksNumDataCodewords] = rawCodewords[rawCodewordsOffset++];
    }

    final int max = result.first.codewords.length;
    for (int i = shorterBlocksNumDataCodewords; i < max; i++) {
      for (int j = 0; j < numResultBlocks; j++) {
        final int iOffset = j < longerBlocksStartAt ? i : i + 1;
        result[j].codewords[iOffset] = rawCodewords[rawCodewordsOffset++];
      }
    }
    return result;
  }
}

class UBitSource {
  UBitSource(this.bytes);

  final Uint8List bytes;
  int _byteOffset = 0;
  int _bitOffset = 0;

  int get available => 8 * (bytes.length - _byteOffset) - _bitOffset;

  int get byteOffset => _byteOffset;

  int readBits(int numBits) {
    if (numBits < 1 || numBits > 32 || numBits > available) throw const UCodeDecodeException("Bit source overrun");
    int result = 0;
    int remaining = numBits;

    if (_bitOffset > 0) {
      final int bitsLeft = 8 - _bitOffset;
      final int toRead = remaining < bitsLeft ? remaining : bitsLeft;
      final int bitsToNotRead = bitsLeft - toRead;
      final int mask = (0xFF >> (8 - toRead)) << bitsToNotRead;
      result = (bytes[_byteOffset] & mask) >> bitsToNotRead;
      remaining -= toRead;
      _bitOffset += toRead;
      if (_bitOffset == 8) {
        _bitOffset = 0;
        _byteOffset++;
      }
    }

    if (remaining > 0) {
      while (remaining >= 8) {
        result = (result << 8) | (bytes[_byteOffset] & 0xFF);
        _byteOffset++;
        remaining -= 8;
      }
      if (remaining > 0) {
        final int bitsToNotRead = 8 - remaining;
        final int mask = (0xFF >> bitsToNotRead) << bitsToNotRead;
        result = (result << remaining) | ((bytes[_byteOffset] & mask) >> bitsToNotRead);
        _bitOffset += remaining;
      }
    }
    return result;
  }
}

class UQrDecodeResult {
  const UQrDecodeResult({required this.text, required this.bytes, this.eci, this.structuredAppend, this.symbologyModifier = 1});

  final String text;
  final Uint8List bytes;
  final int? eci;
  final UCodeStructuredAppend? structuredAppend;
  final int symbologyModifier;
}

abstract class UQrDecodedBitStream {
  static const String _alphanumericChars = r"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";

  static UQrDecodeResult decode(Uint8List bytes, UQrVersion version, UQrEcLevel level) {
    final UBitSource bits = UBitSource(bytes);
    final StringBuffer result = StringBuffer();
    final List<int> byteSegments = <int>[];
    int? eci;
    UCodeStructuredAppend? structuredAppend;
    int symbologyModifier = 1;
    bool fnc1 = false;
    bool utf8Hint = false;

    while (bits.available >= 4) {
      final int mode = bits.readBits(4);
      if (mode == 0) break;
      switch (mode) {
        case 0x05:
          fnc1 = true;
          symbologyModifier = 3;
          break;
        case 0x09:
          if (bits.available < 8) break;
          bits.readBits(8);
          fnc1 = true;
          symbologyModifier = 5;
          break;
        case 0x03:
          if (bits.available < 16) throw const UCodeDecodeException("Truncated structured append");
          final int symbolSequence = bits.readBits(8);
          final int parity = bits.readBits(8);
          structuredAppend = UCodeStructuredAppend(index: symbolSequence >> 4, total: (symbolSequence & 0x0F) + 1, parity: parity);
          break;
        case 0x07:
          final int value = _parseEci(bits);
          if (value < 0 || value > 999999) throw const UCodeDecodeException("Bad ECI value");
          eci = value;
          utf8Hint = value == 26;
          break;
        case 0x01:
          _decodeNumeric(bits, result, bits.readBits(_characterCountBits(mode, version)));
          break;
        case 0x02:
          _decodeAlphanumeric(bits, result, bits.readBits(_characterCountBits(mode, version)), fnc1);
          break;
        case 0x04:
          _decodeByte(bits, result, byteSegments, bits.readBits(_characterCountBits(mode, version)), eci, utf8Hint);
          break;
        case 0x08:
          _decodeKanji(bits, result, bits.readBits(_characterCountBits(mode, version)));
          break;
        default:
          throw const UCodeDecodeException("Unsupported QR mode");
      }
    }

    final String text = result.toString();
    return UQrDecodeResult(
      text: text,
      bytes: byteSegments.isNotEmpty ? Uint8List.fromList(byteSegments) : Uint8List.fromList(utf8.encode(text)),
      eci: eci,
      structuredAppend: structuredAppend,
      symbologyModifier: symbologyModifier,
    );
  }

  static int _parseEci(UBitSource bits) {
    final int firstByte = bits.readBits(8);
    if ((firstByte & 0x80) == 0) return firstByte & 0x7F;
    if ((firstByte & 0xC0) == 0x80) return ((firstByte & 0x3F) << 8) | bits.readBits(8);
    if ((firstByte & 0xE0) == 0xC0) return ((firstByte & 0x1F) << 16) | bits.readBits(16);
    return -1;
  }

  static int _characterCountBits(int mode, UQrVersion version) {
    final int number = version.number;
    final int offset = number <= 9 ? 0 : (number <= 26 ? 1 : 2);
    switch (mode) {
      case 0x01:
        return const <int>[10, 12, 14][offset];
      case 0x02:
        return const <int>[9, 11, 13][offset];
      case 0x04:
        return const <int>[8, 16, 16][offset];
      case 0x08:
        return const <int>[8, 10, 12][offset];
      default:
        return 0;
    }
  }

  static void _decodeNumeric(UBitSource bits, StringBuffer result, int count) {
    int remaining = count;
    while (remaining >= 3) {
      final int threeDigits = bits.readBits(10);
      if (threeDigits >= 1000) throw const UCodeDecodeException("Bad numeric triple");
      result
        ..write(_alphanumericChars[threeDigits ~/ 100])
        ..write(_alphanumericChars[(threeDigits ~/ 10) % 10])
        ..write(_alphanumericChars[threeDigits % 10]);
      remaining -= 3;
    }
    if (remaining == 2) {
      final int twoDigits = bits.readBits(7);
      if (twoDigits >= 100) throw const UCodeDecodeException("Bad numeric pair");
      result
        ..write(_alphanumericChars[twoDigits ~/ 10])
        ..write(_alphanumericChars[twoDigits % 10]);
    } else if (remaining == 1) {
      final int digit = bits.readBits(4);
      if (digit >= 10) throw const UCodeDecodeException("Bad numeric digit");
      result.write(_alphanumericChars[digit]);
    }
  }

  static void _decodeAlphanumeric(UBitSource bits, StringBuffer result, int count, bool fnc1) {
    final int start = result.length;
    int remaining = count;
    while (remaining > 1) {
      final int nextTwoChars = bits.readBits(11);
      result
        ..write(_alphanumericChars[nextTwoChars ~/ 45])
        ..write(_alphanumericChars[nextTwoChars % 45]);
      remaining -= 2;
    }
    if (remaining == 1) result.write(_alphanumericChars[bits.readBits(6)]);
    if (!fnc1) return;

    final String whole = result.toString();
    final String segment = whole.substring(start);
    if (!segment.contains("%")) return;
    final String groupSeparator = String.fromCharCode(29);
    final String placeholder = String.fromCharCode(0);
    final String replaced = segment.replaceAll("%%", placeholder).replaceAll("%", groupSeparator).replaceAll(placeholder, "%");
    result
      ..clear()
      ..write(whole.substring(0, start))
      ..write(replaced);
  }

  static void _decodeByte(UBitSource bits, StringBuffer result, List<int> byteSegments, int count, int? eci, bool utf8Hint) {
    if (8 * count > bits.available) throw const UCodeDecodeException("Truncated byte segment");
    final Uint8List readBytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      readBytes[i] = bits.readBits(8);
    }
    byteSegments.addAll(readBytes);
    result.write(UCharsetDecoder.decode(readBytes, eci: eci, preferUtf8: utf8Hint));
  }

  static void _decodeKanji(UBitSource bits, StringBuffer result, int count) {
    if (count * 13 > bits.available) throw const UCodeDecodeException("Truncated kanji segment");
    final List<int> buffer = <int>[];
    int remaining = count;
    while (remaining > 0) {
      final int twoBytes = bits.readBits(13);
      int assembled = ((twoBytes ~/ 0x0C0) << 8) | (twoBytes % 0x0C0);
      assembled += assembled < 0x01F00 ? 0x08140 : 0x0C140;
      buffer
        ..add((assembled >> 8) & 0xFF)
        ..add(assembled & 0xFF);
      remaining--;
    }
    result.write(UCharsetDecoder.shiftJis(Uint8List.fromList(buffer)));
  }
}

/// Decodes byte segments using the declared ECI charset, with a UTF-8 then
/// Latin-1 fallback when no ECI is present.
abstract class UCharsetDecoder {
  static String decode(Uint8List bytes, {int? eci, bool preferUtf8 = false}) {
    if (eci == 25) return _utf16be(bytes);
    if (eci == 20) return shiftJis(bytes);
    if (eci == 27 || eci == 170) return String.fromCharCodes(bytes.map((int b) => b & 0x7F));
    return _tryUtf8(bytes) ?? String.fromCharCodes(bytes);
  }

  static String? _tryUtf8(Uint8List bytes) {
    try {
      return const Utf8Decoder().convert(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _utf16be(Uint8List bytes) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      buffer.writeCharCode((bytes[i] << 8) | bytes[i + 1]);
    }
    return buffer.toString();
  }

  /// Minimal Shift-JIS handling: ASCII and half-width katakana map directly and
  /// double-byte sequences become the replacement character, so the rest of the
  /// payload still decodes instead of failing outright.
  static String shiftJis(Uint8List bytes) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      final int b = bytes[i];
      if (b < 0x80) {
        buffer.writeCharCode(b);
      } else if (b >= 0xA1 && b <= 0xDF) {
        buffer.writeCharCode(0xFF61 + (b - 0xA1));
      } else {
        buffer.write(String.fromCharCode(0xFFFD));
        if (i + 1 < bytes.length) i++;
      }
    }
    return buffer.toString();
  }
}

// =============================================================================
// QR detection: finder patterns, alignment patterns, perspective sampling
// =============================================================================

class UPatternPoint {
  const UPatternPoint(this.x, this.y, this.estimatedModuleSize, [this.count = 1]);

  final double x;
  final double y;
  final double estimatedModuleSize;
  final int count;

  Offset get offset => Offset(x, y);

  bool aboutEquals(double moduleSize, double i, double j) {
    if ((i - y).abs() > moduleSize || (j - x).abs() > moduleSize) return false;
    final double moduleSizeDifference = (moduleSize - estimatedModuleSize).abs();
    return moduleSizeDifference <= 1.0 || moduleSizeDifference <= estimatedModuleSize;
  }

  UPatternPoint combine(double i, double j, double newModuleSize) {
    final int combinedCount = count + 1;
    return UPatternPoint(
      (count * x + j) / combinedCount,
      (count * y + i) / combinedCount,
      (count * estimatedModuleSize + newModuleSize) / combinedCount,
      combinedCount,
    );
  }

  static double distance(UPatternPoint a, UPatternPoint b) {
    final double dx = a.x - b.x;
    final double dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }
}

class UQrFinderInfo {
  const UQrFinderInfo(this.bottomLeft, this.topLeft, this.topRight);

  final UPatternPoint bottomLeft;
  final UPatternPoint topLeft;
  final UPatternPoint topRight;
}

/// Locates the three 1:1:3:1:1 finder patterns of a QR symbol.
class UQrFinderPatternFinder {
  UQrFinderPatternFinder(this.image);

  static const int _centerQuorum = 2;
  static const int _minSkip = 3;
  static const int _maxModules = 97;

  final UBitMatrix image;
  final List<UPatternPoint> _possibleCenters = <UPatternPoint>[];
  bool _hasSkipped = false;

  List<UQrFinderInfo> find({bool tryHarder = true, int maxSymbols = 8}) {
    final int maxI = image.height;
    final int maxJ = image.width;
    int iSkip = (3 * maxI) ~/ (4 * _maxModules);
    if (iSkip < _minSkip || tryHarder) iSkip = _minSkip;

    bool done = false;
    final Int32List stateCount = Int32List(5);
    for (int i = iSkip - 1; i < maxI && !done; i += iSkip) {
      _clear(stateCount);
      int currentState = 0;
      for (int j = 0; j < maxJ; j++) {
        if (image.get(j, i)) {
          if ((currentState & 1) == 1) currentState++;
          stateCount[currentState]++;
        } else {
          if ((currentState & 1) == 0) {
            if (currentState == 4) {
              if (_foundPatternCross(stateCount)) {
                final bool confirmed = _handlePossibleCenter(stateCount, i, j);
                if (confirmed) {
                  iSkip = 2;
                  if (_hasSkipped) {
                    done = _haveMultiplyConfirmedCenters();
                  } else {
                    final int rowSkip = _findRowSkip();
                    if (rowSkip > stateCount[2]) {
                      i += rowSkip - stateCount[2] - iSkip;
                      j = maxJ - 1;
                    }
                  }
                  _clear(stateCount);
                  currentState = 0;
                  continue;
                }
              }
              stateCount[0] = stateCount[2];
              stateCount[1] = stateCount[3];
              stateCount[2] = stateCount[4];
              stateCount[3] = 1;
              stateCount[4] = 0;
              currentState = 3;
              continue;
            }
            currentState++;
            stateCount[currentState]++;
          } else {
            stateCount[currentState]++;
          }
        }
      }
      if (_foundPatternCross(stateCount)) {
        final bool confirmed = _handlePossibleCenter(stateCount, i, maxJ);
        if (confirmed) {
          iSkip = stateCount[0];
          if (_hasSkipped) done = _haveMultiplyConfirmedCenters();
        }
      }
    }
    return _selectBestPatterns(maxSymbols);
  }

  static void _clear(Int32List stateCount) {
    stateCount[0] = 0;
    stateCount[1] = 0;
    stateCount[2] = 0;
    stateCount[3] = 0;
    stateCount[4] = 0;
  }

  static bool _foundPatternCross(Int32List stateCount) {
    int totalModuleSize = 0;
    for (int i = 0; i < 5; i++) {
      final int count = stateCount[i];
      if (count == 0) return false;
      totalModuleSize += count;
    }
    if (totalModuleSize < 7) return false;
    final double moduleSize = totalModuleSize / 7.0;
    final double maxVariance = moduleSize / 2.0;
    return (moduleSize - stateCount[0]).abs() < maxVariance &&
        (moduleSize - stateCount[1]).abs() < maxVariance &&
        (3.0 * moduleSize - stateCount[2]).abs() < 3 * maxVariance &&
        (moduleSize - stateCount[3]).abs() < maxVariance &&
        (moduleSize - stateCount[4]).abs() < maxVariance;
  }

  static double _centerFromEnd(Int32List stateCount, int end) => (end - stateCount[4] - stateCount[3]) - stateCount[2] / 2.0;

  double? _crossCheckVertical(int startI, int centerJ, int maxCount, int originalStateCountTotal) {
    final Int32List stateCount = Int32List(5);
    int i = startI;
    while (i >= 0 && image.get(centerJ, i)) {
      stateCount[2]++;
      i--;
    }
    if (i < 0) return null;
    while (i >= 0 && !image.get(centerJ, i) && stateCount[1] <= maxCount) {
      stateCount[1]++;
      i--;
    }
    if (i < 0 || stateCount[1] > maxCount) return null;
    while (i >= 0 && image.get(centerJ, i) && stateCount[0] <= maxCount) {
      stateCount[0]++;
      i--;
    }
    if (stateCount[0] > maxCount) return null;

    final int maxI = image.height;
    i = startI + 1;
    while (i < maxI && image.get(centerJ, i)) {
      stateCount[2]++;
      i++;
    }
    if (i == maxI) return null;
    while (i < maxI && !image.get(centerJ, i) && stateCount[3] < maxCount) {
      stateCount[3]++;
      i++;
    }
    if (i == maxI || stateCount[3] >= maxCount) return null;
    while (i < maxI && image.get(centerJ, i) && stateCount[4] < maxCount) {
      stateCount[4]++;
      i++;
    }
    if (stateCount[4] >= maxCount) return null;

    final int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
    if (5 * (stateCountTotal - originalStateCountTotal).abs() >= 2 * originalStateCountTotal) return null;
    return _foundPatternCross(stateCount) ? _centerFromEnd(stateCount, i) : null;
  }

  double? _crossCheckHorizontal(int startJ, int centerI, int maxCount, int originalStateCountTotal) {
    final Int32List stateCount = Int32List(5);
    int j = startJ;
    while (j >= 0 && image.get(j, centerI)) {
      stateCount[2]++;
      j--;
    }
    if (j < 0) return null;
    while (j >= 0 && !image.get(j, centerI) && stateCount[1] <= maxCount) {
      stateCount[1]++;
      j--;
    }
    if (j < 0 || stateCount[1] > maxCount) return null;
    while (j >= 0 && image.get(j, centerI) && stateCount[0] <= maxCount) {
      stateCount[0]++;
      j--;
    }
    if (stateCount[0] > maxCount) return null;

    final int maxJ = image.width;
    j = startJ + 1;
    while (j < maxJ && image.get(j, centerI)) {
      stateCount[2]++;
      j++;
    }
    if (j == maxJ) return null;
    while (j < maxJ && !image.get(j, centerI) && stateCount[3] < maxCount) {
      stateCount[3]++;
      j++;
    }
    if (j == maxJ || stateCount[3] >= maxCount) return null;
    while (j < maxJ && image.get(j, centerI) && stateCount[4] < maxCount) {
      stateCount[4]++;
      j++;
    }
    if (stateCount[4] >= maxCount) return null;

    final int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
    if (5 * (stateCountTotal - originalStateCountTotal).abs() >= originalStateCountTotal) return null;
    return _foundPatternCross(stateCount) ? _centerFromEnd(stateCount, j) : null;
  }

  bool _handlePossibleCenter(Int32List stateCount, int i, int j) {
    final int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
    final double centerJ = _centerFromEnd(stateCount, j);
    final double? centerI = _crossCheckVertical(i, centerJ.toInt(), stateCount[2], stateCountTotal);
    if (centerI == null) return false;
    final double? checkedJ = _crossCheckHorizontal(centerJ.toInt(), centerI.toInt(), stateCount[2], stateCountTotal);
    if (checkedJ == null) return false;

    final double estimatedModuleSize = stateCountTotal / 7.0;
    for (int index = 0; index < _possibleCenters.length; index++) {
      final UPatternPoint center = _possibleCenters[index];
      if (center.aboutEquals(estimatedModuleSize, centerI, checkedJ)) {
        _possibleCenters[index] = center.combine(centerI, checkedJ, estimatedModuleSize);
        return true;
      }
    }
    _possibleCenters.add(UPatternPoint(checkedJ, centerI, estimatedModuleSize));
    return false;
  }

  int _findRowSkip() {
    if (_possibleCenters.length <= 1) return 0;
    UPatternPoint? firstConfirmed;
    for (final UPatternPoint center in _possibleCenters) {
      if (center.count < _centerQuorum) continue;
      if (firstConfirmed == null) {
        firstConfirmed = center;
      } else {
        _hasSkipped = true;
        return ((firstConfirmed.x - center.x).abs() - (firstConfirmed.y - center.y).abs()).abs() ~/ 2;
      }
    }
    return 0;
  }

  bool _haveMultiplyConfirmedCenters() {
    int confirmedCount = 0;
    double totalModuleSize = 0;
    for (final UPatternPoint center in _possibleCenters) {
      if (center.count < _centerQuorum) continue;
      confirmedCount++;
      totalModuleSize += center.estimatedModuleSize;
    }
    if (confirmedCount < 3) return false;
    final double average = totalModuleSize / _possibleCenters.length;
    double totalDeviation = 0;
    for (final UPatternPoint center in _possibleCenters) {
      totalDeviation += (center.estimatedModuleSize - average).abs();
    }
    return totalDeviation <= 0.05 * totalModuleSize;
  }

  List<UQrFinderInfo> _selectBestPatterns(int maxSymbols) {
    final List<UPatternPoint> candidates = _possibleCenters.where((UPatternPoint p) => p.count >= _centerQuorum).toList();
    if (candidates.length < 3) {
      if (_possibleCenters.length < 3) return const <UQrFinderInfo>[];
      candidates
        ..clear()
        ..addAll(_possibleCenters);
    }
    candidates.sort((UPatternPoint a, UPatternPoint b) => b.count.compareTo(a.count));

    final List<UQrFinderInfo> results = <UQrFinderInfo>[];
    final int limit = candidates.length > 12 ? 12 : candidates.length;
    for (int a = 0; a < limit - 2 && results.length < maxSymbols; a++) {
      for (int b = a + 1; b < limit - 1 && results.length < maxSymbols; b++) {
        for (int c = b + 1; c < limit && results.length < maxSymbols; c++) {
          final UQrFinderInfo? info = _orderBestPatterns(candidates[a], candidates[b], candidates[c]);
          if (info != null) results.add(info);
        }
      }
    }
    return results;
  }

  static UQrFinderInfo? _orderBestPatterns(UPatternPoint p0, UPatternPoint p1, UPatternPoint p2) {
    final double zeroOne = UPatternPoint.distance(p0, p1);
    final double oneTwo = UPatternPoint.distance(p1, p2);
    final double zeroTwo = UPatternPoint.distance(p0, p2);

    UPatternPoint pointA;
    UPatternPoint pointB;
    UPatternPoint pointC;
    if (oneTwo >= zeroOne && oneTwo >= zeroTwo) {
      pointB = p0;
      pointA = p1;
      pointC = p2;
    } else if (zeroTwo >= oneTwo && zeroTwo >= zeroOne) {
      pointB = p1;
      pointA = p0;
      pointC = p2;
    } else {
      pointB = p2;
      pointA = p0;
      pointC = p1;
    }

    if (_crossProductZ(pointA, pointB, pointC) < 0.0) {
      final UPatternPoint swap = pointA;
      pointA = pointC;
      pointC = swap;
    }

    final double moduleSize = (pointA.estimatedModuleSize + pointB.estimatedModuleSize + pointC.estimatedModuleSize) / 3;
    if (moduleSize <= 0) return null;
    final double hypotenuse = UPatternPoint.distance(pointA, pointC);
    final double side = UPatternPoint.distance(pointA, pointB);
    if (side <= 0 || hypotenuse <= 0) return null;
    final double ratio = hypotenuse / side;
    if (ratio < 0.5 || ratio > 2.0) return null;
    return UQrFinderInfo(pointA, pointB, pointC);
  }

  static double _crossProductZ(UPatternPoint a, UPatternPoint b, UPatternPoint c) =>
      ((c.x - b.x) * (a.y - b.y)) - ((c.y - b.y) * (a.x - b.x));
}

/// Finds the alignment pattern near the bottom-right of larger QR symbols.
class UQrAlignmentPatternFinder {
  UQrAlignmentPatternFinder(this.image, this.startX, this.startY, this.width, this.height, this.moduleSize);

  final UBitMatrix image;
  final int startX;
  final int startY;
  final int width;
  final int height;
  final double moduleSize;
  final List<UPatternPoint> _possibleCenters = <UPatternPoint>[];

  UPatternPoint? find() {
    final int maxJ = startX + width;
    final int middleI = startY + (height ~/ 2);
    final Int32List stateCount = Int32List(3);
    for (int iGen = 0; iGen < height; iGen++) {
      final int i = middleI + ((iGen & 0x01) == 0 ? (iGen + 1) ~/ 2 : -((iGen + 1) ~/ 2));
      if (i < 0 || i >= image.height) continue;
      stateCount[0] = 0;
      stateCount[1] = 0;
      stateCount[2] = 0;
      int j = startX;
      while (j < maxJ && !image.get(j, i)) {
        j++;
      }
      int currentState = 0;
      while (j < maxJ) {
        if (image.get(j, i)) {
          if (currentState == 1) {
            stateCount[1]++;
          } else {
            if (currentState == 2) {
              if (_foundPatternCross(stateCount)) {
                final UPatternPoint? confirmed = _handlePossibleCenter(stateCount, i, j);
                if (confirmed != null) return confirmed;
              }
              stateCount[0] = stateCount[2];
              stateCount[1] = 1;
              stateCount[2] = 0;
              currentState = 1;
            } else {
              currentState++;
              stateCount[currentState]++;
            }
          }
        } else {
          if (currentState == 1) currentState++;
          stateCount[currentState]++;
        }
        j++;
      }
      if (_foundPatternCross(stateCount)) {
        final UPatternPoint? confirmed = _handlePossibleCenter(stateCount, i, maxJ);
        if (confirmed != null) return confirmed;
      }
    }
    return _possibleCenters.isNotEmpty ? _possibleCenters.first : null;
  }

  bool _foundPatternCross(Int32List stateCount) {
    final double maxVariance = moduleSize / 2.0;
    for (int i = 0; i < 3; i++) {
      if ((moduleSize - stateCount[i]).abs() >= maxVariance) return false;
    }
    return true;
  }

  double? _crossCheckVertical(int startI, int centerJ, int maxCount, int originalStateCountTotal) {
    final int maxI = image.height;
    final Int32List stateCount = Int32List(3);
    int i = startI;
    while (i >= 0 && image.get(centerJ, i) && stateCount[1] <= maxCount) {
      stateCount[1]++;
      i--;
    }
    if (i < 0 || stateCount[1] > maxCount) return null;
    while (i >= 0 && !image.get(centerJ, i) && stateCount[0] <= maxCount) {
      stateCount[0]++;
      i--;
    }
    if (stateCount[0] > maxCount) return null;

    i = startI + 1;
    while (i < maxI && image.get(centerJ, i) && stateCount[1] <= maxCount) {
      stateCount[1]++;
      i++;
    }
    if (i == maxI || stateCount[1] > maxCount) return null;
    while (i < maxI && !image.get(centerJ, i) && stateCount[2] <= maxCount) {
      stateCount[2]++;
      i++;
    }
    if (stateCount[2] > maxCount) return null;

    final int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2];
    if (5 * (stateCountTotal - originalStateCountTotal).abs() >= 2 * originalStateCountTotal) return null;
    return _foundPatternCross(stateCount) ? (i - stateCount[2]) - stateCount[1] / 2.0 : null;
  }

  UPatternPoint? _handlePossibleCenter(Int32List stateCount, int i, int j) {
    final int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2];
    final double centerJ = (j - stateCount[2]) - stateCount[1] / 2.0;
    final double? centerI = _crossCheckVertical(i, centerJ.toInt(), 2 * stateCount[1], stateCountTotal);
    if (centerI == null) return null;
    final double estimatedModuleSize = stateCountTotal / 3.0;
    for (final UPatternPoint center in _possibleCenters) {
      if (center.aboutEquals(estimatedModuleSize, centerI, centerJ)) return center.combine(centerI, centerJ, estimatedModuleSize);
    }
    _possibleCenters.add(UPatternPoint(centerJ, centerI, estimatedModuleSize));
    return null;
  }
}

class UQrDetectorResult {
  const UQrDetectorResult(this.bits, this.points);

  final UBitMatrix bits;
  final List<Offset> points;
}

class UQrDetector {
  const UQrDetector(this.image);

  final UBitMatrix image;

  List<UQrDetectorResult> detect({bool tryHarder = true, int maxSymbols = 8}) {
    final List<UQrFinderInfo> infos = UQrFinderPatternFinder(image).find(tryHarder: tryHarder, maxSymbols: maxSymbols);
    final List<UQrDetectorResult> results = <UQrDetectorResult>[];
    for (final UQrFinderInfo info in infos) {
      try {
        final UQrDetectorResult? result = _processFinderPatternInfo(info);
        if (result != null) results.add(result);
      } catch (_) {
        continue;
      }
    }
    return results;
  }

  UQrDetectorResult? _processFinderPatternInfo(UQrFinderInfo info) {
    final UPatternPoint topLeft = info.topLeft;
    final UPatternPoint topRight = info.topRight;
    final UPatternPoint bottomLeft = info.bottomLeft;

    final double moduleSize = _calculateModuleSize(topLeft, topRight, bottomLeft);
    if (moduleSize < 1.0) return null;
    final int dimension = _computeDimension(topLeft, topRight, bottomLeft, moduleSize);
    final UQrVersion? provisionalVersion = UQrVersion.forDimension(dimension);
    if (provisionalVersion == null) return null;
    final int modulesBetweenFinderPatterns = provisionalVersion.dimension - 7;

    UPatternPoint? alignmentPattern;
    if (provisionalVersion.alignmentPatternCenters.isNotEmpty) {
      final double bottomRightX = topRight.x - topLeft.x + bottomLeft.x;
      final double bottomRightY = topRight.y - topLeft.y + bottomLeft.y;
      final double correctionToTopLeft = 1.0 - 3.0 / modulesBetweenFinderPatterns;
      final int estAlignmentX = (topLeft.x + correctionToTopLeft * (bottomRightX - topLeft.x)).toInt();
      final int estAlignmentY = (topLeft.y + correctionToTopLeft * (bottomRightY - topLeft.y)).toInt();
      for (int i = 4; i <= 16; i <<= 1) {
        alignmentPattern = _findAlignmentInRegion(moduleSize, estAlignmentX, estAlignmentY, i.toDouble());
        if (alignmentPattern != null) break;
      }
    }

    final UPerspectiveTransform transform = _createTransform(topLeft, topRight, bottomLeft, alignmentPattern, dimension);
    final UBitMatrix bits = UGridSampler.sample(image, dimension, dimension, transform);
    final List<Offset> points = alignmentPattern == null
        ? <Offset>[bottomLeft.offset, topLeft.offset, topRight.offset]
        : <Offset>[bottomLeft.offset, topLeft.offset, topRight.offset, alignmentPattern.offset];
    return UQrDetectorResult(bits, points);
  }

  static UPerspectiveTransform _createTransform(
    UPatternPoint topLeft,
    UPatternPoint topRight,
    UPatternPoint bottomLeft,
    UPatternPoint? alignmentPattern,
    int dimension,
  ) {
    final double dimMinusThree = dimension - 3.5;
    double bottomRightX;
    double bottomRightY;
    double sourceBottomRightX;
    double sourceBottomRightY;
    if (alignmentPattern != null) {
      bottomRightX = alignmentPattern.x;
      bottomRightY = alignmentPattern.y;
      sourceBottomRightX = dimMinusThree - 3.0;
      sourceBottomRightY = sourceBottomRightX;
    } else {
      bottomRightX = (topRight.x - topLeft.x) + bottomLeft.x;
      bottomRightY = (topRight.y - topLeft.y) + bottomLeft.y;
      sourceBottomRightX = dimMinusThree;
      sourceBottomRightY = dimMinusThree;
    }
    return UPerspectiveTransform.quadrilateralToQuadrilateral(
      3.5,
      3.5,
      dimMinusThree,
      3.5,
      sourceBottomRightX,
      sourceBottomRightY,
      3.5,
      dimMinusThree,
      topLeft.x,
      topLeft.y,
      topRight.x,
      topRight.y,
      bottomRightX,
      bottomRightY,
      bottomLeft.x,
      bottomLeft.y,
    );
  }

  double _calculateModuleSize(UPatternPoint topLeft, UPatternPoint topRight, UPatternPoint bottomLeft) =>
      (_calculateModuleSizeOneWay(topLeft, topRight) + _calculateModuleSizeOneWay(topLeft, bottomLeft)) / 2.0;

  double _calculateModuleSizeOneWay(UPatternPoint pattern, UPatternPoint otherPattern) {
    final double moduleSizeEst1 = _sizeOfBlackWhiteBlackRunBothWays(pattern.x.toInt(), pattern.y.toInt(), otherPattern.x.toInt(), otherPattern.y.toInt());
    final double moduleSizeEst2 = _sizeOfBlackWhiteBlackRunBothWays(otherPattern.x.toInt(), otherPattern.y.toInt(), pattern.x.toInt(), pattern.y.toInt());
    if (moduleSizeEst1.isNaN) return moduleSizeEst2 / 7.0;
    if (moduleSizeEst2.isNaN) return moduleSizeEst1 / 7.0;
    return (moduleSizeEst1 + moduleSizeEst2) / 14.0;
  }

  double _sizeOfBlackWhiteBlackRunBothWays(int fromX, int fromY, int toX, int toY) {
    double result = _sizeOfBlackWhiteBlackRun(fromX, fromY, toX, toY);
    double scale = 1;
    int otherToX = fromX - (toX - fromX);
    if (otherToX < 0) {
      scale = fromX / (fromX - otherToX);
      otherToX = 0;
    } else if (otherToX >= image.width) {
      scale = (image.width - 1 - fromX) / (otherToX - fromX);
      otherToX = image.width - 1;
    }
    int otherToY = (fromY - (toY - fromY) * scale).toInt();
    scale = 1;
    if (otherToY < 0) {
      scale = fromY / (fromY - otherToY);
      otherToY = 0;
    } else if (otherToY >= image.height) {
      scale = (image.height - 1 - fromY) / (otherToY - fromY);
      otherToY = image.height - 1;
    }
    otherToX = (fromX + (otherToX - fromX) * scale).toInt();
    result += _sizeOfBlackWhiteBlackRun(fromX, fromY, otherToX, otherToY);
    return result - 1.0;
  }

  double _sizeOfBlackWhiteBlackRun(int fromX, int fromY, int toX, int toY) {
    final bool steep = (toY - fromY).abs() > (toX - fromX).abs();
    int x1 = fromX;
    int y1 = fromY;
    int x2 = toX;
    int y2 = toY;
    if (steep) {
      int temp = x1;
      x1 = y1;
      y1 = temp;
      temp = x2;
      x2 = y2;
      y2 = temp;
    }

    final int dx = (x2 - x1).abs();
    final int dy = (y2 - y1).abs();
    int error = -dx ~/ 2;
    final int xStep = x1 < x2 ? 1 : -1;
    final int yStep = y1 < y2 ? 1 : -1;

    int state = 0;
    final int xLimit = x2 + xStep;
    int x = x1;
    int y = y1;
    while (x != xLimit) {
      final int realX = steep ? y : x;
      final int realY = steep ? x : y;
      if ((state == 1) == image.get(realX, realY)) {
        if (state == 2) {
          final int diffX = x - x1;
          final int diffY = y - y1;
          return sqrt((diffX * diffX + diffY * diffY).toDouble());
        }
        state++;
      }
      error += dy;
      if (error > 0) {
        if (y == y2) break;
        y += yStep;
        error -= dx;
      }
      x += xStep;
    }
    if (state == 2) {
      final int diffX = x2 + xStep - x1;
      final int diffY = y2 - y1;
      return sqrt((diffX * diffX + diffY * diffY).toDouble());
    }
    return double.nan;
  }

  static int _computeDimension(UPatternPoint topLeft, UPatternPoint topRight, UPatternPoint bottomLeft, double moduleSize) {
    final int tltrCentersDimension = (UPatternPoint.distance(topLeft, topRight) / moduleSize).round();
    final int tlblCentersDimension = (UPatternPoint.distance(topLeft, bottomLeft) / moduleSize).round();
    int dimension = ((tltrCentersDimension + tlblCentersDimension) ~/ 2) + 7;
    switch (dimension & 0x03) {
      case 0:
        dimension++;
        break;
      case 2:
        dimension--;
        break;
      case 3:
        return 0;
    }
    return dimension;
  }

  UPatternPoint? _findAlignmentInRegion(double overallEstModuleSize, int estAlignmentX, int estAlignmentY, double allowanceFactor) {
    final int allowance = (allowanceFactor * overallEstModuleSize).toInt();
    final int alignmentAreaLeftX = max(0, estAlignmentX - allowance);
    final int alignmentAreaRightX = min(image.width - 1, estAlignmentX + allowance);
    if (alignmentAreaRightX - alignmentAreaLeftX < overallEstModuleSize * 3) return null;
    final int alignmentAreaTopY = max(0, estAlignmentY - allowance);
    final int alignmentAreaBottomY = min(image.height - 1, estAlignmentY + allowance);
    if (alignmentAreaBottomY - alignmentAreaTopY < overallEstModuleSize * 3) return null;
    return UQrAlignmentPatternFinder(
      image,
      alignmentAreaLeftX,
      alignmentAreaTopY,
      alignmentAreaRightX - alignmentAreaLeftX,
      alignmentAreaBottomY - alignmentAreaTopY,
      overallEstModuleSize,
    ).find();
  }
}

/// Decodes an already-sampled QR bit matrix, retrying mirrored.
abstract class UQrMatrixDecoder {
  static UCode decode(UBitMatrix bits, List<Offset> points) {
    try {
      return _decodeInternal(bits.copy(), points, false);
    } catch (_) {
      final UQrBitMatrixParser parser = UQrBitMatrixParser(bits);
      parser.mirror();
      return _decodeInternal(bits, points.reversed.toList(growable: false), true);
    }
  }

  static UCode _decodeInternal(UBitMatrix bits, List<Offset> points, bool mirrored) {
    final UQrBitMatrixParser parser = UQrBitMatrixParser(bits);
    if (mirrored) parser.mirror();
    final UQrVersion version = parser.readVersion();
    final UQrFormatInformation formatInfo = parser.readFormatInformation();
    final Uint8List codewords = parser.readCodewords();
    final List<UQrDataBlock> blocks = UQrDataBlock.split(codewords, version, formatInfo);

    int totalBytes = 0;
    for (final UQrDataBlock block in blocks) {
      totalBytes += block.numDataCodewords;
    }
    final Uint8List resultBytes = Uint8List(totalBytes);
    int resultOffset = 0;
    for (final UQrDataBlock block in blocks) {
      final Uint8List codewordBytes = block.codewords;
      final int numDataCodewords = block.numDataCodewords;
      final Int32List codewordsInt = Int32List(codewordBytes.length);
      for (int i = 0; i < codewordBytes.length; i++) {
        codewordsInt[i] = codewordBytes[i];
      }
      UReedSolomon.decode(UGaloisField.qr, codewordsInt, codewordBytes.length - numDataCodewords);
      for (int i = 0; i < numDataCodewords; i++) {
        resultBytes[resultOffset++] = codewordsInt[i] & 0xFF;
      }
    }

    final UQrDecodeResult decoded = UQrDecodedBitStream.decode(resultBytes, version, formatInfo.errorCorrectionLevel);
    return UCode(
      format: UCodeFormat.qr,
      text: decoded.text,
      bytes: decoded.bytes,
      corners: points,
      eci: decoded.eci,
      structuredAppend: decoded.structuredAppend,
      errorCorrectionLevel: formatInfo.levelName,
      version: version.number,
      mask: formatInfo.dataMask,
    );
  }
}

// =============================================================================
// Data Matrix
// =============================================================================

/// Finds a white-bordered rectangle containing a symbol, used as the starting
/// point for the Data Matrix and PDF417 detectors.
class UWhiteRectangleDetector {
  UWhiteRectangleDetector(this.image, {int initSize = 10, int? x, int? y})
    : _leftInit = (x ?? image.width ~/ 2) - initSize ~/ 2,
      _rightInit = (x ?? image.width ~/ 2) + initSize ~/ 2,
      _upInit = (y ?? image.height ~/ 2) - initSize ~/ 2,
      _downInit = (y ?? image.height ~/ 2) + initSize ~/ 2;

  static const int _initSize = 10;
  static const int _corr = 1;

  final UBitMatrix image;
  final int _leftInit;
  final int _rightInit;
  final int _upInit;
  final int _downInit;

  List<Offset>? detect() {
    int left = _leftInit;
    int right = _rightInit;
    int up = _upInit;
    int down = _downInit;
    if (up < 0 || left < 0 || down >= image.height || right >= image.width) return null;

    bool sizeExceeded = false;
    bool aBlackPointFoundOnBorder = true;
    bool atLeastOneBlackPointFoundOnRight = false;
    bool atLeastOneBlackPointFoundOnBottom = false;
    bool atLeastOneBlackPointFoundOnLeft = false;
    bool atLeastOneBlackPointFoundOnTop = false;

    while (aBlackPointFoundOnBorder) {
      aBlackPointFoundOnBorder = false;

      bool rightBorderNotWhite = true;
      while ((rightBorderNotWhite || !atLeastOneBlackPointFoundOnRight) && right < image.width) {
        rightBorderNotWhite = _containsBlackPoint(up, down, right, false);
        if (rightBorderNotWhite) {
          right++;
          aBlackPointFoundOnBorder = true;
          atLeastOneBlackPointFoundOnRight = true;
        } else if (!atLeastOneBlackPointFoundOnRight) {
          right++;
        }
      }
      if (right >= image.width) {
        sizeExceeded = true;
        break;
      }

      bool bottomBorderNotWhite = true;
      while ((bottomBorderNotWhite || !atLeastOneBlackPointFoundOnBottom) && down < image.height) {
        bottomBorderNotWhite = _containsBlackPoint(left, right, down, true);
        if (bottomBorderNotWhite) {
          down++;
          aBlackPointFoundOnBorder = true;
          atLeastOneBlackPointFoundOnBottom = true;
        } else if (!atLeastOneBlackPointFoundOnBottom) {
          down++;
        }
      }
      if (down >= image.height) {
        sizeExceeded = true;
        break;
      }

      bool leftBorderNotWhite = true;
      while ((leftBorderNotWhite || !atLeastOneBlackPointFoundOnLeft) && left >= 0) {
        leftBorderNotWhite = _containsBlackPoint(up, down, left, false);
        if (leftBorderNotWhite) {
          left--;
          aBlackPointFoundOnBorder = true;
          atLeastOneBlackPointFoundOnLeft = true;
        } else if (!atLeastOneBlackPointFoundOnLeft) {
          left--;
        }
      }
      if (left < 0) {
        sizeExceeded = true;
        break;
      }

      bool topBorderNotWhite = true;
      while ((topBorderNotWhite || !atLeastOneBlackPointFoundOnTop) && up >= 0) {
        topBorderNotWhite = _containsBlackPoint(left, right, up, true);
        if (topBorderNotWhite) {
          up--;
          aBlackPointFoundOnBorder = true;
          atLeastOneBlackPointFoundOnTop = true;
        } else if (!atLeastOneBlackPointFoundOnTop) {
          up--;
        }
      }
      if (up < 0) {
        sizeExceeded = true;
        break;
      }
    }

    if (sizeExceeded) return null;

    final int maxSize = right - left;
    Offset? z;
    for (int i = 1; z == null && i < maxSize; i++) {
      z = _getBlackPointOnSegment(left.toDouble(), (down - i).toDouble(), (left + i).toDouble(), down.toDouble());
    }
    if (z == null) return null;

    Offset? t;
    for (int i = 1; t == null && i < maxSize; i++) {
      t = _getBlackPointOnSegment(left.toDouble(), (up + i).toDouble(), (left + i).toDouble(), up.toDouble());
    }
    if (t == null) return null;

    Offset? x;
    for (int i = 1; x == null && i < maxSize; i++) {
      x = _getBlackPointOnSegment(right.toDouble(), (up + i).toDouble(), (right - i).toDouble(), up.toDouble());
    }
    if (x == null) return null;

    Offset? y;
    for (int i = 1; y == null && i < maxSize; i++) {
      y = _getBlackPointOnSegment(right.toDouble(), (down - i).toDouble(), (right - i).toDouble(), down.toDouble());
    }
    if (y == null) return null;

    return _centerEdges(y, z, x, t);
  }

  Offset? _getBlackPointOnSegment(double aX, double aY, double bX, double bY) {
    final int dist = _distanceInt(aX, aY, bX, bY);
    if (dist == 0) return null;
    final double xStep = (bX - aX) / dist;
    final double yStep = (bY - aY) / dist;
    for (int i = 0; i < dist; i++) {
      final int x = (aX + i * xStep).round();
      final int y = (aY + i * yStep).round();
      if (image.get(x, y)) return Offset(x.toDouble(), y.toDouble());
    }
    return null;
  }

  static int _distanceInt(double aX, double aY, double bX, double bY) {
    final double dx = aX - bX;
    final double dy = aY - bY;
    return sqrt(dx * dx + dy * dy).round();
  }

  List<Offset> _centerEdges(Offset y, Offset z, Offset x, Offset t) {
    final double yi = y.dx;
    final double zi = z.dx;
    final double xi = x.dx;
    final double ti = t.dx;
    if (yi < image.width / 2.0) {
      return <Offset>[
        Offset(ti - _corr, t.dy + _corr),
        Offset(zi + _corr, z.dy + _corr),
        Offset(xi - _corr, x.dy - _corr),
        Offset(yi + _corr, y.dy - _corr),
      ];
    }
    return <Offset>[
      Offset(ti + _corr, t.dy + _corr),
      Offset(zi + _corr, z.dy - _corr),
      Offset(xi - _corr, x.dy + _corr),
      Offset(yi - _corr, y.dy - _corr),
    ];
  }

  bool _containsBlackPoint(int a, int b, int fixed, bool horizontal) {
    if (horizontal) {
      for (int x = a; x <= b; x++) {
        if (image.get(x, fixed)) return true;
      }
    } else {
      for (int y = a; y <= b; y++) {
        if (image.get(fixed, y)) return true;
      }
    }
    return false;
  }

  static const int initSize = _initSize;
}

class UDataMatrixVersion {
  const UDataMatrixVersion(
    this.versionNumber,
    this.symbolSizeRows,
    this.symbolSizeColumns,
    this.dataRegionSizeRows,
    this.dataRegionSizeColumns,
    this.ecBlocks,
  );

  final int versionNumber;
  final int symbolSizeRows;
  final int symbolSizeColumns;
  final int dataRegionSizeRows;
  final int dataRegionSizeColumns;

  /// [ecCodewords, blockCount, dataCodewords] or two triples for the 144x144 case.
  final List<List<int>> ecBlocks;

  int get totalCodewords {
    int total = 0;
    for (final List<int> block in ecBlocks) {
      total += block[1] * (block[2] + block[0]);
    }
    return total;
  }

  int get totalDataCodewords {
    int total = 0;
    for (final List<int> block in ecBlocks) {
      total += block[1] * block[2];
    }
    return total;
  }

  int get ecCodewordsPerBlock => ecBlocks.first[0];

  static UDataMatrixVersion? forDimensions(int numRows, int numColumns) {
    if ((numRows & 0x01) != 0 || (numColumns & 0x01) != 0) return null;
    for (final UDataMatrixVersion version in versions) {
      if (version.symbolSizeRows == numRows && version.symbolSizeColumns == numColumns) return version;
    }
    return null;
  }

  static const List<UDataMatrixVersion> versions = <UDataMatrixVersion>[
    UDataMatrixVersion(1, 10, 10, 8, 8, <List<int>>[<int>[5, 1, 3]]),
    UDataMatrixVersion(2, 12, 12, 10, 10, <List<int>>[<int>[7, 1, 5]]),
    UDataMatrixVersion(3, 14, 14, 12, 12, <List<int>>[<int>[10, 1, 8]]),
    UDataMatrixVersion(4, 16, 16, 14, 14, <List<int>>[<int>[12, 1, 12]]),
    UDataMatrixVersion(5, 18, 18, 16, 16, <List<int>>[<int>[14, 1, 18]]),
    UDataMatrixVersion(6, 20, 20, 18, 18, <List<int>>[<int>[18, 1, 22]]),
    UDataMatrixVersion(7, 22, 22, 20, 20, <List<int>>[<int>[20, 1, 30]]),
    UDataMatrixVersion(8, 24, 24, 22, 22, <List<int>>[<int>[24, 1, 36]]),
    UDataMatrixVersion(9, 26, 26, 24, 24, <List<int>>[<int>[28, 1, 44]]),
    UDataMatrixVersion(10, 32, 32, 14, 14, <List<int>>[<int>[36, 1, 62]]),
    UDataMatrixVersion(11, 36, 36, 16, 16, <List<int>>[<int>[42, 1, 86]]),
    UDataMatrixVersion(12, 40, 40, 18, 18, <List<int>>[<int>[48, 1, 114]]),
    UDataMatrixVersion(13, 44, 44, 20, 20, <List<int>>[<int>[56, 1, 144]]),
    UDataMatrixVersion(14, 48, 48, 22, 22, <List<int>>[<int>[68, 1, 174]]),
    UDataMatrixVersion(15, 52, 52, 24, 24, <List<int>>[<int>[42, 2, 102]]),
    UDataMatrixVersion(16, 64, 64, 14, 14, <List<int>>[<int>[56, 2, 140]]),
    UDataMatrixVersion(17, 72, 72, 16, 16, <List<int>>[<int>[36, 4, 92]]),
    UDataMatrixVersion(18, 80, 80, 18, 18, <List<int>>[<int>[48, 4, 114]]),
    UDataMatrixVersion(19, 88, 88, 20, 20, <List<int>>[<int>[56, 4, 144]]),
    UDataMatrixVersion(20, 96, 96, 22, 22, <List<int>>[<int>[68, 4, 174]]),
    UDataMatrixVersion(21, 104, 104, 24, 24, <List<int>>[<int>[56, 6, 136]]),
    UDataMatrixVersion(22, 120, 120, 18, 18, <List<int>>[<int>[68, 6, 175]]),
    UDataMatrixVersion(23, 132, 132, 20, 20, <List<int>>[<int>[62, 8, 163]]),
    UDataMatrixVersion(24, 144, 144, 22, 22, <List<int>>[<int>[62, 8, 156], <int>[62, 2, 155]]),
    UDataMatrixVersion(25, 8, 18, 6, 16, <List<int>>[<int>[7, 1, 5]]),
    UDataMatrixVersion(26, 8, 32, 6, 14, <List<int>>[<int>[11, 1, 10]]),
    UDataMatrixVersion(27, 12, 26, 10, 24, <List<int>>[<int>[14, 1, 16]]),
    UDataMatrixVersion(28, 12, 36, 10, 16, <List<int>>[<int>[18, 1, 22]]),
    UDataMatrixVersion(29, 16, 36, 14, 16, <List<int>>[<int>[24, 1, 32]]),
    UDataMatrixVersion(30, 16, 48, 14, 22, <List<int>>[<int>[28, 1, 49]]),
  ];
}

/// Strips the alignment patterns and reads the codewords of a sampled symbol.
class UDataMatrixBitMatrixParser {
  UDataMatrixBitMatrixParser(UBitMatrix bitMatrix) {
    final int dimension = bitMatrix.height;
    if (dimension < 8 || dimension > 144 || (dimension & 0x01) != 0) throw const UCodeDecodeException("Bad Data Matrix dimension");
    final UDataMatrixVersion? version = UDataMatrixVersion.forDimensions(bitMatrix.height, bitMatrix.width);
    if (version == null) throw const UCodeDecodeException("Unknown Data Matrix version");
    _version = version;
    _mappingBitMatrix = _extractDataRegion(bitMatrix);
    _readMappingMatrix = UBitMatrix(_mappingBitMatrix.width, _mappingBitMatrix.height);
  }

  late final UDataMatrixVersion _version;
  late final UBitMatrix _mappingBitMatrix;
  late final UBitMatrix _readMappingMatrix;

  UDataMatrixVersion get version => _version;

  UBitMatrix _extractDataRegion(UBitMatrix bitMatrix) {
    final int symbolSizeRows = _version.symbolSizeRows;
    final int symbolSizeColumns = _version.symbolSizeColumns;
    final int dataRegionSizeRows = _version.dataRegionSizeRows;
    final int dataRegionSizeColumns = _version.dataRegionSizeColumns;
    final int numDataRegionsRow = symbolSizeRows ~/ (dataRegionSizeRows + 2);
    final int numDataRegionsColumn = symbolSizeColumns ~/ (dataRegionSizeColumns + 2);
    final int sizeDataRegionRow = numDataRegionsRow * dataRegionSizeRows;
    final int sizeDataRegionColumn = numDataRegionsColumn * dataRegionSizeColumns;

    final UBitMatrix bitMatrixWithoutAlignment = UBitMatrix(sizeDataRegionColumn, sizeDataRegionRow);
    for (int dataRegionRow = 0; dataRegionRow < numDataRegionsRow; dataRegionRow++) {
      final int dataRegionRowOffset = dataRegionRow * dataRegionSizeRows;
      for (int dataRegionColumn = 0; dataRegionColumn < numDataRegionsColumn; dataRegionColumn++) {
        final int dataRegionColumnOffset = dataRegionColumn * dataRegionSizeColumns;
        for (int i = 0; i < dataRegionSizeRows; i++) {
          final int readRowOffset = dataRegionRow * (dataRegionSizeRows + 2) + 1 + i;
          final int writeRowOffset = dataRegionRowOffset + i;
          for (int j = 0; j < dataRegionSizeColumns; j++) {
            final int readColumnOffset = dataRegionColumn * (dataRegionSizeColumns + 2) + 1 + j;
            if (!bitMatrix.get(readColumnOffset, readRowOffset)) continue;
            bitMatrixWithoutAlignment.set(dataRegionColumnOffset + j, writeRowOffset);
          }
        }
      }
    }
    return bitMatrixWithoutAlignment;
  }

  Uint8List readCodewords() {
    final Uint8List result = Uint8List(_version.totalCodewords);
    int resultOffset = 0;
    int row = 4;
    int column = 0;
    final int numRows = _mappingBitMatrix.height;
    final int numColumns = _mappingBitMatrix.width;
    bool corner1Read = false;
    bool corner2Read = false;
    bool corner3Read = false;
    bool corner4Read = false;

    do {
      if (row == numRows && column == 0 && !corner1Read) {
        result[resultOffset++] = _readCorner1(numRows, numColumns);
        row -= 2;
        column += 2;
        corner1Read = true;
      } else if (row == numRows - 2 && column == 0 && (numColumns & 0x03) != 0 && !corner2Read) {
        result[resultOffset++] = _readCorner2(numRows, numColumns);
        row -= 2;
        column += 2;
        corner2Read = true;
      } else if (row == numRows + 4 && column == 2 && (numColumns & 0x07) == 0 && !corner3Read) {
        result[resultOffset++] = _readCorner3(numRows, numColumns);
        row -= 2;
        column += 2;
        corner3Read = true;
      } else if (row == numRows - 2 && column == 0 && (numColumns & 0x07) == 4 && !corner4Read) {
        result[resultOffset++] = _readCorner4(numRows, numColumns);
        row -= 2;
        column += 2;
        corner4Read = true;
      } else {
        do {
          if (row < numRows && column >= 0 && !_readMappingMatrix.get(column, row)) {
            result[resultOffset++] = _readUtah(row, column, numRows, numColumns);
          }
          row -= 2;
          column += 2;
        } while (row >= 0 && column < numColumns);
        row += 1;
        column += 3;

        do {
          if (row >= 0 && column < numColumns && !_readMappingMatrix.get(column, row)) {
            result[resultOffset++] = _readUtah(row, column, numRows, numColumns);
          }
          row += 2;
          column -= 2;
        } while (row < numRows && column >= 0);
        row += 3;
        column += 1;
      }
    } while (row < numRows || column < numColumns);

    if (resultOffset != _version.totalCodewords) throw const UCodeDecodeException("Data Matrix codeword count mismatch");
    return result;
  }

  bool _readModule(int row, int column, int numRows, int numColumns) {
    int r = row;
    int c = column;
    if (r < 0) {
      r += numRows;
      c += 4 - ((numRows + 4) & 0x07);
    }
    if (c < 0) {
      c += numColumns;
      r += 4 - ((numColumns + 4) & 0x07);
    }
    if (r >= numRows) r -= numRows;
    _readMappingMatrix.set(c, r);
    return _mappingBitMatrix.get(c, r);
  }

  int _readUtah(int row, int column, int numRows, int numColumns) {
    int currentByte = 0;
    const List<List<int>> offsets = <List<int>>[
      <int>[-2, -2], <int>[-2, -1], <int>[-1, -2], <int>[-1, -1],
      <int>[-1, 0], <int>[0, -2], <int>[0, -1], <int>[0, 0],
    ];
    for (final List<int> offset in offsets) {
      currentByte <<= 1;
      if (_readModule(row + offset[0], column + offset[1], numRows, numColumns)) currentByte |= 1;
    }
    return currentByte;
  }

  int _readCorner1(int numRows, int numColumns) {
    int currentByte = 0;
    const List<List<int>> coordinates = <List<int>>[
      <int>[0, 0], <int>[0, 1], <int>[0, 2], <int>[1, 0], <int>[2, 0], <int>[3, 0], <int>[4, 0],
    ];
    currentByte = _shiftIn(currentByte, numRows - 1, 0, numRows, numColumns);
    currentByte = _shiftIn(currentByte, numRows - 1, 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, numRows - 1, 2, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 2, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 1, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 2, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 3, numColumns - 1, numRows, numColumns);
    return coordinates.isEmpty ? 0 : currentByte;
  }

  int _readCorner2(int numRows, int numColumns) {
    int currentByte = 0;
    currentByte = _shiftIn(currentByte, numRows - 3, 0, numRows, numColumns);
    currentByte = _shiftIn(currentByte, numRows - 2, 0, numRows, numColumns);
    currentByte = _shiftIn(currentByte, numRows - 1, 0, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 4, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 3, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 2, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 1, numColumns - 1, numRows, numColumns);
    return currentByte;
  }

  int _readCorner3(int numRows, int numColumns) {
    int currentByte = 0;
    currentByte = _shiftIn(currentByte, numRows - 1, 0, numRows, numColumns);
    currentByte = _shiftIn(currentByte, numRows - 1, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 3, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 2, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 1, numColumns - 3, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 1, numColumns - 2, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 1, numColumns - 1, numRows, numColumns);
    return currentByte;
  }

  int _readCorner4(int numRows, int numColumns) {
    int currentByte = 0;
    currentByte = _shiftIn(currentByte, numRows - 3, 0, numRows, numColumns);
    currentByte = _shiftIn(currentByte, numRows - 2, 0, numRows, numColumns);
    currentByte = _shiftIn(currentByte, numRows - 1, 0, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 2, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 0, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 1, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 2, numColumns - 1, numRows, numColumns);
    currentByte = _shiftIn(currentByte, 3, numColumns - 1, numRows, numColumns);
    return currentByte;
  }

  int _shiftIn(int currentByte, int row, int column, int numRows, int numColumns) {
    final int shifted = currentByte << 1;
    _readMappingMatrix.set(column, row);
    return _mappingBitMatrix.get(column, row) ? shifted | 1 : shifted;
  }
}

abstract class UDataMatrixDecodedBitStream {
  static const int _padEncode = 0;
  static const int _asciiEncode = 1;
  static const int _c40Encode = 2;
  static const int _textEncode = 3;
  static const int _ansiX12Encode = 4;
  static const int _edifactEncode = 5;
  static const int _base256Encode = 6;
  static const int _eciEncode = 7;

  static const String _c40Basic = "*** 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  static const String _c40Shift2 = "!" '"' r"#$%&'()*+,-./:;<=>?@[\]^_";
  static const String _textBasic = "*** 0123456789abcdefghijklmnopqrstuvwxyz";
  static const String _textShift3 = "`abcdefghijklmnopqrstuvwxyz{|}~";

  static UQrDecodeResult decode(Uint8List bytes) {
    final UBitSource bits = UBitSource(bytes);
    final StringBuffer result = StringBuffer();
    final StringBuffer resultTrailer = StringBuffer();
    final List<int> byteSegments = <int>[];
    int mode = _asciiEncode;
    int? eci;

    do {
      if (mode == _asciiEncode) {
        mode = _decodeAscii(bits, result, resultTrailer);
      } else {
        switch (mode) {
          case _c40Encode:
            _decodeC40(bits, result);
            break;
          case _textEncode:
            _decodeText(bits, result);
            break;
          case _ansiX12Encode:
            _decodeAnsiX12(bits, result);
            break;
          case _edifactEncode:
            _decodeEdifact(bits, result);
            break;
          case _base256Encode:
            eci = _decodeBase256(bits, result, byteSegments) ?? eci;
            break;
          case _eciEncode:
            eci = _decodeEci(bits);
            break;
          default:
            throw const UCodeDecodeException("Unsupported Data Matrix mode");
        }
        mode = _asciiEncode;
      }
    } while (mode != _padEncode && bits.available > 0);

    if (resultTrailer.isNotEmpty) result.write(resultTrailer);
    final String text = result.toString();
    return UQrDecodeResult(text: text, bytes: byteSegments.isNotEmpty ? Uint8List.fromList(byteSegments) : Uint8List.fromList(utf8.encode(text)), eci: eci);
  }

  static int _decodeAscii(UBitSource bits, StringBuffer result, StringBuffer resultTrailer) {
    bool upperShift = false;
    do {
      final int oneByte = bits.readBits(8);
      if (oneByte == 0) {
        throw const UCodeDecodeException("Zero Data Matrix codeword");
      } else if (oneByte <= 128) {
        final int value = upperShift ? oneByte + 128 : oneByte;
        upperShift = false;
        result.writeCharCode(value - 1);
        return _asciiEncode;
      } else if (oneByte == 129) {
        return _padEncode;
      } else if (oneByte <= 229) {
        final int value = oneByte - 130;
        if (value < 10) result.write("0");
        result.write(value);
      } else {
        switch (oneByte) {
          case 230:
            return _c40Encode;
          case 231:
            return _base256Encode;
          case 232:
            result.writeCharCode(29);
            break;
          case 233:
          case 234:
            break;
          case 235:
            upperShift = true;
            break;
          case 236:
            result.write("[)>05");
            resultTrailer.write("");
            break;
          case 237:
            result.write("[)>06");
            resultTrailer.write("");
            break;
          case 238:
            return _ansiX12Encode;
          case 239:
            return _textEncode;
          case 240:
            return _edifactEncode;
          case 241:
            return _eciEncode;
          default:
            if (oneByte != 254 && bits.available != 0) throw const UCodeDecodeException("Bad ASCII codeword");
            break;
        }
      }
    } while (bits.available > 0);
    return _asciiEncode;
  }

  static void _decodeC40(UBitSource bits, StringBuffer result) {
    bool upperShift = false;
    final List<int> cValues = <int>[0, 0, 0];
    int shift = 0;

    while (bits.available >= 16) {
      final int firstByte = bits.readBits(8);
      if (firstByte == 254) return;
      _parseTwoBytes(firstByte, bits.readBits(8), cValues);
      for (int i = 0; i < 3; i++) {
        final int cValue = cValues[i];
        switch (shift) {
          case 0:
            if (cValue < 3) {
              shift = cValue + 1;
            } else if (cValue < _c40Basic.length) {
              final String c40char = _c40Basic[cValue];
              if (upperShift) {
                result.writeCharCode(c40char.codeUnitAt(0) + 128);
                upperShift = false;
              } else {
                result.write(c40char);
              }
            } else {
              throw const UCodeDecodeException("Bad C40 value");
            }
            break;
          case 1:
            if (upperShift) {
              result.writeCharCode(cValue + 128);
              upperShift = false;
            } else {
              result.writeCharCode(cValue);
            }
            shift = 0;
            break;
          case 2:
            if (cValue < _c40Shift2.length) {
              final String c40char = _c40Shift2[cValue];
              if (upperShift) {
                result.writeCharCode(c40char.codeUnitAt(0) + 128);
                upperShift = false;
              } else {
                result.write(c40char);
              }
            } else if (cValue == 27) {
              result.writeCharCode(29);
            } else if (cValue == 30) {
              upperShift = true;
            } else {
              throw const UCodeDecodeException("Bad C40 shift 2 value");
            }
            shift = 0;
            break;
          case 3:
            if (upperShift) {
              result.writeCharCode(cValue + 224);
              upperShift = false;
            } else {
              result.writeCharCode(cValue + 96);
            }
            shift = 0;
            break;
          default:
            throw const UCodeDecodeException("Bad C40 shift");
        }
      }
      if (bits.available <= 0) break;
    }
  }

  static void _decodeText(UBitSource bits, StringBuffer result) {
    bool upperShift = false;
    final List<int> cValues = <int>[0, 0, 0];
    int shift = 0;

    while (bits.available >= 16) {
      final int firstByte = bits.readBits(8);
      if (firstByte == 254) return;
      _parseTwoBytes(firstByte, bits.readBits(8), cValues);
      for (int i = 0; i < 3; i++) {
        final int cValue = cValues[i];
        switch (shift) {
          case 0:
            if (cValue < 3) {
              shift = cValue + 1;
            } else if (cValue < _textBasic.length) {
              final String textChar = _textBasic[cValue];
              if (upperShift) {
                result.writeCharCode(textChar.codeUnitAt(0) + 128);
                upperShift = false;
              } else {
                result.write(textChar);
              }
            } else {
              throw const UCodeDecodeException("Bad text value");
            }
            break;
          case 1:
            if (upperShift) {
              result.writeCharCode(cValue + 128);
              upperShift = false;
            } else {
              result.writeCharCode(cValue);
            }
            shift = 0;
            break;
          case 2:
            if (cValue < _c40Shift2.length) {
              final String textChar = _c40Shift2[cValue];
              if (upperShift) {
                result.writeCharCode(textChar.codeUnitAt(0) + 128);
                upperShift = false;
              } else {
                result.write(textChar);
              }
            } else if (cValue == 27) {
              result.writeCharCode(29);
            } else if (cValue == 30) {
              upperShift = true;
            } else {
              throw const UCodeDecodeException("Bad text shift 2 value");
            }
            shift = 0;
            break;
          case 3:
            if (cValue < _textShift3.length) {
              final String textChar = _textShift3[cValue];
              if (upperShift) {
                result.writeCharCode(textChar.codeUnitAt(0) + 128);
                upperShift = false;
              } else {
                result.write(textChar);
              }
              shift = 0;
            } else {
              throw const UCodeDecodeException("Bad text shift 3 value");
            }
            break;
          default:
            throw const UCodeDecodeException("Bad text shift");
        }
      }
      if (bits.available <= 0) break;
    }
  }

  static void _decodeAnsiX12(UBitSource bits, StringBuffer result) {
    final List<int> cValues = <int>[0, 0, 0];
    while (bits.available >= 16) {
      final int firstByte = bits.readBits(8);
      if (firstByte == 254) return;
      _parseTwoBytes(firstByte, bits.readBits(8), cValues);
      for (int i = 0; i < 3; i++) {
        final int cValue = cValues[i];
        if (cValue == 0) {
          result.write("\r");
        } else if (cValue == 1) {
          result.write("*");
        } else if (cValue == 2) {
          result.write(">");
        } else if (cValue == 3) {
          result.write(" ");
        } else if (cValue < 14) {
          result.writeCharCode(cValue + 44);
        } else if (cValue < 40) {
          result.writeCharCode(cValue + 51);
        } else {
          throw const UCodeDecodeException("Bad X12 value");
        }
      }
      if (bits.available <= 0) break;
    }
  }

  static void _parseTwoBytes(int firstByte, int secondByte, List<int> result) {
    int fullBitValue = (firstByte << 8) + secondByte - 1;
    int temp = fullBitValue ~/ 1600;
    result[0] = temp;
    fullBitValue -= temp * 1600;
    temp = fullBitValue ~/ 40;
    result[1] = temp;
    result[2] = fullBitValue - temp * 40;
  }

  static void _decodeEdifact(UBitSource bits, StringBuffer result) {
    while (bits.available > 16) {
      for (int i = 0; i < 4; i++) {
        int edifactValue = bits.readBits(6);
        if (edifactValue == 0x1F) return;
        if ((edifactValue & 0x20) == 0) edifactValue |= 0x40;
        result.writeCharCode(edifactValue);
      }
      if (bits.available <= 0) break;
    }
  }

  static int? _decodeBase256(UBitSource bits, StringBuffer result, List<int> byteSegments) {
    int codewordPosition = 1 + bits.byteOffset;
    final int d1 = _unrandomize255State(bits.readBits(8), codewordPosition++);
    int count;
    if (d1 == 0) {
      count = bits.available ~/ 8;
    } else if (d1 < 250) {
      count = d1;
    } else {
      count = 250 * (d1 - 249) + _unrandomize255State(bits.readBits(8), codewordPosition++);
    }
    if (count < 0) throw const UCodeDecodeException("Bad base 256 length");

    final Uint8List bytes = Uint8List(count);
    for (int i = 0; i < count; i++) {
      if (bits.available < 8) throw const UCodeDecodeException("Truncated base 256 segment");
      bytes[i] = _unrandomize255State(bits.readBits(8), codewordPosition++);
    }
    byteSegments.addAll(bytes);
    result.write(String.fromCharCodes(bytes));
    return null;
  }

  static int _decodeEci(UBitSource bits) {
    if (bits.available < 8) throw const UCodeDecodeException("Truncated ECI");
    final int c1 = bits.readBits(8);
    if (c1 <= 127) return c1 - 1;
    return 0;
  }

  static int _unrandomize255State(int randomizedBase256Codeword, int base256CodewordPosition) {
    final int pseudoRandomNumber = ((149 * base256CodewordPosition) % 255) + 1;
    final int tempVariable = randomizedBase256Codeword - pseudoRandomNumber;
    return tempVariable >= 0 ? tempVariable : tempVariable + 256;
  }
}

abstract class UDataMatrixScanner {
  static List<UCode> scan(UBitMatrix matrix, UCodeScanOptions options) {
    try {
      final List<Offset>? corners = UWhiteRectangleDetector(matrix).detect();
      if (corners == null) return const <UCode>[];
      final _UDataMatrixShape? shape = _detectShape(matrix, corners);
      if (shape == null) return const <UCode>[];
      final UCode code = _decodeMatrix(shape.bits, shape.points);
      return <UCode>[code];
    } catch (_) {
      return const <UCode>[];
    }
  }

  static UCode _decodeMatrix(UBitMatrix bits, List<Offset> points) {
    final UDataMatrixBitMatrixParser parser = UDataMatrixBitMatrixParser(bits);
    final UDataMatrixVersion version = parser.version;
    final Uint8List codewords = parser.readCodewords();

    final List<List<int>> ecBlocks = version.ecBlocks;
    int totalBlocks = 0;
    for (final List<int> block in ecBlocks) {
      totalBlocks += block[1];
    }
    final List<int> dataSizes = <int>[];
    final List<int> ecSizes = <int>[];
    for (final List<int> block in ecBlocks) {
      for (int i = 0; i < block[1]; i++) {
        dataSizes.add(block[2]);
        ecSizes.add(block[0]);
      }
    }

    final List<Uint8List> blocks = <Uint8List>[];
    for (int i = 0; i < totalBlocks; i++) {
      blocks.add(Uint8List(dataSizes[i] + ecSizes[i]));
    }

    final int longerBlocksTotalCodewords = blocks.first.length;
    for (int i = 0; i < longerBlocksTotalCodewords; i++) {
      for (int j = 0; j < totalBlocks; j++) {
        if (i >= blocks[j].length) continue;
        final int rawIndex = i * totalBlocks + j;
        if (rawIndex >= codewords.length) continue;
        blocks[j][i] = codewords[rawIndex];
      }
    }

    final List<int> decoded = <int>[];
    for (int j = 0; j < totalBlocks; j++) {
      final Int32List block = Int32List(blocks[j].length);
      for (int i = 0; i < blocks[j].length; i++) {
        block[i] = blocks[j][i];
      }
      UReedSolomon.decode(UGaloisField.dataMatrix, block, ecSizes[j]);
      for (int i = 0; i < dataSizes[j]; i++) {
        decoded.add(block[i] & 0xFF);
      }
    }

    final UQrDecodeResult result = UDataMatrixDecodedBitStream.decode(Uint8List.fromList(decoded));
    return UCode(format: UCodeFormat.dataMatrix, text: result.text, bytes: result.bytes, corners: points, eci: result.eci, version: version.versionNumber);
  }

  static _UDataMatrixShape? _detectShape(UBitMatrix image, List<Offset> cornerPoints) {
    final Offset pointA = cornerPoints[0];
    final Offset pointB = cornerPoints[1];
    final Offset pointC = cornerPoints[2];
    final Offset pointD = cornerPoints[3];

    final List<_UTransitionCount> transitions = <_UTransitionCount>[
      _transitionsBetween(image, pointA, pointB),
      _transitionsBetween(image, pointA, pointC),
      _transitionsBetween(image, pointB, pointD),
      _transitionsBetween(image, pointC, pointD),
    ]..sort((_UTransitionCount a, _UTransitionCount b) => a.transitions.compareTo(b.transitions));

    final _UTransitionCount lSideOne = transitions[0];
    final _UTransitionCount lSideTwo = transitions[1];

    final Map<Offset, int> pointCount = <Offset, int>{};
    _increment(pointCount, lSideOne.from);
    _increment(pointCount, lSideOne.to);
    _increment(pointCount, lSideTwo.from);
    _increment(pointCount, lSideTwo.to);

    Offset? maybeTopLeft;
    Offset? bottomLeft;
    Offset? maybeBottomRight;
    pointCount.forEach((Offset point, int count) {
      if (count == 2) {
        bottomLeft = point;
      } else if (maybeTopLeft == null) {
        maybeTopLeft = point;
      } else {
        maybeBottomRight = point;
      }
    });
    final Offset? topLeftCandidate = maybeTopLeft;
    final Offset? bottomLeftPoint = bottomLeft;
    final Offset? bottomRightCandidate = maybeBottomRight;
    if (topLeftCandidate == null || bottomLeftPoint == null || bottomRightCandidate == null) return null;

    final List<Offset> corners = <Offset>[topLeftCandidate, bottomLeftPoint, bottomRightCandidate];
    _orderByBestPatterns(corners);
    final Offset bottomRight = corners[0];
    final Offset bottomLeftOrdered = corners[1];
    final Offset topLeft = corners[2];

    final Offset topRight = pointCount.containsKey(pointA)
        ? (pointCount.containsKey(pointB) ? (pointCount.containsKey(pointC) ? pointD : pointC) : pointB)
        : pointA;

    int dimensionTop = _transitionsBetween(image, topLeft, topRight).transitions + 1;
    int dimensionRight = _transitionsBetween(image, bottomRight, topRight).transitions + 1;
    if ((dimensionTop & 0x01) == 1) dimensionTop++;
    if ((dimensionRight & 0x01) == 1) dimensionRight++;

    if (4 * dimensionTop < 6 * dimensionRight && 4 * dimensionRight < 6 * dimensionTop) {
      final int dimension = max(dimensionTop, dimensionRight);
      dimensionTop = dimension;
      dimensionRight = dimension;
    }
    if (dimensionTop < 8 || dimensionRight < 8 || dimensionTop > 144 || dimensionRight > 144) return null;

    final Offset correctedTopRight = Offset(
      topRight.dx,
      topRight.dy,
    );
    final UPerspectiveTransform transform = UPerspectiveTransform.quadrilateralToQuadrilateral(
      0.5,
      0.5,
      dimensionTop - 0.5,
      0.5,
      dimensionTop - 0.5,
      dimensionRight - 0.5,
      0.5,
      dimensionRight - 0.5,
      topLeft.dx,
      topLeft.dy,
      correctedTopRight.dx,
      correctedTopRight.dy,
      bottomRight.dx,
      bottomRight.dy,
      bottomLeftOrdered.dx,
      bottomLeftOrdered.dy,
    );
    final UBitMatrix bits = UGridSampler.sample(image, dimensionTop, dimensionRight, transform);
    return _UDataMatrixShape(bits, <Offset>[topLeft, correctedTopRight, bottomRight, bottomLeftOrdered]);
  }

  static void _increment(Map<Offset, int> table, Offset key) => table[key] = (table[key] ?? 0) + 1;

  static void _orderByBestPatterns(List<Offset> patterns) {
    final double zeroOneDistance = _distance(patterns[0], patterns[1]);
    final double oneTwoDistance = _distance(patterns[1], patterns[2]);
    final double zeroTwoDistance = _distance(patterns[0], patterns[2]);

    Offset pointA;
    Offset pointB;
    Offset pointC;
    if (oneTwoDistance >= zeroOneDistance && oneTwoDistance >= zeroTwoDistance) {
      pointB = patterns[0];
      pointA = patterns[1];
      pointC = patterns[2];
    } else if (zeroTwoDistance >= oneTwoDistance && zeroTwoDistance >= zeroOneDistance) {
      pointB = patterns[1];
      pointA = patterns[0];
      pointC = patterns[2];
    } else {
      pointB = patterns[2];
      pointA = patterns[0];
      pointC = patterns[1];
    }
    if (_crossProductZ(pointA, pointB, pointC) < 0.0) {
      final Offset temp = pointA;
      pointA = pointC;
      pointC = temp;
    }
    patterns[0] = pointA;
    patterns[1] = pointB;
    patterns[2] = pointC;
  }

  static double _distance(Offset a, Offset b) {
    final double dx = a.dx - b.dx;
    final double dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
  }

  static double _crossProductZ(Offset a, Offset b, Offset c) => ((c.dx - b.dx) * (a.dy - b.dy)) - ((c.dy - b.dy) * (a.dx - b.dx));

  static _UTransitionCount _transitionsBetween(UBitMatrix image, Offset from, Offset to) {
    int fromX = from.dx.toInt();
    int fromY = from.dy.toInt();
    int toX = to.dx.toInt();
    int toY = min(image.height - 1, to.dy.toInt());

    final bool steep = (toY - fromY).abs() > (toX - fromX).abs();
    if (steep) {
      int temp = fromX;
      fromX = fromY;
      fromY = temp;
      temp = toX;
      toX = toY;
      toY = temp;
    }

    final int dx = (toX - fromX).abs();
    final int dy = (toY - fromY).abs();
    int error = -dx ~/ 2;
    final int yStep = fromY < toY ? 1 : -1;
    final int xStep = fromX < toX ? 1 : -1;
    int transitions = 0;
    bool inBlack = image.get(steep ? fromY : fromX, steep ? fromX : fromY);

    int y = fromY;
    for (int x = fromX; x != toX; x += xStep) {
      final bool isBlack = image.get(steep ? y : x, steep ? x : y);
      if (isBlack != inBlack) {
        transitions++;
        inBlack = isBlack;
      }
      error += dy;
      if (error > 0) {
        if (y == toY) break;
        y += yStep;
        error -= dx;
      }
    }
    return _UTransitionCount(from, to, transitions);
  }
}

class _UTransitionCount {
  const _UTransitionCount(this.from, this.to, this.transitions);

  final Offset from;
  final Offset to;
  final int transitions;
}

class _UDataMatrixShape {
  const _UDataMatrixShape(this.bits, this.points);

  final UBitMatrix bits;
  final List<Offset> points;
}

// =============================================================================
// Aztec
// =============================================================================

class UAztecDetectorResult {
  const UAztecDetectorResult(this.bits, this.points, this.compact, this.nbDatablocks, this.nbLayers);

  final UBitMatrix bits;
  final List<Offset> points;
  final bool compact;
  final int nbDatablocks;
  final int nbLayers;
}

class UAztecDetector {
  UAztecDetector(this.image);

  final UBitMatrix image;
  bool _compact = false;
  int _nbLayers = 0;
  int _nbDataBlocks = 0;
  int _nbCenterLayers = 0;
  int _shift = 0;

  static const List<int> _expectedCorner = <int>[0xEE0, 0x1DC, 0x83B, 0x707];

  UAztecDetectorResult? detect() {
    final Offset? center = _getMatrixCenter();
    if (center == null) return null;
    final List<Offset>? bullsEyeCorners = _getBullsEyeCorners(center);
    if (bullsEyeCorners == null) return null;
    if (!_extractParameters(bullsEyeCorners)) return null;

    final int dimension = _getDimension();
    final int lowOffset = (_nbCenterLayers * 2) - (_compact ? 5 : 7);
    final List<Offset> corners = _expandSquare(bullsEyeCorners, 2 * _nbCenterLayers, dimension);
    final UBitMatrix? bits = _sampleGrid(corners[_shift % 4], corners[(_shift + 1) % 4], corners[(_shift + 2) % 4], corners[(_shift + 3) % 4], dimension);
    if (bits == null || lowOffset < -1000) return null;
    return UAztecDetectorResult(bits, corners, _compact, _nbDataBlocks, _nbLayers);
  }

  bool _extractParameters(List<Offset> bullsEyeCorners) {
    if (!_isValidPoint(bullsEyeCorners[0]) || !_isValidPoint(bullsEyeCorners[1]) || !_isValidPoint(bullsEyeCorners[2]) || !_isValidPoint(bullsEyeCorners[3])) {
      return false;
    }
    final int length = 2 * _nbCenterLayers;
    final List<int> sides = <int>[
      _sampleLine(bullsEyeCorners[0], bullsEyeCorners[1], length),
      _sampleLine(bullsEyeCorners[1], bullsEyeCorners[2], length),
      _sampleLine(bullsEyeCorners[2], bullsEyeCorners[3], length),
      _sampleLine(bullsEyeCorners[3], bullsEyeCorners[0], length),
    ];

    _shift = _getRotation(sides, length);
    if (_shift < 0) return false;

    int parameterData = 0;
    for (int i = 0; i < 4; i++) {
      final int side = sides[(_shift + i) % 4];
      if (_compact) {
        parameterData <<= 7;
        parameterData += (side >> 1) & 0x7F;
      } else {
        parameterData <<= 10;
        parameterData += ((side >> 2) & (0x1F << 5)) + ((side >> 1) & 0x1F);
      }
    }

    final int correctedData = _getCorrectedParameterData(parameterData, _compact);
    if (correctedData < 0) return false;
    if (_compact) {
      _nbLayers = (correctedData >> 6) + 1;
      _nbDataBlocks = (correctedData & 0x3F) + 1;
    } else {
      _nbLayers = (correctedData >> 11) + 1;
      _nbDataBlocks = (correctedData & 0x7FF) + 1;
    }
    return true;
  }

  static int _getRotation(List<int> sides, int length) {
    int cornerBits = 0;
    for (final int side in sides) {
      final int t = ((side >> (length - 2)) << 1) + (side & 0x01);
      cornerBits = (cornerBits << 3) + t;
    }
    cornerBits = ((cornerBits & 1) << 11) + (cornerBits >> 1);
    for (int shift = 0; shift < 4; shift++) {
      if (_bitCount(cornerBits ^ _expectedCorner[shift]) <= 2) return shift;
    }
    return -1;
  }

  static int _bitCount(int value) {
    int v = value;
    int count = 0;
    while (v != 0) {
      count += v & 1;
      v >>= 1;
    }
    return count;
  }

  static int _getCorrectedParameterData(int parameterData, bool compact) {
    final int numCodewords = compact ? 7 : 10;
    final int numDataCodewords = compact ? 2 : 4;
    final int numEcCodewords = numCodewords - numDataCodewords;
    final Int32List parameterWords = Int32List(numCodewords);
    int data = parameterData;
    for (int i = numCodewords - 1; i >= 0; i--) {
      parameterWords[i] = data & 0x0F;
      data >>= 4;
    }
    try {
      UReedSolomon.decode(UGaloisField.aztecParam, parameterWords, numEcCodewords);
    } catch (_) {
      return -1;
    }
    int result = 0;
    for (int i = 0; i < numDataCodewords; i++) {
      result = (result << 4) + parameterWords[i];
    }
    return result;
  }

  List<Offset>? _getBullsEyeCorners(Offset pCenter) {
    Offset pina = pCenter;
    Offset pinb = pCenter;
    Offset pinc = pCenter;
    Offset pind = pCenter;
    bool color = true;

    for (_nbCenterLayers = 1; _nbCenterLayers < 9; _nbCenterLayers++) {
      final Offset pouta = _getFirstDifferent(pina, color, 1, -1);
      final Offset poutb = _getFirstDifferent(pinb, color, 1, 1);
      final Offset poutc = _getFirstDifferent(pinc, color, -1, 1);
      final Offset poutd = _getFirstDifferent(pind, color, -1, -1);

      if (_nbCenterLayers > 2) {
        final double q = _distance(poutd, pouta) * _nbCenterLayers / (_distance(pind, pina) * (_nbCenterLayers + 2));
        if (q < 0.75 || q > 1.25 || !_isWhiteOrBlackRectangle(pouta, poutb, poutc, poutd)) break;
      }
      pina = pouta;
      pinb = poutb;
      pinc = poutc;
      pind = poutd;
      color = !color;
    }

    if (_nbCenterLayers != 5 && _nbCenterLayers != 7) return null;
    _compact = _nbCenterLayers == 5;

    final Offset pinax = Offset(pina.dx + 0.5, pina.dy - 0.5);
    final Offset pinbx = Offset(pinb.dx + 0.5, pinb.dy + 0.5);
    final Offset pincx = Offset(pinc.dx - 0.5, pinc.dy + 0.5);
    final Offset pindx = Offset(pind.dx - 0.5, pind.dy - 0.5);
    return _expandSquare(<Offset>[pinax, pinbx, pincx, pindx], 2 * _nbCenterLayers - 3, 2 * _nbCenterLayers);
  }

  Offset? _getMatrixCenter() {
    List<Offset>? cornerPoints = UWhiteRectangleDetector(image).detect();
    Offset pointA;
    Offset pointB;
    Offset pointC;
    Offset pointD;
    if (cornerPoints != null) {
      pointA = cornerPoints[0];
      pointB = cornerPoints[1];
      pointC = cornerPoints[2];
      pointD = cornerPoints[3];
    } else {
      final int cx = image.width ~/ 2;
      final int cy = image.height ~/ 2;
      pointA = _getFirstDifferent(Offset((cx + 7).toDouble(), (cy - 7).toDouble()), false, 1, -1);
      pointB = _getFirstDifferent(Offset((cx + 7).toDouble(), (cy + 7).toDouble()), false, 1, 1);
      pointC = _getFirstDifferent(Offset((cx - 7).toDouble(), (cy + 7).toDouble()), false, -1, 1);
      pointD = _getFirstDifferent(Offset((cx - 7).toDouble(), (cy - 7).toDouble()), false, -1, -1);
    }

    int cx = ((pointA.dx + pointD.dx + pointB.dx + pointC.dx) / 4).round();
    int cy = ((pointA.dy + pointD.dy + pointB.dy + pointC.dy) / 4).round();

    cornerPoints = UWhiteRectangleDetector(image, initSize: 15, x: cx, y: cy).detect();
    if (cornerPoints != null) {
      pointA = cornerPoints[0];
      pointB = cornerPoints[1];
      pointC = cornerPoints[2];
      pointD = cornerPoints[3];
    } else {
      pointA = _getFirstDifferent(Offset((cx + 7).toDouble(), (cy - 7).toDouble()), false, 1, -1);
      pointB = _getFirstDifferent(Offset((cx + 7).toDouble(), (cy + 7).toDouble()), false, 1, 1);
      pointC = _getFirstDifferent(Offset((cx - 7).toDouble(), (cy + 7).toDouble()), false, -1, 1);
      pointD = _getFirstDifferent(Offset((cx - 7).toDouble(), (cy - 7).toDouble()), false, -1, -1);
    }

    cx = ((pointA.dx + pointD.dx + pointB.dx + pointC.dx) / 4).round();
    cy = ((pointA.dy + pointD.dy + pointB.dy + pointC.dy) / 4).round();
    if (cx < 0 || cy < 0 || cx >= image.width || cy >= image.height) return null;
    return Offset(cx.toDouble(), cy.toDouble());
  }

  int _getDimension() {
    if (_compact) return 4 * _nbLayers + 11;
    if (_nbLayers <= 4) return 4 * _nbLayers + 15;
    return 4 * _nbLayers + 2 * ((_nbLayers - 4) ~/ 8 + 1) + 15;
  }

  UBitMatrix? _sampleGrid(Offset topLeft, Offset topRight, Offset bottomRight, Offset bottomLeft, int dimension) {
    const double low = 0.5;
    final double high = dimension - 0.5;
    final UPerspectiveTransform transform = UPerspectiveTransform.quadrilateralToQuadrilateral(
      low,
      low,
      high,
      low,
      high,
      high,
      low,
      high,
      topLeft.dx,
      topLeft.dy,
      topRight.dx,
      topRight.dy,
      bottomRight.dx,
      bottomRight.dy,
      bottomLeft.dx,
      bottomLeft.dy,
    );
    return UGridSampler.sample(image, dimension, dimension, transform);
  }

  int _sampleLine(Offset p1, Offset p2, int size) {
    int result = 0;
    final double d = _distance(p1, p2);
    final double moduleSize = d / size;
    final double px = p1.dx;
    final double py = p1.dy;
    final double dx = moduleSize * (p2.dx - p1.dx) / d;
    final double dy = moduleSize * (p2.dy - p1.dy) / d;
    for (int i = 0; i < size; i++) {
      if (image.get((px + i * dx + 0.5).toInt(), (py + i * dy + 0.5).toInt())) result |= 1 << (size - i - 1);
    }
    return result;
  }

  bool _isWhiteOrBlackRectangle(Offset p1, Offset p2, Offset p3, Offset p4) {
    const int corr = 3;
    final Offset a = Offset(max(0, p1.dx - corr), min(image.height - 1, p1.dy + corr).toDouble());
    final Offset b = Offset(max(0, p2.dx - corr), max(0, p2.dy - corr));
    final Offset c = Offset(min(image.width - 1, p3.dx + corr).toDouble(), max(0, min(image.height - 1, p3.dy - corr)).toDouble());
    final Offset d = Offset(min(image.width - 1, p4.dx + corr).toDouble(), min(image.height - 1, p4.dy + corr).toDouble());

    final int cAD = _getColor(d, a);
    if (cAD == 0) return false;
    final int cAB = _getColor(a, b);
    if (cAB != cAD) return false;
    final int cBC = _getColor(b, c);
    if (cBC != cAB) return false;
    final int cCD = _getColor(c, d);
    return cCD == cAB;
  }

  int _getColor(Offset p1, Offset p2) {
    final double d = _distance(p1, p2);
    if (d == 0.0) return 0;
    final double dx = (p2.dx - p1.dx) / d;
    final double dy = (p2.dy - p1.dy) / d;
    int error = 0;
    double px = p1.dx;
    double py = p1.dy;
    final bool colorModel = image.get(p1.dx.toInt(), p1.dy.toInt());
    final int iMax = d.floor();
    for (int i = 0; i < iMax; i++) {
      if (image.get(px.toInt(), py.toInt()) != colorModel) error++;
      px += dx;
      py += dy;
    }
    final double errRatio = error / d;
    if (errRatio > 0.1 && errRatio < 0.9) return 0;
    return (errRatio <= 0.1) == colorModel ? 1 : -1;
  }

  Offset _getFirstDifferent(Offset init, bool color, int dx, int dy) {
    int x = init.dx.toInt() + dx;
    int y = init.dy.toInt() + dy;
    while (_isValid(x, y) && image.get(x, y) == color) {
      x += dx;
      y += dy;
    }
    x -= dx;
    y -= dy;
    while (_isValid(x, y) && image.get(x, y) == color) {
      x += dx;
    }
    x -= dx;
    while (_isValid(x, y) && image.get(x, y) == color) {
      y += dy;
    }
    y -= dy;
    return Offset(x.toDouble(), y.toDouble());
  }

  static List<Offset> _expandSquare(List<Offset> cornerPoints, int oldSide, int newSide) {
    final double ratio = newSide / (2.0 * oldSide);
    double dx = cornerPoints[0].dx - cornerPoints[2].dx;
    double dy = cornerPoints[0].dy - cornerPoints[2].dy;
    double centerx = (cornerPoints[0].dx + cornerPoints[2].dx) / 2.0;
    double centery = (cornerPoints[0].dy + cornerPoints[2].dy) / 2.0;
    final Offset result0 = Offset(centerx + ratio * dx, centery + ratio * dy);
    final Offset result2 = Offset(centerx - ratio * dx, centery - ratio * dy);

    dx = cornerPoints[1].dx - cornerPoints[3].dx;
    dy = cornerPoints[1].dy - cornerPoints[3].dy;
    centerx = (cornerPoints[1].dx + cornerPoints[3].dx) / 2.0;
    centery = (cornerPoints[1].dy + cornerPoints[3].dy) / 2.0;
    final Offset result1 = Offset(centerx + ratio * dx, centery + ratio * dy);
    final Offset result3 = Offset(centerx - ratio * dx, centery - ratio * dy);
    return <Offset>[result0, result1, result2, result3];
  }

  bool _isValid(int x, int y) => x >= 0 && x < image.width && y >= 0 && y < image.height;

  bool _isValidPoint(Offset point) => _isValid(point.dx.round(), point.dy.round());

  static double _distance(Offset a, Offset b) {
    final double dx = a.dx - b.dx;
    final double dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
  }
}

abstract class UAztecDecoder {
  static const List<String> _upperTable = <String>[
    "CTRL_PS", " ", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
    "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "CTRL_LL", "CTRL_ML", "CTRL_DL", "CTRL_BS",
  ];

  static const List<String> _lowerTable = <String>[
    "CTRL_PS", " ", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
    "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "CTRL_US", "CTRL_ML", "CTRL_DL", "CTRL_BS",
  ];

  static final List<String> _mixedTable = <String>[
    "CTRL_PS",
    " ",
    ...List<String>.generate(13, (int i) => String.fromCharCode(i + 1)),
    ...List<String>.generate(5, (int i) => String.fromCharCode(i + 27)),
    "@",
    String.fromCharCode(92),
    "^",
    "_",
    "`",
    "|",
    "~",
    String.fromCharCode(127),
    "CTRL_LL",
    "CTRL_UL",
    "CTRL_PL",
    "CTRL_BS",
  ];

  static final List<String> _punctTable = <String>[
    "FLG(n)",
    String.fromCharCode(13),
    String.fromCharCodes(<int>[13, 10]),
    ". ",
    ", ",
    ": ",
    "!",
    String.fromCharCode(34),
    "#",
    r"$",
    "%",
    "&",
    "'",
    "(",
    ")",
    "*",
    "+",
    ",",
    "-",
    ".",
    "/",
    ":",
    ";",
    "<",
    "=",
    ">",
    "?",
    "[",
    "]",
    "{",
    "}",
    "CTRL_UL",
  ];

  static const List<String> _digitTable = <String>[
    "CTRL_PS", " ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ".", "CTRL_UL", "CTRL_US",
  ];

  static UCode decode(UAztecDetectorResult detectorResult) {
    final UBitMatrix matrix = detectorResult.bits;
    final List<bool> rawbits = _extractBits(detectorResult, matrix);
    final List<bool> correctedBits = _correctBits(detectorResult, rawbits);
    final Uint8List rawBytes = _convertBoolArrayToByteArray(correctedBits);
    final String text = _getEncodedData(correctedBits);
    return UCode(format: UCodeFormat.aztec, text: text, bytes: rawBytes, corners: detectorResult.points, version: detectorResult.nbLayers);
  }

  static List<bool> _extractBits(UAztecDetectorResult result, UBitMatrix matrix) {
    final bool compact = result.compact;
    final int layers = result.nbLayers;
    final int baseMatrixSize = (compact ? 11 : 14) + layers * 4;
    final Int32List alignmentMap = Int32List(baseMatrixSize);
    final List<bool> rawbits = List<bool>.filled(_totalBitsInLayer(layers, compact), false);

    if (compact) {
      for (int i = 0; i < alignmentMap.length; i++) {
        alignmentMap[i] = i;
      }
    } else {
      final int matrixSize = baseMatrixSize + 1 + 2 * ((baseMatrixSize ~/ 2 - 1) ~/ 15);
      final int origCenter = baseMatrixSize ~/ 2;
      final int center = matrixSize ~/ 2;
      for (int i = 0; i < origCenter; i++) {
        final int newOffset = i + i ~/ 15;
        alignmentMap[origCenter - i - 1] = center - newOffset - 1;
        alignmentMap[origCenter + i] = center + newOffset + 1;
      }
    }

    for (int i = 0, rowOffset = 0; i < layers; i++) {
      final int rowSize = (layers - i) * 4 + (compact ? 9 : 12);
      final int low = i * 2;
      final int high = baseMatrixSize - 1 - low;
      for (int j = 0; j < rowSize; j++) {
        final int columnOffset = j * 2;
        for (int k = 0; k < 2; k++) {
          if (rowOffset + columnOffset + k >= rawbits.length) continue;
          rawbits[rowOffset + columnOffset + k] = matrix.get(alignmentMap[low + k], alignmentMap[low + j]);
          final int index1 = rowOffset + rowSize * 2 + columnOffset + k;
          if (index1 < rawbits.length) rawbits[index1] = matrix.get(alignmentMap[low + j], alignmentMap[high - k]);
          final int index2 = rowOffset + rowSize * 4 + columnOffset + k;
          if (index2 < rawbits.length) rawbits[index2] = matrix.get(alignmentMap[high - k], alignmentMap[high - j]);
          final int index3 = rowOffset + rowSize * 6 + columnOffset + k;
          if (index3 < rawbits.length) rawbits[index3] = matrix.get(alignmentMap[high - j], alignmentMap[low + k]);
        }
      }
      rowOffset += rowSize * 8;
    }
    return rawbits;
  }

  static int _totalBitsInLayer(int layers, bool compact) => ((compact ? 88 : 112) + 16 * layers) * layers;

  static List<bool> _correctBits(UAztecDetectorResult result, List<bool> rawbits) {
    final UGaloisField field;
    final int codewordSize;
    if (result.nbLayers <= 2) {
      codewordSize = 6;
      field = UGaloisField.aztec6;
    } else if (result.nbLayers <= 8) {
      codewordSize = 8;
      field = UGaloisField.aztec8;
    } else if (result.nbLayers <= 22) {
      codewordSize = 10;
      field = UGaloisField.aztec10;
    } else {
      codewordSize = 12;
      field = UGaloisField.aztec12;
    }

    final int numDataCodewords = result.nbDatablocks;
    final int numCodewords = rawbits.length ~/ codewordSize;
    if (numCodewords < numDataCodewords) throw const UCodeDecodeException("Aztec codeword shortage");
    int offset = rawbits.length % codewordSize;

    final Int32List dataWords = Int32List(numCodewords);
    for (int i = 0; i < numCodewords; i++, offset += codewordSize) {
      int value = 0;
      for (int j = 0; j < codewordSize; j++) {
        value = (value << 1) | (rawbits[offset + j] ? 1 : 0);
      }
      dataWords[i] = value;
    }

    UReedSolomon.decode(field, dataWords, numCodewords - numDataCodewords);

    final int mask = (1 << codewordSize) - 1;
    int stuffedBits = 0;
    for (int i = 0; i < numDataCodewords; i++) {
      final int dataWord = dataWords[i];
      if (dataWord == 0 || dataWord == mask) throw const UCodeDecodeException("Invalid Aztec codeword");
      if (dataWord == 1 || dataWord == mask - 1) stuffedBits++;
    }

    final List<bool> correctedBits = List<bool>.filled(numDataCodewords * codewordSize - stuffedBits, false);
    int index = 0;
    for (int i = 0; i < numDataCodewords; i++) {
      final int dataWord = dataWords[i];
      if (dataWord == 1 || dataWord == mask - 1) {
        correctedBits.fillRange(index, index + codewordSize - 1, dataWord > 1);
        index += codewordSize - 1;
      } else {
        for (int bit = codewordSize - 1; bit >= 0; bit--) {
          correctedBits[index++] = (dataWord & (1 << bit)) != 0;
        }
      }
    }
    return correctedBits;
  }

  static Uint8List _convertBoolArrayToByteArray(List<bool> bits) {
    final Uint8List bytes = Uint8List((bits.length + 7) ~/ 8);
    for (int i = 0; i < bytes.length; i++) {
      final int bitsLeft = min(8, bits.length - i * 8);
      int value = 0;
      for (int j = 0; j < bitsLeft; j++) {
        value = (value << 1) | (bits[i * 8 + j] ? 1 : 0);
      }
      bytes[i] = value << (8 - bitsLeft);
    }
    return bytes;
  }

  static String _getEncodedData(List<bool> correctedBits) {
    final int endIndex = correctedBits.length;
    List<String> latchTable = _upperTable;
    List<String> shiftTable = _upperTable;
    final StringBuffer result = StringBuffer();
    int index = 0;

    while (index < endIndex) {
      if (identical(shiftTable, _binaryMarker)) {
        if (endIndex - index < 5) break;
        int length = _readCode(correctedBits, index, 5);
        index += 5;
        if (length == 0) {
          if (endIndex - index < 11) break;
          length = _readCode(correctedBits, index, 11) + 31;
          index += 11;
        }
        final List<int> bytes = <int>[];
        for (int charCount = 0; charCount < length; charCount++) {
          if (endIndex - index < 8) {
            index = endIndex;
            break;
          }
          bytes.add(_readCode(correctedBits, index, 8));
          index += 8;
        }
        result.write(UCharsetDecoder.decode(Uint8List.fromList(bytes)));
        shiftTable = latchTable;
        continue;
      }

      final int size = identical(shiftTable, _digitTable) ? 4 : 5;
      if (endIndex - index < size) break;
      final int code = _readCode(correctedBits, index, size);
      index += size;
      final String str = shiftTable[code];

      if (str.startsWith("CTRL_")) {
        final String mode = str[5];
        shiftTable = _tableFor(mode);
        if (str[6] == "L") latchTable = shiftTable;
        continue;
      }
      if (str == "CTRL_BS" || str == "FLG(n)") {
        shiftTable = latchTable;
        continue;
      }
      result.write(str);
      shiftTable = latchTable;
    }
    return result.toString();
  }

  static const List<String> _binaryMarker = <String>["__binary__"];

  static List<String> _tableFor(String code) {
    switch (code) {
      case "U":
        return _upperTable;
      case "L":
        return _lowerTable;
      case "M":
        return _mixedTable;
      case "P":
        return _punctTable;
      case "D":
        return _digitTable;
      case "B":
        return _binaryMarker;
      default:
        return _upperTable;
    }
  }

  static int _readCode(List<bool> rawbits, int startIndex, int length) {
    int res = 0;
    for (int i = startIndex; i < startIndex + length; i++) {
      res <<= 1;
      if (rawbits[i]) res |= 0x01;
    }
    return res;
  }
}

abstract class UAztecScanner {
  static List<UCode> scan(UBitMatrix matrix, UCodeScanOptions options) {
    try {
      final UAztecDetectorResult? detected = UAztecDetector(matrix).detect();
      if (detected == null) return const <UCode>[];
      return <UCode>[UAztecDecoder.decode(detected)];
    } catch (_) {
      return const <UCode>[];
    }
  }
}

// =============================================================================
// PDF417
//
// The 3 x 929 symbol table already ships with the barcode generator, so the
// decoder inverts that table at first use instead of carrying a second copy.
// =============================================================================

abstract class UPdf417Symbols {
  static Map<int, int>? _byPattern;

  static const int startPattern = 0x1FEA8;
  static const int stopPattern = 0x3FA29;
  static const int modulesPerCodeword = 17;

  /// pattern -> cluster * 1000 + codeword value.
  static Map<int, int> get byPattern {
    final Map<int, int>? cached = _byPattern;
    if (cached != null) return cached;
    final Map<int, int> table = <int, int>{};
    for (int cluster = 0; cluster < barcode.codewords.length; cluster++) {
      final List<int> patterns = barcode.codewords[cluster];
      for (int word = 0; word < patterns.length; word++) {
        table[patterns[word]] = cluster * 1000 + word;
      }
    }
    _byPattern = table;
    return table;
  }

  /// Returns cluster * 1000 + codeword for [pattern], or -1 when nothing fits.
  static int lookup(int pattern, {int maxDistance = 2}) {
    final int? exact = byPattern[pattern];
    if (exact != null) return exact;
    if (maxDistance <= 0 || pattern == 0) return -1;
    int best = -1;
    int bestDistance = maxDistance + 1;
    byPattern.forEach((int candidate, int value) {
      final int distance = _bitDistance(candidate, pattern);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = value;
      }
    });
    return bestDistance <= maxDistance ? best : -1;
  }

  static int _bitDistance(int a, int b) {
    int value = a ^ b;
    int count = 0;
    while (value != 0) {
      count += value & 1;
      value >>= 1;
    }
    return count;
  }
}

class UPdf417Row {
  const UPdf417Row({
    required this.rowNumber,
    required this.codewords,
    required this.rowsCount,
    required this.columnsCount,
    required this.ecLevel,
  });

  final int rowNumber;
  final List<int> codewords;

  /// -1 when this row's indicators do not carry the value.
  final int rowsCount;
  final int columnsCount;
  final int ecLevel;
}

abstract class UPdf417Scanner {
  static List<UCode> scan(UBitMatrix matrix, UCodeScanOptions options) {
    try {
      final UCode? code = _scan(matrix);
      return code == null ? const <UCode>[] : <UCode>[code];
    } catch (_) {
      return const <UCode>[];
    }
  }

  static UCode? _scan(UBitMatrix matrix) {
    final Map<int, List<int>> rowData = <int, List<int>>{};
    int rowsCount = -1;
    int columnsCount = -1;
    int ecLevel = -1;
    double top = double.infinity;
    double bottom = -1;

    final int step = matrix.height > 400 ? 2 : 1;
    for (int y = 0; y < matrix.height; y += step) {
      final UPdf417Row? row = _decodeRow(matrix, y);
      if (row == null) continue;
      rowData.putIfAbsent(row.rowNumber, () => row.codewords);
      if (row.rowsCount > 0) rowsCount = row.rowsCount;
      if (row.columnsCount > 0) columnsCount = row.columnsCount;
      if (row.ecLevel >= 0) ecLevel = row.ecLevel;
      if (y < top) top = y.toDouble();
      if (y > bottom) bottom = y.toDouble();
    }

    if (rowsCount <= 0) rowsCount = rowData.keys.isEmpty ? 0 : rowData.keys.reduce(max) + 1;
    if (columnsCount <= 0 && rowData.isNotEmpty) columnsCount = rowData.values.first.length;
    if (rowsCount <= 0 || columnsCount <= 0 || ecLevel < 0 || ecLevel > 8) return null;

    final List<int> all = <int>[];
    for (int r = 0; r < rowsCount; r++) {
      final List<int>? row = rowData[r];
      if (row == null || row.length != columnsCount) return null;
      all.addAll(row);
    }

    final int numEcCodewords = 1 << (ecLevel + 1);
    if (all.length <= numEcCodewords) return null;
    final Int32List received = Int32List.fromList(all);
    UModulusPoly.decode(received, numEcCodewords, Int32List(0));

    final int length = received[0];
    if (length < 1 || length > received.length - numEcCodewords) return null;
    final List<int> data = received.sublist(1, length).toList();
    final UQrDecodeResult decoded = UPdf417DecodedBitStream.decode(data);

    return UCode(
      format: UCodeFormat.pdf417,
      text: decoded.text,
      bytes: decoded.bytes,
      corners: <Offset>[Offset(0, top), Offset(matrix.width.toDouble(), top), Offset(matrix.width.toDouble(), bottom), Offset(0, bottom)],
      eci: decoded.eci,
      errorCorrectionLevel: "$ecLevel",
      version: columnsCount,
    );
  }

  static UPdf417Row? _decodeRow(UBitMatrix matrix, int y) {
    final UBitArray row = UBitArray.fromMatrixRow(matrix, y);
    final List<int>? start = _findPattern(row, row.getNextSet(0), const <int>[8, 1, 1, 1, 1, 1, 1, 3]);
    if (start == null) return null;
    final double moduleWidth = (start[1] - start[0]) / modulesPerCodeword;
    if (moduleWidth < 0.75) return null;

    final List<int>? stop = _findPattern(row, start[1], const <int>[7, 1, 1, 3, 1, 1, 1, 2, 1]);
    if (stop == null) return null;

    final double span = stop[0] - start[1].toDouble();
    final int count = (span / (moduleWidth * modulesPerCodeword)).round();
    if (count < 3) return null;
    final double step = span / count;

    final List<int> values = <int>[];
    final List<int> clusters = <int>[];
    for (int i = 0; i < count; i++) {
      final int pattern = _readPattern(row, start[1] + i * step, step / modulesPerCodeword);
      final int found = UPdf417Symbols.lookup(pattern);
      if (found < 0) return null;
      clusters.add(found ~/ 1000);
      values.add(found % 1000);
    }

    final int cluster = clusters.first;
    final int leftIndicator = values.first;
    final int rightIndicator = values.last;
    final List<int> data = values.sublist(1, values.length - 1);
    if (data.isEmpty) return null;
    if (leftIndicator ~/ 30 != rightIndicator ~/ 30) return null;

    final int rowNumber = 3 * (leftIndicator ~/ 30) + cluster;
    final int leftRemainder = leftIndicator % 30;
    final int rightRemainder = rightIndicator % 30;

    int rowsCount = -1;
    int columnsCount = -1;
    int ecLevel = -1;
    switch (cluster) {
      case 0:
        columnsCount = rightRemainder + 1;
        break;
      case 1:
        ecLevel = leftRemainder ~/ 3;
        rowsCount = rightRemainder * 3 + (leftRemainder % 3) + 1;
        break;
      case 2:
        columnsCount = leftRemainder + 1;
        ecLevel = rightRemainder ~/ 3;
        break;
    }

    return UPdf417Row(rowNumber: rowNumber, codewords: data, rowsCount: rowsCount, columnsCount: columnsCount, ecLevel: ecLevel);
  }

  static const int modulesPerCodeword = UPdf417Symbols.modulesPerCodeword;

  static int _readPattern(UBitArray row, double start, double moduleWidth) {
    int pattern = 0;
    for (int i = 0; i < UPdf417Symbols.modulesPerCodeword; i++) {
      final int x = (start + (i + 0.5) * moduleWidth).round();
      pattern <<= 1;
      if (row.get(x)) pattern |= 1;
    }
    return pattern;
  }

  static List<int>? _findPattern(UBitArray row, int from, List<int> widths) {
    final Int32List counters = Int32List(widths.length);
    final int width = row.size;
    int counterPosition = 0;
    int patternStart = row.getNextSet(from);
    bool isWhite = false;

    for (int x = patternStart; x < width; x++) {
      if (row.get(x) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == widths.length - 1) {
          if (U1DReader.patternMatchVariance(counters, widths, 0.8) < 0.45) return <int>[patternStart, x];
          patternStart += counters[0] + counters[1];
          for (int i = 2; i < widths.length; i++) {
            counters[i - 2] = counters[i];
          }
          counters[widths.length - 2] = 0;
          counters[widths.length - 1] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    return null;
  }
}

abstract class UPdf417DecodedBitStream {
  static const int _textCompactionModeLatch = 900;
  static const int _byteCompactionModeLatch = 901;
  static const int _numericCompactionModeLatch = 902;
  static const int _byteCompactionModeLatch6 = 924;
  static const int _eciCharset = 927;
  static const int _beginMacroControlBlock = 928;
  static const int _beginMacroOptionalField = 923;
  static const int _macroTerminator = 922;
  static const int _modeShiftToByteCompaction = 913;
  static const int _maxNumericCodewords = 15;

  static const List<String> _punctChars = <String>[
    ";", "<", ">", "@", "[", r"\", "]", "_", "`", "~", "!", "\r", "\t", ",", ":", "\n",
    "-", ".", r"$", "/", '"', "|", "*", "(", ")", "?", "{", "}", "'",
  ];

  static const List<String> _mixedChars = <String>[
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "&", "\r", "\t", ",", ":", "#",
    "-", ".", r"$", "/", "+", "%", "*", "=", "^",
  ];

  static UQrDecodeResult decode(List<int> codewords) {
    final StringBuffer result = StringBuffer();
    final List<int> byteSegments = <int>[];
    int? eci;
    int index = 0;

    while (index < codewords.length) {
      final int code = codewords[index++];
      switch (code) {
        case _textCompactionModeLatch:
          index = _textCompaction(codewords, index, result);
          break;
        case _byteCompactionModeLatch:
        case _byteCompactionModeLatch6:
          index = _byteCompaction(codewords, index, result, byteSegments);
          break;
        case _modeShiftToByteCompaction:
          if (index < codewords.length) {
            final int value = codewords[index++] % 256;
            result.writeCharCode(value);
            byteSegments.add(value);
          }
          break;
        case _numericCompactionModeLatch:
          index = _numericCompaction(codewords, index, result);
          break;
        case _eciCharset:
          if (index < codewords.length) eci = codewords[index++];
          break;
        case _beginMacroControlBlock:
        case _beginMacroOptionalField:
        case _macroTerminator:
          index = codewords.length;
          break;
        default:
          index = _textCompaction(codewords, index - 1, result);
          break;
      }
    }

    final String text = result.toString();
    return UQrDecodeResult(text: text, bytes: byteSegments.isNotEmpty ? Uint8List.fromList(byteSegments) : Uint8List.fromList(utf8.encode(text)), eci: eci);
  }

  static int _textCompaction(List<int> codewords, int start, StringBuffer result) {
    final List<int> values = <int>[];
    int index = start;
    while (index < codewords.length && codewords[index] < 900) {
      final int code = codewords[index];
      index++;
      values
        ..add(code ~/ 30)
        ..add(code % 30);
    }
    _decodeTextCompaction(values, result);
    return index;
  }

  static void _decodeTextCompaction(List<int> data, StringBuffer result) {
    int subMode = 0;
    int priorToShiftMode = 0;
    for (final int value in data) {
      switch (subMode) {
        case 0:
          if (value < 26) {
            result.writeCharCode(65 + value);
          } else if (value == 26) {
            result.write(" ");
          } else if (value == 27) {
            subMode = 1;
          } else if (value == 28) {
            subMode = 2;
          } else if (value == 29) {
            priorToShiftMode = subMode;
            subMode = 4;
          }
          break;
        case 1:
          if (value < 26) {
            result.writeCharCode(97 + value);
          } else if (value == 26) {
            result.write(" ");
          } else if (value == 27) {
            priorToShiftMode = subMode;
            subMode = 3;
          } else if (value == 28) {
            subMode = 2;
          } else if (value == 29) {
            priorToShiftMode = subMode;
            subMode = 4;
          }
          break;
        case 2:
          if (value < 25) {
            result.write(_mixedChars[value]);
          } else if (value == 25) {
            subMode = 5;
          } else if (value == 26) {
            result.write(" ");
          } else if (value == 27) {
            subMode = 1;
          } else if (value == 28) {
            subMode = 0;
          } else if (value == 29) {
            priorToShiftMode = subMode;
            subMode = 4;
          }
          break;
        case 5:
          if (value < _punctChars.length) {
            result.write(_punctChars[value]);
          } else if (value == 29) {
            subMode = 0;
          }
          break;
        case 3:
          subMode = priorToShiftMode;
          if (value < 26) {
            result.writeCharCode(65 + value);
          } else if (value == 26) {
            result.write(" ");
          }
          break;
        case 4:
          subMode = priorToShiftMode;
          if (value < _punctChars.length) result.write(_punctChars[value]);
          break;
      }
    }
  }

  static int _byteCompaction(List<int> codewords, int start, StringBuffer result, List<int> byteSegments) {
    int index = start;
    final List<int> buffer = <int>[];
    final List<int> chunk = <int>[];
    while (index < codewords.length && codewords[index] < 900) {
      chunk.add(codewords[index]);
      index++;
      if (chunk.length == 5) {
        int value = 0;
        for (final int code in chunk) {
          value = value * 900 + code;
        }
        final List<int> bytes = List<int>.filled(6, 0);
        for (int i = 5; i >= 0; i--) {
          bytes[i] = value % 256;
          value ~/= 256;
        }
        buffer.addAll(bytes);
        chunk.clear();
      }
    }
    for (final int code in chunk) {
      buffer.add(code % 256);
    }
    byteSegments.addAll(buffer);
    result.write(String.fromCharCodes(buffer));
    return index;
  }

  static int _numericCompaction(List<int> codewords, int start, StringBuffer result) {
    int index = start;
    final List<int> group = <int>[];
    while (index < codewords.length && codewords[index] < 900) {
      group.add(codewords[index]);
      index++;
      if (group.length == _maxNumericCodewords) {
        result.write(_decodeBase900toBase10(group));
        group.clear();
      }
    }
    if (group.isNotEmpty) result.write(_decodeBase900toBase10(group));
    return index;
  }

  static String _decodeBase900toBase10(List<int> group) {
    BigInt value = BigInt.zero;
    for (final int code in group) {
      value = value * BigInt.from(900) + BigInt.from(code);
    }
    final String text = value.toString();
    return text.startsWith("1") ? text.substring(1) : "";
  }
}

// =============================================================================
// Public entry point
// =============================================================================

class UCodeScanOptions {
  const UCodeScanOptions({
    this.formats = const <UCodeFormat>[],
    this.multiple = false,
    this.tryHarder = true,
    this.tryRotate = true,
    this.tryInvert = false,
    this.tryDownscale = true,
    this.maxSymbols = 8,
    this.region,
  });

  /// Empty means every supported symbology. Restricting this is the single
  /// biggest decode-speed win.
  final List<UCodeFormat> formats;

  /// Keep looking after the first symbol.
  final bool multiple;

  /// Spend more time on hard images (more rows, more rotations).
  final bool tryHarder;
  final bool tryRotate;

  /// Also try the inverted image, for light-on-dark symbols.
  final bool tryInvert;

  /// Retry at half resolution when the full-resolution pass finds nothing.
  final bool tryDownscale;
  final int maxSymbols;

  /// Restrict decoding to this rectangle of the source image.
  final Rect? region;

  Set<UCodeFormat> get effectiveFormats {
    if (formats.isEmpty) {
      return UCodeFormat.values.where((UCodeFormat f) => f != UCodeFormat.unknown).toSet();
    }
    final Set<UCodeFormat> set = formats.toSet();
    if (set.contains(UCodeFormat.itf)) set.add(UCodeFormat.itf);
    return set;
  }

  bool get wantsMatrix {
    final Set<UCodeFormat> set = effectiveFormats;
    return set.contains(UCodeFormat.qr) ||
        set.contains(UCodeFormat.microQr) ||
        set.contains(UCodeFormat.dataMatrix) ||
        set.contains(UCodeFormat.aztec) ||
        set.contains(UCodeFormat.pdf417);
  }

  UCodeScanOptions copyWith({List<UCodeFormat>? formats, bool? multiple, bool? tryHarder, bool? tryRotate, bool? tryInvert, bool? tryDownscale, int? maxSymbols, Rect? region}) =>
      UCodeScanOptions(
        formats: formats ?? this.formats,
        multiple: multiple ?? this.multiple,
        tryHarder: tryHarder ?? this.tryHarder,
        tryRotate: tryRotate ?? this.tryRotate,
        tryInvert: tryInvert ?? this.tryInvert,
        tryDownscale: tryDownscale ?? this.tryDownscale,
        maxSymbols: maxSymbols ?? this.maxSymbols,
        region: region ?? this.region,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    "formats": formats.map((UCodeFormat f) => f.name).toList(growable: false),
    "multiple": multiple,
    "tryHarder": tryHarder,
    "tryRotate": tryRotate,
    "tryInvert": tryInvert,
    "tryDownscale": tryDownscale,
    "maxSymbols": maxSymbols,
    "region": region == null ? null : <double>[region!.left, region!.top, region!.width, region!.height],
  };

  static UCodeScanOptions fromMap(Map<Object?, Object?> map) {
    final Object? rawFormats = map["formats"];
    final Object? rawRegion = map["region"];
    return UCodeScanOptions(
      formats: rawFormats is List<Object?>
          ? rawFormats
                .map((Object? name) => UCodeFormat.values.firstWhere((UCodeFormat f) => f.name == name, orElse: () => UCodeFormat.unknown))
                .where((UCodeFormat f) => f != UCodeFormat.unknown)
                .toList(growable: false)
          : const <UCodeFormat>[],
      multiple: map["multiple"] == true,
      tryHarder: map["tryHarder"] != false,
      tryRotate: map["tryRotate"] != false,
      tryInvert: map["tryInvert"] == true,
      tryDownscale: map["tryDownscale"] != false,
      maxSymbols: (map["maxSymbols"] as num?)?.toInt() ?? 8,
      region: rawRegion is List<Object?> && rawRegion.length == 4
          ? Rect.fromLTWH(
              ((rawRegion[0] as num?) ?? 0).toDouble(),
              ((rawRegion[1] as num?) ?? 0).toDouble(),
              ((rawRegion[2] as num?) ?? 0).toDouble(),
              ((rawRegion[3] as num?) ?? 0).toDouble(),
            )
          : null,
    );
  }
}

abstract class UCodeReader {
  /// Decodes every enabled symbology from a grayscale image.
  static List<UCode> decode(UGrayImage image, [UCodeScanOptions options = const UCodeScanOptions()]) {
    if (image.isEmpty) return const <UCode>[];
    UGrayImage working = image;
    final Rect? region = options.region;
    if (region != null) {
      working = image.crop(region.left.round(), region.top.round(), region.width.round(), region.height.round());
      if (working.isEmpty) return const <UCode>[];
    }

    List<UCode> results = _decodeGray(working, options);
    if (results.isEmpty && options.tryDownscale && working.width > 640) {
      results = _decodeGray(working.downscale(2), options);
      if (results.isNotEmpty) results = results.map((UCode code) => _scale(code, 2)).toList(growable: false);
    }
    if (results.isEmpty && options.tryInvert) {
      results = _decodeGray(working.inverted(), options);
      results = results
          .map(
            (UCode code) => UCode(
              format: code.format,
              text: code.text,
              bytes: code.bytes,
              corners: code.corners,
              eci: code.eci,
              inverted: true,
              structuredAppend: code.structuredAppend,
              errorCorrectionLevel: code.errorCorrectionLevel,
              version: code.version,
              mask: code.mask,
            ),
          )
          .toList(growable: false);
    }
    if (results.isEmpty) return const <UCode>[];
    if (working.left == 0 && working.top == 0) return results;
    return results.map((UCode code) => code.translated(working.left.toDouble(), working.top.toDouble())).toList(growable: false);
  }

  static UCode _scale(UCode code, int factor) => UCode(
    format: code.format,
    text: code.text,
    bytes: code.bytes,
    corners: code.corners.map((Offset o) => Offset(o.dx * factor, o.dy * factor)).toList(growable: false),
    eci: code.eci,
    source: code.source,
    inverted: code.inverted,
    structuredAppend: code.structuredAppend,
    errorCorrectionLevel: code.errorCorrectionLevel,
    version: code.version,
    mask: code.mask,
  );

  static List<UCode> _decodeGray(UGrayImage image, UCodeScanOptions options) {
    final UBitMatrix matrix = UBinarizer.hybrid(image);
    final List<UCode> results = decodeBits(matrix, options);
    if (results.isNotEmpty || !options.tryHarder) return results;
    return decodeBits(UBinarizer.global(image), options);
  }

  /// Decodes an already-binarized matrix.
  static List<UCode> decodeBits(UBitMatrix matrix, [UCodeScanOptions options = const UCodeScanOptions()]) {
    final List<UCode> results = <UCode>[];
    final Set<UCodeFormat> formats = options.effectiveFormats;

    if (formats.contains(UCodeFormat.qr)) {
      for (final UQrDetectorResult detected in UQrDetector(matrix).detect(tryHarder: options.tryHarder, maxSymbols: options.maxSymbols)) {
        try {
          results.add(UQrMatrixDecoder.decode(detected.bits, detected.points));
          if (!options.multiple) return results;
        } catch (_) {
          continue;
        }
      }
    }

    if (formats.contains(UCodeFormat.dataMatrix)) {
      final List<UCode> found = UDataMatrixScanner.scan(matrix, options);
      results.addAll(found);
      if (found.isNotEmpty && !options.multiple) return results;
    }

    if (formats.contains(UCodeFormat.aztec)) {
      final List<UCode> found = UAztecScanner.scan(matrix, options);
      results.addAll(found);
      if (found.isNotEmpty && !options.multiple) return results;
    }

    if (formats.contains(UCodeFormat.pdf417)) {
      final List<UCode> found = UPdf417Scanner.scan(matrix, options);
      results.addAll(found);
      if (found.isNotEmpty && !options.multiple) return results;
    }

    final List<UCode> linear = ULinearScanner.scan(matrix, options);
    results.addAll(linear);
    if (results.isNotEmpty || !options.tryRotate) return results;

    final UBitMatrix rotated = matrix.rotate90();
    final List<UCode> rotatedResults = <UCode>[];
    if (formats.contains(UCodeFormat.qr)) {
      for (final UQrDetectorResult detected in UQrDetector(rotated).detect(tryHarder: options.tryHarder, maxSymbols: options.maxSymbols)) {
        try {
          rotatedResults.add(UQrMatrixDecoder.decode(detected.bits, detected.points));
        } catch (_) {
          continue;
        }
      }
    }
    rotatedResults.addAll(ULinearScanner.scan(rotated, options));
    for (final UCode code in rotatedResults) {
      results.add(_unrotate(code, matrix.width, matrix.height));
    }
    return results;
  }

  static UCode _unrotate(UCode code, int originalWidth, int originalHeight) => UCode(
    format: code.format,
    text: code.text,
    bytes: code.bytes,
    corners: code.corners.map((Offset o) => Offset(o.dy, originalHeight - 1 - o.dx)).toList(growable: false),
    eci: code.eci,
    source: code.source,
    inverted: code.inverted,
    structuredAppend: code.structuredAppend,
    errorCorrectionLevel: code.errorCorrectionLevel,
    version: code.version,
    mask: code.mask,
  );

  /// Decodes packed 32-bit pixel data (BGRA or RGBA) straight from a frame.
  static List<UCode> decodePixels(Uint8List pixels, int width, int height, {bool bgra = true, int rowStride = 0, UCodeScanOptions options = const UCodeScanOptions()}) =>
      decode(UGrayImage.fromPacked(pixels, width, height, bgra: bgra, rowStride: rowStride), options);

  /// Decodes the luminance plane of a YUV/NV21 camera frame with no copy.
  static List<UCode> decodeLuminance(Uint8List plane, int width, int height, {int rowStride = 0, UCodeScanOptions options = const UCodeScanOptions()}) =>
      decode(UGrayImage.fromLuminance(plane, width, height, rowStride: rowStride), options);
}

// =============================================================================
// Linear (1D) symbologies
// =============================================================================

class UBitArray {
  UBitArray(this.size) : bits = Uint8List(size);

  final int size;
  final Uint8List bits;

  bool get(int i) => i >= 0 && i < size && bits[i] != 0;

  void set(int i) {
    if (i >= 0 && i < size) bits[i] = 1;
  }

  int getNextSet(int from) {
    for (int i = from; i < size; i++) {
      if (bits[i] != 0) return i;
    }
    return size;
  }

  int getNextUnset(int from) {
    for (int i = from; i < size; i++) {
      if (bits[i] == 0) return i;
    }
    return size;
  }

  bool isRange(int start, int end, bool value) {
    for (int i = start; i < end; i++) {
      if ((bits[i] != 0) != value) return false;
    }
    return true;
  }

  UBitArray reversed() {
    final UBitArray out = UBitArray(size);
    for (int i = 0; i < size; i++) {
      if (bits[i] != 0) out.bits[size - 1 - i] = 1;
    }
    return out;
  }

  static UBitArray fromMatrixRow(UBitMatrix matrix, int y) {
    final UBitArray out = UBitArray(matrix.width);
    final int offset = y * matrix.width;
    for (int x = 0; x < matrix.width; x++) {
      out.bits[x] = matrix.bits[offset + x];
    }
    return out;
  }
}

class U1DResult {
  const U1DResult(this.format, this.text, this.start, this.end);

  final UCodeFormat format;
  final String text;
  final double start;
  final double end;
}

abstract class U1DReader {
  static const double _maxAvgVariance = 0.48;
  static const double _maxIndividualVariance = 0.7;

  /// Fills [counters] with alternating run lengths starting at [start].
  static void recordPattern(UBitArray row, int start, Int32List counters) {
    final int numCounters = counters.length;
    counters.fillRange(0, numCounters, 0);
    final int end = row.size;
    if (start >= end) throw const UCodeDecodeException("Pattern start out of range");
    bool isWhite = !row.get(start);
    int counterPosition = 0;
    int i = start;
    while (i < end) {
      if (row.get(i) != isWhite) {
        counters[counterPosition]++;
      } else {
        counterPosition++;
        if (counterPosition == numCounters) break;
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
      i++;
    }
    if (!(counterPosition == numCounters || (counterPosition == numCounters - 1 && i == end))) {
      throw const UCodeDecodeException("Truncated pattern");
    }
  }

  static void recordPatternInReverse(UBitArray row, int start, Int32List counters) {
    int numTransitionsLeft = counters.length;
    bool last = row.get(start);
    int position = start;
    while (position > 0 && numTransitionsLeft >= 0) {
      position--;
      if (row.get(position) != last) {
        numTransitionsLeft--;
        last = !last;
      }
    }
    if (numTransitionsLeft >= 0) throw const UCodeDecodeException("Truncated reverse pattern");
    recordPattern(row, position + 1, counters);
  }

  static double patternMatchVariance(Int32List counters, List<int> pattern, double maxIndividualVariance) {
    final int numCounters = counters.length;
    int total = 0;
    int patternLength = 0;
    for (int i = 0; i < numCounters; i++) {
      total += counters[i];
      patternLength += pattern[i];
    }
    if (total < patternLength) return double.infinity;

    final double unitBarWidth = total / patternLength;
    final double scaledIndividualVariance = maxIndividualVariance * unitBarWidth;
    double totalVariance = 0;
    for (int x = 0; x < numCounters; x++) {
      final int counter = counters[x];
      final double scaledPattern = pattern[x] * unitBarWidth;
      final double variance = counter > scaledPattern ? counter - scaledPattern : scaledPattern - counter;
      if (variance > scaledIndividualVariance) return double.infinity;
      totalVariance += variance;
    }
    return totalVariance / total;
  }

  static double get maxAvgVariance => _maxAvgVariance;

  static double get maxIndividualVariance => _maxIndividualVariance;
}

// -----------------------------------------------------------------------------
// UPC / EAN family
// -----------------------------------------------------------------------------

abstract class UUpcEanPatterns {
  static const List<int> startEndPattern = <int>[1, 1, 1];
  static const List<int> middlePattern = <int>[1, 1, 1, 1, 1];
  static const List<int> endPattern = <int>[1, 1, 1, 1, 1, 1];

  static const List<List<int>> lPatterns = <List<int>>[
    <int>[3, 2, 1, 1],
    <int>[2, 2, 2, 1],
    <int>[2, 1, 2, 2],
    <int>[1, 4, 1, 1],
    <int>[1, 1, 3, 2],
    <int>[1, 2, 3, 1],
    <int>[1, 1, 1, 4],
    <int>[1, 3, 1, 2],
    <int>[1, 2, 1, 3],
    <int>[3, 1, 1, 2],
  ];

  /// L patterns followed by their mirrored G patterns.
  static final List<List<int>> lAndGPatterns = <List<int>>[
    ...lPatterns,
    ...lPatterns.map((List<int> pattern) => pattern.reversed.toList(growable: false)),
  ];

  static const List<int> firstDigitEncodings = <int>[0x00, 0x0B, 0x0D, 0x0E, 0x13, 0x19, 0x1C, 0x15, 0x16, 0x1A];

  static const List<List<int>> numsysAndCheckDigit = <List<int>>[
    <int>[0x38, 0x34, 0x32, 0x31, 0x2C, 0x26, 0x23, 0x2A, 0x29, 0x25],
    <int>[0x07, 0x0B, 0x0D, 0x0E, 0x13, 0x19, 0x1C, 0x15, 0x16, 0x1A],
  ];

  static bool checksum(String digits) {
    if (digits.isEmpty) return false;
    int sum = 0;
    for (int i = digits.length - 2; i >= 0; i -= 2) {
      final int digit = digits.codeUnitAt(i) - 48;
      if (digit < 0 || digit > 9) return false;
      sum += digit;
    }
    sum *= 3;
    for (int i = digits.length - 3; i >= 0; i -= 2) {
      final int digit = digits.codeUnitAt(i) - 48;
      if (digit < 0 || digit > 9) return false;
      sum += digit;
    }
    return (1000 - sum) % 10 == digits.codeUnitAt(digits.length - 1) - 48;
  }
}

class UUpcEanReader {
  const UUpcEanReader();

  U1DResult? decodeRow(UBitArray row, Set<UCodeFormat> formats) {
    final List<int>? startRange = _findStartGuardPattern(row);
    if (startRange == null) return null;

    final StringBuffer result = StringBuffer();
    int rowOffset = startRange[1];
    final Int32List counters = Int32List(4);

    final Int32List lgPatternFound = Int32List(1);
    try {
      rowOffset = _decodeMiddle(row, startRange, result, counters, lgPatternFound);
    } catch (_) {
      return null;
    }

    final List<int>? endRange = _findGuardPattern(row, rowOffset, false, UUpcEanPatterns.startEndPattern);
    if (endRange == null) return null;

    final int quietEnd = endRange[1] + (endRange[1] - endRange[0]);
    if (quietEnd >= row.size || !row.isRange(endRange[1], quietEnd, false)) return null;

    String text = result.toString();
    if (text.length != 13) return null;
    if (!UUpcEanPatterns.checksum(text)) return null;

    UCodeFormat format = UCodeFormat.ean13;
    if (text.startsWith("0")) {
      if (formats.contains(UCodeFormat.upcA)) {
        format = UCodeFormat.upcA;
        text = text.substring(1);
      } else if (!formats.contains(UCodeFormat.ean13)) {
        return null;
      }
    } else if (!formats.contains(UCodeFormat.ean13)) {
      return null;
    }
    return U1DResult(format, text, startRange[0].toDouble(), endRange[1].toDouble());
  }

  int _decodeMiddle(UBitArray row, List<int> startRange, StringBuffer result, Int32List counters, Int32List lgPatternFound) {
    int rowOffset = startRange[1];
    int lgPattern = 0;
    for (int x = 0; x < 6; x++) {
      final int bestMatch = _decodeDigit(row, counters, rowOffset, UUpcEanPatterns.lAndGPatterns);
      result.writeCharCode(48 + bestMatch % 10);
      for (final int counter in counters) {
        rowOffset += counter;
      }
      if (bestMatch >= 10) lgPattern |= 1 << (5 - x);
    }
    final int firstDigit = UUpcEanPatterns.firstDigitEncodings.indexOf(lgPattern);
    if (firstDigit < 0) throw const UCodeDecodeException("Bad EAN-13 parity");
    final String head = String.fromCharCode(48 + firstDigit);
    final String body = result.toString();
    result
      ..clear()
      ..write(head)
      ..write(body);

    final List<int>? middleRange = _findGuardPattern(row, rowOffset, true, UUpcEanPatterns.middlePattern);
    if (middleRange == null) throw const UCodeDecodeException("Missing EAN middle guard");
    rowOffset = middleRange[1];

    for (int x = 0; x < 6; x++) {
      final int bestMatch = _decodeDigit(row, counters, rowOffset, UUpcEanPatterns.lPatterns);
      result.writeCharCode(48 + bestMatch);
      for (final int counter in counters) {
        rowOffset += counter;
      }
    }
    lgPatternFound[0] = lgPattern;
    return rowOffset;
  }

  static int _decodeDigit(UBitArray row, Int32List counters, int rowOffset, List<List<int>> patterns) {
    U1DReader.recordPattern(row, rowOffset, counters);
    double bestVariance = U1DReader.maxAvgVariance;
    int bestMatch = -1;
    for (int i = 0; i < patterns.length; i++) {
      final double variance = U1DReader.patternMatchVariance(counters, patterns[i], U1DReader.maxIndividualVariance);
      if (variance < bestVariance) {
        bestVariance = variance;
        bestMatch = i;
      }
    }
    if (bestMatch < 0) throw const UCodeDecodeException("Unrecognized UPC/EAN digit");
    return bestMatch;
  }

  static List<int>? _findStartGuardPattern(UBitArray row) {
    bool foundStart = false;
    List<int>? startRange;
    int nextStart = 0;
    final Int32List counters = Int32List(UUpcEanPatterns.startEndPattern.length);
    while (!foundStart) {
      counters.fillRange(0, counters.length, 0);
      startRange = _findGuardPattern(row, nextStart, false, UUpcEanPatterns.startEndPattern, counters);
      if (startRange == null) return null;
      final int start = startRange[0];
      nextStart = startRange[1];
      final int quietStart = start - (nextStart - start);
      if (quietStart >= 0) foundStart = row.isRange(quietStart, start, false);
    }
    return startRange;
  }

  static List<int>? _findGuardPattern(UBitArray row, int rowOffset, bool whiteFirst, List<int> pattern, [Int32List? reuse]) {
    final Int32List counters = reuse ?? Int32List(pattern.length);
    counters.fillRange(0, counters.length, 0);
    final int width = row.size;
    bool isWhite = whiteFirst;
    final int offset = whiteFirst ? row.getNextUnset(rowOffset) : row.getNextSet(rowOffset);
    int counterPosition = 0;
    int patternStart = offset;
    final int patternLength = pattern.length;

    for (int x = offset; x < width; x++) {
      if (row.get(x) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          if (U1DReader.patternMatchVariance(counters, pattern, U1DReader.maxIndividualVariance) < U1DReader.maxAvgVariance) {
            return <int>[patternStart, x];
          }
          patternStart += counters[0] + counters[1];
          for (int y = 2; y < patternLength; y++) {
            counters[y - 2] = counters[y];
          }
          counters[patternLength - 2] = 0;
          counters[patternLength - 1] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    return null;
  }
}

/// EAN-8 uses the same guards but eight digits with no parity encoding.
class UEan8Reader {
  const UEan8Reader();

  U1DResult? decodeRow(UBitArray row) {
    final List<int>? startRange = UUpcEanReader._findStartGuardPattern(row);
    if (startRange == null) return null;
    final StringBuffer result = StringBuffer();
    final Int32List counters = Int32List(4);
    int rowOffset = startRange[1];

    try {
      for (int x = 0; x < 4; x++) {
        final int bestMatch = UUpcEanReader._decodeDigit(row, counters, rowOffset, UUpcEanPatterns.lPatterns);
        result.writeCharCode(48 + bestMatch);
        for (final int counter in counters) {
          rowOffset += counter;
        }
      }
      final List<int>? middleRange = UUpcEanReader._findGuardPattern(row, rowOffset, true, UUpcEanPatterns.middlePattern);
      if (middleRange == null) return null;
      rowOffset = middleRange[1];
      for (int x = 0; x < 4; x++) {
        final int bestMatch = UUpcEanReader._decodeDigit(row, counters, rowOffset, UUpcEanPatterns.lPatterns);
        result.writeCharCode(48 + bestMatch);
        for (final int counter in counters) {
          rowOffset += counter;
        }
      }
    } catch (_) {
      return null;
    }

    final List<int>? endRange = UUpcEanReader._findGuardPattern(row, rowOffset, false, UUpcEanPatterns.startEndPattern);
    if (endRange == null) return null;
    final int quietEnd = endRange[1] + (endRange[1] - endRange[0]);
    if (quietEnd >= row.size || !row.isRange(endRange[1], quietEnd, false)) return null;

    final String text = result.toString();
    if (text.length != 8 || !UUpcEanPatterns.checksum(text)) return null;
    return U1DResult(UCodeFormat.ean8, text, startRange[0].toDouble(), endRange[1].toDouble());
  }
}

/// UPC-E: six digits between a start guard and a six-element end pattern.
class UUpcEReader {
  const UUpcEReader();

  U1DResult? decodeRow(UBitArray row) {
    final List<int>? startRange = UUpcEanReader._findStartGuardPattern(row);
    if (startRange == null) return null;
    final StringBuffer result = StringBuffer();
    final Int32List counters = Int32List(4);
    int rowOffset = startRange[1];
    int lgPatternFound = 0;

    try {
      for (int x = 0; x < 6; x++) {
        final int bestMatch = UUpcEanReader._decodeDigit(row, counters, rowOffset, UUpcEanPatterns.lAndGPatterns);
        result.writeCharCode(48 + bestMatch % 10);
        for (final int counter in counters) {
          rowOffset += counter;
        }
        if (bestMatch >= 10) lgPatternFound |= 1 << (5 - x);
      }
    } catch (_) {
      return null;
    }

    int numSys = -1;
    for (int system = 0; system <= 1; system++) {
      for (int digit = 0; digit < 10; digit++) {
        if (lgPatternFound == UUpcEanPatterns.numsysAndCheckDigit[system][digit]) {
          numSys = system;
          break;
        }
      }
      if (numSys >= 0) break;
    }
    if (numSys < 0) return null;

    final List<int>? endRange = UUpcEanReader._findGuardPattern(row, rowOffset, true, UUpcEanPatterns.endPattern);
    if (endRange == null) return null;

    final String compressed = "$numSys${result.toString()}";
    final String expanded = _expand(compressed);
    if (expanded.isEmpty) return null;
    final String full = expanded + _checkDigit(expanded);
    if (!UUpcEanPatterns.checksum(full)) return null;
    return U1DResult(UCodeFormat.upcE, "$compressed${_checkDigit(expanded)}", startRange[0].toDouble(), endRange[1].toDouble());
  }

  static String _expand(String compressed) {
    if (compressed.length != 7) return "";
    final String numberSystem = compressed[0];
    final String manufacturer = compressed.substring(1, 6);
    final String lastDigit = compressed[6];
    final StringBuffer buffer = StringBuffer(numberSystem);
    switch (lastDigit) {
      case "0":
      case "1":
      case "2":
        buffer
          ..write(manufacturer.substring(0, 2))
          ..write(lastDigit)
          ..write("0000")
          ..write(manufacturer.substring(2, 5));
        break;
      case "3":
        buffer
          ..write(manufacturer.substring(0, 3))
          ..write("00000")
          ..write(manufacturer.substring(3, 5));
        break;
      case "4":
        buffer
          ..write(manufacturer.substring(0, 4))
          ..write("00000")
          ..write(manufacturer[4]);
        break;
      default:
        buffer
          ..write(manufacturer)
          ..write("0000")
          ..write(lastDigit);
        break;
    }
    return buffer.toString();
  }

  static String _checkDigit(String elevenDigits) {
    int sum = 0;
    for (int i = 0; i < elevenDigits.length; i++) {
      final int digit = elevenDigits.codeUnitAt(i) - 48;
      sum += (i % 2 == 0) ? digit * 3 : digit;
    }
    return ((10 - (sum % 10)) % 10).toString();
  }
}

// -----------------------------------------------------------------------------
// Code 128
// -----------------------------------------------------------------------------

abstract class UCode128Patterns {
  static const List<List<int>> patterns = <List<int>>[
    <int>[2, 1, 2, 2, 2, 2], <int>[2, 2, 2, 1, 2, 2], <int>[2, 2, 2, 2, 2, 1], <int>[1, 2, 1, 2, 2, 3],
    <int>[1, 2, 1, 3, 2, 2], <int>[1, 3, 1, 2, 2, 2], <int>[1, 2, 2, 2, 1, 3], <int>[1, 2, 2, 3, 1, 2],
    <int>[1, 3, 2, 2, 1, 2], <int>[2, 2, 1, 2, 1, 3], <int>[2, 2, 1, 3, 1, 2], <int>[2, 3, 1, 2, 1, 2],
    <int>[1, 1, 2, 2, 3, 2], <int>[1, 2, 2, 1, 3, 2], <int>[1, 2, 2, 2, 3, 1], <int>[1, 1, 3, 2, 2, 2],
    <int>[1, 2, 3, 1, 2, 2], <int>[1, 2, 3, 2, 2, 1], <int>[2, 2, 3, 2, 1, 1], <int>[2, 2, 1, 1, 3, 2],
    <int>[2, 2, 1, 2, 3, 1], <int>[2, 1, 3, 2, 1, 2], <int>[2, 2, 3, 1, 1, 2], <int>[3, 1, 2, 1, 3, 1],
    <int>[3, 1, 1, 2, 2, 2], <int>[3, 2, 1, 1, 2, 2], <int>[3, 2, 1, 2, 2, 1], <int>[3, 1, 2, 2, 1, 2],
    <int>[3, 2, 2, 1, 1, 2], <int>[3, 2, 2, 2, 1, 1], <int>[2, 1, 2, 1, 2, 3], <int>[2, 1, 2, 3, 2, 1],
    <int>[2, 3, 2, 1, 2, 1], <int>[1, 1, 1, 3, 2, 3], <int>[1, 3, 1, 1, 2, 3], <int>[1, 3, 1, 3, 2, 1],
    <int>[1, 1, 2, 3, 1, 3], <int>[1, 3, 2, 1, 1, 3], <int>[1, 3, 2, 3, 1, 1], <int>[2, 1, 1, 3, 1, 3],
    <int>[2, 3, 1, 1, 1, 3], <int>[2, 3, 1, 3, 1, 1], <int>[1, 1, 2, 1, 3, 3], <int>[1, 1, 2, 3, 3, 1],
    <int>[1, 3, 2, 1, 3, 1], <int>[1, 1, 3, 1, 2, 3], <int>[1, 1, 3, 3, 2, 1], <int>[1, 3, 3, 1, 2, 1],
    <int>[3, 1, 3, 1, 2, 1], <int>[2, 1, 1, 3, 3, 1], <int>[2, 3, 1, 1, 3, 1], <int>[2, 1, 3, 1, 1, 3],
    <int>[2, 1, 3, 3, 1, 1], <int>[2, 1, 3, 1, 3, 1], <int>[3, 1, 1, 1, 2, 3], <int>[3, 1, 1, 3, 2, 1],
    <int>[3, 3, 1, 1, 2, 1], <int>[3, 1, 2, 1, 1, 3], <int>[3, 1, 2, 3, 1, 1], <int>[3, 3, 2, 1, 1, 1],
    <int>[3, 1, 4, 1, 1, 1], <int>[2, 2, 1, 4, 1, 1], <int>[4, 3, 1, 1, 1, 1], <int>[1, 1, 1, 2, 2, 4],
    <int>[1, 1, 1, 4, 2, 2], <int>[1, 2, 1, 1, 2, 4], <int>[1, 2, 1, 4, 2, 1], <int>[1, 4, 1, 1, 2, 2],
    <int>[1, 4, 1, 2, 2, 1], <int>[1, 1, 2, 2, 1, 4], <int>[1, 1, 2, 4, 1, 2], <int>[1, 2, 2, 1, 1, 4],
    <int>[1, 2, 2, 4, 1, 1], <int>[1, 4, 2, 1, 1, 2], <int>[1, 4, 2, 2, 1, 1], <int>[2, 4, 1, 2, 1, 1],
    <int>[2, 2, 1, 1, 1, 4], <int>[4, 1, 3, 1, 1, 1], <int>[2, 4, 1, 1, 1, 2], <int>[1, 3, 4, 1, 1, 1],
    <int>[1, 1, 1, 2, 4, 2], <int>[1, 2, 1, 1, 4, 2], <int>[1, 2, 1, 2, 4, 1], <int>[1, 1, 4, 2, 1, 2],
    <int>[1, 2, 4, 1, 1, 2], <int>[1, 2, 4, 2, 1, 1], <int>[4, 1, 1, 2, 1, 2], <int>[4, 2, 1, 1, 1, 2],
    <int>[4, 2, 1, 2, 1, 1], <int>[2, 1, 2, 1, 4, 1], <int>[2, 1, 4, 1, 2, 1], <int>[4, 1, 2, 1, 2, 1],
    <int>[1, 1, 1, 1, 4, 3], <int>[1, 1, 1, 3, 4, 1], <int>[1, 3, 1, 1, 4, 1], <int>[1, 1, 4, 1, 1, 3],
    <int>[1, 1, 4, 3, 1, 1], <int>[4, 1, 1, 1, 1, 3], <int>[4, 1, 1, 3, 1, 1], <int>[1, 1, 3, 1, 4, 1],
    <int>[1, 1, 4, 1, 3, 1], <int>[3, 1, 1, 1, 4, 1], <int>[4, 1, 1, 1, 3, 1], <int>[2, 1, 1, 4, 1, 2],
    <int>[2, 1, 1, 2, 1, 4], <int>[2, 1, 1, 2, 3, 2], <int>[2, 3, 3, 1, 1, 1, 2],
  ];

  static const int codeStartA = 103;
  static const int codeStartB = 104;
  static const int codeStartC = 105;
  static const int codeStop = 106;
  static const int codeFnc1 = 102;
  static const int codeFnc2 = 97;
  static const int codeFnc3 = 96;
  static const int codeShift = 98;
  static const int codeCodeA = 101;
  static const int codeCodeB = 100;
  static const int codeCodeC = 99;
}

class UCode128Reader {
  const UCode128Reader();

  U1DResult? decodeRow(UBitArray row) {
    final List<int>? startInfo = _findStartPattern(row);
    if (startInfo == null) return null;
    final int startCode = startInfo[2];

    int codeSet;
    switch (startCode) {
      case UCode128Patterns.codeStartA:
        codeSet = UCode128Patterns.codeCodeA;
        break;
      case UCode128Patterns.codeStartB:
        codeSet = UCode128Patterns.codeCodeB;
        break;
      case UCode128Patterns.codeStartC:
        codeSet = UCode128Patterns.codeCodeC;
        break;
      default:
        return null;
    }

    bool done = false;
    bool isNextShifted = false;
    final StringBuffer result = StringBuffer();
    int lastStart = startInfo[0];
    int nextStart = startInfo[1];
    final Int32List counters = Int32List(6);
    int lastCode = 0;
    int code = 0;
    int checksumTotal = startCode;
    int multiplier = 0;
    bool lastCharacterWasPrintable = true;

    while (!done) {
      final bool unshift = isNextShifted;
      isNextShifted = false;
      lastCode = code;
      try {
        code = _decodeCode(row, counters, nextStart);
      } catch (_) {
        return null;
      }
      lastStart = nextStart;
      for (final int counter in counters) {
        nextStart += counter;
      }

      if (code != UCode128Patterns.codeStop) {
        lastCharacterWasPrintable = true;
        multiplier++;
        checksumTotal += multiplier * code;
      }

      switch (codeSet) {
        case UCode128Patterns.codeCodeA:
          if (code < 64) {
            result.writeCharCode(32 + code);
          } else if (code < 96) {
            result.writeCharCode(code - 64);
          } else {
            if (code != UCode128Patterns.codeStop) lastCharacterWasPrintable = false;
            switch (code) {
              case UCode128Patterns.codeFnc1:
                result.writeCharCode(29);
                break;
              case UCode128Patterns.codeShift:
                isNextShifted = true;
                codeSet = UCode128Patterns.codeCodeB;
                break;
              case UCode128Patterns.codeCodeB:
                codeSet = UCode128Patterns.codeCodeB;
                break;
              case UCode128Patterns.codeCodeC:
                codeSet = UCode128Patterns.codeCodeC;
                break;
              case UCode128Patterns.codeStop:
                done = true;
                break;
            }
          }
          break;
        case UCode128Patterns.codeCodeB:
          if (code < 96) {
            result.writeCharCode(32 + code);
          } else {
            if (code != UCode128Patterns.codeStop) lastCharacterWasPrintable = false;
            switch (code) {
              case UCode128Patterns.codeFnc1:
                result.writeCharCode(29);
                break;
              case UCode128Patterns.codeShift:
                isNextShifted = true;
                codeSet = UCode128Patterns.codeCodeA;
                break;
              case UCode128Patterns.codeCodeA:
                codeSet = UCode128Patterns.codeCodeA;
                break;
              case UCode128Patterns.codeCodeC:
                codeSet = UCode128Patterns.codeCodeC;
                break;
              case UCode128Patterns.codeStop:
                done = true;
                break;
            }
          }
          break;
        case UCode128Patterns.codeCodeC:
          if (code < 100) {
            if (code < 10) result.write("0");
            result.write(code);
          } else {
            if (code != UCode128Patterns.codeStop) lastCharacterWasPrintable = false;
            switch (code) {
              case UCode128Patterns.codeFnc1:
                result.writeCharCode(29);
                break;
              case UCode128Patterns.codeCodeA:
                codeSet = UCode128Patterns.codeCodeA;
                break;
              case UCode128Patterns.codeCodeB:
                codeSet = UCode128Patterns.codeCodeB;
                break;
              case UCode128Patterns.codeStop:
                done = true;
                break;
            }
          }
          break;
      }
      if (unshift) {
        codeSet = codeSet == UCode128Patterns.codeCodeA ? UCode128Patterns.codeCodeB : UCode128Patterns.codeCodeA;
      }
    }

    final int lastPatternSize = nextStart - lastStart;
    nextStart = row.getNextUnset(nextStart);
    if (!row.isRange(nextStart, min(row.size, nextStart + (nextStart - lastStart) ~/ 2), false)) return null;

    checksumTotal -= multiplier * lastCode;
    if (checksumTotal % 103 != lastCode) return null;

    String text = result.toString();
    if (text.isEmpty) return null;
    if (lastCharacterWasPrintable) {
      final int trim = codeSet == UCode128Patterns.codeCodeC ? 2 : 1;
      if (text.length < trim) return null;
      text = text.substring(0, text.length - trim);
    }
    if (text.isEmpty) return null;
    return U1DResult(UCodeFormat.code128, text, (startInfo[1] + startInfo[0]) / 2, lastStart + lastPatternSize / 2);
  }

  static List<int>? _findStartPattern(UBitArray row) {
    final int width = row.size;
    final int rowOffset = row.getNextSet(0);
    int counterPosition = 0;
    final Int32List counters = Int32List(6);
    int patternStart = rowOffset;
    bool isWhite = false;

    for (int i = rowOffset; i < width; i++) {
      if (row.get(i) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == 5) {
          double bestVariance = U1DReader.maxAvgVariance;
          int bestMatch = -1;
          for (int startCode = UCode128Patterns.codeStartA; startCode <= UCode128Patterns.codeStartC; startCode++) {
            final double variance = U1DReader.patternMatchVariance(counters, UCode128Patterns.patterns[startCode], U1DReader.maxIndividualVariance);
            if (variance < bestVariance) {
              bestVariance = variance;
              bestMatch = startCode;
            }
          }
          if (bestMatch >= 0 && row.isRange(max(0, patternStart - (i - patternStart) ~/ 2), patternStart, false)) {
            return <int>[patternStart, i, bestMatch];
          }
          patternStart += counters[0] + counters[1];
          for (int y = 2; y < 6; y++) {
            counters[y - 2] = counters[y];
          }
          counters[4] = 0;
          counters[5] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    return null;
  }

  static int _decodeCode(UBitArray row, Int32List counters, int rowOffset) {
    U1DReader.recordPattern(row, rowOffset, counters);
    double bestVariance = U1DReader.maxAvgVariance;
    int bestMatch = -1;
    for (int d = 0; d < UCode128Patterns.patterns.length; d++) {
      final double variance = U1DReader.patternMatchVariance(counters, UCode128Patterns.patterns[d], U1DReader.maxIndividualVariance);
      if (variance < bestVariance) {
        bestVariance = variance;
        bestMatch = d;
      }
    }
    if (bestMatch < 0) throw const UCodeDecodeException("Unrecognized Code 128 symbol");
    return bestMatch;
  }
}

// -----------------------------------------------------------------------------
// Code 39 / Code 93 / Codabar / ITF
// -----------------------------------------------------------------------------

abstract class UCode39Patterns {
  static const String alphabet = r"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%*";

  static const List<int> characterEncodings = <int>[
    0x034, 0x121, 0x061, 0x160, 0x031, 0x130, 0x070, 0x025, 0x124, 0x064,
    0x109, 0x049, 0x148, 0x019, 0x118, 0x058, 0x00D, 0x10C, 0x04C, 0x01C,
    0x103, 0x043, 0x142, 0x013, 0x112, 0x052, 0x007, 0x106, 0x046, 0x016,
    0x181, 0x0C1, 0x1C0, 0x091, 0x190, 0x0D0, 0x085, 0x184, 0x0C4, 0x0A8,
    0x0A2, 0x08A, 0x02A, 0x094,
  ];

  static const int asteriskEncoding = 0x094;
}

class UCode39Reader {
  const UCode39Reader({this.usingCheckDigit = false, this.extendedMode = false});

  final bool usingCheckDigit;
  final bool extendedMode;

  U1DResult? decodeRow(UBitArray row) {
    final Int32List counters = Int32List(9);
    final List<int>? start = _findAsteriskPattern(row, counters);
    if (start == null) return null;

    int nextStart = row.getNextSet(start[1]);
    final int end = row.size;
    final StringBuffer result = StringBuffer();
    int lastStart;
    String decodedChar;

    do {
      try {
        U1DReader.recordPattern(row, nextStart, counters);
      } catch (_) {
        return null;
      }
      final int pattern = _toNarrowWidePattern(counters);
      if (pattern < 0) return null;
      final int index = UCode39Patterns.characterEncodings.indexOf(pattern);
      if (index < 0) return null;
      decodedChar = UCode39Patterns.alphabet[index];
      result.write(decodedChar);
      lastStart = nextStart;
      for (final int counter in counters) {
        nextStart += counter;
      }
      nextStart = row.getNextSet(nextStart);
    } while (decodedChar != "*" && nextStart < end);

    final String raw = result.toString();
    if (!raw.endsWith("*")) return null;
    String text = raw.substring(0, raw.length - 1);

    int lastPatternSize = 0;
    for (final int counter in counters) {
      lastPatternSize += counter;
    }
    final int whiteSpaceAfterEnd = nextStart - lastStart - lastPatternSize;
    if (nextStart != end && (whiteSpaceAfterEnd * 2) < lastPatternSize) return null;

    if (usingCheckDigit) {
      if (text.isEmpty) return null;
      int total = 0;
      for (int i = 0; i < text.length - 1; i++) {
        total += UCode39Patterns.alphabet.indexOf(text[i]);
      }
      if (text[text.length - 1] != UCode39Patterns.alphabet[total % 43]) return null;
      text = text.substring(0, text.length - 1);
    }
    if (text.isEmpty) return null;
    if (extendedMode) {
      final String? decoded = _decodeExtended(text);
      if (decoded == null) return null;
      text = decoded;
    }
    return U1DResult(UCodeFormat.code39, text, (start[1] + start[0]) / 2, lastStart + lastPatternSize / 2);
  }

  static List<int>? _findAsteriskPattern(UBitArray row, Int32List counters) {
    final int width = row.size;
    final int rowOffset = row.getNextSet(0);
    int counterPosition = 0;
    int patternStart = rowOffset;
    bool isWhite = false;
    counters.fillRange(0, counters.length, 0);

    for (int i = rowOffset; i < width; i++) {
      if (row.get(i) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == 8) {
          if (_toNarrowWidePattern(counters) == UCode39Patterns.asteriskEncoding &&
              row.isRange(max(0, patternStart - ((i - patternStart) ~/ 2)), patternStart, false)) {
            return <int>[patternStart, i];
          }
          patternStart += counters[0] + counters[1];
          for (int y = 2; y < 9; y++) {
            counters[y - 2] = counters[y];
          }
          counters[7] = 0;
          counters[8] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    return null;
  }

  static int _toNarrowWidePattern(Int32List counters) {
    final int numCounters = counters.length;
    int maxNarrowCounter = 0;
    int wideCounters;
    do {
      int minCounter = 1 << 30;
      for (final int counter in counters) {
        if (counter < minCounter && counter > maxNarrowCounter) minCounter = counter;
      }
      maxNarrowCounter = minCounter;
      wideCounters = 0;
      int totalWideCountersWidth = 0;
      int pattern = 0;
      for (int i = 0; i < numCounters; i++) {
        final int counter = counters[i];
        if (counter > maxNarrowCounter) {
          pattern |= 1 << (numCounters - 1 - i);
          wideCounters++;
          totalWideCountersWidth += counter;
        }
      }
      if (wideCounters == 3) {
        for (int i = 0; i < numCounters && wideCounters > 0; i++) {
          final int counter = counters[i];
          if (counter > maxNarrowCounter) {
            wideCounters--;
            if ((counter * 2) >= totalWideCountersWidth) return -1;
          }
        }
        return pattern;
      }
    } while (wideCounters > 3);
    return -1;
  }

  static String? _decodeExtended(String encoded) {
    final StringBuffer decoded = StringBuffer();
    for (int i = 0; i < encoded.length; i++) {
      final String c = encoded[i];
      if (c == "+" || c == "\$" || c == "%" || c == "/") {
        if (i + 1 >= encoded.length) return null;
        final int next = encoded.codeUnitAt(i + 1);
        int decodedChar = 0;
        switch (c) {
          case "+":
            if (next < 65 || next > 90) return null;
            decodedChar = next + 32;
            break;
          case r"$":
            if (next < 65 || next > 90) return null;
            decodedChar = next - 64;
            break;
          case "%":
            if (next >= 65 && next <= 69) {
              decodedChar = next - 38;
            } else if (next >= 70 && next <= 79) {
              decodedChar = next - 11;
            } else if (next >= 83 && next <= 90) {
              decodedChar = 127;
            } else {
              return null;
            }
            break;
          case "/":
            if (next >= 65 && next <= 79) {
              decodedChar = next - 32;
            } else if (next == 90) {
              decodedChar = 58;
            } else {
              return null;
            }
            break;
        }
        decoded.writeCharCode(decodedChar);
        i++;
      } else {
        decoded.write(c);
      }
    }
    return decoded.toString();
  }
}

abstract class UCode93Patterns {
  static const String alphabet = r"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%abcd*";

  static const List<int> characterEncodings = <int>[
    0x114, 0x148, 0x144, 0x142, 0x128, 0x124, 0x122, 0x150, 0x112, 0x10A,
    0x1A8, 0x1A4, 0x1A2, 0x194, 0x192, 0x18A, 0x168, 0x164, 0x162, 0x134,
    0x11A, 0x158, 0x14C, 0x146, 0x12C, 0x116, 0x1B4, 0x1B2, 0x1AC, 0x1A6,
    0x196, 0x19A, 0x16C, 0x166, 0x136, 0x13A, 0x12E, 0x1D4, 0x1D2, 0x1CA,
    0x16E, 0x176, 0x1AE, 0x126, 0x1DA, 0x1D6, 0x132, 0x15E,
  ];

  static const int asteriskEncoding = 0x15E;
}

class UCode93Reader {
  const UCode93Reader();

  U1DResult? decodeRow(UBitArray row) {
    final Int32List counters = Int32List(6);
    final List<int>? start = _findAsteriskPattern(row, counters);
    if (start == null) return null;

    int nextStart = row.getNextSet(start[1]);
    final int end = row.size;
    final StringBuffer result = StringBuffer();
    int lastStart;
    String decodedChar;

    do {
      try {
        U1DReader.recordPattern(row, nextStart, counters);
      } catch (_) {
        return null;
      }
      final int pattern = _toPattern(counters);
      if (pattern < 0) return null;
      final int index = UCode93Patterns.characterEncodings.indexOf(pattern);
      if (index < 0) return null;
      decodedChar = UCode93Patterns.alphabet[index];
      result.write(decodedChar);
      lastStart = nextStart;
      for (final int counter in counters) {
        nextStart += counter;
      }
      nextStart = row.getNextSet(nextStart);
    } while (decodedChar != "*" && nextStart < end);

    String raw = result.toString();
    if (!raw.endsWith("*")) return null;
    raw = raw.substring(0, raw.length - 1);
    if (raw.length < 2) return null;

    if (!_checkChecksum(raw, 20, 15)) return null;
    raw = raw.substring(0, raw.length - 2);
    final String? text = _decodeExtended(raw);
    if (text == null || text.isEmpty) return null;

    int lastPatternSize = 0;
    for (final int counter in counters) {
      lastPatternSize += counter;
    }
    return U1DResult(UCodeFormat.code93, text, (start[1] + start[0]) / 2, lastStart + lastPatternSize / 2);
  }

  static bool _checkChecksum(String result, int maxWeightC, int maxWeightK) {
    if (result.length < 2) return false;
    if (!_checkOneChecksum(result, result.length - 2, maxWeightC)) return false;
    return _checkOneChecksum(result, result.length - 1, maxWeightK);
  }

  static bool _checkOneChecksum(String result, int checkPosition, int weightMax) {
    int weight = 1;
    int total = 0;
    for (int i = checkPosition - 1; i >= 0; i--) {
      total += weight * UCode93Patterns.alphabet.indexOf(result[i]);
      weight++;
      if (weight > weightMax) weight = 1;
    }
    return result[checkPosition] == UCode93Patterns.alphabet[total % 47];
  }

  static List<int>? _findAsteriskPattern(UBitArray row, Int32List counters) {
    final int width = row.size;
    final int rowOffset = row.getNextSet(0);
    int counterPosition = 0;
    int patternStart = rowOffset;
    bool isWhite = false;
    counters.fillRange(0, counters.length, 0);

    for (int i = rowOffset; i < width; i++) {
      if (row.get(i) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == 5) {
          if (_toPattern(counters) == UCode93Patterns.asteriskEncoding) return <int>[patternStart, i];
          patternStart += counters[0] + counters[1];
          for (int y = 2; y < 6; y++) {
            counters[y - 2] = counters[y];
          }
          counters[4] = 0;
          counters[5] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    return null;
  }

  static int _toPattern(Int32List counters) {
    int sum = 0;
    for (final int counter in counters) {
      sum += counter;
    }
    int pattern = 0;
    final int max = counters.length;
    for (int i = 0; i < max; i++) {
      final int scaled = (counters[i] * 9 * 2 + sum) ~/ (2 * sum);
      if (scaled < 1 || scaled > 4) return -1;
      if ((i & 0x01) == 0) {
        for (int j = 0; j < scaled; j++) {
          pattern = (pattern << 1) | 0x01;
        }
      } else {
        pattern <<= scaled;
      }
    }
    return pattern;
  }

  static String? _decodeExtended(String encoded) {
    final StringBuffer decoded = StringBuffer();
    for (int i = 0; i < encoded.length; i++) {
      final String c = encoded[i];
      if (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 100) {
        if (i + 1 >= encoded.length) return null;
        final int next = encoded.codeUnitAt(i + 1);
        int decodedChar = 0;
        switch (c) {
          case "d":
            if (next < 65 || next > 90) return null;
            decodedChar = next + 32;
            break;
          case "a":
            if (next < 65 || next > 90) return null;
            decodedChar = next - 64;
            break;
          case "b":
            if (next >= 65 && next <= 69) {
              decodedChar = next - 38;
            } else if (next >= 70 && next <= 74) {
              decodedChar = next - 11;
            } else if (next >= 75 && next <= 79) {
              decodedChar = next + 16;
            } else if (next >= 80 && next <= 83) {
              decodedChar = next + 43;
            } else if (next >= 84 && next <= 90) {
              decodedChar = 127;
            } else {
              return null;
            }
            break;
          case "c":
            if (next >= 65 && next <= 79) {
              decodedChar = next - 32;
            } else if (next == 90) {
              decodedChar = 58;
            } else {
              return null;
            }
            break;
        }
        decoded.writeCharCode(decodedChar);
        i++;
      } else {
        decoded.write(c);
      }
    }
    return decoded.toString();
  }
}

class UCodabarReader {
  const UCodabarReader();

  static const String _alphabet = r"0123456789-$:/.+ABCD";

  static const List<int> _characterEncodings = <int>[
    0x003, 0x006, 0x009, 0x060, 0x012, 0x042, 0x021, 0x024, 0x030, 0x048,
    0x00c, 0x018, 0x045, 0x051, 0x054, 0x015, 0x01A, 0x029, 0x00B, 0x00E,
  ];

  U1DResult? decodeRow(UBitArray row) {
    final List<int> counters = <int>[];
    final int i = row.getNextUnset(0);
    final int end = row.size;
    int count = 0;
    bool isWhite = true;
    for (int j = i; j < end; j++) {
      if (row.get(j) != isWhite) {
        count++;
      } else {
        counters.add(count);
        count = 1;
        isWhite = !isWhite;
      }
    }
    counters.add(count);
    if (counters.length < 8) return null;

    final Int32List counterArray = Int32List.fromList(counters);
    int startOffset = -1;
    for (int k = 1; k < counters.length; k += 2) {
      final int charOffset = _toNarrowWidePattern(counterArray, k);
      if (charOffset != -1 && _isStartOrEnd(_alphabet[charOffset])) {
        startOffset = k;
        break;
      }
    }
    if (startOffset < 0) return null;

    final StringBuffer result = StringBuffer();
    int nextStart = startOffset;
    do {
      final int charOffset = _toNarrowWidePattern(counterArray, nextStart);
      if (charOffset == -1) return null;
      result.write(_alphabet[charOffset]);
      nextStart += 8;
      if (result.length > 1 && _isStartOrEnd(_alphabet[charOffset])) break;
    } while (nextStart < counters.length);

    String text = result.toString();
    if (text.length < 3) return null;
    if (!_isStartOrEnd(text[0]) || !_isStartOrEnd(text[text.length - 1])) return null;
    text = text.substring(1, text.length - 1);
    if (text.isEmpty) return null;

    double runningCount = 0;
    for (int k = 0; k < startOffset; k++) {
      runningCount += counterArray[k];
    }
    final double left = runningCount;
    for (int k = startOffset; k < nextStart - 1; k++) {
      runningCount += counterArray[k];
    }
    return U1DResult(UCodeFormat.codabar, text, left, runningCount);
  }

  static bool _isStartOrEnd(String value) => value == "A" || value == "B" || value == "C" || value == "D";

  static int _toNarrowWidePattern(Int32List counters, int position) {
    final int end = position + 7;
    if (end >= counters.length) return -1;

    int maxBar = 0;
    int minBar = 1 << 30;
    for (int j = position; j < end; j += 2) {
      final int currentCounter = counters[j];
      if (currentCounter < minBar) minBar = currentCounter;
      if (currentCounter > maxBar) maxBar = currentCounter;
    }
    final int thresholdBar = (minBar + maxBar) ~/ 2;

    int maxSpace = 0;
    int minSpace = 1 << 30;
    for (int j = position + 1; j < end; j += 2) {
      final int currentCounter = counters[j];
      if (currentCounter < minSpace) minSpace = currentCounter;
      if (currentCounter > maxSpace) maxSpace = currentCounter;
    }
    final int thresholdSpace = (minSpace + maxSpace) ~/ 2;

    int bitmask = 1 << 7;
    int pattern = 0;
    for (int i = 0; i < 7; i++) {
      final int threshold = (i & 1) == 0 ? thresholdBar : thresholdSpace;
      bitmask >>= 1;
      if (counters[position + i] > threshold) pattern |= bitmask;
    }
    for (int i = 0; i < _characterEncodings.length; i++) {
      if (_characterEncodings[i] == pattern) return i;
    }
    return -1;
  }
}

class UItfReader {
  const UItfReader();

  static const List<int> _startPattern = <int>[1, 1, 1, 1];
  static const List<List<int>> _patterns = <List<int>>[
    <int>[1, 1, 2, 2, 1],
    <int>[2, 1, 1, 1, 2],
    <int>[1, 2, 1, 1, 2],
    <int>[2, 2, 1, 1, 1],
    <int>[1, 1, 2, 1, 2],
    <int>[2, 1, 2, 1, 1],
    <int>[1, 2, 2, 1, 1],
    <int>[1, 1, 1, 2, 2],
    <int>[2, 1, 1, 2, 1],
    <int>[1, 2, 1, 2, 1],
  ];

  U1DResult? decodeRow(UBitArray row) {
    final List<int>? startRange = _decodeStart(row);
    if (startRange == null) return null;
    final List<int>? endRange = _decodeEnd(row);
    if (endRange == null) return null;

    final StringBuffer result = StringBuffer();
    int payloadStart = startRange[1];
    final int payloadEnd = endRange[0];
    final Int32List counterDigitPair = Int32List(10);
    final Int32List counterBlack = Int32List(5);
    final Int32List counterWhite = Int32List(5);

    while (payloadStart < payloadEnd) {
      try {
        U1DReader.recordPattern(row, payloadStart, counterDigitPair);
      } catch (_) {
        return null;
      }
      for (int k = 0; k < 5; k++) {
        counterBlack[k] = counterDigitPair[k * 2];
        counterWhite[k] = counterDigitPair[k * 2 + 1];
      }
      final int blackDigit = _decodeDigit(counterBlack);
      final int whiteDigit = _decodeDigit(counterWhite);
      if (blackDigit < 0 || whiteDigit < 0) return null;
      result
        ..writeCharCode(48 + blackDigit)
        ..writeCharCode(48 + whiteDigit);
      for (final int counter in counterDigitPair) {
        payloadStart += counter;
      }
    }

    final String text = result.toString();
    if (text.length < 6 || text.length.isOdd) return null;
    return U1DResult(UCodeFormat.itf, text, startRange[1].toDouble(), endRange[0].toDouble());
  }

  static List<int>? _decodeStart(UBitArray row) {
    final int endStart = row.getNextSet(0);
    final List<int>? startPattern = _findGuardPattern(row, endStart, _startPattern);
    if (startPattern == null) return null;
    final int quietCount = (startPattern[1] - startPattern[0]) * 10;
    final int quietStart = max(0, startPattern[0] - quietCount);
    if (!row.isRange(quietStart, startPattern[0], false)) return null;
    return startPattern;
  }

  static List<int>? _decodeEnd(UBitArray row) {
    final UBitArray reversed = row.reversed();
    final int endStart = reversed.getNextSet(0);
    List<int>? endPattern = _findGuardPattern(reversed, endStart, const <int>[1, 1, 2]);
    endPattern ??= _findGuardPattern(reversed, endStart, const <int>[1, 1, 3]);
    if (endPattern == null) return null;
    final int quietCount = (endPattern[1] - endPattern[0]) * 10;
    final int quietStart = max(0, endPattern[0] - quietCount);
    if (!reversed.isRange(quietStart, endPattern[0], false)) return null;
    final int start = reversed.size - endPattern[1];
    final int end = reversed.size - endPattern[0];
    return <int>[start, end];
  }

  static List<int>? _findGuardPattern(UBitArray row, int rowOffset, List<int> pattern) {
    final int patternLength = pattern.length;
    final Int32List counters = Int32List(patternLength);
    final int width = row.size;
    bool isWhite = false;
    int counterPosition = 0;
    int patternStart = rowOffset;

    for (int x = rowOffset; x < width; x++) {
      if (row.get(x) != isWhite) {
        counters[counterPosition]++;
      } else {
        if (counterPosition == patternLength - 1) {
          if (U1DReader.patternMatchVariance(counters, pattern, U1DReader.maxIndividualVariance) < U1DReader.maxAvgVariance) {
            return <int>[patternStart, x];
          }
          patternStart += counters[0] + counters[1];
          for (int y = 2; y < patternLength; y++) {
            counters[y - 2] = counters[y];
          }
          counters[patternLength - 2] = 0;
          counters[patternLength - 1] = 0;
          counterPosition--;
        } else {
          counterPosition++;
        }
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    return null;
  }

  static int _decodeDigit(Int32List counters) {
    double bestVariance = U1DReader.maxAvgVariance;
    int bestMatch = -1;
    for (int i = 0; i < _patterns.length; i++) {
      final double variance = U1DReader.patternMatchVariance(counters, _patterns[i], U1DReader.maxIndividualVariance);
      if (variance < bestVariance) {
        bestVariance = variance;
        bestMatch = i;
      } else if (variance == bestVariance) {
        bestMatch = -1;
      }
    }
    return bestMatch;
  }
}

/// Scans a bit matrix row by row for every enabled linear symbology.
abstract class ULinearScanner {
  static List<UCode> scan(UBitMatrix matrix, UCodeScanOptions options) {
    final Set<UCodeFormat> formats = options.effectiveFormats;
    final bool wantsUpcEan = formats.contains(UCodeFormat.ean13) ||
        formats.contains(UCodeFormat.ean8) ||
        formats.contains(UCodeFormat.upcA) ||
        formats.contains(UCodeFormat.upcE);
    if (!wantsUpcEan &&
        !formats.contains(UCodeFormat.code128) &&
        !formats.contains(UCodeFormat.code39) &&
        !formats.contains(UCodeFormat.code93) &&
        !formats.contains(UCodeFormat.codabar) &&
        !formats.contains(UCodeFormat.itf)) {
      return const <UCode>[];
    }

    final List<UCode> found = <UCode>[];
    final Set<String> seen = <String>{};
    final int height = matrix.height;
    final int middle = height ~/ 2;
    final int rowStep = max(1, height ~/ (options.tryHarder ? 40 : 16));

    for (int pass = 0; pass < (options.tryHarder ? 40 : 16); pass++) {
      final int rowStepsAboveOrBelow = (pass + 1) ~/ 2;
      final bool isAbove = pass.isEven;
      final int rowNumber = middle + rowStep * (isAbove ? rowStepsAboveOrBelow : -rowStepsAboveOrBelow);
      if (rowNumber < 0 || rowNumber >= height) continue;

      final UBitArray row = UBitArray.fromMatrixRow(matrix, rowNumber);
      for (int attempt = 0; attempt < 2; attempt++) {
        final UBitArray candidate = attempt == 0 ? row : row.reversed();
        final List<U1DResult> results = _decodeRow(candidate, formats, wantsUpcEan);
        for (final U1DResult result in results) {
          final String key = "${result.format.name}:${result.text}";
          if (!seen.add(key)) continue;
          final double left = attempt == 0 ? result.start : matrix.width - result.end;
          final double right = attempt == 0 ? result.end : matrix.width - result.start;
          found.add(
            UCode(
              format: result.format,
              text: result.text,
              bytes: Uint8List.fromList(result.text.codeUnits),
              corners: <Offset>[
                Offset(left, rowNumber.toDouble()),
                Offset(right, rowNumber.toDouble()),
                Offset(right, rowNumber.toDouble()),
                Offset(left, rowNumber.toDouble()),
              ],
            ),
          );
          if (!options.multiple) return found;
        }
      }
    }
    return found;
  }

  static List<U1DResult> _decodeRow(UBitArray row, Set<UCodeFormat> formats, bool wantsUpcEan) {
    final List<U1DResult> results = <U1DResult>[];
    if (wantsUpcEan) {
      final U1DResult? ean13 = const UUpcEanReader().decodeRow(row, formats);
      if (ean13 != null) results.add(ean13);
      if (formats.contains(UCodeFormat.ean8)) {
        final U1DResult? ean8 = const UEan8Reader().decodeRow(row);
        if (ean8 != null) results.add(ean8);
      }
      if (formats.contains(UCodeFormat.upcE)) {
        final U1DResult? upcE = const UUpcEReader().decodeRow(row);
        if (upcE != null) results.add(upcE);
      }
    }
    if (formats.contains(UCodeFormat.code128)) {
      final U1DResult? code128 = const UCode128Reader().decodeRow(row);
      if (code128 != null) results.add(code128);
    }
    if (formats.contains(UCodeFormat.code39)) {
      final U1DResult? code39 = const UCode39Reader(extendedMode: true).decodeRow(row) ?? const UCode39Reader().decodeRow(row);
      if (code39 != null) results.add(code39);
    }
    if (formats.contains(UCodeFormat.code93)) {
      final U1DResult? code93 = const UCode93Reader().decodeRow(row);
      if (code93 != null) results.add(code93);
    }
    if (formats.contains(UCodeFormat.codabar)) {
      final U1DResult? codabar = const UCodabarReader().decodeRow(row);
      if (codabar != null) results.add(codabar);
    }
    if (formats.contains(UCodeFormat.itf)) {
      final U1DResult? itf = const UItfReader().decodeRow(row);
      if (itf != null) results.add(itf);
    }
    return results;
  }
}
