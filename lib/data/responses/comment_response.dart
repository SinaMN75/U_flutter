part of "../data.dart";

class UCommentResponse {
  UCommentResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.score,
    required this.description,
    required this.userId,
    required this.adminUserIds,
    this.parentId,
    this.user,
    this.creator,
    this.creatorId,
    this.productId,
    this.blogId,
    this.children,
    this.media,
  });

  factory UCommentResponse.fromJson(String str) => UCommentResponse.fromMap(json.decode(str));

  factory UCommentResponse.fromMap(Map<String, dynamic> json) => UCommentResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UCommentJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    score: json["score"],
    description: json["description"],
    parentId: json["parentId"],
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    userId: json["userId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    productId: json["productId"],
    blogId: json["blogId"],
    children: json["children"] == null ? <UCommentResponse>[] : List<UCommentResponse>.from(json["children"].map((dynamic x) => UCommentResponse.fromMap(x))),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );
  final String id;
  final DateTime createdAt;
  final UCommentJson jsonData;
  final List<int> tags;
  final double score;
  final String description;
  final String? parentId;
  final UUserResponse? user;
  final String userId;
  final UUserResponse? creator;
  final String? creatorId;
  final String? productId;
  final String? blogId;
  final List<UCommentResponse>? children;
  final List<UMediaResponse>? media;
  final List<String> adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "score": score,
    "description": description,
    "parentId": parentId,
    "user": user?.toMap(),
    "userId": userId,
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "productId": productId,
    "blogId": blogId,
    "children": children == null ? null : List<dynamic>.from(children!.map((UCommentResponse x) => x.toMap())),
    "media": media == null ? null : List<dynamic>.from(media!.map((UMediaResponse x) => x.toMap())),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UCommentJson {
  UCommentJson({
    this.reacts,
    this.detail1,
    this.detail2,
  });

  factory UCommentJson.fromJson(String str) => UCommentJson.fromMap(json.decode(str));

  factory UCommentJson.fromMap(Map<String, dynamic> json) => UCommentJson(
    reacts: json["reacts"] == null ? <UCommentReacts>[] : List<UCommentReacts>.from(json["reacts"].map((dynamic x) => UCommentReacts.fromMap(x))),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final List<UCommentReacts>? reacts;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reacts": reacts == null ? null : List<dynamic>.from(reacts!.map((UCommentReacts x) => x.toMap())),
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UCommentReacts {
  UCommentReacts({
    required this.tag,
    required this.userId,
  });

  factory UCommentReacts.fromJson(String str) => UCommentReacts.fromMap(json.decode(str));

  factory UCommentReacts.fromMap(Map<String, dynamic> json) => UCommentReacts(
    tag: json["tag"],
    userId: json["userId"],
  );
  final int tag;
  final String userId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tag": tag,
    "userId": userId,
  };
}
