part of "../data.dart";

class UTxnResponse {
  final String id;
  final double amount;
  final String userId;
  final UBaseJson jsonData;
  final List<int> tags;
  final String? trackingNumber;
  final UUserResponse? user;
  final String? createdAt;
  final String? creatorId;
  final UUserResponse? creator;
  final List<String> adminUserIds;

  UTxnResponse({
    required this.id,
    required this.jsonData,
    required this.tags,
    required this.amount,
    required this.userId,
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
    amount: json["amount"].toString().toDouble(),
    trackingNumber: json["trackingNumber"],
    userId: json["userId"],
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    id: json["id"],
    createdAt: json["createdAt"],
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "amount": amount,
    "trackingNumber": trackingNumber,
    "userId": userId,
    "user": user?.toMap(),
    "id": id,
    "createdAt": createdAt,
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "creatorId": creatorId,
    "creator": creator?.toMap(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}
