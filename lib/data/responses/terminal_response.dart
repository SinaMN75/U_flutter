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
  final String title;
  final String model;
  final List<int> tags;
  final String id;
  final UBaseJson jsonData;
  final DateTime createdAt;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  UTerminalBrandResponse({
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
    title: json["title"],
    model: json["model"],
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    jsonData: UBaseJson.fromMap(json["jsonData"]),
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

class UTerminalBrokerResponse {
  final String title;
  final List<int> tags;
  final String id;
  final UBaseJson jsonData;
  final DateTime createdAt;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  UTerminalBrokerResponse({
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
    title: json["title"],
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    jsonData: UBaseJson.fromMap(json["jsonData"]),
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
