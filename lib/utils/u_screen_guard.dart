import "package:u/utilities.dart";

/// Hides the app from screenshots and screen recordings (banking, OTP, paid videos). Android, iOS, macOS, Windows; Linux/web do nothing. `UScreenGuard.enable()`
abstract final class UScreenGuard {
  /// Blocks screenshots and recordings (Android/Windows/macOS: captured black; iOS: hidden in recordings/screenshots). `await UScreenGuard.enable()`
  static Future<void> enable() => UScreenGuardChannel.enable();

  /// Allows screenshots and recordings again. `await UScreenGuard.disable()`
  static Future<void> disable() => UScreenGuardChannel.disable();

  /// Turns protection on or off. `UScreenGuard.set(enabled: isSensitivePage)`
  static Future<void> set({required bool enabled}) => enabled ? enable() : disable();

  /// True while protection is on.
  static bool get isEnabled => UScreenGuardChannel.enabled;

  /// Runs when the user takes a screenshot (iOS only). `UScreenGuard.onScreenshot = () => UToast.warning(message: "Screenshots are not allowed")`
  static void Function()? get onScreenshot => UScreenGuardChannel.onScreenshot;

  /// Runs when the user takes a screenshot (iOS only). `UScreenGuard.onScreenshot = () => UToast.warning(message: "Screenshots are not allowed")`
  static set onScreenshot(void Function()? callback) => UScreenGuardChannel.onScreenshot = callback;

  /// Runs with true/false when screen recording starts/stops (iOS only). `UScreenGuard.onScreenRecording = (on) => pauseVideo()`
  static void Function(bool active)? get onScreenRecording => UScreenGuardChannel.onScreenRecording;

  /// Runs with true/false when screen recording starts/stops (iOS only). `UScreenGuard.onScreenRecording = (on) => pauseVideo()`
  static set onScreenRecording(void Function(bool active)? callback) => UScreenGuardChannel.onScreenRecording = callback;
}
