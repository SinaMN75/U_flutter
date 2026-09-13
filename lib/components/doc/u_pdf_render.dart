import "dart:ui" as ui;

import "package:u/utilities.dart";

abstract class UPdfGlyphSource {
  int get unitsPerEm;

  int get glyphCount;

  Path? glyphPath(int glyphId);

  double advance(int glyphId);

  int glyphForUnicode(int codePoint) => 0;

  int glyphForName(String name) => 0;

  int glyphForCid(int cid) => cid;
}

class UPdfTrueType implements UPdfGlyphSource {
  UPdfTrueType._(this._bytes, this._tables);

  final Uint8List _bytes;
  final Map<String, List<int>> _tables;
  final Map<int, Path?> _pathCache = <int, Path?>{};

  int _unitsPerEm = 1000;
  int _indexToLocFormat = 0;
  int _numGlyphs = 0;
  int _numberOfHMetrics = 0;
  List<int> _loca = const <int>[];
  Map<int, int> _cmapUnicode = const <int, int>{};
  Map<int, int> _cmapMacRoman = const <int, int>{};
  Map<String, int> _postNames = const <String, int>{};
  UPdfCff? cff;

  @override
  int get unitsPerEm => _unitsPerEm;

  @override
  int get glyphCount => _numGlyphs;

  static UPdfTrueType? parse(Uint8List bytes) {
    try {
      if (bytes.length < 12) return null;
      final UDocCursor cursor = UDocCursor(bytes);
      int tableStart = 0;
      final int tag = cursor.u32();
      if (tag == 0x74746366) {
        cursor.skip(4);
        final int count = cursor.u32();
        if (count == 0) return null;
        tableStart = cursor.u32();
        cursor.seek(tableStart);
        cursor.u32();
      } else if (tag != 0x00010000 && tag != 0x4F54544F && tag != 0x74727565) {
        return null;
      }
      final int numTables = cursor.u16();
      cursor.skip(6);
      final Map<String, List<int>> tables = <String, List<int>>{};
      for (int i = 0; i < numTables && i < 512; i++) {
        if (cursor.remaining < 16) break;
        final String name = cursor.ascii(4);
        cursor.skip(4);
        final int offset = cursor.u32();
        final int length = cursor.u32();
        if (offset >= 0 && offset < bytes.length) tables[name] = <int>[offset, length];
      }
      final UPdfTrueType font = UPdfTrueType._(bytes, tables);
      font._readTables();
      return font;
    } on Object {
      return null;
    }
  }

  UDocCursor? _table(String name) {
    final List<int>? entry = _tables[name];
    if (entry == null) return null;
    final int offset = entry[0];
    final int end = offset + entry[1] > _bytes.length ? _bytes.length : offset + entry[1];
    if (offset >= end) return null;
    return UDocCursor(_bytes, start: offset, end: end);
  }

  void _readTables() {
    final UDocCursor? head = _table("head");
    if (head != null) {
      head.seek(head.position + 18);
      _unitsPerEm = head.u16();
      if (_unitsPerEm <= 0) _unitsPerEm = 1000;
      head.skip(30);
      _indexToLocFormat = head.i16();
    }
    final UDocCursor? maxp = _table("maxp");
    if (maxp != null) {
      maxp.skip(4);
      _numGlyphs = maxp.u16();
    }
    final UDocCursor? hhea = _table("hhea");
    if (hhea != null) {
      hhea.skip(34);
      _numberOfHMetrics = hhea.u16();
    }
    _readLoca();
    _readCmap();
    _readPost();
    final List<int>? cffTable = _tables["CFF "];
    if (cffTable != null) {
      final int end = cffTable[0] + cffTable[1] > _bytes.length ? _bytes.length : cffTable[0] + cffTable[1];
      cff = UPdfCff.parse(Uint8List.sublistView(_bytes, cffTable[0], end));
    }
  }

  void _readLoca() {
    final UDocCursor? loca = _table("loca");
    if (loca == null || _numGlyphs <= 0) return;
    final List<int> offsets = <int>[];
    for (int i = 0; i <= _numGlyphs; i++) {
      if (_indexToLocFormat == 0) {
        if (loca.remaining < 2) break;
        offsets.add(loca.u16() * 2);
      } else {
        if (loca.remaining < 4) break;
        offsets.add(loca.u32());
      }
    }
    _loca = offsets;
  }

  void _readCmap() {
    final UDocCursor? cmap = _table("cmap");
    if (cmap == null) return;
    final int base = cmap.position;
    cmap.skip(2);
    final int count = cmap.u16();
    int unicodeOffset = -1;
    int macOffset = -1;
    int symbolOffset = -1;
    for (int i = 0; i < count && i < 64; i++) {
      if (cmap.remaining < 8) break;
      final int platform = cmap.u16();
      final int encoding = cmap.u16();
      final int offset = cmap.u32();
      if (platform == 3 && (encoding == 1 || encoding == 10)) unicodeOffset = base + offset;
      if (platform == 0) unicodeOffset = unicodeOffset < 0 ? base + offset : unicodeOffset;
      if (platform == 3 && encoding == 0) symbolOffset = base + offset;
      if (platform == 1 && encoding == 0) macOffset = base + offset;
    }
    if (unicodeOffset < 0 && symbolOffset >= 0) unicodeOffset = symbolOffset;
    if (unicodeOffset >= 0) _cmapUnicode = _readCmapSubtable(unicodeOffset);
    if (macOffset >= 0) _cmapMacRoman = _readCmapSubtable(macOffset);
    if (symbolOffset >= 0 && symbolOffset != unicodeOffset) {
      final Map<int, int> symbol = _readCmapSubtable(symbolOffset);
      final Map<int, int> merged = <int, int>{..._cmapUnicode};
      symbol.forEach((int key, int value) {
        merged.putIfAbsent(key, () => value);
        if (key >= 0xF000 && key <= 0xF0FF) merged.putIfAbsent(key - 0xF000, () => value);
      });
      _cmapUnicode = merged;
    }
  }

  Map<int, int> _readCmapSubtable(int offset) {
    final Map<int, int> map = <int, int>{};
    try {
      final UDocCursor cursor = UDocCursor(_bytes, start: offset);
      final int format = cursor.u16();
      if (format == 0) {
        cursor.skip(4);
        for (int i = 0; i < 256; i++) {
          map[i] = cursor.u8();
        }
      } else if (format == 4) {
        cursor.skip(4);
        final int segCountX2 = cursor.u16();
        final int segCount = segCountX2 ~/ 2;
        cursor.skip(6);
        final List<int> endCodes = List<int>.generate(segCount, (int _) => cursor.u16());
        cursor.skip(2);
        final List<int> startCodes = List<int>.generate(segCount, (int _) => cursor.u16());
        final List<int> deltas = List<int>.generate(segCount, (int _) => cursor.i16());
        final int rangeOffsetBase = cursor.position;
        final List<int> rangeOffsets = List<int>.generate(segCount, (int _) => cursor.u16());
        for (int segment = 0; segment < segCount; segment++) {
          final int start = startCodes[segment];
          final int end = endCodes[segment];
          if (start > end || end == 0xFFFF && start == 0xFFFF) continue;
          for (int code = start; code <= end && code - start < 65536; code++) {
            int glyph;
            if (rangeOffsets[segment] == 0) {
              glyph = (code + deltas[segment]) & 0xFFFF;
            } else {
              final int index = rangeOffsetBase + segment * 2 + rangeOffsets[segment] + (code - start) * 2;
              if (index + 1 >= _bytes.length) continue;
              glyph = (_bytes[index] << 8) | _bytes[index + 1];
              if (glyph != 0) glyph = (glyph + deltas[segment]) & 0xFFFF;
            }
            if (glyph != 0) map[code] = glyph;
          }
        }
      } else if (format == 6) {
        cursor.skip(4);
        final int first = cursor.u16();
        final int count = cursor.u16();
        for (int i = 0; i < count; i++) {
          map[first + i] = cursor.u16();
        }
      } else if (format == 12) {
        cursor.skip(10);
        final int groups = cursor.u32();
        for (int i = 0; i < groups && i < 100000; i++) {
          final int start = cursor.u32();
          final int end = cursor.u32();
          final int startGlyph = cursor.u32();
          for (int code = start; code <= end && code - start < 65536; code++) {
            map[code] = startGlyph + (code - start);
          }
        }
      }
    } on Object {
      return map;
    }
    return map;
  }

  void _readPost() {
    final UDocCursor? post = _table("post");
    if (post == null) return;
    try {
      final int version = post.u32();
      if (version != 0x00020000) return;
      post.skip(28);
      final int count = post.u16();
      final List<int> indices = List<int>.generate(count, (int _) => post.u16());
      final List<String> names = <String>[];
      while (!post.isEmpty && names.length < count) {
        final int length = post.u8();
        if (post.remaining < length) break;
        names.add(post.ascii(length));
      }
      final Map<String, int> map = <String, int>{};
      for (int gid = 0; gid < count; gid++) {
        final int index = indices[gid];
        if (index >= 258) {
          final int custom = index - 258;
          if (custom < names.length) map[names[custom]] = gid;
        } else if (index < UPdfStandardNames.macGlyphNames.length) {
          map.putIfAbsent(UPdfStandardNames.macGlyphNames[index], () => gid);
        }
      }
      _postNames = map;
    } on Object {
      return;
    }
  }

  @override
  double advance(int glyphId) {
    final UDocCursor? hmtx = _table("hmtx");
    if (hmtx == null || _numberOfHMetrics <= 0) return _unitsPerEm / 2;
    final int index = glyphId < _numberOfHMetrics ? glyphId : _numberOfHMetrics - 1;
    final int offset = index * 4;
    if (hmtx.remaining < offset + 2) return _unitsPerEm / 2;
    hmtx.skip(offset);
    return hmtx.u16().toDouble();
  }

  @override
  int glyphForUnicode(int codePoint) => _cmapUnicode[codePoint] ?? _cmapUnicode[0xF000 + codePoint] ?? 0;

  int glyphForMacRoman(int code) => _cmapMacRoman[code] ?? 0;

  @override
  int glyphForName(String name) => _postNames[name] ?? cff?.glyphForName(name) ?? 0;

  @override
  Path? glyphPath(int glyphId) {
    if (_pathCache.containsKey(glyphId)) return _pathCache[glyphId];
    Path? path;
    try {
      final UPdfCff? outlines = cff;
      path = outlines != null ? outlines.glyphPath(glyphId) : _glyfPath(glyphId, 0);
    } on Object {
      path = null;
    }
    if (_pathCache.length > 4096) _pathCache.clear();
    _pathCache[glyphId] = path;
    return path;
  }

  Path? _glyfPath(int glyphId, int depth) {
    if (depth > 8 || glyphId < 0 || glyphId + 1 >= _loca.length) return null;
    final List<int>? glyfEntry = _tables["glyf"];
    if (glyfEntry == null) return null;
    final int start = glyfEntry[0] + _loca[glyphId];
    final int end = glyfEntry[0] + _loca[glyphId + 1];
    if (end <= start || end > _bytes.length) return Path();
    final UDocCursor cursor = UDocCursor(_bytes, start: start, end: end);
    final int contourCount = cursor.i16();
    cursor.skip(8);
    if (contourCount < 0) return _compositePath(cursor, depth);
    final List<int> endPoints = List<int>.generate(contourCount, (int _) => cursor.u16());
    final int pointCount = endPoints.isEmpty ? 0 : endPoints.last + 1;
    if (pointCount <= 0 || pointCount > 20000) return Path();
    final int instructionLength = cursor.u16();
    cursor.skip(instructionLength > cursor.remaining ? cursor.remaining : instructionLength);
    final List<int> flags = <int>[];
    while (flags.length < pointCount && !cursor.isEmpty) {
      final int flag = cursor.u8();
      flags.add(flag);
      if (flag & 8 != 0 && !cursor.isEmpty) {
        final int repeat = cursor.u8();
        for (int i = 0; i < repeat && flags.length < pointCount; i++) {
          flags.add(flag);
        }
      }
    }
    while (flags.length < pointCount) {
      flags.add(0);
    }
    final List<int> xs = <int>[];
    int x = 0;
    for (int i = 0; i < pointCount; i++) {
      final int flag = flags[i];
      if (flag & 2 != 0) {
        if (cursor.isEmpty) break;
        final int delta = cursor.u8();
        x += flag & 16 != 0 ? delta : -delta;
      } else if (flag & 16 == 0) {
        if (cursor.remaining < 2) break;
        x += cursor.i16();
      }
      xs.add(x);
    }
    while (xs.length < pointCount) {
      xs.add(x);
    }
    final List<int> ys = <int>[];
    int y = 0;
    for (int i = 0; i < pointCount; i++) {
      final int flag = flags[i];
      if (flag & 4 != 0) {
        if (cursor.isEmpty) break;
        final int delta = cursor.u8();
        y += flag & 32 != 0 ? delta : -delta;
      } else if (flag & 32 == 0) {
        if (cursor.remaining < 2) break;
        y += cursor.i16();
      }
      ys.add(y);
    }
    while (ys.length < pointCount) {
      ys.add(y);
    }
    final Path path = Path();
    int startPoint = 0;
    for (final int endPoint in endPoints) {
      if (endPoint < startPoint || endPoint >= pointCount) {
        startPoint = endPoint + 1;
        continue;
      }
      _emitContour(path, flags, xs, ys, startPoint, endPoint);
      startPoint = endPoint + 1;
    }
    return path;
  }

  void _emitContour(Path path, List<int> flags, List<int> xs, List<int> ys, int start, int end) {
    final int count = end - start + 1;
    if (count <= 0) return;
    bool onCurve(int index) => flags[start + (index % count)] & 1 != 0;
    double pointX(int index) => xs[start + (index % count)].toDouble();
    double pointY(int index) => ys[start + (index % count)].toDouble();

    int firstOnCurve = -1;
    for (int i = 0; i < count; i++) {
      if (onCurve(i)) {
        firstOnCurve = i;
        break;
      }
    }
    double startX;
    double startY;
    if (firstOnCurve < 0) {
      startX = (pointX(0) + pointX(1)) / 2;
      startY = (pointY(0) + pointY(1)) / 2;
      firstOnCurve = 0;
    } else {
      startX = pointX(firstOnCurve);
      startY = pointY(firstOnCurve);
    }
    path.moveTo(startX, startY);
    double currentX = startX;
    double currentY = startY;
    int index = firstOnCurve + 1;
    int processed = 0;
    double? controlX;
    double? controlY;
    while (processed < count) {
      final bool isOn = onCurve(index);
      final double px = pointX(index);
      final double py = pointY(index);
      if (isOn) {
        if (controlX == null) {
          path.lineTo(px, py);
        } else {
          path.quadraticBezierTo(controlX, controlY!, px, py);
          controlX = null;
          controlY = null;
        }
        currentX = px;
        currentY = py;
      } else {
        if (controlX != null) {
          final double midX = (controlX + px) / 2;
          final double midY = (controlY! + py) / 2;
          path.quadraticBezierTo(controlX, controlY, midX, midY);
          currentX = midX;
          currentY = midY;
        }
        controlX = px;
        controlY = py;
      }
      index++;
      processed++;
    }
    if (controlX != null) {
      path.quadraticBezierTo(controlX, controlY!, startX, startY);
    } else if (currentX != startX || currentY != startY) {
      path.lineTo(startX, startY);
    }
    path.close();
  }

  Path? _compositePath(UDocCursor cursor, int depth) {
    final Path path = Path();
    int guard = 0;
    while (guard < 32) {
      guard++;
      if (cursor.remaining < 4) break;
      final int flags = cursor.u16();
      final int glyphIndex = cursor.u16();
      int dx = 0;
      int dy = 0;
      if (flags & 1 != 0) {
        if (cursor.remaining < 4) break;
        dx = cursor.i16();
        dy = cursor.i16();
      } else {
        if (cursor.remaining < 2) break;
        final int packed = cursor.u16();
        dx = (packed >> 8) & 0xFF;
        dy = packed & 0xFF;
        if (dx > 127) dx -= 256;
        if (dy > 127) dy -= 256;
      }
      double scaleX = 1;
      double scaleY = 1;
      double skewX = 0;
      double skewY = 0;
      if (flags & 8 != 0) {
        scaleX = cursor.f2dot14();
        scaleY = scaleX;
      } else if (flags & 64 != 0) {
        scaleX = cursor.f2dot14();
        scaleY = cursor.f2dot14();
      } else if (flags & 128 != 0) {
        scaleX = cursor.f2dot14();
        skewY = cursor.f2dot14();
        skewX = cursor.f2dot14();
        scaleY = cursor.f2dot14();
      }
      final Path? component = _glyfPath(glyphIndex, depth + 1);
      if (component != null) {
        final Float64List matrix = Float64List.fromList(<double>[
          scaleX,
          skewY,
          0,
          0,
          skewX,
          scaleY,
          0,
          0,
          0,
          0,
          1,
          0,
          dx.toDouble(),
          dy.toDouble(),
          0,
          1,
        ]);
        path.addPath(component.transform(matrix), Offset.zero);
      }
      if (flags & 32 == 0) break;
    }
    return path;
  }

  @override
  int glyphForCid(int cid) {
    throw UnimplementedError();
  }
}

class UPdfIndex {
  const UPdfIndex(this.offsets, this.data, this.endOffset);

  final List<int> offsets;
  final Uint8List data;
  final int endOffset;

  int get count => offsets.isEmpty ? 0 : offsets.length - 1;

  Uint8List operator [](int index) {
    if (index < 0 || index + 1 >= offsets.length) return Uint8List(0);
    final int start = offsets[index];
    final int end = offsets[index + 1];
    if (start < 0 || end > data.length || end < start) return Uint8List(0);
    return Uint8List.sublistView(data, start, end);
  }

  static UPdfIndex read(UDocCursor cursor) {
    if (cursor.remaining < 2) return UPdfIndex(const <int>[], Uint8List(0), cursor.position);
    final int count = cursor.u16();
    if (count == 0) return UPdfIndex(const <int>[], Uint8List(0), cursor.position);
    final int offSize = cursor.u8();
    if (offSize < 1 || offSize > 4) return UPdfIndex(const <int>[], Uint8List(0), cursor.position);
    final List<int> offsets = <int>[];
    for (int i = 0; i <= count; i++) {
      int value = 0;
      for (int b = 0; b < offSize; b++) {
        value = (value << 8) | cursor.u8();
      }
      offsets.add(value - 1);
    }
    final int base = cursor.position;
    final int last = offsets.isEmpty ? 0 : offsets.last;
    final int end = base + last;
    final Uint8List data = Uint8List.sublistView(cursor.bytes, base, end > cursor.bytes.length ? cursor.bytes.length : end);
    return UPdfIndex(offsets, data, end);
  }
}

class UPdfCff implements UPdfGlyphSource {
  UPdfCff._(
    this._charStrings,
    this._globalSubrs,
    this._localSubrs,
    this._charsetIds,
    this._isCid,
    this._fdSelect,
    this._fdLocalSubrs,
    this._fontMatrix,
    this._stringIndex,
    this._defaultWidthX,
    this._nominalWidthX,
  );

  final UPdfIndex _charStrings;
  final UPdfIndex _globalSubrs;
  final UPdfIndex _localSubrs;
  final List<int> _charsetIds;
  final bool _isCid;
  final List<int> _fdSelect;
  final List<UPdfIndex> _fdLocalSubrs;
  final List<double> _fontMatrix;
  final UPdfIndex _stringIndex;
  final double _defaultWidthX;
  final double _nominalWidthX;

  final Map<int, Path?> _pathCache = <int, Path?>{};
  final Map<int, double> _widthCache = <int, double>{};
  Map<int, int>? _cidToGid;
  Map<String, int>? _nameToGid;

  bool get isCid => _isCid;

  List<double> get fontMatrix => _fontMatrix;

  @override
  int get unitsPerEm => _fontMatrix[0] == 0 ? 1000 : (1 / _fontMatrix[0]).round();

  @override
  int get glyphCount => _charStrings.count;

  static UPdfCff? parse(Uint8List bytes) {
    try {
      if (bytes.length < 4) return null;
      final int headerSize = bytes[2];
      final UDocCursor cursor = UDocCursor(bytes, start: headerSize);
      UPdfIndex.read(cursor);
      final UDocCursor topCursor = UDocCursor(bytes, start: cursor.position);
      final UPdfIndex topDicts = UPdfIndex.read(topCursor);
      final UDocCursor stringCursor = UDocCursor(bytes, start: topCursor.position);
      final UPdfIndex strings = UPdfIndex.read(stringCursor);
      final UDocCursor globalCursor = UDocCursor(bytes, start: stringCursor.position);
      final UPdfIndex globalSubrs = UPdfIndex.read(globalCursor);
      if (topDicts.count == 0) return null;
      final Map<int, List<num>> top = _readDict(topDicts[0]);
      final int charStringsOffset = (top[17]?.first ?? 0).toInt();
      if (charStringsOffset <= 0 || charStringsOffset >= bytes.length) return null;
      final UPdfIndex charStrings = UPdfIndex.read(UDocCursor(bytes, start: charStringsOffset));
      final bool isCid = top.containsKey(1230);
      final List<double> matrix = top[1207] != null && top[1207]!.length >= 6 ? top[1207]!.map((num value) => value.toDouble()).toList() : <double>[0.001, 0, 0, 0.001, 0, 0];
      UPdfIndex localSubrs = UPdfIndex(const <int>[], Uint8List(0), 0);
      double defaultWidthX = 0;
      double nominalWidthX = 0;
      final List<num>? privateEntry = top[18];
      if (privateEntry != null && privateEntry.length >= 2) {
        final int privateSize = privateEntry[0].toInt();
        final int privateOffset = privateEntry[1].toInt();
        if (privateOffset > 0 && privateOffset + privateSize <= bytes.length) {
          final Map<int, List<num>> private = _readDict(Uint8List.sublistView(bytes, privateOffset, privateOffset + privateSize));
          defaultWidthX = (private[20]?.first ?? 0).toDouble();
          nominalWidthX = (private[21]?.first ?? 0).toDouble();
          final int subrsOffset = (private[19]?.first ?? 0).toInt();
          if (subrsOffset > 0 && privateOffset + subrsOffset < bytes.length) localSubrs = UPdfIndex.read(UDocCursor(bytes, start: privateOffset + subrsOffset));
        }
      }
      final List<int> charsetIds = _readCharset(bytes, (top[15]?.first ?? 0).toInt(), charStrings.count);
      final List<int> fdSelect = <int>[];
      final List<UPdfIndex> fdLocalSubrs = <UPdfIndex>[];
      if (isCid) {
        final int fdArrayOffset = (top[1236]?.first ?? 0).toInt();
        final int fdSelectOffset = (top[1237]?.first ?? 0).toInt();
        if (fdArrayOffset > 0 && fdArrayOffset < bytes.length) {
          final UPdfIndex fdArray = UPdfIndex.read(UDocCursor(bytes, start: fdArrayOffset));
          for (int i = 0; i < fdArray.count; i++) {
            final Map<int, List<num>> fontDict = _readDict(fdArray[i]);
            final List<num>? fdPrivate = fontDict[18];
            UPdfIndex subrs = UPdfIndex(const <int>[], Uint8List(0), 0);
            if (fdPrivate != null && fdPrivate.length >= 2) {
              final int size = fdPrivate[0].toInt();
              final int offset = fdPrivate[1].toInt();
              if (offset > 0 && offset + size <= bytes.length) {
                final Map<int, List<num>> private = _readDict(Uint8List.sublistView(bytes, offset, offset + size));
                final int subrsOffset = (private[19]?.first ?? 0).toInt();
                if (subrsOffset > 0 && offset + subrsOffset < bytes.length) subrs = UPdfIndex.read(UDocCursor(bytes, start: offset + subrsOffset));
              }
            }
            fdLocalSubrs.add(subrs);
          }
        }
        if (fdSelectOffset > 0 && fdSelectOffset < bytes.length) fdSelect.addAll(_readFdSelect(bytes, fdSelectOffset, charStrings.count));
      }
      return UPdfCff._(charStrings, globalSubrs, localSubrs, charsetIds, isCid, fdSelect, fdLocalSubrs, matrix, strings, defaultWidthX, nominalWidthX);
    } on Object {
      return null;
    }
  }

  static Map<int, List<num>> _readDict(Uint8List bytes) {
    final Map<int, List<num>> dict = <int, List<num>>{};
    final List<num> operands = <num>[];
    int index = 0;
    while (index < bytes.length) {
      final int byte = bytes[index];
      if (byte <= 21) {
        int key = byte;
        index++;
        if (byte == 12 && index < bytes.length) {
          key = 1200 + bytes[index];
          index++;
        }
        dict[key] = List<num>.from(operands);
        operands.clear();
        continue;
      }
      if (byte == 28) {
        if (index + 2 >= bytes.length) break;
        int value = (bytes[index + 1] << 8) | bytes[index + 2];
        if (value > 32767) value -= 65536;
        operands.add(value);
        index += 3;
        continue;
      }
      if (byte == 29) {
        if (index + 4 >= bytes.length) break;
        int value = (bytes[index + 1] << 24) | (bytes[index + 2] << 16) | (bytes[index + 3] << 8) | bytes[index + 4];
        if (value > 2147483647) value -= 4294967296;
        operands.add(value);
        index += 5;
        continue;
      }
      if (byte == 30) {
        final StringBuffer buffer = StringBuffer();
        index++;
        bool done = false;
        while (index < bytes.length && !done) {
          final int packed = bytes[index++];
          for (final int nibble in <int>[packed >> 4, packed & 0x0F]) {
            if (nibble <= 9) {
              buffer.write(nibble);
            } else if (nibble == 10) {
              buffer.write(".");
            } else if (nibble == 11) {
              buffer.write("E");
            } else if (nibble == 12) {
              buffer.write("E-");
            } else if (nibble == 14) {
              buffer.write("-");
            } else if (nibble == 15) {
              done = true;
              break;
            }
          }
        }
        operands.add(double.tryParse(buffer.toString()) ?? 0);
        continue;
      }
      if (byte >= 32 && byte <= 246) {
        operands.add(byte - 139);
        index++;
        continue;
      }
      if (byte >= 247 && byte <= 250) {
        if (index + 1 >= bytes.length) break;
        operands.add((byte - 247) * 256 + bytes[index + 1] + 108);
        index += 2;
        continue;
      }
      if (byte >= 251 && byte <= 254) {
        if (index + 1 >= bytes.length) break;
        operands.add(-(byte - 251) * 256 - bytes[index + 1] - 108);
        index += 2;
        continue;
      }
      index++;
    }
    return dict;
  }

  static List<int> _readCharset(Uint8List bytes, int offset, int glyphCount) {
    final List<int> ids = List<int>.filled(glyphCount, 0);
    for (int i = 0; i < glyphCount; i++) {
      ids[i] = i;
    }
    if (offset <= 2 || offset >= bytes.length || glyphCount <= 0) return ids;
    try {
      final UDocCursor cursor = UDocCursor(bytes, start: offset);
      final int format = cursor.u8();
      ids[0] = 0;
      int gid = 1;
      if (format == 0) {
        while (gid < glyphCount && cursor.remaining >= 2) {
          ids[gid++] = cursor.u16();
        }
      } else if (format == 1 || format == 2) {
        while (gid < glyphCount && cursor.remaining >= (format == 1 ? 3 : 4)) {
          final int first = cursor.u16();
          final int left = format == 1 ? cursor.u8() : cursor.u16();
          for (int i = 0; i <= left && gid < glyphCount; i++) {
            ids[gid++] = first + i;
          }
        }
      }
    } on Object {
      return ids;
    }
    return ids;
  }

  static List<int> _readFdSelect(Uint8List bytes, int offset, int glyphCount) {
    final List<int> select = List<int>.filled(glyphCount, 0);
    try {
      final UDocCursor cursor = UDocCursor(bytes, start: offset);
      final int format = cursor.u8();
      if (format == 0) {
        for (int i = 0; i < glyphCount && !cursor.isEmpty; i++) {
          select[i] = cursor.u8();
        }
      } else if (format == 3) {
        final int ranges = cursor.u16();
        int first = cursor.u16();
        for (int i = 0; i < ranges; i++) {
          if (cursor.remaining < 3) break;
          final int fd = cursor.u8();
          final int next = cursor.u16();
          for (int gid = first; gid < next && gid < glyphCount; gid++) {
            select[gid] = fd;
          }
          first = next;
        }
      }
    } on Object {
      return select;
    }
    return select;
  }

  String _stringForSid(int sid) {
    if (sid < UPdfStandardNames.cffStandardStrings.length) return UPdfStandardNames.cffStandardStrings[sid];
    final int index = sid - UPdfStandardNames.cffStandardStrings.length;
    if (index < 0 || index >= _stringIndex.count) return "";
    return String.fromCharCodes(_stringIndex[index]);
  }

  @override
  int glyphForName(String name) {
    final Map<String, int>? cached = _nameToGid;
    if (cached != null) return cached[name] ?? 0;
    final Map<String, int> map = <String, int>{};
    if (!_isCid) {
      for (int gid = 0; gid < _charsetIds.length; gid++) {
        map.putIfAbsent(_stringForSid(_charsetIds[gid]), () => gid);
      }
    }
    _nameToGid = map;
    return map[name] ?? 0;
  }

  @override
  int glyphForCid(int cid) {
    if (!_isCid) return cid;
    final Map<int, int>? cached = _cidToGid;
    if (cached != null) return cached[cid] ?? 0;
    final Map<int, int> map = <int, int>{};
    for (int gid = 0; gid < _charsetIds.length; gid++) {
      map.putIfAbsent(_charsetIds[gid], () => gid);
    }
    _cidToGid = map;
    return map[cid] ?? 0;
  }

  @override
  double advance(int glyphId) {
    final double? cached = _widthCache[glyphId];
    if (cached != null) return cached;
    glyphPath(glyphId);
    return _widthCache[glyphId] ?? _defaultWidthX;
  }

  @override
  Path? glyphPath(int glyphId) {
    if (_pathCache.containsKey(glyphId)) return _pathCache[glyphId];
    Path? path;
    try {
      final _UPdfType2Interpreter interpreter = _UPdfType2Interpreter(
        charStrings: _charStrings,
        globalSubrs: _globalSubrs,
        localSubrs: _isCid && _fdLocalSubrs.isNotEmpty ? _fdLocalSubrs[glyphId < _fdSelect.length ? _fdSelect[glyphId].clamp(0, _fdLocalSubrs.length - 1) : 0] : _localSubrs,
        nominalWidthX: _nominalWidthX,
        defaultWidthX: _defaultWidthX,
        owner: this,
      );
      path = interpreter.run(glyphId);
      _widthCache[glyphId] = interpreter.width;
    } on Object {
      path = null;
    }
    if (_pathCache.length > 4096) _pathCache.clear();
    _pathCache[glyphId] = path;
    return path;
  }

  int glyphForStandardCode(int code) {
    final String name = code >= 0 && code < UPdfStandardNames.standardEncoding.length ? UPdfStandardNames.standardEncoding[code] : "";
    return name.isEmpty ? 0 : glyphForName(name);
  }

  @override
  int glyphForUnicode(int codePoint) {
    throw UnimplementedError();
  }
}

class _UPdfType2Interpreter {
  _UPdfType2Interpreter({
    required this.charStrings,
    required this.globalSubrs,
    required this.localSubrs,
    required this.nominalWidthX,
    required this.defaultWidthX,
    required this.owner,
  });

  final UPdfIndex charStrings;
  final UPdfIndex globalSubrs;
  final UPdfIndex localSubrs;
  final double nominalWidthX;
  final double defaultWidthX;
  final UPdfCff owner;

  final List<double> _stack = <double>[];
  final List<double> _transient = List<double>.filled(32, 0);
  final Path _path = Path();

  double _x = 0;
  double _y = 0;
  int _stems = 0;
  bool _widthParsed = false;
  bool _open = false;
  double width = 0;

  static int _bias(int count) => count < 1240 ? 107 : (count < 33900 ? 1131 : 32768);

  Path run(int glyphId) {
    width = defaultWidthX;
    final Uint8List charString = charStrings[glyphId];
    if (charString.isEmpty) return _path;
    _execute(charString, 0);
    if (_open) _path.close();
    return _path;
  }

  void _moveTo(double x, double y) {
    if (_open) _path.close();
    _path.moveTo(x, y);
    _open = true;
  }

  void _execute(Uint8List code, int depth) {
    if (depth > 10) return;
    int index = 0;
    while (index < code.length) {
      final int byte = code[index++];
      if (byte >= 32 || byte == 28) {
        if (byte == 28) {
          if (index + 1 >= code.length) return;
          int value = (code[index] << 8) | code[index + 1];
          if (value > 32767) value -= 65536;
          _stack.add(value.toDouble());
          index += 2;
        } else if (byte <= 246) {
          _stack.add((byte - 139).toDouble());
        } else if (byte <= 250) {
          if (index >= code.length) return;
          _stack.add(((byte - 247) * 256 + code[index++] + 108).toDouble());
        } else if (byte <= 254) {
          if (index >= code.length) return;
          _stack.add((-(byte - 251) * 256 - code[index++] - 108).toDouble());
        } else {
          if (index + 3 >= code.length) return;
          int value = (code[index] << 24) | (code[index + 1] << 16) | (code[index + 2] << 8) | code[index + 3];
          if (value > 2147483647) value -= 4294967296;
          _stack.add(value / 65536);
          index += 4;
        }
        if (_stack.length > 96) _stack.removeRange(0, _stack.length - 96);
        continue;
      }
      switch (byte) {
        case 1:
        case 3:
        case 18:
        case 23:
          if (!_widthParsed && _stack.length % 2 == 1) width = nominalWidthX + _stack.removeAt(0);
          _widthParsed = true;
          _stems += _stack.length ~/ 2;
          _stack.clear();
          break;
        case 19:
        case 20:
          if (!_widthParsed && _stack.length % 2 == 1) width = nominalWidthX + _stack.removeAt(0);
          _widthParsed = true;
          _stems += _stack.length ~/ 2;
          _stack.clear();
          index += (_stems + 7) ~/ 8;
          break;
        case 21:
          if (!_widthParsed && _stack.length > 2) width = nominalWidthX + _stack.removeAt(0);
          _widthParsed = true;
          if (_stack.length >= 2) {
            _x += _stack[0];
            _y += _stack[1];
          }
          _moveTo(_x, _y);
          _stack.clear();
          break;
        case 22:
          if (!_widthParsed && _stack.length > 1) width = nominalWidthX + _stack.removeAt(0);
          _widthParsed = true;
          if (_stack.isNotEmpty) _x += _stack[0];
          _moveTo(_x, _y);
          _stack.clear();
          break;
        case 4:
          if (!_widthParsed && _stack.length > 1) width = nominalWidthX + _stack.removeAt(0);
          _widthParsed = true;
          if (_stack.isNotEmpty) _y += _stack[0];
          _moveTo(_x, _y);
          _stack.clear();
          break;
        case 5:
          for (int i = 0; i + 1 < _stack.length; i += 2) {
            _x += _stack[i];
            _y += _stack[i + 1];
            _path.lineTo(_x, _y);
          }
          _stack.clear();
          break;
        case 6:
        case 7:
          {
            bool horizontal = byte == 6;
            for (int i = 0; i < _stack.length; i++) {
              if (horizontal) {
                _x += _stack[i];
              } else {
                _y += _stack[i];
              }
              _path.lineTo(_x, _y);
              horizontal = !horizontal;
            }
            _stack.clear();
          }
          break;
        case 8:
          for (int i = 0; i + 5 < _stack.length; i += 6) {
            _curve(_stack[i], _stack[i + 1], _stack[i + 2], _stack[i + 3], _stack[i + 4], _stack[i + 5]);
          }
          _stack.clear();
          break;
        case 24:
          {
            int i = 0;
            for (; i + 7 < _stack.length; i += 6) {
              _curve(_stack[i], _stack[i + 1], _stack[i + 2], _stack[i + 3], _stack[i + 4], _stack[i + 5]);
            }
            if (i + 1 < _stack.length) {
              _x += _stack[i];
              _y += _stack[i + 1];
              _path.lineTo(_x, _y);
            }
            _stack.clear();
          }
          break;
        case 25:
          {
            int j = 0;
            for (; j + 7 < _stack.length; j += 2) {
              _x += _stack[j];
              _y += _stack[j + 1];
              _path.lineTo(_x, _y);
            }
            if (j + 5 < _stack.length) _curve(_stack[j], _stack[j + 1], _stack[j + 2], _stack[j + 3], _stack[j + 4], _stack[j + 5]);
            _stack.clear();
          }
          break;
        case 26:
        case 27:
          {
            int k = 0;
            double extra = 0;
            if (_stack.length % 4 == 1) {
              extra = _stack[0];
              k = 1;
            }
            for (; k + 3 < _stack.length; k += 4) {
              if (byte == 26) {
                _curve(extra, _stack[k], _stack[k + 1], _stack[k + 2], 0, _stack[k + 3]);
              } else {
                _curve(_stack[k], extra, _stack[k + 1], _stack[k + 2], _stack[k + 3], 0);
              }
              extra = 0;
            }
            _stack.clear();
          }
          break;
        case 30:
        case 31:
          {
            bool startHorizontal = byte == 31;
            int position = 0;
            while (position + 3 < _stack.length) {
              final bool last = _stack.length - position == 5;
              if (startHorizontal) {
                _curve(_stack[position], 0, _stack[position + 1], _stack[position + 2], last ? _stack[position + 4] : 0, _stack[position + 3]);
              } else {
                _curve(0, _stack[position], _stack[position + 1], _stack[position + 2], _stack[position + 3], last ? _stack[position + 4] : 0);
              }
              position += last ? 5 : 4;
              startHorizontal = !startHorizontal;
            }
            _stack.clear();
          }
          break;
        case 10:
          {
            if (_stack.isEmpty) break;
            final int localIndex = _stack.removeLast().toInt() + _bias(localSubrs.count);
            if (localIndex >= 0 && localIndex < localSubrs.count) _execute(localSubrs[localIndex], depth + 1);
          }
          break;
        case 29:
          {
            if (_stack.isEmpty) break;
            final int globalIndex = _stack.removeLast().toInt() + _bias(globalSubrs.count);
            if (globalIndex >= 0 && globalIndex < globalSubrs.count) _execute(globalSubrs[globalIndex], depth + 1);
          }
          break;
        case 11:
          return;
        case 14:
          if (!_widthParsed && (_stack.length == 1 || _stack.length == 5)) width = nominalWidthX + _stack.removeAt(0);
          _widthParsed = true;
          if (_stack.length >= 4) _seac();
          if (_open) _path.close();
          _open = false;
          _stack.clear();
          return;
        case 12:
          if (index >= code.length) return;
          _escape(code[index++]);
          break;
        default:
          _stack.clear();
          break;
      }
    }
  }

  void _seac() {
    final int achar = _stack.removeLast().toInt();
    final int bchar = _stack.removeLast().toInt();
    final double ady = _stack.removeLast();
    final double adx = _stack.removeLast();
    final Path? base = owner.glyphPath(owner.glyphForStandardCode(bchar));
    final Path? accent = owner.glyphPath(owner.glyphForStandardCode(achar));
    if (base != null) _path.addPath(base, Offset.zero);
    if (accent != null) _path.addPath(accent, Offset(adx, ady));
  }

  void _escape(int operator) {
    switch (operator) {
      case 35:
        if (_stack.length >= 13) {
          _curve(_stack[0], _stack[1], _stack[2], _stack[3], _stack[4], _stack[5]);
          _curve(_stack[6], _stack[7], _stack[8], _stack[9], _stack[10], _stack[11]);
        }
        _stack.clear();
        break;
      case 34:
        if (_stack.length >= 7) {
          final double startY = _y;
          _curve(_stack[0], 0, _stack[1], _stack[2], _stack[3], 0);
          _curve(_stack[4], 0, _stack[5], startY - (_y + _stack[2]), _stack[6], 0);
        }
        _stack.clear();
        break;
      case 36:
        if (_stack.length >= 9) {
          final double startY = _y;
          _curve(_stack[0], _stack[1], _stack[2], _stack[3], _stack[4], 0);
          _curve(_stack[5], 0, _stack[6], _stack[7], _stack[8], startY - _y - _stack[1] - _stack[3] - _stack[7]);
        }
        _stack.clear();
        break;
      case 37:
        if (_stack.length >= 11) {
          final double startX = _x;
          final double startY = _y;
          _curve(_stack[0], _stack[1], _stack[2], _stack[3], _stack[4], _stack[5]);
          final double dx = _stack[6];
          final double dy = _stack[7];
          final double dx2 = _stack[8];
          final double dy2 = _stack[9];
          final double last = _stack[10];
          final double sumX = _x + dx + dx2;
          final double sumY = _y + dy + dy2;
          final bool horizontal = (sumX - startX).abs() > (sumY - startY).abs();
          _curve(dx, dy, dx2, dy2, horizontal ? last : startX - sumX, horizontal ? startY - sumY : last);
        }
        _stack.clear();
        break;
      case 3:
      case 4:
      case 5:
      case 9:
      case 10:
      case 11:
      case 12:
      case 14:
      case 15:
      case 18:
      case 21:
      case 22:
      case 23:
      case 24:
      case 26:
      case 27:
      case 28:
      case 29:
      case 30:
        _stack.clear();
        break;
      case 20:
        if (_stack.length >= 2) {
          final int slot = _stack.removeLast().toInt();
          final double value = _stack.removeLast();
          if (slot >= 0 && slot < _transient.length) _transient[slot] = value;
        }
        break;
      default:
        _stack.clear();
        break;
    }
  }

  void _curve(double dx1, double dy1, double dx2, double dy2, double dx3, double dy3) {
    final double c1x = _x + dx1;
    final double c1y = _y + dy1;
    final double c2x = c1x + dx2;
    final double c2y = c1y + dy2;
    _x = c2x + dx3;
    _y = c2y + dy3;
    if (!_open) _moveTo(c1x, c1y);
    _path.cubicTo(c1x, c1y, c2x, c2y, _x, _y);
  }
}

abstract class UPdfStandardNames {
  static const String _cffStrings =
      ".notdef space exclam quotedbl numbersign dollar percent ampersand quoteright parenleft parenright asterisk plus comma hyphen period slash zero one two three four five six seven eight nine colon semicolon less equal greater question at "
      "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z bracketleft backslash bracketright asciicircum underscore quoteleft "
      "a b c d e f g h i j k l m n o p q r s t u v w x y z braceleft bar braceright asciitilde exclamdown cent sterling fraction yen florin section currency quotesingle quotedblleft guillemotleft guilsinglleft guilsinglright fi fl endash dagger daggerdbl periodcentered paragraph bullet quotesinglbase quotedblbase quotedblright guillemotright ellipsis perthousand questiondown grave acute circumflex tilde macron breve dotaccent dieresis ring cedilla hungarumlaut ogonek caron emdash AE ordfeminine Lslash Oslash OE ordmasculine ae dotlessi lslash oslash oe germandbls onesuperior logicalnot mu trademark Eth onehalf plusminus Thorn onequarter divide brokenbar degree thorn threequarters twosuperior registered minus eth multiply threesuperior copyright "
      "Aacute Acircumflex Adieresis Agrave Aring Atilde Ccedilla Eacute Ecircumflex Edieresis Egrave Iacute Icircumflex Idieresis Igrave Ntilde Oacute Ocircumflex Odieresis Ograve Otilde Scaron Uacute Ucircumflex Udieresis Ugrave Yacute Ydieresis Zcaron "
      "aacute acircumflex adieresis agrave aring atilde ccedilla eacute ecircumflex edieresis egrave iacute icircumflex idieresis igrave ntilde oacute ocircumflex odieresis ograve otilde scaron uacute ucircumflex udieresis ugrave yacute ydieresis zcaron "
      "exclamsmall Hungarumlautsmall dollaroldstyle dollarsuperior ampersandsmall Acutesmall parenleftsuperior parenrightsuperior twodotenleader onedotenleader zerooldstyle oneoldstyle twooldstyle threeoldstyle fouroldstyle fiveoldstyle sixoldstyle sevenoldstyle eightoldstyle nineoldstyle commasuperior threequartersemdash periodsuperior questionsmall asuperior bsuperior centsuperior dsuperior esuperior isuperior lsuperior msuperior nsuperior osuperior rsuperior ssuperior tsuperior ff ffi ffl parenleftinferior parenrightinferior Circumflexsmall hyphensuperior Gravesmall "
      "Asmall Bsmall Csmall Dsmall Esmall Fsmall Gsmall Hsmall Ismall Jsmall Ksmall Lsmall Msmall Nsmall Osmall Psmall Qsmall Rsmall Ssmall Tsmall Usmall Vsmall Wsmall Xsmall Ysmall Zsmall "
      "colonmonetary onefitted rupiah Tildesmall exclamdownsmall centoldstyle Lslashsmall Scaronsmall Zcaronsmall Dieresissmall Brevesmall Caronsmall Dotaccentsmall Macronsmall figuredash hypheninferior Ogoneksmall Ringsmall Cedillasmall questiondownsmall oneeighth threeeighths fiveeighths seveneighths onethird twothirds zerosuperior foursuperior fivesuperior sixsuperior sevensuperior eightsuperior ninesuperior zeroinferior oneinferior twoinferior threeinferior fourinferior fiveinferior sixinferior seveninferior eightinferior nineinferior centinferior dollarinferior periodinferior commainferior "
      "Agravesmall Aacutesmall Acircumflexsmall Atildesmall Adieresissmall Aringsmall AEsmall Ccedillasmall Egravesmall Eacutesmall Ecircumflexsmall Edieresissmall Igravesmall Iacutesmall Icircumflexsmall Idieresissmall Ethsmall Ntildesmall Ogravesmall Oacutesmall Ocircumflexsmall Otildesmall Odieresissmall OEsmall Oslashsmall Ugravesmall Uacutesmall Ucircumflexsmall Udieresissmall Yacutesmall Thornsmall Ydieresissmall "
      "001.000 001.001 001.002 001.003 Black Bold Book Light Medium Regular Roman Semibold";

  static const String _macGlyphs =
      ".notdef .null nonmarkingreturn space exclam quotedbl numbersign dollar percent ampersand quotesingle parenleft parenright asterisk plus comma hyphen period slash zero one two three four five six seven eight nine colon semicolon less equal greater question at "
      "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z bracketleft backslash bracketright asciicircum underscore grave "
      "a b c d e f g h i j k l m n o p q r s t u v w x y z braceleft bar braceright asciitilde "
      "Adieresis Aring Ccedilla Eacute Ntilde Odieresis Udieresis aacute agrave acircumflex adieresis atilde aring ccedilla eacute egrave ecircumflex edieresis iacute igrave icircumflex idieresis ntilde oacute ograve ocircumflex odieresis otilde uacute ugrave ucircumflex udieresis dagger degree cent sterling section bullet paragraph germandbls registered copyright trademark acute dieresis notequal AE Oslash infinity plusminus lessequal greaterequal yen mu partialdiff summation product pi integral ordfeminine ordmasculine Omega ae oslash questiondown exclamdown logicalnot radical florin approxequal Delta guillemotleft guillemotright ellipsis nonbreakingspace Agrave Atilde Otilde OE oe endash emdash quotedblleft quotedblright quoteleft quoteright divide lozenge ydieresis Ydieresis fraction currency guilsinglleft guilsinglright fi fl daggerdbl periodcentered quotesinglbase quotedblbase perthousand Acircumflex Ecircumflex Aacute Edieresis Egrave Iacute Icircumflex Idieresis Igrave Oacute Ocircumflex apple Ograve Uacute Ucircumflex Ugrave dotlessi circumflex tilde macron breve dotaccent ring cedilla hungarumlaut ogonek caron Lslash lslash Scaron scaron Zcaron zcaron brokenbar Eth eth Yacute yacute Thorn thorn minus multiply onesuperior twosuperior threesuperior onehalf onequarter threequarters franc Gbreve gbreve Idotaccent Scedilla scedilla Cacute cacute Ccaron ccaron dcroat";

  static const String _winAnsiHigh =
      "Euro .notdef quotesinglbase florin quotedblbase ellipsis dagger daggerdbl circumflex perthousand Scaron guilsinglleft OE .notdef Zcaron .notdef "
      ".notdef quoteleft quoteright quotedblleft quotedblright bullet endash emdash tilde trademark scaron guilsinglright oe .notdef zcaron Ydieresis "
      "space exclamdown cent sterling currency yen brokenbar section dieresis copyright ordfeminine guillemotleft logicalnot hyphen registered macron "
      "degree plusminus twosuperior threesuperior acute mu paragraph periodcentered cedilla onesuperior ordmasculine guillemotright onequarter onehalf threequarters questiondown "
      "Agrave Aacute Acircumflex Atilde Adieresis Aring AE Ccedilla Egrave Eacute Ecircumflex Edieresis Igrave Iacute Icircumflex Idieresis "
      "Eth Ntilde Ograve Oacute Ocircumflex Otilde Odieresis multiply Oslash Ugrave Uacute Ucircumflex Udieresis Yacute Thorn germandbls "
      "agrave aacute acircumflex atilde adieresis aring ae ccedilla egrave eacute ecircumflex edieresis igrave iacute icircumflex idieresis "
      "eth ntilde ograve oacute ocircumflex otilde odieresis divide oslash ugrave uacute ucircumflex udieresis yacute thorn ydieresis";

  static const String _macRomanHigh =
      "Adieresis Aring Ccedilla Eacute Ntilde Odieresis Udieresis aacute agrave acircumflex adieresis atilde aring ccedilla eacute egrave "
      "ecircumflex edieresis iacute igrave icircumflex idieresis ntilde oacute ograve ocircumflex odieresis otilde uacute ugrave ucircumflex udieresis "
      "dagger degree cent sterling section bullet paragraph germandbls registered copyright trademark acute dieresis notequal AE Oslash "
      "infinity plusminus lessequal greaterequal yen mu partialdiff summation product pi integral ordfeminine ordmasculine Omega ae oslash "
      "questiondown exclamdown logicalnot radical florin approxequal Delta guillemotleft guillemotright ellipsis space Agrave Atilde Otilde OE oe "
      "endash emdash quotedblleft quotedblright quoteleft quoteright divide lozenge ydieresis Ydieresis fraction currency guilsinglleft guilsinglright fi fl "
      "daggerdbl periodcentered quotesinglbase quotedblbase perthousand Acircumflex Ecircumflex Aacute Edieresis Egrave Iacute Icircumflex Idieresis Igrave Oacute Ocircumflex "
      "apple Ograve Uacute Ucircumflex Ugrave dotlessi circumflex tilde macron breve dotaccent ring cedilla hungarumlaut ogonek caron";

  static const String _standardHigh =
      "161 exclamdown 162 cent 163 sterling 164 fraction 165 yen 166 florin 167 section 168 currency 169 quotesingle 170 quotedblleft 171 guillemotleft "
      "172 guilsinglleft 173 guilsinglright 174 fi 175 fl 177 endash 178 dagger 179 daggerdbl 180 periodcentered 182 paragraph 183 bullet "
      "184 quotesinglbase 185 quotedblbase 186 quotedblright 187 guillemotright 188 ellipsis 189 perthousand 191 questiondown 193 grave 194 acute "
      "195 circumflex 196 tilde 197 macron 198 breve 199 dotaccent 200 dieresis 202 ring 203 cedilla 205 hungarumlaut 206 ogonek 207 caron "
      "208 emdash 225 AE 227 ordfeminine 232 Lslash 233 Oslash 234 OE 235 ordmasculine 241 ae 245 dotlessi 248 lslash 249 oslash 250 oe 251 germandbls";

  static const String _extraUnicode =
      "fi FB01 fl FB02 dotlessi 0131 Lslash 0141 lslash 0142 OE 0152 oe 0153 Scaron 0160 scaron 0161 Zcaron 017D zcaron 017E Ydieresis 0178 "
      "florin 0192 circumflex 02C6 tilde 02DC Delta 0394 Omega 03A9 pi 03C0 quoteleft 2018 quoteright 2019 quotesinglbase 201A quotedblleft 201C "
      "quotedblright 201D quotedblbase 201E dagger 2020 daggerdbl 2021 bullet 2022 endash 2013 emdash 2014 ellipsis 2026 perthousand 2030 "
      "guilsinglleft 2039 guilsinglright 203A fraction 2044 Euro 20AC trademark 2122 partialdiff 2202 summation 2211 product 220F minus 2212 "
      "radical 221A infinity 221E integral 222B approxequal 2248 notequal 2260 lessequal 2264 greaterequal 2265 lozenge 25CA apple F8FF "
      "nonbreakingspace 00A0 nonmarkingreturn 000D .null 0000 space 0020 quotesingle 0027 grave 0060 ff FB00 ffi FB03 ffl FB04";

  static List<String>? _cffCache;
  static List<String>? _macCache;
  static List<String>? _standardCache;
  static List<String>? _winAnsiCache;
  static List<String>? _macRomanCache;
  static Map<String, int>? _unicodeCache;

  static List<String> get cffStandardStrings => _cffCache ??= _cffStrings.split(" ").where((String value) => value.isNotEmpty).toList();

  static List<String> get macGlyphNames => _macCache ??= _macGlyphs.split(" ").where((String value) => value.isNotEmpty).toList();

  static List<String> get standardEncoding {
    final List<String>? cached = _standardCache;
    if (cached != null) return cached;
    final List<String> table = List<String>.filled(256, "");
    final List<String> strings = cffStandardStrings;
    for (int code = 32; code <= 126; code++) {
      final int index = code - 31;
      if (index < strings.length) table[code] = strings[index];
    }
    final List<String> pairs = _standardHigh.split(" ").where((String value) => value.isNotEmpty).toList();
    for (int i = 0; i + 1 < pairs.length; i += 2) {
      final int? code = int.tryParse(pairs[i]);
      if (code != null && code < 256) table[code] = pairs[i + 1];
    }
    _standardCache = table;
    return table;
  }

  static List<String> get winAnsiEncoding {
    final List<String>? cached = _winAnsiCache;
    if (cached != null) return cached;
    final List<String> table = List<String>.filled(256, "");
    final List<String> strings = cffStandardStrings;
    for (int code = 32; code <= 126; code++) {
      final int index = code - 31;
      if (index < strings.length) table[code] = strings[index];
    }
    table[39] = "quotesingle";
    table[96] = "grave";
    final List<String> high = _winAnsiHigh.split(" ").where((String value) => value.isNotEmpty).toList();
    for (int i = 0; i < high.length && 128 + i < 256; i++) {
      if (high[i] != ".notdef") table[128 + i] = high[i];
    }
    _winAnsiCache = table;
    return table;
  }

  static List<String> get macRomanEncoding {
    final List<String>? cached = _macRomanCache;
    if (cached != null) return cached;
    final List<String> table = List<String>.filled(256, "");
    final List<String> strings = cffStandardStrings;
    for (int code = 32; code <= 126; code++) {
      final int index = code - 31;
      if (index < strings.length) table[code] = strings[index];
    }
    table[39] = "quotesingle";
    table[96] = "grave";
    final List<String> high = _macRomanHigh.split(" ").where((String value) => value.isNotEmpty).toList();
    for (int i = 0; i < high.length && 128 + i < 256; i++) {
      table[128 + i] = high[i];
    }
    _macRomanCache = table;
    return table;
  }

  static Map<String, int> get glyphNameToUnicode {
    final Map<String, int>? cached = _unicodeCache;
    if (cached != null) return cached;
    final Map<String, int> map = <String, int>{};
    final List<String> win = winAnsiEncoding;
    for (int code = 32; code <= 126; code++) {
      if (win[code].isNotEmpty) map.putIfAbsent(win[code], () => code);
    }
    for (int code = 160; code <= 255; code++) {
      if (win[code].isNotEmpty) map.putIfAbsent(win[code], () => code);
    }
    final List<String> pairs = _extraUnicode.split(" ").where((String value) => value.isNotEmpty).toList();
    for (int i = 0; i + 1 < pairs.length; i += 2) {
      final int? value = int.tryParse(pairs[i + 1], radix: 16);
      if (value != null) map[pairs[i]] = value;
    }
    _unicodeCache = map;
    return map;
  }

  static int unicodeForGlyphName(String name) {
    if (name.isEmpty) return -1;
    final int? direct = glyphNameToUnicode[name];
    if (direct != null) return direct;
    if (name.length == 1) return name.codeUnitAt(0);
    if (name.startsWith("uni") && name.length >= 7) {
      final int? value = int.tryParse(name.substring(3, 7), radix: 16);
      if (value != null) return value;
    }
    if (name.startsWith("u") && name.length >= 5 && name.length <= 7) {
      final int? value = int.tryParse(name.substring(1), radix: 16);
      if (value != null) return value;
    }
    final int dot = name.indexOf(".");
    if (dot > 0) return unicodeForGlyphName(name.substring(0, dot));
    final RegExpMatch? indexed = RegExp(r"^(?:g|cid|c|G)(\d+)$").firstMatch(name);
    if (indexed != null) return -1;
    return -1;
  }
}

class UPdfType1 implements UPdfGlyphSource {
  UPdfType1._(this._charStrings, this._subrs, this._encoding, this._fontMatrix);

  final Map<String, Uint8List> _charStrings;
  final List<Uint8List> _subrs;
  final List<String> _encoding;
  final List<double> _fontMatrix;

  final Map<String, Path?> _pathCache = <String, Path?>{};
  final Map<String, double> _widthCache = <String, double>{};
  List<String>? _names;

  List<String> get glyphNames => _names ??= _charStrings.keys.toList();

  List<String> get builtinEncoding => _encoding;

  @override
  int get unitsPerEm => _fontMatrix[0] == 0 ? 1000 : (1 / _fontMatrix[0]).round();

  @override
  int get glyphCount => _charStrings.length;

  static UPdfType1? parse(Uint8List bytes) {
    try {
      Uint8List data = bytes;
      if (data.length > 6 && data[0] == 0x80) {
        final List<int> joined = <int>[];
        int index = 0;
        while (index + 6 <= data.length && data[index] == 0x80) {
          final int type = data[index + 1];
          if (type == 3) break;
          final int length = data[index + 2] | (data[index + 3] << 8) | (data[index + 4] << 16) | (data[index + 5] << 24);
          final int start = index + 6;
          final int end = start + length > data.length ? data.length : start + length;
          joined.addAll(Uint8List.sublistView(data, start, end));
          index = end;
        }
        data = Uint8List.fromList(joined);
      }
      final int eexecIndex = UDocCursor(data).indexOf(const <int>[0x65, 0x65, 0x78, 0x65, 0x63]);
      final String clearText = String.fromCharCodes(Uint8List.sublistView(data, 0, eexecIndex < 0 ? (data.length < 4096 ? data.length : 4096) : eexecIndex));
      if (eexecIndex < 0) return null;
      int start = eexecIndex + 5;
      while (start < data.length && (data[start] == 0x0D || data[start] == 0x0A || data[start] == 0x20 || data[start] == 0x09)) {
        start++;
      }
      Uint8List encrypted = Uint8List.sublistView(data, start);
      if (_looksHex(encrypted)) encrypted = UPdfCodecs.asciiHex(encrypted);
      final Uint8List decrypted = _decrypt(encrypted, 55665, 4);
      return _readPrivate(decrypted, clearText);
    } on Object {
      return null;
    }
  }

  static bool _looksHex(Uint8List bytes) {
    for (int i = 0; i < 4 && i < bytes.length; i++) {
      final int byte = bytes[i];
      final bool hex = (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x46) || (byte >= 0x61 && byte <= 0x66);
      if (!hex) return false;
    }
    return true;
  }

  static Uint8List _decrypt(Uint8List data, int key, int skip) {
    int r = key;
    const int c1 = 52845;
    const int c2 = 22719;
    final List<int> out = <int>[];
    for (final int byte in data) {
      final int plain = byte ^ (r >> 8);
      r = ((byte + r) * c1 + c2) & 0xFFFF;
      out.add(plain & 0xFF);
    }
    if (out.length <= skip) return Uint8List(0);
    return Uint8List.fromList(out.sublist(skip));
  }

  static UPdfType1 _readPrivate(Uint8List data, String clearText) {
    int lenIV = 4;
    final RegExpMatch? lenMatch = RegExp(r"/lenIV\s+(\d+)").firstMatch(String.fromCharCodes(Uint8List.sublistView(data, 0, data.length < 4096 ? data.length : 4096)));
    if (lenMatch != null) lenIV = int.tryParse(lenMatch.group(1) ?? "4") ?? 4;
    final List<Uint8List> subrs = <Uint8List>[];
    final Map<String, Uint8List> charStrings = <String, Uint8List>{};
    final UDocCursor cursor = UDocCursor(data);
    final int subrsIndex = cursor.indexOf(const <int>[0x2F, 0x53, 0x75, 0x62, 0x72, 0x73]);
    if (subrsIndex >= 0) {
      int position = subrsIndex;
      while (position < data.length) {
        final int dup = UDocCursor(data, start: position).indexOf(const <int>[0x64, 0x75, 0x70, 0x20]);
        if (dup < 0) break;
        final _UPdfTokenScan scan = _UPdfTokenScan(data, dup + 4);
        final int? index = scan.readInt();
        final int? length = scan.readInt();
        if (index == null || length == null || length < 0 || length > data.length) break;
        final int dataStart = scan.skipToBinary();
        if (dataStart < 0 || dataStart + length > data.length) break;
        while (subrs.length <= index) {
          subrs.add(Uint8List(0));
        }
        subrs[index] = _decrypt(Uint8List.sublistView(data, dataStart, dataStart + length), 4330, lenIV);
        position = dataStart + length;
        if (subrs.length > 65536) break;
        final int charStringsAhead = UDocCursor(data, start: position).indexOf(const <int>[0x2F, 0x43, 0x68, 0x61, 0x72, 0x53, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x73]);
        if (charStringsAhead >= 0 && charStringsAhead < position + 32) break;
      }
    }
    final int charStringsIndex = cursor.indexOf(const <int>[0x2F, 0x43, 0x68, 0x61, 0x72, 0x53, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x73]);
    if (charStringsIndex >= 0) {
      int position = charStringsIndex + 12;
      while (position < data.length && charStrings.length < 20000) {
        final int slash = UDocCursor(data, start: position).indexOf(const <int>[0x2F]);
        if (slash < 0) break;
        final _UPdfTokenScan scan = _UPdfTokenScan(data, slash + 1);
        final String name = scan.readName();
        final int? length = scan.readInt();
        if (name.isEmpty || length == null || length < 0 || length > data.length) {
          position = slash + 1;
          continue;
        }
        final int dataStart = scan.skipToBinary();
        if (dataStart < 0 || dataStart + length > data.length) break;
        charStrings[name] = _decrypt(Uint8List.sublistView(data, dataStart, dataStart + length), 4330, lenIV);
        position = dataStart + length;
      }
    }
    final List<String> encoding = List<String>.filled(256, "");
    if (clearText.contains("StandardEncoding")) {
      encoding.setAll(0, UPdfStandardNames.standardEncoding);
    } else {
      for (final RegExpMatch match in RegExp(r"dup\s+(\d+)\s*/([^\s/]+)\s+put").allMatches(clearText)) {
        final int? code = int.tryParse(match.group(1) ?? "");
        if (code != null && code >= 0 && code < 256) encoding[code] = match.group(2) ?? "";
      }
    }
    final List<double> matrix = <double>[0.001, 0, 0, 0.001, 0, 0];
    final RegExpMatch? matrixMatch = RegExp(r"/FontMatrix\s*\[([^\]]*)\]").firstMatch(clearText);
    if (matrixMatch != null) {
      final List<double> values = (matrixMatch.group(1) ?? "").split(RegExp(r"\s+")).map((String value) => double.tryParse(value) ?? 0).toList();
      if (values.length >= 6) matrix.setAll(0, values.sublist(0, 6));
    }
    return UPdfType1._(charStrings, subrs, encoding, matrix);
  }

  @override
  int glyphForName(String name) => glyphNames.indexOf(name);

  @override
  double advance(int glyphId) {
    final List<String> names = glyphNames;
    if (glyphId < 0 || glyphId >= names.length) return 0;
    return advanceForName(names[glyphId]);
  }

  double advanceForName(String name) {
    final double? cached = _widthCache[name];
    if (cached != null) return cached;
    glyphPathForName(name);
    return _widthCache[name] ?? 0;
  }

  @override
  Path? glyphPath(int glyphId) {
    final List<String> names = glyphNames;
    if (glyphId < 0 || glyphId >= names.length) return null;
    return glyphPathForName(names[glyphId]);
  }

  Path? glyphPathForName(String name) {
    if (_pathCache.containsKey(name)) return _pathCache[name];
    Path? path;
    try {
      final Uint8List? charString = _charStrings[name];
      if (charString != null) {
        final _UPdfType1Interpreter interpreter = _UPdfType1Interpreter(_subrs, this);
        path = interpreter.run(charString);
        _widthCache[name] = interpreter.width;
      }
    } on Object {
      path = null;
    }
    if (_pathCache.length > 4096) _pathCache.clear();
    _pathCache[name] = path;
    return path;
  }

  @override
  int glyphForCid(int cid) {
    throw UnimplementedError();
  }

  @override
  int glyphForUnicode(int codePoint) {
    throw UnimplementedError();
  }
}

class _UPdfTokenScan {
  _UPdfTokenScan(this._data, this._position);

  final Uint8List _data;
  int _position;

  void _skipSpace() {
    while (_position < _data.length && (_data[_position] == 0x20 || _data[_position] == 0x0A || _data[_position] == 0x0D || _data[_position] == 0x09)) {
      _position++;
    }
  }

  int? readInt() {
    _skipSpace();
    final int start = _position;
    while (_position < _data.length && _data[_position] >= 0x30 && _data[_position] <= 0x39) {
      _position++;
    }
    if (_position == start) return null;
    return int.tryParse(String.fromCharCodes(Uint8List.sublistView(_data, start, _position)));
  }

  String readName() {
    final int start = _position;
    while (_position < _data.length && _data[_position] > 0x20 && _data[_position] != 0x2F && _data[_position] != 0x28 && _data[_position] != 0x5B) {
      _position++;
    }
    return String.fromCharCodes(Uint8List.sublistView(_data, start, _position));
  }

  int skipToBinary() {
    _skipSpace();
    final int start = _position;
    while (_position < _data.length && _data[_position] > 0x20) {
      _position++;
    }
    if (_position == start) return -1;
    if (_position < _data.length) _position++;
    return _position;
  }
}

class _UPdfType1Interpreter {
  _UPdfType1Interpreter(this._subrs, this._owner);

  final List<Uint8List> _subrs;
  final UPdfType1 _owner;
  final List<double> _stack = <double>[];
  final List<double> _psStack = <double>[];
  final Path _path = Path();

  double _x = 0;
  double _y = 0;
  double _sbx = 0;
  bool _open = false;
  bool _inFlex = false;
  final List<Offset> _flexPoints = <Offset>[];
  double width = 0;

  Path run(Uint8List code) {
    _execute(code, 0);
    if (_open) _path.close();
    return _path;
  }

  void _moveTo(double x, double y) {
    if (_inFlex) {
      _flexPoints.add(Offset(x, y));
      return;
    }
    if (_open) _path.close();
    _path.moveTo(x, y);
    _open = true;
  }

  void _execute(Uint8List code, int depth) {
    if (depth > 10) return;
    int index = 0;
    while (index < code.length) {
      final int byte = code[index++];
      if (byte >= 32) {
        if (byte <= 246) {
          _stack.add((byte - 139).toDouble());
        } else if (byte <= 250) {
          if (index >= code.length) return;
          _stack.add(((byte - 247) * 256 + code[index++] + 108).toDouble());
        } else if (byte <= 254) {
          if (index >= code.length) return;
          _stack.add((-(byte - 251) * 256 - code[index++] - 108).toDouble());
        } else {
          if (index + 3 >= code.length) return;
          int value = (code[index] << 24) | (code[index + 1] << 16) | (code[index + 2] << 8) | code[index + 3];
          if (value > 2147483647) value -= 4294967296;
          _stack.add(value.toDouble());
          index += 4;
        }
        if (_stack.length > 48) _stack.removeRange(0, _stack.length - 48);
        continue;
      }
      switch (byte) {
        case 13:
          if (_stack.length >= 2) {
            _sbx = _stack[0];
            width = _stack[1];
            _x = _sbx;
            _y = 0;
          }
          _stack.clear();
          break;
        case 9:
          if (_open) _path.close();
          _open = false;
          _stack.clear();
          break;
        case 1:
        case 3:
          _stack.clear();
          break;
        case 21:
          if (_stack.length >= 2) {
            _x += _stack[0];
            _y += _stack[1];
            _moveTo(_x, _y);
          }
          _stack.clear();
          break;
        case 22:
          if (_stack.isNotEmpty) {
            _x += _stack[0];
            _moveTo(_x, _y);
          }
          _stack.clear();
          break;
        case 4:
          if (_stack.isNotEmpty) {
            _y += _stack[0];
            _moveTo(_x, _y);
          }
          _stack.clear();
          break;
        case 5:
          if (_stack.length >= 2) {
            _x += _stack[0];
            _y += _stack[1];
            _path.lineTo(_x, _y);
          }
          _stack.clear();
          break;
        case 6:
          if (_stack.isNotEmpty) {
            _x += _stack[0];
            _path.lineTo(_x, _y);
          }
          _stack.clear();
          break;
        case 7:
          if (_stack.isNotEmpty) {
            _y += _stack[0];
            _path.lineTo(_x, _y);
          }
          _stack.clear();
          break;
        case 8:
          if (_stack.length >= 6) _curve(_stack[0], _stack[1], _stack[2], _stack[3], _stack[4], _stack[5]);
          _stack.clear();
          break;
        case 30:
          if (_stack.length >= 4) _curve(0, _stack[0], _stack[1], _stack[2], _stack[3], 0);
          _stack.clear();
          break;
        case 31:
          if (_stack.length >= 4) _curve(_stack[0], 0, _stack[1], _stack[2], 0, _stack[3]);
          _stack.clear();
          break;
        case 10:
          {
            if (_stack.isEmpty) break;
            final int subr = _stack.removeLast().toInt();
            if (subr >= 0 && subr < _subrs.length) _execute(_subrs[subr], depth + 1);
          }
          break;
        case 11:
          return;
        case 14:
          if (_open) _path.close();
          _open = false;
          return;
        case 12:
          {
            if (index >= code.length) return;
            final int escape = code[index++];
            _escape(escape, depth);
          }
          break;
        default:
          _stack.clear();
          break;
      }
    }
  }

  void _escape(int operator, int depth) {
    switch (operator) {
      case 12:
        if (_stack.length >= 2) {
          final double b = _stack.removeLast();
          final double a = _stack.removeLast();
          _stack.add(b == 0 ? 0 : a / b);
        }
        break;
      case 16:
        {
          if (_stack.length < 2) {
            _stack.clear();
            break;
          }
          final int otherSubr = _stack.removeLast().toInt();
          final int count = _stack.removeLast().toInt();
          final List<double> arguments = <double>[];
          for (int i = 0; i < count && _stack.isNotEmpty; i++) {
            arguments.insert(0, _stack.removeLast());
          }
          if (otherSubr == 1) {
            _inFlex = true;
            _flexPoints.clear();
          } else if (otherSubr == 0) {
            _inFlex = false;
            if (_flexPoints.length >= 7) {
              _path.cubicTo(_flexPoints[1].dx, _flexPoints[1].dy, _flexPoints[2].dx, _flexPoints[2].dy, _flexPoints[3].dx, _flexPoints[3].dy);
              _path.cubicTo(_flexPoints[4].dx, _flexPoints[4].dy, _flexPoints[5].dx, _flexPoints[5].dy, _flexPoints[6].dx, _flexPoints[6].dy);
              _x = _flexPoints[6].dx;
              _y = _flexPoints[6].dy;
            }
            _psStack
              ..clear()
              ..add(_y)
              ..add(_x);
          } else if (otherSubr == 3) {
            _psStack
              ..clear()
              ..add(3);
          } else {
            _psStack
              ..clear()
              ..addAll(arguments.reversed);
          }
        }
        break;
      case 17:
        _stack.add(_psStack.isEmpty ? 0 : _psStack.removeLast());
        break;
      case 6:
        {
          if (_stack.length >= 5) {
            final int achar = _stack[4].toInt();
            final int bchar = _stack[3].toInt();
            final double ady = _stack[2];
            final double adx = _stack[1];
            final List<String> encoding = UPdfStandardNames.standardEncoding;
            final String baseName = bchar >= 0 && bchar < 256 ? encoding[bchar] : "";
            final String accentName = achar >= 0 && achar < 256 ? encoding[achar] : "";
            final Path? base = _owner.glyphPathForName(baseName);
            final Path? accent = _owner.glyphPathForName(accentName);
            if (base != null) _path.addPath(base, Offset.zero);
            if (accent != null) _path.addPath(accent, Offset(_sbx - _stack[0] + adx, ady));
          }
          _stack.clear();
        }
        return;
      case 7:
        if (_stack.length >= 4) {
          _sbx = _stack[0];
          width = _stack[2];
          _x = _stack[0];
          _y = _stack[1];
        }
        _stack.clear();
        break;
      case 33:
        if (_stack.length >= 2) {
          _x = _stack[0];
          _y = _stack[1];
          _moveTo(_x, _y);
        }
        _stack.clear();
        break;
      case 0:
      case 1:
      case 2:
        _stack.clear();
        break;
      default:
        _stack.clear();
        break;
    }
    if (depth > 10) _stack.clear();
  }

  void _curve(double dx1, double dy1, double dx2, double dy2, double dx3, double dy3) {
    final double c1x = _x + dx1;
    final double c1y = _y + dy1;
    final double c2x = c1x + dx2;
    final double c2y = c1y + dy2;
    _x = c2x + dx3;
    _y = c2y + dy3;
    if (!_open) _moveTo(c1x, c1y);
    _path.cubicTo(c1x, c1y, c2x, c2y, _x, _y);
  }
}

class UPdfCodespace {
  const UPdfCodespace(this.byteLength, this.low, this.high);

  final int byteLength;
  final int low;
  final int high;

  bool contains(int code) => code >= low && code <= high;
}

class UPdfCidRange {
  const UPdfCidRange(this.low, this.high, this.cid);

  final int low;
  final int high;
  final int cid;
}

class UPdfCMap {
  UPdfCMap({required this.codespaces, required this.singles, required this.ranges, this.vertical = false, this.identityBytes = 0});

  final List<UPdfCodespace> codespaces;
  final Map<int, int> singles;
  final List<UPdfCidRange> ranges;
  final bool vertical;
  final int identityBytes;

  static UPdfCMap identity({int bytes = 2, bool vertical = false}) => UPdfCMap(
    codespaces: <UPdfCodespace>[UPdfCodespace(bytes, 0, (1 << (bytes * 8)) - 1)],
    singles: <int, int>{},
    ranges: const <UPdfCidRange>[],
    vertical: vertical,
    identityBytes: bytes,
  );

  bool get isIdentity => identityBytes > 0;

  int cidFor(int code) {
    if (isIdentity) return code;
    final int? single = singles[code];
    if (single != null) return single;
    for (final UPdfCidRange range in ranges) {
      if (code >= range.low && code <= range.high) return range.cid + (code - range.low);
    }
    return 0;
  }

  int codeLengthAt(Uint8List bytes, int offset) {
    if (isIdentity) return identityBytes;
    for (int length = 1; length <= 4 && offset + length <= bytes.length; length++) {
      int code = 0;
      for (int i = 0; i < length; i++) {
        code = (code << 8) | bytes[offset + i];
      }
      for (final UPdfCodespace space in codespaces) {
        if (space.byteLength == length && space.contains(code)) return length;
      }
    }
    return codespaces.isEmpty ? 1 : codespaces.first.byteLength;
  }

  static UPdfCMap parse(Uint8List bytes, {bool vertical = false}) {
    final List<UPdfCodespace> codespaces = <UPdfCodespace>[];
    final Map<int, int> singles = <int, int>{};
    final List<UPdfCidRange> ranges = <UPdfCidRange>[];
    final UDocCursor cursor = UDocCursor(bytes);
    final List<Object?> stack = <Object?>[];
    int guard = 0;
    while (!cursor.isEmpty && guard < 2000000) {
      guard++;
      UPdfSyntax.skipWhitespace(cursor);
      if (cursor.isEmpty) break;
      final int byte = cursor.peek;
      if (byte == 0x3C && cursor.peekAt(1) != 0x3C) {
        stack.add(UPdfSyntax.readHexString(cursor));
        continue;
      }
      if (byte == 0x2F || byte == 0x5B || byte == 0x28 || (byte == 0x3C && cursor.peekAt(1) == 0x3C) || UPdfSyntax.isDigit(byte) || byte == 0x2D || byte == 0x2E) {
        stack.add(UPdfSyntax.parseObject(cursor));
        continue;
      }
      final String keyword = UPdfSyntax.readKeyword(cursor);
      if (keyword.isEmpty) {
        cursor.skip(1);
        continue;
      }
      switch (keyword) {
        case "endcodespacerange":
          for (int i = 0; i + 1 < stack.length; i += 2) {
            final Object? low = stack[i];
            final Object? high = stack[i + 1];
            if (low is UPdfString && high is UPdfString) codespaces.add(UPdfCodespace(low.bytes.length, _toInt(low.bytes), _toInt(high.bytes)));
          }
          stack.clear();
          break;
        case "endcidrange":
        case "endbfrange":
          for (int i = 0; i + 2 < stack.length; i += 3) {
            final Object? low = stack[i];
            final Object? high = stack[i + 1];
            final Object? value = stack[i + 2];
            if (low is! UPdfString || high is! UPdfString) continue;
            if (value is num) {
              ranges.add(UPdfCidRange(_toInt(low.bytes), _toInt(high.bytes), value.toInt()));
            } else if (value is UPdfString) {
              ranges.add(UPdfCidRange(_toInt(low.bytes), _toInt(high.bytes), _toInt(value.bytes)));
            } else if (value is List<Object?>) {
              final int start = _toInt(low.bytes);
              for (int j = 0; j < value.length; j++) {
                final Object? entry = value[j];
                if (entry is UPdfString) singles[start + j] = _toInt(entry.bytes);
              }
            }
          }
          stack.clear();
          break;
        case "endcidchar":
        case "endbfchar":
          for (int i = 0; i + 1 < stack.length; i += 2) {
            final Object? code = stack[i];
            final Object? value = stack[i + 1];
            if (code is! UPdfString) continue;
            if (value is num) {
              singles[_toInt(code.bytes)] = value.toInt();
            } else if (value is UPdfString) {
              singles[_toInt(code.bytes)] = _toInt(value.bytes);
            }
          }
          stack.clear();
          break;
        case "begincodespacerange":
        case "begincidrange":
        case "beginbfrange":
        case "begincidchar":
        case "beginbfchar":
          stack.clear();
          break;
        default:
          if (stack.length > 3000) stack.clear();
          break;
      }
    }
    if (codespaces.isEmpty) codespaces.add(const UPdfCodespace(2, 0, 0xFFFF));
    return UPdfCMap(codespaces: codespaces, singles: singles, ranges: ranges, vertical: vertical);
  }

  static Map<int, String> parseToUnicode(Uint8List bytes) {
    final Map<int, String> map = <int, String>{};
    final UDocCursor cursor = UDocCursor(bytes);
    final List<Object?> stack = <Object?>[];
    int guard = 0;
    while (!cursor.isEmpty && guard < 2000000) {
      guard++;
      UPdfSyntax.skipWhitespace(cursor);
      if (cursor.isEmpty) break;
      final int byte = cursor.peek;
      if (byte == 0x3C && cursor.peekAt(1) != 0x3C) {
        stack.add(UPdfSyntax.readHexString(cursor));
        continue;
      }
      if (byte == 0x5B || byte == 0x2F || UPdfSyntax.isDigit(byte) || byte == 0x2D) {
        stack.add(UPdfSyntax.parseObject(cursor));
        continue;
      }
      final String keyword = UPdfSyntax.readKeyword(cursor);
      if (keyword.isEmpty) {
        cursor.skip(1);
        continue;
      }
      if (keyword == "endbfchar") {
        for (int i = 0; i + 1 < stack.length; i += 2) {
          final Object? code = stack[i];
          final Object? value = stack[i + 1];
          if (code is UPdfString && value is UPdfString) map[_toInt(code.bytes)] = _utf16(value.bytes);
        }
        stack.clear();
      } else if (keyword == "endbfrange") {
        for (int i = 0; i + 2 < stack.length; i += 3) {
          final Object? low = stack[i];
          final Object? high = stack[i + 1];
          final Object? value = stack[i + 2];
          if (low is! UPdfString || high is! UPdfString) continue;
          final int start = _toInt(low.bytes);
          final int end = _toInt(high.bytes);
          if (value is UPdfString) {
            final String base = _utf16(value.bytes);
            for (int code = start; code <= end && code - start < 65536; code++) {
              if (base.isEmpty) continue;
              final int lastUnit = base.codeUnitAt(base.length - 1) + (code - start);
              map[code] = base.substring(0, base.length - 1) + String.fromCharCode(lastUnit & 0xFFFF);
            }
          } else if (value is List<Object?>) {
            for (int j = 0; j < value.length && start + j <= end; j++) {
              final Object? entry = value[j];
              if (entry is UPdfString) map[start + j] = _utf16(entry.bytes);
            }
          }
        }
        stack.clear();
      } else if (keyword.startsWith("begin")) {
        stack.clear();
      } else if (stack.length > 3000) {
        stack.clear();
      }
    }
    return map;
  }

  static int _toInt(Uint8List bytes) {
    int value = 0;
    for (int i = 0; i < bytes.length && i < 4; i++) {
      value = (value << 8) | bytes[i];
    }
    return value;
  }

  static String _utf16(Uint8List bytes) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      buffer.writeCharCode((bytes[i] << 8) | bytes[i + 1]);
    }
    if (bytes.length == 1) buffer.writeCharCode(bytes[0]);
    return buffer.toString();
  }
}

class UPdfCodePoint {
  const UPdfCodePoint({required this.code, required this.cid, required this.byteLength});

  final int code;
  final int cid;
  final int byteLength;
}

class UPdfFont {
  UPdfFont._({
    required this.baseFont,
    required this.subtype,
    required this.isType0,
    required this.isType3,
    required this.symbolic,
    required this.defaultWidth,
    required this.fontMatrix,
  });

  final String baseFont;
  final String subtype;
  final bool isType0;
  final bool isType3;
  final bool symbolic;
  final double defaultWidth;
  final List<double> fontMatrix;

  UPdfGlyphSource? glyphs;
  UPdfCMap? encodingCMap;
  Map<int, String> unicodeMap = <int, String>{};
  Map<int, double> widths = <int, double>{};
  List<String> encodingNames = const <String>[];
  Map<int, int>? cidToGid;
  Map<int, UPdfStream> charProcs = <int, UPdfStream>{};
  UPdfDict? type3Resources;
  double ascent = 750;
  double descent = -250;
  double italicAngle = 0;
  bool vertical = false;
  bool embedded = false;

  final Map<int, Path?> _pathCache = <int, Path?>{};

  static final Map<String, UPdfFont> _cache = <String, UPdfFont>{};

  static void clearCache() => _cache.clear();

  static Future<UPdfFont> load(UPdfDocument document, UPdfDict dict, {String cacheKey = ""}) async {
    final UPdfFont? cached = cacheKey.isEmpty ? null : _cache[cacheKey];
    if (cached != null) return cached;
    final UPdfFont font = await _build(document, dict);
    if (cacheKey.isNotEmpty) {
      if (_cache.length > 256) _cache.clear();
      _cache[cacheKey] = font;
    }
    return font;
  }

  static Future<UPdfFont> _build(UPdfDocument document, UPdfDict dict) async {
    final Object? subtypeObject = await document.resolve(dict["Subtype"]);
    final String subtype = subtypeObject is UPdfName ? subtypeObject.value : "Type1";
    final Object? baseObject = await document.resolve(dict["BaseFont"]);
    final String baseFont = baseObject is UPdfName ? baseObject.value : "";
    if (subtype == "Type0") return _buildType0(document, dict, baseFont);
    final UPdfFont font = UPdfFont._(
      baseFont: baseFont,
      subtype: subtype,
      isType0: false,
      isType3: subtype == "Type3",
      symbolic: false,
      defaultWidth: 0,
      fontMatrix: <double>[0.001, 0, 0, 0.001, 0, 0],
    );
    final Object? descriptorObject = await document.resolve(dict["FontDescriptor"]);
    final UPdfDict? descriptor = descriptorObject is UPdfDict ? descriptorObject : null;
    await font._readDescriptor(document, descriptor);
    if (subtype == "Type3") {
      final Object? matrixObject = await document.resolve(dict["FontMatrix"]);
      if (matrixObject is List<Object?> && matrixObject.length >= 6) {
        for (int i = 0; i < 6; i++) {
          final Object? value = matrixObject[i];
          font.fontMatrix[i] = value is num ? value.toDouble() : font.fontMatrix[i];
        }
      }
      final Object? procs = await document.resolve(dict["CharProcs"]);
      final Object? resources = await document.resolve(dict["Resources"]);
      font.type3Resources = resources is UPdfDict ? resources : null;
      await font._readEncoding(document, dict);
      if (procs is UPdfDict) {
        for (int code = 0; code < 256; code++) {
          final String name = code < font.encodingNames.length ? font.encodingNames[code] : "";
          if (name.isEmpty) continue;
          final Object? proc = await document.resolve(procs[name]);
          if (proc is UPdfStream) font.charProcs[code] = proc;
        }
      }
    } else {
      await font._readEncoding(document, dict);
    }
    await font._readSimpleWidths(document, dict);
    await font._readToUnicode(document, dict);
    return font;
  }

  static Future<UPdfFont> _buildType0(UPdfDocument document, UPdfDict dict, String baseFont) async {
    final Object? encodingObject = await document.resolve(dict["Encoding"]);
    bool vertical = false;
    UPdfCMap cmap = UPdfCMap.identity();
    if (encodingObject is UPdfName) {
      vertical = encodingObject.value.endsWith("-V");
      if (encodingObject.value.startsWith("Identity")) {
        cmap = UPdfCMap.identity(vertical: vertical);
      } else {
        cmap = UPdfCMap.identity(vertical: vertical);
      }
    } else if (encodingObject is UPdfStream) {
      cmap = UPdfCMap.parse((await document.decodeStream(encodingObject)).bytes, vertical: vertical);
    }
    final Object? descendants = await document.resolve(dict["DescendantFonts"]);
    UPdfDict? descendant;
    if (descendants is List<Object?> && descendants.isNotEmpty) {
      final Object? first = await document.resolve(descendants.first);
      if (first is UPdfDict) descendant = first;
    }
    final Object? defaultWidthObject = await document.resolve(descendant?["DW"]);
    final UPdfFont font = UPdfFont._(
      baseFont: baseFont,
      subtype: "Type0",
      isType0: true,
      isType3: false,
      symbolic: true,
      defaultWidth: defaultWidthObject is num ? defaultWidthObject.toDouble() : 1000,
      fontMatrix: <double>[0.001, 0, 0, 0.001, 0, 0],
    );
    font.encodingCMap = cmap;
    font.vertical = vertical;
    if (descendant != null) {
      final Object? descriptorObject = await document.resolve(descendant["FontDescriptor"]);
      await font._readDescriptor(document, descriptorObject is UPdfDict ? descriptorObject : null);
      await font._readCidWidths(document, descendant);
      final Object? cidToGidObject = await document.resolve(descendant["CIDToGIDMap"]);
      if (cidToGidObject is UPdfStream) {
        final Uint8List data = (await document.decodeStream(cidToGidObject)).bytes;
        final Map<int, int> map = <int, int>{};
        for (int i = 0; i + 1 < data.length; i += 2) {
          final int gid = (data[i] << 8) | data[i + 1];
          if (gid != 0) map[i ~/ 2] = gid;
        }
        font.cidToGid = map;
      }
    }
    await font._readToUnicode(document, dict);
    return font;
  }

  Future<void> _readDescriptor(UPdfDocument document, UPdfDict? descriptor) async {
    if (descriptor == null) return;
    final Object? flagsObject = await document.resolve(descriptor["Flags"]);
    final int flags = flagsObject is num ? flagsObject.toInt() : 0;
    final Object? ascentObject = await document.resolve(descriptor["Ascent"]);
    final Object? descentObject = await document.resolve(descriptor["Descent"]);
    final Object? angleObject = await document.resolve(descriptor["ItalicAngle"]);
    if (ascentObject is num) ascent = ascentObject.toDouble();
    if (descentObject is num) descent = descentObject.toDouble();
    if (angleObject is num) italicAngle = angleObject.toDouble();
    final Object? missing = await document.resolve(descriptor["MissingWidth"]);
    if (missing is num && missing > 0) widths[-1] = missing.toDouble();
    final bool isSymbolic = flags & 4 != 0 && flags & 32 == 0;
    final Object? file2 = await document.resolve(descriptor["FontFile2"]);
    final Object? file3 = await document.resolve(descriptor["FontFile3"]);
    final Object? file = await document.resolve(descriptor["FontFile"]);
    try {
      if (file2 is UPdfStream) {
        glyphs = UPdfTrueType.parse((await document.decodeStream(file2)).bytes);
      } else if (file3 is UPdfStream) {
        final Uint8List data = (await document.decodeStream(file3)).bytes;
        final Object? subtypeObject = file3.dict["Subtype"];
        final String type = subtypeObject is UPdfName ? subtypeObject.value : "";
        if (type == "OpenType") {
          glyphs = UPdfTrueType.parse(data);
        } else {
          glyphs = UPdfCff.parse(data);
        }
      } else if (file is UPdfStream) {
        glyphs = UPdfType1.parse((await document.decodeStream(file)).bytes);
      }
    } on Object {
      glyphs = null;
    }
    embedded = glyphs != null;
    if (isSymbolic && encodingNames.isEmpty) encodingNames = const <String>[];
  }

  Future<void> _readEncoding(UPdfDocument document, UPdfDict dict) async {
    final List<String> table = List<String>.filled(256, "");
    final UPdfGlyphSource? source = glyphs;
    if (source is UPdfType1) {
      for (int i = 0; i < 256 && i < source.builtinEncoding.length; i++) {
        table[i] = source.builtinEncoding[i];
      }
    }
    bool hasBase = false;
    final Object? encodingObject = await document.resolve(dict["Encoding"]);
    void applyBase(String name) {
      hasBase = true;
      final List<String> base = name == "WinAnsiEncoding"
          ? UPdfStandardNames.winAnsiEncoding
          : name == "MacRomanEncoding"
          ? UPdfStandardNames.macRomanEncoding
          : UPdfStandardNames.standardEncoding;
      table.setAll(0, base);
    }

    if (encodingObject is UPdfName) applyBase(encodingObject.value);
    if (encodingObject is UPdfDict) {
      final Object? baseObject = await document.resolve(encodingObject["BaseEncoding"]);
      if (baseObject is UPdfName) applyBase(baseObject.value);
      final Object? differences = await document.resolve(encodingObject["Differences"]);
      if (differences is List<Object?>) {
        int code = 0;
        for (final Object? entry in differences) {
          final Object? value = await document.resolve(entry);
          if (value is num) {
            code = value.toInt();
          } else if (value is UPdfName) {
            if (code >= 0 && code < 256) table[code] = value.value;
            code++;
          }
        }
      }
    }
    if (!hasBase && source == null && table.every((String value) => value.isEmpty)) table.setAll(0, UPdfStandardNames.standardEncoding);
    encodingNames = table;
  }

  Future<void> _readSimpleWidths(UPdfDocument document, UPdfDict dict) async {
    final Object? firstObject = await document.resolve(dict["FirstChar"]);
    final Object? widthsObject = await document.resolve(dict["Widths"]);
    if (widthsObject is! List<Object?>) return;
    final int first = firstObject is num ? firstObject.toInt() : 0;
    for (int i = 0; i < widthsObject.length; i++) {
      final Object? value = await document.resolve(widthsObject[i]);
      if (value is num) widths[first + i] = value.toDouble();
    }
  }

  Future<void> _readCidWidths(UPdfDocument document, UPdfDict descendant) async {
    final Object? widthsObject = await document.resolve(descendant["W"]);
    if (widthsObject is! List<Object?>) return;
    int index = 0;
    while (index < widthsObject.length) {
      final Object? firstObject = await document.resolve(widthsObject[index]);
      if (firstObject is! num) break;
      final int first = firstObject.toInt();
      if (index + 1 >= widthsObject.length) break;
      final Object? next = await document.resolve(widthsObject[index + 1]);
      if (next is List<Object?>) {
        for (int i = 0; i < next.length; i++) {
          final Object? value = await document.resolve(next[i]);
          if (value is num) widths[first + i] = value.toDouble();
        }
        index += 2;
        continue;
      }
      if (next is num && index + 2 < widthsObject.length) {
        final Object? value = await document.resolve(widthsObject[index + 2]);
        final int last = next.toInt();
        if (value is num && last >= first && last - first < 65536) {
          for (int cid = first; cid <= last; cid++) {
            widths[cid] = value.toDouble();
          }
        }
        index += 3;
        continue;
      }
      break;
    }
  }

  Future<void> _readToUnicode(UPdfDocument document, UPdfDict dict) async {
    final Object? toUnicode = await document.resolve(dict["ToUnicode"]);
    if (toUnicode is UPdfStream) {
      try {
        unicodeMap = UPdfCMap.parseToUnicode((await document.decodeStream(toUnicode)).bytes);
      } on Object {
        unicodeMap = <int, String>{};
      }
    }
  }

  List<UPdfCodePoint> decode(Uint8List bytes) {
    final List<UPdfCodePoint> out = <UPdfCodePoint>[];
    if (isType0) {
      final UPdfCMap cmap = encodingCMap ?? UPdfCMap.identity();
      int offset = 0;
      while (offset < bytes.length) {
        final int length = cmap.codeLengthAt(bytes, offset).clamp(1, 4);
        int code = 0;
        for (int i = 0; i < length && offset + i < bytes.length; i++) {
          code = (code << 8) | bytes[offset + i];
        }
        out.add(UPdfCodePoint(code: code, cid: cmap.cidFor(code), byteLength: length));
        offset += length;
      }
      return out;
    }
    for (final int byte in bytes) {
      out.add(UPdfCodePoint(code: byte, cid: byte, byteLength: 1));
    }
    return out;
  }

  double widthFor(UPdfCodePoint point) {
    final double? explicit = widths[isType0 ? point.cid : point.code];
    if (explicit != null) return explicit;
    if (isType0) return defaultWidth;
    final double? missing = widths[-1];
    if (missing != null) return missing;
    final UPdfGlyphSource? source = glyphs;
    if (source != null) {
      final int gid = glyphIdFor(point);
      if (gid > 0) {
        final double units = source.advance(gid);
        return units * 1000 / source.unitsPerEm;
      }
    }
    return _fallbackWidth(point);
  }

  double _fallbackWidth(UPdfCodePoint point) {
    final String lower = baseFont.toLowerCase();
    if (lower.contains("courier") || lower.contains("mono")) return 600;
    final String text = unicodeFor(point);
    if (text == " ") return lower.contains("times") ? 250 : 278;
    if (text.isEmpty) return 500;
    final int code = text.codeUnitAt(0);
    if (code >= 0x30 && code <= 0x39) return 500;
    if (code >= 0x41 && code <= 0x5A) return lower.contains("times") ? 667 : 722;
    if (code >= 0x61 && code <= 0x7A) return lower.contains("times") ? 500 : 556;
    if (UDocText.isRtlCode(code)) return 520;
    return 500;
  }

  int glyphIdFor(UPdfCodePoint point) {
    final UPdfGlyphSource? source = glyphs;
    if (source == null) return 0;
    if (isType0) {
      final Map<int, int>? map = cidToGid;
      if (map != null) return map[point.cid] ?? 0;
      if (source is UPdfCff && source.isCid) return source.glyphForCid(point.cid);
      return point.cid;
    }
    final String name = point.code < encodingNames.length ? encodingNames[point.code] : "";
    if (source is UPdfType1) {
      if (name.isNotEmpty) {
        final int index = source.glyphForName(name);
        if (index >= 0) return index;
      }
      final String builtin = point.code < source.builtinEncoding.length ? source.builtinEncoding[point.code] : "";
      return builtin.isEmpty ? 0 : source.glyphForName(builtin);
    }
    if (source is UPdfCff) {
      if (name.isNotEmpty) {
        final int gid = source.glyphForName(name);
        if (gid > 0) return gid;
      }
      return source.glyphForStandardCode(point.code);
    }
    if (source is UPdfTrueType) {
      if (symbolic || name.isEmpty) {
        final int direct = source.glyphForUnicode(0xF000 + point.code);
        if (direct > 0) return direct;
        final int plain = source.glyphForUnicode(point.code);
        if (plain > 0) return plain;
        final int mac = source.glyphForMacRoman(point.code);
        if (mac > 0) return mac;
      }
      if (name.isNotEmpty) {
        final int unicode = UPdfStandardNames.unicodeForGlyphName(name);
        if (unicode >= 0) {
          final int gid = source.glyphForUnicode(unicode);
          if (gid > 0) return gid;
        }
        final int byName = source.glyphForName(name);
        if (byName > 0) return byName;
        final RegExpMatch? indexed = RegExp(r"^(?:g|glyph|index|cid)(\d+)$").firstMatch(name);
        if (indexed != null) return int.tryParse(indexed.group(1) ?? "") ?? 0;
      }
      final int fallback = source.glyphForUnicode(point.code);
      if (fallback > 0) return fallback;
      return point.code < source.glyphCount ? point.code : 0;
    }
    return 0;
  }

  Path? pathFor(UPdfCodePoint point) {
    final int key = isType0 ? point.cid | 0x1000000 : point.code;
    if (_pathCache.containsKey(key)) return _pathCache[key];
    final UPdfGlyphSource? source = glyphs;
    Path? path;
    if (source != null) {
      final int gid = glyphIdFor(point);
      final Path? raw = source.glyphPath(gid);
      if (raw != null) {
        final double scale = 1 / (source.unitsPerEm <= 0 ? 1000 : source.unitsPerEm);
        path = raw.transform(Float64List.fromList(<double>[scale, 0, 0, 0, 0, scale, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
      }
    }
    if (_pathCache.length > 2048) _pathCache.clear();
    _pathCache[key] = path;
    return path;
  }

  String unicodeFor(UPdfCodePoint point) {
    final String? mapped = unicodeMap[point.code];
    if (mapped != null && mapped.isNotEmpty && mapped.codeUnitAt(0) != 0) return mapped;
    if (!isType0) {
      final String name = point.code < encodingNames.length ? encodingNames[point.code] : "";
      if (name.isNotEmpty) {
        final int unicode = UPdfStandardNames.unicodeForGlyphName(name);
        if (unicode > 0) return String.fromCharCode(unicode);
      }
      if (point.code >= 32 && point.code < 127) return String.fromCharCode(point.code);
      if (point.code >= 160) return Cp1256.decode(<int>[point.code]);
      return "";
    }
    if (point.cid >= 32 && point.cid < 127) return String.fromCharCode(point.cid);
    return "";
  }
}

abstract class UPdfFunction {
  List<double> get domain;

  List<double>? get range;

  List<double> evaluate(List<double> inputs);

  static double _clamp(double value, double low, double high) => value < low ? low : (value > high ? high : value);

  static Future<UPdfFunction?> load(UPdfDocument document, Object? value, {int depth = 0}) async {
    if (depth > 8) return null;
    final Object? resolved = await document.resolve(value);
    if (resolved is List<Object?>) {
      final List<UPdfFunction> parts = <UPdfFunction>[];
      for (final Object? entry in resolved) {
        final UPdfFunction? part = await load(document, entry, depth: depth + 1);
        if (part != null) parts.add(part);
      }
      return parts.isEmpty ? null : UPdfFunctionArray(parts);
    }
    UPdfDict? dict;
    Uint8List? data;
    if (resolved is UPdfStream) {
      dict = resolved.dict;
      data = (await document.decodeStream(resolved)).bytes;
    } else if (resolved is UPdfDict) {
      dict = resolved;
    }
    if (dict == null) return null;
    final int type = ((await document.resolve(dict["FunctionType"])) as num?)?.toInt() ?? -1;
    final List<double> domain = await _numbers(document, dict["Domain"]);
    final List<double>? outputRange = dict.has("Range") ? await _numbers(document, dict["Range"]) : null;
    switch (type) {
      case 0:
        if (data == null) return null;
        return UPdfSampledFunction(
          domain: domain,
          range: outputRange ?? <double>[0, 1],
          size: (await _numbers(document, dict["Size"])).map((double value) => value.toInt()).toList(),
          bitsPerSample: ((await document.resolve(dict["BitsPerSample"])) as num?)?.toInt() ?? 8,
          encode: dict.has("Encode") ? await _numbers(document, dict["Encode"]) : null,
          decode: dict.has("Decode") ? await _numbers(document, dict["Decode"]) : null,
          samples: data,
        );
      case 2:
        return UPdfExponentialFunction(
          domain: domain.isEmpty ? <double>[0, 1] : domain,
          range: outputRange,
          c0: dict.has("C0") ? await _numbers(document, dict["C0"]) : <double>[0],
          c1: dict.has("C1") ? await _numbers(document, dict["C1"]) : <double>[1],
          exponent: ((await document.resolve(dict["N"])) as num?)?.toDouble() ?? 1,
        );
      case 3:
        final Object? functionsObject = await document.resolve(dict["Functions"]);
        final List<UPdfFunction> functions = <UPdfFunction>[];
        if (functionsObject is List<Object?>) {
          for (final Object? entry in functionsObject) {
            final UPdfFunction? part = await load(document, entry, depth: depth + 1);
            if (part != null) functions.add(part);
          }
        }
        return UPdfStitchingFunction(
          domain: domain.isEmpty ? <double>[0, 1] : domain,
          range: outputRange,
          functions: functions,
          bounds: await _numbers(document, dict["Bounds"]),
          encode: await _numbers(document, dict["Encode"]),
        );
      case 4:
        if (data == null) return null;
        return UPdfPostScriptFunction(domain: domain, range: outputRange ?? <double>[0, 1], program: String.fromCharCodes(data));
      default:
        return null;
    }
  }

  static Future<List<double>> _numbers(UPdfDocument document, Object? value) async {
    final Object? resolved = await document.resolve(value);
    if (resolved is! List<Object?>) return const <double>[];
    final List<double> out = <double>[];
    for (final Object? entry in resolved) {
      final Object? number = await document.resolve(entry);
      if (number is num) out.add(number.toDouble());
    }
    return out;
  }
}

class UPdfFunctionArray implements UPdfFunction {
  const UPdfFunctionArray(this.functions);

  final List<UPdfFunction> functions;

  @override
  List<double> get domain => functions.isEmpty ? const <double>[0, 1] : functions.first.domain;

  @override
  List<double>? get range => null;

  @override
  List<double> evaluate(List<double> inputs) {
    final List<double> out = <double>[];
    for (final UPdfFunction function in functions) {
      out.addAll(function.evaluate(inputs));
    }
    return out;
  }
}

class UPdfExponentialFunction implements UPdfFunction {
  const UPdfExponentialFunction({required this.domain, required this.c0, required this.c1, required this.exponent, this.range});

  @override
  final List<double> domain;

  @override
  final List<double>? range;

  final List<double> c0;
  final List<double> c1;
  final double exponent;

  @override
  List<double> evaluate(List<double> inputs) {
    final double low = domain.isNotEmpty ? domain[0] : 0;
    final double high = domain.length > 1 ? domain[1] : 1;
    final double raw = inputs.isEmpty ? 0 : inputs.first;
    final double t = UPdfFunction._clamp(raw, low, high);
    final double factor = exponent == 1 ? t : pow(t, exponent).toDouble();
    final int count = c0.length > c1.length ? c0.length : c1.length;
    final List<double> out = <double>[];
    for (int i = 0; i < count; i++) {
      final double start = i < c0.length ? c0[i] : 0;
      final double end = i < c1.length ? c1[i] : 1;
      out.add(start + factor * (end - start));
    }
    return out;
  }
}

class UPdfStitchingFunction implements UPdfFunction {
  const UPdfStitchingFunction({required this.domain, required this.functions, required this.bounds, required this.encode, this.range});

  @override
  final List<double> domain;

  @override
  final List<double>? range;

  final List<UPdfFunction> functions;
  final List<double> bounds;
  final List<double> encode;

  @override
  List<double> evaluate(List<double> inputs) {
    if (functions.isEmpty) return const <double>[0];
    final double low = domain.isNotEmpty ? domain[0] : 0;
    final double high = domain.length > 1 ? domain[1] : 1;
    final double t = UPdfFunction._clamp(inputs.isEmpty ? 0 : inputs.first, low, high);
    int index = 0;
    while (index < bounds.length && t >= bounds[index]) {
      index++;
    }
    if (index >= functions.length) index = functions.length - 1;
    final double segmentLow = index == 0 ? low : bounds[index - 1];
    final double segmentHigh = index >= bounds.length ? high : bounds[index];
    final double encodeLow = index * 2 < encode.length ? encode[index * 2] : 0;
    final double encodeHigh = index * 2 + 1 < encode.length ? encode[index * 2 + 1] : 1;
    final double span = segmentHigh - segmentLow;
    final double mapped = span == 0 ? encodeLow : encodeLow + (t - segmentLow) * (encodeHigh - encodeLow) / span;
    return functions[index].evaluate(<double>[mapped]);
  }
}

class UPdfSampledFunction implements UPdfFunction {
  UPdfSampledFunction({required this.domain, required this.range, required this.size, required this.bitsPerSample, required this.samples, this.encode, this.decode});

  @override
  final List<double> domain;

  @override
  final List<double> range;

  final List<int> size;
  final int bitsPerSample;
  final Uint8List samples;
  final List<double>? encode;
  final List<double>? decode;

  int get outputCount => range.length ~/ 2;

  double _sample(int index) {
    final int bitOffset = index * bitsPerSample;
    final int max = (1 << bitsPerSample) - 1;
    if (bitsPerSample == 8) {
      final int byte = bitOffset ~/ 8;
      return byte < samples.length ? samples[byte] / 255 : 0;
    }
    int value = 0;
    for (int i = 0; i < bitsPerSample; i++) {
      final int bit = bitOffset + i;
      final int byte = bit ~/ 8;
      if (byte >= samples.length) return 0;
      value = (value << 1) | ((samples[byte] >> (7 - bit % 8)) & 1);
    }
    return max == 0 ? 0 : value / max;
  }

  @override
  List<double> evaluate(List<double> inputs) {
    if (size.isEmpty || outputCount == 0) return const <double>[0];
    final List<int> indices = <int>[];
    for (int i = 0; i < size.length; i++) {
      final double low = i * 2 < domain.length ? domain[i * 2] : 0;
      final double high = i * 2 + 1 < domain.length ? domain[i * 2 + 1] : 1;
      final double raw = i < inputs.length ? inputs[i] : 0;
      final double encodeLow = encode != null && i * 2 < encode!.length ? encode![i * 2] : 0;
      final double encodeHigh = encode != null && i * 2 + 1 < encode!.length ? encode![i * 2 + 1] : (size[i] - 1).toDouble();
      final double span = high - low;
      final double position = span == 0 ? encodeLow : encodeLow + (UPdfFunction._clamp(raw, low, high) - low) * (encodeHigh - encodeLow) / span;
      indices.add(position.round().clamp(0, size[i] - 1));
    }
    int flat = 0;
    int stride = 1;
    for (int i = 0; i < indices.length; i++) {
      flat += indices[i] * stride;
      stride *= size[i];
    }
    final List<double> out = <double>[];
    for (int i = 0; i < outputCount; i++) {
      final double raw = _sample(flat * outputCount + i);
      final double decodeLow = decode != null && i * 2 < decode!.length ? decode![i * 2] : range[i * 2];
      final double decodeHigh = decode != null && i * 2 + 1 < decode!.length ? decode![i * 2 + 1] : range[i * 2 + 1];
      out.add(decodeLow + raw * (decodeHigh - decodeLow));
    }
    return out;
  }
}

class UPdfPostScriptFunction implements UPdfFunction {
  UPdfPostScriptFunction({required this.domain, required this.range, required String program}) : _tokens = _tokenize(program);

  @override
  final List<double> domain;

  @override
  final List<double> range;

  final List<String> _tokens;

  static List<String> _tokenize(String program) => program.replaceAll("{", " { ").replaceAll("}", " } ").split(RegExp(r"\s+")).where((String token) => token.isNotEmpty).toList();

  @override
  List<double> evaluate(List<double> inputs) {
    final List<double> stack = <double>[...inputs];
    _run(stack, _tokens.isNotEmpty && _tokens.first == "{" ? 1 : 0, 0);
    final int outputCount = range.length ~/ 2;
    final List<double> out = <double>[];
    final int start = stack.length - outputCount;
    for (int i = 0; i < outputCount; i++) {
      final int index = start + i;
      final double value = index >= 0 && index < stack.length ? stack[index] : 0;
      out.add(UPdfFunction._clamp(value, range[i * 2], range[i * 2 + 1]));
    }
    return out;
  }

  int _skipBlock(int start) {
    int depth = 0;
    int index = start;
    while (index < _tokens.length) {
      if (_tokens[index] == "{") depth++;
      if (_tokens[index] == "}") {
        depth--;
        if (depth == 0) return index + 1;
      }
      index++;
    }
    return _tokens.length;
  }

  int _run(List<double> stack, int start, int depth) {
    if (depth > 32) return _tokens.length;
    int index = start;
    while (index < _tokens.length) {
      final String token = _tokens[index];
      if (token == "}") return index + 1;
      if (token == "{") {
        final int first = index + 1;
        final int afterFirst = _skipBlock(index);
        if (afterFirst < _tokens.length && _tokens[afterFirst] == "{") {
          final int second = afterFirst + 1;
          final int afterSecond = _skipBlock(afterFirst);
          if (afterSecond < _tokens.length && _tokens[afterSecond] == "ifelse") {
            final double condition = stack.isEmpty ? 0 : stack.removeLast();
            _run(stack, condition != 0 ? first : second, depth + 1);
            index = afterSecond + 1;
            continue;
          }
          index = afterSecond;
          continue;
        }
        if (afterFirst < _tokens.length && _tokens[afterFirst] == "if") {
          final double condition = stack.isEmpty ? 0 : stack.removeLast();
          if (condition != 0) _run(stack, first, depth + 1);
          index = afterFirst + 1;
          continue;
        }
        index = afterFirst;
        continue;
      }
      final double? number = double.tryParse(token);
      if (number != null) {
        stack.add(number);
        index++;
        if (stack.length > 128) stack.removeRange(0, stack.length - 128);
        continue;
      }
      _apply(stack, token);
      index++;
    }
    return index;
  }

  void _apply(List<double> stack, String token) {
    double pop() => stack.isEmpty ? 0 : stack.removeLast();
    switch (token) {
      case "add":
        {
          final double b = pop();
          stack.add(pop() + b);
        }
        break;
      case "sub":
        {
          final double b = pop();
          stack.add(pop() - b);
        }
        break;
      case "mul":
        {
          final double b = pop();
          stack.add(pop() * b);
        }
        break;
      case "div":
        {
          final double b = pop();
          final double a = pop();
          stack.add(b == 0 ? 0 : a / b);
        }
        break;
      case "idiv":
        {
          final double b = pop();
          final double a = pop();
          stack.add(b == 0 ? 0 : (a ~/ b).toDouble());
        }
        break;
      case "mod":
        {
          final double b = pop();
          final double a = pop();
          stack.add(b == 0 ? 0 : a % b);
        }
        break;
      case "neg":
        stack.add(-pop());
        break;
      case "abs":
        stack.add(pop().abs());
        break;
      case "sqrt":
        stack.add(sqrt(pop().abs()));
        break;
      case "sin":
        stack.add(sin(pop() * pi / 180));
        break;
      case "cos":
        stack.add(cos(pop() * pi / 180));
        break;
      case "atan":
        {
          final double denominator = pop();
          final double numerator = pop();
          double angle = atan2(numerator, denominator) * 180 / pi;
          if (angle < 0) angle += 360;
          stack.add(angle);
        }
        break;
      case "exp":
        {
          final double exponent = pop();
          stack.add(pow(pop(), exponent).toDouble());
        }
        break;
      case "ln":
        {
          final double value = pop();
          stack.add(value <= 0 ? 0 : log(value));
        }
        break;
      case "log":
        {
          final double value = pop();
          stack.add(value <= 0 ? 0 : log(value) / ln10);
        }
        break;
      case "cvi":
      case "truncate":
        stack.add(pop().truncateToDouble());
        break;
      case "cvr":
        break;
      case "floor":
        stack.add(pop().floorToDouble());
        break;
      case "ceiling":
        stack.add(pop().ceilToDouble());
        break;
      case "round":
        stack.add(pop().roundToDouble());
        break;
      case "dup":
        {
          final double value = pop();
          stack.add(value);
          stack.add(value);
        }
        break;
      case "pop":
        pop();
        break;
      case "exch":
        {
          final double b = pop();
          final double a = pop();
          stack.add(b);
          stack.add(a);
        }
        break;
      case "copy":
        {
          final int count = pop().toInt();
          if (count > 0 && count <= stack.length) stack.addAll(stack.sublist(stack.length - count));
        }
        break;
      case "index":
        {
          final int offset = pop().toInt();
          final int position = stack.length - 1 - offset;
          stack.add(position >= 0 && position < stack.length ? stack[position] : 0);
        }
        break;
      case "roll":
        {
          final int shift = pop().toInt();
          final int count = pop().toInt();
          if (count > 0 && count <= stack.length) {
            final List<double> slice = stack.sublist(stack.length - count);
            stack.removeRange(stack.length - count, stack.length);
            final int normalized = ((shift % count) + count) % count;
            stack.addAll(<double>[...slice.sublist(count - normalized), ...slice.sublist(0, count - normalized)]);
          }
        }
        break;
      case "eq":
        stack.add(pop() == pop() ? 1 : 0);
        break;
      case "ne":
        stack.add(pop() != pop() ? 1 : 0);
        break;
      case "gt":
        {
          final double b = pop();
          stack.add(pop() > b ? 1 : 0);
        }
        break;
      case "ge":
        {
          final double b = pop();
          stack.add(pop() >= b ? 1 : 0);
        }
        break;
      case "lt":
        {
          final double b = pop();
          stack.add(pop() < b ? 1 : 0);
        }
        break;
      case "le":
        {
          final double b = pop();
          stack.add(pop() <= b ? 1 : 0);
        }
        break;
      case "and":
        {
          final int b = pop().toInt();
          stack.add((pop().toInt() & b).toDouble());
        }
        break;
      case "or":
        {
          final int b = pop().toInt();
          stack.add((pop().toInt() | b).toDouble());
        }
        break;
      case "xor":
        {
          final int b = pop().toInt();
          stack.add((pop().toInt() ^ b).toDouble());
        }
        break;
      case "not":
        {
          final double value = pop();
          stack.add(value == 0 ? 1 : (value == 1 ? 0 : (~value.toInt()).toDouble()));
        }
        break;
      case "bitshift":
        {
          final int shift = pop().toInt();
          final int value = pop().toInt();
          stack.add((shift >= 0 ? value << shift : value >> -shift).toDouble());
        }
        break;
      case "true":
        stack.add(1);
        break;
      case "false":
        stack.add(0);
        break;
      default:
        break;
    }
  }
}

abstract class UPdfColorSpace {
  int get components;

  String get family;

  List<double> get initial;

  Color color(List<double> values);

  bool get isPattern => false;

  static const UPdfColorSpace deviceGray = _UPdfGraySpace();
  static const UPdfColorSpace deviceRgb = _UPdfRgbSpace();
  static const UPdfColorSpace deviceCmyk = _UPdfCmykSpace();
  static const UPdfColorSpace pattern = _UPdfPatternSpace();

  static int _byte(double value) => (value * 255).round().clamp(0, 255);

  static Future<UPdfColorSpace> load(UPdfDocument document, Object? value, {UPdfDict? resources, int depth = 0}) async {
    if (depth > 8) return deviceGray;
    final Object? resolved = await document.resolve(value);
    if (resolved is UPdfName) {
      switch (resolved.value) {
        case "DeviceGray":
        case "G":
        case "CalGray":
          return deviceGray;
        case "DeviceRGB":
        case "RGB":
        case "CalRGB":
          return deviceRgb;
        case "DeviceCMYK":
        case "CMYK":
          return deviceCmyk;
        case "Pattern":
          return pattern;
        default:
          final Object? spaces = await document.resolve(resources?["ColorSpace"]);
          if (spaces is UPdfDict && spaces.has(resolved.value)) return load(document, spaces[resolved.value], resources: resources, depth: depth + 1);
          return deviceGray;
      }
    }
    if (resolved is! List<Object?> || resolved.isEmpty) return deviceGray;
    final Object? head = await document.resolve(resolved.first);
    final String name = head is UPdfName ? head.value : "";
    switch (name) {
      case "ICCBased":
        final Object? stream = resolved.length > 1 ? await document.resolve(resolved[1]) : null;
        final int count = stream is UPdfStream ? (((await document.resolve(stream.dict["N"])) as num?)?.toInt() ?? 3) : 3;
        if (count == 1) return deviceGray;
        if (count == 4) return deviceCmyk;
        return deviceRgb;
      case "Indexed":
      case "I":
        if (resolved.length < 4) return deviceGray;
        final UPdfColorSpace base = await load(document, resolved[1], resources: resources, depth: depth + 1);
        final Object? lookupObject = await document.resolve(resolved[3]);
        Uint8List lookup = Uint8List(0);
        if (lookupObject is UPdfString) lookup = lookupObject.bytes;
        if (lookupObject is UPdfStream) lookup = (await document.decodeStream(lookupObject)).bytes;
        final int hival = ((await document.resolve(resolved[2])) as num?)?.toInt() ?? 0;
        return _UPdfIndexedSpace(base, lookup, hival);
      case "Separation":
      case "DeviceN":
        final int inputs = name == "Separation" ? 1 : await _deviceNCount(document, resolved);
        final UPdfColorSpace alternate = resolved.length > 2 ? await load(document, resolved[2], resources: resources, depth: depth + 1) : deviceGray;
        final UPdfFunction? tint = resolved.length > 3 ? await UPdfFunction.load(document, resolved[3]) : null;
        final Object? firstName = resolved.length > 1 ? await document.resolve(resolved[1]) : null;
        final bool isNone = firstName is UPdfName && firstName.value == "None";
        return _UPdfSeparationSpace(inputs, alternate, tint, isNone);
      case "CalRGB":
        return deviceRgb;
      case "CalGray":
        return deviceGray;
      case "Lab":
        return const _UPdfLabSpace();
      case "Pattern":
        return pattern;
      case "DeviceGray":
        return deviceGray;
      case "DeviceRGB":
        return deviceRgb;
      case "DeviceCMYK":
        return deviceCmyk;
      default:
        return deviceGray;
    }
  }

  static Future<int> _deviceNCount(UPdfDocument document, List<Object?> array) async {
    if (array.length < 2) return 1;
    final Object? names = await document.resolve(array[1]);
    return names is List<Object?> ? names.length : 1;
  }
}

class _UPdfGraySpace implements UPdfColorSpace {
  const _UPdfGraySpace();

  @override
  int get components => 1;

  @override
  String get family => "DeviceGray";

  @override
  List<double> get initial => const <double>[0];

  @override
  bool get isPattern => false;

  @override
  Color color(List<double> values) {
    final int gray = UPdfColorSpace._byte(values.isEmpty ? 0 : values.first.clamp(0, 1).toDouble());
    return Color.fromARGB(255, gray, gray, gray);
  }
}

class _UPdfRgbSpace implements UPdfColorSpace {
  const _UPdfRgbSpace();

  @override
  int get components => 3;

  @override
  String get family => "DeviceRGB";

  @override
  List<double> get initial => const <double>[0, 0, 0];

  @override
  bool get isPattern => false;

  @override
  Color color(List<double> values) => Color.fromARGB(
    255,
    UPdfColorSpace._byte(values.isNotEmpty ? values[0].clamp(0, 1).toDouble() : 0),
    UPdfColorSpace._byte(values.length > 1 ? values[1].clamp(0, 1).toDouble() : 0),
    UPdfColorSpace._byte(values.length > 2 ? values[2].clamp(0, 1).toDouble() : 0),
  );
}

class _UPdfCmykSpace implements UPdfColorSpace {
  const _UPdfCmykSpace();

  @override
  int get components => 4;

  @override
  String get family => "DeviceCMYK";

  @override
  List<double> get initial => const <double>[0, 0, 0, 1];

  @override
  bool get isPattern => false;

  @override
  Color color(List<double> values) {
    final double c = values.isNotEmpty ? values[0].clamp(0, 1).toDouble() : 0;
    final double m = values.length > 1 ? values[1].clamp(0, 1).toDouble() : 0;
    final double y = values.length > 2 ? values[2].clamp(0, 1).toDouble() : 0;
    final double k = values.length > 3 ? values[3].clamp(0, 1).toDouble() : 0;
    return Color.fromARGB(255, UPdfColorSpace._byte((1 - c) * (1 - k)), UPdfColorSpace._byte((1 - m) * (1 - k)), UPdfColorSpace._byte((1 - y) * (1 - k)));
  }
}

class _UPdfPatternSpace implements UPdfColorSpace {
  const _UPdfPatternSpace();

  @override
  int get components => 1;

  @override
  String get family => "Pattern";

  @override
  List<double> get initial => const <double>[0];

  @override
  bool get isPattern => true;

  @override
  Color color(List<double> values) => const Color(0xFF808080);
}

class _UPdfIndexedSpace implements UPdfColorSpace {
  const _UPdfIndexedSpace(this.base, this.lookup, this.hival);

  final UPdfColorSpace base;
  final Uint8List lookup;
  final int hival;

  @override
  int get components => 1;

  @override
  String get family => "Indexed";

  @override
  List<double> get initial => const <double>[0];

  @override
  bool get isPattern => false;

  @override
  Color color(List<double> values) {
    final int index = (values.isEmpty ? 0 : values.first.round()).clamp(0, hival < 0 ? 0 : hival);
    final int count = base.components;
    final List<double> out = <double>[];
    for (int i = 0; i < count; i++) {
      final int position = index * count + i;
      out.add(position < lookup.length ? lookup[position] / 255 : 0);
    }
    if (base.family == "Lab") {
      final double lightness = out.isNotEmpty ? out[0] * 100 : 0;
      final double a = out.length > 1 ? out[1] * 255 - 128 : 0;
      final double b = out.length > 2 ? out[2] * 255 - 128 : 0;
      return base.color(<double>[lightness, a, b]);
    }
    return base.color(out);
  }
}

class _UPdfSeparationSpace implements UPdfColorSpace {
  const _UPdfSeparationSpace(this.inputs, this.alternate, this.tint, this.isNone);

  final int inputs;
  final UPdfColorSpace alternate;
  final UPdfFunction? tint;
  final bool isNone;

  @override
  int get components => inputs;

  @override
  String get family => "Separation";

  @override
  List<double> get initial => List<double>.filled(inputs, 1);

  @override
  bool get isPattern => false;

  @override
  Color color(List<double> values) {
    if (isNone) return const Color(0x00000000);
    final UPdfFunction? transform = tint;
    if (transform == null) {
      final double value = values.isEmpty ? 0 : values.first.clamp(0, 1).toDouble();
      final int gray = UPdfColorSpace._byte(1 - value);
      return Color.fromARGB(255, gray, gray, gray);
    }
    return alternate.color(transform.evaluate(values));
  }
}

class _UPdfLabSpace implements UPdfColorSpace {
  const _UPdfLabSpace();

  @override
  int get components => 3;

  @override
  String get family => "Lab";

  @override
  List<double> get initial => const <double>[0, 0, 0];

  @override
  bool get isPattern => false;

  @override
  Color color(List<double> values) {
    final double l = values.isNotEmpty ? values[0] : 0;
    final double a = values.length > 1 ? values[1] : 0;
    final double b = values.length > 2 ? values[2] : 0;
    final double fy = (l + 16) / 116;
    final double fx = fy + a / 500;
    final double fz = fy - b / 200;
    double invert(double t) => t > 6 / 29 ? t * t * t : 3 * (6 / 29) * (6 / 29) * (t - 4 / 29);
    final double x = 0.9505 * invert(fx);
    final double y = invert(fy);
    final double z = 1.089 * invert(fz);
    double gamma(double c) => c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4).toDouble() - 0.055;
    final double r = gamma(3.2406 * x - 1.5372 * y - 0.4986 * z).clamp(0, 1).toDouble();
    final double g = gamma(-0.9689 * x + 1.8758 * y + 0.0415 * z).clamp(0, 1).toDouble();
    final double bl = gamma(0.0557 * x - 0.204 * y + 1.057 * z).clamp(0, 1).toDouble();
    return Color.fromARGB(255, UPdfColorSpace._byte(r), UPdfColorSpace._byte(g), UPdfColorSpace._byte(bl));
  }
}

class UPdfCcittDecoder {
  UPdfCcittDecoder({required this.columns, required this.rows, required this.k, required this.blackIs1, required this.byteAlign});

  final int columns;
  final int rows;
  final int k;
  final bool blackIs1;
  final bool byteAlign;

  static const String _whiteCodes =
      "0:00110101 1:000111 2:0111 3:1000 4:1011 5:1100 6:1110 7:1111 8:10011 9:10100 10:00111 11:01000 12:001000 13:000011 14:110100 15:110101 "
      "16:101010 17:101011 18:0100111 19:0001100 20:0001000 21:0010111 22:0000011 23:0000100 24:0101000 25:0101011 26:0010011 27:0100100 28:0011000 "
      "29:00000010 30:00000011 31:00011010 32:00011011 33:00010010 34:00010011 35:00010100 36:00010101 37:00010110 38:00010111 39:00101000 40:00101001 "
      "41:00101010 42:00101011 43:00101100 44:00101101 45:00000100 46:00000101 47:00001010 48:00001011 49:01010010 50:01010011 51:01010100 52:01010101 "
      "53:00100100 54:00100101 55:01011000 56:01011001 57:01011010 58:01011011 59:01001010 60:01001011 61:00110010 62:00110011 63:00110100 "
      "64:11011 128:10010 192:010111 256:0110111 320:00110110 384:00110111 448:01100100 512:01100101 576:01101000 640:01100111 704:011001100 "
      "768:011001101 832:011010010 896:011010011 960:011010100 1024:011010101 1088:011010110 1152:011010111 1216:011011000 1280:011011001 "
      "1344:011011010 1408:011011011 1472:010011000 1536:010011001 1600:010011010 1664:011000 1728:010011011";

  static const String _blackCodes =
      "0:0000110111 1:010 2:11 3:10 4:011 5:0011 6:0010 7:00011 8:000101 9:000100 10:0000100 11:0000101 12:0000111 13:00000100 14:00000111 "
      "15:000011000 16:0000010111 17:0000011000 18:0000001000 19:00001100111 20:00001101000 21:00001101100 22:00000110111 23:00000101000 "
      "24:00000010111 25:00000011000 26:000011001010 27:000011001011 28:000011001100 29:000011001101 30:000001101000 31:000001101001 "
      "32:000001101010 33:000001101011 34:000011010010 35:000011010011 36:000011010100 37:000011010101 38:000011010110 39:000011010111 "
      "40:000001101100 41:000001101101 42:000011011010 43:000011011011 44:000001010100 45:000001010101 46:000001010110 47:000001010111 "
      "48:000001100100 49:000001100101 50:000001010010 51:000001010011 52:000000100100 53:000000110111 54:000000111000 55:000000100111 "
      "56:000000101000 57:000001011000 58:000001011001 59:000000101011 60:000000101100 61:000001011010 62:000001100110 63:000001100111 "
      "64:0000001111 128:000011001000 192:000011001001 256:000001011011 320:000000110011 384:000000110100 448:000000110101 512:0000001101100 "
      "576:0000001101101 640:0000001001010 704:0000001001011 768:0000001001100 832:0000001001101 896:0000001110010 960:0000001110011 "
      "1024:0000001110100 1088:0000001110101 1152:0000001110110 1216:0000001110111 1280:0000001010010 1344:0000001010011 1408:0000001010100 "
      "1472:0000001010101 1536:0000001011010 1600:0000001011011 1664:0000001100100 1728:0000001100101";

  static const String _extendedCodes =
      "1792:00000001000 1856:00000001100 1920:00000001101 1984:000000010010 2048:000000010011 2112:000000010100 2176:000000010101 "
      "2240:000000010110 2304:000000010111 2368:000000011100 2432:000000011101 2496:000000011110 2560:000000011111";

  static Map<String, int>? _white;
  static Map<String, int>? _black;

  static Map<String, int> _table(String source, String extended) {
    final Map<String, int> map = <String, int>{};
    for (final String entry in "$source $extended".split(" ")) {
      if (entry.isEmpty) continue;
      final int colon = entry.indexOf(":");
      if (colon <= 0) continue;
      final int? run = int.tryParse(entry.substring(0, colon));
      if (run != null) map[entry.substring(colon + 1)] = run;
    }
    return map;
  }

  static Map<String, int> get whiteTable => _white ??= _table(_whiteCodes, _extendedCodes);

  static Map<String, int> get blackTable => _black ??= _table(_blackCodes, _extendedCodes);

  late Uint8List _data;
  int _bitPosition = 0;

  bool get _atEnd => _bitPosition >= _data.length * 8;

  int _readBit() {
    if (_atEnd) return -1;
    final int byte = _data[_bitPosition >> 3];
    final int bit = (byte >> (7 - (_bitPosition & 7))) & 1;
    _bitPosition++;
    return bit;
  }

  int _readRun(bool white) {
    final Map<String, int> table = white ? whiteTable : blackTable;
    int total = 0;
    int guard = 0;
    while (guard < 64) {
      guard++;
      final StringBuffer buffer = StringBuffer();
      int? run;
      for (int length = 0; length < 14; length++) {
        final int bit = _readBit();
        if (bit < 0) return total > 0 ? total : -1;
        buffer.write(bit);
        run = table[buffer.toString()];
        if (run != null) break;
      }
      if (run == null) return total > 0 ? total : -1;
      total += run;
      if (run < 64) return total;
    }
    return total;
  }

  Uint8List decode(Uint8List input) {
    _data = input;
    _bitPosition = 0;
    final int width = columns <= 0 ? 1728 : columns;
    final int rowBytes = (width + 7) >> 3;
    final int maxRows = rows > 0 ? rows : 1 << 20;
    final List<int> out = <int>[];
    List<int> reference = <int>[width, width];
    int row = 0;
    while (row < maxRows && !_atEnd) {
      final List<int> changes = k < 0 ? _decode2D(reference, width) : (k == 0 ? _decode1D(width) : _decodeMixed(reference, width));
      if (changes.isEmpty) break;
      final Uint8List line = Uint8List(rowBytes);
      int color = 0;
      int position = 0;
      for (final int change in changes) {
        final int end = change > width ? width : change;
        if (color == 1) {
          for (int x = position; x < end; x++) {
            line[x >> 3] |= 0x80 >> (x & 7);
          }
        }
        position = end;
        color ^= 1;
        if (position >= width) break;
      }
      if (color == 1 && position < width) {
        for (int x = position; x < width; x++) {
          line[x >> 3] |= 0x80 >> (x & 7);
        }
      }
      out.addAll(line);
      reference = changes;
      row++;
      if (byteAlign) _bitPosition = (_bitPosition + 7) & ~7;
    }
    while (rows > 0 && out.length < rows * rowBytes) {
      out.add(0);
    }
    final Uint8List result = Uint8List.fromList(out);
    if (!blackIs1) {
      for (int i = 0; i < result.length; i++) {
        result[i] = ~result[i] & 0xFF;
      }
    }
    return result;
  }

  List<int> _decode1D(int width) {
    final List<int> changes = <int>[];
    int position = 0;
    bool white = true;
    while (position < width) {
      final int run = _readRun(white);
      if (run < 0) return changes;
      position += run;
      changes.add(position > width ? width : position);
      white = !white;
    }
    return changes;
  }

  List<int> _decodeMixed(List<int> reference, int width) {
    final int bit = _readBit();
    if (bit < 0) return const <int>[];
    return bit == 1 ? _decode1D(width) : _decode2D(reference, width);
  }

  List<int> _decode2D(List<int> reference, int width) {
    final List<int> changes = <int>[];
    int a0 = -1;
    int color = 0;
    int guard = 0;
    while (a0 < width && guard < width * 4 + 64) {
      guard++;
      int b1 = width;
      for (int i = 0; i < reference.length; i++) {
        if (reference[i] > a0 && i % 2 == color) {
          b1 = reference[i];
          break;
        }
      }
      if (b1 > width) b1 = width;
      int b2 = width;
      for (int i = 0; i < reference.length; i++) {
        if (reference[i] > b1) {
          b2 = reference[i];
          break;
        }
      }
      if (b2 > width) b2 = width;
      final String mode = _readMode();
      if (mode.isEmpty) break;
      if (mode == "P") {
        a0 = b2;
        continue;
      }
      if (mode == "H") {
        final int start = a0 < 0 ? 0 : a0;
        final int run1 = _readRun(color == 0);
        final int run2 = _readRun(color != 0);
        if (run1 < 0 || run2 < 0) break;
        final int a1 = start + run1;
        final int a2 = a1 + run2;
        changes.add(a1 > width ? width : a1);
        changes.add(a2 > width ? width : a2);
        a0 = a2;
        continue;
      }
      final int? delta = int.tryParse(mode);
      if (delta == null) break;
      final int a1 = b1 + delta;
      changes.add(a1 < 0 ? 0 : (a1 > width ? width : a1));
      a0 = a1;
      color ^= 1;
    }
    return changes;
  }

  String _readMode() {
    final StringBuffer buffer = StringBuffer();
    for (int length = 0; length < 12; length++) {
      final int bit = _readBit();
      if (bit < 0) return "";
      buffer.write(bit);
      final String code = buffer.toString();
      switch (code) {
        case "1":
          return "0";
        case "011":
          return "1";
        case "010":
          return "-1";
        case "001":
          return "H";
        case "0001":
          return "P";
        case "000011":
          return "2";
        case "000010":
          return "-2";
        case "0000011":
          return "3";
        case "0000010":
          return "-3";
        case "000000000001":
          return "";
        default:
          break;
      }
    }
    return "";
  }
}

abstract class UPdfImages {
  static Future<ui.Image?> fromPixels(Uint8List rgba, int width, int height) async {
    if (width <= 0 || height <= 0 || rgba.length < width * height * 4) return null;
    try {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
      final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(buffer, width: width, height: height, pixelFormat: ui.PixelFormat.rgba8888);
      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } on Object {
      return null;
    }
  }

  static Future<ui.Image?> fromEncoded(Uint8List bytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } on Object {
      return null;
    }
  }

  static Future<ui.Image?> decode(UPdfDocument document, UPdfStream stream, {UPdfDict? resources, Color fillColor = const Color(0xFF000000)}) async {
    try {
      final UPdfDict dict = stream.dict;
      final int width = ((await document.resolve(dict["Width"] ?? dict["W"])) as num?)?.toInt() ?? 0;
      final int height = ((await document.resolve(dict["Height"] ?? dict["H"])) as num?)?.toInt() ?? 0;
      if (width <= 0 || height <= 0 || width * height > 80000000) return null;
      final bool isMask = (await document.resolve(dict["ImageMask"] ?? dict["IM"])) as bool? ?? false;
      final int bits = isMask ? 1 : (((await document.resolve(dict["BitsPerComponent"] ?? dict["BPC"])) as num?)?.toInt() ?? 8);
      final UPdfDecodedStream decoded = await document.decodeStream(stream);
      final List<double> decodeArray = <double>[];
      final Object? decodeObject = await document.resolve(dict["Decode"] ?? dict["D"]);
      if (decodeObject is List<Object?>) {
        for (final Object? entry in decodeObject) {
          final Object? value = await document.resolve(entry);
          if (value is num) decodeArray.add(value.toDouble());
        }
      }
      Uint8List samples = decoded.bytes;
      UPdfColorSpace space = isMask ? UPdfColorSpace.deviceGray : await UPdfColorSpace.load(document, dict["ColorSpace"] ?? dict["CS"], resources: resources);
      final String? filter = decoded.imageFilter;
      if (filter == "DCTDecode" || filter == "DCT" || filter == "JPXDecode") {
        final ui.Image? direct = await fromEncoded(samples);
        if (direct != null) return await _applyMask(document, direct, dict, resources);
        if (filter == "JPXDecode") return null;
        return null;
      }
      if (filter == "JBIG2Decode") {
        Uint8List? globals;
        final UPdfDict? parms = decoded.imageParms;
        final Object? globalsObject = await document.resolve(parms?["JBIG2Globals"]);
        if (globalsObject is UPdfStream) globals = (await document.decodeStream(globalsObject)).bytes;
        final Uint8List? packed = UJbig2.decode(samples, width: width, height: height, globals: globals);
        if (packed == null) return null;
        samples = packed;
        space = UPdfColorSpace.deviceGray;
      }
      if (filter == "CCITTFaxDecode" || filter == "CCF") {
        final UPdfDict? parms = decoded.imageParms;
        final int k = ((await document.resolve(parms?["K"])) as num?)?.toInt() ?? 0;
        final int columns = ((await document.resolve(parms?["Columns"])) as num?)?.toInt() ?? 1728;
        final int rowCount = ((await document.resolve(parms?["Rows"])) as num?)?.toInt() ?? height;
        final bool blackIs1 = (await document.resolve(parms?["BlackIs1"])) as bool? ?? false;
        final bool align = (await document.resolve(parms?["EncodedByteAlign"])) as bool? ?? false;
        samples = UPdfCcittDecoder(columns: columns, rows: rowCount, k: k, blackIs1: blackIs1, byteAlign: align).decode(samples);
        space = UPdfColorSpace.deviceGray;
      }
      final int componentCount = isMask ? 1 : space.components;
      final int maxValue = (1 << bits) - 1;
      final int rowBits = width * componentCount * bits;
      final int rowBytes = (rowBits + 7) >> 3;
      final Uint8List rgba = Uint8List(width * height * 4);
      final bool indexed = space.family == "Indexed";
      final List<double> values = List<double>.filled(componentCount, 0);
      final Map<int, int> cache = <int, int>{};
      for (int y = 0; y < height; y++) {
        final int rowStart = y * rowBytes;
        if (rowStart >= samples.length) break;
        for (int x = 0; x < width; x++) {
          int key = 0;
          for (int c = 0; c < componentCount; c++) {
            final int bitOffset = (x * componentCount + c) * bits;
            int raw = 0;
            if (bits == 8) {
              final int index = rowStart + (bitOffset >> 3);
              raw = index < samples.length ? samples[index] : 0;
            } else if (bits == 16) {
              final int index = rowStart + (bitOffset >> 3);
              raw = index + 1 < samples.length ? samples[index] : 0;
            } else {
              for (int b = 0; b < bits; b++) {
                final int bit = bitOffset + b;
                final int index = rowStart + (bit >> 3);
                final int value = index < samples.length ? (samples[index] >> (7 - (bit & 7))) & 1 : 0;
                raw = (raw << 1) | value;
              }
            }
            if (bits == 16) raw = raw & 0xFF;
            double normalized = indexed ? raw.toDouble() : raw / (bits == 16 ? 255 : maxValue);
            if (decodeArray.length >= (c + 1) * 2) {
              final double low = decodeArray[c * 2];
              final double high = decodeArray[c * 2 + 1];
              normalized = indexed ? low + raw * (high - low) / maxValue : low + normalized * (high - low);
            }
            values[c] = normalized;
            key = (key << 8) | (raw & 0xFF);
          }
          final int offset = (y * width + x) * 4;
          if (isMask) {
            final bool paint = values[0] < 0.5;
            rgba[offset] = (fillColor.r * 255).round();
            rgba[offset + 1] = (fillColor.g * 255).round();
            rgba[offset + 2] = (fillColor.b * 255).round();
            rgba[offset + 3] = paint ? 255 : 0;
            continue;
          }
          final int? cached = componentCount <= 2 ? cache[key] : null;
          final int argb = cached ?? space.color(values).toARGB32();
          if (componentCount <= 2 && cached == null) cache[key] = argb;
          rgba[offset] = (argb >> 16) & 0xFF;
          rgba[offset + 1] = (argb >> 8) & 0xFF;
          rgba[offset + 2] = argb & 0xFF;
          rgba[offset + 3] = 255;
        }
      }
      await _applyAlpha(document, rgba, width, height, dict, resources);
      return await fromPixels(rgba, width, height);
    } on Object {
      return null;
    }
  }

  static Future<ui.Image?> _applyMask(UPdfDocument document, ui.Image image, UPdfDict dict, UPdfDict? resources) async {
    final Object? smask = await document.resolve(dict["SMask"]);
    if (smask is! UPdfStream) return image;
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final ui.Image? mask = await decode(document, smask, resources: resources);
      if (mask == null) return image;
      final Rect bounds = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      canvas.saveLayer(bounds, Paint());
      canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), bounds, Paint());
      canvas.drawImageRect(mask, Rect.fromLTWH(0, 0, mask.width.toDouble(), mask.height.toDouble()), bounds, Paint()..blendMode = BlendMode.dstIn);
      canvas.restore();
      final ui.Picture picture = recorder.endRecording();
      final ui.Image composed = await picture.toImage(image.width, image.height);
      picture.dispose();
      mask.dispose();
      image.dispose();
      return composed;
    } on Object {
      return image;
    }
  }

  static Future<void> _applyAlpha(UPdfDocument document, Uint8List rgba, int width, int height, UPdfDict dict, UPdfDict? resources) async {
    final Object? smaskObject = await document.resolve(dict["SMask"]);
    if (smaskObject is! UPdfStream) return;
    try {
      final int maskWidth = ((await document.resolve(smaskObject.dict["Width"])) as num?)?.toInt() ?? 0;
      final int maskHeight = ((await document.resolve(smaskObject.dict["Height"])) as num?)?.toInt() ?? 0;
      final int maskBits = ((await document.resolve(smaskObject.dict["BitsPerComponent"])) as num?)?.toInt() ?? 8;
      final UPdfDecodedStream mask = await document.decodeStream(smaskObject);
      if (mask.isImageEncoded || maskWidth <= 0 || maskHeight <= 0) return;
      final int rowBytes = (maskWidth * maskBits + 7) >> 3;
      for (int y = 0; y < height; y++) {
        final int maskY = maskHeight == height ? y : (y * maskHeight ~/ height);
        for (int x = 0; x < width; x++) {
          final int maskX = maskWidth == width ? x : (x * maskWidth ~/ width);
          int alpha = 255;
          if (maskBits == 8) {
            final int index = maskY * rowBytes + maskX;
            alpha = index < mask.bytes.length ? mask.bytes[index] : 255;
          } else if (maskBits == 1) {
            final int bit = maskX;
            final int index = maskY * rowBytes + (bit >> 3);
            alpha = index < mask.bytes.length ? (((mask.bytes[index] >> (7 - (bit & 7))) & 1) == 1 ? 255 : 0) : 255;
          }
          rgba[(y * width + x) * 4 + 3] = alpha;
        }
      }
    } on Object {
      return;
    }
  }
}

class UPdfShadingPaint {
  const UPdfShadingPaint({this.shader, this.fallback, this.background});

  final Shader? shader;
  final Color? fallback;
  final Color? background;

  static Future<UPdfShadingPaint?> build(UPdfDocument document, UPdfDict shading, {UPdfDict? resources}) async {
    try {
      final int type = ((await document.resolve(shading["ShadingType"])) as num?)?.toInt() ?? 0;
      final UPdfColorSpace space = await UPdfColorSpace.load(document, shading["ColorSpace"], resources: resources);
      final UPdfFunction? function = await UPdfFunction.load(document, shading["Function"]);
      final List<double> coords = <double>[];
      final Object? coordsObject = await document.resolve(shading["Coords"]);
      if (coordsObject is List<Object?>) {
        for (final Object? entry in coordsObject) {
          final Object? value = await document.resolve(entry);
          if (value is num) coords.add(value.toDouble());
        }
      }
      final List<double> domain = <double>[0, 1];
      final Object? domainObject = await document.resolve(shading["Domain"]);
      if (domainObject is List<Object?> && domainObject.length >= 2) {
        for (int i = 0; i < 2; i++) {
          final Object? value = await document.resolve(domainObject[i]);
          if (value is num) domain[i] = value.toDouble();
        }
      }
      final List<bool> extend = <bool>[false, false];
      final Object? extendObject = await document.resolve(shading["Extend"]);
      if (extendObject is List<Object?> && extendObject.length >= 2) {
        extend[0] = extendObject[0] as bool? ?? false;
        extend[1] = extendObject[1] as bool? ?? false;
      }
      const int steps = 64;
      final List<Color> colors = <Color>[];
      final List<double> stops = <double>[];
      for (int i = 0; i < steps; i++) {
        final double t = i / (steps - 1);
        final double value = domain[0] + t * (domain[1] - domain[0]);
        final List<double> components = function?.evaluate(<double>[value]) ?? <double>[value];
        colors.add(space.color(components));
        stops.add(t);
      }
      if (type == 2 && coords.length >= 4) {
        return UPdfShadingPaint(
          shader: ui.Gradient.linear(
            Offset(coords[0], coords[1]),
            Offset(coords[2], coords[3]),
            colors,
            stops,
            extend[0] || extend[1] ? TileMode.clamp : TileMode.decal,
          ),
        );
      }
      if (type == 3 && coords.length >= 6) {
        final double r0 = coords[2];
        final double r1 = coords[5];
        final Offset center = Offset(coords[3], coords[4]);
        final Offset focal = Offset(coords[0], coords[1]);
        final double radius = r1 > r0 ? r1 : r0;
        if (radius <= 0) return UPdfShadingPaint(fallback: colors.isEmpty ? null : colors.last);
        return UPdfShadingPaint(
          shader: ui.Gradient.radial(
            center,
            radius,
            r1 >= r0 ? colors : colors.reversed.toList(),
            stops,
            extend[0] || extend[1] ? TileMode.clamp : TileMode.decal,
            null,
            focal,
            r0 < r1 ? r0 / radius : r1 / radius,
          ),
        );
      }
      final Color average = _average(colors);
      return UPdfShadingPaint(fallback: average);
    } on Object {
      return null;
    }
  }

  static Color _average(List<Color> colors) {
    if (colors.isEmpty) return const Color(0xFF808080);
    double r = 0;
    double g = 0;
    double b = 0;
    for (final Color color in colors) {
      r += color.r;
      g += color.g;
      b += color.b;
    }
    return Color.fromARGB(255, (r / colors.length * 255).round(), (g / colors.length * 255).round(), (b / colors.length * 255).round());
  }
}

List<double> uPdfMul(List<double> m, List<double> n) => <double>[
  m[0] * n[0] + m[1] * n[2],
  m[0] * n[1] + m[1] * n[3],
  m[2] * n[0] + m[3] * n[2],
  m[2] * n[1] + m[3] * n[3],
  m[4] * n[0] + m[5] * n[2] + n[4],
  m[4] * n[1] + m[5] * n[3] + n[5],
];

List<double> uPdfInvert(List<double> m) {
  final double determinant = m[0] * m[3] - m[1] * m[2];
  if (determinant == 0) return <double>[1, 0, 0, 1, 0, 0];
  final double a = m[3] / determinant;
  final double b = -m[1] / determinant;
  final double c = -m[2] / determinant;
  final double d = m[0] / determinant;
  return <double>[a, b, c, d, -(m[4] * a + m[5] * c), -(m[4] * b + m[5] * d)];
}

Offset uPdfApply(List<double> m, double x, double y) => Offset(m[0] * x + m[2] * y + m[4], m[1] * x + m[3] * y + m[5]);

Float64List uPdfMatrix4(List<double> m) => Float64List.fromList(<double>[m[0], m[1], 0, 0, m[2], m[3], 0, 0, 0, 0, 1, 0, m[4], m[5], 0, 1]);

List<double> uPdfBaseMatrix(Rect box, int rotation, double scale) {
  final double left = box.left;
  final double right = box.right;
  final double minY = box.top;
  final double maxY = box.bottom;
  switch (rotation) {
    case 90:
      return <double>[0, scale, scale, 0, -minY * scale, -left * scale];
    case 180:
      return <double>[-scale, 0, 0, scale, right * scale, -minY * scale];
    case 270:
      return <double>[0, -scale, -scale, 0, maxY * scale, right * scale];
    default:
      return <double>[scale, 0, 0, -scale, -left * scale, maxY * scale];
  }
}

class UPdfRenderOptions {
  const UPdfRenderOptions({
    this.scale = 1,
    this.collectText = true,
    this.drawAnnotations = true,
    this.maxOperations = 2000000,
    this.hiddenOptionalGroups = const <int>{},
  });

  final double scale;
  final bool collectText;
  final bool drawAnnotations;
  final int maxOperations;
  final Set<int> hiddenOptionalGroups;
}

class UPdfRenderResult {
  const UPdfRenderResult({required this.picture, required this.text, required this.deviceSize, this.truncated = false});

  final ui.Picture? picture;
  final UDocTextPage text;
  final Size deviceSize;
  final bool truncated;
}

class _UPdfGlyphRecord {
  const _UPdfGlyphRecord({required this.text, required this.rect, required this.fontSize, required this.fontName, required this.isSpace});

  final String text;
  final Rect rect;
  final double fontSize;
  final String fontName;
  final bool isSpace;
}

class _UPdfState {
  _UPdfState({
    required this.ctm,
    required this.fillSpace,
    required this.strokeSpace,
    required this.fillColor,
    required this.strokeColor,
    required this.lineWidth,
    required this.fillAlpha,
    required this.strokeAlpha,
    required this.cap,
    required this.join,
    required this.miterLimit,
    required this.dash,
    required this.dashPhase,
    required this.blend,
    required this.fontSize,
    required this.charSpacing,
    required this.wordSpacing,
    required this.horizontalScale,
    required this.leading,
    required this.rise,
    required this.renderMode,
    this.font,
    this.fillShader,
    this.strokeShader,
  });

  List<double> ctm;
  UPdfColorSpace fillSpace;
  UPdfColorSpace strokeSpace;
  Color fillColor;
  Color strokeColor;
  double lineWidth;
  double fillAlpha;
  double strokeAlpha;
  StrokeCap cap;
  StrokeJoin join;
  double miterLimit;
  List<double> dash;
  double dashPhase;
  BlendMode blend;
  UPdfFont? font;
  double fontSize;
  double charSpacing;
  double wordSpacing;
  double horizontalScale;
  double leading;
  double rise;
  int renderMode;
  Shader? fillShader;
  Shader? strokeShader;

  _UPdfState clone() => _UPdfState(
    ctm: List<double>.from(ctm),
    fillSpace: fillSpace,
    strokeSpace: strokeSpace,
    fillColor: fillColor,
    strokeColor: strokeColor,
    lineWidth: lineWidth,
    fillAlpha: fillAlpha,
    strokeAlpha: strokeAlpha,
    cap: cap,
    join: join,
    miterLimit: miterLimit,
    dash: List<double>.from(dash),
    dashPhase: dashPhase,
    blend: blend,
    font: font,
    fontSize: fontSize,
    charSpacing: charSpacing,
    wordSpacing: wordSpacing,
    horizontalScale: horizontalScale,
    leading: leading,
    rise: rise,
    renderMode: renderMode,
    fillShader: fillShader,
    strokeShader: strokeShader,
  );

  static _UPdfState initial(List<double> ctm) => _UPdfState(
    ctm: ctm,
    fillSpace: UPdfColorSpace.deviceGray,
    strokeSpace: UPdfColorSpace.deviceGray,
    fillColor: const Color(0xFF000000),
    strokeColor: const Color(0xFF000000),
    lineWidth: 1,
    fillAlpha: 1,
    strokeAlpha: 1,
    cap: StrokeCap.butt,
    join: StrokeJoin.miter,
    miterLimit: 10,
    dash: const <double>[],
    dashPhase: 0,
    blend: BlendMode.srcOver,
    fontSize: 0,
    charSpacing: 0,
    wordSpacing: 0,
    horizontalScale: 1,
    leading: 0,
    rise: 0,
    renderMode: 0,
  );
}

class UPdfPageRenderer {
  UPdfPageRenderer(this.document);

  final UPdfDocument document;

  Future<UPdfRenderResult> render(UPdfPage page, {UPdfRenderOptions options = const UPdfRenderOptions()}) async {
    final Rect box = page.box;
    final Size device = page.rotation == 90 || page.rotation == 270 ? Size(box.height * options.scale, box.width * options.scale) : Size(box.width * options.scale, box.height * options.scale);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, device.width, device.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, device.width, device.height), Paint()..color = const Color(0xFFFFFFFF));
    final _UPdfContentExecutor executor = _UPdfContentExecutor(document: document, canvas: canvas, options: options);
    final List<double> base = uPdfBaseMatrix(box, page.rotation, options.scale);
    try {
      final Uint8List content = await document.pageContent(page);
      await executor.run(content, page.resources, base, 0);
      if (options.drawAnnotations) await _drawAnnotations(executor, page, base);
    } on Object {
      executor.markTruncated();
    }
    final ui.Picture picture = recorder.endRecording();
    return UPdfRenderResult(picture: picture, text: executor.buildTextPage(page.index, device), deviceSize: device, truncated: executor.truncated);
  }

  Future<UDocTextPage> extractText(UPdfPage page) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final _UPdfContentExecutor executor = _UPdfContentExecutor(document: document, canvas: canvas, options: const UPdfRenderOptions(drawAnnotations: false), textOnly: true);
    final List<double> base = uPdfBaseMatrix(page.box, page.rotation, 1);
    try {
      final Uint8List content = await document.pageContent(page);
      await executor.run(content, page.resources, base, 0);
    } on Object {
      executor.markTruncated();
    }
    recorder.endRecording().dispose();
    final Size size = page.rotation == 90 || page.rotation == 270 ? Size(page.box.height, page.box.width) : Size(page.box.width, page.box.height);
    return executor.buildTextPage(page.index, size);
  }

  Future<void> _drawAnnotations(_UPdfContentExecutor executor, UPdfPage page, List<double> base) async {
    final Object? annotations = await document.resolve(page.dict["Annots"]);
    if (annotations is! List<Object?>) return;
    for (final Object? entry in annotations) {
      final Object? annotation = await document.resolve(entry);
      if (annotation is! UPdfDict) continue;
      final Object? flagsObject = await document.resolve(annotation["F"]);
      final int flags = flagsObject is num ? flagsObject.toInt() : 0;
      if (flags & 2 != 0) continue;
      final Object? subtype = annotation["Subtype"];
      if (subtype is UPdfName && (subtype.value == "Link" || subtype.value == "Popup")) continue;
      final Object? appearance = await document.resolve(annotation["AP"]);
      if (appearance is! UPdfDict) continue;
      Object? normal = await document.resolve(appearance["N"]);
      if (normal is UPdfDict && normal is! UPdfStream) {
        final Object? stateObject = await document.resolve(annotation["AS"]);
        final String state = stateObject is UPdfName ? stateObject.value : "";
        final UPdfDict states = normal;
        normal = await document.resolve(state.isNotEmpty ? states[state] : (states.keys.isEmpty ? null : states[states.keys.first]));
      }
      if (normal is! UPdfStream) continue;
      final Object? rectObject = await document.resolve(annotation["Rect"]);
      final Rect rect = uPdfRectFromArray(rectObject is List<Object?> ? rectObject : null, fallback: Rect.zero);
      if (rect.width <= 0 || rect.height <= 0) continue;
      await executor.drawAnnotationAppearance(normal, rect, base);
    }
  }
}

class _UPdfContentExecutor {
  _UPdfContentExecutor({required this.document, required this.canvas, required this.options, this.textOnly = false});

  final UPdfDocument document;
  final Canvas canvas;
  final UPdfRenderOptions options;
  final bool textOnly;

  final List<_UPdfState> _stack = <_UPdfState>[];
  final List<Object?> _operands = <Object?>[];
  final List<_UPdfGlyphRecord> _glyphs = <_UPdfGlyphRecord>[];
  final Map<String, UPdfFont> _fonts = <String, UPdfFont>{};

  late _UPdfState _state;
  Path _path = Path();
  double _startX = 0;
  double _startY = 0;
  double _currentX = 0;
  double _currentY = 0;
  int _pendingClip = 0;
  int _operations = 0;
  int _hiddenDepth = 0;
  int _markedDepth = 0;
  bool truncated = false;

  List<double> _textMatrix = <double>[1, 0, 0, 1, 0, 0];
  List<double> _lineMatrix = <double>[1, 0, 0, 1, 0, 0];

  void markTruncated() => truncated = true;

  bool get _skipDrawing => textOnly || _hiddenDepth > 0;

  Future<void> run(Uint8List content, UPdfDict? resources, List<double> baseMatrix, int depth) async {
    _state = _UPdfState.initial(List<double>.from(baseMatrix));
    canvas.save();
    canvas.transform(uPdfMatrix4(baseMatrix));
    await _execute(content, resources, depth);
    canvas.restore();
  }

  Future<void> _execute(Uint8List content, UPdfDict? resources, int depth) async {
    if (depth > 12) return;
    final UDocCursor cursor = UDocCursor(content);
    while (!cursor.isEmpty) {
      if (_operations++ > options.maxOperations) {
        truncated = true;
        return;
      }
      UPdfSyntax.skipWhitespace(cursor);
      if (cursor.isEmpty) break;
      final int byte = cursor.peek;
      if (byte == 0x2F || byte == 0x5B || byte == 0x28 || byte == 0x3C || UPdfSyntax.isDigit(byte) || byte == 0x2B || byte == 0x2D || byte == 0x2E) {
        _operands.add(UPdfSyntax.parseObject(cursor));
        if (_operands.length > 64) _operands.removeRange(0, _operands.length - 64);
        continue;
      }
      final String op = UPdfSyntax.readKeyword(cursor);
      if (op.isEmpty) {
        cursor.skip(1);
        continue;
      }
      if (op == "BI") {
        await _inlineImage(cursor, resources);
        _operands.clear();
        continue;
      }
      await _apply(op, resources, depth);
      _operands.clear();
    }
  }

  double _number(int index) {
    if (index < 0 || index >= _operands.length) return 0;
    final Object? value = _operands[index];
    return value is num ? value.toDouble() : 0;
  }

  String _name(int index) {
    if (index < 0 || index >= _operands.length) return "";
    final Object? value = _operands[index];
    return value is UPdfName ? value.value : "";
  }

  List<double> _numbers() {
    final List<double> out = <double>[];
    for (final Object? value in _operands) {
      if (value is num) out.add(value.toDouble());
    }
    return out;
  }

  Paint _fillPaint() {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = _state.blend
      ..isAntiAlias = true;
    final Shader? shader = _state.fillShader;
    if (shader != null) {
      paint.shader = shader;
      paint.color = const Color(0xFF000000).withValues(alpha: _state.fillAlpha);
    } else {
      paint.color = _state.fillColor.withValues(alpha: _state.fillColor.a * _state.fillAlpha);
    }
    return paint;
  }

  Paint _strokePaint({double? overrideWidth}) {
    final double width = overrideWidth ?? _state.lineWidth;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width <= 0 ? 0.6 : width
      ..strokeCap = _state.cap
      ..strokeJoin = _state.join
      ..strokeMiterLimit = _state.miterLimit
      ..blendMode = _state.blend
      ..isAntiAlias = true;
    final Shader? shader = _state.strokeShader;
    if (shader != null) {
      paint.shader = shader;
      paint.color = const Color(0xFF000000).withValues(alpha: _state.strokeAlpha);
    } else {
      paint.color = _state.strokeColor.withValues(alpha: _state.strokeColor.a * _state.strokeAlpha);
    }
    return paint;
  }

  Path _dashed(Path path) {
    final List<double> pattern = _state.dash;
    if (pattern.isEmpty || pattern.every((double value) => value <= 0)) return path;
    final Path out = Path();
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = _state.dashPhase % _patternLength(pattern);
      int index = 0;
      bool draw = true;
      double consumed = 0;
      while (consumed < distance && index < 512) {
        consumed += pattern[index % pattern.length];
        draw = !draw;
        index++;
      }
      distance = 0;
      while (distance < metric.length && index < 100000) {
        final double step = pattern[index % pattern.length];
        final double end = distance + step > metric.length ? metric.length : distance + step;
        if (draw && end > distance) out.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end;
        draw = !draw;
        index++;
        if (step <= 0) break;
      }
    }
    return out;
  }

  double _patternLength(List<double> pattern) {
    double total = 0;
    for (final double value in pattern) {
      total += value;
    }
    return total <= 0 ? 1 : total;
  }

  void _paintPath({required bool fill, required bool stroke, required bool evenOdd, required bool close}) {
    if (close) _path.close();
    _path.fillType = evenOdd ? PathFillType.evenOdd : PathFillType.nonZero;
    if (!_skipDrawing) {
      if (fill) canvas.drawPath(_path, _fillPaint());
      if (stroke) canvas.drawPath(_dashed(_path), _strokePaint());
    }
    _finishPath();
  }

  void _finishPath() {
    if (_pendingClip != 0) {
      final Path clip = Path.from(_path);
      clip.fillType = _pendingClip == 2 ? PathFillType.evenOdd : PathFillType.nonZero;
      if (!textOnly) canvas.clipPath(clip);
      _pendingClip = 0;
    }
    _path = Path();
  }

  Future<void> _apply(String op, UPdfDict? resources, int depth) async {
    switch (op) {
      case "q":
        _stack.add(_state.clone());
        canvas.save();
        break;
      case "Q":
        if (_stack.isNotEmpty) {
          _state = _stack.removeLast();
          canvas.restore();
        }
        break;
      case "cm":
        {
          final List<double> values = _numbers();
          if (values.length >= 6) {
            final List<double> matrix = values.sublist(values.length - 6);
            canvas.transform(uPdfMatrix4(matrix));
            _state.ctm = uPdfMul(matrix, _state.ctm);
          }
        }
        break;
      case "w":
        _state.lineWidth = _number(0);
        break;
      case "J":
        _state.cap = _number(0) == 1 ? StrokeCap.round : (_number(0) == 2 ? StrokeCap.square : StrokeCap.butt);
        break;
      case "j":
        _state.join = _number(0) == 1 ? StrokeJoin.round : (_number(0) == 2 ? StrokeJoin.bevel : StrokeJoin.miter);
        break;
      case "M":
        _state.miterLimit = _number(0);
        break;
      case "d":
        {
          final Object? first = _operands.isEmpty ? null : _operands[0];
          final List<double> pattern = <double>[];
          if (first is List<Object?>) {
            for (final Object? value in first) {
              if (value is num) pattern.add(value.toDouble());
            }
          }
          _state.dash = pattern;
          _state.dashPhase = _number(1);
        }
        break;
      case "gs":
        await _applyExtGState(_name(0), resources);
        break;
      case "m":
        _currentX = _number(0);
        _currentY = _number(1);
        _startX = _currentX;
        _startY = _currentY;
        _path.moveTo(_currentX, _currentY);
        break;
      case "l":
        _currentX = _number(0);
        _currentY = _number(1);
        _path.lineTo(_currentX, _currentY);
        break;
      case "c":
        _path.cubicTo(_number(0), _number(1), _number(2), _number(3), _number(4), _number(5));
        _currentX = _number(4);
        _currentY = _number(5);
        break;
      case "v":
        _path.cubicTo(_currentX, _currentY, _number(0), _number(1), _number(2), _number(3));
        _currentX = _number(2);
        _currentY = _number(3);
        break;
      case "y":
        _path.cubicTo(_number(0), _number(1), _number(2), _number(3), _number(2), _number(3));
        _currentX = _number(2);
        _currentY = _number(3);
        break;
      case "h":
        _path.close();
        _currentX = _startX;
        _currentY = _startY;
        break;
      case "re":
        {
          final double x = _number(0);
          final double y = _number(1);
          final double w = _number(2);
          final double h = _number(3);
          _path.addRect(Rect.fromLTWH(x < x + w ? x : x + w, y < y + h ? y : y + h, w.abs(), h.abs()));
          _currentX = x;
          _currentY = y;
          _startX = x;
          _startY = y;
        }
        break;
      case "W":
        _pendingClip = 1;
        break;
      case "W*":
        _pendingClip = 2;
        break;
      case "n":
        _finishPath();
        break;
      case "S":
        _paintPath(fill: false, stroke: true, evenOdd: false, close: false);
        break;
      case "s":
        _paintPath(fill: false, stroke: true, evenOdd: false, close: true);
        break;
      case "f":
      case "F":
        _paintPath(fill: true, stroke: false, evenOdd: false, close: false);
        break;
      case "f*":
        _paintPath(fill: true, stroke: false, evenOdd: true, close: false);
        break;
      case "B":
        _paintPath(fill: true, stroke: true, evenOdd: false, close: false);
        break;
      case "B*":
        _paintPath(fill: true, stroke: true, evenOdd: true, close: false);
        break;
      case "b":
        _paintPath(fill: true, stroke: true, evenOdd: false, close: true);
        break;
      case "b*":
        _paintPath(fill: true, stroke: true, evenOdd: true, close: true);
        break;
      case "g":
        _state.fillSpace = UPdfColorSpace.deviceGray;
        _state.fillColor = UPdfColorSpace.deviceGray.color(_numbers());
        _state.fillShader = null;
        break;
      case "G":
        _state.strokeSpace = UPdfColorSpace.deviceGray;
        _state.strokeColor = UPdfColorSpace.deviceGray.color(_numbers());
        _state.strokeShader = null;
        break;
      case "rg":
        _state.fillSpace = UPdfColorSpace.deviceRgb;
        _state.fillColor = UPdfColorSpace.deviceRgb.color(_numbers());
        _state.fillShader = null;
        break;
      case "RG":
        _state.strokeSpace = UPdfColorSpace.deviceRgb;
        _state.strokeColor = UPdfColorSpace.deviceRgb.color(_numbers());
        _state.strokeShader = null;
        break;
      case "k":
        _state.fillSpace = UPdfColorSpace.deviceCmyk;
        _state.fillColor = UPdfColorSpace.deviceCmyk.color(_numbers());
        _state.fillShader = null;
        break;
      case "K":
        _state.strokeSpace = UPdfColorSpace.deviceCmyk;
        _state.strokeColor = UPdfColorSpace.deviceCmyk.color(_numbers());
        _state.strokeShader = null;
        break;
      case "cs":
        _state.fillSpace = await UPdfColorSpace.load(document, _operands.isEmpty ? null : _operands[0], resources: resources);
        _state.fillColor = _state.fillSpace.color(_state.fillSpace.initial);
        _state.fillShader = null;
        break;
      case "CS":
        _state.strokeSpace = await UPdfColorSpace.load(document, _operands.isEmpty ? null : _operands[0], resources: resources);
        _state.strokeColor = _state.strokeSpace.color(_state.strokeSpace.initial);
        _state.strokeShader = null;
        break;
      case "sc":
      case "scn":
        await _setColor(resources, fill: true);
        break;
      case "SC":
      case "SCN":
        await _setColor(resources, fill: false);
        break;
      case "BT":
        _textMatrix = <double>[1, 0, 0, 1, 0, 0];
        _lineMatrix = <double>[1, 0, 0, 1, 0, 0];
        break;
      case "ET":
        break;
      case "Tc":
        _state.charSpacing = _number(0);
        break;
      case "Tw":
        _state.wordSpacing = _number(0);
        break;
      case "Tz":
        _state.horizontalScale = _number(0) / 100;
        break;
      case "TL":
        _state.leading = _number(0);
        break;
      case "Ts":
        _state.rise = _number(0);
        break;
      case "Tr":
        _state.renderMode = _number(0).toInt();
        break;
      case "Tf":
        _state.fontSize = _number(1);
        _state.font = await _loadFont(_name(0), resources);
        break;
      case "Td":
        _lineMatrix = uPdfMul(<double>[1, 0, 0, 1, _number(0), _number(1)], _lineMatrix);
        _textMatrix = List<double>.from(_lineMatrix);
        break;
      case "TD":
        _state.leading = -_number(1);
        _lineMatrix = uPdfMul(<double>[1, 0, 0, 1, _number(0), _number(1)], _lineMatrix);
        _textMatrix = List<double>.from(_lineMatrix);
        break;
      case "Tm":
        {
          final List<double> values = _numbers();
          if (values.length >= 6) {
            _lineMatrix = values.sublist(values.length - 6);
            _textMatrix = List<double>.from(_lineMatrix);
          }
        }
        break;
      case "T*":
        _lineMatrix = uPdfMul(<double>[1, 0, 0, 1, 0, -_state.leading], _lineMatrix);
        _textMatrix = List<double>.from(_lineMatrix);
        break;
      case "Tj":
        await _showText(_operands.isEmpty ? null : _operands[0], resources, depth);
        break;
      case "'":
        _lineMatrix = uPdfMul(<double>[1, 0, 0, 1, 0, -_state.leading], _lineMatrix);
        _textMatrix = List<double>.from(_lineMatrix);
        await _showText(_operands.isEmpty ? null : _operands[0], resources, depth);
        break;
      case "\"":
        _state.wordSpacing = _number(0);
        _state.charSpacing = _number(1);
        _lineMatrix = uPdfMul(<double>[1, 0, 0, 1, 0, -_state.leading], _lineMatrix);
        _textMatrix = List<double>.from(_lineMatrix);
        await _showText(_operands.length > 2 ? _operands[2] : null, resources, depth);
        break;
      case "TJ":
        {
          final Object? array = _operands.isEmpty ? null : _operands[0];
          if (array is List<Object?>) {
            for (final Object? entry in array) {
              if (entry is num) {
                final double shift = -entry.toDouble() / 1000 * _state.fontSize * _state.horizontalScale;
                _textMatrix = uPdfMul(<double>[1, 0, 0, 1, shift, 0], _textMatrix);
              } else if (entry is UPdfString) {
                await _showString(entry, resources, depth);
              }
            }
          }
        }
        break;
      case "Do":
        await _doXObject(_name(0), resources, depth);
        break;
      case "sh":
        await _shading(_name(0), resources);
        break;
      case "BDC":
        _markedDepth++;
        if (_hiddenDepth > 0) {
          _hiddenDepth++;
        } else if (await _isHiddenMarkedContent(resources)) {
          _hiddenDepth = 1;
        }
        break;
      case "BMC":
        _markedDepth++;
        if (_hiddenDepth > 0) _hiddenDepth++;
        break;
      case "EMC":
        if (_markedDepth > 0) _markedDepth--;
        if (_hiddenDepth > 0) _hiddenDepth--;
        break;
      case "d0":
      case "d1":
      case "ri":
      case "i":
      case "MP":
      case "DP":
      case "BX":
      case "EX":
        break;
      default:
        break;
    }
  }

  Future<bool> _isHiddenMarkedContent(UPdfDict? resources) async {
    if (options.hiddenOptionalGroups.isEmpty) return false;
    if (_operands.isEmpty || _name(0) != "OC") return false;
    final Object? target = _operands.length > 1 ? _operands[1] : null;
    if (target is UPdfRef) return options.hiddenOptionalGroups.contains(target.number);
    if (target is UPdfName) {
      final Object? properties = await document.resolve(resources?["Properties"]);
      if (properties is UPdfDict) {
        final Object? group = properties[target.value];
        if (group is UPdfRef) return options.hiddenOptionalGroups.contains(group.number);
      }
    }
    return false;
  }

  Future<void> _setColor(UPdfDict? resources, {required bool fill}) async {
    final UPdfColorSpace space = fill ? _state.fillSpace : _state.strokeSpace;
    if (space.isPattern) {
      final String patternName = _name(_operands.length - 1);
      final Object? patterns = await document.resolve(resources?["Pattern"]);
      Shader? shader;
      Color color = const Color(0xFF808080);
      if (patterns is UPdfDict) {
        final Object? pattern = await document.resolve(patterns[patternName]);
        final UPdfDict? patternDict = pattern is UPdfStream ? pattern.dict : (pattern is UPdfDict ? pattern : null);
        final int patternType = ((await document.resolve(patternDict?["PatternType"])) as num?)?.toInt() ?? 1;
        if (patternType == 2) {
          final Object? shadingObject = await document.resolve(patternDict?["Shading"]);
          final UPdfDict? shadingDict = shadingObject is UPdfStream ? shadingObject.dict : (shadingObject is UPdfDict ? shadingObject : null);
          if (shadingDict != null) {
            final UPdfShadingPaint? paint = await UPdfShadingPaint.build(document, shadingDict, resources: resources);
            shader = paint?.shader;
            color = paint?.fallback ?? color;
          }
        } else if (pattern is UPdfStream) {
          color = const Color(0xFFB0B0B0);
        }
      }
      if (fill) {
        _state.fillShader = shader;
        _state.fillColor = color;
      } else {
        _state.strokeShader = shader;
        _state.strokeColor = color;
      }
      return;
    }
    final List<double> values = _numbers();
    if (values.isEmpty) return;
    final Color color = space.color(values);
    if (fill) {
      _state.fillColor = color;
      _state.fillShader = null;
    } else {
      _state.strokeColor = color;
      _state.strokeShader = null;
    }
  }

  Future<void> _applyExtGState(String name, UPdfDict? resources) async {
    final Object? states = await document.resolve(resources?["ExtGState"]);
    if (states is! UPdfDict) return;
    final Object? entry = await document.resolve(states[name]);
    if (entry is! UPdfDict) return;
    final Object? lineWidth = await document.resolve(entry["LW"]);
    if (lineWidth is num) _state.lineWidth = lineWidth.toDouble();
    final Object? fillAlpha = await document.resolve(entry["ca"]);
    if (fillAlpha is num) _state.fillAlpha = fillAlpha.toDouble().clamp(0, 1).toDouble();
    final Object? strokeAlpha = await document.resolve(entry["CA"]);
    if (strokeAlpha is num) _state.strokeAlpha = strokeAlpha.toDouble().clamp(0, 1).toDouble();
    final Object? blend = await document.resolve(entry["BM"]);
    final String blendName = blend is UPdfName ? blend.value : (blend is List<Object?> && blend.isNotEmpty && blend.first is UPdfName ? (blend.first! as UPdfName).value : "");
    _state.blend = _blendFor(blendName);
    final Object? fontEntry = await document.resolve(entry["Font"]);
    if (fontEntry is List<Object?> && fontEntry.length >= 2) {
      final Object? fontDict = await document.resolve(fontEntry[0]);
      final Object? size = await document.resolve(fontEntry[1]);
      if (fontDict is UPdfDict) _state.font = await UPdfFont.load(document, fontDict);
      if (size is num) _state.fontSize = size.toDouble();
    }
  }

  BlendMode _blendFor(String name) {
    switch (name) {
      case "Multiply":
        return BlendMode.multiply;
      case "Screen":
        return BlendMode.screen;
      case "Overlay":
        return BlendMode.overlay;
      case "Darken":
        return BlendMode.darken;
      case "Lighten":
        return BlendMode.lighten;
      case "ColorDodge":
        return BlendMode.colorDodge;
      case "ColorBurn":
        return BlendMode.colorBurn;
      case "HardLight":
        return BlendMode.hardLight;
      case "SoftLight":
        return BlendMode.softLight;
      case "Difference":
        return BlendMode.difference;
      case "Exclusion":
        return BlendMode.exclusion;
      case "Hue":
        return BlendMode.hue;
      case "Saturation":
        return BlendMode.saturation;
      case "Color":
        return BlendMode.color;
      case "Luminosity":
        return BlendMode.luminosity;
      default:
        return BlendMode.srcOver;
    }
  }

  Future<UPdfFont?> _loadFont(String name, UPdfDict? resources) async {
    final Object? fonts = await document.resolve(resources?["Font"]);
    if (fonts is! UPdfDict) return _state.font;
    final Object? reference = fonts[name];
    final String key = reference is UPdfRef ? "ref:${reference.number}" : "name:$name:${identityHashCode(fonts)}";
    final UPdfFont? cached = _fonts[key];
    if (cached != null) return cached;
    final Object? dict = await document.resolve(reference);
    if (dict is! UPdfDict) return _state.font;
    final UPdfFont font = await UPdfFont.load(document, dict, cacheKey: "${document.fingerprint}:$key");
    _fonts[key] = font;
    return font;
  }

  Future<void> _showText(Object? value, UPdfDict? resources, int depth) async {
    if (value is UPdfString) await _showString(value, resources, depth);
  }

  Future<void> _showString(UPdfString value, UPdfDict? resources, int depth) async {
    final UPdfFont? font = _state.font;
    if (font == null || _state.fontSize == 0) return;
    final List<UPdfCodePoint> points = font.decode(value.bytes);
    for (final UPdfCodePoint point in points) {
      final double width0 = font.widthFor(point) / 1000;
      final List<double> parameters = <double>[_state.fontSize * _state.horizontalScale, 0, 0, _state.fontSize, 0, _state.rise];
      final List<double> trm = uPdfMul(parameters, _textMatrix);
      final String text = font.unicodeFor(point);
      final bool isSpace = point.byteLength == 1 && point.code == 32;
      if (options.collectText) _recordGlyph(text, trm, width0, font, isSpace);
      if (!_skipDrawing && _state.renderMode != 3 && _state.renderMode != 7) {
        if (font.isType3) {
          await _drawType3(font, point, trm, resources, depth);
        } else {
          final Path? glyph = font.pathFor(point);
          if (glyph != null) {
            _drawGlyph(glyph, trm);
          } else if (text.isNotEmpty && text != " ") {
            _drawFallbackGlyph(text, trm, font);
          }
        }
      }
      final double advance = (width0 * _state.fontSize + _state.charSpacing + (isSpace ? _state.wordSpacing : 0)) * _state.horizontalScale;
      _textMatrix = uPdfMul(<double>[1, 0, 0, 1, advance, 0], _textMatrix);
    }
  }

  void _drawGlyph(Path glyph, List<double> trm) {
    canvas.save();
    canvas.transform(uPdfMatrix4(trm));
    final int mode = _state.renderMode;
    if (mode == 0 || mode == 2 || mode == 4 || mode == 6) canvas.drawPath(glyph, _fillPaint());
    if (mode == 1 || mode == 2 || mode == 5 || mode == 6) {
      final double scale = trm[0].abs() > trm[3].abs() ? trm[0].abs() : trm[3].abs();
      canvas.drawPath(glyph, _strokePaint(overrideWidth: scale <= 0 ? _state.lineWidth : _state.lineWidth / scale));
    }
    canvas.restore();
  }

  void _drawFallbackGlyph(String text, List<double> trm, UPdfFont font) {
    final ui.Paragraph? paragraph = UPdfFallbackText.paragraph(text, font, _state.fillColor.withValues(alpha: _state.fillColor.a * _state.fillAlpha));
    if (paragraph == null) return;
    canvas.save();
    canvas.transform(uPdfMatrix4(trm));
    canvas.transform(uPdfMatrix4(const <double>[1, 0, 0, -1, 0, 0]));
    canvas.drawParagraph(paragraph, Offset(0, -paragraph.alphabeticBaseline));
    canvas.restore();
  }

  Future<void> _drawType3(UPdfFont font, UPdfCodePoint point, List<double> trm, UPdfDict? resources, int depth) async {
    final UPdfStream? proc = font.charProcs[point.code];
    if (proc == null || depth > 8) return;
    final List<double> matrix = uPdfMul(font.fontMatrix, trm);
    final _UPdfState saved = _state.clone();
    final List<double> savedText = List<double>.from(_textMatrix);
    final List<double> savedLine = List<double>.from(_lineMatrix);
    canvas.save();
    canvas.transform(uPdfMatrix4(matrix));
    _state.ctm = uPdfMul(matrix, _state.ctm);
    try {
      await _execute((await document.decodeStream(proc)).bytes, font.type3Resources ?? resources, depth + 1);
    } on Object {
      truncated = true;
    }
    canvas.restore();
    _state = saved;
    _textMatrix = savedText;
    _lineMatrix = savedLine;
  }

  void _recordGlyph(String text, List<double> trm, double width0, UPdfFont font, bool isSpace) {
    final double ascent = (font.ascent == 0 ? 750 : font.ascent) / 1000;
    final double descent = (font.descent == 0 ? -250 : font.descent) / 1000;
    final List<double> device = uPdfMul(trm, _state.ctm);
    final Offset p1 = uPdfApply(device, 0, descent);
    final Offset p2 = uPdfApply(device, width0, descent);
    final Offset p3 = uPdfApply(device, width0, ascent);
    final Offset p4 = uPdfApply(device, 0, ascent);
    final double left = <double>[p1.dx, p2.dx, p3.dx, p4.dx].reduce(min);
    final double right = <double>[p1.dx, p2.dx, p3.dx, p4.dx].reduce(max);
    final double top = <double>[p1.dy, p2.dy, p3.dy, p4.dy].reduce(min);
    final double bottom = <double>[p1.dy, p2.dy, p3.dy, p4.dy].reduce(max);
    final double size = (bottom - top).abs();
    _glyphs.add(_UPdfGlyphRecord(text: text, rect: Rect.fromLTRB(left, top, right, bottom), fontSize: size, fontName: font.baseFont, isSpace: isSpace || text.trim().isEmpty));
    if (_glyphs.length > 400000) _glyphs.removeRange(0, 1000);
  }

  Future<void> _doXObject(String name, UPdfDict? resources, int depth) async {
    if (depth > 12) return;
    final Object? xobjects = await document.resolve(resources?["XObject"]);
    if (xobjects is! UPdfDict) return;
    final Object? reference = xobjects[name];
    final Object? stream = await document.resolve(reference);
    if (stream is! UPdfStream) return;
    if (reference is UPdfRef && options.hiddenOptionalGroups.isNotEmpty) {
      final Object? oc = stream.dict["OC"];
      if (oc is UPdfRef && options.hiddenOptionalGroups.contains(oc.number)) return;
    }
    final Object? subtype = stream.dict["Subtype"];
    final String type = subtype is UPdfName ? subtype.value : "";
    if (type == "Image") {
      if (_skipDrawing) return;
      await _drawImage(stream, resources);
      return;
    }
    if (type != "Form") return;
    await _runForm(stream, resources, depth);
  }

  Future<void> _runForm(UPdfStream stream, UPdfDict? resources, int depth) async {
    final _UPdfState saved = _state.clone();
    final List<double> savedText = List<double>.from(_textMatrix);
    final List<double> savedLine = List<double>.from(_lineMatrix);
    final int savedStack = _stack.length;
    canvas.save();
    final Object? matrixObject = await document.resolve(stream.dict["Matrix"]);
    if (matrixObject is List<Object?> && matrixObject.length >= 6) {
      final List<double> matrix = <double>[];
      for (final Object? value in matrixObject) {
        if (value is num) matrix.add(value.toDouble());
      }
      if (matrix.length >= 6) {
        canvas.transform(uPdfMatrix4(matrix.sublist(0, 6)));
        _state.ctm = uPdfMul(matrix.sublist(0, 6), _state.ctm);
      }
    }
    final Object? bboxObject = await document.resolve(stream.dict["BBox"]);
    if (bboxObject is List<Object?> && bboxObject.length >= 4) {
      final Rect bbox = uPdfRectFromArray(bboxObject, fallback: Rect.zero);
      if (bbox.width > 0 && bbox.height > 0 && !textOnly) canvas.clipRect(bbox);
    }
    final Object? formResources = await document.resolve(stream.dict["Resources"]);
    try {
      await _execute((await document.decodeStream(stream)).bytes, formResources is UPdfDict ? formResources : resources, depth + 1);
    } on Object {
      truncated = true;
    }
    while (_stack.length > savedStack) {
      _stack.removeLast();
      canvas.restore();
    }
    canvas.restore();
    _state = saved;
    _textMatrix = savedText;
    _lineMatrix = savedLine;
  }

  Future<void> _drawImage(UPdfStream stream, UPdfDict? resources) async {
    final ui.Image? image = await UPdfImages.decode(document, stream, resources: resources, fillColor: _state.fillColor);
    if (image == null) return;
    canvas.save();
    canvas.transform(uPdfMatrix4(<double>[1 / image.width, 0, 0, -1 / image.height, 0, 1]));
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true
      ..blendMode = _state.blend
      ..color = const Color(0xFF000000).withValues(alpha: _state.fillAlpha);
    canvas.drawImage(image, Offset.zero, paint);
    canvas.restore();
    image.dispose();
  }

  Future<void> _shading(String name, UPdfDict? resources) async {
    if (_skipDrawing) return;
    final Object? shadings = await document.resolve(resources?["Shading"]);
    if (shadings is! UPdfDict) return;
    final Object? entry = await document.resolve(shadings[name]);
    final UPdfDict? dict = entry is UPdfStream ? entry.dict : (entry is UPdfDict ? entry : null);
    if (dict == null) return;
    final UPdfShadingPaint? shading = await UPdfShadingPaint.build(document, dict, resources: resources);
    if (shading == null) return;
    final Rect bounds = canvas.getLocalClipBounds();
    final Paint paint = Paint()..blendMode = _state.blend;
    if (shading.shader != null) {
      paint.shader = shading.shader;
    } else {
      paint.color = (shading.fallback ?? const Color(0xFF808080)).withValues(alpha: _state.fillAlpha);
    }
    canvas.drawRect(bounds, paint);
  }

  Future<void> _inlineImage(UDocCursor cursor, UPdfDict? resources) async {
    final Map<String, Object?> entries = <String, Object?>{};
    int guard = 0;
    while (!cursor.isEmpty && guard < 256) {
      guard++;
      UPdfSyntax.skipWhitespace(cursor);
      if (cursor.isEmpty) return;
      if (cursor.peek == 0x2F) {
        final String key = UPdfSyntax.readName(cursor);
        final Object? value = UPdfSyntax.parseObject(cursor);
        entries[_expandInlineKey(key)] = _expandInlineValue(value);
        continue;
      }
      final String keyword = UPdfSyntax.readKeyword(cursor);
      if (keyword == "ID") break;
      if (keyword.isEmpty) cursor.skip(1);
      if (keyword == "EI") return;
    }
    if (!cursor.isEmpty) cursor.skip(1);
    final int start = cursor.position;
    int end = -1;
    final Object? declared = entries["Length"] ?? entries["L"];
    if (declared is num && start + declared.toInt() <= cursor.end) {
      end = start + declared.toInt();
      cursor.seek(end);
      UPdfSyntax.skipWhitespace(cursor);
      UPdfSyntax.readKeyword(cursor);
    } else {
      int search = start;
      while (true) {
        final int found = cursor.indexOf(const <int>[0x45, 0x49], from: search);
        if (found < 0) break;
        final int before = found - 1;
        final int after = found + 2;
        final bool boundedLeft = before >= 0 && UPdfSyntax.isWhitespace(cursor.bytes[before]);
        final bool boundedRight = after >= cursor.end || UPdfSyntax.isWhitespace(cursor.bytes[after]) || UPdfSyntax.isDelimiter(cursor.bytes[after]);
        if (boundedLeft && boundedRight) {
          end = before;
          cursor.seek(after > cursor.end ? cursor.end : after);
          break;
        }
        search = found + 2;
      }
      if (end < 0) {
        cursor.seek(cursor.end);
        return;
      }
    }
    if (_skipDrawing || end <= start) return;
    final Uint8List data = Uint8List.sublistView(cursor.bytes, start, end);
    final UPdfStream stream = UPdfStream(dict: UPdfDict(entries), rawOffset: 0, rawLength: data.length, rawBytes: data);
    await _drawImage(stream, resources);
  }

  String _expandInlineKey(String key) {
    switch (key) {
      case "BPC":
        return "BitsPerComponent";
      case "CS":
        return "ColorSpace";
      case "D":
        return "Decode";
      case "DP":
        return "DecodeParms";
      case "F":
        return "Filter";
      case "H":
        return "Height";
      case "W":
        return "Width";
      case "IM":
        return "ImageMask";
      case "I":
        return "Interpolate";
      case "L":
        return "Length";
      default:
        return key;
    }
  }

  Object? _expandInlineValue(Object? value) {
    if (value is UPdfName) {
      switch (value.value) {
        case "G":
          return const UPdfName("DeviceGray");
        case "RGB":
          return const UPdfName("DeviceRGB");
        case "CMYK":
          return const UPdfName("DeviceCMYK");
        case "I":
          return const UPdfName("Indexed");
        default:
          return value;
      }
    }
    if (value is List<Object?>) return value.map(_expandInlineValue).toList();
    return value;
  }

  Future<void> drawAnnotationAppearance(UPdfStream appearance, Rect rect, List<double> base) async {
    final Object? bboxObject = await document.resolve(appearance.dict["BBox"]);
    Rect bbox = uPdfRectFromArray(bboxObject is List<Object?> ? bboxObject : null, fallback: Rect.zero);
    List<double> matrix = <double>[1, 0, 0, 1, 0, 0];
    final Object? matrixObject = await document.resolve(appearance.dict["Matrix"]);
    if (matrixObject is List<Object?> && matrixObject.length >= 6) {
      final List<double> values = <double>[];
      for (final Object? value in matrixObject) {
        if (value is num) values.add(value.toDouble());
      }
      if (values.length >= 6) matrix = values.sublist(0, 6);
    }
    if (bbox.width <= 0 || bbox.height <= 0) bbox = rect;
    final Offset c1 = uPdfApply(matrix, bbox.left, bbox.top);
    final Offset c2 = uPdfApply(matrix, bbox.right, bbox.top);
    final Offset c3 = uPdfApply(matrix, bbox.right, bbox.bottom);
    final Offset c4 = uPdfApply(matrix, bbox.left, bbox.bottom);
    final double left = <double>[c1.dx, c2.dx, c3.dx, c4.dx].reduce(min);
    final double right = <double>[c1.dx, c2.dx, c3.dx, c4.dx].reduce(max);
    final double top = <double>[c1.dy, c2.dy, c3.dy, c4.dy].reduce(min);
    final double bottom = <double>[c1.dy, c2.dy, c3.dy, c4.dy].reduce(max);
    final double scaleX = (right - left).abs() < 0.0001 ? 1 : rect.width / (right - left);
    final double scaleY = (bottom - top).abs() < 0.0001 ? 1 : rect.height / (bottom - top);
    final List<double> placement = <double>[scaleX, 0, 0, scaleY, rect.left - left * scaleX, rect.top - top * scaleY];
    _state = _UPdfState.initial(List<double>.from(base));
    _textMatrix = <double>[1, 0, 0, 1, 0, 0];
    _lineMatrix = <double>[1, 0, 0, 1, 0, 0];
    canvas.save();
    canvas.transform(uPdfMatrix4(base));
    canvas.transform(uPdfMatrix4(placement));
    _state.ctm = uPdfMul(placement, base);
    canvas.clipRect(Rect.fromLTRB(left, top, right, bottom));
    canvas.transform(uPdfMatrix4(matrix));
    _state.ctm = uPdfMul(matrix, _state.ctm);
    final Object? formResources = await document.resolve(appearance.dict["Resources"]);
    try {
      await _execute((await document.decodeStream(appearance)).bytes, formResources is UPdfDict ? formResources : null, 1);
    } on Object {
      truncated = true;
    }
    canvas.restore();
  }

  UDocTextPage buildTextPage(int pageIndex, Size size) {
    if (_glyphs.isEmpty) return UDocTextPage(pageIndex: pageIndex, runs: const <UDocTextRun>[], text: "", size: size);
    final List<_UPdfGlyphRecord> sorted = List<_UPdfGlyphRecord>.from(_glyphs)
      ..sort((_UPdfGlyphRecord a, _UPdfGlyphRecord b) {
        final double dy = a.rect.center.dy - b.rect.center.dy;
        if (dy.abs() > (a.rect.height + b.rect.height) / 4) return dy < 0 ? -1 : 1;
        return a.rect.left.compareTo(b.rect.left);
      });
    final List<List<_UPdfGlyphRecord>> lines = <List<_UPdfGlyphRecord>>[];
    List<_UPdfGlyphRecord> current = <_UPdfGlyphRecord>[];
    for (final _UPdfGlyphRecord glyph in sorted) {
      if (current.isEmpty) {
        current.add(glyph);
        continue;
      }
      final _UPdfGlyphRecord previous = current.last;
      final double tolerance = (previous.rect.height + glyph.rect.height) / 4;
      if ((glyph.rect.center.dy - previous.rect.center.dy).abs() > tolerance) {
        lines.add(current);
        current = <_UPdfGlyphRecord>[glyph];
        continue;
      }
      current.add(glyph);
    }
    if (current.isNotEmpty) lines.add(current);
    final List<UDocTextRun> runs = <UDocTextRun>[];
    final StringBuffer pageText = StringBuffer();
    int lineIndex = 0;
    for (final List<_UPdfGlyphRecord> line in lines) {
      final List<UDocGlyph> glyphs = <UDocGlyph>[];
      final StringBuffer buffer = StringBuffer();
      Rect? bounds;
      double maxSize = 0;
      String fontName = "";
      double previousRight = double.negativeInfinity;
      for (final _UPdfGlyphRecord glyph in line) {
        if (glyph.text.isEmpty && !glyph.isSpace) continue;
        final bool gap = previousRight.isFinite && glyph.rect.left - previousRight > glyph.rect.height * 0.28;
        if (gap && buffer.isNotEmpty && !buffer.toString().endsWith(" ")) {
          buffer.write(" ");
          glyphs.add(UDocGlyph(text: " ", rect: Rect.fromLTRB(previousRight, glyph.rect.top, glyph.rect.left, glyph.rect.bottom), rtl: false));
        }
        final String text = glyph.isSpace && glyph.text.isEmpty ? " " : glyph.text;
        if (text.isEmpty) continue;
        buffer.write(text);
        glyphs.add(UDocGlyph(text: text, rect: glyph.rect, rtl: UDocText.isRtl(text), fontSize: glyph.fontSize));
        bounds = bounds == null ? glyph.rect : bounds.expandToInclude(glyph.rect);
        if (glyph.fontSize > maxSize) maxSize = glyph.fontSize;
        if (fontName.isEmpty) fontName = glyph.fontName;
        previousRight = glyph.rect.right;
      }
      final String raw = buffer.toString();
      if (raw.trim().isEmpty || bounds == null) continue;
      final bool rtl = UDocText.isRtl(raw);
      final String logical = rtl ? _reverseVisual(raw) : raw;
      runs.add(UDocTextRun(text: logical, rect: bounds, rtl: rtl, glyphs: rtl ? glyphs.reversed.toList() : glyphs, fontName: fontName, fontSize: maxSize, lineIndex: lineIndex));
      pageText.writeln(logical);
      lineIndex++;
    }
    return UDocTextPage(pageIndex: pageIndex, runs: runs, text: pageText.toString().trimRight(), size: size);
  }

  String _reverseVisual(String text) {
    final String unfolded = UDocText.unfoldPresentationForms(text);
    final List<int> runes = unfolded.runes.toList();
    final List<int> out = <int>[];
    int index = runes.length - 1;
    while (index >= 0) {
      final int code = runes[index];
      if (!UDocText.isRtlCode(code) && !UDocText.isNeutralCode(code) && code > 0x20) {
        int start = index;
        while (start >= 0 && !UDocText.isRtlCode(runes[start]) && runes[start] > 0x20) {
          start--;
        }
        out.addAll(runes.sublist(start + 1, index + 1));
        index = start;
        continue;
      }
      out.add(_mirror(code));
      index--;
    }
    return String.fromCharCodes(out);
  }

  int _mirror(int code) {
    switch (code) {
      case 0x28:
        return 0x29;
      case 0x29:
        return 0x28;
      case 0x5B:
        return 0x5D;
      case 0x5D:
        return 0x5B;
      case 0x7B:
        return 0x7D;
      case 0x7D:
        return 0x7B;
      case 0x3C:
        return 0x3E;
      case 0x3E:
        return 0x3C;
      default:
        return code;
    }
  }
}

class UPdfController extends UDocController {
  UPdfController();

  UPdfDocument? _document;
  UPdfPageRenderer? _renderer;
  UDocTextIndex? _index;

  final Map<int, UPdfPage> _pages = <int, UPdfPage>{};
  final Map<int, UDocPageInfo> _infos = <int, UDocPageInfo>{};
  final Map<int, UDocTextPage> _texts = <int, UDocTextPage>{};
  final Map<int, Future<ui.Picture?>> _pending = <int, Future<ui.Picture?>>{};
  final ULruCache<int, ui.Image> _thumbnails = ULruCache<int, ui.Image>(maxBytes: uDocThumbnailCacheBytes, sizeOf: _thumbnailSize, onEvict: _disposeThumbnail);

  List<UDocOutlineNode> outline = <UDocOutlineNode>[];
  Set<int> hiddenOptionalGroups = <int>{};
  UDocPageInfo _fallbackInfo = const UDocPageInfo(index: 0, size: Size(612, 792));

  bool _searching = false;
  int _searchToken = 0;

  static int _thumbnailSize(ui.Image image) => image.width * image.height * 4;

  static void _disposeThumbnail(int key, ui.Image image) => image.dispose();

  UPdfDocument? get document => _document;

  @override
  String get documentId => _document?.fingerprint ?? "pdf";

  @override
  UDocKind get kind => UDocKind.pdf;

  Future<void> open({String? path, String? url, Uint8List? bytes, String? asset, Object? blob, Map<String, String>? headers, String password = ""}) async {
    emit(value.copyWith(state: UDocState.opening, isBusy: true, clearError: true));
    try {
      final UPdfDocument document = await UPdfDocument.open(path: path, url: url, bytes: bytes, asset: asset, blob: blob, headers: headers, password: password);
      _document = document;
      _renderer = UPdfPageRenderer(document);
      _index = await UDocTextIndex.open(document.fingerprint);
      await _loadHiddenGroups(document);
      final UDocMetadata metadata = await document.metadata();
      final UPdfPage? first = await document.page(0);
      if (first != null) {
        _pages[0] = first;
        _fallbackInfo = _infoFor(first);
        _infos[0] = _fallbackInfo;
      }
      unawaited(_prefetchInfos());
      unawaited(_loadOutline());
      emit(
        value.copyWith(
          state: UDocState.ready,
          kind: UDocKind.pdf,
          pageCount: document.pageCount,
          metadata: metadata,
          permissions: document.permissions,
          isBusy: false,
          loadedPercent: 1,
          clearError: true,
        ),
      );
      await UDocProgressStore.instance.load();
      final UDocProgress? progress = UDocProgressStore.instance.get(document.fingerprint);
      if (progress != null && progress.pageIndex > 0 && progress.pageIndex < document.pageCount) emit(value.copyWith(pageIndex: progress.pageIndex));
    } on UDocError catch (error) {
      failWith(error);
    } on Object catch (error) {
      failWith(UDocError(code: UDocErrorCode.corrupt, message: "Could not open the document", detail: "$error"));
    }
  }

  Future<void> _loadHiddenGroups(UPdfDocument document) async {
    try {
      final Object? properties = await document.resolve(document.catalog?["OCProperties"]);
      if (properties is! UPdfDict) return;
      final Object? defaults = await document.resolve(properties["D"]);
      if (defaults is! UPdfDict) return;
      final Object? off = await document.resolve(defaults["OFF"]);
      if (off is! List<Object?>) return;
      final Set<int> hidden = <int>{};
      for (final Object? entry in off) {
        if (entry is UPdfRef) hidden.add(entry.number);
      }
      hiddenOptionalGroups = hidden;
    } on Object {
      return;
    }
  }

  Future<void> _prefetchInfos() async {
    final UPdfDocument? document = _document;
    if (document == null) return;
    final int limit = document.pageCount < 64 ? document.pageCount : 64;
    for (int i = 0; i < limit; i++) {
      if (isDisposed) return;
      await pdfPage(i);
    }
    if (!isDisposed) notifyListeners();
  }

  Future<void> _loadOutline() async {
    final UPdfDocument? document = _document;
    if (document == null) return;
    try {
      final List<UDocOutlineNode> nodes = await document.outline();
      if (isDisposed) return;
      outline = nodes;
      notifyListeners();
    } on Object {
      return;
    }
  }

  UDocPageInfo _infoFor(UPdfPage page) => UDocPageInfo(
    index: page.index,
    size: Size(page.box.width, page.box.height),
    rotation: page.rotation,
    cropBox: page.cropBox,
    mediaBox: page.mediaBox,
  );

  Future<UPdfPage?> pdfPage(int index) async {
    final UPdfPage? cached = _pages[index];
    if (cached != null) return cached;
    final UPdfDocument? document = _document;
    if (document == null) return null;
    final UPdfPage? page = await document.page(index);
    if (page == null) return null;
    if (_pages.length > 512) _pages.clear();
    _pages[index] = page;
    _infos[index] = _infoFor(page);
    return page;
  }

  @override
  UDocPageInfo pageInfo(int pageIndex) => _infos[pageIndex] ?? UDocPageInfo(index: pageIndex, size: _fallbackInfo.size, rotation: _fallbackInfo.rotation);

  bool hasPageInfo(int pageIndex) => _infos.containsKey(pageIndex);

  Future<UDocPageInfo> ensurePageInfo(int pageIndex) async {
    final UPdfPage? page = await pdfPage(pageIndex);
    return page == null ? pageInfo(pageIndex) : _infoFor(page);
  }

  @override
  Future<ui.Picture?> renderPage(int pageIndex, {double scale = 1, Rect? clip}) {
    final String key = UDocPictureCache.key(documentId, pageIndex, 1);
    final ui.Picture? cached = UDocPictureCache.instance.get(key);
    if (cached != null) return Future<ui.Picture?>.value(cached);
    final Future<ui.Picture?>? pending = _pending[pageIndex];
    if (pending != null) return pending;
    final Future<ui.Picture?> request = _renderInternal(pageIndex, key);
    _pending[pageIndex] = request;
    return request;
  }

  Future<ui.Picture?> _renderInternal(int pageIndex, String key) async {
    try {
      final UPdfPageRenderer? renderer = _renderer;
      final UPdfPage? page = await pdfPage(pageIndex);
      if (renderer == null || page == null) return null;
      final UPdfRenderResult result = await renderer.render(
        page,
        options: UPdfRenderOptions(
          drawAnnotations: settings.showAnnotations,
          hiddenOptionalGroups: hiddenOptionalGroups,
        ),
      );
      final ui.Picture? picture = result.picture;
      if (picture != null) UDocPictureCache.instance.put(key, picture);
      if (result.text.runs.isNotEmpty || !_texts.containsKey(pageIndex)) {
        _texts[pageIndex] = result.text;
        if (_texts.length > 96) {
          final List<int> keys = _texts.keys.toList();
          for (int i = 0; i < keys.length - 96; i++) {
            _texts.remove(keys[i]);
          }
        }
        unawaited(_index?.writePage(pageIndex, result.text.text) ?? Future<void>.value());
      }
      return picture;
    } on Object {
      return null;
    } finally {
      final Future<ui.Picture?>? removed = _pending.remove(pageIndex);
      if (removed != null) unawaited(removed);
    }
  }

  @override
  Future<UDocTextPage> textPage(int pageIndex) async {
    final UDocTextPage? cached = _texts[pageIndex];
    if (cached != null) return cached;
    final UPdfPageRenderer? renderer = _renderer;
    final UPdfPage? page = await pdfPage(pageIndex);
    if (renderer == null || page == null) return UDocTextPage.empty;
    try {
      final UDocTextPage text = await renderer.extractText(page);
      _texts[pageIndex] = text;
      unawaited(_index?.writePage(pageIndex, text.text) ?? Future<void>.value());
      return text;
    } on Object {
      return UDocTextPage.empty;
    }
  }

  @override
  Future<ui.Image?> renderThumbnail(int pageIndex, {int maxSize = 240}) async {
    final ui.Image? cached = _thumbnails.get(pageIndex);
    if (cached != null) return cached;
    try {
      final ui.Picture? picture = await renderPage(pageIndex);
      final UDocPageInfo info = pageInfo(pageIndex);
      if (picture == null) return null;
      final Size rotated = info.rotatedSize;
      final double scale = rotated.width > rotated.height ? maxSize / rotated.width : maxSize / rotated.height;
      final int width = (rotated.width * scale).round().clamp(1, 2048);
      final int height = (rotated.height * scale).round().clamp(1, 2048);
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.scale(scale);
      canvas.drawPicture(picture);
      final ui.Picture scaled = recorder.endRecording();
      final ui.Image image = await scaled.toImage(width, height);
      scaled.dispose();
      _thumbnails.put(pageIndex, image);
      return image;
    } on Object {
      return null;
    }
  }

  Future<void> reopenWith(Uint8List bytes) async {
    final UPdfDocument? previous = _document;
    UDocPictureCache.instance.evictDocument(documentId);
    _thumbnails.clear();
    _texts.clear();
    _pages.clear();
    _infos.clear();
    _pending.clear();
    if (previous != null) UPdfDocumentPages.resetCaches(previous.fingerprint);
    await previous?.close();
    _document = null;
    await open(bytes: bytes);
  }

  Future<List<UDocLink>> links(int pageIndex) async {
    final UPdfDocument? document = _document;
    if (document == null) return const <UDocLink>[];
    try {
      return await document.links(pageIndex);
    } on Object {
      return const <UDocLink>[];
    }
  }

  Future<String?> pageLabel(int pageIndex) async {
    final UPdfDocument? document = _document;
    if (document == null) return null;
    try {
      return await document.pageLabel(pageIndex);
    } on Object {
      return null;
    }
  }

  Future<List<UDocSearchHit>> search(String query, {UDocSearchOptions options = const UDocSearchOptions()}) async {
    final UPdfDocument? document = _document;
    final String trimmed = query.trim();
    if (document == null || trimmed.isEmpty) {
      clearSearch();
      return const <UDocSearchHit>[];
    }
    final int token = ++_searchToken;
    _searching = true;
    liveHits.value = const <UDocSearchHit>[];
    emit(value.copyWith(searchQuery: trimmed, isSearching: true, searchHits: const <UDocSearchHit>[], searchHitIndex: -1));
    final String needle = options.normalizePersian ? UDocText.forSearch(trimmed) : (options.caseSensitive ? trimmed : trimmed.toLowerCase());
    final List<UDocSearchHit> hits = <UDocSearchHit>[];
    final int start = options.startPage.clamp(0, document.pageCount);
    final int end = options.endPage < 0 ? document.pageCount : options.endPage.clamp(0, document.pageCount);
    RegExp? pattern;
    if (options.regex) {
      try {
        pattern = RegExp(trimmed, caseSensitive: options.caseSensitive, multiLine: true);
      } on FormatException {
        pattern = null;
      }
    }
    for (int page = start; page < end; page++) {
      if (token != _searchToken || isDisposed) return hits;
      final UDocTextPage text = await textPage(page);
      if (text.text.isEmpty) continue;
      final UDocNormalizedText normalized = options.normalizePersian
          ? UDocNormalizedText.build(text.text)
          : UDocNormalizedText(options.caseSensitive ? text.text : text.text.toLowerCase(), List<int>.generate(text.text.length, (int i) => i));
      final List<List<int>> matches = <List<int>>[];
      if (pattern != null) {
        for (final RegExpMatch match in pattern.allMatches(text.text)) {
          matches.add(<int>[match.start, match.end]);
        }
      } else {
        for (final int index in UDocText.findAll(normalized.text, needle, wholeWord: options.wholeWord)) {
          matches.add(<int>[normalized.sourceAt(index), normalized.sourceAt(index + needle.length - 1) + 1]);
        }
      }
      for (final List<int> match in matches) {
        final int rawStart = match[0];
        final int rawEnd = match[1] > rawStart ? match[1] : rawStart + 1;
        final int snippetStart = rawStart - 40 < 0 ? 0 : rawStart - 40;
        final int snippetEnd = rawEnd + 40 > text.text.length ? text.text.length : rawEnd + 40;
        hits.add(
          UDocSearchHit(
            pageIndex: page,
            start: rawStart,
            end: rawEnd,
            snippet: text.text.substring(snippetStart, snippetEnd).replaceAll("\n", " "),
            rects: text.rectsForRange(rawStart, rawEnd),
            matchIndex: hits.length,
          ),
        );
        if (hits.length >= options.maxHits) break;
      }
      liveHits.value = List<UDocSearchHit>.from(hits);
      if (hits.length >= options.maxHits) break;
    }
    if (token != _searchToken || isDisposed) return hits;
    _searching = false;
    emit(value.copyWith(searchHits: hits, isSearching: false, searchHitIndex: hits.isEmpty ? -1 : 0, pageIndex: hits.isEmpty ? value.pageIndex : hits.first.pageIndex));
    return hits;
  }

  bool get isSearching => _searching;

  void saveProgress() {
    final UPdfDocument? document = _document;
    if (document == null) return;
    UDocProgressStore.instance.put(
      UDocProgress(
        fingerprint: document.fingerprint,
        updatedAt: DateTime.now(),
        pageIndex: value.pageIndex,
        zoom: settings.zoom,
        percent: value.progress,
        scrollMode: settings.scrollMode,
        colorMode: settings.colorMode,
      ),
    );
  }

  void invalidatePage(int pageIndex) {
    UDocPictureCache.instance.evictPage(documentId, pageIndex);
    _thumbnails.remove(pageIndex);
    _texts.remove(pageIndex);
    _pages.remove(pageIndex);
    _pending.remove(pageIndex);
    notifyListeners();
  }

  void invalidateAll() {
    UDocPictureCache.instance.evictDocument(documentId);
    _thumbnails.clear();
    _texts.clear();
    _pages.clear();
    _pending.clear();
    final UPdfDocument? document = _document;
    if (document != null) {
      UPdfDocumentPages.resetCaches(document.fingerprint);
      emit(value.copyWith(pageCount: document.pageCount));
    }
    unawaited(_refreshInfos());
    notifyListeners();
  }

  Future<void> _refreshInfos() async {
    final UPdfDocument? document = _document;
    if (document == null) return;
    _infos.clear();
    final int limit = document.pageCount < 32 ? document.pageCount : 32;
    for (int i = 0; i < limit; i++) {
      if (isDisposed) return;
      await pdfPage(i);
    }
    if (!isDisposed) notifyListeners();
  }

  @override
  Future<void> close() async {
    saveProgress();
    UDocPictureCache.instance.evictDocument(documentId);
    _thumbnails.clear();
    _texts.clear();
    _pages.clear();
    await _index?.close();
    await _document?.close();
    _document = null;
    _renderer = null;
    emit(value.copyWith(state: UDocState.closed));
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

abstract class UPdfFallbackText {
  static final ULruCache<String, ui.Paragraph> _cache = ULruCache<String, ui.Paragraph>(maxBytes: 2 * 1024 * 1024, sizeOf: _size);

  static int _size(ui.Paragraph paragraph) => 512;

  static String _family(String baseFont) {
    final String lower = baseFont.toLowerCase();
    if (lower.contains("courier") || lower.contains("mono")) return "monospace";
    if (lower.contains("times") || lower.contains("serif") || lower.contains("georgia") || lower.contains("roman")) return "serif";
    return "sans-serif";
  }

  static ui.Paragraph? paragraph(String text, UPdfFont font, Color color) {
    final String lower = font.baseFont.toLowerCase();
    final bool bold = lower.contains("bold") || lower.contains("black") || lower.contains("heavy");
    final bool italic = lower.contains("italic") || lower.contains("oblique") || font.italicAngle.abs() > 4;
    final String key = "${_family(font.baseFont)}|$bold|$italic|${color.toARGB32()}|$text";
    final ui.Paragraph? cached = _cache.get(key);
    if (cached != null) return cached;
    try {
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontFamily: _family(font.baseFont),
          fontSize: 1,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        ),
      );
      builder.pushStyle(ui.TextStyle(color: color, fontSize: 1));
      builder.addText(text);
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 1000));
      _cache.put(key, paragraph);
      return paragraph;
    } on Object {
      return null;
    }
  }

  static void clear() => _cache.clear();
}
