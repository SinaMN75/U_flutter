part of "../data.dart";

class UMediaCreateParams {
  UMediaCreateParams({
    required this.file,
    required this.tag1,
    this.tag2,
    this.tag3,
    this.userId,
    this.contentId,
    this.commentId,
    this.categoryId,
    this.productId,
    this.blogId,
    this.title,
    this.description,
    this.creatorId,
    this.hotelId,
    this.hotelRoomId,
    this.dormId,
    this.dormRoomId,
    this.dormBedId,
  });

  final FileData file;
  final String? userId;
  final String? contentId;
  final String? commentId;
  final String? categoryId;
  final String? productId;
  final String? blogId;
  final String? title;
  final String? description;
  final int tag1;
  final int? tag2;
  final int? tag3;
  final String? creatorId;
  final String? hotelId;
  final String? hotelRoomId;
  final String? dormId;
  final String? dormRoomId;
  final String? dormBedId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "contentId": contentId,
    "commentId": commentId,
    "categoryId": categoryId,
    "productId": productId,
    "blogId": blogId,
    "title": title,
    "description": description,
    "tag1": tag1,
    "tag2": tag2,
    "tag3": tag3,
    "creatorId": creatorId,
    "hotelId": hotelId,
    "hotelRoomId": hotelRoomId,
    "dormId": dormId,
    "dormRoomId": dormRoomId,
    "dormBedId": dormBedId,
  };
}

class UMediaUpdateParams {
  UMediaUpdateParams({
    required this.id,
    this.addTags,
    this.removeTags,
    this.title,
    this.description,
    this.userId,
    this.contentId,
    this.commentId,
    this.categoryId,
    this.productId,
    this.blogId,
    this.detail1,
    this.detail2,
    this.tags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.hotelId,
    this.hotelRoomId,
    this.dormId,
    this.dormRoomId,
    this.dormBedId,
  });

  factory UMediaUpdateParams.fromJson(String str) => UMediaUpdateParams.fromMap(json.decode(str));

  factory UMediaUpdateParams.fromMap(Map<String, dynamic> json) => UMediaUpdateParams(
    id: json["id"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    title: json["title"],
    description: json["description"],
    userId: json["userId"],
    contentId: json["contentId"],
    commentId: json["commentId"],
    categoryId: json["categoryId"],
    productId: json["productId"],
    blogId: json["blogId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    hotelId: json["hotelId"],
    hotelRoomId: json["hotelRoomId"],
    dormId: json["dormId"],
    dormRoomId: json["dormRoomId"],
    dormBedId: json["dormBedId"],
  );

  final String id;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? title;
  final String? description;
  final String? userId;
  final String? contentId;
  final String? commentId;
  final String? categoryId;
  final String? productId;
  final String? blogId;
  final String? detail1;
  final String? detail2;
  final List<int>? tags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final String? hotelId;
  final String? hotelRoomId;
  final String? dormId;
  final String? dormRoomId;
  final String? dormBedId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "title": title,
    "description": description,
    "userId": userId,
    "contentId": contentId,
    "commentId": commentId,
    "categoryId": categoryId,
    "productId": productId,
    "blogId": blogId,
    "detail1": detail1,
    "detail2": detail2,
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "hotelId": hotelId,
    "hotelRoomId": hotelRoomId,
    "dormId": dormId,
    "dormRoomId": dormRoomId,
    "dormBedId": dormBedId,
  };
}

class UMediaReadParams {
  UMediaReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.orderBy,
  });

  factory UMediaReadParams.fromJson(String str) => UMediaReadParams.fromMap(json.decode(str));

  factory UMediaReadParams.fromMap(Map<String, dynamic> json) => UMediaReadParams(
    pageSize: json["pageSize"] ?? 0,
    pageNumber: json["pageNumber"] ?? 0,
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
  );

  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final int? orderBy;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "orderBy": orderBy,
  };
}
