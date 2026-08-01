import "package:intl/intl.dart" as intl;
import "package:u/utilities.dart";

extension DateTimeExtensions on DateTime {
  String formatDate(final String dateFormat) => intl.DateFormat(dateFormat).format(this);

  DateTime utcNow() => DateTime.now().toUtc();

  String utcNowIso() => DateTime.now().toUtc().toIso8601String();

  String toJalaliDateTime() => "${toJalali().formatCompactDate()} ${hour.toString().append0()}:${minute.toString().append0()}";

  String toJalaliDate() => toJalali().formatCompactDate();

  Jalali toJalali() => Jalali.fromDateTime(this);

  String toTimeAgo({final bool numericDates = false, final bool persian = false}) {
    try {
      final Duration difference = DateTime.now().difference(this);

      if ((difference.inDays / 365).floor() >= 2) {
        return persian ? "${difference.inDays.toString().toPersianNumber()} سال پیش" : "${(difference.inDays / 365).floor()}y";
      } else if ((difference.inDays / 365).floor() >= 1)
        return persian
            ? numericDates
                  ? "۱ سال پیش"
                  : "سال پیش"
            : numericDates
            ? "1y"
            : "Last year";
      else if ((difference.inDays / 30).floor() >= 2)
        // return persian ? '${difference.inDays.toString().toPersianNumber()} ماه پیش' : '${(difference.inDays / 30).floor()}M';
        return persian ? "${(difference.inDays / 30).floor()} ماه پیش" : "${(difference.inDays / 30).floor()}M";
      else if ((difference.inDays / 30).floor() >= 1)
        return persian
            ? numericDates
                  ? "۱ ماه پیش"
                  : "ماه پیش"
            : numericDates
            ? "1M"
            : "Last month";
      else if ((difference.inDays / 7).floor() >= 2)
        return persian ? "${difference.inDays.toString().toPersianNumber()} روز پیش" : "${(difference.inDays / 7).floor()}w";
      else if ((difference.inDays / 7).floor() >= 1)
        return persian
            ? numericDates
                  ? "۱ هفته پیش"
                  : "هفته پیش"
            : numericDates
            ? "1w"
            : "Last week";
      else if (difference.inDays >= 2)
        return persian ? "${difference.inDays.toString().toPersianNumber()} روز پیش" : "${difference.inDays}d";
      else if (difference.inDays >= 1)
        return persian
            ? numericDates
                  ? "۱ روز پیش"
                  : "دیروز"
            : numericDates
            ? "1d"
            : "Yesterday";
      else if (difference.inHours >= 2)
        return persian ? "${difference.inHours.toString().toPersianNumber()} ساعت پیش" : "${difference.inHours}h";
      else if (difference.inHours >= 1)
        return persian
            ? numericDates
                  ? "۱ ساعت پیش"
                  : "یک ساعت پیش"
            : numericDates
            ? "1h"
            : "An hour ago";
      else if (difference.inMinutes >= 2)
        return persian ? "${difference.inMinutes.toString().toPersianNumber()} دقیقه پیش" : "${difference.inMinutes}m";
      else if (difference.inMinutes >= 1)
        return persian
            ? numericDates
                  ? "۱ دقیقه پیش"
                  : "یک دقیقه پیش"
            : numericDates
            ? "1m"
            : "A minute ago";
      else if (difference.inSeconds >= 3)
        return persian ? "${difference.inSeconds.toString().toPersianNumber()} ثانیه پیش" : "${difference.inSeconds}s";
      else
        return persian ? "همین الان" : "Just now";
    } catch (e) {
      return toIso8601String();
    }
  }
}
