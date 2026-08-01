part of "../data.dart";

class UMoadiCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final String? userId;
  final String name;
  final String economicCode;
  final String legalEntity;
  final String uniqueTaxCode;
  final String ownerName;
  final String ownerMobile;
  final String ownerNationalCode;
  final String? nationalCode;
  final String? postalCode;
  final String? registrationDate;
  final String? registrationNumber;
  final String? address;
  final int? startInvoiceNumber;
  final String? introductionCode;
  final List<String>? adminUserIds;

  UMoadiCreateParams({
    required this.tags,
    required this.name,
    required this.economicCode,
    required this.legalEntity,
    required this.uniqueTaxCode,
    required this.ownerName,
    required this.ownerMobile,
    required this.ownerNationalCode,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.userId,
    this.nationalCode,
    this.postalCode,
    this.registrationDate,
    this.registrationNumber,
    this.address,
    this.startInvoiceNumber,
    this.introductionCode,
    this.adminUserIds,
  });

  factory UMoadiCreateParams.fromJson(String str) => UMoadiCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMoadiCreateParams.fromMap(Map<String, dynamic> json) => UMoadiCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    userId: json["userId"],
    name: json["name"],
    economicCode: json["economicCode"],
    legalEntity: json["legalEntity"],
    uniqueTaxCode: json["uniqueTaxCode"],
    ownerName: json["ownerName"],
    ownerMobile: json["ownerMobile"],
    ownerNationalCode: json["ownerNationalCode"],
    nationalCode: json["nationalCode"],
    postalCode: json["postalCode"],
    registrationDate: json["registrationDate"],
    registrationNumber: json["registrationNumber"],
    address: json["address"],
    startInvoiceNumber: json["startInvoiceNumber"],
    introductionCode: json["introductionCode"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
    "userId": userId,
    "name": name,
    "economicCode": economicCode,
    "legalEntity": legalEntity,
    "uniqueTaxCode": uniqueTaxCode,
    "ownerName": ownerName,
    "ownerMobile": ownerMobile,
    "ownerNationalCode": ownerNationalCode,
    "nationalCode": nationalCode,
    "postalCode": postalCode,
    "registrationDate": registrationDate,
    "registrationNumber": registrationNumber,
    "address": address,
    "startInvoiceNumber": startInvoiceNumber,
    "introductionCode": introductionCode,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UMoadiUpdateParams {
  final String id;
  final String? name;
  final String? economicCode;
  final String? legalEntity;
  final String? uniqueTaxCode;
  final String? nationalCode;
  final String? postalCode;
  final String? registrationDate;
  final String? registrationNumber;
  final String? address;
  final int? startInvoiceNumber;
  final String? introductionCode;
  final String? ownerName;
  final String? ownerMobile;
  final String? ownerNationalCode;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UMoadiUpdateParams({
    required this.id,
    this.name,
    this.economicCode,
    this.legalEntity,
    this.uniqueTaxCode,
    this.nationalCode,
    this.postalCode,
    this.registrationDate,
    this.registrationNumber,
    this.address,
    this.startInvoiceNumber,
    this.introductionCode,
    this.ownerName,
    this.ownerMobile,
    this.ownerNationalCode,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UMoadiUpdateParams.fromJson(String str) => UMoadiUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMoadiUpdateParams.fromMap(Map<String, dynamic> json) => UMoadiUpdateParams(
    id: json["id"],
    name: json["name"],
    economicCode: json["economicCode"],
    legalEntity: json["legalEntity"],
    uniqueTaxCode: json["uniqueTaxCode"],
    nationalCode: json["nationalCode"],
    postalCode: json["postalCode"],
    registrationDate: json["registrationDate"],
    registrationNumber: json["registrationNumber"],
    address: json["address"],
    startInvoiceNumber: json["startInvoiceNumber"],
    introductionCode: json["introductionCode"],
    ownerName: json["ownerName"],
    ownerMobile: json["ownerMobile"],
    ownerNationalCode: json["ownerNationalCode"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "name": name,
    "economicCode": economicCode,
    "legalEntity": legalEntity,
    "uniqueTaxCode": uniqueTaxCode,
    "nationalCode": nationalCode,
    "postalCode": postalCode,
    "registrationDate": registrationDate,
    "registrationNumber": registrationNumber,
    "address": address,
    "startInvoiceNumber": startInvoiceNumber,
    "introductionCode": introductionCode,
    "ownerName": ownerName,
    "ownerMobile": ownerMobile,
    "ownerNationalCode": ownerNationalCode,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UMoadiRejectParams {
  final String id;
  final String? reason;

  UMoadiRejectParams({required this.id, this.reason});

  factory UMoadiRejectParams.fromJson(String str) => UMoadiRejectParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMoadiRejectParams.fromMap(Map<String, dynamic> json) => UMoadiRejectParams(
    id: json["id"],
    reason: json["reason"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "reason": reason,
  };
}

class UMoadiReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? userId;
  final String? name;
  final String? economicCode;
  final String? nationalCode;
  final String? uniqueTaxCode;
  final String? legalEntity;
  final String? uuid;
  final int? orderBy;
  final MoadiSelectorArgs? selectorArgs;

  UMoadiReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.userId,
    this.name,
    this.economicCode,
    this.nationalCode,
    this.uniqueTaxCode,
    this.legalEntity,
    this.uuid,
    this.orderBy,
    this.selectorArgs,
  });

  factory UMoadiReadParams.fromJson(String str) => UMoadiReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMoadiReadParams.fromMap(Map<String, dynamic> json) => UMoadiReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    userId: json["userId"],
    name: json["name"],
    economicCode: json["economicCode"],
    nationalCode: json["nationalCode"],
    uniqueTaxCode: json["uniqueTaxCode"],
    legalEntity: json["legalEntity"],
    uuid: json["uuid"],
    orderBy: json["orderBy"],
    selectorArgs: json["selectorArgs"] == null ? null : MoadiSelectorArgs.fromMap(json["selectorArgs"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "userId": userId,
    "name": name,
    "economicCode": economicCode,
    "nationalCode": nationalCode,
    "uniqueTaxCode": uniqueTaxCode,
    "legalEntity": legalEntity,
    "uuid": uuid,
    "orderBy": orderBy,
    "selectorArgs": selectorArgs?.toMap(),
  };
}
