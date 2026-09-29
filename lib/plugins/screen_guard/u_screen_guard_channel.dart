import "package:flutter/services.dart";

/// Native side of UScreenGuard ("u/screen_guard"): blocks screenshots / recording and reports them.
abstract final class UScreenGuardChannel {
  static const MethodChannel _channel = MethodChannel("u/screen_guard");
  static void Function()? onScreenshot;
  static void Function(bool active)? onScreenRecording;
  static bool _handlerAttached = false;
  static bool enabled = false;

  static void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler(
      (MethodCall call) async {
        switch (call.method) {
          case "onScreenshot":
            onScreenshot?.call();
            break;
          case "onScreenRecording":
            onScreenRecording?.call(call.arguments == true);
            break;
        }
      },
    );
  }

  static Future<void> enable() async {
    _attachHandler();
    await _invoke("enable");
    enabled = true;
  }

  static Future<void> disable() async {
    await _invoke("disable");
    enabled = false;
  }

  // Linux and the web have no native guard: treat it as a no-op instead of throwing.
  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      return;
    }
  }
}
