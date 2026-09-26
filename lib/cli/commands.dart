import "dart:io";

import "package:u/cli/core.dart";
import "package:u/cli/permissions.dart";
import "package:u/cli/platforms.dart";
import "package:u/cli/plist.dart";

const AppleFiles _ios = AppleFiles(Target.ios);
const AppleFiles _macos = AppleFiles(Target.macos);

/// Prints a heading and a warning when a platform the user asked for explicitly is missing.
bool _need(Project p, Target t) {
  if (p.present(t)) {
    return true;
  }
  Out.header(t.id);
  Out.warn("This app has no ${t.id}/ folder.");
  return false;
}

void _requireAny(Project p, List<Target> targets, String what) {
  if (!targets.any(p.targets)) {
    throw CliException("$what applies to ${targets.map((Target t) => t.id).join(" / ")}, and none of those platforms are in this app${p.only != null ? " (or selected by --platforms)" : ""}.");
  }
}

// =============================================================================================
// name

void cmdName(Project p, Args a) {
  final String name = a.text("dart run u:app name \"My App\"");
  final String short = a.option("short") ?? name;

  p.section(Target.android, () => _androidName(p, name));

  p.section(Target.ios, () {
    editPlist(p, _ios.infoPlist, (Plist pl) {
      pl.setString("CFBundleDisplayName", name);
      pl.setString("CFBundleName", name);
    }, "CFBundleDisplayName / CFBundleName = \"$name\"");
  });

  p.section(Target.macos, () {
    final String? old = XcConfig.get(p.read(AppleFiles.appInfo), "PRODUCT_NAME");
    // PRODUCT_NAME becomes the .app folder and executable name, so drop characters files can't have.
    final String product = name.replaceAll(RegExp(r'[/\\:"*?<>|$()]'), "").trim();
    if (product != name) {
      Out.note("macOS uses the name as the .app file name, so it becomes \"$product\"");
    }
    p.edit(AppleFiles.appInfo, (String t) => XcConfig.set(t, "PRODUCT_NAME", product), "PRODUCT_NAME = $product  ${Out.dim("(menu bar, Dock, .app name)")}");
    if (old != null && old != product) {
      p.edit(
        _macos.pbxproj,
        (String t) => Pbx.mapAll(
          t,
          "TEST_HOST",
          (String v) => v.replaceAll("/$old.app/", "/$product.app/").replaceAll(RegExp("/${RegExp.escape(old)}\$"), "/$product"),
        ),
        "RunnerTests TEST_HOST → $product.app",
        quiet: true,
      );
    }
  });

  p.section(Target.linux, () {
    p.edit(LinuxFiles.app, (String t) {
      if (!LinuxFiles.headerTitle.hasMatch(t) && !LinuxFiles.windowTitle.hasMatch(t)) {
        throw EditSkip("window title calls not found");
      }
      return t
          .replaceAllMapped(LinuxFiles.headerTitle, (Match m) => "${m.group(1)}\"${cEscape(name)}\"")
          .replaceAllMapped(LinuxFiles.windowTitle, (Match m) => "${m.group(1)}\"${cEscape(name)}\"");
    }, "window title = \"$name\"");
  });

  p.section(Target.windows, () {
    p.edit(WindowsFiles.main, (String t) {
      if (!WindowsFiles.windowCreate.hasMatch(t)) {
        throw EditSkip("window.Create(L\"...\") not found");
      }
      return t.replaceFirstMapped(WindowsFiles.windowCreate, (Match m) => "${m.group(1)}\"${wideEscape(name)}\"");
    }, "window title = \"$name\"");
    p.edit(WindowsFiles.rc, (String t) => WindowsFiles.rcSet(WindowsFiles.rcSet(t, "FileDescription", name), "ProductName", name), "ProductName / FileDescription = \"$name\"");
  });

  p.section(Target.web, () {
    p.edit(WebFiles.manifest, (String t) => WebFiles.jsonSet(WebFiles.jsonSet(t, "name", name), "short_name", short), "name = \"$name\", short_name = \"$short\"");
    p.edit(WebFiles.index, (String t) {
      String out = t.replaceFirstMapped(WebFiles.title, (Match m) => "${m.group(1)}${htmlEscape(name)}${m.group(3)}");
      out = out.replaceFirstMapped(WebFiles.meta("apple-mobile-web-app-title"), (Match m) => "${m.group(1)}${htmlEscape(short)}${m.group(3)}");
      return out;
    }, "<title> / apple-mobile-web-app-title = \"$name\"");
  });
}

/// Escapes text for an Android string resource (strings.xml).
String _androidText(String s) {
  final String escaped = s.replaceAll("\\", "\\\\").replaceAll("'", "\\'").replaceAll("\"", "\\\"");
  return escaped.startsWith("@") || escaped.startsWith("?") ? "\\$escaped" : escaped;
}

void _androidName(Project p, String name) {
  final String? manifest = p.read(AndroidFiles.manifest);
  if (manifest == null) {
    Out.skip(AndroidFiles.manifest, "file not found");
    return;
  }
  final (int, int)? tag = Xml.openTag(manifest, "application");
  final String? label = tag == null ? null : Xml.attr(manifest.substring(tag.$1, tag.$2), "android:label");
  if (label != null && label.startsWith("@string/")) {
    final String key = label.substring(8);
    final RegExp re = RegExp('(<string\\s+name="${RegExp.escape(key)}"[^>]*>)[\\s\\S]*?(</string>)');
    p.edit("android/app/src/main/res/values/strings.xml", (String t) {
      if (!re.hasMatch(t)) {
        throw EditSkip("<string name=\"$key\"> not found");
      }
      return t.replaceFirstMapped(re, (Match m) => "${m.group(1)}${xmlEscape(_androidText(name))}${m.group(2)}");
    }, "@string/$key = \"$name\"");
    final Directory res = Directory(p.path("android/app/src/main/res"));
    for (final FileSystemEntity d in res.listSync()) {
      final File f = File("${d.path}/strings.xml");
      final String folder = d.path.split(Platform.pathSeparator).last;
      if (folder.startsWith("values-") && f.existsSync() && re.hasMatch(f.readAsStringSync())) {
        Out.note("$folder/strings.xml also defines $key (a translated name). It was left unchanged.");
      }
    }
    return;
  }
  p.edit(
    AndroidFiles.manifest,
    (String t) => Xml.replaceOpenTag(t, "application", (String tag) => Xml.setAttr(tag, "android:label", name.startsWith("@") || name.startsWith("?") ? "\\$name" : name)),
    "android:label = \"$name\"",
  );
}

// =============================================================================================
// id

const Set<String> _reserved = <String>{
  "abstract", "as", "assert", "boolean", "break", "byte", "case", "catch", "char", "class", "const", "continue", "default", "do", "double", "else", "enum", //
  "extends", "false", "final", "finally", "float", "for", "fun", "goto", "if", "implements", "import", "in", "instanceof", "int", "interface", "is", "long", //
  "native", "new", "null", "object", "package", "private", "protected", "public", "return", "short", "static", "strictfp", "super", "switch", "synchronized", //
  "this", "throw", "throws", "transient", "true", "try", "typealias", "typeof", "val", "var", "void", "volatile", "when", "while",
};

String _androidStyleId(String id) => id.replaceAll("-", "_");

/// Flutter's own rule for Apple ids: `my_app` → `myApp` (underscores aren't allowed).
String _appleStyleId(String id) => id
    .split(".")
    .map((String seg) {
      final List<String> parts = seg.split("_").where((String s) => s.isNotEmpty).toList();
      if (parts.isEmpty) {
        return seg;
      }
      return parts.first + parts.skip(1).map((String s) => s[0].toUpperCase() + s.substring(1)).join();
    })
    .join(".");

void _validateAndroidId(String id) {
  if (!RegExp(r"^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$").hasMatch(id)) {
    throw CliException("\"$id\" is not a valid Android application id: use 2+ dot-separated parts, each starting with a letter (letters, digits, _).");
  }
  final String? bad = id.split(".").where(_reserved.contains).firstOrNull;
  if (bad != null) {
    throw CliException("\"$id\" contains \"$bad\", a Java/Kotlin keyword, which can't be part of an Android package name.");
  }
}

void _validateAppleId(String id) {
  if (!RegExp(r"^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$").hasMatch(id)) {
    throw CliException("\"$id\" is not a valid Apple bundle id: use dot-separated parts with letters, digits and hyphens only.");
  }
}

void cmdId(Project p, Args a) {
  final String id = a.text("dart run u:app id com.company.app").replaceAll(" ", "");
  final String androidId = a.option("android") ?? _androidStyleId(id);
  final String iosBundle = a.option("ios") ?? _appleStyleId(id);
  final String macBundle = a.option("macos") ?? iosBundle;
  final String linuxId = a.option("linux") ?? androidId;
  if (p.targets(Target.android)) {
    _validateAndroidId(androidId);
  }
  if (p.targets(Target.linux)) {
    _validateAndroidId(linuxId);
  }
  if (p.targets(Target.ios)) {
    _validateAppleId(iosBundle);
  }
  if (p.targets(Target.macos)) {
    _validateAppleId(macBundle);
  }
  if (id.startsWith("com.example.")) {
    Out.warn("Google Play and the App Store reject ids starting with com.example.");
  }

  p.section(Target.android, () {
    if (androidId != id) {
      Out.note("Android ids can't contain \"-\", so it becomes $androidId");
    }
    _androidId(p, androidId);
  });
  p.section(Target.ios, () {
    if (iosBundle != id) {
      Out.note("Apple bundle ids can't contain \"_\", so it becomes $iosBundle");
    }
    _appleId(p, _ios, iosBundle);
  });
  p.section(Target.macos, () => _appleId(p, _macos, macBundle));
  p.section(Target.linux, () => p.edit(LinuxFiles.cmake, (String t) => Cmake.set(t, "APPLICATION_ID", linuxId), "APPLICATION_ID = $linuxId"));
  p.section(Target.windows, () => Out.note("Windows apps have no application id. Nothing to change (see `company` / `binary`)."));
  p.section(Target.web, () => Out.note("Web apps have no application id. Nothing to change."));

  final List<String> firebase = <String>[
    "android/app/google-services.json",
    "ios/Runner/GoogleService-Info.plist",
    "macos/Runner/GoogleService-Info.plist",
    "lib/firebase_options.dart",
  ].where(p.exists).toList();
  Out.line();
  if (firebase.isNotEmpty) {
    Out.warn("Firebase config found (${firebase.join(", ")}). Register the new id in Firebase and run `flutterfire configure` again.");
  }
  Out.note("The new id makes this a different app. Uninstall the old one from your devices/simulators to avoid confusion.");
}

void _androidId(Project p, String id) {
  final String gradlePath = AndroidFiles.gradle(p);
  final bool kts = AndroidFiles.kts(p);
  final String? gradle = p.read(gradlePath);
  final String? oldNamespace = Gradle.getString(gradle, "namespace") ?? Gradle.getString(gradle, "applicationId");
  p.edit(gradlePath, (String t) {
    String out = Gradle.set(t, <String>["applicationId"], "\"$id\"", kts: kts, block: "defaultConfig");
    if (Gradle.get(out, <String>["namespace"]) != null) {
      out = Gradle.set(out, <String>["namespace"], "\"$id\"", kts: kts);
    }
    return out;
  }, "applicationId / namespace = $id");

  final Directory src = Directory(p.path("android/app/src"));
  if (!src.existsSync()) {
    return;
  }
  for (final FileSystemEntity e in src.listSync()) {
    final String rel = "android/app/src/${e.path.split(Platform.pathSeparator).last}/AndroidManifest.xml";
    final String? m = p.read(rel);
    if (m != null && RegExp(r'<manifest[^>]*\spackage="').hasMatch(m)) {
      p.edit(rel, (String t) => Xml.replaceOpenTag(t, "manifest", (String tag) => Xml.setAttr(tag, "package", id)), "package = $id");
    }
  }
  _moveAndroidSources(p, oldNamespace, id);
}

/// Moves MainActivity (and anything else in its package) into the folder of the new package
/// and rewrites `package` / `import` lines, because the manifest's `.MainActivity` resolves
/// against the namespace.
void _moveAndroidSources(Project p, String? fallbackOld, String newPkg) {
  final Directory src = Directory(p.path("android/app/src"));
  final List<File> sources = src
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => (f.path.endsWith(".kt") || f.path.endsWith(".java")) && !f.path.contains("${Platform.pathSeparator}io${Platform.pathSeparator}flutter${Platform.pathSeparator}plugins"))
      .toList();
  String? oldPkg;
  for (final File f in sources) {
    if (f.uri.pathSegments.last.startsWith("MainActivity.")) {
      oldPkg = RegExp(r"^package\s+`?([\w.`]+?)`?\s*;?\s*$", multiLine: true).firstMatch(f.readAsStringSync())?.group(1)?.replaceAll("`", "");
      break;
    }
  }
  oldPkg ??= fallbackOld;
  if (oldPkg == null || oldPkg == newPkg) {
    return;
  }
  final String oldPath = oldPkg.replaceAll(".", "/");
  final String newPath = newPkg.replaceAll(".", "/");
  final RegExp pkgLine = RegExp("^(package\\s+)`?${RegExp.escape(oldPkg)}`?(?=[.;\\s]|\$)", multiLine: true);
  final RegExp importLine = RegExp("^(import\\s+(?:static\\s+)?)${RegExp.escape(oldPkg)}\\.", multiLine: true);
  final RegExp inOldDir = RegExp("^(android/app/src/[^/]+/(?:kotlin|java))/${RegExp.escape(oldPath)}/(.+)\$");
  final Map<String, String> emptied = <String, String>{};
  for (final File f in sources) {
    final String rel = f.path.substring(p.root.length + 1).replaceAll(Platform.pathSeparator, "/");
    final String text = f.readAsStringSync();
    final String next = text.replaceAllMapped(pkgLine, (Match m) => "${m.group(1)}$newPkg").replaceAllMapped(importLine, (Match m) => "${m.group(1)}$newPkg.");
    final Match? loc = inOldDir.firstMatch(rel);
    if (loc != null) {
      p.move(rel, "${loc.group(1)}/$newPath/${loc.group(2)}", next);
      emptied["${loc.group(1)}/$oldPath"] = loc.group(1)!;
    } else if (next != text) {
      p.write(rel, next, "package references → $newPkg");
    }
  }
  emptied.forEach(p.pruneEmptyDirs);
}

void _appleId(Project p, AppleFiles f, String id) {
  final String? old = appleId(p, f.target);
  if (!f.isIos) {
    p.edit(AppleFiles.appInfo, (String t) => XcConfig.set(t, "PRODUCT_BUNDLE_IDENTIFIER", id), "PRODUCT_BUNDLE_IDENTIFIER = $id");
  }
  p.edit(f.pbxproj, (String t) {
    String out = Pbx.mapAll(t, "PRODUCT_BUNDLE_IDENTIFIER", (String v) {
      if (old != null && (v == old || v.startsWith("$old."))) {
        return id + v.substring(old.length);
      }
      return v.endsWith(".RunnerTests") ? "$id.RunnerTests" : null;
    });
    if (f.isIos) {
      out = Pbx.setInRunner(out, "PRODUCT_BUNDLE_IDENTIFIER", id);
    }
    return out;
  }, f.isIos ? "PRODUCT_BUNDLE_IDENTIFIER = $id  ${Out.dim("(+ RunnerTests / extensions)")}" : "RunnerTests id = $id.RunnerTests", quiet: !f.isIos);
}

// =============================================================================================
// SDK levels

void cmdMinSdk(Project p, Args a) {
  const String usage = "dart run u:app min-sdk android 24 ios 18 macos 14";
  final Map<Target, String> wanted = <Target, String>{};
  final List<String> pos = a.positional;
  for (int i = 0; i < pos.length; i++) {
    final Match? inline = RegExp(r"^([a-zA-Z]+)[=:](.+)$").firstMatch(pos[i]);
    if (inline != null) {
      wanted[Target.parse(inline.group(1)!)] = inline.group(2)!;
    } else if (i + 1 < pos.length) {
      wanted[Target.parse(pos[i])] = pos[++i];
    } else {
      throw CliException("Missing version after \"${pos[i]}\".\n  Usage: $usage");
    }
  }
  for (final Target t in Target.values) {
    final String? v = a.option(t.id);
    if (v != null) {
      wanted[t] = v;
    }
  }
  if (wanted.isEmpty) {
    throw CliException("Tell me which platform(s).\n  Usage: $usage");
  }
  wanted.forEach((Target t, String v) {
    switch (t) {
      case Target.android:
        _androidSdk(p, v, <String>["minSdk", "minSdkVersion"], "defaultConfig", "minSdk");
      case Target.ios:
        _appleMin(p, _ios, v);
      case Target.macos:
        _appleMin(p, _macos, v);
      case Target.linux:
      case Target.windows:
      case Target.web:
        Out.header(t.id);
        Out.note("${t.id} has no minimum-OS setting in a Flutter project. Nothing to change.");
    }
  });
}

void cmdTargetSdk(Project p, Args a) => _androidSdk(p, a.text("dart run u:app target-sdk 36"), <String>["targetSdk", "targetSdkVersion"], "defaultConfig", "targetSdk");

void cmdCompileSdk(Project p, Args a) => _androidSdk(p, a.text("dart run u:app compile-sdk 36"), <String>["compileSdk", "compileSdkVersion"], "android", "compileSdk");

void _androidSdk(Project p, String value, List<String> keys, String block, String label) {
  if (!_need(p, Target.android)) {
    return;
  }
  final bool reset = value == "default" || value == "flutter";
  final int? level = int.tryParse(value);
  if (!reset && (level == null || level < 1 || level > 99)) {
    throw CliException("\"$value\" is not an Android API level. Use a number like 24, or \"default\" for Flutter's default.");
  }
  final String expr = reset ? "flutter.${label}Version" : "$level";
  final String gradlePath = AndroidFiles.gradle(p);
  if (!p.targets(Target.android)) {
    return;
  }
  Out.header("android");
  p.edit(gradlePath, (String t) => Gradle.set(t, keys, expr, kts: AndroidFiles.kts(p), block: block), "$label = $expr");
  if (label == "minSdk" && level != null && level < 21) {
    Out.warn("Flutter doesn't support Android below API 21.");
  }
  final String? gradle = p.read(gradlePath);
  final int? min = int.tryParse(Gradle.get(gradle, <String>["minSdk", "minSdkVersion"]) ?? "");
  final int? target = int.tryParse(Gradle.get(gradle, <String>["targetSdk", "targetSdkVersion"]) ?? "");
  if (min != null && target != null && min > target) {
    Out.warn("minSdk ($min) is higher than targetSdk ($target).");
  }
}

void _appleMin(Project p, AppleFiles f, String value) {
  if (!_need(p, f.target) || !p.targets(f.target)) {
    return;
  }
  if (!RegExp(r"^\d{1,2}(\.\d{1,2}){0,2}$").hasMatch(value)) {
    throw CliException("\"$value\" is not a ${f.target.id} version. Use something like ${f.isIos ? "18 or 16.4" : "14 or 10.15"}.");
  }
  final String v = value.contains(".") ? value : "$value.0";
  final double major = double.tryParse(v.split(".").take(2).join(".")) ?? 0;
  Out.header(f.target.id);
  p.edit(f.pbxproj, (String t) => Pbx.setAll(t, f.deploymentKey, v), "${f.deploymentKey} = $v");
  p.edit(f.podfile, (String t) => Podfile.setPlatform(t, f.podPlatform, v, f.deploymentKey), "platform :${f.podPlatform}, '$v'", optional: true);
  if (f.isIos) {
    p.edit(
      "ios/Flutter/AppFrameworkInfo.plist",
      (String t) {
        final Plist pl = Plist(t);
        if (!pl.has("MinimumOSVersion")) {
          throw EditSkip.silent();
        }
        pl.setString("MinimumOSVersion", v);
        return pl.text;
      },
      "MinimumOSVersion = $v",
      optional: true,
      quiet: true,
    );
  }
  if (f.isIos && major < 13) {
    Out.warn("Flutter doesn't support iOS below 13.");
  }
  if (!f.isIos && major < 10.15) {
    Out.warn("Flutter doesn't support macOS below 10.15.");
  }
  if (p.exists(f.podfile)) {
    Out.note("CocoaPods picks this up on the next `flutter run` / `flutter build` (or run `pod install` in ${f.dir}/).");
  }
}

void cmdNdk(Project p, Args a) {
  final String v = a.text("dart run u:app ndk 27.0.12077973");
  final bool reset = v == "default" || v == "flutter";
  if (!reset && !RegExp(r"^\d+\.\d+\.\d+$").hasMatch(v)) {
    throw CliException("\"$v\" doesn't look like an NDK version (e.g. 27.0.12077973), or use \"default\".");
  }
  if (!_need(p, Target.android) || !p.targets(Target.android)) {
    return;
  }
  final String expr = reset ? "flutter.ndkVersion" : "\"$v\"";
  Out.header("android");
  p.edit(AndroidFiles.gradle(p), (String t) => Gradle.set(t, <String>["ndkVersion"], expr, kts: AndroidFiles.kts(p), block: "android"), "ndkVersion = $expr");
}

void cmdJava(Project p, Args a) {
  final String v = a.text("dart run u:app java 17");
  if (!RegExp(r"^(1\.8|8|11|17|21|2[2-9])$").hasMatch(v)) {
    throw CliException("Use a Java version like 11, 17 or 21.");
  }
  if (!_need(p, Target.android) || !p.targets(Target.android)) {
    return;
  }
  final bool eight = v == "8" || v == "1.8";
  final String enumSuffix = eight ? "1_8" : v;
  final String target = eight ? "1.8" : v;
  Out.header("android");
  p.edit(AndroidFiles.gradle(p), (String t) {
    final String out = t
        .replaceAll(RegExp(r"JavaVersion\.VERSION_\d+(?:_\d+)?"), "JavaVersion.VERSION_$enumSuffix")
        .replaceAll(RegExp(r"JvmTarget\.JVM_\d+(?:_\d+)?"), "JvmTarget.JVM_$enumSuffix")
        .replaceAllMapped(RegExp("(jvmTarget\\s*=?\\s*)([\"'])[\\d.]+\\2"), (Match m) => "${m.group(1)}${m.group(2)}$target${m.group(2)}")
        .replaceAllMapped(RegExp(r"(jvmToolchain\()\d+(\))"), (Match m) => "${m.group(1)}${eight ? 8 : v}${m.group(2)}");
    if (!RegExp(r"JavaVersion\.|JvmTarget\.|jvmTarget|jvmToolchain").hasMatch(t)) {
      throw EditSkip("no Java / Kotlin JVM target settings found");
    }
    return out;
  }, "Java source/target + Kotlin jvmTarget = $target");
}

// =============================================================================================
// version / description

final RegExp _versionLine = RegExp(r"^version:[ \t]*([^\s#]*).*$", multiLine: true);

String? pubspecVersion(Project p) => _versionLine.firstMatch(p.read("pubspec.yaml") ?? "")?.group(1);

void _setVersion(Project p, String v) {
  Out.header("pubspec");
  p.edit("pubspec.yaml", (String t) {
    if (_versionLine.hasMatch(t)) {
      return t.replaceFirst(_versionLine, "version: $v");
    }
    final Match? name = RegExp(r"^name:.*$", multiLine: true).firstMatch(t);
    if (name == null) {
      throw EditSkip("no name: line to put version after");
    }
    return t.replaceRange(name.end, name.end, "\nversion: $v");
  }, "version: $v");
  Out.note("Every platform reads this on the next build: Android versionName/versionCode, iOS/macOS CFBundleShortVersionString/CFBundleVersion, Windows file version, web version.json.");
}

void cmdVersion(Project p, Args a) {
  final String v = a.text("dart run u:app version 1.2.0+12");
  if (!RegExp(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+\d+)?$").hasMatch(v)) {
    throw CliException("\"$v\" isn't a valid version. Use MAJOR.MINOR.PATCH+BUILD, e.g. 1.2.0+12.");
  }
  _setVersion(p, v);
}

void cmdBump(Project p, Args a) {
  final String part = a.positional.isEmpty ? "build" : a.positional.first.toLowerCase();
  final String current = pubspecVersion(p) ?? "0.0.0+0";
  final Match? m = RegExp(r"^(\d+)\.(\d+)\.(\d+)(?:-[^+]*)?(?:\+(\d+))?$").firstMatch(current);
  if (m == null) {
    throw CliException("Can't parse the current version \"$current\". Set one with `dart run u:app version 1.0.0+1`.");
  }
  int major = int.parse(m.group(1)!);
  int minor = int.parse(m.group(2)!);
  int patch = int.parse(m.group(3)!);
  final int build = int.parse(m.group(4) ?? "0") + 1;
  switch (part) {
    case "major":
      major++;
      minor = 0;
      patch = 0;
    case "minor":
      minor++;
      patch = 0;
    case "patch":
      patch++;
    case "build":
      break;
    default:
      throw CliException("Use one of: major, minor, patch, build.");
  }
  final String next = "$major.$minor.$patch+$build";
  _setVersion(p, next);
  Out.note("$current → $next");
}

void cmdDescription(Project p, Args a) {
  final String d = a.text("dart run u:app description \"What the app does\"");
  Out.header("pubspec");
  p.edit("pubspec.yaml", (String t) {
    final Match? m = RegExp(r"^description:.*(?:\n[ \t]+\S.*)*", multiLine: true).firstMatch(t);
    if (m == null) {
      final Match? name = RegExp(r"^name:.*$", multiLine: true).firstMatch(t);
      if (name == null) {
        throw EditSkip("no name: line found");
      }
      return t.replaceRange(name.end, name.end, "\ndescription: ${yamlScalar(d)}");
    }
    return t.replaceRange(m.start, m.end, "description: ${yamlScalar(d)}");
  }, "description");
  p.section(Target.web, () {
    p.edit(WebFiles.manifest, (String t) => WebFiles.jsonSet(t, "description", d), "description");
    p.edit(WebFiles.index, (String t) {
      if (!WebFiles.meta("description").hasMatch(t)) {
        throw EditSkip("<meta name=\"description\"> not found");
      }
      return t.replaceFirstMapped(WebFiles.meta("description"), (Match m) => "${m.group(1)}${htmlEscape(d)}${m.group(3)}");
    }, "<meta name=\"description\">");
  });
}

// =============================================================================================
// desktop identity

void cmdBinary(Project p, Args a) {
  final String name = a.text("dart run u:app binary my_app");
  if (!RegExp(r"^[A-Za-z0-9_][A-Za-z0-9_.-]*$").hasMatch(name)) {
    throw CliException("Use letters, digits, _ . - only (no spaces) for the executable name.");
  }
  _requireAny(p, <Target>[Target.linux, Target.windows], "binary");
  p.section(Target.linux, () => p.edit(LinuxFiles.cmake, (String t) => Cmake.set(t, "BINARY_NAME", name), "BINARY_NAME = $name"));
  p.section(Target.windows, () {
    p.edit(WindowsFiles.cmake, (String t) {
      final String out = Cmake.set(t, "BINARY_NAME", name);
      return out.replaceFirstMapped(RegExp(r"(project\(\s*)[^\s)]+"), (Match m) => "${m.group(1)}$name");
    }, "BINARY_NAME / project() = $name");
    p.edit(WindowsFiles.rc, (String t) => WindowsFiles.rcSet(WindowsFiles.rcSet(t, "InternalName", name), "OriginalFilename", "$name.exe"), "InternalName / OriginalFilename = $name.exe");
  });
  if (p.targets(Target.macos)) {
    Out.line();
    Out.note("On macOS the .app name follows `name` (PRODUCT_NAME).");
  }
}

void cmdTeam(Project p, Args a) {
  final String team = a.text("dart run u:app team ABCDE12345").toUpperCase();
  if (!RegExp(r"^[A-Z0-9]{10}$").hasMatch(team)) {
    throw CliException("An Apple Team ID is 10 letters/digits (find it at developer.apple.com → Membership).");
  }
  _requireAny(p, <Target>[Target.ios, Target.macos], "team");
  for (final AppleFiles f in <AppleFiles>[_ios, _macos]) {
    p.section(f.target, () {
      p.edit(f.pbxproj, (String t) => Pbx.setInRunner(Pbx.mapAll(t, "DEVELOPMENT_TEAM", (String _) => team), "DEVELOPMENT_TEAM", team), "DEVELOPMENT_TEAM = $team");
    });
  }
}

void cmdCompany(Project p, Args a) {
  final String company = a.text("dart run u:app company \"Acme Inc.\"");
  _requireAny(p, <Target>[Target.windows], "company");
  p.section(Target.windows, () => p.edit(WindowsFiles.rc, (String t) => WindowsFiles.rcSet(t, "CompanyName", company), "CompanyName = \"$company\""));
}

void cmdCopyright(Project p, Args a) {
  final String c = a.text("dart run u:app copyright \"© 2026 Acme Inc.\"");
  _requireAny(p, <Target>[Target.macos, Target.windows], "copyright");
  p.section(Target.macos, () => p.edit(AppleFiles.appInfo, (String t) => XcConfig.set(t, "PRODUCT_COPYRIGHT", c), "PRODUCT_COPYRIGHT = $c"));
  p.section(Target.windows, () => p.edit(WindowsFiles.rc, (String t) => WindowsFiles.rcSet(t, "LegalCopyright", c), "LegalCopyright = \"$c\""));
}

// =============================================================================================
// permissions

void cmdPermission(Project p, Args a) {
  final List<String> pos = a.positional;
  if (pos.isEmpty || pos.first == "list" || pos.first == "ls") {
    _permissionList(p);
    return;
  }
  String action = pos.first.toLowerCase();
  List<String> names = pos.skip(1).toList();
  if (!<String>{"add", "remove", "rm", "delete"}.contains(action)) {
    action = "add";
    names = pos;
  }
  final List<UPermission> perms = parsePermissions(names);
  if (action == "add") {
    _permissionAdd(p, perms, a.option("message"));
  } else {
    _permissionRemove(p, perms);
  }
}

String _names(List<UPermission> list) => list.map((UPermission x) => x.name).join(", ");

void _permissionAdd(Project p, List<UPermission> requested, String? message) {
  final List<UPermission> all = withRequirements(requested);
  final List<UPermission> extra = all.where((UPermission x) => !requested.contains(x)).toList();
  if (extra.isNotEmpty) {
    Out.note("also adding ${_names(extra)} (required)");
  }
  String? msg(UPermission x) => requested.contains(x) ? message : null;

  p.section(Target.android, () {
    final List<UPermission> list = all.where((UPermission x) => x.on(Target.android)).toList();
    if (list.isEmpty) {
      Out.note("Nothing to declare on Android for ${_names(requested)}.");
      return;
    }
    p.edit(AndroidFiles.manifest, (String t) => list.fold(t, androidAdd), "+ ${_names(list)}");
  });

  p.section(Target.ios, () {
    final List<UPermission> list = all.where((UPermission x) => x.on(Target.ios)).toList();
    if (list.isEmpty) {
      Out.note("iOS needs no declaration for ${_names(requested)}.");
      return;
    }
    editPlist(p, _ios.infoPlist, (Plist pl) {
      for (final UPermission x in list) {
        iosAdd(pl, x, msg(x));
      }
    }, "+ ${_names(list)}");
  });

  p.section(Target.macos, () {
    final List<UPermission> list = all.where((UPermission x) => x.on(Target.macos)).toList();
    if (list.isEmpty) {
      Out.note("macOS needs no declaration for ${_names(requested)}.");
      return;
    }
    final List<UPermission> withInfo = list.where((UPermission x) => x.macos.isNotEmpty).toList();
    if (withInfo.isNotEmpty) {
      editPlist(p, _macos.infoPlist, (Plist pl) {
        for (final UPermission x in withInfo) {
          macosAddInfo(pl, x, msg(x));
        }
      }, "+ ${_names(withInfo)}");
    }
    final List<String> ents = list.expand((UPermission x) => x.macEntitlements).toSet().toList();
    if (ents.isNotEmpty) {
      for (final String file in AppleFiles.entitlements) {
        editPlist(p, file, (Plist pl) {
          for (final String e in ents) {
            pl.setBool(e, value: true);
          }
        }, "+ ${ents.map((String e) => e.replaceFirst("com.apple.security.", "")).join(", ")}");
      }
    }
  });

  for (final Target t in <Target>[Target.linux, Target.windows, Target.web]) {
    p.section(t, () => Out.note(t == Target.web ? "Nothing to declare. The browser asks the user at runtime." : "Nothing to declare. ${t.id} desktop apps have no permission manifest."));
  }
  _permissionNotes(all);
}

void _permissionRemove(Project p, List<UPermission> removing) {
  for (final UPermission x in uPermissions.where((UPermission x) => !removing.contains(x))) {
    final List<String> needed = x.requires.where((String r) => removing.contains(findPermission(r))).toList();
    if (needed.isNotEmpty && Target.values.any((Target t) => p.targets(t) && declaredPermissions(p, t).contains(x.name))) {
      Out.warn("${x.name} is still declared and needs ${needed.join(", ")}. Remove ${x.name} too, or it stops working.");
    }
  }
  /// Items still needed by another permission that is fully declared and not being removed.
  bool Function(Object) keeper(Target t, bool Function(UPermission x) declared, Iterable<Object> Function(UPermission x) items) {
    final Set<Object> kept = uPermissions.where((UPermission x) => !removing.contains(x) && x.on(t) && declared(x)).expand(items).toSet();
    return kept.contains;
  }

  p.section(Target.android, () {
    final String? manifest = p.read(AndroidFiles.manifest);
    if (manifest == null) {
      Out.skip(AndroidFiles.manifest, "file not found");
      return;
    }
    final bool Function(Object) keep = keeper(
      Target.android,
      (UPermission x) => androidHas(manifest, x),
      (UPermission x) => <Object>[...x.android.map((AndroidPermission a) => a.fullName), ...x.androidFeatures],
    );
    p.edit(AndroidFiles.manifest, (String t) => removing.fold(t, (String acc, UPermission x) => androidRemove(acc, x, keep)), "− ${_names(removing)}");
  });

  p.section(Target.ios, () {
    final Plist? info = readPlist(p, _ios.infoPlist);
    if (info == null) {
      Out.skip(_ios.infoPlist, "file not found");
      return;
    }
    final bool Function(Object) keep = keeper(
      Target.ios,
      (UPermission x) => iosHas(info, x),
      (UPermission x) => <Object>[...x.ios.keys, ...x.iosFlags, ...x.iosBackgroundModes.map((String m) => "bg:$m")],
    );
    editPlist(p, _ios.infoPlist, (Plist pl) {
      for (final UPermission x in removing) {
        iosRemove(pl, x, keep);
      }
    }, "− ${_names(removing)}");
  });

  p.section(Target.macos, () {
    final Plist? info = readPlist(p, _macos.infoPlist);
    final List<Plist> ents = AppleFiles.entitlements.map((String e) => readPlist(p, e)).whereType<Plist>().toList();
    if (info == null) {
      Out.skip(_macos.infoPlist, "file not found");
      return;
    }
    final bool Function(Object) keep = keeper(Target.macos, (UPermission x) => macosHas(info, ents, x), (UPermission x) => <Object>[...x.macos.keys, ...x.macEntitlements]);
    editPlist(p, _macos.infoPlist, (Plist pl) {
      for (final String k in removing.expand((UPermission x) => x.macos.keys)) {
        if (!keep(k)) {
          pl.remove(k);
        }
      }
    }, "− ${_names(removing)}");
    for (final String file in AppleFiles.entitlements) {
      editPlist(p, file, (Plist pl) {
        for (final String e in removing.expand((UPermission x) => x.macEntitlements)) {
          if (!keep(e)) {
            pl.remove(e);
          }
        }
      }, "− ${_names(removing)}");
    }
  });
}

void _permissionNotes(List<UPermission> perms) {
  final List<UPermission> withNotes = perms.where((UPermission x) => x.note != null).toList();
  if (withNotes.isEmpty) {
    return;
  }
  Out.line();
  for (final UPermission x in withNotes) {
    Out.warn("${x.name}: ${x.note}");
  }
}

void _permissionList(Project p) {
  const List<Target> cols = <Target>[Target.android, Target.ios, Target.macos];
  final Map<Target, List<String>> declared = <Target, List<String>>{for (final Target t in cols) t: p.present(t) ? declaredPermissions(p, t) : <String>[]};
  Out.header("Permissions");
  Out.line(Out.dim("  ✓ declared in this app   · available, not declared   – nothing to declare on that platform"));
  Out.line(Out.dim("  linux / windows / web never need declarations.\n"));
  // Each column is its label plus two spaces; the mark sits under the label's middle letter.
  const Map<Target, String> labels = <Target, String>{Target.android: "android", Target.ios: "ios", Target.macos: "macos"};
  Out.line(Out.bold("  ${"name".padRight(22)}${cols.map((Target t) => "${labels[t]}  ").join()} what it's for"));
  for (final UPermission x in uPermissions) {
    final String marks = cols.map((Target t) {
      final String mark = !x.on(t) ? Out.dim("–") : (declared[t]!.contains(x.name) ? Out.green("✓") : Out.dim("·"));
      final int width = labels[t]!.length;
      final int left = width ~/ 2;
      return "${" " * left}$mark${" " * (width - left - 1)}  ";
    }).join();
    final String aliases = x.aliases.isEmpty ? "" : Out.dim("  (also: ${x.aliases.join(", ")})");
    Out.line("  ${x.name.padRight(22)}$marks ${x.summary}$aliases");
  }
  Out.line();
  Out.line(Out.dim("  Add:     dart run u:app permission add camera location"));
  Out.line(Out.dim("  Remove:  dart run u:app permission remove camera"));
  Out.line(Out.dim("  Custom iOS/macOS prompt text:  --message \"Why you need it\""));
}

// =============================================================================================
// orientation

void cmdOrientation(Project p, Args a) {
  final String raw = a.text("dart run u:app orientation portrait|landscape|all").toLowerCase();
  final String mode = switch (raw) {
    "portrait" || "vertical" => "portrait",
    "landscape" || "horizontal" => "landscape",
    "all" || "any" || "auto" || "both" || "free" => "all",
    _ => throw CliException("Use portrait, landscape or all."),
  };
  _requireAny(p, <Target>[Target.android, Target.ios, Target.web], "orientation");

  p.section(Target.android, () {
    final String? value = switch (mode) {
      "portrait" => "portrait",
      "landscape" => "sensorLandscape",
      _ => null,
    };
    p.edit(AndroidFiles.manifest, (String t) {
      final (int, int)? act = Xml.launcherActivity(t);
      if (act == null) {
        throw EditSkip("<activity> not found");
      }
      final (int, int) tag = Xml.openTag(t, "activity", act.$1)!;
      return t.replaceRange(tag.$1, tag.$2, Xml.setAttr(t.substring(tag.$1, tag.$2), "android:screenOrientation", value));
    }, value == null ? "screenOrientation removed (follows the device)" : "screenOrientation = $value");
    if (value != null) {
      Out.note("Android 16+ ignores orientation locks on large screens (tablets, foldables, 600dp+).");
    }
  });

  p.section(Target.ios, () {
    const String up = "UIInterfaceOrientationPortrait";
    const String down = "UIInterfaceOrientationPortraitUpsideDown";
    const String left = "UIInterfaceOrientationLandscapeLeft";
    const String right = "UIInterfaceOrientationLandscapeRight";
    final List<String> phone = switch (mode) {
      "portrait" => <String>[up],
      "landscape" => <String>[left, right],
      _ => <String>[up, left, right],
    };
    final List<String> pad = switch (mode) {
      "portrait" => <String>[up, down],
      "landscape" => <String>[left, right],
      _ => <String>[up, down, left, right],
    };
    editPlist(p, _ios.infoPlist, (Plist pl) {
      pl.setStringArray("UISupportedInterfaceOrientations", phone);
      pl.setStringArray("UISupportedInterfaceOrientations~ipad", pad);
      if (mode == "all") {
        pl.remove("UIRequiresFullScreen");
      } else {
        pl.setBool("UIRequiresFullScreen", value: true);
      }
    }, "orientations = $mode${mode == "all" ? "" : " (+ UIRequiresFullScreen for iPad)"}");
  });

  p.section(Target.web, () {
    final String value = switch (mode) {
      "portrait" => "portrait-primary",
      "landscape" => "landscape",
      _ => "any",
    };
    p.edit(WebFiles.manifest, (String t) => WebFiles.jsonSet(t, "orientation", value), "orientation = $value");
  });

  for (final Target t in <Target>[Target.macos, Target.linux, Target.windows]) {
    p.section(t, () => Out.note("Desktop windows have no orientation. Nothing to change."));
  }
  Out.line();
  Out.note("To lock it at runtime too, use SystemChrome.setPreferredOrientations in main().");
}

// =============================================================================================
// deep links

void cmdDeepLink(Project p, Args a) {
  final List<String> pos = a.positional;
  final bool remove = pos.isNotEmpty && <String>{"remove", "rm", "delete"}.contains(pos.first.toLowerCase());
  final List<String> rest = pos.isNotEmpty && <String>{"add", "remove", "rm", "delete"}.contains(pos.first.toLowerCase()) ? pos.skip(1).toList() : pos;
  if (rest.isEmpty) {
    throw CliException("Name the URL scheme.\n  Usage: dart run u:app deep-link myapp   |   dart run u:app deep-link remove myapp");
  }
  final String input = rest.first.replaceAll(RegExp(r"://.*$"), "");
  final String scheme = input.toLowerCase();
  if (!RegExp(r"^[a-z][a-z0-9+.-]*$").hasMatch(scheme)) {
    throw CliException("\"$input\" isn't a valid URL scheme: start with a letter, then letters, digits, + . -");
  }
  if (<String>{"http", "https"}.contains(scheme)) {
    throw CliException("http/https links (App Links / Universal Links) need a verified domain. This command registers custom schemes like myapp://");
  }
  final String? host = a.option("host");
  _requireAny(p, <Target>[Target.android, Target.ios, Target.macos], "deep-link");

  p.section(Target.android, () {
    p.edit(AndroidFiles.manifest, (String t) => remove ? _androidRemoveScheme(t, scheme) : _androidAddScheme(t, scheme, host), remove ? "− $scheme://" : "+ intent-filter for $scheme://${host ?? ""}");
  });
  for (final AppleFiles f in <AppleFiles>[_ios, _macos]) {
    p.section(f.target, () {
      editPlist(p, f.infoPlist, (Plist pl) => remove ? _appleRemoveScheme(pl, scheme) : _appleAddScheme(pl, scheme), remove ? "− CFBundleURLTypes $scheme" : "+ CFBundleURLTypes $scheme");
    });
  }
  for (final Target t in <Target>[Target.linux, Target.windows, Target.web]) {
    p.section(t, () => Out.note(t == Target.web ? "Web apps can't register URL schemes." : "On ${t.id} the installer registers URL schemes, not the Flutter project."));
  }
  if (!remove) {
    Out.line();
    Out.note("Test: open $scheme://anything on the device. Read it in Dart with the app_links package or Flutter's deep-link routing.");
  }
}

String _androidAddScheme(String t, String scheme, String? host) {
  final (int, int)? act = Xml.launcherActivity(t);
  if (act == null) {
    throw EditSkip("<activity> not found");
  }
  final String block = t.substring(act.$1, act.$2);
  if (block.contains("android:scheme=\"$scheme\"")) {
    return t;
  }
  final int close = block.lastIndexOf("</activity>");
  if (close < 0) {
    throw EditSkip("the launcher <activity> has no closing tag");
  }
  final Match? existing = RegExp(r"^([ \t]*)<intent-filter", multiLine: true).firstMatch(block);
  final String ind = existing?.group(1) ?? "${indentAt(t, act.$1)}    ";
  final String i2 = "$ind    ";
  final String data = host == null ? "<data android:scheme=\"$scheme\" />" : "<data android:scheme=\"$scheme\" android:host=\"${xmlEscape(host)}\" />";
  final String filter =
      "$ind<intent-filter>\n"
      "$i2<action android:name=\"android.intent.action.VIEW\" />\n"
      "$i2<category android:name=\"android.intent.category.DEFAULT\" />\n"
      "$i2<category android:name=\"android.intent.category.BROWSABLE\" />\n"
      "$i2$data\n"
      "$ind</intent-filter>\n";
  final int at = lineStart(t, act.$1 + close);
  return t.replaceRange(at, at, filter);
}

String _androidRemoveScheme(String t, String scheme) {
  final (int, int)? act = Xml.launcherActivity(t);
  if (act == null) {
    throw EditSkip("<activity> not found");
  }
  final String block = t.substring(act.$1, act.$2);
  final String next = block.replaceAllMapped(RegExp(r"[ \t]*<intent-filter[^>]*>[\s\S]*?</intent-filter>[ \t]*\n?"), (Match m) => m.group(0)!.contains("android:scheme=\"$scheme\"") ? "" : m.group(0)!);
  return t.replaceRange(act.$1, act.$2, next);
}

final RegExp _urlSchemesArray = RegExp(r"(<key>CFBundleURLSchemes</key>\s*<array>)([\s\S]*?)(</array>)");

void _appleAddScheme(Plist pl, String scheme) {
  final String? raw = pl.raw("CFBundleURLTypes");
  if (raw != null && _urlSchemesArray.allMatches(raw).any((Match m) => m.group(2)!.contains("<string>$scheme</string>"))) {
    return;
  }
  String dict(String indent) =>
      "$indent\t<dict>\n"
      "$indent\t\t<key>CFBundleTypeRole</key>\n"
      "$indent\t\t<string>Editor</string>\n"
      "$indent\t\t<key>CFBundleURLName</key>\n"
      "$indent\t\t<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>\n"
      "$indent\t\t<key>CFBundleURLSchemes</key>\n"
      "$indent\t\t<array>\n"
      "$indent\t\t\t<string>$scheme</string>\n"
      "$indent\t\t</array>\n"
      "$indent\t</dict>\n";
  pl.setRaw("CFBundleURLTypes", (String indent) {
    if (raw == null || !raw.startsWith("<array>")) {
      return "<array>\n${dict(indent)}$indent</array>";
    }
    final int close = raw.lastIndexOf("</array>");
    final int at = lineStart(raw, close);
    return raw.replaceRange(at, at, dict(indent));
  });
}

void _appleRemoveScheme(Plist pl, String scheme) {
  final String? raw = pl.raw("CFBundleURLTypes");
  if (raw == null) {
    return;
  }
  final String next = raw.replaceAllMapped(RegExp(r"[ \t]*<dict>[\s\S]*?</dict>[ \t]*\n?"), (Match d) {
    final Match? arr = _urlSchemesArray.firstMatch(d.group(0)!);
    if (arr == null || !arr.group(2)!.contains("<string>$scheme</string>")) {
      return d.group(0)!;
    }
    final String inner = arr.group(2)!.replaceAll(RegExp("[ \\t]*<string>${RegExp.escape(scheme)}</string>[ \\t]*\\n?"), "");
    if (!inner.contains("<string>")) {
      return "";
    }
    return d.group(0)!.replaceRange(arr.start, arr.end, "${arr.group(1)}$inner${arr.group(3)}");
  });
  if (!next.contains("<dict>")) {
    pl.remove("CFBundleURLTypes");
  } else {
    pl.setRaw("CFBundleURLTypes", (String _) => next);
  }
}

// =============================================================================================
// web

void cmdWebColor(Project p, Args a) {
  String norm(String v) {
    final String h = v.startsWith("#") ? v.substring(1) : v;
    if (!RegExp(r"^[0-9a-fA-F]{6}$").hasMatch(h)) {
      throw CliException("\"$v\" isn't a hex color like #0175C2.");
    }
    return "#${h.toUpperCase()}";
  }

  final String theme = norm(a.text("dart run u:app web-color \"#0175C2\" [--background \"#FFFFFF\"]"));
  final String bg = norm(a.option("background") ?? theme);
  _requireAny(p, <Target>[Target.web], "web-color");
  p.section(Target.web, () {
    p.edit(WebFiles.manifest, (String t) => WebFiles.jsonSet(WebFiles.jsonSet(t, "theme_color", theme), "background_color", bg), "theme_color = $theme, background_color = $bg");
    p.edit(WebFiles.index, (String t) {
      if (WebFiles.meta("theme-color").hasMatch(t)) {
        return t.replaceFirstMapped(WebFiles.meta("theme-color"), (Match m) => "${m.group(1)}$theme${m.group(3)}");
      }
      final int head = t.indexOf("</head>");
      if (head < 0) {
        throw EditSkip("</head> not found");
      }
      final int at = lineStart(t, head);
      return t.replaceRange(at, at, "  <meta name=\"theme-color\" content=\"$theme\">\n");
    }, "<meta name=\"theme-color\"> = $theme");
  });
}

// =============================================================================================
// Android release signing

Future<void> cmdSigning(Project p, Args a) async {
  if (!_need(p, Target.android)) {
    return;
  }
  Out.header("android");
  final _Keystore k = a.flag("create") ? await _createKeystoreWizard(p, a) : _existingKeystoreWizard(p, a);

  // Gradle's file() resolves against android/app, so a keystore inside the project is stored
  // relative to it: the project keeps working after it's moved or cloned somewhere else.
  final String rootPrefix = "${p.root}${Platform.pathSeparator}";
  final String storeFile = k.path.startsWith(rootPrefix) ? "../../${k.path.substring(rootPrefix.length).replaceAll("\\", "/")}" : k.path.replaceAll("\\", "/");
  String prop(String v) => v.replaceAll("\\", "\\\\");
  p.write(
    AndroidFiles.keyProperties,
    "storePassword=${prop(k.storePassword)}\nkeyPassword=${prop(k.keyPassword)}\nkeyAlias=${k.alias}\nstoreFile=$storeFile\n",
    "passwords + alias + storeFile=$storeFile",
  );

  final bool kts = AndroidFiles.kts(p);
  p.edit(AndroidFiles.gradle(p), (String t) => kts ? _signingKts(t) : _signingGroovy(t), "release builds are signed with key.properties");

  String ignore(String t, List<String> lines) {
    String out = t.isEmpty || t.endsWith("\n") ? t : "$t\n";
    final List<String> missing = lines.where((String l) => !RegExp("^${RegExp.escape(l)}\\s*\$", multiLine: true).hasMatch(out)).toList();
    if (missing.isNotEmpty) {
      out += "\n# Android signing secrets (dart run u:app signing)\n${missing.join("\n")}\n";
    }
    return out;
  }

  if (!p.exists(".gitignore")) {
    p.write(".gitignore", "", "created");
  }
  p.edit(".gitignore", (String t) => ignore(t, <String>["*.jks", "*.keystore", "key.properties"]), "ignores *.jks / *.keystore / key.properties");
  p.edit("android/.gitignore", (String t) => ignore(t, <String>["key.properties", "**/*.jks", "**/*.keystore"]), "ignores key.properties / *.jks", optional: true);

  Out.line();
  Out.note("From now on every `flutter build apk --release` / `flutter build appbundle` is signed with this key.");
  Out.warn("The .jks and key.properties are git-ignored, so git won't save them. Back up ${k.path} and both passwords somewhere safe. Without them you can't publish updates.");
}

class _Keystore {
  const _Keystore(this.path, this.storePassword, this.alias, this.keyPassword);

  final String path;
  final String storePassword;
  final String alias;
  final String keyPassword;
}

/// Asks the same questions as Android Studio's "New Key Store" dialog, then creates the .jks.
Future<_Keystore> _createKeystoreWizard(Project p, Args a) async {
  final String defaultPath = a.option("keystore") ?? "${p.root}${Platform.pathSeparator}upload-keystore.jks";
  Out.line(Out.dim("  Creating a new upload keystore. Press Enter to keep the value in [brackets].\n"));

  Out.line(Out.bold("  Key store"));
  final String path = _askUntil("Path", defaultPath, (String v) {
    final String full = _absolute(v);
    if (File(full).existsSync()) {
      return "$full already exists. Pick another name, or run without --create to use it.";
    }
    return full.endsWith(".jks") || full.endsWith(".keystore") ? null : "Use a .jks file name.";
  }, map: _absolute);
  final String storePassword = _askNewPassword("Password", "Confirm");

  Out.line(Out.bold("\n  Key"));
  final String alias = _askUntil("Alias", "upload", (String v) => RegExp(r"^[A-Za-z0-9_.-]+$").hasMatch(v) ? null : "Use letters, digits, _ . - only.");
  final String keyPassword = _askNewPassword("Password", "Confirm", sameAs: storePassword);
  final int years = int.parse(_askUntil("Validity (years)", "25", (String v) {
    final int? n = int.tryParse(v);
    return n != null && n >= 1 && n <= 100 ? null : "Enter a number of years (Google Play needs 25+).";
  }));

  Out.line(Out.bold("\n  Certificate") + Out.dim("  (at least one field)"));
  final String name = _ask("First and last name");
  final String unit = _ask("Organizational unit");
  final String org = _ask("Organization");
  final String city = _ask("City or locality");
  final String state = _ask("State or province");
  final String country = _askUntil("Country code (XX)", "", (String v) => v.isEmpty || RegExp(r"^[A-Za-z]{2}$").hasMatch(v) ? null : "Two letters, e.g. IR, US, DE.").toUpperCase();

  String esc(String v) => v.replaceAllMapped(RegExp(r'[,+"\\<>;=]'), (Match m) => "\\${m.group(0)}");
  final List<String> dn = <String>[
    if (name.isNotEmpty) "CN=${esc(name)}",
    if (unit.isNotEmpty) "OU=${esc(unit)}",
    if (org.isNotEmpty) "O=${esc(org)}",
    if (city.isNotEmpty) "L=${esc(city)}",
    if (state.isNotEmpty) "ST=${esc(state)}",
    if (country.isNotEmpty) "C=$country",
  ];
  if (dn.isEmpty) {
    dn.add("CN=${esc(androidName(p) ?? "Android")}");
    Out.note("No certificate fields given, using ${dn.first}");
  }
  if (years < 25) {
    Out.warn("Google Play requires keys valid until at least 2033. 25+ years is recommended.");
  }

  Out.line();
  if (!_confirm("Create $path?")) {
    throw CliException("Cancelled. Nothing was written.");
  }
  p.changes++;
  if (p.dryRun) {
    Out.changed(path, "new keystore, alias $alias, $years years, ${dn.join(", ")}", dryRun: true);
  } else {
    File(path).parent.createSync(recursive: true);
    final int code = await _keytool(
      <String>[
        "-genkeypair", "-noprompt", //
        "-keystore", path, "-storetype", "JKS", "-alias", alias,
        "-keyalg", "RSA", "-keysize", "2048", "-validity", "${years * 365}",
        "-dname", dn.join(", "),
        // Passed through the environment, so they never appear in the process list.
        "-storepass:env", "U_KEYSTORE_PASS", "-keypass:env", "U_KEY_PASS",
      ],
      <String, String>{"U_KEYSTORE_PASS": storePassword, "U_KEY_PASS": keyPassword},
    );
    if (code != 0 || !File(path).existsSync()) {
      throw CliException("keytool failed (exit code $code).");
    }
    Out.changed(path, "new keystore, alias $alias, $years years, ${dn.join(", ")}", dryRun: false);
  }
  return _Keystore(path, storePassword, alias, keyPassword);
}

/// Points the app at a keystore that already exists.
_Keystore _existingKeystoreWizard(Project p, Args a) {
  final String defaultPath = a.option("keystore") ?? "${p.root}${Platform.pathSeparator}upload-keystore.jks";
  Out.line(Out.dim("  Using an existing keystore (add --create to make a new one). Press Enter to keep the value in [brackets].\n"));
  final String path = _askUntil("Key store path", defaultPath, (String v) => File(_absolute(v)).existsSync() ? null : "${_absolute(v)} doesn't exist.", map: _absolute);
  final String storePassword = _askSecret("Key store password");
  final String alias = _askUntil("Key alias", "upload", (String v) => v.isEmpty ? "Required." : null);
  final String keyPassword = _askSecret("Key password", fallback: storePassword, hint: "Enter = same as key store");
  return _Keystore(path, storePassword, alias, keyPassword);
}

String _absolute(String v) {
  final String home = Platform.environment["HOME"] ?? Platform.environment["USERPROFILE"] ?? "";
  final String expanded = v.startsWith("~") ? "$home${v.substring(1)}" : v;
  return File(expanded).absolute.uri.normalizePath().toFilePath();
}

/// Reads one line; works both in a terminal and with piped input.
String _readLine({bool secret = false}) {
  final bool tty = stdin.hasTerminal;
  if (secret && tty) {
    stdin.echoMode = false;
  }
  final String? line = stdin.readLineSync();
  if (secret && tty) {
    stdin.echoMode = true;
    stdout.writeln();
  }
  if (line == null) {
    throw CliException("Input ended before all questions were answered.");
  }
  return line.trim();
}

String _ask(String label, [String def = ""]) {
  stdout.write("    $label${def.isEmpty ? "" : " ${Out.dim("[$def]")}"}: ");
  final String v = _readLine();
  return v.isEmpty ? def : v;
}

/// Asks until [check] returns null (valid); [map] turns the answer into the stored value.
String _askUntil(String label, String def, String? Function(String v) check, {String Function(String v)? map}) {
  while (true) {
    final String v = _ask(label, def);
    final String? error = check(v);
    if (error == null) {
      return map == null ? v : map(v);
    }
    Out.line("      ${Out.yellow(error)}");
  }
}

String _askSecret(String label, {String? fallback, String? hint}) {
  while (true) {
    stdout.write("    $label${hint == null ? "" : " ${Out.dim("($hint)")}"}: ");
    final String v = _readLine(secret: true);
    if (v.isEmpty && fallback != null) {
      return fallback;
    }
    if (v.isNotEmpty) {
      return v;
    }
    Out.line("      ${Out.yellow("Required.")}");
  }
}

/// A new password typed twice, 6+ characters. With [sameAs], Enter reuses that password.
String _askNewPassword(String label, String confirmLabel, {String? sameAs}) {
  while (true) {
    final String first = _askSecret(label, fallback: sameAs, hint: sameAs == null ? "6+ characters" : "Enter = same as key store");
    if (identical(first, sameAs)) {
      return first;
    }
    if (first.length < 6) {
      Out.line("      ${Out.yellow("At least 6 characters.")}");
      continue;
    }
    if (_askSecret(confirmLabel) == first) {
      return first;
    }
    Out.line("      ${Out.yellow("The passwords don't match. Try again.")}");
  }
}

bool _confirm(String question) {
  stdout.write("  $question ${Out.dim("[Y/n]")}: ");
  final String v = _readLine().toLowerCase();
  return v.isEmpty || v == "y" || v == "yes";
}

/// Real keytool binaries, best first. On macOS `/usr/bin/keytool` is only a stub when no
/// default Java is set, so JDKs that Android Studio / Flutter / Homebrew install come first.
List<String> _keytoolCandidates() {
  final Map<String, String> env = Platform.environment;
  final String home = env["HOME"] ?? env["USERPROFILE"] ?? "";
  final String exe = Platform.isWindows ? "keytool.exe" : "keytool";
  final List<String> dirs = <String>[
    if (env["JAVA_HOME"] != null) "${env["JAVA_HOME"]}/bin",
  ];
  final File flutterSettings = File("$home/.config/flutter/settings");
  if (flutterSettings.existsSync()) {
    final String? jdk = RegExp(r'"jdk-dir"\s*:\s*"([^"]+)"').firstMatch(flutterSettings.readAsStringSync())?.group(1);
    if (jdk != null) {
      dirs.add("$jdk/bin");
    }
  }
  void scan(String parent, String suffix, {bool Function(String name)? where}) {
    final Directory d = Directory(parent);
    if (!d.existsSync()) {
      return;
    }
    final List<FileSystemEntity> items = d.listSync()..sort((FileSystemEntity x, FileSystemEntity y) => y.path.compareTo(x.path));
    for (final FileSystemEntity e in items) {
      if (where == null || where(e.path.split(Platform.pathSeparator).last)) {
        dirs.add("${e.path}$suffix");
      }
    }
  }

  if (Platform.isMacOS) {
    for (final String apps in <String>["/Applications", "$home/Applications"]) {
      scan(apps, "/Contents/jbr/Contents/Home/bin", where: (String n) => n.startsWith("Android Studio"));
    }
    scan("/Library/Java/JavaVirtualMachines", "/Contents/Home/bin");
    scan("$home/Library/Java/JavaVirtualMachines", "/Contents/Home/bin");
    scan("/opt/homebrew/opt", "/bin", where: (String n) => n.startsWith("openjdk"));
    scan("/usr/local/opt", "/bin", where: (String n) => n.startsWith("openjdk"));
  } else if (Platform.isWindows) {
    dirs.add(r"C:\Program Files\Android\Android Studio\jbr\bin");
    scan(r"C:\Program Files\Java", r"\bin");
    scan(r"C:\Program Files\Eclipse Adoptium", r"\bin");
  } else {
    dirs.addAll(<String>["/opt/android-studio/jbr/bin", "$home/android-studio/jbr/bin", "/snap/android-studio/current/jbr/bin"]);
    scan("/usr/lib/jvm", "/bin");
  }
  return <String>[
    ...dirs.map((String d) => "$d${Platform.pathSeparator}$exe").where((String f) => File(f).existsSync()),
    exe,
  ];
}

/// Runs keytool quietly; its output (e.g. the JKS-format advice) is only shown when it fails.
Future<int> _keytool(List<String> args, Map<String, String> environment) async {
  for (final String exe in _keytoolCandidates()) {
    try {
      final ProcessResult r = await Process.run(exe, args, environment: environment);
      if (r.exitCode != 0) {
        Out.line("${r.stdout}${r.stderr}".trim());
      }
      return r.exitCode;
    } on ProcessException {
      continue;
    }
  }
  throw CliException("keytool not found. Install a JDK or Android Studio, or set JAVA_HOME.");
}

String _signingKts(String t) {
  String out = t;
  if (!out.contains("keystoreProperties")) {
    if (!out.contains("import java.util.Properties")) {
      out = "import java.util.Properties\n${out.contains("import java.io.FileInputStream") ? "" : "import java.io.FileInputStream\n"}\n$out";
    }
    final Match? android = RegExp(r"^android\s*\{", multiLine: true).firstMatch(out);
    if (android == null) {
      throw EditSkip("android { } block not found");
    }
    out = out.replaceRange(
      android.start,
      android.start,
      "val keystoreProperties = Properties()\n"
      "val keystorePropertiesFile = rootProject.file(\"key.properties\")\n"
      "if (keystorePropertiesFile.exists()) {\n"
      "    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n"
      "}\n\n",
    );
  }
  if (!RegExp(r"signingConfigs\s*\{").hasMatch(out)) {
    final Match? buildTypes = RegExp(r"^([ \t]*)buildTypes\s*\{", multiLine: true).firstMatch(out);
    if (buildTypes == null) {
      throw EditSkip("buildTypes { } block not found");
    }
    final String i = buildTypes.group(1)!;
    out = out.replaceRange(
      buildTypes.start,
      buildTypes.start,
      "${i}signingConfigs {\n"
      "$i    create(\"release\") {\n"
      "$i        keyAlias = keystoreProperties[\"keyAlias\"] as String?\n"
      "$i        keyPassword = keystoreProperties[\"keyPassword\"] as String?\n"
      "$i        storeFile = keystoreProperties[\"storeFile\"]?.let { file(it) }\n"
      "$i        storePassword = keystoreProperties[\"storePassword\"] as String?\n"
      "$i    }\n"
      "$i}\n\n",
    );
  }
  const String use = "signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName(\"release\") else signingConfigs.getByName(\"debug\")";
  final RegExp existing = RegExp(r'signingConfig\s*=\s*signingConfigs\.getByName\("(?:debug|release)"\)');
  if (existing.hasMatch(out)) {
    return out.replaceFirst(existing, use);
  }
  if (out.contains(use)) {
    return out;
  }
  final Match? release = RegExp(r'^([ \t]*)(?:release|getByName\("release"\))\s*\{[ \t]*$', multiLine: true).allMatches(out).lastOrNull;
  if (release == null) {
    throw EditSkip("buildTypes.release { } block not found");
  }
  return out.replaceRange(release.end, release.end, "\n${release.group(1)}    $use");
}

String _signingGroovy(String t) {
  String out = t;
  if (!out.contains("keystoreProperties")) {
    final Match? android = RegExp(r"^android\s*\{", multiLine: true).firstMatch(out);
    if (android == null) {
      throw EditSkip("android { } block not found");
    }
    out = out.replaceRange(
      android.start,
      android.start,
      "def keystoreProperties = new Properties()\n"
      "def keystorePropertiesFile = rootProject.file('key.properties')\n"
      "if (keystorePropertiesFile.exists()) {\n"
      "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
      "}\n\n",
    );
  }
  if (!RegExp(r"signingConfigs\s*\{").hasMatch(out)) {
    final Match? buildTypes = RegExp(r"^([ \t]*)buildTypes\s*\{", multiLine: true).firstMatch(out);
    if (buildTypes == null) {
      throw EditSkip("buildTypes { } block not found");
    }
    final String i = buildTypes.group(1)!;
    out = out.replaceRange(
      buildTypes.start,
      buildTypes.start,
      "${i}signingConfigs {\n"
      "$i    release {\n"
      "$i        keyAlias keystoreProperties['keyAlias']\n"
      "$i        keyPassword keystoreProperties['keyPassword']\n"
      "$i        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null\n"
      "$i        storePassword keystoreProperties['storePassword']\n"
      "$i    }\n"
      "$i}\n\n",
    );
  }
  const String use = "signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug";
  final RegExp existing = RegExp(r"signingConfig\s*=?\s*signingConfigs\.(?:debug|release)(?!\s*:)");
  if (out.contains(use)) {
    return out;
  }
  if (existing.hasMatch(out)) {
    return out.replaceFirst(existing, use);
  }
  final Match? release = RegExp(r"^([ \t]*)release\s*\{[ \t]*$", multiLine: true).allMatches(out).lastOrNull;
  if (release == null) {
    throw EditSkip("buildTypes.release { } block not found");
  }
  return out.replaceRange(release.end, release.end, "\n${release.group(1)}    $use");
}
