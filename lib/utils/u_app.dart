import "package:u/utilities.dart";
import "package:u/utils/web/u_web_native.dart" if (dart.library.js_interop) "package:u/utils/web/u_web_browser.dart";

abstract class UApp {
  /// This app's package info (same field names as package_info_plus). See [UPackage].
  static UPackageInfo get packageInfo => UPackage.info;

  /// This device's info on every platform in one model. See [UDevice].
  static UDeviceInfo get deviceInfo => UDevice.info;

  static String get name => UPackage.appName;

  static String get packageName => UPackage.packageName;

  static String get version => UPackage.version;

  static String get buildNumber => UPackage.buildNumber;

  static bool get isWeb => kIsWeb;

  static bool get isAndroid => !isWeb && Platform.isAndroid;

  static bool get isIos => !isWeb && Platform.isIOS;

  static bool get isMacOs => !isWeb && Platform.isMacOS;

  static bool get isWindows => !isWeb && Platform.isWindows;

  static bool get isLinux => !isWeb && Platform.isLinux;

  static bool get isFuchsia => !isWeb && Platform.isFuchsia;

  static bool get isMobile => isAndroid || isIos;

  static bool get isDesktop => isMacOs || isWindows || isLinux;

  static bool get isDarkMode => UAppState.isDarkMode;

  /// Stable device id; see [UDevice.id]. Empty before `initU()` completes.
  static String deviceId() => UDevice.isReady ? UDevice.id : "";

  static bool isLandscape() => MediaQuery.of(navigatorKey.currentContext!).orientation == Orientation.landscape;

  static bool isPortrait() => MediaQuery.of(navigatorKey.currentContext!).orientation == Orientation.portrait;

  static bool isTablet() => !isWeb && MediaQuery.of(navigatorKey.currentContext!).size.shortestSide >= 600;

  static bool isPhone() => !isWeb && MediaQuery.of(navigatorKey.currentContext!).size.shortestSide < 600;

  static bool isMobileSize() => MediaQuery.of(navigatorKey.currentContext!).size.width < 850;

  static bool isTabletSize() => MediaQuery.of(navigatorKey.currentContext!).size.width < 1100 && MediaQuery.of(navigatorKey.currentContext!).size.width >= 850;

  static bool isDesktopSize() => MediaQuery.of(navigatorKey.currentContext!).size.width >= 1100;

  static String locale() => UAppState.locale.value.languageCode;

  static void updateLocale(Locale locale) {
    UAppState.updateLocale(locale);
    ULocalStorage.set(UConstants.locale, locale.languageCode);
  }

  static bool isDarkTheme() => UAppState.isDarkMode;

  static void toDarkMode() {
    UAppState.changeThemeMode(ThemeMode.dark);
    ULocalStorage.setDarkMode(true);
  }

  static void toLightMode() {
    UAppState.changeThemeMode(ThemeMode.light);
    ULocalStorage.setDarkMode(false);
  }

  static bool? _isEmbedded;

  static Map<String, String> get queryParameters => Uri.base.queryParameters;

  static bool get isEmbedded => _isEmbedded ??= _detectEmbedded();

  static bool _detectEmbedded() {
    if (!isWeb) return false;
    if ((queryParameters["embedded"] ?? "").toLowerCase() == "true") return true;
    return UWebBridge.isEmbedded();
  }

  static Future<void> initDeviceInfo() => UDevice.init();
}
