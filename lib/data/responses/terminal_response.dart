part of "../data.dart";

class UMerchantResponse {
  final String id;
  final DateTime createdAt;
  final UMerchantJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String zipCode;
  final String cityCode;
  final String phoneNumber;
  final String title;
  final String landline;
  final String nationalCode;
  final String? bankAccountId;
  final String mcc;
  final String? merchantId;
  final String? insId;
  final String userId;
  final UUserResponse? user;
  final List<UTerminalResponse>? terminals;
  final List<String> adminUserIds;

  UMerchantResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.zipCode,
    required this.cityCode,
    required this.phoneNumber,
    required this.title,
    required this.landline,
    required this.nationalCode,
    required this.mcc,
    required this.userId,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
    this.bankAccountId,
    this.merchantId,
    this.insId,
    this.user,
    this.terminals,
  });

  factory UMerchantResponse.fromJson(String str) => UMerchantResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMerchantResponse.fromMap(Map<String, dynamic> json) => UMerchantResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UMerchantJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    zipCode: json["zipCode"] as String,
    cityCode: json["cityCode"] as String,
    phoneNumber: json["phoneNumber"] as String,
    title: json["title"] as String,
    landline: json["landline"] as String,
    nationalCode: json["nationalCode"] as String,
    bankAccountId: json["bankAccountId"],
    mcc: json["mcc"] as String,
    merchantId: json["merchantId"],
    insId: json["insId"],
    userId: json["userId"] as String,
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    terminals: json["terminals"] == null ? <UTerminalResponse>[] : List<UTerminalResponse>.from(json["terminals"]!.map((dynamic x) => UTerminalResponse.fromMap(x))),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<int>.from(tags.map((int x) => x)),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "zipCode": zipCode,
    "cityCode": cityCode,
    "phoneNumber": phoneNumber,
    "title": title,
    "landline": landline,
    "nationalCode": nationalCode,
    "bankAccountId": bankAccountId,
    "mcc": mcc,
    "merchantId": merchantId,
    "insId": insId,
    "userId": userId,
    "user": user?.toMap(),
    "terminals": terminals == null ? <UTerminalResponse>[] : List<UTerminalResponse>.from(terminals!.map((UTerminalResponse x) => x.toMap())),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UMerchantJson {
  final String? detail1;
  final String? detail2;
  final String? businessTitle;
  final String? address;
  final String? ownerPhoneNumber;
  final int? definitionTemplate;
  final int? settlementCurrency;
  final String? ownerName;

  UMerchantJson({
    this.detail1,
    this.detail2,
    this.businessTitle,
    this.address,
    this.ownerPhoneNumber,
    this.definitionTemplate,
    this.settlementCurrency,
    this.ownerName,
  });

  factory UMerchantJson.fromJson(String str) => UMerchantJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMerchantJson.fromMap(Map<String, dynamic> json) => UMerchantJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    businessTitle: json["businessTitle"],
    address: json["address"],
    ownerPhoneNumber: json["ownerPhoneNumber"],
    definitionTemplate: json["definitionTemplate"],
    settlementCurrency: json["settlementCurrency"],
    ownerName: json["ownerName"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "businessTitle": businessTitle,
    "address": address,
    "ownerPhoneNumber": ownerPhoneNumber,
    "definitionTemplate": definitionTemplate,
    "settlementCurrency": settlementCurrency,
    "ownerName": ownerName,
  };
}

class UTerminalResponse {
  final String serial;
  final List<int> tags;
  final String id;
  final String? simCardNumber;
  final String? simCardSerial;
  final String? imei;
  final String? terminalId;
  final String? agreement;
  final UBaseJson jsonData;
  final DateTime createdAt;
  final UMerchantResponse? merchant;
  final String terminalBrandId;
  final UTerminalBrandResponse? terminalBrand;
  final String terminalBrokerId;
  final UTerminalBrokerResponse? terminalBroker;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;
  final String? merchantId;

  UTerminalResponse({
    required this.tags,
    required this.jsonData,
    required this.serial,
    required this.createdAt,
    required this.id,
    required this.adminUserIds,
    required this.terminalBrandId,
    required this.terminalBrokerId,
    this.terminalId,
    this.simCardNumber,
    this.simCardSerial,
    this.agreement,
    this.imei,
    this.merchant,
    this.terminalBrand,
    this.terminalBroker,
    this.creator,
    this.creatorId,
    this.merchantId,
  });

  factory UTerminalResponse.fromJson(String str) => UTerminalResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalResponse.fromMap(Map<String, dynamic> json) => UTerminalResponse(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    terminalId: json["terminalId"],
    serial: json["serial"],
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    merchant: json["merchant"] == null ? null : UMerchantResponse.fromMap(json["merchant"]),
    terminalBrandId: json["terminalBrandId"] as String,
    terminalBrand: json["terminalBrand"] == null ? null : UTerminalBrandResponse.fromMap(json["terminalBrand"]),
    terminalBrokerId: json["terminalBrokerId"] as String,
    terminalBroker: json["terminalBroker"] == null ? null : UTerminalBrokerResponse.fromMap(json["terminalBroker"]),
    simCardNumber: json["simCardNumber"],
    simCardSerial: json["simCardSerial"],
    imei: json["imei"],
    agreement: json["agreement"],
    createdAt: DateTime.parse(json["createdAt"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    merchantId: json["merchantId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "terminalId": terminalId,
    "agreement": agreement,
    "serial": serial,
    "simCardNumber": simCardNumber,
    "simCardSerial": simCardSerial,
    "imei": imei,
    "jsonData": jsonData.toMap(),
    "merchant": merchant?.toMap(),
    "terminalBrandId": terminalBrandId,
    "terminalBrand": terminalBrand?.toMap(),
    "terminalBrokerId": terminalBrokerId,
    "terminalBroker": terminalBroker?.toMap(),
    "createdAt": createdAt.toIso8601String(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
    "merchantId": merchantId,
  };
}

class UTerminalAvailabilityResponse {
  final String id;
  final String serial;
  final String? agreement;

  UTerminalAvailabilityResponse({
    required this.id,
    required this.serial,
    this.agreement,
  });

  factory UTerminalAvailabilityResponse.fromJson(String str) => UTerminalAvailabilityResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalAvailabilityResponse.fromMap(Map<String, dynamic> json) => UTerminalAvailabilityResponse(
    id: json["id"],
    serial: json["serial"],
    agreement: json["agreement"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "serial": serial,
    "agreement": agreement,
  };
}

class UTerminalSupportPasswordResponse {
  final String? password;

  UTerminalSupportPasswordResponse({
    this.password,
  });

  factory UTerminalSupportPasswordResponse.fromJson(String str) => UTerminalSupportPasswordResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalSupportPasswordResponse.fromMap(Map<String, dynamic> json) => UTerminalSupportPasswordResponse(
    password: json["password"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "password": password,
  };
}

class UTerminalImportResponse {
  final int totalRows;
  final int imported;
  final int skipped;
  final List<String> skippedSerials;

  UTerminalImportResponse({
    required this.totalRows,
    required this.imported,
    required this.skipped,
    required this.skippedSerials,
  });

  factory UTerminalImportResponse.fromJson(String str) => UTerminalImportResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalImportResponse.fromMap(
    Map<String, dynamic> json,
  ) => UTerminalImportResponse(
    totalRows: json["totalRows"],
    imported: json["imported"],
    skipped: json["skipped"],
    skippedSerials: json["skippedSerials"] == null
        ? <String>[]
        : List<String>.from(
            json["skippedSerials"]!.map((dynamic x) => x),
          ),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "totalRows": totalRows,
    "imported": imported,
    "skipped": skipped,
    "skippedSerials": List<dynamic>.from(
      skippedSerials.map((String x) => x),
    ),
  };
}

class UTerminalBrandResponse {
  final String code;
  final String title;
  final String model;
  final List<int> tags;
  final String id;
  final UTerminalBrandJson jsonData;
  final DateTime createdAt;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  UTerminalBrandResponse({
    required this.code,
    required this.title,
    required this.model,
    required this.tags,
    required this.id,
    required this.jsonData,
    required this.createdAt,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
  });

  factory UTerminalBrandResponse.fromJson(String str) => UTerminalBrandResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrandResponse.fromMap(
    Map<String, dynamic> json,
  ) => UTerminalBrandResponse(
    code: json["code"] ?? "",
    title: json["title"],
    model: json["model"],
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    jsonData: UTerminalBrandJson.fromMap(json["jsonData"]),
    createdAt: DateTime.parse(json["createdAt"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null
        ? <String>[]
        : List<String>.from(
            json["adminUserIds"]!.map((dynamic x) => x),
          ),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "title": title,
    "model": model,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "jsonData": jsonData.toMap(),
    "createdAt": createdAt.toIso8601String(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(
      adminUserIds.map((String x) => x),
    ),
  };
}

class UTerminalBrandJson {
  final String? detail1;
  final String? detail2;
  final String? agreement;

  UTerminalBrandJson({
    this.detail1,
    this.detail2,
    this.agreement,
  });

  factory UTerminalBrandJson.fromJson(String str) => UTerminalBrandJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrandJson.fromMap(Map<String, dynamic> json) => UTerminalBrandJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    agreement: json["agreement"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "agreement": agreement,
  };
}

class UTerminalBrokerResponse {
  final String code;
  final String title;
  final List<int> tags;
  final String id;
  final UTerminalBrokerJson jsonData;
  final DateTime createdAt;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  UTerminalBrokerResponse({
    required this.code,
    required this.title,
    required this.tags,
    required this.id,
    required this.jsonData,
    required this.createdAt,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
  });

  factory UTerminalBrokerResponse.fromJson(String str) => UTerminalBrokerResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrokerResponse.fromMap(
    Map<String, dynamic> json,
  ) => UTerminalBrokerResponse(
    code: json["code"] ?? "",
    title: json["title"],
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    jsonData: UTerminalBrokerJson.fromMap(json["jsonData"]),
    createdAt: DateTime.parse(json["createdAt"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null
        ? <String>[]
        : List<String>.from(
            json["adminUserIds"]!.map((dynamic x) => x),
          ),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "title": title,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "jsonData": jsonData.toMap(),
    "createdAt": createdAt.toIso8601String(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(
      adminUserIds.map((String x) => x),
    ),
  };
}

class UTerminalBrokerJson {
  final String? detail1;
  final String? detail2;
  final String? registrationNumber;
  final String? nationalCode;
  final String? representative;
  final String? address;
  final String? postalCode;
  final String? phoneNumber;
  final String? sign1Base64;
  final String? sign1Owner;
  final String? sign2Base64;
  final String? sign2Owner;
  final String? logoBase64;

  UTerminalBrokerJson({
    this.detail1,
    this.detail2,
    this.registrationNumber,
    this.nationalCode,
    this.representative,
    this.address,
    this.postalCode,
    this.phoneNumber,
    this.sign1Base64,
    this.sign1Owner,
    this.sign2Base64,
    this.sign2Owner,
    this.logoBase64,
  });

  factory UTerminalBrokerJson.fromJson(String str) => UTerminalBrokerJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrokerJson.fromMap(Map<String, dynamic> json) => UTerminalBrokerJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    registrationNumber: json["registrationNumber"],
    nationalCode: json["nationalCode"],
    representative: json["representative"],
    address: json["address"],
    postalCode: json["postalCode"],
    phoneNumber: json["phoneNumber"],
    sign1Base64: json["sign1Base64"],
    sign1Owner: json["sign1Owner"],
    sign2Base64: json["sign2Base64"],
    sign2Owner: json["sign2Owner"],
    logoBase64: json["logoBase64"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "registrationNumber": registrationNumber,
    "nationalCode": nationalCode,
    "representative": representative,
    "address": address,
    "postalCode": postalCode,
    "phoneNumber": phoneNumber,
    "sign1Base64": sign1Base64,
    "sign1Owner": sign1Owner,
    "sign2Base64": sign2Base64,
    "sign2Owner": sign2Owner,
    "logoBase64": logoBase64,
  };
}

class UFinancialOpsDashboardResponse {
  final DateTime generatedAt;
  final DateTime fromDate;
  final DateTime toDate;

  final int usersCount;
  final int newUsersCount;

  final int merchantsCount;
  final int newMerchantsCount;

  final int terminalsCount;
  final int terminalsAssignedCount;
  final int terminalsUnassignedCount;

  final int txnCount;
  final int newTxnCount;

  final int walletsCount;
  final double totalWalletBalance;

  final double totalIn;
  final double totalOut;
  final double net;

  final List<UAccountingBreakdownItem> txnByStatus;
  final List<UAccountingBreakdownItem> txnByMethod;
  final List<UAccountingBreakdownItem> terminalsByType;
  final List<UAccountingTimelineItem> dailyTimeline;

  final List<UTopMerchantItem> topMerchants;
  final List<URecentTxnItem> recentTransactions;
  final List<URecentMerchantItem> recentMerchants;
  final List<URecentUserItem> recentUsers;

  UFinancialOpsDashboardResponse({
    required this.generatedAt,
    required this.fromDate,
    required this.toDate,
    required this.usersCount,
    required this.newUsersCount,
    required this.merchantsCount,
    required this.newMerchantsCount,
    required this.terminalsCount,
    required this.terminalsAssignedCount,
    required this.terminalsUnassignedCount,
    required this.txnCount,
    required this.newTxnCount,
    required this.walletsCount,
    required this.totalWalletBalance,
    required this.totalIn,
    required this.totalOut,
    required this.net,
    required this.txnByStatus,
    required this.txnByMethod,
    required this.terminalsByType,
    required this.dailyTimeline,
    required this.topMerchants,
    required this.recentTransactions,
    required this.recentMerchants,
    required this.recentUsers,
  });

  factory UFinancialOpsDashboardResponse.fromMap(Map<String, dynamic> json) => UFinancialOpsDashboardResponse(
    generatedAt: DateTime.parse(json["generatedAt"]),
    fromDate: DateTime.parse(json["fromDate"]),
    toDate: DateTime.parse(json["toDate"]),
    usersCount: json["usersCount"] ?? 0,
    newUsersCount: json["newUsersCount"] ?? 0,
    merchantsCount: json["merchantsCount"] ?? 0,
    newMerchantsCount: json["newMerchantsCount"] ?? 0,
    terminalsCount: json["terminalsCount"] ?? 0,
    terminalsAssignedCount: json["terminalsAssignedCount"] ?? 0,
    terminalsUnassignedCount: json["terminalsUnassignedCount"] ?? 0,
    txnCount: json["txnCount"] ?? 0,
    newTxnCount: json["newTxnCount"] ?? 0,
    walletsCount: json["walletsCount"] ?? 0,
    totalWalletBalance: (json["totalWalletBalance"] ?? 0).toString().toDouble(),
    totalIn: (json["totalIn"] ?? 0).toString().toDouble(),
    totalOut: (json["totalOut"] ?? 0).toString().toDouble(),
    net: (json["net"] ?? 0).toString().toDouble(),
    txnByStatus: ((json["txnByStatus"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UAccountingBreakdownItem.fromMap(x)).toList(),
    txnByMethod: ((json["txnByMethod"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UAccountingBreakdownItem.fromMap(x)).toList(),
    terminalsByType: ((json["terminalsByType"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UAccountingBreakdownItem.fromMap(x)).toList(),
    dailyTimeline: ((json["dailyTimeline"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UAccountingTimelineItem.fromMap(x)).toList(),
    topMerchants: ((json["topMerchants"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UTopMerchantItem.fromMap(x)).toList(),
    recentTransactions: ((json["recentTransactions"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => URecentTxnItem.fromMap(x)).toList(),
    recentMerchants: ((json["recentMerchants"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => URecentMerchantItem.fromMap(x)).toList(),
    recentUsers: ((json["recentUsers"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => URecentUserItem.fromMap(x)).toList(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "generatedAt": generatedAt.toIso8601String(),
    "fromDate": fromDate.toIso8601String(),
    "toDate": toDate.toIso8601String(),
    "usersCount": usersCount,
    "newUsersCount": newUsersCount,
    "merchantsCount": merchantsCount,
    "newMerchantsCount": newMerchantsCount,
    "terminalsCount": terminalsCount,
    "terminalsAssignedCount": terminalsAssignedCount,
    "terminalsUnassignedCount": terminalsUnassignedCount,
    "txnCount": txnCount,
    "newTxnCount": newTxnCount,
    "walletsCount": walletsCount,
    "totalWalletBalance": totalWalletBalance,
    "totalIn": totalIn,
    "totalOut": totalOut,
    "net": net,
    "txnByStatus": List<dynamic>.from(txnByStatus.map((UAccountingBreakdownItem x) => x.toMap())),
    "txnByMethod": List<dynamic>.from(txnByMethod.map((UAccountingBreakdownItem x) => x.toMap())),
    "terminalsByType": List<dynamic>.from(terminalsByType.map((UAccountingBreakdownItem x) => x.toMap())),
    "dailyTimeline": List<dynamic>.from(dailyTimeline.map((UAccountingTimelineItem x) => x.toMap())),
    "topMerchants": List<dynamic>.from(topMerchants.map((UTopMerchantItem x) => x.toMap())),
    "recentTransactions": List<dynamic>.from(recentTransactions.map((URecentTxnItem x) => x.toMap())),
    "recentMerchants": List<dynamic>.from(recentMerchants.map((URecentMerchantItem x) => x.toMap())),
    "recentUsers": List<dynamic>.from(recentUsers.map((URecentUserItem x) => x.toMap())),
  };

  String toJson() => json.encode(toMap());

  factory UFinancialOpsDashboardResponse.fromJson(String str) => UFinancialOpsDashboardResponse.fromMap(json.decode(str));
}

class UTopMerchantItem {
  final String id;
  final String title;
  final String city;
  final int terminalCount;
  final DateTime createdAt;

  UTopMerchantItem({required this.id, required this.title, required this.city, required this.terminalCount, required this.createdAt});

  factory UTopMerchantItem.fromMap(Map<String, dynamic> json) => UTopMerchantItem(
    id: json["id"] as String,
    title: json["title"] ?? "",
    city: json["city"] ?? "",
    terminalCount: json["terminalCount"] ?? 0,
    createdAt: DateTime.parse(json["createdAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "city": city,
    "terminalCount": terminalCount,
    "createdAt": createdAt.toIso8601String(),
  };

  String toJson() => json.encode(toMap());

  factory UTopMerchantItem.fromJson(String str) => UTopMerchantItem.fromMap(json.decode(str));
}

class URecentTxnItem {
  final String id;
  final double amount;
  final String trackingNumber;
  final String? userName;
  final List<String> tags;
  final DateTime createdAt;

  URecentTxnItem({required this.id, required this.amount, required this.trackingNumber, required this.tags, required this.createdAt, this.userName});

  factory URecentTxnItem.fromMap(Map<String, dynamic> json) => URecentTxnItem(
    id: json["id"] as String,
    amount: (json["amount"] ?? 0).toString().toDouble(),
    trackingNumber: json["trackingNumber"] ?? "",
    userName: json["userName"],
    tags: json["tags"] == null ? <String>[] : List<String>.from(json["tags"].map((dynamic x) => x.toString())),
    createdAt: DateTime.parse(json["createdAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "amount": amount,
    "trackingNumber": trackingNumber,
    "userName": userName,
    "tags": List<dynamic>.from(tags.map((String x) => x)),
    "createdAt": createdAt.toIso8601String(),
  };

  String toJson() => json.encode(toMap());

  factory URecentTxnItem.fromJson(String str) => URecentTxnItem.fromMap(json.decode(str));
}

class URecentMerchantItem {
  final String id;
  final String title;
  final String cityCode;
  final int terminalCount;
  final DateTime createdAt;

  URecentMerchantItem({required this.id, required this.title, required this.cityCode, required this.terminalCount, required this.createdAt});

  factory URecentMerchantItem.fromMap(Map<String, dynamic> json) => URecentMerchantItem(
    id: json["id"] as String,
    title: json["title"] ?? "",
    cityCode: json["cityCode"] ?? "",
    terminalCount: json["terminalCount"] ?? 0,
    createdAt: DateTime.parse(json["createdAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "cityCode": cityCode,
    "terminalCount": terminalCount,
    "createdAt": createdAt.toIso8601String(),
  };

  String toJson() => json.encode(toMap());

  factory URecentMerchantItem.fromJson(String str) => URecentMerchantItem.fromMap(json.decode(str));
}
