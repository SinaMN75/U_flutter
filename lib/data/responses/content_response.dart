part of "../data.dart";

extension ContentListExtension on Iterable<UContentResponse> {
  UContentResponse? firstByTag(TagContent tag) => firstWhereOrNull((final UContentResponse i) => i.tags.contains(tag.number));

  List<UContentResponse> byTag(TagContent tag) => where((final UContentResponse i) => i.tags.contains(tag.number)).toList();
}

class UContentResponse {
  UContentResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
    this.media = const <UMediaResponse>[],
  });

  factory UContentResponse.fromJson(String str) => UContentResponse.fromMap(json.decode(str));

  factory UContentResponse.fromMap(Map<String, dynamic> json) => UContentResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UContentJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  final String id;
  final DateTime createdAt;
  final UContentJson jsonData;
  final List<int> tags;
  final List<UMediaResponse> media;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "media": List<dynamic>.from(media.map((UMediaResponse x) => x.toMap())),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UContentJson {
  UContentJson({
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
    this.telegram,
    this.whatsapp,
    this.phone,
    this.subTitle,
    this.description,
    this.links = const <UContentLink>[],
    this.items = const <UContentItem>[],
  });

  factory UContentJson.fromJson(String str) => UContentJson.fromMap(json.decode(str));

  factory UContentJson.fromMap(Map<String, dynamic> json) => UContentJson(
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
    telegram: json["telegram"],
    whatsapp: json["whatsapp"],
    phone: json["phone"],
    subTitle: json["subTitle"],
    description: json["description"],
    links: json["links"] == null ? <UContentLink>[] : List<UContentLink>.from(json["links"].map((dynamic x) => UContentLink.fromMap(x))),
    items: json["items"] == null ? <UContentItem>[] : List<UContentItem>.from(json["items"].map((dynamic x) => UContentItem.fromMap(x))),
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
  final String? telegram;
  final String? whatsapp;
  final String? phone;
  final String? subTitle;
  final String? description;
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
    "telegram": telegram,
    "whatsapp": whatsapp,
    "phone": phone,
    "subTitle": subTitle,
    "description": description,
    "links": List<dynamic>.from(links.map((UContentLink x) => x.toMap())),
    "items": List<dynamic>.from(items.map((UContentItem x) => x.toMap())),
  };
}

class UContentItem {
  UContentItem({
    this.title,
    this.subTitle,
    this.description,
    this.iconBase64,
    this.imageBase64,
    this.link,
    this.order,
  });

  factory UContentItem.fromJson(String str) => UContentItem.fromMap(json.decode(str));

  factory UContentItem.fromMap(Map<String, dynamic> json) => UContentItem(
    title: json["title"],
    subTitle: json["subTitle"],
    description: json["description"],
    iconBase64: json["iconBase64"],
    imageBase64: json["imageBase64"],
    link: json["link"],
    order: json["order"],
  );

  final String? title;
  final String? subTitle;
  final String? description;
  final String? iconBase64;
  final String? imageBase64;
  final String? link;
  final int? order;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "subTitle": subTitle,
    "description": description,
    "iconBase64": iconBase64,
    "imageBase64": imageBase64,
    "link": link,
    "order": order,
  };
}

class UContentLink {
  UContentLink({this.title, this.url, this.iconBase64});

  factory UContentLink.fromJson(String str) => UContentLink.fromMap(json.decode(str));

  factory UContentLink.fromMap(Map<String, dynamic> json) => UContentLink(
    title: json["title"],
    url: json["url"],
    iconBase64: json["iconBase64"],
  );

  final String? title;
  final String? url;
  final String? iconBase64;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "url": url,
    "iconBase64": iconBase64,
  };
}
