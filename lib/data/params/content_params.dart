part of "../data.dart";

class UContentCreateParams {
  final List<String>? media;

  UContentCreateParams({
    required this.tags,
    this.title,
    this.detail1,
    this.detail2,
    this.imageBase64,
    this.iconBase64,
    this.buttonText,
    this.buttonLink,
    this.link,
    this.order,
    this.instagram,
    this.id,
    this.creatorId,
    this.adminUserIds,
    this.description,
    this.subTitle,
    this.telegram,
    this.whatsapp,
    this.phone,
    this.links = const <UContentLink>[],
    this.items = const <UContentItem>[],
    this.media,
  });

  factory UContentCreateParams.fromJson(String str) => UContentCreateParams.fromMap(json.decode(str));

  factory UContentCreateParams.fromMap(Map<String, dynamic> json) => UContentCreateParams(
    title: json["title"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    imageBase64: json["imageBase64"],
    iconBase64: json["iconBase64"],
    buttonText: json["buttonText"],
    buttonLink: json["buttonLink"],
    link: json["link"],
    order: json["order"],
    instagram: json["instagram"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    description: json["description"],
    subTitle: json["subTitle"],
    telegram: json["telegram"],
    whatsapp: json["whatsapp"],
    phone: json["phone"],
    links: json["links"] == null ? <UContentLink>[] : List<UContentLink>.from(json["links"].map((dynamic x) => UContentLink.fromMap(x))),
    items: json["items"] == null ? <UContentItem>[] : List<UContentItem>.from(json["items"].map((dynamic x) => UContentItem.fromMap(x))),
    media: json["media"] == null ? <String>[] : List<String>.from(json["media"]!.map((dynamic x) => x)),
  );
  final String? title;
  final String? detail1;
  final String? detail2;
  final String? imageBase64;
  final String? iconBase64;
  final String? buttonText;
  final String? buttonLink;
  final String? link;
  final int? order;
  final String? instagram;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;
  final String? description;
  final String? subTitle;
  final String? telegram;
  final String? whatsapp;
  final String? phone;
  final List<UContentLink> links;
  final List<UContentItem> items;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "detail1": detail1,
    "detail2": detail2,
    "imageBase64": imageBase64,
    "iconBase64": iconBase64,
    "buttonText": buttonText,
    "buttonLink": buttonLink,
    "link": link,
    "order": order,
    "instagram": instagram,
    "tags": List<dynamic>.from(tags.map((dynamic x) => x)),
    "id": id,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "description": description,
    "subTitle": subTitle,
    "telegram": telegram,
    "whatsapp": whatsapp,
    "phone": phone,
    "links": List<dynamic>.from(links.map((UContentLink x) => x.toMap())),
    "items": List<dynamic>.from(items.map((UContentItem x) => x.toMap())),
    "media": media == null ? <dynamic>[] : List<dynamic>.from(media!.map((String x) => x)),
  };
}

class UContentUpdateParams {
  final String? creatorId;
  final List<String>? media;

  UContentUpdateParams({
    required this.id,
    this.title,
    this.detail1,
    this.detail2,
    this.imageBase64,
    this.iconBase64,
    this.buttonText,
    this.buttonLink,
    this.link,
    this.order,
    this.instagram,
    this.addTags,
    this.removeTags,
    this.tags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.description,
    this.subTitle,
    this.telegram,
    this.whatsapp,
    this.phone,
    this.links,
    this.items,
    this.creatorId,
    this.media,
  });

  factory UContentUpdateParams.fromJson(String str) => UContentUpdateParams.fromMap(json.decode(str));

  factory UContentUpdateParams.fromMap(Map<String, dynamic> json) => UContentUpdateParams(
    id: json["id"],
    title: json["title"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    imageBase64: json["imageBase64"],
    iconBase64: json["iconBase64"],
    buttonText: json["buttonText"],
    buttonLink: json["buttonLink"],
    link: json["link"],
    order: json["order"],
    instagram: json["instagram"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    description: json["description"],
    subTitle: json["subTitle"],
    telegram: json["telegram"],
    whatsapp: json["whatsapp"],
    phone: json["phone"],
    links: json["links"] == null ? null : List<UContentLink>.from(json["links"].map((dynamic x) => UContentLink.fromMap(x))),
    items: json["items"] == null ? null : List<UContentItem>.from(json["items"].map((dynamic x) => UContentItem.fromMap(x))),
    creatorId: json["creatorId"],
    media: json["media"] == null ? <String>[] : List<String>.from(json["media"]!.map((dynamic x) => x)),
  );
  final String id;
  final String? title;
  final String? detail1;
  final String? detail2;
  final String? imageBase64;
  final String? iconBase64;
  final String? buttonText;
  final String? buttonLink;
  final String? link;
  final int? order;
  final String? instagram;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final String? description;
  final String? subTitle;
  final String? telegram;
  final String? whatsapp;
  final String? phone;
  final List<UContentLink>? links;
  final List<UContentItem>? items;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "detail1": detail1,
    "detail2": detail2,
    "imageBase64": imageBase64,
    "iconBase64": iconBase64,
    "buttonText": buttonText,
    "buttonLink": buttonLink,
    "link": link,
    "order": order,
    "instagram": instagram,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((dynamic x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((dynamic x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "description": description,
    "subTitle": subTitle,
    "telegram": telegram,
    "whatsapp": whatsapp,
    "phone": phone,
    "links": links == null ? null : List<dynamic>.from(links!.map((UContentLink x) => x.toMap())),
    "items": items == null ? null : List<dynamic>.from(items!.map((UContentItem x) => x.toMap())),
    "creatorId": creatorId,
    "media": media == null ? <dynamic>[] : List<dynamic>.from(media!.map((String x) => x)),
  };
}

class UContentReadParams {
  final String? query;

  UContentReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.selectorArgs,
    this.orderBy,
    this.ids,
    this.creatorId,
    this.query,
  });

  factory UContentReadParams.fromJson(String str) => UContentReadParams.fromMap(json.decode(str));

  factory UContentReadParams.fromMap(Map<String, dynamic> json) => UContentReadParams(
    pageSize: json["pageSize"] ?? 0,
    pageNumber: json["pageNumber"] ?? 0,
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    selectorArgs: json["selectorArgs"] == null ? null : ContentSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    query: json["query"],
  );
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final ContentSelectorArgs? selectorArgs;
  final int? orderBy;
  final List<String>? ids;
  final String? creatorId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((dynamic x) => x)),
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "query": query,
  };
}
