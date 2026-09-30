import "dart:convert";
import "dart:io";

/// A user-facing error: printed as a single line, without a stack trace.
class CliException implements Exception {
  CliException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown from inside an edit when the file does not contain what the edit needs.
/// A [silent] skip prints nothing (used for files that only sometimes carry a setting).
class EditSkip implements Exception {
  EditSkip(this.reason) : silent = false;

  EditSkip.silent() : reason = "", silent = true;

  final String reason;
  final bool silent;
}

enum Target {
  android("android"),
  ios("ios"),
  macos("macos"),
  linux("linux"),
  windows("windows"),
  web("web");

  const Target(this.id);

  final String id;

  static Target parse(String value) {
    final String v = value.toLowerCase().trim();
    if (v == "osx" || v == "mac") {
      return Target.macos;
    }
    if (v == "win") {
      return Target.windows;
    }
    return Target.values.firstWhere(
      (Target t) => t.id == v,
      orElse: () => throw CliException("Unknown platform \"$value\". Use one of: ${Target.values.map((Target t) => t.id).join(", ")}"),
    );
  }
}

/// Terminal output helpers.
abstract final class Out {
  static final bool _ansi = stdout.supportsAnsiEscapes;

  static String _c(String code, String s) => _ansi ? "\x1B[${code}m$s\x1B[0m" : s;

  static String bold(String s) => _c("1", s);

  static String dim(String s) => _c("2", s);

  static String green(String s) => _c("32", s);

  static String yellow(String s) => _c("33", s);

  static String red(String s) => _c("31", s);

  static String cyan(String s) => _c("36", s);

  static void line([String s = ""]) => stdout.writeln(s);

  static void header(String s) => line("\n${bold(cyan(s))}");

  static void changed(String file, String what, {required bool dryRun}) => line("  ${dryRun ? yellow("~") : green("✓")} ${dim(file)}  $what${dryRun ? dim("  (dry run)") : ""}");

  static void same(String file, String what) => line("  ${dim("=")} ${dim(file)}  ${dim("already $what")}");

  static void skip(String file, String reason) => line("  ${yellow("!")} ${dim(file)}  ${yellow(reason)}");

  static void note(String s) => line("  ${dim("·")} ${dim(s)}");

  static void warn(String s) => line("  ${yellow("!")} ${yellow(s)}");

  static void error(String s) => stderr.writeln(_c("31", "✗ $s"));
}

/// Hand-rolled argument parser: positionals, `--flag`, `--key value` and `--key=value`.
class Args {
  Args(List<String> raw) {
    for (int i = 0; i < raw.length; i++) {
      final String a = raw[i];
      if (a == "-h") {
        flags.add("help");
        continue;
      }
      if (a == "-n") {
        flags.add("dry-run");
        continue;
      }
      if (a.startsWith("--") && a.length > 2) {
        final String body = a.substring(2);
        final int eq = body.indexOf("=");
        if (eq > 0) {
          options[body.substring(0, eq)] = body.substring(eq + 1);
        } else if (_flags.contains(body) || i + 1 >= raw.length || raw[i + 1].startsWith("--")) {
          flags.add(body);
        } else {
          options[body] = raw[++i];
        }
        continue;
      }
      positional.add(a);
    }
  }

  static const Set<String> _flags = <String>{"help", "dry-run", "create", "force"};

  final List<String> positional = <String>[];
  final Map<String, String> options = <String, String>{};
  final Set<String> flags = <String>{};

  bool flag(String name) => flags.contains(name);

  String? option(String name) => options[name];

  /// All positionals joined with spaces, so `name My App` works without quotes.
  String text(String usage, {int from = 0}) {
    final String v = positional.skip(from).join(" ").trim();
    if (v.isEmpty) {
      throw CliException("Missing value.\n  Usage: $usage");
    }
    return v;
  }

  /// The platforms selected by `--platforms android,ios` (null = all).
  Set<Target>? get platforms {
    final String? v = options["platforms"] ?? options["platform"];
    if (v == null) {
      return null;
    }
    return v.split(",").where((String s) => s.trim().isNotEmpty).map(Target.parse).toSet();
  }
}

/// The host Flutter app the command runs against.
class Project {
  Project(this.root, {required this.dryRun, this.only});

  /// Walks up from the current directory to the nearest pubspec.yaml.
  factory Project.find({required bool dryRun, Set<Target>? only}) {
    Directory dir = Directory.current.absolute;
    while (!File("${dir.path}/pubspec.yaml").existsSync()) {
      final Directory parent = dir.parent;
      if (parent.path == dir.path) {
        throw CliException("No pubspec.yaml found. Run this command from your Flutter app's folder.");
      }
      dir = parent;
    }
    final Project p = Project(dir.path, dryRun: dryRun, only: only);
    if (RegExp(r"^[ \t]+plugin:[ \t]*$", multiLine: true).hasMatch(p.read("pubspec.yaml") ?? "")) {
      throw CliException("${p.root} is a plugin, not an app. Run this command inside the app that uses it (for example its example/ folder).");
    }
    if (!Target.values.any(p.present)) {
      throw CliException("No platform folders (android/, ios/, macos/, linux/, windows/, web/) found in ${p.root}.");
    }
    return p;
  }

  final String root;
  final bool dryRun;
  final Set<Target>? only;
  int changes = 0;

  String path(String rel) => "$root/$rel";

  File file(String rel) => File(path(rel));

  bool exists(String rel) => FileSystemEntity.typeSync(path(rel)) != FileSystemEntityType.notFound;

  /// Whether the app has this platform at all.
  bool present(Target t) => switch (t) {
    Target.android => exists("android/app/build.gradle.kts") || exists("android/app/build.gradle"),
    Target.ios => exists("ios/Runner.xcodeproj/project.pbxproj"),
    Target.macos => exists("macos/Runner.xcodeproj/project.pbxproj"),
    Target.linux => exists("linux/CMakeLists.txt") && exists("linux/runner"),
    Target.windows => exists("windows/CMakeLists.txt") && exists("windows/runner"),
    Target.web => exists("web/index.html"),
  };

  /// Whether the current command should touch [t]: present and allowed by `--platforms`.
  bool targets(Target t) => present(t) && (only == null || only!.contains(t));

  /// Runs [body] under a platform heading when [t] is targeted.
  void section(Target t, void Function() body) {
    if (!targets(t)) {
      return;
    }
    Out.header(t.id);
    body();
  }

  /// Reads a file with line endings normalised to `\n`, or null when missing.
  String? read(String rel) {
    final File f = file(rel);
    return f.existsSync() ? f.readAsStringSync().replaceAll("\r\n", "\n") : null;
  }

  /// Transforms a file in place, keeping its line endings. Writes only when the content changes.
  /// [optional] hides the "file not found" line; [quiet] hides the "already" line.
  bool edit(String rel, String Function(String text) transform, String what, {bool optional = false, bool quiet = false}) {
    final File f = file(rel);
    if (!f.existsSync()) {
      if (!optional) {
        Out.skip(rel, "file not found");
      }
      return false;
    }
    final String raw = f.readAsStringSync();
    final bool crlf = raw.contains("\r\n");
    final String text = crlf ? raw.replaceAll("\r\n", "\n") : raw;
    final String next;
    try {
      next = transform(text);
    } on EditSkip catch (e) {
      if (!e.silent) {
        Out.skip(rel, e.reason);
      }
      return false;
    }
    if (next == text) {
      if (!quiet) {
        Out.same(rel, what);
      }
      return false;
    }
    if (!dryRun) {
      f.writeAsStringSync(crlf ? next.replaceAll("\n", "\r\n") : next);
    }
    changes++;
    Out.changed(rel, what, dryRun: dryRun);
    return true;
  }

  /// Creates or replaces a whole file.
  void write(String rel, String content, String what) {
    final File f = file(rel);
    if (f.existsSync() && f.readAsStringSync() == content) {
      Out.same(rel, what);
      return;
    }
    if (!dryRun) {
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(content);
    }
    changes++;
    Out.changed(rel, what, dryRun: dryRun);
  }

  /// Moves a file, creating the destination folder.
  void move(String fromRel, String toRel, String content) {
    if (!dryRun) {
      final File to = file(toRel);
      to.parent.createSync(recursive: true);
      to.writeAsStringSync(content);
      file(fromRel).deleteSync();
    }
    changes++;
    Out.changed(fromRel, "moved to $toRel", dryRun: dryRun);
  }

  /// Deletes empty folders inside [rel], then [rel] and its parents while empty, stopping at [stopAt].
  void pruneEmptyDirs(String rel, String stopAt) {
    if (dryRun || !Directory(path(rel)).existsSync()) {
      return;
    }
    final List<Directory> inner = Directory(path(rel)).listSync(recursive: true).whereType<Directory>().toList()
      ..sort((Directory a, Directory b) => b.path.length.compareTo(a.path.length));
    for (final Directory d in inner) {
      if (d.listSync().isEmpty) {
        d.deleteSync();
      }
    }
    Directory d = Directory(path(rel));
    final String stop = Directory(path(stopAt)).absolute.path;
    while (d.absolute.path != stop && d.absolute.path.startsWith(stop) && d.existsSync() && d.listSync().isEmpty) {
      d.deleteSync();
      d = d.parent;
    }
  }
}

// ---------------------------------------------------------------------------------------------
// String escaping for the file formats we write into.

String xmlEscape(String s) => s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("\"", "&quot;");

String xmlUnescape(String s) => s.replaceAll("&lt;", "<").replaceAll("&gt;", ">").replaceAll("&quot;", "\"").replaceAll("&apos;", "'").replaceAll("&amp;", "&");

String htmlEscape(String s) => xmlEscape(s);

/// A C string literal body (Linux GTK sources are UTF-8, so non-ASCII stays as is).
String cEscape(String s) => s.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"");

/// A C++ wide literal body. Non-ASCII is written as universal character names so MSVC
/// reads it correctly whatever the source code page is.
String wideEscape(String s) {
  final StringBuffer b = StringBuffer();
  for (final int r in s.runes) {
    if (r == 0x5C) {
      b.write("\\\\");
    } else if (r == 0x22) {
      b.write("\\\"");
    } else if (r < 0x80) {
      b.writeCharCode(r);
    } else if (r <= 0xFFFF) {
      b.write("\\u${r.toRadixString(16).padLeft(4, "0")}");
    } else {
      b.write("\\U${r.toRadixString(16).padLeft(8, "0")}");
    }
  }
  return b.toString();
}

/// A Windows resource (.rc) string body: quotes are doubled.
String rcEscape(String s) => s.replaceAll("\\", "\\\\").replaceAll("\"", "\"\"");

/// A JSON string literal, quotes included.
String jsonString(String s) => jsonEncode(s);

/// A YAML scalar: plain when safe, otherwise a double-quoted (JSON-compatible) string.
String yamlScalar(String s) => RegExp(r"^[A-Za-z0-9][A-Za-z0-9 ._/()!?,'-]*$").hasMatch(s) && !s.endsWith(" ") ? s : jsonEncode(s);

/// Index of the first character of the line containing [index].
int lineStart(String text, int index) {
  final int nl = text.lastIndexOf("\n", index > 0 ? index - 1 : 0);
  return index == 0 ? 0 : nl + 1;
}

/// Index just past the newline ending the line containing [index].
int lineEnd(String text, int index) {
  final int nl = text.indexOf("\n", index);
  return nl < 0 ? text.length : nl + 1;
}

/// Leading whitespace of the line containing [index].
String indentAt(String text, int index) {
  final int start = lineStart(text, index);
  final Match? m = RegExp(r"[ \t]*").matchAsPrefix(text, start);
  return m?.group(0) ?? "";
}
