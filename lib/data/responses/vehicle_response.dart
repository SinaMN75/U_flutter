part of "../data.dart";

class UVehicleResponse {
  final String licencePlate;
  final List<int> tags;
  final String id;
  final String? brand;
  final String? title;
  final String? color;
  final UUserResponse? creator;
  final String? creatorId;
  final UBaseJson jsonData;
  final DateTime createdAt;
  final List<String> adminUserIds;

  UVehicleResponse({
    required this.licencePlate,
    required this.tags,
    required this.id,
    required this.jsonData,
    required this.createdAt,
    required this.adminUserIds,
    this.brand,
    this.title,
    this.color,
    this.creator,
    this.creatorId,
  });

  factory UVehicleResponse.fromJson(String str) => UVehicleResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UVehicleResponse.fromMap(Map<String, dynamic> json) => UVehicleResponse(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    id: json["id"],
    title: json["title"],
    licencePlate: json["licencePlate"],
    brand: json["brand"],
    color: json["color"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    createdAt: DateTime.parse(json["createdAt"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "title": title,
    "licencePlate": licencePlate,
    "brand": brand,
    "color": color,
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "jsonData": jsonData.toMap(),
    "createdAt": createdAt.toIso8601String(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}
