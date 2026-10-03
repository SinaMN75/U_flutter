part of "../data.dart";

class USportCreateParams {
  USportCreateParams({
    required this.tags,
    required this.title,
    this.order = 0,
    this.minLevel = 1,
    this.maxLevel = 7,
    this.icon,
    this.id,
    this.detail1,
    this.detail2,
  });

  factory USportCreateParams.fromJson(String str) => USportCreateParams.fromMap(json.decode(str));

  factory USportCreateParams.fromMap(Map<String, dynamic> json) => USportCreateParams(
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    order: json["order"] ?? 0,
    minLevel: json["minLevel"]?.toDouble() ?? 1,
    maxLevel: json["maxLevel"]?.toDouble() ?? 7,
    icon: json["icon"],
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final List<int> tags;
  final String title;
  final int order;
  final double minLevel;
  final double maxLevel;
  final String? icon;
  final String? id;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "order": order,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
    "icon": icon,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class USportUpdateParams {
  USportUpdateParams({
    required this.id,
    this.title,
    this.order,
    this.minLevel,
    this.maxLevel,
    this.icon,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory USportUpdateParams.fromJson(String str) => USportUpdateParams.fromMap(json.decode(str));

  factory USportUpdateParams.fromMap(Map<String, dynamic> json) => USportUpdateParams(
    id: json["id"],
    title: json["title"],
    order: json["order"],
    minLevel: json["minLevel"]?.toDouble(),
    maxLevel: json["maxLevel"]?.toDouble(),
    icon: json["icon"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String id;
  final String? title;
  final int? order;
  final double? minLevel;
  final double? maxLevel;
  final String? icon;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "order": order,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
    "icon": icon,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class USportReadParams {
  USportReadParams({
    this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.ids,
    this.orderBy,
  });

  factory USportReadParams.fromJson(String str) => USportReadParams.fromMap(json.decode(str));

  factory USportReadParams.fromMap(Map<String, dynamic> json) => USportReadParams(
    selectorArgs: json["selectorArgs"] == null ? null : USportSelectorArgs.fromMap(json["selectorArgs"]),
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
  );
  final USportSelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags ?? <int>[],
    "ids": ids ?? <String>[],
    "orderBy": orderBy,
  };
}

class UPlayerSportProfileCreateParams {
  UPlayerSportProfileCreateParams({
    required this.sportId,
    required this.level,
    this.tags = const <int>[101],
    this.userId,
    this.id,
    this.detail1,
    this.detail2,
  });

  factory UPlayerSportProfileCreateParams.fromJson(String str) => UPlayerSportProfileCreateParams.fromMap(json.decode(str));

  factory UPlayerSportProfileCreateParams.fromMap(Map<String, dynamic> json) => UPlayerSportProfileCreateParams(
    sportId: json["sportId"],
    level: json["level"].toDouble(),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    userId: json["userId"],
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String sportId;
  final double level;
  final List<int> tags;
  final String? userId;
  final String? id;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "sportId": sportId,
    "level": level,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "userId": userId,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UPlayerSportProfileUpdateParams {
  UPlayerSportProfileUpdateParams({
    required this.id,
    this.level,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UPlayerSportProfileUpdateParams.fromJson(String str) => UPlayerSportProfileUpdateParams.fromMap(json.decode(str));

  factory UPlayerSportProfileUpdateParams.fromMap(Map<String, dynamic> json) => UPlayerSportProfileUpdateParams(
    id: json["id"],
    level: json["level"]?.toDouble(),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String id;
  final double? level;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "level": level,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UPlayerSportProfileReadParams {
  UPlayerSportProfileReadParams({
    this.userId,
    this.sportId,
    this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.ids,
    this.orderBy,
  });

  factory UPlayerSportProfileReadParams.fromJson(String str) => UPlayerSportProfileReadParams.fromMap(json.decode(str));

  factory UPlayerSportProfileReadParams.fromMap(Map<String, dynamic> json) => UPlayerSportProfileReadParams(
    userId: json["userId"],
    sportId: json["sportId"],
    selectorArgs: json["selectorArgs"] == null ? null : UPlayerSportProfileSelectorArgs.fromMap(json["selectorArgs"]),
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
  );
  final String? userId;
  final String? sportId;
  final UPlayerSportProfileSelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "sportId": sportId,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags ?? <int>[],
    "ids": ids ?? <String>[],
    "orderBy": orderBy,
  };
}
