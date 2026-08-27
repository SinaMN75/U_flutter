import "package:u/utilities.dart";
import "package:u/utils/web/u_web_stub.dart" if (dart.library.html) "package:u/utils/web/u_web_impl.dart";

abstract class UApp {
  static late PackageInfo packageInfo;
  static DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  static late AndroidDeviceInfo androidDeviceInfo;
  static late IosDeviceInfo iosDeviceInfo;
  static late WebBrowserInfo webBrowserInfo;
  static late MacOsDeviceInfo macOsDeviceInfo;
  static late WindowsDeviceInfo windowsDeviceInfo;
  static late LinuxDeviceInfo linuxDeviceInfo;

  static String name = packageInfo.appName;

  static String packageName = packageInfo.packageName;

  static String version = packageInfo.version;

  static String buildNumber = packageInfo.buildNumber;

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

  static String deviceId() {
    try {
      if (isAndroid) return androidDeviceInfo.id;
      if (isIos) return iosDeviceInfo.identifierForVendor ?? "";
      if (isMacOs) return macOsDeviceInfo.systemGUID ?? "";
      if (isWindows) return windowsDeviceInfo.deviceId;
      if (isLinux) return linuxDeviceInfo.machineId ?? "";
    } catch (_) {
      return "";
    }
    return "";
  }

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
    return embedDetectFromDom();
  }
}
