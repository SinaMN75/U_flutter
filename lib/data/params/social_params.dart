part of "../data.dart";

class UPostCreateParams {
  UPostCreateParams({
    this.tags = const <int>[],
    this.text,
    this.parentId,
    this.linkType,
    this.linkId,
    this.id,
    this.detail1,
    this.detail2,
  });

  factory UPostCreateParams.fromJson(String str) => UPostCreateParams.fromMap(json.decode(str));

  factory UPostCreateParams.fromMap(Map<String, dynamic> json) => UPostCreateParams(
    tags: json["tags"] == null ? const <int>[] : List<int>.from(json["tags"].map((dynamic x) => x)),
    text: json["text"],
    parentId: json["parentId"],
    linkType: json["linkType"],
    linkId: json["linkId"],
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final List<int> tags;
  final String? text;

  /// A reply to this post.
  final String? parentId;
  final String? linkType;
  final String? linkId;
  final String? id;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "text": text,
    "parentId": parentId,
    "linkType": linkType,
    "linkId": linkId,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UPostUpdateParams {
  UPostUpdateParams({
    required this.id,
    this.text,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UPostUpdateParams.fromJson(String str) => UPostUpdateParams.fromMap(json.decode(str));

  factory UPostUpdateParams.fromMap(Map<String, dynamic> json) => UPostUpdateParams(
    id: json["id"],
    text: json["text"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String id;
  final String? text;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "text": text,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UPostReadParams {
  UPostReadParams({
    this.feed = false,
    this.stories = false,
    this.userId,
    this.parentId,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UPostReadParams.fromJson(String str) => UPostReadParams.fromMap(json.decode(str));

  factory UPostReadParams.fromMap(Map<String, dynamic> json) => UPostReadParams(
    feed: json["feed"] ?? false,
    stories: json["stories"] ?? false,
    userId: json["userId"],
    parentId: json["parentId"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UPostSelectorArgs.fromMap(json["selectorArgs"]),
  );

  /// Posts of the people the user follows, and their own.
  final bool feed;
  final bool stories;
  final String? userId;

  /// The replies of a post.
  final String? parentId;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UPostSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "feed": feed,
    "stories": stories,
    "userId": userId,
    "parentId": parentId,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UPostReactParams {
  UPostReactParams({
    required this.id,
    this.tag,
  });

  factory UPostReactParams.fromJson(String str) => UPostReactParams.fromMap(json.decode(str));

  factory UPostReactParams.fromMap(Map<String, dynamic> json) => UPostReactParams(
    id: json["id"],
    tag: json["tag"],
  );

  final String id;

  /// A TagReaction number; null removes the reaction.
  final int? tag;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tag": tag,
  };
}

class UReportCreateParams {
  UReportCreateParams({
    required this.targetId,
    required this.tags,
    this.reason,
  });

  factory UReportCreateParams.fromJson(String str) => UReportCreateParams.fromMap(json.decode(str));

  factory UReportCreateParams.fromMap(Map<String, dynamic> json) => UReportCreateParams(
    targetId: json["targetId"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    reason: json["reason"],
  );

  final String targetId;
  final List<int> tags;
  final String? reason;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "targetId": targetId,
    "tags": tags,
    "reason": reason,
  };
}

class UReportUpdateParams {
  UReportUpdateParams({
    required this.id,
    this.note,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UReportUpdateParams.fromJson(String str) => UReportUpdateParams.fromMap(json.decode(str));

  factory UReportUpdateParams.fromMap(Map<String, dynamic> json) => UReportUpdateParams(
    id: json["id"],
    note: json["note"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String id;
  final String? note;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "note": note,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UReportReadParams {
  UReportReadParams({
    this.targetId,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UReportReadParams.fromJson(String str) => UReportReadParams.fromMap(json.decode(str));

  factory UReportReadParams.fromMap(Map<String, dynamic> json) => UReportReadParams(
    targetId: json["targetId"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UReportSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final String? targetId;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UReportSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "targetId": targetId,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UBlockParams {
  UBlockParams({
    required this.userId,
  });

  factory UBlockParams.fromJson(String str) => UBlockParams.fromMap(json.decode(str));

  factory UBlockParams.fromMap(Map<String, dynamic> json) => UBlockParams(
    userId: json["userId"],
  );

  final String userId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
  };
}

class UBlockReadParams {
  UBlockReadParams({
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
  });

  factory UBlockReadParams.fromJson(String str) => UBlockReadParams.fromMap(json.decode(str));

  factory UBlockReadParams.fromMap(Map<String, dynamic> json) => UBlockReadParams(
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
  );

  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  };
}
