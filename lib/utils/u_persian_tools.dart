enum DigitLocale { en, fa, ar }

enum SimCardType { credit, permanent, both }

class Operator {
  const Operator._(this.name);

  final String name;
  static const Operator shatelMobile = Operator._("شاتل موبایل");
  static const Operator mci = Operator._("همراه اول");
  static const Operator irancell = Operator._("ایرانسل");
  static const Operator taliya = Operator._("تالیا");
  static const Operator rightTel = Operator._("رایتل");
  static const Operator samanTel = Operator._("سامانتل");

  @override
  bool operator ==(Object other) => identical(this, other) || other is Operator && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => "Operator{name: $name}";
}

class OperatorDetail {
  const OperatorDetail({
    required this.base,
    required this.operator,
    this.provinces = const <String>[],
    this.model,
    this.type = SimCardType.both,
  });

  final String base;
  final List<String> provinces;
  final String? model;
  final SimCardType type;
  final Operator operator;

  String get name => operator.name;

  OperatorDetail copyWith({
    String? base,
    List<String>? provinces,
    String? model,
    SimCardType? type,
    Operator? operator,
  }) => OperatorDetail(
    base: base ?? this.base,
    provinces: provinces ?? this.provinces,
    model: model ?? this.model,
    type: type ?? this.type,
    operator: operator ?? this.operator,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OperatorDetail && base == other.base && provinces == other.provinces && model == other.model && type == other.type && operator == other.operator;

  @override
  int get hashCode => base.hashCode ^ provinces.hashCode ^ model.hashCode ^ type.hashCode ^ operator.hashCode;

  @override
  String toString() => "OperatorDetail{base: $base, provinces: $provinces, model: $model, type: $type, operator: $operator}";
}

class AccountNumberModel {
  const AccountNumberModel({
    required this.accountNumber,
    required this.formattedAccountNumber,
  });

  final String accountNumber;
  final String formattedAccountNumber;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AccountNumberModel && accountNumber == other.accountNumber && formattedAccountNumber == other.formattedAccountNumber;

  @override
  int get hashCode => accountNumber.hashCode ^ formattedAccountNumber.hashCode;
}

class BankInfo {
  const BankInfo({
    required this.nickname,
    required this.name,
    required this.persianName,
    this.isAccountNumberAvailable = false,
    this.process,
    this.accountNumber,
    this.formattedAccountNumber,
  });

  final String nickname;
  final String name;
  final String persianName;
  final bool isAccountNumberAvailable;
  final AccountNumberModel Function(String)? process;
  final String? accountNumber;
  final String? formattedAccountNumber;

  BankInfo copyWith({
    String? nickname,
    String? name,
    String? persianName,
    bool? isAccountNumberAvailable,
    AccountNumberModel Function(String)? process,
    String? accountNumber,
    String? formattedAccountNumber,
  }) => BankInfo(
    nickname: nickname ?? this.nickname,
    name: name ?? this.name,
    persianName: persianName ?? this.persianName,
    isAccountNumberAvailable: isAccountNumberAvailable ?? this.isAccountNumberAvailable,
    process: process ?? this.process,
    accountNumber: accountNumber ?? this.accountNumber,
    formattedAccountNumber: formattedAccountNumber ?? this.formattedAccountNumber,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankInfo &&
          nickname == other.nickname &&
          name == other.name &&
          persianName == other.persianName &&
          isAccountNumberAvailable == other.isAccountNumberAvailable &&
          accountNumber == other.accountNumber &&
          formattedAccountNumber == other.formattedAccountNumber;

  @override
  int get hashCode => nickname.hashCode ^ name.hashCode ^ persianName.hashCode ^ isAccountNumberAvailable.hashCode ^ accountNumber.hashCode ^ formattedAccountNumber.hashCode;
}

class PersianTools {
  static const String _faText = "ابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی۰۱۲۳۴۵۶۷۸۹َُِآاً";
  static const String _faComplexText = "$_faTextًٌٍَُِّْٰٔءك‌ةۀأإيـئؤ،";

  static const String _faNumber = "۰۱۲۳۴۵۶۷۸۹";
  static const String _arNumber = "٠١٢٣٤٥٦٧٨٩";

  static final RegExp _asciiDigits = RegExp("[0-9]");
  static final RegExp _faDigits = RegExp("[$_faNumber]");
  static final RegExp _arDigits = RegExp("[$_arNumber]");
  static final RegExp _thousandsGroup = RegExp(r"(\d)(?=(\d{3})+(?!\d))");
  static const Map<int, String> _numberToWord = <int, String>{
    0: "",
    1: "یک",
    2: "دو",
    3: "سه",
    4: "چهار",
    5: "پنج",
    6: "شش",
    7: "هفت",
    8: "هشت",
    9: "نه",
    10: "ده",
    11: "یازده",
    12: "دوازده",
    13: "سیزده",
    14: "چهارده",
    15: "پانزده",
    16: "شانزده",
    17: "هفده",
    18: "هجده",
    19: "نوزده",
    20: "بیست",
    30: "سی",
    40: "چهل",
    50: "پنجاه",
    60: "شصت",
    70: "هفتاد",
    80: "هشتاد",
    90: "نود",
    100: "صد",
    200: "دویست",
    300: "سیصد",
    400: "چهارصد",
    500: "پانصد",
    600: "ششصد",
    700: "هفتصد",
    800: "هشتصد",
    900: "نهصد",
  };
  static const Map<String, int> _units = <String, int>{
    "صفر": 0,
    "یک": 1,
    "دو": 2,
    "سه": 3,
    "چهار": 4,
    "پنج": 5,
    "شش": 6,
    "شیش": 6,
    "هفت": 7,
    "هشت": 8,
    "نه": 9,
    "ده": 10,
    "یازده": 11,
    "دوازده": 12,
    "سیزده": 13,
    "چهارده": 14,
    "پانزده": 15,
    "شانزده": 16,
    "هفده": 17,
    "هجده": 18,
    "نوزده": 19,
    "بیست": 20,
    "سی": 30,
    "چهل": 40,
    "پنجاه": 50,
    "شصت": 60,
    "هفتاد": 70,
    "هشتاد": 80,
    "نود": 90,
  };
  static const Map<String, int> _ten = <String, int>{
    "صد": 100,
    "یکصد": 100,
    "دویست": 200,
    "سیصد": 300,
    "چهارصد": 400,
    "پانصد": 500,
    "ششصد": 600,
    "هفتصد": 700,
    "هشتصد": 800,
    "نهصد": 900,
  };

  static final Map<String, BankInfo> _bankInfo = <String, BankInfo>{
    "010": const BankInfo(nickname: "central-bank", name: "Central Bank of Iran", persianName: "بانک مرکزی جمهوری اسلامی ایران"),
    "011": const BankInfo(nickname: "sanat-o-madan", name: "Sanat O Madan Bank", persianName: "بانک صنعت و معدن"),
    "012": const BankInfo(nickname: "mellat", name: "Mellat Bank", persianName: "بانک ملت"),
    "013": const BankInfo(nickname: "refah", name: "Refah Bank", persianName: "بانک رفاه کارگران"),
    "014": const BankInfo(nickname: "maskan", name: "Maskan Bank", persianName: "بانک مسکن"),
    "015": const BankInfo(nickname: "sepah", name: "Sepah Bank", persianName: "بانک سپه"),
    "016": const BankInfo(nickname: "keshavarzi", name: "Keshavarzi", persianName: "بانک کشاورزی"),
    "017": const BankInfo(nickname: "melli", name: "Melli", persianName: "بانک ملی ایران"),
    "018": const BankInfo(nickname: "tejarat", name: "Tejarat Bank", persianName: "بانک تجارت"),
    "019": const BankInfo(nickname: "saderat", name: "Saderat Bank", persianName: "بانک صادرات ایران"),
    "020": const BankInfo(nickname: "tosee-saderat", name: "Tose Saderat Bank", persianName: "بانک توسعه صادرات"),
    "021": const BankInfo(nickname: "post", name: "Post Bank", persianName: "پست بانک ایران"),
    "022": const BankInfo(nickname: "toose-taavon", name: "Tosee Taavon Bank", persianName: "بانک توسعه تعاون"),
    "051": const BankInfo(nickname: "tosee", name: "Tosee Bank", persianName: "موسسه اعتباری توسعه"),
    "052": const BankInfo(nickname: "ghavamin", name: "Ghavamin Bank", persianName: "بانک قوامین"),
    "053": const BankInfo(nickname: "karafarin", name: "Karafarin Bank", persianName: "بانک کارآفرین"),
    "055": const BankInfo(nickname: "eghtesad-novin", name: "Eghtesad Novin Bank", persianName: "بانک اقتصاد نوین"),
    "056": const BankInfo(nickname: "saman", name: "Saman Bank", persianName: "بانک سامان"),
    "058": const BankInfo(nickname: "sarmayeh", name: "Sarmayeh Bank", persianName: "بانک سرمایه"),
    "059": const BankInfo(nickname: "sina", name: "Sina Bank", persianName: "بانک سینا"),
    "060": const BankInfo(nickname: "mehr-iran", name: "Mehr Iran Bank", persianName: "بانک مهر ایران"),
    "062": const BankInfo(nickname: "ayandeh", name: "Ayandeh Bank", persianName: "بانک آینده"),
    "063": const BankInfo(nickname: "ansar", name: "Ansar Bank", persianName: "بانک انصار"),
    "064": const BankInfo(nickname: "gardeshgari", name: "Gardeshgari Bank", persianName: "بانک گردشگری"),
    "065": const BankInfo(nickname: "hekmat-iranian", name: "Hekmat Iranian Bank", persianName: "بانک حکمت ایرانیان"),
    "066": const BankInfo(nickname: "dey", name: "Dey Bank", persianName: "بانک دی"),
    "069": const BankInfo(nickname: "iran-zamin", name: "Iran Zamin Bank", persianName: "بانک ایران زمین"),
    "070": const BankInfo(nickname: "resalat", name: "Resalat Bank", persianName: "بانک قرض الحسنه رسالت"),
    "073": const BankInfo(nickname: "kosar", name: "Kosar Credit Institute", persianName: "موسسه اعتباری کوثر"),
    "075": const BankInfo(nickname: "melal", name: "Melal Credit Institute", persianName: "موسسه اعتباری ملل"),
    "078": const BankInfo(nickname: "middle-east-bank", name: "Middle East Bank", persianName: "بانک خاورمیانه"),
    "080": const BankInfo(nickname: "noor-bank", name: "Noor Credit Institution", persianName: "موسسه اعتباری نور"),
    "079": const BankInfo(nickname: "mehr-eqtesad", name: "Mehr Eqtesad Bank", persianName: "بانک مهر اقتصاد"),
    "090": const BankInfo(nickname: "mehr-iran", name: "Mehr Iran Bank", persianName: "بانک مهر ایران"),
    "095": const BankInfo(nickname: "iran-venezuela", name: "Iran and Venezuela Bank", persianName: "بانک ایران و ونزوئلا"),
    "061": BankInfo(
      nickname: "shahr",
      name: "City Bank",
      persianName: "بانک شهر",
      isAccountNumberAvailable: true,
      process: (String s) {
        s = s.substring(7);
        while (s.startsWith("0")) {
          s = s.substring(1);
        }
        return AccountNumberModel(accountNumber: s, formattedAccountNumber: s);
      },
    ),
    "057": BankInfo(
      nickname: "pasargad",
      name: "Pasargad Bank",
      persianName: "بانک پاسارگاد",
      isAccountNumberAvailable: true,
      process: (String s) {
        s = s.substring(7);
        while (s.startsWith("0")) {
          s = s.substring(1);
        }
        s = s.substring(0, s.length - 1);
        return AccountNumberModel(
          accountNumber: s,
          formattedAccountNumber: "${s.substring(0, 4)}-${s.substring(3, 6)}-${s.substring(6, 14)}-${s[s.length - 1]}",
        );
      },
    ),
    "054": BankInfo(
      nickname: "parsian",
      name: "Parsian Bank",
      persianName: "بانک پارسیان",
      isAccountNumberAvailable: true,
      process: (String s) {
        s = s.substring(14);
        return AccountNumberModel(
          accountNumber: s,
          formattedAccountNumber: "0${s.substring(0, 3)}-0${s.substring(2, 8)}-${s.substring(9, 12)}",
        );
      },
    ),
  };

  static final Map<String, String> _bankCardPrefixes = <String, String>{
    "636214": "بانک آینده",
    "627412": "بانک اقتصاد نوین",
    "627381": "بانک انصار",
    "505785": "بانک ایران زمین",
    "622106": "بانک پارسیان",
    "627884": "بانک پارسیان",
    "502229": "بانک پاسارگاد",
    "639347": "بانک پاسارگاد",
    "627760": "پست بانک ایران",
    "585983": "بانک تجارت",
    "627353": "بانک تجارت",
    "502908": "بانک توسعه تعاون",
    "207177": "بانک توسعه صادرات",
    "627648": "بانک توسعه صادرات",
    "636949": "بانک حکمت ایرانیان",
    "585949": "بانک خاورمیانه",
    "502938": "بانک دی",
    "504172": "بانک رسالت",
    "589463": "بانک رفاه کارگران",
    "621986": "بانک سامان",
    "589210": "بانک سپه",
    "639607": "بانک سرمایه",
    "639346": "بانک سینا",
    "502806": "بانک شهر",
    "504706": "بانک شهر",
    "603769": "بانک صادرات ایران",
    "903769": "بانک صادرات ایران",
    "627961": "بانک صنعت و معدن",
    "639370": "بانک قرض الحسنه مهر",
    "639599": "بانک قوامین",
    "627488": "بانک کارآفرین",
    "603770": "بانک کشاورزی",
    "639217": "بانک کشاورزی",
    "505416": "بانک گردشگری",
    "505426": "بانک گردشگری",
    "636797": "بانک مرکزی ایران",
    "628023": "بانک مسکن",
    "610433": "بانک ملت",
    "991975": "بانک ملت",
    "170019": "بانک ملی ایران",
    "603799": "بانک ملی ایران",
    "606373": "بانک مهر ایران",
    "505801": "موسسه کوثر",
    "606256": "موسسه اعتباری ملل",
    "628157": "موسسه اعتباری توسعه",
    "507677": "موسسه مالی اعتباری نور",
    "585947": "بانک خاورمیانه",
  };

  static final RegExp _mobileRegex = RegExp(r"^(?:[+|0{2}]?98)?0?(\d{3})+(\d{3})+(\d{4})$");
  static final Map<String, OperatorDetail> _operators = <String, OperatorDetail>{
    "910": const OperatorDetail(base: "کشوری", operator: Operator.mci),
    "914": const OperatorDetail(
      base: "آذربایجان غربی",
      provinces: <String>["آذربایجان شرقی", "اردبیل", "اصفهان"],
      operator: Operator.mci,
    ),
    "911": const OperatorDetail(
      base: "مازندران",
      provinces: <String>["گلستان", "گیلان"],
      operator: Operator.mci,
    ),
    "912": const OperatorDetail(
      base: "تهران",
      provinces: <String>["البرز", "زنجان", "سمنان", "قزوین", "قم", "برخی از شهرستان های استان مرکزی"],
      type: SimCardType.permanent,
      operator: Operator.mci,
    ),
    "913": const OperatorDetail(
      base: "اصفهان",
      provinces: <String>["یزد", "چهارمحال و بختیاری", "کرمان"],
      operator: Operator.mci,
    ),
    "915": const OperatorDetail(
      base: "خراسان رضوی",
      provinces: <String>["خراسان شمالی", "خراسان جنوبی", "سیستان و بلوچستان"],
      operator: Operator.mci,
    ),
    "916": const OperatorDetail(
      base: "خوزستان",
      provinces: <String>["لرستان", "فارس", "اصفهان"],
      operator: Operator.mci,
    ),
    "917": const OperatorDetail(
      base: "فارس",
      provinces: <String>["بوشهر", "کهگیلویه و بویر احمد", "هرمزگان"],
      operator: Operator.mci,
    ),
    "918": const OperatorDetail(
      base: "کرمانشاه",
      provinces: <String>["کردستان", "ایلام", "همدان"],
      operator: Operator.mci,
    ),
    "919": const OperatorDetail(
      base: "تهران",
      provinces: <String>["البرز", "سمنان", "قم", "قزوین", "زنجان"],
      type: SimCardType.credit,
      operator: Operator.mci,
    ),
    "990": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.mci),
    "991": const OperatorDetail(base: "کشوری", operator: Operator.mci),
    "992": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.mci),
    "993": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.mci),
    "994": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.mci),
    "995": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.mci),
    "996": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.mci),
    "932": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.taliya),
    "920": const OperatorDetail(base: "کشوری", type: SimCardType.permanent, operator: Operator.rightTel),
    "921": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.rightTel),
    "922": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.rightTel),
    "900": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "930": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "933": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "935": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "936": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "937": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "938": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "939": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "901": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "902": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "903": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "905": const OperatorDetail(base: "کشوری", operator: Operator.irancell),
    "904": const OperatorDetail(base: "کشوری", model: "سیم‌کارت کودک", type: SimCardType.credit, operator: Operator.irancell),
    "941": const OperatorDetail(base: "کشوری", model: "TD-LTE", type: SimCardType.credit, operator: Operator.irancell),
    "998": const OperatorDetail(base: "کشوری", type: SimCardType.credit, operator: Operator.shatelMobile),
    "999": const OperatorDetail(base: "کشوری", operator: Operator.samanTel),
  };

  static bool isPersian(String input, {bool complex = false}) {
    if (input.isEmpty) return false;
    final RegExp pattern = RegExp('["\'-+()؟\\s.]');
    final String rawText = input.replaceAll(pattern, "");
    final String faRegExp = complex ? _faComplexText : _faText;
    return RegExp("^[$faRegExp]+\$").hasMatch(rawText);
  }

  static bool hasPersian(String input, {bool complex = false}) {
    final String faRegExp = complex ? _faComplexText : _faText;
    return RegExp("[$faRegExp]").hasMatch(input);
  }

  static String trim(String input) => input.trim();

  static String replaceMapValue(String input, Map<String, String> mapPattern) => input.replaceAllMapped(
    RegExp(mapPattern.keys.join("|"), caseSensitive: false),
    (Match match) => mapPattern[match.group(0)]!,
  );

  static bool validateNationalCode(String? input) {
    if (input == null) return false;
    final String code = input.trim();
    if (code.length != 10 || RegExp("[^0-9]").hasMatch(code)) return false;
    if (RegExp(r"^(\d)\1{9}$").hasMatch(code)) return false;
    final List<int> digits = code.split("").map(int.parse).toList();
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i);
    }
    final int remainder = sum % 11;
    final int expected = remainder < 2 ? remainder : 11 - remainder;
    return expected == digits[9];
  }

  static bool validateTaxMemoryId(String? input) {
    if (input == null) return false;
    final String code = input.trim().toUpperCase();
    if (code.length != 6) return false;
    return RegExp(r"^[A-Z0-9]{6}$").hasMatch(code);
  }

  static bool validateCardNumber(String cardNumber) {
    if (!RegExp(r"^\d{16}$").hasMatch(cardNumber) || int.parse(cardNumber.substring(1, 11)) == 0) return false;
    int sum = 0;
    for (int i = 0; i < 16; i++) {
      final int multiplier = i.isEven ? 2 : 1;
      final int subDigit = int.parse(cardNumber[i]) * multiplier;
      sum += subDigit > 9 ? subDigit - 9 : subDigit;
    }
    return sum % 10 == 0;
  }

  static String? getBankNameFromCard(String cardNumber) {
    if (cardNumber.length != 16) return null;
    return _bankCardPrefixes[cardNumber.substring(0, 6)];
  }

  static bool isShebaValid(String sheba) {
    if (sheba.length != 26 || !RegExp("IR[0-9]{24}").hasMatch(sheba)) return false;
    final int d1 = sheba.codeUnitAt(0) - 65 + 10;
    final int d2 = sheba.codeUnitAt(1) - 65 + 10;
    final String iban = "${sheba.substring(4)}$d1$d2${sheba.substring(2, 4)}";
    String remainder = iban;
    while (remainder.length > 2) {
      final String block = remainder.length >= 9 ? remainder.substring(0, 9) : remainder;
      remainder = "${int.parse(block) % 97}${remainder.substring(block.length)}";
    }
    return int.parse(remainder) % 97 == 1;
  }

  static BankInfo? getBankFromSheba(String sheba) {
    if (!isShebaValid(sheba)) return null;
    final String? bankCode = RegExp("IR[0-9]{2}([0-9]{3})").firstMatch(sheba)?[1];
    final BankInfo? bank = _bankInfo[bankCode];
    if (bank == null) return null;
    if (bank.isAccountNumberAvailable && bank.process != null) {
      final AccountNumberModel data = bank.process!(sheba);
      return bank.copyWith(
        accountNumber: data.accountNumber,
        formattedAccountNumber: data.formattedAccountNumber,
      );
    }
    return bank;
  }

  static String? numberToWords(num number, {bool ordinal = false}) {
    if (number == 0) return "صفر";
    final String result = _convertNumberToWords(number.abs().toInt());
    if (result.isEmpty) return null;
    return trim((number < 0 ? "منفی " : "") + result);
  }

  static String? wordsToNumberString(String words, {DigitLocale digits = DigitLocale.en, bool addComma = false}) {
    final int? number = _wordsToNumber(words);
    if (number == null) return null;
    final String result = addComma ? _addCommas(number) : number.toString();
    switch (digits) {
      case DigitLocale.fa:
        return _convertEnToFa(result);
      case DigitLocale.ar:
        return _convertEnToAr(result);
      case DigitLocale.en:
        return result;
    }
  }

  static String convertDigits(String digits, DigitLocale from, DigitLocale to) {
    if (from == to) return digits;
    if (from == DigitLocale.en && to == DigitLocale.fa) return _convertEnToFa(digits);
    if (from == DigitLocale.en && to == DigitLocale.ar) return _convertEnToAr(digits);
    if (from == DigitLocale.fa && to == DigitLocale.en) return _convertFaToEn(digits);
    if (from == DigitLocale.ar && to == DigitLocale.fa) return _convertArToFa(digits);
    if (from == DigitLocale.ar && to == DigitLocale.en) return _convertArToEn(digits);
    return _convertFaToEn(_convertArToFa(digits));
  }

  static OperatorDetail? getPhoneDetails(String phoneNumber) {
    if (!_mobileRegex.hasMatch(phoneNumber)) return null;
    final String? prefix = _mobileRegex.firstMatch(phoneNumber)?.group(1);
    return prefix != null ? _operators[prefix] : null;
  }

  static String? formatPhoneNumber(String phoneNumber) {
    if (!_mobileRegex.hasMatch(phoneNumber)) return null;
    final RegExpMatch match = _mobileRegex.firstMatch(phoneNumber)!;
    return "+98${match.group(1)}-${match.group(2)}-${match.group(3)}";
  }

  static String? formatCardNumber(String cardNumber) {
    if (!validateCardNumber(cardNumber)) return null;
    return "${cardNumber.substring(0, 4)}-${cardNumber.substring(4, 8)}-${cardNumber.substring(8, 12)}-${cardNumber.substring(12)}";
  }

  static String _addCommas(num number) {
    final String str = number.toString();
    final List<String> parts = str.split(".");
    final String integer = parts[0].replaceAllMapped(
      _thousandsGroup,
      (Match m) => "${m[1]},",
    );
    return parts.length > 1 ? "$integer.${parts[1]}" : integer;
  }

  static String _convertEnToFa(String digits) => digits.replaceAllMapped(_asciiDigits, (Match m) => _faNumber[int.parse(m.group(0)!)]);

  static String _convertEnToAr(String digits) => digits.replaceAllMapped(_asciiDigits, (Match m) => _arNumber[int.parse(m.group(0)!)]);

  static String _convertFaToEn(String digits) => digits.replaceAllMapped(_faDigits, (Match m) => _faNumber.indexOf(m.group(0)!).toString());

  static String _convertArToFa(String digits) => digits.replaceAllMapped(_arDigits, (Match m) => _faNumber[_arNumber.indexOf(m.group(0)!)]);

  static String _convertArToEn(String digits) => digits.replaceAllMapped(_arDigits, (Match m) => _arNumber.indexOf(m.group(0)!).toString());

  static String _convertNumberToWords(int number) {
    final List<String> result = <String>[];
    while (number > 0) {
      final String chunk = _numToWord(number % 1000);
      if (chunk.isNotEmpty) result.add(chunk);
      number ~/= 1000;
    }
    for (int i = 0; i < result.length; i++) {
      if (i > 0 && result[i].isNotEmpty) {
        result[i] += " ${<String>["", "هزار", "میلیون", "میلیارد"][i]} و ";
      }
    }
    final String words = result.reversed.join();
    return words.endsWith(" و ") ? words.substring(0, words.length - 3) : words;
  }

  static String _numToWord(int number) {
    if (_numberToWord.containsKey(number)) return _numberToWord[number]!;
    int unit = 100;
    String result = "";
    while (unit > 0) {
      if ((number ~/ unit) * unit != 0) {
        result += "${_numberToWord[(number ~/ unit) * unit]} و ";
        number %= unit;
      }
      unit ~/= 10;
    }
    return result.endsWith(" و ") ? result.substring(0, result.length - 3) : result;
  }

  static int? _wordsToNumber(String words) {
    if (words.isEmpty) return null;
    words = replaceMapValue(
      words.replaceAll(RegExp("مین\$", caseSensitive: false), ""),
      <String, String>{"شیش صد": "ششصد", "شش صد": "ششصد", "هفت صد": "هفتصد", "هشت صد": "هشتصد", "نه صد": "نهصد"},
    );
    final List<String> tokens = words.split(" ").where((String e) => e != "و").toList();
    int sum = 0;
    bool isNegative = false;

    for (final String token in tokens) {
      final String enToken = _convertFaToEn(token);
      if (enToken == "منفی") {
        isNegative = true;
      } else if (_units.containsKey(enToken)) {
        sum += _units[enToken]!;
      } else if (_ten.containsKey(enToken)) {
        sum += _ten[enToken]!;
      } else if (int.tryParse(enToken) != null) {
        sum += int.parse(enToken);
      } else {
        final int? multiplier = <String, int>{
          "هزار": 1000,
          "میلیون": 1000000,
          "بیلیون": 1000000000,
          "میلیارد": 1000000000,
          "تریلیون": 1000000000000,
        }[enToken];
        if (multiplier != null) sum *= multiplier;
      }
    }
    return isNegative ? -sum : sum;
  }
}
