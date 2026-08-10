// Abstract base class for date formatting
abstract class DateFormatter {
  static final RegExp _asciiDigits = RegExp("[0-9]");

  final Date date;

  const DateFormatter(this.date);

  // Year as string
  String get y => date.year.toString();

  // Four-digit year, padded with zeros
  String get yyyy {
    if (date.year < 0 || date.year > 9999) throw RangeError("Year out of range: ${date.year}");
    return date.year.toString().padLeft(4, "0");
  }

  // Two-digit year (last two digits)
  String get yy {
    if (date.year < 1000 || date.year > 9999) throw RangeError("Year out of range: ${date.year}");
    return (date.year % 100).toString().padLeft(2, "0");
  }

  // Month as string
  String get m => date.month.toString();

  // Two-digit month
  String get mm => m.padLeft(2, "0");

  // Month name
  String get mN;

  // Day as string
  String get d => date.day.toString();

  // Two-digit day
  String get dd => d.padLeft(2, "0");

  // Weekday name
  String get wN;

  // Persian number formatting
  String toPersian(String input) => input.replaceAllMapped(_asciiDigits, (Match m) => "۰۱۲۳۴۵۶۷۸۹"[int.parse(m.group(0)!)]);
}

// Abstract base class for dates
abstract class Date implements Comparable<Date> {
  const Date();

  static const int minJDN = 1925675;
  static const int maxJDN = 3108616;

  int get year;

  int get month;

  int get day;

  int get hour;

  int get minute;

  int get second;

  int get millisecond;

  int get julianDayNumber;

  int get weekDay;

  int get monthLength;

  DateFormatter get formatter;

  bool isLeapYear();

  DateTime toDateTime();

  DateTime toUtcDateTime();

  Date copy({int? year, int? month, int? day, int? hour, int? minute, int? second, int? millisecond});

  Date add({int years = 0, int months = 0, int days = 0, int hours = 0, int minutes = 0, int seconds = 0, int milliseconds = 0});

  Date operator +(int days);

  Date operator -(int days);

  int distanceTo(Date other) => other.julianDayNumber - julianDayNumber;

  @override
  int compareTo(Date other) => julianDayNumber == other.julianDayNumber ? time.compareTo(other.time) : julianDayNumber - other.julianDayNumber;

  Duration get time => Duration(hours: hour, minutes: minute, seconds: second, milliseconds: millisecond);

  @override
  bool operator ==(Object other) => other is Date && compareTo(other) == 0;

  @override
  int get hashCode => julianDayNumber.hashCode ^ time.hashCode;

  bool operator >(Date other) => compareTo(other) > 0;

  bool operator >=(Date other) => compareTo(other) >= 0;

  bool operator <(Date other) => compareTo(other) < 0;

  bool operator <=(Date other) => compareTo(other) <= 0;
}

// Jalali date formatter
class JalaliFormatter extends DateFormatter {
  const JalaliFormatter(Jalali super.date);

  static const List<String> _monthNames = <String>["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
  static const List<String> _monthNamesAfghanistan = <String>["حمل", "ثور", "جوزا", "سرطان", "اسد", "سنبله", "میزان", "عقرب", "قوس", "جدی", "دلو", "حوت"];
  static const List<String> _weekDayNames = <String>["شنبه", "یک‌شنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنج‌شنبه", "جمعه"];

  @override
  String get mN => _monthNames[date.month - 1];

  String get mNAf => _monthNamesAfghanistan[date.month - 1];

  @override
  String get wN => _weekDayNames[date.weekDay - 1];
}

// Jalali date implementation
class Jalali extends Date {
  factory Jalali(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) =>
      _JAlgo.createFromYearMonthDay(year, month, day, hour, minute, second, millisecond);

  const Jalali._raw(this.julianDayNumber, this.year, this.month, this.day, this.hour, this.minute, this.second, this.millisecond, this._isLeap);

  factory Jalali.fromJulianDayNumber(int jdn, [int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) => _JAlgo.createFromJulianDayNumber(jdn, hour, minute, second, millisecond);

  factory Jalali.fromDateTime(DateTime dt) => Gregorian.fromDateTime(dt).toJalali();

  factory Jalali.fromGregorian(Gregorian g) => Jalali.fromJulianDayNumber(g.julianDayNumber, g.hour, g.minute, g.second, g.millisecond);

  factory Jalali.now() => Gregorian.now().toJalali();
  static const Jalali min = Jalali._raw(1925675, -61, 1, 1, 0, 0, 0, 0, true);
  static const Jalali max = Jalali._raw(3108616, 3177, 10, 11, 23, 59, 59, 999, false);

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
  JalaliFormatter get formatter => JalaliFormatter(this);

  @override
  bool isLeapYear() => _isLeap;

  @override
  DateTime toDateTime() => toGregorian().toDateTime();

  @override
  DateTime toUtcDateTime() => toGregorian().toUtcDateTime();

  Gregorian toGregorian() => Gregorian.fromJulianDayNumber(julianDayNumber, hour, minute, second, millisecond);

  @override
  String toString() => "Jalali($year, $month, $day, $hour:$minute:$second.$millisecond)";

  @override
  Jalali operator +(int days) => addDays(days);

  @override
  Jalali operator -(int days) => addDays(-days);

  @override
  Jalali copy({int? year, int? month, int? day, int? hour, int? minute, int? second, int? millisecond}) => Jalali(
    year ?? this.year,
    month ?? this.month,
    day ?? this.day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
    millisecond ?? this.millisecond,
  );

  @override
  Jalali add({int years = 0, int months = 0, int days = 0, int hours = 0, int minutes = 0, int seconds = 0, int milliseconds = 0}) => Jalali(
    year + years,
    month + months,
    day + days,
    hour + hours,
    minute + minutes,
    second + seconds,
    millisecond + milliseconds,
  );

  Jalali addDays(int days) => days == 0 ? this : Jalali.fromJulianDayNumber(julianDayNumber + days, hour, minute, second, millisecond);
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

  static Jalali createFromJulianDayNumber(int jdn, int hour, int minute, int second, int millisecond) {
    if (jdn < Date.minJDN || jdn > Date.maxJDN) throw RangeError("Julian day out of range");
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59 || millisecond < 0 || millisecond > 999) {
      throw RangeError("Time out of range");
    }
    final int gy = Gregorian.fromJulianDayNumber(jdn).year;
    int jy = gy - 621;
    final _JalaliCalculation r = calculate(jy);
    final int jdn1f = Gregorian(r.gy, 3, r.march).julianDayNumber;
    int k = jdn - jdn1f;
    bool isLeap = r.leap == 0;
    if (k >= 0) {
      if (k <= 185) {
        final int jm = 1 + (k ~/ 31);
        final int jd = (k % 31) + 1;
        return Jalali._raw(jdn, jy, jm, jd, hour, minute, second, millisecond, isLeap);
      }
      k -= 186;
    } else {
      jy--;
      k += r.leap == 1 ? 180 : 179;
      isLeap = r.leap == 1;
    }
    final int jm = 7 + (k ~/ 30);
    final int jd = (k % 30) + 1;
    return Jalali._raw(jdn, jy, jm, jd, hour, minute, second, millisecond, isLeap);
  }

  static Jalali createFromYearMonthDay(int year, int month, int day, int hour, int minute, int second, int millisecond) {
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
    final int jdn = Gregorian(r.gy, 3, r.march).julianDayNumber + (month - 1) * 31 - (month ~/ 7) * (month - 7) + day - 1;
    return Jalali._raw(jdn, year, month, day, hour, minute, second, millisecond, r.leap == 0);
  }
}

class _JalaliCalculation {
  const _JalaliCalculation({required this.leap, required this.gy, required this.march});

  final int leap;
  final int gy;
  final int march;
}

// Gregorian date formatter
class GregorianFormatter extends DateFormatter {
  const GregorianFormatter(Gregorian super.date);

  static const List<String> _monthNames = <String>["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  static const List<String> _weekDayNames = <String>["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

  @override
  String get mN => _monthNames[date.month - 1];

  @override
  String get wN => _weekDayNames[date.weekDay - 1];
}

// Gregorian date implementation
class Gregorian extends Date {
  factory Gregorian(int year, [int month = 1, int day = 1, int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) =>
      _GAlgo.createFromYearMonthDay(year, month, day, hour, minute, second, millisecond);

  const Gregorian._raw(this.julianDayNumber, this.year, this.month, this.day, this.hour, this.minute, this.second, this.millisecond);

  factory Gregorian.fromJulianDayNumber(int jdn, [int hour = 0, int minute = 0, int second = 0, int millisecond = 0]) => _GAlgo.createFromJulianDayNumber(jdn, hour, minute, second, millisecond);

  factory Gregorian.fromDateTime(DateTime dt) => Gregorian(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);

  factory Gregorian.now() => Gregorian.fromDateTime(DateTime.now());
  static const Gregorian min = Gregorian._raw(1925675, 560, 3, 20, 0, 0, 0, 0);
  static const Gregorian max = Gregorian._raw(3108616, 3798, 12, 31, 23, 59, 59, 999);

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
  GregorianFormatter get formatter => GregorianFormatter(this);

  @override
  bool isLeapYear() => _GAlgo.isLeapYear(year);

  @override
  DateTime toDateTime() => DateTime(year, month, day, hour, minute, second, millisecond);

  @override
  DateTime toUtcDateTime() => DateTime.utc(year, month, day, hour, minute, second, millisecond);

  Jalali toJalali() => Jalali.fromJulianDayNumber(julianDayNumber, hour, minute, second, millisecond);

  @override
  String toString() => "Gregorian($year, $month, $day, $hour:$minute:$second.$millisecond)";

  @override
  Gregorian operator +(int days) => addDays(days);

  @override
  Gregorian operator -(int days) => addDays(-days);

  @override
  Gregorian copy({int? year, int? month, int? day, int? hour, int? minute, int? second, int? millisecond}) => Gregorian(
    year ?? this.year,
    month ?? this.month,
    day ?? this.day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
    millisecond ?? this.millisecond,
  );

  @override
  Gregorian add({int years = 0, int months = 0, int days = 0, int hours = 0, int minutes = 0, int seconds = 0, int milliseconds = 0}) => Gregorian(
    year + years,
    month + months,
    day + days,
    hour + hours,
    minute + minutes,
    second + seconds,
    millisecond + milliseconds,
  );

  Gregorian addDays(int days) => days == 0 ? this : Gregorian.fromJulianDayNumber(julianDayNumber + days, hour, minute, second, millisecond);
}

// Gregorian calculation helper
class _GAlgo {
  static const List<int> _monthLengths = <int>[31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  static bool isLeapYear(int year) => year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  static int getMonthLength(int year, int month) => month == 2 ? (isLeapYear(year) ? 29 : 28) : _monthLengths[month - 1];

  static Gregorian createFromJulianDayNumber(int jdn, int hour, int minute, int second, int millisecond) {
    if (jdn < Date.minJDN || jdn > Date.maxJDN) throw RangeError("Julian day out of range");
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59 || millisecond < 0 || millisecond > 999) {
      throw RangeError("Time out of range");
    }
    final int j = 4 * jdn + 139361631 + ((((4 * jdn + 183187720) ~/ 146097) * 3) ~/ 4) * 4 - 3908;
    final int i = ((j % 1461) ~/ 4) * 5 + 308;
    final int gd = (i % 153) ~/ 5 + 1;
    final int gm = (i ~/ 153) % 12 + 1;
    final int gy = j ~/ 1461 - 100100 + (8 - gm) ~/ 6;
    return Gregorian._raw(jdn, gy, gm, gd, hour, minute, second, millisecond);
  }

  static Gregorian createFromYearMonthDay(int year, int month, int day, int hour, int minute, int second, int millisecond) {
    if (year < 560 || year > 3798 || month < 1 || month > 12 || day < 1 || day > getMonthLength(year, month) || (year == 560 && (month < 3 || (month == 3 && day < 20)))) {
      throw RangeError("Date out of range");
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59 || millisecond < 0 || millisecond > 999) {
      throw RangeError("Time out of range");
    }
    final int jdn = ((year + ((month - 8) ~/ 6) + 100100) * 1461) ~/ 4 + (153 * ((month + 9) % 12) + 2) ~/ 5 + day - 34840408 - (((year + 100100 + ((month - 8) ~/ 6)) ~/ 100) * 3) ~/ 4 + 752;
    return Gregorian._raw(jdn, year, month, day, hour, minute, second, millisecond);
  }
}

// Extensions for additional Jalali functionality
// Extension for Jalali date with enhanced formatting and utilities
extension JalaliExt on Jalali {
  // Constants for weekdays
  static const int monday = 3;
  static const int tuesday = 4;
  static const int wednesday = 5;
  static const int thursday = 6;
  static const int friday = 7;
  static const int saturday = 1;
  static const int sunday = 2;

  // Constants for months
  static const int farvardin = 1;
  static const int ordibehesht = 2;
  static const int khordad = 3;
  static const int tir = 4;
  static const int mordad = 5;
  static const int shahrivar = 6;
  static const int mehr = 7;
  static const int aban = 8;
  static const int azar = 9;
  static const int dey = 10;
  static const int bahman = 11;
  static const int esfand = 12;

  // Month and weekday name lists
  static const List<String> months = <String>["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
  static const List<String> narrowWeekdays = <String>["ش", "ی", "د", "س", "چ", "پ", "ج"];
  static const List<String> shortDayName = <String>["شنبه", "۱شنبه", "۲شنبه", "۳شنبه", "۴شنبه", "۵شنبه", "جمعه"];

  // Get milliseconds since epoch
  int get millisecondsSinceEpoch => toDateTime().millisecondsSinceEpoch;

  // Comparison utilities
  bool isBefore(Jalali other) => compareTo(other) < 0;

  bool isAfter(Jalali other) => compareTo(other) > 0;

  bool isAtSameMomentAs(Jalali other) => compareTo(other) == 0;

  bool isSameDayAs(Jalali other) => year == other.year && month == other.month && day == other.day;

  // Formatting utilities
  String formatFullDate({bool persianDigits = false}) {
    final JalaliFormatter f = formatter;
    final String result = "${f.wN} ${f.d} ${f.mN} ${f.yyyy}";
    return persianDigits ? f.toPersian(result) : result;
  }

  String formatCompactDate({bool persianDigits = false}) {
    final JalaliFormatter f = formatter;
    final String result = "${f.yyyy}/${f.mm}/${f.dd}";
    return persianDigits ? f.toPersian(result) : result;
  }

  String formatDateTime({bool persianDigits = false}) {
    final JalaliFormatter f = formatter;
    final String result = '${f.yyyy}-${f.mm}-${f.dd} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
    return persianDigits ? f.toPersian(result) : result;
  }

  String formatCustom(String pattern, {bool persianDigits = false}) {
    final JalaliFormatter f = formatter;
    // FIX: replace "mNAf" before "mN" (otherwise "mN" consumed the prefix and broke the Afghan-month token); narrow weekday now uses a distinct "wW" token (it was a duplicate "wN", which was unreachable after the full-name replacement).
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

  String formatShortDate({bool persianDigits = false}) {
    final JalaliFormatter f = formatter;
    final String result = "${f.dd} ${f.mN} ${f.yyyy}";
    return persianDigits ? f.toPersian(result) : result;
  }

  String formatMonthYear({bool persianDigits = false}) {
    final JalaliFormatter f = formatter;
    final String result = "${f.mN} ${f.yyyy}";
    return persianDigits ? f.toPersian(result) : result;
  }

  String formatAfghanDate({bool persianDigits = false}) {
    final JalaliFormatter f = formatter;
    final String result = "${f.wN} ${f.d} ${f.mNAf} ${f.yyyy}";
    return persianDigits ? f.toPersian(result) : result;
  }

  String formatTime({bool persianDigits = false}) {
    final String result = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
    return persianDigits ? formatter.toPersian(result) : result;
  }

  // New utility functions
  // Get quarter of the year (1-4)
  int get quarter => (month - 1) ~/ 3 + 1;

  // Check if date is today
  bool isToday() => isSameDayAs(Jalali.now());

  // Check if date is in the current month
  bool isThisMonth() {
    final Jalali now = Jalali.now();
    return year == now.year && month == now.month;
  }

  // Get the first day of the month
  Jalali firstDayOfMonth() => Jalali(year, month, 1, hour, minute, second, millisecond);

  // Get the last day of the month
  Jalali lastDayOfMonth() => Jalali(year, month, monthLength, hour, minute, second, millisecond);

  // Get the next day
  Jalali nextDay() => addDays(1);

  // Get the previous day
  Jalali previousDay() => addDays(-1);

  // Get the start of the week (Saturday)
  Jalali startOfWeek() => addDays(-(weekDay - saturday));

  // Get the end of the week (Friday)
  Jalali endOfWeek() => addDays(friday - weekDay);

  // Get days until a specific date
  int daysUntil(Jalali other) => other.julianDayNumber - julianDayNumber;

  // Check if date is a weekend (Friday)
  bool isWeekend() => weekDay == friday;

  // Get the number of weeks in the year
  int weeksInYear() {
    final Jalali lastDay = Jalali(year, esfand, isLeapYear() ? 30 : 29);
    final Jalali firstDay = Jalali(year);
    return (lastDay.julianDayNumber - firstDay.julianDayNumber + weekDay) ~/ 7 + 1;
  }

  // Add minutes with overflow handling
  Jalali addMinutes(int minutes) {
    final int newMinute = (minute + minutes) % 60;
    final int hourOverflow = (minute + minutes) ~/ 60;
    return copy(minute: newMinute).addHours(hourOverflow);
  }

  // Add seconds with overflow handling
  Jalali addSeconds(int seconds) {
    final int newSecond = (second + seconds) % 60;
    final int minuteOverflow = (second + seconds) ~/ 60;
    return copy(second: newSecond).addMinutes(minuteOverflow);
  }

  // Add hours with overflow handling
  Jalali addHours(int hours) => copy(hour: (hour + hours) % 24).addDays((hour + hours) ~/ 24);
}
