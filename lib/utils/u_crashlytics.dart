import "package:u/utilities.dart";

/// Receives each crash report as a JSON-ready map (error, stack, app, device, screen).
typedef UCrashListener = void Function(Map<String, dynamic> errorData);

/// Catches every uncaught Dart/Flutter error with app, device and screen info, so you can send it to your server. `UCrashlytics.initialize(onCrash: (report) => api.logCrash(report))`
class UCrashlytics {
  static UCrashListener? _crashListener;

  /// Starts catching errors; previous handlers (console, other reporters) keep working. Call it in main() after initU().
  static Future<void> initialize({UCrashListener? onCrash}) async {
    _crashListener = onCrash;
    // Chain the previous handlers so errors still reach the console / other reporters.
    final bool Function(Object, StackTrace)? previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _recordError(error, stack);
      previousPlatform?.call(error, stack);
      return true;
    };
    final FlutterExceptionHandler? previousFlutter = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _recordFlutterError(details);
      previousFlutter?.call(details);
    };
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
      await UDevice.init();
      final UDeviceInfo device = UDevice.info;
      return <String, dynamic>{
        "type": device.os,
        "model": device.model,
        "manufacturer": device.manufacturer,
        "osVersion": device.osVersion,
        "physical": device.isPhysical,
        if (UApp.isWeb) "browser": "${device.extra["browser"]} ${device.extra["browserVersion"]}",
      };
    } catch (e) {
      return <String, dynamic>{"error": "Failed to get detailed device info: $e"};
    }
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
        "deviceType": _getDeviceType(),
      };
    } catch (e) {
      return <String, dynamic>{"error": "Failed to get screen info: $e"};
    }
  }

  static String _getDeviceType() {
    if (UApp.isWeb) return "Web";
    if (UApp.isTablet()) return "Tablet";
    if (UApp.isPhone()) return "Phone";
    if (UApp.isDesktop) {
      if (UApp.isDesktopSize()) return "Desktop (large)";
      return "Desktop";
    }
    return "Unknown";
  }

  /// Reports an error you caught yourself. `catch (e, s) { UCrashlytics.reportError(e, s); }`
  static void reportError(dynamic error, StackTrace stackTrace) {
    _recordError(error, stackTrace);
  }
}
