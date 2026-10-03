part of "../data.dart";

class UNotificationResponse {
  UNotificationResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.userId,
    required this.adminUserIds,
    this.user,
    this.creator,
    this.creatorId,
    this.zipCode,
  });

  factory UNotificationResponse.fromJson(String str) => UNotificationResponse.fromMap(json.decode(str));

  factory UNotificationResponse.fromMap(Map<String, dynamic> json) => UNotificationResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UNotificationJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    userId: json["userId"],
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    zipCode: json["zipCode"],
  );
  final String id;
  final DateTime createdAt;
  final UNotificationJson jsonData;
  final List<int> tags;
  final String userId;
  final UUserResponse? user;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;
  final String? zipCode;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "userId": userId,
    "user": user?.toMap(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
    "zipCode": zipCode,
  };
}

class UNotificationJson {
  UNotificationJson({
    this.detail1,
    this.detail2,
    this.linkType,
    this.linkId,
  });

  factory UNotificationJson.fromJson(String str) => UNotificationJson.fromMap(json.decode(str));

  factory UNotificationJson.fromMap(Map<String, dynamic> json) => UNotificationJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    linkType: json["linkType"],
    linkId: json["linkId"],
  );

  /// The title, or for sport / social notifications a message key (see [UNotificationMessages]).
  final String? detail1;
  final String? detail2;

  /// What the notification opens, e.g. "tournament" + its id.
  final String? linkType;
  final String? linkId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "linkType": linkType,
    "linkId": linkId,
  };
}

/// Sport, booking and social notifications carry a message key in detail1 and the subject (a title or a name) in detail2.
abstract class UNotificationMessages {
  static Map<String, String Function(String subject)> get _messages => <String, String Function(String subject)>{
    "notifTournamentStarted": U.s.notifTournamentStarted,
    "notifTournamentFinished": U.s.notifTournamentFinished,
    "notifTournamentCancelled": U.s.notifTournamentCancelled,
    "notifNewEntry": U.s.notifNewEntry,
    "notifEntryApproved": U.s.notifEntryApproved,
    "notifEntryRejected": U.s.notifEntryRejected,
    "notifMatchResult": U.s.notifMatchResult,
    "notifMatchSoon": U.s.notifMatchSoon,
    "notifNewBadge": (String s) => U.s.notifNewBadge(UBadges.label(s)),
    "notifChallenge": U.s.notifChallenge,
    "notifGameInvite": U.s.notifGameInvite,
    "notifJoinRequest": U.s.notifJoinRequest,
    "notifJoinApproved": U.s.notifJoinApproved,
    "notifPlayerJoined": U.s.notifPlayerJoined,
    "notifPlayerLeft": U.s.notifPlayerLeft,
    "notifGameCancelled": U.s.notifGameCancelled,
    "notifGameSoon": U.s.notifGameSoon,
    "notifNewBooking": U.s.notifNewBooking,
    "notifBookingShare": U.s.notifBookingShare,
    "notifBookingCancelled": U.s.notifBookingCancelled,
    "notifBookingSoon": U.s.notifBookingSoon,
    "notifVenueApproved": U.s.notifVenueApproved,
    "notifVenueRejected": U.s.notifVenueRejected,
    "notifVenueSuspended": U.s.notifVenueSuspended,
    "notifNewReply": U.s.notifNewReply,
    "notifNewReaction": U.s.notifNewReaction,
  };

  /// The notification's text in the app language; other notifications show their own title.
  static String text(UNotificationResponse n) {
    final String key = n.jsonData.detail1 ?? "";
    final String subject = n.jsonData.detail2 ?? "";
    return _messages[key]?.call(subject) ?? (key.isEmpty ? subject : key);
  }
}
