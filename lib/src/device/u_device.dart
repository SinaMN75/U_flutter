import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:u/src/device/u_device_channel.dart";
import "package:u/src/device/u_package.dart";
import "package:u/src/files/u_storage_backend.dart";
import "package:u/src/files/u_vault.dart";
import "package:u/src/web/u_web_native.dart" if (dart.library.js_interop) "package:u/src/web/u_web_browser.dart";

// =============================================================================
// u_device — one device model for every platform. Replaces device_info_plus.
//
//   UDevice.model / .manufacturer / .osVersion / .isPhysical / .type   // sync
//   UDevice.id                                    // stable, see [UDevice.id]
//   UDevice.timeZone / .locales / .is24HourFormat
//   final UDeviceStatus s = await UDevice.status();      // battery, RAM, disk, thermal
//   final UDeviceIntegrity i = await UDevice.integrity(); // root / jailbreak / emulator / debugger
//   http.get(url, headers: UDevice.headers);              // X-Device-* and X-App-* headers
//
// Anything platform-specific that has no common field is in [UDeviceInfo.extra].
// =============================================================================

String _uPlatformName() => kIsWeb ? "web" : Platform.operatingSystem;

/// Device kind: phone, tablet, desktop, tv, watch, car, web.
enum UDeviceType { phone, tablet, desktop, tv, watch, car, web, unknown }

/// Battery: charging, discharging, full, notCharging, unknown.
enum UBatteryState { charging, discharging, full, notCharging, none, unknown }

/// Device heat: nominal, fair, serious, critical.
enum UThermalState { nominal, fair, serious, critical, unknown }

/// Device facts (model, OS, id, locales, time zone…) — see UApp.deviceInfo.
@immutable
class UDeviceInfo {
  const UDeviceInfo({
    required this.platform,
    required this.os,
    required this.osVersion,
    required this.model,
    required this.manufacturer,
    required this.brand,
    required this.name,
    required this.type,
    required this.isPhysical,
    required this.id,
    this.osBuild,
    this.sdkInt,
    this.cpuArch,
    this.cpuCores,
    this.totalMemory,
    this.locales = const <String>[],
    this.timeZone,
    this.is24HourFormat,
    this.extra = const <String, Object?>{},
  });

  /// Reads it from the native map.
  factory UDeviceInfo.fromMap(Map<String, Object?> m) => UDeviceInfo(
    platform: m.str("platform") ?? _uPlatformName(),
    os: m.str("os") ?? _uPlatformName(),
    osVersion: m.str("osVersion") ?? "",
    osBuild: m.str("osBuild"),
    sdkInt: m.integer("sdkInt"),
    model: m.str("model") ?? "",
    manufacturer: m.str("manufacturer") ?? "",
    brand: m.str("brand") ?? m.str("manufacturer") ?? "",
    name: m.str("name") ?? "",
    type: UDeviceType.values.firstWhere((UDeviceType t) => t.name == m.str("type"), orElse: () => UDeviceType.unknown),
    isPhysical: m.flag("physical") ?? true,
    id: m.str("id") ?? "",
    cpuArch: m.str("arch"),
    cpuCores: m.integer("cores"),
    totalMemory: m.integer("memory"),
    locales: m.strings("locales"),
    timeZone: m.str("timeZone"),
    is24HourFormat: m.flag("is24h"),
    extra: Map<String, Object?>.unmodifiable(m.child("extra")),
  );

  /// android, ios, macos, windows, linux or web.
  final String platform;

  /// Marketing OS name: "Android", "iOS", "iPadOS", "macOS", "Windows 11", "Ubuntu", "Chrome on Android", …
  final String os;

  /// "14", "17.4.1", "14.4", "10.0.22631", …
  final String osVersion;

  /// Build identifier (Android build id, Apple build "21E236", Windows build + UBR, kernel on Linux).
  final String? osBuild;

  /// Android API level.
  final int? sdkInt;

  /// Hardware model: "SM-S918B", "iPhone16,1", "MacBookPro18,3", …
  final String model;

  /// Maker.
  final String manufacturer;

  /// Brand.
  final String brand;

  /// The name the user gave the device (Android / macOS / Windows / Linux hostname). Generic on iOS 16+.
  final String name;

  /// Phone, tablet, desktop…
  final UDeviceType type;

  /// False on emulators, simulators and virtual machines.
  final bool isPhysical;

  /// See [UDevice.id].
  final String id;

  /// "arm64", "x86_64", …
  final String? cpuArch;

  /// CPU cores.
  final int? cpuCores;

  /// Physical RAM in bytes.
  final int? totalMemory;

  /// Preferred languages as BCP-47 tags, most preferred first.
  final List<String> locales;

  /// IANA time zone, e.g. "Asia/Tehran".
  final String? timeZone;

  /// 24-hour clock setting.
  final bool? is24HourFormat;

  /// Platform-specific extras (Android fingerprint / ABIs / security patch, Windows edition, Linux os-release, browser, …).
  final Map<String, Object?> extra;

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{
    "platform": platform,
    "os": os,
    "osVersion": osVersion,
    "osBuild": osBuild,
    "sdkInt": sdkInt,
    "model": model,
    "manufacturer": manufacturer,
    "brand": brand,
    "name": name,
    "type": type.name,
    "physical": isPhysical,
    "id": id,
    "arch": cpuArch,
    "cores": cpuCores,
    "memory": totalMemory,
    "locales": locales,
    "timeZone": timeZone,
    "is24h": is24HourFormat,
    "extra": extra,
  };

  UDeviceInfo _withId(String id) => UDeviceInfo.fromMap(<String, Object?>{...toMap(), "id": id});

  @override
  String toString() => "UDeviceInfo($manufacturer $model, $os $osVersion, ${type.name}${isPhysical ? "" : ", virtual"})";
}

/// Values that change while the app runs; read with [UDevice.status].
@immutable
class UDeviceStatus {
  const UDeviceStatus({
    this.batteryLevel,
    this.batteryState = UBatteryState.unknown,
    this.powerSaveMode,
    this.thermalState = UThermalState.unknown,
    this.freeMemory,
    this.totalMemory,
    this.freeDisk,
    this.totalDisk,
    this.uptime,
  });

  /// Reads it from the native map.
  factory UDeviceStatus.fromMap(Map<String, Object?> m) => UDeviceStatus(
    batteryLevel: m.integer("battery"),
    batteryState: UBatteryState.values.firstWhere((UBatteryState s) => s.name == m.str("batteryState"), orElse: () => UBatteryState.unknown),
    powerSaveMode: m.flag("powerSave"),
    thermalState: UThermalState.values.firstWhere((UThermalState s) => s.name == m.str("thermal"), orElse: () => UThermalState.unknown),
    freeMemory: m.integer("memFree"),
    totalMemory: m.integer("memTotal"),
    freeDisk: m.integer("diskFree"),
    totalDisk: m.integer("diskTotal"),
    uptime: m.integer("uptimeMs") == null ? null : Duration(milliseconds: m.integer("uptimeMs")!),
  );

  /// 0–100, null when there is no battery or it cannot be read.
  final int? batteryLevel;

  /// Charging state.
  final UBatteryState batteryState;

  /// Battery Saver / Low Power Mode / Windows energy saver.
  final bool? powerSaveMode;

  /// Heat level.
  final UThermalState thermalState;

  /// Bytes. Memory is system-wide; disk is the volume holding the app's data.
  final int? freeMemory;

  /// Total RAM in bytes.
  final int? totalMemory;

  /// Free disk in bytes.
  final int? freeDisk;

  /// Total disk in bytes.
  final int? totalDisk;

  /// Time since boot.
  final Duration? uptime;

  /// True when charging or full.
  bool get isCharging => batteryState == UBatteryState.charging || batteryState == UBatteryState.full;

  /// True at 15% or less and not charging.
  bool get isLowBattery => batteryLevel != null && batteryLevel! <= 15 && !isCharging;

  /// Low power, low battery or a hot device: a good moment to skip heavy background work.
  bool get shouldSaveEnergy => powerSaveMode == true || isLowBattery || thermalState == UThermalState.serious || thermalState == UThermalState.critical;

  @override
  String toString() => "UDeviceStatus(battery: $batteryLevel% ${batteryState.name}, disk free: $freeDisk, mem free: $freeMemory)";
}

/// Signals that the app may be running somewhere it cannot trust. Heuristics, not proof:
/// use them to add friction (re-auth, block payments), not to crash.
@immutable
class UDeviceIntegrity {
  const UDeviceIntegrity({
    this.rooted = false,
    this.emulator = false,
    this.debuggerAttached = false,
    this.hooked = false,
    this.developerMode = false,
    this.adbEnabled = false,
    this.virtualMachine = false,
    this.automated = false,
    this.reasons = const <String>[],
  });

  /// Reads it from the native map.
  factory UDeviceIntegrity.fromMap(Map<String, Object?> m) => UDeviceIntegrity(
    rooted: m.flag("rooted") ?? false,
    emulator: m.flag("emulator") ?? false,
    debuggerAttached: m.flag("debugger") ?? false,
    hooked: m.flag("hooked") ?? false,
    developerMode: m.flag("developerMode") ?? false,
    adbEnabled: m.flag("adb") ?? false,
    virtualMachine: m.flag("vm") ?? false,
    automated: m.flag("automation") ?? false,
    reasons: m.strings("reasons"),
  );

  /// Rooted (Android) or jailbroken (iOS).
  final bool rooted;

  /// Android emulator or iOS simulator.
  final bool emulator;

  /// A debugger is attached.
  final bool debuggerAttached;

  /// Frida / Xposed / Substrate or similar instrumentation detected.
  final bool hooked;

  /// Android developer options.
  final bool developerMode;

  /// Android USB debugging.
  final bool adbEnabled;

  /// Desktop running inside a hypervisor (VMware, VirtualBox, Parallels, QEMU, Hyper-V guest).
  final bool virtualMachine;

  /// Web: the browser is driven by automation (navigator.webdriver).
  final bool automated;

  /// Human-readable evidence, e.g. "su binary at /system/xbin/su".
  final List<String> reasons;

  /// Rooted, hooked or debugged: the app's own code cannot be trusted.
  bool get isCompromised => rooted || hooked || debuggerAttached;

  @override
  String toString() => "UDeviceIntegrity(${reasons.isEmpty ? "clean" : reasons.join("; ")})";
}

/// Engine behind the device part of UApp; use UApp instead.
abstract final class UDevice {
  static UDeviceInfo? _info;
  static Future<void>? _init;
  static Future<UDeviceIntegrity>? _integrity;

  /// Loads device info with one native call. Idempotent; `initU()` calls it for you.
  static Future<void> init() => _init ??= _initialize();

  static Future<void> _initialize() async {
    final UDeviceInfo raw = kIsWeb ? _webInfo() : UDeviceInfo.fromMap((await UDeviceChannel.bootstrap()).child("device"));
    _info = raw._withId(await _stableId(raw));
  }

  /// Same as UApp.deviceInfo.
  static UDeviceInfo get info => _info ?? (throw StateError("UDevice is not initialized. Call `await initU()` (or `await UDevice.init()`) first."));

  /// Same as UApp.isDeviceInfoReady.
  static bool get isReady => _info != null;

  /// A stable identifier for this install of the app on this device:
  ///   * Android — `Settings.Secure.ANDROID_ID` (per signing key and user; survives reinstall).
  ///   * iOS — `identifierForVendor`, pinned in the Keychain so it also survives reinstall.
  ///   * macOS — IOPlatformUUID; Windows — MachineGuid; Linux — /etc/machine-id.
  ///   * Web — a random UUID kept in encrypted IndexedDB, per browser profile and origin.
  static String get id => info.id;

  /// Same as UApp.deviceModel.
  static String get model => info.model;

  /// Same as UApp.deviceManufacturer.
  static String get manufacturer => info.manufacturer;

  /// Same as UApp.deviceBrand.
  static String get brand => info.brand;

  /// Same as UApp.deviceName.
  static String get name => info.name;

  /// Same as UApp.osName.
  static String get os => info.os;

  /// Same as UApp.osVersion.
  static String get osVersion => info.osVersion;

  /// Same as UApp.sdkInt.
  static int? get sdkInt => info.sdkInt;

  /// Same as UApp.deviceType.
  static UDeviceType get type => info.type;

  /// Same as UApp.isPhysicalDevice.
  static bool get isPhysical => info.isPhysical;

  /// Same as UApp.isEmulator.
  static bool get isEmulator => !info.isPhysical;

  /// Same as UApp.isPhoneDevice.
  static bool get isPhone => info.type == UDeviceType.phone;

  /// Same as UApp.isTabletDevice.
  static bool get isTablet => info.type == UDeviceType.tablet;

  /// Same as UApp.isDesktopDevice.
  static bool get isDesktop => info.type == UDeviceType.desktop;

  /// Same as UApp.isTvDevice.
  static bool get isTv => info.type == UDeviceType.tv;

  /// Same as UApp.timeZone.
  static String? get timeZone => info.timeZone;

  /// Same as UApp.deviceLocales.
  static List<String> get locales => info.locales;

  /// Same as UApp.is24HourFormat.
  static bool? get is24HourFormat => info.is24HourFormat;

  /// Same as UApp.cpuCores.
  static int? get cpuCores => info.cpuCores;

  /// Same as UApp.totalMemory.
  static int? get totalMemory => info.totalMemory;

  /// Battery, memory, disk and thermal state right now (not cached).
  static Future<UDeviceStatus> status() async {
    final Map<String, Object?>? map = kIsWeb ? await UWebBridge.deviceStatus() : await UDeviceChannel.status();
    return map == null ? const UDeviceStatus() : UDeviceStatus.fromMap(map);
  }

  /// Same as UApp.batteryLevel.
  static Future<int?> batteryLevel() async => (await status()).batteryLevel;

  /// Keeps the display from sleeping while [on] (video, navigation, scanners).
  static Future<bool> keepScreenOn(bool on) => kIsWeb ? UWebBridge.keepScreenOn(on) : UDeviceChannel.keepScreenOn(on);

  /// Root / jailbreak / emulator / hook / debugger checks. Runs once off the UI thread and is cached
  /// unless [refresh] (a debugger can attach later).
  static Future<UDeviceIntegrity> integrity({bool refresh = false}) {
    if (refresh) _integrity = null;
    return _integrity ??= () async {
      final Map<String, Object?>? map = kIsWeb ? UWebBridge.integrity() : await UDeviceChannel.integrity();
      return map == null ? const UDeviceIntegrity() : UDeviceIntegrity.fromMap(map);
    }();
  }

  /// Headers that identify the client to your API.
  static Map<String, String> get headers => <String, String>{
    if (_info != null) ...<String, String>{
      "X-Device-Id": id,
      "X-Device-Model": model,
      "X-Device-Type": type.name,
      "X-OS": info.platform,
      "X-OS-Version": osVersion,
    },
    if (UPackage.isReady) ...<String, String>{
      "X-App-Id": UPackage.packageName,
      "X-App-Version": UPackage.version,
      "X-App-Build": UPackage.buildNumber,
    },
  };

  /// "MyApp/1.4.0+12 (Android 14; SM-S918B)" for a User-Agent header.
  static String get userAgent {
    final String app = UPackage.isReady ? "${UPackage.appName.replaceAll(" ", "")}/${UPackage.fullVersion}" : "u";
    return _info == null ? app : "$app (${info.os} $osVersion; $model)";
  }

  // ---------------------------------------------------------------------------

  static const String _idAlias = "u_device_id_v1";

  // iOS and web ids reset (vendor apps removed / site data cleared). Pin the first one in the
  // key store — the Keychain outlives a reinstall — and generate one where the platform has none.
  static Future<String> _stableId(UDeviceInfo raw) async {
    final bool pin = kIsWeb || raw.platform == "ios" || raw.id.isEmpty;
    if (!pin) return raw.id;
    final UStorageBackend backend = UStorageBackend.instance;
    try {
      final Uint8List? saved = await backend.loadSecret(_idAlias);
      if (saved != null && saved.isNotEmpty) return utf8.decode(saved);
    } catch (_) {}
    final String id = raw.id.isNotEmpty ? raw.id : _uuid();
    try {
      await backend.storeSecret(_idAlias, utf8.encode(id));
    } catch (_) {}
    return id;
  }

  static String _uuid() {
    final Uint8List b = uRandomBytes(16);
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final String h = b.map((int x) => x.toRadixString(16).padLeft(2, "0")).join();
    return "${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}";
  }

  static UDeviceInfo _webInfo() {
    final Map<String, Object?> m = UWebBridge.deviceInfo();
    final String ua = m.str("userAgent") ?? "";
    final ({String os, String osVersion}) os = _parseOs(ua, m.str("uaPlatform"));
    final ({String name, String version}) browser = _parseBrowser(ua);
    final bool mobile = m.flag("mobile") ?? RegExp("Mobi|Android|iPhone", caseSensitive: false).hasMatch(ua);
    final bool tablet = RegExp("iPad|Tablet", caseSensitive: false).hasMatch(ua) || (os.os == "Android" && !ua.contains("Mobile")) || (os.os == "macOS" && (m.integer("touchPoints") ?? 0) > 1);
    return UDeviceInfo.fromMap(<String, Object?>{
      ...m,
      "platform": "web",
      "os": os.os,
      "osVersion": os.osVersion,
      "model": m.str("uaModel") ?? browser.name,
      "manufacturer": m.str("vendor") ?? "",
      "brand": browser.name,
      "name": "${browser.name} on ${os.os}",
      "type": tablet ? "tablet" : (mobile ? "phone" : "desktop"),
      "physical": !(m.flag("webdriver") ?? false),
      "id": "",
      "extra": <String, Object?>{...m.child("extra"), "browser": browser.name, "browserVersion": browser.version, "userAgent": ua},
    });
  }

  static ({String os, String osVersion}) _parseOs(String ua, String? hint) {
    String v(RegExp r) => (r.firstMatch(ua)?.group(1) ?? "").replaceAll("_", ".");
    if (ua.contains("Android")) return (os: "Android", osVersion: v(RegExp(r"Android ([\d.]+)")));
    if (RegExp("iPhone|iPad|iPod").hasMatch(ua)) return (os: ua.contains("iPad") ? "iPadOS" : "iOS", osVersion: v(RegExp(r"OS ([\d_]+)")));
    if (ua.contains("Mac OS X")) return (os: "macOS", osVersion: v(RegExp(r"Mac OS X ([\d_.]+)")));
    if (ua.contains("Windows")) return (os: "Windows", osVersion: v(RegExp(r"Windows NT ([\d.]+)")));
    if (ua.contains("CrOS")) return (os: "ChromeOS", osVersion: "");
    if (ua.contains("Linux")) return (os: "Linux", osVersion: "");
    return (os: hint ?? "Unknown", osVersion: "");
  }

  static ({String name, String version}) _parseBrowser(String ua) {
    for (final (String name, RegExp r) in <(String, RegExp)>[
      ("Edge", RegExp(r"Edg(?:e|A|iOS)?/([\d.]+)")),
      ("Opera", RegExp(r"OPR/([\d.]+)")),
      ("Samsung Internet", RegExp(r"SamsungBrowser/([\d.]+)")),
      ("Firefox", RegExp(r"(?:Firefox|FxiOS)/([\d.]+)")),
      ("Chrome", RegExp(r"(?:Chrome|CriOS)/([\d.]+)")),
      ("Safari", RegExp(r"Version/([\d.]+).*Safari")),
    ]) {
      final RegExpMatch? m = r.firstMatch(ua);
      if (m != null) return (name: name, version: m.group(1) ?? "");
    }
    return (name: "Browser", version: "");
  }
}
