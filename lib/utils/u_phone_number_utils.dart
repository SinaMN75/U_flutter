import "package:u/utilities.dart";

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

    final String ccNoPlus = countryCode.substring(1);
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

  static String sanitize(String rawInput) => rawInput.toLatinNumber().replaceAll(RegExp(r"[^\d+]"), "");

  static String dialCodeOf(String countryCode) {
    final String code = countryCode.trim();
    return code.startsWith("+") ? code : "+$code";
  }

  static const int e164MaxDigits = 15;
  static const int nationalMinDigits = 4;

  static const Set<String> significantLeadingZeroDialCodes = <String>{"+39", "+225"};

  static const Map<String, String> trunkPrefixes = <String, String>{
    "+1": "1",
    "+7": "8",
    "+36": "06",
    "+370": "8",
    "+375": "8",
  };

  static const Map<String, String> primaryCountryByDialCode = <String, String>{
    "+1": "US",
    "+7": "RU",
    "+39": "IT",
    "+44": "GB",
    "+47": "NO",
    "+61": "AU",
    "+64": "NZ",
    "+212": "MA",
    "+262": "RE",
    "+358": "FI",
    "+500": "FK",
    "+590": "GP",
    "+599": "CW",
    "+672": "NF",
  };

  static UCountry? countryOfDialCode(String? countryCode) {
    if (countryCode == null || countryCode.trim().isEmpty) return null;
    final String code = dialCodeOf(countryCode);
    return UCountries.byIsoCode(primaryCountryByDialCode[code]) ?? UCountries.byDialCode(code);
  }

  static UCountry resolveCountry(String? value) => UCountries.byIsoCode(value) ?? countryOfDialCode(value) ?? countryOf(value ?? "") ?? U.defaultPhoneCountry;

  static UCountry? countryOf(String rawInput) {
    final String input = sanitize(rawInput);
    final String international = input.startsWith("+")
        ? input
        : input.startsWith("00")
        ? "+${input.substring(2)}"
        : "";
    if (international.length < 2) return null;
    String? dialCode;
    for (final UCountry i in UCountries.countries) {
      if (international.startsWith(i.dialCode) && (dialCode == null || i.dialCode.length > dialCode.length)) dialCode = i.dialCode;
    }
    return countryOfDialCode(dialCode);
  }

  static String nationalNumber(String rawInput, {required String countryCode}) {
    String input = sanitize(rawInput);
    if (input.isEmpty) return "";

    final String code = dialCodeOf(countryCode);
    final String ccNoPlus = code.substring(1);

    if (input.startsWith(code)) {
      input = input.substring(code.length);
    } else if (input.startsWith("00$ccNoPlus")) {
      input = input.substring(ccNoPlus.length + 2);
    } else if (input.startsWith("+")) {
      input = input.substring(1);
    }

    input = input.replaceAll("+", "");
    if (significantLeadingZeroDialCodes.contains(code)) return input;

    final String trunk = trunkPrefixes[code] ?? "0";
    if (input.startsWith(trunk)) input = input.substring(trunk.length);
    if (trunk != "0" && input.startsWith("0")) input = input.substring(1);
    return input;
  }

  static int maxNationalDigits(String countryCode) => e164MaxDigits - (dialCodeOf(countryCode).length - 1);

  static String toE164(String rawInput, {required String countryCode}) {
    final String national = nationalNumber(rawInput, countryCode: countryCode);
    if (national.isEmpty) return "";
    return "${dialCodeOf(countryCode)}$national";
  }

  static bool isValid(String rawInput, {required String countryCode}) {
    final String national = nationalNumber(rawInput, countryCode: countryCode);
    if (national.length < nationalMinDigits || national.length > maxNationalDigits(countryCode)) return false;
    final List<int>? lengths = nationalDigitLengths[dialCodeOf(countryCode)];
    return lengths == null || lengths.contains(national.length);
  }

  static const Map<String, List<int>> nationalDigitLengths = <String, List<int>>{
    "+98": <int>[10],
    "+1": <int>[10],
    "+7": <int>[10],
    "+20": <int>[10],
    "+27": <int>[9],
    "+30": <int>[10],
    "+31": <int>[9],
    "+32": <int>[8, 9],
    "+33": <int>[9],
    "+34": <int>[9],
    "+36": <int>[8, 9],
    "+40": <int>[9],
    "+41": <int>[9],
    "+43": <int>[10, 11, 12, 13],
    "+44": <int>[9, 10],
    "+45": <int>[8],
    "+46": <int>[7, 8, 9],
    "+48": <int>[9],
    "+49": <int>[10, 11],
    "+51": <int>[9],
    "+52": <int>[10],
    "+53": <int>[8],
    "+54": <int>[10],
    "+55": <int>[10, 11],
    "+56": <int>[9],
    "+57": <int>[10],
    "+58": <int>[10],
    "+60": <int>[9, 10],
    "+61": <int>[9],
    "+62": <int>[9, 10, 11, 12],
    "+63": <int>[10],
    "+64": <int>[8, 9, 10],
    "+65": <int>[8],
    "+66": <int>[9],
    "+81": <int>[10],
    "+82": <int>[9, 10],
    "+84": <int>[9],
    "+86": <int>[11],
    "+90": <int>[10],
    "+91": <int>[10],
    "+92": <int>[10],
    "+93": <int>[9],
    "+94": <int>[9],
    "+95": <int>[8, 9, 10],
    "+212": <int>[9],
    "+213": <int>[9],
    "+216": <int>[8],
    "+218": <int>[9],
    "+220": <int>[7],
    "+234": <int>[10],
    "+249": <int>[9],
    "+251": <int>[9],
    "+254": <int>[9],
    "+255": <int>[9],
    "+256": <int>[9],
    "+260": <int>[9],
    "+263": <int>[9],
    "+351": <int>[9],
    "+352": <int>[9],
    "+353": <int>[9],
    "+354": <int>[7],
    "+355": <int>[9],
    "+358": <int>[9, 10],
    "+359": <int>[8, 9],
    "+370": <int>[8],
    "+375": <int>[9],
    "+371": <int>[8],
    "+372": <int>[7, 8],
    "+380": <int>[9],
    "+381": <int>[8, 9],
    "+385": <int>[8, 9],
    "+386": <int>[8],
    "+420": <int>[9],
    "+421": <int>[9],
    "+852": <int>[8],
    "+853": <int>[8],
    "+880": <int>[10],
    "+886": <int>[9],
    "+961": <int>[7, 8],
    "+962": <int>[9],
    "+963": <int>[9],
    "+964": <int>[10],
    "+965": <int>[8],
    "+966": <int>[9],
    "+967": <int>[9],
    "+968": <int>[8],
    "+971": <int>[9],
    "+972": <int>[9],
    "+973": <int>[8],
    "+974": <int>[8],
    "+975": <int>[8],
    "+976": <int>[8],
    "+977": <int>[10],
    "+992": <int>[9],
    "+993": <int>[8],
    "+994": <int>[9],
    "+995": <int>[9],
    "+996": <int>[9],
    "+998": <int>[9],
  };
}
