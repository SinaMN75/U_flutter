part of "../data.dart";

class UTxnResponse {
  final String id;
  final double amount;
  final String userId;
  final UTxnJson jsonData;
  final List<int> tags;
  final String? trackingNumber;
  final UUserResponse? user;
  final DateTime? createdAt;
  final String? creatorId;
  final UUserResponse? creator;
  final List<String> adminUserIds;

  UTxnResponse({
    required this.id,
    required this.amount,
    required this.userId,
    required this.jsonData,
    required this.tags,
    required this.trackingNumber,
    required this.adminUserIds,
    this.user,
    this.createdAt,
    this.creatorId,
    this.creator,
  });

  factory UTxnResponse.fromJson(String str) => UTxnResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTxnResponse.fromMap(Map<String, dynamic> json) => UTxnResponse(
    id: json["id"],
    amount: json["amount"].toString().toDouble(),
    userId: json["userId"] ?? "",
    jsonData: UTxnJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    trackingNumber: json["trackingNumber"],
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    creatorId: json["creatorId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "amount": amount,
    "userId": userId,
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "trackingNumber": trackingNumber,
    "user": user?.toMap(),
    "createdAt": createdAt?.toIso8601String(),
    "creatorId": creatorId,
    "creator": creator?.toMap(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UTxnJson {
  final List<UKeyValueData> keyValues;
  final String? detail1;
  final String? detail2;

  UTxnJson({
    this.keyValues = const <UKeyValueData>[],
    this.detail1,
    this.detail2,
  });

  factory UTxnJson.fromJson(String str) => UTxnJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTxnJson.fromMap(Map<String, dynamic> json) => UTxnJson(
    keyValues: json["keyValues"] == null ? <UKeyValueData>[] : List<UKeyValueData>.from(json["keyValues"]!.map((dynamic x) => UKeyValueData.fromMap(x))),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "keyValues": List<dynamic>.from(keyValues.map((UKeyValueData x) => x.toMap())),
    "detail1": detail1,
    "detail2": detail2,
  };
}
