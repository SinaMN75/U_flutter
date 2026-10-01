import "package:u/utilities.dart";

/// Human text for map numbers: distances, durations, speeds, ETAs and turn instructions, in English or Persian (Persian digits).
abstract final class UMapFormat {
  /// "850 m", "12.4 km", "0.3 mi" or "۸۵۰ متر" / "۱۲٫۴ کیلومتر".
  static String distance(double meters, {bool persian = false, bool imperial = false}) {
    String out;
    if (imperial) {
      final double feet = meters * 3.28084;
      out = feet < 1000 ? "${feet.round()} ${persian ? "فوت" : "ft"}" : "${(meters / 1609.344).toStringAsFixed(meters < 16093 ? 1 : 0)} ${persian ? "مایل" : "mi"}";
    } else if (meters < 1000) {
      final int m = meters < 100 ? (meters / 5).round() * 5 : (meters / 10).round() * 10;
      out = "$m ${persian ? "متر" : "m"}";
    } else {
      out = "${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} ${persian ? "کیلومتر" : "km"}";
    }
    return persian ? _fa(out) : out;
  }

  /// "45 min", "2 h 10 min" or "۴۵ دقیقه" / "۲ ساعت و ۱۰ دقیقه".
  static String duration(Duration d, {bool persian = false}) {
    final int minutes = (d.inSeconds / 60).round();
    if (minutes < 1) return persian ? "کمتر از ۱ دقیقه" : "< 1 min";
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (persian) return _fa(h == 0 ? "$m دقیقه" : (m == 0 ? "$h ساعت" : "$h ساعت و $m دقیقه"));
    return h == 0 ? "$m min" : (m == 0 ? "$h h" : "$h h $m min");
  }

  /// "54 km/h" / "34 mph" / "۵۴ کیلومتر بر ساعت" from metres per second.
  static String speed(double metersPerSecond, {bool persian = false, bool imperial = false}) {
    final String out = imperial ? "${(metersPerSecond * 2.23694).round()} ${persian ? "مایل بر ساعت" : "mph"}" : "${(metersPerSecond * 3.6).round()} ${persian ? "کیلومتر بر ساعت" : "km/h"}";
    return persian ? _fa(out) : out;
  }

  /// Minutes per km pace for runners, e.g. "5:20 /km".
  static String pace(double metersPerSecond, {bool persian = false}) {
    if (metersPerSecond <= 0) return "-";
    final int s = (1000 / metersPerSecond).round();
    final String out = "${s ~/ 60}:${(s % 60).toString().padLeft(2, "0")} ${persian ? "/کیلومتر" : "/km"}";
    return persian ? _fa(out) : out;
  }

  /// Arrival clock time after [remaining], e.g. "14:35" (Persian digits when [persian]).
  static String eta(Duration remaining, {bool persian = false, DateTime? from}) {
    final DateTime t = (from ?? DateTime.now()).add(remaining);
    final String out = "${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}";
    return persian ? _fa(out) : out;
  }

  /// Compass word for a bearing: N, NE… or شمال، شمال شرقی…
  static String compass(double bearing, {bool persian = false}) {
    const List<String> en = <String>["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    const List<String> fa = <String>["شمال", "شمال شرقی", "شرق", "جنوب شرقی", "جنوب", "جنوب غربی", "غرب", "شمال غربی"];
    final int i = (((bearing % 360) + 22.5) ~/ 45) % 8;
    return persian ? fa[i] : en[i];
  }

  /// Area as m², hectares or km².
  static String area(double squareMeters, {bool persian = false}) {
    String out;
    if (squareMeters < 10000) {
      out = "${squareMeters.round()} ${persian ? "متر مربع" : "m²"}";
    } else if (squareMeters < 1000000) {
      out = "${(squareMeters / 10000).toStringAsFixed(2)} ${persian ? "هکتار" : "ha"}";
    } else {
      out = "${(squareMeters / 1000000).toStringAsFixed(2)} ${persian ? "کیلومتر مربع" : "km²"}";
    }
    return persian ? _fa(out) : out;
  }

  static String _fa(String s) => s.toPersianNumber().replaceAll(".", "٫");

  /// Turn instruction text for an OSRM-style maneuver (type + modifier), e.g. "Turn left onto Valiasr St" / "به چپ بپیچید به خیابان ولیعصر".
  static String instruction(String type, String? modifier, {String? street, int? exit, bool persian = false}) {
    final String m = modifier ?? "straight";
    final bool hasName = street != null && street.trim().isNotEmpty;
    if (persian) {
      final String onto = hasName ? " به $street" : "";
      const Map<String, String> dir = <String, String>{
        "uturn": "دور بزنید",
        "sharp right": "به‌شدت به راست بپیچید",
        "right": "به راست بپیچید",
        "slight right": "کمی به راست بروید",
        "straight": "مستقیم بروید",
        "slight left": "کمی به چپ بروید",
        "left": "به چپ بپیچید",
        "sharp left": "به‌شدت به چپ بپیچید",
      };
      final String turn = dir[m] ?? "ادامه دهید";
      final String text = switch (type) {
        "depart" => "حرکت کنید${hasName ? " در $street" : ""}",
        "arrive" => "به مقصد رسیدید",
        "roundabout" || "rotary" => "وارد میدان شوید و از خروجی ${exit ?? 1} خارج شوید$onto",
        "exit roundabout" || "exit rotary" => "از میدان خارج شوید$onto",
        "merge" => "ادغام شوید$onto",
        "on ramp" => "وارد رمپ شوید$onto",
        "off ramp" => "از خروجی خارج شوید$onto",
        "fork" => "${m.contains("left") ? "در دوراهی سمت چپ" : "در دوراهی سمت راست"} را بروید$onto",
        "end of road" => "در انتهای مسیر $turn$onto",
        "continue" || "new name" => "${m == "straight" ? "ادامه دهید" : turn}$onto",
        _ => "$turn$onto",
      };
      return _fa(text);
    }
    final String onto = hasName ? " onto $street" : "";
    final String turn = m == "uturn" ? "Make a U-turn" : (m == "straight" ? "Go straight" : "Turn $m");
    return switch (type) {
      "depart" => "Head out${hasName ? " on $street" : ""}",
      "arrive" => "You have arrived",
      "roundabout" || "rotary" => "At the roundabout take exit ${exit ?? 1}$onto",
      "exit roundabout" || "exit rotary" => "Exit the roundabout$onto",
      "merge" => "Merge$onto",
      "on ramp" => "Take the ramp$onto",
      "off ramp" => "Take the exit$onto",
      "fork" => "Keep ${m.contains("left") ? "left" : "right"} at the fork$onto",
      "end of road" => "At the end of the road ${turn.toLowerCase()}$onto",
      "continue" || "new name" => "${m == "straight" ? "Continue" : turn}$onto",
      _ => "$turn$onto",
    };
  }

  /// Material icon for a maneuver.
  static IconData maneuverIcon(String type, String? modifier) {
    if (type == "arrive") return Icons.flag;
    if (type == "depart") return Icons.navigation;
    if (type.contains("roundabout") || type.contains("rotary")) return Icons.roundabout_right;
    if (type == "fork") return (modifier ?? "").contains("left") ? Icons.fork_left : Icons.fork_right;
    if (type == "merge") return Icons.merge;
    if (type.contains("ramp")) return (modifier ?? "").contains("left") ? Icons.ramp_left : Icons.ramp_right;
    return switch (modifier) {
      "uturn" => Icons.u_turn_left,
      "sharp right" => Icons.turn_sharp_right,
      "right" => Icons.turn_right,
      "slight right" => Icons.turn_slight_right,
      "slight left" => Icons.turn_slight_left,
      "left" => Icons.turn_left,
      "sharp left" => Icons.turn_sharp_left,
      _ => Icons.straight,
    };
  }
}
