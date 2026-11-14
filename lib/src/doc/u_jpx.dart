import "dart:typed_data";

import "package:u/utilities.dart";

/// Decoded JPEG 2000 samples: 8 bits per component, interleaved, components in file order.
class UJpxImage {
  const UJpxImage({required this.width, required this.height, required this.components, required this.data, this.colorChannels});

  final int width;
  final int height;
  final int components;
  final Uint8List data;

  /// Color channels of the JP2 color space (1 gray, 3 RGB, 4 CMYK); further channels are alpha. Null for a bare codestream.
  final int? colorChannels;
}

/// Internal: JPEG 2000 decoder for PDF images (JPXDecode): JP2 files and raw codestreams,
/// 5/3 and 9/7 wavelets, every progression order, multiple tiles and layers, palettes.
abstract class UJpx {
  /// [palette] applies a JP2 palette (pclr); a PDF that names its own color space (e.g. /Indexed) wants the
  /// raw indices instead.
  static UJpxImage? decode(Uint8List bytes, {bool palette = true}) {
    try {
      return _UJpxDecoder(bytes, applyPalette: palette).run();
    } on Object {
      return null;
    }
  }

  /// Number of components without decoding (null when unknown).
  static int? components(Uint8List bytes) {
    try {
      final _UJpxDecoder decoder = _UJpxDecoder(bytes);
      final (int, int)? codestream = decoder._locateCodestream();
      if (codestream == null) return null;
      if (decoder._palette != null) return decoder._palette!.length;
      int offset = codestream.$1;
      while (offset + 4 < codestream.$2) {
        final int marker = (bytes[offset] << 8) | bytes[offset + 1];
        if (marker == 0xFF51) return (bytes[offset + 38] << 8) | bytes[offset + 39];
        offset += marker == 0xFF4F ? 2 : 2 + ((bytes[offset + 2] << 8) | bytes[offset + 3]);
      }
      return null;
    } on Object {
      return null;
    }
  }
}

class _UJpxComponent {
  _UJpxComponent(this.precision, this.signed, this.dx, this.dy);

  final int precision;
  final bool signed;
  final int dx;
  final int dy;
  _UJpxCoding? coding;
  _UJpxQuant? quant;
}

class _UJpxCoding {
  int levels = 5;
  int blockWidth = 6;
  int blockHeight = 6;
  int style = 0;
  bool reversible = true;
  List<int> precincts = const <int>[];

  _UJpxCoding copy() => _UJpxCoding()
    ..levels = levels
    ..blockWidth = blockWidth
    ..blockHeight = blockHeight
    ..style = style
    ..reversible = reversible
    ..precincts = precincts;

  int precinctWidth(int resolution) => resolution < precincts.length ? precincts[resolution] & 15 : 15;

  int precinctHeight(int resolution) => resolution < precincts.length ? precincts[resolution] >> 4 : 15;
}

class _UJpxQuant {
  int guard = 2;
  int style = 0;
  List<int> exponents = <int>[];
  List<int> mantissas = <int>[];

  (int, int) stepOf(int index, int levels) {
    if (style == 1) {
      // Scalar derived: every subband follows from the LL value.
      final int n = index == 0 ? levels : levels - (index - 1) ~/ 3;
      final int exponent = exponents.isEmpty ? 0 : exponents[0] - levels + n;
      return (exponent, mantissas.isEmpty ? 0 : mantissas[0]);
    }
    final int safe = min(index, exponents.length - 1);
    return (safe < 0 ? 0 : exponents[safe], safe < 0 || safe >= mantissas.length ? 0 : mantissas[safe]);
  }
}

class _UJpxCodeBlock {
  _UJpxCodeBlock(this.x0, this.y0, this.x1, this.y1, this.gridX, this.gridY);

  final int x0;
  final int y0;
  final int x1;
  final int y1;
  final int gridX;
  final int gridY;
  bool? included;
  int zeroPlanes = 0;
  int lengthBits = 3;
  int passes = 0;
  final List<Uint8List> chunks = <Uint8List>[];
}

class _UJpxSubband {
  _UJpxSubband(this.kind, this.x0, this.y0, this.x1, this.y1);

  /// 0 = LL, 1 = HL, 2 = LH, 3 = HH.
  final int kind;
  final int x0;
  final int y0;
  final int x1;
  final int y1;
  int blockWidth = 6;
  int blockHeight = 6;
  double step = 1;
  int bitPlanes = 0;
  final List<_UJpxCodeBlock> blocks = <_UJpxCodeBlock>[];

  int get width => x1 - x0;

  int get height => y1 - y0;
}

class _UJpxPrecinct {
  _UJpxPrecinct(this.bands);

  final List<_UJpxPrecinctBand> bands;
}

class _UJpxPrecinctBand {
  _UJpxPrecinctBand(this.band, this.blocks, this.minX, this.minY, this.columns, this.rows)
    : inclusion = _UJpxInclusionTree(max(columns, 1), max(rows, 1)),
      zeroPlanes = _UJpxTagTree(max(columns, 1), max(rows, 1));

  final _UJpxSubband band;
  final List<_UJpxCodeBlock> blocks;
  final int minX;
  final int minY;
  final int columns;
  final int rows;
  final _UJpxInclusionTree inclusion;
  final _UJpxTagTree zeroPlanes;
}

class _UJpxResolution {
  _UJpxResolution(this.x0, this.y0, this.x1, this.y1, this.precinctWidth, this.precinctHeight);

  final int x0;
  final int y0;
  final int x1;
  final int y1;
  final int precinctWidth;
  final int precinctHeight;
  final List<_UJpxSubband> bands = <_UJpxSubband>[];
  int precinctsWide = 0;
  int precinctsHigh = 0;
  List<_UJpxPrecinct?> precincts = <_UJpxPrecinct?>[];
}

class _UJpxTileComponent {
  _UJpxTileComponent(this.x0, this.y0, this.x1, this.y1, this.coding);

  final int x0;
  final int y0;
  final int x1;
  final int y1;
  final _UJpxCoding coding;
  final List<_UJpxResolution> resolutions = <_UJpxResolution>[];
}

class _UJpxTile {
  _UJpxTile(this.index, this.x0, this.y0, this.x1, this.y1);

  final int index;
  final int x0;
  final int y0;
  final int x1;
  final int y1;
  final List<Uint8List> parts = <Uint8List>[];
  _UJpxCoding? coding;
  final Map<int, _UJpxCoding> componentCoding = <int, _UJpxCoding>{};
  final Map<int, _UJpxQuant> componentQuant = <int, _UJpxQuant>{};
  _UJpxQuant? quant;
  int? progression;
  int? layers;
  int? mct;
  int? codingStyle;
}

class _UJpxTagTree {
  _UJpxTagTree(int width, int height) {
    int w = width;
    int h = height;
    while (true) {
      _widths.add(w);
      _items.add(List<int?>.filled(w * h, null));
      if (w == 1 && h == 1) break;
      w = (w + 1) >> 1;
      h = (h + 1) >> 1;
    }
    _indices = List<int>.filled(_items.length, 0);
  }

  final List<int> _widths = <int>[];
  final List<List<int?>> _items = <List<int?>>[];
  late List<int> _indices;
  int _level = 0;
  int value = 0;

  void reset(int i, int j) {
    int level = 0;
    int found = 0;
    while (level < _items.length) {
      final int index = i + j * _widths[level];
      final int? item = _items[level][index];
      if (item != null) {
        found = item;
        break;
      }
      _indices[level] = index;
      i >>= 1;
      j >>= 1;
      level++;
    }
    if (level == 0) {
      _indices[0] = i;
      _level = 0;
      value = found;
      return;
    }
    level--;
    _items[level][_indices[level]] = found;
    _level = level;
  }

  void increment() => _items[_level][_indices[_level]] = (_items[_level][_indices[_level]] ?? 0) + 1;

  bool nextLevel() {
    final int current = _items[_level][_indices[_level]] ?? 0;
    if (_level == 0) {
      value = current;
      return false;
    }
    _level--;
    _items[_level][_indices[_level]] = current;
    return true;
  }
}

class _UJpxInclusionTree {
  _UJpxInclusionTree(int width, int height) {
    int w = width;
    int h = height;
    while (true) {
      _widths.add(w);
      _items.add(Uint8List(w * h));
      if (w == 1 && h == 1) break;
      w = (w + 1) >> 1;
      h = (h + 1) >> 1;
    }
    _indices = List<int>.filled(_items.length, 0);
  }

  final List<int> _widths = <int>[];
  final List<Uint8List> _items = <Uint8List>[];
  late List<int> _indices;
  int _level = 0;

  bool reset(int i, int j, int stop) {
    int level = 0;
    while (level < _items.length) {
      final int index = i + j * _widths[level];
      _indices[level] = index;
      final int value = _items[level][index];
      if (value == 0xFF) break;
      if (value > stop) {
        _level = level;
        _propagate();
        return false;
      }
      i >>= 1;
      j >>= 1;
      level++;
    }
    _level = max(level - 1, 0);
    return true;
  }

  void increment(int stop) {
    _items[_level][_indices[_level]] = min(stop + 1, 0xFE);
    _propagate();
  }

  void _propagate() {
    final int value = _items[_level][_indices[_level]];
    for (int level = _level - 1; level >= 0; level--) {
      _items[level][_indices[level]] = value;
    }
  }

  bool nextLevel() {
    final int value = _items[_level][_indices[_level]];
    _items[_level][_indices[_level]] = 0xFF;
    if (_level == 0) return false;
    _level--;
    _items[_level][_indices[_level]] = value;
    return true;
  }
}

class _UJpxDecoder {
  _UJpxDecoder(this._data, {this.applyPalette = true});

  final Uint8List _data;
  final bool applyPalette;
  int _width = 0;
  int _height = 0;
  int _x0 = 0;
  int _y0 = 0;
  int _tileWidth = 0;
  int _tileHeight = 0;
  int _tileX0 = 0;
  int _tileY0 = 0;
  final List<_UJpxComponent> _components = <_UJpxComponent>[];
  _UJpxCoding _coding = _UJpxCoding();
  _UJpxQuant _quant = _UJpxQuant();
  int _progression = 0;
  int _layers = 1;
  int _mct = 0;
  int _codingStyle = 0;
  final Map<int, _UJpxTile> _tiles = <int, _UJpxTile>{};

  /// Palette (pclr box): output components, each a list of entries.
  List<List<int>>? _palette;
  List<int> _paletteBits = const <int>[];
  int? _colorChannels;

  static const int _contexts = 19;
  static const int _runContext = 17;
  static const int _uniformContext = 18;

  (int, int)? _locateCodestream() {
    if (_data.length > 2 && _data[0] == 0xFF && _data[1] == 0x4F) return (0, _data.length);
    int offset = 0;
    while (offset + 8 <= _data.length) {
      int length = _u32(offset);
      final int type = _u32(offset + 4);
      int header = 8;
      if (length == 1) {
        length = _u32(offset + 12) + (_u32(offset + 8) << 32);
        header = 16;
      } else if (length == 0) {
        length = _data.length - offset;
      }
      if (length < header) return null;
      if (type == 0x6A703268) _readHeaderBoxes(offset + header, min(offset + length, _data.length));
      if (type == 0x6A703263) return (offset + header, min(offset + length, _data.length));
      offset += length;
    }
    return null;
  }

  void _readHeaderBoxes(int start, int end) {
    int offset = start;
    while (offset + 8 <= end) {
      final int length = _u32(offset);
      final int type = _u32(offset + 4);
      if (length < 8) return;
      if (type == 0x636F6C72 && _colorChannels == null) {
        final int method = _data[offset + 8];
        if (method == 1) {
          final int space = _u32(offset + 11);
          _colorChannels = space == 17 ? 1 : (space == 12 || space == 13 ? 4 : (space == 16 || space == 18 || space == 20 || space == 21 ? 3 : null));
        } else if ((method == 2 || method == 3) && offset + 31 <= end) {
          // An ICC profile: its header names the color space.
          final int space = _u32(offset + 11 + 16);
          _colorChannels = space == 0x47524159 ? 1 : (space == 0x434D594B ? 4 : (space == 0x52474220 ? 3 : null));
        }
      }
      if (type == 0x70636C72) {
        final int entries = (_data[offset + 8] << 8) | _data[offset + 9];
        final int columns = _data[offset + 10];
        final List<int> bits = <int>[];
        for (int c = 0; c < columns; c++) {
          bits.add((_data[offset + 11 + c] & 0x7F) + 1);
        }
        final List<List<int>> palette = List<List<int>>.generate(columns, (int _) => <int>[]);
        int position = offset + 11 + columns;
        for (int e = 0; e < entries; e++) {
          for (int c = 0; c < columns; c++) {
            final int bytes = (bits[c] + 7) >> 3;
            int value = 0;
            for (int b = 0; b < bytes; b++) {
              value = (value << 8) | _data[position++];
            }
            palette[c].add(value);
          }
        }
        _palette = palette;
        _paletteBits = bits;
      }
      offset += length;
    }
  }

  int _u16(int offset) => (_data[offset] << 8) | _data[offset + 1];

  int _u32(int offset) => (_data[offset] << 24) | (_data[offset + 1] << 16) | (_data[offset + 2] << 8) | _data[offset + 3];

  UJpxImage? run() {
    final (int, int)? range = _locateCodestream();
    if (range == null) return null;
    _parse(range.$1, range.$2);
    if (_width <= 0 || _height <= 0 || _components.isEmpty) return null;
    final int count = _components.length;
    final List<Float32List> planes = <Float32List>[];
    final List<int> planeWidths = <int>[];
    final List<int> planeHeights = <int>[];
    for (final _UJpxComponent component in _components) {
      final int w = (_width / component.dx).ceil() - (_x0 / component.dx).ceil();
      final int h = (_height / component.dy).ceil() - (_y0 / component.dy).ceil();
      planes.add(Float32List(max(w, 0) * max(h, 0)));
      planeWidths.add(w);
      planeHeights.add(h);
    }
    final List<int> keys = _tiles.keys.toList()..sort();
    for (final int key in keys) {
      _decodeTile(_tiles[key]!, planes, planeWidths);
    }
    return _output(planes, planeWidths, planeHeights, count);
  }

  void _parse(int start, int end) {
    int offset = start;
    _UJpxTile? tile;
    while (offset + 2 <= end) {
      final int marker = _u16(offset);
      if (marker == 0xFF4F) {
        offset += 2;
        continue;
      }
      if (marker == 0xFFD9) break;
      if (offset + 4 > end) break;
      final int length = _u16(offset + 2);
      final int body = offset + 4;
      switch (marker) {
        case 0xFF51:
          _width = _u32(body + 2);
          _height = _u32(body + 6);
          _x0 = _u32(body + 10);
          _y0 = _u32(body + 14);
          _tileWidth = _u32(body + 18);
          _tileHeight = _u32(body + 22);
          _tileX0 = _u32(body + 26);
          _tileY0 = _u32(body + 30);
          final int count = _u16(body + 34);
          for (int c = 0; c < count; c++) {
            final int base = body + 36 + c * 3;
            _components.add(_UJpxComponent((_data[base] & 0x7F) + 1, _data[base] & 0x80 != 0, max(1, _data[base + 1]), max(1, _data[base + 2])));
          }
          break;
        case 0xFF52:
          final (_UJpxCoding, int, int, int, int) cod = _readCod(body);
          if (tile == null) {
            _coding = cod.$1;
            _codingStyle = cod.$2;
            _progression = cod.$3;
            _layers = cod.$4;
            _mct = cod.$5;
          } else {
            tile.coding = cod.$1;
            tile.codingStyle = cod.$2;
            tile.progression = cod.$3;
            tile.layers = cod.$4;
            tile.mct = cod.$5;
          }
          break;
        case 0xFF53:
          final bool wide = _components.length > 256;
          final int component = wide ? _u16(body) : _data[body];
          final int position = body + (wide ? 2 : 1);
          final _UJpxCoding coding = (tile?.coding ?? _coding).copy();
          final int style = _data[position];
          _readCodingParameters(coding, position + 1, style & 1 != 0);
          if (tile == null) {
            if (component < _components.length) _components[component].coding = coding;
          } else {
            tile.componentCoding[component] = coding;
          }
          break;
        case 0xFF5C:
          final _UJpxQuant quant = _readQuant(body, body + length - 2);
          if (tile == null) {
            _quant = quant;
          } else {
            tile.quant = quant;
          }
          break;
        case 0xFF5D:
          final bool wide = _components.length > 256;
          final int component = wide ? _u16(body) : _data[body];
          final _UJpxQuant quant = _readQuant(body + (wide ? 2 : 1), body + length - 2);
          if (tile == null) {
            if (component < _components.length) _components[component].quant = quant;
          } else {
            tile.componentQuant[component] = quant;
          }
          break;
        case 0xFF90:
          final int index = _u16(body);
          int partLength = _u32(body + 2);
          if (partLength == 0) partLength = end - offset;
          final int partEnd = min(offset + partLength, end);
          tile = _tiles.putIfAbsent(index, () => _newTile(index));
          int cursor = offset + 2 + length;
          while (cursor + 4 <= partEnd) {
            final int inner = _u16(cursor);
            if (inner == 0xFF93) {
              cursor += 2;
              break;
            }
            final int innerLength = _u16(cursor + 2);
            final int innerBody = cursor + 4;
            if (inner == 0xFF52) {
              final (_UJpxCoding, int, int, int, int) cod = _readCod(innerBody);
              tile.coding = cod.$1;
              tile.codingStyle = cod.$2;
              tile.progression = cod.$3;
              tile.layers = cod.$4;
              tile.mct = cod.$5;
            } else if (inner == 0xFF53) {
              final bool wide = _components.length > 256;
              final int component = wide ? _u16(innerBody) : _data[innerBody];
              final int position = innerBody + (wide ? 2 : 1);
              final _UJpxCoding coding = (tile.coding ?? _components[min(component, _components.length - 1)].coding ?? _coding).copy();
              _readCodingParameters(coding, position + 1, _data[position] & 1 != 0);
              tile.componentCoding[component] = coding;
            } else if (inner == 0xFF5C) {
              tile.quant = _readQuant(innerBody, innerBody + innerLength - 2);
            } else if (inner == 0xFF5D) {
              final bool wide = _components.length > 256;
              final int component = wide ? _u16(innerBody) : _data[innerBody];
              tile.componentQuant[component] = _readQuant(innerBody + (wide ? 2 : 1), innerBody + innerLength - 2);
            }
            cursor += 2 + innerLength;
          }
          if (cursor < partEnd) tile.parts.add(Uint8List.sublistView(_data, cursor, partEnd));
          offset = partEnd;
          tile = null;
          continue;
        default:
          break;
      }
      offset += 2 + length;
    }
  }

  _UJpxTile _newTile(int index) {
    final int across = ((_width - _tileX0) / max(_tileWidth, 1)).ceil();
    final int p = index % max(across, 1);
    final int q = index ~/ max(across, 1);
    return _UJpxTile(
      index,
      max(_tileX0 + p * _tileWidth, _x0),
      max(_tileY0 + q * _tileHeight, _y0),
      min(_tileX0 + (p + 1) * _tileWidth, _width),
      min(_tileY0 + (q + 1) * _tileHeight, _height),
    );
  }

  (_UJpxCoding, int, int, int, int) _readCod(int body) {
    final int style = _data[body];
    final int progression = _data[body + 1];
    final int layers = _u16(body + 2);
    final int mct = _data[body + 4];
    final _UJpxCoding coding = _UJpxCoding();
    _readCodingParameters(coding, body + 5, style & 1 != 0);
    return (coding, style, progression, layers, mct);
  }

  void _readCodingParameters(_UJpxCoding coding, int position, bool precincts) {
    coding.levels = _data[position];
    coding.blockWidth = (_data[position + 1] & 15) + 2;
    coding.blockHeight = (_data[position + 2] & 15) + 2;
    coding.style = _data[position + 3];
    coding.reversible = _data[position + 4] == 1;
    if (precincts) {
      coding.precincts = List<int>.generate(coding.levels + 1, (int r) => _data[position + 5 + r]);
    } else {
      coding.precincts = const <int>[];
    }
  }

  _UJpxQuant _readQuant(int start, int end) {
    final _UJpxQuant quant = _UJpxQuant();
    final int value = _data[start];
    quant.guard = value >> 5;
    quant.style = value & 0x1F;
    int position = start + 1;
    while (position < end) {
      if (quant.style == 0) {
        quant.exponents.add(_data[position] >> 3);
        quant.mantissas.add(0);
        position++;
      } else {
        if (position + 1 >= end) break;
        final int v = _u16(position);
        quant.exponents.add(v >> 11);
        quant.mantissas.add(v & 0x7FF);
        position += 2;
      }
    }
    return quant;
  }

  static int _ceilDiv(int a, int b) => (a / b).ceil();

  _UJpxTileComponent _buildComponent(_UJpxTile tile, int c) {
    final _UJpxComponent component = _components[c];
    final _UJpxCoding coding = tile.componentCoding[c] ?? (tile.coding ?? component.coding ?? _coding);
    final _UJpxQuant quant = tile.componentQuant[c] ?? tile.quant ?? component.quant ?? _quant;
    final int cx0 = _ceilDiv(tile.x0, component.dx);
    final int cy0 = _ceilDiv(tile.y0, component.dy);
    final int cx1 = _ceilDiv(tile.x1, component.dx);
    final int cy1 = _ceilDiv(tile.y1, component.dy);
    final _UJpxTileComponent result = _UJpxTileComponent(cx0, cy0, cx1, cy1, coding);
    final int levels = coding.levels;
    for (int r = 0; r <= levels; r++) {
      final int scale = 1 << (levels - r);
      final int ppx = coding.precinctWidth(r);
      final int ppy = coding.precinctHeight(r);
      final _UJpxResolution resolution = _UJpxResolution(_ceilDiv(cx0, scale), _ceilDiv(cy0, scale), _ceilDiv(cx1, scale), _ceilDiv(cy1, scale), ppx, ppy);
      resolution.precinctsWide = resolution.x1 > resolution.x0 ? _ceilDiv(resolution.x1, 1 << ppx) - (resolution.x0 >> ppx) : 0;
      resolution.precinctsHigh = resolution.y1 > resolution.y0 ? _ceilDiv(resolution.y1, 1 << ppy) - (resolution.y0 >> ppy) : 0;
      final List<int> kinds = r == 0 ? const <int>[0] : const <int>[1, 2, 3];
      for (final int kind in kinds) {
        final int n = r == 0 ? levels : levels - r + 1;
        final int xo = kind == 1 || kind == 3 ? 1 : 0;
        final int yo = kind == 2 || kind == 3 ? 1 : 0;
        final int half = n == 0 ? 0 : 1 << (n - 1);
        final int div = 1 << n;
        final _UJpxSubband band = _UJpxSubband(kind, _ceilDiv(cx0 - half * xo, div), _ceilDiv(cy0 - half * yo, div), _ceilDiv(cx1 - half * xo, div), _ceilDiv(cy1 - half * yo, div));
        band.blockWidth = min(coding.blockWidth, r == 0 ? ppx : ppx - 1);
        band.blockHeight = min(coding.blockHeight, r == 0 ? ppy : ppy - 1);
        final int index = r == 0 ? 0 : 1 + (r - 1) * 3 + (kind - 1);
        final (int, int) step = quant.stepOf(index, levels);
        final int gain = kind == 0 ? 0 : (kind == 3 ? 2 : 1);
        band.bitPlanes = quant.guard + step.$1 - 1;
        band.step = coding.reversible ? 1 : pow(2, component.precision + gain - step.$1).toDouble() * (1 + step.$2 / 2048);
        if (band.width > 0 && band.height > 0) {
          final int bw = 1 << band.blockWidth;
          final int bh = 1 << band.blockHeight;
          for (int gy = band.y0 ~/ bh; gy * bh < band.y1; gy++) {
            for (int gx = band.x0 ~/ bw; gx * bw < band.x1; gx++) {
              band.blocks.add(_UJpxCodeBlock(max(gx * bw, band.x0), max(gy * bh, band.y0), min((gx + 1) * bw, band.x1), min((gy + 1) * bh, band.y1), gx, gy));
            }
          }
        }
        resolution.bands.add(band);
      }
      resolution.precincts = List<_UJpxPrecinct?>.filled(resolution.precinctsWide * resolution.precinctsHigh, null);
      result.resolutions.add(resolution);
    }
    return result;
  }

  /// Code-blocks of a precinct, per subband, with their tag trees (built on first use).
  _UJpxPrecinct _precinct(_UJpxResolution resolution, int index, int r) {
    final _UJpxPrecinct? existing = resolution.precincts[index];
    if (existing != null) return existing;
    final int px = index % resolution.precinctsWide + (resolution.x0 >> resolution.precinctWidth);
    final int py = index ~/ resolution.precinctsWide + (resolution.y0 >> resolution.precinctHeight);
    final List<_UJpxPrecinctBand> bands = <_UJpxPrecinctBand>[];
    for (final _UJpxSubband band in resolution.bands) {
      // Precinct size in the subband: halved above the lowest resolution.
      final int sw = r == 0 ? resolution.precinctWidth : resolution.precinctWidth - 1;
      final int sh = r == 0 ? resolution.precinctHeight : resolution.precinctHeight - 1;
      final int bx0 = px << sw;
      final int by0 = py << sh;
      final int bx1 = (px + 1) << sw;
      final int by1 = (py + 1) << sh;
      final List<_UJpxCodeBlock> blocks = band.blocks.where((_UJpxCodeBlock b) => b.x0 >= bx0 && b.x0 < bx1 && b.y0 >= by0 && b.y0 < by1).toList();
      int minX = 1 << 30;
      int minY = 1 << 30;
      int maxX = -1;
      int maxY = -1;
      for (final _UJpxCodeBlock block in blocks) {
        minX = min(minX, block.gridX);
        minY = min(minY, block.gridY);
        maxX = max(maxX, block.gridX);
        maxY = max(maxY, block.gridY);
      }
      bands.add(_UJpxPrecinctBand(band, blocks, minX, minY, maxX - minX + 1, maxY - minY + 1));
    }
    return resolution.precincts[index] = _UJpxPrecinct(bands);
  }

  void _decodeTile(_UJpxTile tile, List<Float32List> planes, List<int> planeWidths) {
    final int count = _components.length;
    final List<_UJpxTileComponent> components = List<_UJpxTileComponent>.generate(count, (int c) => _buildComponent(tile, c));
    final Uint8List data = _concat(tile.parts);
    final int layers = tile.layers ?? _layers;
    final int progression = tile.progression ?? _progression;
    final int style = tile.codingStyle ?? _codingStyle;
    final _UJpxPacketReader reader = _UJpxPacketReader(data, sop: style & 2 != 0, eph: style & 4 != 0);
    for (final (int, int, int, int) packet in _packets(tile, components, layers, progression)) {
      if (reader.done) break;
      final int r = packet.$2;
      final _UJpxResolution resolution = components[packet.$3].resolutions[r];
      reader.read(_precinct(resolution, packet.$4, r), packet.$1);
    }
    final bool mctOn = (tile.mct ?? _mct) == 1 && count >= 3;
    final List<Float32List> samples = <Float32List>[];
    for (int c = 0; c < count; c++) {
      samples.add(_reconstruct(components[c]));
    }
    if (mctOn) _inverseMct(samples, components[0].coding.reversible);
    for (int c = 0; c < count; c++) {
      final _UJpxTileComponent tc = components[c];
      final _UJpxComponent component = _components[c];
      final double shift = component.signed ? 0 : (1 << (component.precision - 1)).toDouble();
      final Float32List plane = planes[c];
      final int stride = planeWidths[c];
      final int ox = _ceilDiv(_x0, component.dx);
      final int oy = _ceilDiv(_y0, component.dy);
      final int w = tc.x1 - tc.x0;
      final Float32List source = samples[c];
      for (int y = 0; y < tc.y1 - tc.y0; y++) {
        final int target = (tc.y0 - oy + y) * stride + (tc.x0 - ox);
        for (int x = 0; x < w; x++) {
          final int index = target + x;
          if (index >= 0 && index < plane.length) plane[index] = source[y * w + x] + shift;
        }
      }
    }
  }

  static Uint8List _concat(List<Uint8List> parts) {
    if (parts.length == 1) return parts.first;
    final BytesBuilder builder = BytesBuilder(copy: false);
    for (final Uint8List part in parts) {
      builder.add(part);
    }
    return builder.takeBytes();
  }

  /// Packets in codestream order: (layer, resolution, component, precinct).
  Iterable<(int, int, int, int)> _packets(_UJpxTile tile, List<_UJpxTileComponent> components, int layers, int progression) sync* {
    final int count = components.length;
    int maxLevels = 0;
    for (final _UJpxTileComponent c in components) {
      maxLevels = max(maxLevels, c.coding.levels);
    }
    switch (progression) {
      case 0:
        for (int l = 0; l < layers; l++) {
          for (int r = 0; r <= maxLevels; r++) {
            for (int c = 0; c < count; c++) {
              if (r > components[c].coding.levels) continue;
              final _UJpxResolution res = components[c].resolutions[r];
              for (int p = 0; p < res.precincts.length; p++) {
                yield (l, r, c, p);
              }
            }
          }
        }
        break;
      case 1:
        for (int r = 0; r <= maxLevels; r++) {
          for (int l = 0; l < layers; l++) {
            for (int c = 0; c < count; c++) {
              if (r > components[c].coding.levels) continue;
              final _UJpxResolution res = components[c].resolutions[r];
              for (int p = 0; p < res.precincts.length; p++) {
                yield (l, r, c, p);
              }
            }
          }
        }
        break;
      default:
        yield* _positionPackets(tile, components, layers, progression, maxLevels);
    }
  }

  /// RPCL (2), PCRL (3) and CPRL (4): packets follow precinct positions on the tile grid.
  Iterable<(int, int, int, int)> _positionPackets(_UJpxTile tile, List<_UJpxTileComponent> components, int layers, int progression, int maxLevels) sync* {
    int stepX = 1 << 30;
    int stepY = 1 << 30;
    for (int c = 0; c < components.length; c++) {
      final _UJpxTileComponent tc = components[c];
      for (int r = 0; r <= tc.coding.levels; r++) {
        final _UJpxResolution res = tc.resolutions[r];
        stepX = min(stepX, _components[c].dx << (res.precinctWidth + tc.coding.levels - r));
        stepY = min(stepY, _components[c].dy << (res.precinctHeight + tc.coding.levels - r));
      }
    }
    stepX = max(stepX, 1);
    stepY = max(stepY, 1);
    final List<int> ys = <int>[tile.y0];
    for (int y = (tile.y0 ~/ stepY + 1) * stepY; y < tile.y1; y += stepY) {
      ys.add(y);
    }
    final List<int> xs = <int>[tile.x0];
    for (int x = (tile.x0 ~/ stepX + 1) * stepX; x < tile.x1; x += stepX) {
      xs.add(x);
    }
    int? precinctAt(int c, int r, int x, int y) {
      final _UJpxTileComponent tc = components[c];
      if (r > tc.coding.levels) return null;
      final _UJpxResolution res = tc.resolutions[r];
      if (res.precincts.isEmpty) return null;
      final int levelShift = tc.coding.levels - r;
      final int dx = _components[c].dx;
      final int dy = _components[c].dy;
      final bool alignY = y % (dy << (res.precinctHeight + levelShift)) == 0 || (y == tile.y0 && ((res.y0 << levelShift) % (1 << (res.precinctHeight + levelShift))) != 0);
      final bool alignX = x % (dx << (res.precinctWidth + levelShift)) == 0 || (x == tile.x0 && ((res.x0 << levelShift) % (1 << (res.precinctWidth + levelShift))) != 0);
      if (!alignX || !alignY) return null;
      final int px = (_ceilDiv(x, dx << levelShift) >> res.precinctWidth) - (res.x0 >> res.precinctWidth);
      final int py = (_ceilDiv(y, dy << levelShift) >> res.precinctHeight) - (res.y0 >> res.precinctHeight);
      if (px < 0 || py < 0 || px >= res.precinctsWide || py >= res.precinctsHigh) return null;
      return py * res.precinctsWide + px;
    }

    final int count = components.length;
    if (progression == 2) {
      for (int r = 0; r <= maxLevels; r++) {
        for (final int y in ys) {
          for (final int x in xs) {
            for (int c = 0; c < count; c++) {
              final int? p = precinctAt(c, r, x, y);
              if (p == null) continue;
              for (int l = 0; l < layers; l++) {
                yield (l, r, c, p);
              }
            }
          }
        }
      }
    } else if (progression == 3) {
      for (final int y in ys) {
        for (final int x in xs) {
          for (int c = 0; c < count; c++) {
            for (int r = 0; r <= components[c].coding.levels; r++) {
              final int? p = precinctAt(c, r, x, y);
              if (p == null) continue;
              for (int l = 0; l < layers; l++) {
                yield (l, r, c, p);
              }
            }
          }
        }
      }
    } else {
      for (int c = 0; c < count; c++) {
        for (final int y in ys) {
          for (final int x in xs) {
            for (int r = 0; r <= components[c].coding.levels; r++) {
              final int? p = precinctAt(c, r, x, y);
              if (p == null) continue;
              for (int l = 0; l < layers; l++) {
                yield (l, r, c, p);
              }
            }
          }
        }
      }
    }
  }

  // ───────────────────────── tier 1 (code-block decoding) ─────────────────────────

  Float32List _reconstruct(_UJpxTileComponent tc) {
    final bool reversible = tc.coding.reversible;
    final int levels = tc.coding.levels;
    final _UJpxResolution first = tc.resolutions[0];
    Float32List current = _bandCoefficients(first.bands[0], tc.coding);
    int width = first.x1 - first.x0;
    int height = first.y1 - first.y0;
    for (int r = 1; r <= levels; r++) {
      final _UJpxResolution res = tc.resolutions[r];
      final Float32List hl = _bandCoefficients(res.bands[0], tc.coding);
      final Float32List lh = _bandCoefficients(res.bands[1], tc.coding);
      final Float32List hh = _bandCoefficients(res.bands[2], tc.coding);
      final int w = res.x1 - res.x0;
      final int h = res.y1 - res.y0;
      current = _synthesize(current, width, hl, res.bands[0].width, lh, res.bands[1].width, hh, res.bands[2].width, w, h, res.x0, res.y0, reversible);
      width = w;
      height = h;
    }
    return width == tc.x1 - tc.x0 && height == tc.y1 - tc.y0 ? current : Float32List((tc.x1 - tc.x0) * (tc.y1 - tc.y0));
  }

  Float32List _bandCoefficients(_UJpxSubband band, _UJpxCoding coding) {
    final int width = band.width;
    final Float32List out = Float32List(max(width, 0) * max(band.height, 0));
    if (out.isEmpty) return out;
    for (final _UJpxCodeBlock block in band.blocks) {
      if (block.passes == 0 || block.chunks.isEmpty) continue;
      _decodeBlock(block, band, coding, out, width);
    }
    return out;
  }

  void _decodeBlock(_UJpxCodeBlock block, _UJpxSubband band, _UJpxCoding coding, Float32List out, int stride) {
    final int w = block.x1 - block.x0;
    final int h = block.y1 - block.y0;
    if (w <= 0 || h <= 0) return;
    final int topPlane = band.bitPlanes - 1 - block.zeroPlanes;
    if (topPlane < 0 || topPlane > 30) return;
    final Uint8List data = _concat(block.chunks);
    final int pw = w + 2;
    final Uint8List significant = Uint8List(pw * (h + 2));
    final Uint8List negative = Uint8List(pw * (h + 2));
    final Uint8List visited = Uint8List(pw * (h + 2));
    final Uint8List refined = Uint8List(pw * (h + 2));
    final Int32List magnitude = Int32List(pw * (h + 2));
    final Int8List lastPlane = Int8List(pw * (h + 2));
    final Uint8List contexts = Uint8List(_contexts);
    void resetContexts() {
      contexts.fillRange(0, _contexts, 0);
      contexts[0] = 4 << 1;
      contexts[_runContext] = 3 << 1;
      contexts[_uniformContext] = 46 << 1;
    }

    resetContexts();
    final UJbig2ArithmeticDecoder decoder = UJbig2ArithmeticDecoder(data);
    final bool reset = coding.style & 2 != 0;
    final bool causal = coding.style & 8 != 0;
    final bool segmentation = coding.style & 32 != 0;
    final int kind = band.kind;

    int zeroContext(int i, int y) {
      final bool lastRow = causal && (y & 3) == 3;
      final int hCount = significant[i - 1] + significant[i + 1];
      final int vCount = significant[i - pw] + (lastRow ? 0 : significant[i + pw]);
      final int dCount = significant[i - pw - 1] + significant[i - pw + 1] + (lastRow ? 0 : significant[i + pw - 1] + significant[i + pw + 1]);
      if (kind == 3) {
        final int hv = hCount + vCount;
        if (dCount >= 3) return 8;
        if (dCount == 2) return hv >= 1 ? 7 : 6;
        if (dCount == 1) return hv >= 2 ? 5 : (hv == 1 ? 4 : 3);
        return hv >= 2 ? 2 : (hv == 1 ? 1 : 0);
      }
      final int a = kind == 1 ? vCount : hCount;
      final int b = kind == 1 ? hCount : vCount;
      if (a == 2) return 8;
      if (a == 1) return b >= 1 ? 7 : (dCount >= 1 ? 6 : 5);
      if (b == 2) return 4;
      if (b == 1) return 3;
      return dCount >= 2 ? 2 : (dCount == 1 ? 1 : 0);
    }

    bool hasNeighbour(int i, int y) {
      final bool lastRow = causal && (y & 3) == 3;
      return significant[i - 1] != 0 ||
          significant[i + 1] != 0 ||
          significant[i - pw] != 0 ||
          significant[i - pw - 1] != 0 ||
          significant[i - pw + 1] != 0 ||
          (!lastRow && (significant[i + pw] != 0 || significant[i + pw - 1] != 0 || significant[i + pw + 1] != 0));
    }

    int contribution(int j) => significant[j] == 0 ? 0 : (negative[j] != 0 ? -1 : 1);

    void decodeSign(int i, int y) {
      final bool lastRow = causal && (y & 3) == 3;
      final int hc = (contribution(i - 1) + contribution(i + 1)).clamp(-1, 1);
      final int vc = (contribution(i - pw) + (lastRow ? 0 : contribution(i + pw))).clamp(-1, 1);
      int context;
      int flip;
      if (hc == 1) {
        context = vc == 1 ? 13 : (vc == 0 ? 12 : 11);
        flip = 0;
      } else if (hc == 0) {
        context = vc == 0 ? 9 : 10;
        flip = vc == -1 ? 1 : 0;
      } else {
        context = vc == 1 ? 11 : (vc == 0 ? 12 : 13);
        flip = 1;
      }
      negative[i] = decoder.decode(contexts, context) ^ flip;
    }

    int plane = topPlane;
    int passType = 2;
    for (int pass = 0; pass < block.passes && plane >= 0; pass++) {
      if (passType == 0) {
        for (int y0 = 0; y0 < h; y0 += 4) {
          for (int x = 0; x < w; x++) {
            for (int y = y0; y < y0 + 4 && y < h; y++) {
              final int i = (y + 1) * pw + x + 1;
              if (significant[i] != 0 || !hasNeighbour(i, y)) continue;
              visited[i] = 1;
              if (decoder.decode(contexts, zeroContext(i, y)) == 1) {
                decodeSign(i, y);
                significant[i] = 1;
                magnitude[i] = 1 << plane;
                lastPlane[i] = plane;
              }
            }
          }
        }
      } else if (passType == 1) {
        for (int y0 = 0; y0 < h; y0 += 4) {
          for (int x = 0; x < w; x++) {
            for (int y = y0; y < y0 + 4 && y < h; y++) {
              final int i = (y + 1) * pw + x + 1;
              if (significant[i] == 0 || visited[i] != 0) continue;
              final int context = refined[i] != 0 ? 16 : (hasNeighbour(i, y) ? 15 : 14);
              if (decoder.decode(contexts, context) == 1) magnitude[i] |= 1 << plane;
              refined[i] = 1;
              lastPlane[i] = plane;
            }
          }
        }
      } else {
        for (int y0 = 0; y0 < h; y0 += 4) {
          for (int x = 0; x < w; x++) {
            int y = y0;
            if (y0 + 3 < h) {
              bool run = true;
              for (int k = 0; k < 4 && run; k++) {
                final int i = (y0 + k + 1) * pw + x + 1;
                if (significant[i] != 0 || visited[i] != 0 || hasNeighbour(i, y0 + k)) run = false;
              }
              if (run) {
                if (decoder.decode(contexts, _runContext) == 0) continue;
                final int offset = (decoder.decode(contexts, _uniformContext) << 1) | decoder.decode(contexts, _uniformContext);
                y = y0 + offset;
                final int i = (y + 1) * pw + x + 1;
                decodeSign(i, y);
                significant[i] = 1;
                magnitude[i] = 1 << plane;
                lastPlane[i] = plane;
                y++;
              }
            }
            for (; y < y0 + 4 && y < h; y++) {
              final int i = (y + 1) * pw + x + 1;
              if (significant[i] != 0 || visited[i] != 0) continue;
              if (decoder.decode(contexts, zeroContext(i, y)) == 1) {
                decodeSign(i, y);
                significant[i] = 1;
                magnitude[i] = 1 << plane;
                lastPlane[i] = plane;
              }
            }
          }
        }
        if (segmentation) {
          for (int k = 0; k < 4; k++) {
            decoder.decode(contexts, _uniformContext);
          }
        }
        visited.fillRange(0, visited.length, 0);
        plane--;
      }
      passType = (passType + 1) % 3;
      if (reset) resetContexts();
    }
    final double step = band.step;
    final bool reversible = coding.reversible;
    for (int y = 0; y < h; y++) {
      final int row = (block.y0 - band.y0 + y) * stride + (block.x0 - band.x0);
      for (int x = 0; x < w; x++) {
        final int i = (y + 1) * pw + x + 1;
        final int m = magnitude[i];
        if (m == 0) continue;
        final int last = lastPlane[i];
        // Bits below the last decoded plane are unknown: take the middle of that range.
        double value = m.toDouble();
        if (last > 0) {
          value += 1 << (last - 1);
        } else if (!reversible) {
          value += 0.5;
        }
        if (negative[i] != 0) value = -value;
        out[row + x] = reversible ? value : value * step;
      }
    }
  }

  // ───────────────────────── wavelet and color transforms ─────────────────────────

  Float32List _synthesize(Float32List ll, int llWidth, Float32List hl, int hlWidth, Float32List lh, int lhWidth, Float32List hh, int hhWidth, int width, int height, int u0, int v0, bool reversible) {
    final Float32List out = Float32List(width * height);
    if (width == 0 || height == 0) return out;
    // Interleave the four subbands: even absolute positions take low-pass samples.
    for (int y = 0; y < height; y++) {
      final bool lowRow = (v0 + y) & 1 == 0;
      final int by = lowRow ? ((v0 + y) >> 1) - _ceilDiv(v0, 2) : ((v0 + y) >> 1) - (v0 >> 1);
      for (int x = 0; x < width; x++) {
        final bool lowColumn = (u0 + x) & 1 == 0;
        final int bx = lowColumn ? ((u0 + x) >> 1) - _ceilDiv(u0, 2) : ((u0 + x) >> 1) - (u0 >> 1);
        double value = 0;
        if (lowRow && lowColumn) {
          if (bx < llWidth && by * llWidth + bx < ll.length) value = ll[by * llWidth + bx];
        } else if (lowRow) {
          if (bx < hlWidth && by * hlWidth + bx < hl.length) value = hl[by * hlWidth + bx];
        } else if (lowColumn) {
          if (bx < lhWidth && by * lhWidth + bx < lh.length) value = lh[by * lhWidth + bx];
        } else {
          if (bx < hhWidth && by * hhWidth + bx < hh.length) value = hh[by * hhWidth + bx];
        }
        out[y * width + x] = value;
      }
    }
    const int pad = 4;
    final Float64List buffer = Float64List(max(width, height) + pad * 2);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        buffer[pad + x] = out[y * width + x];
      }
      _filter(buffer, pad, width, u0, reversible);
      for (int x = 0; x < width; x++) {
        out[y * width + x] = buffer[pad + x];
      }
    }
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        buffer[pad + y] = out[y * width + x];
      }
      _filter(buffer, pad, height, v0, reversible);
      for (int y = 0; y < height; y++) {
        out[y * width + x] = buffer[pad + y];
      }
    }
    return out;
  }

  /// 1D synthesis of [length] samples at buffer[pad..]; [start] is the absolute coordinate of the first one.
  static void _filter(Float64List x, int pad, int length, int start, bool reversible) {
    if (length == 1) {
      if (start & 1 == 1) x[pad] = reversible ? (x[pad] / 2).floorToDouble() : x[pad] / 2;
      return;
    }
    // Whole-sample symmetric extension.
    for (int k = 1; k <= pad; k++) {
      int left = -k;
      int right = length - 1 + k;
      while (left < 0 || left >= length) {
        left = left < 0 ? -left : 2 * (length - 1) - left;
      }
      while (right < 0 || right >= length) {
        right = right < 0 ? -right : 2 * (length - 1) - right;
      }
      x[pad - k] = x[pad + left];
      x[pad + length - 1 + k] = x[pad + right];
    }
    final int end = pad + length + pad;
    // Buffer index j holds absolute coordinate start + j - pad; even coordinates are low-pass.
    final int firstLow = (start & 1) == 0 ? 0 : 1;
    final int firstHigh = 1 - firstLow;
    if (reversible) {
      for (int j = firstLow == 0 ? 2 : 1; j < end - 1; j += 2) {
        x[j] -= ((x[j - 1] + x[j + 1] + 2) / 4).floorToDouble();
      }
      for (int j = firstHigh == 0 ? 2 : 1; j < end - 1; j += 2) {
        x[j] += ((x[j - 1] + x[j + 1]) / 2).floorToDouble();
      }
      return;
    }
    const double alpha = -1.586134342059924;
    const double beta = -0.052980118572961;
    const double gamma = 0.882911075530934;
    const double delta = 0.443506852043971;
    const double k = 1.230174104914001;
    for (int j = firstHigh; j < end; j += 2) {
      x[j] /= k;
    }
    for (int j = firstLow; j < end; j += 2) {
      x[j] *= k;
    }
    for (int j = firstLow == 0 ? 2 : 1; j < end - 1; j += 2) {
      x[j] -= delta * (x[j - 1] + x[j + 1]);
    }
    for (int j = firstHigh == 0 ? 2 : 1; j < end - 1; j += 2) {
      x[j] -= gamma * (x[j - 1] + x[j + 1]);
    }
    for (int j = firstLow == 0 ? 2 : 1; j < end - 1; j += 2) {
      x[j] -= beta * (x[j - 1] + x[j + 1]);
    }
    for (int j = firstHigh == 0 ? 2 : 1; j < end - 1; j += 2) {
      x[j] -= alpha * (x[j - 1] + x[j + 1]);
    }
  }

  static void _inverseMct(List<Float32List> samples, bool reversible) {
    final Float32List a = samples[0];
    final Float32List b = samples[1];
    final Float32List c = samples[2];
    final int n = min(a.length, min(b.length, c.length));
    for (int i = 0; i < n; i++) {
      final double y = a[i];
      final double u = b[i];
      final double v = c[i];
      if (reversible) {
        final double g = y - ((u + v) / 4).floorToDouble();
        a[i] = v + g;
        b[i] = g;
        c[i] = u + g;
      } else {
        a[i] = y + 1.402 * v;
        b[i] = y - 0.34413 * u - 0.71414 * v;
        c[i] = y + 1.772 * u;
      }
    }
  }

  UJpxImage _output(List<Float32List> planes, List<int> widths, List<int> heights, int count) {
    final List<List<int>>? palette = applyPalette ? _palette : null;
    final int outCount = palette != null && count == 1 ? palette.length : count;
    final int imageWidth = _width - _x0;
    final int imageHeight = _height - _y0;
    final Uint8List result = Uint8List(imageWidth * imageHeight * outCount);
    for (int c = 0; c < count; c++) {
      final _UJpxComponent component = _components[c];
      final int maxValue = (1 << component.precision) - 1;
      final double half = component.signed ? (1 << (component.precision - 1)).toDouble() : 0;
      final Float32List plane = planes[c];
      final int w = widths[c];
      final int h = heights[c];
      for (int y = 0; y < imageHeight; y++) {
        final int sy = min(y ~/ component.dy, h - 1);
        for (int x = 0; x < imageWidth; x++) {
          final int sx = min(x ~/ component.dx, w - 1);
          final int raw = (plane[sy * w + sx] + half).round().clamp(0, maxValue);
          final int target = (y * imageWidth + x) * outCount;
          if (palette != null && count == 1) {
            for (int p = 0; p < outCount; p++) {
              final List<int> column = palette[p];
              final int value = raw < column.length ? column[raw] : 0;
              final int bits = _paletteBits[p];
              result[target + p] = bits == 8 ? value : (value * 255 / ((1 << bits) - 1)).round();
            }
          } else {
            result[target + c] = component.precision == 8 ? raw : (raw * 255 / maxValue).round();
          }
        }
      }
    }
    return UJpxImage(width: imageWidth, height: imageHeight, components: outCount, data: result, colorChannels: palette == null && _palette != null ? 1 : _colorChannels);
  }
}

/// Internal: reads packet headers and bodies of one tile.
class _UJpxPacketReader {
  _UJpxPacketReader(this.data, {required this.sop, required this.eph});

  final Uint8List data;
  final bool sop;
  final bool eph;
  int _position = 0;
  int _buffer = 0;
  int _bufferSize = 0;
  bool _skipBit = false;

  bool get done => _position >= data.length;

  int _readBits(int count) {
    while (_bufferSize < count) {
      final int byte = _position < data.length ? data[_position] : 0;
      _position++;
      if (_skipBit) {
        _buffer = ((_buffer << 7) | byte) & 0xFFFFFFFF;
        _bufferSize += 7;
        _skipBit = false;
      } else {
        _buffer = ((_buffer << 8) | byte) & 0xFFFFFFFF;
        _bufferSize += 8;
      }
      if (byte == 0xFF) _skipBit = true;
    }
    _bufferSize -= count;
    return (_buffer >> _bufferSize) & ((1 << count) - 1);
  }

  void _align() {
    _bufferSize = 0;
    if (_skipBit) {
      _position++;
      _skipBit = false;
    }
  }

  int _passes() {
    if (_readBits(1) == 0) return 1;
    if (_readBits(1) == 0) return 2;
    int value = _readBits(2);
    if (value < 3) return value + 3;
    value = _readBits(5);
    if (value < 31) return value + 6;
    return _readBits(7) + 37;
  }

  void read(_UJpxPrecinct precinct, int layer) {
    if (sop && _position + 1 < data.length && data[_position] == 0xFF && data[_position + 1] == 0x91) _position += 6;
    final List<(_UJpxCodeBlock, int)> queue = <(_UJpxCodeBlock, int)>[];
    if (_readBits(1) == 1) {
      for (final _UJpxPrecinctBand band in precinct.bands) {
        for (final _UJpxCodeBlock block in band.blocks) {
          final int x = block.gridX - band.minX;
          final int y = block.gridY - band.minY;
          bool included = false;
          bool first = false;
          if (block.included == null) {
            if (band.inclusion.reset(x, y, layer)) {
              while (true) {
                if (_readBits(1) == 1) {
                  if (!band.inclusion.nextLevel()) {
                    block.included = true;
                    included = true;
                    first = true;
                    break;
                  }
                } else {
                  band.inclusion.increment(layer);
                  break;
                }
              }
            }
          } else {
            included = _readBits(1) == 1;
          }
          if (!included) continue;
          if (first) {
            band.zeroPlanes.reset(x, y);
            while (true) {
              if (_readBits(1) == 1) {
                if (!band.zeroPlanes.nextLevel()) break;
              } else {
                band.zeroPlanes.increment();
              }
            }
            block.zeroPlanes = band.zeroPlanes.value;
          }
          final int passes = _passes();
          while (_readBits(1) == 1) {
            block.lengthBits++;
          }
          int log = 0;
          while ((1 << (log + 1)) <= passes) {
            log++;
          }
          final int length = _readBits(block.lengthBits + log);
          queue.add((block, length));
          block.passes += passes;
        }
      }
    }
    _align();
    if (eph && _position + 1 < data.length && data[_position] == 0xFF && data[_position + 1] == 0x92) _position += 2;
    for (final (_UJpxCodeBlock, int) item in queue) {
      final int end = min(_position + item.$2, data.length);
      if (end > _position) item.$1.chunks.add(Uint8List.sublistView(data, _position, end));
      _position = end;
    }
  }
}
