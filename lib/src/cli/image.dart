import "dart:io";
import "dart:math" as math;
import "dart:typed_data";

import "package:u/src/cli/core.dart";

/// An sRGB color with 8-bit channels.
class Rgba {
  const Rgba(this.r, this.g, this.b, [this.a = 255]);

  static const Rgba white = Rgba(255, 255, 255);
  static const Rgba black = Rgba(0, 0, 0);
  static const Rgba transparent = Rgba(0, 0, 0, 0);

  /// Parses `#RGB` or `#RRGGBB` (the `#` is optional).
  static Rgba parse(String value) {
    String h = value.trim();
    h = h.startsWith("#") ? h.substring(1) : h;
    if (RegExp(r"^[0-9a-fA-F]{3}$").hasMatch(h)) {
      h = h.split("").map((String c) => "$c$c").join();
    }
    if (!RegExp(r"^[0-9a-fA-F]{6}$").hasMatch(h)) {
      throw CliException("\"$value\" isn't a hex color like #0175C2.");
    }
    return Rgba(int.parse(h.substring(0, 2), radix: 16), int.parse(h.substring(2, 4), radix: 16), int.parse(h.substring(4, 6), radix: 16));
  }

  static bool isColor(String value) => RegExp(r"^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$").hasMatch(value.trim());

  final int r;
  final int g;
  final int b;
  final int a;

  String get hex => "#${<int>[r, g, b].map((int c) => c.toRadixString(16).padLeft(2, "0")).join().toUpperCase()}";

  double get luminance => (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
}

/// An 8-bit RGBA bitmap (not premultiplied), rows top to bottom.
class Bitmap {
  Bitmap(this.width, this.height, [Rgba fill = Rgba.transparent]) : pixels = Uint8List(width * height * 4) {
    if (fill.a != 0 || fill.r != 0 || fill.g != 0 || fill.b != 0) {
      for (int i = 0; i < pixels.length; i += 4) {
        pixels[i] = fill.r;
        pixels[i + 1] = fill.g;
        pixels[i + 2] = fill.b;
        pixels[i + 3] = fill.a;
      }
    }
  }

  Bitmap._(this.width, this.height, this.pixels);

  final int width;
  final int height;
  final Uint8List pixels;

  bool get opaque {
    for (int i = 3; i < pixels.length; i += 4) {
      if (pixels[i] != 255) {
        return false;
      }
    }
    return true;
  }

  /// Reads a PNG file, resolving [path] against the current folder, then the app's root.
  static Bitmap load(Project p, String path) {
    final File f = <File>[File(path), File(p.path(path))].firstWhere((File f) => f.existsSync(), orElse: () => throw CliException("Image not found: $path"));
    if (!f.path.toLowerCase().endsWith(".png")) {
      throw CliException("${f.path} isn't a PNG. Export the image as .png (1024×1024 or larger works best).");
    }
    return decodePng(f.readAsBytesSync(), f.path);
  }

  /// The smallest rectangle that holds every non-transparent pixel, as (left, top, width, height).
  (int, int, int, int) get contentBox {
    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[(y * width + x) * 4 + 3] > 8) {
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }
    return maxX < 0 ? (0, 0, width, height) : (minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  Bitmap crop(int left, int top, int w, int h) {
    final Bitmap out = Bitmap(w, h);
    for (int y = 0; y < h; y++) {
      out.pixels.setRange(y * w * 4, (y + 1) * w * 4, pixels, ((top + y) * width + left) * 4);
    }
    return out;
  }

  /// Resamples to [w]×[h]: area averaging when shrinking, bilinear when growing, in premultiplied alpha.
  Bitmap resize(int w, int h) {
    if (w == width && h == height) {
      return Bitmap._(w, h, Uint8List.fromList(pixels));
    }
    final Float32List src = Float32List(width * height * 4);
    for (int i = 0; i < pixels.length; i += 4) {
      final double a = pixels[i + 3] / 255;
      src[i] = pixels[i] * a;
      src[i + 1] = pixels[i + 1] * a;
      src[i + 2] = pixels[i + 2] * a;
      src[i + 3] = a;
    }
    final Float32List mid = Float32List(w * height * 4);
    final List<_Taps> tx = _taps(width, w);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < w; x++) {
        final _Taps t = tx[x];
        for (int c = 0; c < 4; c++) {
          double s = 0;
          for (int k = 0; k < t.index.length; k++) {
            s += src[(y * width + t.index[k]) * 4 + c] * t.weight[k];
          }
          mid[(y * w + x) * 4 + c] = s;
        }
      }
    }
    final Bitmap out = Bitmap(w, h);
    final List<_Taps> ty = _taps(height, h);
    for (int y = 0; y < h; y++) {
      final _Taps t = ty[y];
      for (int x = 0; x < w; x++) {
        final List<double> v = <double>[0, 0, 0, 0];
        for (int k = 0; k < t.index.length; k++) {
          final int o = (t.index[k] * w + x) * 4;
          for (int c = 0; c < 4; c++) {
            v[c] += mid[o + c] * t.weight[k];
          }
        }
        final int o = (y * w + x) * 4;
        final double a = v[3];
        if (a > 0) {
          out.pixels[o] = (v[0] / a).round().clamp(0, 255);
          out.pixels[o + 1] = (v[1] / a).round().clamp(0, 255);
          out.pixels[o + 2] = (v[2] / a).round().clamp(0, 255);
          out.pixels[o + 3] = (a * 255).round().clamp(0, 255);
        }
      }
    }
    return out;
  }

  /// Scales to fit inside [w]×[h], keeping the aspect ratio.
  Bitmap contain(int w, int h) {
    final double s = math.min(w / width, h / height);
    return resize(math.max(1, (width * s).round()), math.max(1, (height * s).round()));
  }

  /// Draws [img] with its top-left corner at ([left], [top]), alpha blended over this bitmap.
  void draw(Bitmap img, int left, int top) {
    for (int y = 0; y < img.height; y++) {
      final int dy = top + y;
      if (dy < 0 || dy >= height) {
        continue;
      }
      for (int x = 0; x < img.width; x++) {
        final int dx = left + x;
        if (dx < 0 || dx >= width) {
          continue;
        }
        final int s = (y * img.width + x) * 4;
        final int d = (dy * width + dx) * 4;
        final double sa = img.pixels[s + 3] / 255;
        if (sa == 0) {
          continue;
        }
        final double da = pixels[d + 3] / 255;
        final double oa = sa + da * (1 - sa);
        for (int c = 0; c < 3; c++) {
          pixels[d + c] = ((img.pixels[s + c] * sa + pixels[d + c] * da * (1 - sa)) / oa).round().clamp(0, 255);
        }
        pixels[d + 3] = (oa * 255).round().clamp(0, 255);
      }
    }
  }

  /// [img] scaled to fit a [size]×[size] square whose edges keep [inset] (0–0.5 of the side) empty, centered.
  static Bitmap square(Bitmap img, int size, {double inset = 0, Rgba background = Rgba.transparent}) {
    final int box = math.max(1, (size * (1 - inset * 2)).round());
    final Bitmap fitted = img.contain(box, box);
    return Bitmap(size, size, background)..draw(fitted, (size - fitted.width) ~/ 2, (size - fitted.height) ~/ 2);
  }

  /// Every pixel recolored to [color], keeping the alpha (themed / monochrome icons).
  Bitmap tinted(Rgba color) {
    final Bitmap out = Bitmap._(width, height, Uint8List.fromList(pixels));
    for (int i = 0; i < out.pixels.length; i += 4) {
      out.pixels[i] = color.r;
      out.pixels[i + 1] = color.g;
      out.pixels[i + 2] = color.b;
    }
    return out;
  }

  /// A fully opaque copy drawn over [background] (App Store icons must not have alpha).
  Bitmap flatten(Rgba background) => Bitmap(width, height, Rgba(background.r, background.g, background.b))..draw(this, 0, 0);

  Uint8List png() => encodePng(this);
}

class _Taps {
  _Taps(this.index, this.weight);

  final List<int> index;
  final List<double> weight;
}

List<_Taps> _taps(int from, int to) {
  final double scale = from / to;
  return List<_Taps>.generate(to, (int i) {
    if (scale >= 1) {
      final double start = i * scale;
      final double end = start + scale;
      final List<int> index = <int>[];
      final List<double> weight = <double>[];
      for (int j = start.floor(); j < math.min(from, end.ceil()); j++) {
        final double cover = math.min(end, j + 1.0) - math.max(start, j.toDouble());
        if (cover > 0) {
          index.add(j);
          weight.add(cover / scale);
        }
      }
      return _Taps(index, weight);
    }
    final double center = (i + 0.5) * scale - 0.5;
    final int j = center.floor();
    final double t = center - j;
    return _Taps(<int>[j.clamp(0, from - 1), (j + 1).clamp(0, from - 1)], <double>[1 - t, t]);
  });
}

// ---------------------------------------------------------------------------------------------
// PNG

const List<int> _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

final Uint32List _crcTable = Uint32List.fromList(
  List<int>.generate(256, (int n) {
    int c = n;
    for (int k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
    }
    return c;
  }),
);

int crc32(List<int> bytes, [int crc = 0]) {
  int c = crc ^ 0xFFFFFFFF;
  for (final int b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >>> 8);
  }
  return c ^ 0xFFFFFFFF;
}

/// Decodes any standard PNG: gray, RGB, palette, gray+alpha, RGBA; 1–16 bits; interlaced or not.
Bitmap decodePng(Uint8List bytes, String name) {
  for (int i = 0; i < 8; i++) {
    if (bytes.length < 8 || bytes[i] != _pngSignature[i]) {
      throw CliException("$name isn't a valid PNG file.");
    }
  }
  final ByteData view = ByteData.sublistView(bytes);
  int pos = 8;
  int width = 0;
  int height = 0;
  int depth = 0;
  int color = 0;
  int interlace = 0;
  Uint8List? palette;
  Uint8List? trns;
  final BytesBuilder idat = BytesBuilder(copy: false);
  while (pos + 8 <= bytes.length) {
    final int len = view.getUint32(pos);
    final String type = String.fromCharCodes(bytes, pos + 4, pos + 8);
    final Uint8List data = Uint8List.sublistView(bytes, pos + 8, pos + 8 + len);
    pos += 12 + len;
    if (type == "IHDR") {
      final ByteData h = ByteData.sublistView(data);
      width = h.getUint32(0);
      height = h.getUint32(4);
      depth = data[8];
      color = data[9];
      interlace = data[12];
    } else if (type == "PLTE") {
      palette = data;
    } else if (type == "tRNS") {
      trns = data;
    } else if (type == "IDAT") {
      idat.add(data);
    } else if (type == "IEND") {
      break;
    }
  }
  if (width == 0 || height == 0) {
    throw CliException("$name has no image header.");
  }
  final int channels = switch (color) {
    0 => 1,
    2 => 3,
    3 => 1,
    4 => 2,
    6 => 4,
    _ => throw CliException("$name uses an unknown PNG color type $color."),
  };
  final Uint8List raw = Uint8List.fromList(zlib.decode(idat.takeBytes()));
  final Bitmap out = Bitmap(width, height);
  final int bits = channels * depth;
  final int bpp = math.max(1, bits >> 3);
  final int maxValue = (1 << depth) - 1;
  int at = 0;
  final List<List<int>> passes = interlace == 1
      ? <List<int>>[
          <int>[0, 0, 8, 8],
          <int>[4, 0, 8, 8],
          <int>[0, 4, 4, 8],
          <int>[2, 0, 4, 4],
          <int>[0, 2, 2, 4],
          <int>[1, 0, 2, 2],
          <int>[0, 1, 1, 2],
        ]
      : <List<int>>[
          <int>[0, 0, 1, 1],
        ];
  for (final List<int> pass in passes) {
    final int pw = (width - pass[0] + pass[2] - 1) ~/ pass[2];
    final int ph = (height - pass[1] + pass[3] - 1) ~/ pass[3];
    if (pw <= 0 || ph <= 0) {
      continue;
    }
    final int rowBytes = (pw * bits + 7) >> 3;
    Uint8List prev = Uint8List(rowBytes);
    for (int y = 0; y < ph; y++) {
      final int filter = raw[at];
      final Uint8List row = Uint8List.fromList(Uint8List.sublistView(raw, at + 1, at + 1 + rowBytes));
      at += 1 + rowBytes;
      _unfilter(filter, row, prev, bpp);
      prev = row;
      int sample(int i) {
        if (depth == 8) {
          return row[i];
        }
        if (depth == 16) {
          return (row[i * 2] << 8) | row[i * 2 + 1];
        }
        final int bit = i * depth;
        return (row[bit >> 3] >> (8 - depth - (bit & 7))) & maxValue;
      }

      int to8(int v) => depth == 16 ? v >> 8 : (depth == 8 ? v : v * 255 ~/ maxValue);
      for (int x = 0; x < pw; x++) {
        final int o = ((pass[1] + y * pass[3]) * width + pass[0] + x * pass[2]) * 4;
        int r;
        int g;
        int b;
        int a = 255;
        switch (color) {
          case 0:
            final int v = sample(x);
            r = g = b = to8(v);
            if (trns != null && trns.length >= 2 && v == ((trns[0] << 8) | trns[1])) {
              a = 0;
            }
          case 2:
            final int vr = sample(x * 3);
            final int vg = sample(x * 3 + 1);
            final int vb = sample(x * 3 + 2);
            r = to8(vr);
            g = to8(vg);
            b = to8(vb);
            if (trns != null && trns.length >= 6 && vr == ((trns[0] << 8) | trns[1]) && vg == ((trns[2] << 8) | trns[3]) && vb == ((trns[4] << 8) | trns[5])) {
              a = 0;
            }
          case 3:
            final int idx = sample(x);
            if (palette == null || idx * 3 + 2 >= palette.length) {
              throw CliException("$name has a broken palette.");
            }
            r = palette[idx * 3];
            g = palette[idx * 3 + 1];
            b = palette[idx * 3 + 2];
            a = trns != null && idx < trns.length ? trns[idx] : 255;
          case 4:
            r = g = b = to8(sample(x * 2));
            a = to8(sample(x * 2 + 1));
          default:
            r = to8(sample(x * 4));
            g = to8(sample(x * 4 + 1));
            b = to8(sample(x * 4 + 2));
            a = to8(sample(x * 4 + 3));
        }
        out.pixels[o] = r;
        out.pixels[o + 1] = g;
        out.pixels[o + 2] = b;
        out.pixels[o + 3] = a;
      }
    }
  }
  return out;
}

int _paeth(int a, int b, int c) {
  final int p = a + b - c;
  final int pa = (p - a).abs();
  final int pb = (p - b).abs();
  final int pc = (p - c).abs();
  return pa <= pb && pa <= pc ? a : (pb <= pc ? b : c);
}

void _unfilter(int filter, Uint8List row, Uint8List prev, int bpp) {
  for (int i = 0; i < row.length; i++) {
    final int left = i >= bpp ? row[i - bpp] : 0;
    final int up = prev[i];
    final int upLeft = i >= bpp ? prev[i - bpp] : 0;
    row[i] =
        switch (filter) {
          0 => row[i],
          1 => row[i] + left,
          2 => row[i] + up,
          3 => row[i] + ((left + up) >> 1),
          4 => row[i] + _paeth(left, up, upLeft),
          _ => throw CliException("Broken PNG data (filter $filter)."),
        } &
        0xFF;
  }
}

/// Encodes as 8-bit RGBA, or RGB when every pixel is opaque (so App Store icons carry no alpha channel).
Uint8List encodePng(Bitmap img) {
  final bool rgb = img.opaque;
  final int bpp = rgb ? 3 : 4;
  final int rowBytes = img.width * bpp;
  final Uint8List filtered = Uint8List((rowBytes + 1) * img.height);
  Uint8List prev = Uint8List(rowBytes);
  final List<Uint8List> candidates = List<Uint8List>.generate(5, (_) => Uint8List(rowBytes));
  for (int y = 0; y < img.height; y++) {
    final Uint8List row = Uint8List(rowBytes);
    for (int x = 0; x < img.width; x++) {
      final int s = (y * img.width + x) * 4;
      row.setRange(x * bpp, x * bpp + bpp, img.pixels, s);
    }
    int best = 0;
    int bestScore = -1;
    for (int f = 0; f < 5; f++) {
      final Uint8List c = candidates[f];
      int score = 0;
      for (int i = 0; i < rowBytes; i++) {
        final int left = i >= bpp ? row[i - bpp] : 0;
        final int up = prev[i];
        final int upLeft = i >= bpp ? prev[i - bpp] : 0;
        final int v =
            switch (f) {
              0 => row[i],
              1 => row[i] - left,
              2 => row[i] - up,
              3 => row[i] - ((left + up) >> 1),
              _ => row[i] - _paeth(left, up, upLeft),
            } &
            0xFF;
        c[i] = v;
        score += v < 128 ? v : 256 - v;
      }
      if (bestScore < 0 || score < bestScore) {
        bestScore = score;
        best = f;
      }
    }
    final int o = y * (rowBytes + 1);
    filtered[o] = best;
    filtered.setRange(o + 1, o + 1 + rowBytes, candidates[best]);
    prev = row;
  }
  final BytesBuilder out = BytesBuilder(copy: false)..add(_pngSignature);
  void chunk(String type, List<int> data) {
    final Uint8List head = Uint8List(8);
    ByteData.sublistView(head).setUint32(0, data.length);
    head.setRange(4, 8, type.codeUnits);
    final Uint8List crc = Uint8List(4);
    ByteData.sublistView(crc).setUint32(0, crc32(data, crc32(type.codeUnits)));
    out
      ..add(head)
      ..add(data)
      ..add(crc);
  }

  final Uint8List ihdr = Uint8List(13);
  ByteData.sublistView(ihdr)
    ..setUint32(0, img.width)
    ..setUint32(4, img.height);
  ihdr[8] = 8;
  ihdr[9] = rgb ? 2 : 6;
  chunk("IHDR", ihdr);
  chunk("IDAT", ZLibEncoder(level: 9).convert(filtered));
  chunk("IEND", const <int>[]);
  return out.takeBytes();
}

// ---------------------------------------------------------------------------------------------
// ICO (Windows)

/// A Windows .ico holding every size: 256 as PNG, smaller ones as 32-bit bitmaps for old readers.
Uint8List encodeIco(Bitmap source, List<int> sizes) {
  final List<(int, Uint8List)> images = <(int, Uint8List)>[];
  for (final int size in sizes) {
    final Bitmap img = Bitmap.square(source, size);
    images.add((size, size >= 256 ? img.png() : _dib(img)));
  }
  final BytesBuilder out = BytesBuilder(copy: false);
  final ByteData head = ByteData(6 + 16 * images.length)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, images.length, Endian.little);
  int offset = head.lengthInBytes;
  for (int i = 0; i < images.length; i++) {
    final (int size, Uint8List data) = images[i];
    final int e = 6 + i * 16;
    head
      ..setUint8(e, size >= 256 ? 0 : size)
      ..setUint8(e + 1, size >= 256 ? 0 : size)
      ..setUint16(e + 4, 1, Endian.little)
      ..setUint16(e + 6, 32, Endian.little)
      ..setUint32(e + 8, data.length, Endian.little)
      ..setUint32(e + 12, offset, Endian.little);
    offset += data.length;
  }
  out.add(head.buffer.asUint8List());
  for (final (int _, Uint8List data) in images) {
    out.add(data);
  }
  return out.takeBytes();
}

Uint8List _dib(Bitmap img) {
  final int w = img.width;
  final int h = img.height;
  final int maskRow = ((w + 31) ~/ 32) * 4;
  final ByteData d = ByteData(40 + w * h * 4 + maskRow * h)
    ..setUint32(0, 40, Endian.little)
    ..setInt32(4, w, Endian.little)
    ..setInt32(8, h * 2, Endian.little)
    ..setUint16(12, 1, Endian.little)
    ..setUint16(14, 32, Endian.little)
    ..setUint32(20, w * h * 4 + maskRow * h, Endian.little);
  int o = 40;
  for (int y = h - 1; y >= 0; y--) {
    for (int x = 0; x < w; x++) {
      final int s = (y * w + x) * 4;
      d
        ..setUint8(o++, img.pixels[s + 2])
        ..setUint8(o++, img.pixels[s + 1])
        ..setUint8(o++, img.pixels[s])
        ..setUint8(o++, img.pixels[s + 3]);
    }
  }
  for (int y = h - 1; y >= 0; y--) {
    for (int x = 0; x < w; x++) {
      if (img.pixels[(y * w + x) * 4 + 3] == 0) {
        final int at = o + (x >> 3);
        d.setUint8(at, d.getUint8(at) | (0x80 >> (x & 7)));
      }
    }
    o += maskRow;
  }
  return d.buffer.asUint8List();
}
