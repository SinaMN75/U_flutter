import "package:u/utils/extensions/string_extension.dart";

class UPhoneNumberUtils {
  static String normalizePhone(
    String rawInput, {
    required String countryCode,
    bool stripLeadingZero = true,
  }) {
    rawInput = rawInput.toLatinNumber();
    if (rawInput.trim().isEmpty) return "";

    countryCode = countryCode.trim();
    if (!countryCode.startsWith("+")) {
      countryCode = "+$countryCode";
    }
    String input = rawInput.replaceAll(RegExp(r"[^\d+]"), "");

    if (input.startsWith(countryCode)) {
      return input;
    }

    final String ccNoPlus = countryCode.substring(1); // e.g. 98
    final String doubleZeroPrefix = "00$ccNoPlus";
    if (input.startsWith(doubleZeroPrefix)) {
      return countryCode + input.substring(doubleZeroPrefix.length);
    }

    if (input.startsWith("+") && !input.startsWith(countryCode)) {
      return input;
    }
    if (stripLeadingZero && input.startsWith("0")) {
      input = input.substring(1);
    }
    if (RegExp(r"^\d+$").hasMatch(input)) {
      return countryCode + input;
    }
    return input;
  }
}
