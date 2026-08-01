part of "../data.dart";

class UBlogResponse {
  final String id;
  final DateTime createdAt;
  final UBlogJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;
  final String title;
  final String? subtitle;
  final String? slug;
  final String? content;
  final List<UMediaResponse>? media;
  final List<UCategoryResponse>? categories;
  final List<UCommentResponse>? comments;
  final int? commentCount;
  final String? code;
  final String? description;
  final String? type;
  final double? latitude;
  final double? longitude;
  final String? parentId;
  final List<UBlogResponse>? children;
  final int? childrenCount;

  UBlogResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    this.adminUserIds = const <String>[],
    this.creator,
    this.creatorId,
    this.subtitle,
    this.slug,
    this.content,
    this.media,
    this.categories,
    this.comments,
    this.commentCount,
    this.code,
    this.description,
    this.type,
    this.latitude,
    this.longitude,
    this.parentId,
    this.children,
    this.childrenCount,
  });

  factory UBlogResponse.fromJson(String str) => UBlogResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBlogResponse.fromMap(Map<String, dynamic> json) => UBlogResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBlogJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    title: json["title"] as String,
    subtitle: json["subtitle"],
    slug: json["slug"],
    content: json["content"],
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"]!.map((dynamic x) => UMediaResponse.fromMap(x))),
    categories: json["categories"] == null ? <UCategoryResponse>[] : List<UCategoryResponse>.from(json["categories"]!.map((dynamic x) => UCategoryResponse.fromMap(x))),
    comments: json["comments"] == null ? <UCommentResponse>[] : List<UCommentResponse>.from(json["comments"]!.map((dynamic x) => UCommentResponse.fromMap(x))),
    commentCount: json["commentCount"],
    code: json["code"],
    description: json["description"],
    type: json["type"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    parentId: json["parentId"],
    children: json["children"] == null ? <UBlogResponse>[] : List<UBlogResponse>.from(json["children"]!.map((dynamic x) => UBlogResponse.fromMap(x))),
    childrenCount: json["childrenCount"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<int>.from(tags.map((int x) => x)),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<String>.from(adminUserIds.map((String x) => x)),
    "title": title,
    "subtitle": subtitle,
    "slug": slug,
    "content": content,
    "media": media == null ? <UMediaResponse>[] : List<UMediaResponse>.from(media!.map((UMediaResponse x) => x.toMap())),
    "categories": categories == null ? <UCategoryResponse>[] : List<UCategoryResponse>.from(categories!.map((UCategoryResponse x) => x.toMap())),
    "comments": comments == null ? <UCommentResponse>[] : List<UCommentResponse>.from(comments!.map((UCommentResponse x) => x.toMap())),
    "commentCount": commentCount,
    "code": code,
    "description": description,
    "type": type,
    "latitude": latitude,
    "longitude": longitude,
    "parentId": parentId,
    "children": children == null ? <UBlogResponse>[] : List<UBlogResponse>.from(children!.map((UBlogResponse x) => x.toMap())),
    "childrenCount": childrenCount,
  };
}

class UBlogJson {
  final String? metaTitle;
  final String? metaDescription;
  final String? source;
  final String? detail1;
  final String? detail2;
  final String? actionType;
  final String? actionTitle;
  final String? actionUri;
  final List<String>? relatedBlogs;

  UBlogJson({
    this.metaTitle,
    this.metaDescription,
    this.source,
    this.detail1,
    this.detail2,
    this.actionType,
    this.actionTitle,
    this.actionUri,
    this.relatedBlogs,
  });

  factory UBlogJson.fromJson(String str) => UBlogJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBlogJson.fromMap(Map<String, dynamic> json) => UBlogJson(
    metaTitle: json["metaTitle"],
    metaDescription: json["metaDescription"],
    source: json["source"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    actionType: json["actionType"],
    actionTitle: json["actionTitle"],
    actionUri: json["actionUri"],
    relatedBlogs: json["relatedBlogs"] == null ? <String>[] : List<String>.from(json["relatedBlogs"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "metaTitle": metaTitle,
    "metaDescription": metaDescription,
    "source": source,
    "detail1": detail1,
    "detail2": detail2,
    "actionType": actionType,
    "actionTitle": actionTitle,
    "actionUri": actionUri,
    "relatedBlogs": relatedBlogs == null ? <dynamic>[] : List<dynamic>.from(relatedBlogs!.map((String x) => x)),
  };
}
