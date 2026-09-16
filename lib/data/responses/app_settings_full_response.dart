part of "../data.dart";

// Full, editable mirror of the backend AppSettings for the admin config editor; the server replaces its settings wholesale on save.
class UAppSettings {
  UAppSettings({
    required this.baseUrl,
    required this.apiKey,
    required this.test,
    required this.connectionServer,
    required this.jwt,
    required this.middleware,
    required this.smsPanel,
    required this.itHub,
    required this.mobtakeran,
    required this.basicSettings,
    required this.ipg,
    required this.avreen,
    required this.pnApiKey,
    required this.cors,
    required this.namat,
    required this.gold,
    required this.inquiryCacheDurations,
    required this.apiCallCosts,
    required this.chargeInternet,
    required this.chargeInternetTaxPercent,
    required this.users,
  });

  factory UAppSettings.fromMap(Map<String, dynamic> j) => UAppSettings(
    baseUrl: j["baseUrl"] ?? "",
    apiKey: j["apiKey"] ?? "",
    test: j["test"] ?? false,
    connectionServer: (j["connectionStrings"] ?? <String, dynamic>{})["server"] ?? "",
    jwt: USettingsJwt.fromMap(j["jwt"] ?? <String, dynamic>{}),
    middleware: USettingsMiddleware.fromMap(j["middleware"] ?? <String, dynamic>{}),
    smsPanel: USettingsSms.fromMap(j["smsPanel"] ?? <String, dynamic>{}),
    itHub: USettingsItHub.fromMap(j["itHub"] ?? <String, dynamic>{}),
    mobtakeran: USettingsMobtakeran.fromMap(j["mobtakeran"] ?? <String, dynamic>{}),
    basicSettings: USettingsBasic.fromMap(j["basicSettings"] ?? <String, dynamic>{}),
    ipg: USettingsIpg.fromMap(j["ipg"] ?? <String, dynamic>{}),
    avreen: USettingsAvreen.fromMap(j["avreen"] ?? <String, dynamic>{}),
    pnApiKey: (j["pn"] ?? <String, dynamic>{})["apiKey"] ?? "",
    cors: USettingsCors.fromMap(j["cors"] ?? <String, dynamic>{}),
    namat: USettingsNamat.fromMap(j["namat"] ?? <String, dynamic>{}),
    gold: USettingsGold.fromMap(j["gold"] ?? <String, dynamic>{}),
    inquiryCacheDurations: USettingsInquiryCacheDurations.fromMap(j["inquiryCacheDurations"] ?? <String, dynamic>{}),
    apiCallCosts: USettingsCosts.fromMap(j["apiCallCosts"] ?? <String, dynamic>{}),
    chargeInternet: List<USettingsChargeInternet>.from((j["chargeInternet"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => USettingsChargeInternet.fromMap(x))),
    chargeInternetTaxPercent: double.tryParse("${j["chargeInternetTaxPercent"] ?? 0}") ?? 0,
    users: j["users"],
  );

  String baseUrl;
  String apiKey;
  bool test;
  String connectionServer;
  USettingsJwt jwt;
  USettingsMiddleware middleware;
  USettingsSms smsPanel;
  USettingsItHub itHub;
  USettingsMobtakeran mobtakeran;
  USettingsBasic basicSettings;
  USettingsIpg ipg;
  USettingsAvreen avreen;
  String pnApiKey;
  USettingsCors cors;
  USettingsNamat namat;
  USettingsGold gold;
  USettingsInquiryCacheDurations inquiryCacheDurations;
  USettingsCosts apiCallCosts;
  List<USettingsChargeInternet> chargeInternet;
  double chargeInternetTaxPercent;

  // Full AppSettings.Users blob, passed through untouched so the server can replace Core.App wholesale.
  dynamic users;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "baseUrl": baseUrl,
    "apiKey": apiKey,
    "test": test,
    "connectionStrings": <String, dynamic>{"server": connectionServer},
    "jwt": jwt.toMap(),
    "middleware": middleware.toMap(),
    "smsPanel": smsPanel.toMap(),
    "itHub": itHub.toMap(),
    "mobtakeran": mobtakeran.toMap(),
    "basicSettings": basicSettings.toMap(),
    "ipg": ipg.toMap(),
    "avreen": avreen.toMap(),
    "pn": <String, dynamic>{"apiKey": pnApiKey},
    "cors": cors.toMap(),
    "namat": namat.toMap(),
    "gold": gold.toMap(),
    "inquiryCacheDurations": inquiryCacheDurations.toMap(),
    "apiCallCosts": apiCallCosts.toMap(),
    "chargeInternet": chargeInternet.map((USettingsChargeInternet e) => e.toMap()).toList(),
    "chargeInternetTaxPercent": chargeInternetTaxPercent,
    "users": users,
  };

  String toJson() => json.encode(toMap());

  factory UAppSettings.fromJson(String str) => UAppSettings.fromMap(json.decode(str));
}

class USettingsJwt {
  USettingsJwt({required this.key, required this.issuer, required this.audience, required this.expires, this.refreshTokenExpiresInDays = 7});

  factory USettingsJwt.fromMap(Map<String, dynamic> j) => USettingsJwt(
    key: j["key"] ?? "",
    issuer: j["issuer"] ?? "",
    audience: j["audience"] ?? "",
    expires: int.tryParse("${j["expires"] ?? 0}") ?? 0,
    refreshTokenExpiresInDays: int.tryParse("${j["refreshTokenExpiresInDays"] ?? 7}") ?? 7,
  );

  String key;
  String issuer;
  String audience;
  int expires;
  int refreshTokenExpiresInDays;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "key": key,
    "issuer": issuer,
    "audience": audience,
    "expires": expires,
    "refreshTokenExpiresInDays": refreshTokenExpiresInDays,
  };

  String toJson() => json.encode(toMap());

  factory USettingsJwt.fromJson(String str) => USettingsJwt.fromMap(json.decode(str));
}

class USettingsCors {
  USettingsCors({required this.allowedOrigins});

  factory USettingsCors.fromMap(Map<String, dynamic> j) => USettingsCors(
    allowedOrigins: List<String>.from((j["allowedOrigins"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x.toString())),
  );

  List<String> allowedOrigins;

  Map<String, dynamic> toMap() => <String, dynamic>{"allowedOrigins": allowedOrigins};

  String toJson() => json.encode(toMap());

  factory USettingsCors.fromJson(String str) => USettingsCors.fromMap(json.decode(str));
}

class USettingsNamat {
  USettingsNamat({required this.baseUrl, required this.branchToken});

  factory USettingsNamat.fromMap(Map<String, dynamic> j) => USettingsNamat(baseUrl: j["baseUrl"] ?? "", branchToken: j["branchToken"] ?? "");

  String baseUrl;
  String branchToken;

  Map<String, dynamic> toMap() => <String, dynamic>{"baseUrl": baseUrl, "branchToken": branchToken};

  String toJson() => json.encode(toMap());

  factory USettingsNamat.fromJson(String str) => USettingsNamat.fromMap(json.decode(str));
}

class USettingsGold {
  USettingsGold({required this.baseUrl, required this.clientKey, required this.clientSecret, required this.scopes, this.apiToken});

  factory USettingsGold.fromMap(Map<String, dynamic> j) => USettingsGold(
    baseUrl: j["baseUrl"] ?? "",
    clientKey: j["clientKey"] ?? "",
    clientSecret: j["clientSecret"] ?? "",
    scopes: List<String>.from((j["scopes"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x.toString())),
    apiToken: j["apiToken"],
  );

  String baseUrl;
  String clientKey;
  String clientSecret;
  List<String> scopes;
  String? apiToken;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "baseUrl": baseUrl,
    "clientKey": clientKey,
    "clientSecret": clientSecret,
    "scopes": scopes,
    "apiToken": apiToken,
  };

  String toJson() => json.encode(toMap());

  factory USettingsGold.fromJson(String str) => USettingsGold.fromMap(json.decode(str));
}

class USettingsInquiryCacheDurations {
  USettingsInquiryCacheDurations({
    required this.mobileAndNationalCodeVerification,
    required this.zipCodeToAddressDetail,
    required this.vehicleViolationsDetail,
    required this.drivingLicenceStatus,
    required this.freewayToll,
    required this.licencePlateDetail,
    required this.drivingLicenceNegativePoint,
    required this.iBanToBankAccountDetail,
  });

  factory USettingsInquiryCacheDurations.fromMap(Map<String, dynamic> j) => USettingsInquiryCacheDurations(
    mobileAndNationalCodeVerification: _i(j["mobileAndNationalCodeVerification"]),
    zipCodeToAddressDetail: _i(j["zipCodeToAddressDetail"]),
    vehicleViolationsDetail: _i(j["vehicleViolationsDetail"]),
    drivingLicenceStatus: _i(j["drivingLicenceStatus"]),
    freewayToll: _i(j["freewayToll"]),
    licencePlateDetail: _i(j["licencePlateDetail"]),
    drivingLicenceNegativePoint: _i(j["drivingLicenceNegativePoint"]),
    iBanToBankAccountDetail: _i(j["iBanToBankAccountDetail"]),
  );

  int mobileAndNationalCodeVerification;
  int zipCodeToAddressDetail;
  int vehicleViolationsDetail;
  int drivingLicenceStatus;
  int freewayToll;
  int licencePlateDetail;
  int drivingLicenceNegativePoint;
  int iBanToBankAccountDetail;

  static int _i(dynamic v) => int.tryParse("${v ?? 0}") ?? 0;

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

  factory USettingsInquiryCacheDurations.fromJson(String str) => USettingsInquiryCacheDurations.fromMap(json.decode(str));
}

class USettingsMiddleware {
  USettingsMiddleware({required this.requireApiKey, required this.requireRefreshToken, required this.log, required this.logSuccess, required this.logHeaders});

  factory USettingsMiddleware.fromMap(Map<String, dynamic> j) => USettingsMiddleware(
    requireApiKey: j["requireApiKey"] ?? false,
    requireRefreshToken: j["requireRefreshToken"] ?? false,
    log: j["log"] ?? false,
    logSuccess: j["logSuccess"] ?? false,
    logHeaders: j["logHeaders"] ?? false,
  );

  bool requireApiKey;
  bool requireRefreshToken;
  bool log;
  bool logSuccess;
  bool logHeaders;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "requireApiKey": requireApiKey,
    "requireRefreshToken": requireRefreshToken,
    "log": log,
    "logSuccess": logSuccess,
    "logHeaders": logHeaders,
  };

  String toJson() => json.encode(toMap());

  factory USettingsMiddleware.fromJson(String str) => USettingsMiddleware.fromMap(json.decode(str));
}

class USettingsSms {
  USettingsSms({required this.tag, required this.loginOtpPattern, required this.supportPasswordOtp, required this.apiKey});

  factory USettingsSms.fromMap(Map<String, dynamic> j) => USettingsSms(
    tag: TagSmsPanel.values.firstWhere((TagSmsPanel e) => e.number == j["tag"], orElse: () => TagSmsPanel.kavenegar),
    loginOtpPattern: j["loginOtpPattern"] ?? "",
    supportPasswordOtp: j["supportPasswordOtp"] ?? "",
    apiKey: j["apiKey"] ?? "",
  );

  TagSmsPanel tag;
  String loginOtpPattern;
  String supportPasswordOtp;
  String apiKey;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tag": tag.number,
    "loginOtpPattern": loginOtpPattern,
    "supportPasswordOtp": supportPasswordOtp,
    "apiKey": apiKey,
  };

  String toJson() => json.encode(toMap());

  factory USettingsSms.fromJson(String str) => USettingsSms.fromMap(json.decode(str));
}

class USettingsItHub {
  USettingsItHub({required this.clientId, required this.clientSecret, required this.userName, required this.password});

  factory USettingsItHub.fromMap(Map<String, dynamic> j) => USettingsItHub(
    clientId: j["clientId"] ?? "",
    clientSecret: j["clientSecret"] ?? "",
    userName: j["userName"] ?? "",
    password: j["password"] ?? "",
  );

  String clientId;
  String clientSecret;
  String userName;
  String password;

  Map<String, dynamic> toMap() => <String, dynamic>{"clientId": clientId, "clientSecret": clientSecret, "userName": userName, "password": password};

  String toJson() => json.encode(toMap());

  factory USettingsItHub.fromJson(String str) => USettingsItHub.fromMap(json.decode(str));
}

class USettingsMobtakeran {
  USettingsMobtakeran({required this.userName, required this.password, required this.apiKey, required this.baseUrl});

  factory USettingsMobtakeran.fromMap(Map<String, dynamic> j) => USettingsMobtakeran(
    userName: j["userName"] ?? "",
    password: j["password"] ?? "",
    apiKey: j["apiKey"] ?? "",
    baseUrl: j["baseUrl"] ?? "",
  );

  String userName;
  String password;
  String apiKey;
  String baseUrl;

  Map<String, dynamic> toMap() => <String, dynamic>{"userName": userName, "password": password, "apiKey": apiKey, "baseUrl": baseUrl};

  String toJson() => json.encode(toMap());

  factory USettingsMobtakeran.fromJson(String str) => USettingsMobtakeran.fromMap(json.decode(str));
}

class USettingsBasic {
  USettingsBasic({required this.defaultVerificationKey, required this.verificationCodeLenght});

  factory USettingsBasic.fromMap(Map<String, dynamic> j) => USettingsBasic(
    defaultVerificationKey: j["defaultVerificationKey"] ?? "",
    verificationCodeLenght: (j["verificationCodeLenght"] ?? 0) is int ? (j["verificationCodeLenght"] ?? 0) : int.tryParse("${j["verificationCodeLenght"]}") ?? 0,
  );

  String defaultVerificationKey;
  int verificationCodeLenght;

  Map<String, dynamic> toMap() => <String, dynamic>{"defaultVerificationKey": defaultVerificationKey, "verificationCodeLenght": verificationCodeLenght};

  String toJson() => json.encode(toMap());

  factory USettingsBasic.fromJson(String str) => USettingsBasic.fromMap(json.decode(str));
}

class USettingsIpg {
  USettingsIpg({required this.ipgUserId, required this.tag, required this.title, required this.token, required this.callBackUrl});

  factory USettingsIpg.fromMap(Map<String, dynamic> j) => USettingsIpg(
    ipgUserId: j["ipgUserId"] ?? "",
    tag: TagIpg.values.firstWhere((TagIpg e) => e.number == j["tag"], orElse: () => TagIpg.values.first),
    title: j["title"] ?? "",
    token: j["token"] ?? "",
    callBackUrl: j["callBackUrl"] ?? "",
  );

  String ipgUserId;
  TagIpg tag;
  String title;
  String token;
  String callBackUrl;

  Map<String, dynamic> toMap() => <String, dynamic>{"ipgUserId": ipgUserId, "tag": tag.number, "title": title, "token": token, "callBackUrl": callBackUrl};

  String toJson() => json.encode(toMap());

  factory USettingsIpg.fromJson(String str) => USettingsIpg.fromMap(json.decode(str));
}

class USettingsAvreen {
  USettingsAvreen({required this.authHeader, required this.baseUrl});

  factory USettingsAvreen.fromMap(Map<String, dynamic> j) => USettingsAvreen(authHeader: j["authHeader"] ?? "", baseUrl: j["baseUrl"] ?? "");

  String authHeader;
  String baseUrl;

  Map<String, dynamic> toMap() => <String, dynamic>{"authHeader": authHeader, "baseUrl": baseUrl};

  String toJson() => json.encode(toMap());

  factory USettingsAvreen.fromJson(String str) => USettingsAvreen.fromMap(json.decode(str));
}

class USettingsCosts {
  USettingsCosts({
    required this.mobileAndNationalCodeVerification,
    required this.zipCodeToAddressDetail,
    required this.vehicleViolationsDetail,
    required this.drivingLicenceStatus,
    required this.freewayToll,
    required this.licencePlateDetail,
    required this.drivingLicenceNegativePoint,
    required this.iBanToBankAccountDetail,
  });

  factory USettingsCosts.fromMap(Map<String, dynamic> j) => USettingsCosts(
    mobileAndNationalCodeVerification: _d(j["mobileAndNationalCodeVerification"]),
    zipCodeToAddressDetail: _d(j["zipCodeToAddressDetail"]),
    vehicleViolationsDetail: _d(j["vehicleViolationsDetail"]),
    drivingLicenceStatus: _d(j["drivingLicenceStatus"]),
    freewayToll: _d(j["freewayToll"]),
    licencePlateDetail: _d(j["licencePlateDetail"]),
    drivingLicenceNegativePoint: _d(j["drivingLicenceNegativePoint"]),
    iBanToBankAccountDetail: _d(j["iBanToBankAccountDetail"]),
  );

  double mobileAndNationalCodeVerification;
  double zipCodeToAddressDetail;
  double vehicleViolationsDetail;
  double drivingLicenceStatus;
  double freewayToll;
  double licencePlateDetail;
  double drivingLicenceNegativePoint;
  double iBanToBankAccountDetail;

  static double _d(dynamic v) => double.tryParse("${v ?? 0}") ?? 0;

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

  factory USettingsCosts.fromJson(String str) => USettingsCosts.fromMap(json.decode(str));
}

class USettingsChargeInternet {
  USettingsChargeInternet({required this.operator, required this.title, required this.logo, required this.pinAmountsList, required this.topupAmountsList});

  factory USettingsChargeInternet.fromMap(Map<String, dynamic> j) => USettingsChargeInternet(
    operator: TagSimOperator.values.firstWhere((TagSimOperator e) => e.number == j["operator"], orElse: () => TagSimOperator.values.first),
    title: j["title"] ?? "",
    logo: j["logo"] ?? "",
    pinAmountsList: _amounts(j["pinAmountsList"]),
    topupAmountsList: _amounts(j["topupAmountsList"]),
  );

  static List<USettingsChargeAmount> _amounts(dynamic list) => List<USettingsChargeAmount>.from((list as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => USettingsChargeAmount.fromMap(x)));

  TagSimOperator operator;
  String title;
  String logo;
  List<USettingsChargeAmount> pinAmountsList;
  List<USettingsChargeAmount> topupAmountsList;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "operator": operator.number,
    "title": title,
    "logo": logo,
    "pinAmountsList": pinAmountsList.map((USettingsChargeAmount e) => e.toMap()).toList(),
    "topupAmountsList": topupAmountsList.map((USettingsChargeAmount e) => e.toMap()).toList(),
  };

  String toJson() => json.encode(toMap());

  factory USettingsChargeInternet.fromJson(String str) => USettingsChargeInternet.fromMap(json.decode(str));
}

class USettingsChargeAmount {
  USettingsChargeAmount({required this.title, required this.amount});

  factory USettingsChargeAmount.fromMap(Map<String, dynamic> j) => USettingsChargeAmount(
    title: j["title"] ?? "",
    amount: double.tryParse("${j["amount"] ?? 0}") ?? 0,
  );

  String title;
  double amount;

  Map<String, dynamic> toMap() => <String, dynamic>{"title": title, "amount": amount};

  String toJson() => json.encode(toMap());

  factory USettingsChargeAmount.fromJson(String str) => USettingsChargeAmount.fromMap(json.decode(str));
}
