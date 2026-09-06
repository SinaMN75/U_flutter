/// PAN handling ported from the Java `PanUtil`.
abstract class PanUtil {
  static String cardNumberFromTrack2(String track2) => track2.split("=").first;

  static String? maskPanInternal(String? pan) {
    if (pan == null) return null;
    if (pan.length != 16 && pan.length != 19) return pan;
    return "${pan.substring(0, 6)}***${pan.substring(pan.length - 4)}";
  }

  static String? maskPan(String panOrTrack2, String? panLast4Digit) {
    if (panLast4Digit != null && panLast4Digit.isNotEmpty) return "**********$panLast4Digit";
    return maskPanInternal(cardNumberFromTrack2(panOrTrack2));
  }

  static bool isDomestic(String track2, String domesticBin) => track2.length >= 6 && track2.substring(0, 6) == domesticBin;
}
