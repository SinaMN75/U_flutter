import "package:u/utilities.dart";

/// Helpers on every number: durations, file sizes, percentages, Persian words. `5.seconds`, `1536.toBKMG()`
extension NumExtension on num {
  /// Bytes → readable size. 1536 → "1.5 KB"
  String toBKMG() {
    if (this <= 0) return "0 B";
    const List<String> suffixes = <String>["B", "KB", "MB", "GB", "TB", "PB"];
    final int i = this < 1 ? 0 : min((log(this) / log(1024)).floor(), suffixes.length - 1);
    final num value = this / pow(1024, i);
    return "${i == 0 ? value.round() : value.toStringAsFixed(1)} ${suffixes[i]}";
  }

  /// This many milliseconds. `300.ms`
  Duration get ms => Duration(microseconds: (this * 1000).round());

  /// This many seconds. `2.seconds`, `1.5.seconds`
  Duration get seconds => Duration(microseconds: (this * 1000000).round());

  /// This many minutes. `5.minutes`
  Duration get minutes => Duration(microseconds: (this * 60000000).round());

  /// This many hours. `2.hours`
  Duration get hours => Duration(microseconds: (this * 3600000000).round());

  /// This many days. `7.days`
  Duration get days => Duration(microseconds: (this * 86400000000).round());

  /// True when between [low] and [high] (both included). `age.between(18, 60)`
  bool between(num low, num high) => this >= low && this <= high;

  /// What percent this is of [total]. `25.percentOf(200)` → 12.5
  double percentOf(num total) => total == 0 ? 0 : this * 100 / total;

  /// As a percent label; [digits] decimals; set fromFraction false when it is already 0-100. `0.256.toPercent()` → "26%"
  String toPercent({int digits = 0, bool fromFraction = true}) => "${(fromFraction ? this * 100 : this).toStringAsFixed(digits)}%";

  /// Number in Persian words. `1250.toPersianWords()` → "یک هزار و دویست و پنجاه"
  String toPersianWords() => UPersianTools.numberToWords(this) ?? toString();

  /// Groups the whole part with commas, decimals untouched. 1234567.8 → "1,234,567.8"
  String get withCommas {
    final String text = toString();
    final int dot = text.indexOf(".");
    final String whole = dot < 0 ? text : text.substring(0, dot);
    return "${whole.separateNumbers3By3()}${dot < 0 ? "" : text.substring(dot)}";
  }
}

/// Rounding and money formatting on doubles. `1234.5.separate3By3()`
extension DoubleExtionsion on double {
  /// Cuts to [maxPrecision] decimals (no rounding), then groups with commas. 1234567.891 → "1,234,567"
  String separate3By3({int maxPrecision = 0}) => toStringAsSmartRound(maxPrecision: maxPrecision).separateNumbers3By3();

  /// Cuts to [maxPrecision] decimals and drops trailing zeros. 2.50 → "2.5", 3.0 → "3"
  String toStringAsSmartRound({int maxPrecision = 2}) {
    final String str = toString();
    if (!str.contains(".") || str.contains("e")) return str;
    final int periodIndex = str.indexOf(".");
    final String wholePart = str.substring(0, periodIndex);
    final String mantissa = str.substring(periodIndex + 1, min(str.length, periodIndex + 1 + maxPrecision)).replaceAll(RegExp(r"0+$"), "");
    return mantissa.isEmpty ? wholePart : "$wholePart.$mantissa";
  }

  /// toInt() clamped to [minValue]/[maxValue]. `150.7.toSafeInt(maxValue: 100)` → 100
  int toSafeInt({int? minValue, int? maxValue}) {
    if (minValue != null && this < minValue) return minValue;
    if (maxValue != null && this > maxValue) return maxValue;
    return toInt();
  }
}

/// Money, counts, time and month-name helpers on ints. `1500000.toman()`
extension IntExtesion on int {
  /// Subtracts and clamps between [minValue] and [maxValue]. `stock.subtractClamping(5)`
  int subtractClamping(int subtract, {int minValue = 0, int maxValue = 999999999}) => (this - subtract).clamp(minValue, maxValue);

  /// Short count. 1500 → "1.5 K", 2300000 → "2.3 M"
  String toKMB() {
    if (this < 1000) return toString();
    if (this < 100000) return "${(this / 1000).toStringAsFixed(1)} K";
    if (this < 1000000) return "${(this / 1000).toStringAsFixed(0)} K";
    if (this < 1000000000) return "${(this / 1000000).toStringAsFixed(1)} M";
    return "${(this / 1000000000).toStringAsFixed(1)} B";
  }

  /// 1500000 → "1,500,000 ریال"; [removeNegative] drops the minus sign.
  String rial({bool removeNegative = false}) => "${toString().separateNumbers3By3()} ریال".replaceAll(removeNegative ? "-" : "", "");

  /// 1500000 → "1,500,000"; [removeNegative] drops the minus sign.
  String separate3By3({bool removeNegative = false}) => toString().separateNumbers3By3().replaceAll(removeNegative ? "-" : "", "");

  /// 1500000 → "1,500,000 تومان"; [removeNegative] drops the minus sign.
  String toman({bool removeNegative = false}) => "${toString().separateNumbers3By3()} تومان".replaceAll(removeNegative ? "-" : "", "");

  /// Rial → toman (÷10). 150000 → "15,000 تومان"
  String rialToToman({bool removeNegative = false}) => "${(this ~/ 10).toString().separateNumbers3By3()} تومان".replaceAll(removeNegative ? "-" : "", "");

  /// Seconds → countdown text. 75 → "01:15", 3725 → "01:02:05", 9 → "09"
  String secondsToTimeLeft() {
    final int h = this ~/ 3600;
    final int m = (this % 3600) ~/ 60;
    final int s = this % 60;
    if (h > 0) return "${h.twoDigits}:${m.twoDigits}:${s.twoDigits}";
    if (m > 0) return "${m.twoDigits}:${s.twoDigits}";
    return s.twoDigits;
  }

  /// Zero-padded to 2 digits. 5 → "05"
  String get twoDigits => toString().padLeft(2, "0");

  /// Month name: Jalali when [isJalali], else short English. `1.getMonthName(true)` → "فروردین"
  String getMonthName(bool isJalali) => isJalali ? jalaliMonthName : gregorianMonthName;

  /// Jalali month name for 1-12. 1 → "فروردین"
  String get jalaliMonthName => this >= 1 && this <= 12 ? JalaliExt.months[this - 1] : "$this";

  /// Short English month name for 1-12. 1 → "Jan"
  String get gregorianMonthName {
    const List<String> names = <String>["Jan", "Feb", "March", "April", "May", "June", "July", "August", "Sep", "Oct", "Nov", "Dec"];
    return this >= 1 && this <= 12 ? names[this - 1] : "$this";
  }

  /// Milliseconds since 1970 → DateTime. `1700000000000.toDateTime()`
  DateTime toDateTime({bool isUtc = false}) => DateTime.fromMillisecondsSinceEpoch(this, isUtc: isUtc);
}

/// Money formatting on int? (null counts as 0). `user.balance.toman()`
extension OptionalIntExtension on int? {
  /// null → "0 ریال", 1500 → "1,500 ریال".
  String rial({bool removeNegative = false}) => "${(this ?? 0).toString().separateNumbers3By3()} ریال".replaceAll(removeNegative ? "-" : "", "").trim();

  /// null → "0 تومان", 1500 → "1,500 تومان".
  String toman({bool removeNegative = false}) => "${(this ?? 0).toString().separateNumbers3By3()} تومان".replaceAll(removeNegative ? "-" : "", "").trim();

  /// Rial → toman (÷10); null counts as 0.
  String rialToToman({bool removeNegative = false}) => "${((this ?? 0) ~/ 10).toString().separateNumbers3By3()} تومان".replaceAll(removeNegative ? "-" : "", "").trim();

  /// The number as text, or "" when null.
  String toStringOrEmptyIfNull() => this == null ? "" : toString();
}

/// Money formatting on double? (null counts as 0, decimals dropped). `price.toman()`
extension OptionalDoubleExtension on double? {
  /// null → "0 ریال", 1500.7 → "1,500 ریال".
  String rial({bool removeNegative = false}) => "${(this ?? 0).toInt().toString().separateNumbers3By3()} ریال".replaceAll(removeNegative ? "-" : "", "").trim();

  /// null → "0 تومان", 1500.7 → "1,500 تومان".
  String toman({bool removeNegative = false}) => "${(this ?? 0).toInt().toString().separateNumbers3By3()} تومان".replaceAll(removeNegative ? "-" : "", "").trim();

  /// Rial → toman (÷10, decimals dropped); null counts as 0.
  String rialToTomanMoneyPersian({bool removeNegative = false}) => "${((this ?? 0) ~/ 10).toString().separateNumbers3By3()} تومان".replaceAll(removeNegative ? "-" : "", "").trim();

  /// The number as text, or "" when null.
  String toStringOrEmptyIfNull() => this == null ? "" : toString();
}

/// Readable durations. `90.seconds.toClock()` → "01:30"
extension UDurationExtension on Duration {
  /// "HH:MM:SS", or "MM:SS" under an hour. 90 s → "01:30"
  String toClock() {
    final int h = inHours;
    final int m = inMinutes % 60;
    final int s = inSeconds % 60;
    return h > 0 ? "${h.twoDigits}:${m.twoDigits}:${s.twoDigits}" : "${m.twoDigits}:${s.twoDigits}";
  }

  /// Largest two units in words. 3725 s → "1h 2m", persian → "۱ ساعت و ۲ دقیقه"
  String toHuman({bool persian = false}) {
    final List<(int, String, String)> parts = <(int, String, String)>[
      (inDays, "d", "روز"),
      (inHours % 24, "h", "ساعت"),
      (inMinutes % 60, "m", "دقیقه"),
      (inSeconds % 60, "s", "ثانیه"),
    ].where(((int, String, String) p) => p.$1 > 0).take(2).toList();
    if (parts.isEmpty) return persian ? "۰ ثانیه" : "0s";
    return persian ? parts.map(((int, String, String) p) => "${p.$1.toString().toPersianNumber()} ${p.$3}").join(" و ") : parts.map(((int, String, String) p) => "${p.$1}${p.$2}").join(" ");
  }

  /// Waits this long. `await 2.seconds.delay()`
  Future<void> delay() => Future<void>.delayed(this);
}
