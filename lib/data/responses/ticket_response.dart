part of "../data.dart";

class UTicketResponse {
  UTicketResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.creatorId,
    required this.adminUserIds,
    this.creator,
    this.media,
  });

  factory UTicketResponse.fromMap(Map<String, dynamic> json) => UTicketResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UTicketJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]),
    creatorId: json["creatorId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  final String id;
  final DateTime createdAt;
  final UTicketJson jsonData;
  final List<int> tags;
  final String creatorId;
  final UUserResponse? creator;
  final List<UMediaResponse>? media;
  final List<String> adminUserIds;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "creator": creator?.toMap(),
    "media": media?.map((UMediaResponse e) => e.toMap()).toList(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };

  String toJson() => json.encode(toMap());

  factory UTicketResponse.fromJson(String str) => UTicketResponse.fromMap(json.decode(str));
}

class UTicketJson {
  UTicketJson({
    required this.title,
    required this.description,
    this.detail1,
    this.detail2,
    this.instagram,
    this.telegram,
    this.whatsapp,
    this.phone,
  });

  factory UTicketJson.fromMap(Map<String, dynamic> json) => UTicketJson(
    title: json["title"],
    description: json["description"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    instagram: json["instagram"],
    telegram: json["telegram"],
    whatsapp: json["whatsapp"],
    phone: json["phone"],
  );

  final String title;
  final String description;
  final String? detail1;
  final String? detail2;
  final String? instagram;
  final String? telegram;
  final String? whatsapp;
  final String? phone;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "description": description,
    "detail1": detail1,
    "detail2": detail2,
    "instagram": instagram,
    "telegram": telegram,
    "whatsapp": whatsapp,
    "phone": phone,
  };

  String toJson() => json.encode(toMap());

  factory UTicketJson.fromJson(String str) => UTicketJson.fromMap(json.decode(str));
}
