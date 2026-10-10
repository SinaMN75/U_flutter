part of "../data.dart";

class UAppSettingsResponse {
  final List<UChargeInternet> chargeInternet;
  final double chargeInternetTaxPercent;
  final List<UAppVersionResponse> appVersions;

  UAppSettingsResponse({
    required this.apiCallCosts,
    required this.chargeInternet,
    required this.chargeInternetTaxPercent,
    this.appVersions = const <UAppVersionResponse>[],
  });

  factory UAppSettingsResponse.fromMap(Map<String, dynamic> json) => UAppSettingsResponse(
    apiCallCosts: UApiCallCosts.fromMap(json["apiCallCosts"] ?? <String, dynamic>{}),
    chargeInternet: json["chargeInternet"] == null ? <UChargeInternet>[] : List<UChargeInternet>.from(json["chargeInternet"]!.map((dynamic x) => UChargeInternet.fromMap(x))),
    chargeInternetTaxPercent: (json["chargeInternetTaxPercent"] ?? 0).toString().toDouble(),
    appVersions: json["appVersions"] == null ? <UAppVersionResponse>[] : List<UAppVersionResponse>.from(json["appVersions"]!.map((dynamic x) => UAppVersionResponse.fromMap(x))),
  );

  final UApiCallCosts apiCallCosts;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "chargeInternet": List<dynamic>.from(chargeInternet.map((UChargeInternet x) => x.toMap())),
    "apiCallCosts": apiCallCosts.toMap(),
    "chargeInternetTaxPercent": chargeInternetTaxPercent,
    "appVersions": List<dynamic>.from(appVersions.map((UAppVersionResponse x) => x.toMap())),
  };

  String toJson() => json.encode(toMap());

  factory UAppSettingsResponse.fromJson(String str) => UAppSettingsResponse.fromMap(json.decode(str));
}

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
  final double topupTaxPercent;

  UChargeInternet({
    required this.operator,
    required this.title,
    required this.logo,
    required this.pinAmountsList,
    required this.topupAmountsList,
    this.topupTaxPercent = 0,
  });

  factory UChargeInternet.fromJson(String str) => UChargeInternet.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UChargeInternet.fromMap(Map<String, dynamic> json) => UChargeInternet(
    operator: json["operator"],
    title: json["title"],
    logo: json["logo"],
    pinAmountsList: _amounts(json["pinAmountsList"]),
    topupAmountsList: _amounts(json["topupAmountsList"]),
    topupTaxPercent: (json["topupTaxPercent"] ?? 0).toString().toDouble(),
  );

  static List<UChargeInternetPreDefinedAmounts> _amounts(dynamic list) =>
      list == null ? <UChargeInternetPreDefinedAmounts>[] : List<UChargeInternetPreDefinedAmounts>.from(list.map((dynamic x) => UChargeInternetPreDefinedAmounts.fromMap(x)));

  Map<String, dynamic> toMap() => <String, dynamic>{
    "operator": operator,
    "title": title,
    "logo": logo,
    "pinAmountsList": List<dynamic>.from(pinAmountsList.map((UChargeInternetPreDefinedAmounts x) => x.toMap())),
    "topupAmountsList": List<dynamic>.from(topupAmountsList.map((UChargeInternetPreDefinedAmounts x) => x.toMap())),
    "topupTaxPercent": topupTaxPercent,
  };
}

class UChargeInternetPreDefinedAmounts {
  final String title;
  final double amount;
  final int type;

  UChargeInternetPreDefinedAmounts({
    required this.title,
    required this.amount,
    this.type = 0,
  });

  factory UChargeInternetPreDefinedAmounts.fromJson(String str) => UChargeInternetPreDefinedAmounts.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UChargeInternetPreDefinedAmounts.fromMap(Map<String, dynamic> json) => UChargeInternetPreDefinedAmounts(
    title: json["title"],
    amount: (json["amount"] as num).toDouble(),
    type: json["type"] ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "amount": amount,
    "type": type,
  };
}

class UAppVersionResponse {
  UAppVersionResponse({
    required this.id,
    required this.tags,
    required this.latestBuildNumber,
    required this.minBuildNumber,
    required this.jsonData,
  });

  factory UAppVersionResponse.fromMap(Map<String, dynamic> json) => UAppVersionResponse(
    id: json["id"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    latestBuildNumber: json["latestBuildNumber"] ?? 0,
    minBuildNumber: json["minBuildNumber"] ?? 0,
    jsonData: UAppVersionJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
  );

  final String id;
  final List<int> tags;
  final int latestBuildNumber;
  final int minBuildNumber;
  final UAppVersionJson jsonData;

  TagAppVersion? get platform => TagAppVersion.values.firstWhereOrNull((TagAppVersion t) => tags.contains(t.number));

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "latestBuildNumber": latestBuildNumber,
    "minBuildNumber": minBuildNumber,
    "jsonData": jsonData.toMap(),
  };
}

class UAppVersionJson {
  UAppVersionJson({this.latestVersionName, this.description, this.links = const <UAppVersionLink>[]});

  factory UAppVersionJson.fromMap(Map<String, dynamic> json) => UAppVersionJson(
    latestVersionName: json["latestVersionName"],
    description: json["description"],
    links: json["links"] == null ? <UAppVersionLink>[] : List<UAppVersionLink>.from(json["links"]!.map((dynamic x) => UAppVersionLink.fromMap(x))),
  );

  final String? latestVersionName;
  final String? description;
  final List<UAppVersionLink> links;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "latestVersionName": latestVersionName,
    "description": description,
    "links": List<dynamic>.from(links.map((UAppVersionLink x) => x.toMap())),
  };
}

class UAppVersionLink {
  UAppVersionLink({this.title, this.url, this.iconBase64});

  factory UAppVersionLink.fromMap(Map<String, dynamic> json) => UAppVersionLink(
    title: json["title"],
    url: json["url"],
    iconBase64: json["iconBase64"],
  );

  final String? title;
  final String? url;
  final String? iconBase64;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "url": url,
    "iconBase64": iconBase64,
  };
}
