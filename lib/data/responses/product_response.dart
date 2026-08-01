part of "../data.dart";

class UProductResponse {
  UProductResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.point,
    required this.creatorId,
    required this.adminUserIds,
    required this.order,
    this.code,
    this.subtitle,
    this.description,
    this.slug,
    this.type,
    this.content,
    this.latitude,
    this.longitude,
    this.stock,
    this.parentId,
    this.creator,
    this.children,
    this.media,
    this.categories,
    this.commentCount,
    this.isFollowing,
    this.childrenCount,
  });

  factory UProductResponse.fromJson(String str) => UProductResponse.fromMap(json.decode(str));

  factory UProductResponse.fromMap(Map<String, dynamic> json) => UProductResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UProductJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    code: json["code"],
    subtitle: json["subtitle"],
    description: json["description"],
    slug: json["slug"],
    type: json["type"],
    content: json["content"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    stock: json["stock"],
    point: json["point"],
    parentId: json["parentId"],
    creatorId: json["creatorId"],
    commentCount: json["commentCount"],
    isFollowing: json["isFollowing"],
    childrenCount: json["childrenCount"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    children: json["children"] == null ? <UProductResponse>[] : List<UProductResponse>.from(json["children"].map((dynamic x) => UProductResponse.fromMap(x))),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    categories: json["categories"] == null ? <UCategoryResponse>[] : List<UCategoryResponse>.from(json["categories"].map((dynamic x) => UCategoryResponse.fromMap(x))),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    order: json["order"],
  );
  final String id;
  final DateTime createdAt;
  final UProductJson jsonData;
  final List<int> tags;
  final String title;
  final String? code;
  final String? subtitle;
  final String? description;
  final String? slug;
  final String? type;
  final String? content;
  final double? latitude;
  final double? longitude;
  final int? stock;
  final int point;
  final String? parentId;
  final String creatorId;
  final UUserResponse? creator;
  final List<UProductResponse>? children;
  final List<UMediaResponse>? media;
  final List<UCategoryResponse>? categories;
  final int? commentCount;
  final bool? isFollowing;
  final int? childrenCount;
  final List<String> adminUserIds;
  final int order;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "code": code,
    "subtitle": subtitle,
    "description": description,
    "slug": slug,
    "type": type,
    "point": point,
    "content": content,
    "latitude": latitude,
    "longitude": longitude,
    "stock": stock,
    "parentId": parentId,
    "creatorId": creatorId,
    "commentCount": commentCount,
    "isFollowing": isFollowing,
    "childrenCount": childrenCount,
    "creator": creator?.toMap(),
    "children": children == null ? null : List<dynamic>.from(children!.map((UProductResponse x) => x.toMap())),
    "media": media == null ? null : List<dynamic>.from(media!.map((UMediaResponse x) => x.toMap())),
    "categories": categories == null ? null : List<dynamic>.from(categories!.map((UCategoryResponse x) => x.toMap())),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
    "order": order,
  };
}

class UProductJson {
  UProductJson({
    this.actionType,
    this.actionTitle,
    this.actionUri,
    this.details,
    this.relatedProducts,
    this.phoneNumber,
    this.address,
    this.detail1,
    this.detail2,
  });

  factory UProductJson.fromJson(String str) => UProductJson.fromMap(json.decode(str));

  factory UProductJson.fromMap(Map<String, dynamic> json) => UProductJson(
    actionType: json["actionType"],
    actionTitle: json["actionTitle"],
    actionUri: json["actionUri"],
    details: json["details"],
    relatedProducts: json["relatedProducts"] == null ? <String>[] : List<String>.from(json["relatedProducts"].map((dynamic x) => x)),
    phoneNumber: json["phoneNumber"],
    address: json["address"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String? actionType;
  final String? actionTitle;
  final String? actionUri;
  final String? details;
  final List<String>? relatedProducts;
  final String? phoneNumber;
  final String? address;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "actionType": actionType,
    "actionTitle": actionTitle,
    "actionUri": actionUri,
    "details": details,
    "relatedProducts": relatedProducts == null ? null : List<dynamic>.from(relatedProducts!.map((String x) => x)),
    "phoneNumber": phoneNumber,
    "address": address,
    "detail1": detail1,
    "detail2": detail2,
  };
}
