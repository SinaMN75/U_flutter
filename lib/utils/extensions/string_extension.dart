import "package:intl/intl.dart" as intl;
import "package:u/utilities.dart";

/// Shortcuts on a TextEditingController for number fields and on-screen keyboards. `controller.numInt()`
extension TextEditingControllerExtension on TextEditingController {
  /// Digits only, Persian digits converted. "۱۲,۳۰۰" → "12300"
  String numString() => text.toLatinNumber().extractLatinNumber();

  /// The digits as a double (0 when empty). `priceController.numDouble()`
  double numDouble() => text.toLatinNumber().extractLatinNumber().toDouble();

  /// The digits as an int (0 when empty). `amountController.numInt()`
  int numInt() => text.toLatinNumber().extractLatinNumber().toInt();

  /// The text, or null when empty (handy for optional API fields). `controller.valueOrNull()`
  String? valueOrNull() => text.isEmpty ? null : text;

  /// True when the field is empty.
  bool isNullOrEmpty() => text.isEmpty;

  /// True when the field has text.
  bool isNotNullOrEmpty() => text.isNotEmpty;

  /// Trimmed text with Persian digits converted. `controller.trimmedLatin()`
  String trimmedLatin() => text.toLatinNumber().trim();

  /// Adds one character at the end and moves the cursor there (custom keypads). `controller.appendCharacter("5", maxLength: 6)`
  void appendCharacter(String character, {int? maxLength}) {
    if (maxLength != null && text.length >= maxLength) return;
    final String updated = text + character;
    value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
  }

  /// Deletes the last character (custom keypad backspace). `controller.dropLastCharacter()`
  void dropLastCharacter() {
    if (text.isEmpty) return;
    final String updated = text.characters.skipLast(1).toString();
    value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
  }

  /// Replaces the text and puts the cursor at the end. `controller.setText("hello")`
  void setText(String value) => this.value = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );
}

/// Null-safe helpers on String? (null counts as empty). `json["name"].isNullOrEmpty()`
extension OptionalStringExtension on String? {
  /// Digits only ("0" when null). "a1b2" → "12"
  String numberString() => (this ?? "0").replaceAll(RegExp("[^0-9]"), "");

  /// The text, or "" when null. `user.bio.toStringOrEmptyIfNull()`
  String toStringOrEmptyIfNull() => this ?? "";

  /// The digits as an int (0 when null). "Order #42" → 42
  int number() => (this ?? "0").replaceAll(RegExp("[^0-9]"), "").toInt();

  /// Null when null or "". `name.nullIfEmpty()`
  String? nullIfEmpty() => (this ?? "").isEmpty ? null : this;

  /// Groups a whole number with commas, "0" when empty. "1500000" → "1,500,000"
  String getPrice() {
    final int nums = (this ?? "0").toInt();
    return nums > 0 ? intl.NumberFormat("#,##0").format(nums) : "0";
  }

  /// Puts a comma every 3 digits. "1500000" → "1,500,000"
  String separateNumbers3By3() => (this ?? "").replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},");

  /// ISO date text → long Jalali date (now when null). "2024-03-20" → "چهارشنبه ۱ فروردین ۱۴۰۳"
  String toJalaliDateString() => UJalali.fromDateTime(DateTime.parse(this ?? DateTime.now().toString())).formatFullDate();

  /// ISO date text → "1403/01/01 14:05" in Jalali (now when null).
  String toJalaliDateTime() {
    final DateTime dateTime = DateTime.parse(this ?? DateTime.now().toString());
    return "${UJalali.fromDateTime(dateTime).formatCompactDate()} ${dateTime.hour.twoDigits}:${dateTime.minute.twoDigits}";
  }

  /// ISO date text → "1403/01/01" in Jalali (now when null).
  String toJalaliDate() => UJalali.fromDateTime(DateTime.parse(this ?? DateTime.now().toString())).formatCompactDate();

  /// "1500000" → "1,500,000 ریال"; [removeNegative] drops the minus sign.
  String rial({bool removeNegative = false}) => "${(this ?? "").separateNumbers3By3()} ریال".trim().replaceAll(removeNegative ? "-" : "", "");

  /// "1500000" → "1,500,000 تومان"; [removeNegative] drops the minus sign.
  String toman({bool removeNegative = false}) => "${(this ?? "").separateNumbers3By3()} تومان".trim().replaceAll(removeNegative ? "-" : "", "");

  /// Rial text → toman text (÷10). "150000" → "15,000 تومان"
  String rialToTomanMoneyPersian() => "${((this ?? "0").toInt() ~/ 10).toString().separateNumbers3By3()} تومان";

  /// ISO date text → local "14:05:09 1403/1/1", or just the date at midnight.
  String formatJalaliDateTime() {
    final DateTime dateTime = DateTime.parse(this ?? DateTime.now().toString()).toLocal();
    final UJalali jalali = UJalali.fromDateTime(dateTime);
    if (dateTime.hour == 0 && dateTime.minute == 0) return "${jalali.year}/${jalali.month}/${jalali.day}";
    return "${dateTime.hour.twoDigits}:${dateTime.minute.twoDigits}:${dateTime.second.twoDigits} ${jalali.year}/${jalali.month}/${jalali.day}";
  }

  /// True when null or "".
  bool isNullOrEmpty() => this == null || this == "";

  /// True when it has at least one character.
  bool isNotNullOrEmpty() => this != null && this != "";

  /// True when null, "" or only spaces.
  bool isNullOrBlank() => this == null || this!.trim().isEmpty;

  /// True when it parses as a number. "3.5" → true
  bool isNumeric() => this != null && double.tryParse(this!) != null;

  /// The text, or [fallback] when null or blank. `user.name.orIfBlank("Guest")`
  String orIfBlank(String fallback) => isNullOrBlank() ? fallback : this!;
}

/// Everyday String helpers: numbers, money, Persian digits, dates, file names, validation, encodings. `"۱۲۳".toLatinNumber()`
extension StringExtensions on String {
  static final RegExp _nonDigits = RegExp("[^0-9]");
  static final RegExp _thousands = RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
  static final RegExp _emailPattern = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
  static final RegExp _urlPattern = RegExp(r"^(https?://)?([\w\-]+\.)+[\w\-]+(:\d+)?(/\S*)?$");
  static final RegExp _phonePattern = RegExp(r"^\+?[\d\s-]{8,15}$");
  static final RegExp _alphanumericPattern = RegExp(r"^[a-zA-Z0-9]+$");
  static final RegExp _strongPasswordPattern = RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$");

  /// Base64 text → bytes. `imageBase64.toBytesFromBase64()`
  Uint8List toBytesFromBase64() => base64.decode(this);

  /// URL-safe base64 text → bytes.
  Uint8List toBytesFromBase64Url() => base64Url.decode(this);

  /// substring(start, end) that returns the whole text when it is shorter than [end]. `"hello".subStringIfExist(0, 3)` → "hel"
  String subStringIfExist(int start, int end) => length > end ? substring(start, end) : this;

  /// Digits only. "a1-b2" → "12"
  String numberString() => replaceAll(_nonDigits, "");

  /// The digits as an int. "Order #42" → 42
  int number() => replaceAll(_nonDigits, "").toInt();

  /// Null when "". `name.nullIfEmpty()`
  String? nullIfEmpty() => isEmpty ? null : this;

  /// "1500000" → "1,500,000 ریال "
  String rial() => "${separateNumbers3By3()} ریال ";

  /// "1500000" → "1,500,000 تومان "
  String toman() => "${separateNumbers3By3()} تومان ";

  /// True for "true" (any case).
  bool isTrue() => toLowerCase() == "true";

  /// True for "false" (any case).
  bool isFalse() => toLowerCase() == "false";

  /// True when it parses as a number. "3.5" → true
  bool isNumeric() => double.tryParse(this) != null;

  /// Parses an int, 0 when it is not one. "42" → 42
  int toInt() => int.tryParse(this) ?? 0;

  /// Parses a double, 0 when it is not one. "3.5" → 3.5
  double toDouble() => double.tryParse(this) ?? 0;

  /// Parses an int, null when it is not one. "x".toIntOrNull() → null
  int? toIntOrNull() => int.tryParse(toLatinNumber().trim());

  /// Parses a double, null when it is not one.
  double? toDoubleOrNull() => double.tryParse(toLatinNumber().trim());

  /// Parses an ISO date, null when it is not one. "2024-03-20".toDateTime()
  DateTime? toDateTime() => DateTime.tryParse(this);

  /// Puts a comma every 3 digits. "1500000" → "1,500,000"
  String separateNumbers3By3() => replaceAllMapped(_thousands, (Match m) => "${m[1]},");

  /// Puts [separator] every [number] digits from the right. `"1234567".separateCharacters(3, "٬")`
  String separateCharacters(int number, String separator) => replaceAllMapped(RegExp("(\\d{1,$number})(?=(\\d{$number})+(?!\\d))"), (Match m) => "${m[1]}$separator");

  /// ISO date → "1403/01/01".
  String toJalaliCompactDateString() => UJalali.fromDateTime(DateTime.parse(this)).formatCompactDate();

  /// ISO date → long Jalali date with weekday and month name.
  String toJalaliDateString() => UJalali.fromDateTime(DateTime.parse(this)).formatFullDate();

  /// Last part of a path or URL, without ?query or #hash. "https://x.com/a/b.pdf?x=1" → "b.pdf"
  String get fileName {
    if (trim().isEmpty) return "";
    String url = this;
    final int endIndex = url.indexOf(RegExp("[?#]"));
    if (endIndex >= 0) url = url.substring(0, endIndex);
    url = url.replaceAll(RegExp(r"[/\\]+$"), "");
    final int lastSlash = max(url.lastIndexOf("/"), url.lastIndexOf(r"\"));
    final String name = lastSlash >= 0 ? url.substring(lastSlash + 1) : url;
    try {
      return Uri.decodeComponent(name);
    } catch (_) {
      return name;
    }
  }

  /// File name without its extension. "a/b.tar.gz" → "b.tar"
  String get fileNameWithoutExtension {
    final String name = fileName;
    if (name.isEmpty) return "";
    final int dotIndex = name.lastIndexOf(".");
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }

  /// Extension with the dot. "a/b.pdf" → ".pdf"
  String get fileExtension {
    final String name = fileName;
    if (name.isEmpty) return "";
    final int dotIndex = name.lastIndexOf(".");
    return dotIndex > 0 ? name.substring(dotIndex) : "";
  }

  /// Adds a leading zero to a single character. "5" → "05"
  String append0() => length == 1 ? "0$this" : this;

  /// ISO date → "1403/1/1 14:05:09" in Jalali.
  String formatJalaliDateTime() {
    final DateTime dateTime = DateTime.parse(this);
    final UJalali jalali = UJalali.fromDateTime(dateTime);
    return "${jalali.year}/${jalali.month}/${jalali.day} ${dateTime.hour.twoDigits}:${dateTime.minute.twoDigits}:${dateTime.second.twoDigits}";
  }

  /// Cuts to [max] characters with "..." at the end. `"Hello world".maxLength(max: 8)` → "Hello..."
  String maxLength({required int max}) {
    if (length <= max) return this;
    if (max <= 3) return substring(0, max);
    return "${substring(0, max - 3)}...";
  }

  /// Day from an ISO date. "2024-03-20" → 20
  int getDay() => int.parse(substring(8, 10));

  /// Month from an ISO date. "2024-03-20" → 3
  int getMonth() => int.parse(substring(5, 7));

  /// Year from an ISO date. "2024-03-20" → 2024
  int getYear() => int.parse(substring(0, 4));

  /// Hour from "HH:mm". "14:05" → 14
  int getHour() => int.parse(substring(0, 2));

  /// Minute from "HH:mm". "14:05" → 5
  int getMinute() => int.parse(substring(3, 5));

  /// ISO date → "3 hours ago" / "۳ ساعت پیش"; older than 8 days shows the date. `createdAt.toTimeAgo(persian: true)`
  String toTimeAgo({bool numericDates = false, bool persian = false}) {
    final DateTime? date = DateTime.tryParse(this);
    if (date == null) return this;
    final Duration difference = DateTime.now().difference(date);
    if (difference.inDays > 8) return length >= 10 ? substring(0, 10) : this;
    if (difference.inDays >= 7) return persian ? (numericDates ? "۱ هفته پیش" : "هفته پیش") : (numericDates ? "1 week ago" : "Last week");
    if (difference.inDays >= 2) return persian ? "${difference.inDays.toString().toPersianNumber()} روز پیش" : "${difference.inDays} days ago";
    if (difference.inDays >= 1) return persian ? (numericDates ? "۱ روز پیش" : "دیروز") : (numericDates ? "1 day ago" : "Yesterday");
    if (difference.inHours >= 2) return persian ? "${difference.inHours.toString().toPersianNumber()} ساعت پیش" : "${difference.inHours} hours ago";
    if (difference.inHours >= 1) return persian ? (numericDates ? "۱ ساعت پیش" : "یک ساعت پیش") : (numericDates ? "1 hour ago" : "An hour ago");
    if (difference.inMinutes >= 2) return persian ? "${difference.inMinutes.toString().toPersianNumber()} دقیقه پیش" : "${difference.inMinutes} minutes ago";
    if (difference.inMinutes >= 1) return persian ? (numericDates ? "۱ دقیقه پیش" : "یک دقیقه پیش") : (numericDates ? "1 minute ago" : "A minute ago");
    if (difference.inSeconds >= 3) return persian ? "${difference.inSeconds.toString().toPersianNumber()} ثانیه پیش" : "${difference.inSeconds} seconds ago";
    return persian ? "همین الان" : "Just now";
  }

  /// Latin digits → Persian digits. "123" → "۱۲۳"
  String toPersianNumber() {
    final StringBuffer out = StringBuffer();
    for (final int c in codeUnits) {
      out.writeCharCode(c >= 0x30 && c <= 0x39 ? c - 0x30 + 0x06F0 : c);
    }
    return out.toString();
  }

  /// Any digits (Persian, Arabic, Hindi, full-width…) → Latin digits. "۱۲۳" → "123"
  String toLatinNumber() {
    final StringBuffer result = StringBuffer();
    for (final int rune in runes) {
      final int? digit = _unicodeDigitToLatin(rune);
      if (digit != null) {
        result.write(digit);
      } else {
        result.writeCharCode(rune);
      }
    }
    return result.toString();
  }

  static int? _unicodeDigitToLatin(int codePoint) {
    const List<int> zeros = <int>[0x30, 0x0660, 0x06F0, 0x0966, 0x09E6, 0x0A66, 0x0AE6, 0x0B66, 0x0BE6, 0x0C66, 0x0CE6, 0x0D66, 0x0E50, 0x0ED0, 0x0F20, 0x1040, 0x17E0, 0x1810, 0xFF10];
    for (final int zero in zeros) {
      if (codePoint >= zero && codePoint <= zero + 9) return codePoint - zero;
    }
    return null;
  }

  /// English weekday names → Persian. "Monday" → "دو شنبه"
  String persianDayDay() => replaceAll("Sunday", "یک شنبه")
      .replaceAll("Monday", "دو شنبه")
      .replaceAll("Tuesday", "سه شنبه")
      .replaceAll("Wednesday", "چهار شنبه")
      .replaceAll("Thursday", "پنج شنبه")
      .replaceAll("Friday", "جمعه")
      .replaceAll("Saturday", "شنبه");

  /// Persian weekday names (with space, half-space or joined) → English. "دوشنبه" → "Monday"
  String englishDay() {
    String day = this;
    const Map<String, String> names = <String, String>{"یک": "Sunday", "دو": "Monday", "سه": "Tuesday", "چهار": "Wednesday", "پنج": "Thursday"};
    names.forEach((String prefix, String english) => day = day.replaceAll(RegExp("$prefix[ ‌]?شنبه"), english));
    return day.replaceAll("جمعه", "Friday").replaceAll("شنبه", "Saturday");
  }

  /// Two-digit month numbers → Jalali month names. "01" → "فروردین"
  String persianMonth() {
    const List<String> names = <String>["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
    final int? n = int.tryParse(trim());
    if (n != null && n >= 1 && n <= 12) return names[n - 1];
    return this;
  }

  /// Two-digit month numbers → English month names. "01" → "January"
  String englishMonth() {
    const List<String> names = <String>["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    final int? n = int.tryParse(trim());
    if (n != null && n >= 1 && n <= 12) return names[n - 1];
    return this;
  }

  /// Removes the character at [charIndex]. `"abc".removeCharAt(1)` → "ac"
  String removeCharAt(int charIndex) => replaceRange(charIndex, charIndex + 1, "");

  /// Text → base64. "hi" → "aGk="
  String toBase64() => base64Encode(utf8.encode(this));

  /// Base64 → text. "aGk=" → "hi"
  String fromBase64() => utf8.decode(base64Decode(this));

  /// Text → Base58 (Bitcoin alphabet).
  String toBase58() => UEncryption.base58EncodeText(this);

  /// Base58 → text; throws FormatException on a bad character.
  String fromBase58() => UEncryption.base58DecodeText(this);

  /// Digits only, Persian digits converted first. "۱۲-۳" → "123"
  String extractLatinNumber() => toLatinNumber().replaceAll(_nonDigits, "");

  /// True for a valid email address.
  bool get isValidEmail => _emailPattern.hasMatch(this);

  /// True for a web address (http/https optional).
  bool get isValidUrl => _urlPattern.hasMatch(this);

  /// True for 8-15 digits with optional + (Latin digits only; call toLatinNumber() first).
  bool get isValidPhone => _phonePattern.hasMatch(this);

  /// True when only English letters and digits.
  bool get isAlphanumeric => _alphanumericPattern.hasMatch(this);

  /// True for 8+ chars with upper, lower, digit and one of @$!%*?&.
  bool get isStrongPassword => _strongPasswordPattern.hasMatch(this);

  /// True when the text is written in Persian letters. "سلام".isPersian → true
  bool get isPersian => UPersianTools.isPersian(this);

  /// True when the text contains any Persian letter.
  bool get hasPersian => UPersianTools.hasPersian(this);

  /// True when empty or only spaces.
  bool get isBlank => trim().isEmpty;

  /// First letter upper-case. "hello" → "Hello"
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";

  /// Every word capitalized. "hello big world" → "Hello Big World"
  String toTitleCase() => split(" ").map((String w) => w.isEmpty ? w : "${w[0].toUpperCase()}${w.substring(1).toLowerCase()}").join(" ");

  /// URL-friendly slug (Persian letters kept). "Hello World!" → "hello-world"
  String toSlug() => trim().toLowerCase().replaceAll(RegExp(r"[^\w؀-ۿ]+"), "-").replaceAll(RegExp(r"^-+|-+$"), "");

  /// Hides the middle with [char], keeping [start] and [end] characters. "09121234567".mask(start: 4, end: 3) → "0912****567"
  String mask({int start = 4, int end = 4, String char = "*"}) {
    if (length <= start + end) return this;
    return "${substring(0, start)}${char * (length - start - end)}${substring(length - end)}";
  }

  /// Arabic ي/ك → Persian ی/ک and removes tatweel (ـ), for search and saving. "علي" → "علی"
  String normalizePersian() => replaceAll("ي", "ی").replaceAll("ى", "ی").replaceAll("ك", "ک").replaceAll("ـ", "").replaceAll("ة", "ه");

  /// Hex color text → Color; accepts "#RGB", "#RRGGBB" and "#AARRGGBB". "#FF5722".toColor()
  Color toColor() {
    String hex = replaceAll("#", "").trim();
    if (hex.length == 3) hex = hex.split("").map((String c) => "$c$c").join();
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }

  /// Number of times [other] appears. `"banana".countOf("a")` → 3
  int countOf(String other) => other.isEmpty ? 0 : RegExp(RegExp.escape(other)).allMatches(this).length;

  /// The text reversed (emoji safe). "abc" → "cba"
  String get reversed => characters.toList().reversed.join();
}

/// Base64 helpers on bytes. `bytes.toBase64()`
extension Base64BytesExtensions on Uint8List {
  /// Bytes → base64.
  String toBase64() => base64.encode(this);

  /// Bytes → URL-safe base64.
  String toBase64Url() => base64Url.encode(this);

  /// Bytes → base64 without "=" padding.
  String toBase64WithoutPadding() => base64.encode(this).replaceAll("=", "");

  /// Bytes → hex. `[255, 1]` → "ff01"
  String toHex() => UEncryption.hexEncode(this);
}
