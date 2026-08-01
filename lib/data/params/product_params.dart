part of "../data.dart";

class UProductCreateParams {
  UProductCreateParams({
    required this.title,
    required this.tags,
    this.code,
    this.subtitle,
    this.description,
    this.actionType,
    this.actionTitle,
    this.actionUri,
    this.slug,
    this.type,
    this.content,
    this.latitude,
    this.longitude,
    this.stock,
    this.details,
    this.categories,
    this.relatedProducts,
    this.parentId,
    this.creatorId,
    this.point,
    this.phoneNumber,
    this.address,
    this.detail1,
    this.detail2,
    this.id,
    this.adminUserIds,
    this.order,
    this.children,
    this.media,
  });

  factory UProductCreateParams.fromJson(String str) => UProductCreateParams.fromMap(json.decode(str));

  factory UProductCreateParams.fromMap(Map<String, dynamic> json) => UProductCreateParams(
    title: json["title"],
    code: json["code"],
    subtitle: json["subtitle"],
    description: json["description"],
    actionType: json["actionType"],
    actionTitle: json["actionTitle"],
    actionUri: json["actionUri"],
    slug: json["slug"],
    type: json["type"],
    content: json["content"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    stock: json["stock"],
    details: json["details"],
    point: json["point"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    categories: json["categories"] == null ? null : List<String>.from(json["categories"].map((dynamic x) => x)),
    relatedProducts: json["relatedProducts"] == null ? null : List<String>.from(json["relatedProducts"].map((dynamic x) => x)),
    parentId: json["parentId"],
    creatorId: json["creatorId"],
    phoneNumber: json["phoneNumber"],
    address: json["address"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    id: json["id"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    order: json["order"],
    children: json["children"] == null ? <UProductCreateParams>[] : List<UProductCreateParams>.from(json["children"]!.map((dynamic x) => UProductCreateParams.fromMap(x))),
    media: json["media"] == null ? <String>[] : List<String>.from(json["media"]!.map((dynamic x) => x)),
  );
  final String title;
  final String? code;
  final String? subtitle;
  final String? description;
  final String? actionType;
  final String? actionTitle;
  final String? actionUri;
  final String? slug;
  final String? type;
  final String? content;
  final double? latitude;
  final double? longitude;
  final int? stock;
  final String? details;
  final List<int> tags;
  final List<String>? categories;
  final List<String>? relatedProducts;
  final String? parentId;
  final String? creatorId;
  final int? point;
  final String? phoneNumber;
  final String? address;
  final String? detail1;
  final String? detail2;
  final String? id;
  final List<String>? adminUserIds;
  final int? order;
  final List<UProductCreateParams>? children;
  final List<String>? media;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "code": code,
    "subtitle": subtitle,
    "description": description,
    "actionType": actionType,
    "actionTitle": actionTitle,
    "actionUri": actionUri,
    "slug": slug,
    "type": type,
    "content": content,
    "latitude": latitude,
    "longitude": longitude,
    "stock": stock,
    "details": details,
    "tags": List<dynamic>.from(tags.map((dynamic x) => x)),
    "categories": categories == null ? null : List<dynamic>.from(categories!.map((dynamic x) => x)),
    "relatedProducts": relatedProducts == null ? null : List<dynamic>.from(relatedProducts!.map((dynamic x) => x)),
    "parentId": parentId,
    "creatorId": creatorId,
    "point": point,
    "phoneNumber": phoneNumber,
    "address": address,
    "detail1": detail1,
    "detail2": detail2,
    "id": id,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "order": order,
    "children": children == null ? <UProductCreateParams>[] : List<UProductCreateParams>.from(children!.map((UProductCreateParams x) => x.toMap())),
    "media": media == null ? <dynamic>[] : List<dynamic>.from(media!.map((String x) => x)),
  };
}

class UProductUpdateParams {
  UProductUpdateParams({
    required this.id,
    this.title,
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
    this.creatorId,
    this.actionType,
    this.actionTitle,
    this.actionUri,
    this.details,
    this.relatedProducts,
    this.addRelatedProducts,
    this.removeRelatedProducts,
    this.addCategories,
    this.categories,
    this.removeCategories,
    this.addTags,
    this.removeTags,
    this.tags,
    this.point,
    this.phoneNumber,
    this.address,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.order,
    this.media,
  });

  factory UProductUpdateParams.fromJson(String str) => UProductUpdateParams.fromMap(json.decode(str));

  factory UProductUpdateParams.fromMap(Map<String, dynamic> json) => UProductUpdateParams(
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
    actionType: json["actionType"],
    actionTitle: json["actionTitle"],
    actionUri: json["actionUri"],
    details: json["details"],
    relatedProducts: json["relatedProducts"] == null ? null : List<String>.from(json["relatedProducts"].map((dynamic x) => x)),
    addRelatedProducts: json["addRelatedProducts"] == null ? null : List<String>.from(json["addRelatedProducts"].map((dynamic x) => x)),
    removeRelatedProducts: json["removeRelatedProducts"] == null ? null : List<String>.from(json["removeRelatedProducts"].map((dynamic x) => x)),
    addCategories: json["addCategories"] == null ? null : List<String>.from(json["addCategories"].map((dynamic x) => x)),
    removeCategories: json["removeCategories"] == null ? null : List<String>.from(json["removeCategories"].map((dynamic x) => x)),
    categories: json["categories"] == null ? null : List<String>.from(json["categories"].map((dynamic x) => x)),
    id: json["id"],
    phoneNumber: json["phoneNumber"],
    address: json["address"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    order: json["order"],
    media: json["media"] == null ? <String>[] : List<String>.from(json["media"]!.map((dynamic x) => x)),
  );
  final String? title;
  final String? code;
  final String? subtitle;
  final String? description;
  final String? slug;
  final String? type;
  final String? content;
  final double? latitude;
  final double? longitude;
  final int? stock;
  final String? parentId;
  final String? creatorId;
  final String? actionType;
  final String? actionTitle;
  final String? actionUri;
  final String? details;
  final List<String>? relatedProducts;
  final List<String>? addRelatedProducts;
  final List<String>? removeRelatedProducts;
  final List<String>? addCategories;
  final List<String>? removeCategories;
  final List<String>? categories;
  final String id;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final int? point;
  final String? phoneNumber;
  final String? address;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final int? order;
  final List<String>? media;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "code": code,
    "subtitle": subtitle,
    "description": description,
    "slug": slug,
    "type": type,
    "content": content,
    "latitude": latitude,
    "longitude": longitude,
    "stock": stock,
    "parentId": parentId,
    "creatorId": creatorId,
    "point": point,
    "actionType": actionType,
    "actionTitle": actionTitle,
    "actionUri": actionUri,
    "details": details,
    "relatedProducts": relatedProducts == null ? null : List<dynamic>.from(relatedProducts!.map((dynamic x) => x)),
    "addRelatedProducts": addRelatedProducts == null ? null : List<dynamic>.from(addRelatedProducts!.map((dynamic x) => x)),
    "removeRelatedProducts": removeRelatedProducts == null ? null : List<dynamic>.from(removeRelatedProducts!.map((dynamic x) => x)),
    "addCategories": addCategories == null ? null : List<dynamic>.from(addCategories!.map((dynamic x) => x)),
    "removeCategories": removeCategories == null ? null : List<dynamic>.from(removeCategories!.map((dynamic x) => x)),
    "categories": categories == null ? null : List<dynamic>.from(categories!.map((dynamic x) => x)),
    "id": id,
    "phoneNumber": phoneNumber,
    "address": address,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((dynamic x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((dynamic x) => x)),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((dynamic x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "order": order,
    "media": media == null ? <dynamic>[] : List<dynamic>.from(media!.map((String x) => x)),
  };
}

class UProductReadParams {
  UProductReadParams({
    this.query,
    this.title,
    this.code,
    this.parentId,
    this.creatorId,
    this.minStock,
    this.maxStock,
    this.ids,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.selectorArgs,
    this.categories,
    this.orderBy,
    this.slug,
  });

  factory UProductReadParams.fromJson(String str) => UProductReadParams.fromMap(json.decode(str));

  factory UProductReadParams.fromMap(Map<String, dynamic> json) => UProductReadParams(
    query: json["query"],
    title: json["title"],
    code: json["code"],
    parentId: json["parentId"],
    creatorId: json["creatorId"],
    minStock: json["minStock"],
    maxStock: json["maxStock"],
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    pageSize: json["pageSize"] ?? 0,
    pageNumber: json["pageNumber"] ?? 0,
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    selectorArgs: json["selectorArgs"] == null ? null : ProductSelectorArgs.fromMap(json["selectorArgs"]),
    categories: json["categories"] == null ? null : List<String>.from(json["categories"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    slug: json["slug"],
  );
  final String? query;
  final String? title;
  final String? code;
  final String? parentId;
  final String? creatorId;
  final int? minStock;
  final int? maxStock;
  final List<String>? ids;
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? categories;
  final ProductSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? slug;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "query": query,
    "title": title,
    "code": code,
    "parentId": parentId,
    "creatorId": creatorId,
    "minStock": minStock,
    "maxStock": maxStock,
    "ids": ids == null ? null : List<dynamic>.from(ids!.map((dynamic x) => x)),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((dynamic x) => x)),
    "selectorArgs": selectorArgs?.toMap(),
    "categories": categories == null ? null : List<dynamic>.from(categories!.map((dynamic x) => x)),
    "orderBy": orderBy,
    "slug": slug,
  };
}
