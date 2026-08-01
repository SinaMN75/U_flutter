import "package:u/utilities.dart";

typedef CrashListener = void Function(Map<String, dynamic> errorData);

class UCrashlytics {
  static CrashListener? _crashListener;

  static Future<void> initialize({CrashListener? onCrash}) async {
    _crashListener = onCrash;

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _recordError(error, stack);
      return true;
    };

    FlutterError.onError = _recordFlutterError;
  }

  static Future<void> _recordError(dynamic error, StackTrace stack) async {
    final Map<String, dynamic> errorData = <String, dynamic>{
      "type": "DART_ERROR",
      "timestamp": DateTime.now().toIso8601String(),
      "error": <String, String>{
        "type": error.runtimeType.toString(),
        "message": error.toString(),
      },
      "stackTrace": _formatStackTrace(stack),
      "systemInfo": await _getSystemInfo(),
    };

    _crashListener?.call(errorData);
  }

  static Future<void> _recordFlutterError(FlutterErrorDetails details) async {
    final Map<String, dynamic> errorData = <String, dynamic>{
      "type": "FLUTTER_ERROR",
      "timestamp": DateTime.now().toIso8601String(),
      "error": <String, String?>{
        "library": details.library,
        "exceptionType": details.exception.runtimeType.toString(),
        "exception": details.exception.toString(),
      },
      "stackTrace": _formatFlutterStackTrace(details.stack),
      "context": details.context?.toString() ?? "No context",
      "additionalInfo": details.informationCollector != null ? _formatInformationCollector(details.informationCollector) : null,
      "systemInfo": await _getSystemInfo(),
    };

    _crashListener?.call(errorData);
  }

  static String _formatStackTrace(StackTrace? stack) {
    if (stack == null) return "";
    if (stack == StackTrace.empty) return "Empty stack trace provided";
    return stack.toString();
  }

  static String _formatFlutterStackTrace(StackTrace? stack) {
    if (stack == null) return "";
    return stack.toString();
  }

  static List<String> _formatInformationCollector(InformationCollector? collector) {
    if (collector == null) return <String>[];

    try {
      final Iterable<DiagnosticsNode> information = collector();
      return information.map((DiagnosticsNode info) => info.toString()).toList();
    } catch (e) {
      return <String>["Failed to collect additional information: $e"];
    }
  }

  static Future<Map<String, dynamic>> _getSystemInfo() async => <String, dynamic>{
    "app": <String, String>{
      "name": UApp.name,
      "packageName": UApp.packageName,
      "version": UApp.version,
      "buildNumber": UApp.buildNumber,
    },
    "platform": _getPlatformInfo(),
    "device": await _getDeviceInfo(),
    "screen": _getScreenInfo(),
    "locale": UApp.locale(),
  };

  static String _getPlatformInfo() {
    if (UApp.isWeb) return "Web";
    if (UApp.isAndroid) return "Android";
    if (UApp.isIos) return "iOS";
    if (UApp.isMacOs) return "macOS";
    if (UApp.isWindows) return "Windows";
    if (UApp.isLinux) return "Linux";
    if (UApp.isFuchsia) return "Fuchsia";
    return "Unknown";
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (UApp.isAndroid) {
        return <String, dynamic>{
          "type": "Android",
          "model": UApp.androidDeviceInfo.model,
          "manufacturer": UApp.androidDeviceInfo.manufacturer,
          "osVersion": UApp.androidDeviceInfo.version.release,
        };
      } else if (UApp.isIos) {
        return <String, dynamic>{
          "type": "iOS",
          "model": UApp.iosDeviceInfo.model,
          "osVersion": UApp.iosDeviceInfo.systemVersion,
        };
      } else if (UApp.isWeb) {
        return <String, dynamic>{
          "type": "Web",
          "browser": UApp.webBrowserInfo.browserName.name,
          "version": UApp.webBrowserInfo.appVersion,
        };
      } else if (UApp.isMacOs) {
        return <String, dynamic>{
          "type": "macOS",
          "model": UApp.macOsDeviceInfo.model,
          "osVersion": UApp.macOsDeviceInfo.osRelease,
        };
      } else if (UApp.isWindows) {
        return <String, dynamic>{
          "type": "Windows",
          "computerName": UApp.windowsDeviceInfo.computerName,
          "version": UApp.windowsDeviceInfo.majorVersion,
        };
      } else if (UApp.isLinux) {
        return <String, dynamic>{
          "type": "Linux",
          "name": UApp.linuxDeviceInfo.name,
          "version": UApp.linuxDeviceInfo.version,
        };
      }
    } catch (e) {
      return <String, dynamic>{"error": "Failed to get detailed device info: $e"};
    }
    return <String, dynamic>{"type": "Unknown device"};
  }

  static Map<String, dynamic> _getScreenInfo() {
    try {
      final MediaQueryData media = MediaQuery.of(navigatorKey.currentContext!);
      final Size size = media.size;

      return <String, dynamic>{
        "size": <String, double>{
          "width": size.width,
          "height": size.height,
        },
        "pixelRatio": media.devicePixelRatio,
        "orientation": media.orientation.name,
        "deviceType": _getDeviceType(navigatorKey.currentContext!),
      };
    } catch (e) {
      return <String, dynamic>{"error": "Failed to get screen info: $e"};
    }
  }

  static String _getDeviceType(BuildContext context) {
    if (UApp.isWeb) return "Web";
    if (UApp.isTablet()) return "Tablet";
    if (UApp.isPhone()) return "Phone";
    if (UApp.isDesktop) {
      if (UApp.isDesktopSize()) return "Desktop (large)";
      return "Desktop";
    }
    return "Unknown";
  }

  static void reportError(dynamic error, StackTrace stackTrace) {
    _recordError(error, stackTrace);
  }
}
