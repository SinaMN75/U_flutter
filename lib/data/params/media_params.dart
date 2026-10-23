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
    this.venueId,
    this.postId,
  });

  final UFileData file;
  final String? userId;
  final String? contentId;
  final String? commentId;
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
  final String? venueId;
  final String? postId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "contentId": contentId,
    "commentId": commentId,
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
    "venueId": venueId,
    "postId": postId,
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
