import "package:u/cli/commands.dart";
import "package:u/cli/core.dart";
import "package:u/cli/permissions.dart";
import "package:u/cli/platforms.dart";
import "package:u/cli/plist.dart";

const AppleFiles _ios = AppleFiles(Target.ios);
const AppleFiles _macos = AppleFiles(Target.macos);

void _row(String key, String? value) => Out.line("  ${Out.dim(key.padRight(16))}${value == null || value.isEmpty ? Out.dim("—") : value}");

String? _yaml(String? pubspec, String key) {
  final String? v = RegExp("^$key:[ \\t]*(.*)\$", multiLine: true).firstMatch(pubspec ?? "")?.group(1)?.trim();
  if (v == null) {
    return null;
  }
  return v.length >= 2 && v.startsWith("\"") && v.endsWith("\"") ? v.substring(1, v.length - 1) : v;
}

String _list(List<String> items) => items.isEmpty ? "" : items.join(", ");

List<String> _androidSchemes(String? manifest) => RegExp('android:scheme="([^"]+)"').allMatches(manifest ?? "").map((Match m) => m.group(1)!).toSet().toList();

List<String> _appleSchemes(Plist? info) {
  final String? raw = info?.raw("CFBundleURLTypes");
  if (raw == null) {
    return <String>[];
  }
  return RegExp(r"<key>CFBundleURLSchemes</key>\s*<array>([\s\S]*?)</array>")
      .allMatches(raw)
      .expand((Match m) => RegExp("<string>([^<]*)</string>").allMatches(m.group(1)!).map((Match s) => s.group(1)!))
      .toList();
}

String? _androidOrientation(String? manifest) {
  if (manifest == null) {
    return null;
  }
  final (int, int)? act = Xml.launcherActivity(manifest);
  if (act == null) {
    return null;
  }
  final (int, int)? tag = Xml.openTag(manifest, "activity", act.$1);
  return tag == null ? null : Xml.attr(manifest.substring(tag.$1, tag.$2), "android:screenOrientation") ?? "all (follows the device)";
}

String? _iosOrientation(Plist? info) {
  final List<String>? o = info?.getStringArray("UISupportedInterfaceOrientations");
  if (o == null) {
    return null;
  }
  final bool portrait = o.any((String s) => s.contains("Portrait"));
  final bool landscape = o.any((String s) => s.contains("Landscape"));
  return portrait && landscape ? "all" : (portrait ? "portrait" : "landscape");
}

bool _releaseUsesDebugKeys(String? gradle) {
  if (gradle == null) {
    return false;
  }
  return !gradle.contains("keystoreProperties") && RegExp(r'signingConfig\s*=?\s*signingConfigs\.(?:getByName\("debug"\)|debug)').hasMatch(gradle);
}

// =============================================================================================
// info

void cmdInfo(Project p, Args a) {
  final String? pubspec = p.read("pubspec.yaml");
  Out.line(Out.dim(p.root));
  Out.header("pubspec");
  _row("name", _yaml(pubspec, "name"));
  _row("version", pubspecVersion(p));
  _row("description", _yaml(pubspec, "description"));

  p.section(Target.android, () {
    final String? gradle = p.read(AndroidFiles.gradle(p));
    final String? manifest = p.read(AndroidFiles.manifest);
    _row("name", androidName(p));
    _row("applicationId", Gradle.getString(gradle, "applicationId"));
    final String? ns = Gradle.getString(gradle, "namespace");
    if (ns != Gradle.getString(gradle, "applicationId")) {
      _row("namespace", ns);
    }
    _row("minSdk", Gradle.display(Gradle.get(gradle, <String>["minSdk", "minSdkVersion"])));
    _row("targetSdk", Gradle.display(Gradle.get(gradle, <String>["targetSdk", "targetSdkVersion"])));
    _row("compileSdk", Gradle.display(Gradle.get(gradle, <String>["compileSdk", "compileSdkVersion"])));
    _row("ndkVersion", Gradle.display(Gradle.get(gradle, <String>["ndkVersion"])));
    _row("orientation", _androidOrientation(manifest));
    _row("permissions", _list(declaredPermissions(p, Target.android)));
    _row("deep links", _list(_androidSchemes(manifest).map((String s) => "$s://").toList()));
    _row("release keys", p.exists(AndroidFiles.keyProperties) ? "key.properties" : (_releaseUsesDebugKeys(gradle) ? Out.yellow("debug keys") : null));
  });

  p.section(Target.ios, () {
    final Plist? info = readPlist(p, _ios.infoPlist);
    final String? pbx = p.read(_ios.pbxproj);
    _row("name", info?.getString("CFBundleDisplayName") ?? info?.getString("CFBundleName"));
    _row("bundle id", iosId(p));
    _row("min iOS", appleMin(p, _ios));
    _row("team", Pbx.runnerValues(pbx, "DEVELOPMENT_TEAM").firstOrNull);
    _row("orientation", _iosOrientation(info));
    _row("permissions", _list(declaredPermissions(p, Target.ios)));
    _row("deep links", _list(_appleSchemes(info).map((String s) => "$s://").toList()));
  });

  p.section(Target.macos, () {
    final String? appInfo = p.read(AppleFiles.appInfo);
    final Plist? info = readPlist(p, _macos.infoPlist);
    _row("name", XcConfig.get(appInfo, "PRODUCT_NAME"));
    _row("bundle id", XcConfig.get(appInfo, "PRODUCT_BUNDLE_IDENTIFIER"));
    _row("min macOS", appleMin(p, _macos));
    _row("team", Pbx.runnerValues(p.read(_macos.pbxproj), "DEVELOPMENT_TEAM").firstOrNull);
    _row("copyright", XcConfig.get(appInfo, "PRODUCT_COPYRIGHT"));
    _row("permissions", _list(declaredPermissions(p, Target.macos)));
    _row("deep links", _list(_appleSchemes(info).map((String s) => "$s://").toList()));
  });

  p.section(Target.linux, () {
    final String? cmake = p.read(LinuxFiles.cmake);
    _row("name", LinuxFiles.name(p));
    _row("application id", Cmake.get(cmake, "APPLICATION_ID"));
    _row("binary", Cmake.get(cmake, "BINARY_NAME"));
  });

  p.section(Target.windows, () {
    final String? rc = p.read(WindowsFiles.rc);
    _row("name", WindowsFiles.name(p));
    _row("binary", "${Cmake.get(p.read(WindowsFiles.cmake), "BINARY_NAME") ?? "?"}.exe");
    _row("company", WindowsFiles.rcGet(rc, "CompanyName"));
    _row("copyright", WindowsFiles.rcGet(rc, "LegalCopyright"));
  });

  p.section(Target.web, () {
    final String? m = p.read(WebFiles.manifest);
    _row("name", WebFiles.jsonGet(m, "name"));
    _row("short name", WebFiles.jsonGet(m, "short_name"));
    _row("description", WebFiles.jsonGet(m, "description"));
    _row("theme color", WebFiles.jsonGet(m, "theme_color"));
    _row("orientation", WebFiles.jsonGet(m, "orientation"));
  });
  Out.line();
}

// =============================================================================================
// doctor

class _Doctor {
  int warnings = 0;
  int notes = 0;
  bool _any = false;

  void warn(String s) {
    warnings++;
    _any = true;
    Out.line("  ${Out.yellow("!")} $s");
  }

  void note(String s) {
    notes++;
    _any = true;
    Out.line("  ${Out.cyan("i")} $s");
  }

  void done() {
    if (!_any) {
      Out.line("  ${Out.green("✓")} ${Out.dim("looks good")}");
    }
    _any = false;
  }
}

void cmdDoctor(Project p, Args a) {
  final _Doctor d = _Doctor();
  final Map<String, String> names = <String, String>{};
  final Map<String, String> ids = <String, String>{};
  final Map<Target, List<String>> perms = <Target, List<String>>{};

  p.section(Target.android, () {
    final String? gradle = p.read(AndroidFiles.gradle(p));
    final String? manifest = p.read(AndroidFiles.manifest);
    final String? id = Gradle.getString(gradle, "applicationId");
    if (id != null) {
      ids["android"] = id;
      if (id.startsWith("com.example")) {
        d.warn("applicationId is $id. Google Play rejects com.example ids. Fix: dart run u:app id com.yourcompany.app");
      }
    }
    final String? name = androidName(p);
    if (name != null) {
      names["android"] = name;
    }
    if (manifest != null && !manifest.contains("android.permission.INTERNET")) {
      d.warn("No INTERNET permission in the main manifest. Release builds can't reach the network. Fix: dart run u:app permission add internet");
    }
    if (_releaseUsesDebugKeys(gradle)) {
      d.warn("Release builds are signed with debug keys (Play Console rejects them). Fix: dart run u:app signing --keystore ~/keys/upload.jks --create");
    }
    for (final String k in <String>["versionCode", "versionName"]) {
      final String? v = Gradle.get(gradle, <String>[k]);
      if (v != null && !v.startsWith("flutter.")) {
        d.warn("$k is hard-coded ($v), so the pubspec version is ignored on Android.");
      }
    }
    perms[Target.android] = declaredPermissions(p, Target.android);
    d.done();
  });

  for (final AppleFiles f in <AppleFiles>[_ios, _macos]) {
    p.section(f.target, () {
      final Plist? info = readPlist(p, f.infoPlist);
      final String? pbx = p.read(f.pbxproj);
      final String? id = appleId(p, f.target);
      if (id != null) {
        ids[f.target.id] = id;
        if (id.startsWith("com.example")) {
          d.warn("Bundle id is $id. The App Store rejects com.example ids.");
        }
      }
      final String? name = f.isIos ? info?.getString("CFBundleDisplayName") ?? info?.getString("CFBundleName") : XcConfig.get(p.read(AppleFiles.appInfo), "PRODUCT_NAME");
      if (name != null) {
        names[f.target.id] = name;
      }
      final String? short = info?.getString("CFBundleShortVersionString");
      if (short != null && !short.contains("FLUTTER_BUILD_NAME")) {
        d.warn("CFBundleShortVersionString is hard-coded ($short), so the pubspec version is ignored.");
      }
      final List<String> targets = Pbx.values(pbx, f.deploymentKey).toSet().toList();
      if (targets.length > 1) {
        d.note("${f.deploymentKey} differs between build configurations (${targets.join(", ")}). Fix: dart run u:app min-sdk ${f.target.id} ${appleMin(p, f)}");
      }
      final String? pod = Podfile.platform(p.read(f.podfile), f.podPlatform);
      final String? min = appleMin(p, f);
      if (pod != null && min != null && pod != min) {
        d.warn("Podfile says platform :${f.podPlatform}, '$pod' but the project targets $min. Fix: dart run u:app min-sdk ${f.target.id} $min");
      }
      if (Pbx.runnerValues(pbx, "DEVELOPMENT_TEAM").isEmpty) {
        d.note("No signing team set (needed for devices and release). Fix: dart run u:app team ABCDE12345");
      }
      if (!f.isIos) {
        final Plist? release = readPlist(p, AppleFiles.entitlements.last);
        if (release != null && !(release.getBool("com.apple.security.network.client") ?? false)) {
          d.warn("Release.entitlements lacks network.client. Release builds can't reach the network. Fix: dart run u:app permission add internet --platforms macos");
        }
      }
      perms[f.target] = declaredPermissions(p, f.target);
      d.done();
    });
  }

  p.section(Target.linux, () {
    final String? id = Cmake.get(p.read(LinuxFiles.cmake), "APPLICATION_ID");
    if (id != null && id.startsWith("com.example")) {
      d.warn("APPLICATION_ID is $id. Fix: dart run u:app id com.yourcompany.app --platforms linux");
    }
    final String? name = LinuxFiles.name(p);
    if (name != null) {
      names["linux"] = name;
    }
    d.done();
  });

  p.section(Target.windows, () {
    final String? rc = p.read(WindowsFiles.rc);
    if ((WindowsFiles.rcGet(rc, "CompanyName") ?? "").contains("com.example")) {
      d.note("CompanyName is still the template value. Fix: dart run u:app company \"Your Company\"");
    }
    if ((WindowsFiles.rcGet(rc, "LegalCopyright") ?? "").contains("com.example")) {
      d.note("LegalCopyright is still the template value. Fix: dart run u:app copyright \"© 2026 Your Company\"");
    }
    final String? name = WindowsFiles.name(p);
    if (name != null) {
      names["windows"] = name;
    }
    d.done();
  });

  p.section(Target.web, () {
    final String? m = p.read(WebFiles.manifest);
    if (WebFiles.jsonGet(m, "description") == "A new Flutter project.") {
      d.note("The web description is still \"A new Flutter project.\". Fix: dart run u:app description \"...\"");
    }
    final String? name = WebFiles.jsonGet(m, "name");
    if (name != null) {
      names["web"] = name;
    }
    d.done();
  });

  Out.header("across platforms");
  if (names.values.toSet().length > 1) {
    d.note("App names differ: ${names.entries.map((MapEntry<String, String> e) => "${e.key} \"${e.value}\"").join(", ")}. Fix: dart run u:app name \"My App\"");
  }
  final Set<String> normalizedIds = ids.values.map((String s) => s.toLowerCase().replaceAll("_", "").replaceAll("-", "")).toSet();
  if (normalizedIds.length > 1) {
    d.note("Ids differ: ${ids.entries.map((MapEntry<String, String> e) => "${e.key} ${e.value}").join(", ")}. Fix: dart run u:app id com.yourcompany.app");
  }
  final List<String> androidPerms = perms[Target.android] ?? <String>[];
  for (final Target t in <Target>[Target.ios, Target.macos]) {
    final List<String>? mine = perms[t];
    if (mine == null || perms[Target.android] == null) {
      continue;
    }
    final List<String> missing = androidPerms.where((String n) {
      final UPermission x = findPermission(n);
      return (t == Target.ios ? x.ios : x.macos).isNotEmpty && !mine.contains(n);
    }).toList();
    if (missing.isNotEmpty) {
      d.warn("${_list(missing)} declared on Android but not on ${t.id}. The ${t.id} app crashes when it asks for them. Fix: dart run u:app permission add ${missing.join(" ")} --platforms ${t.id}");
    }
  }
  d.done();
  Out.line();
  Out.line(d.warnings == 0 && d.notes == 0 ? Out.green("No issues found.") : "${d.warnings} warning(s), ${d.notes} note(s).");
}
