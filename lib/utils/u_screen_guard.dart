import "package:u/utilities.dart";

/// Blocks screenshots and screen recording of the app, and tells you when someone tries.
abstract final class UScreenGuard {
  /// Blocks screenshots / screen recording (Android, iOS, macOS, Windows; no-op on Linux and web).
  static Future<void> enable() => UScreenGuardChannel.enable();

  /// Allows screenshots / screen recording again.
  static Future<void> disable() => UScreenGuardChannel.disable();

  /// Turns protection on or off.
  static Future<void> set({required bool enabled}) => enabled ? enable() : disable();

  /// True while protection is on.
  static bool get isEnabled => UScreenGuardChannel.enabled;

  /// Called when the user takes a screenshot (iOS).
  static void Function()? get onScreenshot => UScreenGuardChannel.onScreenshot;

  /// Sets what happens when the user takes a screenshot.
  static set onScreenshot(void Function()? callback) => UScreenGuardChannel.onScreenshot = callback;

  /// Called with true/false when screen recording starts/stops (iOS).
  static void Function(bool active)? get onScreenRecording => UScreenGuardChannel.onScreenRecording;

  /// Sets what happens when screen recording starts/stops.
  static set onScreenRecording(void Function(bool active)? callback) => UScreenGuardChannel.onScreenRecording = callback;
}
