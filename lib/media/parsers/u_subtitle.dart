import "package:u/utilities.dart";

class USubtitleSpan {
  const USubtitleSpan(this.text, {this.bold = false, this.italic = false, this.underline = false, this.strikethrough = false, this.color, this.fontScale});

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final Color? color;
  final double? fontScale;

  bool get isPlain => !bold && !italic && !underline && !strikethrough && color == null && fontScale == null;
}

class USubtitleStyle {
  const USubtitleStyle({
    required this.name,
    this.fontName,
    this.fontSize,
    this.primaryColor,
    this.outlineColor,
    this.backColor,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.alignment = 2,
    this.marginLeft = 0,
    this.marginRight = 0,
    this.marginVertical = 0,
    this.outline = 0,
    this.shadow = 0,
  });

  final String name;
  final String? fontName;
  final double? fontSize;
  final Color? primaryColor;
  final Color? outlineColor;
  final Color? backColor;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final int alignment;
  final int marginLeft;
  final int marginRight;
  final int marginVertical;
  final double outline;
  final double shadow;
}

class USubtitleCue {
  const USubtitleCue({required this.start, required this.end, required this.spans, required this.text, this.alignment = 2, this.position, this.layer = 0, this.styleName});

  final Duration start;
  final Duration end;
  final List<USubtitleSpan> spans;
  final String text;
  final int alignment;
  final Offset? position;
  final int layer;
  final String? styleName;

  bool get isRtl => UBidi.isRtl(text);

  bool contains(Duration time) => time >= start && time < end;
}

class USubtitleData {
  const USubtitleData({required this.format, required this.cues, this.styles = const <String, USubtitleStyle>{}, this.language, this.label, this.playResX = 0, this.playResY = 0, this.encoding = "utf-8"});

  final USubtitleFormat format;
  final List<USubtitleCue> cues;
  final Map<String, USubtitleStyle> styles;
  final String? language;
  final String? label;
  final int playResX;
  final int playResY;
  final String encoding;

  static const USubtitleData empty = USubtitleData(format: USubtitleFormat.srt, cues: <USubtitleCue>[]);

  bool get isEmpty => cues.isEmpty;

  Duration get lastEnd => cues.isEmpty ? Duration.zero : cues.last.end;

  List<USubtitleCue> activeAt(Duration time, {Duration delay = Duration.zero, double scale = 1}) {
    final Duration target = _adjust(time, delay, scale);
    final int index = _floorIndex(target);
    if (index < 0) return const <USubtitleCue>[];
    final List<USubtitleCue> result = <USubtitleCue>[];
    for (int i = index; i >= 0 && i > index - 12; i--) {
      final USubtitleCue cue = cues[i];
      if (cue.contains(target)) result.add(cue);
    }
    if (result.length > 1) result.sort((USubtitleCue a, USubtitleCue b) => a.layer.compareTo(b.layer));
    return result;
  }

  Duration _adjust(Duration time, Duration delay, double scale) {
    final int ms = ((time.inMilliseconds / (scale == 0 ? 1 : scale)) - delay.inMilliseconds).round();
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  int _floorIndex(Duration target) {
    int low = 0;
    int high = cues.length - 1;
    int found = -1;
    while (low <= high) {
      final int mid = (low + high) >> 1;
      if (cues[mid].start <= target) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }
}

abstract final class USubtitleParser {
  static USubtitleData parseBytes(Uint8List bytes, {USubtitleFormat? format, String? encoding, String? language, String? label, double fps = 23.976}) {
    final UDecodedText decoded = UTextDecoder.decode(bytes, forced: encoding);
    final USubtitleData data = parse(decoded.text, format: format, language: language, label: label, fps: fps);
    return USubtitleData(
      format: data.format,
      cues: data.cues,
      styles: data.styles,
      language: data.language,
      label: data.label,
      playResX: data.playResX,
      playResY: data.playResY,
      encoding: decoded.encoding,
    );
  }

  static USubtitleData parse(String content, {USubtitleFormat? format, String? language, String? label, double fps = 23.976}) {
    final String normalized = content.replaceAll("\r\n", "\n").replaceAll("\r", "\n");
    final USubtitleFormat resolved = format ?? detectFormat(normalized);
    switch (resolved) {
      case USubtitleFormat.vtt:
        return _parseVtt(normalized, language, label);
      case USubtitleFormat.ass:
      case USubtitleFormat.ssa:
        return _parseAss(normalized, language, label);
      case USubtitleFormat.lrc:
        return _parseLrc(normalized, language, label);
      case USubtitleFormat.sub:
        return _parseMicroDvd(normalized, language, label, fps);
      case USubtitleFormat.srt:
      case USubtitleFormat.ttml:
      case USubtitleFormat.pgs:
      case USubtitleFormat.cea608:
      case USubtitleFormat.cea708:
        return _parseSrt(normalized, language, label);
    }
  }

  static USubtitleFormat detectFormat(String content) {
    final String head = content.length > 4096 ? content.substring(0, 4096) : content;
    if (head.startsWith("WEBVTT")) return USubtitleFormat.vtt;
    if (head.contains("[Script Info]") || head.contains("[V4+ Styles]") || head.contains("[V4 Styles]")) return USubtitleFormat.ass;
    if (RegExp(r"^\{\d+\}\{\d+\}", multiLine: true).hasMatch(head)) return USubtitleFormat.sub;
    if (RegExp(r"^\[\d{1,3}:\d{2}([.:]\d{1,3})?\]", multiLine: true).hasMatch(head)) return USubtitleFormat.lrc;
    return USubtitleFormat.srt;
  }

  static Duration _srtTime(String value) {
    final RegExpMatch? m = RegExp(r"(\d{1,3}):(\d{1,2}):(\d{1,2})[,.](\d{1,3})").firstMatch(value);
    if (m == null) return Duration.zero;
    return Duration(
      hours: int.parse(m.group(1)!),
      minutes: int.parse(m.group(2)!),
      seconds: int.parse(m.group(3)!),
      milliseconds: int.parse(m.group(4)!.padRight(3, "0")),
    );
  }

  static Duration _vttTime(String value) {
    final RegExpMatch? full = RegExp(r"(\d{1,3}):(\d{2}):(\d{2})[.,](\d{1,3})").firstMatch(value);
    if (full != null) {
      return Duration(
        hours: int.parse(full.group(1)!),
        minutes: int.parse(full.group(2)!),
        seconds: int.parse(full.group(3)!),
        milliseconds: int.parse(full.group(4)!.padRight(3, "0")),
      );
    }
    final RegExpMatch? short = RegExp(r"(\d{1,3}):(\d{2})[.,](\d{1,3})").firstMatch(value);
    if (short == null) return Duration.zero;
    return Duration(minutes: int.parse(short.group(1)!), seconds: int.parse(short.group(2)!), milliseconds: int.parse(short.group(3)!.padRight(3, "0")));
  }

  static Duration _assTime(String value) {
    final RegExpMatch? m = RegExp(r"(\d{1,2}):(\d{2}):(\d{2})[.,](\d{1,2})").firstMatch(value);
    if (m == null) return Duration.zero;
    return Duration(
      hours: int.parse(m.group(1)!),
      minutes: int.parse(m.group(2)!),
      seconds: int.parse(m.group(3)!),
      milliseconds: int.parse(m.group(4)!.padRight(2, "0")) * 10,
    );
  }

  static USubtitleData _parseSrt(String content, String? language, String? label) {
    final List<USubtitleCue> cues = <USubtitleCue>[];
    final List<String> blocks = content.split(RegExp("\n{2,}"));
    for (final String block in blocks) {
      final List<String> lines = block.split("\n").where((String l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      int cursor = 0;
      if (!lines[cursor].contains("-->")) cursor++;
      if (cursor >= lines.length || !lines[cursor].contains("-->")) continue;
      final List<String> parts = lines[cursor].split("-->");
      if (parts.length < 2) continue;
      final Duration start = _srtTime(parts[0]);
      final Duration end = _srtTime(parts[1]);
      final String body = lines.sublist(cursor + 1).join("\n");
      if (body.trim().isEmpty) continue;
      cues.add(_cueFromMarkup(body, start, end));
    }
    cues.sort((USubtitleCue a, USubtitleCue b) => a.start.compareTo(b.start));
    return USubtitleData(format: USubtitleFormat.srt, cues: cues, language: language, label: label);
  }

  static USubtitleData _parseVtt(String content, String? language, String? label) {
    final List<USubtitleCue> cues = <USubtitleCue>[];
    final List<String> blocks = content.split(RegExp("\n{2,}"));
    for (final String block in blocks) {
      if (block.startsWith("WEBVTT") || block.startsWith("NOTE") || block.startsWith("STYLE") || block.startsWith("REGION")) continue;
      final List<String> lines = block.split("\n").where((String l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      int cursor = 0;
      if (!lines[cursor].contains("-->")) cursor++;
      if (cursor >= lines.length || !lines[cursor].contains("-->")) continue;
      final String timeLine = lines[cursor];
      final List<String> parts = timeLine.split("-->");
      final Duration start = _vttTime(parts[0]);
      final Duration end = _vttTime(parts[1]);
      final int alignment = _vttAlignment(parts.length > 1 ? parts[1] : "");
      final String body = lines.sublist(cursor + 1).join("\n");
      if (body.trim().isEmpty) continue;
      final USubtitleCue base = _cueFromMarkup(body, start, end);
      cues.add(USubtitleCue(start: base.start, end: base.end, spans: base.spans, text: base.text, alignment: alignment));
    }
    cues.sort((USubtitleCue a, USubtitleCue b) => a.start.compareTo(b.start));
    return USubtitleData(format: USubtitleFormat.vtt, cues: cues, language: language, label: label);
  }

  static int _vttAlignment(String settings) {
    if (settings.contains("line:0") || settings.contains("line:5%") || settings.contains("line:10%")) return 8;
    if (settings.contains("align:left") || settings.contains("align:start")) return 1;
    if (settings.contains("align:right") || settings.contains("align:end")) return 3;
    return 2;
  }

  static USubtitleData _parseLrc(String content, String? language, String? label) {
    final List<USubtitleCue> cues = <USubtitleCue>[];
    final RegExp stamp = RegExp(r"\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]");
    int offsetMs = 0;
    final List<_LrcLine> collected = <_LrcLine>[];
    for (final String line in content.split("\n")) {
      final RegExpMatch? offsetMatch = RegExp(r"^\[offset:\s*([+-]?\d+)\]").firstMatch(line.trim());
      if (offsetMatch != null) {
        offsetMs = int.tryParse(offsetMatch.group(1)!) ?? 0;
        continue;
      }
      final Iterable<RegExpMatch> stamps = stamp.allMatches(line);
      if (stamps.isEmpty) continue;
      final String text = line.substring(stamps.last.end).trim();
      for (final RegExpMatch m in stamps) {
        final String fraction = m.group(3) ?? "0";
        final int ms = fraction.length == 1 ? int.parse(fraction) * 100 : (fraction.length == 2 ? int.parse(fraction) * 10 : int.parse(fraction.padRight(3, "0")));
        collected.add(_LrcLine(Duration(minutes: int.parse(m.group(1)!), seconds: int.parse(m.group(2)!), milliseconds: ms + offsetMs), text));
      }
    }
    collected.sort((_LrcLine a, _LrcLine b) => a.time.compareTo(b.time));
    for (int i = 0; i < collected.length; i++) {
      final _LrcLine line = collected[i];
      if (line.text.isEmpty) continue;
      final Duration end = i + 1 < collected.length ? collected[i + 1].time : line.time + const Duration(seconds: 5);
      cues.add(USubtitleCue(start: line.time, end: end, spans: <USubtitleSpan>[USubtitleSpan(line.text)], text: line.text));
    }
    return USubtitleData(format: USubtitleFormat.lrc, cues: cues, language: language, label: label);
  }

  static USubtitleData _parseMicroDvd(String content, String? language, String? label, double fps) {
    final List<USubtitleCue> cues = <USubtitleCue>[];
    final RegExp pattern = RegExp(r"^\{(\d+)\}\{(\d+)\}(.*)$");
    final double rate = fps <= 0 ? 23.976 : fps;
    for (final String line in content.split("\n")) {
      final RegExpMatch? m = pattern.firstMatch(line.trim());
      if (m == null) continue;
      final String body = m.group(3)!.replaceAll("|", "\n").replaceAll(RegExp(r"\{[^}]*\}"), "").trim();
      if (body.isEmpty) continue;
      final Duration start = Duration(milliseconds: (int.parse(m.group(1)!) / rate * 1000).round());
      final Duration end = Duration(milliseconds: (int.parse(m.group(2)!) / rate * 1000).round());
      cues.add(USubtitleCue(start: start, end: end, spans: <USubtitleSpan>[USubtitleSpan(body)], text: body));
    }
    return USubtitleData(format: USubtitleFormat.sub, cues: cues, language: language, label: label);
  }

  static USubtitleCue _cueFromMarkup(String body, Duration start, Duration end) {
    final List<USubtitleSpan> spans = _parseMarkup(body);
    final String plain = spans.map((USubtitleSpan s) => s.text).join();
    return USubtitleCue(start: start, end: end, spans: spans, text: plain);
  }

  static List<USubtitleSpan> _parseMarkup(String input) {
    final List<USubtitleSpan> spans = <USubtitleSpan>[];
    final StringBuffer buffer = StringBuffer();
    bool bold = false;
    bool italic = false;
    bool underline = false;
    Color? color;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(USubtitleSpan(buffer.toString(), bold: bold, italic: italic, underline: underline, color: color));
      buffer.clear();
    }

    int i = 0;
    while (i < input.length) {
      if (input[i] == "<") {
        final int close = input.indexOf(">", i);
        if (close < 0) {
          buffer.write(input.substring(i));
          break;
        }
        final String tag = input.substring(i + 1, close).trim().toLowerCase();
        flush();
        if (tag == "b" || tag.startsWith("b ")) {
          bold = true;
        } else if (tag == "/b") {
          bold = false;
        } else if (tag == "i" || tag.startsWith("i ")) {
          italic = true;
        } else if (tag == "/i") {
          italic = false;
        } else if (tag == "u" || tag.startsWith("u ")) {
          underline = true;
        } else if (tag == "/u") {
          underline = false;
        } else if (tag.startsWith("font")) {
          color = _htmlColor(tag);
        } else if (tag == "/font") {
          color = null;
        }
        i = close + 1;
        continue;
      }
      buffer.write(input[i]);
      i++;
    }
    flush();
    return spans.isEmpty ? <USubtitleSpan>[USubtitleSpan(input)] : spans;
  }

  static Color? _htmlColor(String tag) {
    final RegExpMatch? m = RegExp("color\\s*=\\s*[\"']?#?([0-9a-fA-F]{6})").firstMatch(tag);
    if (m == null) return null;
    return Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
  }

  static USubtitleData _parseAss(String content, String? language, String? label) {
    final Map<String, USubtitleStyle> styles = <String, USubtitleStyle>{};
    final List<USubtitleCue> cues = <USubtitleCue>[];
    List<String> styleFormat = <String>[];
    List<String> eventFormat = <String>[];
    String section = "";
    int playResX = 0;
    int playResY = 0;

    for (final String raw in content.split("\n")) {
      final String line = raw.trim();
      if (line.isEmpty || line.startsWith(";") || line.startsWith("!:")) continue;
      if (line.startsWith("[") && line.endsWith("]")) {
        section = line.toLowerCase();
        continue;
      }
      final int colon = line.indexOf(":");
      if (colon < 0) continue;
      final String key = line.substring(0, colon).trim().toLowerCase();
      final String value = line.substring(colon + 1).trim();

      if (section.contains("script info")) {
        if (key == "playresx") playResX = int.tryParse(value) ?? 0;
        if (key == "playresy") playResY = int.tryParse(value) ?? 0;
        continue;
      }
      if (section.contains("styles")) {
        if (key == "format") {
          styleFormat = value.split(",").map((String s) => s.trim().toLowerCase()).toList();
        } else if (key == "style") {
          final USubtitleStyle? style = _assStyle(styleFormat, value);
          if (style != null) styles[style.name] = style;
        }
        continue;
      }
      if (section.contains("events")) {
        if (key == "format") {
          eventFormat = value.split(",").map((String s) => s.trim().toLowerCase()).toList();
        } else if (key == "dialogue") {
          final USubtitleCue? cue = _assDialogue(eventFormat, value, styles);
          if (cue != null) cues.add(cue);
        }
      }
    }
    cues.sort((USubtitleCue a, USubtitleCue b) => a.start.compareTo(b.start));
    return USubtitleData(format: USubtitleFormat.ass, cues: cues, styles: styles, language: language, label: label, playResX: playResX, playResY: playResY);
  }

  static USubtitleStyle? _assStyle(List<String> format, String value) {
    if (format.isEmpty) return null;
    final List<String> parts = value.split(",");
    String field(String name) {
      final int index = format.indexOf(name);
      return index >= 0 && index < parts.length ? parts[index].trim() : "";
    }

    final String name = field("name");
    if (name.isEmpty) return null;
    return USubtitleStyle(
      name: name,
      fontName: field("fontname").isEmpty ? null : field("fontname"),
      fontSize: double.tryParse(field("fontsize")),
      primaryColor: _assColor(field("primarycolour")),
      outlineColor: _assColor(field("outlinecolour")),
      backColor: _assColor(field("backcolour")),
      bold: field("bold") == "-1" || field("bold") == "1",
      italic: field("italic") == "-1" || field("italic") == "1",
      underline: field("underline") == "-1" || field("underline") == "1",
      strikethrough: field("strikeout") == "-1" || field("strikeout") == "1",
      alignment: int.tryParse(field("alignment")) ?? 2,
      marginLeft: int.tryParse(field("marginl")) ?? 0,
      marginRight: int.tryParse(field("marginr")) ?? 0,
      marginVertical: int.tryParse(field("marginv")) ?? 0,
      outline: double.tryParse(field("outline")) ?? 0,
      shadow: double.tryParse(field("shadow")) ?? 0,
    );
  }

  static Color? _assColor(String value) {
    final RegExpMatch? m = RegExp("&H([0-9a-fA-F]{1,8})").firstMatch(value);
    if (m == null) return null;
    final int raw = int.parse(m.group(1)!.padLeft(8, "0"), radix: 16);
    final int alpha = 255 - ((raw >> 24) & 0xFF);
    final int blue = (raw >> 16) & 0xFF;
    final int green = (raw >> 8) & 0xFF;
    final int red = raw & 0xFF;
    return Color.fromARGB(alpha, red, green, blue);
  }

  static USubtitleCue? _assDialogue(List<String> format, String value, Map<String, USubtitleStyle> styles) {
    if (format.isEmpty) return null;
    final int textIndex = format.indexOf("text");
    if (textIndex < 0) return null;
    final List<String> parts = value.split(",");
    if (parts.length <= textIndex) return null;
    final String text = parts.sublist(textIndex).join(",");

    String field(String name) {
      final int index = format.indexOf(name);
      return index >= 0 && index < parts.length ? parts[index].trim() : "";
    }

    final String styleName = field("style");
    final USubtitleStyle? style = styles[styleName];
    final _AssText parsed = _parseAssText(text, style);
    if (parsed.plain.trim().isEmpty) return null;

    return USubtitleCue(
      start: _assTime(field("start")),
      end: _assTime(field("end")),
      spans: parsed.spans,
      text: parsed.plain,
      alignment: parsed.alignment ?? style?.alignment ?? 2,
      position: parsed.position,
      layer: int.tryParse(field("layer")) ?? 0,
      styleName: styleName.isEmpty ? null : styleName,
    );
  }

  static _AssText _parseAssText(String input, USubtitleStyle? style) {
    final List<USubtitleSpan> spans = <USubtitleSpan>[];
    final StringBuffer buffer = StringBuffer();
    bool bold = style?.bold ?? false;
    bool italic = style?.italic ?? false;
    bool underline = style?.underline ?? false;
    bool strike = style?.strikethrough ?? false;
    Color? color = style?.primaryColor;
    int? alignment;
    Offset? position;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(USubtitleSpan(buffer.toString(), bold: bold, italic: italic, underline: underline, strikethrough: strike, color: color));
      buffer.clear();
    }

    int i = 0;
    while (i < input.length) {
      final String ch = input[i];
      if (ch == "{") {
        final int close = input.indexOf("}", i);
        if (close < 0) {
          buffer.write(input.substring(i));
          break;
        }
        flush();
        final String block = input.substring(i + 1, close);
        for (final RegExpMatch tag in RegExp(r"\\([a-zA-Z]+)([^\\]*)").allMatches(block)) {
          final String name = tag.group(1)!.toLowerCase();
          final String arg = tag.group(2)!.trim();
          switch (name) {
            case "b":
              bold = arg != "0";
              break;
            case "i":
              italic = arg != "0";
              break;
            case "u":
              underline = arg != "0";
              break;
            case "s":
              strike = arg != "0";
              break;
            case "an":
              alignment = int.tryParse(arg);
              break;
            case "a":
              alignment = _legacyAlignment(int.tryParse(arg) ?? 2);
              break;
            case "c":
            case "1c":
              color = _assColor(arg) ?? color;
              break;
            case "pos":
              final RegExpMatch? p = RegExp(r"\(\s*([\d.-]+)\s*,\s*([\d.-]+)\s*\)").firstMatch(arg);
              if (p != null) position = Offset(double.parse(p.group(1)!), double.parse(p.group(2)!));
              break;
            case "r":
              bold = style?.bold ?? false;
              italic = style?.italic ?? false;
              underline = style?.underline ?? false;
              strike = style?.strikethrough ?? false;
              color = style?.primaryColor;
              break;
          }
        }
        i = close + 1;
        continue;
      }
      if (ch == "\\" && i + 1 < input.length) {
        final String next = input[i + 1];
        if (next == "N" || next == "n") {
          buffer.write("\n");
          i += 2;
          continue;
        }
        if (next == "h") {
          buffer.write("\u00A0");
          i += 2;
          continue;
        }
      }
      buffer.write(ch);
      i++;
    }
    flush();
    final String plain = spans.map((USubtitleSpan s) => s.text).join();
    return _AssText(spans, plain, alignment, position);
  }

  static int _legacyAlignment(int value) {
    switch (value) {
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 5:
        return 7;
      case 6:
        return 8;
      case 7:
        return 9;
      case 9:
        return 4;
      case 10:
        return 5;
      case 11:
        return 6;
      default:
        return 2;
    }
  }
}

class _LrcLine {
  const _LrcLine(this.time, this.text);

  final Duration time;
  final String text;
}

class _AssText {
  const _AssText(this.spans, this.plain, this.alignment, this.position);

  final List<USubtitleSpan> spans;
  final String plain;
  final int? alignment;
  final Offset? position;
}
