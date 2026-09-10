import "dart:ui" as ui;

import "package:u/utilities.dart";

abstract class UPdfSerializer {
  static const List<int> _stream = <int>[0x73, 0x74, 0x72, 0x65, 0x61, 0x6D];
  static const List<int> _endstream = <int>[0x65, 0x6E, 0x64, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D];

  static String number(num value) {
    if (value is int) return "$value";
    final double asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble() && asDouble.abs() < 1000000000) return "${asDouble.round()}";
    String text = asDouble.toStringAsFixed(6);
    while (text.contains(".") && (text.endsWith("0") || text.endsWith("."))) {
      text = text.substring(0, text.length - 1);
    }
    return text.isEmpty ? "0" : text;
  }

  static String name(String value) {
    final StringBuffer buffer = StringBuffer("/");
    for (final int code in value.codeUnits) {
      final bool regular = code > 0x20 && code < 0x7F && code != 0x23 && !UPdfSyntax.isDelimiter(code);
      if (regular) {
        buffer.writeCharCode(code);
      } else {
        buffer.write("#${code.toRadixString(16).padLeft(2, "0")}");
      }
    }
    return buffer.toString();
  }

  static List<int> literalString(Uint8List bytes) {
    final List<int> out = <int>[0x28];
    for (final int byte in bytes) {
      if (byte == 0x28 || byte == 0x29 || byte == 0x5C) {
        out.add(0x5C);
        out.add(byte);
        continue;
      }
      if (byte == 0x0A || byte == 0x0D || byte == 0x09 || byte == 0x08 || byte == 0x0C || byte < 0x20 || byte > 0x7E) {
        out.add(0x5C);
        out.addAll("${(byte >> 6) & 7}${(byte >> 3) & 7}${byte & 7}".codeUnits);
        continue;
      }
      out.add(byte);
    }
    out.add(0x29);
    return out;
  }

  static List<int> hexString(Uint8List bytes) {
    final StringBuffer buffer = StringBuffer("<");
    for (final int byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, "0"));
    }
    buffer.write(">");
    return buffer.toString().codeUnits;
  }

  static void write(BytesBuilder out, Object? value, {UPdfEncryption? encryption, int objectNumber = 0, int generation = 0, int depth = 0}) {
    if (depth > 48) {
      out.add("null".codeUnits);
      return;
    }
    if (value == null) {
      out.add("null".codeUnits);
      return;
    }
    if (value is bool) {
      out.add((value ? "true" : "false").codeUnits);
      return;
    }
    if (value is num) {
      out.add(number(value).codeUnits);
      return;
    }
    if (value is UPdfName) {
      out.add(name(value.value).codeUnits);
      return;
    }
    if (value is UPdfRef) {
      out.add("${value.number} ${value.generation} R".codeUnits);
      return;
    }
    if (value is UPdfString) {
      final Uint8List bytes = encryption == null ? value.bytes : encryption.encrypt(value.bytes, objectNumber, generation, isString: true);
      out.add(value.hex || encryption != null ? hexString(bytes) : literalString(bytes));
      return;
    }
    if (value is List<Object?>) {
      out.add("[".codeUnits);
      for (final Object? entry in value) {
        out.add(" ".codeUnits);
        write(out, entry, encryption: encryption, objectNumber: objectNumber, generation: generation, depth: depth + 1);
      }
      out.add(" ]".codeUnits);
      return;
    }
    if (value is UPdfStream) {
      final Uint8List data = value.rawBytes ?? Uint8List(0);
      final Uint8List payload = encryption == null ? data : encryption.encrypt(data, objectNumber, generation, isString: false);
      final UPdfDict dict = value.dict.copy();
      dict["Length"] = payload.length;
      write(out, dict, encryption: encryption, objectNumber: objectNumber, generation: generation, depth: depth + 1);
      out.add("\n".codeUnits);
      out.add(_stream);
      out.add("\n".codeUnits);
      out.add(payload);
      out.add("\n".codeUnits);
      out.add(_endstream);
      return;
    }
    if (value is UPdfDict) {
      out.add("<<".codeUnits);
      value.entries.forEach((String key, Object? entry) {
        out.add(" ".codeUnits);
        out.add(name(key).codeUnits);
        out.add(" ".codeUnits);
        write(out, entry, encryption: encryption, objectNumber: objectNumber, generation: generation, depth: depth + 1);
      });
      out.add(" >>".codeUnits);
      return;
    }
    out.add("null".codeUnits);
  }
}

enum UPdfAnnotationStyle { highlight, underline, strikeOut, squiggly, ink, note, freeText, square, circle, line, arrow, stamp, redact }

class UPdfAnnotationSpec {
  const UPdfAnnotationSpec({
    required this.style,
    required this.rect,
    this.quads = const <Rect>[],
    this.inkPaths = const <List<Offset>>[],
    this.color = const Color(0xFFFFEB3B),
    this.borderColor,
    this.opacity = 1,
    this.borderWidth = 2,
    this.contents = "",
    this.author = "",
    this.title = "",
    this.fontSize = 12,
    this.textColor = const Color(0xFF000000),
    this.imageBytes,
    this.rtl = false,
  });

  final UPdfAnnotationStyle style;
  final Rect rect;
  final List<Rect> quads;
  final List<List<Offset>> inkPaths;
  final Color color;
  final Color? borderColor;
  final double opacity;
  final double borderWidth;
  final String contents;
  final String author;
  final String title;
  final double fontSize;
  final Color textColor;
  final Uint8List? imageBytes;
  final bool rtl;
}

class UPdfAnnotationInfo {
  const UPdfAnnotationInfo({required this.objectNumber, required this.pageIndex, required this.subtype, required this.rect, this.contents = "", this.author = "", this.modified, this.color});

  final int objectNumber;
  final int pageIndex;
  final String subtype;
  final Rect rect;
  final String contents;
  final String author;
  final DateTime? modified;
  final Color? color;
}

class UPdfFormField {
  const UPdfFormField({
    required this.objectNumber,
    required this.name,
    required this.kind,
    required this.pageIndex,
    required this.rect,
    this.value,
    this.options = const <String>[],
    this.readOnly = false,
    this.required = false,
    this.maxLength = 0,
  });

  final int objectNumber;
  final String name;
  final UDocFieldKind kind;
  final int pageIndex;
  final Rect rect;
  final Object? value;
  final List<String> options;
  final bool readOnly;
  final bool required;
  final int maxLength;

  String get displayValue => value == null ? "" : "$value";
}

class UPdfEdit {
  UPdfEdit(this.document) : _nextObject = _initialNext(document);

  static int _initialNext(UPdfDocument document) {
    int highest = 0;
    for (final int number in document.xref.entries.keys) {
      if (number > highest) highest = number;
    }
    final Object? size = document.xref.trailer?["Size"];
    if (size is num && size.toInt() > highest) highest = size.toInt() - 1;
    return highest + 1;
  }

  final UPdfDocument document;
  final Map<int, Object?> _changed = <int, Object?>{};
  int _nextObject;

  bool get hasChanges => _changed.isNotEmpty;

  int get pendingCount => _changed.length;

  Map<int, Object?> get pending => Map<int, Object?>.unmodifiable(_changed);

  void discard() {
    _changed.clear();
    document.clearStaged();
  }

  int allocate() => _nextObject++;

  void put(int number, Object? value) {
    _changed[number] = value;
    document.stage(number, value);
  }

  Object? peek(int number) => _changed[number];

  Future<Object?> current(UPdfRef ref) async => _changed.containsKey(ref.number) ? _changed[ref.number] : await document.resolve(ref);

  Future<UPdfDict?> mutablePage(int index) async {
    final UPdfPage? page = await document.page(index);
    final UPdfRef? ref = page?.ref;
    if (page == null || ref == null) return null;
    final Object? staged = _changed[ref.number];
    if (staged is UPdfDict) return staged;
    final UPdfDict copy = page.dict.copy();
    put(ref.number, copy);
    return copy;
  }

  Future<UPdfRef?> pageRef(int index) async => (await document.page(index))?.ref;

  UPdfStream buildStream(Uint8List data, {Map<String, Object?> extra = const <String, Object?>{}, bool compress = true}) {
    final Uint8List deflated = compress && !kIsWeb ? UPdfCodecs.deflate(data) : data;
    final bool useDeflate = compress && !kIsWeb && deflated.length < data.length;
    final Uint8List payload = useDeflate ? deflated : data;
    final Map<String, Object?> entries = <String, Object?>{...extra};
    if (useDeflate) entries["Filter"] = const UPdfName("FlateDecode");
    entries["Length"] = payload.length;
    return UPdfStream(dict: UPdfDict(entries), rawOffset: 0, rawLength: payload.length, rawBytes: payload);
  }

  Future<int> putImageObject(Uint8List rgba, int width, int height) async {
    final int pixels = width * height;
    final Uint8List colour = Uint8List(pixels * 3);
    final Uint8List alpha = Uint8List(pixels);
    bool transparent = false;
    for (int i = 0; i < pixels; i++) {
      colour[i * 3] = rgba[i * 4];
      colour[i * 3 + 1] = rgba[i * 4 + 1];
      colour[i * 3 + 2] = rgba[i * 4 + 2];
      alpha[i] = rgba[i * 4 + 3];
      if (alpha[i] != 255) transparent = true;
    }
    int? maskNumber;
    if (transparent) {
      maskNumber = allocate();
      put(
        maskNumber,
        buildStream(
          alpha,
          extra: <String, Object?>{
            "Type": const UPdfName("XObject"),
            "Subtype": const UPdfName("Image"),
            "Width": width,
            "Height": height,
            "ColorSpace": const UPdfName("DeviceGray"),
            "BitsPerComponent": 8,
          },
        ),
      );
    }
    final int number = allocate();
    put(
      number,
      buildStream(
        colour,
        extra: <String, Object?>{
          "Type": const UPdfName("XObject"),
          "Subtype": const UPdfName("Image"),
          "Width": width,
          "Height": height,
          "ColorSpace": const UPdfName("DeviceRGB"),
          "BitsPerComponent": 8,
          if (maskNumber != null) "SMask": UPdfRef(maskNumber, 0),
        },
      ),
    );
    return number;
  }

  static Future<UPdfRaster?> rasterizeImage(Uint8List encoded, {int maxSize = 2048}) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(encoded);
      final ui.FrameInfo frame = await codec.getNextFrame();
      ui.Image image = frame.image;
      if (image.width > maxSize || image.height > maxSize) {
        final double scale = maxSize / (image.width > image.height ? image.width : image.height);
        final int width = (image.width * scale).round().clamp(1, maxSize);
        final int height = (image.height * scale).round().clamp(1, maxSize);
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          Paint()..filterQuality = FilterQuality.medium,
        );
        final ui.Picture picture = recorder.endRecording();
        final ui.Image resized = await picture.toImage(width, height);
        picture.dispose();
        image.dispose();
        image = resized;
      }
      final ByteData? data = await image.toByteData();
      final int width = image.width;
      final int height = image.height;
      image.dispose();
      if (data == null) return null;
      return UPdfRaster(data.buffer.asUint8List(), width, height);
    } on Object {
      return null;
    }
  }

  static Future<UPdfRaster?> rasterizeText(
    String text, {
    required double width,
    required double height,
    double fontSize = 14,
    Color color = const Color(0xFF000000),
    bool rtl = false,
    String? fontFamily,
    double pixelRatio = 2.5,
    TextAlign align = TextAlign.start,
  }) async {
    if (text.isEmpty || width <= 0 || height <= 0) return null;
    try {
      final int pixelWidth = (width * pixelRatio).round().clamp(1, 4096);
      final int pixelHeight = (height * pixelRatio).round().clamp(1, 4096);
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: fontSize * pixelRatio,
          fontFamily: fontFamily,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          textAlign: align,
        ),
      );
      builder.pushStyle(ui.TextStyle(color: color, fontSize: fontSize * pixelRatio));
      builder.addText(text);
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: pixelWidth.toDouble()));
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawParagraph(paragraph, Offset.zero);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(pixelWidth, pixelHeight);
      picture.dispose();
      final ByteData? data = await image.toByteData();
      image.dispose();
      if (data == null) return null;
      return UPdfRaster(data.buffer.asUint8List(), pixelWidth, pixelHeight);
    } on Object {
      return null;
    }
  }

  static bool isWinAnsiSafe(String text) {
    for (final int code in text.codeUnits) {
      if (code > 0xFF) return false;
      if (code < 0x20 && code != 0x0A) return false;
    }
    return true;
  }

  static String _colorOperator(Color color, {required bool stroke}) => "${UPdfSerializer.number(color.r)} ${UPdfSerializer.number(color.g)} ${UPdfSerializer.number(color.b)} ${stroke ? "RG" : "rg"}";

  static List<Object?> _colorArray(Color color) => <Object?>[color.r, color.g, color.b];

  static UPdfString dateString(DateTime time) => _dateString(time);

  static UPdfString textString(String value) => _text(value);

  static UPdfString _dateString(DateTime time) {
    String two(int value) => value.toString().padLeft(2, "0");
    final Duration offset = time.timeZoneOffset;
    final String sign = offset.isNegative ? "-" : "+";
    final String zone = "$sign${two(offset.inHours.abs())}'${two(offset.inMinutes.abs() % 60)}'";
    return UPdfString(Uint8List.fromList("D:${time.year}${two(time.month)}${two(time.day)}${two(time.hour)}${two(time.minute)}${two(time.second)}$zone".codeUnits));
  }

  static UPdfString _text(String value) {
    final bool ascii = value.codeUnits.every((int code) => code >= 0x20 && code < 0x7F);
    if (ascii) return UPdfString(Uint8List.fromList(value.codeUnits));
    final List<int> bytes = <int>[0xFE, 0xFF];
    for (final int code in value.codeUnits) {
      bytes.add((code >> 8) & 0xFF);
      bytes.add(code & 0xFF);
    }
    return UPdfString(Uint8List.fromList(bytes), hex: true);
  }

  Future<int> addAnnotation(int pageIndex, UPdfAnnotationSpec spec) async {
    final UPdfDict? page = await mutablePage(pageIndex);
    final UPdfRef? ref = await pageRef(pageIndex);
    if (page == null || ref == null) return -1;
    final int number = allocate();
    final Map<String, Object?> annotation = <String, Object?>{
      "Type": const UPdfName("Annot"),
      "Subtype": UPdfName(_subtypeFor(spec.style)),
      "Rect": <Object?>[spec.rect.left, spec.rect.top, spec.rect.right, spec.rect.bottom],
      "F": 4,
      "M": _dateString(DateTime.now()),
      "CA": spec.opacity,
      "C": _colorArray(spec.color),
      "P": ref,
      "NM": _text("u-${DateTime.now().microsecondsSinceEpoch}-$number"),
    };
    if (spec.contents.isNotEmpty) annotation["Contents"] = _text(spec.contents);
    if (spec.author.isNotEmpty) annotation["T"] = _text(spec.author);
    if (spec.title.isNotEmpty) annotation["Subj"] = _text(spec.title);
    if (spec.borderWidth > 0) annotation["BS"] = UPdfDict(<String, Object?>{"W": spec.borderWidth, "S": const UPdfName("S")});
    if (spec.quads.isNotEmpty) {
      final List<Object?> quadPoints = <Object?>[];
      for (final Rect quad in spec.quads) {
        quadPoints.addAll(<Object?>[quad.left, quad.bottom, quad.right, quad.bottom, quad.left, quad.top, quad.right, quad.top]);
      }
      annotation["QuadPoints"] = quadPoints;
    }
    if (spec.style == UPdfAnnotationStyle.ink && spec.inkPaths.isNotEmpty) {
      final List<Object?> inkList = <Object?>[];
      for (final List<Offset> path in spec.inkPaths) {
        final List<Object?> points = <Object?>[];
        for (final Offset point in path) {
          points.addAll(<Object?>[point.dx, point.dy]);
        }
        inkList.add(points);
      }
      annotation["InkList"] = inkList;
    }
    if (spec.style == UPdfAnnotationStyle.freeText) {
      annotation["DA"] = UPdfString(Uint8List.fromList("${_colorOperator(const Color(0xFF000000), stroke: false)} /Helv ${UPdfSerializer.number(spec.fontSize)} Tf".codeUnits));
      annotation["Q"] = spec.rtl ? 2 : 0;
    }
    final int appearanceNumber = allocate();
    final UPdfStream? appearance = await _buildAppearance(spec);
    if (appearance != null) {
      put(appearanceNumber, appearance);
      annotation["AP"] = UPdfDict(<String, Object?>{"N": UPdfRef(appearanceNumber, 0)});
    }
    put(number, UPdfDict(annotation));
    final Object? existing = await document.resolve(page["Annots"]);
    final List<Object?> annotations = existing is List<Object?> ? <Object?>[...existing] : <Object?>[];
    annotations.add(UPdfRef(number, 0));
    page["Annots"] = annotations;
    return number;
  }

  String _subtypeFor(UPdfAnnotationStyle style) {
    switch (style) {
      case UPdfAnnotationStyle.highlight:
        return "Highlight";
      case UPdfAnnotationStyle.underline:
        return "Underline";
      case UPdfAnnotationStyle.strikeOut:
        return "StrikeOut";
      case UPdfAnnotationStyle.squiggly:
        return "Squiggly";
      case UPdfAnnotationStyle.ink:
        return "Ink";
      case UPdfAnnotationStyle.note:
        return "Text";
      case UPdfAnnotationStyle.freeText:
        return "FreeText";
      case UPdfAnnotationStyle.square:
        return "Square";
      case UPdfAnnotationStyle.circle:
        return "Circle";
      case UPdfAnnotationStyle.line:
      case UPdfAnnotationStyle.arrow:
        return "Line";
      case UPdfAnnotationStyle.stamp:
        return "Stamp";
      case UPdfAnnotationStyle.redact:
        return "Square";
    }
  }

  Future<UPdfStream?> rebuildAppearance(UPdfAnnotationSpec spec) => _buildAppearance(spec);

  Future<UPdfStream?> _buildAppearance(UPdfAnnotationSpec spec) async {
    final Rect box = spec.rect;
    final double width = box.width.abs();
    final double height = box.height.abs();
    if (width <= 0 || height <= 0) return null;
    final StringBuffer content = StringBuffer();
    final Map<String, Object?> resources = <String, Object?>{};
    final Map<String, Object?> extGState = <String, Object?>{};
    if (spec.opacity < 1 || spec.style == UPdfAnnotationStyle.highlight) {
      extGState["GS0"] = UPdfDict(<String, Object?>{
        "Type": const UPdfName("ExtGState"),
        "ca": spec.opacity,
        "CA": spec.opacity,
        if (spec.style == UPdfAnnotationStyle.highlight) "BM": const UPdfName("Multiply"),
      });
      content.writeln("/GS0 gs");
    }
    final double originX = box.left;
    final double originY = box.top < box.bottom ? box.top : box.bottom;
    double x(double value) => value - originX;
    double y(double value) => value - originY;

    switch (spec.style) {
      case UPdfAnnotationStyle.highlight:
      case UPdfAnnotationStyle.redact:
        content.writeln(_colorOperator(spec.style == UPdfAnnotationStyle.redact ? const Color(0xFF000000) : spec.color, stroke: false));
        final List<Rect> areas = spec.quads.isEmpty ? <Rect>[box] : spec.quads;
        for (final Rect quad in areas) {
          final double top = quad.top < quad.bottom ? quad.top : quad.bottom;
          content.writeln("${UPdfSerializer.number(x(quad.left))} ${UPdfSerializer.number(y(top))} ${UPdfSerializer.number(quad.width.abs())} ${UPdfSerializer.number(quad.height.abs())} re f");
        }
        break;
      case UPdfAnnotationStyle.underline:
      case UPdfAnnotationStyle.strikeOut:
      case UPdfAnnotationStyle.squiggly:
        content.writeln(_colorOperator(spec.color, stroke: false));
        final List<Rect> marks = spec.quads.isEmpty ? <Rect>[box] : spec.quads;
        for (final Rect quad in marks) {
          final double thickness = quad.height.abs() * 0.07 + 0.6;
          final double top = quad.top < quad.bottom ? quad.top : quad.bottom;
          final double baseline = spec.style == UPdfAnnotationStyle.strikeOut ? y(quad.center.dy) : y(top) + thickness;
          content.writeln("${UPdfSerializer.number(x(quad.left))} ${UPdfSerializer.number(baseline)} ${UPdfSerializer.number(quad.width.abs())} ${UPdfSerializer.number(thickness)} re f");
        }
        break;
      case UPdfAnnotationStyle.ink:
        content.writeln(_colorOperator(spec.borderColor ?? spec.color, stroke: true));
        content.writeln("${UPdfSerializer.number(spec.borderWidth)} w 1 J 1 j");
        for (final List<Offset> path in spec.inkPaths) {
          if (path.isEmpty) continue;
          content.writeln("${UPdfSerializer.number(x(path.first.dx))} ${UPdfSerializer.number(y(path.first.dy))} m");
          for (int i = 1; i < path.length; i++) {
            content.writeln("${UPdfSerializer.number(x(path[i].dx))} ${UPdfSerializer.number(y(path[i].dy))} l");
          }
          content.writeln("S");
        }
        break;
      case UPdfAnnotationStyle.square:
        content.writeln(_colorOperator(spec.borderColor ?? spec.color, stroke: true));
        if (spec.color.a > 0) {
          content.writeln(_colorOperator(spec.color, stroke: false));
          content.writeln(
            "${UPdfSerializer.number(spec.borderWidth)} w ${UPdfSerializer.number(spec.borderWidth / 2)} ${UPdfSerializer.number(spec.borderWidth / 2)} ${UPdfSerializer.number(width - spec.borderWidth)} ${UPdfSerializer.number(height - spec.borderWidth)} re B",
          );
          break;
        }
        content.writeln("${UPdfSerializer.number(spec.borderWidth)} w");
        content.writeln(
          "${UPdfSerializer.number(spec.borderWidth / 2)} ${UPdfSerializer.number(spec.borderWidth / 2)} ${UPdfSerializer.number(width - spec.borderWidth)} ${UPdfSerializer.number(height - spec.borderWidth)} re S",
        );
        break;
      case UPdfAnnotationStyle.circle:
        content.writeln(_colorOperator(spec.borderColor ?? spec.color, stroke: true));
        content.writeln("${UPdfSerializer.number(spec.borderWidth)} w");
        content.write(_ellipse(spec.borderWidth / 2, spec.borderWidth / 2, width - spec.borderWidth, height - spec.borderWidth));
        content.writeln("S");
        break;
      case UPdfAnnotationStyle.line:
      case UPdfAnnotationStyle.arrow:
        content.writeln(_colorOperator(spec.borderColor ?? spec.color, stroke: true));
        content.writeln("${UPdfSerializer.number(spec.borderWidth)} w 1 J");
        content.writeln("0 0 m ${UPdfSerializer.number(width)} ${UPdfSerializer.number(height)} l S");
        if (spec.style == UPdfAnnotationStyle.arrow) {
          final double head = spec.borderWidth * 4 + 4;
          content.writeln("${UPdfSerializer.number(width)} ${UPdfSerializer.number(height)} m ${UPdfSerializer.number(width - head)} ${UPdfSerializer.number(height - head / 2)} l S");
          content.writeln("${UPdfSerializer.number(width)} ${UPdfSerializer.number(height)} m ${UPdfSerializer.number(width - head / 2)} ${UPdfSerializer.number(height - head)} l S");
        }
        break;
      case UPdfAnnotationStyle.note:
        content.writeln(_colorOperator(spec.color, stroke: false));
        content.writeln("0 0 ${UPdfSerializer.number(width)} ${UPdfSerializer.number(height)} re f");
        content.writeln("${_colorOperator(const Color(0xFF000000), stroke: true)} 1 w");
        for (int i = 1; i <= 3; i++) {
          final double lineY = height * i / 4;
          content.writeln("${UPdfSerializer.number(width * 0.2)} ${UPdfSerializer.number(lineY)} m ${UPdfSerializer.number(width * 0.8)} ${UPdfSerializer.number(lineY)} l S");
        }
        break;
      case UPdfAnnotationStyle.freeText:
        if (spec.color.a > 0) {
          content.writeln(_colorOperator(spec.color, stroke: false));
          content.writeln("0 0 ${UPdfSerializer.number(width)} ${UPdfSerializer.number(height)} re f");
        }
        if (spec.borderWidth > 0) {
          content.writeln("${_colorOperator(spec.borderColor ?? const Color(0xFF000000), stroke: true)} ${UPdfSerializer.number(spec.borderWidth)} w");
          content.writeln(
            "${UPdfSerializer.number(spec.borderWidth / 2)} ${UPdfSerializer.number(spec.borderWidth / 2)} ${UPdfSerializer.number(width - spec.borderWidth)} ${UPdfSerializer.number(height - spec.borderWidth)} re S",
          );
        }
        if (isWinAnsiSafe(spec.contents)) {
          resources["Font"] = UPdfDict(<String, Object?>{
            "Helv": UPdfDict(<String, Object?>{
              "Type": const UPdfName("Font"),
              "Subtype": const UPdfName("Type1"),
              "BaseFont": const UPdfName("Helvetica"),
              "Encoding": const UPdfName("WinAnsiEncoding"),
            }),
          });
          content.writeln("BT ${_colorOperator(spec.textColor, stroke: false)} /Helv ${UPdfSerializer.number(spec.fontSize)} Tf");
          double cursorY = height - spec.fontSize * 1.15 - spec.borderWidth;
          for (final String line in spec.contents.split("\n")) {
            content.writeln("1 0 0 1 ${UPdfSerializer.number(spec.borderWidth + 2)} ${UPdfSerializer.number(cursorY)} Tm");
            content.writeln("${String.fromCharCodes(UPdfSerializer.literalString(Uint8List.fromList(line.codeUnits)))} Tj");
            cursorY -= spec.fontSize * 1.25;
          }
          content.writeln("ET");
          break;
        }
        final double inset = spec.borderWidth + 2;
        final UPdfRaster? raster = await rasterizeText(
          spec.contents,
          width: width - inset * 2,
          height: height - inset * 2,
          fontSize: spec.fontSize,
          color: spec.textColor,
          rtl: spec.rtl,
          align: spec.rtl ? TextAlign.right : TextAlign.left,
        );
        if (raster != null && !raster.isEmpty) {
          final int imageNumber = await putImageObject(raster.rgba, raster.width, raster.height);
          resources["XObject"] = UPdfDict(<String, Object?>{"Tx0": UPdfRef(imageNumber, 0)});
          content.writeln(
            "q ${UPdfSerializer.number(width - inset * 2)} 0 0 ${UPdfSerializer.number(height - inset * 2)} ${UPdfSerializer.number(inset)} ${UPdfSerializer.number(inset)} cm /Tx0 Do Q",
          );
        }
        break;
      case UPdfAnnotationStyle.stamp:
        final Uint8List? source = spec.imageBytes;
        if (source == null) return null;
        final UPdfRaster? image = await rasterizeImage(source);
        if (image == null || image.isEmpty) return null;
        final int imageNumber = await putImageObject(image.rgba, image.width, image.height);
        resources["XObject"] = UPdfDict(<String, Object?>{"Im0": UPdfRef(imageNumber, 0)});
        content.writeln("q ${UPdfSerializer.number(width)} 0 0 ${UPdfSerializer.number(height)} 0 0 cm /Im0 Do Q");
        break;
    }
    if (extGState.isNotEmpty) resources["ExtGState"] = UPdfDict(extGState);
    return buildStream(
      Uint8List.fromList(utf8.encode(content.toString())),
      extra: <String, Object?>{
        "Type": const UPdfName("XObject"),
        "Subtype": const UPdfName("Form"),
        "FormType": 1,
        "BBox": <Object?>[0, 0, width, height],
        "Resources": UPdfDict(resources),
      },
    );
  }

  String _ellipse(double left, double bottom, double width, double height) {
    const double kappa = 0.5523;
    final double cx = left + width / 2;
    final double cy = bottom + height / 2;
    final double rx = width / 2;
    final double ry = height / 2;
    String n(double value) => UPdfSerializer.number(value);
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("${n(cx - rx)} ${n(cy)} m");
    buffer.writeln("${n(cx - rx)} ${n(cy + ry * kappa)} ${n(cx - rx * kappa)} ${n(cy + ry)} ${n(cx)} ${n(cy + ry)} c");
    buffer.writeln("${n(cx + rx * kappa)} ${n(cy + ry)} ${n(cx + rx)} ${n(cy + ry * kappa)} ${n(cx + rx)} ${n(cy)} c");
    buffer.writeln("${n(cx + rx)} ${n(cy - ry * kappa)} ${n(cx + rx * kappa)} ${n(cy - ry)} ${n(cx)} ${n(cy - ry)} c");
    buffer.writeln("${n(cx - rx * kappa)} ${n(cy - ry)} ${n(cx - rx)} ${n(cy - ry * kappa)} ${n(cx - rx)} ${n(cy)} c");
    return buffer.toString();
  }

  Future<List<UPdfAnnotationInfo>> annotations(int pageIndex) async {
    final UPdfPage? page = await document.page(pageIndex);
    if (page == null) return const <UPdfAnnotationInfo>[];
    final UPdfDict source = (_changed[page.ref?.number] is UPdfDict ? _changed[page.ref?.number]! as UPdfDict : page.dict);
    final Object? list = await document.resolve(source["Annots"]);
    if (list is! List<Object?>) return const <UPdfAnnotationInfo>[];
    final List<UPdfAnnotationInfo> out = <UPdfAnnotationInfo>[];
    for (final Object? entry in list) {
      final Object? annotation = entry is UPdfRef ? await current(entry) : await document.resolve(entry);
      if (annotation is! UPdfDict) continue;
      final Object? subtype = annotation["Subtype"];
      final Object? rectObject = await document.resolve(annotation["Rect"]);
      final List<double> numbers = <double>[];
      if (rectObject is List<Object?>) {
        for (final Object? value in rectObject) {
          if (value is num) numbers.add(value.toDouble());
        }
      }
      if (numbers.length < 4) continue;
      final Object? contents = await document.resolve(annotation["Contents"]);
      final Object? author = await document.resolve(annotation["T"]);
      final Object? modified = await document.resolve(annotation["M"]);
      final Object? colorObject = await document.resolve(annotation["C"]);
      Color? color;
      if (colorObject is List<Object?> && colorObject.length >= 3) {
        final List<double> rgb = colorObject.whereType<num>().map((num value) => value.toDouble()).toList();
        if (rgb.length >= 3) color = Color.fromARGB(255, (rgb[0] * 255).round().clamp(0, 255), (rgb[1] * 255).round().clamp(0, 255), (rgb[2] * 255).round().clamp(0, 255));
      }
      out.add(
        UPdfAnnotationInfo(
          objectNumber: entry is UPdfRef ? entry.number : -1,
          pageIndex: pageIndex,
          subtype: subtype is UPdfName ? subtype.value : "",
          rect: Rect.fromLTRB(min(numbers[0], numbers[2]), min(numbers[1], numbers[3]), max(numbers[0], numbers[2]), max(numbers[1], numbers[3])),
          contents: contents is UPdfString ? contents.text : "",
          author: author is UPdfString ? author.text : "",
          modified: modified is UPdfString ? modified.date : null,
          color: color,
        ),
      );
    }
    return out;
  }

  Future<bool> removeAnnotation(int pageIndex, int objectNumber) async {
    final UPdfDict? page = await mutablePage(pageIndex);
    if (page == null) return false;
    final Object? list = await document.resolve(page["Annots"]);
    if (list is! List<Object?>) return false;
    final List<Object?> next = list.where((Object? entry) => !(entry is UPdfRef && entry.number == objectNumber)).toList();
    if (next.length == list.length) return false;
    page["Annots"] = next;
    put(objectNumber, null);
    return true;
  }

  Future<void> rotatePage(int index, int degrees) async {
    final UPdfDict? page = await mutablePage(index);
    if (page == null) return;
    final Object? current = await document.resolve(page["Rotate"]);
    final int base = current is num ? current.toInt() : 0;
    page["Rotate"] = ((base + degrees) % 360 + 360) % 360;
  }

  Future<void> setCropBox(int index, Rect box) async {
    final UPdfDict? page = await mutablePage(index);
    if (page == null) return;
    page["CropBox"] = <Object?>[box.left, box.top, box.right, box.bottom];
  }

  Future<List<UPdfRef>> flattenPageTree() async {
    final List<UPdfRef> refs = <UPdfRef>[];
    for (int i = 0; i < document.pageCount; i++) {
      final UPdfRef? ref = await pageRef(i);
      if (ref != null) refs.add(ref);
    }
    return refs;
  }

  Future<bool> setPageOrder(List<UPdfRef> order) async {
    final Object? rootRef = document.catalog?["Pages"];
    if (rootRef is! UPdfRef) return false;
    final Object? root = await current(rootRef);
    if (root is! UPdfDict) return false;
    final UPdfDict mutable = _changed[rootRef.number] is UPdfDict ? _changed[rootRef.number]! as UPdfDict : root.copy();
    mutable["Kids"] = List<Object?>.from(order);
    mutable["Count"] = order.length;
    mutable["Type"] = const UPdfName("Pages");
    put(rootRef.number, mutable);
    document.notePageCount(order.length);
    for (final UPdfRef ref in order) {
      final Object? page = await current(ref);
      if (page is! UPdfDict) continue;
      final UPdfDict pageCopy = _changed[ref.number] is UPdfDict ? _changed[ref.number]! as UPdfDict : page.copy();
      pageCopy["Parent"] = rootRef;
      put(ref.number, pageCopy);
    }
    return true;
  }

  Future<bool> deletePages(List<int> indices) async {
    final Set<int> doomed = indices.toSet();
    final List<UPdfRef> refs = await flattenPageTree();
    final List<UPdfRef> kept = <UPdfRef>[];
    for (int i = 0; i < refs.length; i++) {
      if (!doomed.contains(i)) kept.add(refs[i]);
    }
    if (kept.isEmpty || kept.length == refs.length) return false;
    return setPageOrder(kept);
  }

  Future<bool> movePage(int from, int to) async {
    final List<UPdfRef> refs = await flattenPageTree();
    if (from < 0 || from >= refs.length || to < 0 || to >= refs.length) return false;
    final UPdfRef moved = refs.removeAt(from);
    refs.insert(to, moved);
    return setPageOrder(refs);
  }

  Future<bool> duplicatePage(int index) async {
    final List<UPdfRef> refs = await flattenPageTree();
    if (index < 0 || index >= refs.length) return false;
    final Object? page = await current(refs[index]);
    if (page is! UPdfDict) return false;
    final int number = allocate();
    put(number, page.copy());
    refs.insert(index + 1, UPdfRef(number, 0));
    return setPageOrder(refs);
  }

  Future<bool> insertBlankPage(int at, {Size size = const Size(595.28, 841.89)}) async {
    final List<UPdfRef> refs = await flattenPageTree();
    final int contentNumber = allocate();
    put(contentNumber, buildStream(Uint8List(0)));
    final int number = allocate();
    put(
      number,
      UPdfDict(<String, Object?>{
        "Type": const UPdfName("Page"),
        "MediaBox": <Object?>[0, 0, size.width, size.height],
        "Resources": UPdfDict(<String, Object?>{}),
        "Contents": UPdfRef(contentNumber, 0),
      }),
    );
    refs.insert(at.clamp(0, refs.length), UPdfRef(number, 0));
    return setPageOrder(refs);
  }

  Future<void> appendContent(int pageIndex, String operators, {Map<String, Object?> extraResources = const <String, Object?>{}}) async {
    final UPdfDict? page = await mutablePage(pageIndex);
    if (page == null) return;
    final int number = allocate();
    put(number, buildStream(Uint8List.fromList(utf8.encode("\nq\n$operators\nQ\n"))));
    final Object? contents = page["Contents"];
    if (contents is List<Object?>) {
      page["Contents"] = <Object?>[...contents, UPdfRef(number, 0)];
    } else if (contents != null) {
      page["Contents"] = <Object?>[contents, UPdfRef(number, 0)];
    } else {
      page["Contents"] = <Object?>[UPdfRef(number, 0)];
    }
    if (extraResources.isEmpty) return;
    final Object? resolved = await document.resolve(page["Resources"]);
    final UPdfDict resources = resolved is UPdfDict ? resolved.copy() : UPdfDict(<String, Object?>{});
    extraResources.forEach((String key, Object? value) {
      final Object? existing = resources[key];
      if (existing is UPdfDict && value is UPdfDict) {
        final UPdfDict merged = existing.copy();
        value.entries.forEach((String innerKey, Object? innerValue) => merged[innerKey] = innerValue);
        resources[key] = merged;
      } else {
        resources[key] = value;
      }
    });
    page["Resources"] = resources;
  }

  Future<void> addTextWatermark(String text, {double fontSize = 48, Color color = const Color(0x33000000), double rotation = 45, List<int>? pages}) async {
    final List<int> targets = pages ?? List<int>.generate(document.pageCount, (int index) => index);
    for (final int index in targets) {
      final UPdfPage? page = await document.page(index);
      if (page == null) continue;
      final double centerX = page.box.width / 2 + page.box.left;
      final double centerY = page.box.height / 2 + page.box.top;
      final double radians = rotation * pi / 180;
      final double cosine = cos(radians);
      final double sine = sin(radians);
      final String escaped = String.fromCharCodes(UPdfSerializer.literalString(Uint8List.fromList(text.codeUnits)));
      final StringBuffer buffer = StringBuffer()
        ..writeln("/GSW gs")
        ..writeln("BT ${_colorOperator(color, stroke: false)} /Helv ${UPdfSerializer.number(fontSize)} Tf")
        ..writeln(
          "${UPdfSerializer.number(cosine)} ${UPdfSerializer.number(sine)} ${UPdfSerializer.number(-sine)} ${UPdfSerializer.number(cosine)} "
          "${UPdfSerializer.number(centerX - text.length * fontSize * 0.25)} ${UPdfSerializer.number(centerY)} Tm",
        )
        ..writeln("$escaped Tj")
        ..writeln("ET");
      await appendContent(
        index,
        buffer.toString(),
        extraResources: <String, Object?>{
          "Font": UPdfDict(<String, Object?>{
            "Helv": UPdfDict(<String, Object?>{
              "Type": const UPdfName("Font"),
              "Subtype": const UPdfName("Type1"),
              "BaseFont": const UPdfName("Helvetica"),
              "Encoding": const UPdfName("WinAnsiEncoding"),
            }),
          }),
          "ExtGState": UPdfDict(<String, Object?>{
            "GSW": UPdfDict(<String, Object?>{"Type": const UPdfName("ExtGState"), "ca": color.a, "CA": color.a}),
          }),
        },
      );
    }
  }

  Future<void> addPageNumbers({double fontSize = 10, Color color = const Color(0xFF000000), double margin = 24, int startAt = 1, bool rightAligned = true}) async {
    for (int index = 0; index < document.pageCount; index++) {
      final UPdfPage? page = await document.page(index);
      if (page == null) continue;
      final String label = "${startAt + index}";
      final double x = rightAligned ? page.box.right - margin - fontSize * label.length * 0.6 : page.box.left + margin;
      final double y = page.box.top + margin;
      final String escaped = String.fromCharCodes(UPdfSerializer.literalString(Uint8List.fromList(label.codeUnits)));
      await appendContent(
        index,
        "BT ${_colorOperator(color, stroke: false)} /Helv ${UPdfSerializer.number(fontSize)} Tf 1 0 0 1 ${UPdfSerializer.number(x)} ${UPdfSerializer.number(y)} Tm $escaped Tj ET",
        extraResources: <String, Object?>{
          "Font": UPdfDict(<String, Object?>{
            "Helv": UPdfDict(<String, Object?>{
              "Type": const UPdfName("Font"),
              "Subtype": const UPdfName("Type1"),
              "BaseFont": const UPdfName("Helvetica"),
              "Encoding": const UPdfName("WinAnsiEncoding"),
            }),
          }),
        },
      );
    }
  }

  Future<void> setMetadata(UDocMetadata metadata) async {
    final Object? infoRef = document.xref.trailer?["Info"];
    final int number = infoRef is UPdfRef ? infoRef.number : allocate();
    final Object? existing = infoRef is UPdfRef ? await current(infoRef) : null;
    final UPdfDict info = existing is UPdfDict ? existing.copy() : UPdfDict(<String, Object?>{});
    void assign(String key, String? value) {
      if (value == null) return;
      if (value.isEmpty) {
        info.entries.remove(key);
        return;
      }
      info[key] = _text(value);
    }

    assign("Title", metadata.title);
    assign("Author", metadata.author);
    assign("Subject", metadata.subject);
    assign("Keywords", metadata.keywords);
    assign("Creator", metadata.creator);
    assign("Producer", metadata.producer ?? "u_doc");
    info["ModDate"] = _dateString(DateTime.now());
    put(number, info);
    if (infoRef is! UPdfRef) {
      final UPdfDict trailer = document.xref.trailer ?? UPdfDict(<String, Object?>{});
      trailer["Info"] = UPdfRef(number, 0);
      document.xref.trailer = trailer;
    }
  }

  Future<List<UPdfFormField>> formFields() async {
    final Object? acroForm = await document.resolve(document.catalog?["AcroForm"]);
    if (acroForm is! UPdfDict) return const <UPdfFormField>[];
    final Object? fields = await document.resolve(acroForm["Fields"]);
    if (fields is! List<Object?>) return const <UPdfFormField>[];
    final List<UPdfFormField> out = <UPdfFormField>[];
    final Map<int, int> pageOf = <int, int>{};
    for (int index = 0; index < document.pageCount && index < 4096; index++) {
      final UPdfPage? page = await document.page(index);
      final Object? annots = await document.resolve(page?.dict["Annots"]);
      if (annots is! List<Object?>) continue;
      for (final Object? entry in annots) {
        if (entry is UPdfRef) pageOf[entry.number] = index;
      }
    }
    Future<void> walk(Object? entry, String prefix, int depth) async {
      if (depth > 12 || out.length > 4096) return;
      final Object? field = entry is UPdfRef ? await current(entry) : await document.resolve(entry);
      if (field is! UPdfDict) return;
      final Object? partial = await document.resolve(field["T"]);
      final String name = partial is UPdfString ? (prefix.isEmpty ? partial.text : "$prefix.${partial.text}") : prefix;
      final Object? kids = await document.resolve(field["Kids"]);
      if (kids is List<Object?> && kids.isNotEmpty) {
        for (final Object? kid in kids) {
          await walk(kid, name, depth + 1);
        }
        return;
      }
      final Object? typeObject = await document.resolve(field["FT"]);
      final String type = typeObject is UPdfName ? typeObject.value : "";
      final Object? flagsObject = await document.resolve(field["Ff"]);
      final int flags = flagsObject is num ? flagsObject.toInt() : 0;
      UDocFieldKind kind = UDocFieldKind.unknown;
      if (type == "Tx") kind = UDocFieldKind.text;
      if (type == "Btn") kind = flags & 65536 != 0 ? UDocFieldKind.pushButton : (flags & 32768 != 0 ? UDocFieldKind.radioButton : UDocFieldKind.checkBox);
      if (type == "Ch") kind = flags & 131072 != 0 ? UDocFieldKind.comboBox : UDocFieldKind.listBox;
      if (type == "Sig") kind = UDocFieldKind.signature;
      final Object? rectObject = await document.resolve(field["Rect"]);
      final List<double> numbers = <double>[];
      if (rectObject is List<Object?>) {
        for (final Object? value in rectObject) {
          if (value is num) numbers.add(value.toDouble());
        }
      }
      final Object? valueObject = await document.resolve(field["V"]);
      Object? value;
      if (valueObject is UPdfString) value = valueObject.text;
      if (valueObject is UPdfName) value = valueObject.value;
      if (valueObject is num) value = valueObject;
      final List<String> options = <String>[];
      final Object? optionsObject = await document.resolve(field["Opt"]);
      if (optionsObject is List<Object?>) {
        for (final Object? option in optionsObject) {
          final Object? resolved = await document.resolve(option);
          if (resolved is UPdfString) options.add(resolved.text);
          if (resolved is List<Object?> && resolved.isNotEmpty) {
            final Object? label = await document.resolve(resolved.last);
            if (label is UPdfString) options.add(label.text);
          }
        }
      }
      final Object? maxLengthObject = await document.resolve(field["MaxLen"]);
      out.add(
        UPdfFormField(
          objectNumber: entry is UPdfRef ? entry.number : -1,
          name: name,
          kind: kind,
          pageIndex: entry is UPdfRef ? (pageOf[entry.number] ?? 0) : 0,
          rect: numbers.length >= 4 ? Rect.fromLTRB(min(numbers[0], numbers[2]), min(numbers[1], numbers[3]), max(numbers[0], numbers[2]), max(numbers[1], numbers[3])) : Rect.zero,
          value: value,
          options: options,
          readOnly: flags & 1 != 0,
          required: flags & 2 != 0,
          maxLength: maxLengthObject is num ? maxLengthObject.toInt() : 0,
        ),
      );
    }

    for (final Object? entry in fields) {
      await walk(entry, "", 0);
    }
    return out;
  }

  Future<bool> setFieldValue(UPdfFormField field, Object? value) async {
    if (field.objectNumber < 0) return false;
    final Object? existing = await current(UPdfRef(field.objectNumber, 0));
    if (existing is! UPdfDict) return false;
    final UPdfDict widget = existing.copy();
    switch (field.kind) {
      case UDocFieldKind.checkBox:
      case UDocFieldKind.radioButton:
        final bool on = value == true || value == "Yes" || value == "On";
        widget["V"] = UPdfName(on ? "Yes" : "Off");
        widget["AS"] = UPdfName(on ? "Yes" : "Off");
        break;
      case UDocFieldKind.comboBox:
      case UDocFieldKind.listBox:
      case UDocFieldKind.text:
        widget["V"] = _text("${value ?? ""}");
        widget.entries.remove("AP");
        final double height = field.rect.height <= 0 ? 14 : field.rect.height;
        final double fontSize = height * 0.62;
        final int appearance = allocate();
        final String escaped = String.fromCharCodes(UPdfSerializer.literalString(Uint8List.fromList("${value ?? ""}".codeUnits)));
        put(
          appearance,
          buildStream(
            Uint8List.fromList(utf8.encode("/Tx BMC q BT 0 g /Helv ${UPdfSerializer.number(fontSize)} Tf 1 0 0 1 2 ${UPdfSerializer.number((height - fontSize) / 2)} Tm $escaped Tj ET Q EMC")),
            extra: <String, Object?>{
              "Type": const UPdfName("XObject"),
              "Subtype": const UPdfName("Form"),
              "FormType": 1,
              "BBox": <Object?>[0, 0, field.rect.width, height],
              "Resources": UPdfDict(<String, Object?>{
                "Font": UPdfDict(<String, Object?>{
                  "Helv": UPdfDict(<String, Object?>{
                    "Type": const UPdfName("Font"),
                    "Subtype": const UPdfName("Type1"),
                    "BaseFont": const UPdfName("Helvetica"),
                    "Encoding": const UPdfName("WinAnsiEncoding"),
                  }),
                }),
              }),
            },
          ),
        );
        widget["AP"] = UPdfDict(<String, Object?>{"N": UPdfRef(appearance, 0)});
        break;
      case UDocFieldKind.pushButton:
      case UDocFieldKind.signature:
      case UDocFieldKind.unknown:
        return false;
    }
    put(field.objectNumber, widget);
    await _setNeedAppearances(false);
    return true;
  }

  Future<void> _setNeedAppearances(bool value) async {
    final Object? acroFormRef = document.catalog?["AcroForm"];
    if (acroFormRef is! UPdfRef) return;
    final Object? acroForm = await current(acroFormRef);
    if (acroForm is! UPdfDict) return;
    final UPdfDict copy = acroForm.copy();
    copy["NeedAppearances"] = value;
    put(acroFormRef.number, copy);
  }

  Future<Uint8List> buildIncrement() async {
    final BytesBuilder out = BytesBuilder(copy: false);
    final int base = document.source.length;
    final Map<int, int> offsets = <int, int>{};
    final List<int> numbers = _changed.keys.toList()..sort();
    final UPdfEncryption? encryption = document.encryption;
    out.add("\n".codeUnits);
    int cursor = base + 1;
    for (final int number in numbers) {
      final Object? value = _changed[number];
      final BytesBuilder body = BytesBuilder(copy: false);
      body.add("$number 0 obj\n".codeUnits);
      if (value == null) {
        body.add("null".codeUnits);
      } else {
        UPdfSerializer.write(body, value, encryption: encryption, objectNumber: number);
      }
      body.add("\nendobj\n".codeUnits);
      final Uint8List bytes = body.takeBytes();
      offsets[number] = value == null ? -1 : cursor;
      cursor += bytes.length;
      out.add(bytes);
    }
    final int xrefOffset = cursor;
    final BytesBuilder table = BytesBuilder(copy: false);
    table.add("xref\n".codeUnits);
    final List<List<int>> runs = <List<int>>[];
    for (final int number in numbers) {
      if (runs.isNotEmpty && runs.last.last + 1 == number) {
        runs.last.add(number);
      } else {
        runs.add(<int>[number]);
      }
    }
    for (final List<int> run in runs) {
      table.add("${run.first} ${run.length}\n".codeUnits);
      for (final int number in run) {
        final int offset = offsets[number] ?? -1;
        if (offset < 0) {
          table.add("0000000000 65535 f \n".codeUnits);
        } else {
          table.add("${offset.toString().padLeft(10, "0")} 00000 n \n".codeUnits);
        }
      }
    }
    int highest = 0;
    for (final int number in numbers) {
      if (number > highest) highest = number;
    }
    for (final int number in document.xref.entries.keys) {
      if (number > highest) highest = number;
    }
    final UPdfDict trailer = UPdfDict(<String, Object?>{
      "Size": highest + 1,
      if (document.xref.trailer?["Root"] != null) "Root": document.xref.trailer!["Root"],
      if (document.xref.trailer?["Info"] != null) "Info": document.xref.trailer!["Info"],
      if (document.xref.trailer?["Encrypt"] != null) "Encrypt": document.xref.trailer!["Encrypt"],
      if (document.xref.trailer?["ID"] != null) "ID": document.xref.trailer!["ID"],
      if (document.startXrefOffset >= 0) "Prev": document.startXrefOffset,
    });
    table.add("trailer\n".codeUnits);
    UPdfSerializer.write(table, trailer);
    table.add("\nstartxref\n$xrefOffset\n%%EOF\n".codeUnits);
    out.add(table.takeBytes());
    return out.takeBytes();
  }

  Future<bool> saveIncrementalTo(String path) async {
    if (kIsWeb) return false;
    try {
      final Uint8List increment = await buildIncrement();
      final File target = File(path);
      final String? sourcePath = document.source.inner is UFileByteSource ? (document.source.inner as UFileByteSource).path : null;
      if (sourcePath != null && sourcePath == path) {
        final RandomAccessFile handle = await target.open(mode: FileMode.append);
        await handle.writeFrom(increment);
        await handle.close();
        return true;
      }
      final IOSink sink = target.openWrite();
      const int chunk = 1 << 20;
      int offset = 0;
      while (offset < document.source.length) {
        final int take = offset + chunk > document.source.length ? document.source.length - offset : chunk;
        sink.add(await document.source.read(offset, take));
        offset += take;
      }
      sink.add(increment);
      await sink.flush();
      await sink.close();
      return true;
    } on Object {
      return false;
    }
  }

  Future<Uint8List?> saveToBytes({int cap = 256 * 1024 * 1024}) async {
    if (document.source.length > cap) return null;
    try {
      final Uint8List original = await document.source.read(0, document.source.length);
      final Uint8List increment = await buildIncrement();
      final Uint8List out = Uint8List(original.length + increment.length);
      out.setRange(0, original.length, original);
      out.setRange(original.length, out.length, increment);
      return out;
    } on Object {
      return null;
    }
  }
}

class UPdfRaster {
  const UPdfRaster(this.rgba, this.width, this.height);

  final Uint8List rgba;
  final int width;
  final int height;

  bool get isEmpty => width <= 0 || height <= 0 || rgba.isEmpty;
}

class UPdfRedactor {
  UPdfRedactor(this.edit);

  final UPdfEdit edit;

  UPdfDocument get document => edit.document;

  Future<int> apply(int pageIndex, List<Rect> areas, {bool paintBlack = true, Color fill = const Color(0xFF000000)}) async {
    if (areas.isEmpty) return 0;
    final UPdfPage? page = await document.page(pageIndex);
    final UPdfDict? mutable = await edit.mutablePage(pageIndex);
    if (page == null || mutable == null) return 0;
    final Uint8List content = await document.pageContent(page);
    final _UPdfRedactionPass pass = _UPdfRedactionPass(document: document, resources: page.resources, areas: areas);
    final Uint8List filtered = await pass.run(content);
    final int contentNumber = edit.allocate();
    edit.put(contentNumber, edit.buildStream(filtered));
    mutable["Contents"] = UPdfRef(contentNumber, 0);
    if (paintBlack) {
      final StringBuffer buffer = StringBuffer("${UPdfSerializer.number(fill.r)} ${UPdfSerializer.number(fill.g)} ${UPdfSerializer.number(fill.b)} rg\n");
      for (final Rect area in areas) {
        buffer.writeln("${UPdfSerializer.number(area.left)} ${UPdfSerializer.number(area.top)} ${UPdfSerializer.number(area.width)} ${UPdfSerializer.number(area.height)} re f");
      }
      await edit.appendContent(pageIndex, buffer.toString());
    }
    await _removeRedactAnnotations(pageIndex, mutable);
    return pass.removed;
  }

  Future<void> _removeRedactAnnotations(int pageIndex, UPdfDict page) async {
    final Object? list = await document.resolve(page["Annots"]);
    if (list is! List<Object?>) return;
    final List<Object?> kept = <Object?>[];
    for (final Object? entry in list) {
      final Object? annotation = await document.resolve(entry);
      final Object? subtype = annotation is UPdfDict ? annotation["Subtype"] : null;
      final Object? intent = annotation is UPdfDict ? annotation["IT"] : null;
      final bool isRedact = (subtype is UPdfName && subtype.value == "Redact") || (intent is UPdfName && intent.value == "Redact");
      if (isRedact) continue;
      kept.add(entry);
    }
    page["Annots"] = kept;
  }
}

class _UPdfRedactionPass {
  _UPdfRedactionPass({required this.document, required this.resources, required this.areas});

  final UPdfDocument document;
  final UPdfDict? resources;
  final List<Rect> areas;

  int removed = 0;

  Future<Uint8List> run(Uint8List content) async {
    final _UPdfRedactionState state = _UPdfRedactionState();
    final StringBuffer out = StringBuffer();
    final UDocCursor cursor = UDocCursor(content);
    final List<Object?> operands = <Object?>[];
    int guard = 0;
    while (!cursor.isEmpty && guard < 4000000) {
      guard++;
      UPdfSyntax.skipWhitespace(cursor);
      if (cursor.isEmpty) break;
      final int byte = cursor.peek;
      if (byte == 0x2F || byte == 0x5B || byte == 0x28 || byte == 0x3C || UPdfSyntax.isDigit(byte) || byte == 0x2B || byte == 0x2D || byte == 0x2E) {
        operands.add(UPdfSyntax.parseObject(cursor));
        if (operands.length > 64) operands.removeRange(0, operands.length - 64);
        continue;
      }
      final String op = UPdfSyntax.readKeyword(cursor);
      if (op.isEmpty) {
        cursor.skip(1);
        continue;
      }
      if (op == "BI") {
        final int start = cursor.position;
        _skipInlineImage(cursor);
        out.write(String.fromCharCodes(Uint8List.sublistView(content, start - 2 < 0 ? 0 : start - 2, cursor.position)));
        operands.clear();
        continue;
      }
      final bool keep = await _handle(op, operands, state, out);
      if (keep) {
        for (final Object? operand in operands) {
          final BytesBuilder builder = BytesBuilder(copy: false);
          UPdfSerializer.write(builder, operand);
          out.write(String.fromCharCodes(builder.takeBytes()));
          out.write(" ");
        }
        out.writeln(op);
      }
      operands.clear();
    }
    return Uint8List.fromList(utf8.encode(out.toString()));
  }

  void _skipInlineImage(UDocCursor cursor) {
    int guard = 0;
    while (!cursor.isEmpty && guard < 100000) {
      guard++;
      final int found = cursor.indexOf(const <int>[0x45, 0x49], from: cursor.position);
      if (found < 0) {
        cursor.seek(cursor.end);
        return;
      }
      cursor.seek(found + 2 > cursor.end ? cursor.end : found + 2);
      return;
    }
  }

  Future<bool> _handle(String op, List<Object?> operands, _UPdfRedactionState state, StringBuffer out) async {
    double number(int index) {
      if (index < 0 || index >= operands.length) return 0;
      final Object? value = operands[index];
      return value is num ? value.toDouble() : 0;
    }

    switch (op) {
      case "q":
        state.push();
        return true;
      case "Q":
        state.pop();
        return true;
      case "cm":
        if (operands.length >= 6) state.ctm = uPdfMul(<double>[number(0), number(1), number(2), number(3), number(4), number(5)], state.ctm);
        return true;
      case "BT":
        state.textMatrix = <double>[1, 0, 0, 1, 0, 0];
        state.lineMatrix = <double>[1, 0, 0, 1, 0, 0];
        return true;
      case "Tf":
        state.fontSize = number(1);
        state.font = await _font(operands.isEmpty ? "" : (operands[0] is UPdfName ? (operands[0]! as UPdfName).value : ""));
        return true;
      case "Tc":
        state.charSpacing = number(0);
        return true;
      case "Tw":
        state.wordSpacing = number(0);
        return true;
      case "Tz":
        state.horizontalScale = number(0) / 100;
        return true;
      case "TL":
        state.leading = number(0);
        return true;
      case "Ts":
        state.rise = number(0);
        return true;
      case "Td":
        state.lineMatrix = uPdfMul(<double>[1, 0, 0, 1, number(0), number(1)], state.lineMatrix);
        state.textMatrix = List<double>.from(state.lineMatrix);
        return true;
      case "TD":
        state.leading = -number(1);
        state.lineMatrix = uPdfMul(<double>[1, 0, 0, 1, number(0), number(1)], state.lineMatrix);
        state.textMatrix = List<double>.from(state.lineMatrix);
        return true;
      case "Tm":
        if (operands.length >= 6) {
          state.lineMatrix = <double>[number(0), number(1), number(2), number(3), number(4), number(5)];
          state.textMatrix = List<double>.from(state.lineMatrix);
        }
        return true;
      case "T*":
        state.lineMatrix = uPdfMul(<double>[1, 0, 0, 1, 0, -state.leading], state.lineMatrix);
        state.textMatrix = List<double>.from(state.lineMatrix);
        return true;
      case "'":
      case '"':
        {
          state.lineMatrix = uPdfMul(<double>[1, 0, 0, 1, 0, -state.leading], state.lineMatrix);
          state.textMatrix = List<double>.from(state.lineMatrix);
          final Object? shown = operands.isEmpty ? null : operands.last;
          if (shown is UPdfString) {
            final String? replacement = _showText(shown, state);
            if (replacement != null) {
              out.writeln(replacement);
              return false;
            }
          }
        }
        return true;
      case "Tj":
        {
          final Object? value = operands.isEmpty ? null : operands[0];
          if (value is UPdfString) {
            final String? replacement = _showText(value, state);
            if (replacement != null) {
              out.writeln(replacement);
              return false;
            }
          }
        }
        return true;
      case "TJ":
        {
          final Object? array = operands.isEmpty ? null : operands[0];
          if (array is! List<Object?>) return true;
          final List<Object?> rebuilt = <Object?>[];
          bool changed = false;
          for (final Object? entry in array) {
            if (entry is num) {
              rebuilt.add(entry);
              state.textMatrix = uPdfMul(<double>[1, 0, 0, 1, -entry.toDouble() / 1000 * state.fontSize * state.horizontalScale, 0], state.textMatrix);
              continue;
            }
            if (entry is! UPdfString) continue;
            final double advance = _advanceOf(entry, state);
            if (_intersects(entry, state)) {
              changed = true;
              removed++;
              final double denominator = state.fontSize * state.horizontalScale;
              rebuilt.add(denominator == 0 ? 0 : -advance * 1000 / denominator);
            } else {
              rebuilt.add(entry);
            }
            state.textMatrix = uPdfMul(<double>[1, 0, 0, 1, advance, 0], state.textMatrix);
          }
          if (!changed) return true;
          final BytesBuilder builder = BytesBuilder(copy: false);
          UPdfSerializer.write(builder, rebuilt);
          out.writeln("${String.fromCharCodes(builder.takeBytes())} TJ");
          return false;
        }
      case "Do":
        {
          final String name = operands.isEmpty ? "" : (operands[0] is UPdfName ? (operands[0]! as UPdfName).value : "");
          if (name.isEmpty) return true;
          final Object? xobjects = await document.resolve(resources?["XObject"]);
          if (xobjects is! UPdfDict) return true;
          final Object? stream = await document.resolve(xobjects[name]);
          if (stream is! UPdfStream) return true;
          final Object? subtype = stream.dict["Subtype"];
          if (subtype is! UPdfName || subtype.value != "Image") return true;
          if (_unitSquareIntersects(state.ctm)) {
            removed++;
            return false;
          }
          return true;
        }
      default:
        return true;
    }
  }

  Future<UPdfFont?> _font(String name) async {
    if (name.isEmpty) return null;
    final Object? fonts = await document.resolve(resources?["Font"]);
    if (fonts is! UPdfDict) return null;
    final Object? dict = await document.resolve(fonts[name]);
    if (dict is! UPdfDict) return null;
    return UPdfFont.load(document, dict, cacheKey: "${document.fingerprint}:redact:$name");
  }

  String? _showText(UPdfString value, _UPdfRedactionState state) {
    final double advance = _advanceOf(value, state);
    final bool hit = _intersects(value, state);
    state.textMatrix = uPdfMul(<double>[1, 0, 0, 1, advance, 0], state.textMatrix);
    if (!hit) return null;
    removed++;
    final double denominator = state.fontSize * state.horizontalScale;
    final double shift = denominator == 0 ? 0 : -advance * 1000 / denominator;
    return "[ ${UPdfSerializer.number(shift)} ] TJ";
  }

  double _advanceOf(UPdfString value, _UPdfRedactionState state) {
    final UPdfFont? font = state.font;
    if (font == null) return 0;
    double total = 0;
    for (final UPdfCodePoint point in font.decode(value.bytes)) {
      final bool isSpace = point.byteLength == 1 && point.code == 32;
      total += (font.widthFor(point) / 1000 * state.fontSize + state.charSpacing + (isSpace ? state.wordSpacing : 0)) * state.horizontalScale;
    }
    return total;
  }

  bool _intersects(UPdfString value, _UPdfRedactionState state) {
    final UPdfFont? font = state.font;
    if (font == null) return false;
    double cursor = 0;
    for (final UPdfCodePoint point in font.decode(value.bytes)) {
      final double width = font.widthFor(point) / 1000 * state.fontSize;
      final List<double> parameters = <double>[state.fontSize * state.horizontalScale, 0, 0, state.fontSize, cursor, state.rise];
      final List<double> trm = uPdfMul(uPdfMul(parameters, state.textMatrix), state.ctm);
      final Offset a = uPdfApply(trm, 0, font.descent / 1000);
      final Offset b = uPdfApply(trm, width / (state.fontSize == 0 ? 1 : state.fontSize), font.ascent / 1000);
      final Rect glyph = Rect.fromLTRB(min(a.dx, b.dx), min(a.dy, b.dy), max(a.dx, b.dx), max(a.dy, b.dy));
      for (final Rect area in areas) {
        if (area.overlaps(glyph.inflate(0.1))) return true;
      }
      final bool isSpace = point.byteLength == 1 && point.code == 32;
      cursor += (width + state.charSpacing + (isSpace ? state.wordSpacing : 0)) * state.horizontalScale;
    }
    return false;
  }

  bool _unitSquareIntersects(List<double> matrix) {
    final Offset a = uPdfApply(matrix, 0, 0);
    final Offset b = uPdfApply(matrix, 1, 0);
    final Offset c = uPdfApply(matrix, 1, 1);
    final Offset d = uPdfApply(matrix, 0, 1);
    final Rect box = Rect.fromLTRB(
      <double>[a.dx, b.dx, c.dx, d.dx].reduce(min),
      <double>[a.dy, b.dy, c.dy, d.dy].reduce(min),
      <double>[a.dx, b.dx, c.dx, d.dx].reduce(max),
      <double>[a.dy, b.dy, c.dy, d.dy].reduce(max),
    );
    for (final Rect area in areas) {
      if (area.overlaps(box)) return true;
    }
    return false;
  }
}

class _UPdfRedactionState {
  List<double> ctm = <double>[1, 0, 0, 1, 0, 0];
  List<double> textMatrix = <double>[1, 0, 0, 1, 0, 0];
  List<double> lineMatrix = <double>[1, 0, 0, 1, 0, 0];
  UPdfFont? font;
  double fontSize = 0;
  double charSpacing = 0;
  double wordSpacing = 0;
  double horizontalScale = 1;
  double leading = 0;
  double rise = 0;

  final List<List<double>> _stack = <List<double>>[];

  void push() => _stack.add(List<double>.from(ctm));

  void pop() {
    if (_stack.isEmpty) return;
    ctm = _stack.removeLast();
  }
}

class UPdfComposer {
  UPdfComposer();

  final Map<int, Object?> _objects = <int, Object?>{};
  final Map<UPdfDocument, Map<int, int>> _maps = <UPdfDocument, Map<int, int>>{};
  final List<int> _pages = <int>[];

  int _next = 1;

  int get pageCount => _pages.length;

  int allocate() => _next++;

  void put(int number, Object? value) => _objects[number] = value;

  Future<int?> addPage(UPdfDocument source, int index, {Rect? crop, int? rotate}) async {
    final UPdfPage? page = await source.page(index);
    if (page == null) return null;
    final Map<int, int> map = _maps.putIfAbsent(source, () => <int, int>{});
    final UPdfDict dict = page.dict.copy();
    dict["Type"] = const UPdfName("Page");
    dict["MediaBox"] = <Object?>[page.mediaBox.left, page.mediaBox.top, page.mediaBox.right, page.mediaBox.bottom];
    final Rect box = crop ?? page.cropBox;
    dict["CropBox"] = <Object?>[box.left, box.top, box.right, box.bottom];
    dict["Rotate"] = rotate ?? page.rotation;
    if (page.resources != null) dict["Resources"] = page.resources;
    dict.entries.remove("Parent");
    final int number = allocate();
    _objects[number] = await _copyValue(source, dict, map, 0);
    _pages.add(number);
    return number;
  }

  void addBlankPage({Size size = const Size(595.28, 841.89)}) {
    final int contents = allocate();
    _objects[contents] = _stream(Uint8List(0));
    final int number = allocate();
    _objects[number] = UPdfDict(<String, Object?>{
      "Type": const UPdfName("Page"),
      "MediaBox": <Object?>[0, 0, size.width, size.height],
      "Resources": UPdfDict(<String, Object?>{}),
      "Contents": UPdfRef(contents, 0),
    });
    _pages.add(number);
  }

  Future<int?> addImagePage(Uint8List encoded, {Size? size, double margin = 0}) async {
    final UPdfRaster? raster = await UPdfEdit.rasterizeImage(encoded, maxSize: 4096);
    if (raster == null || raster.isEmpty) return null;
    final double pageWidth = size?.width ?? raster.width.toDouble();
    final double pageHeight = size?.height ?? raster.height.toDouble();
    final int pixels = raster.width * raster.height;
    final Uint8List colour = Uint8List(pixels * 3);
    final Uint8List alpha = Uint8List(pixels);
    bool transparent = false;
    for (int i = 0; i < pixels; i++) {
      colour[i * 3] = raster.rgba[i * 4];
      colour[i * 3 + 1] = raster.rgba[i * 4 + 1];
      colour[i * 3 + 2] = raster.rgba[i * 4 + 2];
      alpha[i] = raster.rgba[i * 4 + 3];
      if (alpha[i] != 255) transparent = true;
    }
    int? maskNumber;
    if (transparent) {
      maskNumber = allocate();
      _objects[maskNumber] = _stream(
        alpha,
        extra: <String, Object?>{
          "Type": const UPdfName("XObject"),
          "Subtype": const UPdfName("Image"),
          "Width": raster.width,
          "Height": raster.height,
          "ColorSpace": const UPdfName("DeviceGray"),
          "BitsPerComponent": 8,
        },
      );
    }
    final int imageNumber = allocate();
    _objects[imageNumber] = _stream(
      colour,
      extra: <String, Object?>{
        "Type": const UPdfName("XObject"),
        "Subtype": const UPdfName("Image"),
        "Width": raster.width,
        "Height": raster.height,
        "ColorSpace": const UPdfName("DeviceRGB"),
        "BitsPerComponent": 8,
        if (maskNumber != null) "SMask": UPdfRef(maskNumber, 0),
      },
    );
    final double drawWidth = pageWidth - margin * 2;
    final double drawHeight = pageHeight - margin * 2;
    final double scale = min(drawWidth / raster.width, drawHeight / raster.height);
    final double placedWidth = raster.width * scale;
    final double placedHeight = raster.height * scale;
    final double offsetX = (pageWidth - placedWidth) / 2;
    final double offsetY = (pageHeight - placedHeight) / 2;
    final int contents = allocate();
    _objects[contents] = _stream(
      Uint8List.fromList(
        utf8.encode("q ${UPdfSerializer.number(placedWidth)} 0 0 ${UPdfSerializer.number(placedHeight)} ${UPdfSerializer.number(offsetX)} ${UPdfSerializer.number(offsetY)} cm /Im0 Do Q"),
      ),
    );
    final int number = allocate();
    _objects[number] = UPdfDict(<String, Object?>{
      "Type": const UPdfName("Page"),
      "MediaBox": <Object?>[0, 0, pageWidth, pageHeight],
      "Resources": UPdfDict(<String, Object?>{
        "XObject": UPdfDict(<String, Object?>{"Im0": UPdfRef(imageNumber, 0)}),
      }),
      "Contents": UPdfRef(contents, 0),
    });
    _pages.add(number);
    return number;
  }

  UPdfStream _stream(Uint8List data, {Map<String, Object?> extra = const <String, Object?>{}}) {
    final Uint8List deflated = kIsWeb ? data : UPdfCodecs.deflate(data);
    final bool useDeflate = !kIsWeb && deflated.length < data.length;
    final Uint8List payload = useDeflate ? deflated : data;
    final Map<String, Object?> entries = <String, Object?>{...extra};
    if (useDeflate) entries["Filter"] = const UPdfName("FlateDecode");
    entries["Length"] = payload.length;
    return UPdfStream(dict: UPdfDict(entries), rawOffset: 0, rawLength: payload.length, rawBytes: payload);
  }

  Future<Object?> _copyValue(UPdfDocument source, Object? value, Map<int, int> map, int depth) async {
    if (depth > 48) return null;
    if (value is UPdfRef) {
      final int? mapped = map[value.number];
      if (mapped != null) return UPdfRef(mapped, 0);
      final int number = allocate();
      map[value.number] = number;
      final Object? resolved = await source.resolve(value);
      _objects[number] = await _copyValue(source, resolved, map, depth + 1);
      return UPdfRef(number, 0);
    }
    if (value is List<Object?>) {
      final List<Object?> out = <Object?>[];
      for (final Object? entry in value) {
        out.add(await _copyValue(source, entry, map, depth + 1));
      }
      return out;
    }
    if (value is UPdfStream) {
      final Uint8List raw = await source.rawStreamBytes(value);
      final UPdfDict dict = value.dict.copy();
      dict.entries.remove("Length");
      final Map<String, Object?> entries = <String, Object?>{};
      for (final String key in dict.keys) {
        entries[key] = await _copyValue(source, dict[key], map, depth + 1);
      }
      entries["Length"] = raw.length;
      return UPdfStream(dict: UPdfDict(entries), rawOffset: 0, rawLength: raw.length, rawBytes: raw);
    }
    if (value is UPdfDict) {
      final Map<String, Object?> entries = <String, Object?>{};
      for (final String key in value.keys) {
        entries[key] = await _copyValue(source, value[key], map, depth + 1);
      }
      return UPdfDict(entries);
    }
    return value;
  }

  Future<Object?> copyForeign(UPdfDocument source, Object? value, Map<int, int> map) => _copyValue(source, value, map, 0);

  UPdfStream streamFor(Uint8List data, {Map<String, Object?> extra = const <String, Object?>{}}) => _stream(data, extra: extra);

  void addComposedPage(Size size, String content, Map<String, Object?> xobjects) {
    final int contents = allocate();
    _objects[contents] = _stream(Uint8List.fromList(utf8.encode(content)));
    final int number = allocate();
    _objects[number] = UPdfDict(<String, Object?>{
      "Type": const UPdfName("Page"),
      "MediaBox": <Object?>[0, 0, size.width, size.height],
      "Resources": UPdfDict(<String, Object?>{"XObject": UPdfDict(xobjects)}),
      "Contents": UPdfRef(contents, 0),
    });
    _pages.add(number);
  }

  Uint8List build({UDocMetadata? metadata}) {
    final int pagesNumber = allocate();
    final int catalogNumber = allocate();
    for (final int page in _pages) {
      final Object? dict = _objects[page];
      if (dict is UPdfDict) dict["Parent"] = UPdfRef(pagesNumber, 0);
    }
    _objects[pagesNumber] = UPdfDict(<String, Object?>{
      "Type": const UPdfName("Pages"),
      "Kids": _pages.map((int number) => UPdfRef(number, 0)).toList(),
      "Count": _pages.length,
    });
    _objects[catalogNumber] = UPdfDict(<String, Object?>{"Type": const UPdfName("Catalog"), "Pages": UPdfRef(pagesNumber, 0)});
    int? infoNumber;
    if (metadata != null) {
      infoNumber = allocate();
      final Map<String, Object?> info = <String, Object?>{"Producer": UPdfEdit.textString("u_doc"), "ModDate": UPdfEdit.dateString(DateTime.now())};
      if (metadata.title != null && metadata.title!.isNotEmpty) info["Title"] = UPdfEdit.textString(metadata.title!);
      if (metadata.author != null && metadata.author!.isNotEmpty) info["Author"] = UPdfEdit.textString(metadata.author!);
      if (metadata.subject != null && metadata.subject!.isNotEmpty) info["Subject"] = UPdfEdit.textString(metadata.subject!);
      if (metadata.keywords != null && metadata.keywords!.isNotEmpty) info["Keywords"] = UPdfEdit.textString(metadata.keywords!);
      _objects[infoNumber] = UPdfDict(info);
    }
    final BytesBuilder out = BytesBuilder(copy: false);
    out.add("%PDF-1.7\n%âãÏÓ\n".codeUnits);
    final Map<int, int> offsets = <int, int>{};
    final List<int> numbers = _objects.keys.toList()..sort();
    for (final int number in numbers) {
      offsets[number] = out.length;
      out.add("$number 0 obj\n".codeUnits);
      UPdfSerializer.write(out, _objects[number]);
      out.add("\nendobj\n".codeUnits);
    }
    final int xrefOffset = out.length;
    final int size = numbers.isEmpty ? 1 : numbers.last + 1;
    out.add("xref\n0 $size\n".codeUnits);
    out.add("0000000000 65535 f \n".codeUnits);
    for (int number = 1; number < size; number++) {
      final int? offset = offsets[number];
      if (offset == null) {
        out.add("0000000000 65535 f \n".codeUnits);
      } else {
        out.add("${offset.toString().padLeft(10, "0")} 00000 n \n".codeUnits);
      }
    }
    out.add("trailer\n".codeUnits);
    UPdfSerializer.write(
      out,
      UPdfDict(<String, Object?>{
        "Size": size,
        "Root": UPdfRef(catalogNumber, 0),
        if (infoNumber != null) "Info": UPdfRef(infoNumber, 0),
      }),
    );
    out.add("\nstartxref\n$xrefOffset\n%%EOF\n".codeUnits);
    return out.takeBytes();
  }

  Future<bool> writeTo(String path, {UDocMetadata? metadata}) async {
    if (kIsWeb) return false;
    try {
      await File(path).writeAsBytes(build(metadata: metadata), flush: true);
      return true;
    } on Object {
      return false;
    }
  }
}

extension UPdfEditDocumentOps on UPdfEdit {
  Future<int> flattenAnnotations({List<int>? pages, bool widgetsOnly = false}) async {
    int flattened = 0;
    final List<int> targets = pages ?? List<int>.generate(document.pageCount, (int index) => index);
    for (final int index in targets) {
      final UPdfPage? page = await document.page(index);
      final UPdfDict? mutable = await mutablePage(index);
      if (page == null || mutable == null) continue;
      final Object? list = await document.resolve(mutable["Annots"]);
      if (list is! List<Object?>) continue;
      final List<Object?> kept = <Object?>[];
      final Map<String, Object?> stamps = <String, Object?>{};
      final StringBuffer content = StringBuffer();
      int counter = 0;
      for (final Object? entry in list) {
        final Object? annotation = await document.resolve(entry);
        if (annotation is! UPdfDict) continue;
        final Object? subtype = annotation["Subtype"];
        final String type = subtype is UPdfName ? subtype.value : "";
        if (type == "Link" || type == "Popup") {
          kept.add(entry);
          continue;
        }
        if (widgetsOnly && type != "Widget") {
          kept.add(entry);
          continue;
        }
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
        final Object? bboxObject = await document.resolve(normal.dict["BBox"]);
        final Rect bbox = uPdfRectFromArray(bboxObject is List<Object?> ? bboxObject : null, fallback: rect);
        final double scaleX = bbox.width <= 0 ? 1 : rect.width / bbox.width;
        final double scaleY = bbox.height <= 0 ? 1 : rect.height / bbox.height;
        final String name = "UFlat$counter";
        counter++;
        final int number = allocate();
        this.put(number, normal);
        stamps[name] = UPdfRef(number, 0);
        content.writeln(
          "q ${UPdfSerializer.number(scaleX)} 0 0 ${UPdfSerializer.number(scaleY)} "
          "${UPdfSerializer.number(rect.left - bbox.left * scaleX)} ${UPdfSerializer.number(rect.top - bbox.top * scaleY)} cm /$name Do Q",
        );
        flattened++;
      }
      if (stamps.isEmpty) continue;
      mutable["Annots"] = kept;
      await appendContent(index, content.toString(), extraResources: <String, Object?>{"XObject": UPdfDict(stamps)});
    }
    if (!widgetsOnly || flattened == 0) return flattened;
    final Object? catalogRef = document.xref.trailer?["Root"];
    if (catalogRef is UPdfRef) {
      final Object? catalog = await current(catalogRef);
      if (catalog is UPdfDict) {
        final UPdfDict copy = catalog.copy();
        copy.entries.remove("AcroForm");
        this.put(catalogRef.number, copy);
      }
    }
    return flattened;
  }

  Future<String> exportXfdf() async {
    final List<UPdfFormField> fields = await formFields();
    final StringBuffer buffer = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>\n<xfdf xmlns="http://ns.adobe.com/xfdf/">\n  <fields>\n');
    for (final UPdfFormField field in fields) {
      if (field.name.isEmpty) continue;
      final String value = field.displayValue.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
      buffer.writeln('    <field name="${field.name.replaceAll('"', "")}">');
      buffer.writeln("      <value>$value</value>");
      buffer.writeln("    </field>");
    }
    buffer.writeln("  </fields>\n</xfdf>");
    return buffer.toString();
  }

  Future<int> importXfdf(String xml) async {
    final List<UPdfFormField> fields = await formFields();
    final Map<String, String> values = <String, String>{};
    for (final RegExpMatch match in RegExp('<field[^>]*name="([^"]*)"[^>]*>(.*?)</field>', dotAll: true).allMatches(xml)) {
      final String name = match.group(1) ?? "";
      final String body = match.group(2) ?? "";
      final RegExpMatch? value = RegExp("<value>(.*?)</value>", dotAll: true).firstMatch(body);
      if (name.isEmpty) continue;
      values[name] = (value?.group(1) ?? "").replaceAll("&lt;", "<").replaceAll("&gt;", ">").replaceAll("&amp;", "&");
    }
    int applied = 0;
    for (final UPdfFormField field in fields) {
      final String? value = values[field.name];
      if (value == null) continue;
      if (await setFieldValue(field, field.kind == UDocFieldKind.checkBox || field.kind == UDocFieldKind.radioButton ? value != "Off" && value.isNotEmpty : value)) applied++;
    }
    return applied;
  }

  Future<int> resetForm() async {
    final List<UPdfFormField> fields = await formFields();
    int reset = 0;
    for (final UPdfFormField field in fields) {
      if (field.objectNumber < 0) continue;
      final Object? widget = await current(UPdfRef(field.objectNumber, 0));
      if (widget is! UPdfDict) continue;
      final UPdfDict copy = widget.copy();
      final Object? fallback = copy["DV"];
      if (fallback == null) {
        copy.entries.remove("V");
        copy.entries.remove("AS");
      } else {
        copy["V"] = fallback;
        if (fallback is UPdfName) copy["AS"] = fallback;
      }
      copy.entries.remove("AP");
      this.put(field.objectNumber, copy);
      reset++;
    }
    return reset;
  }

  Future<List<String>> missingRequiredFields() async {
    final List<UPdfFormField> fields = await formFields();
    final List<String> missing = <String>[];
    for (final UPdfFormField field in fields) {
      if (!field.required || field.readOnly) continue;
      if (field.displayValue.trim().isEmpty || field.displayValue == "Off") missing.add(field.name);
    }
    return missing;
  }

  Future<Uint8List?> composeCurrent({List<int>? pages, UDocMetadata? metadata}) async {
    final UPdfComposer composer = UPdfComposer();
    final List<int> targets = pages ?? List<int>.generate(document.pageCount, (int index) => index);
    for (final int index in targets) {
      await composer.addPage(document, index);
    }
    if (composer.pageCount == 0) return null;
    return composer.build(metadata: metadata ?? await document.metadata());
  }

  Future<bool> saveOptimizedTo(String path, {List<int>? pages, UDocMetadata? metadata}) async {
    if (kIsWeb) return false;
    final Uint8List? bytes = await composeCurrent(pages: pages, metadata: metadata);
    if (bytes == null) return false;
    try {
      await File(path).writeAsBytes(bytes, flush: true);
      return true;
    } on Object {
      return false;
    }
  }
}

abstract class UPdfOps {
  static Future<Uint8List?> merge(List<UPdfDocument> documents, {UDocMetadata? metadata}) async {
    final UPdfComposer composer = UPdfComposer();
    for (final UPdfDocument document in documents) {
      for (int index = 0; index < document.pageCount; index++) {
        await composer.addPage(document, index);
      }
    }
    if (composer.pageCount == 0) return null;
    return composer.build(metadata: metadata);
  }

  static Future<Uint8List?> mergeFiles(List<String> paths, {UDocMetadata? metadata}) async {
    final List<UPdfDocument> documents = <UPdfDocument>[];
    try {
      for (final String path in paths) {
        documents.add(await UPdfDocument.open(path: path));
      }
      return await merge(documents, metadata: metadata);
    } on Object {
      return null;
    } finally {
      for (final UPdfDocument document in documents) {
        await document.close();
      }
    }
  }

  static Future<Uint8List?> extractPages(UPdfDocument document, List<int> indices, {UDocMetadata? metadata}) async {
    final UPdfComposer composer = UPdfComposer();
    for (final int index in indices) {
      await composer.addPage(document, index);
    }
    if (composer.pageCount == 0) return null;
    return composer.build(metadata: metadata);
  }

  static Future<List<Uint8List>> split(UPdfDocument document, {int pagesPerFile = 1}) async {
    final List<Uint8List> out = <Uint8List>[];
    final int step = pagesPerFile < 1 ? 1 : pagesPerFile;
    for (int start = 0; start < document.pageCount; start += step) {
      final List<int> indices = <int>[];
      for (int i = start; i < start + step && i < document.pageCount; i++) {
        indices.add(i);
      }
      final Uint8List? bytes = await extractPages(document, indices);
      if (bytes != null) out.add(bytes);
    }
    return out;
  }

  static Future<Uint8List?> fromImages(List<Uint8List> images, {Size? pageSize, double margin = 0}) async {
    final UPdfComposer composer = UPdfComposer();
    for (final Uint8List image in images) {
      await composer.addImagePage(image, size: pageSize, margin: margin);
    }
    if (composer.pageCount == 0) return null;
    return composer.build();
  }

  static Future<Uint8List?> nUp(UPdfDocument document, {int columns = 2, int rows = 1, Size sheet = const Size(841.89, 595.28), double gap = 8}) async {
    if (columns < 1 || rows < 1) return null;
    final UPdfComposer composer = UPdfComposer();
    final int perSheet = columns * rows;
    for (int start = 0; start < document.pageCount; start += perSheet) {
      final List<int> indices = <int>[];
      for (int i = start; i < start + perSheet && i < document.pageCount; i++) {
        indices.add(i);
      }
      await _composeSheet(composer, document, indices, columns, rows, sheet, gap);
    }
    if (composer.pageCount == 0) return null;
    return composer.build();
  }

  static Future<void> _composeSheet(UPdfComposer composer, UPdfDocument document, List<int> indices, int columns, int rows, Size sheet, double gap) async {
    final Map<String, Object?> xobjects = <String, Object?>{};
    final StringBuffer content = StringBuffer();
    final double cellWidth = (sheet.width - gap * (columns + 1)) / columns;
    final double cellHeight = (sheet.height - gap * (rows + 1)) / rows;
    for (int i = 0; i < indices.length; i++) {
      final UPdfPage? page = await document.page(indices[i]);
      if (page == null) continue;
      final Uint8List raw = await document.pageContent(page);
      final int number = composer.allocate();
      final Map<int, int> map = <int, int>{};
      final Object? copiedResources = await composer.copyForeign(document, page.resources, map);
      composer.put(
        number,
        composer.streamFor(
          raw,
          extra: <String, Object?>{
            "Type": const UPdfName("XObject"),
            "Subtype": const UPdfName("Form"),
            "FormType": 1,
            "BBox": <Object?>[page.box.left, page.box.top, page.box.right, page.box.bottom],
            if (copiedResources != null) "Resources": copiedResources,
          },
        ),
      );
      final String name = "UP$i";
      xobjects[name] = UPdfRef(number, 0);
      final int column = i % columns;
      final int row = i ~/ columns;
      final double scale = min(cellWidth / page.box.width, cellHeight / page.box.height);
      final double x = gap + column * (cellWidth + gap);
      final double y = sheet.height - gap - (row + 1) * cellHeight - row * gap;
      content.writeln("q ${UPdfSerializer.number(scale)} 0 0 ${UPdfSerializer.number(scale)} ${UPdfSerializer.number(x)} ${UPdfSerializer.number(y)} cm /$name Do Q");
    }
    composer.addComposedPage(sheet, content.toString(), xobjects);
  }
}

abstract class UPdfExport {
  static Future<Uint8List?> pageImage(UPdfController controller, int pageIndex, {double dpi = 150, bool png = true}) async {
    try {
      final ui.Picture? picture = await controller.renderPage(pageIndex);
      if (picture == null) return null;
      final Size size = controller.pageInfo(pageIndex).rotatedSize;
      final double scale = (dpi <= 0 ? 150 : dpi) / 72;
      final int width = (size.width * scale).round().clamp(1, 10000);
      final int height = (size.height * scale).round().clamp(1, 10000);
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = const Color(0xFFFFFFFF));
      canvas.scale(scale);
      canvas.drawPicture(picture);
      final ui.Picture scaled = recorder.endRecording();
      final ui.Image image = await scaled.toImage(width, height);
      scaled.dispose();
      final ByteData? data = await image.toByteData(format: png ? ui.ImageByteFormat.png : ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data?.buffer.asUint8List();
    } on Object {
      return null;
    }
  }

  static Future<List<Uint8List>> pageImages(UPdfController controller, {List<int>? pages, double dpi = 150}) async {
    final List<int> targets = pages ?? List<int>.generate(controller.pageCount, (int index) => index);
    final List<Uint8List> out = <Uint8List>[];
    for (final int index in targets) {
      final Uint8List? bytes = await pageImage(controller, index, dpi: dpi);
      if (bytes != null) out.add(bytes);
    }
    return out;
  }

  static Future<Uint8List?> printablePdf(UPdfController controller, {List<int>? pages, double dpi = 150}) async {
    final List<int> targets = pages ?? List<int>.generate(controller.pageCount, (int index) => index);
    final UPdfComposer composer = UPdfComposer();
    for (final int index in targets) {
      final Uint8List? image = await pageImage(controller, index, dpi: dpi);
      if (image == null) continue;
      final Size size = controller.pageInfo(index).rotatedSize;
      await composer.addImagePage(image, size: size);
    }
    if (composer.pageCount == 0) return null;
    return composer.build(metadata: controller.value.metadata);
  }

  static Future<bool> sharePrintable(UPdfController controller, {List<int>? pages, double dpi = 150, String fileName = "print.pdf"}) async {
    final Uint8List? bytes = await printablePdf(controller, pages: pages, dpi: dpi);
    if (bytes == null) return false;
    await UShare.bytes(bytes: bytes, fileName: fileName, mimeType: "application/pdf");
    return true;
  }

  static Future<bool> shareImages(UPdfController controller, {List<int>? pages, double dpi = 150}) async {
    final List<Uint8List> images = await pageImages(controller, pages: pages, dpi: dpi);
    if (images.isEmpty) return false;
    if (images.length == 1) {
      await UShare.bytes(bytes: images.first, fileName: "page.png", mimeType: "image/png");
      return true;
    }
    if (kIsWeb) return false;
    final Directory directory = await getTemporaryDirectory();
    final List<String> paths = <String>[];
    for (int i = 0; i < images.length; i++) {
      final File file = File("${directory.path}${Platform.pathSeparator}u_doc_page_${i + 1}.png");
      await file.writeAsBytes(images[i], flush: true);
      paths.add(file.path);
    }
    await UShare.files(paths: paths);
    return true;
  }
}

extension UPdfEditAnnotations on UPdfEdit {
  Future<UPdfAnnotationSpec?> specOf(int pageIndex, int objectNumber) async {
    final Object? annotation = await current(UPdfRef(objectNumber, 0));
    if (annotation is! UPdfDict) return null;
    final Object? rectObject = await document.resolve(annotation["Rect"]);
    final Rect rect = uPdfRectFromArray(rectObject is List<Object?> ? rectObject : null, fallback: Rect.zero);
    final Object? subtype = annotation["Subtype"];
    final String type = subtype is UPdfName ? subtype.value : "";
    final Object? contents = await document.resolve(annotation["Contents"]);
    final Object? author = await document.resolve(annotation["T"]);
    final Object? opacity = await document.resolve(annotation["CA"]);
    final Object? colorObject = await document.resolve(annotation["C"]);
    Color color = const Color(0xFFFFEB3B);
    if (colorObject is List<Object?> && colorObject.length >= 3) {
      final List<double> rgb = colorObject.whereType<num>().map((num value) => value.toDouble()).toList();
      if (rgb.length >= 3) color = Color.fromARGB(255, (rgb[0] * 255).round().clamp(0, 255), (rgb[1] * 255).round().clamp(0, 255), (rgb[2] * 255).round().clamp(0, 255));
    }
    final List<Rect> quads = <Rect>[];
    final Object? quadObject = await document.resolve(annotation["QuadPoints"]);
    if (quadObject is List<Object?>) {
      final List<double> numbers = quadObject.whereType<num>().map((num value) => value.toDouble()).toList();
      for (int i = 0; i + 7 < numbers.length; i += 8) {
        quads.add(Rect.fromLTRB(min(numbers[i], numbers[i + 2]), min(numbers[i + 1], numbers[i + 5]), max(numbers[i], numbers[i + 2]), max(numbers[i + 1], numbers[i + 5])));
      }
    }
    final List<List<Offset>> ink = <List<Offset>>[];
    final Object? inkObject = await document.resolve(annotation["InkList"]);
    if (inkObject is List<Object?>) {
      for (final Object? entry in inkObject) {
        final Object? path = await document.resolve(entry);
        if (path is! List<Object?>) continue;
        final List<double> numbers = path.whereType<num>().map((num value) => value.toDouble()).toList();
        final List<Offset> points = <Offset>[];
        for (int i = 0; i + 1 < numbers.length; i += 2) {
          points.add(Offset(numbers[i], numbers[i + 1]));
        }
        if (points.isNotEmpty) ink.add(points);
      }
    }
    return UPdfAnnotationSpec(
      style: _styleFromSubtype(type),
      rect: rect,
      quads: quads,
      inkPaths: ink,
      color: color,
      opacity: opacity is num ? opacity.toDouble() : 1,
      contents: contents is UPdfString ? contents.text : "",
      author: author is UPdfString ? author.text : "",
      rtl: contents is UPdfString && UDocText.isRtl(contents.text),
    );
  }

  UPdfAnnotationStyle _styleFromSubtype(String subtype) {
    switch (subtype) {
      case "Underline":
        return UPdfAnnotationStyle.underline;
      case "StrikeOut":
        return UPdfAnnotationStyle.strikeOut;
      case "Squiggly":
        return UPdfAnnotationStyle.squiggly;
      case "Ink":
        return UPdfAnnotationStyle.ink;
      case "Text":
        return UPdfAnnotationStyle.note;
      case "FreeText":
        return UPdfAnnotationStyle.freeText;
      case "Square":
        return UPdfAnnotationStyle.square;
      case "Circle":
        return UPdfAnnotationStyle.circle;
      case "Line":
        return UPdfAnnotationStyle.line;
      case "Stamp":
        return UPdfAnnotationStyle.stamp;
      default:
        return UPdfAnnotationStyle.highlight;
    }
  }

  Future<bool> updateAnnotation(
    int pageIndex,
    int objectNumber, {
    Rect? rect,
    Color? color,
    double? opacity,
    String? contents,
    double? borderWidth,
    double? fontSize,
  }) async {
    final Object? existing = await current(UPdfRef(objectNumber, 0));
    if (existing is! UPdfDict) return false;
    final UPdfAnnotationSpec? previous = await specOf(pageIndex, objectNumber);
    if (previous == null) return false;
    final Rect target = rect ?? previous.rect;
    final Offset shift = Offset(target.left - previous.rect.left, target.top - previous.rect.top);
    final double scaleX = previous.rect.width <= 0 ? 1 : target.width / previous.rect.width;
    final double scaleY = previous.rect.height <= 0 ? 1 : target.height / previous.rect.height;
    final UPdfAnnotationSpec next = UPdfAnnotationSpec(
      style: previous.style,
      rect: target,
      quads: previous.quads
          .map(
            (Rect quad) => Rect.fromLTRB(
              target.left + (quad.left - previous.rect.left) * scaleX,
              target.top + (quad.top - previous.rect.top) * scaleY,
              target.left + (quad.right - previous.rect.left) * scaleX,
              target.top + (quad.bottom - previous.rect.top) * scaleY,
            ),
          )
          .toList(),
      inkPaths: previous.inkPaths
          .map((List<Offset> path) => path.map((Offset point) => Offset(target.left + (point.dx - previous.rect.left) * scaleX, target.top + (point.dy - previous.rect.top) * scaleY)).toList())
          .toList(),
      color: color ?? previous.color,
      borderColor: color ?? previous.borderColor,
      opacity: opacity ?? previous.opacity,
      borderWidth: borderWidth ?? previous.borderWidth,
      contents: contents ?? previous.contents,
      author: previous.author,
      fontSize: fontSize ?? previous.fontSize,
      rtl: UDocText.isRtl(contents ?? previous.contents),
    );
    final UPdfDict updated = existing.copy();
    updated["Rect"] = <Object?>[next.rect.left, next.rect.top, next.rect.right, next.rect.bottom];
    updated["M"] = UPdfEdit.dateString(DateTime.now());
    updated["C"] = <Object?>[next.color.r, next.color.g, next.color.b];
    updated["CA"] = next.opacity;
    if (contents != null) updated["Contents"] = UPdfEdit.textString(contents);
    if (next.quads.isNotEmpty) {
      final List<Object?> quadPoints = <Object?>[];
      for (final Rect quad in next.quads) {
        quadPoints.addAll(<Object?>[quad.left, quad.bottom, quad.right, quad.bottom, quad.left, quad.top, quad.right, quad.top]);
      }
      updated["QuadPoints"] = quadPoints;
    }
    if (next.inkPaths.isNotEmpty) {
      final List<Object?> inkList = <Object?>[];
      for (final List<Offset> path in next.inkPaths) {
        final List<Object?> points = <Object?>[];
        for (final Offset point in path) {
          points.addAll(<Object?>[point.dx, point.dy]);
        }
        inkList.add(points);
      }
      updated["InkList"] = inkList;
    }
    final UPdfStream? appearance = await rebuildAppearance(next);
    if (appearance != null) {
      final int number = allocate();
      this.put(number, appearance);
      updated["AP"] = UPdfDict(<String, Object?>{"N": UPdfRef(number, 0)});
    }
    this.put(objectNumber, updated);
    if (shift != Offset.zero || scaleX != 1 || scaleY != 1) return true;
    return true;
  }
}
