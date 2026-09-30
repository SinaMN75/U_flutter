import "package:u/utilities.dart";
import "package:u/plugins/web/u_web_native.dart" if (dart.library.js_interop) "package:u/plugins/web/u_web_browser.dart";

abstract class UApp {
  /// All info about this app (name, id, version, build, install time, …).
  static UPackageInfo get packageInfo => UPackage.info;

  /// All info about this device (model, OS, id, locales, time zone, …).
  static UDeviceInfo get deviceInfo => UDevice.info;

  /// App name.
  static String get name => UPackage.appName;

  /// App id: Android application id / Apple bundle id.
  static String get packageName => UPackage.packageName;

  /// App version, e.g. "1.4.0".
  static String get version => UPackage.version;

  /// App build number, e.g. "12".
  static String get buildNumber => UPackage.buildNumber;

  /// True when running in a browser.
  static bool get isWeb => kIsWeb;

  /// True on Android.
  static bool get isAndroid => !isWeb && Platform.isAndroid;

  /// True on iOS.
  static bool get isIos => !isWeb && Platform.isIOS;

  /// True on macOS.
  static bool get isMacOs => !isWeb && Platform.isMacOS;

  /// True on Windows.
  static bool get isWindows => !isWeb && Platform.isWindows;

  /// True on Linux.
  static bool get isLinux => !isWeb && Platform.isLinux;

  /// True on Fuchsia.
  static bool get isFuchsia => !isWeb && Platform.isFuchsia;

  /// True on Android or iOS.
  static bool get isMobile => isAndroid || isIos;

  /// True on macOS, Windows or Linux.
  static bool get isDesktop => isMacOs || isWindows || isLinux;

  /// True when the app is currently in dark theme.
  static bool get isDarkMode => UAppState.isDarkMode;

  /// Stable id of this device; empty before initU() finishes.
  static String deviceId() => UDevice.isReady ? UDevice.id : "";

  /// True when the screen is wider than tall.
  static bool isLandscape() => MediaQuery.of(navigatorKey.currentContext!).orientation == Orientation.landscape;

  /// True when the screen is taller than wide.
  static bool isPortrait() => MediaQuery.of(navigatorKey.currentContext!).orientation == Orientation.portrait;

  /// True when the screen's short side is at least 600 (not on web).
  static bool isTablet() => !isWeb && MediaQuery.of(navigatorKey.currentContext!).size.shortestSide >= 600;

  /// True when the screen's short side is under 600 (not on web).
  static bool isPhone() => !isWeb && MediaQuery.of(navigatorKey.currentContext!).size.shortestSide < 600;

  /// True when the window is narrower than 850.
  static bool isMobileSize() => MediaQuery.of(navigatorKey.currentContext!).size.width < 850;

  /// True when the window is between 850 and 1100 wide.
  static bool isTabletSize() => MediaQuery.of(navigatorKey.currentContext!).size.width < 1100 && MediaQuery.of(navigatorKey.currentContext!).size.width >= 850;

  /// True when the window is at least 1100 wide.
  static bool isDesktopSize() => MediaQuery.of(navigatorKey.currentContext!).size.width >= 1100;

  /// Current app language code, e.g. "fa".
  static String locale() => UAppState.locale.value.languageCode;

  /// Switches the app language and remembers it.
  static void updateLocale(Locale locale) {
    UAppState.updateLocale(locale);
    ULocalStorage.set(UConstants.locale, locale.languageCode);
  }

  /// True when the app is currently in dark theme.
  static bool isDarkTheme() => UAppState.isDarkMode;

  /// Switches the app to dark theme and remembers it.
  static void toDarkMode() {
    UAppState.changeThemeMode(ThemeMode.dark);
    ULocalStorage.setDarkMode(true);
  }

  /// Switches the app to light theme and remembers it.
  static void toLightMode() {
    UAppState.changeThemeMode(ThemeMode.light);
    ULocalStorage.setDarkMode(false);
  }

  static bool? _isEmbedded;

  /// Query parameters of the page URL (web).
  static Map<String, String> get queryParameters => Uri.base.queryParameters;

  /// True when the web app runs inside an iframe or a WebView.
  static bool get isEmbedded => _isEmbedded ??= _detectEmbedded();

  static bool _detectEmbedded() {
    if (!isWeb) return false;
    if ((queryParameters["embedded"] ?? "").toLowerCase() == "true") return true;
    return UWebBridge.isEmbedded();
  }

  // --- UDevice, one wrapper each ------------------------------------------------------------
  // Prefixed with "device" / "os" where UApp already uses the plain name for something else
  // (name = app name, isTablet() = screen size, isDesktop = platform).

  /// Loads app info and records this launch (initU() already does this).
  static Future<void> initPackageInfo() => UPackage.init();

  /// True once device info is loaded.
  static bool get isDeviceInfoReady => UDevice.isReady;

  /// Hardware model, e.g. "SM-S918B" or "iPhone16,1".
  static String get deviceModel => UDevice.model;

  /// Maker, e.g. "Samsung" or "Apple".
  static String get deviceManufacturer => UDevice.manufacturer;

  /// Brand, e.g. "samsung".
  static String get deviceBrand => UDevice.brand;

  /// The name the user gave the device.
  static String get deviceName => UDevice.name;

  /// phone, tablet, desktop, tv, watch, car or web.
  static UDeviceType get deviceType => UDevice.type;

  /// False on emulators, simulators and virtual machines.
  static bool get isPhysicalDevice => UDevice.isPhysical;

  /// True on emulators, simulators and virtual machines.
  static bool get isEmulator => UDevice.isEmulator;

  /// True when the hardware is a phone.
  static bool get isPhoneDevice => UDevice.isPhone;

  /// True when the hardware is a tablet.
  static bool get isTabletDevice => UDevice.isTablet;

  /// True when the hardware is a computer.
  static bool get isDesktopDevice => UDevice.isDesktop;

  /// True when the hardware is a TV.
  static bool get isTvDevice => UDevice.isTv;

  /// OS name, e.g. "Android", "iOS", "Windows 11".
  static String get osName => UDevice.os;

  /// OS version, e.g. "14" or "17.4.1".
  static String get osVersion => UDevice.osVersion;

  /// OS build id, e.g. "21E236".
  static String? get osBuild => UDevice.info.osBuild;

  /// Android API level (null elsewhere).
  static int? get sdkInt => UDevice.sdkInt;

  /// CPU architecture, e.g. "arm64".
  static String? get cpuArch => UDevice.info.cpuArch;

  /// Number of CPU cores.
  static int? get cpuCores => UDevice.cpuCores;

  /// Total RAM in bytes.
  static int? get totalMemory => UDevice.totalMemory;

  /// Device time zone, e.g. "Asia/Tehran".
  static String? get timeZone => UDevice.timeZone;

  /// Device languages, most preferred first, e.g. ["fa-IR", "en-US"].
  static List<String> get deviceLocales => UDevice.locales;

  /// True when the device shows time in 24-hour format.
  static bool? get is24HourFormat => UDevice.is24HourFormat;

  /// Extra platform-specific device details.
  static Map<String, Object?> get deviceExtra => UDevice.info.extra;

  /// Battery, free RAM, free disk and temperature state right now.
  static Future<UDeviceStatus> deviceStatus() => UDevice.status();

  /// Battery percent 0-100 (null if no battery).
  static Future<int?> batteryLevel() => UDevice.batteryLevel();

  /// True when plugged in and charging (or full).
  static Future<bool> isCharging() async => (await UDevice.status()).isCharging;

  /// True when battery is 15% or less and not charging.
  static Future<bool> isLowBattery() async => (await UDevice.status()).isLowBattery;

  /// True when battery saver / low power mode is on.
  static Future<bool?> isPowerSaveMode() async => (await UDevice.status()).powerSaveMode;

  /// True when you should skip heavy work (low battery, saver on, or hot).
  static Future<bool> shouldSaveEnergy() async => (await UDevice.status()).shouldSaveEnergy;

  /// Free disk space in bytes.
  static Future<int?> freeDiskSpace() async => (await UDevice.status()).freeDisk;

  /// Free RAM in bytes.
  static Future<int?> freeMemory() async => (await UDevice.status()).freeMemory;

  /// Root/jailbreak, emulator, hooking and debugger check results.
  static Future<UDeviceIntegrity> deviceIntegrity({bool refresh = false}) => UDevice.integrity(refresh: refresh);

  /// True when rooted, hooked or being debugged.
  static Future<bool> isDeviceCompromised() async => (await UDevice.integrity()).isCompromised;

  /// True when rooted (Android) or jailbroken (iOS).
  static Future<bool> isRooted() async => (await UDevice.integrity()).rooted;

  /// Ready-made X-Device-* / X-App-* headers for your API calls.
  static Map<String, String> get deviceHeaders => UDevice.headers;

  /// User-Agent string, e.g. "MyApp/1.4.0+12 (Android 14; SM-S918B)".
  static String get userAgent => UDevice.userAgent;

  // --- UPackage, one wrapper each -----------------------------------------------------------

  /// True once app info is loaded.
  static bool get isPackageInfoReady => UPackage.isReady;

  /// Version with build, e.g. "1.4.0+12".
  static String get fullVersion => UPackage.fullVersion;

  /// When the app was first installed.
  static DateTime? get installTime => UPackage.installTime;

  /// When the app was last updated.
  static DateTime? get updateTime => UPackage.updateTime;

  /// Where the app came from: Play, App Store, Bazaar, Myket, sideload, …
  static UInstaller get installer => UPackage.installer;

  /// Android signing certificate fingerprint, to detect repackaged APKs.
  static String? get signatureSha256 => UPackage.signatureSha256;

  /// Build flavor name, if one was used.
  static String? get flavor => UPackage.flavor;

  /// True in debug builds.
  static bool get isDebug => UPackage.isDebug;

  /// True in profile builds.
  static bool get isProfile => UPackage.isProfile;

  /// True in release builds.
  static bool get isRelease => UPackage.isRelease;

  /// True on the very first launch after install.
  static bool get isFirstLaunch => UPackage.isFirstLaunch;

  /// True on the first launch of this version.
  static bool get isFirstLaunchOfVersion => UPackage.isFirstLaunchOfVersion;

  /// True when the app was updated since the last launch.
  static bool get justUpdated => UPackage.justUpdated;

  /// Version that ran last time (null on first launch).
  static String? get previousVersion => UPackage.previousVersion;

  /// How many times the app has been opened.
  static int get launchCount => UPackage.launchCount;

  /// When the app was opened for the first time.
  static DateTime? get firstLaunchTime => UPackage.firstLaunchTime;

  /// When this version was opened for the first time.
  static DateTime? get versionFirstLaunchTime => UPackage.versionFirstLaunchTime;

  /// Compares two versions: negative if a < b, 0 if equal, positive if a > b.
  static int compareVersions(String a, String b) => UPackage.compareVersions(a, b);

  /// True when this app's version is [minimum] or newer.
  static bool isVersionAtLeast(String minimum) => UPackage.isAtLeast(minimum);

  /// True when this app's version is older than [other].
  static bool isVersionOlderThan(String other) => UPackage.isOlderThan(other);
}
