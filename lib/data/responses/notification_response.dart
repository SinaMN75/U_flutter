part of "../data.dart";

class UNotificationResponse {
  UNotificationResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.userId,
    required this.adminUserIds,
    this.user,
    this.creator,
    this.creatorId,
    this.zipCode,
  });

  factory UNotificationResponse.fromJson(String str) => UNotificationResponse.fromMap(json.decode(str));

  factory UNotificationResponse.fromMap(Map<String, dynamic> json) => UNotificationResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UNotificationJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    userId: json["userId"],
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    zipCode: json["zipCode"],
  );
  final String id;
  final DateTime createdAt;
  final UNotificationJson jsonData;
  final List<int> tags;
  final String userId;
  final UUserResponse? user;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;
  final String? zipCode;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "userId": userId,
    "user": user?.toMap(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
    "zipCode": zipCode,
  };

  /// What the notification opens (a 3xx tag), with [UNotificationJson.linkId].
  TagNotification? get link => TagNotification.values.group(300).firstWhereOrNull((TagNotification x) => tags.contains(x.number));
}

class UNotificationJson {
  UNotificationJson({
    this.detail1,
    this.detail2,
    this.linkId,
  });

  factory UNotificationJson.fromJson(String str) => UNotificationJson.fromMap(json.decode(str));

  factory UNotificationJson.fromMap(Map<String, dynamic> json) => UNotificationJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    linkId: json["linkId"],
  );

  /// Title, or a message key the app resolves itself.
  final String? detail1;
  final String? detail2;

  /// The id of what the notification opens; what it is comes from [UNotificationResponse.link].
  final String? linkId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "linkId": linkId,
  };
}
