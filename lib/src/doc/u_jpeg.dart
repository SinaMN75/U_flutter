import "dart:typed_data";

import "package:u/utilities.dart";

/// Decoded JPEG samples, interleaved, in the order the PDF expects (gray, RGB or CMYK).
class UJpegImage {
  const UJpegImage({required this.width, required this.height, required this.components, required this.data, required this.adobe});

  final int width;
  final int height;
  final int components;
  final Uint8List data;

  /// True when the file has an Adobe APP14 marker.
  final bool adobe;
}

class _UJpegHuffman {
  _UJpegHuffman(List<int> counts, List<int> values) : _values = values {
    int code = 0;
    int index = 0;
    for (int length = 1; length <= 16; length++) {
      final int count = counts[length - 1];
      _valuePointer[length] = index;
      _minCode[length] = code;
      code += count;
      index += count;
      _maxCode[length] = count == 0 ? -1 : code - 1;
      code <<= 1;
    }
  }

  final List<int> _values;
  final Int32List _maxCode = Int32List(18);
  final Int32List _minCode = Int32List(18);
  final Int32List _valuePointer = Int32List(18);
}

class _UJpegComponent {
  _UJpegComponent(this.id, this.h, this.v, this.quantTable);

  final int id;
  final int h;
  final int v;
  final int quantTable;
  int blocksPerLine = 0;
  int blocksPerColumn = 0;
  Int16List blocks = Int16List(0);
  _UJpegHuffman? dc;
  _UJpegHuffman? ac;
  int pred = 0;
}

/// Internal: baseline and progressive JPEG decoder for PDF images (DCTDecode).
/// Platform codecs disagree on CMYK and YCCK JPEGs and ignore the PDF Decode array, so those go through here.
abstract class UJpeg {
  static const List<int> _zigZag = <int>[
    0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28, //
    35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63, //
    63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63,
  ];

  /// Number of components and whether an Adobe marker is present, without decoding.
  static (int, bool)? probe(Uint8List bytes) {
    int offset = 2;
    bool adobe = false;
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }
      final int marker = bytes[offset + 1];
      if (marker == 0xFF) {
        offset++;
        continue;
      }
      final int length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (marker == 0xEE && offset + 9 <= bytes.length && bytes[offset + 4] == 0x41 && bytes[offset + 5] == 0x64 && bytes[offset + 6] == 0x6F) adobe = true;
      if ((marker >= 0xC0 && marker <= 0xC3) || (marker >= 0xC5 && marker <= 0xC7) || (marker >= 0xC9 && marker <= 0xCB) || (marker >= 0xCD && marker <= 0xCF)) {
        if (offset + 9 >= bytes.length) return null;
        return (bytes[offset + 9], adobe);
      }
      if (marker == 0xD9 || marker == 0xDA) return null;
      offset += 2 + length;
    }
    return null;
  }

  /// [colorTransform] is the PDF /ColorTransform parameter (null = decide from the file).
  static UJpegImage? decode(Uint8List bytes, {int? colorTransform}) {
    try {
      return _UJpegDecoder(bytes, colorTransform).run();
    } on Object {
      return null;
    }
  }
}

class _UJpegDecoder {
  _UJpegDecoder(this._data, this._colorTransform);

  final Uint8List _data;
  final int? _colorTransform;
  final List<Int32List?> _quant = List<Int32List?>.filled(4, null);
  final List<_UJpegHuffman?> _dcTables = List<_UJpegHuffman?>.filled(4, null);
  final List<_UJpegHuffman?> _acTables = List<_UJpegHuffman?>.filled(4, null);
  final List<_UJpegComponent> _components = <_UJpegComponent>[];
  int _width = 0;
  int _height = 0;
  int _maxH = 1;
  int _maxV = 1;
  int _mcusPerLine = 0;
  int _mcusPerColumn = 0;
  bool _progressive = false;
  int _resetInterval = 0;
  bool _adobe = false;
  int _adobeTransform = 0;
  bool _frameRead = false;

  int _offset = 0;
  int _bits = 0;
  int _bitCount = 0;
  int _eobRun = 0;
  int _acState = 0;
  int _acNext = 0;

  int _u16() {
    final int value = (_data[_offset] << 8) | _data[_offset + 1];
    _offset += 2;
    return value;
  }

  UJpegImage? run() {
    if (_data.length < 4 || _data[0] != 0xFF || _data[1] != 0xD8) return null;
    _offset = 2;
    while (_offset < _data.length) {
      if (_data[_offset] != 0xFF) {
        _offset++;
        continue;
      }
      final int marker = _data[_offset + 1];
      _offset += 2;
      if (marker == 0xFF || marker == 0x00 || (marker >= 0xD0 && marker <= 0xD7) || marker == 0x01) {
        if (marker == 0xFF) _offset--;
        continue;
      }
      if (marker == 0xD9) break;
      final int start = _offset;
      final int length = _u16();
      final int end = start + length;
      if (end > _data.length) break;
      switch (marker) {
        case 0xEE:
          if (length >= 12 && _data[start + 2] == 0x41 && _data[start + 3] == 0x64 && _data[start + 4] == 0x6F && _data[start + 5] == 0x62 && _data[start + 6] == 0x65) {
            _adobe = true;
            _adobeTransform = _data[start + 13];
          }
          break;
        case 0xDB:
          _readQuantTables(end);
          break;
        case 0xC4:
          _readHuffmanTables(end);
          break;
        case 0xDD:
          _resetInterval = (_data[start + 2] << 8) | _data[start + 3];
          break;
        case 0xC0:
        case 0xC1:
        case 0xC2:
          if (_frameRead) break;
          _progressive = marker == 0xC2;
          _readFrame(start + 2);
          break;
        case 0xC3:
        case 0xC5:
        case 0xC6:
        case 0xC7:
        case 0xC9:
        case 0xCA:
        case 0xCB:
        case 0xCD:
        case 0xCE:
        case 0xCF:
          return null;
        case 0xDA:
          if (!_frameRead) return null;
          _offset = start + 2;
          _readScan();
          continue;
        default:
          break;
      }
      _offset = end;
    }
    if (!_frameRead) return null;
    return _output();
  }

  void _readQuantTables(int end) {
    while (_offset < end) {
      final int info = _data[_offset++];
      final int precision = info >> 4;
      final Int32List table = Int32List(64);
      for (int i = 0; i < 64; i++) {
        final int value = precision == 0 ? _data[_offset++] : _u16();
        table[UJpeg._zigZag[i]] = value;
      }
      _quant[info & 3] = table;
    }
  }

  void _readHuffmanTables(int end) {
    while (_offset < end) {
      final int info = _data[_offset++];
      final List<int> counts = List<int>.generate(16, (int i) => _data[_offset + i]);
      _offset += 16;
      int total = 0;
      for (final int count in counts) {
        total += count;
      }
      final List<int> values = List<int>.generate(total, (int i) => _data[_offset + i]);
      _offset += total;
      final _UJpegHuffman table = _UJpegHuffman(counts, values);
      if (info >> 4 == 0) {
        _dcTables[info & 3] = table;
      } else {
        _acTables[info & 3] = table;
      }
    }
  }

  void _readFrame(int position) {
    _offset = position;
    final int precision = _data[_offset++];
    if (precision != 8) throw const FormatException("Only 8-bit JPEG");
    _height = _u16();
    _width = _u16();
    final int count = _data[_offset++];
    if (_width <= 0 || count < 1 || count > 4) throw const FormatException("Bad frame");
    for (int i = 0; i < count; i++) {
      final int id = _data[_offset];
      final int sampling = _data[_offset + 1];
      final int table = _data[_offset + 2];
      _offset += 3;
      final int h = max(1, sampling >> 4);
      final int v = max(1, sampling & 15);
      _components.add(_UJpegComponent(id, h, v, table & 3));
      _maxH = max(_maxH, h);
      _maxV = max(_maxV, v);
    }
    if (_height == 0) _height = _scanHeightFromDnl();
    _mcusPerLine = (_width / 8 / _maxH).ceil();
    _mcusPerColumn = (_height / 8 / _maxV).ceil();
    for (final _UJpegComponent component in _components) {
      component.blocksPerLine = ((_width / 8).ceil() * component.h / _maxH).ceil();
      component.blocksPerColumn = ((_height / 8).ceil() * component.v / _maxV).ceil();
      final int perLine = _mcusPerLine * component.h;
      final int perColumn = _mcusPerColumn * component.v;
      component.blocks = Int16List(64 * perColumn * (perLine + 1));
    }
    _frameRead = true;
  }

  int _scanHeightFromDnl() {
    for (int i = _offset; i + 5 < _data.length; i++) {
      if (_data[i] == 0xFF && _data[i + 1] == 0xDC) return (_data[i + 4] << 8) | _data[i + 5];
    }
    throw const FormatException("Missing height");
  }

  void _readScan() {
    final int count = _data[_offset++];
    final List<_UJpegComponent> scan = <_UJpegComponent>[];
    for (int i = 0; i < count; i++) {
      final int id = _data[_offset];
      final int tables = _data[_offset + 1];
      _offset += 2;
      final _UJpegComponent component = _components.firstWhere((_UJpegComponent c) => c.id == id, orElse: () => _components[min(i, _components.length - 1)]);
      component.dc = _dcTables[tables >> 4];
      component.ac = _acTables[tables & 15];
      scan.add(component);
    }
    final int spectralStart = _data[_offset];
    final int spectralEnd = _data[_offset + 1];
    final int approximation = _data[_offset + 2];
    _offset += 3;
    _decodeScan(scan, spectralStart, spectralEnd, approximation >> 4, approximation & 15);
  }

  int _readBit() {
    if (_bitCount > 0) {
      _bitCount--;
      return (_bits >> _bitCount) & 1;
    }
    if (_offset >= _data.length) return 0;
    _bits = _data[_offset];
    if (_bits == 0xFF) {
      final int next = _offset + 1 < _data.length ? _data[_offset + 1] : 0;
      if (next != 0) {
        // A marker inside entropy data: feed zeros until the scan loop finds it.
        _bits = 0;
        _bitCount = 7;
        return 0;
      }
      _offset++;
    }
    _offset++;
    _bitCount = 7;
    return (_bits >> 7) & 1;
  }

  int _receive(int length) {
    int value = 0;
    while (length > 0) {
      value = (value << 1) | _readBit();
      length--;
    }
    return value;
  }

  int _receiveExtend(int length) {
    if (length == 0) return 0;
    if (length == 1) return _readBit() == 1 ? 1 : -1;
    final int value = _receive(length);
    if (value >= 1 << (length - 1)) return value;
    return value + (-1 << length) + 1;
  }

  int _decodeHuffman(_UJpegHuffman? table) {
    if (table == null) return 0;
    int code = 0;
    for (int length = 1; length <= 16; length++) {
      code = (code << 1) | _readBit();
      if (code <= table._maxCode[length]) {
        final int index = table._valuePointer[length] + code - table._minCode[length];
        return index < table._values.length ? table._values[index] : 0;
      }
    }
    return 0;
  }

  void _decodeBaseline(_UJpegComponent component, int offset) {
    final Int16List blocks = component.blocks;
    final int t = _decodeHuffman(component.dc);
    component.pred += _receiveExtend(t);
    blocks[offset] = component.pred;
    int k = 1;
    while (k < 64) {
      final int rs = _decodeHuffman(component.ac);
      final int s = rs & 15;
      final int r = rs >> 4;
      if (s == 0) {
        if (r < 15) break;
        k += 16;
        continue;
      }
      k += r;
      if (k > 63) break;
      blocks[offset + UJpeg._zigZag[k]] = _receiveExtend(s);
      k++;
    }
  }

  void _decodeDcFirst(_UJpegComponent component, int offset, int successive) {
    final int t = _decodeHuffman(component.dc);
    component.pred += _receiveExtend(t) << successive;
    component.blocks[offset] = component.pred;
  }

  void _decodeDcSuccessive(_UJpegComponent component, int offset, int successive) {
    if (_readBit() == 1) component.blocks[offset] |= 1 << successive;
  }

  void _decodeAcFirst(_UJpegComponent component, int offset, int start, int end, int successive) {
    if (_eobRun > 0) {
      _eobRun--;
      return;
    }
    int k = start;
    while (k <= end) {
      final int rs = _decodeHuffman(component.ac);
      final int s = rs & 15;
      final int r = rs >> 4;
      if (s == 0) {
        if (r < 15) {
          _eobRun = _receive(r) + (1 << r) - 1;
          break;
        }
        k += 16;
        continue;
      }
      k += r;
      if (k > 63) break;
      component.blocks[offset + UJpeg._zigZag[k]] = _receiveExtend(s) * (1 << successive);
      k++;
    }
  }

  void _decodeAcSuccessive(_UJpegComponent component, int offset, int start, int end, int successive) {
    final Int16List blocks = component.blocks;
    int k = start;
    int r = 0;
    while (k <= end) {
      final int z = offset + UJpeg._zigZag[k];
      final int coefficient = blocks[z];
      final int sign = coefficient < 0 ? -1 : 1;
      switch (_acState) {
        case 0:
          final int rs = _decodeHuffman(component.ac);
          final int s = rs & 15;
          r = rs >> 4;
          if (s == 0) {
            if (r < 15) {
              _eobRun = _receive(r) + (1 << r);
              _acState = 4;
            } else {
              r = 16;
              _acState = 1;
            }
          } else {
            _acNext = _receiveExtend(s);
            _acState = r != 0 ? 2 : 3;
          }
          continue;
        case 1:
        case 2:
          if (coefficient != 0) {
            blocks[z] += sign * (_readBit() << successive);
          } else {
            r--;
            if (r == 0) _acState = _acState == 2 ? 3 : 0;
          }
          break;
        case 3:
          if (coefficient != 0) {
            blocks[z] += sign * (_readBit() << successive);
          } else {
            blocks[z] = _acNext << successive;
            _acState = 0;
          }
          break;
        case 4:
          if (coefficient != 0) blocks[z] += sign * (_readBit() << successive);
          break;
      }
      k++;
    }
    if (_acState == 4) {
      _eobRun--;
      if (_eobRun == 0) _acState = 0;
    }
  }

  void _decodeBlock(_UJpegComponent component, int row, int column, int spectralStart, int spectralEnd, int previous, int successive) {
    final int offset = 64 * ((component.blocksPerLine + 1) * row + column);
    if (offset + 64 > component.blocks.length) return;
    if (!_progressive) {
      _decodeBaseline(component, offset);
    } else if (spectralStart == 0) {
      if (previous == 0) {
        _decodeDcFirst(component, offset, successive);
      } else {
        _decodeDcSuccessive(component, offset, successive);
      }
    } else if (previous == 0) {
      _decodeAcFirst(component, offset, spectralStart, spectralEnd, successive);
    } else {
      _decodeAcSuccessive(component, offset, spectralStart, spectralEnd, successive);
    }
  }

  void _decodeScan(List<_UJpegComponent> scan, int spectralStart, int spectralEnd, int previous, int successive) {
    _bitCount = 0;
    _eobRun = 0;
    _acState = 0;
    final bool single = scan.length == 1;
    final int expected = single ? scan.first.blocksPerLine * scan.first.blocksPerColumn : _mcusPerLine * _mcusPerColumn;
    int mcu = 0;
    while (mcu < expected) {
      final int toRead = _resetInterval > 0 ? min(expected - mcu, _resetInterval) : expected;
      for (final _UJpegComponent component in scan) {
        component.pred = 0;
      }
      _eobRun = 0;
      _acState = 0;
      for (int n = 0; n < toRead; n++) {
        if (single) {
          final _UJpegComponent component = scan.first;
          _decodeBlock(component, mcu ~/ component.blocksPerLine, mcu % component.blocksPerLine, spectralStart, spectralEnd, previous, successive);
        } else {
          final int mcuRow = mcu ~/ _mcusPerLine;
          final int mcuColumn = mcu % _mcusPerLine;
          for (final _UJpegComponent component in scan) {
            for (int j = 0; j < component.v; j++) {
              for (int k = 0; k < component.h; k++) {
                _decodeBlock(component, mcuRow * component.v + j, mcuColumn * component.h + k, spectralStart, spectralEnd, previous, successive);
              }
            }
          }
        }
        mcu++;
      }
      _bitCount = 0;
      final int marker = _nextMarker();
      if (marker < 0) break;
      if (marker >= 0xD0 && marker <= 0xD7) {
        _offset += 2;
        continue;
      }
      break;
    }
    final int marker = _nextMarker();
    if (marker >= 0xD0 && marker <= 0xD7) _offset += 2;
  }

  /// Moves to the next marker (skipping fill bytes and garbage) and returns its code, or -1 at the end.
  int _nextMarker() {
    while (_offset + 1 < _data.length) {
      if (_data[_offset] == 0xFF && _data[_offset + 1] != 0 && _data[_offset + 1] != 0xFF) return _data[_offset + 1];
      _offset++;
    }
    return -1;
  }

  UJpegImage _output() {
    final List<Uint8List> planes = <Uint8List>[];
    for (final _UJpegComponent component in _components) {
      planes.add(_planeOf(component));
    }
    final int count = _components.length;
    final Uint8List out = Uint8List(_width * _height * count);
    for (int c = 0; c < count; c++) {
      final _UJpegComponent component = _components[c];
      final Uint8List plane = planes[c];
      final int stride = component.blocksPerLine * 8;
      final int planeHeight = component.blocksPerColumn * 8;
      final Int32List columns = Int32List(_width);
      for (int x = 0; x < _width; x++) {
        columns[x] = min(x * component.h ~/ _maxH, stride - 1);
      }
      for (int y = 0; y < _height; y++) {
        final int row = min(y * component.v ~/ _maxV, planeHeight - 1) * stride;
        int target = y * _width * count + c;
        for (int x = 0; x < _width; x++) {
          out[target] = plane[row + columns[x]];
          target += count;
        }
      }
    }
    _transformColors(out, count);
    return UJpegImage(width: _width, height: _height, components: count, data: out, adobe: _adobe);
  }

  bool get _needsTransform {
    if (_adobe) return _adobeTransform != 0;
    final int? forced = _colorTransform;
    if (_components.length == 3) {
      if (forced == 0) return false;
      if (_components[0].id == 0x52 && _components[1].id == 0x47 && _components[2].id == 0x42) return false;
      return true;
    }
    if (_components.length == 4) return forced == 1;
    return false;
  }

  void _transformColors(Uint8List data, int count) {
    if ((count != 3 && count != 4) || !_needsTransform) return;
    for (int i = 0; i + count <= data.length; i += count) {
      final int y = data[i];
      final int cb = data[i + 1] - 128;
      final int cr = data[i + 2] - 128;
      final int r = (y + 1.402 * cr).round().clamp(0, 255);
      final int g = (y - 0.344136 * cb - 0.714136 * cr).round().clamp(0, 255);
      final int b = (y + 1.772 * cb).round().clamp(0, 255);
      if (count == 3) {
        data[i] = r;
        data[i + 1] = g;
        data[i + 2] = b;
      } else {
        data[i] = 255 - r;
        data[i + 1] = 255 - g;
        data[i + 2] = 255 - b;
      }
    }
  }

  Uint8List _planeOf(_UJpegComponent component) {
    final int stride = component.blocksPerLine * 8;
    final Uint8List plane = Uint8List(stride * component.blocksPerColumn * 8);
    final Int32List quant = _quant[component.quantTable] ?? (Int32List(64)..fillRange(0, 64, 1));
    final Int32List coefficients = Int32List(64);
    final Int32List work = Int32List(64);
    for (int row = 0; row < component.blocksPerColumn; row++) {
      for (int column = 0; column < component.blocksPerLine; column++) {
        final int offset = 64 * ((component.blocksPerLine + 1) * row + column);
        if (offset + 64 > component.blocks.length) continue;
        for (int i = 0; i < 64; i++) {
          coefficients[i] = component.blocks[offset + i] * quant[i];
        }
        _idct(coefficients, work, plane, row * 8 * stride + column * 8, stride);
      }
    }
    return plane;
  }

  static int _clamp(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);

  /// Integer inverse DCT (the islow algorithm, 12-bit fixed point).
  static void _idct(Int32List d, Int32List v, Uint8List out, int outOffset, int stride) {
    for (int i = 0; i < 8; i++) {
      if (d[i + 8] == 0 && d[i + 16] == 0 && d[i + 24] == 0 && d[i + 32] == 0 && d[i + 40] == 0 && d[i + 48] == 0 && d[i + 56] == 0) {
        final int dc = d[i] * 4;
        v[i] = dc;
        v[i + 8] = dc;
        v[i + 16] = dc;
        v[i + 24] = dc;
        v[i + 32] = dc;
        v[i + 40] = dc;
        v[i + 48] = dc;
        v[i + 56] = dc;
        continue;
      }
      int p2 = d[i + 16];
      int p3 = d[i + 48];
      int p1 = (p2 + p3) * 2217;
      int t2 = p1 + p3 * -7567;
      int t3 = p1 + p2 * 3135;
      p2 = d[i];
      p3 = d[i + 32];
      int t0 = (p2 + p3) * 4096;
      int t1 = (p2 - p3) * 4096;
      final int x0 = t0 + t3 + 512;
      final int x3 = t0 - t3 + 512;
      final int x1 = t1 + t2 + 512;
      final int x2 = t1 - t2 + 512;
      t0 = d[i + 56];
      t1 = d[i + 40];
      t2 = d[i + 24];
      t3 = d[i + 8];
      p3 = t0 + t2;
      int p4 = t1 + t3;
      p1 = t0 + t3;
      p2 = t1 + t2;
      final int p5 = (p3 + p4) * 4816;
      t0 = t0 * 1223;
      t1 = t1 * 8410;
      t2 = t2 * 12586;
      t3 = t3 * 6149;
      p1 = p5 + p1 * -3685;
      p2 = p5 + p2 * -10497;
      p3 = p3 * -8034;
      p4 = p4 * -1598;
      t3 += p1 + p4;
      t2 += p2 + p3;
      t1 += p2 + p4;
      t0 += p1 + p3;
      v[i] = (x0 + t3) >> 10;
      v[i + 56] = (x0 - t3) >> 10;
      v[i + 8] = (x1 + t2) >> 10;
      v[i + 48] = (x1 - t2) >> 10;
      v[i + 16] = (x2 + t1) >> 10;
      v[i + 40] = (x2 - t1) >> 10;
      v[i + 24] = (x3 + t0) >> 10;
      v[i + 32] = (x3 - t0) >> 10;
    }
    for (int i = 0; i < 8; i++) {
      final int r = i * 8;
      int p2 = v[r + 2];
      int p3 = v[r + 6];
      int p1 = (p2 + p3) * 2217;
      int t2 = p1 + p3 * -7567;
      int t3 = p1 + p2 * 3135;
      p2 = v[r];
      p3 = v[r + 4];
      int t0 = (p2 + p3) * 4096;
      int t1 = (p2 - p3) * 4096;
      const int bias = 65536 + (128 << 17);
      final int x0 = t0 + t3 + bias;
      final int x3 = t0 - t3 + bias;
      final int x1 = t1 + t2 + bias;
      final int x2 = t1 - t2 + bias;
      t0 = v[r + 7];
      t1 = v[r + 5];
      t2 = v[r + 3];
      t3 = v[r + 1];
      p3 = t0 + t2;
      int p4 = t1 + t3;
      p1 = t0 + t3;
      p2 = t1 + t2;
      final int p5 = (p3 + p4) * 4816;
      t0 = t0 * 1223;
      t1 = t1 * 8410;
      t2 = t2 * 12586;
      t3 = t3 * 6149;
      p1 = p5 + p1 * -3685;
      p2 = p5 + p2 * -10497;
      p3 = p3 * -8034;
      p4 = p4 * -1598;
      t3 += p1 + p4;
      t2 += p2 + p3;
      t1 += p2 + p4;
      t0 += p1 + p3;
      final int o = outOffset + i * stride;
      out[o] = _clamp((x0 + t3) >> 17);
      out[o + 7] = _clamp((x0 - t3) >> 17);
      out[o + 1] = _clamp((x1 + t2) >> 17);
      out[o + 6] = _clamp((x1 - t2) >> 17);
      out[o + 2] = _clamp((x2 + t1) >> 17);
      out[o + 5] = _clamp((x2 - t1) >> 17);
      out[o + 3] = _clamp((x3 + t0) >> 17);
      out[o + 4] = _clamp((x3 - t0) >> 17);
    }
  }
}
