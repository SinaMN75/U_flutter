part of "../data.dart";

class USimCardResponse {
  final String id;
  final String createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String number;
  final String? serial;
  final String userId;
  final UUserResponse? user;
  final List<String> adminUserIds;

  USimCardResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.number,
    required this.userId,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
    this.serial,
    this.user,
  });

  factory USimCardResponse.fromJson(String str) => USimCardResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory USimCardResponse.fromMap(Map<String, dynamic> json) => USimCardResponse(
    id: json["id"] as String,
    createdAt: json["createdAt"] as String,
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    number: json["number"] as String,
    serial: json["serial"],
    userId: json["userId"] as String,
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt,
    "jsonData": jsonData.toJson(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "creator": creator?.toJson(),
    "creatorId": creatorId,
    "number": number,
    "serial": serial,
    "userId": userId,
    "user": user?.toJson(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}
