part of "../data.dart";

// Server-side prices used to show the amount on the payment page before each paid action.
class UAppSettingsResponse {
  final List<UChargeInternet> chargeInternet;

  // Percent added to every sim charge nominal price; the server sends this amount to the operator and debits it from the wallet.
  final double chargeInternetTaxPercent;

  UAppSettingsResponse({
    required this.apiCallCosts,
    required this.chargeInternet,
    required this.chargeInternetTaxPercent,
    required this.features,
  });

  factory UAppSettingsResponse.fromMap(Map<String, dynamic> json) => UAppSettingsResponse(
    apiCallCosts: UApiCallCosts.fromMap(json["apiCallCosts"] ?? <String, dynamic>{}),
    chargeInternet: json["chargeInternet"] == null ? <UChargeInternet>[] : List<UChargeInternet>.from(json["chargeInternet"]!.map((dynamic x) => UChargeInternet.fromMap(x))),
    chargeInternetTaxPercent: (json["chargeInternetTaxPercent"] ?? 0).toString().toDouble(),
    features: UFeatures.fromMap(json["features"] ?? <String, dynamic>{}),
  );

  final UApiCallCosts apiCallCosts;

  final UFeatures features;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "chargeInternet": List<dynamic>.from(chargeInternet.map((UChargeInternet x) => x.toMap())),
    "apiCallCosts": apiCallCosts.toMap(),
    "chargeInternetTaxPercent": chargeInternetTaxPercent,
    "features": features.toMap(),
  };

  String toJson() => json.encode(toMap());

  factory UAppSettingsResponse.fromJson(String str) => UAppSettingsResponse.fromMap(json.decode(str));
}

// Price (in rial) of each vehicle / inquiry service, mirroring the backend ApiCallCosts.
class UApiCallCosts {
  UApiCallCosts({
    required this.mobileAndNationalCodeVerification,
    required this.zipCodeToAddressDetail,
    required this.vehicleViolationsDetail,
    required this.drivingLicenceStatus,
    required this.freewayToll,
    required this.licencePlateDetail,
    required this.drivingLicenceNegativePoint,
    required this.iBanToBankAccountDetail,
  });

  factory UApiCallCosts.fromMap(Map<String, dynamic> json) => UApiCallCosts(
    mobileAndNationalCodeVerification: (json["mobileAndNationalCodeVerification"] ?? 0).toString().toDouble(),
    zipCodeToAddressDetail: (json["zipCodeToAddressDetail"] ?? 0).toString().toDouble(),
    vehicleViolationsDetail: (json["vehicleViolationsDetail"] ?? 0).toString().toDouble(),
    drivingLicenceStatus: (json["drivingLicenceStatus"] ?? 0).toString().toDouble(),
    freewayToll: (json["freewayToll"] ?? 0).toString().toDouble(),
    licencePlateDetail: (json["licencePlateDetail"] ?? 0).toString().toDouble(),
    drivingLicenceNegativePoint: (json["drivingLicenceNegativePoint"] ?? 0).toString().toDouble(),
    iBanToBankAccountDetail: (json["iBanToBankAccountDetail"] ?? 0).toString().toDouble(),
  );

  final double mobileAndNationalCodeVerification;
  final double zipCodeToAddressDetail;
  final double vehicleViolationsDetail;
  final double drivingLicenceStatus;
  final double freewayToll;
  final double licencePlateDetail;
  final double drivingLicenceNegativePoint;
  final double iBanToBankAccountDetail;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "mobileAndNationalCodeVerification": mobileAndNationalCodeVerification,
    "zipCodeToAddressDetail": zipCodeToAddressDetail,
    "vehicleViolationsDetail": vehicleViolationsDetail,
    "drivingLicenceStatus": drivingLicenceStatus,
    "freewayToll": freewayToll,
    "licencePlateDetail": licencePlateDetail,
    "drivingLicenceNegativePoint": drivingLicenceNegativePoint,
    "iBanToBankAccountDetail": iBanToBankAccountDetail,
  };

  String toJson() => json.encode(toMap());

  factory UApiCallCosts.fromJson(String str) => UApiCallCosts.fromMap(json.decode(str));
}

class UChargeInternet {
  final int operator;
  final String title;
  final String logo;
  final List<UChargeInternetPreDefinedAmounts> pinAmountsList;
  final List<UChargeInternetPreDefinedAmounts> topupAmountsList;

  UChargeInternet({
    required this.operator,
    required this.title,
    required this.logo,
    required this.pinAmountsList,
    required this.topupAmountsList,
  });

  factory UChargeInternet.fromJson(String str) => UChargeInternet.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UChargeInternet.fromMap(Map<String, dynamic> json) => UChargeInternet(
    operator: json["operator"],
    title: json["title"],
    logo: json["logo"],
    pinAmountsList: _amounts(json["pinAmountsList"]),
    topupAmountsList: _amounts(json["topupAmountsList"]),
  );

  static List<UChargeInternetPreDefinedAmounts> _amounts(dynamic list) =>
      list == null ? <UChargeInternetPreDefinedAmounts>[] : List<UChargeInternetPreDefinedAmounts>.from(list.map((dynamic x) => UChargeInternetPreDefinedAmounts.fromMap(x)));

  Map<String, dynamic> toMap() => <String, dynamic>{
    "operator": operator,
    "title": title,
    "logo": logo,
    "pinAmountsList": List<dynamic>.from(pinAmountsList.map((UChargeInternetPreDefinedAmounts x) => x.toMap())),
    "topupAmountsList": List<dynamic>.from(topupAmountsList.map((UChargeInternetPreDefinedAmounts x) => x.toMap())),
  };
}

class UChargeInternetPreDefinedAmounts {
  final String title;
  final double amount;

  UChargeInternetPreDefinedAmounts({
    required this.title,
    required this.amount,
  });

  factory UChargeInternetPreDefinedAmounts.fromJson(String str) => UChargeInternetPreDefinedAmounts.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UChargeInternetPreDefinedAmounts.fromMap(Map<String, dynamic> json) => UChargeInternetPreDefinedAmounts(
    title: json["title"],
    amount: (json["amount"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "amount": amount,
  };
}

// Each flag mirrors AppSettings.Features on the server; false means the feature is switched off.
class UFeatures {
  UFeatures({
    this.gold = true,
    this.bill = true,
    this.simCharge = true,
    this.internet = true,
    this.vehicleServices = true,
    this.merchant = true,
    this.moadi = true,
    this.cardToCard = true,
    this.charity = true,
    this.insurance = true,
    this.loan = true,
    this.sayadCheck = true,
    this.creditValidation = true,
  });

  factory UFeatures.fromMap(Map<String, dynamic> json) => UFeatures(
    gold: json["gold"] ?? true,
    bill: json["bill"] ?? true,
    simCharge: json["simCharge"] ?? true,
    internet: json["internet"] ?? true,
    vehicleServices: json["vehicleServices"] ?? true,
    merchant: json["merchant"] ?? true,
    moadi: json["moadi"] ?? true,
    cardToCard: json["cardToCard"] ?? true,
    charity: json["charity"] ?? true,
    insurance: json["insurance"] ?? true,
    loan: json["loan"] ?? true,
    sayadCheck: json["sayadCheck"] ?? true,
    creditValidation: json["creditValidation"] ?? true,
  );

  final bool gold;
  final bool bill;
  final bool simCharge;
  final bool internet;
  final bool vehicleServices;
  final bool merchant;
  final bool moadi;
  final bool cardToCard;
  final bool charity;
  final bool insurance;
  final bool loan;
  final bool sayadCheck;
  final bool creditValidation;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "gold": gold,
    "bill": bill,
    "simCharge": simCharge,
    "internet": internet,
    "vehicleServices": vehicleServices,
    "merchant": merchant,
    "moadi": moadi,
    "cardToCard": cardToCard,
    "charity": charity,
    "insurance": insurance,
    "loan": loan,
    "sayadCheck": sayadCheck,
    "creditValidation": creditValidation,
  };
}
