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
  });

  factory UAppSettingsResponse.fromMap(Map<String, dynamic> json) => UAppSettingsResponse(
    apiCallCosts: UApiCallCosts.fromMap(json["apiCallCosts"] ?? <String, dynamic>{}),
    chargeInternet: json["chargeInternet"] == null ? <UChargeInternet>[] : List<UChargeInternet>.from(json["chargeInternet"]!.map((dynamic x) => UChargeInternet.fromMap(x))),
    chargeInternetTaxPercent: (json["chargeInternetTaxPercent"] ?? 0).toString().toDouble(),
  );

  final UApiCallCosts apiCallCosts;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "chargeInternet": List<dynamic>.from(chargeInternet.map((UChargeInternet x) => x.toMap())),
    "apiCallCosts": apiCallCosts.toMap(),
    "chargeInternetTaxPercent": chargeInternetTaxPercent,
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
