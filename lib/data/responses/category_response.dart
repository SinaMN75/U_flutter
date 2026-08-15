part of "../data.dart";

extension CategoryListExtension on Iterable<UCategoryResponse> {
  List<UCategoryResponse> whereByTag(int tag) => where((UCategoryResponse i) => i.tags.contains(tag)).toList();

  UCategoryResponse? firstWhereByTagOrNull(int tag) => firstWhereOrNull((UCategoryResponse i) => i.tags.contains(tag));
}

extension NullableCategoryListExtension on Iterable<UCategoryResponse>? {
  List<UCategoryResponse> whereByTag(int tag) => (this ?? <UCategoryResponse>[]).where((UCategoryResponse i) => i.tags.contains(tag)).toList();

  UCategoryResponse? firstWhereByTagOrNull(int tag) => (this ?? <UCategoryResponse>[]).firstWhereOrNull((UCategoryResponse i) => i.tags.contains(tag));
}

class UCategoryResponse {
  UCategoryResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.adminUserIds,
    this.code,
    this.parentId,
    this.order,
    this.children,
    this.media,
    this.creator,
    this.creatorId,
  });

  factory UCategoryResponse.fromJson(String str) => UCategoryResponse.fromMap(json.decode(str));

  factory UCategoryResponse.fromMap(Map<String, dynamic> json) => UCategoryResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UCategoryJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    code: json["code"],
    parentId: json["parentId"],
    order: json["order"],
    children: json["children"] == null ? <UCategoryResponse>[] : List<UCategoryResponse>.from(json["children"].map((dynamic x) => UCategoryResponse.fromMap(x))),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );
  final String id;
  final DateTime createdAt;
  final UCategoryJson jsonData;
  final List<int> tags;
  final String title;
  final String? code;
  final String? parentId;
  final int? order;
  final List<UCategoryResponse>? children;
  final List<UMediaResponse>? media;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "parentId": parentId,
    "order": order,
    "code": code,
    "children": children == null ? null : List<dynamic>.from(children!.map((UCategoryResponse x) => x.toMap())),
    "media": children == null ? null : List<dynamic>.from(media!.map((UMediaResponse x) => x.toMap())),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UCategoryJson {
  UCategoryJson({
    this.subtitle,
    this.link,
    this.location,
    this.type,
    this.address,
    this.phoneNumber,
    this.relatedProducts,
    this.detail1,
    this.detail2,
  });

  factory UCategoryJson.fromJson(String str) => UCategoryJson.fromMap(json.decode(str));

  factory UCategoryJson.fromMap(Map<String, dynamic> json) => UCategoryJson(
    subtitle: json["subtitle"],
    link: json["link"],
    location: json["location"],
    type: json["type"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    relatedProducts: json["relatedProducts"] == null ? <String>[] : List<String>.from(json["relatedProducts"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String? subtitle;
  final String? link;
  final String? location;
  final String? type;
  final String? address;
  final String? phoneNumber;
  final List<String>? relatedProducts;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "subtitle": subtitle,
    "link": link,
    "location": location,
    "type": type,
    "phoneNumber": phoneNumber,
    "address": address,
    "relatedProducts": relatedProducts == null ? null : List<dynamic>.from(relatedProducts!.map((String x) => x)),
    "detail1": detail1,
    "detail2": detail2,
  };
}
