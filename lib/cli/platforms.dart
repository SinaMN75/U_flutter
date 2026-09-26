import "dart:convert";

import "package:u/cli/core.dart";
import "package:u/cli/plist.dart";

// =============================================================================================
// Android

abstract final class AndroidFiles {
  static const String manifest = "android/app/src/main/AndroidManifest.xml";
  static const String keyProperties = "android/key.properties";

  static String gradle(Project p) => p.exists("android/app/build.gradle.kts") ? "android/app/build.gradle.kts" : "android/app/build.gradle";

  static bool kts(Project p) => gradle(p).endsWith(".kts");
}

/// Line-based edits of `android/app/build.gradle(.kts)`.
abstract final class Gradle {
  static RegExp _prop(String key) => RegExp("^([ \\t]*)($key)\\b([ \\t]*=[ \\t]*|[ \\t]+)(.+)\$", multiLine: true);

  /// The raw expression assigned to the first of [keys], e.g. `flutter.minSdkVersion` or `24`.
  static String? get(String? text, List<String> keys) {
    if (text == null) {
      return null;
    }
    final Match? m = _prop(keys.map(RegExp.escape).join("|")).firstMatch(text);
    return m?.group(4)?.trim();
  }

  /// A string literal value (quotes stripped).
  static String? getString(String? text, String key) {
    final String? v = get(text, <String>[key]);
    if (v == null) {
      return null;
    }
    final Match? m = RegExp("^([\"'])(.*)\\1").firstMatch(v);
    return m?.group(2);
  }

  /// Sets the first of [keys] to [value]; inserts `keys.first` into [block] when absent.
  static String set(String text, List<String> keys, String value, {required bool kts, String? block}) {
    final RegExp re = _prop(keys.map(RegExp.escape).join("|"));
    final Match? m = re.firstMatch(text);
    if (m != null) {
      final String sep = m.group(3)!.contains("=") ? m.group(3)! : (kts ? " = " : " ");
      return text.replaceRange(m.start, m.end, "${m.group(1)}${m.group(2)}$sep$value");
    }
    if (block == null) {
      throw EditSkip("${keys.first} not found");
    }
    final Match? b = RegExp("^([ \\t]*)$block\\s*\\{[ \\t]*\$", multiLine: true).firstMatch(text);
    if (b == null) {
      throw EditSkip("$block { } block not found");
    }
    final String indent = "${b.group(1)}    ";
    return text.replaceRange(b.end, b.end, "\n$indent${keys.first}${kts ? " = " : " "}$value");
  }

  /// Friendly display for Flutter-managed defaults.
  static String display(String? v) {
    if (v == null) {
      return "—";
    }
    return v.startsWith("flutter.") ? "$v ${Out.dim("(Flutter default)")}" : v;
  }
}

/// Small regex-based helpers for AndroidManifest.xml.
abstract final class Xml {
  /// Start/end (exclusive) of the first opening tag `<name ...>`.
  static (int, int)? openTag(String text, String name, [int from = 0]) {
    final Match? m = RegExp("<$name(?=[\\s>/])").allMatches(text, from).firstOrNull;
    if (m == null) {
      return null;
    }
    return (m.start, _tagEnd(text, m.start));
  }

  static int _tagEnd(String text, int start) {
    bool inQuote = false;
    for (int i = start; i < text.length; i++) {
      final String c = text[i];
      if (c == "\"") {
        inQuote = !inQuote;
      } else if (c == ">" && !inQuote) {
        return i + 1;
      }
    }
    throw EditSkip("malformed XML");
  }

  static String? attr(String tag, String name) {
    final Match? m = RegExp("\\s${RegExp.escape(name)}\\s*=\\s*\"([^\"]*)\"").firstMatch(tag);
    return m == null ? null : xmlUnescape(m.group(1)!);
  }

  /// Sets ([value] non-null) or removes an attribute on an opening tag, matching the tag's layout.
  static String setAttr(String tag, String name, String? value) {
    final Match? m = RegExp("(\\s+)${RegExp.escape(name)}\\s*=\\s*\"[^\"]*\"").firstMatch(tag);
    if (value == null) {
      return m == null ? tag : tag.replaceRange(m.start, m.end, "");
    }
    final String escaped = xmlEscape(value);
    if (m != null) {
      return tag.replaceRange(m.start, m.end, "${m.group(1)}$name=\"$escaped\"");
    }
    final int insertAt = tag.endsWith("/>") ? tag.length - 2 : tag.length - 1;
    final Match? ind = RegExp(r"\n([ \t]+)\S").allMatches(tag).lastOrNull;
    final String sep = ind != null ? "\n${ind.group(1)}" : " ";
    return "${tag.substring(0, insertAt).trimRight()}$sep$name=\"$escaped\"${tag.substring(insertAt)}";
  }

  /// Replaces an opening tag inside [text].
  static String replaceOpenTag(String text, String name, String Function(String tag) change) {
    final (int, int)? r = openTag(text, name);
    if (r == null) {
      throw EditSkip("<$name> not found");
    }
    return text.replaceRange(r.$1, r.$2, change(text.substring(r.$1, r.$2)));
  }

  /// The `<activity>` element that has the LAUNCHER intent filter (the Flutter activity).
  static (int, int)? launcherActivity(String text) {
    (int, int)? first;
    for (final Match m in RegExp(r"<activity(?=[\s>/])").allMatches(text)) {
      final int tagEnd = _tagEnd(text, m.start);
      final int end = text[tagEnd - 2] == "/" ? tagEnd : text.indexOf("</activity>", tagEnd) + "</activity>".length;
      final (int, int) range = (m.start, end);
      first ??= range;
      if (text.substring(m.start, end).contains("android.intent.category.LAUNCHER")) {
        return range;
      }
    }
    return first;
  }

  /// Removes the match plus its whole line when it stands alone on that line.
  static String removeLine(String text, Match m) {
    final int start = lineStart(text, m.start);
    final int end = lineEnd(text, m.end);
    if (text.substring(start, m.start).trim().isEmpty && text.substring(m.end, end).trim().isEmpty) {
      return text.replaceRange(start, end, "");
    }
    return text.replaceRange(m.start, m.end, "");
  }
}

/// Reads the app name Android shows, resolving `@string/` labels.
String? androidName(Project p) {
  final String? m = p.read(AndroidFiles.manifest);
  if (m == null) {
    return null;
  }
  final (int, int)? tag = Xml.openTag(m, "application");
  if (tag == null) {
    return null;
  }
  final String? label = Xml.attr(m.substring(tag.$1, tag.$2), "android:label");
  if (label != null && label.startsWith("@string/")) {
    final String? strings = p.read("android/app/src/main/res/values/strings.xml");
    final Match? s = RegExp("<string\\s+name=\"${RegExp.escape(label.substring(8))}\"[^>]*>([\\s\\S]*?)</string>").firstMatch(strings ?? "");
    return s == null ? label : xmlUnescape(s.group(1)!);
  }
  return label;
}

// =============================================================================================
// Apple (iOS + macOS)

class AppleFiles {
  const AppleFiles(this.target);

  final Target target;

  bool get isIos => target == Target.ios;

  String get dir => target.id;

  String get pbxproj => "$dir/Runner.xcodeproj/project.pbxproj";

  String get infoPlist => "$dir/Runner/Info.plist";

  String get podfile => "$dir/Podfile";

  String get deploymentKey => isIos ? "IPHONEOS_DEPLOYMENT_TARGET" : "MACOSX_DEPLOYMENT_TARGET";

  String get podPlatform => isIos ? "ios" : "osx";

  static const String appInfo = "macos/Runner/Configs/AppInfo.xcconfig";

  static const List<String> entitlements = <String>["macos/Runner/DebugProfile.entitlements", "macos/Runner/Release.entitlements"];
}

/// Build-setting edits of `project.pbxproj`.
abstract final class Pbx {
  static RegExp _setting(String key) => RegExp("(\\b$key = )(\"(?:[^\"\\\\]|\\\\.)*\"|[^;\\n]*);");

  static String quote(String v) => RegExp(r"^[A-Za-z0-9_./]+$").hasMatch(v) ? v : "\"${v.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"")}\"";

  static String unquote(String v) => v.startsWith("\"") && v.endsWith("\"") && v.length >= 2 ? v.substring(1, v.length - 1).replaceAll("\\\"", "\"").replaceAll("\\\\", "\\") : v;

  static List<String> values(String? text, String key) => text == null ? <String>[] : _setting(key).allMatches(text).map((Match m) => unquote(m.group(2)!)).toList();

  /// Rewrites every value of [key]; [change] returns null to leave a value as is.
  static String mapAll(String text, String key, String? Function(String old) change) =>
      text.replaceAllMapped(_setting(key), (Match m) {
        final String? next = change(unquote(m.group(2)!));
        return next == null ? m.group(0)! : "${m.group(1)}${quote(next)};";
      });

  static String setAll(String text, String key, String value) {
    if (!_setting(key).hasMatch(text)) {
      throw EditSkip("$key not found");
    }
    return mapAll(text, key, (String _) => value);
  }

  /// `buildSettings = { ... }` ranges of the Runner app target's configurations.
  static List<(int, int)> runnerSettings(String text) {
    final List<(int, int)> out = <(int, int)>[];
    for (final Match m in RegExp(r"buildSettings = \{").allMatches(text)) {
      int depth = 1;
      int i = m.end;
      while (depth > 0 && i < text.length) {
        final String c = text[i];
        if (c == "{") {
          depth++;
        } else if (c == "}") {
          depth--;
        }
        i++;
      }
      final String body = text.substring(m.end, i);
      if (RegExp(r"INFOPLIST_FILE = Runner/Info\.plist;").hasMatch(body)) {
        out.add((m.end, i - 1));
      }
    }
    return out;
  }

  /// Values of [key] inside the Runner target's configurations.
  static List<String> runnerValues(String? text, String key) {
    if (text == null) {
      return <String>[];
    }
    return runnerSettings(text).expand(((int, int) r) => values(text.substring(r.$1, r.$2), key)).toList();
  }

  /// Sets [key] in every Runner configuration, inserting it alphabetically when missing.
  static String setInRunner(String text, String key, String value) {
    final List<(int, int)> ranges = runnerSettings(text);
    if (ranges.isEmpty) {
      throw EditSkip("Runner build configurations not found");
    }
    String out = text;
    for (final (int, int) r in ranges.reversed) {
      final String body = out.substring(r.$1, r.$2);
      String next;
      if (_setting(key).hasMatch(body)) {
        next = mapAll(body, key, (String _) => value);
      } else {
        final List<Match> lines = RegExp(r"^([ \t]+)([A-Z0-9_]+) = ", multiLine: true).allMatches(body).toList();
        final String indent = lines.isEmpty ? "\t\t\t\t" : lines.first.group(1)!;
        final Match? after = lines.where((Match l) => l.group(1) == indent && l.group(2)!.compareTo(key) > 0).firstOrNull;
        final int at = after != null ? after.start : lineStart(body, body.length);
        next = body.replaceRange(at, at, "$indent$key = ${quote(value)};\n");
      }
      out = out.replaceRange(r.$1, r.$2, next);
    }
    return out;
  }
}

abstract final class Podfile {
  static String setPlatform(String text, String platform, String version, String deploymentKey) {
    final RegExp re = RegExp("^#?[ \\t]*platform\\s+:$platform\\s*,\\s*['\"][^'\"]*['\"]", multiLine: true);
    String out = re.hasMatch(text) ? text.replaceFirst(re, "platform :$platform, '$version'") : "platform :$platform, '$version'\n$text";
    out = out.replaceAllMapped(RegExp("(\\[['\"]$deploymentKey['\"]\\]\\s*=\\s*)['\"][^'\"]*['\"]"), (Match m) => "${m.group(1)}'$version'");
    return out;
  }

  static String? platform(String? text, String platform) {
    if (text == null) {
      return null;
    }
    return RegExp("^[ \\t]*platform\\s+:$platform\\s*,\\s*['\"]([^'\"]*)['\"]", multiLine: true).firstMatch(text)?.group(1);
  }
}

abstract final class XcConfig {
  static RegExp _re(String key) => RegExp("^([ \\t]*$key[ \\t]*=[ \\t]*)(.*)\$", multiLine: true);

  static String? get(String? text, String key) => text == null ? null : _re(key).firstMatch(text)?.group(2)?.trim();

  static String set(String text, String key, String value) {
    final Match? m = _re(key).firstMatch(text);
    if (m != null) {
      return text.replaceRange(m.start, m.end, "${m.group(1)}$value");
    }
    return "${text.endsWith("\n") ? text : "$text\n"}$key = $value\n";
  }
}

String? iosId(Project p) => Pbx.runnerValues(p.read(const AppleFiles(Target.ios).pbxproj), "PRODUCT_BUNDLE_IDENTIFIER").firstOrNull;

String? macosId(Project p) => XcConfig.get(p.read(AppleFiles.appInfo), "PRODUCT_BUNDLE_IDENTIFIER");

String? appleId(Project p, Target t) => t == Target.ios ? iosId(p) : macosId(p);

String? appleMin(Project p, AppleFiles f) {
  final String? text = p.read(f.pbxproj);
  return Pbx.runnerValues(text, f.deploymentKey).firstOrNull ?? Pbx.values(text, f.deploymentKey).firstOrNull;
}

Plist? readPlist(Project p, String rel) {
  final String? text = p.read(rel);
  if (text == null) {
    return null;
  }
  try {
    return Plist(text);
  } on EditSkip {
    return null;
  }
}

/// Edits a plist file through [Plist].
bool editPlist(Project p, String rel, void Function(Plist plist) change, String what, {bool optional = false}) => p.edit(
  rel,
  (String text) {
    final Plist plist = Plist(text);
    change(plist);
    return plist.text;
  },
  what,
  optional: optional,
);

// =============================================================================================
// Linux / Windows / Web

abstract final class Cmake {
  static RegExp _set(String name) => RegExp("(set\\($name\\s+)\"([^\"]*)\"");

  static String? get(String? text, String name) => text == null ? null : _set(name).firstMatch(text)?.group(2);

  static String set(String text, String name, String value) {
    if (!_set(name).hasMatch(text)) {
      throw EditSkip("set($name ...) not found");
    }
    return text.replaceFirstMapped(_set(name), (Match m) => "${m.group(1)}\"$value\"");
  }
}

abstract final class LinuxFiles {
  static const String cmake = "linux/CMakeLists.txt";
  static const String app = "linux/runner/my_application.cc";

  static final RegExp headerTitle = RegExp(r'(gtk_header_bar_set_title\(\s*header_bar\s*,\s*)"((?:[^"\\]|\\.)*)"');
  static final RegExp windowTitle = RegExp(r'(gtk_window_set_title\(\s*window\s*,\s*)"((?:[^"\\]|\\.)*)"');

  static String? name(Project p) => headerTitle.firstMatch(p.read(app) ?? "")?.group(2)?.replaceAll("\\\"", "\"");
}

abstract final class WindowsFiles {
  static const String cmake = "windows/CMakeLists.txt";
  static const String main = "windows/runner/main.cpp";
  static const String rc = "windows/runner/Runner.rc";

  static final RegExp windowCreate = RegExp(r'(window\.Create\(\s*L)"((?:[^"\\]|\\.)*)"');

  static RegExp rcValue(String key) => RegExp('(VALUE\\s+"$key"\\s*,\\s*)"((?:[^"]|"")*)"');

  static String? rcGet(String? text, String key) => text == null ? null : rcValue(key).firstMatch(text)?.group(2)?.replaceAll("\"\"", "\"");

  static String rcSet(String text, String key, String value) {
    if (!rcValue(key).hasMatch(text)) {
      throw EditSkip("VALUE \"$key\" not found");
    }
    return text.replaceFirstMapped(rcValue(key), (Match m) => "${m.group(1)}\"${rcEscape(value)}\"");
  }

  /// Decodes `\uXXXX` escapes written by [wideEscape] for display.
  static String? name(Project p) {
    final String? raw = windowCreate.firstMatch(p.read(main) ?? "")?.group(2);
    return raw?.replaceAllMapped(RegExp(r"\\u([0-9a-fA-F]{4})|\\U([0-9a-fA-F]{8})"), (Match m) => String.fromCharCode(int.parse(m.group(1) ?? m.group(2)!, radix: 16)));
  }
}

abstract final class WebFiles {
  static const String manifest = "web/manifest.json";
  static const String index = "web/index.html";

  static RegExp _jsonKey(String key) => RegExp('("$key"\\s*:\\s*)("(?:[^"\\\\]|\\\\.)*")');

  static String? jsonGet(String? text, String key) {
    final Match? m = text == null ? null : _jsonKey(key).firstMatch(text);
    return m == null ? null : jsonDecode(m.group(2)!) as String;
  }

  /// Sets a top-level string field, keeping the file's formatting; adds it after `"name"` when missing.
  static String jsonSet(String text, String key, String value) {
    if (_jsonKey(key).hasMatch(text)) {
      return text.replaceFirstMapped(_jsonKey(key), (Match m) => "${m.group(1)}${jsonString(value)}");
    }
    final Match? open = RegExp(r"\{\s*\n([ \t]*)").firstMatch(text);
    if (open == null) {
      throw EditSkip("unexpected manifest.json layout");
    }
    return text.replaceRange(open.end, open.end, "\"$key\": ${jsonString(value)},\n${open.group(1)}");
  }

  static RegExp meta(String name) => RegExp('(<meta\\s+name="$name"\\s+content=")([^"]*)(")');

  static final RegExp title = RegExp(r"(<title>)([\s\S]*?)(</title>)");
}
