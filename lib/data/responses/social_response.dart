part of "../data.dart";

class UPostReaction {
  UPostReaction({
    required this.userId,
    required this.tag,
  });

  factory UPostReaction.fromJson(String str) => UPostReaction.fromMap(json.decode(str));

  factory UPostReaction.fromMap(Map<String, dynamic> json) => UPostReaction(
    userId: json["userId"],
    tag: json["tag"],
  );

  final String userId;
  final int tag;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "tag": tag,
  };
}

class UPostJson {
  UPostJson({
    this.reactions = const <UPostReaction>[],
    this.viewerIds = const <String>[],
    this.linkType,
    this.linkId,
    this.detail1,
    this.detail2,
  });

  factory UPostJson.fromJson(String str) => UPostJson.fromMap(json.decode(str));

  factory UPostJson.fromMap(Map<String, dynamic> json) => UPostJson(
    reactions: json["reactions"] == null ? const <UPostReaction>[] : List<UPostReaction>.from(json["reactions"].map((dynamic x) => UPostReaction.fromMap(x))),
    viewerIds: json["viewerIds"] == null ? const <String>[] : List<String>.from(json["viewerIds"].map((dynamic x) => x)),
    linkType: json["linkType"],
    linkId: json["linkId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final List<UPostReaction> reactions;

  /// Who saw a story (its author only).
  final List<String> viewerIds;

  /// "tournament", "openMatch", "achievement", "venue"...
  final String? linkType;
  final String? linkId;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reactions": reactions.map((UPostReaction x) => x.toMap()).toList(),
    "viewerIds": viewerIds,
    "linkType": linkType,
    "linkId": linkId,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UPostResponse {
  UPostResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    this.creatorId,
    this.text,
    this.expiresAt,
    this.parentId,
    this.replyCount = 0,
    this.reactionCount = 0,
    this.myReaction,
    this.user,
    this.media,
    this.children,
  });

  factory UPostResponse.fromJson(String str) => UPostResponse.fromMap(json.decode(str));

  factory UPostResponse.fromMap(Map<String, dynamic> json) => UPostResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UPostJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    text: json["text"],
    expiresAt: json["expiresAt"] == null ? null : DateTime.parse(json["expiresAt"]),
    parentId: json["parentId"],
    replyCount: json["replyCount"] ?? 0,
    reactionCount: json["reactionCount"] ?? 0,
    myReaction: json["myReaction"],
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    media: json["media"] == null ? null : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    children: json["children"] == null ? null : List<UPostResponse>.from(json["children"].map((dynamic x) => UPostResponse.fromMap(x))),
  );

  final String id;
  final DateTime createdAt;
  final UPostJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String? text;
  final DateTime? expiresAt;
  final String? parentId;
  final int replyCount;
  final int reactionCount;
  final int? myReaction;

  /// The author: public fields only.
  final UUserResponse? user;
  final List<UMediaResponse>? media;
  final List<UPostResponse>? children;

  bool get isStory => tags.contains(TagPost.story.number);

  bool get isHidden => tags.contains(TagPost.hidden.number);

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "text": text,
    "expiresAt": expiresAt?.toIso8601String(),
    "parentId": parentId,
    "replyCount": replyCount,
    "reactionCount": reactionCount,
    "myReaction": myReaction,
    "user": user?.toMap(),
    "media": media?.map((UMediaResponse x) => x.toMap()).toList(),
    "children": children?.map((UPostResponse x) => x.toMap()).toList(),
  };
}

class UReportJson {
  UReportJson({
    this.note,
    this.detail1,
    this.detail2,
  });

  factory UReportJson.fromJson(String str) => UReportJson.fromMap(json.decode(str));

  factory UReportJson.fromMap(Map<String, dynamic> json) => UReportJson(
    note: json["note"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? note;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "note": note,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UReportResponse {
  UReportResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.targetId,
    this.creatorId,
    this.reason,
    this.creator,
  });

  factory UReportResponse.fromJson(String str) => UReportResponse.fromMap(json.decode(str));

  factory UReportResponse.fromMap(Map<String, dynamic> json) => UReportResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UReportJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    targetId: json["targetId"],
    reason: json["reason"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
  );

  final String id;
  final DateTime createdAt;
  final UReportJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String targetId;
  final String? reason;
  final UUserResponse? creator;

  TagReport? get kind => TagReport.values.group(100).firstWhereOrNull((TagReport t) => tags.contains(t.number));

  TagReport? get status => TagReport.values.group(200).firstWhereOrNull((TagReport t) => tags.contains(t.number));

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "targetId": targetId,
    "reason": reason,
    "creator": creator?.toMap(),
  };
}

class UBlockResponse {
  UBlockResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.blockedUserId,
    this.creatorId,
    this.blockedUser,
  });

  factory UBlockResponse.fromJson(String str) => UBlockResponse.fromMap(json.decode(str));

  factory UBlockResponse.fromMap(Map<String, dynamic> json) => UBlockResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    blockedUserId: json["blockedUserId"],
    blockedUser: json["blockedUser"] == null ? null : UUserResponse.fromMap(json["blockedUser"]),
  );

  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String blockedUserId;
  final UUserResponse? blockedUser;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "blockedUserId": blockedUserId,
    "blockedUser": blockedUser?.toMap(),
  };
}
