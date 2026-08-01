part of "../data.dart";

class UMerchantResponse {
  final String id;
  final DateTime createdAt;
  final MerchantJsonData jsonData;
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
    jsonData: MerchantJsonData.fromMap(json["jsonData"]),
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
    "terminals": terminals == null ? <UTerminalResponse>[] : List<UTerminalResponse>.from(terminals!.map((UTerminalResponse x) => x.toMap())), // terminals remains optional
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class MerchantJsonData {
  final String? detail1;
  final String? detail2;
  final String? businessTitle;
  final String? address;
  final String? ownerPhoneNumber;
  final int? definitionTemplate;
  final int? settlementCurrency;
  final String? ownerName;

  MerchantJsonData({
    this.detail1,
    this.detail2,
    this.businessTitle,
    this.address,
    this.ownerPhoneNumber,
    this.definitionTemplate,
    this.settlementCurrency,
    this.ownerName,
  });

  factory MerchantJsonData.fromJson(String str) => MerchantJsonData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MerchantJsonData.fromMap(Map<String, dynamic> json) => MerchantJsonData(
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
