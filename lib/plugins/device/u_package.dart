import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:u/plugins/device/u_device_channel.dart";
import "package:u/plugins/device/u_storage.dart";
import "package:u/plugins/web/u_web_native.dart" if (dart.library.js_interop) "package:u/plugins/web/u_web_browser.dart";

// =============================================================================
// u_package — this app's identity and launch history. Replaces package_info_plus.
//
//   UPackage.version / .buildNumber / .fullVersion / .packageName   // sync
//   UPackage.isAtLeast("2.1.0")                // compare with a server's min version
//   UPackage.isFirstLaunch / .justUpdated / .previousVersion / .launchCount
//   UPackage.installer                         // play, appStore, testFlight, bazaar, myket, sideload, …
//   UPackage.signatureSha256                   // detect re-signed (tampered) Android builds
//
// Field names of [UPackageInfo] match package_info_plus (appName, packageName, version,
// buildNumber, installerStore, installTime, updateTime, buildSignature), so code that
// used `UApp.packageInfo.version` keeps compiling.
// =============================================================================

enum UInstaller { playStore, appStore, testFlight, bazaar, myket, galaxyStore, huaweiAppGallery, amazon, microsoftStore, macAppStore, sideload, debug, web, unknown }

@immutable
class UPackageInfo {
  const UPackageInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    this.installerStore,
    this.installTime,
    this.updateTime,
    this.signatureSha256,
    this.minSdk,
    this.targetSdk,
    this.isTestFlight = false,
    this.executablePath,
  });

  factory UPackageInfo.fromMap(Map<String, Object?> m) => UPackageInfo(
    appName: m.str("appName") ?? "",
    packageName: m.str("packageName") ?? "",
    version: m.str("version") ?? "0.0.0",
    buildNumber: m.str("buildNumber") ?? "0",
    installerStore: m.str("installer"),
    installTime: m.time("installTime"),
    updateTime: m.time("updateTime"),
    signatureSha256: m.str("signature"),
    minSdk: m.integer("minSdk"),
    targetSdk: m.integer("targetSdk"),
    isTestFlight: m.flag("testFlight") ?? false,
    executablePath: m.str("executable"),
  );

  final String appName;

  /// Android application id, Apple bundle id, Windows/Linux application id.
  final String packageName;

  /// "1.4.0" (pubspec version without the build part).
  final String version;

  /// "12" (pubspec build number).
  final String buildNumber;

  /// Raw installer id: "com.android.vending", "com.farsitel.bazaar", "app_store", …
  final String? installerStore;

  final DateTime? installTime;
  final DateTime? updateTime;

  /// SHA-256 of the signing certificate (Android), uppercase hex with colons. Compare it with your
  /// release certificate to detect a repackaged APK.
  final String? signatureSha256;

  /// Android min / target SDK from the manifest.
  final int? minSdk;
  final int? targetSdk;

  final bool isTestFlight;

  final String? executablePath;

  /// package_info_plus name for [signatureSha256].
  String get buildSignature => signatureSha256 ?? "";

  String get fullVersion => buildNumber.isEmpty || buildNumber == "0" ? version : "$version+$buildNumber";

  Map<String, Object?> toMap() => <String, Object?>{
    "appName": appName,
    "packageName": packageName,
    "version": version,
    "buildNumber": buildNumber,
    "installer": installerStore,
    "installTime": installTime?.millisecondsSinceEpoch,
    "updateTime": updateTime?.millisecondsSinceEpoch,
    "signature": signatureSha256,
    "minSdk": minSdk,
    "targetSdk": targetSdk,
    "testFlight": isTestFlight,
    "executable": executablePath,
  };

  @override
  String toString() => "UPackageInfo($packageName $fullVersion)";
}

abstract final class UPackage {
  static UPackageInfo? _info;
  static Future<void>? _init;

  static const String _kFirst = "__u.pkg.firstLaunch";
  static const String _kCount = "__u.pkg.launchCount";
  static const String _kVersion = "__u.pkg.lastVersion";
  static const String _kVersionFirst = "__u.pkg.versionFirstLaunch";

  static bool _firstLaunch = false;
  static bool _firstLaunchOfVersion = false;
  static String? _previousVersion;

  /// Loads package info (shares the device bootstrap call) and records this launch.
  /// Idempotent; `initU()` calls it for you.
  static Future<void> init() => _init ??= _initialize();

  static Future<void> _initialize() async {
    final Future<void> storage = UStorage.init();
    UPackageInfo info = kIsWeb ? await _webInfo() : UPackageInfo.fromMap((await UDeviceChannel.bootstrap()).child("package"));
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows) && (info.version == "0.0.0" || info.appName.isEmpty)) info = await _versionJson(info);
    _info = info;
    await storage;
    _trackLaunch(info);
  }

  static UPackageInfo get info => _info ?? (throw StateError("UPackage is not initialized. Call `await initU()` (or `await UPackage.init()`) first."));

  static bool get isReady => _info != null;

  static String get appName => info.appName;

  static String get packageName => info.packageName;

  static String get version => info.version;

  static String get buildNumber => info.buildNumber;

  /// "1.4.0+12".
  static String get fullVersion => info.fullVersion;

  static DateTime? get installTime => info.installTime;

  static DateTime? get updateTime => info.updateTime;

  static String? get signatureSha256 => info.signatureSha256;

  /// Flavor from `flutter run --flavor <name>`, when one was used.
  static String? get flavor => appFlavor;

  static bool get isDebug => kDebugMode;

  static bool get isProfile => kProfileMode;

  static bool get isRelease => kReleaseMode;

  /// Where the app came from, normalized across stores.
  static UInstaller get installer {
    if (kIsWeb) return UInstaller.web;
    if (info.isTestFlight) return UInstaller.testFlight;
    final String? raw = info.installerStore;
    return switch (raw) {
      "com.android.vending" || "com.google.android.feedback" => UInstaller.playStore,
      "com.farsitel.bazaar" => UInstaller.bazaar,
      "ir.mservices.market" => UInstaller.myket,
      "com.sec.android.app.samsungapps" => UInstaller.galaxyStore,
      "com.huawei.appmarket" => UInstaller.huaweiAppGallery,
      "com.amazon.venezia" => UInstaller.amazon,
      "app_store" => Platform.isMacOS ? UInstaller.macAppStore : UInstaller.appStore,
      "microsoft_store" => UInstaller.microsoftStore,
      "debug" => UInstaller.debug,
      null || "" || "sideload" || "com.google.android.packageinstaller" || "com.android.packageinstaller" => kDebugMode ? UInstaller.debug : UInstaller.sideload,
      _ => UInstaller.unknown,
    };
  }

  // --- launch history --------------------------------------------------------

  /// First launch ever on this device (since install, or since app data was cleared).
  static bool get isFirstLaunch => _firstLaunch;

  /// First launch of the current version (true on first install too).
  static bool get isFirstLaunchOfVersion => _firstLaunchOfVersion;

  /// Updated from an older version since the last launch. Show the changelog, run data migrations.
  static bool get justUpdated => _previousVersion != null && _previousVersion != fullVersion;

  /// Version that ran on the previous launch; null on first launch.
  static String? get previousVersion => _previousVersion;

  static int get launchCount => UStorage.getOr<int>(_kCount, 0);

  static DateTime? get firstLaunchTime => UStorage.get<DateTime>(_kFirst);

  /// When the current version first launched.
  static DateTime? get versionFirstLaunchTime => UStorage.get<DateTime>(_kVersionFirst);

  static void _trackLaunch(UPackageInfo info) {
    final String current = info.fullVersion;
    _firstLaunch = UStorage.get<DateTime>(_kFirst) == null;
    _previousVersion = UStorage.get<String>(_kVersion);
    _firstLaunchOfVersion = _previousVersion != current;
    final DateTime now = DateTime.now();
    unawaited(
      UStorage.setAll(<String, Object?>{
        if (_firstLaunch) _kFirst: now,
        if (_firstLaunchOfVersion) _kVersionFirst: now,
        _kVersion: current,
        _kCount: launchCount + 1,
      }),
    );
  }

  // --- versions --------------------------------------------------------------

  /// Compares two dotted versions numerically ("1.10.0" > "1.9.3"); a build suffix ("+12") breaks ties.
  /// Returns <0, 0 or >0 like [Comparable.compareTo].
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v.split(RegExp(r"[.+\-]")).map((String p) => int.tryParse(RegExp(r"\d+").firstMatch(p)?.group(0) ?? "") ?? 0).toList();
    final List<int> x = parts(a);
    final List<int> y = parts(b);
    for (int i = 0; i < x.length || i < y.length; i++) {
      final int d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }

  /// Whether this app is [minimum] or newer, e.g. against a "force update below" value from the server.
  static bool isAtLeast(String minimum) => compareVersions(fullVersion, minimum) >= 0;

  static bool isOlderThan(String other) => compareVersions(fullVersion, other) < 0;

  // --- platform fallbacks ----------------------------------------------------

  // Flutter writes version.json into flutter_assets for web and desktop builds.
  static Future<UPackageInfo> _versionJson(UPackageInfo fallback) async {
    try {
      final String dir = File(Platform.resolvedExecutable).parent.path;
      final File file = File("$dir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}version.json");
      if (!file.existsSync()) return fallback;
      return _merge(fallback, asStringMap(jsonDecode(await file.readAsString())));
    } catch (_) {
      return fallback;
    }
  }

  static Future<UPackageInfo> _webInfo() async {
    const UPackageInfo empty = UPackageInfo(appName: "", packageName: "", version: "0.0.0", buildNumber: "0");
    try {
      final String? text = await UWebBridge.fetch("${UWebBridge.baseUrl()}version.json", "no-store");
      final UPackageInfo info = text == null ? empty : _merge(empty, asStringMap(jsonDecode(text)));
      return UPackageInfo.fromMap(<String, Object?>{...info.toMap(), "installer": "web", "packageName": info.packageName.isEmpty ? Uri.base.host : info.packageName});
    } catch (_) {
      return empty;
    }
  }

  static UPackageInfo _merge(UPackageInfo base, Map<String, Object?>? json) {
    if (json == null) return base;
    return UPackageInfo.fromMap(<String, Object?>{
      ...base.toMap(),
      if (json.str("app_name") != null && base.appName.isEmpty) "appName": json.str("app_name"),
      if (json.str("package_name") != null && base.packageName.isEmpty) "packageName": json.str("package_name"),
      if (json.str("version") != null) "version": json.str("version"),
      if (json.str("build_number") != null) "buildNumber": json.str("build_number"),
    });
  }
}
