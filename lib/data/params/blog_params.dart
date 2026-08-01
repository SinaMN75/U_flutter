part of "../data.dart";

class UBlogCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;
  final String title;
  final String? subtitle;
  final String? slug;
  final String? content;
  final String? metaTitle;
  final String? metaDescription;
  final String? source;
  final List<String>? categories;
  final List<String>? media;
  final String? code;
  final String? description;
  final String? type;
  final String? actionType;
  final String? actionTitle;
  final String? actionUri;
  final double? latitude;
  final double? longitude;
  final String? parentId;
  final List<String>? relatedBlogs;
  final List<UBlogCreateParams>? children;

  UBlogCreateParams({
    required this.tags,
    required this.title,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
    this.subtitle,
    this.slug,
    this.content,
    this.metaTitle,
    this.metaDescription,
    this.source,
    this.categories,
    this.media,
    this.code,
    this.description,
    this.type,
    this.actionType,
    this.actionTitle,
    this.actionUri,
    this.latitude,
    this.longitude,
    this.parentId,
    this.relatedBlogs,
    this.children,
  });

  factory UBlogCreateParams.fromJson(String str) => UBlogCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBlogCreateParams.fromMap(Map<String, dynamic> json) => UBlogCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    title: json["title"],
    subtitle: json["subtitle"],
    slug: json["slug"],
    content: json["content"],
    metaTitle: json["metaTitle"],
    metaDescription: json["metaDescription"],
    source: json["source"],
    categories: json["categories"] == null ? <String>[] : List<String>.from(json["categories"]!.map((dynamic x) => x)),
    media: json["media"] == null ? <String>[] : List<String>.from(json["media"]!.map((dynamic x) => x)),
    code: json["code"],
    description: json["description"],
    type: json["type"],
    actionType: json["actionType"],
    actionTitle: json["actionTitle"],
    actionUri: json["actionUri"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    parentId: json["parentId"],
    relatedBlogs: json["relatedBlogs"] == null ? <String>[] : List<String>.from(json["relatedBlogs"]!.map((dynamic x) => x)),
    children: json["children"] == null ? <UBlogCreateParams>[] : List<UBlogCreateParams>.from(json["children"]!.map((dynamic x) => UBlogCreateParams.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "title": title,
    "subtitle": subtitle,
    "slug": slug,
    "content": content,
    "metaTitle": metaTitle,
    "metaDescription": metaDescription,
    "source": source,
    "categories": categories == null ? <dynamic>[] : List<dynamic>.from(categories!.map((String x) => x)),
    "media": media == null ? <dynamic>[] : List<dynamic>.from(media!.map((String x) => x)),
    "code": code,
    "description": description,
    "type": type,
    "actionType": actionType,
    "actionTitle": actionTitle,
    "actionUri": actionUri,
    "latitude": latitude,
    "longitude": longitude,
    "parentId": parentId,
    "relatedBlogs": relatedBlogs == null ? <dynamic>[] : List<dynamic>.from(relatedBlogs!.map((String x) => x)),
    "children": children == null ? <UBlogCreateParams>[] : List<UBlogCreateParams>.from(children!.map((UBlogCreateParams x) => x.toMap())),
  };
}

class UBlogUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final String? title;
  final String? subtitle;
  final String? slug;
  final String? content;
  final String? metaTitle;
  final String? metaDescription;
  final String? source;
  final List<String>? addCategories;
  final List<String>? removeCategories;
  final List<String>? categories;
  final List<String>? media;
  final String? code;
  final String? description;
  final String? type;
  final String? actionType;
  final String? actionTitle;
  final String? actionUri;
  final double? latitude;
  final double? longitude;
  final String? parentId;
  final String? creatorId;
  final List<String>? relatedBlogs;
  final List<String>? addRelatedBlogs;
  final List<String>? removeRelatedBlogs;

  UBlogUpdateParams({
    required this.id,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.title,
    this.subtitle,
    this.slug,
    this.content,
    this.metaTitle,
    this.metaDescription,
    this.source,
    this.addCategories,
    this.removeCategories,
    this.categories,
    this.media,
    this.code,
    this.description,
    this.type,
    this.actionType,
    this.actionTitle,
    this.actionUri,
    this.latitude,
    this.longitude,
    this.parentId,
    this.creatorId,
    this.relatedBlogs,
    this.addRelatedBlogs,
    this.removeRelatedBlogs,
  });

  factory UBlogUpdateParams.fromJson(String str) => UBlogUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBlogUpdateParams.fromMap(Map<String, dynamic> json) => UBlogUpdateParams(
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    title: json["title"],
    subtitle: json["subtitle"],
    slug: json["slug"],
    content: json["content"],
    metaTitle: json["metaTitle"],
    metaDescription: json["metaDescription"],
    source: json["source"],
    addCategories: json["addCategories"] == null ? <String>[] : List<String>.from(json["addCategories"]!.map((dynamic x) => x)),
    removeCategories: json["removeCategories"] == null ? <String>[] : List<String>.from(json["removeCategories"]!.map((dynamic x) => x)),
    categories: json["categories"] == null ? <String>[] : List<String>.from(json["categories"]!.map((dynamic x) => x)),
    media: json["media"] == null ? <String>[] : List<String>.from(json["media"]!.map((dynamic x) => x)),
    code: json["code"],
    description: json["description"],
    type: json["type"],
    actionType: json["actionType"],
    actionTitle: json["actionTitle"],
    actionUri: json["actionUri"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    parentId: json["parentId"],
    creatorId: json["creatorId"],
    relatedBlogs: json["relatedBlogs"] == null ? <String>[] : List<String>.from(json["relatedBlogs"]!.map((dynamic x) => x)),
    addRelatedBlogs: json["addRelatedBlogs"] == null ? <String>[] : List<String>.from(json["addRelatedBlogs"]!.map((dynamic x) => x)),
    removeRelatedBlogs: json["removeRelatedBlogs"] == null ? <String>[] : List<String>.from(json["removeRelatedBlogs"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "title": title,
    "subtitle": subtitle,
    "slug": slug,
    "content": content,
    "metaTitle": metaTitle,
    "metaDescription": metaDescription,
    "source": source,
    "addCategories": addCategories == null ? <dynamic>[] : List<dynamic>.from(addCategories!.map((String x) => x)),
    "removeCategories": removeCategories == null ? <dynamic>[] : List<dynamic>.from(removeCategories!.map((String x) => x)),
    "categories": categories == null ? <dynamic>[] : List<dynamic>.from(categories!.map((String x) => x)),
    "media": media == null ? <dynamic>[] : List<dynamic>.from(media!.map((String x) => x)),
    "code": code,
    "description": description,
    "type": type,
    "actionType": actionType,
    "actionTitle": actionTitle,
    "actionUri": actionUri,
    "latitude": latitude,
    "longitude": longitude,
    "parentId": parentId,
    "creatorId": creatorId,
    "relatedBlogs": relatedBlogs == null ? <dynamic>[] : List<dynamic>.from(relatedBlogs!.map((String x) => x)),
    "addRelatedBlogs": addRelatedBlogs == null ? <dynamic>[] : List<dynamic>.from(addRelatedBlogs!.map((String x) => x)),
    "removeRelatedBlogs": removeRelatedBlogs == null ? <dynamic>[] : List<dynamic>.from(removeRelatedBlogs!.map((String x) => x)),
  };
}

class UBlogReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? query;
  final String? title;
  final String? slug;
  final List<String>? categories;
  final BlogSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? code;
  final String? parentId;

  UBlogReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.query,
    this.title,
    this.slug,
    this.categories,
    this.selectorArgs,
    this.orderBy,
    this.code,
    this.parentId,
  });

  factory UBlogReadParams.fromJson(String str) => UBlogReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBlogReadParams.fromMap(Map<String, dynamic> json) => UBlogReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    query: json["query"],
    title: json["title"],
    slug: json["slug"],
    categories: json["categories"] == null ? <String>[] : List<String>.from(json["categories"]!.map((dynamic x) => x)),
    selectorArgs: json["selectorArgs"] == null ? null : BlogSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    code: json["code"],
    parentId: json["parentId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "query": query,
    "title": title,
    "slug": slug,
    "categories": categories == null ? <dynamic>[] : List<dynamic>.from(categories!.map((String x) => x)),
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "code": code,
    "parentId": parentId,
  };
}
