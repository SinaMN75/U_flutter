import "dart:io";

import "package:u/src/cli/core.dart";
import "package:u/src/cli/platforms.dart";

/// Versions a Flutter SDK uses for a new Android app.
class FlutterToolchain {
  const FlutterToolchain({
    required this.agp,
    required this.gradle,
    required this.kotlin,
    required this.java,
    required this.compileSdk,
    required this.targetSdk,
    required this.ndk,
    required this.fromSdk,
    this.flutterVersion,
  });

  final String agp;
  final String gradle;
  final String kotlin;
  final String java;
  final String compileSdk;
  final String targetSdk;
  final String ndk;
  final bool fromSdk;
  final String? flutterVersion;

  /// Used when this machine's Flutter SDK cannot be read.
  static const FlutterToolchain fallback = FlutterToolchain(
    agp: "9.3.1",
    gradle: "9.5.0",
    kotlin: "2.4.20",
    java: "17",
    compileSdk: "36",
    targetSdk: "36",
    ndk: "28.2.13676358",
    fromSdk: false,
  );

  /// Reads `gradle_utils.dart` from the Flutter SDK this project (or `flutter` on PATH) uses.
  static FlutterToolchain load(Project p) {
    final String? sdk = _sdkPath(p);
    if (sdk == null) {
      return fallback;
    }
    final File utils = File("$sdk/packages/flutter_tools/lib/src/android/gradle_utils.dart");
    if (!utils.existsSync()) {
      return fallback;
    }
    final String text = utils.readAsStringSync();
    final String? agp = _constString(text, "templateAndroidGradlePluginVersion");
    final String? gradle = _constString(text, "templateDefaultGradleVersion");
    final String? kotlin = _constString(text, "templateKotlinGradlePluginVersion");
    if (agp == null || gradle == null || kotlin == null) {
      return fallback;
    }
    return FlutterToolchain(
      agp: agp,
      gradle: gradle,
      kotlin: kotlin,
      java: RegExp(r"errorJavaMinVersionAndroid = Version\((\d+)").firstMatch(text)?.group(1) ?? "17",
      compileSdk: RegExp(r"const compileSdkVersionInt = (\d+)").firstMatch(text)?.group(1) ?? "36",
      targetSdk: _constString(text, "targetSdkVersion") ?? "36",
      ndk: _constString(text, "ndkVersion") ?? "28.2.13676358",
      flutterVersion: _flutterVersion(sdk),
      fromSdk: true,
    );
  }

  String get source => fromSdk ? "Flutter ${flutterVersion ?? "SDK"} ships" : "Built-in set is";
}

/// Negative when [a] is older than [b]. Missing pieces count as 0, so `9.5` equals `9.5.0`.
int compareVersions(String a, String b) {
  final List<int> pa = a.split(".").map((String s) => int.tryParse(s) ?? 0).toList();
  final List<int> pb = b.split(".").map((String s) => int.tryParse(s) ?? 0).toList();
  final int n = pa.length > pb.length ? pa.length : pb.length;
  for (int i = 0; i < n; i++) {
    final int d = (i < pa.length ? pa[i] : 0) - (i < pb.length ? pb[i] : 0);
    if (d != 0) {
      return d < 0 ? -1 : 1;
    }
  }
  return 0;
}

// Minimum Gradle for an AGP line. https://developer.android.com/build/releases/about-agp
String? minGradleForAgp(String agp) {
  final List<String> parts = agp.split(".");
  final int? major = int.tryParse(parts.first);
  final int? minor = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (major != 9 || minor == null) {
    return null;
  }
  if (minor >= 5) {
    return "9.6.0";
  }
  return const <int, String>{0: "9.1.0", 1: "9.3.1", 2: "9.4.1", 3: "9.5.0", 4: "9.6.0"}[minor];
}

final RegExp _agpId = RegExp("id\\s*\\(?\\s*[\"']com\\.android\\.(?:application|library)[\"']\\s*\\)?\\s*version\\s*[\"']([^\"']+)[\"']");
final RegExp _agpClasspath = RegExp("com\\.android\\.tools\\.build:gradle:(\\d[^\"'\\s)]*)");
final RegExp _kotlinId = RegExp("id\\s*\\(?\\s*[\"']org\\.jetbrains\\.kotlin\\.android[\"']\\s*\\)?\\s*version\\s*[\"']([^\"']+)[\"']");
final RegExp _kotlinVar = RegExp("((?:kotlinVersion|kotlin_version)\\s*=\\s*[\"'])(\\d[^\"']*)([\"'])");
final RegExp _kotlinClasspath = RegExp("org\\.jetbrains\\.kotlin:kotlin-gradle-plugin:(\\d[^\"'\\s)]*)");
final RegExp _gradleUrl = RegExp(r"gradle-(\d+\.\d+(?:\.\d+)?)-(all|bin)\.zip");

String? readAgpVersion(String? text) {
  if (text == null) {
    return null;
  }
  return _agpId.firstMatch(text)?.group(1) ?? _agpClasspath.firstMatch(text)?.group(1);
}

String? readKotlinVersion(String? text) {
  if (text == null) {
    return null;
  }
  return _kotlinId.firstMatch(text)?.group(1) ?? _kotlinVar.firstMatch(text)?.group(2) ?? _kotlinClasspath.firstMatch(text)?.group(1);
}

String? readWrapperGradle(String? text) => text == null ? null : _gradleUrl.firstMatch(text)?.group(1);

/// Prints doctor warnings when Android is behind the Flutter SDK this machine has.
void warnToolchain(Project p, void Function(String message) warn) {
  final FlutterToolchain sdk = FlutterToolchain.load(p);
  final String? settings = _text(p, AndroidFiles.settings(p));
  final String? root = _text(p, AndroidFiles.rootBuild(p));
  final String? app = p.read(AndroidFiles.gradle(p));
  final String? agp = readAgpVersion(settings) ?? readAgpVersion(root) ?? readAgpVersion(app);
  final String? kotlin = readKotlinVersion(settings) ?? readKotlinVersion(root) ?? readKotlinVersion(app);
  final String? gradle = readWrapperGradle(p.read(AndroidFiles.wrapper));
  final int? java = Gradle.jvmVersion(app) ?? Gradle.jvmVersion(root);
  if (agp != null && compareVersions(agp, sdk.agp) < 0) {
    warn("Android Gradle Plugin is $agp. ${sdk.source} ${sdk.agp}. Fix: dart run u:app toolchain");
  }
  if (kotlin != null && compareVersions(kotlin, sdk.kotlin) < 0) {
    warn("Kotlin is $kotlin. ${sdk.source} ${sdk.kotlin}. Fix: dart run u:app toolchain");
  }
  if (gradle != null && compareVersions(gradle, sdk.gradle) < 0) {
    warn("Gradle is $gradle. ${sdk.source} ${sdk.gradle}. Fix: dart run u:app toolchain");
  }
  final String? floor = agp == null ? null : minGradleForAgp(agp);
  if (gradle != null && floor != null && compareVersions(gradle, floor) < 0) {
    warn("Gradle $gradle is older than Android Gradle Plugin $agp needs ($floor). Fix: dart run u:app toolchain");
  }
  final int? javaFloor = int.tryParse(sdk.java);
  if (java != null && javaFloor != null && java < javaFloor) {
    warn("Java is $java. ${sdk.source} Java $javaFloor. Fix: dart run u:app toolchain");
  }
}

void cmdToolchain(Project p, Args a) {
  if (p.only != null && !p.only!.contains(Target.android)) {
    throw CliException("toolchain only changes Android. Drop --platforms, or include android.");
  }
  if (!p.isPlugin && !p.present(Target.android)) {
    Out.header("android");
    Out.warn("This app has no android/ folder.");
    return;
  }
  if (p.isPlugin && AndroidFiles.rootBuild(p) == null) {
    throw CliException("This plugin has no android/build.gradle.");
  }
  final FlutterToolchain sdk = FlutterToolchain.load(p);
  final _Want want = _resolve(a, sdk);
  Out.header("android");
  if (sdk.fromSdk) {
    Out.note("${sdk.source} AGP ${sdk.agp}, Gradle ${sdk.gradle}, Kotlin ${sdk.kotlin}, Java ${sdk.java}.");
  } else {
    Out.warn("Couldn't read the Flutter SDK. Using AGP ${sdk.agp}, Gradle ${sdk.gradle}, Kotlin ${sdk.kotlin}, Java ${sdk.java}.");
  }
  final String? floor = minGradleForAgp(want.agp);
  if (want.explicit("gradle") && floor != null && compareVersions(want.gradle, floor) < 0) {
    Out.warn("Gradle ${want.gradle} is older than Android Gradle Plugin ${want.agp} needs ($floor).");
  }
  if (p.exists(AndroidFiles.wrapper)) {
    _bump(p, AndroidFiles.wrapper, readWrapperGradle, _writeGradle, want.gradle, "Gradle", exact: want.explicit("gradle"));
  } else if (!p.isPlugin) {
    Out.skip(AndroidFiles.wrapper, "file not found");
  }
  bool sawKotlin = false;
  bool followsFlutter = false;
  for (final String rel in _gradleFiles(p)) {
    if (readKotlinVersion(p.read(rel)) != null) {
      sawKotlin = true;
    }
    _bump(p, rel, readAgpVersion, _writeAgp, want.agp, "Android Gradle Plugin", exact: want.explicit("agp"));
    _bump(p, rel, readKotlinVersion, _writeKotlin, want.kotlin, "Kotlin", exact: want.explicit("kotlin"));
    _bumpJava(p, rel, want.java, exact: want.explicit("java"));
    _bumpSdk(p, rel, <String>["compileSdk", "compileSdkVersion"], "android", "compileSdk", want.compileSdk, exact: want.explicit("compile-sdk"), onFlutter: () => followsFlutter = true);
    _bumpSdk(p, rel, <String>["targetSdk", "targetSdkVersion"], "defaultConfig", "targetSdk", want.targetSdk, exact: want.explicit("target-sdk"), onFlutter: () => followsFlutter = true);
    _bumpNdk(p, rel, want.ndk, exact: want.explicit("ndk"), onFlutter: () => followsFlutter = true);
  }
  if (!sawKotlin) {
    Out.note("No Kotlin version is pinned. Flutter supplies it.");
  }
  if (followsFlutter) {
    Out.note("compileSdk, targetSdk and ndk that say flutter.* stay on the Flutter SDK. Pass --compile-sdk, --target-sdk or --ndk to pin a number.");
  }
  Out.note("The next Android build downloads a new Gradle if the wrapper changed.");
}

class _Want {
  _Want(this.agp, this.gradle, this.kotlin, this.java, this.compileSdk, this.targetSdk, this.ndk, this._explicit);

  final String agp;
  final String gradle;
  final String kotlin;
  final String java;
  final String compileSdk;
  final String targetSdk;
  final String ndk;
  final Set<String> _explicit;

  bool explicit(String name) => _explicit.contains(name);
}

_Want _resolve(Args a, FlutterToolchain sdk) {
  final Set<String> explicit = <String>{};
  String take(String name, String label, String pattern, String sample, String fallback) {
    final String? v = a.option(name);
    if (v == null) {
      return fallback;
    }
    if (!RegExp(pattern).hasMatch(v)) {
      throw CliException("\"$v\" is not an acceptable $label (for example $sample).");
    }
    explicit.add(name);
    return v;
  }

  final String agp = take("agp", "Android Gradle Plugin version", r"^\d+\.\d+(?:\.\d+)?$", "9.3.1", sdk.agp);
  String gradle = take("gradle", "Gradle version", r"^\d+\.\d+(?:\.\d+)?$", "9.5.0", sdk.gradle);
  final String? floor = minGradleForAgp(agp);
  if (!explicit.contains("gradle") && floor != null && compareVersions(gradle, floor) < 0) {
    gradle = floor;
  }
  return _Want(
    agp,
    gradle,
    take("kotlin", "Kotlin version", r"^\d+\.\d+(?:\.\d+)?$", "2.4.20", sdk.kotlin),
    take("java", "Java version", r"^(1\.8|8|11|17|21|2[2-9])$", "17", sdk.java),
    take("compile-sdk", "compileSdk level", r"^\d{1,2}$", "36", sdk.compileSdk),
    take("target-sdk", "targetSdk level", r"^\d{1,2}$", "36", sdk.targetSdk),
    take("ndk", "ndk version", r"^\d+\.\d+\.\d+$", "28.2.13676358", sdk.ndk),
    explicit,
  );
}

List<String> _gradleFiles(Project p) {
  final List<String> files = <String>[];
  final String? settings = AndroidFiles.settings(p);
  if (settings != null) {
    files.add(settings);
  }
  final String? root = AndroidFiles.rootBuild(p);
  if (root != null) {
    files.add(root);
  }
  if (!p.isPlugin && p.exists(AndroidFiles.gradle(p))) {
    files.add(AndroidFiles.gradle(p));
  }
  return files;
}

void _bump(Project p, String rel, String? Function(String? text) read, String Function(String text, String version) write, String version, String label, {required bool exact}) {
  final String? text = p.read(rel);
  final String? now = read(text);
  if (text == null || now == null) {
    return;
  }
  if (now == version || (!exact && compareVersions(now, version) >= 0)) {
    Out.same(rel, "$label $now");
    return;
  }
  p.edit(rel, (String t) => write(t, version), "$label = $version");
}

void _bumpJava(Project p, String rel, String version, {required bool exact}) {
  final String? text = p.read(rel);
  final int? now = Gradle.jvmVersion(text);
  final int? want = int.tryParse(version == "1.8" ? "8" : version);
  if (text == null || now == null || want == null) {
    return;
  }
  if (now == want || (!exact && now >= want)) {
    Out.same(rel, "Java $now");
    return;
  }
  p.edit(rel, (String t) => Gradle.applyJvm(t, version), "Java source/target + Kotlin jvmTarget = $version");
}

void _bumpSdk(Project p, String rel, List<String> keys, String block, String label, String version, {required bool exact, required void Function() onFlutter}) {
  final String? text = p.read(rel);
  if (text == null) {
    return;
  }
  final String? raw = Gradle.get(text, keys)?.trim();
  if (raw == null) {
    return;
  }
  if (raw.startsWith("flutter.")) {
    if (exact) {
      p.edit(rel, (String t) => Gradle.set(t, keys, version, kts: rel.endsWith(".kts"), block: block), "$label = $version");
    } else {
      onFlutter();
    }
    return;
  }
  if (!RegExp(r"^\d+$").hasMatch(raw)) {
    return;
  }
  if (raw == version || (!exact && compareVersions(raw, version) >= 0)) {
    Out.same(rel, "$label $raw");
    return;
  }
  p.edit(rel, (String t) => Gradle.set(t, keys, version, kts: rel.endsWith(".kts"), block: block), "$label = $version");
}

void _bumpNdk(Project p, String rel, String version, {required bool exact, required void Function() onFlutter}) {
  final String? text = p.read(rel);
  if (text == null) {
    return;
  }
  final String? raw = Gradle.get(text, <String>["ndkVersion"])?.trim();
  if (raw == null) {
    return;
  }
  if (raw.startsWith("flutter.")) {
    if (exact) {
      p.edit(rel, (String t) => Gradle.set(t, <String>["ndkVersion"], "\"$version\"", kts: rel.endsWith(".kts"), block: "android"), "ndkVersion = \"$version\"");
    } else {
      onFlutter();
    }
    return;
  }
  final String? now = Gradle.getString(text, "ndkVersion");
  if (now == null) {
    return;
  }
  if (now == version || (!exact && compareVersions(now, version) >= 0)) {
    Out.same(rel, "ndk $now");
    return;
  }
  p.edit(rel, (String t) => Gradle.set(t, <String>["ndkVersion"], "\"$version\"", kts: rel.endsWith(".kts"), block: "android"), "ndkVersion = \"$version\"");
}

String _writeGradle(String text, String version) {
  if (!_gradleUrl.hasMatch(text)) {
    throw EditSkip("no Gradle distributionUrl");
  }
  return text.replaceAllMapped(_gradleUrl, (Match m) => "gradle-$version-${m.group(2)}.zip");
}

String _writeAgp(String text, String version) => _swap(_swap(text, _agpId, version), _agpClasspath, version);

String _writeKotlin(String text, String version) {
  final String ids = _swap(_swap(text, _kotlinId, version), _kotlinClasspath, version);
  return ids.replaceAllMapped(_kotlinVar, (Match m) => "${m.group(1)}$version${m.group(3)}");
}

String _swap(String text, RegExp re, String version) => text.replaceAllMapped(re, (Match m) {
  final String full = m.group(0)!;
  final String old = m.group(1)!;
  final int at = full.lastIndexOf(old);
  return full.replaceRange(at, at + old.length, version);
});

String? _text(Project p, String? rel) => rel == null ? null : p.read(rel);

String? _constString(String text, String name) => RegExp("const $name = '([^']*)'").firstMatch(text)?.group(1);

String? _flutterVersion(String sdk) {
  final File stamp = File("$sdk/bin/cache/flutter.version.json");
  if (!stamp.existsSync()) {
    return null;
  }
  return RegExp(r'"frameworkVersion"\s*:\s*"([^"]+)"').firstMatch(stamp.readAsStringSync())?.group(1);
}

String? _sdkPath(Project p) {
  final String? fromLocal = RegExp(r"^flutter\.sdk=(.*)$", multiLine: true).firstMatch(p.read("android/local.properties") ?? "")?.group(1)?.trim();
  if (fromLocal != null && fromLocal.isNotEmpty) {
    final String path = fromLocal.replaceAll("\\\\", "\\");
    if (Directory(path).existsSync()) {
      return path;
    }
  }
  final String? env = Platform.environment["FLUTTER_ROOT"];
  if (env != null && env.isNotEmpty && Directory(env).existsSync()) {
    return env;
  }
  final ProcessResult which = Process.runSync(Platform.isWindows ? "where" : "which", <String>["flutter"], runInShell: true);
  if (which.exitCode != 0) {
    return null;
  }
  final String line = "${which.stdout}".split(RegExp(r"\r?\n")).map((String s) => s.trim()).firstWhere((String s) => s.isNotEmpty, orElse: () => "");
  if (line.isEmpty) {
    return null;
  }
  final String root = File(line).parent.parent.path;
  if (File("$root/packages/flutter_tools/lib/src/android/gradle_utils.dart").existsSync()) {
    return root;
  }
  return null;
}
