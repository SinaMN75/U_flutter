import "package:flutter/services.dart";

abstract class ScreenGuard {
  static const MethodChannel _channel = MethodChannel("u/screen_guard");
  static void Function()? onScreenshot;

  static void Function(bool active)? onScreenRecording;

  static bool _handlerAttached = false;

  static void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "onScreenshot":
          onScreenshot?.call();
        case "onScreenRecording":
          onScreenRecording?.call(call.arguments == true);
      }
    });
  }

  static Future<void> enable() async {
    _attachHandler();
    try {
      await _channel.invokeMethod<void>("enable");
    } catch (_) {}
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>("disable");
    } catch (_) {}
  }
}
