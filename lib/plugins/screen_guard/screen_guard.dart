import "package:flutter/services.dart";

/// Fully native screenshot / screen-recording prevention, provided by the
/// `u` plugin. Bridges to platform code over a dedicated [MethodChannel]
/// named `u/screen_guard`. Prevention is applied natively on every platform:
///   - Android: `FLAG_SECURE` (screenshots and recordings are blocked).
///   - iOS: secure-field capture blocking + screenshot / recording detection.
///   - macOS: `NSWindow.sharingType = .none`.
///   - Windows: `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)`.
///   - Linux / web: no-op (no platform capture-prevention API).
///
/// Optional detection callbacks fire when the OS cannot fully block capture
/// (mainly iOS): [onScreenshot] and [onScreenRecording].
abstract class ScreenGuard {
  static const MethodChannel _channel = MethodChannel("u/screen_guard");

  /// Fired on iOS when the user takes a screenshot despite blocking.
  static void Function()? onScreenshot;

  /// Fired when a screen recording / mirroring session starts or stops.
  /// The bool is `true` while capture is active.
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

  /// Turn on capture prevention for the current window/activity.
  static Future<void> enable() async {
    _attachHandler();
    try {
      await _channel.invokeMethod<void>("enable");
    } on PlatformException catch (_) {
      // Platform without a guard implementation (e.g. web) is a no-op.
    } on MissingPluginException catch (_) {}
  }

  /// Turn off capture prevention (e.g. to allow an intended export screen).
  static Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>("disable");
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }
}
