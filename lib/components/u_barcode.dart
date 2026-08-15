import "dart:math" as math;
import "dart:typed_data";
import "dart:ui" as ui;

import "package:u/utilities.dart";

class BarcodeAztec extends Barcode2D {
  const BarcodeAztec(this.minECCPercent, this.userSpecifiedLayers) : assert(minECCPercent >= 0 && minECCPercent <= 100), assert(userSpecifiedLayers >= 0);
  static const defaultEcPercent = 33;
  static const defaultLayers = 0;
  final int minECCPercent;
  final int userSpecifiedLayers;
  static const _maxNbBits = 32;
  static const _maxNbBitsCompact = 4;
  static const _wordSize = <int>[4, 6, 6, 8, 8, 8, 8, 8, 8, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12];
  static bool _initialized = false;
  static late Map<_EncodingMode, List<int?>> _charMap;

  static void _init() {
    _charMap = <_EncodingMode, List<int?>>{};
    _charMap[_EncodingMode.mode_upper] = List<int?>.filled(256, null);
    _charMap[_EncodingMode.mode_lower] = List<int?>.filled(256, null);
    _charMap[_EncodingMode.mode_digit] = List<int?>.filled(256, null);
    _charMap[_EncodingMode.mode_mixed] = List<int?>.filled(256, null);
    _charMap[_EncodingMode.mode_punct] = List<int?>.filled(256, null);
    _charMap[_EncodingMode.mode_upper]![0x20] = 1;
    for (var c = 0x41; c <= 0x5a; c++) _charMap[_EncodingMode.mode_upper]![c] = c - 0x41 + 2;

    _charMap[_EncodingMode.mode_lower]![0x20] = 1;
    for (var c = 0x61; c <= 0x7a; c++) _charMap[_EncodingMode.mode_lower]![c] = c - 0x61 + 2;
    _charMap[_EncodingMode.mode_digit]![0x20] = 1;
    for (var c = 0x30; c <= 0x39; c++) _charMap[_EncodingMode.mode_digit]![c] = c - 0x30 + 2;
    _charMap[_EncodingMode.mode_digit]![0x2c] = 12;
    _charMap[_EncodingMode.mode_digit]![0x2e] = 13;

    final mixedTable = <int>[0, 0x20, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 27, 28, 29, 30, 31, 0x40, 0x5c, 0x5e, 0x5f, 0x60, 0x7c, 0x7e, 127];
    for (var i = 0; i < mixedTable.length; i++) _charMap[_EncodingMode.mode_mixed]![mixedTable[i]] = i;

    const punctTable = <int>[0, 0xd, 0, 0, 0, 0, 0x21, 0x27, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x5b, 0x5d, 0x7b, 0x7d];

    for (var i = 0; i < punctTable.length; i++) {
      final v = punctTable[i];
      if (v > 0) _charMap[_EncodingMode.mode_punct]![v] = i;
    }
  }

  @override
  Barcode2DMatrix convert(Uint8List data) {
    if (!_initialized) {
      _init();
      _initialized = true;
    }

    final m = _encode(data);

    return Barcode2DMatrix(m.matrixSize, m.matrixSize, 1, m.bits);
  }

  @override
  Iterable<int> get charSet => Iterable<int>.generate(256);

  @override
  String get name => "Aztec";

  @override
  int get maxLength => 2335;

  List<int> _bitsToWords(List<bool> stuffedBits, int wordSize, int wordCount) {
    final message = List<int>.filled(wordCount, 0);

    for (var i = 0; i < wordCount; i++) {
      var value = 0;
      for (var j = 0; j < wordSize; j++) {
        if (stuffedBits[i * wordSize + j]) value |= 1 << (wordSize - j - 1);
      }
      message[i] = value;
    }
    return message;
  }

  List<bool> _generateCheckWords(List<bool> bits, int totalBits, int wordSize) {
    final rs = ReedSolomonEncoder(_getGF(wordSize));
    final messageWordCount = bits.length ~/ wordSize;
    final totalWordCount = totalBits ~/ wordSize;
    final eccWordCount = totalWordCount - messageWordCount;
    final messageWords = _bitsToWords(bits, wordSize, messageWordCount);
    final eccWords = rs.encode(messageWords, eccWordCount);
    final startPad = totalBits % wordSize;
    final messageBits = <bool>[];
    messageBits.addAll(_addBits(0, startPad));
    for (final messageWord in messageWords) messageBits.addAll(_addBits(messageWord, wordSize));
    for (final eccWord in eccWords) messageBits.addAll(_addBits(eccWord, wordSize));
    return messageBits;
  }

  GaloisField _getGF(int wordSize) {
    switch (wordSize) {
      case 4:
        return GaloisField(0x13, 16, 1);
      case 6:
        return GaloisField(0x43, 64, 1);
      case 8:
        return GaloisField(0x012D, 256, 1);
      case 10:
        return GaloisField(0x409, 1024, 1);
      case 12:
        return GaloisField(0x1069, 4096, 1);
      default:
        throw const BarcodeException("Unable to find the Galois field");
    }
  }

  List<bool> _highlevelEncode(List<int> data) {
    var states = <_State>[_State.initialState];

    for (var index = 0; index < data.length; index++) {
      var pairCode = 0;
      var nextChar = 0;
      if (index + 1 < data.length) nextChar = data[index + 1];

      final cur = data[index];
      if (cur == 0xd && nextChar == 0xa)
        pairCode = 2;
      else if (cur == 0x2e && nextChar == 0x20)
        pairCode = 3;
      else if (cur == 0x2c && nextChar == 0x20)
        pairCode = 4;
      else if (cur == 0x3a && nextChar == 0x20)
        pairCode = 5;

      if (pairCode > 0) {
        states = _updateStateListForPair(states, data, index, pairCode);
        index++;
      } else states = _updateStateListForChar(states, data, index);
    }
    int? minBitCnt;
    _State? result;
    for (final s in states) {
      if (minBitCnt == null || s.bitCount < minBitCnt) {
        minBitCnt = s.bitCount;
        result = s;
      }
    }
    if (result != null) {
      return result.toBitList(data);
    } else {
      return <bool>[];
    }
  }

  List<_State> _simplifyStates(List<_State> states) {
    var result = <_State>[];
    for (final newState in states) {
      var add = true;
      final newResult = <_State>[];

      for (final oldState in result) {
        if (add && oldState.isBetterThanOrEqualTo(newState)) {
          add = false;
        }
        if (!(add && newState.isBetterThanOrEqualTo(oldState))) {
          newResult.add(oldState);
        }
      }

      if (add) {
        result.add(newState);
      } else {
        result = newResult;
      }
    }

    return result;
  }

  List<_State> _updateStateListForChar(List<_State> states, List<int> data, int index) {
    final result = <_State>[];
    for (final s in states) {
      final r = _updateStateForChar(s, data, index);
      if (r.isNotEmpty) {
        result.addAll(r);
      }
    }
    return _simplifyStates(result);
  }

  List<_State> _updateStateForChar(_State s, List<int> data, int index) {
    final result = <_State>[];
    final ch = data[index];
    final charInCurrentTable = _charMap[s.mode]![ch] != null;

    _State? stateNoBinary;
    for (var mode in _EncodingMode.values) {
      final charInMode = _charMap[mode]![ch];
      if (charInMode != null && charInMode > 0) {
        stateNoBinary ??= s.endBinaryShift(index);

        if (!charInCurrentTable || mode == s.mode || mode == _EncodingMode.mode_digit) {
          final res = stateNoBinary.latchAndAppend(mode, charInMode);
          result.add(res);
        }

        if (!charInCurrentTable && _shiftTable[s.mode] != null && _shiftTable[s.mode]![mode] != null) {
          final res = stateNoBinary.shiftAndAppend(mode, charInMode);
          result.add(res);
        }
      }
    }
    if (s.bShiftByteCount > 0 || _charMap[s.mode]![ch] == null) {
      final res = s.addBinaryShiftChar(index);
      result.add(res);
    }
    return result;
  }

  List<_State> _updateStateListForPair(List<_State> states, List<int> data, int index, int pairCode) {
    final result = <_State>[];
    for (final s in states) {
      final r = _updateStateForPair(s, data, index, pairCode);
      if (r.isNotEmpty) {
        result.addAll(r);
      }
    }
    return _simplifyStates(result);
  }

  List<_State> _updateStateForPair(_State s, List<int> data, int index, int pairCode) {
    final result = <_State>[];
    final stateNoBinary = s.endBinaryShift(index);

    result.add(stateNoBinary.latchAndAppend(_EncodingMode.mode_punct, pairCode));
    if (s.mode != _EncodingMode.mode_punct) {
      result.add(stateNoBinary.shiftAndAppend(_EncodingMode.mode_punct, pairCode));
    }
    if (pairCode == 3 || pairCode == 4) {
      final digitState = stateNoBinary.latchAndAppend(_EncodingMode.mode_digit, 16 - pairCode).latchAndAppend(_EncodingMode.mode_digit, 1);
      result.add(digitState);
    }
    if (s.bShiftByteCount > 0) {
      result.add(s.addBinaryShiftChar(index).addBinaryShiftChar(index + 1));
    }
    return result;
  }

  int _totalBitsInLayer(int layers, bool compact) {
    var tmp = 112;
    if (compact) {
      tmp = 88;
    }
    return (tmp + 16 * layers) * layers;
  }

  List<bool> _stuffBits(List<bool> bits, int wordSize) {
    final out = <bool>[];
    final n = bits.length;
    final mask = (1 << wordSize) - 2;
    for (var i = 0; i < n; i += wordSize) {
      var word = 0;
      for (var j = 0; j < wordSize; j++) {
        if (i + j >= n || bits[i + j]) {
          word |= 1 << (wordSize - 1 - j);
        }
      }
      if ((word & mask) == mask) {
        out.addAll(_addBits(word & mask, wordSize));
        i--;
      } else if ((word & mask) == 0) {
        out.addAll(_addBits(word | 1, wordSize));
        i--;
      } else {
        out.addAll(_addBits(word, wordSize));
      }
    }
    return out;
  }

  List<bool> _generateModeMessage(bool compact, int layers, int messageSizeInWords) {
    var modeMessage = <bool>[];
    if (compact) {
      modeMessage.addAll(_addBits(layers - 1, 2));
      modeMessage.addAll(_addBits(messageSizeInWords - 1, 6));
      modeMessage = _generateCheckWords(modeMessage, 28, 4);
    } else {
      modeMessage.addAll(_addBits(layers - 1, 5));
      modeMessage.addAll(_addBits(messageSizeInWords - 1, 11));
      modeMessage = _generateCheckWords(modeMessage, 40, 4);
    }
    return modeMessage;
  }

  void _drawModeMessage(_AztecCode matrix, bool compact, int matrixSize, List<bool> modeMessage) {
    final center = matrixSize ~/ 2;

    if (compact) {
      for (var i = 0; i < 7; i++) {
        final offset = center - 3 + i;
        if (modeMessage[i]) {
          matrix.set(offset, center - 5);
        }
        if (modeMessage[i + 7]) {
          matrix.set(center + 5, offset);
        }
        if (modeMessage[20 - i]) {
          matrix.set(offset, center + 5);
        }
        if (modeMessage[27 - i]) {
          matrix.set(center - 5, offset);
        }
      }
    } else {
      for (var i = 0; i < 10; i++) {
        final offset = center - 5 + i + i ~/ 5;
        if (modeMessage[i]) {
          matrix.set(offset, center - 7);
        }
        if (modeMessage[i + 10]) {
          matrix.set(center + 7, offset);
        }
        if (modeMessage[29 - i]) {
          matrix.set(offset, center + 7);
        }
        if (modeMessage[39 - i]) {
          matrix.set(center - 7, offset);
        }
      }
    }
  }

  void _drawBullsEye(_AztecCode matrix, int center, int size) {
    for (var i = 0; i < size; i += 2) {
      for (var j = center - i; j <= center + i; j++) {
        matrix.set(j, center - i);
        matrix.set(j, center + i);
        matrix.set(center - i, j);
        matrix.set(center + i, j);
      }
    }
    matrix.set(center - size, center - size);
    matrix.set(center - size + 1, center - size);
    matrix.set(center - size, center - size + 1);
    matrix.set(center + size, center - size);
    matrix.set(center + size, center - size + 1);
    matrix.set(center + size, center + size - 1);
  }

  _AztecCode _encode(List<int> data) {
    final bits = _highlevelEncode(data);
    final eccBits = ((bits.length * minECCPercent) ~/ 100) + 11;
    final totalSizeBits = bits.length + eccBits;
    int layers;
    int wordSize;
    int totalBitsInLayer;
    bool compact;
    List<bool>? stuffedBits;
    if (userSpecifiedLayers != defaultLayers) {
      compact = userSpecifiedLayers < 0;
      if (compact) {
        layers = -userSpecifiedLayers;
      } else {
        layers = userSpecifiedLayers;
      }
      if ((compact && layers > _maxNbBitsCompact) || (!compact && layers > _maxNbBits)) {
        throw BarcodeException("Illegal value $userSpecifiedLayers for layers");
      }
      totalBitsInLayer = _totalBitsInLayer(layers, compact);
      wordSize = _wordSize[layers];
      final usableBitsInLayers = totalBitsInLayer - (totalBitsInLayer % wordSize);
      stuffedBits = _stuffBits(bits, wordSize);
      if (stuffedBits.length + eccBits > usableBitsInLayers) {
        throw const BarcodeException("Data too large for user specified layer");
      }
      if (compact && stuffedBits.length > wordSize * 64) {
        throw const BarcodeException("Data too large for user specified layer");
      }
    } else {
      wordSize = 0;
      stuffedBits = null;

      for (var i = 0; ; i++) {
        if (i > _maxNbBits) {
          throw const BarcodeException("Data too large for an aztec code");
        }
        compact = i <= 3;
        layers = i;
        if (compact) {
          layers = i + 1;
        }
        totalBitsInLayer = _totalBitsInLayer(layers, compact);
        if (totalSizeBits > totalBitsInLayer) {
          continue;
        }

        if (wordSize != _wordSize[layers]) {
          wordSize = _wordSize[layers];
          stuffedBits = _stuffBits(bits, wordSize);
        }
        final usableBitsInLayers = totalBitsInLayer - (totalBitsInLayer % wordSize);
        if (compact && stuffedBits!.length > wordSize * 64) {
          continue;
        }
        if (stuffedBits!.length + eccBits <= usableBitsInLayers) {
          break;
        }
      }
    }
    final messageBits = _generateCheckWords(stuffedBits, totalBitsInLayer, wordSize);
    final messageSizeInWords = stuffedBits.length ~/ wordSize;
    final modeMessage = _generateModeMessage(compact, layers, messageSizeInWords);

    int baseMatrixSize;
    if (compact) {
      baseMatrixSize = 11 + layers * 4;
    } else {
      baseMatrixSize = 14 + layers * 4;
    }
    final alignmentMap = List<int>.filled(baseMatrixSize, 0);
    int matrixSize;

    if (compact) {
      matrixSize = baseMatrixSize;
      for (var i = 0; i < alignmentMap.length; i++) {
        alignmentMap[i] = i;
      }
    } else {
      matrixSize = baseMatrixSize + 1 + 2 * ((baseMatrixSize / 2 - 1) ~/ 15);
      final origCenter = baseMatrixSize ~/ 2;
      final center = matrixSize ~/ 2;
      for (var i = 0; i < origCenter; i++) {
        final newOffset = i + i ~/ 15;
        alignmentMap[origCenter - i - 1] = center - newOffset - 1;
        alignmentMap[origCenter + i] = center + newOffset + 1;
      }
    }
    final code = _AztecCode(matrixSize);

    var rowOffset = 0;
    for (var i = 0; i < layers; i++) {
      var rowSize = (layers - i) * 4;
      if (compact) {
        rowSize += 9;
      } else {
        rowSize += 12;
      }

      for (var j = 0; j < rowSize; j++) {
        final columnOffset = j * 2;
        for (var k = 0; k < 2; k++) {
          if (messageBits[rowOffset + columnOffset + k]) {
            code.set(alignmentMap[i * 2 + k], alignmentMap[i * 2 + j]);
          }
          if (messageBits[rowOffset + rowSize * 2 + columnOffset + k]) {
            code.set(alignmentMap[i * 2 + j], alignmentMap[baseMatrixSize - 1 - i * 2 - k]);
          }
          if (messageBits[rowOffset + rowSize * 4 + columnOffset + k]) {
            code.set(alignmentMap[baseMatrixSize - 1 - i * 2 - k], alignmentMap[baseMatrixSize - 1 - i * 2 - j]);
          }
          if (messageBits[rowOffset + rowSize * 6 + columnOffset + k]) {
            code.set(alignmentMap[baseMatrixSize - 1 - i * 2 - j], alignmentMap[i * 2 + k]);
          }
        }
      }
      rowOffset += rowSize * 8;
    }

    _drawModeMessage(code, compact, matrixSize, modeMessage);

    if (compact) {
      _drawBullsEye(code, matrixSize ~/ 2, 5);
    } else {
      _drawBullsEye(code, matrixSize ~/ 2, 7);
      var j = 0;
      for (var i = 0; i < baseMatrixSize / 2 - 1; i += 15,) {
        for (var k = (matrixSize ~/ 2) & 1; k < matrixSize; k += 2) {
          code.set(matrixSize ~/ 2 - j, k);
          code.set(matrixSize ~/ 2 + j, k);
          code.set(k, matrixSize ~/ 2 - j);
          code.set(k, matrixSize ~/ 2 + j);
        }
        j += 16;
      }
    }
    return code;
  }
}

abstract class _Token {
  _Token(this.prev);

  final _Token? prev;

  void appendTo(List<bool> bits, List<int> text);
}

class _SimpleToken extends _Token {
  _SimpleToken(_Token? prev, this.value, this.bitCount) : super(prev);

  final int value;
  final int bitCount;

  @override
  void appendTo(List<bool> bits, List<int> text) {
    bits.addAll(_addBits(value, bitCount));
  }
}

class _BinaryShiftToken extends _Token {
  _BinaryShiftToken(_Token? prev, this.bShiftStart, this.bShiftByteCnt) : super(prev);

  final int bShiftStart;
  final int bShiftByteCnt;

  @override
  void appendTo(List<bool> bits, List<int> text) {
    for (var i = 0; i < bShiftByteCnt; i++) {
      if (i == 0 || (i == 31 && bShiftByteCnt <= 62)) {
        bits.addAll(_addBits(31, 5));
        if (bShiftByteCnt > 62) {
          bits.addAll(_addBits(bShiftByteCnt - 31, 16));
        } else if (i == 0) {
          if (bShiftByteCnt < 31) {
            bits.addAll(_addBits(bShiftByteCnt, 5));
          } else {
            bits.addAll(_addBits(31, 5));
          }
        } else {
          bits.addAll(_addBits(bShiftByteCnt - 31, 5));
        }
      }
      bits.addAll(_addBits(text[bShiftStart + i], 8));
    }
  }
}

Iterable<bool> _addBits(int b, int count) sync* {
  for (var i = count - 1; i >= 0; i--) {
    yield ((b >> i) & 1) == 1;
  }
}

enum _EncodingMode {
  mode_upper,
  mode_lower,
  mode_digit,
  mode_mixed,
  mode_punct,
}

const _shiftTable = <_EncodingMode, Map<_EncodingMode, int>>{
  _EncodingMode.mode_upper: {
    _EncodingMode.mode_punct: 0,
  },
  _EncodingMode.mode_lower: {
    _EncodingMode.mode_punct: 0,
    _EncodingMode.mode_upper: 28,
  },
  _EncodingMode.mode_mixed: {
    _EncodingMode.mode_punct: 0,
  },
  _EncodingMode.mode_digit: {
    _EncodingMode.mode_punct: 0,
    _EncodingMode.mode_upper: 15,
  },
};

class _State {
  const _State({
    required this.mode,
    this.tokens,
    required this.bShiftByteCount,
    required this.bitCount,
  });

  static const initialState = _State(
    mode: _EncodingMode.mode_upper,
    tokens: null,
    bShiftByteCount: 0,
    bitCount: 0,
  );

  final _EncodingMode mode;
  final _Token? tokens;
  final int bShiftByteCount;
  final int bitCount;

  static const latchTable = <_EncodingMode, Map<_EncodingMode, int>>{
    _EncodingMode.mode_upper: {
      _EncodingMode.mode_upper: 0,
      _EncodingMode.mode_lower: (5 << 16) + 28,
      _EncodingMode.mode_digit: (5 << 16) + 30,
      _EncodingMode.mode_mixed: (5 << 16) + 29,
      _EncodingMode.mode_punct: (10 << 16) + (29 << 5) + 30,
    },
    _EncodingMode.mode_lower: {
      _EncodingMode.mode_upper: (9 << 16) + (30 << 4) + 14,
      _EncodingMode.mode_lower: 0,
      _EncodingMode.mode_digit: (5 << 16) + 30,
      _EncodingMode.mode_mixed: (5 << 16) + 29,
      _EncodingMode.mode_punct: (10 << 16) + (29 << 5) + 30,
    },
    _EncodingMode.mode_digit: {
      _EncodingMode.mode_upper: (4 << 16) + 14,
      _EncodingMode.mode_lower: (9 << 16) + (14 << 5) + 28,
      _EncodingMode.mode_digit: 0,
      _EncodingMode.mode_mixed: (9 << 16) + (14 << 5) + 29,
      _EncodingMode.mode_punct: (14 << 16) + (14 << 10) + (29 << 5) + 30,
    },
    _EncodingMode.mode_mixed: {
      _EncodingMode.mode_upper: (5 << 16) + 29,
      _EncodingMode.mode_lower: (5 << 16) + 28,
      _EncodingMode.mode_digit: (10 << 16) + (29 << 5) + 30,
      _EncodingMode.mode_mixed: 0,
      _EncodingMode.mode_punct: (5 << 16) + 30,
    },
    _EncodingMode.mode_punct: {
      _EncodingMode.mode_upper: (5 << 16) + 31,
      _EncodingMode.mode_lower: (10 << 16) + (31 << 5) + 28,
      _EncodingMode.mode_digit: (10 << 16) + (31 << 5) + 30,
      _EncodingMode.mode_mixed: (10 << 16) + (31 << 5) + 29,
      _EncodingMode.mode_punct: 0,
    },
  };

  _State latchAndAppend(_EncodingMode mode, int value) {
    var bitCount = this.bitCount;
    var tokens = this.tokens;

    if (mode != this.mode) {
      final latch = latchTable[this.mode]![mode]!;
      tokens = _SimpleToken(tokens, latch & 0xFFFF, latch >> 16);
      bitCount += latch >> 16;
    }
    tokens = _SimpleToken(tokens, value, _bitCount(mode));
    return _State(
      mode: mode,
      tokens: tokens,
      bShiftByteCount: 0,
      bitCount: bitCount + _bitCount(mode),
    );
  }

  _State shiftAndAppend(_EncodingMode mode, int value) {
    var tokens = this.tokens;

    tokens = _SimpleToken(tokens, _shiftTable[this.mode]![mode]!, _bitCount(this.mode));
    tokens = _SimpleToken(tokens, value, 5);

    return _State(
      mode: this.mode,
      tokens: tokens,
      bShiftByteCount: 0,
      bitCount: bitCount + _bitCount(this.mode) + 5,
    );
  }

  _State addBinaryShiftChar(int index) {
    var tokens = this.tokens;
    var mode = this.mode;
    var bitCnt = bitCount;
    if (this.mode == _EncodingMode.mode_punct || this.mode == _EncodingMode.mode_digit) {
      final latch = latchTable[this.mode]![_EncodingMode.mode_upper]!;
      tokens = _SimpleToken(tokens, latch & 0xFFFF, latch >> 16);
      bitCnt += latch >> 16;
      mode = _EncodingMode.mode_upper;
    }
    var deltaBitCount = 8;
    if (bShiftByteCount == 0 || bShiftByteCount == 31) {
      deltaBitCount = 18;
    } else if (bShiftByteCount == 62) {
      deltaBitCount = 9;
    }
    var result = _State(
      mode: mode,
      tokens: tokens,
      bShiftByteCount: bShiftByteCount + 1,
      bitCount: bitCnt + deltaBitCount,
    );
    if (result.bShiftByteCount == 2047 + 31) {
      result = result.endBinaryShift(index + 1);
    }

    return result;
  }

  _State endBinaryShift(int index) {
    if (bShiftByteCount == 0) {
      return this;
    }
    final tokens = _BinaryShiftToken(this.tokens, index - bShiftByteCount, bShiftByteCount);
    return _State(
      mode: mode,
      tokens: tokens,
      bShiftByteCount: 0,
      bitCount: bitCount,
    );
  }

  bool isBetterThanOrEqualTo(_State other) {
    var mySize = bitCount + (latchTable[mode]![other.mode]! >> 16);

    if (other.bShiftByteCount > 0 && (bShiftByteCount == 0 || bShiftByteCount > other.bShiftByteCount)) {
      mySize += 10;
    }
    return mySize <= other.bitCount;
  }

  List<bool> toBitList(List<int> text) {
    final tokens = <_Token>[];
    final se = endBinaryShift(text.length);

    for (var t = se.tokens; t != null; t = t.prev) {
      tokens.add(t);
    }
    final res = <bool>[];
    for (var i = tokens.length - 1; i >= 0; i--) {
      tokens[i].appendTo(res, text);
    }
    return res;
  }
}

int _bitCount(_EncodingMode em) {
  if (em == _EncodingMode.mode_digit) {
    return 4;
  }
  return 5;
}

class _AztecCode {
  _AztecCode(this.matrixSize) : bits = List<bool>.filled(matrixSize * matrixSize, false);

  final List<bool> bits;

  final int matrixSize;

  void set(int x, int y) {
    bits[y * matrixSize + x] = true;
  }
}

abstract class Barcode {
  const Barcode();

  factory Barcode.fromType(BarcodeType type) {
    switch (type) {
      case BarcodeType.Code39:
        return Barcode.code39();
      case BarcodeType.Code93:
        return Barcode.code93();
      case BarcodeType.Code128:
        return Barcode.code128();
      case BarcodeType.GS128:
        return Barcode.gs128();
      case BarcodeType.Itf:
        return Barcode.itf();
      case BarcodeType.CodeITF14:
        return Barcode.itf14();
      case BarcodeType.CodeITF16:
        return Barcode.itf16();
      case BarcodeType.CodeEAN13:
        return Barcode.ean13();
      case BarcodeType.CodeEAN8:
        return Barcode.ean8();
      case BarcodeType.CodeEAN5:
        return Barcode.ean5();
      case BarcodeType.CodeEAN2:
        return Barcode.ean2();
      case BarcodeType.CodeISBN:
        return Barcode.isbn();
      case BarcodeType.CodeUPCA:
        return Barcode.upcA();
      case BarcodeType.CodeUPCE:
        return Barcode.upcE();
      case BarcodeType.Telepen:
        return Barcode.telepen();
      case BarcodeType.Codabar:
        return Barcode.codabar();
      case BarcodeType.Rm4scc:
        return Barcode.rm4scc();
      case BarcodeType.Postnet:
        return Barcode.postnet();
      case BarcodeType.QrCode:
        return Barcode.qrCode();
      case BarcodeType.PDF417:
        return Barcode.pdf417();
      case BarcodeType.DataMatrix:
        return Barcode.dataMatrix();
      case BarcodeType.Aztec:
        return Barcode.aztec();
      default:
        throw UnimplementedError("Barcode $type not supported");
    }
  }

  static Barcode code39({bool drawSpacers = true}) => BarcodeCode39(drawSpacers);

  static Barcode code93() => const BarcodeCode93();

  static Barcode code128({
    bool useCode128A = true,
    bool useCode128B = true,
    bool useCode128C = true,
    bool escapes = false,
  }) => BarcodeCode128(
    useCode128A: useCode128A,
    useCode128B: useCode128B,
    useCode128C: useCode128C,
    isGS1: false,
    escapes: escapes,
    addSpaceAfterParenthesis: false,
    keepParenthesis: false,
  );

  static Barcode gs128({
    bool useCode128A = true,
    bool useCode128B = true,
    bool useCode128C = true,
    bool escapes = false,
    bool addSpaceAfterParenthesis = true,
    bool keepParenthesis = false,
  }) => BarcodeCode128(
    useCode128A: useCode128A,
    useCode128B: useCode128B,
    useCode128C: useCode128C,
    isGS1: true,
    escapes: escapes,
    addSpaceAfterParenthesis: addSpaceAfterParenthesis,
    keepParenthesis: keepParenthesis,
  );

  static Barcode itf14({
    bool drawBorder = true,
    double? borderWidth,
    double? quietWidth,
  }) => BarcodeItf14(drawBorder, borderWidth, quietWidth);

  static Barcode itf16({
    bool drawBorder = true,
    double? borderWidth,
    double? quietWidth,
  }) => BarcodeItf16(drawBorder, borderWidth, quietWidth);

  static Barcode itf({
    bool addChecksum = false,
    bool zeroPrepend = false,
    bool drawBorder = false,
    double? borderWidth,
    double? quietWidth,
    int? fixedLength,
  }) => BarcodeItf(addChecksum, zeroPrepend, drawBorder, borderWidth, quietWidth, fixedLength);

  static Barcode ean13({bool drawEndChar = false}) => BarcodeEan13(drawEndChar);

  static Barcode ean8({bool drawSpacers = false}) => BarcodeEan8(drawSpacers);

  static Barcode ean5() => const BarcodeEan5();

  static Barcode ean2() => const BarcodeEan2();

  static Barcode isbn({bool drawEndChar = false, bool drawIsbn = true}) => BarcodeIsbn(drawEndChar, drawIsbn);

  static Barcode upcA() => const BarcodeUpcA();

  static Barcode upcE({bool fallback = false}) => BarcodeUpcE(fallback);

  static Barcode telepen() => const BarcodeTelepen();

  static Barcode qrCode({int? typeNumber, BarcodeQRCorrectionLevel errorCorrectLevel = BarcodeQRCorrectionLevel.low}) => BarcodeQR(typeNumber, errorCorrectLevel);

  static Barcode pdf417({
    Pdf417SecurityLevel securityLevel = Pdf417SecurityLevel.level2,
    double moduleHeight = 2.0,
    double preferredRatio = 3.0,
  }) => BarcodePDF417(securityLevel, moduleHeight, preferredRatio);

  static Barcode codabar({
    BarcodeCodabarStartStop start = BarcodeCodabarStartStop.A,
    BarcodeCodabarStartStop stop = BarcodeCodabarStartStop.B,
    bool printStartStop = false,
    bool explicitStartStop = false,
  }) => BarcodeCodabar(start, stop, printStartStop, explicitStartStop);

  static Barcode rm4scc() => const BarcodeRm4scc();

  static Barcode postnet() => const BarcodePostnet();

  static Barcode dataMatrix() => const BarcodeDataMatrix();

  static Barcode aztec({int minECCPercent = BarcodeAztec.defaultEcPercent, int userSpecifiedLayers = BarcodeAztec.defaultLayers}) => BarcodeAztec(minECCPercent, userSpecifiedLayers);

  Iterable<BarcodeElement> make(
    String data, {
    required double width,
    required double height,
    bool drawText = false,
    double? fontHeight,
    double? textPadding,
  }) => makeBytes(
    utf8.encoder.convert(data),
    width: width,
    height: height,
    drawText: drawText,
    fontHeight: fontHeight,
    textPadding: textPadding,
  );

  Iterable<BarcodeElement> makeBytes(
    Uint8List data, {
    required double width,
    required double height,
    bool drawText = false,
    double? fontHeight,
    double? textPadding,
  });

  bool isValid(String data) {
    try {
      verify(data);
    } catch (_) {
      return false;
    }

    return true;
  }

  bool isValidBytes(Uint8List data) {
    try {
      verifyBytes(data);
    } catch (_) {
      return false;
    }

    return true;
  }

  void verify(String data) => verifyBytes(utf8.encoder.convert(data));

  void verifyBytes(Uint8List data) {
    if (data.length > maxLength) {
      throw BarcodeException('Unable to encode "$data", maximum length is $maxLength for $name Barcode');
    }

    if (data.length < minLength) {
      throw BarcodeException('Unable to encode "$data", minimum length is $minLength for $name Barcode');
    }

    final chr = charSet.toSet();

    for (var code in data) {
      if (!chr.contains(code)) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }
    }
  }

  String toSvg(
    String data, {
    double x = 0,
    double y = 0,
    double width = 200,
    double height = 80,
    bool drawText = true,
    String fontFamily = "monospace",
    double? fontHeight,
    double? textPadding,
    int color = 0x000000,
    bool fullSvg = true,
    double baseline = .75,
  }) {
    fontHeight ??= height * 0.2;
    textPadding ??= height * 0.05;

    final recipe = make(
      data,
      width: width.toDouble(),
      height: height.toDouble(),
      drawText: drawText,
      fontHeight: fontHeight,
      textPadding: textPadding,
    );

    return _toSvg(recipe, x, y, width, height, fontFamily, fontHeight, textPadding, color, fullSvg, baseline);
  }

  String toSvgBytes(
    Uint8List data, {
    double x = 0,
    double y = 0,
    double width = 200,
    double height = 80,
    bool drawText = true,
    String fontFamily = "monospace",
    double? fontHeight,
    double? textPadding,
    int color = 0x000000,
    bool fullSvg = true,
    double baseline = .75,
  }) {
    fontHeight ??= height * 0.2;
    textPadding ??= height * 0.05;

    final recipe = makeBytes(
      data,
      width: width.toDouble(),
      height: height.toDouble(),
      drawText: drawText,
      fontHeight: fontHeight,
      textPadding: textPadding,
    );

    return _toSvg(recipe, x, y, width, height, fontFamily, fontHeight, textPadding, color, fullSvg, baseline);
  }

  String _d(double d) {
    assert(d != double.infinity);
    return d.toStringAsFixed(5);
  }

  String _s(String s) {
    const esc = HtmlEscape();
    return esc.convert(s);
  }

  String _c(int c) {
    return "#${(c & 0xffffff).toRadixString(16).padLeft(6, '0')}";
  }

  String _toSvg(
    Iterable<BarcodeElement> recipe,
    double x,
    double y,
    double width,
    double height,
    String fontFamily,
    double fontHeight,
    double textPadding,
    int color,
    bool fullSvg,
    double baseline,
  ) {
    final path = StringBuffer();
    final tSpan = StringBuffer();

    for (var elem in recipe) {
      if (elem is BarcodeBar) {
        if (elem.black) {
          path.write("M ${_d(x + elem.left)} ${_d(y + elem.top)} ");
          path.write("h ${_d(elem.width)} ");
          path.write("v ${_d(elem.height)} ");
          path.write("h ${_d(-elem.width)} ");
          path.write("z ");
        }
      } else if (elem is BarcodeText) {
        final lY = y + elem.top + elem.height * baseline;

        final double lX;
        String anchor;
        switch (elem.align) {
          case BarcodeTextAlign.left:
            lX = x + elem.left;
            anchor = "start";
            break;
          case BarcodeTextAlign.center:
            lX = x + elem.left + elem.width / 2;
            anchor = "middle";
            break;
          case BarcodeTextAlign.right:
            lX = x + elem.left + elem.width;
            anchor = "end";
            break;
        }

        tSpan.write('<tspan style="text-anchor: $anchor" x="${_d(lX)}" y="${_d(lY)}">${_s(elem.text)}</tspan>');
      }
    }

    final output = StringBuffer();
    if (fullSvg) {
      output.write('<svg viewBox="${_d(x)} ${_d(y)} ${_d(width)} ${_d(height)}" xmlns="http://www.w3.org/2000/svg">');
    }

    output.write('<path d="$path" style="fill: ${_c(color)}"/>');
    output.write('<text style="fill: ${_c(color)}; font-family: &quot;${_s(fontFamily)}&quot;; font-size: ${_d(fontHeight)}px" x="${_d(x)}" y="${_d(y)}">$tSpan</text>');

    if (fullSvg) {
      output.write("</svg>");
    }

    return output.toString();
  }

  Iterable<int> get charSet;

  String get name;

  static const int _infiniteMaxLength = 1000;

  int get maxLength => _infiniteMaxLength;

  int get minLength => 1;

  @override
  String toString() => "Barcode $name";
}

abstract class Barcode1D extends Barcode {
  const Barcode1D();

  static const defaultTextPadding = 0.0;

  @override
  Iterable<BarcodeElement> makeBytes(
    Uint8List data, {
    required double width,
    required double height,
    bool drawText = false,
    double? fontHeight,
    double? textPadding,
  }) sync* {
    assert(width > 0);
    assert(height > 0);
    assert(!drawText || fontHeight != null);
    fontHeight ??= 0;
    textPadding ??= defaultTextPadding;

    final text = utf8.decoder.convert(data);
    final bits = convert(text).toList();

    if (bits.isEmpty) {
      return;
    }

    final top = marginTop(drawText, width, height, fontHeight, textPadding);
    final left = marginLeft(drawText, width, height, fontHeight, textPadding);
    final right = marginRight(drawText, width, height, fontHeight, textPadding);
    final lineWidth = (width - left - right) / bits.length;

    var color = bits.first;
    var count = 1;

    for (var i = 1; i < bits.length; i++) {
      if (color == bits[i]) {
        count++;
        continue;
      }

      yield BarcodeBar(
        left: left + (i - count) * lineWidth,
        top: top,
        width: count * lineWidth,
        height: getHeight(
          i - count,
          count,
          width,
          height - top,
          fontHeight,
          textPadding,
          drawText,
        ),
        black: color,
      );

      color = bits[i];
      count = 1;
    }

    final l = bits.length;
    yield BarcodeBar(
      left: left + (l - count) * lineWidth,
      top: top,
      width: count * lineWidth,
      height: getHeight(
        l - count,
        count,
        width,
        height - top,
        fontHeight,
        textPadding,
        drawText,
      ),
      black: color,
    );

    if (drawText) {
      yield* makeText(text, width, height, fontHeight, textPadding, lineWidth);
    }
  }

  double getHeight(
    int index,
    int count,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    bool drawText,
  ) {
    return height - (drawText ? fontHeight + textPadding : 0);
  }

  double marginTop(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) => 0;

  double marginLeft(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) => 0;

  double marginRight(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) => 0;

  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) sync* {
    yield BarcodeText(
      left: 0,
      top: height - fontHeight,
      width: width,
      height: fontHeight,
      text: data,
      align: BarcodeTextAlign.center,
    );
  }

  Iterable<bool> add(int data, int count) sync* {
    for (var i = 0; i < count; i++) {
      yield (1 & (data >> i)) == 1;
    }
  }

  String toHex(String data) {
    var intermediate = "";
    for (var bit in convert(data)) {
      intermediate += bit ? "1" : "0";
    }

    var result = "";
    while (intermediate.length > 8) {
      final sub = intermediate.substring(intermediate.length - 8);
      result += int.parse(sub, radix: 2).toRadixString(16);
      intermediate = intermediate.substring(0, intermediate.length - 8);
    }
    result += int.parse(intermediate, radix: 2).toRadixString(16);

    return result;
  }

  String getText(String data) {
    final result = StringBuffer();

    for (final elem in makeText(data, 200, 200, 10, 5, 10)) {
      if (elem is BarcodeText) {
        result.write(elem.text);
      }
    }

    return result.toString();
  }

  Iterable<bool> convert(String data);
}

class Barcode2DMatrix {
  const Barcode2DMatrix(this.width, this.height, this.ratio, this.pixels);

  factory Barcode2DMatrix.fromXY(
    int width,
    int height,
    double ratio,
    bool Function(int x, int y) isDark,
  ) => Barcode2DMatrix(
    width,
    height,
    ratio,
    Iterable<bool>.generate(width * height, (p) {
      final x = p % height;
      final y = p ~/ height;
      return isDark(y, x);
    }),
  );

  final int width;

  final int height;

  final double ratio;

  final Iterable<bool> pixels;
}

abstract class Barcode2D extends Barcode {
  const Barcode2D();

  @override
  Iterable<BarcodeElement> makeBytes(
    Uint8List data, {
    required double width,
    required double height,
    bool drawText = false,
    double? fontHeight,
    double? textPadding,
  }) sync* {
    assert(width > 0);
    assert(height > 0);

    final matrix = convert(data);

    final mh = matrix.height * matrix.ratio;
    double w;
    double h;
    if (width / height > matrix.width / mh) {
      w = matrix.width * height / mh;
      h = height;
    } else {
      w = width;
      h = mh * width / matrix.width;
    }

    final pixelW = w / matrix.width;
    final pixelH = h / matrix.height;
    final offsetX = (width - w) / 2;
    final offsetY = (height - h) / 2;

    var start = 0;
    bool? color;
    var x = 0;
    var y = 0;

    for (final pixel in matrix.pixels) {
      color ??= pixel;

      if (pixel != color) {
        yield BarcodeBar(
          left: offsetX + start * pixelW,
          top: offsetY + y * pixelH,
          width: (x - start) * pixelW,
          height: pixelH,
          black: color,
        );

        color = pixel;
        start = x;
      }

      x++;
      if (x >= matrix.width) {
        yield BarcodeBar(
          left: offsetX + start * pixelW,
          top: offsetY + y * pixelH,
          width: (matrix.width - start) * pixelW,
          height: pixelH,
          black: color,
        );
        color = null;
        start = 0;
        x = 0;
        y++;
      }
    }
  }

  @override
  void verifyBytes(Uint8List data) {
    super.verifyBytes(data);

    try {
      convert(data);
    } on Exception catch (ex) {
      throw BarcodeException(ex.toString());
    }
  }

  String toHex(String data) {
    var intermediate = "";
    final matrix = convert(Uint8List.fromList(data.codeUnits));
    for (var bit in matrix.pixels) {
      intermediate += bit ? "1" : "0";
    }

    var result = "";
    while (intermediate.length > 8) {
      final sub = intermediate.substring(intermediate.length - 8);
      result += int.parse(sub, radix: 2).toRadixString(16);
      intermediate = intermediate.substring(0, intermediate.length - 8);
    }
    result += int.parse(intermediate, radix: 2).toRadixString(16);

    return result;
  }

  Barcode2DMatrix convert(Uint8List data);
}

class BarcodeException implements Exception {
  const BarcodeException(this.message);

  final String message;

  @override
  String toString() => "$runtimeType: $message";
}

enum BarcodeHMBar {
  tracker,
  ascender,
  descender,
  full,
}

abstract class BarcodeHM extends Barcode1D {
  const BarcodeHM({double tracker = 0.3}) : _tracker = tracker;

  final double _tracker;

  @override
  Iterable<BarcodeElement> makeBytes(
    Uint8List data, {
    required double width,
    required double height,
    bool drawText = false,
    double? fontHeight,
    double? textPadding,
  }) sync* {
    assert(width > 0);
    assert(height > 0);
    assert(!drawText || fontHeight != null);
    fontHeight ??= 0;
    textPadding ??= Barcode1D.defaultTextPadding;

    final text = utf8.decoder.convert(data);
    final bars = convertHM(text).toList();

    if (bars.isEmpty) {
      return;
    }

    final top = marginTop(
      drawText,
      width,
      height,
      fontHeight,
      textPadding,
    );
    final left = marginLeft(
      drawText,
      width,
      height,
      fontHeight,
      textPadding,
    );
    final right = marginRight(
      drawText,
      width,
      height,
      fontHeight,
      textPadding,
    );
    final lineWidth = (width - left - right) / (bars.length * 2 - 1);
    var index = 0;

    final barHeight = height - (drawText ? fontHeight + textPadding : 0) - top;
    final tracker = barHeight * _tracker;

    for (final bar in bars) {
      switch (bar) {
        case BarcodeHMBar.tracker:
          yield BarcodeBar(
            left: left + (index * 2) * lineWidth,
            top: top + barHeight / 2 - tracker / 2,
            width: lineWidth,
            height: tracker,
            black: true,
          );
          break;
        case BarcodeHMBar.ascender:
          yield BarcodeBar(
            left: left + (index * 2) * lineWidth,
            top: top,
            width: lineWidth,
            height: barHeight / 2 + tracker / 2,
            black: true,
          );
          break;
        case BarcodeHMBar.descender:
          yield BarcodeBar(
            left: left + (index * 2) * lineWidth,
            top: top + barHeight / 2 - tracker / 2,
            width: lineWidth,
            height: barHeight / 2 + tracker / 2,
            black: true,
          );
          break;
        case BarcodeHMBar.full:
          yield BarcodeBar(
            left: left + (index * 2) * lineWidth,
            top: top,
            width: lineWidth,
            height: barHeight,
            black: true,
          );
          break;
      }

      index++;
    }

    if (drawText) {
      yield* makeText(text, width, height, fontHeight, textPadding, lineWidth);
    }
  }

  @override
  String toHex(String data) {
    var result = "";
    var b = 0;
    var n = false;
    for (var bit in convertHM(data)) {
      b = (b << 2) + bit.index;
      if (n) {
        result += b.toRadixString(16);
        b = 0;
      }
      n = !n;
    }
    return result;
  }

  BarcodeHMBar fromBits(int bits) => BarcodeHMBar.values[bits];

  Iterable<BarcodeHMBar> addHW(int code, int len) sync* {
    for (var index = 0; index < len; index++) {
      yield fromBits((code >> index * 2) & 3);
    }
  }

  @override
  Iterable<bool> convert(String data) {
    throw UnimplementedError();
  }

  Iterable<BarcodeHMBar> convertHM(String data);
}

class BarcodeMaps {
  static const code39 = <int, int>{
    0x30: 0xb65,
    0x31: 0xd4b,
    0x32: 0xd4d,
    0x33: 0xa9b,
    0x34: 0xd65,
    0x35: 0xacb,
    0x36: 0xacd,
    0x37: 0xda5,
    0x38: 0xb4b,
    0x39: 0xb4d,
    0x41: 0xd2b,
    0x42: 0xd2d,
    0x43: 0xa5b,
    0x44: 0xd35,
    0x45: 0xa6b,
    0x46: 0xa6d,
    0x47: 0xd95,
    0x48: 0xb2b,
    0x49: 0xb2d,
    0x4a: 0xb35,
    0x4b: 0xcab,
    0x4c: 0xcad,
    0x4d: 0x95b,
    0x4e: 0xcb5,
    0x4f: 0x96b,
    0x50: 0x96d,
    0x51: 0xcd5,
    0x52: 0x9ab,
    0x53: 0x9ad,
    0x54: 0x9b5,
    0x55: 0xd53,
    0x56: 0xd59,
    0x57: 0xab3,
    0x58: 0xd69,
    0x59: 0xad3,
    0x5a: 0xad9,
    0x2d: 0xda9,
    0x2e: 0xb53,
    0x20: 0xb59,
    0x24: 0xa49,
    0x2f: 0x949,
    0x2b: 0x929,
    0x25: 0x925,
  };

  static const code39StartStop = 0xb69;
  static const int code39Len = 13;

  static const code93 = <int, int>{
    0x30: 0x51,
    0x31: 0x25,
    0x32: 0x45,
    0x33: 0x85,
    0x34: 0x29,
    0x35: 0x49,
    0x36: 0x89,
    0x37: 0x15,
    0x38: 0x91,
    0x39: 0xa1,
    0x41: 0x2b,
    0x42: 0x4b,
    0x43: 0x8b,
    0x44: 0x53,
    0x45: 0x93,
    0x46: 0xa3,
    0x47: 0x2d,
    0x48: 0x4d,
    0x49: 0x8d,
    0x4a: 0x59,
    0x4b: 0xb1,
    0x4c: 0x35,
    0x4d: 0x65,
    0x4e: 0xc5,
    0x4f: 0x69,
    0x50: 0xd1,
    0x51: 0x5b,
    0x52: 0x9b,
    0x53: 0x6b,
    0x54: 0xcb,
    0x55: 0xd3,
    0x56: 0xb3,
    0x57: 0x6d,
    0x58: 0xcd,
    0x59: 0xd9,
    0x5a: 0xb9,
    0x2d: 0xe9,
    0x2e: 0x57,
    0x20: 0x97,
    0x24: 0xa7,
    0x2f: 0xed,
    0x2b: 0xdd,
    0x25: 0xeb,
    -1: code93Dollar,
    -2: code93Percent,
    -3: code93Slash,
    -4: code93Plus,
    -5: code93StartStop,
    -6: code93ReverseStop,
  };

  static const code93Dollar = 0xc9;
  static const code93Percent = 0xb7;
  static const code93Slash = 0xd7;
  static const code93Plus = 0x99;
  static const code93StartStop = 0xf5;
  static const code93ReverseStop = 0xbd;
  static const code93Len = 9;

  static const code128A = <int, int>{
    0x20: 0x0,
    0x21: 0x1,
    0x22: 0x2,
    0x23: 0x3,
    0x24: 0x4,
    0x25: 0x5,
    0x26: 0x6,
    0x27: 0x7,
    0x28: 0x8,
    0x29: 0x9,
    0x2a: 0xa,
    0x2b: 0xb,
    0x2c: 0xc,
    0x2d: 0xd,
    0x2e: 0xe,
    0x2f: 0xf,
    0x30: 0x10,
    0x31: 0x11,
    0x32: 0x12,
    0x33: 0x13,
    0x34: 0x14,
    0x35: 0x15,
    0x36: 0x16,
    0x37: 0x17,
    0x38: 0x18,
    0x39: 0x19,
    0x3a: 0x1a,
    0x3b: 0x1b,
    0x3c: 0x1c,
    0x3d: 0x1d,
    0x3e: 0x1e,
    0x3f: 0x1f,
    0x40: 0x20,
    0x41: 0x21,
    0x42: 0x22,
    0x43: 0x23,
    0x44: 0x24,
    0x45: 0x25,
    0x46: 0x26,
    0x47: 0x27,
    0x48: 0x28,
    0x49: 0x29,
    0x4a: 0x2a,
    0x4b: 0x2b,
    0x4c: 0x2c,
    0x4d: 0x2d,
    0x4e: 0x2e,
    0x4f: 0x2f,
    0x50: 0x30,
    0x51: 0x31,
    0x52: 0x32,
    0x53: 0x33,
    0x54: 0x34,
    0x55: 0x35,
    0x56: 0x36,
    0x57: 0x37,
    0x58: 0x38,
    0x59: 0x39,
    0x5a: 0x3a,
    0x5b: 0x3b,
    0x5c: 0x3c,
    0x5d: 0x3d,
    0x5e: 0x3e,
    0x5f: 0x3f,
    0x0: 0x40,
    0x1: 0x41,
    0x2: 0x42,
    0x3: 0x43,
    0x4: 0x44,
    0x5: 0x45,
    0x6: 0x46,
    0x7: 0x47,
    0x8: 0x48,
    0x9: 0x49,
    0xa: 0x4a,
    0xb: 0x4b,
    0xc: 0x4c,
    0xd: 0x4d,
    0xe: 0x4e,
    0xf: 0x4f,
    0x10: 0x50,
    0x11: 0x51,
    0x12: 0x52,
    0x13: 0x53,
    0x14: 0x54,
    0x15: 0x55,
    0x16: 0x56,
    0x17: 0x57,
    0x18: 0x58,
    0x19: 0x59,
    0x1a: 0x5a,
    0x1b: 0x5b,
    0x1c: 0x5c,
    0x1d: 0x5d,
    0x1e: 0x5e,
    0x1f: 0x5f,
    code128FNC3: 0x60,
    code128FNC2: 0x61,
    code128ShiftB: 0x62,
    code128CodeC: 0x63,
    code128CodeB: 0x64,
    code128FNC4: 0x65,
    code128FNC1: 0x66,
  };

  static const code128B = <int, int>{
    0x20: 0x0,
    0x21: 0x1,
    0x22: 0x2,
    0x23: 0x3,
    0x24: 0x4,
    0x25: 0x5,
    0x26: 0x6,
    0x27: 0x7,
    0x28: 0x8,
    0x29: 0x9,
    0x2a: 0xa,
    0x2b: 0xb,
    0x2c: 0xc,
    0x2d: 0xd,
    0x2e: 0xe,
    0x2f: 0xf,
    0x30: 0x10,
    0x31: 0x11,
    0x32: 0x12,
    0x33: 0x13,
    0x34: 0x14,
    0x35: 0x15,
    0x36: 0x16,
    0x37: 0x17,
    0x38: 0x18,
    0x39: 0x19,
    0x3a: 0x1a,
    0x3b: 0x1b,
    0x3c: 0x1c,
    0x3d: 0x1d,
    0x3e: 0x1e,
    0x3f: 0x1f,
    0x40: 0x20,
    0x41: 0x21,
    0x42: 0x22,
    0x43: 0x23,
    0x44: 0x24,
    0x45: 0x25,
    0x46: 0x26,
    0x47: 0x27,
    0x48: 0x28,
    0x49: 0x29,
    0x4a: 0x2a,
    0x4b: 0x2b,
    0x4c: 0x2c,
    0x4d: 0x2d,
    0x4e: 0x2e,
    0x4f: 0x2f,
    0x50: 0x30,
    0x51: 0x31,
    0x52: 0x32,
    0x53: 0x33,
    0x54: 0x34,
    0x55: 0x35,
    0x56: 0x36,
    0x57: 0x37,
    0x58: 0x38,
    0x59: 0x39,
    0x5a: 0x3a,
    0x5b: 0x3b,
    0x5c: 0x3c,
    0x5d: 0x3d,
    0x5e: 0x3e,
    0x5f: 0x3f,
    0x60: 0x40,
    0x61: 0x41,
    0x62: 0x42,
    0x63: 0x43,
    0x64: 0x44,
    0x65: 0x45,
    0x66: 0x46,
    0x67: 0x47,
    0x68: 0x48,
    0x69: 0x49,
    0x6a: 0x4a,
    0x6b: 0x4b,
    0x6c: 0x4c,
    0x6d: 0x4d,
    0x6e: 0x4e,
    0x6f: 0x4f,
    0x70: 0x50,
    0x71: 0x51,
    0x72: 0x52,
    0x73: 0x53,
    0x74: 0x54,
    0x75: 0x55,
    0x76: 0x56,
    0x77: 0x57,
    0x78: 0x58,
    0x79: 0x59,
    0x7a: 0x5a,
    0x7b: 0x5b,
    0x7c: 0x5c,
    0x7d: 0x5d,
    0x7e: 0x5e,
    0x7f: 0x5f,
    code128FNC3: 0x60,
    code128FNC2: 0x61,
    code128ShiftA: 0x62,
    code128CodeC: 0x63,
    code128FNC4: 0x64,
    code128CodeA: 0x65,
    code128FNC1: 0x66,
  };

  static const code128C = <int, int>{
    0x0: 0x0,
    0x1: 0x1,
    0x2: 0x2,
    0x3: 0x3,
    0x4: 0x4,
    0x5: 0x5,
    0x6: 0x6,
    0x7: 0x7,
    0x8: 0x8,
    0x9: 0x9,
    0xa: 0xa,
    0xb: 0xb,
    0xc: 0xc,
    0xd: 0xd,
    0xe: 0xe,
    0xf: 0xf,
    0x10: 0x10,
    0x11: 0x11,
    0x12: 0x12,
    0x13: 0x13,
    0x14: 0x14,
    0x15: 0x15,
    0x16: 0x16,
    0x17: 0x17,
    0x18: 0x18,
    0x19: 0x19,
    0x1a: 0x1a,
    0x1b: 0x1b,
    0x1c: 0x1c,
    0x1d: 0x1d,
    0x1e: 0x1e,
    0x1f: 0x1f,
    0x20: 0x20,
    0x21: 0x21,
    0x22: 0x22,
    0x23: 0x23,
    0x24: 0x24,
    0x25: 0x25,
    0x26: 0x26,
    0x27: 0x27,
    0x28: 0x28,
    0x29: 0x29,
    0x2a: 0x2a,
    0x2b: 0x2b,
    0x2c: 0x2c,
    0x2d: 0x2d,
    0x2e: 0x2e,
    0x2f: 0x2f,
    0x30: 0x30,
    0x31: 0x31,
    0x32: 0x32,
    0x33: 0x33,
    0x34: 0x34,
    0x35: 0x35,
    0x36: 0x36,
    0x37: 0x37,
    0x38: 0x38,
    0x39: 0x39,
    0x3a: 0x3a,
    0x3b: 0x3b,
    0x3c: 0x3c,
    0x3d: 0x3d,
    0x3e: 0x3e,
    0x3f: 0x3f,
    0x40: 0x40,
    0x41: 0x41,
    0x42: 0x42,
    0x43: 0x43,
    0x44: 0x44,
    0x45: 0x45,
    0x46: 0x46,
    0x47: 0x47,
    0x48: 0x48,
    0x49: 0x49,
    0x4a: 0x4a,
    0x4b: 0x4b,
    0x4c: 0x4c,
    0x4d: 0x4d,
    0x4e: 0x4e,
    0x4f: 0x4f,
    0x50: 0x50,
    0x51: 0x51,
    0x52: 0x52,
    0x53: 0x53,
    0x54: 0x54,
    0x55: 0x55,
    0x56: 0x56,
    0x57: 0x57,
    0x58: 0x58,
    0x59: 0x59,
    0x5a: 0x5a,
    0x5b: 0x5b,
    0x5c: 0x5c,
    0x5d: 0x5d,
    0x5e: 0x5e,
    0x5f: 0x5f,
    0x60: 0x60,
    0x61: 0x61,
    0x62: 0x62,
    0x63: 0x63,
    code128CodeB: 0x64,
    code128CodeA: 0x65,
    code128FNC1: 0x66,
  };

  static const code128 = <int, int>{
    0x0: 0x19b,
    0x1: 0x1b3,
    0x2: 0x333,
    0x3: 0xc9,
    0x4: 0x189,
    0x5: 0x191,
    0x6: 0x99,
    0x7: 0x119,
    0x8: 0x131,
    0x9: 0x93,
    0xa: 0x113,
    0xb: 0x123,
    0xc: 0x1cd,
    0xd: 0x1d9,
    0xe: 0x399,
    0xf: 0x19d,
    0x10: 0x1b9,
    0x11: 0x339,
    0x12: 0x273,
    0x13: 0x1d3,
    0x14: 0x393,
    0x15: 0x13b,
    0x16: 0x173,
    0x17: 0x3b7,
    0x18: 0x197,
    0x19: 0x1a7,
    0x1a: 0x327,
    0x1b: 0x137,
    0x1c: 0x167,
    0x1d: 0x267,
    0x1e: 0xdb,
    0x1f: 0x31b,
    0x20: 0x363,
    0x21: 0xc5,
    0x22: 0xd1,
    0x23: 0x311,
    0x24: 0x8d,
    0x25: 0xb1,
    0x26: 0x231,
    0x27: 0x8b,
    0x28: 0xa3,
    0x29: 0x223,
    0x2a: 0xed,
    0x2b: 0x38d,
    0x2c: 0x3b1,
    0x2d: 0xdd,
    0x2e: 0x31d,
    0x2f: 0x371,
    0x30: 0x377,
    0x31: 0x38b,
    0x32: 0x3a3,
    0x33: 0xbb,
    0x34: 0x23b,
    0x35: 0x3bb,
    0x36: 0xd7,
    0x37: 0x317,
    0x38: 0x347,
    0x39: 0xb7,
    0x3a: 0x237,
    0x3b: 0x2c7,
    0x3c: 0x2f7,
    0x3d: 0x213,
    0x3e: 0x28f,
    0x3f: 0x65,
    0x40: 0x185,
    0x41: 0x69,
    0x42: 0x309,
    0x43: 0x1a1,
    0x44: 0x321,
    0x45: 0x4d,
    0x46: 0x10d,
    0x47: 0x59,
    0x48: 0x219,
    0x49: 0x161,
    0x4a: 0x261,
    0x4b: 0x243,
    0x4c: 0x53,
    0x4d: 0x2ef,
    0x4e: 0x143,
    0x4f: 0x2f1,
    0x50: 0x1e5,
    0x51: 0x1e9,
    0x52: 0x3c9,
    0x53: 0x13d,
    0x54: 0x179,
    0x55: 0x279,
    0x56: 0x12f,
    0x57: 0x14f,
    0x58: 0x24f,
    0x59: 0x3db,
    0x5a: 0x37b,
    0x5b: 0x36f,
    0x5c: 0xf5,
    0x5d: 0x3c5,
    0x5e: 0x3d1,
    0x5f: 0xbd,
    0x60: 0x23d,
    0x61: 0xaf,
    0x62: 0x22f,
    0x63: 0x3dd,
    0x64: 0x3bd,
    0x65: 0x3d7,
    0x66: 0x3af,
    code128StartCodeA: 0x10b,
    code128StartCodeB: 0x4b,
    code128StartCodeC: 0x1cb,
    code128Stop: 0x2e3,
    code128ReverseStop: 0xeb,
    code128StopPattern: 0x1ae3,
  };

  static const code128StartCodeA = 0x67;
  static const code128StartCodeB = 0x68;
  static const code128StartCodeC = 0x69;
  static const code128Stop = 0x6a;
  static const code128ReverseStop = 0x6b;
  static const code128StopPattern = 0x6c;
  static const code128FNC1 = 0xfa;
  static const code128FNC1String = "\u{fa}";
  static const code128FNC2 = 0xfb;
  static const code128FNC2String = "\u{fb}";
  static const code128FNC3 = 0xfc;
  static const code128FNC3String = "\u{fc}";
  static const code128FNC4 = 0xfd;
  static const code128FNC4String = "\u{fd}";
  static const code128ShiftA = -5;
  static const code128ShiftB = -6;
  static const code128CodeA = -7;
  static const code128CodeB = -8;
  static const code128CodeC = -9;
  static const code128Len = 11;

  static const ean = <int, List<int>>{
    0x30: <int>[0x58, 0x72, 0x27],
    0x31: <int>[0x4c, 0x66, 0x33],
    0x32: <int>[0x64, 0x6c, 0x1b],
    0x33: <int>[0x5e, 0x42, 0x21],
    0x34: <int>[0x62, 0x5c, 0x1d],
    0x35: <int>[0x46, 0x4e, 0x39],
    0x36: <int>[0x7a, 0x50, 0x5],
    0x37: <int>[0x6e, 0x44, 0x11],
    0x38: <int>[0x76, 0x48, 0x9],
    0x39: <int>[0x68, 0x74, 0x17],
  };

  static const eanFirst = <int, int>{
    0x30: 0x0,
    0x31: 0x34,
    0x32: 0x2c,
    0x33: 0x1c,
    0x34: 0x32,
    0x35: 0x26,
    0x36: 0xe,
    0x37: 0x2a,
    0x38: 0x1a,
    0x39: 0x16,
  };

  static const ean5Checksum = <int, int>{
    0x30: 0x3,
    0x31: 0x5,
    0x32: 0x9,
    0x33: 0x11,
    0x34: 0x6,
    0x35: 0xc,
    0x36: 0x18,
    0x37: 0xa,
    0x38: 0x12,
    0x39: 0x14,
  };

  static const upce = <int, int>{
    0x30: 0x38,
    0x31: 0x34,
    0x32: 0x2c,
    0x33: 0x1c,
    0x34: 0x32,
    0x35: 0x26,
    0x36: 0xe,
    0x37: 0x2a,
    0x38: 0x1a,
    0x39: 0x16,
  };

  static const eanStartEnd = 0x5;
  static const eanCenter = 0xa;
  static const eanEndUpcE = 0x2a;
  static const eanStartEan2 = 0x1a;
  static const eanCenterEan2 = 0x2;

  static const itf = <int, int>{
    0x30: 0xc,
    0x31: 0x11,
    0x32: 0x12,
    0x33: 0x3,
    0x34: 0x14,
    0x35: 0x5,
    0x36: 0x6,
    0x37: 0x18,
    0x38: 0x9,
    0x39: 0xa,
  };

  static const itfStart = 0x5;
  static const itfEnd = 0x17;

  static const telepen = <int>[
    0x7777,
    0x5ddd,
    0x5dc7,
    0x7775,
    0x5dd7,
    0x771d,
    0x7711,
    0x5dd5,
    0x5c77,
    0x775d,
    0x7747,
    0x5c75,
    0x7757,
    0x5c45,
    0x5c51,
    0x7755,
    0x5d77,
    0x71dd,
    0x71c7,
    0x5d75,
    0x71d7,
    0x5d1d,
    0x5d11,
    0x71d5,
    0x7117,
    0x5d5d,
    0x5d47,
    0x7115,
    0x5d57,
    0x7145,
    0x7151,
    0x5d55,
    0x4777,
    0x75dd,
    0x75c7,
    0x4775,
    0x75d7,
    0x471d,
    0x4711,
    0x75d5,
    0x7477,
    0x475d,
    0x4747,
    0x7475,
    0x4757,
    0x7445,
    0x7451,
    0x4755,
    0x7577,
    0x445d,
    0x4447,
    0x7575,
    0x4457,
    0x751d,
    0x7511,
    0x4455,
    0x4517,
    0x755d,
    0x7547,
    0x4515,
    0x7557,
    0x4545,
    0x4551,
    0x7555,
    0x5777,
    0x1ddd,
    0x1dc7,
    0x5775,
    0x1dd7,
    0x571d,
    0x5711,
    0x1dd5,
    0x1c77,
    0x575d,
    0x5747,
    0x1c75,
    0x5757,
    0x1c45,
    0x1c51,
    0x5755,
    0x1d77,
    0x51dd,
    0x51c7,
    0x1d75,
    0x51d7,
    0x1d1d,
    0x1d11,
    0x51d5,
    0x5117,
    0x1d5d,
    0x1d47,
    0x5115,
    0x1d57,
    0x5145,
    0x5151,
    0x1d55,
    0x1177,
    0x55dd,
    0x55c7,
    0x1175,
    0x55d7,
    0x111d,
    0x1111,
    0x55d5,
    0x5477,
    0x115d,
    0x1147,
    0x5475,
    0x1157,
    0x5445,
    0x5451,
    0x1155,
    0x5577,
    0x145d,
    0x1447,
    0x5575,
    0x1457,
    0x551d,
    0x5511,
    0x1455,
    0x1517,
    0x555d,
    0x5547,
    0x1515,
    0x5557,
    0x1545,
    0x1551,
    0x5555,
  ];

  static const telepenStart = 0x1d55;
  static const telepenEnd = 0x5547;
  static const telepenLen = 16;

  static const codabar = <int, int>{
    0x30: 0x195,
    0x31: 0x135,
    0x34: 0x12d,
    0x35: 0x12b,
    0x32: 0x1a5,
    0x2d: 0x165,
    0x24: 0x14d,
    0x39: 0x14b,
    0x36: 0x1a9,
    0x37: 0x169,
    0x38: 0x159,
    0x33: 0x153,
    0x2e: 0x2db,
    0x2f: 0x35b,
    0x3a: 0x36b,
    0x2b: 0x36d,
    0x43: 0x325,
    0x44: 0x265,
    0x41: 0x24d,
    0x42: 0x349,
  };

  static const codabarLen = <int, int>{
    0x30: 9,
    0x31: 9,
    0x34: 9,
    0x35: 9,
    0x32: 9,
    0x2d: 9,
    0x24: 9,
    0x39: 9,
    0x36: 9,
    0x37: 9,
    0x38: 9,
    0x33: 9,
    0x2e: 10,
    0x2f: 10,
    0x3a: 10,
    0x2b: 10,
    0x43: 10,
    0x44: 10,
    0x41: 10,
    0x42: 10,
  };

  static const rm4scc = <int, int>{
    0x30: 0xf0,
    0x31: 0xd8,
    0x32: 0x78,
    0x33: 0xd2,
    0x34: 0x72,
    0x35: 0x5a,
    0x36: 0xe4,
    0x37: 0xcc,
    0x38: 0x6c,
    0x39: 0xc6,
    0x41: 0x66,
    0x42: 0x4e,
    0x43: 0xb4,
    0x44: 0x9c,
    0x45: 0x3c,
    0x46: 0x96,
    0x47: 0x36,
    0x48: 0x1e,
    0x49: 0xe1,
    0x4a: 0xc9,
    0x4b: 0x69,
    0x4c: 0xc3,
    0x4d: 0x63,
    0x4e: 0x4b,
    0x4f: 0xb1,
    0x50: 0x99,
    0x51: 0x39,
    0x52: 0x93,
    0x53: 0x33,
    0x54: 0x1b,
    0x55: 0xa5,
    0x56: 0x8d,
    0x57: 0x2d,
    0x58: 0x87,
    0x59: 0x27,
    0x5a: 0xf,
  };

  static const rm4sccLen = 4;
  static const rm4sccStart = 0x1;
  static const rm4sccStop = 0x3;

  static const postnet = <int, int>{
    0x30: 0x2af,
    0x31: 0x3ea,
    0x32: 0x3ba,
    0x33: 0x2fa,
    0x34: 0x3ae,
    0x35: 0x2ee,
    0x36: 0x2be,
    0x37: 0x3ab,
    0x38: 0x2eb,
    0x39: 0xbb,
  };

  static const postnetLen = 5;
  static const postnetStartStop = 0x3;
}

class BarcodeElement {
  const BarcodeElement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;

  final double top;

  final double width;

  final double height;

  double get right => left + width;

  double get bottom => top + height;

  @override
  String toString() => "$runtimeType $left $top $width $height";
}

class BarcodeBar extends BarcodeElement {
  const BarcodeBar({
    required double left,
    required double top,
    required double width,
    required double height,
    required this.black,
  }) : super(
         left: left,
         top: top,
         width: width,
         height: height,
       );

  final bool black;

  @override
  String toString() => "$runtimeType [${black ? 'X' : ' '}] $left $top $width $height";
}

enum BarcodeTextAlign {
  left,
  center,
  right,
}

class BarcodeText extends BarcodeElement {
  const BarcodeText({
    required double left,
    required double top,
    required double width,
    required double height,
    required this.text,
    required this.align,
  }) : super(
         left: left,
         top: top,
         width: width,
         height: height,
       );

  final String text;

  final BarcodeTextAlign align;

  @override
  String toString() => '$runtimeType "$text" $left $top $width $height $align';
}

enum BarcodeType {
  CodeITF16,
  CodeITF14,
  CodeEAN13,
  CodeEAN8,
  CodeEAN5,
  CodeEAN2,
  CodeISBN,
  Code39,
  Code93,
  CodeUPCA,
  CodeUPCE,
  Code128,
  GS128,
  Telepen,
  QrCode,
  Codabar,
  PDF417,
  DataMatrix,
  Aztec,
  Rm4scc,
  Postnet,
  Itf,
}

final class QrBitBuffer {
  Uint8List _buffer = Uint8List(32);
  int _length = 0;

  int get length => _length;

  int getByte(int index) => _buffer[index];

  Uint8List getBytes(int offset, int length) => _buffer.sublist(offset, offset + length);

  void put(int number, int length) {
    if (length == 0) return;

    assert(length > 0, "length must be strictly positive");
    assert(number >= 0, "number must be non-negative");

    var bitIndex = _length;
    final endBitIndex = bitIndex + length;

    final neededBytes = (endBitIndex + 7) >> 3;
    _ensureCapacity(neededBytes);

    if (length == 8 && (bitIndex & 7) == 0 && number >= 0 && number <= 255) {
      _buffer[bitIndex >> 3] = number;
      _length = endBitIndex;
      return;
    }

    var bitsLeft = length;

    while (bitsLeft > 0) {
      final bufIndex = bitIndex >> 3;
      final leftBitIndex = bitIndex & 7;
      final available = 8 - leftBitIndex;
      final bitsToWrite = bitsLeft < available ? bitsLeft : available;

      final shift = bitsLeft - bitsToWrite;
      final bits = (number >> shift) & ((1 << bitsToWrite) - 1);

      final posShift = 8 - leftBitIndex - bitsToWrite;
      _buffer[bufIndex] |= bits << posShift;

      bitsLeft -= bitsToWrite;
      bitIndex += bitsToWrite;
    }

    _length = endBitIndex;
  }

  @override
  String toString() {
    final chars = Uint8List(_length);
    var charIndex = 0;

    final fullBytes = _length >> 3;
    for (var i = 0; i < fullBytes; i++) {
      final byte = _buffer[i];
      for (var j = 7; j >= 0; j--) {
        chars[charIndex++] = ((byte >> j) & 1) + 48;
      }
    }

    final remainingBits = _length & 7;
    if (remainingBits > 0) {
      final byte = _buffer[fullBytes];
      for (var i = 0; i < remainingBits; i++) {
        chars[charIndex++] = ((byte >> (7 - i)) & 1) + 48;
      }
    }

    return String.fromCharCodes(chars);
  }

  void _ensureCapacity(int neededBytes) {
    if (_buffer.length < neededBytes) {
      var newLength = _buffer.isEmpty ? 4 : _buffer.length * 2;
      while (newLength < neededBytes) {
        newLength *= 2;
      }
      final newBuffer = Uint8List(newLength)..setRange(0, _buffer.length, _buffer);
      _buffer = newBuffer;
    }
  }
}

abstract interface class QrDatum {
  QrMode get mode;

  int get length;

  int get bitLength;

  void write(QrBitBuffer buffer);

  static List<QrDatum> toDatums(String data) {
    if (QrNumeric.validationRegex.hasMatch(data)) {
      return [QrNumeric.fromString(data)];
    }
    if (QrAlphaNumeric.validationRegex.hasMatch(data)) {
      return [QrAlphaNumeric.fromString(data)];
    }

    final hasNonLatin1 = data.codeUnits.any((c) => c > 255);
    if (hasNonLatin1) {
      return [QrEci(26), QrByte(data)];
    }
    return [QrByte(data)];
  }
}

final class QrByte implements QrDatum {
  @override
  final QrMode mode = QrMode.byte;
  final Uint8List _data;

  factory QrByte(String input) => QrByte.fromUint8List(utf8.encoder.convert(input));

  QrByte.fromUint8List(Uint8List input) : _data = input;

  factory QrByte.fromByteData(TypedData input) => QrByte.fromUint8List(
    input.buffer.asUint8List(input.offsetInBytes, input.lengthInBytes),
  );

  @override
  int get length => _data.length;

  @override
  int get bitLength => _data.length * 8;

  @override
  void write(QrBitBuffer buffer) {
    for (final v in _data) {
      buffer.put(v, 8);
    }
  }
}

final class QrNumeric implements QrDatum {
  static final RegExp validationRegex = RegExp(r"^[0-9]+$");

  factory QrNumeric.fromString(String numberString) {
    if (!validationRegex.hasMatch(numberString)) {
      final value = numberString.length > 10 ? "${numberString.substring(0, 10)}..." : numberString;
      throw ArgumentError.value(
        value,
        "numberString",
        "string can only contain digits 0-9",
      );
    }
    final newList = Uint8List(numberString.length);
    var count = 0;
    for (var char in numberString.codeUnits) {
      newList[count++] = char - 0x30;
    }
    return QrNumeric._(newList);
  }

  QrNumeric._(this._data);

  final Uint8List _data;

  @override
  final QrMode mode = QrMode.numeric;

  @override
  void write(QrBitBuffer buffer) {
    final leftOver = _data.length % 3;

    final efficientGrab = _data.length - leftOver;
    for (var i = 0; i < efficientGrab; i += 3) {
      final encoded = _data[i] * 100 + _data[i + 1] * 10 + _data[i + 2];
      buffer.put(encoded, 10);
    }
    switch (leftOver) {
      case 2:
        buffer.put(_data[_data.length - 2] * 10 + _data[_data.length - 1], 7);
      case 1:
        buffer.put(_data.last, 4);
    }
  }

  @override
  int get length => _data.length;

  @override
  int get bitLength {
    final leftOver = _data.length % 3;
    var bits = (_data.length ~/ 3) * 10;
    if (leftOver == 1) {
      bits += 4;
    } else if (leftOver == 2) {
      bits += 7;
    }
    return bits;
  }
}

final class QrAlphaNumeric implements QrDatum {
  static const alphaNumTable = r"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";

  static final validationRegex = RegExp(
    r"^[-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+./:]+$",
  );
  static final encodeArray = () {
    final array = List<int?>.filled(91, null);
    for (var i = 0; i < alphaNumTable.length; i++) {
      final char = alphaNumTable.codeUnitAt(i);
      array[char] = i;
    }
    return array;
  }();

  final String _string;

  factory QrAlphaNumeric.fromString(String alphaNumeric) {
    if (!alphaNumeric.contains(validationRegex)) {
      final value = alphaNumeric.length > 10 ? "${alphaNumeric.substring(0, 10)}..." : alphaNumeric;
      throw ArgumentError.value(
        value,
        "alphaNumeric",
        "String does not contain valid ALPHA-NUM character set",
      );
    }
    return QrAlphaNumeric._(alphaNumeric);
  }

  QrAlphaNumeric._(this._string);

  @override
  final QrMode mode = QrMode.alphaNumeric;

  @override
  void write(QrBitBuffer buffer) {
    final leftOver = _string.length % 2;

    final efficientGrab = _string.length - leftOver;
    for (var i = 0; i < efficientGrab; i += 2) {
      final encoded = encodeArray[_string.codeUnitAt(i)]! * 45 + encodeArray[_string.codeUnitAt(i + 1)]!;
      buffer.put(encoded, 11);
    }
    if (leftOver > 0) {
      buffer.put(encodeArray[_string.codeUnitAt(_string.length - 1)]!, 6);
    }
  }

  @override
  int get length => _string.length;

  @override
  int get bitLength {
    final leftOver = _string.length % 2;
    var bits = (_string.length ~/ 2) * 11;
    if (leftOver == 1) {
      bits += 6;
    }
    return bits;
  }
}

enum BarcodeCodabarStartStop {
  A,
  B,
  C,
  D,
}

class BarcodeCodabar extends Barcode1D {
  const BarcodeCodabar(
    this.start,
    this.stop,
    this.printStartStop,
    this.explicitStartStop,
  );

  final BarcodeCodabarStartStop start;

  final BarcodeCodabarStartStop stop;

  final bool printStartStop;

  final bool explicitStartStop;

  @override
  Iterable<int> get charSet => BarcodeMaps.codabar.keys.where((int x) => x < 0x40);

  @override
  String get name => "CODABAR";

  @override
  Iterable<bool> convert(String data) sync* {
    final startStop = <int>[0x41, 0x42, 0x43, 0x44];

    var lStart = startStop[start.index];
    var lStop = startStop[stop.index];

    if (explicitStartStop) {
      lStart = _getStartStopByte(data.codeUnitAt(0));
      lStop = _getStartStopByte(data.codeUnitAt(data.length - 1));
      data = data.substring(1, data.length - 1);
    }

    yield* add(BarcodeMaps.codabar[lStart]!, BarcodeMaps.codabarLen[lStart]!);

    yield false;

    for (var code in data.codeUnits) {
      if (code > 0x40 || code == 0x2a) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      final codeValue = BarcodeMaps.codabar[code];
      if (codeValue == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }
      final codeLen = BarcodeMaps.codabarLen[code]!;
      yield* add(codeValue, codeLen);

      yield false;
    }

    yield* add(BarcodeMaps.codabar[lStop]!, BarcodeMaps.codabarLen[lStop]!);
  }

  int _getStartStopByte(int value) {
    switch (value) {
      case 0x54:
        return 0x41;
      case 0x4e:
        return 0x42;
      case 0x2a:
        return 0x43;
      case 0x45:
        return 0x44;
    }
    return value;
  }

  @override
  void verifyBytes(Uint8List data) {
    if (explicitStartStop) {
      const validStartStop = [0x41, 0x42, 0x43, 0x44, 0x4e, 0x54, 0x2a, 0x45];

      if (data.length < 3) {
        throw BarcodeException("Unable to encode $name Barcode: missing start and/or stop chars");
      }

      if (!validStartStop.contains(data[0])) {
        throw BarcodeException('Unable to encode $name Barcode: "${String.fromCharCode(data[0])}" is an invalid start char');
      }

      if (!validStartStop.contains(data[data.length - 1])) {
        throw BarcodeException('Unable to encode $name Barcode: "${String.fromCharCode(data[data.length - 1])}" is an invalid start char');
      }

      data = data.sublist(1, data.length - 1);
    }

    super.verifyBytes(data);
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) {
    if (printStartStop && !explicitStartStop) {
      data = String.fromCharCode(start.index + 0x41) + data + String.fromCharCode(stop.index + 0x41);
    } else if (!printStartStop && explicitStartStop) {
      data = data.substring(1, data.length - 1);
    }

    return super.makeText(
      data,
      width,
      height,
      fontHeight,
      textPadding,
      lineWidth,
    );
  }
}

class BarcodeCode128Fnc {
  static const fnc1 = BarcodeMaps.code128FNC1String;

  static const fnc2 = BarcodeMaps.code128FNC2String;

  static const fnc3 = BarcodeMaps.code128FNC3String;

  static const fnc4 = BarcodeMaps.code128FNC4String;
}

class BarcodeCode128 extends Barcode1D {
  const BarcodeCode128({
    required this.useCode128A,
    required this.useCode128B,
    required this.useCode128C,
    required this.isGS1,
    required this.escapes,
    required this.keepParenthesis,
    required this.addSpaceAfterParenthesis,
  }) : assert(useCode128A || useCode128B || useCode128C, "Enable at least one of the CODE 128 tables");

  final bool useCode128A;

  final bool useCode128B;

  final bool useCode128C;

  final bool escapes;

  final bool isGS1;

  final bool keepParenthesis;

  final bool addSpaceAfterParenthesis;

  @override
  Iterable<int> get charSet => BarcodeMaps.code128B.keys
      .where((int x) => useCode128B && x >= 0)
      .followedBy(BarcodeMaps.code128A.keys.where((int x) => useCode128A && x >= 0))
      .followedBy(useCode128C ? List<int>.generate(10, (int index) => index + 0x30) : [])
      .followedBy([
        BarcodeMaps.code128FNC1,
        if (useCode128A || useCode128B) BarcodeMaps.code128FNC2,
        if (useCode128A || useCode128B) BarcodeMaps.code128FNC3,
        if (useCode128A || useCode128B) BarcodeMaps.code128FNC4,
        if (isGS1) ...[40, 41],
      ])
      .toSet();

  @override
  String get name => isGS1 ? "GS1 128" : "CODE 128";

  Iterable<int> shortestCode(List<int> data) {
    var table = 0;

    var lastTable = 0;

    var length = 0;
    var digitCount = 0;

    final result = <int>[];

    void addFrom(List<int> data, int start) {
      Map<int, int>? t;
      if (table & 4 != 0 && digitCount & 1 == 0) {
        t = BarcodeMaps.code128C;
        if (lastTable == 1) {
          result.add(t[BarcodeMaps.code128CodeA]!);
        } else if (lastTable == 2) {
          result.add(t[BarcodeMaps.code128CodeB]!);
        }
        lastTable = 3;
      } else if (table & 1 != 0) {
        t = BarcodeMaps.code128A;
        if (lastTable == 2) {
          result.add(t[BarcodeMaps.code128CodeB]!);
        } else if (lastTable == 3) {
          result.add(t[BarcodeMaps.code128CodeC]!);
        }
        lastTable = 1;
      } else if (table & 2 != 0) {
        t = BarcodeMaps.code128B;
        if (lastTable == 1) {
          result.add(t[BarcodeMaps.code128CodeA]!);
        } else if (lastTable == 3) {
          result.add(t[BarcodeMaps.code128CodeC]!);
        }
        lastTable = 2;
      }

      if (t == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCodes(data)}" to $name Barcode');
      }

      if (lastTable == 3) {
        for (var i = start + length - 1; i >= start; i--) {
          if (data[i] == BarcodeMaps.code128FNC1) {
            result.add(t[BarcodeMaps.code128FNC1]!);
          } else {
            final digit = data[i] - 0x30 + (data[i - 1] - 0x30) * 10;
            assert(t[digit] != null);
            result.add(t[digit]!);
            i--;
          }
        }
      } else {
        for (final c in data.sublist(start, start + length).reversed) {
          assert(t[c] != null);
          result.add(t[c]!);
        }
      }
    }

    for (var index = data.length - 1; index >= 0; index--) {
      final code = data[index];

      final codeA = useCode128A && BarcodeMaps.code128A.containsKey(code);
      final codeB = useCode128B && BarcodeMaps.code128B.containsKey(code);
      final isFnc1 = code == BarcodeMaps.code128FNC1;
      final codeC = useCode128C && (code >= 0x30 && code <= 0x39);

      var available = 0;
      if (codeA) {
        available = 1;
      }
      if (codeB) {
        available |= 2;
      }
      if (codeC || isFnc1) {
        available |= 4;
      }

      if (available == 0) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      if (codeC) {
        digitCount++;
      } else if (isFnc1) {
        length++;
        addFrom(data, index);
        length = 0;
        digitCount = 0;
        continue;
      } else {
        if (digitCount >= 4) {
          if (digitCount & 1 != 0) {
            digitCount--;
          } else {}
          if (length > digitCount) {
            length -= digitCount;

            table &= 3;
            if (table == 0) {
              throw BarcodeException('Unable to encode "${String.fromCharCodes(data)}" to $name Barcode');
            }
            addFrom(data, index + digitCount + 1);
            length = digitCount;
          }

          table = 4;
          addFrom(data, index + 1);
          table = 0;
          length = 0;
        }
        digitCount = 0;
      }

      if (table == 0) {
        table = available;
        length++;
      } else {
        final newTable = table & available;
        if (newTable == 0) {
          addFrom(data, index + 1);
          length = 0;
          table = available;
        } else {
          table = newTable;
        }
        length++;
      }
    }

    if (digitCount >= 2) {
      if (digitCount & 1 != 0) {
        length -= digitCount - 1;
        addFrom(data, digitCount - 1);
        digitCount--;
      } else if (length > digitCount) {
        length -= digitCount;
        addFrom(data, digitCount);
      }
      table = 4;
      length = digitCount;
    }
    if (length > 0) {
      addFrom(data, 0);
    }

    if (lastTable == 1) {
      result.add(BarcodeMaps.code128StartCodeA);
    } else if (lastTable == 2) {
      result.add(BarcodeMaps.code128StartCodeB);
    } else if (lastTable == 3) {
      result.add(BarcodeMaps.code128StartCodeC);
    }

    return result.reversed;
  }

  String adaptData(String data, [bool text = false]) {
    if (isGS1) {
      final result = StringBuffer();
      var start = 0;
      for (final match in RegExp(r"\(.+?\)").allMatches(data)) {
        result.write(data.substring(start, match.start));
        result.write(BarcodeMaps.code128FNC1String);
        if (text && keepParenthesis) {
          result.write("(");
        }
        result.write(data.substring(match.start + 1, match.end - 1));
        if (text && keepParenthesis) {
          result.write(")");
        }
        if (text && addSpaceAfterParenthesis) {
          result.write(" ");
        }
        start = match.end;
      }
      result.write(data.substring(start));
      data = result.toString();
    }

    if (escapes) {
      final result = StringBuffer();
      var start = 0;
      for (final match in RegExp(r"{\d}").allMatches(data)) {
        result.write(data.substring(start, match.start));
        switch (match.group(0)) {
          case "{1}":
            result.write(BarcodeMaps.code128FNC1String);
            break;
          case "{2}":
            result.write(BarcodeMaps.code128FNC2String);
            break;
          case "{3}":
            result.write(BarcodeMaps.code128FNC3String);
            break;
          case "{4}":
            result.write(BarcodeMaps.code128FNC4String);
            break;
          default:
            result.write(match.group(0));
        }

        start = match.end;
      }
      result.write(data.substring(start));
      data = result.toString();
    }

    return data;
  }

  @override
  Iterable<bool> convert(String data) sync* {
    data = adaptData(data);

    final checksum = <int>[];

    for (var codeIndex in shortestCode(data.codeUnits)) {
      final codeValue = BarcodeMaps.code128[codeIndex]!;
      yield* add(codeValue, BarcodeMaps.code128Len);
      checksum.add(codeIndex);
    }

    var sum = 0;
    for (var index = 0; index < checksum.length; index++) {
      final code = checksum[index];
      final mul = index == 0 ? 1 : index;
      sum += code * mul;
    }
    sum = sum % 103;
    yield* add(BarcodeMaps.code128[sum]!, BarcodeMaps.code128Len);

    yield* add(BarcodeMaps.code128[BarcodeMaps.code128Stop]!, BarcodeMaps.code128Len);

    yield true;
    yield true;
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) {
    data = adaptData(data, true).replaceAll(RegExp("[^ -\u{7f}]"), " ").trim();

    return super.makeText(
      data,
      width,
      height,
      fontHeight,
      textPadding,
      lineWidth,
    );
  }

  @override
  void verifyBytes(Uint8List data) {
    final text = Uint8List.fromList(
      adaptData(utf8.decoder.convert(data)).codeUnits,
    );
    shortestCode(text);
    super.verifyBytes(text);
  }
}

class BarcodeCode39 extends Barcode1D {
  const BarcodeCode39(this.drawSpacers);

  final bool drawSpacers;

  @override
  Iterable<int> get charSet => BarcodeMaps.code39.keys;

  @override
  String get name => "CODE 39";

  @override
  Iterable<bool> convert(String data) sync* {
    yield* add(BarcodeMaps.code39StartStop, BarcodeMaps.code39Len);

    for (var code in data.codeUnits) {
      final codeValue = BarcodeMaps.code39[code];
      if (codeValue == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }
      yield* add(codeValue, BarcodeMaps.code39Len);
    }

    yield* add(BarcodeMaps.code39StartStop, BarcodeMaps.code39Len);
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) sync* {
    final text = drawSpacers ? "*$data*" : data;

    final additionalOffset = drawSpacers ? 0 : 1;
    for (var i = 0; i < text.length; i++) {
      yield BarcodeText(
        left: lineWidth * BarcodeMaps.code39Len * (i + additionalOffset),
        top: height - fontHeight,
        width: lineWidth * BarcodeMaps.code39Len,
        height: fontHeight,
        text: text[i],
        align: BarcodeTextAlign.center,
      );
    }
  }
}

class BarcodeCode93 extends Barcode1D {
  const BarcodeCode93();

  @override
  Iterable<int> get charSet => BarcodeMaps.code93.keys.where((int x) => x > 0);

  @override
  String get name => "CODE 93";

  @override
  Iterable<bool> convert(String data) sync* {
    yield* add(BarcodeMaps.code93StartStop, BarcodeMaps.code93Len);

    final keys = BarcodeMaps.code93.keys.toList();

    for (var code in data.codeUnits) {
      final codeValue = BarcodeMaps.code93[code];
      if (codeValue == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }
      yield* add(codeValue, BarcodeMaps.code93Len);
    }

    var sumC = 0;
    var sumK = 0;
    var indexC = 1;
    var indexK = 2;

    for (var index = data.codeUnits.length - 1; index >= 0; index--) {
      final code = data.codeUnits[index];
      sumC += keys.indexOf(code) * indexC;
      sumK += keys.indexOf(code) * indexK;

      indexC++;
      if (indexC > 20) {
        indexC = 1;
      }
      indexK++;
      if (indexK > 15) {
        indexK = 1;
      }
    }

    sumC = sumC % 47;
    yield* add(BarcodeMaps.code93[keys[sumC]]!, BarcodeMaps.code93Len);

    sumK = (sumK + sumC) % 47;
    yield* add(BarcodeMaps.code93[keys[sumK]]!, BarcodeMaps.code93Len);

    yield* add(BarcodeMaps.code93StartStop, BarcodeMaps.code93Len);

    yield true;
  }
}

class BarcodeDataMatrix extends Barcode2D {
  const BarcodeDataMatrix();

  @override
  Iterable<BarcodeElement> make(
    String data, {
    required double width,
    required double height,
    bool drawText = false,
    double? fontHeight,
    double? textPadding,
  }) {
    final encoder = DataMatrixEncoder()..ascii(data);
    return makeBytes(
      encoder.toBytes(),
      width: width,
      height: height,
      drawText: drawText,
      fontHeight: fontHeight,
      textPadding: textPadding,
    );
  }

  @override
  Barcode2DMatrix convert(Uint8List data) {
    var text = <int>[...data];

    _CodeSize? size;
    for (final s in _CodeSize.codeSizes) {
      if (s.dataCodewords() >= text.length) {
        size = s;
        break;
      }
    }

    if (size == null) {
      throw const BarcodeException("Too much data to encode");
    }
    text = _addPadding(text, size.dataCodewords());
    text = _ErrorCorrection.ec.calcECC(text, size);
    final code = _render(text, size);

    return Barcode2DMatrix(
      size.columns,
      size.rows,
      1,
      code,
    );
  }

  @override
  Iterable<int> get charSet => Iterable<int>.generate(256);

  @override
  String get name => "Data Matrix";

  @override
  int get maxLength => 1559;

  List<bool> _render(List<int> data, _CodeSize size) {
    final cl = _CodeLayout(size);
    cl.setValues(data);
    return cl.merge();
  }

  List<int> _addPadding(List<int> data, int toCount) {
    if (data.length < toCount) {
      data.add(0x81);
    }

    while (data.length < toCount) {
      final r = ((149 * (data.length + 1)) % 253) + 1;
      data.add((0x81 + r) % 254);
    }

    return data;
  }
}

class _CodeLayout {
  _CodeLayout(this.size) {
    matrix = List<bool>.filled(size.matrixColumns() * size.matrixRows(), false);
    occupy = List<bool>.filled(size.matrixColumns() * size.matrixRows(), false);
  }

  late List<bool> matrix;
  late List<bool> occupy;
  final _CodeSize size;

  bool occupied(int row, int col) {
    return occupy[col + row * size.matrixColumns()];
  }

  void setXY(int row, int col, int value, int bitNum) {
    final val = ((value >> (7 - bitNum)) & 1) == 1;

    if (row < 0) {
      row += size.matrixRows();
      col += 4 - ((size.matrixRows() + 4) % 8);
    }

    if (col < 0) {
      col += size.matrixColumns();
      row += 4 - ((size.matrixColumns() + 4) % 8);
    }

    assert(!occupied(row, col), "Field already occupied row: $row col: $col");

    occupy[col + row * size.matrixColumns()] = true;

    matrix[col + row * size.matrixColumns()] = val;
  }

  void setSimple(int row, int col, int value) {
    setXY(row - 2, col - 2, value, 0);
    setXY(row - 2, col - 1, value, 1);
    setXY(row - 1, col - 2, value, 2);
    setXY(row - 1, col - 1, value, 3);
    setXY(row - 1, col - 0, value, 4);
    setXY(row - 0, col - 2, value, 5);
    setXY(row - 0, col - 1, value, 6);
    setXY(row - 0, col - 0, value, 7);
  }

  void corner1(int value) {
    setXY(size.matrixRows() - 1, 0, value, 0);
    setXY(size.matrixRows() - 1, 1, value, 1);
    setXY(size.matrixRows() - 1, 2, value, 2);
    setXY(0, size.matrixColumns() - 2, value, 3);
    setXY(0, size.matrixColumns() - 1, value, 4);
    setXY(1, size.matrixColumns() - 1, value, 5);
    setXY(2, size.matrixColumns() - 1, value, 6);
    setXY(3, size.matrixColumns() - 1, value, 7);
  }

  void corner2(int value) {
    setXY(size.matrixRows() - 3, 0, value, 0);
    setXY(size.matrixRows() - 2, 0, value, 1);
    setXY(size.matrixRows() - 1, 0, value, 2);
    setXY(0, size.matrixColumns() - 4, value, 3);
    setXY(0, size.matrixColumns() - 3, value, 4);
    setXY(0, size.matrixColumns() - 2, value, 5);
    setXY(0, size.matrixColumns() - 1, value, 6);
    setXY(1, size.matrixColumns() - 1, value, 7);
  }

  void corner3(int value) {
    setXY(size.matrixRows() - 3, 0, value, 0);
    setXY(size.matrixRows() - 2, 0, value, 1);
    setXY(size.matrixRows() - 1, 0, value, 2);
    setXY(0, size.matrixColumns() - 2, value, 3);
    setXY(0, size.matrixColumns() - 1, value, 4);
    setXY(1, size.matrixColumns() - 1, value, 5);
    setXY(2, size.matrixColumns() - 1, value, 6);
    setXY(3, size.matrixColumns() - 1, value, 7);
  }

  void corner4(int value) {
    setXY(size.matrixRows() - 1, 0, value, 0);
    setXY(size.matrixRows() - 1, size.matrixColumns() - 1, value, 1);
    setXY(0, size.matrixColumns() - 3, value, 2);
    setXY(0, size.matrixColumns() - 2, value, 3);
    setXY(0, size.matrixColumns() - 1, value, 4);
    setXY(1, size.matrixColumns() - 3, value, 5);
    setXY(1, size.matrixColumns() - 2, value, 6);
    setXY(1, size.matrixColumns() - 1, value, 7);
  }

  void setValues(List<int> data) {
    var idx = 0;
    var row = 4;
    var col = 0;

    while ((row < size.matrixRows()) || (col < size.matrixColumns())) {
      if ((row == size.matrixRows()) && (col == 0)) {
        corner1(data[idx]);
        idx++;
      }
      if ((row == size.matrixRows() - 2) && (col == 0) && (size.matrixColumns() % 4 != 0)) {
        corner2(data[idx]);
        idx++;
      }
      if ((row == size.matrixRows() - 2) && (col == 0) && (size.matrixColumns() % 8 == 4)) {
        corner3(data[idx]);
        idx++;
      }

      if ((row == size.matrixRows() + 4) && (col == 2) && (size.matrixColumns() % 8 == 0)) {
        corner4(data[idx]);
        idx++;
      }

      while (true) {
        if ((row < size.matrixRows()) && (col >= 0) && !occupied(row, col)) {
          setSimple(row, col, data[idx]);
          idx++;
        }
        row -= 2;
        col += 2;
        if ((row < 0) || (col >= size.matrixColumns())) {
          break;
        }
      }
      row += 1;
      col += 3;

      while (true) {
        if ((row >= 0) && (col < size.matrixColumns()) && !occupied(row, col)) {
          setSimple(row, col, data[idx]);
          idx++;
        }
        row += 2;
        col -= 2;
        if ((row >= size.matrixRows()) || (col < 0)) {
          break;
        }
      }
      row += 3;
      col += 1;
    }

    if (!occupied(size.matrixRows() - 1, size.matrixColumns() - 1)) {
      setXY(size.matrixRows() - 1, size.matrixColumns() - 1, 255, 0);
      setXY(size.matrixRows() - 2, size.matrixColumns() - 2, 255, 0);
    }
  }

  List<bool> merge() {
    final result = List<bool>.filled(size.rows * size.columns, false);

    void setXY(int x, int y, bool v) {
      result[x + y * size.columns] = v;
    }

    for (var r = 0; r < size.rows; r += size.regionRows() + 2) {
      for (var c = 0; c < size.columns; c += 2) {
        setXY(c, r, true);
      }
    }

    for (var r = size.regionRows() + 1; r < size.rows; r += size.regionRows() + 2) {
      for (var c = 0; c < size.columns; c++) {
        setXY(c, r, true);
      }
    }

    for (var c = size.regionColumns() + 1; c < size.columns; c += size.regionColumns() + 2) {
      for (var r = 1; r < size.rows; r += 2) {
        setXY(c, r, true);
      }
    }

    for (var c = 0; c < size.columns; c += size.regionColumns() + 2) {
      for (var r = 0; r < size.rows; r++) {
        setXY(c, r, true);
      }
    }

    for (var hRegion = 0; hRegion < size.regionCountHorizontal; hRegion++) {
      for (var vRegion = 0; vRegion < size.regionCountVertical; vRegion++) {
        for (var x = 0; x < size.regionColumns(); x++) {
          final colMatrix = (size.regionColumns() * hRegion) + x;
          final colResult = ((2 + size.regionColumns()) * hRegion) + x + 1;

          for (var y = 0; y < size.regionRows(); y++) {
            final rowMatrix = (size.regionRows() * vRegion) + y;
            final rowResult = ((2 + size.regionRows()) * vRegion) + y + 1;
            final val = matrix[colMatrix + rowMatrix * size.matrixColumns()];

            setXY(colResult, rowResult, val);
          }
        }
      }
    }

    return result;
  }
}

class _CodeSize {
  const _CodeSize(this.rows, this.columns, this.regionCountHorizontal, this.regionCountVertical, this.eccCount, this.blockCount);

  final int rows;
  final int columns;
  final int regionCountHorizontal;
  final int regionCountVertical;
  final int eccCount;
  final int blockCount;

  int regionRows() {
    return (rows - (regionCountHorizontal * 2)) ~/ regionCountHorizontal;
  }

  int regionColumns() {
    return (columns - (regionCountVertical * 2)) ~/ regionCountVertical;
  }

  int matrixRows() {
    return regionRows() * regionCountHorizontal;
  }

  int matrixColumns() {
    return regionColumns() * regionCountVertical;
  }

  int dataCodewords() {
    return ((matrixColumns() * matrixRows()) ~/ 8) - eccCount;
  }

  int dataCodewordsForBlock(int idx) {
    if (rows == 144 && columns == 144) {
      if (idx < 8) {
        return 156;
      } else {
        return 155;
      }
    }
    return dataCodewords() ~/ blockCount;
  }

  int errorCorrectionCodewordsPerBlock() {
    return eccCount ~/ blockCount;
  }

  static const codeSizes = <_CodeSize>[
    _CodeSize(10, 10, 1, 1, 5, 1),
    _CodeSize(12, 12, 1, 1, 7, 1),
    _CodeSize(14, 14, 1, 1, 10, 1),
    _CodeSize(16, 16, 1, 1, 12, 1),
    _CodeSize(18, 18, 1, 1, 14, 1),
    _CodeSize(20, 20, 1, 1, 18, 1),
    _CodeSize(22, 22, 1, 1, 20, 1),
    _CodeSize(24, 24, 1, 1, 24, 1),
    _CodeSize(26, 26, 1, 1, 28, 1),
    _CodeSize(32, 32, 2, 2, 36, 1),
    _CodeSize(36, 36, 2, 2, 42, 1),
    _CodeSize(40, 40, 2, 2, 48, 1),
    _CodeSize(44, 44, 2, 2, 56, 1),
    _CodeSize(48, 48, 2, 2, 68, 1),
    _CodeSize(52, 52, 2, 2, 84, 2),
    _CodeSize(64, 64, 4, 4, 112, 2),
    _CodeSize(72, 72, 4, 4, 144, 4),
    _CodeSize(80, 80, 4, 4, 192, 4),
    _CodeSize(88, 88, 4, 4, 224, 4),
    _CodeSize(96, 96, 4, 4, 272, 4),
    _CodeSize(104, 104, 4, 4, 336, 6),
    _CodeSize(120, 120, 6, 6, 408, 6),
    _CodeSize(132, 132, 6, 6, 496, 8),
    _CodeSize(144, 144, 6, 6, 620, 10),
  ];
}

class _ErrorCorrection {
  _ErrorCorrection() {
    final gf = GaloisField(301, 256, 1);
    rs = ReedSolomonEncoder(gf);
  }

  late ReedSolomonEncoder rs;

  static final ec = _ErrorCorrection();

  List<int> calcECC(List<int> data, _CodeSize size) {
    final dataSize = data.length;

    data.addAll(List<int>.filled(size.eccCount, 0));

    for (var block = 0; block < size.blockCount; block++) {
      final dataCnt = size.dataCodewordsForBlock(block);

      final buff = List<int>.filled(dataCnt, 0);

      var j = 0;
      for (var i = block; i < dataSize; i += size.blockCount) {
        buff[j] = data[i];
        j++;
      }

      final ecc = ec.rs.encode(buff, size.errorCorrectionCodewordsPerBlock());

      j = 0;
      for (var i = block; i < size.errorCorrectionCodewordsPerBlock() * size.blockCount; i += size.blockCount) {
        data[dataSize + i] = ecc[j];
        j++;
      }
    }

    return data;
  }
}

class DataMatrixEncoder {
  final _data = BytesBuilder();

  void ascii(String data) {
    final input = data.codeUnits;

    for (var i = 0; i < input.length;) {
      final c = input[i];
      i++;

      if (c >= 0x30 && c <= 0x39 && i < input.length && input[i] >= 0x30 && input[i] <= 0x39) {
        final c2 = input[i];
        i++;
        final cw = ((c - 0x30) * 10 + (c2 - 0x30)) + 0x82;
        _data.addByte(cw);
      } else if (c > 0x7f) {
        _data.addByte(0xeb);
        _data.addByte(c - 0x7f);
      } else {
        _data.addByte(c + 1);
      }
    }
  }

  void fnc1() {
    _data.addByte(0xe8);
  }

  void append() {
    _data.addByte(0xe9);
  }

  void program() {
    _data.addByte(0xea);
  }

  void macro05() {
    _data.addByte(0xec);
  }

  void macro06() {
    _data.addByte(0xed);
  }

  void eci() {
    _data.addByte(0xf1);
  }

  void gs() {
    _data.addByte(0x1d);
  }

  Uint8List toBytes() => _data.toBytes();
}

abstract class BarcodeEan extends Barcode1D {
  const BarcodeEan();

  @override
  Iterable<int> get charSet => List<int>.generate(10, (int index) => index + 0x30);

  String checkLength(String data, int length) {
    if (data.length == length - 1) {
      data += checkSumModulo10(data);
    } else {
      if (data.length != length) {
        throw BarcodeException('Unable to encode "$data" to $name Barcode, it is not $length digits');
      }

      final last = data.substring(length - 1);
      final checksum = checkSumModulo10(data.substring(0, length - 1));

      if (last != checksum) {
        throw BarcodeException('Unable to encode "$data" to $name Barcode, checksum "$last" should be "$checksum"');
      }
    }

    return data;
  }

  String checkSumModulo10(String data) {
    var sum = 0;
    var fak = data.length;
    for (var c in data.codeUnits) {
      if (fak % 2 == 0) {
        sum += c - 0x30;
      } else {
        sum += (c - 0x30) * 3;
      }
      fak--;
    }
    if (sum % 10 == 0) {
      return "0";
    } else {
      return String.fromCharCode(10 - (sum % 10) + 0x30);
    }
  }

  String checkSumModulo11(String data) {
    var sum = 0;
    var pos = 10;
    for (var c in data.codeUnits) {
      sum += (c - 0x30) * pos;
      pos--;
    }
    return String.fromCharCode(11 - (sum % 11) + 0x30);
  }

  String normalize(String data) => checkLength(data.padRight(minLength, "0").substring(0, minLength), maxLength);
}

class BarcodeEan13 extends BarcodeEan {
  const BarcodeEan13(this.drawEndChar);

  final bool drawEndChar;

  static const String _finalSpacer = ">";

  @override
  String get name => "EAN 13";

  @override
  int get minLength => 12;

  @override
  int get maxLength => 13;

  @override
  void verifyBytes(Uint8List data) {
    final text = utf8.decoder.convert(data);
    checkLength(text, maxLength);
    super.verifyBytes(data);
  }

  @override
  Iterable<bool> convert(String data) sync* {
    data = checkLength(data, maxLength);

    yield* add(BarcodeMaps.eanStartEnd, 3);

    var index = 0;
    final first = BarcodeMaps.eanFirst[data.codeUnits.first];
    if (first == null) {
      throw BarcodeException('Unable to encode "${String.fromCharCode(data.codeUnits.first)}" to $name Barcode');
    }

    for (var code in data.codeUnits.sublist(1)) {
      final codes = BarcodeMaps.ean[code];

      if (codes == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      if (index == 6) {
        yield* add(BarcodeMaps.eanCenter, 5);
      }

      if (index < 6) {
        yield* add(codes[(first >> index) & 1], 7);
      } else {
        yield* add(codes[2], 7);
      }

      index++;
    }

    yield* add(BarcodeMaps.eanStartEnd, 3);
  }

  @override
  double marginLeft(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double marginRight(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText || !drawEndChar) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double getHeight(
    int index,
    int count,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    bool drawText,
  ) {
    if (!drawText) {
      return super.getHeight(
        index,
        count,
        width,
        height,
        fontHeight,
        textPadding,
        drawText,
      );
    }

    final h = height - fontHeight - textPadding;

    if (index < 3 || (index > 45 && index < 49) || index > 91) {
      return h + fontHeight / 2 + textPadding;
    }

    return h;
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) sync* {
    final text = checkLength(data, maxLength);
    final w = lineWidth * 7;
    final left = marginLeft(true, width, height, fontHeight, textPadding);
    final right = marginRight(true, width, height, fontHeight, textPadding);

    yield BarcodeText(
      left: 0,
      top: height - fontHeight,
      width: left - lineWidth,
      height: fontHeight,
      text: text[0],
      align: BarcodeTextAlign.right,
    );

    var offset = left + lineWidth * 3;

    for (var i = 1; i < text.length; i++) {
      yield BarcodeText(
        left: offset,
        top: height - fontHeight,
        width: w,
        height: fontHeight,
        text: text[i],
        align: BarcodeTextAlign.center,
      );

      offset += w;
      if (i == 6) {
        offset += lineWidth * 5;
      }
    }

    if (drawEndChar) {
      yield BarcodeText(
        left: width - right + lineWidth,
        top: height - fontHeight,
        width: right - lineWidth,
        height: fontHeight,
        text: _finalSpacer,
        align: BarcodeTextAlign.left,
      );
    }
  }
}

class BarcodeEan2 extends BarcodeEan {
  const BarcodeEan2();

  @override
  String get name => "EAN 2";

  @override
  int get minLength => 2;

  @override
  int get maxLength => 2;

  @override
  Iterable<bool> convert(String data) sync* {
    verify(data);
    int idata;
    try {
      idata = int.parse(data);
    } catch (e) {
      throw BarcodeException('Unable to encode "$data" to $name Barcode');
    }
    final pattern = idata % 4;

    yield* add(BarcodeMaps.eanStartEan2, 5);

    var index = 0;
    for (var code in data.codeUnits) {
      final codes = BarcodeMaps.ean[code];

      if (codes == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      if (index == 1) {
        yield* add(BarcodeMaps.eanCenterEan2, 2);
      }

      if (index == 0) {
        yield* add(codes[pattern < 2 ? 0 : 1], 7);
      } else {
        yield* add(codes[pattern % 2 == 0 ? 0 : 1], 7);
      }
      index++;
    }
  }

  @override
  double marginTop(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) => drawText ? fontHeight + textPadding : 0;

  @override
  double getHeight(
    int index,
    int count,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    bool drawText,
  ) => height;

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) sync* {
    yield BarcodeText(
      left: 0,
      top: 0,
      width: width,
      height: fontHeight,
      text: data,
      align: BarcodeTextAlign.center,
    );
  }

  @override
  String normalize(String data) => data.padRight(minLength, "0").substring(0, minLength);
}

class BarcodeEan5 extends BarcodeEan2 {
  const BarcodeEan5();

  @override
  String get name => "EAN 5";

  @override
  int get minLength => 5;

  @override
  int get maxLength => 5;

  @override
  String checkSumModulo10(String data) {
    var sum = 0;
    var fak = data.length;
    for (var c in data.codeUnits) {
      if (fak % 2 == 0) {
        sum += (c - 0x30) * 9;
      } else {
        sum += (c - 0x30) * 3;
      }
      fak--;
    }
    return String.fromCharCode((sum % 10) + 0x30);
  }

  @override
  Iterable<bool> convert(String data) sync* {
    verify(data);
    final checksum = checkSumModulo10(data);
    final pattern = BarcodeMaps.ean5Checksum[checksum.codeUnitAt(0)];

    yield* add(BarcodeMaps.eanStartEan2, 5);

    var index = 0;
    for (var code in data.codeUnits) {
      final codes = BarcodeMaps.ean[code];

      if (codes == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      if (index >= 1) {
        yield* add(BarcodeMaps.eanCenterEan2, 2);
      }

      yield* add(codes[(pattern! >> index) & 1], 7);
      index++;
    }
  }
}

class BarcodeEan8 extends BarcodeEan {
  const BarcodeEan8(this.drawSpacers);

  final bool drawSpacers;

  static const String _startSpacer = "<";

  static const String _finalSpacer = ">";

  @override
  String get name => "EAN 8";

  @override
  int get minLength => 7;

  @override
  int get maxLength => 8;

  @override
  void verifyBytes(Uint8List data) {
    final text = utf8.decoder.convert(data);
    checkLength(text, maxLength);
    super.verifyBytes(data);
  }

  @override
  Iterable<bool> convert(String data) sync* {
    data = checkLength(data, maxLength);

    yield* add(BarcodeMaps.eanStartEnd, 3);

    var index = 0;
    for (var code in data.codeUnits) {
      final codes = BarcodeMaps.ean[code];

      if (codes == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      if (index == 4) {
        yield* add(BarcodeMaps.eanCenter, 5);
      }

      yield* add(codes[index < 4 ? 0 : 2], 7);
      index++;
    }

    yield* add(BarcodeMaps.eanStartEnd, 3);
  }

  @override
  double marginLeft(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText || !drawSpacers) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double marginRight(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText || !drawSpacers) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double getHeight(
    int index,
    int count,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    bool drawText,
  ) {
    if (!drawText) {
      return super.getHeight(
        index,
        count,
        width,
        height,
        fontHeight,
        textPadding,
        drawText,
      );
    }

    final h = height - fontHeight - textPadding;

    if (index + count < 4 || (index > 31 && index + count < 36) || index > 63) {
      return h + fontHeight / 2 + textPadding;
    }

    return h;
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) sync* {
    data = checkLength(data, maxLength);
    final w = lineWidth * 7;
    final left = marginLeft(true, width, height, fontHeight, textPadding);
    final right = marginRight(true, width, height, fontHeight, textPadding);
    var offset = left + lineWidth * 3;

    for (var i = 0; i < data.length; i++) {
      yield BarcodeText(
        left: offset,
        top: height - fontHeight,
        width: w,
        height: fontHeight,
        text: data[i],
        align: BarcodeTextAlign.center,
      );

      offset += w;
      if (i == 3) {
        offset += lineWidth * 5;
      }
    }

    if (drawSpacers) {
      yield BarcodeText(
        left: 0,
        top: height - fontHeight,
        width: left - lineWidth,
        height: fontHeight,
        text: _startSpacer,
        align: BarcodeTextAlign.right,
      );
      yield BarcodeText(
        left: width - right + lineWidth,
        top: height - fontHeight,
        width: right - lineWidth,
        height: fontHeight,
        text: _finalSpacer,
        align: BarcodeTextAlign.left,
      );
    }
  }
}

final class QrEci implements QrDatum {
  final int value;

  factory QrEci(int value) {
    if (value < 0 || value > 999999) {
      throw RangeError.range(value, 0, 999999, "value");
    }
    return QrEci._(value);
  }

  QrEci._(this.value);

  @override
  QrMode get mode => QrMode.eci;

  @override
  int get length => 0;

  @override
  int get bitLength => switch (value) {
    < 128 => 8,
    < 16384 => 16,
    _ => 24,
  };

  @override
  void write(QrBitBuffer buffer) {
    if (value < 128) {
      buffer.put(value, 8);
    } else if (value < 16384) {
      buffer.put(0x8000 | value, 16);
    } else {
      buffer.put(0xC00000 | value, 24);
    }
  }
}

extension type const QrEciValue(int value) implements int {
  static const iso8859_1 = QrEciValue(3);

  static const iso8859_2 = QrEciValue(4);

  static const iso8859_3 = QrEciValue(5);

  static const iso8859_4 = QrEciValue(6);

  static const iso8859_5 = QrEciValue(7);

  static const iso8859_6 = QrEciValue(8);

  static const iso8859_7 = QrEciValue(9);

  static const iso8859_8 = QrEciValue(10);

  static const iso8859_9 = QrEciValue(11);

  static const iso8859_10 = QrEciValue(12);

  static const iso8859_11 = QrEciValue(13);

  static const iso8859_13 = QrEciValue(15);

  static const iso8859_14 = QrEciValue(16);

  static const iso8859_15 = QrEciValue(17);

  static const iso8859_16 = QrEciValue(18);

  static const shiftJis = QrEciValue(20);

  static const windows1250 = QrEciValue(21);

  static const windows1251 = QrEciValue(22);

  static const windows1252 = QrEciValue(23);

  static const windows1256 = QrEciValue(24);

  static const utf16BE = QrEciValue(25);

  static const utf8 = QrEciValue(26);

  static const ascii = QrEciValue(27);

  static const big5 = QrEciValue(28);

  static const gb2312 = QrEciValue(29);

  static const eucKr = QrEciValue(30);

  static const gbk = QrEciValue(31);
}

enum QrErrorCorrectLevel {
  medium(15),
  low(7),
  high(30),
  quartile(25);

  final int recoveryRate;

  const QrErrorCorrectLevel(this.recoveryRate);
}

final class InputTooLongException implements Exception {
  final int inputBits;

  final int inputLimit;

  InputTooLongException._(this.inputBits, this.inputLimit) : assert(inputBits > inputLimit);

  @override
  String toString() => "Input too long. $inputBits > $inputLimit";
}

InputTooLongException createExp(int inputBits, int inputLimit) => InputTooLongException._(inputBits, inputLimit);

class BarcodeIsbn extends BarcodeEan13 {
  const BarcodeIsbn(bool drawEndChar, this.drawIsbn) : super(drawEndChar);

  final bool drawIsbn;

  @override
  double marginTop(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText || !drawIsbn) {
      return super.marginTop(drawText, width, height, fontHeight, textPadding);
    }

    return fontHeight + textPadding;
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) sync* {
    data = checkLength(data, maxLength);
    yield* super.makeText(
      data,
      width,
      height,
      fontHeight,
      textPadding,
      lineWidth,
    );

    if (drawIsbn) {
      final isbn = "${data.substring(0, 3)}-${data.substring(3, 12)}-${data.substring(12, 13)}";

      yield BarcodeText(
        left: 0,
        top: 0,
        width: width,
        height: fontHeight,
        text: "ISBN $isbn",
        align: BarcodeTextAlign.center,
      );
    }
  }

  @override
  String get name => "ISBN";
}

class BarcodeItf extends BarcodeEan {
  const BarcodeItf(
    this.addChecksum,
    this.zeroPrepend,
    this.drawBorder,
    this.borderWidth,
    this.quietWidth,
    this.fixedLength,
  ) : assert(fixedLength == null || fixedLength % 2 == 0);

  final bool addChecksum;

  final bool zeroPrepend;

  final bool drawBorder;

  final double? borderWidth;

  final double? quietWidth;

  final int? fixedLength;

  @override
  String get name => "ITF";

  @override
  int get minLength => fixedLength != null ? fixedLength! - 1 : super.minLength;

  @override
  int get maxLength => fixedLength != null ? fixedLength! : super.maxLength;

  double _getBorderWidth(double width) {
    return borderWidth ?? width * .015;
  }

  double _getQuietWidth(double width) {
    return quietWidth ?? width * .07;
  }

  @override
  double marginTop(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    return drawBorder ? _getBorderWidth(width) : 0;
  }

  @override
  double marginLeft(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    return drawBorder ? _getBorderWidth(width) + _getQuietWidth(width) : 0;
  }

  @override
  double marginRight(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    return drawBorder ? _getBorderWidth(width) + _getQuietWidth(width) : 0;
  }

  @override
  double getHeight(
    int index,
    int count,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    bool drawText,
  ) {
    return super.getHeight(
          index,
          count,
          width,
          height,
          fontHeight,
          textPadding,
          drawText,
        ) -
        (drawBorder ? _getBorderWidth(width) : 0);
  }

  @override
  Iterable<bool> convert(String data) sync* {
    if (fixedLength != null) {
      data = checkLength(data, fixedLength!);
    } else {
      if (zeroPrepend && ((data.length % 2 != 0) != addChecksum)) {
        data = "0$data";
      }

      if (addChecksum) {
        data += checkSumModulo10(data);
      }

      if (data.length % 2 != 0) {
        throw BarcodeException("$name barcode can only encode an even number of digits.");
      }
    }

    yield* add(BarcodeMaps.itfStart, 4);

    final cu = data.codeUnits;
    for (var i = 0; i < cu.length / 2; i++) {
      final tuple = <int?>[BarcodeMaps.itf[cu[i * 2]], BarcodeMaps.itf[cu[i * 2 + 1]]];

      if (tuple[0] == null || tuple[1] == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(cu[i * 2])}${String.fromCharCode(cu[i * 2 + 1])}" to $name Barcode');
      }

      for (var n = 0; n < 10; n++) {
        final v = (tuple[n % 2]! >> (n ~/ 2)) & 1;
        final c = n % 2 == 0;
        yield c;
        if (v != 0) {
          yield c;
          yield c;
        }
      }
    }

    yield* add(BarcodeMaps.itfEnd, 5);
  }

  @override
  Iterable<BarcodeElement> makeBytes(
    Uint8List data, {
    required double width,
    required double height,
    bool drawText = false,
    double? fontHeight,
    double? textPadding,
  }) sync* {
    assert(width > 0);
    assert(height > 0);
    assert(!drawText || fontHeight != null);
    fontHeight ??= 0;
    textPadding ??= Barcode1D.defaultTextPadding;

    yield* super.makeBytes(
      data,
      width: width,
      height: height,
      drawText: drawText,
      fontHeight: fontHeight,
      textPadding: textPadding,
    );

    if (drawBorder) {
      final bw = _getBorderWidth(width);
      final hp = drawText ? fontHeight + textPadding : 0;

      yield BarcodeBar(left: 0, top: 0, width: width, height: bw, black: true);
      yield BarcodeBar(left: 0, top: height - hp - bw, width: width, height: bw, black: true);
      yield BarcodeBar(left: 0, top: bw, width: bw, height: height - hp - bw * 2, black: true);
      yield BarcodeBar(left: width - bw, top: bw, width: bw, height: height - hp - bw * 2, black: true);
    }
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) {
    if (fixedLength != null) {
    } else {
      if (zeroPrepend && ((data.length % 2 != 0) != addChecksum)) {
        data = "0$data";
      }

      if (addChecksum) {
        data += checkSumModulo10(data);
      }
    }

    return super.makeText(
      data,
      width,
      height,
      fontHeight,
      textPadding,
      lineWidth,
    );
  }

  @override
  void verifyBytes(Uint8List data) {
    var text = utf8.decoder.convert(data);

    if (fixedLength != null) {
      text = checkLength(text, maxLength);
    } else {
      if (zeroPrepend && ((text.length % 2 != 0) != addChecksum)) {
        text = "0$text";
      }

      if (addChecksum) {
        text += checkSumModulo10(text);
      }
    }

    if (text.length % 2 != 0) {
      throw BarcodeException("$name barcode can only encode an even number of digits.");
    }

    super.verifyBytes(utf8.encoder.convert(text));
  }

  @override
  String normalize(String data) {
    if (fixedLength != null) {
      return checkLength(zeroPrepend ? data.padRight(minLength, "0").substring(0, minLength) : data, maxLength);
    }

    if (zeroPrepend && ((data.length % 2 != 0) != addChecksum)) {
      data = "0$data";
    }

    if (addChecksum) {
      data += checkSumModulo10(data);
    }

    return data;
  }
}

class BarcodeItf14 extends BarcodeItf {
  const BarcodeItf14(
    bool drawBorder,
    double? borderWidth,
    double? quietWidth,
  ) : super(true, true, drawBorder, borderWidth, quietWidth, 14);

  @override
  String get name => "ITF 14";

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) {
    data = checkLength(data, maxLength);
    data = "${data.substring(0, 1)} ${data.substring(1, 3)} ${data.substring(3, 8)} ${data.substring(8, 13)} ${data.substring(13, 14)}";
    return super.makeText(
      data,
      width,
      height,
      fontHeight,
      textPadding,
      lineWidth,
    );
  }
}

class BarcodeItf16 extends BarcodeItf {
  const BarcodeItf16(
    bool drawBorder,
    double? borderWidth,
    double? quietWidth,
  ) : super(true, true, drawBorder, borderWidth, quietWidth, 16);

  @override
  String get name => "ITF 16";

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) {
    data = checkLength(data, maxLength);
    data = "${data.substring(0, 1)} ${data.substring(1, 3)} ${data.substring(3, 5)} ${data.substring(5, 10)} ${data.substring(10, 15)} ${data.substring(15, 16)}";
    return super.makeText(
      data,
      width,
      height,
      fontHeight,
      textPadding,
      lineWidth,
    );
  }
}

final Uint8List _logTable = _createLogTable();
final Uint8List _expTable = _createExpTable();

int glog(int n) => (n >= 1) ? _logTable[n] : throw ArgumentError.value(n, "n", "must be >= 1");

int gexp(int n) => _expTable[n % 255];

Uint8List _createExpTable() {
  final list = Uint8List(256);
  for (var i = 0; i < 8; i++) {
    list[i] = 1 << i;
  }
  for (var i = 8; i < 256; i++) {
    list[i] = list[i - 4] ^ list[i - 5] ^ list[i - 6] ^ list[i - 8];
  }
  return list;
}

Uint8List _createLogTable() {
  final list = Uint8List(256);
  for (var i = 0; i < 255; i++) {
    list[_expTable[i]] = i;
  }
  return list;
}

class MeCard {
  const MeCard({this.type = "MECARD", this.fields = const <MeTuple>[]});

  factory MeCard.contact({
    String? name,
    String? reading,
    String? tel,
    List<String>? tels,
    String? videophone,
    String? email,
    List<String>? emails,
    String? memo,
    DateTime? birthday,
    String? address,
    String? url,
    List<String>? urls,
    String? nickname,
  }) {
    final fields = <MeTuple>[];

    if (name != null) {
      fields.add(MeTuple("N", name));
    }
    if (reading != null) {
      fields.add(MeTuple("SOUND", reading));
    }
    if (tel != null) {
      fields.add(MeTuple("TEL", tel));
    }
    if (tels != null) {
      for (final tel in tels) {
        fields.add(MeTuple("TEL", tel));
      }
    }
    if (videophone != null) {
      fields.add(MeTuple("TEL-AV", videophone));
    }
    if (email != null) {
      fields.add(MeTuple("EMAIL", email));
    }
    if (emails != null) {
      for (final email in emails) {
        fields.add(MeTuple("EMAIL", email));
      }
    }
    if (memo != null) {
      fields.add(MeTuple("NOTE", memo));
    }
    if (birthday != null) {
      fields.add(MeTuple.date("BDAY", birthday));
    }
    if (address != null) {
      fields.add(MeTuple("ADR", address));
    }
    if (url != null) {
      fields.add(MeTuple("URL", url));
    }
    if (urls != null) {
      for (final url in urls) {
        fields.add(MeTuple("URL", url));
      }
    }
    if (nickname != null) {
      fields.add(MeTuple("NICKNAME", nickname));
    }

    return MeCard(fields: fields);
  }

  factory MeCard.wifi({
    required String ssid,
    String type = "WPA",
    String? password,
    bool hidden = false,
  }) {
    final fields = <MeTuple>[];

    fields.add(MeTuple("S", ssid));

    if (password != null) {
      fields.add(MeTuple("T", type));
      fields.add(MeTuple("P", password));
    }
    if (hidden == true) {
      fields.add(MeTuple.bool("H", true));
    }

    return MeCard(type: "WIFI", fields: fields);
  }

  final String type;

  final List<MeTuple> fields;

  @override
  String toString() {
    final result = StringBuffer();
    result.write("${_str(type)}:");

    for (final field in fields) {
      result.write("${_str(field.key)}:${_str(field.val)};");
    }

    result.write(";");
    return result.toString();
  }

  static String _str(String s) {
    return s.replaceAllMapped(
      RegExp('[;:"]'),
      (match) => r"\" + match.group(0)!,
    );
  }
}

class MeTuple {
  const MeTuple(this.key, this.val);

  factory MeTuple.bool(String key, bool val) {
    return MeTuple(key, val ? "true" : "false");
  }

  factory MeTuple.date(String key, DateTime val) {
    final y = "${val.year}".padLeft(4, "0");
    final m = "${val.month}".padLeft(2, "0");
    final d = "${val.day}".padLeft(2, "0");
    return MeTuple(key, "$y$m$d");
  }

  factory MeTuple.sub(String key, Iterable<String> val) {
    final result = StringBuffer();
    for (final v in val) {
      result.write(v.replaceAll(",", r"\,"));
      result.write(",");
    }

    final data = result.toString();
    var p = data.length - 1;
    while (data.codeUnitAt(p) == 0x2c) {
      p--;
    }

    return MeTuple(key, data.substring(0, p + 1));
  }

  final String key;

  final String val;
}

enum QrMode {
  numeric(1),
  alphaNumeric(2),
  byte(4),
  kanji(8),
  eci(7);

  final int value;

  const QrMode(this.value);

  int getLengthBits(int type) {
    if (type < 1 || type > 40) throw RangeError.range(type, 1, 40, "type");

    if (type < 10) {
      return switch (this) {
        numeric => 10,
        alphaNumeric => 9,
        byte => 8,
        kanji => 8,
        eci => 0,
      };
    } else if (type < 27) {
      return switch (this) {
        numeric => 12,
        alphaNumeric => 11,
        byte => 16,
        kanji => 10,
        eci => 0,
      };
    } else {
      return switch (this) {
        numeric => 14,
        alphaNumeric => 13,
        byte => 16,
        kanji => 12,
        eci => 0,
      };
    }
  }
}

final class QrPayload {
  final _dataList = <QrDatum>[];

  QrPayload();

  factory QrPayload.fromString(String data) => QrPayload()..addString(data);

  factory QrPayload.fromTypedData(TypedData data) => QrPayload().._addToList(QrByte.fromByteData(data));

  void addString(String data) {
    for (final datum in QrDatum.toDatums(data)) {
      _addToList(datum);
    }
  }

  void addTypedData(TypedData data) => _addToList(QrByte.fromByteData(data));

  void addNumeric(String numberString) => _addToList(QrNumeric.fromString(numberString));

  void addAlphaNumeric(String alphaNumeric) => _addToList(QrAlphaNumeric.fromString(alphaNumeric));

  void addECI(QrEciValue eciValue) => _addToList(QrEci(eciValue));

  void _addToList(QrDatum data) {
    _dataList.add(data);
  }
}

extension QrPayloadInternal on QrPayload {
  List<QrDatum> get dataList => _dataList;

  int calculateRequiredBits(int typeNumber) {
    var bits = 0;
    for (final datum in _dataList) {
      bits += 4 + datum.mode.getLengthBits(typeNumber) + datum.bitLength;
    }
    return bits;
  }
}

enum Pdf417SecurityLevel {
  level0,
  level1,
  level2,
  level3,
  level4,
  level5,
  level6,
  level7,
  level8,
}

class BarcodePDF417 extends Barcode2D {
  const BarcodePDF417(this.securityLevel, this.moduleHeight, this.preferredRatio);

  static const _minCols = 2;
  static const _maxCols = 60;
  static const _maxRows = 60;
  static const _minRows = 2;

  final double moduleHeight;

  final double preferredRatio;

  final Pdf417SecurityLevel securityLevel;

  @override
  Barcode2DMatrix convert(Uint8List data) {
    final dataWords = _highlevelEncode(data);

    final dim = _calcDimensions(dataWords.length, _errorCorrectionWordCount(securityLevel));
    if (dim.columns < _minCols || dim.columns > _maxCols || dim.rows < _minRows || dim.rows > _maxRows) {
      throw const BarcodeException("Unable to fit data in barcode");
    }

    final codeWords = _encodeData(dataWords.toList(), dim.columns, securityLevel);

    final grid = <List<int>>[];
    for (var i = 0; i < codeWords.length; i += dim.columns) {
      grid.add(codeWords.sublist(i, min(i + dim.columns, codeWords.length)));
    }

    final codes = <List<int>>[];

    var rowNum = 0;
    for (final row in grid) {
      final table = rowNum % 3;
      final rowCodes = <int>[];

      rowCodes.add(start_word);
      rowCodes.add(_getCodeword(table, _getLeftCodeWord(rowNum, dim.rows, dim.columns, securityLevel)));

      for (final word in row) {
        rowCodes.add(_getCodeword(table, word));
      }

      rowCodes.add(_getCodeword(table, _getRightCodeWord(rowNum, dim.rows, dim.columns, securityLevel)));
      rowCodes.add(stop_word);

      codes.add(rowCodes);

      rowNum++;
    }

    final width = (dim.columns + 4) * 17 + 1;

    return Barcode2DMatrix(
      width,
      dim.rows,
      moduleHeight,
      _renderBarcode(codes),
    );
  }

  @override
  Iterable<int> get charSet => Iterable<int>.generate(256);

  @override
  String get name => "PDF417";

  @override
  int get maxLength => 990;

  List<int> _encodeData(List<int> dataWords, int columns, Pdf417SecurityLevel securityLevel) {
    final dataCount = dataWords.length;

    final ecCount = _errorCorrectionWordCount(securityLevel);

    final padWords = _getPadding(dataCount, ecCount, columns);
    dataWords.addAll(padWords);

    final length = dataWords.length + 1;
    dataWords.insert(0, length);

    final ecWords = _computeErrorCorrection(securityLevel, dataWords);

    dataWords.addAll(ecWords);
    return dataWords;
  }

  int _getLeftCodeWord(int rowNum, int rows, int columns, Pdf417SecurityLevel securityLevel) {
    final tableId = rowNum % 3;

    late int x;

    switch (tableId) {
      case 0:
        x = (rows - 3) ~/ 3;
        break;
      case 1:
        x = securityLevel.index * 3;
        x += (rows - 1) % 3;
        break;
      case 2:
        x = columns - 1;
        break;
    }

    return 30 * (rowNum ~/ 3) + x;
  }

  int _getRightCodeWord(int rowNum, int rows, int columns, Pdf417SecurityLevel securityLevel) {
    final tableId = rowNum % 3;

    late int x;

    switch (tableId) {
      case 0:
        x = columns - 1;
        break;
      case 1:
        x = (rows - 1) ~/ 3;
        break;
      case 2:
        x = securityLevel.index * 3;
        x += (rows - 1) % 3;
        break;
    }

    return 30 * (rowNum ~/ 3) + x;
  }

  Iterable<int> _getPadding(int dataCount, int ecCount, int columns) sync* {
    final totalCount = dataCount + ecCount + 1;
    final mod = totalCount % columns;

    if (mod > 0) {
      final padCount = columns - mod;
      yield* Iterable<int>.generate(padCount, (_) => padding_codeword);
    }
  }

  Iterable<bool> _addBits(int b, int count) sync* {
    for (var i = count - 1; i >= 0; i--) {
      yield ((b >> i) & 1) == 1;
    }
  }

  Iterable<bool> _renderBarcode(List<List<int>> codes) sync* {
    for (final row in codes) {
      final lastIdx = row.length - 1;
      var i = 0;
      for (final col in row) {
        if (i == lastIdx) {
          yield* _addBits(col, 18);
        } else {
          yield* _addBits(col, 17);
        }
        i++;
      }
    }
  }

  int _calculateNumberOfRows(int m, int k, int c) {
    var r = ((m + 1 + k) ~/ c) + 1;
    if (c * r >= (m + 1 + k + c)) {
      r--;
    }
    return r;
  }

  _Pdf417Size _calcDimensions(int dataWords, int eccWords) {
    var ratio = 0.0;
    var cols = 0;
    var rows = 0;

    for (var c = _minCols; c <= _maxCols; c++) {
      final r = _calculateNumberOfRows(dataWords, eccWords, c);

      if (r < _minRows) {
        break;
      }

      if (r > _maxRows) {
        continue;
      }

      if (r != 0) {
        final newRatio = (17 * c + 69) / (r * moduleHeight);

        if ((newRatio - preferredRatio).abs() < (ratio - preferredRatio).abs()) {
          ratio = newRatio;
          cols = c;
          rows = r;
          continue;
        }

        break;
      }
    }

    if (rows == 0) {
      cols = _minCols;
      rows = _calculateNumberOfRows(dataWords, eccWords, cols);
      if (rows < _minRows) {
        rows = _minRows;
      }
    }

    return _Pdf417Size(cols, rows);
  }

  int _errorCorrectionWordCount(Pdf417SecurityLevel level) {
    return 1 << (level.index + 1);
  }

  List<int> _computeErrorCorrection(Pdf417SecurityLevel level, Iterable<int> data) {
    final factors = correctionFactors[level.index];

    final count = _errorCorrectionWordCount(level);

    final ecWords = List<int>.filled(count, 0);

    for (final value in data) {
      final temp = (value + ecWords[0]) % 929;

      for (var i = count - 1; i >= 0; i--) {
        var add = 0;

        if (i > 0) {
          add = ecWords[count - i];
        }

        ecWords[count - 1 - i] = (add + 929 - (temp * factors[i]) % 929) % 929;
      }
    }

    var key = 0;
    for (final word in ecWords) {
      if (word > 0) {
        ecWords[key] = 929 - word;
      }
      key++;
    }

    return ecWords;
  }

  int _getCodeword(int tableId, int word) {
    return codewords[tableId][word];
  }

  int _determineConsecutiveDigitCount(Iterable<int> data) {
    var cnt = 0;
    for (final r in data) {
      if (r < 0x30 || r > 0x39) {
        break;
      }
      cnt++;
    }
    return cnt;
  }

  Iterable<int> _encodeNumeric(List<int> digits) sync* {
    final digitCount = digits.length;
    var chunkCount = digitCount ~/ 44;
    if (digitCount % 44 != 0) {
      chunkCount++;
    }

    for (var i = 0; i < chunkCount; i++) {
      final start = i * 44;
      var end = start + 44;
      if (end > digitCount) {
        end = digitCount;
      }
      final chunk = digits.sublist(start, end);

      var chunkNum = BigInt.parse("1${String.fromCharCodes(chunk)}", radix: 10);

      final cws = <int>[];

      while (chunkNum > BigInt.zero) {
        final newChunk = chunkNum ~/ BigInt.from(900);
        final cw = chunkNum % BigInt.from(900);

        chunkNum = newChunk;
        cws.insert(0, cw.toInt());
      }

      yield* cws;
    }
  }

  bool _isText(int ch) {
    return ch == 0x9 || ch == 0xa || ch == 0xd || (ch >= 32 && ch <= 126);
  }

  int _determineConsecutiveTextCount(List<int> msg) {
    var result = 0;

    var i = 0;
    for (final ch in msg) {
      final numericCount = _determineConsecutiveDigitCount(msg.sublist(i));
      if (numericCount >= min_numeric_count || (numericCount == 0 && !_isText(ch))) {
        break;
      }

      result++;
      i++;
    }
    return result;
  }

  bool _isAlphaUpper(int ch) {
    return ch == 0x20 || (ch >= 0x41 && ch <= 0x5a);
  }

  bool _isAlphaLower(int ch) {
    return ch == 0x20 || (ch >= 0x61 && ch <= 0x7a);
  }

  bool _isMixed(int ch) {
    return mixedMap.containsKey(ch);
  }

  bool _isPunctuation(int ch) {
    return punctMap.containsKey(ch);
  }

  _SubMode _encodeText(List<int> text, _SubMode submode, List<int> result) {
    var idx = 0;
    final tmp = <int?>[];

    while (idx < text.length) {
      final ch = text[idx];
      switch (submode) {
        case _SubMode.subUpper:
          if (_isAlphaUpper(ch)) {
            if (ch == 0x20) {
              tmp.add(26);
            } else {
              tmp.add(ch - 0x41);
            }
          } else {
            if (_isAlphaLower(ch)) {
              submode = _SubMode.subLower;
              tmp.add(27);
              continue;
            } else if (_isMixed(ch)) {
              submode = _SubMode.subMixed;
              tmp.add(28);
              continue;
            } else {
              tmp.add(29);
              tmp.add(punctMap[ch]);
              break;
            }
          }
          break;
        case _SubMode.subLower:
          if (_isAlphaLower(ch)) {
            if (ch == 0x20) {
              tmp.add(26);
            } else {
              tmp.add(ch - 0x61);
            }
          } else {
            if (_isAlphaUpper(ch)) {
              tmp.add(27);
              tmp.add(ch - 0x41);
              break;
            } else if (_isMixed(ch)) {
              submode = _SubMode.subMixed;
              tmp.add(28);
              continue;
            } else {
              tmp.add(29);
              tmp.add(punctMap[ch]);
              break;
            }
          }
          break;
        case _SubMode.subMixed:
          if (_isMixed(ch)) {
            tmp.add(mixedMap[ch]);
          } else {
            if (_isAlphaUpper(ch)) {
              submode = _SubMode.subUpper;
              tmp.add(28);
              continue;
            } else if (_isAlphaLower(ch)) {
              submode = _SubMode.subLower;
              tmp.add(27);
              continue;
            } else {
              if (idx + 1 < text.length) {
                final next = text[idx + 1];
                if (_isPunctuation(next)) {
                  submode = _SubMode.subPunct;
                  tmp.add(25);
                  continue;
                }
              }
              tmp.add(29);
              tmp.add(punctMap[ch]);
            }
          }
          break;
        default:
          if (_isPunctuation(ch)) {
            tmp.add(punctMap[ch]);
          } else {
            submode = _SubMode.subUpper;
            tmp.add(29);
            continue;
          }
      }
      idx++;
    }

    int? h = 0;
    var i = 0;
    for (final val in tmp) {
      if (i % 2 != 0) {
        h = (h! * 30) + val!;
        result.add(h);
      } else {
        h = val;
      }
      i++;
    }
    if (tmp.length % 2 != 0) {
      result.add((h! * 30) + 29);
    }
    return submode;
  }

  int _determineConsecutiveBinaryCount(List<int> msg) {
    var result = 0;

    for (var i = 0; i < msg.length; i++) {
      final numericCount = _determineConsecutiveDigitCount(msg.sublist(i));
      if (numericCount >= min_numeric_count) {
        break;
      }
      final textCount = _determineConsecutiveTextCount(msg.sublist(i));
      if (textCount > 5) {
        break;
      }
      result++;
    }
    return result;
  }

  Iterable<int> _encodeBinary(List<int> data, _Pdf417EncodingMode startmode) sync* {
    final count = data.length;
    if (count == 1 && startmode == _Pdf417EncodingMode.encText) {
      yield shift_to_byte;
    } else if ((count % 6) == 0) {
      yield latch_to_byte;
    } else {
      yield latch_to_byte_padded;
    }

    var idx = 0;

    if (count >= 6) {
      final words = List<int>.filled(5, 0);
      while ((count - idx) >= 6) {
        var t = 0;
        for (var i = 0; i < 6; i++) {
          t = t << 8;
          t += data[idx + i];
        }
        for (var i = 0; i < 5; i++) {
          words[4 - i] = t % 900;
          t = t ~/ 900;
        }
        yield* words;
        idx += 6;
      }
    }

    for (var i = idx; i < count; i++) {
      yield data[i] & 0xff;
    }
  }

  Iterable<int> _highlevelEncode(List<int> data) sync* {
    var encodingMode = _Pdf417EncodingMode.encText;
    var textSubMode = _SubMode.subUpper;

    while (data.isNotEmpty) {
      final numericCount = _determineConsecutiveDigitCount(data);
      if (numericCount >= min_numeric_count || numericCount == data.length) {
        yield latch_to_numeric;
        encodingMode = _Pdf417EncodingMode.encNumeric;
        textSubMode = _SubMode.subUpper;
        final numData = _encodeNumeric(data.sublist(0, numericCount));
        yield* numData;
        data = data.sublist(numericCount);
      } else {
        final textCount = _determineConsecutiveTextCount(data);
        if (textCount >= 5 || textCount == data.length) {
          if (encodingMode != _Pdf417EncodingMode.encText) {
            yield latch_to_text;
            encodingMode = _Pdf417EncodingMode.encText;
            textSubMode = _SubMode.subUpper;
          }
          final txtData = <int>[];
          textSubMode = _encodeText(data.sublist(0, textCount), textSubMode, txtData);
          yield* txtData;
          data = data.sublist(textCount);
        } else {
          var binaryCount = _determineConsecutiveBinaryCount(data);
          if (binaryCount == 0) {
            binaryCount = 1;
          }
          final bytes = data.sublist(0, binaryCount);
          if (bytes.length != 1 || encodingMode != _Pdf417EncodingMode.encText) {
            encodingMode = _Pdf417EncodingMode.encBinary;
            textSubMode = _SubMode.subUpper;
          }
          final byteData = _encodeBinary(bytes, encodingMode);
          yield* byteData;
          data = data.sublist(binaryCount);
        }
      }
    }
  }
}

enum _Pdf417EncodingMode { encText, encNumeric, encBinary }

enum _SubMode { subUpper, subLower, subMixed, subPunct }

class _Pdf417Size {
  _Pdf417Size(this.columns, this.rows);

  final int columns;
  final int rows;
}

const start_word = 0x1fea8;
const stop_word = 0x3fa29;

const padding_codeword = 900;

const codewords = <List<int>>[
  <int>[
    0x1d5c0,
    0x1eaf0,
    0x1f57c,
    0x1d4e0,
    0x1ea78,
    0x1f53e,
    0x1a8c0,
    0x1d470,
    0x1a860,
    0x15040,
    0x1a830,
    0x15020,
    0x1adc0,
    0x1d6f0,
    0x1eb7c,
    0x1ace0,
    0x1d678,
    0x1eb3e,
    0x158c0,
    0x1ac70,
    0x15860,
    0x15dc0,
    0x1aef0,
    0x1d77c,
    0x15ce0,
    0x1ae78,
    0x1d73e,
    0x15c70,
    0x1ae3c,
    0x15ef0,
    0x1af7c,
    0x15e78,
    0x1af3e,
    0x15f7c,
    0x1f5fa,
    0x1d2e0,
    0x1e978,
    0x1f4be,
    0x1a4c0,
    0x1d270,
    0x1e93c,
    0x1a460,
    0x1d238,
    0x14840,
    0x1a430,
    0x1d21c,
    0x14820,
    0x1a418,
    0x14810,
    0x1a6e0,
    0x1d378,
    0x1e9be,
    0x14cc0,
    0x1a670,
    0x1d33c,
    0x14c60,
    0x1a638,
    0x1d31e,
    0x14c30,
    0x1a61c,
    0x14ee0,
    0x1a778,
    0x1d3be,
    0x14e70,
    0x1a73c,
    0x14e38,
    0x1a71e,
    0x14f78,
    0x1a7be,
    0x14f3c,
    0x14f1e,
    0x1a2c0,
    0x1d170,
    0x1e8bc,
    0x1a260,
    0x1d138,
    0x1e89e,
    0x14440,
    0x1a230,
    0x1d11c,
    0x14420,
    0x1a218,
    0x14410,
    0x14408,
    0x146c0,
    0x1a370,
    0x1d1bc,
    0x14660,
    0x1a338,
    0x1d19e,
    0x14630,
    0x1a31c,
    0x14618,
    0x1460c,
    0x14770,
    0x1a3bc,
    0x14738,
    0x1a39e,
    0x1471c,
    0x147bc,
    0x1a160,
    0x1d0b8,
    0x1e85e,
    0x14240,
    0x1a130,
    0x1d09c,
    0x14220,
    0x1a118,
    0x1d08e,
    0x14210,
    0x1a10c,
    0x14208,
    0x1a106,
    0x14360,
    0x1a1b8,
    0x1d0de,
    0x14330,
    0x1a19c,
    0x14318,
    0x1a18e,
    0x1430c,
    0x14306,
    0x1a1de,
    0x1438e,
    0x14140,
    0x1a0b0,
    0x1d05c,
    0x14120,
    0x1a098,
    0x1d04e,
    0x14110,
    0x1a08c,
    0x14108,
    0x1a086,
    0x14104,
    0x141b0,
    0x14198,
    0x1418c,
    0x140a0,
    0x1d02e,
    0x1a04c,
    0x1a046,
    0x14082,
    0x1cae0,
    0x1e578,
    0x1f2be,
    0x194c0,
    0x1ca70,
    0x1e53c,
    0x19460,
    0x1ca38,
    0x1e51e,
    0x12840,
    0x19430,
    0x12820,
    0x196e0,
    0x1cb78,
    0x1e5be,
    0x12cc0,
    0x19670,
    0x1cb3c,
    0x12c60,
    0x19638,
    0x12c30,
    0x12c18,
    0x12ee0,
    0x19778,
    0x1cbbe,
    0x12e70,
    0x1973c,
    0x12e38,
    0x12e1c,
    0x12f78,
    0x197be,
    0x12f3c,
    0x12fbe,
    0x1dac0,
    0x1ed70,
    0x1f6bc,
    0x1da60,
    0x1ed38,
    0x1f69e,
    0x1b440,
    0x1da30,
    0x1ed1c,
    0x1b420,
    0x1da18,
    0x1ed0e,
    0x1b410,
    0x1da0c,
    0x192c0,
    0x1c970,
    0x1e4bc,
    0x1b6c0,
    0x19260,
    0x1c938,
    0x1e49e,
    0x1b660,
    0x1db38,
    0x1ed9e,
    0x16c40,
    0x12420,
    0x19218,
    0x1c90e,
    0x16c20,
    0x1b618,
    0x16c10,
    0x126c0,
    0x19370,
    0x1c9bc,
    0x16ec0,
    0x12660,
    0x19338,
    0x1c99e,
    0x16e60,
    0x1b738,
    0x1db9e,
    0x16e30,
    0x12618,
    0x16e18,
    0x12770,
    0x193bc,
    0x16f70,
    0x12738,
    0x1939e,
    0x16f38,
    0x1b79e,
    0x16f1c,
    0x127bc,
    0x16fbc,
    0x1279e,
    0x16f9e,
    0x1d960,
    0x1ecb8,
    0x1f65e,
    0x1b240,
    0x1d930,
    0x1ec9c,
    0x1b220,
    0x1d918,
    0x1ec8e,
    0x1b210,
    0x1d90c,
    0x1b208,
    0x1b204,
    0x19160,
    0x1c8b8,
    0x1e45e,
    0x1b360,
    0x19130,
    0x1c89c,
    0x16640,
    0x12220,
    0x1d99c,
    0x1c88e,
    0x16620,
    0x12210,
    0x1910c,
    0x16610,
    0x1b30c,
    0x19106,
    0x12204,
    0x12360,
    0x191b8,
    0x1c8de,
    0x16760,
    0x12330,
    0x1919c,
    0x16730,
    0x1b39c,
    0x1918e,
    0x16718,
    0x1230c,
    0x12306,
    0x123b8,
    0x191de,
    0x167b8,
    0x1239c,
    0x1679c,
    0x1238e,
    0x1678e,
    0x167de,
    0x1b140,
    0x1d8b0,
    0x1ec5c,
    0x1b120,
    0x1d898,
    0x1ec4e,
    0x1b110,
    0x1d88c,
    0x1b108,
    0x1d886,
    0x1b104,
    0x1b102,
    0x12140,
    0x190b0,
    0x1c85c,
    0x16340,
    0x12120,
    0x19098,
    0x1c84e,
    0x16320,
    0x1b198,
    0x1d8ce,
    0x16310,
    0x12108,
    0x19086,
    0x16308,
    0x1b186,
    0x16304,
    0x121b0,
    0x190dc,
    0x163b0,
    0x12198,
    0x190ce,
    0x16398,
    0x1b1ce,
    0x1638c,
    0x12186,
    0x16386,
    0x163dc,
    0x163ce,
    0x1b0a0,
    0x1d858,
    0x1ec2e,
    0x1b090,
    0x1d84c,
    0x1b088,
    0x1d846,
    0x1b084,
    0x1b082,
    0x120a0,
    0x19058,
    0x1c82e,
    0x161a0,
    0x12090,
    0x1904c,
    0x16190,
    0x1b0cc,
    0x19046,
    0x16188,
    0x12084,
    0x16184,
    0x12082,
    0x120d8,
    0x161d8,
    0x161cc,
    0x161c6,
    0x1d82c,
    0x1d826,
    0x1b042,
    0x1902c,
    0x12048,
    0x160c8,
    0x160c4,
    0x160c2,
    0x18ac0,
    0x1c570,
    0x1e2bc,
    0x18a60,
    0x1c538,
    0x11440,
    0x18a30,
    0x1c51c,
    0x11420,
    0x18a18,
    0x11410,
    0x11408,
    0x116c0,
    0x18b70,
    0x1c5bc,
    0x11660,
    0x18b38,
    0x1c59e,
    0x11630,
    0x18b1c,
    0x11618,
    0x1160c,
    0x11770,
    0x18bbc,
    0x11738,
    0x18b9e,
    0x1171c,
    0x117bc,
    0x1179e,
    0x1cd60,
    0x1e6b8,
    0x1f35e,
    0x19a40,
    0x1cd30,
    0x1e69c,
    0x19a20,
    0x1cd18,
    0x1e68e,
    0x19a10,
    0x1cd0c,
    0x19a08,
    0x1cd06,
    0x18960,
    0x1c4b8,
    0x1e25e,
    0x19b60,
    0x18930,
    0x1c49c,
    0x13640,
    0x11220,
    0x1cd9c,
    0x1c48e,
    0x13620,
    0x19b18,
    0x1890c,
    0x13610,
    0x11208,
    0x13608,
    0x11360,
    0x189b8,
    0x1c4de,
    0x13760,
    0x11330,
    0x1cdde,
    0x13730,
    0x19b9c,
    0x1898e,
    0x13718,
    0x1130c,
    0x1370c,
    0x113b8,
    0x189de,
    0x137b8,
    0x1139c,
    0x1379c,
    0x1138e,
    0x113de,
    0x137de,
    0x1dd40,
    0x1eeb0,
    0x1f75c,
    0x1dd20,
    0x1ee98,
    0x1f74e,
    0x1dd10,
    0x1ee8c,
    0x1dd08,
    0x1ee86,
    0x1dd04,
    0x19940,
    0x1ccb0,
    0x1e65c,
    0x1bb40,
    0x19920,
    0x1eedc,
    0x1e64e,
    0x1bb20,
    0x1dd98,
    0x1eece,
    0x1bb10,
    0x19908,
    0x1cc86,
    0x1bb08,
    0x1dd86,
    0x19902,
    0x11140,
    0x188b0,
    0x1c45c,
    0x13340,
    0x11120,
    0x18898,
    0x1c44e,
    0x17740,
    0x13320,
    0x19998,
    0x1ccce,
    0x17720,
    0x1bb98,
    0x1ddce,
    0x18886,
    0x17710,
    0x13308,
    0x19986,
    0x17708,
    0x11102,
    0x111b0,
    0x188dc,
    0x133b0,
    0x11198,
    0x188ce,
    0x177b0,
    0x13398,
    0x199ce,
    0x17798,
    0x1bbce,
    0x11186,
    0x13386,
    0x111dc,
    0x133dc,
    0x111ce,
    0x177dc,
    0x133ce,
    0x1dca0,
    0x1ee58,
    0x1f72e,
    0x1dc90,
    0x1ee4c,
    0x1dc88,
    0x1ee46,
    0x1dc84,
    0x1dc82,
    0x198a0,
    0x1cc58,
    0x1e62e,
    0x1b9a0,
    0x19890,
    0x1ee6e,
    0x1b990,
    0x1dccc,
    0x1cc46,
    0x1b988,
    0x19884,
    0x1b984,
    0x19882,
    0x1b982,
    0x110a0,
    0x18858,
    0x1c42e,
    0x131a0,
    0x11090,
    0x1884c,
    0x173a0,
    0x13190,
    0x198cc,
    0x18846,
    0x17390,
    0x1b9cc,
    0x11084,
    0x17388,
    0x13184,
    0x11082,
    0x13182,
    0x110d8,
    0x1886e,
    0x131d8,
    0x110cc,
    0x173d8,
    0x131cc,
    0x110c6,
    0x173cc,
    0x131c6,
    0x110ee,
    0x173ee,
    0x1dc50,
    0x1ee2c,
    0x1dc48,
    0x1ee26,
    0x1dc44,
    0x1dc42,
    0x19850,
    0x1cc2c,
    0x1b8d0,
    0x19848,
    0x1cc26,
    0x1b8c8,
    0x1dc66,
    0x1b8c4,
    0x19842,
    0x1b8c2,
    0x11050,
    0x1882c,
    0x130d0,
    0x11048,
    0x18826,
    0x171d0,
    0x130c8,
    0x19866,
    0x171c8,
    0x1b8e6,
    0x11042,
    0x171c4,
    0x130c2,
    0x171c2,
    0x130ec,
    0x171ec,
    0x171e6,
    0x1ee16,
    0x1dc22,
    0x1cc16,
    0x19824,
    0x19822,
    0x11028,
    0x13068,
    0x170e8,
    0x11022,
    0x13062,
    0x18560,
    0x10a40,
    0x18530,
    0x10a20,
    0x18518,
    0x1c28e,
    0x10a10,
    0x1850c,
    0x10a08,
    0x18506,
    0x10b60,
    0x185b8,
    0x1c2de,
    0x10b30,
    0x1859c,
    0x10b18,
    0x1858e,
    0x10b0c,
    0x10b06,
    0x10bb8,
    0x185de,
    0x10b9c,
    0x10b8e,
    0x10bde,
    0x18d40,
    0x1c6b0,
    0x1e35c,
    0x18d20,
    0x1c698,
    0x18d10,
    0x1c68c,
    0x18d08,
    0x1c686,
    0x18d04,
    0x10940,
    0x184b0,
    0x1c25c,
    0x11b40,
    0x10920,
    0x1c6dc,
    0x1c24e,
    0x11b20,
    0x18d98,
    0x1c6ce,
    0x11b10,
    0x10908,
    0x18486,
    0x11b08,
    0x18d86,
    0x10902,
    0x109b0,
    0x184dc,
    0x11bb0,
    0x10998,
    0x184ce,
    0x11b98,
    0x18dce,
    0x11b8c,
    0x10986,
    0x109dc,
    0x11bdc,
    0x109ce,
    0x11bce,
    0x1cea0,
    0x1e758,
    0x1f3ae,
    0x1ce90,
    0x1e74c,
    0x1ce88,
    0x1e746,
    0x1ce84,
    0x1ce82,
    0x18ca0,
    0x1c658,
    0x19da0,
    0x18c90,
    0x1c64c,
    0x19d90,
    0x1cecc,
    0x1c646,
    0x19d88,
    0x18c84,
    0x19d84,
    0x18c82,
    0x19d82,
    0x108a0,
    0x18458,
    0x119a0,
    0x10890,
    0x1c66e,
    0x13ba0,
    0x11990,
    0x18ccc,
    0x18446,
    0x13b90,
    0x19dcc,
    0x10884,
    0x13b88,
    0x11984,
    0x10882,
    0x11982,
    0x108d8,
    0x1846e,
    0x119d8,
    0x108cc,
    0x13bd8,
    0x119cc,
    0x108c6,
    0x13bcc,
    0x119c6,
    0x108ee,
    0x119ee,
    0x13bee,
    0x1ef50,
    0x1f7ac,
    0x1ef48,
    0x1f7a6,
    0x1ef44,
    0x1ef42,
    0x1ce50,
    0x1e72c,
    0x1ded0,
    0x1ef6c,
    0x1e726,
    0x1dec8,
    0x1ef66,
    0x1dec4,
    0x1ce42,
    0x1dec2,
    0x18c50,
    0x1c62c,
    0x19cd0,
    0x18c48,
    0x1c626,
    0x1bdd0,
    0x19cc8,
    0x1ce66,
    0x1bdc8,
    0x1dee6,
    0x18c42,
    0x1bdc4,
    0x19cc2,
    0x1bdc2,
    0x10850,
    0x1842c,
    0x118d0,
    0x10848,
    0x18426,
    0x139d0,
    0x118c8,
    0x18c66,
    0x17bd0,
    0x139c8,
    0x19ce6,
    0x10842,
    0x17bc8,
    0x1bde6,
    0x118c2,
    0x17bc4,
    0x1086c,
    0x118ec,
    0x10866,
    0x139ec,
    0x118e6,
    0x17bec,
    0x139e6,
    0x17be6,
    0x1ef28,
    0x1f796,
    0x1ef24,
    0x1ef22,
    0x1ce28,
    0x1e716,
    0x1de68,
    0x1ef36,
    0x1de64,
    0x1ce22,
    0x1de62,
    0x18c28,
    0x1c616,
    0x19c68,
    0x18c24,
    0x1bce8,
    0x19c64,
    0x18c22,
    0x1bce4,
    0x19c62,
    0x1bce2,
    0x10828,
    0x18416,
    0x11868,
    0x18c36,
    0x138e8,
    0x11864,
    0x10822,
    0x179e8,
    0x138e4,
    0x11862,
    0x179e4,
    0x138e2,
    0x179e2,
    0x11876,
    0x179f6,
    0x1ef12,
    0x1de34,
    0x1de32,
    0x19c34,
    0x1bc74,
    0x1bc72,
    0x11834,
    0x13874,
    0x178f4,
    0x178f2,
    0x10540,
    0x10520,
    0x18298,
    0x10510,
    0x10508,
    0x10504,
    0x105b0,
    0x10598,
    0x1058c,
    0x10586,
    0x105dc,
    0x105ce,
    0x186a0,
    0x18690,
    0x1c34c,
    0x18688,
    0x1c346,
    0x18684,
    0x18682,
    0x104a0,
    0x18258,
    0x10da0,
    0x186d8,
    0x1824c,
    0x10d90,
    0x186cc,
    0x10d88,
    0x186c6,
    0x10d84,
    0x10482,
    0x10d82,
    0x104d8,
    0x1826e,
    0x10dd8,
    0x186ee,
    0x10dcc,
    0x104c6,
    0x10dc6,
    0x104ee,
    0x10dee,
    0x1c750,
    0x1c748,
    0x1c744,
    0x1c742,
    0x18650,
    0x18ed0,
    0x1c76c,
    0x1c326,
    0x18ec8,
    0x1c766,
    0x18ec4,
    0x18642,
    0x18ec2,
    0x10450,
    0x10cd0,
    0x10448,
    0x18226,
    0x11dd0,
    0x10cc8,
    0x10444,
    0x11dc8,
    0x10cc4,
    0x10442,
    0x11dc4,
    0x10cc2,
    0x1046c,
    0x10cec,
    0x10466,
    0x11dec,
    0x10ce6,
    0x11de6,
    0x1e7a8,
    0x1e7a4,
    0x1e7a2,
    0x1c728,
    0x1cf68,
    0x1e7b6,
    0x1cf64,
    0x1c722,
    0x1cf62,
    0x18628,
    0x1c316,
    0x18e68,
    0x1c736,
    0x19ee8,
    0x18e64,
    0x18622,
    0x19ee4,
    0x18e62,
    0x19ee2,
    0x10428,
    0x18216,
    0x10c68,
    0x18636,
    0x11ce8,
    0x10c64,
    0x10422,
    0x13de8,
    0x11ce4,
    0x10c62,
    0x13de4,
    0x11ce2,
    0x10436,
    0x10c76,
    0x11cf6,
    0x13df6,
    0x1f7d4,
    0x1f7d2,
    0x1e794,
    0x1efb4,
    0x1e792,
    0x1efb2,
    0x1c714,
    0x1cf34,
    0x1c712,
    0x1df74,
    0x1cf32,
    0x1df72,
    0x18614,
    0x18e34,
    0x18612,
    0x19e74,
    0x18e32,
    0x1bef4,
  ],
  <int>[
    0x1f560,
    0x1fab8,
    0x1ea40,
    0x1f530,
    0x1fa9c,
    0x1ea20,
    0x1f518,
    0x1fa8e,
    0x1ea10,
    0x1f50c,
    0x1ea08,
    0x1f506,
    0x1ea04,
    0x1eb60,
    0x1f5b8,
    0x1fade,
    0x1d640,
    0x1eb30,
    0x1f59c,
    0x1d620,
    0x1eb18,
    0x1f58e,
    0x1d610,
    0x1eb0c,
    0x1d608,
    0x1eb06,
    0x1d604,
    0x1d760,
    0x1ebb8,
    0x1f5de,
    0x1ae40,
    0x1d730,
    0x1eb9c,
    0x1ae20,
    0x1d718,
    0x1eb8e,
    0x1ae10,
    0x1d70c,
    0x1ae08,
    0x1d706,
    0x1ae04,
    0x1af60,
    0x1d7b8,
    0x1ebde,
    0x15e40,
    0x1af30,
    0x1d79c,
    0x15e20,
    0x1af18,
    0x1d78e,
    0x15e10,
    0x1af0c,
    0x15e08,
    0x1af06,
    0x15f60,
    0x1afb8,
    0x1d7de,
    0x15f30,
    0x1af9c,
    0x15f18,
    0x1af8e,
    0x15f0c,
    0x15fb8,
    0x1afde,
    0x15f9c,
    0x15f8e,
    0x1e940,
    0x1f4b0,
    0x1fa5c,
    0x1e920,
    0x1f498,
    0x1fa4e,
    0x1e910,
    0x1f48c,
    0x1e908,
    0x1f486,
    0x1e904,
    0x1e902,
    0x1d340,
    0x1e9b0,
    0x1f4dc,
    0x1d320,
    0x1e998,
    0x1f4ce,
    0x1d310,
    0x1e98c,
    0x1d308,
    0x1e986,
    0x1d304,
    0x1d302,
    0x1a740,
    0x1d3b0,
    0x1e9dc,
    0x1a720,
    0x1d398,
    0x1e9ce,
    0x1a710,
    0x1d38c,
    0x1a708,
    0x1d386,
    0x1a704,
    0x1a702,
    0x14f40,
    0x1a7b0,
    0x1d3dc,
    0x14f20,
    0x1a798,
    0x1d3ce,
    0x14f10,
    0x1a78c,
    0x14f08,
    0x1a786,
    0x14f04,
    0x14fb0,
    0x1a7dc,
    0x14f98,
    0x1a7ce,
    0x14f8c,
    0x14f86,
    0x14fdc,
    0x14fce,
    0x1e8a0,
    0x1f458,
    0x1fa2e,
    0x1e890,
    0x1f44c,
    0x1e888,
    0x1f446,
    0x1e884,
    0x1e882,
    0x1d1a0,
    0x1e8d8,
    0x1f46e,
    0x1d190,
    0x1e8cc,
    0x1d188,
    0x1e8c6,
    0x1d184,
    0x1d182,
    0x1a3a0,
    0x1d1d8,
    0x1e8ee,
    0x1a390,
    0x1d1cc,
    0x1a388,
    0x1d1c6,
    0x1a384,
    0x1a382,
    0x147a0,
    0x1a3d8,
    0x1d1ee,
    0x14790,
    0x1a3cc,
    0x14788,
    0x1a3c6,
    0x14784,
    0x14782,
    0x147d8,
    0x1a3ee,
    0x147cc,
    0x147c6,
    0x147ee,
    0x1e850,
    0x1f42c,
    0x1e848,
    0x1f426,
    0x1e844,
    0x1e842,
    0x1d0d0,
    0x1e86c,
    0x1d0c8,
    0x1e866,
    0x1d0c4,
    0x1d0c2,
    0x1a1d0,
    0x1d0ec,
    0x1a1c8,
    0x1d0e6,
    0x1a1c4,
    0x1a1c2,
    0x143d0,
    0x1a1ec,
    0x143c8,
    0x1a1e6,
    0x143c4,
    0x143c2,
    0x143ec,
    0x143e6,
    0x1e828,
    0x1f416,
    0x1e824,
    0x1e822,
    0x1d068,
    0x1e836,
    0x1d064,
    0x1d062,
    0x1a0e8,
    0x1d076,
    0x1a0e4,
    0x1a0e2,
    0x141e8,
    0x1a0f6,
    0x141e4,
    0x141e2,
    0x1e814,
    0x1e812,
    0x1d034,
    0x1d032,
    0x1a074,
    0x1a072,
    0x1e540,
    0x1f2b0,
    0x1f95c,
    0x1e520,
    0x1f298,
    0x1f94e,
    0x1e510,
    0x1f28c,
    0x1e508,
    0x1f286,
    0x1e504,
    0x1e502,
    0x1cb40,
    0x1e5b0,
    0x1f2dc,
    0x1cb20,
    0x1e598,
    0x1f2ce,
    0x1cb10,
    0x1e58c,
    0x1cb08,
    0x1e586,
    0x1cb04,
    0x1cb02,
    0x19740,
    0x1cbb0,
    0x1e5dc,
    0x19720,
    0x1cb98,
    0x1e5ce,
    0x19710,
    0x1cb8c,
    0x19708,
    0x1cb86,
    0x19704,
    0x19702,
    0x12f40,
    0x197b0,
    0x1cbdc,
    0x12f20,
    0x19798,
    0x1cbce,
    0x12f10,
    0x1978c,
    0x12f08,
    0x19786,
    0x12f04,
    0x12fb0,
    0x197dc,
    0x12f98,
    0x197ce,
    0x12f8c,
    0x12f86,
    0x12fdc,
    0x12fce,
    0x1f6a0,
    0x1fb58,
    0x16bf0,
    0x1f690,
    0x1fb4c,
    0x169f8,
    0x1f688,
    0x1fb46,
    0x168fc,
    0x1f684,
    0x1f682,
    0x1e4a0,
    0x1f258,
    0x1f92e,
    0x1eda0,
    0x1e490,
    0x1fb6e,
    0x1ed90,
    0x1f6cc,
    0x1f246,
    0x1ed88,
    0x1e484,
    0x1ed84,
    0x1e482,
    0x1ed82,
    0x1c9a0,
    0x1e4d8,
    0x1f26e,
    0x1dba0,
    0x1c990,
    0x1e4cc,
    0x1db90,
    0x1edcc,
    0x1e4c6,
    0x1db88,
    0x1c984,
    0x1db84,
    0x1c982,
    0x1db82,
    0x193a0,
    0x1c9d8,
    0x1e4ee,
    0x1b7a0,
    0x19390,
    0x1c9cc,
    0x1b790,
    0x1dbcc,
    0x1c9c6,
    0x1b788,
    0x19384,
    0x1b784,
    0x19382,
    0x1b782,
    0x127a0,
    0x193d8,
    0x1c9ee,
    0x16fa0,
    0x12790,
    0x193cc,
    0x16f90,
    0x1b7cc,
    0x193c6,
    0x16f88,
    0x12784,
    0x16f84,
    0x12782,
    0x127d8,
    0x193ee,
    0x16fd8,
    0x127cc,
    0x16fcc,
    0x127c6,
    0x16fc6,
    0x127ee,
    0x1f650,
    0x1fb2c,
    0x165f8,
    0x1f648,
    0x1fb26,
    0x164fc,
    0x1f644,
    0x1647e,
    0x1f642,
    0x1e450,
    0x1f22c,
    0x1ecd0,
    0x1e448,
    0x1f226,
    0x1ecc8,
    0x1f666,
    0x1ecc4,
    0x1e442,
    0x1ecc2,
    0x1c8d0,
    0x1e46c,
    0x1d9d0,
    0x1c8c8,
    0x1e466,
    0x1d9c8,
    0x1ece6,
    0x1d9c4,
    0x1c8c2,
    0x1d9c2,
    0x191d0,
    0x1c8ec,
    0x1b3d0,
    0x191c8,
    0x1c8e6,
    0x1b3c8,
    0x1d9e6,
    0x1b3c4,
    0x191c2,
    0x1b3c2,
    0x123d0,
    0x191ec,
    0x167d0,
    0x123c8,
    0x191e6,
    0x167c8,
    0x1b3e6,
    0x167c4,
    0x123c2,
    0x167c2,
    0x123ec,
    0x167ec,
    0x123e6,
    0x167e6,
    0x1f628,
    0x1fb16,
    0x162fc,
    0x1f624,
    0x1627e,
    0x1f622,
    0x1e428,
    0x1f216,
    0x1ec68,
    0x1f636,
    0x1ec64,
    0x1e422,
    0x1ec62,
    0x1c868,
    0x1e436,
    0x1d8e8,
    0x1c864,
    0x1d8e4,
    0x1c862,
    0x1d8e2,
    0x190e8,
    0x1c876,
    0x1b1e8,
    0x1d8f6,
    0x1b1e4,
    0x190e2,
    0x1b1e2,
    0x121e8,
    0x190f6,
    0x163e8,
    0x121e4,
    0x163e4,
    0x121e2,
    0x163e2,
    0x121f6,
    0x163f6,
    0x1f614,
    0x1617e,
    0x1f612,
    0x1e414,
    0x1ec34,
    0x1e412,
    0x1ec32,
    0x1c834,
    0x1d874,
    0x1c832,
    0x1d872,
    0x19074,
    0x1b0f4,
    0x19072,
    0x1b0f2,
    0x120f4,
    0x161f4,
    0x120f2,
    0x161f2,
    0x1f60a,
    0x1e40a,
    0x1ec1a,
    0x1c81a,
    0x1d83a,
    0x1903a,
    0x1b07a,
    0x1e2a0,
    0x1f158,
    0x1f8ae,
    0x1e290,
    0x1f14c,
    0x1e288,
    0x1f146,
    0x1e284,
    0x1e282,
    0x1c5a0,
    0x1e2d8,
    0x1f16e,
    0x1c590,
    0x1e2cc,
    0x1c588,
    0x1e2c6,
    0x1c584,
    0x1c582,
    0x18ba0,
    0x1c5d8,
    0x1e2ee,
    0x18b90,
    0x1c5cc,
    0x18b88,
    0x1c5c6,
    0x18b84,
    0x18b82,
    0x117a0,
    0x18bd8,
    0x1c5ee,
    0x11790,
    0x18bcc,
    0x11788,
    0x18bc6,
    0x11784,
    0x11782,
    0x117d8,
    0x18bee,
    0x117cc,
    0x117c6,
    0x117ee,
    0x1f350,
    0x1f9ac,
    0x135f8,
    0x1f348,
    0x1f9a6,
    0x134fc,
    0x1f344,
    0x1347e,
    0x1f342,
    0x1e250,
    0x1f12c,
    0x1e6d0,
    0x1e248,
    0x1f126,
    0x1e6c8,
    0x1f366,
    0x1e6c4,
    0x1e242,
    0x1e6c2,
    0x1c4d0,
    0x1e26c,
    0x1cdd0,
    0x1c4c8,
    0x1e266,
    0x1cdc8,
    0x1e6e6,
    0x1cdc4,
    0x1c4c2,
    0x1cdc2,
    0x189d0,
    0x1c4ec,
    0x19bd0,
    0x189c8,
    0x1c4e6,
    0x19bc8,
    0x1cde6,
    0x19bc4,
    0x189c2,
    0x19bc2,
    0x113d0,
    0x189ec,
    0x137d0,
    0x113c8,
    0x189e6,
    0x137c8,
    0x19be6,
    0x137c4,
    0x113c2,
    0x137c2,
    0x113ec,
    0x137ec,
    0x113e6,
    0x137e6,
    0x1fba8,
    0x175f0,
    0x1bafc,
    0x1fba4,
    0x174f8,
    0x1ba7e,
    0x1fba2,
    0x1747c,
    0x1743e,
    0x1f328,
    0x1f996,
    0x132fc,
    0x1f768,
    0x1fbb6,
    0x176fc,
    0x1327e,
    0x1f764,
    0x1f322,
    0x1767e,
    0x1f762,
    0x1e228,
    0x1f116,
    0x1e668,
    0x1e224,
    0x1eee8,
    0x1f776,
    0x1e222,
    0x1eee4,
    0x1e662,
    0x1eee2,
    0x1c468,
    0x1e236,
    0x1cce8,
    0x1c464,
    0x1dde8,
    0x1cce4,
    0x1c462,
    0x1dde4,
    0x1cce2,
    0x1dde2,
    0x188e8,
    0x1c476,
    0x199e8,
    0x188e4,
    0x1bbe8,
    0x199e4,
    0x188e2,
    0x1bbe4,
    0x199e2,
    0x1bbe2,
    0x111e8,
    0x188f6,
    0x133e8,
    0x111e4,
    0x177e8,
    0x133e4,
    0x111e2,
    0x177e4,
    0x133e2,
    0x177e2,
    0x111f6,
    0x133f6,
    0x1fb94,
    0x172f8,
    0x1b97e,
    0x1fb92,
    0x1727c,
    0x1723e,
    0x1f314,
    0x1317e,
    0x1f734,
    0x1f312,
    0x1737e,
    0x1f732,
    0x1e214,
    0x1e634,
    0x1e212,
    0x1ee74,
    0x1e632,
    0x1ee72,
    0x1c434,
    0x1cc74,
    0x1c432,
    0x1dcf4,
    0x1cc72,
    0x1dcf2,
    0x18874,
    0x198f4,
    0x18872,
    0x1b9f4,
    0x198f2,
    0x1b9f2,
    0x110f4,
    0x131f4,
    0x110f2,
    0x173f4,
    0x131f2,
    0x173f2,
    0x1fb8a,
    0x1717c,
    0x1713e,
    0x1f30a,
    0x1f71a,
    0x1e20a,
    0x1e61a,
    0x1ee3a,
    0x1c41a,
    0x1cc3a,
    0x1dc7a,
    0x1883a,
    0x1987a,
    0x1b8fa,
    0x1107a,
    0x130fa,
    0x171fa,
    0x170be,
    0x1e150,
    0x1f0ac,
    0x1e148,
    0x1f0a6,
    0x1e144,
    0x1e142,
    0x1c2d0,
    0x1e16c,
    0x1c2c8,
    0x1e166,
    0x1c2c4,
    0x1c2c2,
    0x185d0,
    0x1c2ec,
    0x185c8,
    0x1c2e6,
    0x185c4,
    0x185c2,
    0x10bd0,
    0x185ec,
    0x10bc8,
    0x185e6,
    0x10bc4,
    0x10bc2,
    0x10bec,
    0x10be6,
    0x1f1a8,
    0x1f8d6,
    0x11afc,
    0x1f1a4,
    0x11a7e,
    0x1f1a2,
    0x1e128,
    0x1f096,
    0x1e368,
    0x1e124,
    0x1e364,
    0x1e122,
    0x1e362,
    0x1c268,
    0x1e136,
    0x1c6e8,
    0x1c264,
    0x1c6e4,
    0x1c262,
    0x1c6e2,
    0x184e8,
    0x1c276,
    0x18de8,
    0x184e4,
    0x18de4,
    0x184e2,
    0x18de2,
    0x109e8,
    0x184f6,
    0x11be8,
    0x109e4,
    0x11be4,
    0x109e2,
    0x11be2,
    0x109f6,
    0x11bf6,
    0x1f9d4,
    0x13af8,
    0x19d7e,
    0x1f9d2,
    0x13a7c,
    0x13a3e,
    0x1f194,
    0x1197e,
    0x1f3b4,
    0x1f192,
    0x13b7e,
    0x1f3b2,
    0x1e114,
    0x1e334,
    0x1e112,
    0x1e774,
    0x1e332,
    0x1e772,
    0x1c234,
    0x1c674,
    0x1c232,
    0x1cef4,
    0x1c672,
    0x1cef2,
    0x18474,
    0x18cf4,
    0x18472,
    0x19df4,
    0x18cf2,
    0x19df2,
    0x108f4,
    0x119f4,
    0x108f2,
    0x13bf4,
    0x119f2,
    0x13bf2,
    0x17af0,
    0x1bd7c,
    0x17a78,
    0x1bd3e,
    0x17a3c,
    0x17a1e,
    0x1f9ca,
    0x1397c,
    0x1fbda,
    0x17b7c,
    0x1393e,
    0x17b3e,
    0x1f18a,
    0x1f39a,
    0x1f7ba,
    0x1e10a,
    0x1e31a,
    0x1e73a,
    0x1ef7a,
    0x1c21a,
    0x1c63a,
    0x1ce7a,
    0x1defa,
    0x1843a,
    0x18c7a,
    0x19cfa,
    0x1bdfa,
    0x1087a,
    0x118fa,
    0x139fa,
    0x17978,
    0x1bcbe,
    0x1793c,
    0x1791e,
    0x138be,
    0x179be,
    0x178bc,
    0x1789e,
    0x1785e,
    0x1e0a8,
    0x1e0a4,
    0x1e0a2,
    0x1c168,
    0x1e0b6,
    0x1c164,
    0x1c162,
    0x182e8,
    0x1c176,
    0x182e4,
    0x182e2,
    0x105e8,
    0x182f6,
    0x105e4,
    0x105e2,
    0x105f6,
    0x1f0d4,
    0x10d7e,
    0x1f0d2,
    0x1e094,
    0x1e1b4,
    0x1e092,
    0x1e1b2,
    0x1c134,
    0x1c374,
    0x1c132,
    0x1c372,
    0x18274,
    0x186f4,
    0x18272,
    0x186f2,
    0x104f4,
    0x10df4,
    0x104f2,
    0x10df2,
    0x1f8ea,
    0x11d7c,
    0x11d3e,
    0x1f0ca,
    0x1f1da,
    0x1e08a,
    0x1e19a,
    0x1e3ba,
    0x1c11a,
    0x1c33a,
    0x1c77a,
    0x1823a,
    0x1867a,
    0x18efa,
    0x1047a,
    0x10cfa,
    0x11dfa,
    0x13d78,
    0x19ebe,
    0x13d3c,
    0x13d1e,
    0x11cbe,
    0x13dbe,
    0x17d70,
    0x1bebc,
    0x17d38,
    0x1be9e,
    0x17d1c,
    0x17d0e,
    0x13cbc,
    0x17dbc,
    0x13c9e,
    0x17d9e,
    0x17cb8,
    0x1be5e,
    0x17c9c,
    0x17c8e,
    0x13c5e,
    0x17cde,
    0x17c5c,
    0x17c4e,
    0x17c2e,
    0x1c0b4,
    0x1c0b2,
    0x18174,
    0x18172,
    0x102f4,
    0x102f2,
    0x1e0da,
    0x1c09a,
    0x1c1ba,
    0x1813a,
    0x1837a,
    0x1027a,
    0x106fa,
    0x10ebe,
    0x11ebc,
    0x11e9e,
    0x13eb8,
    0x19f5e,
    0x13e9c,
    0x13e8e,
    0x11e5e,
    0x13ede,
    0x17eb0,
    0x1bf5c,
    0x17e98,
    0x1bf4e,
    0x17e8c,
    0x17e86,
    0x13e5c,
    0x17edc,
    0x13e4e,
    0x17ece,
    0x17e58,
    0x1bf2e,
    0x17e4c,
    0x17e46,
    0x13e2e,
    0x17e6e,
    0x17e2c,
    0x17e26,
    0x10f5e,
    0x11f5c,
    0x11f4e,
    0x13f58,
    0x19fae,
    0x13f4c,
    0x13f46,
    0x11f2e,
    0x13f6e,
    0x13f2c,
    0x13f26,
  ],
  <int>[
    0x1abe0,
    0x1d5f8,
    0x153c0,
    0x1a9f0,
    0x1d4fc,
    0x151e0,
    0x1a8f8,
    0x1d47e,
    0x150f0,
    0x1a87c,
    0x15078,
    0x1fad0,
    0x15be0,
    0x1adf8,
    0x1fac8,
    0x159f0,
    0x1acfc,
    0x1fac4,
    0x158f8,
    0x1ac7e,
    0x1fac2,
    0x1587c,
    0x1f5d0,
    0x1faec,
    0x15df8,
    0x1f5c8,
    0x1fae6,
    0x15cfc,
    0x1f5c4,
    0x15c7e,
    0x1f5c2,
    0x1ebd0,
    0x1f5ec,
    0x1ebc8,
    0x1f5e6,
    0x1ebc4,
    0x1ebc2,
    0x1d7d0,
    0x1ebec,
    0x1d7c8,
    0x1ebe6,
    0x1d7c4,
    0x1d7c2,
    0x1afd0,
    0x1d7ec,
    0x1afc8,
    0x1d7e6,
    0x1afc4,
    0x14bc0,
    0x1a5f0,
    0x1d2fc,
    0x149e0,
    0x1a4f8,
    0x1d27e,
    0x148f0,
    0x1a47c,
    0x14878,
    0x1a43e,
    0x1483c,
    0x1fa68,
    0x14df0,
    0x1a6fc,
    0x1fa64,
    0x14cf8,
    0x1a67e,
    0x1fa62,
    0x14c7c,
    0x14c3e,
    0x1f4e8,
    0x1fa76,
    0x14efc,
    0x1f4e4,
    0x14e7e,
    0x1f4e2,
    0x1e9e8,
    0x1f4f6,
    0x1e9e4,
    0x1e9e2,
    0x1d3e8,
    0x1e9f6,
    0x1d3e4,
    0x1d3e2,
    0x1a7e8,
    0x1d3f6,
    0x1a7e4,
    0x1a7e2,
    0x145e0,
    0x1a2f8,
    0x1d17e,
    0x144f0,
    0x1a27c,
    0x14478,
    0x1a23e,
    0x1443c,
    0x1441e,
    0x1fa34,
    0x146f8,
    0x1a37e,
    0x1fa32,
    0x1467c,
    0x1463e,
    0x1f474,
    0x1477e,
    0x1f472,
    0x1e8f4,
    0x1e8f2,
    0x1d1f4,
    0x1d1f2,
    0x1a3f4,
    0x1a3f2,
    0x142f0,
    0x1a17c,
    0x14278,
    0x1a13e,
    0x1423c,
    0x1421e,
    0x1fa1a,
    0x1437c,
    0x1433e,
    0x1f43a,
    0x1e87a,
    0x1d0fa,
    0x14178,
    0x1a0be,
    0x1413c,
    0x1411e,
    0x141be,
    0x140bc,
    0x1409e,
    0x12bc0,
    0x195f0,
    0x1cafc,
    0x129e0,
    0x194f8,
    0x1ca7e,
    0x128f0,
    0x1947c,
    0x12878,
    0x1943e,
    0x1283c,
    0x1f968,
    0x12df0,
    0x196fc,
    0x1f964,
    0x12cf8,
    0x1967e,
    0x1f962,
    0x12c7c,
    0x12c3e,
    0x1f2e8,
    0x1f976,
    0x12efc,
    0x1f2e4,
    0x12e7e,
    0x1f2e2,
    0x1e5e8,
    0x1f2f6,
    0x1e5e4,
    0x1e5e2,
    0x1cbe8,
    0x1e5f6,
    0x1cbe4,
    0x1cbe2,
    0x197e8,
    0x1cbf6,
    0x197e4,
    0x197e2,
    0x1b5e0,
    0x1daf8,
    0x1ed7e,
    0x169c0,
    0x1b4f0,
    0x1da7c,
    0x168e0,
    0x1b478,
    0x1da3e,
    0x16870,
    0x1b43c,
    0x16838,
    0x1b41e,
    0x1681c,
    0x125e0,
    0x192f8,
    0x1c97e,
    0x16de0,
    0x124f0,
    0x1927c,
    0x16cf0,
    0x1b67c,
    0x1923e,
    0x16c78,
    0x1243c,
    0x16c3c,
    0x1241e,
    0x16c1e,
    0x1f934,
    0x126f8,
    0x1937e,
    0x1fb74,
    0x1f932,
    0x16ef8,
    0x1267c,
    0x1fb72,
    0x16e7c,
    0x1263e,
    0x16e3e,
    0x1f274,
    0x1277e,
    0x1f6f4,
    0x1f272,
    0x16f7e,
    0x1f6f2,
    0x1e4f4,
    0x1edf4,
    0x1e4f2,
    0x1edf2,
    0x1c9f4,
    0x1dbf4,
    0x1c9f2,
    0x1dbf2,
    0x193f4,
    0x193f2,
    0x165c0,
    0x1b2f0,
    0x1d97c,
    0x164e0,
    0x1b278,
    0x1d93e,
    0x16470,
    0x1b23c,
    0x16438,
    0x1b21e,
    0x1641c,
    0x1640e,
    0x122f0,
    0x1917c,
    0x166f0,
    0x12278,
    0x1913e,
    0x16678,
    0x1b33e,
    0x1663c,
    0x1221e,
    0x1661e,
    0x1f91a,
    0x1237c,
    0x1fb3a,
    0x1677c,
    0x1233e,
    0x1673e,
    0x1f23a,
    0x1f67a,
    0x1e47a,
    0x1ecfa,
    0x1c8fa,
    0x1d9fa,
    0x191fa,
    0x162e0,
    0x1b178,
    0x1d8be,
    0x16270,
    0x1b13c,
    0x16238,
    0x1b11e,
    0x1621c,
    0x1620e,
    0x12178,
    0x190be,
    0x16378,
    0x1213c,
    0x1633c,
    0x1211e,
    0x1631e,
    0x121be,
    0x163be,
    0x16170,
    0x1b0bc,
    0x16138,
    0x1b09e,
    0x1611c,
    0x1610e,
    0x120bc,
    0x161bc,
    0x1209e,
    0x1619e,
    0x160b8,
    0x1b05e,
    0x1609c,
    0x1608e,
    0x1205e,
    0x160de,
    0x1605c,
    0x1604e,
    0x115e0,
    0x18af8,
    0x1c57e,
    0x114f0,
    0x18a7c,
    0x11478,
    0x18a3e,
    0x1143c,
    0x1141e,
    0x1f8b4,
    0x116f8,
    0x18b7e,
    0x1f8b2,
    0x1167c,
    0x1163e,
    0x1f174,
    0x1177e,
    0x1f172,
    0x1e2f4,
    0x1e2f2,
    0x1c5f4,
    0x1c5f2,
    0x18bf4,
    0x18bf2,
    0x135c0,
    0x19af0,
    0x1cd7c,
    0x134e0,
    0x19a78,
    0x1cd3e,
    0x13470,
    0x19a3c,
    0x13438,
    0x19a1e,
    0x1341c,
    0x1340e,
    0x112f0,
    0x1897c,
    0x136f0,
    0x11278,
    0x1893e,
    0x13678,
    0x19b3e,
    0x1363c,
    0x1121e,
    0x1361e,
    0x1f89a,
    0x1137c,
    0x1f9ba,
    0x1377c,
    0x1133e,
    0x1373e,
    0x1f13a,
    0x1f37a,
    0x1e27a,
    0x1e6fa,
    0x1c4fa,
    0x1cdfa,
    0x189fa,
    0x1bae0,
    0x1dd78,
    0x1eebe,
    0x174c0,
    0x1ba70,
    0x1dd3c,
    0x17460,
    0x1ba38,
    0x1dd1e,
    0x17430,
    0x1ba1c,
    0x17418,
    0x1ba0e,
    0x1740c,
    0x132e0,
    0x19978,
    0x1ccbe,
    0x176e0,
    0x13270,
    0x1993c,
    0x17670,
    0x1bb3c,
    0x1991e,
    0x17638,
    0x1321c,
    0x1761c,
    0x1320e,
    0x1760e,
    0x11178,
    0x188be,
    0x13378,
    0x1113c,
    0x17778,
    0x1333c,
    0x1111e,
    0x1773c,
    0x1331e,
    0x1771e,
    0x111be,
    0x133be,
    0x177be,
    0x172c0,
    0x1b970,
    0x1dcbc,
    0x17260,
    0x1b938,
    0x1dc9e,
    0x17230,
    0x1b91c,
    0x17218,
    0x1b90e,
    0x1720c,
    0x17206,
    0x13170,
    0x198bc,
    0x17370,
    0x13138,
    0x1989e,
    0x17338,
    0x1b99e,
    0x1731c,
    0x1310e,
    0x1730e,
    0x110bc,
    0x131bc,
    0x1109e,
    0x173bc,
    0x1319e,
    0x1739e,
    0x17160,
    0x1b8b8,
    0x1dc5e,
    0x17130,
    0x1b89c,
    0x17118,
    0x1b88e,
    0x1710c,
    0x17106,
    0x130b8,
    0x1985e,
    0x171b8,
    0x1309c,
    0x1719c,
    0x1308e,
    0x1718e,
    0x1105e,
    0x130de,
    0x171de,
    0x170b0,
    0x1b85c,
    0x17098,
    0x1b84e,
    0x1708c,
    0x17086,
    0x1305c,
    0x170dc,
    0x1304e,
    0x170ce,
    0x17058,
    0x1b82e,
    0x1704c,
    0x17046,
    0x1302e,
    0x1706e,
    0x1702c,
    0x17026,
    0x10af0,
    0x1857c,
    0x10a78,
    0x1853e,
    0x10a3c,
    0x10a1e,
    0x10b7c,
    0x10b3e,
    0x1f0ba,
    0x1e17a,
    0x1c2fa,
    0x185fa,
    0x11ae0,
    0x18d78,
    0x1c6be,
    0x11a70,
    0x18d3c,
    0x11a38,
    0x18d1e,
    0x11a1c,
    0x11a0e,
    0x10978,
    0x184be,
    0x11b78,
    0x1093c,
    0x11b3c,
    0x1091e,
    0x11b1e,
    0x109be,
    0x11bbe,
    0x13ac0,
    0x19d70,
    0x1cebc,
    0x13a60,
    0x19d38,
    0x1ce9e,
    0x13a30,
    0x19d1c,
    0x13a18,
    0x19d0e,
    0x13a0c,
    0x13a06,
    0x11970,
    0x18cbc,
    0x13b70,
    0x11938,
    0x18c9e,
    0x13b38,
    0x1191c,
    0x13b1c,
    0x1190e,
    0x13b0e,
    0x108bc,
    0x119bc,
    0x1089e,
    0x13bbc,
    0x1199e,
    0x13b9e,
    0x1bd60,
    0x1deb8,
    0x1ef5e,
    0x17a40,
    0x1bd30,
    0x1de9c,
    0x17a20,
    0x1bd18,
    0x1de8e,
    0x17a10,
    0x1bd0c,
    0x17a08,
    0x1bd06,
    0x17a04,
    0x13960,
    0x19cb8,
    0x1ce5e,
    0x17b60,
    0x13930,
    0x19c9c,
    0x17b30,
    0x1bd9c,
    0x19c8e,
    0x17b18,
    0x1390c,
    0x17b0c,
    0x13906,
    0x17b06,
    0x118b8,
    0x18c5e,
    0x139b8,
    0x1189c,
    0x17bb8,
    0x1399c,
    0x1188e,
    0x17b9c,
    0x1398e,
    0x17b8e,
    0x1085e,
    0x118de,
    0x139de,
    0x17bde,
    0x17940,
    0x1bcb0,
    0x1de5c,
    0x17920,
    0x1bc98,
    0x1de4e,
    0x17910,
    0x1bc8c,
    0x17908,
    0x1bc86,
    0x17904,
    0x17902,
    0x138b0,
    0x19c5c,
    0x179b0,
    0x13898,
    0x19c4e,
    0x17998,
    0x1bcce,
    0x1798c,
    0x13886,
    0x17986,
    0x1185c,
    0x138dc,
    0x1184e,
    0x179dc,
    0x138ce,
    0x179ce,
    0x178a0,
    0x1bc58,
    0x1de2e,
    0x17890,
    0x1bc4c,
    0x17888,
    0x1bc46,
    0x17884,
    0x17882,
    0x13858,
    0x19c2e,
    0x178d8,
    0x1384c,
    0x178cc,
    0x13846,
    0x178c6,
    0x1182e,
    0x1386e,
    0x178ee,
    0x17850,
    0x1bc2c,
    0x17848,
    0x1bc26,
    0x17844,
    0x17842,
    0x1382c,
    0x1786c,
    0x13826,
    0x17866,
    0x17828,
    0x1bc16,
    0x17824,
    0x17822,
    0x13816,
    0x17836,
    0x10578,
    0x182be,
    0x1053c,
    0x1051e,
    0x105be,
    0x10d70,
    0x186bc,
    0x10d38,
    0x1869e,
    0x10d1c,
    0x10d0e,
    0x104bc,
    0x10dbc,
    0x1049e,
    0x10d9e,
    0x11d60,
    0x18eb8,
    0x1c75e,
    0x11d30,
    0x18e9c,
    0x11d18,
    0x18e8e,
    0x11d0c,
    0x11d06,
    0x10cb8,
    0x1865e,
    0x11db8,
    0x10c9c,
    0x11d9c,
    0x10c8e,
    0x11d8e,
    0x1045e,
    0x10cde,
    0x11dde,
    0x13d40,
    0x19eb0,
    0x1cf5c,
    0x13d20,
    0x19e98,
    0x1cf4e,
    0x13d10,
    0x19e8c,
    0x13d08,
    0x19e86,
    0x13d04,
    0x13d02,
    0x11cb0,
    0x18e5c,
    0x13db0,
    0x11c98,
    0x18e4e,
    0x13d98,
    0x19ece,
    0x13d8c,
    0x11c86,
    0x13d86,
    0x10c5c,
    0x11cdc,
    0x10c4e,
    0x13ddc,
    0x11cce,
    0x13dce,
    0x1bea0,
    0x1df58,
    0x1efae,
    0x1be90,
    0x1df4c,
    0x1be88,
    0x1df46,
    0x1be84,
    0x1be82,
    0x13ca0,
    0x19e58,
    0x1cf2e,
    0x17da0,
    0x13c90,
    0x19e4c,
    0x17d90,
    0x1becc,
    0x19e46,
    0x17d88,
    0x13c84,
    0x17d84,
    0x13c82,
    0x17d82,
    0x11c58,
    0x18e2e,
    0x13cd8,
    0x11c4c,
    0x17dd8,
    0x13ccc,
    0x11c46,
    0x17dcc,
    0x13cc6,
    0x17dc6,
    0x10c2e,
    0x11c6e,
    0x13cee,
    0x17dee,
    0x1be50,
    0x1df2c,
    0x1be48,
    0x1df26,
    0x1be44,
    0x1be42,
    0x13c50,
    0x19e2c,
    0x17cd0,
    0x13c48,
    0x19e26,
    0x17cc8,
    0x1be66,
    0x17cc4,
    0x13c42,
    0x17cc2,
    0x11c2c,
    0x13c6c,
    0x11c26,
    0x17cec,
    0x13c66,
    0x17ce6,
    0x1be28,
    0x1df16,
    0x1be24,
    0x1be22,
    0x13c28,
    0x19e16,
    0x17c68,
    0x13c24,
    0x17c64,
    0x13c22,
    0x17c62,
    0x11c16,
    0x13c36,
    0x17c76,
    0x1be14,
    0x1be12,
    0x13c14,
    0x17c34,
    0x13c12,
    0x17c32,
    0x102bc,
    0x1029e,
    0x106b8,
    0x1835e,
    0x1069c,
    0x1068e,
    0x1025e,
    0x106de,
    0x10eb0,
    0x1875c,
    0x10e98,
    0x1874e,
    0x10e8c,
    0x10e86,
    0x1065c,
    0x10edc,
    0x1064e,
    0x10ece,
    0x11ea0,
    0x18f58,
    0x1c7ae,
    0x11e90,
    0x18f4c,
    0x11e88,
    0x18f46,
    0x11e84,
    0x11e82,
    0x10e58,
    0x1872e,
    0x11ed8,
    0x18f6e,
    0x11ecc,
    0x10e46,
    0x11ec6,
    0x1062e,
    0x10e6e,
    0x11eee,
    0x19f50,
    0x1cfac,
    0x19f48,
    0x1cfa6,
    0x19f44,
    0x19f42,
    0x11e50,
    0x18f2c,
    0x13ed0,
    0x19f6c,
    0x18f26,
    0x13ec8,
    0x11e44,
    0x13ec4,
    0x11e42,
    0x13ec2,
    0x10e2c,
    0x11e6c,
    0x10e26,
    0x13eec,
    0x11e66,
    0x13ee6,
    0x1dfa8,
    0x1efd6,
    0x1dfa4,
    0x1dfa2,
    0x19f28,
    0x1cf96,
    0x1bf68,
    0x19f24,
    0x1bf64,
    0x19f22,
    0x1bf62,
    0x11e28,
    0x18f16,
    0x13e68,
    0x11e24,
    0x17ee8,
    0x13e64,
    0x11e22,
    0x17ee4,
    0x13e62,
    0x17ee2,
    0x10e16,
    0x11e36,
    0x13e76,
    0x17ef6,
    0x1df94,
    0x1df92,
    0x19f14,
    0x1bf34,
    0x19f12,
    0x1bf32,
    0x11e14,
    0x13e34,
    0x11e12,
    0x17e74,
    0x13e32,
    0x17e72,
    0x1df8a,
    0x19f0a,
    0x1bf1a,
    0x11e0a,
    0x13e1a,
    0x17e3a,
    0x1035c,
    0x1034e,
    0x10758,
    0x183ae,
    0x1074c,
    0x10746,
    0x1032e,
    0x1076e,
    0x10f50,
    0x187ac,
    0x10f48,
    0x187a6,
    0x10f44,
    0x10f42,
    0x1072c,
    0x10f6c,
    0x10726,
    0x10f66,
    0x18fa8,
    0x1c7d6,
    0x18fa4,
    0x18fa2,
    0x10f28,
    0x18796,
    0x11f68,
    0x18fb6,
    0x11f64,
    0x10f22,
    0x11f62,
    0x10716,
    0x10f36,
    0x11f76,
    0x1cfd4,
    0x1cfd2,
    0x18f94,
    0x19fb4,
    0x18f92,
    0x19fb2,
    0x10f14,
    0x11f34,
    0x10f12,
    0x13f74,
    0x11f32,
    0x13f72,
    0x1cfca,
    0x18f8a,
    0x19f9a,
    0x10f0a,
    0x11f1a,
    0x13f3a,
    0x103ac,
    0x103a6,
    0x107a8,
    0x183d6,
    0x107a4,
    0x107a2,
    0x10396,
    0x107b6,
    0x187d4,
    0x187d2,
    0x10794,
    0x10fb4,
    0x10792,
    0x10fb2,
    0x1c7ea,
  ],
];

const correctionFactors = <List<int>>[
  <int>[27, 917],

  <int>[522, 568, 723, 809],

  <int>[237, 308, 436, 284, 646, 653, 428, 379],

  <int>[
    274,
    562,
    232,
    755,
    599,
    524,
    801,
    132,
    295,
    116,
    442,
    428,
    295,
    42,
    176,
    65,
  ],

  <int>[
    361,
    575,
    922,
    525,
    176,
    586,
    640,
    321,
    536,
    742,
    677,
    742,
    687,
    284,
    193,
    517,
    273,
    494,
    263,
    147,
    593,
    800,
    571,
    320,
    803,
    133,
    231,
    390,
    685,
    330,
    63,
    410,
  ],

  <int>[
    539,
    422,
    6,
    93,
    862,
    771,
    453,
    106,
    610,
    287,
    107,
    505,
    733,
    877,
    381,
    612,
    723,
    476,
    462,
    172,
    430,
    609,
    858,
    822,
    543,
    376,
    511,
    400,
    672,
    762,
    283,
    184,
    440,
    35,
    519,
    31,
    460,
    594,
    225,
    535,
    517,
    352,
    605,
    158,
    651,
    201,
    488,
    502,
    648,
    733,
    717,
    83,
    404,
    97,
    280,
    771,
    840,
    629,
    4,
    381,
    843,
    623,
    264,
    543,
  ],

  <int>[
    521,
    310,
    864,
    547,
    858,
    580,
    296,
    379,
    53,
    779,
    897,
    444,
    400,
    925,
    749,
    415,
    822,
    93,
    217,
    208,
    928,
    244,
    583,
    620,
    246,
    148,
    447,
    631,
    292,
    908,
    490,
    704,
    516,
    258,
    457,
    907,
    594,
    723,
    674,
    292,
    272,
    96,
    684,
    432,
    686,
    606,
    860,
    569,
    193,
    219,
    129,
    186,
    236,
    287,
    192,
    775,
    278,
    173,
    40,
    379,
    712,
    463,
    646,
    776,
    171,
    491,
    297,
    763,
    156,
    732,
    95,
    270,
    447,
    90,
    507,
    48,
    228,
    821,
    808,
    898,
    784,
    663,
    627,
    378,
    382,
    262,
    380,
    602,
    754,
    336,
    89,
    614,
    87,
    432,
    670,
    616,
    157,
    374,
    242,
    726,
    600,
    269,
    375,
    898,
    845,
    454,
    354,
    130,
    814,
    587,
    804,
    34,
    211,
    330,
    539,
    297,
    827,
    865,
    37,
    517,
    834,
    315,
    550,
    86,
    801,
    4,
    108,
    539,
  ],

  <int>[
    524,
    894,
    75,
    766,
    882,
    857,
    74,
    204,
    82,
    586,
    708,
    250,
    905,
    786,
    138,
    720,
    858,
    194,
    311,
    913,
    275,
    190,
    375,
    850,
    438,
    733,
    194,
    280,
    201,
    280,
    828,
    757,
    710,
    814,
    919,
    89,
    68,
    569,
    11,
    204,
    796,
    605,
    540,
    913,
    801,
    700,
    799,
    137,
    439,
    418,
    592,
    668,
    353,
    859,
    370,
    694,
    325,
    240,
    216,
    257,
    284,
    549,
    209,
    884,
    315,
    70,
    329,
    793,
    490,
    274,
    877,
    162,
    749,
    812,
    684,
    461,
    334,
    376,
    849,
    521,
    307,
    291,
    803,
    712,
    19,
    358,
    399,
    908,
    103,
    511,
    51,
    8,
    517,
    225,
    289,
    470,
    637,
    731,
    66,
    255,
    917,
    269,
    463,
    830,
    730,
    433,
    848,
    585,
    136,
    538,
    906,
    90,
    2,
    290,
    743,
    199,
    655,
    903,
    329,
    49,
    802,
    580,
    355,
    588,
    188,
    462,
    10,
    134,
    628,
    320,
    479,
    130,
    739,
    71,
    263,
    318,
    374,
    601,
    192,
    605,
    142,
    673,
    687,
    234,
    722,
    384,
    177,
    752,
    607,
    640,
    455,
    193,
    689,
    707,
    805,
    641,
    48,
    60,
    732,
    621,
    895,
    544,
    261,
    852,
    655,
    309,
    697,
    755,
    756,
    60,
    231,
    773,
    434,
    421,
    726,
    528,
    503,
    118,
    49,
    795,
    32,
    144,
    500,
    238,
    836,
    394,
    280,
    566,
    319,
    9,
    647,
    550,
    73,
    914,
    342,
    126,
    32,
    681,
    331,
    792,
    620,
    60,
    609,
    441,
    180,
    791,
    893,
    754,
    605,
    383,
    228,
    749,
    760,
    213,
    54,
    297,
    134,
    54,
    834,
    299,
    922,
    191,
    910,
    532,
    609,
    829,
    189,
    20,
    167,
    29,
    872,
    449,
    83,
    402,
    41,
    656,
    505,
    579,
    481,
    173,
    404,
    251,
    688,
    95,
    497,
    555,
    642,
    543,
    307,
    159,
    924,
    558,
    648,
    55,
    497,
    10,
  ],

  <int>[
    352,
    77,
    373,
    504,
    35,
    599,
    428,
    207,
    409,
    574,
    118,
    498,
    285,
    380,
    350,
    492,
    197,
    265,
    920,
    155,
    914,
    299,
    229,
    643,
    294,
    871,
    306,
    88,
    87,
    193,
    352,
    781,
    846,
    75,
    327,
    520,
    435,
    543,
    203,
    666,
    249,
    346,
    781,
    621,
    640,
    268,
    794,
    534,
    539,
    781,
    408,
    390,
    644,
    102,
    476,
    499,
    290,
    632,
    545,
    37,
    858,
    916,
    552,
    41,
    542,
    289,
    122,
    272,
    383,
    800,
    485,
    98,
    752,
    472,
    761,
    107,
    784,
    860,
    658,
    741,
    290,
    204,
    681,
    407,
    855,
    85,
    99,
    62,
    482,
    180,
    20,
    297,
    451,
    593,
    913,
    142,
    808,
    684,
    287,
    536,
    561,
    76,
    653,
    899,
    729,
    567,
    744,
    390,
    513,
    192,
    516,
    258,
    240,
    518,
    794,
    395,
    768,
    848,
    51,
    610,
    384,
    168,
    190,
    826,
    328,
    596,
    786,
    303,
    570,
    381,
    415,
    641,
    156,
    237,
    151,
    429,
    531,
    207,
    676,
    710,
    89,
    168,
    304,
    402,
    40,
    708,
    575,
    162,
    864,
    229,
    65,
    861,
    841,
    512,
    164,
    477,
    221,
    92,
    358,
    785,
    288,
    357,
    850,
    836,
    827,
    736,
    707,
    94,
    8,
    494,
    114,
    521,
    2,
    499,
    851,
    543,
    152,
    729,
    771,
    95,
    248,
    361,
    578,
    323,
    856,
    797,
    289,
    51,
    684,
    466,
    533,
    820,
    669,
    45,
    902,
    452,
    167,
    342,
    244,
    173,
    35,
    463,
    651,
    51,
    699,
    591,
    452,
    578,
    37,
    124,
    298,
    332,
    552,
    43,
    427,
    119,
    662,
    777,
    475,
    850,
    764,
    364,
    578,
    911,
    283,
    711,
    472,
    420,
    245,
    288,
    594,
    394,
    511,
    327,
    589,
    777,
    699,
    688,
    43,
    408,
    842,
    383,
    721,
    521,
    560,
    644,
    714,
    559,
    62,
    145,
    873,
    663,
    713,
    159,
    672,
    729,
    624,
    59,
    193,
    417,
    158,
    209,
    563,
    564,
    343,
    693,
    109,
    608,
    563,
    365,
    181,
    772,
    677,
    310,
    248,
    353,
    708,
    410,
    579,
    870,
    617,
    841,
    632,
    860,
    289,
    536,
    35,
    777,
    618,
    586,
    424,
    833,
    77,
    597,
    346,
    269,
    757,
    632,
    695,
    751,
    331,
    247,
    184,
    45,
    787,
    680,
    18,
    66,
    407,
    369,
    54,
    492,
    228,
    613,
    830,
    922,
    437,
    519,
    644,
    905,
    789,
    420,
    305,
    441,
    207,
    300,
    892,
    827,
    141,
    537,
    381,
    662,
    513,
    56,
    252,
    341,
    242,
    797,
    838,
    837,
    720,
    224,
    307,
    631,
    61,
    87,
    560,
    310,
    756,
    665,
    397,
    808,
    851,
    309,
    473,
    795,
    378,
    31,
    647,
    915,
    459,
    806,
    590,
    731,
    425,
    216,
    548,
    249,
    321,
    881,
    699,
    535,
    673,
    782,
    210,
    815,
    905,
    303,
    843,
    922,
    281,
    73,
    469,
    791,
    660,
    162,
    498,
    308,
    155,
    422,
    907,
    817,
    187,
    62,
    16,
    425,
    535,
    336,
    286,
    437,
    375,
    273,
    610,
    296,
    183,
    923,
    116,
    667,
    751,
    353,
    62,
    366,
    691,
    379,
    687,
    842,
    37,
    357,
    720,
    742,
    330,
    5,
    39,
    923,
    311,
    424,
    242,
    749,
    321,
    54,
    669,
    316,
    342,
    299,
    534,
    105,
    667,
    488,
    640,
    672,
    576,
    540,
    316,
    486,
    721,
    610,
    46,
    656,
    447,
    171,
    616,
    464,
    190,
    531,
    297,
    321,
    762,
    752,
    533,
    175,
    134,
    14,
    381,
    433,
    717,
    45,
    111,
    20,
    596,
    284,
    736,
    138,
    646,
    411,
    877,
    669,
    141,
    919,
    45,
    780,
    407,
    164,
    332,
    899,
    165,
    726,
    600,
    325,
    498,
    655,
    357,
    752,
    768,
    223,
    849,
    647,
    63,
    310,
    863,
    251,
    366,
    304,
    282,
    738,
    675,
    410,
    389,
    244,
    31,
    121,
    303,
    263,
  ],
];

const latch_to_text = 900;
const latch_to_byte_padded = 901;
const latch_to_numeric = 902;
const latch_to_byte = 924;
const shift_to_byte = 913;

const min_numeric_count = 13;

const mixedMap = <int, int>{
  48: 0,
  49: 1,
  50: 2,
  51: 3,
  52: 4,
  53: 5,
  54: 6,
  55: 7,
  56: 8,
  57: 9,
  38: 10,
  13: 11,
  9: 12,
  44: 13,
  58: 14,
  35: 15,
  45: 16,
  46: 17,
  36: 18,
  47: 19,
  43: 20,
  37: 21,
  42: 22,
  61: 23,
  94: 24,
  32: 26,
};

const punctMap = <int, int>{
  59: 0,
  60: 1,
  62: 2,
  64: 3,
  91: 4,
  92: 5,
  93: 6,
  95: 7,
  96: 8,
  126: 9,
  33: 10,
  13: 11,
  9: 12,
  44: 13,
  58: 14,
  10: 15,
  45: 16,
  46: 17,
  36: 18,
  47: 19,
  34: 20,
  124: 21,
  42: 22,
  40: 23,
  41: 24,
  63: 25,
  123: 26,
  125: 27,
  39: 28,
};

final class QrPolynomial {
  final Uint8List _values;

  factory QrPolynomial(List<int> thing, int shift) {
    var offset = 0;

    while (offset < thing.length && thing[offset] == 0) {
      offset++;
    }

    final values = Uint8List(thing.length - offset + shift);

    for (var i = 0; i < thing.length - offset; i++) {
      values[i] = thing[i + offset];
    }

    return QrPolynomial._internal(values);
  }

  QrPolynomial._internal(this._values);

  int operator [](int index) => _values[index];

  int get length => _values.length;

  QrPolynomial multiply(QrPolynomial e) {
    final eLength = e.length;
    final valLength = length;
    final foo = Uint8List(valLength + eLength - 1);

    final eValues = e._values;

    for (var i = 0; i < valLength; i++) {
      final v1 = _values[i];
      if (v1 == 0) continue;
      final log1 = glog(v1);
      for (var j = 0; j < eLength; j++) {
        final v2 = eValues[j];
        if (v2 == 0) continue;
        foo[i + j] ^= gexp(log1 + glog(v2));
      }
    }

    return QrPolynomial._internal(foo);
  }

  QrPolynomial mod(QrPolynomial e) {
    final eLength = e.length;
    final valLength = length;
    if (valLength - eLength < 0) {
      return this;
    }

    final values = Uint8List.fromList(_values);
    final iterLimit = valLength - eLength + 1;

    final eValues = e._values;
    final e0Log = glog(eValues[0]);

    for (var i = 0; i < iterLimit; i++) {
      final v = values[i];
      if (v == 0) continue;

      final ratio = glog(v) - e0Log;

      for (var j = 0; j < eLength; j++) {
        final eVal = eValues[j];
        if (eVal == 0) continue;
        values[i + j] ^= gexp(glog(eVal) + ratio);
      }
    }

    return QrPolynomial(values.sublist(valLength - eLength + 1), 0);
  }
}

class BarcodePostnet extends BarcodeHM {
  const BarcodePostnet() : super(tracker: 0);

  @override
  Iterable<int> get charSet => [45, ...BarcodeMaps.postnet.keys];

  @override
  String get name => "POSTNET";

  @override
  Iterable<BarcodeHMBar> convertHM(String data) sync* {
    yield fromBits(BarcodeMaps.postnetStartStop);

    var sum = 0;
    for (final codeUnit in data.codeUnits) {
      if (codeUnit == 45) {
        continue;
      }
      final code = BarcodeMaps.postnet[codeUnit];
      if (code == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(codeUnit)}" to $name');
      }
      yield* addHW(code, BarcodeMaps.postnetLen);

      sum += codeUnit - 0x30;
    }

    final crc = (10 - (sum % 10)) % 10;
    yield* addHW(BarcodeMaps.postnet[crc + 0x30]!, BarcodeMaps.postnetLen);

    yield fromBits(BarcodeMaps.postnetStartStop);
  }
}

final class QrCode {
  final int typeNumber;
  final QrErrorCorrectLevel errorCorrectLevel;
  final int moduleCount;
  final QrPayload payload;
  List<int>? _dataCache;

  factory QrCode({
    required QrPayload payload,
    QrErrorCorrectLevel errorCorrectLevel = QrErrorCorrectLevel.medium,
    int minTypeNumber = 1,
  }) {
    final typeNumber = _calculateTypeNumberFromPayload(
      errorCorrectLevel,
      payload,
      minTypeNumber,
    );
    return QrCode._(typeNumber, errorCorrectLevel, payload);
  }

  QrCode._(this.typeNumber, this.errorCorrectLevel, this.payload) : moduleCount = typeNumber * 4 + 17;

  static int _calculateTypeNumberFromPayload(
    QrErrorCorrectLevel errorCorrectLevel,
    QrPayload payload,
    int minTypeNumber,
  ) {
    RangeError.checkValueInInterval(minTypeNumber, 1, 40, "minTypeNumber");

    final requiredBitsFor1 = payload.calculateRequiredBits(1);
    final requiredBitsFor10 = payload.calculateRequiredBits(10);
    final requiredBitsFor27 = payload.calculateRequiredBits(27);

    for (var typeNumber = minTypeNumber; typeNumber <= 40; typeNumber++) {
      final totalDataBits = QrRsBlock.getTotalDataBits(
        typeNumber,
        errorCorrectLevel,
      );

      final requiredBits = switch (typeNumber) {
        < 10 => requiredBitsFor1,
        < 27 => requiredBitsFor10,
        _ => requiredBitsFor27,
      };

      if (requiredBits <= totalDataBits) return typeNumber;
    }

    final maxBits = QrRsBlock.getTotalDataBits(40, errorCorrectLevel);
    throw createExp(requiredBitsFor27, maxBits);
  }
}

List<int> getDataCache(QrCode code) => code._dataCache ??= _createData(
  code.typeNumber,
  code.errorCorrectLevel,
  code.payload.dataList,
);

const int _pad0 = 0xEC;
const int _pad1 = 0x11;

List<int> _createData(
  int typeNumber,
  QrErrorCorrectLevel errorCorrectLevel,
  List<QrDatum> dataList,
) {
  final rsBlocks = QrRsBlock.getRSBlocks(typeNumber, errorCorrectLevel);

  var totalDataBits = 0;
  for (var rsBlock in rsBlocks) {
    totalDataBits += rsBlock.dataCount * 8;
  }

  final buffer = QrBitBuffer();

  for (var i = 0; i < dataList.length; i++) {
    final data = dataList[i];
    buffer
      ..put(data.mode.value, 4)
      ..put(data.length, data.mode.getLengthBits(typeNumber));
    data.write(buffer);
  }

  assert(buffer.length <= totalDataBits, "Buffer exceeded total data bits");

  if (buffer.length + 4 <= totalDataBits) {
    buffer.put(0, 4);
  }

  final paddingBits = 8 - (buffer.length % 8);
  if (paddingBits < 8) {
    buffer.put(0, paddingBits);
  }

  final bitDataCount = totalDataBits;
  var count = 0;
  for (;;) {
    if (buffer.length >= bitDataCount) {
      break;
    }
    buffer.put((count++).isEven ? _pad0 : _pad1, 8);
  }

  return _createBytes(buffer, rsBlocks);
}

List<int> _createBytes(QrBitBuffer buffer, List<QrRsBlock> rsBlocks) {
  var offset = 0;

  var maxDcCount = 0;
  var maxEcCount = 0;

  final dcData = List<List<int>?>.filled(rsBlocks.length, null);
  final ecData = List<List<int>?>.filled(rsBlocks.length, null);

  for (var r = 0; r < rsBlocks.length; r++) {
    final dcCount = rsBlocks[r].dataCount;
    final ecCount = rsBlocks[r].totalCount - dcCount;

    maxDcCount = math.max(maxDcCount, dcCount);
    maxEcCount = math.max(maxEcCount, ecCount);

    final dcItem = dcData[r] = buffer.getBytes(offset, dcCount);
    offset += dcCount;

    final rsPoly = _errorCorrectPolynomial(ecCount);
    final rawPoly = QrPolynomial(dcItem, rsPoly.length - 1);

    final modPoly = rawPoly.mod(rsPoly);
    final ecItem = ecData[r] = Uint8List(rsPoly.length - 1);

    for (var i = 0; i < ecItem.length; i++) {
      final modIndex = i + modPoly.length - ecItem.length;
      ecItem[i] = (modIndex >= 0) ? modPoly[modIndex] : 0;
    }
  }

  var totalCount = 0;
  for (var i = 0; i < rsBlocks.length; i++) {
    totalCount += rsBlocks[i].totalCount;
  }

  final data = Uint8List(totalCount);
  var dataPtr = 0;

  for (var i = 0; i < maxDcCount; i++) {
    for (var r = 0; r < rsBlocks.length; r++) {
      final dcItem = dcData[r]!;
      if (i < dcItem.length) {
        data[dataPtr++] = dcItem[i];
      }
    }
  }

  for (var i = 0; i < maxEcCount; i++) {
    for (var r = 0; r < rsBlocks.length; r++) {
      final ecItem = ecData[r]!;
      if (i < ecItem.length) {
        data[dataPtr++] = ecItem[i];
      }
    }
  }

  return data;
}

QrPolynomial _errorCorrectPolynomial(int errorCorrectLength) {
  var a = QrPolynomial([1], 0);

  for (var i = 0; i < errorCorrectLength; i++) {
    a = a.multiply(QrPolynomial([1, gexp(i)], 0));
  }

  return a;
}

final class QrImage {
  static const _pixelUnassigned = 0;
  static const _pixelLight = 1;
  static const _pixelDark = 2;

  final int moduleCount;
  final int typeNumber;
  final QrErrorCorrectLevel errorCorrectLevel;
  final int maskPattern;

  final Uint8List _data;

  factory QrImage(QrCode qrCode) {
    final template = QrImage._template(qrCode);
    final moduleCount = template.moduleCount;
    final dataSize = moduleCount * moduleCount;

    final dataMap = Uint8List(dataSize)..setRange(0, dataSize, template._data);

    QrImage._fromData(qrCode, 0, dataMap)._mapData(getDataCache(qrCode));

    final workingBuffer = Uint8List(dataSize);
    var minLostPoint = double.maxFinite;
    var bestMaskPattern = 0;
    Uint8List? bestData;

    for (var i = 0; i < 8; i++) {
      workingBuffer.setRange(0, dataSize, dataMap);

      final testImage = QrImage._fromData(qrCode, i, workingBuffer).._applyMask(i, template._data);

      final lostPoint = _lostPoint(testImage);

      if (lostPoint < minLostPoint) {
        minLostPoint = lostPoint;
        bestMaskPattern = i;

        bestData ??= Uint8List(dataSize);
        bestData.setRange(0, dataSize, workingBuffer);
      }
    }

    final finalImage = QrImage._fromData(qrCode, bestMaskPattern, bestData!).._setupTypeInfo(bestMaskPattern, false);
    if (finalImage.typeNumber >= 7) {
      finalImage._setupTypeNumber(false);
    }

    return finalImage;
  }

  QrImage.withMaskPattern(QrCode qrCode, this.maskPattern)
    : assert(maskPattern >= 0 && maskPattern <= 7),
      moduleCount = qrCode.moduleCount,
      typeNumber = qrCode.typeNumber,
      errorCorrectLevel = qrCode.errorCorrectLevel,
      _data = Uint8List(qrCode.moduleCount * qrCode.moduleCount) {
    _makeImpl(maskPattern, getDataCache(qrCode), false);
  }

  QrImage._template(QrCode qrCode)
    : moduleCount = qrCode.moduleCount,
      typeNumber = qrCode.typeNumber,
      errorCorrectLevel = qrCode.errorCorrectLevel,
      maskPattern = 0,

      _data = Uint8List(qrCode.moduleCount * qrCode.moduleCount) {
    _resetModules();
    _setupPositionProbePattern(0, 0);
    _setupPositionProbePattern(moduleCount - 7, 0);
    _setupPositionProbePattern(0, moduleCount - 7);
    _setupPositionAdjustPattern();
    _setupTimingPattern();

    _setupTypeInfo(0, true);
    if (typeNumber >= 7) {
      _setupTypeNumber(true);
    }
  }

  QrImage._fromData(QrCode qrCode, this.maskPattern, this._data) : moduleCount = qrCode.moduleCount, typeNumber = qrCode.typeNumber, errorCorrectLevel = qrCode.errorCorrectLevel;

  List<List<bool?>> get qrModules {
    final list = <List<bool?>>[];
    for (var r = 0; r < moduleCount; r++) {
      final row = List<bool?>.filled(moduleCount, null);
      for (var c = 0; c < moduleCount; c++) {
        final v = _data[r * moduleCount + c];
        row[c] = v == _pixelUnassigned ? null : (v == _pixelDark);
      }
      list.add(row);
    }
    return list;
  }

  void _resetModules() {
    _data.fillRange(0, _data.length, _pixelUnassigned);
  }

  bool isDark(int row, int col) {
    if (row < 0 || moduleCount <= row) {
      throw RangeError.range(row, 0, moduleCount - 1, "row");
    }
    if (col < 0 || moduleCount <= col) {
      throw RangeError.range(col, 0, moduleCount - 1, "col");
    }
    return _data[row * moduleCount + col] == _pixelDark;
  }

  void _set(int row, int col, bool value) {
    _data[row * moduleCount + col] = value ? _pixelDark : _pixelLight;
  }

  void _makeImpl(int maskPattern, List<int> dataCache, bool test) {
    _resetModules();
    _setupPositionProbePattern(0, 0);
    _setupPositionProbePattern(moduleCount - 7, 0);
    _setupPositionProbePattern(0, moduleCount - 7);
    _setupPositionAdjustPattern();
    _setupTimingPattern();
    _setupTypeInfo(maskPattern, test);

    if (typeNumber >= 7) {
      _setupTypeNumber(test);
    }

    _mapData(dataCache, maskPattern);
  }

  void _setupPositionProbePattern(int row, int col) {
    for (var r = -1; r <= 7; r++) {
      if (row + r <= -1 || moduleCount <= row + r) continue;

      for (var c = -1; c <= 7; c++) {
        if (col + c <= -1 || moduleCount <= col + c) continue;

        if ((0 <= r && r <= 6 && (c == 0 || c == 6)) || (0 <= c && c <= 6 && (r == 0 || r == 6)) || (2 <= r && r <= 4 && 2 <= c && c <= 4)) {
          _set(row + r, col + c, true);
        } else {
          _set(row + r, col + c, false);
        }
      }
    }
  }

  void _setupPositionAdjustPattern() {
    final pos = patternPosition(typeNumber);

    for (var i = 0; i < pos.length; i++) {
      for (var j = 0; j < pos.length; j++) {
        final row = pos[i];
        final col = pos[j];

        if (_data[row * moduleCount + col] != _pixelUnassigned) {
          continue;
        }

        for (var r = -2; r <= 2; r++) {
          for (var c = -2; c <= 2; c++) {
            if (r == -2 || r == 2 || c == -2 || c == 2 || (r == 0 && c == 0)) {
              _set(row + r, col + c, true);
            } else {
              _set(row + r, col + c, false);
            }
          }
        }
      }
    }
  }

  void _setupTimingPattern() {
    for (var r = 8; r < moduleCount - 8; r++) {
      if (_data[r * moduleCount + 6] != _pixelUnassigned) {
        continue;
      }
      _set(r, 6, r.isEven);
    }

    for (var c = 8; c < moduleCount - 8; c++) {
      if (_data[6 * moduleCount + c] != _pixelUnassigned) {
        continue;
      }
      _set(6, c, c.isEven);
    }
  }

  void _setupTypeInfo(int maskPattern, bool test) {
    final data = (errorCorrectLevel.index << 3) | maskPattern;
    final bits = bchTypeInfo(data);

    int i;
    bool mod;

    for (i = 0; i < 15; i++) {
      mod = !test && ((bits >> i) & 1) == 1;

      if (i < 6) {
        _set(i, 8, mod);
      } else if (i < 8) {
        _set(i + 1, 8, mod);
      } else {
        _set(moduleCount - 15 + i, 8, mod);
      }
    }

    for (i = 0; i < 15; i++) {
      mod = !test && ((bits >> i) & 1) == 1;

      if (i < 8) {
        _set(8, moduleCount - i - 1, mod);
      } else if (i < 9) {
        _set(8, 15 - i - 1 + 1, mod);
      } else {
        _set(8, 15 - i - 1, mod);
      }
    }

    _set(moduleCount - 8, 8, !test);
  }

  void _setupTypeNumber(bool test) {
    final bits = bchTypeNumber(typeNumber);

    for (var i = 0; i < 18; i++) {
      final mod = !test && ((bits >> i) & 1) == 1;
      _set(i ~/ 3, i % 3 + moduleCount - 8 - 3, mod);
    }

    for (var i = 0; i < 18; i++) {
      final mod = !test && ((bits >> i) & 1) == 1;
      _set(i % 3 + moduleCount - 8 - 3, i ~/ 3, mod);
    }
  }

  void _mapData(List<int> data, [int? maskPattern]) {
    var inc = -1;
    var row = moduleCount - 1;
    var bitIndex = 7;
    var byteIndex = 0;
    final mpIndex = maskPattern;

    for (var col = moduleCount - 1; col > 0; col -= 2) {
      if (col == 6) col--;

      for (;;) {
        for (var c = 0; c < 2; c++) {
          if (_data[row * moduleCount + (col - c)] == _pixelUnassigned) {
            var dark = false;

            if (byteIndex < data.length) {
              dark = ((data[byteIndex] >> bitIndex) & 1) == 1;
            }

            final cCol = col - c;
            var mask = false;
            if (mpIndex != null) {
              mask = _getMaskFunction(mpIndex)(row, cCol);
            }

            if (mask) {
              dark = !dark;
            }

            _set(row, col - c, dark);
            bitIndex--;

            if (bitIndex == -1) {
              byteIndex++;
              bitIndex = 7;
            }
          }
        }

        row += inc;

        if (row < 0 || moduleCount <= row) {
          row -= inc;
          inc = -inc;
          break;
        }
      }
    }
  }

  void _applyMask(int mpIndex, Uint8List templateData) {
    final maskFunction = _getMaskFunction(mpIndex);

    var idx = 0;
    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++, idx++) {
        if (templateData[idx] == _pixelUnassigned && maskFunction(row, col)) {
          _data[idx] ^= _pixelDark ^ _pixelLight;
        }
      }
    }
  }
}

double _lostPoint(QrImage qrImage) {
  final moduleCount = qrImage.moduleCount;
  final data = qrImage._data;
  var lostPoint = 0.0;

  var darkCount = 0;

  for (var row = 0; row < moduleCount; row++) {
    final rowIdx = row * moduleCount;
    for (var col = 0; col < moduleCount; col++) {
      var sameCount = 0;
      final currentIdx = rowIdx + col;
      final p00 = data[currentIdx];

      if (p00 == QrImage._pixelDark) darkCount++;

      if (row > 0) {
        final upIdx = currentIdx - moduleCount;
        if (col > 0 && data[upIdx - 1] == p00) sameCount++;
        if (data[upIdx] == p00) sameCount++;
        if (col < moduleCount - 1 && data[upIdx + 1] == p00) sameCount++;
      }

      if (col > 0 && data[currentIdx - 1] == p00) sameCount++;
      if (col < moduleCount - 1 && data[currentIdx + 1] == p00) sameCount++;

      if (row < moduleCount - 1) {
        final downIdx = currentIdx + moduleCount;
        if (col > 0 && data[downIdx - 1] == p00) sameCount++;
        if (data[downIdx] == p00) sameCount++;
        if (col < moduleCount - 1 && data[downIdx + 1] == p00) sameCount++;
      }

      if (sameCount > 5) {
        lostPoint += 3 + sameCount - 5;
      }

      if (row < moduleCount - 1 && col < moduleCount - 1) {
        if (p00 == data[currentIdx + 1] && p00 == data[currentIdx + moduleCount] && p00 == data[currentIdx + moduleCount + 1]) {
          lostPoint += 3;
        }
      }

      if (p00 == QrImage._pixelDark) {
        if (col < moduleCount - 6 &&
            data[currentIdx + 1] == QrImage._pixelLight &&
            data[currentIdx + 2] == QrImage._pixelDark &&
            data[currentIdx + 3] == QrImage._pixelDark &&
            data[currentIdx + 4] == QrImage._pixelDark &&
            data[currentIdx + 5] == QrImage._pixelLight &&
            data[currentIdx + 6] == QrImage._pixelDark) {
          lostPoint += 40;
        }
        if (row < moduleCount - 6 &&
            data[currentIdx + moduleCount] == QrImage._pixelLight &&
            data[currentIdx + 2 * moduleCount] == QrImage._pixelDark &&
            data[currentIdx + 3 * moduleCount] == QrImage._pixelDark &&
            data[currentIdx + 4 * moduleCount] == QrImage._pixelDark &&
            data[currentIdx + 5 * moduleCount] == QrImage._pixelLight &&
            data[currentIdx + 6 * moduleCount] == QrImage._pixelDark) {
          lostPoint += 40;
        }
      }
    }
  }

  final ratio = (100 * darkCount / moduleCount / moduleCount - 50).abs() / 5;
  return lostPoint + ratio * 10;
}

bool Function(int r, int c) _getMaskFunction(int maskPattern) => switch (maskPattern) {
  0 => (int r, int c) => (r + c).isEven,
  1 => (int r, int c) => r.isEven,
  2 => (int r, int c) => c % 3 == 0,
  3 => (int r, int c) => (r + c) % 3 == 0,
  4 => (int r, int c) => ((r ~/ 2) + (c ~/ 3)).isEven,
  5 => (int r, int c) => ((r * c) % 2 + (r * c) % 3) == 0,
  6 => (int r, int c) => (((r * c) % 2) + ((r * c) % 3)).isEven,
  7 => (int r, int c) => (((r * c) % 3) + ((r + c) % 2)).isEven,
  _ => throw ArgumentError.value(
    maskPattern,
    "maskPattern",
    "Invalid mask pattern",
  ),
};

enum BarcodeQRCorrectionLevel {
  low,
  medium,
  quartile,
  high,
}

class BarcodeQR extends Barcode2D {
  const BarcodeQR(
    this.typeNumber,
    this.errorCorrectLevel,
  ) : assert(typeNumber == null || (typeNumber >= 1 && typeNumber <= 40));

  final int? typeNumber;

  final BarcodeQRCorrectionLevel errorCorrectLevel;

  @override
  Barcode2DMatrix convert(Uint8List data) {
    final QrErrorCorrectLevel errorLevel = switch (errorCorrectLevel) {
      BarcodeQRCorrectionLevel.low => QrErrorCorrectLevel.low,
      BarcodeQRCorrectionLevel.medium => QrErrorCorrectLevel.medium,
      BarcodeQRCorrectionLevel.quartile => QrErrorCorrectLevel.quartile,
      BarcodeQRCorrectionLevel.high => QrErrorCorrectLevel.high,
    };

    QrPayload payload;
    try {
      payload = QrPayload.fromString(utf8.decode(data));
    } catch (_) {
      payload = QrPayload.fromTypedData(data);
    }

    final qrCode = QrCode(
      payload: payload,
      errorCorrectLevel: errorLevel,
      minTypeNumber: typeNumber ?? 1,
    );
    final qrImage = QrImage(qrCode);

    return Barcode2DMatrix.fromXY(
      qrCode.moduleCount,
      qrCode.moduleCount,
      1,
      qrImage.isDark,
    );
  }

  @override
  Iterable<int> get charSet => Iterable<int>.generate(256);

  @override
  String get name => "QR-Code";

  @override
  int get maxLength => 2953;
}

class ReedSolomonEncoder {
  ReedSolomonEncoder(this.gf) {
    polynomes = <GFPoly>[
      GFPoly(gf, <int>[1]),
    ];
  }

  GaloisField gf;
  late List<GFPoly> polynomes;

  GFPoly getPolynomial(int degree) {
    if (degree >= polynomes.length) {
      var last = polynomes[polynomes.length - 1];
      for (var d = polynomes.length; d <= degree; d++) {
        final next = last.multiply(GFPoly(gf, <int>[1, gf.aLogTbl[d - 1 + gf.base]]));
        polynomes.add(next);
        last = next;
      }
    }
    return polynomes[degree];
  }

  List<int> encode(List<int> data, int eccCount) {
    final generator = getPolynomial(eccCount);
    var info = GFPoly(gf, data);
    info = info.multByMonominal(eccCount, 1);
    final remainder = info.divide(generator)[1];

    final result = List<int>.filled(eccCount, 0);
    final numZero = eccCount - remainder.coefficients.length;
    result.setAll(numZero, remainder.coefficients);
    return result;
  }
}

class GaloisField {
  GaloisField(int pp, this.size, this.base) {
    aLogTbl = List<int>.filled(size, 0);
    logTbl = List<int>.filled(size, 0);

    var x = 1;
    for (var i = 0; i < size; i++) {
      aLogTbl[i] = x;
      x = x * 2;
      if (x >= size) {
        x = (x ^ pp) & (size - 1);
      }
    }

    for (var i = 0; i < size; i++) {
      logTbl[aLogTbl[i]] = i;
    }
  }

  int size;
  int base;
  late List<int> aLogTbl;
  late List<int> logTbl;

  GFPoly zero() {
    return GFPoly(this, <int>[0]);
  }

  int addOrSub(int a, int b) {
    return a ^ b;
  }

  int multiply(int a, int b) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return aLogTbl[(logTbl[a] + logTbl[b]) % (size - 1)];
  }

  int divide(int a, int b) {
    if (b == 0) {
      throw const BarcodeException("Divide by zero");
    } else if (a == 0) {
      return 0;
    }
    return aLogTbl[(logTbl[a] - logTbl[b]) % (size - 1)];
  }

  int invers(int num) {
    return aLogTbl[(size - 1) - logTbl[num]];
  }
}

class GFPoly {
  GFPoly(this.gf, this.coefficients) {
    while (coefficients.length > 1 && coefficients[0] == 0) {
      coefficients = coefficients.sublist(1);
    }
  }

  factory GFPoly.monominalPoly(GaloisField field, int degree, int coeff) {
    if (coeff == 0) {
      return field.zero();
    }
    final result = List<int>.filled(degree + 1, 0);
    result[0] = coeff;
    return GFPoly(field, result);
  }

  GaloisField gf;
  List<int> coefficients;

  int getDegree() {
    return coefficients.length - 1;
  }

  bool zero() {
    return coefficients[0] == 0;
  }

  int getCoefficient(int degree) {
    return coefficients[getDegree() - degree];
  }

  GFPoly addOrSubstract(GFPoly other) {
    if (zero()) {
      return other;
    } else if (other.zero()) {
      return this;
    }
    var smallCoeff = coefficients;
    var largeCoeff = other.coefficients;
    if (smallCoeff.length > largeCoeff.length) {
      final swap = largeCoeff;
      largeCoeff = smallCoeff;
      smallCoeff = swap;
    }
    final sumDiff = List<int>.filled(largeCoeff.length, 0);
    final lenDiff = largeCoeff.length - smallCoeff.length;
    sumDiff.setAll(0, largeCoeff.sublist(0, lenDiff));
    for (var i = lenDiff; i < largeCoeff.length; i++) {
      sumDiff[i] = gf.addOrSub(smallCoeff[i - lenDiff], largeCoeff[i]);
    }
    return GFPoly(gf, sumDiff);
  }

  GFPoly multByMonominal(int degree, int coeff) {
    if (coeff == 0) {
      return gf.zero();
    }
    final size = coefficients.length;
    final result = List<int>.filled(size + degree, 0);
    for (var i = 0; i < size; i++) {
      result[i] = gf.multiply(coefficients[i], coeff);
    }
    return GFPoly(gf, result);
  }

  GFPoly multiply(GFPoly other) {
    if (zero() || other.zero()) {
      return gf.zero();
    }
    final aCoeff = coefficients;
    final aLen = aCoeff.length;
    final bCoeff = other.coefficients;
    final bLen = bCoeff.length;
    final product = List<int>.filled(aLen + bLen - 1, 0);
    for (var i = 0; i < aLen; i++) {
      final ac = aCoeff[i];
      for (var j = 0; j < bLen; j++) {
        final bc = bCoeff[j];
        product[i + j] = gf.addOrSub(product[i + j], gf.multiply(ac, bc));
      }
    }
    return GFPoly(gf, product);
  }

  List<GFPoly> divide(GFPoly other) {
    var quotient = gf.zero();
    var remainder = this;
    final fld = gf;
    final denomLeadTerm = other.getCoefficient(other.getDegree());
    final inversDenomLeadTerm = fld.invers(denomLeadTerm);
    while (remainder.getDegree() >= other.getDegree() && !remainder.zero()) {
      final degreeDiff = remainder.getDegree() - other.getDegree();
      final scale = fld.multiply(remainder.getCoefficient(remainder.getDegree()), inversDenomLeadTerm);
      final term = other.multByMonominal(degreeDiff, scale);
      final itQuot = GFPoly.monominalPoly(fld, degreeDiff, scale);
      quotient = quotient.addOrSubstract(itQuot);
      remainder = remainder.addOrSubstract(term);
    }
    return <GFPoly>[quotient, remainder];
  }
}

class BarcodeRm4scc extends BarcodeHM {
  const BarcodeRm4scc();

  @override
  Iterable<int> get charSet => BarcodeMaps.rm4scc.keys;

  @override
  String get name => "RM4SCC";

  @override
  Iterable<BarcodeHMBar> convertHM(String data) sync* {
    yield fromBits(BarcodeMaps.rm4sccStart);

    var sumTop = 0;
    var sumBottom = 0;
    final keys = BarcodeMaps.rm4scc.keys.toList();

    for (final codeUnit in data.codeUnits) {
      final code = BarcodeMaps.rm4scc[codeUnit];
      if (code == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(codeUnit)}" to $name');
      }
      yield* addHW(code, BarcodeMaps.rm4sccLen);

      final index = keys.indexOf(codeUnit);
      sumTop += (index ~/ 6 + 1) % 6;
      sumBottom += (index + 1) % 6;
    }

    final crc = ((sumTop - 1) % 6) * 6 + (sumBottom - 1) % 6;
    yield* addHW(BarcodeMaps.rm4scc[keys[crc]]!, BarcodeMaps.rm4sccLen);

    yield fromBits(BarcodeMaps.rm4sccStop);
  }
}

final class QrRsBlock {
  final int totalCount;
  final int dataCount;

  QrRsBlock._(this.totalCount, this.dataCount);

  static List<QrRsBlock> getRSBlocks(
    int typeNumber,
    QrErrorCorrectLevel errorCorrectLevel,
  ) {
    final rsBlock = _getRsBlockTable(typeNumber, errorCorrectLevel);

    final length = rsBlock.length ~/ 3;

    final list = <QrRsBlock>[];

    for (var i = 0; i < length; i++) {
      final count = rsBlock[i * 3 + 0];
      final totalCount = rsBlock[i * 3 + 1];
      final dataCount = rsBlock[i * 3 + 2];

      for (var j = 0; j < count; j++) {
        list.add(QrRsBlock._(totalCount, dataCount));
      }
    }

    return list;
  }

  static int getTotalDataBits(
    int typeNumber,
    QrErrorCorrectLevel errorCorrectLevel,
  ) {
    final rsBlock = _getRsBlockTable(typeNumber, errorCorrectLevel);
    final length = rsBlock.length ~/ 3;
    var totalDataBits = 0;
    for (var i = 0; i < length; i++) {
      final count = rsBlock[i * 3 + 0];
      final dataCount = rsBlock[i * 3 + 2];
      totalDataBits += count * dataCount * 8;
    }
    return totalDataBits;
  }
}

List<int> _getRsBlockTable(
  int typeNumber,
  QrErrorCorrectLevel errorCorrectLevel,
) => switch (errorCorrectLevel) {
  QrErrorCorrectLevel.low => _rsBlockTable[(typeNumber - 1) * 4 + 0],
  QrErrorCorrectLevel.medium => _rsBlockTable[(typeNumber - 1) * 4 + 1],
  QrErrorCorrectLevel.quartile => _rsBlockTable[(typeNumber - 1) * 4 + 2],
  QrErrorCorrectLevel.high => _rsBlockTable[(typeNumber - 1) * 4 + 3],
};

const List<List<int>> _rsBlockTable = [
  [1, 26, 19],
  [1, 26, 16],
  [1, 26, 13],
  [1, 26, 9],

  [1, 44, 34],
  [1, 44, 28],
  [1, 44, 22],
  [1, 44, 16],

  [1, 70, 55],
  [1, 70, 44],
  [2, 35, 17],
  [2, 35, 13],

  [1, 100, 80],
  [2, 50, 32],
  [2, 50, 24],
  [4, 25, 9],

  [1, 134, 108],
  [2, 67, 43],
  [2, 33, 15, 2, 34, 16],
  [2, 33, 11, 2, 34, 12],

  [2, 86, 68],
  [4, 43, 27],
  [4, 43, 19],
  [4, 43, 15],

  [2, 98, 78],
  [4, 49, 31],
  [2, 32, 14, 4, 33, 15],
  [4, 39, 13, 1, 40, 14],

  [2, 121, 97],
  [2, 60, 38, 2, 61, 39],
  [4, 40, 18, 2, 41, 19],
  [4, 40, 14, 2, 41, 15],

  [2, 146, 116],
  [3, 58, 36, 2, 59, 37],
  [4, 36, 16, 4, 37, 17],
  [4, 36, 12, 4, 37, 13],

  [2, 86, 68, 2, 87, 69],
  [4, 69, 43, 1, 70, 44],
  [6, 43, 19, 2, 44, 20],
  [6, 43, 15, 2, 44, 16],

  [4, 101, 81],
  [1, 80, 50, 4, 81, 51],
  [4, 50, 22, 4, 51, 23],
  [3, 36, 12, 8, 37, 13],

  [2, 116, 92, 2, 117, 93],
  [6, 58, 36, 2, 59, 37],
  [4, 46, 20, 6, 47, 21],
  [7, 42, 14, 4, 43, 15],

  [4, 133, 107],
  [8, 59, 37, 1, 60, 38],
  [8, 44, 20, 4, 45, 21],
  [12, 33, 11, 4, 34, 12],

  [3, 145, 115, 1, 146, 116],
  [4, 64, 40, 5, 65, 41],
  [11, 36, 16, 5, 37, 17],
  [11, 36, 12, 5, 37, 13],

  [5, 109, 87, 1, 110, 88],
  [5, 65, 41, 5, 66, 42],
  [5, 54, 24, 7, 55, 25],
  [11, 36, 12],

  [5, 122, 98, 1, 123, 99],
  [7, 73, 45, 3, 74, 46],
  [15, 43, 19, 2, 44, 20],
  [3, 45, 15, 13, 46, 16],

  [1, 135, 107, 5, 136, 108],
  [10, 74, 46, 1, 75, 47],
  [1, 50, 22, 15, 51, 23],
  [2, 42, 14, 17, 43, 15],

  [5, 150, 120, 1, 151, 121],
  [9, 69, 43, 4, 70, 44],
  [17, 50, 22, 1, 51, 23],
  [2, 42, 14, 19, 43, 15],

  [3, 141, 113, 4, 142, 114],
  [3, 70, 44, 11, 71, 45],
  [17, 47, 21, 4, 48, 22],
  [9, 39, 13, 16, 40, 14],

  [3, 135, 107, 5, 136, 108],
  [3, 67, 41, 13, 68, 42],
  [15, 54, 24, 5, 55, 25],
  [15, 43, 15, 10, 44, 16],

  [4, 144, 116, 4, 145, 117],
  [17, 68, 42],
  [17, 50, 22, 6, 51, 23],
  [19, 46, 16, 6, 47, 17],

  [2, 139, 111, 7, 140, 112],
  [17, 74, 46],
  [7, 54, 24, 16, 55, 25],
  [34, 37, 13],

  [4, 151, 121, 5, 152, 122],
  [4, 75, 47, 14, 76, 48],
  [11, 54, 24, 14, 55, 25],
  [16, 45, 15, 14, 46, 16],

  [6, 147, 117, 4, 148, 118],
  [6, 73, 45, 14, 74, 46],
  [11, 54, 24, 16, 55, 25],
  [30, 46, 16, 2, 47, 17],

  [8, 132, 106, 4, 133, 107],
  [8, 75, 47, 13, 76, 48],
  [7, 54, 24, 22, 55, 25],
  [22, 45, 15, 13, 46, 16],

  [10, 142, 114, 2, 143, 115],
  [19, 74, 46, 4, 75, 47],
  [28, 50, 22, 6, 51, 23],
  [33, 46, 16, 4, 47, 17],

  [8, 152, 122, 4, 153, 123],
  [22, 73, 45, 3, 74, 46],
  [8, 53, 23, 26, 54, 24],
  [12, 45, 15, 28, 46, 16],

  [3, 147, 117, 10, 148, 118],
  [3, 73, 45, 23, 74, 46],
  [4, 54, 24, 31, 55, 25],
  [11, 45, 15, 31, 46, 16],

  [7, 146, 116, 7, 147, 117],
  [21, 73, 45, 7, 74, 46],
  [1, 53, 23, 37, 54, 24],
  [19, 45, 15, 26, 46, 16],

  [5, 145, 115, 10, 146, 116],
  [19, 75, 47, 10, 76, 48],
  [15, 54, 24, 25, 55, 25],
  [23, 45, 15, 25, 46, 16],

  [13, 145, 115, 3, 146, 116],
  [2, 74, 46, 29, 75, 47],
  [42, 54, 24, 1, 55, 25],
  [23, 45, 15, 28, 46, 16],

  [17, 145, 115],
  [10, 74, 46, 23, 75, 47],
  [10, 54, 24, 35, 55, 25],
  [19, 45, 15, 35, 46, 16],

  [17, 145, 115, 1, 146, 116],
  [14, 74, 46, 21, 75, 47],
  [29, 54, 24, 19, 55, 25],
  [11, 45, 15, 46, 46, 16],

  [13, 145, 115, 6, 146, 116],
  [14, 74, 46, 23, 75, 47],
  [44, 54, 24, 7, 55, 25],
  [59, 46, 16, 1, 47, 17],

  [12, 151, 121, 7, 152, 122],
  [12, 75, 47, 26, 76, 48],
  [39, 54, 24, 14, 55, 25],
  [22, 45, 15, 41, 46, 16],

  [6, 151, 121, 14, 152, 122],
  [6, 75, 47, 34, 76, 48],
  [46, 54, 24, 10, 55, 25],
  [2, 45, 15, 64, 46, 16],

  [17, 152, 122, 4, 153, 123],
  [29, 74, 46, 14, 75, 47],
  [49, 54, 24, 10, 55, 25],
  [24, 45, 15, 46, 46, 16],

  [4, 152, 122, 18, 153, 123],
  [13, 74, 46, 32, 75, 47],
  [48, 54, 24, 14, 55, 25],
  [42, 45, 15, 32, 46, 16],

  [20, 147, 117, 4, 148, 118],
  [40, 75, 47, 7, 76, 48],
  [43, 54, 24, 22, 55, 25],
  [10, 45, 15, 67, 46, 16],

  [19, 148, 118, 6, 149, 119],
  [18, 75, 47, 31, 76, 48],
  [34, 54, 24, 34, 55, 25],
  [20, 45, 15, 61, 46, 16],
];

class BarcodeTelepen extends Barcode1D {
  const BarcodeTelepen();

  @override
  Iterable<int> get charSet => Iterable<int>.generate(128);

  @override
  String get name => "Telepen";

  @override
  Iterable<bool> convert(String data) sync* {
    yield* add(BarcodeMaps.telepenStart, BarcodeMaps.telepenLen);

    var checksum = 0;

    for (var code in data.codeUnits) {
      if (code >= BarcodeMaps.telepen.length) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }
      final codeValue = BarcodeMaps.telepen[code];
      yield* add(codeValue, BarcodeMaps.telepenLen);
      checksum += code;
    }

    checksum = 127 - (checksum % 127);
    if (checksum == 127) {
      checksum = 0;
    }
    yield* add(BarcodeMaps.telepen[checksum], BarcodeMaps.telepenLen);

    yield* add(BarcodeMaps.telepenEnd, BarcodeMaps.telepenLen);
  }
}

class BarcodeUpcA extends BarcodeEan {
  const BarcodeUpcA();

  @override
  String get name => "UPC A";

  @override
  int get minLength => 11;

  @override
  int get maxLength => 12;

  @override
  void verifyBytes(Uint8List data) {
    final text = utf8.decoder.convert(data);
    checkLength(text, maxLength);
    super.verifyBytes(data);
  }

  @override
  Iterable<bool> convert(String data) sync* {
    data = checkLength(data, maxLength);

    yield* add(BarcodeMaps.eanStartEnd, 3);

    var index = 0;
    for (var code in data.codeUnits) {
      final codes = BarcodeMaps.ean[code];

      if (codes == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      if (index == 6) {
        yield* add(BarcodeMaps.eanCenter, 5);
      }

      yield* add(codes[index < 6 ? 0 : 2], 7);
      index++;
    }

    yield* add(BarcodeMaps.eanStartEnd, 3);
  }

  @override
  double marginLeft(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double marginRight(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double getHeight(
    int index,
    int count,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    bool drawText,
  ) {
    if (!drawText) {
      return super.getHeight(index, count, width, height, fontHeight, textPadding, drawText);
    }

    final h = height - fontHeight - textPadding;

    if (index + count < 11 || (index > 45 && index < 49) || index > 82) {
      return h + fontHeight / 2 + textPadding;
    }

    return h;
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) sync* {
    final text = checkLength(data, maxLength);
    final w = lineWidth * 7;
    final left = marginLeft(true, width, height, fontHeight, textPadding);
    final right = marginRight(true, width, height, fontHeight, textPadding);

    yield BarcodeText(
      left: 0,
      top: height - fontHeight,
      width: left - lineWidth,
      height: fontHeight,
      text: text[0],
      align: BarcodeTextAlign.right,
    );

    var offset = left + lineWidth * 10;

    for (var i = 1; i < text.length - 1; i++) {
      yield BarcodeText(
        left: offset,
        top: height - fontHeight,
        width: w,
        height: fontHeight,
        text: text[i],
        align: BarcodeTextAlign.center,
      );

      offset += w;
      if (i == 5) {
        offset += lineWidth * 5;
      }
    }

    yield BarcodeText(
      left: width - right + lineWidth,
      top: height - fontHeight,
      width: right - lineWidth,
      height: fontHeight,
      text: text[text.length - 1],
      align: BarcodeTextAlign.left,
    );
  }
}

class BarcodeUpcE extends BarcodeEan {
  const BarcodeUpcE(this.fallback);

  final bool fallback;

  @override
  String get name => "UPC E";

  @override
  int get minLength => 6;

  @override
  int get maxLength => 12;

  @override
  void verifyBytes(Uint8List data) {
    var text = utf8.decoder.convert(data);

    if (text.length <= 8) {
      text = upceToUpca(text);
    }

    if (text.length < 11) {
      throw BarcodeException('Unable to encode "$text", minimum length is 11 for $name Barcode');
    }

    final upca = checkLength(text, maxLength);
    if (!fallback) {
      upcaToUpce(upca);
    }

    super.verifyBytes(utf8.encoder.convert(text));
  }

  String upcaToUpce(String data) {
    if (RegExp(r"^[01]\d{11}$").firstMatch(data) == null) {
      throw BarcodeException('Unable to convert "$data" to $name Barcode');
    }

    final mc = data.substring(1, 6);
    final pc = data.substring(6, 11);

    if (["000", "100", "200"].contains(mc.substring(mc.length - 3)) && int.parse(pc) <= 999) {
      return "${mc.substring(0, 2)}${pc.substring(pc.length - 3)}${mc[2]}";
    } else if (mc.substring(mc.length - 2) == "00" && int.parse(pc) <= 99) {
      return "${mc.substring(0, 3)}${pc.substring(pc.length - 2)}3";
    } else if (mc.substring(mc.length - 1) == "0" && int.parse(pc) <= 9) {
      return "${mc.substring(0, 4)}${pc.substring(pc.length - 1)}4";
    } else if (mc.substring(mc.length - 1) != "0" && [5, 6, 7, 8, 9].contains(int.parse(pc))) {
      return mc + pc.substring(pc.length - 1);
    } else {
      throw BarcodeException('Unable to convert "$data" to $name Barcode');
    }
  }

  String upceToUpca(String data) {
    final exp = RegExp(r"^\d{6,8}$");
    final match = exp.firstMatch(data);

    if (match == null) {
      throw BarcodeException('Unable to convert "$data" to UPC A Barcode');
    }

    var first = "0";
    String? checksum;

    switch (data.length) {
      case 8:
        checksum = data[7];
        first = data[0];
        data = data.substring(1, 7);
        break;
      case 7:
        first = data[0];
        data = data.substring(1, 7);
        break;
    }

    if (first != "0" && first != "1") {
      throw BarcodeException('Unable to convert "$data" to UPC A Barcode');
    }

    final d1 = data[0];
    final d2 = data[1];
    final d3 = data[2];
    final d4 = data[3];
    final d5 = data[4];
    final d6 = data[5];

    String manufacturer;
    String product;

    switch (d6) {
      case "0":
      case "1":
      case "2":
        manufacturer = "$d1$d2${d6}00";
        product = "00$d3$d4$d5";
        break;
      case "3":
        manufacturer = "$d1$d2${d3}00";
        product = "000$d4$d5";
        break;
      case "4":
        manufacturer = "$d1$d2$d3${d4}0";
        product = "0000$d5";
        break;
      default:
        manufacturer = "$d1$d2$d3$d4$d5";
        product = "0000$d6";
        break;
    }

    data = first + manufacturer + product;
    return data + (checksum ?? checkSumModulo10(data));
  }

  @override
  Iterable<bool> convert(String data) sync* {
    if (data.length <= 8) {
      data = upceToUpca(data);
    }

    data = checkLength(data, maxLength);
    final first = data.codeUnitAt(0);
    final last = data.codeUnitAt(11);

    try {
      data = upcaToUpce(data);
    } on BarcodeException {
      if (fallback) {
        yield* const BarcodeUpcA().convert(data);
        return;
      }
      rethrow;
    }

    yield* add(BarcodeMaps.eanStartEnd, 3);

    final parityRow = BarcodeMaps.upce[last];
    final parity = first == 0x30 ? parityRow : parityRow! ^ 0x3f;

    var index = 0;
    for (var code in data.codeUnits) {
      final codes = BarcodeMaps.ean[code];

      if (codes == null) {
        throw BarcodeException('Unable to encode "${String.fromCharCode(code)}" to $name Barcode');
      }

      yield* add(codes[(parity! >> index) & 1 == 0 ? 1 : 0], 7);
      index++;
    }

    yield* add(BarcodeMaps.eanEndUpcE, 6);
  }

  @override
  double marginLeft(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double marginRight(
    bool drawText,
    double width,
    double height,
    double fontHeight,
    double textPadding,
  ) {
    if (!drawText) {
      return 0;
    }

    return fontHeight;
  }

  @override
  double getHeight(
    int index,
    int count,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    bool drawText,
  ) {
    if (!drawText) {
      return super.getHeight(
        index,
        count,
        width,
        height,
        fontHeight,
        textPadding,
        drawText,
      );
    }

    final h = height - fontHeight - textPadding;

    if (index + count < 4 || index > 44) {
      return h + fontHeight / 2 + textPadding;
    }

    return h;
  }

  @override
  Iterable<BarcodeElement> makeText(
    String data,
    double width,
    double height,
    double fontHeight,
    double textPadding,
    double lineWidth,
  ) sync* {
    if (data.length <= 8) {
      data = upceToUpca(data);
    }

    data = checkLength(data, maxLength);
    final first = data.substring(0, 1);
    final last = data.substring(11, 12);

    try {
      data = upcaToUpce(data);
    } on BarcodeException {
      if (fallback) {
        yield* const BarcodeUpcA().makeText(
          data,
          width,
          height,
          fontHeight,
          textPadding,
          lineWidth,
        );
        return;
      }
      rethrow;
    }

    final w = lineWidth * 7;
    final left = marginLeft(true, width, height, fontHeight, textPadding);
    final right = marginRight(true, width, height, fontHeight, textPadding);

    yield BarcodeText(
      left: 0,
      top: height - fontHeight,
      width: left - lineWidth,
      height: fontHeight,
      text: first,
      align: BarcodeTextAlign.right,
    );

    var offset = left + lineWidth * 3;

    for (var i = 0; i < data.length; i++) {
      yield BarcodeText(
        left: offset,
        top: height - fontHeight,
        width: w,
        height: fontHeight,
        text: data[i],
        align: BarcodeTextAlign.center,
      );

      offset += w;
    }

    yield BarcodeText(
      left: width - right + lineWidth,
      top: height - fontHeight,
      width: right - lineWidth,
      height: fontHeight,
      text: last,
      align: BarcodeTextAlign.left,
    );
  }

  @override
  String normalize(String data) {
    if (data.length <= 8) {
      data = upceToUpca(data.padRight(6, "0"));
    }

    data = checkLength(data, maxLength);
    final first = data.substring(0, 1);
    final last = data.substring(11, 12);

    try {
      data = upcaToUpce(data);
    } on BarcodeException {
      if (fallback) {
        return data;
      }
      rethrow;
    }

    return "$first$data$last";
  }
}

const List<List<int>> _patternPositionTable = [
  [],
  [6, 18],
  [6, 22],
  [6, 26],
  [6, 30],
  [6, 34],
  [6, 22, 38],
  [6, 24, 42],
  [6, 26, 46],
  [6, 28, 50],
  [6, 30, 54],
  [6, 32, 58],
  [6, 34, 62],
  [6, 26, 46, 66],
  [6, 26, 48, 70],
  [6, 26, 50, 74],
  [6, 30, 54, 78],
  [6, 30, 56, 82],
  [6, 30, 58, 86],
  [6, 34, 62, 90],
  [6, 28, 50, 72, 94],
  [6, 26, 50, 74, 98],
  [6, 30, 54, 78, 102],
  [6, 28, 54, 80, 106],
  [6, 32, 58, 84, 110],
  [6, 30, 58, 86, 114],
  [6, 34, 62, 90, 118],
  [6, 26, 50, 74, 98, 122],
  [6, 30, 54, 78, 102, 126],
  [6, 26, 52, 78, 104, 130],
  [6, 30, 56, 82, 108, 134],
  [6, 34, 60, 86, 112, 138],
  [6, 30, 58, 86, 114, 142],
  [6, 34, 62, 90, 118, 146],
  [6, 30, 54, 78, 102, 126, 150],
  [6, 24, 50, 76, 102, 128, 154],
  [6, 28, 54, 80, 106, 132, 158],
  [6, 32, 58, 84, 110, 136, 162],
  [6, 26, 54, 82, 110, 138, 166],
  [6, 30, 58, 86, 114, 142, 170],
];

const int _g15 = (1 << 10) | (1 << 8) | (1 << 5) | (1 << 4) | (1 << 2) | (1 << 1) | (1 << 0);
const int _g18 = (1 << 12) | (1 << 11) | (1 << 10) | (1 << 9) | (1 << 8) | (1 << 5) | (1 << 2) | (1 << 0);
const _g15Mask = (1 << 14) | (1 << 12) | (1 << 10) | (1 << 4) | (1 << 1);

int bchTypeInfo(int data) {
  var d = data << 10;
  while (d.bitLength >= 11) {
    d ^= _g15 << (d.bitLength - 11);
  }
  return ((data << 10) | d) ^ _g15Mask;
}

int bchTypeNumber(int data) {
  var d = data << 12;
  while (d.bitLength >= 13) {
    d ^= _g18 << (d.bitLength - 13);
  }
  return (data << 12) | d;
}

List<int> patternPosition(int typeNumber) => _patternPositionTable[typeNumber - 1];

final class QrValidationResult {
  final QrCode? qrCode;

  final List<int> validTypeNumbers;

  final List<QrErrorCorrectLevel> validErrorCorrectLevels;

  const QrValidationResult._({
    this.qrCode,
    required this.validTypeNumbers,
    required this.validErrorCorrectLevels,
  });

  factory QrValidationResult.fromPayload({
    required QrPayload payload,
    required int typeNumber,
    required QrErrorCorrectLevel errorCorrectLevel,
  }) {
    RangeError.checkValueInInterval(typeNumber, 1, 40, "typeNumber");

    final requiredBitsFor1 = payload.calculateRequiredBits(1);
    final requiredBitsFor10 = payload.calculateRequiredBits(10);
    final requiredBitsFor27 = payload.calculateRequiredBits(27);

    int getRequiredBits(int type) {
      if (type < 10) return requiredBitsFor1;
      if (type < 27) return requiredBitsFor10;
      return requiredBitsFor27;
    }

    final validTypes = <int>[];
    for (var type = 1; type <= 40; type++) {
      final required = getRequiredBits(type);
      final capacity = QrRsBlock.getTotalDataBits(type, errorCorrectLevel);
      if (required <= capacity) {
        for (var t = type; t <= 40; t++) {
          validTypes.add(t);
        }
        break;
      }
    }

    final validErrorLevels = <QrErrorCorrectLevel>[];
    for (final level in QrErrorCorrectLevel.values) {
      final requiredForType = getRequiredBits(typeNumber);
      final capacity = QrRsBlock.getTotalDataBits(typeNumber, level);
      if (requiredForType <= capacity) {
        validErrorLevels.add(level);
      }
    }

    QrCode? code;
    if (validTypes.contains(typeNumber) && validErrorLevels.contains(errorCorrectLevel)) {
      code = QrCode(
        payload: payload,
        errorCorrectLevel: errorCorrectLevel,
        minTypeNumber: typeNumber,
      );
    }

    return QrValidationResult._(
      qrCode: code,
      validTypeNumbers: List.unmodifiable(validTypes),
      validErrorCorrectLevels: List.unmodifiable(validErrorLevels),
    );
  }

  bool get isValid => qrCode != null;
}

enum UBarcodeType {
  qrCode,
  dataMatrix,
  aztec,
  pdf417,
  code128,
  code128A,
  code128B,
  code128C,
  gs128,
  code39,
  code39Extended,
  code93,
  codabar,
  itf,
  itf14,
  itf16,
  ean13,
  ean8,
  ean5,
  ean2,
  upcA,
  upcE,
  isbn,
  telepen,
  rm4scc,
  postnet,
}

enum UErrorCorrectionLevel { low, medium, quartile, high }

enum UBarcodeModuleShape { square, rounded, circle, dot }

BarcodeQRCorrectionLevel _mapEcc(UErrorCorrectionLevel level) => switch (level) {
  UErrorCorrectionLevel.low => BarcodeQRCorrectionLevel.low,
  UErrorCorrectionLevel.medium => BarcodeQRCorrectionLevel.medium,
  UErrorCorrectionLevel.quartile => BarcodeQRCorrectionLevel.quartile,
  UErrorCorrectionLevel.high => BarcodeQRCorrectionLevel.high,
};

Barcode _barcodeFor(UBarcodeType type, {int? qrVersion, UErrorCorrectionLevel ecc = UErrorCorrectionLevel.low}) => switch (type) {
  UBarcodeType.qrCode => Barcode.qrCode(typeNumber: qrVersion, errorCorrectLevel: _mapEcc(ecc)),
  UBarcodeType.dataMatrix => Barcode.dataMatrix(),
  UBarcodeType.aztec => Barcode.aztec(),
  UBarcodeType.pdf417 => Barcode.pdf417(),
  UBarcodeType.code128 => Barcode.code128(),
  UBarcodeType.code128A => Barcode.code128(useCode128B: false, useCode128C: false),
  UBarcodeType.code128B => Barcode.code128(useCode128A: false, useCode128C: false),
  UBarcodeType.code128C => Barcode.code128(useCode128A: false, useCode128B: false),
  UBarcodeType.gs128 => Barcode.gs128(),
  UBarcodeType.code39 || UBarcodeType.code39Extended => Barcode.code39(),
  UBarcodeType.code93 => Barcode.code93(),
  UBarcodeType.codabar => Barcode.codabar(),
  UBarcodeType.itf => Barcode.itf(),
  UBarcodeType.itf14 => Barcode.itf14(),
  UBarcodeType.itf16 => Barcode.itf16(),
  UBarcodeType.ean13 => Barcode.ean13(),
  UBarcodeType.ean8 => Barcode.ean8(),
  UBarcodeType.ean5 => Barcode.ean5(),
  UBarcodeType.ean2 => Barcode.ean2(),
  UBarcodeType.upcA => Barcode.upcA(),
  UBarcodeType.upcE => Barcode.upcE(),
  UBarcodeType.isbn => Barcode.isbn(),
  UBarcodeType.telepen => Barcode.telepen(),
  UBarcodeType.rm4scc => Barcode.rm4scc(),
  UBarcodeType.postnet => Barcode.postnet(),
};

class UBarcode extends StatefulWidget {
  const UBarcode({
    required this.value,
    this.type = UBarcodeType.qrCode,
    this.barColor,
    this.backgroundColor,
    this.gradientColors,
    this.gradientBegin = Alignment.centerLeft,
    this.gradientEnd = Alignment.centerRight,
    this.moduleShape = UBarcodeModuleShape.square,
    this.cornerRadiusRatio = 0.3,
    this.showValue = false,
    this.textSpacing = 8,
    this.textStyle,
    this.quietZone = 0,
    this.errorCorrectionLevel,
    this.qrCodeVersion,
    this.module,
    this.enableCheckSum,
    this.logoBytes,
    this.logoSizeRatio = 0.2,
    this.width,
    this.height,
    super.key,
  });

  final String value;
  final UBarcodeType type;
  final Color? barColor;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final UBarcodeModuleShape moduleShape;
  final double cornerRadiusRatio;
  final bool showValue;
  final double textSpacing;
  final TextStyle? textStyle;
  final double quietZone;
  final UErrorCorrectionLevel? errorCorrectionLevel;
  final int? qrCodeVersion;

  final int? module;

  final bool? enableCheckSum;
  final Uint8List? logoBytes;
  final double logoSizeRatio;
  final double? width;
  final double? height;

  static Future<Uint8List?> toPng({
    required String value,
    UBarcodeType type = UBarcodeType.qrCode,
    double width = 512,
    double height = 512,
    double pixelRatio = 1,
    Color barColor = const Color(0xFF000000),
    Color background = const Color(0xFFFFFFFF),
    List<Color>? gradientColors,
    AlignmentGeometry gradientBegin = Alignment.centerLeft,
    AlignmentGeometry gradientEnd = Alignment.centerRight,
    UBarcodeModuleShape moduleShape = UBarcodeModuleShape.square,
    double cornerRadiusRatio = 0.3,
    bool showValue = false,
    double textSpacing = 8,
    double quietZone = 0,
    UErrorCorrectionLevel errorCorrectionLevel = UErrorCorrectionLevel.low,
    int? qrCodeVersion,
  }) async {
    final Barcode barcode = _barcodeFor(type, qrVersion: qrCodeVersion, ecc: errorCorrectionLevel);
    final _UBarcodePainter painter = _UBarcodePainter(
      barcode: barcode,
      data: value,
      drawText: showValue,
      foreground: barColor,
      background: background,
      gradient: gradientColors != null && gradientColors.length >= 2 ? LinearGradient(colors: gradientColors, begin: gradientBegin, end: gradientEnd) : null,
      moduleShape: moduleShape,
      cornerRadiusRatio: cornerRadiusRatio,
      quietZone: quietZone,
      textStyle: TextStyle(color: barColor, fontSize: 12),
      textPadding: textSpacing,
      is2D: barcode is Barcode2D,
      logo: null,
      logoRatio: 0,
    );
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(pixelRatio);
    painter.paint(canvas, Size(width, height));
    final ui.Image image = await recorder.endRecording().toImage((width * pixelRatio).round(), (height * pixelRatio).round());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  static String toSvg({
    required String value,
    UBarcodeType type = UBarcodeType.qrCode,
    double width = 200,
    double height = 80,
    bool showValue = false,
    UErrorCorrectionLevel errorCorrectionLevel = UErrorCorrectionLevel.low,
    int? qrCodeVersion,
  }) => _barcodeFor(type, qrVersion: qrCodeVersion, ecc: errorCorrectionLevel).toSvg(value, width: width, height: height, drawText: showValue);

  static bool isValid(String value, UBarcodeType type) => _barcodeFor(type).isValid(value);

  @override
  State<UBarcode> createState() => _UBarcodeState();
}

class _UBarcodeState extends State<UBarcode> {
  ui.Image? _logo;

  @override
  void initState() {
    super.initState();
    _decodeLogo();
  }

  @override
  void didUpdateWidget(covariant UBarcode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoBytes != widget.logoBytes) _decodeLogo();
  }

  @override
  void dispose() {
    _logo?.dispose();
    super.dispose();
  }

  Future<void> _decodeLogo() async {
    final Uint8List? bytes = widget.logoBytes;
    if (bytes == null) {
      if (_logo != null) setState(() => _logo = null);
      return;
    }
    final ui.Image decoded = await decodeImageFromList(bytes);
    if (!mounted) return;
    setState(() {
      _logo?.dispose();
      _logo = decoded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Barcode barcode = _barcodeFor(widget.type, qrVersion: widget.qrCodeVersion, ecc: widget.errorCorrectionLevel ?? UErrorCorrectionLevel.low);
    final Color foreground = widget.barColor ?? scheme.onSurface;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _UBarcodePainter(
          barcode: barcode,
          data: widget.value,
          drawText: widget.showValue,
          foreground: foreground,
          background: widget.backgroundColor,
          gradient: widget.gradientColors != null && widget.gradientColors!.length >= 2 ? LinearGradient(colors: widget.gradientColors!, begin: widget.gradientBegin, end: widget.gradientEnd) : null,
          moduleShape: widget.moduleShape,
          cornerRadiusRatio: widget.cornerRadiusRatio,
          quietZone: widget.quietZone,
          textStyle: widget.textStyle ?? TextStyle(color: foreground, fontSize: 12),
          textPadding: widget.textSpacing,
          is2D: barcode is Barcode2D,
          logo: _logo,
          logoRatio: widget.logoSizeRatio,
        ),
      ),
    );
  }
}

class _UBarcodePainter extends CustomPainter {
  _UBarcodePainter({
    required this.barcode,
    required this.data,
    required this.drawText,
    required this.foreground,
    required this.background,
    required this.gradient,
    required this.moduleShape,
    required this.cornerRadiusRatio,
    required this.quietZone,
    required this.textStyle,
    required this.textPadding,
    required this.is2D,
    required this.logo,
    required this.logoRatio,
  });

  final Barcode barcode;
  final String data;
  final bool drawText;
  final Color foreground;
  final Color? background;
  final Gradient? gradient;
  final UBarcodeModuleShape moduleShape;
  final double cornerRadiusRatio;
  final double quietZone;
  final TextStyle textStyle;
  final double textPadding;
  final bool is2D;
  final ui.Image? logo;
  final double logoRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) canvas.drawRect(Offset.zero & size, Paint()..color = background!);

    final double qz = quietZone.clamp(0, size.shortestSide / 3);
    final Rect area = Rect.fromLTWH(qz, qz, (size.width - 2 * qz).clamp(0, double.infinity), (size.height - 2 * qz).clamp(0, double.infinity));
    if (area.isEmpty) return;

    final Iterable<BarcodeElement> elements;
    try {
      elements = barcode.make(
        data,
        width: area.width,
        height: area.height,
        drawText: drawText,
        fontHeight: textStyle.fontSize,
        textPadding: textPadding,
      );
    } catch (e) {
      _paintError(canvas, size, e is BarcodeException ? e.message : e.toString());
      return;
    }

    final Paint barPaint = Paint()..isAntiAlias = moduleShape != UBarcodeModuleShape.square;
    if (gradient != null) {
      barPaint.shader = gradient!.createShader(area);
    } else {
      barPaint.color = foreground;
    }

    for (final BarcodeElement element in elements) {
      if (element is BarcodeBar) {
        if (!element.black) continue;
        final Rect r = Rect.fromLTWH(area.left + element.left, area.top + element.top, element.width, element.height);
        if (is2D && moduleShape != UBarcodeModuleShape.square) {
          _paintModule(canvas, r, barPaint);
        } else {
          canvas.drawRect(r, barPaint);
        }
      } else if (element is BarcodeText) {
        _paintText(canvas, area, element);
      }
    }

    if (logo != null && is2D) _paintLogo(canvas, area);
  }

  void _paintModule(Canvas canvas, Rect r, Paint paint) {
    switch (moduleShape) {
      case UBarcodeModuleShape.rounded:
        final double radius = r.shortestSide * cornerRadiusRatio;
        canvas.drawRRect(RRect.fromRectXY(r, radius, radius), paint);
      case UBarcodeModuleShape.circle:
        canvas.drawCircle(r.center, r.shortestSide / 2, paint);
      case UBarcodeModuleShape.dot:
        canvas.drawCircle(r.center, r.shortestSide / 2 * 0.82, paint);
      case UBarcodeModuleShape.square:
        canvas.drawRect(r, paint);
    }
  }

  void _paintText(Canvas canvas, Rect area, BarcodeText element) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: element.text, style: textStyle),
      textAlign: switch (element.align) {
        BarcodeTextAlign.left => TextAlign.left,
        BarcodeTextAlign.center => TextAlign.center,
        BarcodeTextAlign.right => TextAlign.right,
      },
      textDirection: TextDirection.ltr,
    )..layout(minWidth: element.width, maxWidth: element.width);
    tp.paint(canvas, Offset(area.left + element.left, area.top + element.top + (element.height - tp.height) / 2));
  }

  void _paintLogo(Canvas canvas, Rect area) {
    final double target = area.shortestSide * logoRatio.clamp(0.05, 0.35);
    final Rect dst = Rect.fromCenter(center: area.center, width: target, height: target);
    final Rect padded = dst.inflate(target * 0.12);
    canvas.drawRRect(RRect.fromRectXY(padded, target * 0.15, target * 0.15), Paint()..color = background ?? const Color(0xFFFFFFFF));
    final ui.Image image = logo!;
    final Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.save();
    canvas.clipRRect(RRect.fromRectXY(dst, target * 0.1, target * 0.1));
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.high);
    canvas.restore();
  }

  void _paintError(Canvas canvas, Size size, String message) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(color: foreground, fontSize: 11),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 8);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _UBarcodePainter old) =>
      old.data != data ||
      old.barcode != barcode ||
      old.foreground != foreground ||
      old.background != background ||
      old.gradient != gradient ||
      old.moduleShape != moduleShape ||
      old.cornerRadiusRatio != cornerRadiusRatio ||
      old.quietZone != quietZone ||
      old.drawText != drawText ||
      old.textStyle != textStyle ||
      old.textPadding != textPadding ||
      old.logo != logo ||
      old.logoRatio != logoRatio;
}
