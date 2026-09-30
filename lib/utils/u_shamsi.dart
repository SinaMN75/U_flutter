import "dart:math" as math;

// Abstract base class for date formatting
/// Pieces of a date as text (y, yyyy, mm, mN month name, wN weekday…); get one from date.formatter.
abstract class UDateFormatter {
  static final RegExp _asciiDigits = RegExp("[0-9]");

  /// The date being formatted.
  final UDate date;

  /// Formatter for [date].
  const UDateFormatter(this.date);

  /// Year. "1403"
  String get y => date.year.toString();

  /// Year padded to 4 digits.
  String get yyyy {
    if (date.year < 0 || date.year > 9999) throw RangeError("Year out of range: ${date.year}");
    return date.year.toString().padLeft(4, "0");
  }

  /// Last two digits of the year. "03"
  String get yy {
    if (date.year < 1000 || date.year > 9999) throw RangeError("Year out of range: ${date.year}");
    return (date.year % 100).toString().padLeft(2, "0");
  }

  /// Month number. "1"
  String get m => date.month.toString();

  /// Month padded to 2 digits. "01"
  String get mm => m.padLeft(2, "0");

  /// Month name. "فروردین"
  String get mN;

  /// Day number. "5"
  String get d => date.day.toString();

  /// Day padded to 2 digits. "05"
  String get dd => d.padLeft(2, "0");

  /// Weekday name. "شنبه"
  String get wN;

  /// Latin digits → Persian digits.
  String toPersian(String input) => input.replaceAllMapped(_asciiDigits, (Match m) => "۰۱۲۳۴۵۶۷۸۹"[int.parse(m.group(0)!)]);
}

// Abstract base class for dates
/// Base of UJalali and UGregorian: y/m/d/time, Julian day, comparison and math.
abstract class UDate implements Comparable<UDate> {
  /// Base constructor.
  const UDate();

  /// Smallest supported Julian day number.
  static const int minJDN = 1925675;

  /// Largest supported Julian day number.
  static const int maxJDN = 3108616;

  /// Year.
  int get year;

  /// Month 1-12.
  int get month;

  /// Day of the month.
  int get day;

  /// Hour 0-23.
  int get hour;

  /// Minute 0-59.
  int get minute;

  /// Second 0-59.
  int get second;

  /// Millisecond 0-999.
  int get millisecond;

  /// Day number shared by every calendar (for converting and differences).
  int get julianDayNumber;

  /// Weekday 1-7 (Jalali: 1 = Saturday).
  int get weekDay;

  /// Days in this month.
  int get monthLength;

  /// Text pieces for formatting.
  UDateFormatter get formatter;

  /// True in a leap year.
  bool isLeapYear();

  /// Local Dart DateTime.
  DateTime toDateTime();

  /// UTC Dart DateTime.
  DateTime toUtcDateTime();

  /// Copy with some parts changed; throws RangeError when the day does not exist.
  UDate copy({int? year, int? month, int? day, int? hour, int? minute, int? second, int? millisecond});

  /// Adds any amount; months clamp the day (31 + 1 month → 30), days and time overflow correctly. `j.add(months: 1, days: 3)`
  UDate add({int years = 0, int months = 0, int days = 0, int hours = 0, int minutes = 0, int seconds = 0, int milliseconds = 0});

  UDate operator +(int days);

  UDate operator -(int days);

  /// Days from this date to [other].
  int distanceTo(UDate other) => other.julianDayNumber - julianDayNumber;

  @override
  int compareTo(UDate other) => julianDayNumber == other.julianDayNumber ? time.compareTo(other.time) : julianDayNumber - other.julianDayNumber;

  /// Time of day as a Duration.
  Duration get time => Duration(hours: hour, minutes: minute, seconds: second, milliseconds: millisecond);

  @override
  bool operator ==(Object other) => other is UDate && compareTo(other) == 0;

  @override
  int get hashCode => julianDayNumber.hashCode ^ time.hashCode;

  bool operator >(UDate other) => compareTo(other) > 0;

  bool operator >=(UDate other) => compareTo(other) >= 0;

  bool operator <(UDate other) => compareTo(other) < 0;

  bool operator <=(UDate other) => compareTo(other) <= 0;
}

// Jalali date formatter
/// Jalali names: Persian, Afghan (حمل، ثور…) and Latin month/weekday names.
class UJalaliFormatter extends UDateFormatter {
  /// Formatter for a Jalali date.
  const UJalaliFormatter(UJalali super.date);

  /// Persian month names.
  static const List<String> monthNames = <String>["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];

  /// Afghan (Dari) month names.
  static const List<String> monthNamesAfghanistan = <String>["حمل", "ثور", "جوزا", "سرطان", "اسد", "سنبله", "میزان", "عقرب", "قوس", "جدی", "دلو", "حوت"];

  /// Month names in Latin letters. "Farvardin"
  static const List<String> monthNamesLatin = <String>["Farvardin", "Ordibehesht", "Khordad", "Tir", "Mordad", "Shahrivar", "Mehr", "Aban", "Azar", "Dey", "Bahman", "Esfand"];

  /// Persian weekday names from Saturday.
  static const List<String> weekDayNames = <String>["شنبه", "یک‌شنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنج‌شنبه", "جمعه"];

  /// English weekday names from Saturday.
  static const List<String> weekDayNamesLatin = <String>["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

  /// One-letter Persian weekday names.
  static const List<String> weekDayNamesShort = <String>["ش", "ی", "د", "س", "چ", "پ", "ج"];

  /// Two-letter English weekday names.
  static const List<String> weekDayNamesShortLatin = <String>["Sa", "Su", "Mo", "Tu", "We", "Th", "Fr"];

  @override
  String get mN => monthNames[date.month - 1];

  /// Afghan month name. "حمل"
  String get mNAf => monthNamesAfghanistan[date.month - 1];

  /// Month name in Latin letters.
  String get mNLatin => monthNamesLatin[date.month - 1];

  @override
  String get wN => weekDayNames[date.weekDay - 1];

  /// Weekday name in English.
  String get wNLatin => weekDayNamesLatin[date.weekDay - 1];
}

// Jalali date implementation
/// Jalali (Shamsi/Persian) date with exact conversion to/from Gregorian. `UJalali.now().formatFullDate()`, `UJalali(1403, 1, 1).toDateTime()`
class UJalali extends UDate {
  /// Jalali date from parts; throws RangeError for a day that does not exist. `UJalali(1403, 12, 30)`
  factory UJalali(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) =>
      _JAlgo.createFromYearMonthDay(year, month, day, hour, minute, second, millisecond);

  const UJalali._raw(this.julianDayNumber, this.year, this.month, this.day, this.hour, this.minute, this.second, this.millisecond, this._isLeap);

  /// Jalali date from a Julian day number.
  factory UJalali.fromJulianDayNumber(int jdn, [int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) => _JAlgo.createFromJulianDayNumber(jdn, hour, minute, second, millisecond);

  /// Jalali date from a Dart DateTime. `UJalali.fromDateTime(DateTime.now())`
  factory UJalali.fromDateTime(DateTime dt) => UGregorian.fromDateTime(dt).toJalali();

  /// Jalali date from a UGregorian.
  factory UJalali.fromGregorian(UGregorian g) => UJalali.fromJulianDayNumber(g.julianDayNumber, g.hour, g.minute, g.second, g.millisecond);

  /// Today in Jalali.
  factory UJalali.now() => UGregorian.now().toJalali();

  /// Earliest supported date.
  static const UJalali min = UJalali._raw(1925675, -61, 1, 1, 0, 0, 0, 0, true);

  /// Latest supported date.
  static const UJalali max = UJalali._raw(3108616, 3177, 10, 11, 23, 59, 59, 999, false);

  @override
  final int julianDayNumber;
  @override
  final int year;
  @override
  final int month;
  @override
  final int day;
  @override
  final int hour;
  @override
  final int minute;
  @override
  final int second;
  @override
  final int millisecond;
  final bool _isLeap;

  @override
  int get weekDay => (julianDayNumber + 2) % 7 + 1;

  @override
  int get monthLength => month <= 6
      ? 31
      : month <= 11
      ? 30
      : _isLeap
      ? 30
      : 29;

  @override
  UJalaliFormatter get formatter => UJalaliFormatter(this);

  @override
  bool isLeapYear() => _isLeap;

  @override
  DateTime toDateTime() => toGregorian().toDateTime();

  @override
  DateTime toUtcDateTime() => toGregorian().toUtcDateTime();

  /// Same moment as UGregorian.
  UGregorian toGregorian() => UGregorian.fromJulianDayNumber(julianDayNumber, hour, minute, second, millisecond);

  @override
  String toString() => "Jalali($year, $month, $day, $hour:$minute:$second.$millisecond)";

  @override
  UJalali operator +(int days) => addDays(days);

  @override
  UJalali operator -(int days) => addDays(-days);

  @override
  UJalali copy({int? year, int? month, int? day, int? hour, int? minute, int? second, int? millisecond}) => UJalali(
    year ?? this.year,
    month ?? this.month,
    day ?? this.day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
    millisecond ?? this.millisecond,
  );

  @override
  UJalali add({int years = 0, int months = 0, int days = 0, int hours = 0, int minutes = 0, int seconds = 0, int milliseconds = 0}) {
    // Years/months move the calendar month (the day is clamped, e.g. 31 Shahrivar + 1 month = 30 Mehr);
    // days and time are then added as a real duration, so any amount overflows correctly.
    final int totalMonths = (year + years) * 12 + (month - 1) + months;
    final int y = (totalMonths / 12).floor();
    final int m = totalMonths - y * 12 + 1;
    final UJalali base = UJalali(y, m, math.min(day, UJalali(y, m).monthLength));
    final (int dayShift, int h, int mi, int s, int ms) = _shiftTime(hour, minute, second, millisecond, days, hours, minutes, seconds, milliseconds);
    return UJalali.fromJulianDayNumber(base.julianDayNumber + dayShift, h, mi, s, ms);
  }

  /// Moves by whole days (negative goes back). `j.addDays(-7)`
  UJalali addDays(int days) => days == 0 ? this : UJalali.fromJulianDayNumber(julianDayNumber + days, hour, minute, second, millisecond);
}

// Jalali calculation helper
class _JAlgo {
  static _JalaliCalculation calculate(int jy) {
    const List<int> breaks = <int>[-61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178];
    final int gy = jy + 621;
    int leapJ = -14;
    int jp = breaks[0];
    int jump = 0;
    if (jy < -61 || jy >= 3178) throw RangeError("Year out of range");
    for (int i = 1; i < breaks.length; i++) {
      final int jm = breaks[i];
      jump = jm - jp;
      if (jy < jm) break;
      leapJ += (jump ~/ 33) * 8 + (jump % 33) ~/ 4;
      jp = jm;
    }
    int n = jy - jp;
    leapJ += (n ~/ 33) * 8 + ((n % 33) + 3) ~/ 4;
    if (jump % 33 == 4 && jump - n == 4) leapJ++;
    final int leapG = (gy ~/ 4) - (((gy ~/ 100) + 1) * 3 ~/ 4) - 150;
    final int march = 20 + leapJ - leapG;
    if (jump - n < 6) n = n - jump + ((jump + 4) ~/ 33) * 33;
    int leap = (((n + 1) % 33) - 1) % 4;
    if (leap == -1) leap = 4;
    return _JalaliCalculation(leap: leap, gy: gy, march: march);
  }

  static UJalali createFromJulianDayNumber(int jdn, int hour, int minute, int second, int millisecond) {
    if (jdn < UDate.minJDN || jdn > UDate.maxJDN) throw RangeError("Julian day out of range");
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59 || millisecond < 0 || millisecond > 999) {
      throw RangeError("Time out of range");
    }
    final int gy = UGregorian.fromJulianDayNumber(jdn).year;
    int jy = gy - 621;
    final _JalaliCalculation r = calculate(jy);
    final int jdn1f = UGregorian(r.gy, 3, r.march).julianDayNumber;
    int k = jdn - jdn1f;
    bool isLeap = r.leap == 0;
    if (k >= 0) {
      if (k <= 185) {
        final int jm = 1 + (k ~/ 31);
        final int jd = (k % 31) + 1;
        return UJalali._raw(jdn, jy, jm, jd, hour, minute, second, millisecond, isLeap);
      }
      k -= 186;
    } else {
      jy--;
      k += r.leap == 1 ? 180 : 179;
      isLeap = r.leap == 1;
    }
    final int jm = 7 + (k ~/ 30);
    final int jd = (k % 30) + 1;
    return UJalali._raw(jdn, jy, jm, jd, hour, minute, second, millisecond, isLeap);
  }

  static UJalali createFromYearMonthDay(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    if (year < -61 || year > 3177 || month < 1 || month > 12 || day < 1 || (year == 3177 && (month > 10 || (month == 10 && day > 11)))) {
      throw RangeError("Date out of range");
    }
    final _JalaliCalculation r = calculate(year);
    final int ml = month == 12
        ? (r.leap == 0 ? 30 : 29)
        : month > 6
        ? 30
        : 31;
    if (day > ml) throw RangeError("Day out of range");
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59 || millisecond < 0 || millisecond > 999) {
      throw RangeError("Time out of range");
    }
    final int jdn = UGregorian(r.gy, 3, r.march).julianDayNumber + (month - 1) * 31 - (month ~/ 7) * (month - 7) + day - 1;
    return UJalali._raw(jdn, year, month, day, hour, minute, second, millisecond, r.leap == 0);
  }
}

class _JalaliCalculation {
  const _JalaliCalculation({required this.leap, required this.gy, required this.march});

  final int leap;
  final int gy;
  final int march;
}

// Gregorian date formatter
/// English month/weekday names for UGregorian.
class UGregorianFormatter extends UDateFormatter {
  /// Formatter for a Gregorian date.
  const UGregorianFormatter(UGregorian super.date);

  static const List<String> _monthNames = <String>["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  static const List<String> _weekDayNames = <String>["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

  @override
  String get mN => _monthNames[date.month - 1];

  @override
  String get wN => _weekDayNames[date.weekDay - 1];
}

// Gregorian date implementation
/// Gregorian date that converts exactly to/from Jalali. `UGregorian(2024, 3, 20).toJalali()`
class UGregorian extends UDate {
  /// Gregorian date from parts; throws RangeError for a day that does not exist.
  factory UGregorian(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) =>
      _GAlgo.createFromYearMonthDay(year, month, day, hour, minute, second, millisecond);

  const UGregorian._raw(this.julianDayNumber, this.year, this.month, this.day, this.hour, this.minute, this.second, this.millisecond);

  /// Gregorian date from a Julian day number.
  factory UGregorian.fromJulianDayNumber(int jdn, [int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) => _GAlgo.createFromJulianDayNumber(jdn, hour, minute, second, millisecond);

  /// Gregorian date from a Dart DateTime.
  factory UGregorian.fromDateTime(DateTime dt) => UGregorian(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);

  /// Today.
  factory UGregorian.now() => UGregorian.fromDateTime(DateTime.now());

  /// Earliest supported date.
  static const UGregorian min = UGregorian._raw(1925675, 560, 3, 20, 0, 0, 0, 0);

  /// Latest supported date.
  static const UGregorian max = UGregorian._raw(3108616, 3798, 12, 31, 23, 59, 59, 999);

  @override
  final int julianDayNumber;
  @override
  final int year;
  @override
  final int month;
  @override
  final int day;
  @override
  final int hour;
  @override
  final int minute;
  @override
  final int second;
  @override
  final int millisecond;

  @override
  int get weekDay => julianDayNumber % 7 + 1;

  @override
  int get monthLength => _GAlgo.getMonthLength(year, month);

  @override
  UGregorianFormatter get formatter => UGregorianFormatter(this);

  @override
  bool isLeapYear() => _GAlgo.isLeapYear(year);

  @override
  DateTime toDateTime() => DateTime(year, month, day, hour, minute, second, millisecond);

  @override
  DateTime toUtcDateTime() => DateTime.utc(year, month, day, hour, minute, second, millisecond);

  /// Same moment as UJalali.
  UJalali toJalali() => UJalali.fromJulianDayNumber(julianDayNumber, hour, minute, second, millisecond);

  @override
  String toString() => "Gregorian($year, $month, $day, $hour:$minute:$second.$millisecond)";

  @override
  UGregorian operator +(int days) => addDays(days);

  @override
  UGregorian operator -(int days) => addDays(-days);

  @override
  UGregorian copy({int? year, int? month, int? day, int? hour, int? minute, int? second, int? millisecond}) => UGregorian(
    year ?? this.year,
    month ?? this.month,
    day ?? this.day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
    millisecond ?? this.millisecond,
  );

  @override
  UGregorian add({int years = 0, int months = 0, int days = 0, int hours = 0, int minutes = 0, int seconds = 0, int milliseconds = 0}) {
    final int totalMonths = (year + years) * 12 + (month - 1) + months;
    final int y = (totalMonths / 12).floor();
    final int m = totalMonths - y * 12 + 1;
    final UGregorian base = UGregorian(y, m, math.min(day, _GAlgo.getMonthLength(y, m)));
    final (int dayShift, int h, int mi, int s, int ms) = _shiftTime(hour, minute, second, millisecond, days, hours, minutes, seconds, milliseconds);
    return UGregorian.fromJulianDayNumber(base.julianDayNumber + dayShift, h, mi, s, ms);
  }

  /// Moves by whole days.
  UGregorian addDays(int days) => days == 0 ? this : UGregorian.fromJulianDayNumber(julianDayNumber + days, hour, minute, second, millisecond);
}

// Gregorian calculation helper
class _GAlgo {
  static const List<int> _monthLengths = <int>[31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  static bool isLeapYear(int year) => year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  static int getMonthLength(int year, int month) => month == 2 ? (isLeapYear(year) ? 29 : 28) : _monthLengths[month - 1];

  static UGregorian createFromJulianDayNumber(int jdn, int hour, int minute, int second, int millisecond) {
    if (jdn < UDate.minJDN || jdn > UDate.maxJDN) throw RangeError("Julian day out of range");
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59 || millisecond < 0 || millisecond > 999) {
      throw RangeError("Time out of range");
    }
    final int j = 4 * jdn + 139361631 + ((((4 * jdn + 183187720) ~/ 146097) * 3) ~/ 4) * 4 - 3908;
    final int i = ((j % 1461) ~/ 4) * 5 + 308;
    final int gd = (i % 153) ~/ 5 + 1;
    final int gm = (i ~/ 153) % 12 + 1;
    final int gy = j ~/ 1461 - 100100 + (8 - gm) ~/ 6;
    return UGregorian._raw(jdn, gy, gm, gd, hour, minute, second, millisecond);
  }

  static UGregorian createFromYearMonthDay(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    if (year < 560 || year > 3798 || month < 1 || month > 12 || day < 1 || day > getMonthLength(year, month) || (year == 560 && (month < 3 || (month == 3 && day < 20)))) {
      throw RangeError("Date out of range");
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59 || millisecond < 0 || millisecond > 999) {
      throw RangeError("Time out of range");
    }
    final int jdn = ((year + ((month - 8) ~/ 6) + 100100) * 1461) ~/ 4 + (153 * ((month + 9) % 12) + 2) ~/ 5 + day - 34840408 - (((year + 100100 + ((month - 8) ~/ 6)) ~/ 100) * 3) ~/ 4 + 752;
    return UGregorian._raw(jdn, year, month, day, hour, minute, second, millisecond);
  }
}

// Extensions for additional Jalali functionality
// Extension for Jalali date with enhanced formatting and utilities
/// Formatting, comparisons and day math on UJalali. `UJalali.now().formatCustom("wN dd mN yyyy")`
extension JalaliExt on UJalali {
  // Constants for weekdays
  /// Weekday number of Monday (Jalali week starts Saturday = 1).
  static const int monday = 3;

  /// Weekday number of Tuesday.
  static const int tuesday = 4;

  /// Weekday number of Wednesday.
  static const int wednesday = 5;

  /// Weekday number of Thursday.
  static const int thursday = 6;

  /// Weekday number of Friday (weekend).
  static const int friday = 7;

  /// Weekday number of Saturday (first day).
  static const int saturday = 1;

  /// Weekday number of Sunday.
  static const int sunday = 2;

  // Constants for months
  /// Month number 1.
  static const int farvardin = 1;

  /// Month number 2.
  static const int ordibehesht = 2;

  /// Month number 3.
  static const int khordad = 3;

  /// Month number 4.
  static const int tir = 4;

  /// Month number 5.
  static const int mordad = 5;

  /// Month number 6.
  static const int shahrivar = 6;

  /// Month number 7.
  static const int mehr = 7;

  /// Month number 8.
  static const int aban = 8;

  /// Month number 9.
  static const int azar = 9;

  /// Month number 10.
  static const int dey = 10;

  /// Month number 11.
  static const int bahman = 11;

  /// Month number 12.
  static const int esfand = 12;

  /// Persian month names.
  static const List<String> months = <String>["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];

  /// One-letter weekday names from Saturday.
  static const List<String> narrowWeekdays = <String>["ش", "ی", "د", "س", "چ", "پ", "ج"];

  /// Short weekday names from Saturday. "۱شنبه"
  static const List<String> shortDayName = <String>["شنبه", "۱شنبه", "۲شنبه", "۳شنبه", "۴شنبه", "۵شنبه", "جمعه"];

  /// Milliseconds since 1970 (for storage/APIs).
  int get millisecondsSinceEpoch => toDateTime().millisecondsSinceEpoch;

  /// True when earlier than [other].
  bool isBefore(UJalali other) => compareTo(other) < 0;

  /// True when later than [other].
  bool isAfter(UJalali other) => compareTo(other) > 0;

  /// True when the same moment.
  bool isAtSameMomentAs(UJalali other) => compareTo(other) == 0;

  /// True when the same calendar day.
  bool isSameDayAs(UJalali other) => year == other.year && month == other.month && day == other.day;

  /// "شنبه ۱ فروردین ۱۴۰۳" style (weekday day month year). `j.formatFullDate(persianDigits: true)`
  String formatFullDate({bool persianDigits = false}) {
    final UJalaliFormatter f = formatter;
    final String result = "${f.wN} ${f.d} ${f.mN} ${f.yyyy}";
    return persianDigits ? f.toPersian(result) : result;
  }

  /// "1403/01/01".
  String formatCompactDate({bool persianDigits = false}) {
    final UJalaliFormatter f = formatter;
    final String result = "${f.yyyy}/${f.mm}/${f.dd}";
    return persianDigits ? f.toPersian(result) : result;
  }

  /// "1403-01-01 14:05:09".
  String formatDateTime({bool persianDigits = false}) {
    final UJalaliFormatter f = formatter;
    final String result = '${f.yyyy}-${f.mm}-${f.dd} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
    return persianDigits ? f.toPersian(result) : result;
  }

  /// Your own pattern: yyyy yy mm dd mN mNAf wN wS wW HH MM SS q. `j.formatCustom("dd mN yyyy - HH:MM")`
  String formatCustom(String pattern, {bool persianDigits = false}) {
    final UJalaliFormatter f = formatter;
    final String result = pattern
        .replaceAll("yyyy", f.yyyy)
        .replaceAll("yy", f.yy)
        .replaceAll("mNAf", f.mNAf)
        .replaceAll("mN", f.mN)
        .replaceAll("mm", f.mm)
        .replaceAll("dd", f.dd)
        .replaceAll("wN", f.wN)
        .replaceAll("wS", shortDayName[weekDay - 1])
        .replaceAll("wW", narrowWeekdays[weekDay - 1])
        .replaceAll("HH", hour.toString().padLeft(2, "0"))
        .replaceAll("MM", minute.toString().padLeft(2, "0"))
        .replaceAll("SS", second.toString().padLeft(2, "0"))
        .replaceAll("q", quarter.toString());
    return persianDigits ? f.toPersian(result) : result;
  }

  /// "01 فروردین 1403".
  String formatShortDate({bool persianDigits = false}) {
    final UJalaliFormatter f = formatter;
    final String result = "${f.dd} ${f.mN} ${f.yyyy}";
    return persianDigits ? f.toPersian(result) : result;
  }

  /// "فروردین 1403".
  String formatMonthYear({bool persianDigits = false}) {
    final UJalaliFormatter f = formatter;
    final String result = "${f.mN} ${f.yyyy}";
    return persianDigits ? f.toPersian(result) : result;
  }

  /// Date with Afghan month names. "شنبه 1 حمل 1403"
  String formatAfghanDate({bool persianDigits = false}) {
    final UJalaliFormatter f = formatter;
    final String result = "${f.wN} ${f.d} ${f.mNAf} ${f.yyyy}";
    return persianDigits ? f.toPersian(result) : result;
  }

  /// "14:05:09".
  String formatTime({bool persianDigits = false}) {
    final String result = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
    return persianDigits ? formatter.toPersian(result) : result;
  }

  /// Season/quarter 1-4.
  int get quarter => (month - 1) ~/ 3 + 1;

  /// True when this is today.
  bool isToday() => isSameDayAs(UJalali.now());

  /// True when in the current Jalali month.
  bool isThisMonth() {
    final UJalali now = UJalali.now();
    return year == now.year && month == now.month;
  }

  /// The 1st of this month.
  UJalali firstDayOfMonth() => UJalali(year, month, 1, hour, minute, second, millisecond);

  /// The last day of this month (29/30/31).
  UJalali lastDayOfMonth() => UJalali(year, month, monthLength, hour, minute, second, millisecond);

  /// Tomorrow of this date.
  UJalali nextDay() => addDays(1);

  /// Yesterday of this date.
  UJalali previousDay() => addDays(-1);

  /// Saturday of this week.
  UJalali startOfWeek() => addDays(-(weekDay - saturday));

  /// Friday of this week.
  UJalali endOfWeek() => addDays(friday - weekDay);

  /// Days from this date to [other] (negative when earlier).
  int daysUntil(UJalali other) => other.julianDayNumber - julianDayNumber;

  /// True on Friday.
  bool isWeekend() => weekDay == friday;

  /// Number of weeks in this Jalali year.
  int weeksInYear() {
    final UJalali lastDay = UJalali(year, esfand, isLeapYear() ? 30 : 29);
    final UJalali firstDay = UJalali(year);
    return (lastDay.julianDayNumber - firstDay.julianDayNumber + weekDay) ~/ 7 + 1;
  }

  /// Adds minutes (negative allowed), rolling over hours and days. `j.addMinutes(-90)`
  UJalali addMinutes(int minutes) {
    final int newMinute = (minute + minutes) % 60;
    final int hourOverflow = ((minute + minutes) / 60).floor();
    return copy(minute: newMinute).addHours(hourOverflow);
  }

  /// Adds seconds (negative allowed).
  UJalali addSeconds(int seconds) {
    final int newSecond = (second + seconds) % 60;
    final int minuteOverflow = ((second + seconds) / 60).floor();
    return copy(second: newSecond).addMinutes(minuteOverflow);
  }

  /// Adds hours (negative allowed), rolling over days.
  UJalali addHours(int hours) => copy(hour: (hour + hours) % 24).addDays(((hour + hours) / 24).floor());
}

// Adds a duration to a time of day: whole days to move, plus the new hour/minute/second/millisecond.
(int, int, int, int, int) _shiftTime(int hour, int minute, int second, int millisecond, int days, int hours, int minutes, int seconds, int milliseconds) {
  const int dayMs = 86400000;
  final int total = (((hour + hours) * 60 + minute + minutes) * 60 + second + seconds) * 1000 + millisecond + milliseconds;
  final int dayShift = days + (total / dayMs).floor();
  final int rest = total - (total / dayMs).floor() * dayMs;
  return (dayShift, rest ~/ 3600000, rest ~/ 60000 % 60, rest ~/ 1000 % 60, rest % 1000);
}
