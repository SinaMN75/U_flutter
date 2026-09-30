import "package:intl/intl.dart" as intl;
import "package:u/utilities.dart";

/// Formatting, Jalali conversion, "time ago" and day math on DateTime. `DateTime.now().toJalaliDate()`
extension DateTimeExtensions on DateTime {
  /// Formats with an intl pattern. `date.formatDate("yyyy-MM-dd HH:mm")`
  String formatDate(String dateFormat) => intl.DateFormat(dateFormat).format(this);

  /// The current UTC time (ignores this date). `DateTime.now().utcNow()`
  DateTime utcNow() => DateTime.now().toUtc();

  /// The current UTC time as ISO text, ready for an API. "2024-03-20T10:00:00.000Z"
  String utcNowIso() => DateTime.now().toUtc().toIso8601String();

  /// Jalali date and time. "1403/01/01 14:05"
  String toJalaliDateTime() => "${toJalali().formatCompactDate()} ${hour.twoDigits}:${minute.twoDigits}";

  /// Jalali date and time with seconds. "1403/01/01 14:05:09"
  String toJalaliDateTimeSeconds() => "${toJalali().formatCompactDate()} ${hour.twoDigits}:${minute.twoDigits}:${second.twoDigits}";

  /// Jalali date. "1403/01/01"
  String toJalaliDate() => toJalali().formatCompactDate();

  /// Converts to a UJalali date for Jalali math and formatting. `date.toJalali().formatFullDate()`
  UJalali toJalali() => UJalali.fromDateTime(this);

  /// Jalali date with your own pattern (yyyy, mm, dd, mN month name, wN weekday…). `date.toJalaliFormat("wN dd mN yyyy")`
  String toJalaliFormat(String pattern, {bool persianDigits = false}) => toJalali().formatCustom(pattern, persianDigits: persianDigits);

  /// Short "time ago": "3h", "2d", "Just now" or "۳ ساعت پیش" with [persian]. `createdAt.toTimeAgo(persian: true)`
  String toTimeAgo({bool numericDates = false, bool persian = false}) {
    final Duration difference = DateTime.now().difference(this);
    String n(int value) => persian ? value.toString().toPersianNumber() : value.toString();
    final int years = difference.inDays ~/ 365;
    final int months = difference.inDays ~/ 30;
    final int weeks = difference.inDays ~/ 7;
    if (years >= 2) return persian ? "${n(years)} سال پیش" : "${years}y";
    if (years >= 1) return persian ? (numericDates ? "۱ سال پیش" : "سال پیش") : (numericDates ? "1y" : "Last year");
    if (months >= 2) return persian ? "${n(months)} ماه پیش" : "${months}M";
    if (months >= 1) return persian ? (numericDates ? "۱ ماه پیش" : "ماه پیش") : (numericDates ? "1M" : "Last month");
    if (weeks >= 2) return persian ? "${n(weeks)} هفته پیش" : "${weeks}w";
    if (weeks >= 1) return persian ? (numericDates ? "۱ هفته پیش" : "هفته پیش") : (numericDates ? "1w" : "Last week");
    if (difference.inDays >= 2) return persian ? "${n(difference.inDays)} روز پیش" : "${difference.inDays}d";
    if (difference.inDays >= 1) return persian ? (numericDates ? "۱ روز پیش" : "دیروز") : (numericDates ? "1d" : "Yesterday");
    if (difference.inHours >= 2) return persian ? "${n(difference.inHours)} ساعت پیش" : "${difference.inHours}h";
    if (difference.inHours >= 1) return persian ? (numericDates ? "۱ ساعت پیش" : "یک ساعت پیش") : (numericDates ? "1h" : "An hour ago");
    if (difference.inMinutes >= 2) return persian ? "${n(difference.inMinutes)} دقیقه پیش" : "${difference.inMinutes}m";
    if (difference.inMinutes >= 1) return persian ? (numericDates ? "۱ دقیقه پیش" : "یک دقیقه پیش") : (numericDates ? "1m" : "A minute ago");
    if (difference.inSeconds >= 3) return persian ? "${n(difference.inSeconds)} ثانیه پیش" : "${difference.inSeconds}s";
    return persian ? "همین الان" : "Just now";
  }

  /// Same calendar day as [other] (time ignored). `a.isSameDay(b)`
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  /// True when this is today.
  bool get isToday => isSameDay(DateTime.now());

  /// True when this was yesterday.
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// True when this is tomorrow.
  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  /// True when this moment has passed.
  bool get isPast => isBefore(DateTime.now());

  /// True when this moment is still ahead.
  bool get isFuture => isAfter(DateTime.now());

  /// Midnight at the start of this day. `date.startOfDay`
  DateTime get startOfDay => copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  /// The last moment of this day (23:59:59.999). `date.endOfDay`
  DateTime get endOfDay => copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 0);

  /// The first day of this Gregorian month at midnight.
  DateTime get startOfMonth => DateTime(year, month);

  /// Adds whole months, clamping the day (Jan 31 + 1 month → Feb 28/29). `date.addMonths(1)`
  DateTime addMonths(int months) {
    final int target = year * 12 + month - 1 + months;
    final int y = target ~/ 12;
    final int m = target % 12 + 1;
    final int lastDay = DateTime(y, m + 1, 0).day;
    return copyWith(year: y, month: m, day: min(day, lastDay));
  }

  /// Whole calendar days from this date to [other] (negative when [other] is earlier). `today.daysUntil(birthday)`
  int daysUntil(DateTime other) => DateTime.utc(other.year, other.month, other.day).difference(DateTime.utc(year, month, day)).inDays;

  /// Full years from this birth date until today. `birthDate.age`
  int get age {
    final DateTime now = DateTime.now();
    int years = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) years--;
    return years;
  }
}
