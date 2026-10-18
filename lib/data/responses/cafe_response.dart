part of "../data.dart";

class UCafeJson {
  UCafeJson({this.description, this.openHours, this.latitude, this.longitude, this.instagram, this.website});

  factory UCafeJson.fromMap(Map<String, dynamic> json) => UCafeJson(
    description: json["description"],
    openHours: json["openHours"],
    latitude: (json["latitude"] as num?)?.toDouble(),
    longitude: (json["longitude"] as num?)?.toDouble(),
    instagram: json["instagram"],
    website: json["website"],
  );

  final String? description;
  final String? openHours;
  final double? latitude;
  final double? longitude;
  final String? instagram;
  final String? website;
}

class UCafeResponse {
  UCafeResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.cityCode,
    this.address,
    this.phoneNumber,
    this.organizationId,
    this.averageScore = 0,
    this.commentCount = 0,
    this.menuId,
    this.adminUserIds = const <String>[],
    this.media,
    this.comments,
  });

  factory UCafeResponse.fromMap(Map<String, dynamic> json) => UCafeResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UCafeJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    cityCode: json["cityCode"] ?? "",
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    organizationId: json["organizationId"],
    averageScore: (json["averageScore"] as num?)?.toDouble() ?? 0,
    commentCount: json["commentCount"] ?? 0,
    menuId: json["menuId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
    media: json["media"] == null ? null : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    comments: json["comments"] == null ? null : List<UCommentResponse>.from(json["comments"].map((dynamic x) => UCommentResponse.fromMap(x))),
  );

  final String id;
  final DateTime createdAt;
  final UCafeJson jsonData;
  final List<int> tags;
  final String title;
  final String cityCode;
  final String? address;
  final String? phoneNumber;
  final String? organizationId;
  final double averageScore;
  final int commentCount;
  final String? menuId;
  final List<String> adminUserIds;
  final List<UMediaResponse>? media;
  final List<UCommentResponse>? comments;
}

class UMenuCategory {
  UMenuCategory({required this.id, required this.title, this.order = 0});

  factory UMenuCategory.fromMap(Map<String, dynamic> json) => UMenuCategory(id: json["id"], title: json["title"] ?? "", order: json["order"] ?? 0);

  final String id;
  final String title;
  final int order;
}

class UMenuTable {
  UMenuTable({required this.number, this.title, this.scans = 0});

  factory UMenuTable.fromMap(Map<String, dynamic> json) => UMenuTable(number: json["number"], title: json["title"], scans: json["scans"] ?? 0);

  final int number;
  final String? title;
  final int scans;
}

class UMenuJson {
  UMenuJson({this.tagline, this.theme = "classic", this.accent = "#E07A3F", this.font = "lalezar", this.categories = const <UMenuCategory>[], this.tables = const <UMenuTable>[], this.views = 0, this.scans = 0});

  factory UMenuJson.fromMap(Map<String, dynamic> json) => UMenuJson(
    tagline: json["tagline"],
    theme: json["theme"] ?? "classic",
    accent: json["accent"] ?? "#E07A3F",
    font: json["font"] ?? "lalezar",
    categories: json["categories"] == null ? <UMenuCategory>[] : List<UMenuCategory>.from(json["categories"].map((dynamic x) => UMenuCategory.fromMap(x))),
    tables: json["tables"] == null ? <UMenuTable>[] : List<UMenuTable>.from(json["tables"].map((dynamic x) => UMenuTable.fromMap(x))),
    views: json["views"] ?? 0,
    scans: json["scans"] ?? 0,
  );

  final String? tagline;
  final String theme;
  final String accent;
  final String font;
  final List<UMenuCategory> categories;
  final List<UMenuTable> tables;
  final int views;
  final int scans;
}

class UMenuResponse {
  UMenuResponse({
    required this.id,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.placeId,
    this.organizationId,
    this.placeTitle,
    this.itemCount = 0,
    this.items,
  });

  factory UMenuResponse.fromMap(Map<String, dynamic> json) => UMenuResponse(
    id: json["id"],
    jsonData: UMenuJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    placeId: json["placeId"],
    organizationId: json["organizationId"],
    placeTitle: json["placeTitle"],
    itemCount: json["itemCount"] ?? 0,
    items: json["items"] == null ? null : List<UMenuItemResponse>.from(json["items"].map((dynamic x) => UMenuItemResponse.fromMap(x))),
  );

  final String id;
  final UMenuJson jsonData;
  final List<int> tags;
  final String title;
  final String placeId;
  final String? organizationId;
  final String? placeTitle;
  final int itemCount;
  final List<UMenuItemResponse>? items;

  bool has(TagMenu tag) => tags.contains(tag.number);
}

class UMenuItemChoice {
  UMenuItemChoice({required this.title, this.price = 0});

  factory UMenuItemChoice.fromMap(Map<String, dynamic> json) => UMenuItemChoice(title: json["title"] ?? "", price: (json["price"] as num?)?.toDouble() ?? 0);

  final String title;
  final double price;

  Map<String, dynamic> toMap() => <String, dynamic>{"title": title, "price": price};
}

class UMenuItemOption {
  UMenuItemOption({required this.title, this.required = false, this.multiple = false, this.choices = const <UMenuItemChoice>[]});

  factory UMenuItemOption.fromMap(Map<String, dynamic> json) => UMenuItemOption(
    title: json["title"] ?? "",
    required: json["required"] ?? false,
    multiple: json["multiple"] ?? false,
    choices: json["choices"] == null ? <UMenuItemChoice>[] : List<UMenuItemChoice>.from(json["choices"].map((dynamic x) => UMenuItemChoice.fromMap(x))),
  );

  final String title;
  final bool required;
  final bool multiple;
  final List<UMenuItemChoice> choices;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "required": required,
    "multiple": multiple,
    "choices": choices.map((UMenuItemChoice x) => x.toMap()).toList(),
  };
}

class UMenuItemJson {
  UMenuItemJson({this.description, this.calories, this.prepMinutes, this.options = const <UMenuItemOption>[]});

  factory UMenuItemJson.fromMap(Map<String, dynamic> json) => UMenuItemJson(
    description: json["description"],
    calories: json["calories"],
    prepMinutes: json["prepMinutes"],
    options: json["options"] == null ? <UMenuItemOption>[] : List<UMenuItemOption>.from(json["options"].map((dynamic x) => UMenuItemOption.fromMap(x))),
  );

  final String? description;
  final int? calories;
  final int? prepMinutes;
  final List<UMenuItemOption> options;
}

class UMenuItemResponse {
  UMenuItemResponse({
    required this.id,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.price,
    required this.menuId,
    this.order = 0,
    this.categoryId,
    this.media = const <UMediaResponse>[],
  });

  factory UMenuItemResponse.fromMap(Map<String, dynamic> json) => UMenuItemResponse(
    id: json["id"],
    jsonData: UMenuItemJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    price: (json["price"] as num?)?.toDouble() ?? 0,
    menuId: json["menuId"],
    order: json["order"] ?? 0,
    categoryId: json["categoryId"],
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
  );

  final String id;
  final UMenuItemJson jsonData;
  final List<int> tags;
  final String title;
  final double price;
  final String menuId;
  final int order;
  final String? categoryId;
  final List<UMediaResponse> media;

  bool has(TagMenuItem tag) => tags.contains(tag.number);

  String? get imageUrl => media.isEmpty ? null : media.first.url;
}

class UMenuOrderLine {
  UMenuOrderLine({required this.itemId, required this.title, required this.price, required this.quantity, this.choices = const <String>[], this.note});

  factory UMenuOrderLine.fromMap(Map<String, dynamic> json) => UMenuOrderLine(
    itemId: json["itemId"],
    title: json["title"] ?? "",
    price: (json["price"] as num?)?.toDouble() ?? 0,
    quantity: json["quantity"] ?? 1,
    choices: json["choices"] == null ? <String>[] : List<String>.from(json["choices"].map((dynamic x) => x)),
    note: json["note"],
  );

  final String itemId;
  final String title;
  final double price;
  final int quantity;
  final List<String> choices;
  final String? note;
}

class UMenuOrderJson {
  UMenuOrderJson({this.lines = const <UMenuOrderLine>[], this.table, this.room, this.note, this.reason, this.paidAt, this.acceptedAt, this.readyAt, this.completedAt, this.cancelledAt, this.refunded = 0});

  factory UMenuOrderJson.fromMap(Map<String, dynamic> json) => UMenuOrderJson(
    lines: json["lines"] == null ? <UMenuOrderLine>[] : List<UMenuOrderLine>.from(json["lines"].map((dynamic x) => UMenuOrderLine.fromMap(x))),
    table: json["table"],
    room: json["room"],
    note: json["note"],
    reason: json["reason"],
    paidAt: json["paidAt"] == null ? null : DateTime.parse(json["paidAt"]),
    acceptedAt: json["acceptedAt"] == null ? null : DateTime.parse(json["acceptedAt"]),
    readyAt: json["readyAt"] == null ? null : DateTime.parse(json["readyAt"]),
    completedAt: json["completedAt"] == null ? null : DateTime.parse(json["completedAt"]),
    cancelledAt: json["cancelledAt"] == null ? null : DateTime.parse(json["cancelledAt"]),
    refunded: (json["refunded"] as num?)?.toDouble() ?? 0,
  );

  final List<UMenuOrderLine> lines;
  final int? table;
  final String? room;
  final String? note;
  final String? reason;
  final DateTime? paidAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final double refunded;
}

class UMenuOrderResponse {
  UMenuOrderResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.number,
    required this.total,
    required this.menuId,
    required this.userId,
    required this.placeId,
    this.organizationId,
    this.menuTitle,
    this.userName,
    this.userPhoneNumber,
  });

  factory UMenuOrderResponse.fromMap(Map<String, dynamic> json) => UMenuOrderResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UMenuOrderJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    number: json["number"] ?? 0,
    total: (json["total"] as num?)?.toDouble() ?? 0,
    menuId: json["menuId"],
    userId: json["userId"],
    placeId: json["placeId"],
    organizationId: json["organizationId"],
    menuTitle: json["menuTitle"],
    userName: json["userName"],
    userPhoneNumber: json["userPhoneNumber"],
  );

  final String id;
  final DateTime createdAt;
  final UMenuOrderJson jsonData;
  final List<int> tags;
  final int number;
  final double total;
  final String menuId;
  final String userId;
  final String placeId;
  final String? organizationId;
  final String? menuTitle;
  final String? userName;
  final String? userPhoneNumber;

  TagMenuOrder get status => TagMenuOrder.values.firstWhere((TagMenuOrder x) => x.number < 200 && tags.contains(x.number), orElse: () => TagMenuOrder.pending);

  TagMenuOrder get type => TagMenuOrder.values.firstWhere((TagMenuOrder x) => x.number >= 200 && tags.contains(x.number), orElse: () => TagMenuOrder.table);
}
