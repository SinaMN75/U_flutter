import "dart:ui" show AppExitType;

import "package:u/utilities.dart";
import "package:u/src/web/u_web_native.dart" if (dart.library.js_interop) "package:u/src/web/u_web_browser.dart";

/// App, device, platform, theme and language info in one place; filled by initU(). `UApp.version`, `UApp.isAndroid`, `UApp.toDarkMode()`
abstract class UApp {
  /// Everything about this app (name, id, version, build, install time…) as one object. `UApp.packageInfo.version`
  static UPackageInfo get packageInfo => UPackage.info;

  /// Everything about this device (model, OS, id, locales, time zone…) as one object. `UApp.deviceInfo.model`
  static UDeviceInfo get deviceInfo => UDevice.info;

  /// App name as shown on the home screen. `UApp.name` → "My App"
  static String get name => UPackage.appName;

  /// Android application id / Apple bundle id (web: the site host). `UApp.packageName` → "com.company.app"
  static String get packageName => UPackage.packageName;

  /// App version. `UApp.version` → "1.4.0"
  static String get version => UPackage.version;

  /// Build number. `UApp.buildNumber` → "12"
  static String get buildNumber => UPackage.buildNumber;

  /// True in a browser. `if (UApp.isWeb) …`
  static bool get isWeb => kIsWeb;

  /// True on Android (false on web, even in an Android browser).
  static bool get isAndroid => !isWeb && Platform.isAndroid;

  /// True on iOS/iPadOS (false on web).
  static bool get isIos => !isWeb && Platform.isIOS;

  /// True on macOS (false on web).
  static bool get isMacOs => !isWeb && Platform.isMacOS;

  /// True on Windows (false on web).
  static bool get isWindows => !isWeb && Platform.isWindows;

  /// True on Linux (false on web).
  static bool get isLinux => !isWeb && Platform.isLinux;

  /// True on Fuchsia.
  static bool get isFuchsia => !isWeb && Platform.isFuchsia;

  /// True on Android or iOS apps (not mobile browsers; use deviceType for that).
  static bool get isMobile => isAndroid || isIos;

  /// True on macOS, Windows or Linux apps.
  static bool get isDesktop => isMacOs || isWindows || isLinux;

  /// True when the app is showing the dark theme.
  static bool get isDarkMode => UAppState.isDarkMode;

  /// Stable id of this device, empty before initU() finishes. Web: resets when site data is cleared. `UApp.deviceId()`
  static String deviceId() => UDevice.isReady ? UDevice.id : "";

  /// True when the screen is wider than tall (needs a built app, uses navigatorKey).
  static bool isLandscape() => MediaQuery.of(navigatorKey.currentContext!).orientation == Orientation.landscape;

  /// True when the screen is taller than wide.
  static bool isPortrait() => MediaQuery.of(navigatorKey.currentContext!).orientation == Orientation.portrait;

  /// True when the short side is 600+ (always false on web). `if (UApp.isTablet()) twoColumns()`
  static bool isTablet() => !isWeb && MediaQuery.of(navigatorKey.currentContext!).size.shortestSide >= 600;

  /// True when the short side is under 600 (always false on web).
  static bool isPhone() => !isWeb && MediaQuery.of(navigatorKey.currentContext!).size.shortestSide < 600;

  /// True when the window is narrower than 850 (phone layout, any platform).
  static bool isMobileSize() => MediaQuery.of(navigatorKey.currentContext!).size.width < 850;

  /// True when the window is 850-1100 wide.
  static bool isTabletSize() => MediaQuery.of(navigatorKey.currentContext!).size.width < 1100 && MediaQuery.of(navigatorKey.currentContext!).size.width >= 850;

  /// True when the window is 1100+ wide.
  static bool isDesktopSize() => MediaQuery.of(navigatorKey.currentContext!).size.width >= 1100;

  /// Current app language code. `UApp.locale()` → "fa"
  static String locale() => UAppState.locale.value.languageCode;

  /// Switches the app language and saves it for next launch (needs UMaterialApp). `UApp.updateLocale(const Locale("en"))`
  static void updateLocale(Locale locale) {
    UAppState.updateLocale(locale);
    ULocalStorage.set(UConstants.locale, locale.languageCode);
  }

  /// True when the app is showing the dark theme.
  static bool isDarkTheme() => UAppState.isDarkMode;

  /// Switches to the dark theme and saves it (needs UMaterialApp). `UApp.toDarkMode()`
  static void toDarkMode() {
    UAppState.changeThemeMode(ThemeMode.dark);
    ULocalStorage.setDarkMode(true);
  }

  /// Switches to the light theme and saves it (needs UMaterialApp). `UApp.toLightMode()`
  static void toLightMode() {
    UAppState.changeThemeMode(ThemeMode.light);
    ULocalStorage.setDarkMode(false);
  }

  static bool? _isEmbedded;

  /// Web page URL query, e.g. ?ref=x → {"ref": "x"}; empty elsewhere. `UApp.queryParameters["ref"]`
  static Map<String, String> get queryParameters => Uri.base.queryParameters;

  /// Web only: true inside an iframe/WebView or with ?embedded=true.
  static bool get isEmbedded => _isEmbedded ??= _detectEmbedded();

  static bool _detectEmbedded() {
    if (!isWeb) return false;
    if ((queryParameters["embedded"] ?? "").toLowerCase() == "true") return true;
    return UWebBridge.isEmbedded();
  }

  // --- UDevice, one wrapper each ------------------------------------------------------------
  // Prefixed with "device" / "os" where UApp already uses the plain name for something else
  // (name = app name, isTablet() = screen size, isDesktop = platform).

  /// Loads app info (initU() already does it). `await UApp.initPackageInfo()`
  static Future<void> initPackageInfo() => UPackage.init();

  /// True once device info is loaded (after initU()).
  static bool get isDeviceInfoReady => UDevice.isReady;

  /// Hardware model. "SM-S918B", "iPhone16,1", "MacBookPro18,3"; web: the browser.
  static String get deviceModel => UDevice.model;

  /// Maker. "Samsung", "Apple", "Lenovo"
  static String get deviceManufacturer => UDevice.manufacturer;

  /// Brand. "samsung", "Apple"
  static String get deviceBrand => UDevice.brand;

  /// Name the user gave the device. "Sina's iPhone" (iOS 16+ needs an entitlement, else "iPhone")
  static String get deviceName => UDevice.name;

  /// phone, tablet, desktop, tv, watch, car or web. `if (UApp.deviceType == UDeviceType.tablet) …`
  static UDeviceType get deviceType => UDevice.type;

  /// False on emulators, simulators and virtual machines.
  static bool get isPhysicalDevice => UDevice.isPhysical;

  /// True on an emulator/simulator (detected on Android and Apple; desktops report false).
  static bool get isEmulator => UDevice.isEmulator;

  /// True when the hardware is a phone (also for mobile browsers).
  static bool get isPhoneDevice => UDevice.isPhone;

  /// True when the hardware is a tablet (also for tablet browsers).
  static bool get isTabletDevice => UDevice.isTablet;

  /// True when the hardware is a computer.
  static bool get isDesktopDevice => UDevice.isDesktop;

  /// True on Android TV / Apple TV.
  static bool get isTvDevice => UDevice.isTv;

  /// OS name. "Android", "iOS", "macOS", "Windows 11", "Ubuntu"; web: the visitor's OS.
  static String get osName => UDevice.os;

  /// OS version. "14", "17.4.1", "10.0.22631"
  static String get osVersion => UDevice.osVersion;

  /// OS build id. "UP1A.231005.007", "21E236"; null when unknown.
  static String? get osBuild => UDevice.info.osBuild;

  /// Android API level (34 = Android 14); null on other platforms. `if ((UApp.sdkInt ?? 0) >= 33) …`
  static int? get sdkInt => UDevice.sdkInt;

  /// CPU architecture. "arm64", "x86_64"
  static String? get cpuArch => UDevice.info.cpuArch;

  /// Number of CPU cores (web: navigator.hardwareConcurrency).
  static int? get cpuCores => UDevice.cpuCores;

  /// Total RAM in bytes (web: rounded by the browser, Chromium only). `UApp.totalMemory?.toBKMG()`
  static int? get totalMemory => UDevice.totalMemory;

  /// Device time zone (IANA). "Asia/Tehran"
  static String? get timeZone => UDevice.timeZone;

  /// Device languages, most preferred first. ["fa-IR", "en-US"]
  static List<String> get deviceLocales => UDevice.locales;

  /// True when the device clock is 24-hour; null on web and when unknown.
  static bool? get is24HourFormat => UDevice.is24HourFormat;

  /// Raw platform-specific details (e.g. Android fingerprint, Apple model name).
  static Map<String, Object?> get deviceExtra => UDevice.info.extra;

  /// Battery, charging, power saver, thermal, free RAM/disk right now. `final s = await UApp.deviceStatus();`
  static Future<UDeviceStatus> deviceStatus() => UDevice.status();

  /// Battery 0-100; null without a battery (desktops) and on Safari/Firefox. `await UApp.batteryLevel()`
  static Future<int?> batteryLevel() => UDevice.batteryLevel();

  /// True when plugged in and charging or full. `await UApp.isCharging()`
  static Future<bool> isCharging() async => (await UDevice.status()).isCharging;

  /// True when 15% or less and not charging.
  static Future<bool> isLowBattery() async => (await UDevice.status()).isLowBattery;

  /// True when battery saver / Low Power Mode is on; null when unknown (web).
  static Future<bool?> isPowerSaveMode() async => (await UDevice.status()).powerSaveMode;

  /// True when you should skip heavy work (low battery, saver on, or device hot). `if (!await UApp.shouldSaveEnergy()) sync()`
  static Future<bool> shouldSaveEnergy() async => (await UDevice.status()).shouldSaveEnergy;

  /// Free disk space in bytes (web: remaining site storage quota). `(await UApp.freeDiskSpace())?.toBKMG()`
  static Future<int?> freeDiskSpace() async => (await UDevice.status()).freeDisk;

  /// Free RAM in bytes; null on web.
  static Future<int?> freeMemory() async => (await UDevice.status()).freeMemory;

  /// Root/jailbreak, emulator, hooking (Frida/Xposed), debugger and dev-mode checks, cached. `(await UApp.deviceIntegrity()).reasons`
  static Future<UDeviceIntegrity> deviceIntegrity({bool refresh = false}) => UDevice.integrity(refresh: refresh);

  /// True when rooted/jailbroken, hooked or a debugger is attached; block payments with it. `if (await UApp.isDeviceCompromised()) …`
  static Future<bool> isDeviceCompromised() async => (await UDevice.integrity()).isCompromised;

  /// True when rooted (Android) or jailbroken (iOS); always false on desktop and web.
  static Future<bool> isRooted() async => (await UDevice.integrity()).rooted;

  /// Ready-made X-Device-* / X-App-* headers for your API calls. `http.get(url, headers: UApp.deviceHeaders)`
  static Map<String, String> get deviceHeaders => UDevice.headers;

  /// User-Agent for your API calls. "MyApp/1.4.0+12 (Android 14; SM-S918B)"
  static String get userAgent => UDevice.userAgent;

  // --- UPackage, one wrapper each -----------------------------------------------------------

  /// True once app info is loaded (after initU()).
  static bool get isPackageInfoReady => UPackage.isReady;

  /// Version with build. "1.4.0+12"
  static String get fullVersion => UPackage.fullVersion;

  /// When the app was first installed; null on web and Linux.
  static DateTime? get installTime => UPackage.installTime;

  /// When the app was last updated; null on web and Linux.
  static DateTime? get updateTime => UPackage.updateTime;

  /// Where the app came from: Play, App Store, TestFlight, Bazaar, Myket, Microsoft Store, sideload… `if (UApp.installer == UInstaller.bazaar) …`
  static UInstaller get installer => UPackage.installer;

  /// Android signing certificate SHA-256, to catch repackaged APKs; null on other platforms.
  static String? get signatureSha256 => UPackage.signatureSha256;

  /// Build flavor from `flutter run --flavor x`; null when none.
  static String? get flavor => UPackage.flavor;

  /// True in debug builds.
  static bool get isDebug => UPackage.isDebug;

  /// True in profile builds.
  static bool get isProfile => UPackage.isProfile;

  /// True in release builds.
  static bool get isRelease => UPackage.isRelease;

  /// True on the very first launch after install (e.g. show onboarding). `if (UApp.isFirstLaunch) showIntro()`
  static bool get isFirstLaunch => UPackage.isFirstLaunch;

  /// True on the first launch of this version (e.g. show "What's new").
  static bool get isFirstLaunchOfVersion => UPackage.isFirstLaunchOfVersion;

  /// True when the app was updated since the last launch.
  static bool get justUpdated => UPackage.justUpdated;

  /// Version that ran last time; null on first launch.
  static String? get previousVersion => UPackage.previousVersion;

  /// How many times the app has been opened (e.g. ask for a review after 10). `if (UApp.launchCount == 10) ULaunch.requestReview()`
  static int get launchCount => UPackage.launchCount;

  /// When the app was opened for the first time.
  static DateTime? get firstLaunchTime => UPackage.firstLaunchTime;

  /// When this version was opened for the first time.
  static DateTime? get versionFirstLaunchTime => UPackage.versionFirstLaunchTime;

  /// Compares versions: negative if a < b, 0 if equal, positive if a > b. `UApp.compareVersions("1.2.0", "1.10.0")` → -1
  static int compareVersions(String a, String b) => UPackage.compareVersions(a, b);

  /// True when this app is [minimum] or newer. `if (!UApp.isVersionAtLeast(server.minVersion)) forceUpdate()`
  static bool isVersionAtLeast(String minimum) => UPackage.isAtLeast(minimum);

  /// True when this app is older than [other]. `UApp.isVersionOlderThan(latest)`
  static bool isVersionOlderThan(String other) => UPackage.isOlderThan(other);

  /// Closes the on-screen keyboard from anywhere. `UApp.hideKeyboard()`
  static void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  /// Short vibration feedback (Android/iOS; ignored on desktop and web). `UApp.haptic(UHapticType.success)`
  static Future<void> haptic([UHapticType type = UHapticType.light]) => switch (type) {
    UHapticType.light => HapticFeedback.lightImpact(),
    UHapticType.medium || UHapticType.success => HapticFeedback.mediumImpact(),
    UHapticType.heavy || UHapticType.error => HapticFeedback.heavyImpact(),
    UHapticType.selection => HapticFeedback.selectionClick(),
    UHapticType.warning => HapticFeedback.vibrate(),
  };

  /// Makes status/navigation bar icons white (for dark screens) or black; mobile only. `UApp.setStatusBarLight(true)`
  static void setStatusBarLight(bool light) => SystemChrome.setSystemUIOverlayStyle(light ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

  /// Locks rotation (empty list unlocks); ignored on desktop and web. `UApp.setOrientations([DeviceOrientation.portraitUp])`
  static Future<void> setOrientations(List<DeviceOrientation> orientations) => SystemChrome.setPreferredOrientations(orientations);

  /// Hides (true) or shows the status and navigation bars; Android/iOS. `UApp.setFullScreen(true)`
  static Future<void> setFullScreen(bool fullScreen) => SystemChrome.setEnabledSystemUIMode(fullScreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);

  /// Keeps the screen awake while [on] (videos, navigation, scanners); Android/iOS/web. `UApp.keepScreenOn(true)`
  static Future<bool> keepScreenOn(bool on) => UDevice.keepScreenOn(on);

  /// Closes the app on Android and desktop; iOS and web do not allow it (does nothing). `UApp.exit()`
  static Future<void> exit() async {
    if (isAndroid) return SystemNavigator.pop();
    if (isDesktop) await ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

/// Kind of vibration for UApp.haptic: light, medium, heavy, selection, success, warning, error.
enum UHapticType { light, medium, heavy, selection, success, warning, error }
