part of "../data.dart";

class UCategoryCreateParams {
  UCategoryCreateParams({
    required this.title,
    required this.tags,
    this.id,
    this.subtitle,
    this.parentId,
    this.order,
    this.address,
    this.phoneNumber,
    this.code,
    this.location,
    this.type,
    this.link,
    this.relatedProducts,
    this.detail1,
    this.detail2,
    this.creatorId,
    this.adminUserIds,
    this.children,
    this.media,
  });

  factory UCategoryCreateParams.fromJson(String str) => UCategoryCreateParams.fromMap(json.decode(str));

  factory UCategoryCreateParams.fromMap(Map<String, dynamic> json) => UCategoryCreateParams(
    id: json["id"],
    title: json["title"],
    subtitle: json["subtitle"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    parentId: json["parentId"],
    order: json["order"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    code: json["code"],
    location: json["location"],
    type: json["type"],
    link: json["link"],
    relatedProducts: json["relatedProducts"] == null ? null : List<String>.from(json["relatedProducts"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    children: json["children"] == null ? <UCategoryCreateParams>[] : List<UCategoryCreateParams>.from(json["children"]!.map((dynamic x) => UCategoryCreateParams.fromMap(x))),
    media: json["media"] == null ? <String>[] : List<String>.from(json["media"]!.map((dynamic x) => x)),
  );
  final String? id;
  final String title;
  final String? subtitle;
  final List<int> tags;
  final String? parentId;
  final String? address;
  final String? phoneNumber;
  final String? code;
  final int? order;
  final String? location;
  final String? type;
  final String? link;
  final List<String>? relatedProducts;
  final String? detail1;
  final String? detail2;
  final String? creatorId;
  final List<String>? adminUserIds;
  final List<UCategoryCreateParams>? children;
  final List<String>? media;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "subtitle": subtitle,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "parentId": parentId,
    "order": order,
    "location": location,
    "type": type,
    "link": link,
    "address": address,
    "phoneNumber": phoneNumber,
    "code": code,
    "relatedProducts": relatedProducts == null ? null : List<dynamic>.from(relatedProducts!.map((String x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "children": children == null ? <UCategoryCreateParams>[] : List<UCategoryCreateParams>.from(children!.map((UCategoryCreateParams x) => x.toMap())),
    "media": media == null ? <dynamic>[] : List<dynamic>.from(media!.map((String x) => x)),
  };
}

class UCategoryUpdateParams {
  UCategoryUpdateParams({
    required this.id,
    this.title,
    this.subtitle,
    this.link,
    this.location,
    this.address,
    this.phoneNumber,
    this.code,
    this.type,
    this.order,
    this.parentId,
    this.relatedProducts,
    this.addTags,
    this.removeTags,
    this.tags,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.media,
  });

  factory UCategoryUpdateParams.fromJson(String str) => UCategoryUpdateParams.fromMap(json.decode(str));

  factory UCategoryUpdateParams.fromMap(Map<String, dynamic> json) => UCategoryUpdateParams(
    title: json["title"],
    subtitle: json["subtitle"],
    link: json["link"],
    location: json["location"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    code: json["code"],
    type: json["type"],
    order: json["order"],
    parentId: json["parentId"],
    relatedProducts: json["relatedProducts"] == null ? null : List<String>.from(json["relatedProducts"].map((dynamic x) => x)),
    id: json["id"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    media: json["media"] == null ? <String>[] : List<String>.from(json["media"]!.map((dynamic x) => x)),
  );
  final String? title;
  final String? subtitle;
  final String? link;
  final String? location;
  final String? address;
  final String? phoneNumber;
  final String? code;
  final String? type;
  final int? order;
  final String? parentId;
  final List<String>? relatedProducts;
  final String id;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final List<String>? media;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "subtitle": subtitle,
    "link": link,
    "location": location,
    "type": type,
    "order": order,
    "phoneNumber": phoneNumber,
    "address": address,
    "code": code,
    "parentId": parentId,
    "relatedProducts": relatedProducts == null ? null : List<dynamic>.from(relatedProducts!.map((String x) => x)),
    "id": id,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "media": media == null ? <dynamic>[] : List<dynamic>.from(media!.map((String x) => x)),
  };
}

class UCategoryReadParams {
  UCategoryReadParams({
    this.ids,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.selectorArgs,
    this.orderBy,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.creatorId,
  });

  factory UCategoryReadParams.fromJson(String str) => UCategoryReadParams.fromMap(json.decode(str));

  factory UCategoryReadParams.fromMap(Map<String, dynamic> json) => UCategoryReadParams(
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : CategorySelectorArgs.fromMap(json["selectorArgs"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    creatorId: json["creatorId"],
  );
  final List<String>? ids;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final CategorySelectorArgs? selectorArgs;
  final int? orderBy;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final String? creatorId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "ids": ids == null ? null : List<dynamic>.from(ids!.map((String x) => x)),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "orderBy": orderBy,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "creatorId": creatorId,
  };
}
