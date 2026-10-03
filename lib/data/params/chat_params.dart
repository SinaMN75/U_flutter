part of "../data.dart";

class UConversationCreateParams {
  UConversationCreateParams({
    required this.userIds,
    this.tags = const <int>[],
    this.title,
  });

  factory UConversationCreateParams.fromJson(String str) => UConversationCreateParams.fromMap(json.decode(str));

  factory UConversationCreateParams.fromMap(Map<String, dynamic> json) => UConversationCreateParams(
    userIds: List<String>.from(json["userIds"].map((dynamic x) => x)),
    tags: json["tags"] == null ? const <int>[] : List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
  );

  /// Direct: the other user (an existing conversation is returned). Group: the members.
  final List<String> userIds;
  final List<int> tags;
  final String? title;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userIds": userIds,
    "tags": tags,
    "title": title,
  };
}

class UConversationUpdateParams {
  UConversationUpdateParams({
    required this.id,
    this.title,
    this.addUserIds,
    this.removeUserIds,
  });

  factory UConversationUpdateParams.fromJson(String str) => UConversationUpdateParams.fromMap(json.decode(str));

  factory UConversationUpdateParams.fromMap(Map<String, dynamic> json) => UConversationUpdateParams(
    id: json["id"],
    title: json["title"],
    addUserIds: json["addUserIds"] == null ? null : List<String>.from(json["addUserIds"].map((dynamic x) => x)),
    removeUserIds: json["removeUserIds"] == null ? null : List<String>.from(json["removeUserIds"].map((dynamic x) => x)),
  );

  final String id;
  final String? title;
  final List<String>? addUserIds;
  final List<String>? removeUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "addUserIds": addUserIds,
    "removeUserIds": removeUserIds,
  };
}

class UConversationReadParams {
  UConversationReadParams({
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UConversationReadParams.fromJson(String str) => UConversationReadParams.fromMap(json.decode(str));

  factory UConversationReadParams.fromMap(Map<String, dynamic> json) => UConversationReadParams(
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UConversationSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UConversationSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UMessageCreateParams {
  UMessageCreateParams({
    required this.conversationId,
    required this.text,
    this.tags = const <int>[],
    this.replyToId,
    this.linkType,
    this.linkId,
  });

  factory UMessageCreateParams.fromJson(String str) => UMessageCreateParams.fromMap(json.decode(str));

  factory UMessageCreateParams.fromMap(Map<String, dynamic> json) => UMessageCreateParams(
    conversationId: json["conversationId"],
    text: json["text"],
    tags: json["tags"] == null ? const <int>[] : List<int>.from(json["tags"].map((dynamic x) => x)),
    replyToId: json["replyToId"],
    linkType: json["linkType"],
    linkId: json["linkId"],
  );

  final String conversationId;
  final String text;
  final List<int> tags;
  final String? replyToId;
  final String? linkType;
  final String? linkId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "conversationId": conversationId,
    "text": text,
    "tags": tags,
    "replyToId": replyToId,
    "linkType": linkType,
    "linkId": linkId,
  };
}

class UMessageUpdateParams {
  UMessageUpdateParams({
    required this.id,
    this.text,
  });

  factory UMessageUpdateParams.fromJson(String str) => UMessageUpdateParams.fromMap(json.decode(str));

  factory UMessageUpdateParams.fromMap(Map<String, dynamic> json) => UMessageUpdateParams(
    id: json["id"],
    text: json["text"],
  );

  final String id;
  final String? text;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "text": text,
  };
}

class UMessageReadParams {
  UMessageReadParams({
    required this.conversationId,
    this.before,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UMessageReadParams.fromJson(String str) => UMessageReadParams.fromMap(json.decode(str));

  factory UMessageReadParams.fromMap(Map<String, dynamic> json) => UMessageReadParams(
    conversationId: json["conversationId"],
    before: json["before"] == null ? null : DateTime.parse(json["before"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UMessageSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final String conversationId;

  /// Older messages than this (scrolling up); newest first.
  final DateTime? before;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UMessageSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "conversationId": conversationId,
    "before": before?.toUtc().toIso8601String(),
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}
