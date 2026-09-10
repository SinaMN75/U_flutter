import "package:u/utilities.dart";

class UJbig2Bitmap {
  UJbig2Bitmap(this.width, this.height, {int fill = 0}) : data = Uint8List(width * height) {
    if (fill != 0) data.fillRange(0, data.length, 1);
  }

  final int width;
  final int height;
  final Uint8List data;

  int get(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return 0;
    return data[y * width + x];
  }

  void set(int x, int y, int value) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    data[y * width + x] = value;
  }

  void combine(UJbig2Bitmap other, int x0, int y0, int operation) {
    for (int y = 0; y < other.height; y++) {
      final int targetY = y0 + y;
      if (targetY < 0 || targetY >= height) continue;
      for (int x = 0; x < other.width; x++) {
        final int targetX = x0 + x;
        if (targetX < 0 || targetX >= width) continue;
        final int source = other.data[y * other.width + x];
        final int index = targetY * width + targetX;
        switch (operation) {
          case 0:
            data[index] |= source;
            break;
          case 1:
            data[index] &= source;
            break;
          case 2:
            data[index] ^= source;
            break;
          case 3:
            data[index] = (~(data[index] ^ source)) & 1;
            break;
          default:
            data[index] = source;
            break;
        }
      }
    }
  }

  Uint8List toPackedRows({bool blackIsOne = true}) {
    final int rowBytes = (width + 7) >> 3;
    final Uint8List out = Uint8List(rowBytes * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int value = data[y * width + x];
        final bool bit = blackIsOne ? value == 0 : value != 0;
        if (bit) out[y * rowBytes + (x >> 3)] |= 0x80 >> (x & 7);
      }
    }
    return out;
  }
}

abstract class UJbig2ArithmeticDecoderTables {
  static const List<int> qe = <int>[
    0x5601,
    0x3401,
    0x1801,
    0x0AC1,
    0x0521,
    0x0221,
    0x5601,
    0x5401,
    0x4801,
    0x3801,
    0x3001,
    0x2401,
    0x1C01,
    0x1601,
    0x5601,
    0x5401,
    0x5101,
    0x4801,
    0x3801,
    0x3401,
    0x3001,
    0x2801,
    0x2401,
    0x2201,
    0x1C01,
    0x1801,
    0x1601,
    0x1401,
    0x1201,
    0x1101,
    0x0AC1,
    0x09C1,
    0x08A1,
    0x0521,
    0x0441,
    0x02A1,
    0x0221,
    0x0141,
    0x0111,
    0x0085,
    0x0049,
    0x0025,
    0x0015,
    0x0009,
    0x0005,
    0x0001,
    0x5601,
  ];

  static const List<int> nmps = <int>[
    1,
    2,
    3,
    4,
    5,
    38,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    29,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    45,
    45,
    46,
  ];

  static const List<int> nlps = <int>[
    1,
    6,
    9,
    12,
    29,
    33,
    6,
    14,
    14,
    14,
    17,
    18,
    20,
    21,
    14,
    14,
    15,
    16,
    17,
    18,
    19,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    46,
  ];

  static const List<int> switchTable = <int>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];
}

class UJbig2ArithmeticDecoder {
  UJbig2ArithmeticDecoder(this.data, {this.start = 0, int? end}) : _end = end ?? data.length {
    _bp = start;
    _chigh = _byteAt(_bp);
    _byteIn();
    _chigh = ((_chigh << 7) & 0xFFFF) | ((_clow >> 9) & 0x7F);
    _clow = (_clow << 7) & 0xFFFF;
    _ct -= 7;
    _a = 0x8000;
  }

  static const List<int> _qe = UJbig2ArithmeticDecoderTables.qe;
  static const List<int> _nmps = UJbig2ArithmeticDecoderTables.nmps;
  static const List<int> _nlps = UJbig2ArithmeticDecoderTables.nlps;
  static const List<int> _switch = UJbig2ArithmeticDecoderTables.switchTable;

  final Uint8List data;
  final int start;
  final int _end;

  int _bp = 0;
  int _chigh = 0;
  int _clow = 0;
  int _ct = 0;
  int _a = 0;

  int _byteAt(int index) => index < _end && index < data.length ? data[index] : 0xFF;

  void _byteIn() {
    if (_byteAt(_bp) == 0xFF) {
      if (_byteAt(_bp + 1) > 0x8F) {
        _clow += 0xFF00;
        _ct = 8;
      } else {
        _bp++;
        _clow += _byteAt(_bp) << 9;
        _ct = 7;
      }
    } else {
      _bp++;
      _clow += _bp < _end ? _byteAt(_bp) << 8 : 0xFF00;
      _ct = 8;
    }
    if (_clow > 0xFFFF) {
      _chigh += _clow >> 16;
      _clow &= 0xFFFF;
    }
  }

  int decode(Uint8List contexts, int contextIndex) {
    int cxIndex = (contexts[contextIndex] >> 1) & 0x7F;
    int cxMps = contexts[contextIndex] & 1;
    final int qe = _qe[cxIndex];
    int d;
    _a -= qe;
    if (_chigh < qe) {
      if (_a < qe) {
        _a = qe;
        d = cxMps;
        cxIndex = _nmps[cxIndex];
      } else {
        _a = qe;
        d = 1 ^ cxMps;
        if (_switch[cxIndex] == 1) cxMps = d;
        cxIndex = _nlps[cxIndex];
      }
    } else {
      _chigh -= qe;
      if ((_a & 0x8000) != 0) return cxMps;
      if (_a < qe) {
        d = 1 ^ cxMps;
        if (_switch[cxIndex] == 1) cxMps = d;
        cxIndex = _nlps[cxIndex];
      } else {
        d = cxMps;
        cxIndex = _nmps[cxIndex];
      }
    }
    do {
      if (_ct == 0) _byteIn();
      _a <<= 1;
      _chigh = ((_chigh << 1) & 0xFFFF) | ((_clow >> 15) & 1);
      _clow = (_clow << 1) & 0xFFFF;
      _ct--;
    } while ((_a & 0x8000) == 0);
    contexts[contextIndex] = (cxIndex << 1) | cxMps;
    return d;
  }
}

class UJbig2GenericRegion {
  UJbig2GenericRegion({required this.width, required this.height, required this.template, required this.at, this.tpgdon = false});

  final int width;
  final int height;
  final int template;
  final List<int> at;
  final bool tpgdon;

  UJbig2Bitmap decode(UJbig2ArithmeticDecoder decoder, Uint8List contexts) {
    final UJbig2Bitmap bitmap = UJbig2Bitmap(width, height);
    int ltp = 0;
    for (int y = 0; y < height; y++) {
      if (tpgdon) {
        final int context = _tpgdonContext();
        if (decoder.decode(contexts, context) == 1) ltp ^= 1;
        if (ltp == 1) {
          if (y > 0) {
            for (int x = 0; x < width; x++) {
              bitmap.set(x, y, bitmap.get(x, y - 1));
            }
          }
          continue;
        }
      }
      for (int x = 0; x < width; x++) {
        final int context = _contextAt(bitmap, x, y);
        bitmap.set(x, y, decoder.decode(contexts, context));
      }
    }
    return bitmap;
  }

  int contextFor(UJbig2Bitmap bitmap, int x, int y) => _contextAt(bitmap, x, y);

  int _tpgdonContext() {
    switch (template) {
      case 0:
        return 0x9B25;
      case 1:
        return 0x0795;
      case 2:
        return 0x00E5;
      default:
        return 0x0195;
    }
  }

  int _at(int index, int offset) => index * 2 + offset < at.length ? at[index * 2 + offset] : 0;

  int _contextAt(UJbig2Bitmap bitmap, int x, int y) {
    switch (template) {
      case 0:
        return (bitmap.get(x - 1, y) << 0) |
            (bitmap.get(x - 2, y) << 1) |
            (bitmap.get(x - 3, y) << 2) |
            (bitmap.get(x - 4, y) << 3) |
            (bitmap.get(x + _at(0, 0), y + _at(0, 1)) << 4) |
            (bitmap.get(x + 2, y - 1) << 5) |
            (bitmap.get(x + 1, y - 1) << 6) |
            (bitmap.get(x, y - 1) << 7) |
            (bitmap.get(x - 1, y - 1) << 8) |
            (bitmap.get(x - 2, y - 1) << 9) |
            (bitmap.get(x + _at(1, 0), y + _at(1, 1)) << 10) |
            (bitmap.get(x + _at(2, 0), y + _at(2, 1)) << 11) |
            (bitmap.get(x + 1, y - 2) << 12) |
            (bitmap.get(x, y - 2) << 13) |
            (bitmap.get(x - 1, y - 2) << 14) |
            (bitmap.get(x + _at(3, 0), y + _at(3, 1)) << 15);
      case 1:
        return (bitmap.get(x - 1, y) << 0) |
            (bitmap.get(x - 2, y) << 1) |
            (bitmap.get(x - 3, y) << 2) |
            (bitmap.get(x + _at(0, 0), y + _at(0, 1)) << 3) |
            (bitmap.get(x + 2, y - 1) << 4) |
            (bitmap.get(x + 1, y - 1) << 5) |
            (bitmap.get(x, y - 1) << 6) |
            (bitmap.get(x - 1, y - 1) << 7) |
            (bitmap.get(x - 2, y - 1) << 8) |
            (bitmap.get(x + 2, y - 2) << 9) |
            (bitmap.get(x + 1, y - 2) << 10) |
            (bitmap.get(x, y - 2) << 11) |
            (bitmap.get(x - 1, y - 2) << 12);
      case 2:
        return (bitmap.get(x - 1, y) << 0) |
            (bitmap.get(x - 2, y) << 1) |
            (bitmap.get(x + _at(0, 0), y + _at(0, 1)) << 2) |
            (bitmap.get(x + 1, y - 1) << 3) |
            (bitmap.get(x, y - 1) << 4) |
            (bitmap.get(x - 1, y - 1) << 5) |
            (bitmap.get(x - 2, y - 1) << 6) |
            (bitmap.get(x + 1, y - 2) << 7) |
            (bitmap.get(x, y - 2) << 8) |
            (bitmap.get(x - 1, y - 2) << 9);
      default:
        return (bitmap.get(x - 1, y) << 0) |
            (bitmap.get(x - 2, y) << 1) |
            (bitmap.get(x - 3, y) << 2) |
            (bitmap.get(x - 4, y) << 3) |
            (bitmap.get(x + _at(0, 0), y + _at(0, 1)) << 4) |
            (bitmap.get(x + 1, y - 1) << 5) |
            (bitmap.get(x, y - 1) << 6) |
            (bitmap.get(x - 1, y - 1) << 7) |
            (bitmap.get(x - 2, y - 1) << 8) |
            (bitmap.get(x - 3, y - 1) << 9);
    }
  }
}

class UJbig2Segment {
  const UJbig2Segment({required this.number, required this.type, required this.dataStart, required this.dataEnd, required this.referred});

  final int number;
  final int type;
  final int dataStart;
  final int dataEnd;
  final List<int> referred;
}

abstract class UJbig2 {
  static const int typeImmediateGenericRegion = 38;
  static const int typeImmediateLosslessGenericRegion = 39;
  static const int typeIntermediateGenericRegion = 36;
  static const int typePageInformation = 48;

  static Uint8List? decode(Uint8List data, {required int width, required int height, Uint8List? globals}) {
    try {
      final UJbig2Bitmap page = UJbig2Bitmap(width, height);
      bool painted = false;
      if (globals != null && globals.isNotEmpty) painted = _run(globals, page) || painted;
      painted = _run(data, page) || painted;
      if (!painted) return null;
      return page.toPackedRows();
    } on Object {
      return null;
    }
  }

  static bool _run(Uint8List data, UJbig2Bitmap page) {
    final List<UJbig2Segment> segments = parseSegments(data);
    bool painted = false;
    for (final UJbig2Segment segment in segments) {
      if (segment.type != typeImmediateGenericRegion && segment.type != typeImmediateLosslessGenericRegion && segment.type != typeIntermediateGenericRegion) continue;
      final UJbig2Bitmap? region = _decodeGenericRegion(data, segment, page);
      if (region != null) painted = true;
    }
    return painted;
  }

  static List<UJbig2Segment> parseSegments(Uint8List data) {
    final List<UJbig2Segment> segments = <UJbig2Segment>[];
    int offset = 0;
    int guard = 0;
    while (offset + 11 <= data.length && guard < 10000) {
      guard++;
      final int number = _u32(data, offset);
      final int flags = data[offset + 4];
      final int type = flags & 0x3F;
      final bool pageAssociationLarge = (flags & 0x40) != 0;
      int position = offset + 5;
      final int referredFlags = data[position];
      int referredCount = (referredFlags >> 5) & 7;
      if (referredCount == 7) {
        referredCount = _u32(data, position) & 0x1FFFFFFF;
        position += 4 + ((referredCount + 8) >> 3);
      } else {
        position += 1;
      }
      final int referenceSize = number <= 256 ? 1 : (number <= 65536 ? 2 : 4);
      final List<int> referred = <int>[];
      for (int i = 0; i < referredCount; i++) {
        if (position + referenceSize > data.length) break;
        referred.add(referenceSize == 1 ? data[position] : (referenceSize == 2 ? _u16(data, position) : _u32(data, position)));
        position += referenceSize;
      }
      position += pageAssociationLarge ? 4 : 1;
      if (position + 4 > data.length) break;
      final int length = _u32(data, position);
      position += 4;
      final int end = length == 0xFFFFFFFF ? data.length : (position + length > data.length ? data.length : position + length);
      segments.add(UJbig2Segment(number: number, type: type, dataStart: position, dataEnd: end, referred: referred));
      if (length == 0xFFFFFFFF) break;
      offset = end;
    }
    return segments;
  }

  static UJbig2Bitmap? _decodeGenericRegion(Uint8List data, UJbig2Segment segment, UJbig2Bitmap page) {
    int position = segment.dataStart;
    if (position + 18 > data.length) return null;
    final int regionWidth = _u32(data, position);
    final int regionHeight = _u32(data, position + 4);
    final int regionX = _u32(data, position + 8);
    final int regionY = _u32(data, position + 12);
    final int combinationOperator = data[position + 16] & 7;
    position += 17;
    if (position >= data.length) return null;
    final int flags = data[position];
    position++;
    final bool mmr = (flags & 1) != 0;
    final int template = (flags >> 1) & 3;
    final bool tpgdon = (flags & 8) != 0;
    if (regionWidth <= 0 || regionHeight <= 0 || regionWidth > 20000 || regionHeight > 20000) return null;
    final List<int> at = <int>[];
    if (!mmr) {
      final int count = template == 0 ? 4 : 1;
      for (int i = 0; i < count; i++) {
        if (position + 1 >= data.length) break;
        at.add(_i8(data[position]));
        at.add(_i8(data[position + 1]));
        position += 2;
      }
    }
    UJbig2Bitmap bitmap;
    if (mmr) {
      final Uint8List packed = UPdfCcittDecoder(columns: regionWidth, rows: regionHeight, k: -1, blackIs1: true, byteAlign: false).decode(Uint8List.sublistView(data, position, segment.dataEnd));
      bitmap = UJbig2Bitmap(regionWidth, regionHeight);
      final int rowBytes = (regionWidth + 7) >> 3;
      for (int y = 0; y < regionHeight; y++) {
        for (int x = 0; x < regionWidth; x++) {
          final int index = y * rowBytes + (x >> 3);
          if (index >= packed.length) break;
          bitmap.set(x, y, (packed[index] >> (7 - (x & 7))) & 1);
        }
      }
    } else {
      final UJbig2ArithmeticDecoder decoder = UJbig2ArithmeticDecoder(data, start: position, end: segment.dataEnd);
      final Uint8List contexts = Uint8List(1 << 16);
      bitmap = UJbig2GenericRegion(width: regionWidth, height: regionHeight, template: template, at: at, tpgdon: tpgdon).decode(decoder, contexts);
    }
    page.combine(bitmap, regionX, regionY, combinationOperator);
    return bitmap;
  }

  static int _u16(Uint8List data, int offset) => offset + 1 < data.length ? (data[offset] << 8) | data[offset + 1] : 0;

  static int _u32(Uint8List data, int offset) => offset + 3 < data.length ? (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3] : 0;

  static int _i8(int value) => value > 127 ? value - 256 : value;
}
