part of "../data.dart";

// Server-side prices used to show the amount on the payment page before each paid action.
class UAppSettingsResponse {
  final List<UChargeInternet> chargeInternet;

  UAppSettingsResponse({
    required this.apiCallCosts,
    required this.chargeInternet,
  });

  factory UAppSettingsResponse.fromMap(Map<String, dynamic> json) => UAppSettingsResponse(
    apiCallCosts: UApiCallCosts.fromMap(json["apiCallCosts"] ?? <String, dynamic>{}),
    chargeInternet: json["chargeInternet"] == null ? <UChargeInternet>[] : List<UChargeInternet>.from(json["chargeInternet"]!.map((dynamic x) => UChargeInternet.fromMap(x))),
  );

  final UApiCallCosts apiCallCosts;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "chargeInternet": List<dynamic>.from(chargeInternet.map((UChargeInternet x) => x.toMap())),
    "apiCallCosts": apiCallCosts.toMap(),
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
  final List<UChargeInternetPreDefinedAmounts> preDefinedAmountsList;

  UChargeInternet({
    required this.operator,
    required this.title,
    required this.logo,
    required this.preDefinedAmountsList,
  });

  factory UChargeInternet.fromJson(String str) => UChargeInternet.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UChargeInternet.fromMap(Map<String, dynamic> json) => UChargeInternet(
    operator: json["operator"],
    title: json["title"],
    logo: json["logo"],
    preDefinedAmountsList: json["preDefinedAmountsList"] == null
        ? <UChargeInternetPreDefinedAmounts>[]
        : List<UChargeInternetPreDefinedAmounts>.from(json["preDefinedAmountsList"]!.map((dynamic x) => UChargeInternetPreDefinedAmounts.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "operator": operator,
    "title": title,
    "logo": logo,
    "preDefinedAmountsList": List<dynamic>.from(preDefinedAmountsList.map((UChargeInternetPreDefinedAmounts x) => x.toMap())),
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
