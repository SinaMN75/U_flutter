part of "../data.dart";

class UConversationRead {
  UConversationRead({
    required this.userId,
    required this.at,
  });

  factory UConversationRead.fromJson(String str) => UConversationRead.fromMap(json.decode(str));

  factory UConversationRead.fromMap(Map<String, dynamic> json) => UConversationRead(
    userId: json["userId"],
    at: DateTime.parse(json["at"]),
  );

  final String userId;
  final DateTime at;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "at": at.toIso8601String(),
  };
}

class UConversationJson {
  UConversationJson({
    this.lastMessageText,
    this.lastMessageUserId,
    this.reads = const <UConversationRead>[],
    this.detail1,
    this.detail2,
  });

  factory UConversationJson.fromJson(String str) => UConversationJson.fromMap(json.decode(str));

  factory UConversationJson.fromMap(Map<String, dynamic> json) => UConversationJson(
    lastMessageText: json["lastMessageText"],
    lastMessageUserId: json["lastMessageUserId"],
    reads: json["reads"] == null ? const <UConversationRead>[] : List<UConversationRead>.from(json["reads"].map((dynamic x) => UConversationRead.fromMap(x))),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? lastMessageText;
  final String? lastMessageUserId;
  final List<UConversationRead> reads;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "lastMessageText": lastMessageText,
    "lastMessageUserId": lastMessageUserId,
    "reads": reads.map((UConversationRead x) => x.toMap()).toList(),
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UConversationResponse {
  UConversationResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.lastMessageAt,
    this.creatorId,
    this.title,
    this.unreadCount = 0,
    this.adminUserIds = const <String>[],
    this.users,
  });

  factory UConversationResponse.fromJson(String str) => UConversationResponse.fromMap(json.decode(str));

  factory UConversationResponse.fromMap(Map<String, dynamic> json) => UConversationResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UConversationJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    lastMessageAt: DateTime.parse(json["lastMessageAt"]),
    title: json["title"],
    unreadCount: json["unreadCount"] ?? 0,
    adminUserIds: json["adminUserIds"] == null ? const <String>[] : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
    users: json["users"] == null ? null : List<UUserResponse>.from(json["users"].map((dynamic x) => UUserResponse.fromMap(x))),
  );

  final String id;
  final DateTime createdAt;
  final UConversationJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final DateTime lastMessageAt;
  final String? title;
  final int unreadCount;
  final List<String> adminUserIds;

  /// Public fields only.
  final List<UUserResponse>? users;

  bool get isGroup => tags.contains(TagConversation.group.number);

  /// The other member of a direct conversation.
  UUserResponse? other(String? myId) => users?.firstWhereOrNull((UUserResponse u) => u.id != myId);

  /// The group's title, or the other member's name.
  String displayTitle(String? myId) => title.nullIfEmpty() ?? other(myId)?.displayName ?? "-";

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "lastMessageAt": lastMessageAt.toIso8601String(),
    "title": title,
    "unreadCount": unreadCount,
    "adminUserIds": adminUserIds,
    "users": users?.map((UUserResponse x) => x.toMap()).toList(),
  };
}

class UMessageJson {
  UMessageJson({
    this.replyToId,
    this.linkType,
    this.linkId,
    this.detail1,
    this.detail2,
  });

  factory UMessageJson.fromJson(String str) => UMessageJson.fromMap(json.decode(str));

  factory UMessageJson.fromMap(Map<String, dynamic> json) => UMessageJson(
    replyToId: json["replyToId"],
    linkType: json["linkType"],
    linkId: json["linkId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? replyToId;
  final String? linkType;
  final String? linkId;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "replyToId": replyToId,
    "linkType": linkType,
    "linkId": linkId,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UMessageResponse {
  UMessageResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.text,
    required this.conversationId,
    this.creatorId,
    this.user,
  });

  factory UMessageResponse.fromJson(String str) => UMessageResponse.fromMap(json.decode(str));

  factory UMessageResponse.fromMap(Map<String, dynamic> json) => UMessageResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UMessageJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    text: json["text"],
    conversationId: json["conversationId"],
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
  );

  final String id;
  final DateTime createdAt;
  final UMessageJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String text;
  final String conversationId;

  /// The sender: public fields only.
  final UUserResponse? user;

  bool get isDeleted => tags.contains(TagMessage.deleted.number);

  bool get isEdited => tags.contains(TagMessage.edited.number);

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "text": text,
    "conversationId": conversationId,
    "user": user?.toMap(),
  };
}
