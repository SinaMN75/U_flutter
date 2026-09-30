import "package:u/src/datasets/u_timezone_names.dart";
import "package:u/utilities.dart";

/// Device time zone as an IANA id and UTC offset; UHttpClient sends it in the "Timezone" header. `UTimezone.getLocalTimezone()` → "Asia/Tehran"
abstract class UTimezone {
  /// IANA zone of the device, e.g. "Asia/Tehran" (reported by the OS; guessed from the offset when unknown).
  static String getLocalTimezone() {
    final String? native = UDevice.isReady ? UDevice.timeZone : null;
    if (native != null && native.contains("/")) return native;
    final DateTime now = DateTime.now();
    return uGuessIanaZone(now.timeZoneName, offsetText());
  }

  /// Current offset from UTC (changes with daylight saving). `UTimezone.getTimezoneOffset().inMinutes` → 210
  static Duration getTimezoneOffset() => DateTime.now().timeZoneOffset;

  /// Current offset as text. `UTimezone.offsetText()` → "+03:30"
  static String offsetText() {
    final Duration offset = DateTime.now().timeZoneOffset;
    final String sign = offset.isNegative ? "-" : "+";
    final int minutes = offset.inMinutes.abs();
    return "$sign${(minutes ~/ 60).twoDigits}:${(minutes % 60).twoDigits}";
  }
}
