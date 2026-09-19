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

    return stripTrunkPrefix(input.replaceAll("+", ""), countryCode: code);
  }

  static String stripTrunkPrefix(String digits, {required String countryCode}) {
    final String code = dialCodeOf(countryCode);
    if (significantLeadingZeroDialCodes.contains(code)) return digits;

    final String trunk = trunkPrefixes[code] ?? "0";
    if (trunk == "0") return digits.length > 1 && digits.startsWith("0") ? digits.substring(1) : digits;

    final List<int>? lengths = nationalDigitLengths[code];
    if (lengths == null) return digits.startsWith(trunk) ? digits.substring(trunk.length) : digits;

    final int max = maxInputDigits(code);
    String result = digits;
    if (result.length > max && result.startsWith(trunk)) result = result.substring(trunk.length);
    if (result.length > max && result.startsWith("0")) result = result.substring(1);
    return result;
  }

  static int maxNationalDigits(String countryCode) => e164MaxDigits - (dialCodeOf(countryCode).length - 1);

  static String toE164(String rawInput, {required String countryCode}) {
    final String national = nationalNumber(rawInput, countryCode: countryCode);
    if (national.isEmpty) return "";
    return "${dialCodeOf(countryCode)}$national";
  }

  static bool isValid(String rawInput, {required String countryCode}) {
    final String code = dialCodeOf(countryCode);
    final String national = nationalNumber(rawInput, countryCode: code);
    if (national.length < nationalMinDigits || national.length > maxNationalDigits(code)) return false;
    if (national.startsWith("0") && !significantLeadingZeroDialCodes.contains(code)) return false;
    final List<int>? lengths = nationalDigitLengths[code];
    return lengths == null || lengths.contains(national.length);
  }

  static const Map<String, Map<int, String>> nationalFormats = <String, Map<int, String>>{
    "+1": <int, String>{10: "(###) ###-####"},
    "+7": <int, String>{10: "(###) ###-##-##"},
    "+20": <int, String>{10: "## #### ####"},
    "+27": <int, String>{9: "## ### ####"},
    "+30": <int, String>{10: "### ### ####"},
    "+31": <int, String>{9: "# ########"},
    "+32": <int, String>{8: "### ## ## ##", 9: "### ## ## ##"},
    "+33": <int, String>{9: "# ## ## ## ##"},
    "+34": <int, String>{9: "### ## ## ##"},
    "+36": <int, String>{8: "## ### ###", 9: "## ### ####"},
    "+39": <int, String>{9: "### ######", 10: "### ### ####"},
    "+40": <int, String>{9: "### ### ###"},
    "+41": <int, String>{9: "## ### ## ##"},
    "+44": <int, String>{9: "#### #####", 10: "#### ######"},
    "+45": <int, String>{8: "## ## ## ##"},
    "+46": <int, String>{7: "## ### ##", 8: "## ### ## #", 9: "## ### ## ##"},
    "+47": <int, String>{8: "### ## ###"},
    "+48": <int, String>{9: "### ### ###"},
    "+49": <int, String>{10: "### #######", 11: "### ########"},
    "+51": <int, String>{9: "### ### ###"},
    "+52": <int, String>{10: "## #### ####"},
    "+53": <int, String>{8: "# ### ####"},
    "+54": <int, String>{10: "## #### ####"},
    "+55": <int, String>{10: "## ####-####", 11: "## #####-####"},
    "+56": <int, String>{9: "# #### ####"},
    "+57": <int, String>{10: "### ### ####"},
    "+58": <int, String>{10: "### ### ####"},
    "+60": <int, String>{9: "## ### ####", 10: "## #### ####"},
    "+61": <int, String>{9: "### ### ###"},
    "+63": <int, String>{10: "### ### ####"},
    "+64": <int, String>{8: "# ### ####", 9: "## ### ####", 10: "## ### #####"},
    "+65": <int, String>{8: "#### ####"},
    "+66": <int, String>{9: "## ### ####"},
    "+81": <int, String>{10: "## #### ####"},
    "+82": <int, String>{9: "## ### ####", 10: "## #### ####"},
    "+84": <int, String>{9: "### ### ###"},
    "+86": <int, String>{11: "### #### ####"},
    "+90": <int, String>{10: "### ### ## ##"},
    "+91": <int, String>{10: "##### #####"},
    "+92": <int, String>{10: "### #######"},
    "+93": <int, String>{9: "## ### ####"},
    "+94": <int, String>{9: "## ### ####"},
    "+98": <int, String>{10: "### ### ####"},
    "+212": <int, String>{9: "### ### ###"},
    "+213": <int, String>{9: "### ## ## ##"},
    "+216": <int, String>{8: "## ### ###"},
    "+218": <int, String>{9: "## ### ####"},
    "+234": <int, String>{10: "### ### ####"},
    "+249": <int, String>{9: "## ### ####"},
    "+251": <int, String>{9: "## ### ####"},
    "+254": <int, String>{9: "### ######"},
    "+255": <int, String>{9: "### ### ###"},
    "+256": <int, String>{9: "### ######"},
    "+260": <int, String>{9: "## ### ####"},
    "+263": <int, String>{9: "## ### ####"},
    "+351": <int, String>{9: "### ### ###"},
    "+352": <int, String>{9: "### ### ###"},
    "+353": <int, String>{9: "## ### ####"},
    "+354": <int, String>{7: "### ####"},
    "+355": <int, String>{9: "### ### ###"},
    "+358": <int, String>{9: "## ### ####", 10: "## #### ####"},
    "+359": <int, String>{8: "## ### ###", 9: "### ### ###"},
    "+370": <int, String>{8: "### #####"},
    "+371": <int, String>{8: "## ### ###"},
    "+372": <int, String>{7: "### ####", 8: "#### ####"},
    "+375": <int, String>{9: "## ### ## ##"},
    "+380": <int, String>{9: "## ### ####"},
    "+381": <int, String>{8: "## ### ###", 9: "## ### ####"},
    "+385": <int, String>{8: "## ### ###", 9: "## ### ####"},
    "+386": <int, String>{8: "## ### ###"},
    "+420": <int, String>{9: "### ### ###"},
    "+421": <int, String>{9: "### ### ###"},
    "+852": <int, String>{8: "#### ####"},
    "+853": <int, String>{8: "#### ####"},
    "+880": <int, String>{10: "#### ######"},
    "+886": <int, String>{9: "### ### ###"},
    "+961": <int, String>{7: "## ### ###", 8: "## ### ###"},
    "+962": <int, String>{9: "# #### ####"},
    "+963": <int, String>{9: "### ### ###"},
    "+964": <int, String>{10: "### ### ####"},
    "+965": <int, String>{8: "#### ####"},
    "+966": <int, String>{9: "## ### ####"},
    "+967": <int, String>{9: "### ### ###"},
    "+968": <int, String>{8: "#### ####"},
    "+971": <int, String>{9: "## ### ####"},
    "+972": <int, String>{9: "##-###-####"},
    "+973": <int, String>{8: "#### ####"},
    "+974": <int, String>{8: "#### ####"},
    "+975": <int, String>{8: "## ### ###"},
    "+976": <int, String>{8: "#### ####"},
    "+977": <int, String>{10: "###-#######"},
    "+992": <int, String>{9: "## ### ####"},
    "+993": <int, String>{8: "## ######"},
    "+994": <int, String>{9: "## ### ## ##"},
    "+995": <int, String>{9: "### ## ## ##"},
    "+996": <int, String>{9: "### ### ###"},
    "+998": <int, String>{9: "## ### ## ##"},
  };

  static String formatMask(int length, String countryCode) {
    final String? mask = nationalFormats[dialCodeOf(countryCode)]?[length];
    if (mask != null) return mask;
    switch (length) {
      case 0:
        return "";
      case 7:
        return "### ####";
      case 8:
        return "#### ####";
      case 9:
        return "### ### ###";
      case 10:
        return "### ### ####";
      case 11:
        return "### #### ####";
      case 12:
        return "#### #### ####";
      default:
        return List<String>.filled(length, "#").join();
    }
  }

  static String formatNational(String digits, {required String countryCode}) {
    if (digits.isEmpty) return "";
    final String mask = formatMask(digits.length, countryCode);
    if (!mask.contains("#")) return digits;
    final StringBuffer out = StringBuffer();
    int d = 0;
    for (int i = 0; i < mask.length && d < digits.length; i++) {
      if (mask[i] == "#") {
        out.write(digits[d]);
        d++;
      } else {
        out.write(mask[i]);
      }
    }
    while (d < digits.length) {
      out.write(digits[d]);
      d++;
    }
    return out.toString();
  }

  static String formatE164(String e164) {
    final UCountry? country = countryOf(e164);
    if (country == null) return e164;
    return "${country.dialCode} ${formatNational(nationalNumber(e164, countryCode: country.dialCode), countryCode: country.dialCode)}";
  }

  static int maxInputDigits(String countryCode) {
    final List<int>? lengths = nationalDigitLengths[dialCodeOf(countryCode)];
    if (lengths == null || lengths.isEmpty) return maxNationalDigits(countryCode);
    int max = lengths.first;
    for (final int i in lengths) {
      if (i > max) max = i;
    }
    return max;
  }

  static String placeholder(String countryCode) {
    final List<int>? lengths = nationalDigitLengths[dialCodeOf(countryCode)];
    final int length = lengths == null || lengths.isEmpty ? 9 : lengths.last;
    return formatMask(length, countryCode).replaceAll("#", "0");
  }

  static String inputDigits(String rawInput, {required String countryCode}) {
    final String digits = stripTrunkPrefix(sanitize(rawInput).replaceAll("+", ""), countryCode: countryCode);
    final int max = maxInputDigits(countryCode);
    return digits.length > max ? digits.substring(0, max) : digits;
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
