import "package:flutter/services.dart";

abstract final class ScreenGuard {
  static const MethodChannel _channel = MethodChannel("u/screen_guard");
  static void Function()? onScreenshot;
  static void Function(bool active)? onScreenRecording;
  static bool _handlerAttached = false;

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
    await _channel.invokeMethod<void>("enable");
  }

  static Future<void> disable() async => await _channel.invokeMethod<void>("disable");
}
