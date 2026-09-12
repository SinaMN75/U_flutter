part of "../data.dart";

class UBrokerResponse {
  UBrokerResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.code,
    required this.adminUserIds,
    this.agreementTemplateId,
    this.brands = const <UTerminalBrandResponse>[],
    this.creator,
    this.creatorId,
  });

  factory UBrokerResponse.fromJson(String str) => UBrokerResponse.fromMap(json.decode(str));

  factory UBrokerResponse.fromMap(Map<String, dynamic> json) => UBrokerResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBrokerJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    code: json["code"],
    agreementTemplateId: json["agreementTemplateId"],
    brands: json["brands"] == null
        ? <UTerminalBrandResponse>[]
        : List<UTerminalBrandResponse>.from(json["brands"].map((dynamic x) => UTerminalBrandResponse.fromMap(x))),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  final String id;
  final DateTime createdAt;
  final UBrokerJson jsonData;
  final List<int> tags;
  final String title;
  final String code;
  final String? agreementTemplateId;
  final List<UTerminalBrandResponse> brands;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "code": code,
    "agreementTemplateId": agreementTemplateId,
    "brands": List<dynamic>.from(brands.map((UTerminalBrandResponse x) => x.toMap())),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UBrokerJson {
  UBrokerJson({
    this.detail1,
    this.detail2,
    this.legalName,
    this.registrationNumber,
    this.nationalId,
    this.address,
    this.postalCode,
    this.phoneNumber,
    this.supportPhoneNumber,
    this.callCenterPhoneNumber,
    this.representativeName,
    this.representativeRole,
    this.logoBase64,
    this.themeColor,
    this.contractNumberSuffix,
    this.provider,
    this.providerBaseUrl,
    this.providerAuthHeader,
    this.providerProject,
    this.providerDefinitionTemplate,
    this.signatories = const <UBrokerSignatory>[],
  });

  factory UBrokerJson.fromJson(String str) => UBrokerJson.fromMap(json.decode(str));

  factory UBrokerJson.fromMap(Map<String, dynamic> json) => UBrokerJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    legalName: json["legalName"],
    registrationNumber: json["registrationNumber"],
    nationalId: json["nationalId"],
    address: json["address"],
    postalCode: json["postalCode"],
    phoneNumber: json["phoneNumber"],
    supportPhoneNumber: json["supportPhoneNumber"],
    callCenterPhoneNumber: json["callCenterPhoneNumber"],
    representativeName: json["representativeName"],
    representativeRole: json["representativeRole"],
    logoBase64: json["logoBase64"],
    themeColor: json["themeColor"],
    contractNumberSuffix: json["contractNumberSuffix"],
    provider: json["provider"],
    providerBaseUrl: json["providerBaseUrl"],
    providerAuthHeader: json["providerAuthHeader"],
    providerProject: json["providerProject"],
    providerDefinitionTemplate: json["providerDefinitionTemplate"],
    signatories: json["signatories"] == null
        ? <UBrokerSignatory>[]
        : List<UBrokerSignatory>.from(json["signatories"].map((dynamic x) => UBrokerSignatory.fromMap(x))),
  );

  final String? detail1;
  final String? detail2;
  final String? legalName;
  final String? registrationNumber;
  final String? nationalId;
  final String? address;
  final String? postalCode;
  final String? phoneNumber;
  final String? supportPhoneNumber;
  final String? callCenterPhoneNumber;
  final String? representativeName;
  final String? representativeRole;
  final String? logoBase64;
  final String? themeColor;
  final String? contractNumberSuffix;
  final int? provider;
  final String? providerBaseUrl;
  final String? providerAuthHeader;
  final String? providerProject;
  final int? providerDefinitionTemplate;
  final List<UBrokerSignatory> signatories;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "legalName": legalName,
    "registrationNumber": registrationNumber,
    "nationalId": nationalId,
    "address": address,
    "postalCode": postalCode,
    "phoneNumber": phoneNumber,
    "supportPhoneNumber": supportPhoneNumber,
    "callCenterPhoneNumber": callCenterPhoneNumber,
    "representativeName": representativeName,
    "representativeRole": representativeRole,
    "logoBase64": logoBase64,
    "themeColor": themeColor,
    "contractNumberSuffix": contractNumberSuffix,
    "provider": provider,
    "providerBaseUrl": providerBaseUrl,
    "providerAuthHeader": providerAuthHeader,
    "providerProject": providerProject,
    "providerDefinitionTemplate": providerDefinitionTemplate,
    "signatories": List<dynamic>.from(signatories.map((UBrokerSignatory x) => x.toMap())),
  };
}

class UBrokerSignatory {
  UBrokerSignatory({this.name, this.role, this.signatureBase64, this.order});

  factory UBrokerSignatory.fromJson(String str) => UBrokerSignatory.fromMap(json.decode(str));

  factory UBrokerSignatory.fromMap(Map<String, dynamic> json) => UBrokerSignatory(
    name: json["name"],
    role: json["role"],
    signatureBase64: json["signatureBase64"],
    order: json["order"],
  );

  final String? name;
  final String? role;
  final String? signatureBase64;
  final int? order;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "name": name,
    "role": role,
    "signatureBase64": signatureBase64,
    "order": order,
  };
}

class UBrokerBriefResponse {
  UBrokerBriefResponse({
    required this.id,
    required this.title,
    this.legalName,
    this.logoBase64,
    this.phoneNumber,
    this.supportPhoneNumber,
  });

  factory UBrokerBriefResponse.fromJson(String str) => UBrokerBriefResponse.fromMap(json.decode(str));

  factory UBrokerBriefResponse.fromMap(Map<String, dynamic> json) => UBrokerBriefResponse(
    id: json["id"],
    title: json["title"],
    legalName: json["legalName"],
    logoBase64: json["logoBase64"],
    phoneNumber: json["phoneNumber"],
    supportPhoneNumber: json["supportPhoneNumber"],
  );

  final String id;
  final String title;
  final String? legalName;
  final String? logoBase64;
  final String? phoneNumber;
  final String? supportPhoneNumber;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "legalName": legalName,
    "logoBase64": logoBase64,
    "phoneNumber": phoneNumber,
    "supportPhoneNumber": supportPhoneNumber,
  };
}

class UTerminalBrandResponse {
  UTerminalBrandResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.code,
    required this.brokerId,
    required this.adminUserIds,
    this.broker,
    this.creator,
    this.creatorId,
  });

  factory UTerminalBrandResponse.fromJson(String str) => UTerminalBrandResponse.fromMap(json.decode(str));

  factory UTerminalBrandResponse.fromMap(Map<String, dynamic> json) => UTerminalBrandResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UTerminalBrandJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    code: json["code"],
    brokerId: json["brokerId"],
    broker: json["broker"] == null ? null : UBrokerBriefResponse.fromMap(json["broker"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  final String id;
  final DateTime createdAt;
  final UTerminalBrandJson jsonData;
  final List<int> tags;
  final String title;
  final String code;
  final String brokerId;
  final UBrokerBriefResponse? broker;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "code": code,
    "brokerId": brokerId,
    "broker": broker?.toMap(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UTerminalBrandJson {
  UTerminalBrandJson({
    this.detail1,
    this.detail2,
    this.requiresSimCardSerial = true,
    this.requiresImei = false,
    this.imageBase64,
    this.order,
    this.agreementTemplateId,
    this.legacyTag,
  });

  factory UTerminalBrandJson.fromJson(String str) => UTerminalBrandJson.fromMap(json.decode(str));

  factory UTerminalBrandJson.fromMap(Map<String, dynamic> json) => UTerminalBrandJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    requiresSimCardSerial: json["requiresSimCardSerial"] ?? true,
    requiresImei: json["requiresImei"] ?? false,
    imageBase64: json["imageBase64"],
    order: json["order"],
    agreementTemplateId: json["agreementTemplateId"],
    legacyTag: json["legacyTag"],
  );

  final String? detail1;
  final String? detail2;
  final bool requiresSimCardSerial;
  final bool requiresImei;
  final String? imageBase64;
  final int? order;
  final String? agreementTemplateId;
  final int? legacyTag;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "requiresSimCardSerial": requiresSimCardSerial,
    "requiresImei": requiresImei,
    "imageBase64": imageBase64,
    "order": order,
    "agreementTemplateId": agreementTemplateId,
    "legacyTag": legacyTag,
  };
}

class UAgreementTemplateResponse {
  UAgreementTemplateResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.code,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
  });

  factory UAgreementTemplateResponse.fromJson(String str) => UAgreementTemplateResponse.fromMap(json.decode(str));

  factory UAgreementTemplateResponse.fromMap(Map<String, dynamic> json) => UAgreementTemplateResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UAgreementTemplateJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    code: json["code"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  final String id;
  final DateTime createdAt;
  final UAgreementTemplateJson jsonData;
  final List<int> tags;
  final String title;
  final String code;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "code": code,
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UAgreementTemplateJson {
  UAgreementTemplateJson({
    this.detail1,
    this.detail2,
    this.headerTitle,
    this.blocks = const <UAgreementTemplateBlock>[],
  });

  factory UAgreementTemplateJson.fromJson(String str) => UAgreementTemplateJson.fromMap(json.decode(str));

  factory UAgreementTemplateJson.fromMap(Map<String, dynamic> json) => UAgreementTemplateJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    headerTitle: json["headerTitle"],
    blocks: json["blocks"] == null
        ? <UAgreementTemplateBlock>[]
        : List<UAgreementTemplateBlock>.from(json["blocks"].map((dynamic x) => UAgreementTemplateBlock.fromMap(x))),
  );

  final String? detail1;
  final String? detail2;
  final String? headerTitle;
  final List<UAgreementTemplateBlock> blocks;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "headerTitle": headerTitle,
    "blocks": List<dynamic>.from(blocks.map((UAgreementTemplateBlock x) => x.toMap())),
  };
}

class UAgreementTemplateBlock {
  UAgreementTemplateBlock({required this.type, required this.text, required this.order});

  factory UAgreementTemplateBlock.fromJson(String str) => UAgreementTemplateBlock.fromMap(json.decode(str));

  factory UAgreementTemplateBlock.fromMap(Map<String, dynamic> json) => UAgreementTemplateBlock(
    type: json["type"] ?? TagAgreementBlock.clause.number,
    text: json["text"] ?? "",
    order: json["order"] ?? 0,
  );

  final int type;
  final String text;
  final int order;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "type": type,
    "text": text,
    "order": order,
  };
}
