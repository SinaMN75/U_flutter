part of "../data.dart";

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
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;
  final String? merchantId;
  final String? brandId;
  final String? brokerId;
  final UTerminalBrandResponse? brand;
  final UBrokerBriefResponse? broker;

  UTerminalResponse({
    required this.tags,
    required this.jsonData,
    required this.serial,
    required this.createdAt,
    required this.id,
    required this.adminUserIds,
    this.terminalId,
    this.simCardNumber,
    this.simCardSerial,
    this.agreement,
    this.imei,
    this.merchant,
    this.creator,
    this.creatorId,
    this.merchantId,
    this.brandId,
    this.brokerId,
    this.brand,
    this.broker,
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
    simCardNumber: json["simCardNumber"],
    simCardSerial: json["simCardSerial"],
    imei: json["imei"],
    agreement: json["agreement"],
    createdAt: DateTime.parse(json["createdAt"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    merchantId: json["merchantId"],
    brandId: json["brandId"],
    brokerId: json["brokerId"],
    brand: json["brand"] == null ? null : UTerminalBrandResponse.fromMap(json["brand"]),
    broker: json["broker"] == null ? null : UBrokerBriefResponse.fromMap(json["broker"]),
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
    "createdAt": createdAt.toIso8601String(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
    "merchantId": merchantId,
    "brandId": brandId,
    "brokerId": brokerId,
    "brand": brand?.toMap(),
    "broker": broker?.toMap(),
  };
}

class UTerminalAvailabilityResponse {
  final String id;
  final String serial;
  final String? agreement;
  final String? brandId;
  final String? brandTitle;
  final UBrokerBriefResponse? broker;

  UTerminalAvailabilityResponse({
    required this.id,
    required this.serial,
    this.agreement,
    this.brandId,
    this.brandTitle,
    this.broker,
  });

  factory UTerminalAvailabilityResponse.fromJson(String str) => UTerminalAvailabilityResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalAvailabilityResponse.fromMap(Map<String, dynamic> json) => UTerminalAvailabilityResponse(
    id: json["id"],
    serial: json["serial"],
    agreement: json["agreement"],
    brandId: json["brandId"],
    brandTitle: json["brandTitle"],
    broker: json["broker"] == null ? null : UBrokerBriefResponse.fromMap(json["broker"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "serial": serial,
    "agreement": agreement,
    "brandId": brandId,
    "brandTitle": brandTitle,
    "broker": broker?.toMap(),
  };
}

class UTerminalReadSupportPasswordResponse {
  final String? password;

  UTerminalReadSupportPasswordResponse({
    this.password,
  });

  factory UTerminalReadSupportPasswordResponse.fromJson(String str) => UTerminalReadSupportPasswordResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalReadSupportPasswordResponse.fromMap(Map<String, dynamic> json) => UTerminalReadSupportPasswordResponse(
    password: json["password"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "password": password,
  };
}

class UTerminalImportResponse {
  final int? totalRows;
  final int? imported;
  final int? skipped;
  final List<String>? skippedSerials;

  UTerminalImportResponse({
    this.totalRows,
    this.imported,
    this.skipped,
    this.skippedSerials,
  });

  factory UTerminalImportResponse.fromJson(String str) => UTerminalImportResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalImportResponse.fromMap(Map<String, dynamic> json) => UTerminalImportResponse(
    totalRows: json["totalRows"],
    imported: json["imported"],
    skipped: json["skipped"],
    skippedSerials: json["skippedSerials"] == null ? <String>[] : List<String>.from(json["skippedSerials"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "totalRows": totalRows,
    "imported": imported,
    "skipped": skipped,
    "skippedSerials": skippedSerials == null ? <dynamic>[] : List<dynamic>.from(skippedSerials!.map((String x) => x)),
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
