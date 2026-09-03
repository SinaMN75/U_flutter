part of "../data.dart";

class UCommentCreateParams {
  UCommentCreateParams({
    required this.description,
    required this.score,
    required this.tags,
    this.reaction,
    this.parentId,
    this.productId,
    this.blogId,
    this.hotelId,
    this.dormId,
    this.userId,
    this.creatorId,
    this.detail1,
    this.detail2,
    this.id,
    this.adminUserIds,
  });

  factory UCommentCreateParams.fromJson(String str) => UCommentCreateParams.fromMap(json.decode(str));

  factory UCommentCreateParams.fromMap(Map<String, dynamic> json) => UCommentCreateParams(
    description: json["description"],
    score: json["score"] ?? 0,
    reaction: json["reaction"],
    parentId: json["parentId"],
    productId: json["productId"],
    blogId: json["blogId"],
    hotelId: json["hotelId"],
    dormId: json["dormId"],
    userId: json["userId"],
    creatorId: json["creatorId"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    id: json["id"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );
  final String description;
  final double score;
  final int? reaction;
  final String? parentId;
  final String? productId;
  final String? blogId;
  final String? hotelId;
  final String? dormId;
  final String? userId;
  final String? creatorId;
  final List<int> tags;
  final String? detail1;
  final String? detail2;
  final String? id;
  final List<String>? adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "description": description,
    "score": score,
    "reaction": reaction,
    "parentId": parentId,
    "productId": productId,
    "blogId": blogId,
    "hotelId": hotelId,
    "dormId": dormId,
    "userId": userId,
    "creatorId": creatorId,
    "tags": List<dynamic>.from(tags.map((dynamic x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "id": id,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UCommentUpdateParams {
  UCommentUpdateParams({
    required this.id,
    this.description,
    this.score,
    this.addTags,
    this.removeTags,
    this.tags,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UCommentUpdateParams.fromJson(String str) => UCommentUpdateParams.fromMap(json.decode(str));

  factory UCommentUpdateParams.fromMap(Map<String, dynamic> json) => UCommentUpdateParams(
    description: json["description"],
    score: json["score"],
    id: json["id"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );
  final String? description;
  final double? score;
  final String id;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "description": description,
    "score": score,
    "id": id,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((dynamic x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((dynamic x) => x)),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((dynamic x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UCommentReadParams {
  UCommentReadParams({
    this.creatorId,
    this.productId,
    this.blogId,
    this.hotelId,
    this.dormId,
    this.userId,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.selectorArgs,
    this.orderBy,
    this.ids,
  });

  factory UCommentReadParams.fromJson(String str) => UCommentReadParams.fromMap(json.decode(str));

  factory UCommentReadParams.fromMap(Map<String, dynamic> json) => UCommentReadParams(
    creatorId: json["creatorId"],
    productId: json["productId"],
    blogId: json["blogId"],
    hotelId: json["hotelId"],
    dormId: json["dormId"],
    userId: json["userId"],
    pageSize: json["pageSize"] ?? 0,
    pageNumber: json["pageNumber"] ?? 0,
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    selectorArgs: json["selectorArgs"] == null ? null : CommentSelectorArgs.fromMap(json["selectorArgs"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
  );
  final String? creatorId;
  final String? productId;
  final String? blogId;
  final String? hotelId;
  final String? dormId;
  final String? userId;
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final CommentSelectorArgs? selectorArgs;
  final List<int>? tags;
  final int? orderBy;
  final List<String>? ids;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creatorId": creatorId,
    "productId": productId,
    "blogId": blogId,
    "hotelId": hotelId,
    "dormId": dormId,
    "userId": userId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "selectorArgs": selectorArgs?.toMap(),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((dynamic x) => x)),
    "orderBy": orderBy,
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
  };
}
