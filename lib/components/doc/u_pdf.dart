import "package:u/utilities.dart";

class UPdfInflater {
  UPdfInflater(this._input, {int start = 0}) : _pos = start;

  final Uint8List _input;
  int _pos;
  int _bitBuffer = 0;
  int _bitCount = 0;
  bool _truncated = false;

  final List<int> _out = <int>[];

  static const List<int> _lengthBase = <int>[3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258];
  static const List<int> _lengthExtra = <int>[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0];
  static const List<int> _distanceBase = <int>[1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577];
  static const List<int> _distanceExtra = <int>[0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13];
  static const List<int> _codeLengthOrder = <int>[16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

  bool get truncated => _truncated;

  int _bits(int count) {
    while (_bitCount < count) {
      if (_pos >= _input.length) {
        _truncated = true;
        throw const UDocParseException("Deflate stream ended early");
      }
      _bitBuffer |= _input[_pos++] << _bitCount;
      _bitCount += 8;
    }
    final int value = _bitBuffer & ((1 << count) - 1);
    _bitBuffer >>= count;
    _bitCount -= count;
    return value;
  }

  void _align() {
    _bitBuffer = 0;
    _bitCount = 0;
  }

  static List<int> _buildTable(List<int> lengths) {
    int maxBits = 0;
    for (final int length in lengths) {
      if (length > maxBits) maxBits = length;
    }
    if (maxBits == 0) return <int>[0];
    final List<int> counts = List<int>.filled(maxBits + 1, 0);
    for (final int length in lengths) {
      if (length > 0) counts[length]++;
    }
    final List<int> offsets = List<int>.filled(maxBits + 2, 0);
    for (int i = 1; i <= maxBits; i++) {
      offsets[i + 1] = offsets[i] + counts[i];
    }
    final List<int> sorted = List<int>.filled(lengths.length, 0);
    for (int symbol = 0; symbol < lengths.length; symbol++) {
      final int length = lengths[symbol];
      if (length > 0) sorted[offsets[length]++] = symbol;
    }
    final List<int> table = <int>[maxBits];
    table.addAll(counts);
    table.addAll(sorted);
    return table;
  }

  int _decode(List<int> table) {
    final int maxBits = table[0];
    int code = 0;
    int first = 0;
    int index = 0;
    for (int length = 1; length <= maxBits; length++) {
      code |= _bits(1);
      final int count = table[length + 1];
      if (code - first < count) return table[maxBits + 2 + index + (code - first)];
      index += count;
      first = (first + count) << 1;
      code <<= 1;
    }
    throw const UDocParseException("Invalid huffman code");
  }

  void _copyStored() {
    _align();
    if (_pos + 4 > _input.length) {
      _truncated = true;
      return;
    }
    final int length = _input[_pos] | (_input[_pos + 1] << 8);
    _pos += 4;
    final int available = _input.length - _pos;
    final int take = length > available ? available : length;
    if (take < length) _truncated = true;
    for (int i = 0; i < take; i++) {
      _out.add(_input[_pos + i]);
    }
    _pos += take;
  }

  void _block(List<int> literals, List<int> distances) {
    while (true) {
      final int symbol = _decode(literals);
      if (symbol < 256) {
        _out.add(symbol);
        continue;
      }
      if (symbol == 256) return;
      final int lengthIndex = symbol - 257;
      if (lengthIndex >= _lengthBase.length) throw const UDocParseException("Invalid length symbol");
      final int length = _lengthBase[lengthIndex] + _bits(_lengthExtra[lengthIndex]);
      final int distanceSymbol = _decode(distances);
      if (distanceSymbol >= _distanceBase.length) throw const UDocParseException("Invalid distance symbol");
      final int distance = _distanceBase[distanceSymbol] + _bits(_distanceExtra[distanceSymbol]);
      if (distance > _out.length) throw const UDocParseException("Distance beyond output");
      final int start = _out.length - distance;
      for (int i = 0; i < length; i++) {
        _out.add(_out[start + i]);
      }
    }
  }

  Uint8List run() {
    try {
      while (true) {
        final int last = _bits(1);
        final int type = _bits(2);
        if (type == 0) {
          _copyStored();
        } else if (type == 1) {
          _block(_fixedLiterals, _fixedDistances);
        } else if (type == 2) {
          _dynamicBlock();
        } else {
          throw const UDocParseException("Invalid deflate block type");
        }
        if (last == 1) break;
        if (_pos >= _input.length && _bitCount == 0) break;
      }
    } on UDocParseException {
      _truncated = true;
    }
    return Uint8List.fromList(_out);
  }

  void _dynamicBlock() {
    final int literalCount = _bits(5) + 257;
    final int distanceCount = _bits(5) + 1;
    final int codeCount = _bits(4) + 4;
    final List<int> codeLengths = List<int>.filled(19, 0);
    for (int i = 0; i < codeCount; i++) {
      codeLengths[_codeLengthOrder[i]] = _bits(3);
    }
    final List<int> codeTable = _buildTable(codeLengths);
    final List<int> lengths = List<int>.filled(literalCount + distanceCount, 0);
    int index = 0;
    while (index < lengths.length) {
      final int symbol = _decode(codeTable);
      if (symbol < 16) {
        lengths[index++] = symbol;
      } else if (symbol == 16) {
        final int previous = index > 0 ? lengths[index - 1] : 0;
        final int repeat = 3 + _bits(2);
        for (int i = 0; i < repeat && index < lengths.length; i++) {
          lengths[index++] = previous;
        }
      } else if (symbol == 17) {
        index += 3 + _bits(3);
      } else {
        index += 11 + _bits(7);
      }
    }
    _block(_buildTable(lengths.sublist(0, literalCount)), _buildTable(lengths.sublist(literalCount)));
  }

  static final List<int> _fixedLiterals = _buildTable(_fixedLiteralLengths());
  static final List<int> _fixedDistances = _buildTable(List<int>.filled(30, 5));

  static List<int> _fixedLiteralLengths() {
    final List<int> lengths = List<int>.filled(288, 8);
    for (int i = 144; i < 256; i++) {
      lengths[i] = 9;
    }
    for (int i = 256; i < 280; i++) {
      lengths[i] = 7;
    }
    return lengths;
  }
}

abstract class UPdfCodecs {
  static Uint8List inflate(Uint8List input) {
    if (input.isEmpty) return input;
    if (!kIsWeb) {
      try {
        return Uint8List.fromList(zlib.decode(input));
      } on Object {
        return _dartInflate(input);
      }
    }
    return _dartInflate(input);
  }

  static Uint8List _dartInflate(Uint8List input) {
    final bool hasHeader = input.length > 2 && (input[0] & 0x0F) == 8 && ((input[0] << 8) | input[1]) % 31 == 0;
    final UPdfInflater inflater = UPdfInflater(input, start: hasHeader ? 2 : 0);
    final Uint8List result = inflater.run();
    if (result.isNotEmpty || !hasHeader) return result;
    return UPdfInflater(input).run();
  }

  static Uint8List deflate(Uint8List input) {
    if (kIsWeb) return input;
    try {
      return Uint8List.fromList(zlib.encode(input));
    } on Object {
      return input;
    }
  }

  static Uint8List asciiHex(Uint8List input) {
    final List<int> out = <int>[];
    int high = -1;
    for (final int byte in input) {
      if (byte == 0x3E) break;
      final int digit = _hexDigit(byte);
      if (digit < 0) continue;
      if (high < 0) {
        high = digit;
      } else {
        out.add((high << 4) | digit);
        high = -1;
      }
    }
    if (high >= 0) out.add(high << 4);
    return Uint8List.fromList(out);
  }

  static int _hexDigit(int byte) {
    if (byte >= 0x30 && byte <= 0x39) return byte - 0x30;
    if (byte >= 0x41 && byte <= 0x46) return byte - 0x37;
    if (byte >= 0x61 && byte <= 0x66) return byte - 0x57;
    return -1;
  }

  static Uint8List ascii85(Uint8List input) {
    final List<int> out = <int>[];
    final List<int> group = <int>[];
    int index = 0;
    if (input.length >= 2 && input[0] == 0x3C && input[1] == 0x7E) index = 2;
    while (index < input.length) {
      final int byte = input[index++];
      if (byte == 0x7E) break;
      if (byte <= 0x20 || byte == 0x0A || byte == 0x0D) continue;
      if (byte == 0x7A && group.isEmpty) {
        out.addAll(const <int>[0, 0, 0, 0]);
        continue;
      }
      if (byte < 0x21 || byte > 0x75) continue;
      group.add(byte - 0x21);
      if (group.length == 5) {
        _emit85(group, out, 4);
        group.clear();
      }
    }
    if (group.isNotEmpty) {
      final int count = group.length - 1;
      while (group.length < 5) {
        group.add(84);
      }
      _emit85(group, out, count);
    }
    return Uint8List.fromList(out);
  }

  static void _emit85(List<int> group, List<int> out, int count) {
    int value = 0;
    for (final int digit in group) {
      value = value * 85 + digit;
    }
    final List<int> bytes = <int>[(value ~/ 16777216) % 256, (value ~/ 65536) % 256, (value ~/ 256) % 256, value % 256];
    out.addAll(bytes.sublist(0, count));
  }

  static Uint8List runLength(Uint8List input) {
    final List<int> out = <int>[];
    int index = 0;
    while (index < input.length) {
      final int marker = input[index++];
      if (marker == 128) break;
      if (marker < 128) {
        final int count = marker + 1;
        for (int i = 0; i < count && index < input.length; i++) {
          out.add(input[index++]);
        }
      } else {
        if (index >= input.length) break;
        final int byte = input[index++];
        for (int i = 0; i < 257 - marker; i++) {
          out.add(byte);
        }
      }
    }
    return Uint8List.fromList(out);
  }

  static Uint8List lzw(Uint8List input, {int earlyChange = 1}) {
    final List<int> out = <int>[];
    final List<List<int>> table = <List<int>>[];
    void reset() {
      table.clear();
      for (int i = 0; i < 256; i++) {
        table.add(<int>[i]);
      }
      table.add(<int>[]);
      table.add(<int>[]);
    }

    reset();
    int codeWidth = 9;
    int buffer = 0;
    int bits = 0;
    List<int>? previous;
    for (final int byte in input) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= codeWidth) {
        final int code = (buffer >> (bits - codeWidth)) & ((1 << codeWidth) - 1);
        bits -= codeWidth;
        if (code == 256) {
          reset();
          codeWidth = 9;
          previous = null;
          continue;
        }
        if (code == 257) return Uint8List.fromList(out);
        List<int> entry;
        if (code < table.length && table[code].isNotEmpty) {
          entry = table[code];
        } else if (previous != null) {
          entry = <int>[...previous, previous.first];
        } else {
          return Uint8List.fromList(out);
        }
        out.addAll(entry);
        if (previous != null) table.add(<int>[...previous, entry.first]);
        previous = entry;
        if (table.length + earlyChange >= (1 << codeWidth) && codeWidth < 12) codeWidth++;
      }
    }
    return Uint8List.fromList(out);
  }

  static Uint8List predictor(Uint8List data, {required int predictor, required int colors, required int bitsPerComponent, required int columns}) {
    if (predictor <= 1) return data;
    final int bytesPerPixel = ((colors * bitsPerComponent) / 8).ceil().clamp(1, 64).toInt();
    final int rowLength = ((columns * colors * bitsPerComponent) / 8).ceil();
    if (predictor == 2) return _tiffPredictor(data, colors: colors, bitsPerComponent: bitsPerComponent, columns: columns);
    final List<int> out = <int>[];
    final Uint8List previous = Uint8List(rowLength);
    int index = 0;
    while (index + 1 <= data.length) {
      final int filter = data[index++];
      final int available = data.length - index;
      final int take = available < rowLength ? available : rowLength;
      if (take <= 0) break;
      final Uint8List row = Uint8List(rowLength);
      row.setRange(0, take, data, index);
      index += take;
      switch (filter) {
        case 0:
          break;
        case 1:
          for (int i = bytesPerPixel; i < rowLength; i++) {
            row[i] = (row[i] + row[i - bytesPerPixel]) & 0xFF;
          }
          break;
        case 2:
          for (int i = 0; i < rowLength; i++) {
            row[i] = (row[i] + previous[i]) & 0xFF;
          }
          break;
        case 3:
          for (int i = 0; i < rowLength; i++) {
            final int left = i >= bytesPerPixel ? row[i - bytesPerPixel] : 0;
            row[i] = (row[i] + ((left + previous[i]) >> 1)) & 0xFF;
          }
          break;
        case 4:
          for (int i = 0; i < rowLength; i++) {
            final int left = i >= bytesPerPixel ? row[i - bytesPerPixel] : 0;
            final int up = previous[i];
            final int upLeft = i >= bytesPerPixel ? previous[i - bytesPerPixel] : 0;
            row[i] = (row[i] + _paeth(left, up, upLeft)) & 0xFF;
          }
          break;
        default:
          break;
      }
      out.addAll(row);
      previous.setAll(0, row);
    }
    return Uint8List.fromList(out);
  }

  static int _paeth(int a, int b, int c) {
    final int p = a + b - c;
    final int pa = (p - a).abs();
    final int pb = (p - b).abs();
    final int pc = (p - c).abs();
    if (pa <= pb && pa <= pc) return a;
    return pb <= pc ? b : c;
  }

  static Uint8List _tiffPredictor(Uint8List data, {required int colors, required int bitsPerComponent, required int columns}) {
    if (bitsPerComponent != 8) return data;
    final int rowLength = columns * colors;
    final Uint8List out = Uint8List.fromList(data);
    for (int row = 0; row * rowLength < out.length; row++) {
      final int base = row * rowLength;
      for (int i = colors; i < rowLength && base + i < out.length; i++) {
        out[base + i] = (out[base + i] + out[base + i - colors]) & 0xFF;
      }
    }
    return out;
  }
}

abstract class UPdfDigest {
  static Uint8List md5(List<int> message) {
    const List<int> shifts = <int>[
      7,
      12,
      17,
      22,
      7,
      12,
      17,
      22,
      7,
      12,
      17,
      22,
      7,
      12,
      17,
      22,
      5,
      9,
      14,
      20,
      5,
      9,
      14,
      20,
      5,
      9,
      14,
      20,
      5,
      9,
      14,
      20,
      4,
      11,
      16,
      23,
      4,
      11,
      16,
      23,
      4,
      11,
      16,
      23,
      4,
      11,
      16,
      23,
      6,
      10,
      15,
      21,
      6,
      10,
      15,
      21,
      6,
      10,
      15,
      21,
      6,
      10,
      15,
      21,
    ];
    final List<int> table = List<int>.generate(64, (int i) => ((sin(i + 1).abs()) * 4294967296).floor() & 0xFFFFFFFF);
    final List<int> padded = _padLittleEndian(message);
    int a0 = 0x67452301;
    int b0 = 0xefcdab89;
    int c0 = 0x98badcfe;
    int d0 = 0x10325476;
    for (int chunk = 0; chunk < padded.length; chunk += 64) {
      final List<int> words = List<int>.generate(16, (int i) => padded[chunk + i * 4] | (padded[chunk + i * 4 + 1] << 8) | (padded[chunk + i * 4 + 2] << 16) | (padded[chunk + i * 4 + 3] << 24));
      int a = a0;
      int b = b0;
      int c = c0;
      int d = d0;
      for (int i = 0; i < 64; i++) {
        int f;
        int g;
        if (i < 16) {
          f = (b & c) | (~b & d);
          g = i;
        } else if (i < 32) {
          f = (d & b) | (~d & c);
          g = (5 * i + 1) % 16;
        } else if (i < 48) {
          f = b ^ c ^ d;
          g = (3 * i + 5) % 16;
        } else {
          f = c ^ (b | (~d & 0xFFFFFFFF));
          g = (7 * i) % 16;
        }
        f = (f + a + table[i] + words[g]) & 0xFFFFFFFF;
        a = d;
        d = c;
        c = b;
        b = (b + _rotateLeft32(f, shifts[i])) & 0xFFFFFFFF;
      }
      a0 = (a0 + a) & 0xFFFFFFFF;
      b0 = (b0 + b) & 0xFFFFFFFF;
      c0 = (c0 + c) & 0xFFFFFFFF;
      d0 = (d0 + d) & 0xFFFFFFFF;
    }
    final Uint8List out = Uint8List(16);
    _writeLittleEndian(out, 0, a0);
    _writeLittleEndian(out, 4, b0);
    _writeLittleEndian(out, 8, c0);
    _writeLittleEndian(out, 12, d0);
    return out;
  }

  static const List<int> _sha256K = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  static Uint8List sha256(List<int> message) {
    final List<int> hash = <int>[0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
    final List<int> padded = _padBigEndian(message);
    final List<int> words = List<int>.filled(64, 0);
    for (int chunk = 0; chunk < padded.length; chunk += 64) {
      for (int i = 0; i < 16; i++) {
        words[i] = (padded[chunk + i * 4] << 24) | (padded[chunk + i * 4 + 1] << 16) | (padded[chunk + i * 4 + 2] << 8) | padded[chunk + i * 4 + 3];
      }
      for (int i = 16; i < 64; i++) {
        final int s0 = _rotateRight32(words[i - 15], 7) ^ _rotateRight32(words[i - 15], 18) ^ (words[i - 15] >>> 3);
        final int s1 = _rotateRight32(words[i - 2], 17) ^ _rotateRight32(words[i - 2], 19) ^ (words[i - 2] >>> 10);
        words[i] = (words[i - 16] + s0 + words[i - 7] + s1) & 0xFFFFFFFF;
      }
      int a = hash[0];
      int b = hash[1];
      int c = hash[2];
      int d = hash[3];
      int e = hash[4];
      int f = hash[5];
      int g = hash[6];
      int h = hash[7];
      for (int i = 0; i < 64; i++) {
        final int s1 = _rotateRight32(e, 6) ^ _rotateRight32(e, 11) ^ _rotateRight32(e, 25);
        final int ch = (e & f) ^ (~e & g);
        final int temp1 = (h + s1 + ch + _sha256K[i] + words[i]) & 0xFFFFFFFF;
        final int s0 = _rotateRight32(a, 2) ^ _rotateRight32(a, 13) ^ _rotateRight32(a, 22);
        final int maj = (a & b) ^ (a & c) ^ (b & c);
        final int temp2 = (s0 + maj) & 0xFFFFFFFF;
        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }
      hash[0] = (hash[0] + a) & 0xFFFFFFFF;
      hash[1] = (hash[1] + b) & 0xFFFFFFFF;
      hash[2] = (hash[2] + c) & 0xFFFFFFFF;
      hash[3] = (hash[3] + d) & 0xFFFFFFFF;
      hash[4] = (hash[4] + e) & 0xFFFFFFFF;
      hash[5] = (hash[5] + f) & 0xFFFFFFFF;
      hash[6] = (hash[6] + g) & 0xFFFFFFFF;
      hash[7] = (hash[7] + h) & 0xFFFFFFFF;
    }
    final Uint8List out = Uint8List(32);
    for (int i = 0; i < 8; i++) {
      out[i * 4] = (hash[i] >>> 24) & 0xFF;
      out[i * 4 + 1] = (hash[i] >>> 16) & 0xFF;
      out[i * 4 + 2] = (hash[i] >>> 8) & 0xFF;
      out[i * 4 + 3] = hash[i] & 0xFF;
    }
    return out;
  }

  static Uint8List sha384(List<int> message) => _sha512(message, _sha384Init, 48);

  static Uint8List sha512(List<int> message) => _sha512(message, _sha512Init, 64);

  static const List<int> _sha512Init = <int>[
    0x6a09e667,
    0xf3bcc908,
    0xbb67ae85,
    0x84caa73b,
    0x3c6ef372,
    0xfe94f82b,
    0xa54ff53a,
    0x5f1d36f1,
    0x510e527f,
    0xade682d1,
    0x9b05688c,
    0x2b3e6c1f,
    0x1f83d9ab,
    0xfb41bd6b,
    0x5be0cd19,
    0x137e2179,
  ];

  static const List<int> _sha384Init = <int>[
    0xcbbb9d5d,
    0xc1059ed8,
    0x629a292a,
    0x367cd507,
    0x9159015a,
    0x3070dd17,
    0x152fecd8,
    0xf70e5939,
    0x67332667,
    0xffc00b31,
    0x8eb44a87,
    0x68581511,
    0xdb0c2e0d,
    0x64f98fa7,
    0x47b5481d,
    0xbefa4fa4,
  ];

  static const List<int> _sha512K = <int>[
    0x428a2f98,
    0xd728ae22,
    0x71374491,
    0x23ef65cd,
    0xb5c0fbcf,
    0xec4d3b2f,
    0xe9b5dba5,
    0x8189dbbc,
    0x3956c25b,
    0xf348b538,
    0x59f111f1,
    0xb605d019,
    0x923f82a4,
    0xaf194f9b,
    0xab1c5ed5,
    0xda6d8118,
    0xd807aa98,
    0xa3030242,
    0x12835b01,
    0x45706fbe,
    0x243185be,
    0x4ee4b28c,
    0x550c7dc3,
    0xd5ffb4e2,
    0x72be5d74,
    0xf27b896f,
    0x80deb1fe,
    0x3b1696b1,
    0x9bdc06a7,
    0x25c71235,
    0xc19bf174,
    0xcf692694,
    0xe49b69c1,
    0x9ef14ad2,
    0xefbe4786,
    0x384f25e3,
    0x0fc19dc6,
    0x8b8cd5b5,
    0x240ca1cc,
    0x77ac9c65,
    0x2de92c6f,
    0x592b0275,
    0x4a7484aa,
    0x6ea6e483,
    0x5cb0a9dc,
    0xbd41fbd4,
    0x76f988da,
    0x831153b5,
    0x983e5152,
    0xee66dfab,
    0xa831c66d,
    0x2db43210,
    0xb00327c8,
    0x98fb213f,
    0xbf597fc7,
    0xbeef0ee4,
    0xc6e00bf3,
    0x3da88fc2,
    0xd5a79147,
    0x930aa725,
    0x06ca6351,
    0xe003826f,
    0x14292967,
    0x0a0e6e70,
    0x27b70a85,
    0x46d22ffc,
    0x2e1b2138,
    0x5c26c926,
    0x4d2c6dfc,
    0x5ac42aed,
    0x53380d13,
    0x9d95b3df,
    0x650a7354,
    0x8baf63de,
    0x766a0abb,
    0x3c77b2a8,
    0x81c2c92e,
    0x47edaee6,
    0x92722c85,
    0x1482353b,
    0xa2bfe8a1,
    0x4cf10364,
    0xa81a664b,
    0xbc423001,
    0xc24b8b70,
    0xd0f89791,
    0xc76c51a3,
    0x0654be30,
    0xd192e819,
    0xd6ef5218,
    0xd6990624,
    0x5565a910,
    0xf40e3585,
    0x5771202a,
    0x106aa070,
    0x32bbd1b8,
    0x19a4c116,
    0xb8d2d0c8,
    0x1e376c08,
    0x5141ab53,
    0x2748774c,
    0xdf8eeb99,
    0x34b0bcb5,
    0xe19b48a8,
    0x391c0cb3,
    0xc5c95a63,
    0x4ed8aa4a,
    0xe3418acb,
    0x5b9cca4f,
    0x7763e373,
    0x682e6ff3,
    0xd6b2b8a3,
    0x748f82ee,
    0x5defb2fc,
    0x78a5636f,
    0x43172f60,
    0x84c87814,
    0xa1f0ab72,
    0x8cc70208,
    0x1a6439ec,
    0x90befffa,
    0x23631e28,
    0xa4506ceb,
    0xde82bde9,
    0xbef9a3f7,
    0xb2c67915,
    0xc67178f2,
    0xe372532b,
    0xca273ece,
    0xea26619c,
    0xd186b8c7,
    0x21c0c207,
    0xeada7dd6,
    0xcde0eb1e,
    0xf57d4f7f,
    0xee6ed178,
    0x06f067aa,
    0x72176fba,
    0x0a637dc5,
    0xa2c898a6,
    0x113f9804,
    0xbef90dae,
    0x1b710b35,
    0x131c471b,
    0x28db77f5,
    0x23047d84,
    0x32caab7b,
    0x40c72493,
    0x3c9ebe0a,
    0x15c9bebc,
    0x431d67c4,
    0x9c100d4c,
    0x4cc5d4be,
    0xcb3e42b6,
    0x597f299c,
    0xfc657e2a,
    0x5fcb6fab,
    0x3ad6faec,
    0x6c44198c,
    0x4a475817,
  ];

  static Uint8List _sha512(List<int> message, List<int> init, int outputBytes) {
    final List<int> hash = List<int>.from(init);
    final List<int> padded = _padBigEndian128(message);
    final List<int> words = List<int>.filled(160, 0);
    for (int chunk = 0; chunk < padded.length; chunk += 128) {
      for (int i = 0; i < 16; i++) {
        final int base = chunk + i * 8;
        words[i * 2] = (padded[base] << 24) | (padded[base + 1] << 16) | (padded[base + 2] << 8) | padded[base + 3];
        words[i * 2 + 1] = (padded[base + 4] << 24) | (padded[base + 5] << 16) | (padded[base + 6] << 8) | padded[base + 7];
      }
      for (int i = 16; i < 80; i++) {
        final List<int> s0 = _xor64(
          _xor64(_rotateRight64(words[(i - 15) * 2], words[(i - 15) * 2 + 1], 1), _rotateRight64(words[(i - 15) * 2], words[(i - 15) * 2 + 1], 8)),
          _shiftRight64(words[(i - 15) * 2], words[(i - 15) * 2 + 1], 7),
        );
        final List<int> s1 = _xor64(
          _xor64(_rotateRight64(words[(i - 2) * 2], words[(i - 2) * 2 + 1], 19), _rotateRight64(words[(i - 2) * 2], words[(i - 2) * 2 + 1], 61)),
          _shiftRight64(words[(i - 2) * 2], words[(i - 2) * 2 + 1], 6),
        );
        final List<int> sum = _add64(_add64(_add64(<int>[words[(i - 16) * 2], words[(i - 16) * 2 + 1]], s0), <int>[words[(i - 7) * 2], words[(i - 7) * 2 + 1]]), s1);
        words[i * 2] = sum[0];
        words[i * 2 + 1] = sum[1];
      }
      List<int> a = <int>[hash[0], hash[1]];
      List<int> b = <int>[hash[2], hash[3]];
      List<int> c = <int>[hash[4], hash[5]];
      List<int> d = <int>[hash[6], hash[7]];
      List<int> e = <int>[hash[8], hash[9]];
      List<int> f = <int>[hash[10], hash[11]];
      List<int> g = <int>[hash[12], hash[13]];
      List<int> h = <int>[hash[14], hash[15]];
      for (int i = 0; i < 80; i++) {
        final List<int> s1 = _xor64(_xor64(_rotateRight64(e[0], e[1], 14), _rotateRight64(e[0], e[1], 18)), _rotateRight64(e[0], e[1], 41));
        final List<int> ch = <int>[(e[0] & f[0]) ^ (~e[0] & g[0]) & 0xFFFFFFFF, (e[1] & f[1]) ^ (~e[1] & g[1]) & 0xFFFFFFFF];
        final List<int> temp1 = _add64(_add64(_add64(_add64(h, s1), ch), <int>[_sha512K[i * 2], _sha512K[i * 2 + 1]]), <int>[words[i * 2], words[i * 2 + 1]]);
        final List<int> s0 = _xor64(_xor64(_rotateRight64(a[0], a[1], 28), _rotateRight64(a[0], a[1], 34)), _rotateRight64(a[0], a[1], 39));
        final List<int> maj = <int>[(a[0] & b[0]) ^ (a[0] & c[0]) ^ (b[0] & c[0]), (a[1] & b[1]) ^ (a[1] & c[1]) ^ (b[1] & c[1])];
        final List<int> temp2 = _add64(s0, maj);
        h = g;
        g = f;
        f = e;
        e = _add64(d, temp1);
        d = c;
        c = b;
        b = a;
        a = _add64(temp1, temp2);
      }
      final List<List<int>> next = <List<int>>[a, b, c, d, e, f, g, h];
      for (int i = 0; i < 8; i++) {
        final List<int> sum = _add64(<int>[hash[i * 2], hash[i * 2 + 1]], next[i]);
        hash[i * 2] = sum[0];
        hash[i * 2 + 1] = sum[1];
      }
    }
    final Uint8List out = Uint8List(outputBytes);
    for (int i = 0; i < outputBytes; i++) {
      final int word = hash[i ~/ 4];
      out[i] = (word >>> (24 - (i % 4) * 8)) & 0xFF;
    }
    return out;
  }

  static List<int> _xor64(List<int> a, List<int> b) => <int>[(a[0] ^ b[0]) & 0xFFFFFFFF, (a[1] ^ b[1]) & 0xFFFFFFFF];

  static List<int> _add64(List<int> a, List<int> b) {
    final int low = (a[1] + b[1]) & 0xFFFFFFFF;
    final int carry = (a[1] + b[1]) > 0xFFFFFFFF ? 1 : 0;
    return <int>[(a[0] + b[0] + carry) & 0xFFFFFFFF, low];
  }

  static List<int> _rotateRight64(int high, int low, int bits) {
    if (bits == 32) return <int>[low, high];
    if (bits < 32) {
      final int newHigh = ((high >>> bits) | (low << (32 - bits))) & 0xFFFFFFFF;
      final int newLow = ((low >>> bits) | (high << (32 - bits))) & 0xFFFFFFFF;
      return <int>[newHigh, newLow];
    }
    final int shift = bits - 32;
    final int newHigh = ((low >>> shift) | (high << (32 - shift))) & 0xFFFFFFFF;
    final int newLow = ((high >>> shift) | (low << (32 - shift))) & 0xFFFFFFFF;
    return <int>[newHigh, newLow];
  }

  static List<int> _shiftRight64(int high, int low, int bits) {
    if (bits >= 32) return <int>[0, (high >>> (bits - 32)) & 0xFFFFFFFF];
    return <int>[(high >>> bits) & 0xFFFFFFFF, ((low >>> bits) | (high << (32 - bits))) & 0xFFFFFFFF];
  }

  static int _rotateLeft32(int value, int bits) => ((value << bits) | (value >>> (32 - bits))) & 0xFFFFFFFF;

  static int _rotateRight32(int value, int bits) => ((value >>> bits) | (value << (32 - bits))) & 0xFFFFFFFF;

  static void _writeLittleEndian(Uint8List out, int offset, int value) {
    out[offset] = value & 0xFF;
    out[offset + 1] = (value >>> 8) & 0xFF;
    out[offset + 2] = (value >>> 16) & 0xFF;
    out[offset + 3] = (value >>> 24) & 0xFF;
  }

  static List<int> _padLittleEndian(List<int> message) {
    final List<int> padded = List<int>.from(message)..add(0x80);
    while (padded.length % 64 != 56) {
      padded.add(0);
    }
    final int bitLength = message.length * 8;
    for (int i = 0; i < 8; i++) {
      padded.add((bitLength >>> (8 * i)) & 0xFF);
    }
    return padded;
  }

  static List<int> _padBigEndian(List<int> message) {
    final List<int> padded = List<int>.from(message)..add(0x80);
    while (padded.length % 64 != 56) {
      padded.add(0);
    }
    final int bitLength = message.length * 8;
    for (int i = 7; i >= 0; i--) {
      padded.add((bitLength >>> (8 * i)) & 0xFF);
    }
    return padded;
  }

  static List<int> _padBigEndian128(List<int> message) {
    final List<int> padded = List<int>.from(message)..add(0x80);
    while (padded.length % 128 != 112) {
      padded.add(0);
    }
    final int bitLength = message.length * 8;
    for (int i = 0; i < 8; i++) {
      padded.add(0);
    }
    for (int i = 7; i >= 0; i--) {
      padded.add((bitLength >>> (8 * i)) & 0xFF);
    }
    return padded;
  }
}

abstract class UPdfRc4 {
  static Uint8List apply(Uint8List key, Uint8List data) {
    if (key.isEmpty) return data;
    final Uint8List state = Uint8List(256);
    for (int i = 0; i < 256; i++) {
      state[i] = i;
    }
    int j = 0;
    for (int i = 0; i < 256; i++) {
      j = (j + state[i] + key[i % key.length]) & 0xFF;
      final int temp = state[i];
      state[i] = state[j];
      state[j] = temp;
    }
    final Uint8List out = Uint8List(data.length);
    int x = 0;
    int y = 0;
    for (int i = 0; i < data.length; i++) {
      x = (x + 1) & 0xFF;
      y = (y + state[x]) & 0xFF;
      final int temp = state[x];
      state[x] = state[y];
      state[y] = temp;
      out[i] = data[i] ^ state[(state[x] + state[y]) & 0xFF];
    }
    return out;
  }
}

class UPdfAes {
  UPdfAes(Uint8List key) : _rounds = key.length == 16 ? 10 : (key.length == 24 ? 12 : 14) {
    _expandKey(key);
  }

  static Uint8List? _sbox;
  static late Uint8List? _inverse;

  final int _rounds;
  late final List<int> _schedule;

  static Uint8List get sbox {
    final Uint8List? cached = _sbox;
    if (cached != null) return cached;
    final Uint8List table = Uint8List(256);
    final Uint8List inverse = Uint8List(256);
    int p = 1;
    int q = 1;
    do {
      p = (p ^ ((p << 1) & 0xFF) ^ ((p & 0x80) != 0 ? 0x1B : 0)) & 0xFF;
      q ^= (q << 1) & 0xFF;
      q ^= (q << 2) & 0xFF;
      q ^= (q << 4) & 0xFF;
      if ((q & 0x80) != 0) q ^= 0x09;
      q &= 0xFF;
      final int value = (q ^ _rotl8(q, 1) ^ _rotl8(q, 2) ^ _rotl8(q, 3) ^ _rotl8(q, 4) ^ 0x63) & 0xFF;
      table[p] = value;
      inverse[value] = p;
    } while (p != 1);
    table[0] = 0x63;
    inverse[0x63] = 0;
    _sbox = table;
    _inverse = inverse;
    return table;
  }

  static Uint8List get inverseSbox {
    sbox;
    return _inverse!;
  }

  static int _rotl8(int value, int shift) => ((value << shift) | (value >> (8 - shift))) & 0xFF;

  static int _xtime(int value) => ((value << 1) ^ ((value & 0x80) != 0 ? 0x1B : 0)) & 0xFF;

  static int _multiply(int a, int b) {
    int result = 0;
    int x = a;
    int y = b;
    while (y != 0) {
      if ((y & 1) != 0) result ^= x;
      x = _xtime(x);
      y >>= 1;
    }
    return result & 0xFF;
  }

  void _expandKey(Uint8List key) {
    final Uint8List table = sbox;
    final int words = key.length ~/ 4;
    final int total = 4 * (_rounds + 1);
    final List<int> schedule = List<int>.filled(total * 4, 0);
    for (int i = 0; i < key.length; i++) {
      schedule[i] = key[i];
    }
    int rcon = 1;
    for (int i = words; i < total; i++) {
      int t0 = schedule[(i - 1) * 4];
      int t1 = schedule[(i - 1) * 4 + 1];
      int t2 = schedule[(i - 1) * 4 + 2];
      int t3 = schedule[(i - 1) * 4 + 3];
      if (i % words == 0) {
        final int temp = t0;
        t0 = table[t1] ^ rcon;
        t1 = table[t2];
        t2 = table[t3];
        t3 = table[temp];
        rcon = _xtime(rcon);
      } else if (words > 6 && i % words == 4) {
        t0 = table[t0];
        t1 = table[t1];
        t2 = table[t2];
        t3 = table[t3];
      }
      schedule[i * 4] = schedule[(i - words) * 4] ^ t0;
      schedule[i * 4 + 1] = schedule[(i - words) * 4 + 1] ^ t1;
      schedule[i * 4 + 2] = schedule[(i - words) * 4 + 2] ^ t2;
      schedule[i * 4 + 3] = schedule[(i - words) * 4 + 3] ^ t3;
    }
    _schedule = schedule;
  }

  void _addRoundKey(Uint8List state, int round) {
    for (int i = 0; i < 16; i++) {
      state[i] ^= _schedule[round * 16 + i];
    }
  }

  void _encryptBlock(Uint8List state) {
    final Uint8List table = sbox;
    _addRoundKey(state, 0);
    for (int round = 1; round <= _rounds; round++) {
      for (int i = 0; i < 16; i++) {
        state[i] = table[state[i]];
      }
      _shiftRows(state, inverse: false);
      if (round != _rounds) _mixColumns(state, inverse: false);
      _addRoundKey(state, round);
    }
  }

  void _decryptBlock(Uint8List state) {
    final Uint8List table = inverseSbox;
    _addRoundKey(state, _rounds);
    for (int round = _rounds - 1; round >= 0; round--) {
      _shiftRows(state, inverse: true);
      for (int i = 0; i < 16; i++) {
        state[i] = table[state[i]];
      }
      _addRoundKey(state, round);
      if (round != 0) _mixColumns(state, inverse: true);
    }
  }

  void _shiftRows(Uint8List state, {required bool inverse}) {
    final Uint8List copy = Uint8List.fromList(state);
    for (int row = 1; row < 4; row++) {
      for (int column = 0; column < 4; column++) {
        final int source = inverse ? (column - row + 4) % 4 : (column + row) % 4;
        state[column * 4 + row] = copy[source * 4 + row];
      }
    }
  }

  void _mixColumns(Uint8List state, {required bool inverse}) {
    for (int column = 0; column < 4; column++) {
      final int base = column * 4;
      final int a0 = state[base];
      final int a1 = state[base + 1];
      final int a2 = state[base + 2];
      final int a3 = state[base + 3];
      if (inverse) {
        state[base] = _multiply(a0, 14) ^ _multiply(a1, 11) ^ _multiply(a2, 13) ^ _multiply(a3, 9);
        state[base + 1] = _multiply(a0, 9) ^ _multiply(a1, 14) ^ _multiply(a2, 11) ^ _multiply(a3, 13);
        state[base + 2] = _multiply(a0, 13) ^ _multiply(a1, 9) ^ _multiply(a2, 14) ^ _multiply(a3, 11);
        state[base + 3] = _multiply(a0, 11) ^ _multiply(a1, 13) ^ _multiply(a2, 9) ^ _multiply(a3, 14);
      } else {
        state[base] = _multiply(a0, 2) ^ _multiply(a1, 3) ^ a2 ^ a3;
        state[base + 1] = a0 ^ _multiply(a1, 2) ^ _multiply(a2, 3) ^ a3;
        state[base + 2] = a0 ^ a1 ^ _multiply(a2, 2) ^ _multiply(a3, 3);
        state[base + 3] = _multiply(a0, 3) ^ a1 ^ a2 ^ _multiply(a3, 2);
      }
    }
  }

  Uint8List decryptCbc(Uint8List data, {Uint8List? iv, bool stripPadding = true}) {
    if (data.length < 16) return Uint8List(0);
    final Uint8List vector = iv ?? Uint8List.sublistView(data, 0, 16);
    final int start = iv == null ? 16 : 0;
    final int blocks = (data.length - start) ~/ 16;
    final Uint8List out = Uint8List(blocks * 16);
    final Uint8List previous = Uint8List.fromList(vector);
    for (int block = 0; block < blocks; block++) {
      final Uint8List cipher = Uint8List.sublistView(data, start + block * 16, start + block * 16 + 16);
      final Uint8List state = Uint8List.fromList(cipher);
      _decryptBlock(state);
      for (int i = 0; i < 16; i++) {
        out[block * 16 + i] = state[i] ^ previous[i];
      }
      previous.setAll(0, cipher);
    }
    if (!stripPadding || out.isEmpty) return out;
    final int pad = out[out.length - 1];
    if (pad < 1 || pad > 16 || pad > out.length) return out;
    return Uint8List.sublistView(out, 0, out.length - pad);
  }

  Uint8List encryptCbc(Uint8List data, Uint8List iv) {
    final int padding = 16 - (data.length % 16);
    final Uint8List padded = Uint8List(data.length + padding);
    padded.setAll(0, data);
    for (int i = data.length; i < padded.length; i++) {
      padded[i] = padding;
    }
    final Uint8List out = Uint8List(16 + padded.length);
    out.setAll(0, iv);
    final Uint8List previous = Uint8List.fromList(iv);
    for (int block = 0; block * 16 < padded.length; block++) {
      final Uint8List state = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        state[i] = padded[block * 16 + i] ^ previous[i];
      }
      _encryptBlock(state);
      out.setAll(16 + block * 16, state);
      previous.setAll(0, state);
    }
    return out;
  }

  Uint8List decryptEcbNoPadding(Uint8List data) {
    final int blocks = data.length ~/ 16;
    final Uint8List out = Uint8List(blocks * 16);
    for (int block = 0; block < blocks; block++) {
      final Uint8List state = Uint8List.fromList(Uint8List.sublistView(data, block * 16, block * 16 + 16));
      _decryptBlock(state);
      out.setAll(block * 16, state);
    }
    return out;
  }

  Uint8List decryptCbcNoPadding(Uint8List data, Uint8List iv) {
    final int blocks = data.length ~/ 16;
    final Uint8List out = Uint8List(blocks * 16);
    final Uint8List previous = Uint8List.fromList(iv);
    for (int block = 0; block < blocks; block++) {
      final Uint8List cipher = Uint8List.sublistView(data, block * 16, block * 16 + 16);
      final Uint8List state = Uint8List.fromList(cipher);
      _decryptBlock(state);
      for (int i = 0; i < 16; i++) {
        out[block * 16 + i] = state[i] ^ previous[i];
      }
      previous.setAll(0, cipher);
    }
    return out;
  }

  Uint8List encryptCbcNoPadding(Uint8List data, Uint8List iv) {
    final int blocks = data.length ~/ 16;
    final Uint8List out = Uint8List(blocks * 16);
    final Uint8List previous = Uint8List.fromList(iv);
    for (int block = 0; block < blocks; block++) {
      final Uint8List state = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        state[i] = data[block * 16 + i] ^ previous[i];
      }
      _encryptBlock(state);
      out.setAll(block * 16, state);
      previous.setAll(0, state);
    }
    return out;
  }
}

class UPdfName {
  const UPdfName(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is UPdfName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => "/$value";
}

class UPdfRef {
  const UPdfRef(this.number, this.generation);

  final int number;
  final int generation;

  @override
  bool operator ==(Object other) => other is UPdfRef && other.number == number && other.generation == generation;

  @override
  int get hashCode => number * 31 + generation;

  @override
  String toString() => "$number $generation R";
}

class UPdfString {
  const UPdfString(this.bytes, {this.hex = false});

  final Uint8List bytes;
  final bool hex;

  String get text {
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final StringBuffer buffer = StringBuffer();
      for (int i = 2; i + 1 < bytes.length; i += 2) {
        buffer.writeCharCode((bytes[i] << 8) | bytes[i + 1]);
      }
      return buffer.toString();
    }
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) return utf8.decode(Uint8List.sublistView(bytes, 3), allowMalformed: true);
    final StringBuffer buffer = StringBuffer();
    for (final int byte in bytes) {
      buffer.write(_pdfDocEncoding(byte));
    }
    return buffer.toString();
  }

  DateTime? get date {
    final String raw = text.trim();
    final RegExpMatch? match = RegExp(r"D?:?(\d{4})(\d{2})?(\d{2})?(\d{2})?(\d{2})?(\d{2})?([+\-Z])?(\d{2})?'?(\d{2})?").firstMatch(raw);
    if (match == null) return null;
    final int year = int.tryParse(match.group(1) ?? "") ?? 0;
    if (year == 0) return null;
    final DateTime local = DateTime(
      year,
      int.tryParse(match.group(2) ?? "1") ?? 1,
      int.tryParse(match.group(3) ?? "1") ?? 1,
      int.tryParse(match.group(4) ?? "0") ?? 0,
      int.tryParse(match.group(5) ?? "0") ?? 0,
      int.tryParse(match.group(6) ?? "0") ?? 0,
    );
    final String sign = match.group(7) ?? "";
    if (sign.isEmpty || sign == "Z") return local;
    final int offsetHours = int.tryParse(match.group(8) ?? "0") ?? 0;
    final int offsetMinutes = int.tryParse(match.group(9) ?? "0") ?? 0;
    final Duration offset = Duration(hours: offsetHours, minutes: offsetMinutes);
    return sign == "+" ? local.subtract(offset) : local.add(offset);
  }

  static String _pdfDocEncoding(int byte) {
    if (byte >= 0x20 && byte < 0x7F) return String.fromCharCode(byte);
    if (byte == 0x0A || byte == 0x0D || byte == 0x09) return String.fromCharCode(byte);
    if (byte >= 0xA0) return String.fromCharCode(byte);
    const Map<int, int> high = <int, int>{
      0x80: 0x2022,
      0x81: 0x2020,
      0x82: 0x2021,
      0x83: 0x2026,
      0x84: 0x2014,
      0x85: 0x2013,
      0x86: 0x0192,
      0x87: 0x2044,
      0x88: 0x2039,
      0x89: 0x203A,
      0x8A: 0x2212,
      0x8B: 0x2030,
      0x8C: 0x201E,
      0x8D: 0x201C,
      0x8E: 0x201D,
      0x8F: 0x2018,
      0x90: 0x2019,
      0x91: 0x201A,
      0x92: 0x2122,
      0x93: 0xFB01,
      0x94: 0xFB02,
      0x95: 0x0141,
      0x96: 0x0152,
      0x97: 0x0160,
      0x98: 0x0178,
      0x99: 0x017D,
      0x9A: 0x0131,
      0x9B: 0x0142,
      0x9C: 0x0153,
      0x9D: 0x0161,
      0x9E: 0x017E,
      0xA0: 0x20AC,
    };
    final int? mapped = high[byte];
    return mapped == null ? "" : String.fromCharCode(mapped);
  }

  @override
  String toString() => text;
}

class UPdfDict {
  UPdfDict(this.entries);

  UPdfDict.empty() : entries = <String, Object?>{};

  final Map<String, Object?> entries;

  Object? operator [](String key) => entries[key];

  void operator []=(String key, Object? value) => entries[key] = value;

  bool has(String key) => entries.containsKey(key);

  Iterable<String> get keys => entries.keys;

  int get length => entries.length;

  UPdfDict copy() => UPdfDict(<String, Object?>{...entries});

  @override
  String toString() => "<<${entries.keys.join(" ")}>>";
}

class UPdfStream {
  UPdfStream({required this.dict, required this.rawOffset, required this.rawLength, this.rawBytes, this.objectNumber = 0, this.generation = 0});

  final UPdfDict dict;
  final int rawOffset;
  final int rawLength;
  final Uint8List? rawBytes;
  final int objectNumber;
  final int generation;

  Uint8List? decoded;

  @override
  String toString() => "stream(${dict.entries.keys.join(" ")}, $rawLength bytes)";
}

abstract class UPdfSyntax {
  static const int space = 0x20;
  static const int tab = 0x09;
  static const int lineFeed = 0x0A;
  static const int formFeed = 0x0C;
  static const int carriageReturn = 0x0D;
  static const int nul = 0x00;

  static bool isWhitespace(int byte) => byte == space || byte == tab || byte == lineFeed || byte == formFeed || byte == carriageReturn || byte == nul;

  static bool isDelimiter(int byte) => byte == 0x28 || byte == 0x29 || byte == 0x3C || byte == 0x3E || byte == 0x5B || byte == 0x5D || byte == 0x7B || byte == 0x7D || byte == 0x2F || byte == 0x25;

  static bool isRegular(int byte) => byte >= 0 && !isWhitespace(byte) && !isDelimiter(byte);

  static bool isDigit(int byte) => byte >= 0x30 && byte <= 0x39;

  static void skipWhitespace(UDocCursor cursor) {
    while (!cursor.isEmpty) {
      final int byte = cursor.peek;
      if (byte == 0x25) {
        while (!cursor.isEmpty && cursor.peek != lineFeed && cursor.peek != carriageReturn) {
          cursor.skip(1);
        }
        continue;
      }
      if (!isWhitespace(byte)) return;
      cursor.skip(1);
    }
  }

  static String readKeyword(UDocCursor cursor) {
    final StringBuffer buffer = StringBuffer();
    while (!cursor.isEmpty && isRegular(cursor.peek)) {
      buffer.writeCharCode(cursor.u8());
    }
    return buffer.toString();
  }

  static String readName(UDocCursor cursor) {
    cursor.skip(1);
    final StringBuffer buffer = StringBuffer();
    while (!cursor.isEmpty && isRegular(cursor.peek)) {
      final int byte = cursor.u8();
      if (byte == 0x23 && cursor.remaining >= 2) {
        final int high = _hex(cursor.peekAt(0));
        final int low = _hex(cursor.peekAt(1));
        if (high >= 0 && low >= 0) {
          cursor.skip(2);
          buffer.writeCharCode((high << 4) | low);
          continue;
        }
      }
      buffer.writeCharCode(byte);
    }
    return buffer.toString();
  }

  static int _hex(int byte) {
    if (byte >= 0x30 && byte <= 0x39) return byte - 0x30;
    if (byte >= 0x41 && byte <= 0x46) return byte - 0x37;
    if (byte >= 0x61 && byte <= 0x66) return byte - 0x57;
    return -1;
  }

  static UPdfString readLiteralString(UDocCursor cursor) {
    cursor.skip(1);
    final List<int> out = <int>[];
    int depth = 1;
    while (!cursor.isEmpty) {
      final int byte = cursor.u8();
      if (byte == 0x5C) {
        if (cursor.isEmpty) break;
        final int escape = cursor.u8();
        switch (escape) {
          case 0x6E:
            out.add(lineFeed);
            break;
          case 0x72:
            out.add(carriageReturn);
            break;
          case 0x74:
            out.add(tab);
            break;
          case 0x62:
            out.add(0x08);
            break;
          case 0x66:
            out.add(formFeed);
            break;
          case lineFeed:
            break;
          case carriageReturn:
            if (!cursor.isEmpty && cursor.peek == lineFeed) cursor.skip(1);
            break;
          default:
            if (escape >= 0x30 && escape <= 0x37) {
              int value = escape - 0x30;
              for (int i = 0; i < 2 && !cursor.isEmpty && cursor.peek >= 0x30 && cursor.peek <= 0x37; i++) {
                value = value * 8 + (cursor.u8() - 0x30);
              }
              out.add(value & 0xFF);
            } else {
              out.add(escape);
            }
            break;
        }
        continue;
      }
      if (byte == 0x28) {
        depth++;
        out.add(byte);
        continue;
      }
      if (byte == 0x29) {
        depth--;
        if (depth == 0) break;
        out.add(byte);
        continue;
      }
      out.add(byte);
      if (out.length > uDocMaxStringLength) break;
    }
    return UPdfString(Uint8List.fromList(out));
  }

  static UPdfString readHexString(UDocCursor cursor) {
    cursor.skip(1);
    final List<int> out = <int>[];
    int high = -1;
    while (!cursor.isEmpty) {
      final int byte = cursor.u8();
      if (byte == 0x3E) break;
      final int digit = _hex(byte);
      if (digit < 0) continue;
      if (high < 0) {
        high = digit;
      } else {
        out.add((high << 4) | digit);
        high = -1;
      }
      if (out.length > uDocMaxStringLength) break;
    }
    if (high >= 0) out.add(high << 4);
    return UPdfString(Uint8List.fromList(out), hex: true);
  }

  static num readNumber(UDocCursor cursor) {
    final StringBuffer buffer = StringBuffer();
    while (!cursor.isEmpty) {
      final int byte = cursor.peek;
      if (isDigit(byte) || byte == 0x2B || byte == 0x2D || byte == 0x2E || byte == 0x45 || byte == 0x65) {
        buffer.writeCharCode(cursor.u8());
        continue;
      }
      break;
    }
    final String raw = buffer.toString();
    final int? asInt = int.tryParse(raw);
    if (asInt != null) return asInt;
    return double.tryParse(raw) ?? double.tryParse(raw.replaceAll(RegExp(r"[^0-9.\-]"), "")) ?? 0;
  }

  static Object? parseObject(UDocCursor cursor, {int depth = 0}) {
    if (depth > uDocMaxDepth) throw const UDocParseException("Object nesting too deep");
    skipWhitespace(cursor);
    if (cursor.isEmpty) return null;
    final int byte = cursor.peek;
    if (byte == 0x2F) return UPdfName(readName(cursor));
    if (byte == 0x28) return readLiteralString(cursor);
    if (byte == 0x5B) {
      cursor.skip(1);
      final List<Object?> array = <Object?>[];
      while (true) {
        skipWhitespace(cursor);
        if (cursor.isEmpty) break;
        if (cursor.peek == 0x5D) {
          cursor.skip(1);
          break;
        }
        array.add(parseObject(cursor, depth: depth + 1));
        if (array.length > uDocMaxArrayLength) throw const UDocParseException("Array too large");
      }
      return array;
    }
    if (byte == 0x3C) {
      if (cursor.peekAt(1) == 0x3C) {
        cursor.skip(2);
        final Map<String, Object?> map = <String, Object?>{};
        while (true) {
          skipWhitespace(cursor);
          if (cursor.isEmpty) break;
          if (cursor.peek == 0x3E && cursor.peekAt(1) == 0x3E) {
            cursor.skip(2);
            break;
          }
          if (cursor.peek != 0x2F) {
            final Object? skipped = parseObject(cursor, depth: depth + 1);
            if (skipped == null && cursor.isEmpty) break;
            continue;
          }
          final String key = readName(cursor);
          final Object? value = parseObject(cursor, depth: depth + 1);
          map[key] = value;
          if (map.length > uDocMaxArrayLength) throw const UDocParseException("Dictionary too large");
        }
        return UPdfDict(map);
      }
      return readHexString(cursor);
    }
    if (isDigit(byte) || byte == 0x2B || byte == 0x2D || byte == 0x2E) {
      final int start = cursor.position;
      final num first = readNumber(cursor);
      if (first is int && first >= 0) {
        final int afterFirst = cursor.position;
        skipWhitespace(cursor);
        if (!cursor.isEmpty && isDigit(cursor.peek)) {
          final num second = readNumber(cursor);
          skipWhitespace(cursor);
          if (second is int && second >= 0 && !cursor.isEmpty && cursor.peek == 0x52 && !isRegular(cursor.peekAt(1))) {
            cursor.skip(1);
            return UPdfRef(first, second);
          }
        }
        cursor.seek(afterFirst);
      }
      if (cursor.position == start) cursor.skip(1);
      return first;
    }
    final String keyword = readKeyword(cursor);
    if (keyword == "true") return true;
    if (keyword == "false") return false;
    if (keyword == "null") return null;
    if (keyword.isEmpty) {
      cursor.skip(1);
      return null;
    }
    return UPdfName(keyword);
  }
}

class UPdfXrefEntry {
  const UPdfXrefEntry({required this.type, required this.first, required this.second});

  final int type;
  final int first;
  final int second;

  int get offset => first;

  int get generation => second;

  int get streamNumber => first;

  int get indexInStream => second;

  bool get isFree => type == 0;

  bool get isCompressed => type == 2;
}

class UPdfXref {
  final Map<int, UPdfXrefEntry> entries = <int, UPdfXrefEntry>{};
  UPdfDict? trailer;

  void merge(Map<int, UPdfXrefEntry> other) {
    other.forEach((int key, UPdfXrefEntry value) {
      entries.putIfAbsent(key, () => value);
    });
  }

  void mergeTrailer(UPdfDict? other) {
    if (other == null) return;
    final UPdfDict current = trailer ?? UPdfDict.empty();
    other.entries.forEach((String key, Object? value) {
      current.entries.putIfAbsent(key, () => value);
    });
    trailer = current;
  }
}

enum UPdfCryptMethod { none, rc4, aesV2, aesV3 }

class UPdfEncryption {
  UPdfEncryption._({
    required this.revision,
    required this.version,
    required this.keyLength,
    required this.streamMethod,
    required this.stringMethod,
    required this.fileKey,
    required this.permissionFlags,
    required this.authenticated,
    required this.ownerAuthenticated,
    required this.encryptMetadata,
  });

  static const List<int> _pad = <int>[
    0x28,
    0xBF,
    0x4E,
    0x5E,
    0x4E,
    0x75,
    0x8A,
    0x41,
    0x64,
    0x00,
    0x4E,
    0x56,
    0xFF,
    0xFA,
    0x01,
    0x08,
    0x2E,
    0x2E,
    0x00,
    0xB6,
    0xD0,
    0x68,
    0x3E,
    0x80,
    0x2F,
    0x0C,
    0xA9,
    0xFE,
    0x64,
    0x53,
    0x69,
    0x7A,
  ];

  final int revision;
  final int version;
  final int keyLength;
  final UPdfCryptMethod streamMethod;
  final UPdfCryptMethod stringMethod;
  final Uint8List fileKey;
  final int permissionFlags;
  final bool authenticated;
  final bool ownerAuthenticated;
  final bool encryptMetadata;

  UDocPermissions get permissions {
    if (ownerAuthenticated) return UDocPermissions.all;
    final Set<UDocPermission> granted = <UDocPermission>{};
    if (permissionFlags & 4 != 0) granted.add(UDocPermission.print);
    if (permissionFlags & 8 != 0) granted.add(UDocPermission.modify);
    if (permissionFlags & 16 != 0) granted.add(UDocPermission.copy);
    if (permissionFlags & 32 != 0) granted.add(UDocPermission.annotate);
    if (permissionFlags & 256 != 0) granted.add(UDocPermission.fillForms);
    if (permissionFlags & 512 != 0) granted.add(UDocPermission.accessibility);
    if (permissionFlags & 1024 != 0) granted.add(UDocPermission.assemble);
    if (permissionFlags & 2048 != 0) granted.add(UDocPermission.printHighQuality);
    return UDocPermissions(granted: granted);
  }

  static Uint8List _padPassword(List<int> password) {
    final Uint8List out = Uint8List(32);
    final int take = password.length > 32 ? 32 : password.length;
    out.setRange(0, take, password);
    for (int i = take; i < 32; i++) {
      out[i] = _pad[i - take];
    }
    return out;
  }

  static UPdfCryptMethod _methodFor(UPdfDict? filters, Object? nameObject, int version) {
    if (version < 4) return UPdfCryptMethod.rc4;
    final String name = nameObject is UPdfName ? nameObject.value : "Identity";
    if (name == "Identity") return UPdfCryptMethod.none;
    final Object? entry = filters?[name];
    if (entry is! UPdfDict) return UPdfCryptMethod.rc4;
    final Object? cfm = entry["CFM"];
    final String method = cfm is UPdfName ? cfm.value : "V2";
    switch (method) {
      case "AESV2":
        return UPdfCryptMethod.aesV2;
      case "AESV3":
        return UPdfCryptMethod.aesV3;
      case "None":
        return UPdfCryptMethod.none;
      default:
        return UPdfCryptMethod.rc4;
    }
  }

  static UPdfEncryption? create(UPdfDict encrypt, Uint8List firstId, String password) {
    final Object? filterName = encrypt["Filter"];
    if (filterName is UPdfName && filterName.value != "Standard") return null;
    final int version = (encrypt["V"] as num?)?.toInt() ?? 0;
    final int revision = (encrypt["R"] as num?)?.toInt() ?? 2;
    final int bits = (encrypt["Length"] as num?)?.toInt() ?? 40;
    final int permissionFlags = (encrypt["P"] as num?)?.toInt() ?? -1;
    final bool encryptMetadata = encrypt["EncryptMetadata"] as bool? ?? true;
    final Uint8List owner = encrypt["O"] is UPdfString ? (encrypt["O"]! as UPdfString).bytes : Uint8List(0);
    final Uint8List user = encrypt["U"] is UPdfString ? (encrypt["U"]! as UPdfString).bytes : Uint8List(0);
    final UPdfDict? filters = encrypt["CF"] is UPdfDict ? encrypt["CF"]! as UPdfDict : null;
    final UPdfCryptMethod streamMethod = _methodFor(filters, encrypt["StmF"], version);
    final UPdfCryptMethod stringMethod = _methodFor(filters, encrypt["StrF"], version);
    final List<int> passwordBytes = utf8.encode(password);

    if (revision >= 5) {
      final Uint8List ownerExtra = encrypt["OE"] is UPdfString ? (encrypt["OE"]! as UPdfString).bytes : Uint8List(0);
      final Uint8List userExtra = encrypt["UE"] is UPdfString ? (encrypt["UE"]! as UPdfString).bytes : Uint8List(0);
      final _UPdfV5Result? result = _authenticateV5(passwordBytes, owner, user, ownerExtra, userExtra, revision);
      if (result == null) {
        return UPdfEncryption._(
          revision: revision,
          version: version,
          keyLength: 32,
          streamMethod: streamMethod,
          stringMethod: stringMethod,
          fileKey: Uint8List(0),
          permissionFlags: permissionFlags,
          authenticated: false,
          ownerAuthenticated: false,
          encryptMetadata: encryptMetadata,
        );
      }
      return UPdfEncryption._(
        revision: revision,
        version: version,
        keyLength: 32,
        streamMethod: streamMethod,
        stringMethod: stringMethod,
        fileKey: result.key,
        permissionFlags: permissionFlags,
        authenticated: true,
        ownerAuthenticated: result.owner,
        encryptMetadata: encryptMetadata,
      );
    }

    final int keyLength = version == 1 ? 5 : (bits ~/ 8).clamp(5, 16);
    Uint8List key = _legacyKey(passwordBytes, owner, permissionFlags, firstId, revision, keyLength, encryptMetadata);
    bool authenticated = _checkUser(key, user, firstId, revision);
    bool ownerAuthenticated = false;
    if (!authenticated) {
      final List<int>? recovered = _recoverUserPassword(passwordBytes, owner, revision, keyLength);
      if (recovered != null) {
        final Uint8List ownerKey = _legacyKey(recovered, owner, permissionFlags, firstId, revision, keyLength, encryptMetadata);
        if (_checkUser(ownerKey, user, firstId, revision)) {
          key = ownerKey;
          authenticated = true;
          ownerAuthenticated = true;
        }
      }
    }
    return UPdfEncryption._(
      revision: revision,
      version: version,
      keyLength: keyLength,
      streamMethod: streamMethod,
      stringMethod: stringMethod,
      fileKey: key,
      permissionFlags: permissionFlags,
      authenticated: authenticated,
      ownerAuthenticated: ownerAuthenticated,
      encryptMetadata: encryptMetadata,
    );
  }

  static Uint8List _legacyKey(List<int> password, Uint8List owner, int permissions, Uint8List firstId, int revision, int keyLength, bool encryptMetadata) {
    final List<int> input = <int>[];
    input.addAll(_padPassword(password));
    input.addAll(owner);
    input.addAll(<int>[permissions & 0xFF, (permissions >> 8) & 0xFF, (permissions >> 16) & 0xFF, (permissions >> 24) & 0xFF]);
    input.addAll(firstId);
    if (revision >= 4 && !encryptMetadata) input.addAll(<int>[0xFF, 0xFF, 0xFF, 0xFF]);
    Uint8List hash = UPdfDigest.md5(input);
    if (revision >= 3) {
      for (int i = 0; i < 50; i++) {
        hash = UPdfDigest.md5(Uint8List.sublistView(hash, 0, keyLength));
      }
    }
    return Uint8List.fromList(Uint8List.sublistView(hash, 0, keyLength));
  }

  static bool _checkUser(Uint8List key, Uint8List user, Uint8List firstId, int revision) {
    if (user.isEmpty) return true;
    if (revision == 2) {
      final Uint8List expected = UPdfRc4.apply(key, Uint8List.fromList(_pad));
      return _sameBytes(expected, user, 32);
    }
    final List<int> input = <int>[..._pad, ...firstId];
    Uint8List hash = UPdfDigest.md5(input);
    hash = UPdfRc4.apply(key, hash);
    for (int i = 1; i <= 19; i++) {
      final Uint8List roundKey = Uint8List(key.length);
      for (int j = 0; j < key.length; j++) {
        roundKey[j] = key[j] ^ i;
      }
      hash = UPdfRc4.apply(roundKey, hash);
    }
    return _sameBytes(hash, user, 16);
  }

  static List<int>? _recoverUserPassword(List<int> password, Uint8List owner, int revision, int keyLength) {
    if (owner.length < 32) return null;
    Uint8List hash = UPdfDigest.md5(_padPassword(password));
    if (revision >= 3) {
      for (int i = 0; i < 50; i++) {
        hash = UPdfDigest.md5(hash);
      }
    }
    final Uint8List key = Uint8List.fromList(Uint8List.sublistView(hash, 0, keyLength));
    if (revision == 2) return UPdfRc4.apply(key, owner);
    Uint8List result = Uint8List.fromList(owner);
    for (int i = 19; i >= 0; i--) {
      final Uint8List roundKey = Uint8List(key.length);
      for (int j = 0; j < key.length; j++) {
        roundKey[j] = key[j] ^ i;
      }
      result = UPdfRc4.apply(roundKey, result);
    }
    return result;
  }

  static _UPdfV5Result? _authenticateV5(List<int> password, Uint8List owner, Uint8List user, Uint8List ownerExtra, Uint8List userExtra, int revision) {
    if (user.length >= 48) {
      final Uint8List validation = Uint8List.sublistView(user, 32, 40);
      final Uint8List salt = Uint8List.sublistView(user, 40, 48);
      final Uint8List computed = _hash2B(password, validation, const <int>[], revision);
      if (_sameBytes(computed, Uint8List.sublistView(user, 0, 32), 32)) {
        final Uint8List intermediate = _hash2B(password, salt, const <int>[], revision);
        final Uint8List key = UPdfAes(intermediate).decryptCbcNoPadding(userExtra, Uint8List(16));
        return _UPdfV5Result(key, false);
      }
    }
    if (owner.length >= 48 && user.length >= 48) {
      final Uint8List validation = Uint8List.sublistView(owner, 32, 40);
      final Uint8List salt = Uint8List.sublistView(owner, 40, 48);
      final List<int> userData = Uint8List.sublistView(user, 0, 48);
      final Uint8List computed = _hash2B(password, validation, userData, revision);
      if (_sameBytes(computed, Uint8List.sublistView(owner, 0, 32), 32)) {
        final Uint8List intermediate = _hash2B(password, salt, userData, revision);
        final Uint8List key = UPdfAes(intermediate).decryptCbcNoPadding(ownerExtra, Uint8List(16));
        return _UPdfV5Result(key, true);
      }
    }
    return null;
  }

  static Uint8List _hash2B(List<int> password, Uint8List salt, List<int> userData, int revision) {
    Uint8List hash = UPdfDigest.sha256(<int>[...password, ...salt, ...userData]);
    if (revision < 6) return hash;
    int round = 0;
    Uint8List block = Uint8List(0);
    while (true) {
      final List<int> single = <int>[...password, ...hash, ...userData];
      final Uint8List k1 = Uint8List(single.length * 64);
      for (int i = 0; i < 64; i++) {
        k1.setRange(i * single.length, (i + 1) * single.length, single);
      }
      final UPdfAes aes = UPdfAes(Uint8List.fromList(Uint8List.sublistView(hash, 0, 16)));
      block = aes.encryptCbcNoPadding(k1, Uint8List.fromList(Uint8List.sublistView(hash, 16, 32)));
      int sum = 0;
      for (int i = 0; i < 16 && i < block.length; i++) {
        sum += block[i];
      }
      final int mode = sum % 3;
      if (mode == 0) {
        hash = UPdfDigest.sha256(block);
      } else if (mode == 1) {
        hash = UPdfDigest.sha384(block);
      } else {
        hash = UPdfDigest.sha512(block);
      }
      round++;
      if (round >= 64 && block.isNotEmpty && block[block.length - 1] <= round - 32) break;
      if (round > 512) break;
    }
    return Uint8List.fromList(Uint8List.sublistView(hash, 0, 32));
  }

  static bool _sameBytes(Uint8List a, Uint8List b, int count) {
    if (a.length < count || b.length < count) return false;
    for (int i = 0; i < count; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Uint8List _objectKey(int objectNumber, int generation, UPdfCryptMethod method) {
    if (method == UPdfCryptMethod.aesV3) return fileKey;
    final List<int> input = <int>[
      ...fileKey,
      objectNumber & 0xFF,
      (objectNumber >> 8) & 0xFF,
      (objectNumber >> 16) & 0xFF,
      generation & 0xFF,
      (generation >> 8) & 0xFF,
    ];
    if (method == UPdfCryptMethod.aesV2) input.addAll(<int>[0x73, 0x41, 0x6C, 0x54]);
    final Uint8List hash = UPdfDigest.md5(input);
    final int take = fileKey.length + 5 > 16 ? 16 : fileKey.length + 5;
    return Uint8List.fromList(Uint8List.sublistView(hash, 0, take));
  }

  Uint8List decrypt(Uint8List data, int objectNumber, int generation, {required bool isString}) {
    if (fileKey.isEmpty) return data;
    final UPdfCryptMethod method = isString ? stringMethod : streamMethod;
    if (method == UPdfCryptMethod.none) return data;
    final Uint8List key = _objectKey(objectNumber, generation, method);
    if (method == UPdfCryptMethod.rc4) return UPdfRc4.apply(key, data);
    if (data.length < 16) return Uint8List(0);
    return UPdfAes(key).decryptCbc(data);
  }

  Uint8List encrypt(Uint8List data, int objectNumber, int generation, {required bool isString, Uint8List? iv}) {
    if (fileKey.isEmpty) return data;
    final UPdfCryptMethod method = isString ? stringMethod : streamMethod;
    if (method == UPdfCryptMethod.none) return data;
    final Uint8List key = _objectKey(objectNumber, generation, method);
    if (method == UPdfCryptMethod.rc4) return UPdfRc4.apply(key, data);
    final Uint8List vector = iv ?? _randomIv();
    return UPdfAes(key).encryptCbc(data, vector);
  }

  static Uint8List _randomIv() {
    final Random random = Random.secure();
    final Uint8List iv = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }
}

class _UPdfV5Result {
  const _UPdfV5Result(this.key, this.owner);

  final Uint8List key;
  final bool owner;
}

class UPdfDecodedStream {
  const UPdfDecodedStream({required this.bytes, this.imageFilter, this.imageParms});

  final Uint8List bytes;
  final String? imageFilter;
  final UPdfDict? imageParms;

  bool get isImageEncoded => imageFilter != null;
}

class UPdfPage {
  const UPdfPage({required this.index, required this.ref, required this.dict, required this.mediaBox, required this.cropBox, required this.rotation, this.resources});

  final int index;
  final UPdfRef? ref;
  final UPdfDict dict;
  final Rect mediaBox;
  final Rect cropBox;
  final int rotation;
  final UPdfDict? resources;

  Rect get box => cropBox.isEmpty ? mediaBox : cropBox;

  Size get size => Size(box.width, box.height);

  Size get rotatedSize => rotation == 90 || rotation == 270 ? Size(box.height, box.width) : Size(box.width, box.height);
}

class UPdfDocument {
  UPdfDocument._(this.source, this.fingerprint);

  static const List<int> _startxref = <int>[0x73, 0x74, 0x61, 0x72, 0x74, 0x78, 0x72, 0x65, 0x66];
  static const List<int> _objKeyword = <int>[0x6F, 0x62, 0x6A];
  static const List<int> _endstream = <int>[0x65, 0x6E, 0x64, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D];
  static const List<int> _trailerKeyword = <int>[0x74, 0x72, 0x61, 0x69, 0x6C, 0x65, 0x72];

  final UCachedByteSource source;
  final String fingerprint;
  final UPdfXref xref = UPdfXref();
  final ULruCache<int, Object?> _objects = ULruCache<int, Object?>(maxBytes: uDocObjectCacheBytes, sizeOf: _estimate);
  final ULruCache<int, Map<int, Object?>> _objectStreams = ULruCache<int, Map<int, Object?>>(maxBytes: uDocObjectCacheBytes ~/ 2, sizeOf: _estimateMap);
  final Map<int, UPdfDict> _nodeCache = <int, UPdfDict>{};
  final Set<int> _resolving = <int>{};
  final Map<int, Object?> overlay = <int, Object?>{};

  UPdfEncryption? encryption;
  UPdfDict? catalog;
  UPdfDict? info;
  Uint8List firstId = Uint8List(0);
  String version = "1.7";
  bool linearized = false;
  bool rebuilt = false;
  int startXrefOffset = -1;
  int _pageCount = 0;
  List<String>? _pageLabels;
  bool _closed = false;

  int get pageCount => _pageCount;

  UDocPermissions get permissions => encryption?.permissions ?? UDocPermissions.all;

  bool get isEncrypted => encryption != null;

  static int _estimate(Object? value) {
    if (value is UPdfStream) return 512 + (value.decoded?.length ?? 0);
    if (value is UPdfDict) return 128 + value.length * 96;
    if (value is List<Object?>) return 64 + value.length * 32;
    if (value is UPdfString) return 48 + value.bytes.length;
    return 64;
  }

  static int _estimateMap(Map<int, Object?> value) {
    int total = 128;
    value.forEach((int key, Object? entry) => total += _estimate(entry) + 16);
    return total;
  }

  static Future<UPdfDocument> open({String? path, String? url, Uint8List? bytes, String? asset, Object? blob, Map<String, String>? headers, String password = ""}) async {
    final UCachedByteSource source = await UDocSources.open(path: path, url: url, bytes: bytes, asset: asset, blob: blob, headers: headers);
    final String fingerprint = await UDocSources.fingerprint(source);
    final UPdfDocument document = UPdfDocument._(source, fingerprint);
    await document._load(password);
    return document;
  }

  static Future<UPdfDocument> fromSource(UCachedByteSource source, {String password = ""}) async {
    final String fingerprint = await UDocSources.fingerprint(source);
    final UPdfDocument document = UPdfDocument._(source, fingerprint);
    await document._load(password);
    return document;
  }

  Future<UDocCursor> _window(int offset, int length) async {
    final int safeOffset = offset < 0 ? 0 : offset;
    final int available = source.length - safeOffset;
    if (available <= 0) throw UDocParseException("Offset $offset beyond end of file");
    final int take = length > available ? available : length;
    final Uint8List data = await source.read(safeOffset, take);
    return UDocCursor(data, base: safeOffset);
  }

  Future<void> _load(String password) async {
    final Uint8List head = await source.read(0, 1024);
    final int headerIndex = UDocCursor(head).indexOf(<int>[0x25, 0x50, 0x44, 0x46, 0x2D]);
    if (headerIndex >= 0 && headerIndex + 8 <= head.length) {
      version = String.fromCharCodes(Uint8List.sublistView(head, headerIndex + 5, headerIndex + 8));
    }
    final int tailLength = source.length < 4096 ? source.length : 4096;
    final Uint8List tail = await source.read(source.length - tailLength, tailLength);
    final UDocCursor tailCursor = UDocCursor(tail, base: source.length - tailLength);
    final int marker = tailCursor.lastIndexOf(_startxref);
    bool loaded = false;
    if (marker >= 0) {
      tailCursor.seek(marker + _startxref.length);
      UPdfSyntax.skipWhitespace(tailCursor);
      final num start = UPdfSyntax.readNumber(tailCursor);
      if (start is int && start > 0 && start < source.length) {
        startXrefOffset = start;
        try {
          await _loadXrefChain(start);
          loaded = xref.entries.isNotEmpty && xref.trailer != null;
        } on Object {
          loaded = false;
        }
      }
    }
    if (!loaded) await _rebuild();
    await _setUpEncryption(password);
    await _loadCatalog();
  }

  Future<void> _loadXrefChain(int start) async {
    final Set<int> visited = <int>{};
    int? offset = start;
    int guard = 0;
    while (offset != null && offset >= 0 && offset < source.length && guard < 512) {
      guard++;
      if (!visited.add(offset)) break;
      final UPdfDict? trailer = await _loadXrefSection(offset);
      if (trailer == null) break;
      xref.mergeTrailer(trailer);
      final Object? hybrid = trailer["XRefStm"];
      if (hybrid is num) {
        final int hybridOffset = hybrid.toInt();
        if (visited.add(hybridOffset)) await _loadXrefSection(hybridOffset);
      }
      final Object? previous = trailer["Prev"];
      offset = previous is num ? previous.toInt() : null;
    }
  }

  Future<UPdfDict?> _loadXrefSection(int offset) async {
    final UDocCursor probe = await _window(offset, 64);
    UPdfSyntax.skipWhitespace(probe);
    if (probe.matches(const <int>[0x78, 0x72, 0x65, 0x66])) return _loadClassicXref(offset + probe.position + 4);
    final Object? parsed = await _parseIndirectAt(offset, decrypt: false);
    if (parsed is! UPdfStream) return null;
    await _loadXrefStream(parsed);
    return parsed.dict;
  }

  Future<UPdfDict?> _loadClassicXref(int offset) async {
    int cursorOffset = offset;
    final Map<int, UPdfXrefEntry> entries = <int, UPdfXrefEntry>{};
    int guard = 0;
    while (guard < 4096) {
      guard++;
      final UDocCursor header = await _window(cursorOffset, 64);
      UPdfSyntax.skipWhitespace(header);
      if (header.matches(_trailerKeyword)) {
        header.skip(_trailerKeyword.length);
        final int trailerOffset = header.absolute;
        final Object? trailer = await _parseObjectAt(trailerOffset);
        xref.merge(entries);
        return trailer is UPdfDict ? trailer : null;
      }
      if (header.isEmpty || !UPdfSyntax.isDigit(header.peek)) break;
      final num first = UPdfSyntax.readNumber(header);
      UPdfSyntax.skipWhitespace(header);
      final num count = UPdfSyntax.readNumber(header);
      if (first is! int || count is! int || count < 0 || count > 5000000) break;
      final int tableStart = header.absolute;
      UPdfSyntax.skipWhitespace(header);
      final int entriesStart = header.absolute;
      final int tableLength = count * 20 + 32;
      final Uint8List table = await source.read(entriesStart, tableLength > source.length - entriesStart ? source.length - entriesStart : tableLength);
      int position = 0;
      for (int i = 0; i < count; i++) {
        if (position + 18 > table.length) break;
        final String record = String.fromCharCodes(Uint8List.sublistView(table, position, position + 18));
        final int? entryOffset = int.tryParse(record.substring(0, 10).trim());
        final int? generation = int.tryParse(record.substring(11, 16).trim());
        final String typeChar = record.substring(17, 18);
        if (entryOffset != null && generation != null) {
          entries.putIfAbsent(first + i, () => UPdfXrefEntry(type: typeChar == "n" ? 1 : 0, first: entryOffset, second: generation));
        }
        position += 20;
        if (position < table.length && (table[position - 1] != 0x0A && table[position - 1] != 0x0D && table[position - 1] != 0x20)) position -= 1;
      }
      cursorOffset = entriesStart + position;
      if (cursorOffset <= tableStart) break;
    }
    xref.merge(entries);
    return null;
  }

  Future<void> _loadXrefStream(UPdfStream stream) async {
    final Uint8List data = (await decodeStream(stream, decrypt: false)).bytes;
    final Object? widthsObject = stream.dict["W"];
    if (widthsObject is! List<Object?>) return;
    final List<int> widths = widthsObject.map((Object? value) => value is num ? value.toInt() : 0).toList();
    if (widths.length < 3) return;
    final int size = (stream.dict["Size"] as num?)?.toInt() ?? 0;
    final List<int> index = <int>[];
    final Object? indexObject = stream.dict["Index"];
    if (indexObject is List<Object?>) {
      for (final Object? value in indexObject) {
        index.add(value is num ? value.toInt() : 0);
      }
    } else {
      index.addAll(<int>[0, size]);
    }
    final int rowLength = widths.fold(0, (int total, int value) => total + value);
    if (rowLength <= 0) return;
    final Map<int, UPdfXrefEntry> entries = <int, UPdfXrefEntry>{};
    int position = 0;
    for (int section = 0; section + 1 < index.length; section += 2) {
      final int start = index[section];
      final int count = index[section + 1];
      for (int i = 0; i < count; i++) {
        if (position + rowLength > data.length) break;
        int field = 0;
        final List<int> values = <int>[];
        for (final int width in widths) {
          int value = 0;
          for (int b = 0; b < width; b++) {
            value = (value << 8) | data[position + field + b];
          }
          field += width;
          values.add(value);
        }
        position += rowLength;
        final int type = widths[0] == 0 ? 1 : values[0];
        entries.putIfAbsent(start + i, () => UPdfXrefEntry(type: type, first: values[1], second: values.length > 2 ? values[2] : 0));
      }
    }
    xref.merge(entries);
    xref.mergeTrailer(stream.dict);
  }

  Future<void> _rebuild() async {
    rebuilt = true;
    final Map<int, UPdfXrefEntry> entries = <int, UPdfXrefEntry>{};
    final List<int> objectStreamNumbers = <int>[];
    UPdfDict? trailer;
    const int chunk = 1 << 20;
    const int overlap = 64;
    int offset = 0;
    while (offset < source.length) {
      final int take = offset + chunk > source.length ? source.length - offset : chunk;
      final Uint8List data = await source.read(offset, take);
      final UDocCursor cursor = UDocCursor(data, base: offset);
      int search = 0;
      while (true) {
        final int found = cursor.indexOf(_objKeyword, from: search);
        if (found < 0) break;
        search = found + 3;
        if (found + 3 < data.length && UPdfSyntax.isRegular(data[found + 3])) continue;
        int back = found - 1;
        while (back >= 0 && UPdfSyntax.isWhitespace(data[back])) {
          back--;
        }
        final int generationEnd = back + 1;
        while (back >= 0 && UPdfSyntax.isDigit(data[back])) {
          back--;
        }
        final int generationStart = back + 1;
        if (generationStart >= generationEnd) continue;
        while (back >= 0 && UPdfSyntax.isWhitespace(data[back])) {
          back--;
        }
        final int numberEnd = back + 1;
        while (back >= 0 && UPdfSyntax.isDigit(data[back])) {
          back--;
        }
        final int numberStart = back + 1;
        if (numberStart >= numberEnd) continue;
        final int? number = int.tryParse(String.fromCharCodes(Uint8List.sublistView(data, numberStart, numberEnd)));
        final int? generation = int.tryParse(String.fromCharCodes(Uint8List.sublistView(data, generationStart, generationEnd)));
        if (number == null || generation == null) continue;
        entries[number] = UPdfXrefEntry(type: 1, first: offset + numberStart, second: generation);
      }
      int trailerSearch = 0;
      while (true) {
        final int found = cursor.indexOf(_trailerKeyword, from: trailerSearch);
        if (found < 0) break;
        trailerSearch = found + _trailerKeyword.length;
        try {
          final UDocCursor local = UDocCursor(data, base: offset, start: found + _trailerKeyword.length);
          final Object? parsed = UPdfSyntax.parseObject(local);
          if (parsed is UPdfDict && parsed.has("Root")) trailer = parsed;
        } on Object {
          continue;
        }
      }
      if (take < chunk) break;
      offset += chunk - overlap;
    }
    xref.entries.addAll(entries);
    if (trailer != null) xref.mergeTrailer(trailer);
    for (final int number in entries.keys) {
      final Object? candidate = await object(UPdfRef(number, entries[number]!.generation));
      if (candidate is UPdfStream) {
        final Object? type = candidate.dict["Type"];
        if (type is UPdfName && type.value == "ObjStm") objectStreamNumbers.add(number);
        if (type is UPdfName && type.value == "XRef" && xref.trailer == null) xref.mergeTrailer(candidate.dict);
      }
      if (candidate is UPdfDict && candidate.has("Root") && xref.trailer == null) xref.mergeTrailer(candidate);
    }
    for (final int number in objectStreamNumbers) {
      final Map<int, Object?>? contents = await _objectStreamContents(number);
      if (contents == null) continue;
      for (final int inner in contents.keys) {
        xref.entries.putIfAbsent(inner, () => UPdfXrefEntry(type: 2, first: number, second: 0));
      }
    }
    if (xref.trailer == null) {
      for (final int number in entries.keys) {
        final Object? candidate = await object(UPdfRef(number, entries[number]!.generation));
        if (candidate is UPdfDict) {
          final Object? type = candidate["Type"];
          if (type is UPdfName && type.value == "Catalog") {
            xref.mergeTrailer(UPdfDict(<String, Object?>{"Root": UPdfRef(number, entries[number]!.generation)}));
            break;
          }
        }
      }
    }
  }

  Future<void> _setUpEncryption(String password) async {
    final UPdfDict? trailer = xref.trailer;
    if (trailer == null) return;
    final Object? idObject = trailer["ID"];
    if (idObject is List<Object?> && idObject.isNotEmpty && idObject.first is UPdfString) firstId = (idObject.first! as UPdfString).bytes;
    final Object? encryptObject = trailer["Encrypt"];
    if (encryptObject == null) return;
    final Object? resolved = encryptObject is UPdfRef ? await object(encryptObject, decrypt: false) : encryptObject;
    if (resolved is! UPdfDict) return;
    final UPdfEncryption? handler = UPdfEncryption.create(resolved, firstId, password);
    if (handler == null) throw const UDocError(code: UDocErrorCode.unsupported, message: "Unsupported security handler");
    if (!handler.authenticated) throw const UDocError(code: UDocErrorCode.password, message: "A password is required to open this document");
    encryption = handler;
    _objects.clear();
    _objectStreams.clear();
  }

  Future<void> _loadCatalog() async {
    final Object? root = xref.trailer?["Root"];
    final Object? resolved = await resolve(root);
    if (resolved is UPdfDict) catalog = resolved;
    final Object? infoObject = await resolve(xref.trailer?["Info"]);
    if (infoObject is UPdfDict) info = infoObject;
    final Object? pages = await resolve(catalog?["Pages"]);
    if (pages is UPdfDict) {
      final Object? count = await resolve(pages["Count"]);
      _pageCount = count is num ? count.toInt() : 0;
    }
    if (_pageCount <= 0) _pageCount = await _countPagesByScan();
    if (catalog == null) throw const UDocError(code: UDocErrorCode.corrupt, message: "Document has no catalog");
  }

  Future<int> _countPagesByScan() async {
    int count = 0;
    for (final int number in xref.entries.keys) {
      final Object? candidate = await object(UPdfRef(number, xref.entries[number]!.generation));
      if (candidate is UPdfDict) {
        final Object? type = candidate["Type"];
        if (type is UPdfName && type.value == "Page") count++;
      }
    }
    return count;
  }

  Future<Object?> resolve(Object? value, {int depth = 0}) async {
    if (value is! UPdfRef || depth > 32) return value;
    return resolve(await object(value), depth: depth + 1);
  }

  int revision = 0;

  void stage(int number, Object? value) {
    overlay[number] = value;
    revision++;
  }

  void notePageCount(int count) {
    if (count < 0) return;
    _pageCount = count;
    revision++;
  }

  void clearStaged() {
    if (overlay.isEmpty) return;
    overlay.clear();
    revision++;
  }

  Future<Object?> object(UPdfRef ref, {bool decrypt = true}) async {
    if (_closed) return null;
    if (overlay.containsKey(ref.number)) return overlay[ref.number];
    final Object? cached = _objects.get(ref.number);
    if (cached != null) return cached;
    if (_objects.containsKey(ref.number)) return null;
    if (!_resolving.add(ref.number)) return null;
    try {
      final UPdfXrefEntry? entry = xref.entries[ref.number];
      if (entry == null || entry.isFree) return null;
      Object? parsed;
      if (entry.isCompressed) {
        final Map<int, Object?>? contents = await _objectStreamContents(entry.streamNumber);
        parsed = contents?[ref.number];
      } else {
        parsed = await _parseIndirectAt(entry.offset, expectedNumber: ref.number, generation: entry.generation, decrypt: decrypt);
      }
      _objects.put(ref.number, parsed);
      return parsed;
    } on Object {
      return null;
    } finally {
      _resolving.remove(ref.number);
    }
  }

  Future<Map<int, Object?>?> _objectStreamContents(int streamNumber) async {
    final Map<int, Object?>? cached = _objectStreams.get(streamNumber);
    if (cached != null) return cached;
    final UPdfXrefEntry? entry = xref.entries[streamNumber];
    if (entry == null || entry.isCompressed) return null;
    final Object? parsed = await _parseIndirectAt(entry.offset, expectedNumber: streamNumber, generation: entry.generation);
    if (parsed is! UPdfStream) return null;
    final Uint8List data = (await decodeStream(parsed)).bytes;
    final int count = (await resolve(parsed.dict["N"]) as num?)?.toInt() ?? 0;
    final int first = (await resolve(parsed.dict["First"]) as num?)?.toInt() ?? 0;
    if (count <= 0 || first <= 0 || first > data.length) return null;
    final UDocCursor header = UDocCursor(data, end: first);
    final List<int> numbers = <int>[];
    final List<int> offsets = <int>[];
    for (int i = 0; i < count; i++) {
      UPdfSyntax.skipWhitespace(header);
      if (header.isEmpty) break;
      final num number = UPdfSyntax.readNumber(header);
      UPdfSyntax.skipWhitespace(header);
      final num offset = UPdfSyntax.readNumber(header);
      numbers.add(number.toInt());
      offsets.add(offset.toInt());
    }
    final Map<int, Object?> contents = <int, Object?>{};
    for (int i = 0; i < numbers.length; i++) {
      final int start = first + offsets[i];
      if (start < 0 || start >= data.length) continue;
      final int end = i + 1 < offsets.length ? first + offsets[i + 1] : data.length;
      try {
        final UDocCursor cursor = UDocCursor(data, start: start, end: end > data.length ? data.length : end);
        contents[numbers[i]] = UPdfSyntax.parseObject(cursor);
      } on Object {
        continue;
      }
    }
    _objectStreams.put(streamNumber, contents);
    return contents;
  }

  Future<Object?> _parseObjectAt(int offset) async {
    int window = 8192;
    while (window <= uDocMaxAllocation) {
      try {
        final UDocCursor cursor = await _window(offset, window);
        return UPdfSyntax.parseObject(cursor);
      } on UDocParseException {
        if (offset + window >= source.length) return null;
        window *= 4;
      }
    }
    return null;
  }

  Future<Object?> _parseIndirectAt(int offset, {int expectedNumber = -1, int generation = 0, bool decrypt = true}) async {
    int window = 8192;
    while (window <= uDocMaxAllocation) {
      final int available = source.length - offset;
      if (available <= 0) return null;
      final int take = window > available ? available : window;
      final Uint8List data = await source.read(offset, take);
      final UDocCursor cursor = UDocCursor(data, base: offset);
      try {
        UPdfSyntax.skipWhitespace(cursor);
        final num number = UPdfSyntax.readNumber(cursor);
        UPdfSyntax.skipWhitespace(cursor);
        final num objectGeneration = UPdfSyntax.readNumber(cursor);
        UPdfSyntax.skipWhitespace(cursor);
        final String keyword = UPdfSyntax.readKeyword(cursor);
        if (keyword != "obj") return null;
        final int actualNumber = expectedNumber >= 0 ? expectedNumber : number.toInt();
        final Object? value = UPdfSyntax.parseObject(cursor);
        UPdfSyntax.skipWhitespace(cursor);
        if (value is UPdfDict && cursor.matches(const <int>[0x73, 0x74, 0x72, 0x65, 0x61, 0x6D])) {
          cursor.skip(6);
          if (!cursor.isEmpty && cursor.peek == UPdfSyntax.carriageReturn) cursor.skip(1);
          if (!cursor.isEmpty && cursor.peek == UPdfSyntax.lineFeed) cursor.skip(1);
          final int dataOffset = cursor.absolute;
          int length = (await resolve(value["Length"]) as num?)?.toInt() ?? -1;
          if (length < 0 || dataOffset + length > source.length) length = await _scanStreamLength(dataOffset);
          if (length < 0) length = 0;
          return UPdfStream(dict: value, rawOffset: dataOffset, rawLength: length, objectNumber: actualNumber, generation: objectGeneration.toInt());
        }
        if (!decrypt || encryption == null) return value;
        return _decryptObject(value, actualNumber, objectGeneration.toInt());
      } on UDocParseException {
        if (take >= available) return null;
        window *= 4;
      }
    }
    return null;
  }

  Future<int> _scanStreamLength(int dataOffset) async {
    const int chunk = 1 << 18;
    int offset = dataOffset;
    while (offset < source.length) {
      final int take = offset + chunk > source.length ? source.length - offset : chunk;
      final Uint8List data = await source.read(offset, take);
      final int found = UDocCursor(data).indexOf(_endstream);
      if (found >= 0) {
        int end = offset + found;
        if (end > dataOffset && (end - 1) < source.length) {
          final Uint8List trailingBytes = await source.read(end - 2 < dataOffset ? dataOffset : end - 2, 2);
          if (trailingBytes.isNotEmpty && trailingBytes[trailingBytes.length - 1] == UPdfSyntax.lineFeed) end--;
          if (trailingBytes.length > 1 && trailingBytes[0] == UPdfSyntax.carriageReturn) end--;
        }
        return end - dataOffset;
      }
      if (take < chunk) break;
      offset += chunk - _endstream.length;
    }
    return source.length - dataOffset;
  }

  Object? _decryptObject(Object? value, int number, int generation) {
    final UPdfEncryption? handler = encryption;
    if (handler == null) return value;
    if (value is UPdfString) return UPdfString(handler.decrypt(value.bytes, number, generation, isString: true), hex: value.hex);
    if (value is List<Object?>) return value.map((Object? entry) => _decryptObject(entry, number, generation)).toList();
    if (value is UPdfDict) {
      final Map<String, Object?> map = <String, Object?>{};
      value.entries.forEach((String key, Object? entry) => map[key] = _decryptObject(entry, number, generation));
      return UPdfDict(map);
    }
    return value;
  }

  Future<Uint8List> rawStreamBytes(UPdfStream stream) async {
    final Uint8List data = stream.rawBytes ?? await source.read(stream.rawOffset, stream.rawLength);
    final UPdfEncryption? handler = encryption;
    if (handler == null || stream.rawBytes != null) return data;
    final Object? type = stream.dict["Type"];
    final bool isMetadata = type is UPdfName && type.value == "Metadata";
    if (isMetadata && !handler.encryptMetadata) return data;
    return handler.decrypt(data, stream.objectNumber, stream.generation, isString: false);
  }

  Future<UPdfDecodedStream> decodeStream(UPdfStream stream, {bool decrypt = true}) async {
    final Uint8List? memo = stream.decoded;
    if (memo != null) return UPdfDecodedStream(bytes: memo);
    Uint8List data = stream.rawBytes ?? await source.read(stream.rawOffset, stream.rawLength);
    final UPdfEncryption? handler = encryption;
    final Object? type = stream.dict["Type"];
    final bool isMetadata = type is UPdfName && type.value == "Metadata";
    if (decrypt && handler != null && stream.rawBytes == null && !(isMetadata && !handler.encryptMetadata)) {
      data = handler.decrypt(data, stream.objectNumber, stream.generation, isString: false);
    }
    final List<String> filters = <String>[];
    final Object? filterObject = await resolve(stream.dict["Filter"]);
    if (filterObject is UPdfName) filters.add(filterObject.value);
    if (filterObject is List<Object?>) {
      for (final Object? entry in filterObject) {
        final Object? resolved = await resolve(entry);
        if (resolved is UPdfName) filters.add(resolved.value);
      }
    }
    final List<UPdfDict?> parms = <UPdfDict?>[];
    final Object? parmsObject = await resolve(stream.dict["DecodeParms"] ?? stream.dict["DP"]);
    if (parmsObject is UPdfDict) parms.add(parmsObject);
    if (parmsObject is List<Object?>) {
      for (final Object? entry in parmsObject) {
        final Object? resolved = await resolve(entry);
        parms.add(resolved is UPdfDict ? resolved : null);
      }
    }
    for (int i = 0; i < filters.length; i++) {
      final String filter = filters[i];
      final UPdfDict? parm = i < parms.length ? parms[i] : null;
      switch (filter) {
        case "FlateDecode":
        case "Fl":
          data = UPdfCodecs.inflate(data);
          data = await _applyPredictor(data, parm);
          break;
        case "LZWDecode":
        case "LZW":
          data = UPdfCodecs.lzw(data, earlyChange: (await resolve(parm?["EarlyChange"]) as num?)?.toInt() ?? 1);
          data = await _applyPredictor(data, parm);
          break;
        case "ASCII85Decode":
        case "A85":
          data = UPdfCodecs.ascii85(data);
          break;
        case "ASCIIHexDecode":
        case "AHx":
          data = UPdfCodecs.asciiHex(data);
          break;
        case "RunLengthDecode":
        case "RL":
          data = UPdfCodecs.runLength(data);
          break;
        case "Crypt":
          break;
        case "DCTDecode":
        case "DCT":
        case "JPXDecode":
        case "JBIG2Decode":
        case "CCITTFaxDecode":
        case "CCF":
          return UPdfDecodedStream(bytes: data, imageFilter: filter, imageParms: parm);
        default:
          break;
      }
    }
    if (data.length < 4 * 1024 * 1024) stream.decoded = data;
    return UPdfDecodedStream(bytes: data);
  }

  Future<Uint8List> _applyPredictor(Uint8List data, UPdfDict? parm) async {
    if (parm == null) return data;
    final int predictorValue = (await resolve(parm["Predictor"]) as num?)?.toInt() ?? 1;
    if (predictorValue <= 1) return data;
    return UPdfCodecs.predictor(
      data,
      predictor: predictorValue,
      colors: (await resolve(parm["Colors"]) as num?)?.toInt() ?? 1,
      bitsPerComponent: (await resolve(parm["BitsPerComponent"]) as num?)?.toInt() ?? 8,
      columns: (await resolve(parm["Columns"]) as num?)?.toInt() ?? 1,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _objects.clear();
    _objectStreams.clear();
    _nodeCache.clear();
    await source.close();
  }
}

Rect uPdfRectFromArray(List<Object?>? values, {Rect fallback = const Rect.fromLTWH(0, 0, 612, 792)}) {
  if (values == null || values.length < 4) return fallback;
  final List<double> numbers = <double>[];
  for (final Object? value in values) {
    if (value is num) numbers.add(value.toDouble());
  }
  if (numbers.length < 4) return fallback;
  final double left = numbers[0] < numbers[2] ? numbers[0] : numbers[2];
  final double right = numbers[0] < numbers[2] ? numbers[2] : numbers[0];
  final double bottom = numbers[1] < numbers[3] ? numbers[1] : numbers[3];
  final double top = numbers[1] < numbers[3] ? numbers[3] : numbers[1];
  final Rect rect = Rect.fromLTRB(left, bottom, right, top);
  return rect.width <= 0 || rect.height <= 0 ? fallback : rect;
}

extension UPdfDocumentPages on UPdfDocument {
  static final Map<String, Map<int, int>> _pageIndexCache = <String, Map<int, int>>{};
  static final Map<String, List<UPdfRef>> _flatPageCache = <String, List<UPdfRef>>{};

  static void resetCaches(String fingerprint) {
    _pageIndexCache.remove(fingerprint);
    _flatPageCache.remove(fingerprint);
  }

  Future<UPdfPage?> page(int index) async {
    if (index < 0 || index >= pageCount) return null;
    final Object? rootObject = await resolve(catalog?["Pages"]);
    UPdfDict? node = rootObject is UPdfDict ? rootObject : null;
    UPdfRef? nodeRef = catalog?["Pages"] is UPdfRef ? catalog!["Pages"]! as UPdfRef : null;
    Object? resources = node?["Resources"];
    Object? mediaBox = node?["MediaBox"];
    Object? cropBox = node?["CropBox"];
    Object? rotate = node?["Rotate"];
    int remaining = index;
    int depth = 0;
    while (node != null && depth < uDocMaxDepth) {
      depth++;
      final Object? kidsObject = await resolve(node["Kids"]);
      if (kidsObject is! List<Object?>) break;
      bool descended = false;
      for (final Object? kid in kidsObject) {
        final Object? resolved = await resolve(kid);
        if (resolved is! UPdfDict) continue;
        final Object? kidType = resolved["Type"];
        final bool isBranch = (kidType is UPdfName && kidType.value == "Pages") || resolved.has("Kids");
        final int count = isBranch ? ((await resolve(resolved["Count"]) as num?)?.toInt() ?? 0) : 1;
        if (remaining >= count) {
          remaining -= count;
          continue;
        }
        resources = resolved["Resources"] ?? resources;
        mediaBox = resolved["MediaBox"] ?? mediaBox;
        cropBox = resolved["CropBox"] ?? cropBox;
        rotate = resolved["Rotate"] ?? rotate;
        node = resolved;
        nodeRef = kid is UPdfRef ? kid : null;
        descended = true;
        if (!isBranch) return _buildPage(index, nodeRef, resolved, resources, mediaBox, cropBox, rotate);
        break;
      }
      if (!descended) break;
    }
    final List<UPdfRef> flat = await _flatPages();
    if (index < flat.length) {
      final Object? resolved = await resolve(flat[index]);
      if (resolved is UPdfDict) return _buildPage(index, flat[index], resolved, resolved["Resources"], resolved["MediaBox"], resolved["CropBox"], resolved["Rotate"]);
    }
    return null;
  }

  Future<UPdfPage> _buildPage(int index, UPdfRef? ref, UPdfDict dict, Object? resources, Object? mediaBox, Object? cropBox, Object? rotate) async {
    final Object? resolvedResources = await resolve(resources);
    final Object? resolvedMedia = await resolve(mediaBox);
    final Object? resolvedCrop = await resolve(cropBox);
    final Object? resolvedRotate = await resolve(rotate);
    final Rect media = uPdfRectFromArray(resolvedMedia is List<Object?> ? resolvedMedia : null);
    final Rect crop = resolvedCrop is List<Object?> ? uPdfRectFromArray(resolvedCrop, fallback: media) : media;
    final int rotation = resolvedRotate is num ? ((resolvedRotate.toInt() % 360) + 360) % 360 : 0;
    return UPdfPage(
      index: index,
      ref: ref,
      dict: dict,
      mediaBox: media,
      cropBox: crop.intersect(media).isEmpty ? media : crop,
      rotation: rotation - rotation % 90,
      resources: resolvedResources is UPdfDict ? resolvedResources : null,
    );
  }

  Future<List<UPdfRef>> _flatPages() async {
    final List<UPdfRef>? cached = _flatPageCache[fingerprint];
    if (cached != null) return cached;
    final List<UPdfRef> refs = <UPdfRef>[];
    final List<int> numbers = xref.entries.keys.toList()..sort();
    for (final int number in numbers) {
      final UPdfXrefEntry entry = xref.entries[number]!;
      if (entry.isFree) continue;
      final Object? candidate = await object(UPdfRef(number, entry.generation));
      if (candidate is UPdfDict) {
        final Object? type = candidate["Type"];
        if (type is UPdfName && type.value == "Page") refs.add(UPdfRef(number, entry.generation));
      }
    }
    _flatPageCache[fingerprint] = refs;
    return refs;
  }

  Future<Map<int, int>> _pageIndexMap() async {
    final Map<int, int>? cached = _pageIndexCache[fingerprint];
    if (cached != null) return cached;
    final Map<int, int> map = <int, int>{};
    final Object? rootObject = await resolve(catalog?["Pages"]);
    int counter = 0;
    Future<void> walk(Object? nodeObject, Object? nodeRef, int depth) async {
      if (depth > uDocMaxDepth || counter > pageCount + 8) return;
      final Object? resolved = await resolve(nodeObject);
      if (resolved is! UPdfDict) return;
      final Object? kids = await resolve(resolved["Kids"]);
      if (kids is! List<Object?>) {
        if (nodeRef is UPdfRef) map[nodeRef.number] = counter;
        counter++;
        return;
      }
      for (final Object? kid in kids) {
        await walk(kid, kid, depth + 1);
      }
    }

    await walk(rootObject, catalog?["Pages"], 0);
    if (map.isEmpty) {
      final List<UPdfRef> flat = await _flatPages();
      for (int i = 0; i < flat.length; i++) {
        map[flat[i].number] = i;
      }
    }
    _pageIndexCache[fingerprint] = map;
    return map;
  }

  Future<Uint8List> pageContent(UPdfPage page) async {
    final Object? contents = await resolve(page.dict["Contents"]);
    final List<int> out = <int>[];
    if (contents is UPdfStream) {
      out.addAll((await decodeStream(contents)).bytes);
    } else if (contents is List<Object?>) {
      for (final Object? entry in contents) {
        final Object? resolved = await resolve(entry);
        if (resolved is UPdfStream) {
          out.addAll((await decodeStream(resolved)).bytes);
          out.add(UPdfSyntax.lineFeed);
        }
      }
    }
    return Uint8List.fromList(out);
  }

  Future<UDocMetadata> metadata() async {
    final UPdfDict? source = info;
    String? read(String key) {
      final Object? value = source?[key];
      return value is UPdfString ? value.text : null;
    }

    DateTime? readDate(String key) {
      final Object? value = source?[key];
      return value is UPdfString ? value.date : null;
    }

    final Object? language = await resolve(catalog?["Lang"]);
    final Object? markInfo = await resolve(catalog?["MarkInfo"]);
    final bool tagged = markInfo is UPdfDict && (markInfo["Marked"] as bool? ?? false);
    return UDocMetadata(
      title: read("Title"),
      author: read("Author"),
      subject: read("Subject"),
      keywords: read("Keywords"),
      creator: read("Creator"),
      producer: read("Producer"),
      creationDate: readDate("CreationDate"),
      modificationDate: readDate("ModDate"),
      language: language is UPdfString ? language.text : null,
      pageCount: pageCount,
      version: version,
      tagged: tagged,
      linearized: linearized,
      encrypted: isEncrypted,
    );
  }

  Future<UDocDestination?> destination(Object? value, {int depth = 0}) async {
    if (depth > 8) return null;
    final Object? resolved = await resolve(value);
    if (resolved is UPdfString || resolved is UPdfName) {
      final String name = resolved is UPdfString ? resolved.text : (resolved! as UPdfName).value;
      final Object? named = await _lookupNamedDestination(name);
      if (named == null) return null;
      return destination(named, depth: depth + 1);
    }
    if (resolved is UPdfDict) return destination(resolved["D"], depth: depth + 1);
    if (resolved is! List<Object?> || resolved.isEmpty) return null;
    final Object? target = resolved.first;
    int pageIndex = 0;
    if (target is UPdfRef) {
      final Map<int, int> map = await _pageIndexMap();
      pageIndex = map[target.number] ?? 0;
    } else if (target is num) {
      pageIndex = target.toInt();
    }
    UDocFit fit = UDocFit.custom;
    double? left;
    double? top;
    double? zoom;
    if (resolved.length > 1) {
      final Object? mode = resolved[1];
      final String modeName = mode is UPdfName ? mode.value : "";
      switch (modeName) {
        case "XYZ":
          left = resolved.length > 2 && resolved[2] is num ? (resolved[2]! as num).toDouble() : null;
          top = resolved.length > 3 && resolved[3] is num ? (resolved[3]! as num).toDouble() : null;
          zoom = resolved.length > 4 && resolved[4] is num ? (resolved[4]! as num).toDouble() : null;
          break;
        case "Fit":
          fit = UDocFit.page;
          break;
        case "FitH":
        case "FitBH":
          fit = UDocFit.width;
          top = resolved.length > 2 && resolved[2] is num ? (resolved[2]! as num).toDouble() : null;
          break;
        case "FitV":
        case "FitBV":
          fit = UDocFit.height;
          left = resolved.length > 2 && resolved[2] is num ? (resolved[2]! as num).toDouble() : null;
          break;
        case "FitR":
          fit = UDocFit.visible;
          break;
        default:
          break;
      }
    }
    return UDocDestination(pageIndex: pageIndex, left: left, top: top, zoom: zoom, fitMode: fit);
  }

  Future<Object?> _lookupNamedDestination(String name) async {
    final Object? dests = await resolve(catalog?["Dests"]);
    if (dests is UPdfDict && dests.has(name)) return dests[name];
    final Object? names = await resolve(catalog?["Names"]);
    if (names is! UPdfDict) return null;
    final Object? destsTree = await resolve(names["Dests"]);
    return _searchNameTree(destsTree, name, 0);
  }

  Future<Object?> _searchNameTree(Object? nodeObject, String name, int depth) async {
    if (depth > uDocMaxDepth) return null;
    final Object? node = await resolve(nodeObject);
    if (node is! UPdfDict) return null;
    final Object? names = await resolve(node["Names"]);
    if (names is List<Object?>) {
      for (int i = 0; i + 1 < names.length; i += 2) {
        final Object? key = await resolve(names[i]);
        final String keyText = key is UPdfString ? key.text : "";
        if (keyText == name) return names[i + 1];
      }
    }
    final Object? kids = await resolve(node["Kids"]);
    if (kids is List<Object?>) {
      for (final Object? kid in kids) {
        final Object? found = await _searchNameTree(kid, name, depth + 1);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<List<UDocOutlineNode>> outline() async {
    final Object? outlines = await resolve(catalog?["Outlines"]);
    if (outlines is! UPdfDict) return const <UDocOutlineNode>[];
    return _outlineChildren(outlines["First"], 0, <int>{});
  }

  Future<List<UDocOutlineNode>> _outlineChildren(Object? firstObject, int depth, Set<int> visited) async {
    if (depth > 24) return const <UDocOutlineNode>[];
    final List<UDocOutlineNode> nodes = <UDocOutlineNode>[];
    Object? current = firstObject;
    int guard = 0;
    while (current != null && guard < 4096) {
      guard++;
      if (current is UPdfRef && !visited.add(current.number)) break;
      final Object? resolved = await resolve(current);
      if (resolved is! UPdfDict) break;
      final Object? titleObject = await resolve(resolved["Title"]);
      final String title = titleObject is UPdfString ? titleObject.text : "";
      UDocDestination? target = await destination(resolved["Dest"]);
      String? uri;
      final Object? action = await resolve(resolved["A"]);
      if (action is UPdfDict) {
        final Object? actionType = action["S"];
        if (actionType is UPdfName && actionType.value == "URI") {
          final Object? uriObject = await resolve(action["URI"]);
          uri = uriObject is UPdfString ? uriObject.text : null;
        }
        target ??= await destination(action["D"]);
      }
      final Object? countObject = await resolve(resolved["Count"]);
      final int count = countObject is num ? countObject.toInt() : 0;
      final Object? colorObject = await resolve(resolved["C"]);
      Color? color;
      if (colorObject is List<Object?> && colorObject.length >= 3) {
        final List<double> rgb = colorObject.whereType<num>().map((num value) => value.toDouble()).toList();
        if (rgb.length >= 3) color = Color.fromARGB(255, (rgb[0] * 255).round().clamp(0, 255), (rgb[1] * 255).round().clamp(0, 255), (rgb[2] * 255).round().clamp(0, 255));
      }
      final Object? flagsObject = await resolve(resolved["F"]);
      final int flags = flagsObject is num ? flagsObject.toInt() : 0;
      final List<UDocOutlineNode> children = await _outlineChildren(resolved["First"], depth + 1, visited);
      nodes.add(UDocOutlineNode(title: title, destination: target, uri: uri, children: children, expanded: count > 0, color: color, bold: flags & 2 != 0, italic: flags & 1 != 0));
      current = resolved["Next"];
    }
    return nodes;
  }

  Future<List<UDocLink>> links(int pageIndex) async {
    final UPdfPage? target = await page(pageIndex);
    if (target == null) return const <UDocLink>[];
    final Object? annotations = await resolve(target.dict["Annots"]);
    if (annotations is! List<Object?>) return const <UDocLink>[];
    final List<UDocLink> out = <UDocLink>[];
    for (final Object? entry in annotations) {
      final Object? annotation = await resolve(entry);
      if (annotation is! UPdfDict) continue;
      final Object? subtype = annotation["Subtype"];
      if (subtype is! UPdfName || subtype.value != "Link") continue;
      final Object? rectObject = await resolve(annotation["Rect"]);
      final Rect rect = uPdfRectFromArray(rectObject is List<Object?> ? rectObject : null, fallback: Rect.zero);
      UDocDestination? target2 = await destination(annotation["Dest"]);
      String? uri;
      String? actionName;
      final Object? action = await resolve(annotation["A"]);
      if (action is UPdfDict) {
        final Object? actionType = action["S"];
        actionName = actionType is UPdfName ? actionType.value : null;
        if (actionName == "URI") {
          final Object? uriObject = await resolve(action["URI"]);
          uri = uriObject is UPdfString ? uriObject.text : null;
        }
        target2 ??= await destination(action["D"]);
      }
      out.add(UDocLink(pageIndex: pageIndex, rect: rect, destination: target2, uri: uri, action: actionName));
    }
    return out;
  }

  Future<String?> pageLabel(int index) async {
    final List<String>? cached = _pageLabels;
    if (cached != null) return index < cached.length ? cached[index] : null;
    final Object? labels = await resolve(catalog?["PageLabels"]);
    if (labels is! UPdfDict) {
      _pageLabels = const <String>[];
      return null;
    }
    final List<String> out = List<String>.filled(pageCount, "");
    final Object? numbers = await resolve(labels["Nums"]);
    final List<int> starts = <int>[];
    final List<UPdfDict> specs = <UPdfDict>[];
    if (numbers is List<Object?>) {
      for (int i = 0; i + 1 < numbers.length; i += 2) {
        final Object? key = await resolve(numbers[i]);
        final Object? spec = await resolve(numbers[i + 1]);
        if (key is num && spec is UPdfDict) {
          starts.add(key.toInt());
          specs.add(spec);
        }
      }
    }
    for (int i = 0; i < starts.length; i++) {
      final int from = starts[i];
      final int to = i + 1 < starts.length ? starts[i + 1] : pageCount;
      final UPdfDict spec = specs[i];
      final Object? styleObject = spec["S"];
      final String style = styleObject is UPdfName ? styleObject.value : "";
      final Object? prefixObject = await resolve(spec["P"]);
      final String prefix = prefixObject is UPdfString ? prefixObject.text : "";
      final Object? startObject = await resolve(spec["St"]);
      final int start = startObject is num ? startObject.toInt() : 1;
      for (int p = from; p < to && p < pageCount; p++) {
        if (p < 0) continue;
        final int value = start + (p - from);
        out[p] = "$prefix${_labelNumber(value, style)}";
      }
    }
    _pageLabels = out;
    return index < out.length ? out[index] : null;
  }

  String _labelNumber(int value, String style) {
    switch (style) {
      case "D":
        return "$value";
      case "r":
        return _roman(value).toLowerCase();
      case "R":
        return _roman(value);
      case "a":
        return _letters(value).toLowerCase();
      case "A":
        return _letters(value);
      default:
        return "";
    }
  }

  String _roman(int value) {
    const List<int> numbers = <int>[1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const List<String> symbols = <String>["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
    final StringBuffer buffer = StringBuffer();
    int remaining = value;
    for (int i = 0; i < numbers.length; i++) {
      while (remaining >= numbers[i]) {
        buffer.write(symbols[i]);
        remaining -= numbers[i];
      }
    }
    return buffer.toString();
  }

  String _letters(int value) {
    if (value <= 0) return "";
    final int repeat = ((value - 1) ~/ 26) + 1;
    final String letter = String.fromCharCode(0x41 + ((value - 1) % 26));
    return letter * repeat;
  }
}
