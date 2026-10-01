import "dart:math" as math;
import "dart:ui" as ui;

import "package:u/utilities.dart";

/// Elevation, hillshade and contour lines from Terrarium elevation tiles (free AWS open data by default), computed in Dart.
abstract final class UMapTerrain {
  /// Where elevation tiles come from (any Terrarium-encoded source, e.g. your own pmtiles).
  static UMapTileSource source = UMapTileSource.terrarium;

  static final ULruCache<String, Float32List> _grids = ULruCache<String, Float32List>(maxBytes: 64 * 1024 * 1024, sizeOf: (Float32List g) => g.lengthInBytes);
  static final Map<String, Future<Float32List?>> _pending = <String, Future<Float32List?>>{};

  /// 256×256 elevations (metres) of a native DEM tile.
  static Future<Float32List?> _native(int z, int x, int y) {
    final String key = "${source.id}/$z/$x/$y";
    final Float32List? hot = _grids.get(key);
    if (hot != null) return SynchronousFuture<Float32List?>(hot);
    return _pending[key] ??= () async {
      try {
        final Uint8List? png = await UMapTiles.load(source, z, x, y);
        if (png == null) return null;
        final ui.Codec codec = await ui.instantiateImageCodec(png);
        final ui.Image image = (await codec.getNextFrame()).image;
        final ByteData? rgba = await image.toByteData();
        final int w = image.width;
        final int h = image.height;
        image.dispose();
        if (rgba == null) return null;
        final Float32List grid = Float32List(256 * 256);
        for (int j = 0; j < 256; j++) {
          for (int i = 0; i < 256; i++) {
            final int o = ((j * h ~/ 256) * w + (i * w ~/ 256)) * 4;
            grid[j * 256 + i] = rgba.getUint8(o) * 256.0 + rgba.getUint8(o + 1) + rgba.getUint8(o + 2) / 256.0 - 32768.0;
          }
        }
        _grids.put(key, grid);
        return grid;
      } on Object {
        return null;
      } finally {
        unawaited(_pending.remove(key));
      }
    }();
  }

  /// 256×256 elevations for any tile; deeper than the source's max zoom it is resampled (bilinear) from the ancestor.
  static Future<Float32List?> grid(int z, int x, int y) async {
    final int nz = math.min(z, source.maxNativeZoom);
    if (nz == z) return _native(z, x, y);
    final int shift = z - nz;
    final int scale = 1 << shift;
    final Float32List? parent = await _native(nz, x >> shift, y >> shift);
    if (parent == null) return null;
    final double ox = (x - (x >> shift) * scale) * 256 / scale;
    final double oy = (y - (y >> shift) * scale) * 256 / scale;
    final Float32List out = Float32List(256 * 256);
    for (int j = 0; j < 256; j++) {
      for (int i = 0; i < 256; i++) {
        out[j * 256 + i] = _bilinear(parent, ox + i / scale, oy + j / scale);
      }
    }
    return out;
  }

  static double _bilinear(Float32List g, double x, double y) {
    final int x0 = x.floor().clamp(0, 255);
    final int y0 = y.floor().clamp(0, 255);
    final int x1 = math.min(255, x0 + 1);
    final int y1 = math.min(255, y0 + 1);
    final double fx = (x - x0).clamp(0, 1);
    final double fy = (y - y0).clamp(0, 1);
    final double a = g[y0 * 256 + x0] * (1 - fx) + g[y0 * 256 + x1] * fx;
    final double b = g[y1 * 256 + x0] * (1 - fx) + g[y1 * 256 + x1] * fx;
    return a * (1 - fy) + b * fy;
  }

  /// Ground elevation in metres at a point (null offline without data). [zoom] 10–15 trades detail for fewer downloads.
  static Future<double?> elevationAt(LatLng p, {int zoom = 13}) async {
    final int z = math.min(zoom, source.maxNativeZoom);
    final UTileId t = UGeoCodes.tileOf(p, z);
    final Float32List? g = await _native(z, t.x, t.y);
    if (g == null) return null;
    final Offset m = UGeoMath.toMercator(p);
    final Offset m0 = UGeoMath.toMercator(UGeoCodes.tileCorner(z, t.x, t.y));
    final Offset m1 = UGeoMath.toMercator(UGeoCodes.tileCorner(z, t.x + 1, t.y + 1));
    return _bilinear(g, (m.dx - m0.dx) / (m1.dx - m0.dx) * 255, (m.dy - m0.dy) / (m1.dy - m0.dy) * 255);
  }

  /// Elevation profile along a path: [samples] (distance from start in metres, elevation) pairs.
  static Future<List<(double distance, double elevation)>> profile(List<LatLng> path, {int samples = 120, int zoom = 13}) async {
    final double total = UGeoMath.length(path);
    if (path.isEmpty) return <(double, double)>[];
    final List<(double, double)> out = <(double, double)>[];
    for (int i = 0; i <= samples; i++) {
      final double d = total * i / samples;
      final double? e = await elevationAt(UGeoMath.along(path, d), zoom: zoom);
      if (e != null) out.add((d, e));
    }
    return out;
  }

  /// Climb, descent, min and max of a profile (small noise below [threshold] metres ignored).
  static ({double gain, double loss, double min, double max}) stats(List<(double, double)> profile, {double threshold = 2}) {
    double gain = 0;
    double loss = 0;
    double low = double.infinity;
    double high = -double.infinity;
    double? ref;
    for (final (double _, double e) in profile) {
      low = math.min(low, e);
      high = math.max(high, e);
      if (ref == null) {
        ref = e;
      } else if ((e - ref).abs() >= threshold) {
        if (e > ref) {
          gain += e - ref;
        } else {
          loss += ref - e;
        }
        ref = e;
      }
    }
    return (gain: gain, loss: loss, min: low.isFinite ? low : 0, max: high.isFinite ? high : 0);
  }

  /// Hillshade RGBA pixels of a grid (dark shadows, light highlights, transparent flats). Runs in an isolate via [compute].
  static Uint8List shade((Float32List, double cellSize, double azimuth, double altitude, double exaggeration, double strength) args) {
    final (Float32List g, double cell, double azimuth, double altitude, double ex, double strength) = args;
    final Uint8List out = Uint8List(256 * 256 * 4);
    final double zenith = (90 - altitude) * math.pi / 180;
    double azMath = 360 - azimuth + 90;
    if (azMath >= 360) azMath -= 360;
    final double az = azMath * math.pi / 180;
    final double flat = math.cos(zenith);
    double at(int i, int j) => g[j.clamp(0, 255) * 256 + i.clamp(0, 255)];
    for (int j = 0; j < 256; j++) {
      for (int i = 0; i < 256; i++) {
        final double a = at(i - 1, j - 1);
        final double b = at(i, j - 1);
        final double c = at(i + 1, j - 1);
        final double d = at(i - 1, j);
        final double f = at(i + 1, j);
        final double gg = at(i - 1, j + 1);
        final double h = at(i, j + 1);
        final double k = at(i + 1, j + 1);
        final double dzdx = ((c + 2 * f + k) - (a + 2 * d + gg)) / (8 * cell) * ex;
        final double dzdy = ((gg + 2 * h + k) - (a + 2 * b + c)) / (8 * cell) * ex;
        final double slope = math.atan(math.sqrt(dzdx * dzdx + dzdy * dzdy));
        double aspect;
        if (dzdx != 0) {
          aspect = math.atan2(dzdy, -dzdx);
          if (aspect < 0) aspect += 2 * math.pi;
        } else {
          aspect = dzdy > 0 ? math.pi / 2 : (dzdy < 0 ? 3 * math.pi / 2 : 0);
        }
        final double hs = math.cos(zenith) * math.cos(slope) + math.sin(zenith) * math.sin(slope) * math.cos(az - aspect);
        final int o = (j * 256 + i) * 4;
        if (hs < flat) {
          out[o + 3] = ((flat - hs) / flat * 255 * strength).round().clamp(0, 255);
        } else {
          out[o] = 255;
          out[o + 1] = 255;
          out[o + 2] = 255;
          out[o + 3] = ((hs - flat) / (1 - flat) * 160 * strength).round().clamp(0, 255);
        }
      }
    }
    return out;
  }

  /// Contour line segments (in 0..256 grid units) at every [interval] metres, via marching squares. Index lines (every 5th) are flagged.
  static List<(Offset, Offset, bool index)> contours(Float32List g, double interval, {int step = 2}) {
    final List<(Offset, Offset, bool)> out = <(Offset, Offset, bool)>[];
    double lo = double.infinity;
    double hi = -double.infinity;
    for (final double v in g) {
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }
    if (!lo.isFinite || hi - lo < interval / 4) return out;
    for (double level = (lo / interval).ceil() * interval; level <= hi; level += interval) {
      final bool index = ((level / interval).round() % 5) == 0;
      for (int j = 0; j + step < 256; j += step) {
        for (int i = 0; i + step < 256; i += step) {
          final double tl = g[j * 256 + i];
          final double tr = g[j * 256 + i + step];
          final double br = g[(j + step) * 256 + i + step];
          final double bl = g[(j + step) * 256 + i];
          final int code = (tl > level ? 8 : 0) | (tr > level ? 4 : 0) | (br > level ? 2 : 0) | (bl > level ? 1 : 0);
          if (code == 0 || code == 15) continue;
          double t(double a, double b) => a == b ? 0.5 : (level - a) / (b - a);
          final Offset top = Offset(i + t(tl, tr) * step, j.toDouble());
          final Offset right = Offset((i + step).toDouble(), j + t(tr, br) * step);
          final Offset bottom = Offset(i + t(bl, br) * step, (j + step).toDouble());
          final Offset left = Offset(i.toDouble(), j + t(tl, bl) * step);
          switch (code) {
            case 1:
            case 14:
              out.add((left, bottom, index));
            case 2:
            case 13:
              out.add((bottom, right, index));
            case 3:
            case 12:
              out.add((left, right, index));
            case 4:
            case 11:
              out.add((top, right, index));
            case 5:
              out
                ..add((left, top, index))
                ..add((bottom, right, index));
            case 6:
            case 9:
              out.add((top, bottom, index));
            case 7:
            case 8:
              out.add((left, top, index));
            case 10:
              out
                ..add((left, bottom, index))
                ..add((top, right, index));
          }
        }
      }
    }
    return out;
  }

  /// Contour interval in metres that suits a zoom.
  static double intervalFor(int z) => z <= 9 ? 200 : (z <= 11 ? 100 : (z <= 13 ? 50 : (z <= 15 ? 20 : 10)));

  /// Hillshade map layer (draw above a base map). [strength] 0..1.
  static TileLayer hillshadeLayer({double azimuth = 315, double altitude = 45, double exaggeration = 1.5, double strength = 0.6}) => TileLayer(
    tileProvider: _TerrainProvider(_TerrainKind.hillshade, azimuth: azimuth, altitude: altitude, exaggeration: exaggeration, strength: strength),
    maxNativeZoom: 18,
    maxZoom: 22,
    userAgentPackageName: UMapTiles.userAgent,
  );

  /// Contour lines layer with labels on index lines; [color] for the lines.
  static TileLayer contourLayer({Color color = const Color(0xFF8B6B4A), int minZoom = 10}) => TileLayer(
    tileProvider: _TerrainProvider(_TerrainKind.contours, color: color),
    minZoom: minZoom.toDouble(),
    maxNativeZoom: 18,
    maxZoom: 22,
    userAgentPackageName: UMapTiles.userAgent,
  );
}

enum _TerrainKind { hillshade, contours }

class _TerrainProvider extends TileProvider {
  _TerrainProvider(this.kind, {this.azimuth = 315, this.altitude = 45, this.exaggeration = 1.5, this.strength = 0.6, this.color = const Color(0xFF8B6B4A)});

  final _TerrainKind kind;
  final double azimuth;
  final double altitude;
  final double exaggeration;
  final double strength;
  final Color color;

  /// Identity of the look, so equal settings share cached images.
  String get key => "${kind.name}|$azimuth|$altitude|$exaggeration|$strength|${color.toARGB32()}|${UMapTerrain.source.id}";

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => _TerrainImage(this, coordinates.z, coordinates.x, coordinates.y);
}

@immutable
class _TerrainImage extends ImageProvider<_TerrainImage> {
  const _TerrainImage(this.p, this.z, this.x, this.y);

  final _TerrainProvider p;
  final int z;
  final int x;
  final int y;

  @override
  Future<_TerrainImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture<_TerrainImage>(this);

  @override
  ImageStreamCompleter loadImage(_TerrainImage key, ImageDecoderCallback decode) => OneFrameImageStreamCompleter(_load());

  Future<ImageInfo> _load() async {
    final Float32List? g = await UMapTerrain.grid(z, x, y);
    if (g == null) throw StateError("No elevation for $z/$x/$y");
    if (p.kind == _TerrainKind.hillshade) {
      final double lat = UGeoCodes.tileBounds(UTileId(z, x, y)).center.latitude;
      final double cell = UGeoCodes.metersPerPixel(lat, z.toDouble());
      final Uint8List rgba = await compute(UMapTerrain.shade, (g, cell, p.azimuth, p.altitude, p.exaggeration, p.strength));
      final Completer<ui.Image> done = Completer<ui.Image>();
      ui.decodeImageFromPixels(rgba, 256, 256, ui.PixelFormat.rgba8888, done.complete);
      return ImageInfo(image: await done.future);
    }
    final double interval = UMapTerrain.intervalFor(z);
    final List<(Offset, Offset, bool)> segments = await compute(_contours, (g, interval));
    const double size = 512;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint thin = Paint()
      ..color = p.color.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final Paint thick = Paint()
      ..color = p.color.withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final Path thinPath = Path();
    final Path thickPath = Path();
    for (final (Offset a, Offset b, bool index) in segments) {
      (index ? thickPath : thinPath)
        ..moveTo(a.dx * 2, a.dy * 2)
        ..lineTo(b.dx * 2, b.dy * 2);
    }
    canvas
      ..drawPath(thinPath, thin)
      ..drawPath(thickPath, thick);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    picture.dispose();
    return ImageInfo(image: image, scale: 2);
  }

  static List<(Offset, Offset, bool)> _contours((Float32List, double) a) => UMapTerrain.contours(a.$1, a.$2);

  @override
  bool operator ==(Object other) => other is _TerrainImage && other.p.key == p.key && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(p.key, z, x, y);
}
