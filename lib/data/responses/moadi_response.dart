part of "../data.dart";

class UMoadiResponse {
  final String id;
  final DateTime createdAt;
  final MoadiJsonData jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String name;
  final String economicCode;
  final String legalEntity;
  final String uniqueTaxCode;
  final String? nationalCode;
  final String? postalCode;
  final String? registrationDate;
  final String? registrationNumber;
  final String? address;
  final int? startInvoiceNumber;
  final String? introductionCode;
  final String ownerName;
  final String ownerMobile;
  final String ownerNationalCode;
  final String userId;
  final UUserResponse? user;
  final List<String> adminUserIds;

  UMoadiResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.name,
    required this.economicCode,
    required this.legalEntity,
    required this.uniqueTaxCode,
    required this.ownerName,
    required this.ownerMobile,
    required this.ownerNationalCode,
    required this.userId,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
    this.nationalCode,
    this.postalCode,
    this.registrationDate,
    this.registrationNumber,
    this.address,
    this.startInvoiceNumber,
    this.introductionCode,
    this.user,
  });

  factory UMoadiResponse.fromJson(String str) => UMoadiResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UMoadiResponse.fromMap(Map<String, dynamic> json) => UMoadiResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: MoadiJsonData.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    name: json["name"] as String,
    economicCode: json["economicCode"] as String,
    legalEntity: json["legalEntity"] as String,
    uniqueTaxCode: json["uniqueTaxCode"] as String,
    nationalCode: json["nationalCode"],
    postalCode: json["postalCode"],
    registrationDate: json["registrationDate"],
    registrationNumber: json["registrationNumber"],
    address: json["address"],
    startInvoiceNumber: json["startInvoiceNumber"],
    introductionCode: json["introductionCode"],
    ownerName: json["ownerName"] as String,
    ownerMobile: json["ownerMobile"] as String,
    ownerNationalCode: json["ownerNationalCode"] as String,
    userId: json["userId"] as String,
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<int>.from(tags.map((int x) => x)),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
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
    "userId": userId,
    "user": user?.toMap(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class MoadiJsonData {
  final String? detail1;
  final String? detail2;
  final String? uuid;
  final int? registerStep;
  final String? createdType;
  final int? ownerId;
  final bool? activeContract;
  final int? invoicesCount;
  final int? invoicesSuccessCount;
  final String? lastContractStatus;
  final String? rejectReason;

  MoadiJsonData({
    this.detail1,
    this.detail2,
    this.uuid,
    this.registerStep,
    this.createdType,
    this.ownerId,
    this.activeContract,
    this.invoicesCount,
    this.invoicesSuccessCount,
    this.lastContractStatus,
    this.rejectReason,
  });

  factory MoadiJsonData.fromJson(String str) => MoadiJsonData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MoadiJsonData.fromMap(Map<String, dynamic> json) => MoadiJsonData(
    detail1: json["detail1"],
    detail2: json["detail2"],
    uuid: json["uuid"],
    registerStep: json["registerStep"],
    createdType: json["createdType"],
    ownerId: json["ownerId"],
    activeContract: json["activeContract"],
    invoicesCount: json["invoicesCount"],
    invoicesSuccessCount: json["invoicesSuccessCount"],
    lastContractStatus: json["lastContractStatus"],
    rejectReason: json["rejectReason"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "uuid": uuid,
    "registerStep": registerStep,
    "createdType": createdType,
    "ownerId": ownerId,
    "activeContract": activeContract,
    "invoicesCount": invoicesCount,
    "invoicesSuccessCount": invoicesSuccessCount,
    "lastContractStatus": lastContractStatus,
    "rejectReason": rejectReason,
  };
}
