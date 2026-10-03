part of "../data.dart";

class USportResponse {
  USportResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.order,
    required this.minLevel,
    required this.maxLevel,
    this.creatorId,
    this.creator,
  });

  factory USportResponse.fromJson(String str) => USportResponse.fromMap(json.decode(str));

  factory USportResponse.fromMap(Map<String, dynamic> json) => USportResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: USportJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    order: json["order"] ?? 0,
    minLevel: json["minLevel"]?.toDouble() ?? 1,
    maxLevel: json["maxLevel"]?.toDouble() ?? 7,
    creatorId: json["creatorId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
  );
  final String id;
  final DateTime createdAt;
  final USportJson jsonData;
  final List<int> tags;
  final String title;
  final int order;
  final double minLevel;
  final double maxLevel;
  final String? creatorId;
  final UUserResponse? creator;

  /// [title] is a localized-constant key from the server; this is its text in the app language. `Text(sport.localizedTitle)`
  String get localizedTitle => USportKeyValues.label(title);

  /// The [USportLevels] step closest to [level]. `sport.levelLabel(3.5)` → "Intermediate"
  String levelLabel(double level) => USportLevels.label(USportLevels.closest(level));

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "order": order,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
    "creatorId": creatorId,
    "creator": creator?.toMap(),
  };
}

class USportJson {
  USportJson({
    this.icon,
    this.detail1,
    this.detail2,
  });

  factory USportJson.fromJson(String str) => USportJson.fromMap(json.decode(str));

  factory USportJson.fromMap(Map<String, dynamic> json) => USportJson(
    icon: json["icon"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String? icon;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "icon": icon,
    "detail1": detail1,
    "detail2": detail2,
  };
}

/// The self-assessed level steps shown when a player picks a level (1–7 scale).
abstract class USportLevels {
  static const List<double> values = <double>[1, 2, 3, 4.2, 5.5];

  static String label(int index) => <String>[U.s.newcomer, U.s.beginner, U.s.intermediate, U.s.advanced, U.s.semiPro][index];

  static String description(int index) => <String>[
    U.s.newcomerLevelDescription,
    U.s.beginnerLevelDescription,
    U.s.intermediateLevelDescription,
    U.s.advancedLevelDescription,
    U.s.semiProLevelDescription,
  ][index];

  /// Index of the step nearest to [level].
  static int closest(double level) {
    int best = 0;
    for (int i = 1; i < values.length; i++) {
      if ((values[i] - level).abs() < (values[best] - level).abs()) best = i;
    }
    return best;
  }
}

abstract class USportKeyValues {
  static const String padel = "padel";
  static const String tennis = "tennis";
  static const String squash = "squash";
  static const String billiards = "billiards";
  static const String snooker = "snooker";
  static const String football = "football";
  static const String karate = "karate";

  static String label(String key) {
    switch (key) {
      case padel:
        return U.s.padel;
      case tennis:
        return U.s.tennis;
      case squash:
        return U.s.squash;
      case billiards:
        return U.s.billiards;
      case snooker:
        return U.s.snooker;
      case football:
        return U.s.football;
      case karate:
        return U.s.karate;
      default:
        return key;
    }
  }
}

class UPlayerSportProfileResponse {
  UPlayerSportProfileResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.level,
    required this.userId,
    required this.sportId,
    this.creatorId,
    this.lastLevelChange,
    this.user,
    this.sport,
  });

  factory UPlayerSportProfileResponse.fromJson(String str) => UPlayerSportProfileResponse.fromMap(json.decode(str));

  factory UPlayerSportProfileResponse.fromMap(Map<String, dynamic> json) => UPlayerSportProfileResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    level: json["level"].toDouble(),
    userId: json["userId"],
    sportId: json["sportId"],
    creatorId: json["creatorId"],
    lastLevelChange: json["lastLevelChange"]?.toDouble(),
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    sport: json["sport"] == null ? null : USportResponse.fromMap(json["sport"]),
  );
  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final double level;
  final String userId;
  final String sportId;
  final String? creatorId;

  /// The change from the latest rated match.
  final double? lastLevelChange;
  final UUserResponse? user;
  final USportResponse? sport;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "level": level,
    "userId": userId,
    "sportId": sportId,
    "creatorId": creatorId,
    "lastLevelChange": lastLevelChange,
    "user": user?.toMap(),
    "sport": sport?.toMap(),
  };
}

class UTournamentResponse {
  UTournamentResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.startDate,
    required this.capacity,
    required this.entryFee,
    required this.sportId,
    required this.entryCount,
    required this.adminUserIds,
    this.creatorId,
    this.minLevel,
    this.maxLevel,
    this.sport,
    this.entries,
    this.matches,
  });

  factory UTournamentResponse.fromJson(String str) => UTournamentResponse.fromMap(json.decode(str));

  factory UTournamentResponse.fromMap(Map<String, dynamic> json) => UTournamentResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UTournamentJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    startDate: DateTime.parse(json["startDate"]),
    capacity: json["capacity"] ?? 0,
    entryFee: json["entryFee"]?.toDouble() ?? 0,
    sportId: json["sportId"],
    entryCount: json["entryCount"] ?? 0,
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    minLevel: json["minLevel"]?.toDouble(),
    maxLevel: json["maxLevel"]?.toDouble(),
    sport: json["sport"] == null ? null : USportResponse.fromMap(json["sport"]),
    entries: json["entries"] == null ? null : List<UTournamentEntryResponse>.from(json["entries"].map((dynamic x) => UTournamentEntryResponse.fromMap(x))),
    matches: json["matches"] == null ? null : List<UTournamentMatchResponse>.from(json["matches"].map((dynamic x) => UTournamentMatchResponse.fromMap(x))),
  );
  final String id;
  final DateTime createdAt;
  final UTournamentJson jsonData;
  final List<int> tags;
  final String title;
  final DateTime startDate;
  final int capacity;
  final double entryFee;
  final String sportId;
  final int entryCount;
  final List<String> adminUserIds;
  final String? creatorId;
  final double? minLevel;
  final double? maxLevel;
  final USportResponse? sport;
  final List<UTournamentEntryResponse>? entries;
  final List<UTournamentMatchResponse>? matches;

  TagTournament? get format => TagTournament.values.group(100).firstWhereOrNull((TagTournament t) => tags.contains(t.number));

  TagTournament? get participantType => TagTournament.values.group(200).firstWhereOrNull((TagTournament t) => tags.contains(t.number));

  TagTournament? get status => TagTournament.values.group(300).firstWhereOrNull((TagTournament t) => tags.contains(t.number));

  /// The creator or one of the co-organizers.
  bool isOrganizer(String userId) => creatorId == userId || adminUserIds.contains(userId);

  /// The entry [userId] plays in, if any (needs `entries` loaded with users).
  UTournamentEntryResponse? entryOf(String userId) => entries?.firstWhereOrNull((UTournamentEntryResponse e) => e.users?.any((UUserResponse u) => u.id == userId) ?? false);

  UTournamentEntryResponse? entryById(String? id) => id == null ? null : entries?.firstWhereOrNull((UTournamentEntryResponse e) => e.id == id);

  /// A match side's name: the entry, plus the partner in Americano / Mexicano. `t.sideName(m.entryAId, m.partnerAId)`
  String sideName(String? entryId, String? partnerId) =>
      <String>[if (entryId != null) entryById(entryId)?.displayName ?? "-", if (partnerId != null) entryById(partnerId)?.displayName ?? "-"].join(" & ").nullIfEmpty() ?? "—";

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "startDate": startDate.toIso8601String(),
    "capacity": capacity,
    "entryFee": entryFee,
    "sportId": sportId,
    "entryCount": entryCount,
    "adminUserIds": adminUserIds,
    "creatorId": creatorId,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
    "sport": sport?.toMap(),
    "entries": entries?.map((UTournamentEntryResponse x) => x.toMap()).toList(),
    "matches": matches?.map((UTournamentMatchResponse x) => x.toMap()).toList(),
  };
}

class UTournamentJson {
  UTournamentJson({
    this.description,
    this.prize,
    this.venue,
    this.address,
    this.latitude,
    this.longitude,
    this.pointsForWin = 3,
    this.pointsForDraw = 1,
    this.pointsForLoss = 0,
    this.groupCount,
    this.advancePerGroup = 2,
    this.thirdPlaceMatch = false,
    this.rounds,
    this.pointsPerMatch = 24,
    this.boxSize = 5,
    this.setsToWin,
    this.raceTo,
    this.superTiebreak = false,
    this.unrated = false,
    this.previousSeasonId,
    this.detail1,
    this.detail2,
  });

  factory UTournamentJson.fromJson(String str) => UTournamentJson.fromMap(json.decode(str));

  factory UTournamentJson.fromMap(Map<String, dynamic> json) => UTournamentJson(
    description: json["description"],
    prize: json["prize"],
    venue: json["venue"],
    address: json["address"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    pointsForWin: json["pointsForWin"] ?? 3,
    pointsForDraw: json["pointsForDraw"] ?? 1,
    pointsForLoss: json["pointsForLoss"] ?? 0,
    groupCount: json["groupCount"],
    advancePerGroup: json["advancePerGroup"] ?? 2,
    thirdPlaceMatch: json["thirdPlaceMatch"] ?? false,
    rounds: json["rounds"],
    pointsPerMatch: json["pointsPerMatch"] ?? 24,
    boxSize: json["boxSize"] ?? 5,
    setsToWin: json["setsToWin"],
    raceTo: json["raceTo"],
    superTiebreak: json["superTiebreak"] ?? false,
    unrated: json["unrated"] ?? false,
    previousSeasonId: json["previousSeasonId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String? description;
  final String? prize;
  final String? venue;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int pointsForWin;
  final int pointsForDraw;
  final int pointsForLoss;
  final int? groupCount;
  final int advancePerGroup;
  final bool thirdPlaceMatch;
  final int? rounds;
  final int pointsPerMatch;
  final int boxSize;
  final int? setsToWin;
  final int? raceTo;
  final bool superTiebreak;
  final bool unrated;
  final String? previousSeasonId;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "description": description,
    "prize": prize,
    "venue": venue,
    "address": address,
    "latitude": latitude,
    "longitude": longitude,
    "pointsForWin": pointsForWin,
    "pointsForDraw": pointsForDraw,
    "pointsForLoss": pointsForLoss,
    "groupCount": groupCount,
    "advancePerGroup": advancePerGroup,
    "thirdPlaceMatch": thirdPlaceMatch,
    "rounds": rounds,
    "pointsPerMatch": pointsPerMatch,
    "boxSize": boxSize,
    "setsToWin": setsToWin,
    "raceTo": raceTo,
    "superTiebreak": superTiebreak,
    "unrated": unrated,
    "previousSeasonId": previousSeasonId,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UTournamentEntryResponse {
  UTournamentEntryResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.tournamentId,
    this.creatorId,
    this.title,
    this.seed,
    this.groupNumber,
    this.users,
    this.tournament,
  });

  factory UTournamentEntryResponse.fromJson(String str) => UTournamentEntryResponse.fromMap(json.decode(str));

  factory UTournamentEntryResponse.fromMap(Map<String, dynamic> json) => UTournamentEntryResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    tournamentId: json["tournamentId"],
    creatorId: json["creatorId"],
    title: json["title"],
    seed: json["seed"],
    groupNumber: json["groupNumber"],
    users: json["users"] == null ? null : List<UUserResponse>.from(json["users"].map((dynamic x) => UUserResponse.fromMap(x))),
    tournament: json["tournament"] == null ? null : UTournamentResponse.fromMap(json["tournament"]),
  );
  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final String tournamentId;
  final String? creatorId;
  final String? title;
  final int? seed;
  final int? groupNumber;
  final List<UUserResponse>? users;
  final UTournamentResponse? tournament;

  TagTournamentEntry? get status => TagTournamentEntry.values.firstWhereOrNull((TagTournamentEntry t) => tags.contains(t.number));

  /// The team name, or the players' names. `entry.displayName` → "Sara Ahmadi / Ali Karimi"
  String get displayName =>
      title.nullIfEmpty() ?? (users ?? <UUserResponse>[]).map((UUserResponse u) => "${u.firstName ?? ""} ${u.lastName ?? ""}".trim()).where((String i) => i.isNotEmpty).join(" / ").nullIfEmpty() ?? "-";

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "tournamentId": tournamentId,
    "creatorId": creatorId,
    "title": title,
    "seed": seed,
    "groupNumber": groupNumber,
    "users": users?.map((UUserResponse x) => x.toMap()).toList(),
    "tournament": tournament?.toMap(),
  };
}

class UTournamentMatchResponse {
  UTournamentMatchResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.round,
    required this.order,
    required this.tournamentId,
    this.creatorId,
    this.scheduledAt,
    this.entryAId,
    this.entryBId,
    this.winnerEntryId,
    this.groupNumber,
    this.partnerAId,
    this.partnerBId,
    this.nextMatchId,
    this.nextMatchSlot,
    this.loserNextMatchId,
    this.loserNextMatchSlot,
  });

  factory UTournamentMatchResponse.fromJson(String str) => UTournamentMatchResponse.fromMap(json.decode(str));

  factory UTournamentMatchResponse.fromMap(Map<String, dynamic> json) => UTournamentMatchResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UTournamentMatchJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    round: json["round"],
    order: json["order"],
    tournamentId: json["tournamentId"],
    creatorId: json["creatorId"],
    scheduledAt: json["scheduledAt"] == null ? null : DateTime.parse(json["scheduledAt"]),
    entryAId: json["entryAId"],
    entryBId: json["entryBId"],
    winnerEntryId: json["winnerEntryId"],
    groupNumber: json["groupNumber"],
    partnerAId: json["partnerAId"],
    partnerBId: json["partnerBId"],
    nextMatchId: json["nextMatchId"],
    nextMatchSlot: json["nextMatchSlot"],
    loserNextMatchId: json["loserNextMatchId"],
    loserNextMatchSlot: json["loserNextMatchSlot"],
  );
  final String id;
  final DateTime createdAt;
  final UTournamentMatchJson jsonData;
  final List<int> tags;
  final int round;
  final int order;
  final String tournamentId;
  final String? creatorId;
  final DateTime? scheduledAt;
  final String? entryAId;
  final String? entryBId;
  final String? winnerEntryId;
  final int? groupNumber;

  /// Americano / Mexicano partners of side A and B.
  final String? partnerAId;
  final String? partnerBId;
  final String? nextMatchId;
  final int? nextMatchSlot;
  final String? loserNextMatchId;
  final int? loserNextMatchSlot;

  bool get isFinished => tags.contains(TagTournamentMatch.finished.number);

  bool get isBye => tags.contains(TagTournamentMatch.bye.number);

  /// Group, winners, losers, grand final or third place.
  TagTournamentMatch get bracket => TagTournamentMatch.values.group(200).firstWhereOrNull((TagTournamentMatch t) => tags.contains(t.number)) ?? TagTournamentMatch.group;

  bool get isKnockout => bracket != TagTournamentMatch.group;

  TagTournamentMatch? get status => TagTournamentMatch.values.group(100).firstWhereOrNull((TagTournamentMatch t) => tags.contains(t.number));

  /// Sets won by each side. `match.setsA`
  int get setsA => jsonData.sets.where((UMatchSetScore s) => s.a > s.b).length;

  int get setsB => jsonData.sets.where((UMatchSetScore s) => s.b > s.a).length;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "round": round,
    "order": order,
    "tournamentId": tournamentId,
    "creatorId": creatorId,
    "scheduledAt": scheduledAt?.toIso8601String(),
    "entryAId": entryAId,
    "entryBId": entryBId,
    "winnerEntryId": winnerEntryId,
    "groupNumber": groupNumber,
    "partnerAId": partnerAId,
    "partnerBId": partnerBId,
    "nextMatchId": nextMatchId,
    "nextMatchSlot": nextMatchSlot,
    "loserNextMatchId": loserNextMatchId,
    "loserNextMatchSlot": loserNextMatchSlot,
  };
}

class UTournamentMatchJson {
  UTournamentMatchJson({
    this.court,
    this.sets = const <UMatchSetScore>[],
    this.detail1,
    this.detail2,
  });

  factory UTournamentMatchJson.fromJson(String str) => UTournamentMatchJson.fromMap(json.decode(str));

  factory UTournamentMatchJson.fromMap(Map<String, dynamic> json) => UTournamentMatchJson(
    court: json["court"],
    sets: json["sets"] == null ? <UMatchSetScore>[] : List<UMatchSetScore>.from(json["sets"].map((dynamic x) => UMatchSetScore.fromMap(x))),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String? court;
  final List<UMatchSetScore> sets;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "court": court,
    "sets": sets.map((UMatchSetScore x) => x.toMap()).toList(),
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UMatchSetScore {
  UMatchSetScore({
    required this.a,
    required this.b,
  });

  factory UMatchSetScore.fromJson(String str) => UMatchSetScore.fromMap(json.decode(str));

  factory UMatchSetScore.fromMap(Map<String, dynamic> json) => UMatchSetScore(
    a: json["a"] ?? 0,
    b: json["b"] ?? 0,
  );
  final int a;
  final int b;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "a": a,
    "b": b,
  };
}

class UTournamentStandingResponse {
  UTournamentStandingResponse({
    required this.entryId,
    required this.users,
    required this.rank,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.setsFor,
    required this.setsAgainst,
    required this.scoreFor,
    required this.scoreAgainst,
    required this.points,
    this.title,
    this.groupNumber,
    this.promotion = 0,
  });

  factory UTournamentStandingResponse.fromJson(String str) => UTournamentStandingResponse.fromMap(json.decode(str));

  factory UTournamentStandingResponse.fromMap(Map<String, dynamic> json) => UTournamentStandingResponse(
    entryId: json["entryId"],
    title: json["title"],
    users: json["users"] == null ? <UUserResponse>[] : List<UUserResponse>.from(json["users"].map((dynamic x) => UUserResponse.fromMap(x))),
    rank: json["rank"] ?? 0,
    played: json["played"] ?? 0,
    won: json["won"] ?? 0,
    drawn: json["drawn"] ?? 0,
    lost: json["lost"] ?? 0,
    setsFor: json["setsFor"] ?? 0,
    setsAgainst: json["setsAgainst"] ?? 0,
    scoreFor: json["scoreFor"] ?? 0,
    scoreAgainst: json["scoreAgainst"] ?? 0,
    points: json["points"] ?? 0,
    groupNumber: json["groupNumber"],
    promotion: json["promotion"] ?? 0,
  );
  final String entryId;
  final String? title;
  final List<UUserResponse> users;
  final int rank;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int setsFor;
  final int setsAgainst;
  final int scoreFor;
  final int scoreAgainst;
  final int points;

  /// Group or box; null for a single table.
  final int? groupNumber;

  /// Box league: 1 moves up a box, -1 moves down.
  final int promotion;

  String get displayName =>
      title.nullIfEmpty() ?? users.map((UUserResponse u) => "${u.firstName ?? ""} ${u.lastName ?? ""}".trim()).where((String i) => i.isNotEmpty).join(" / ").nullIfEmpty() ?? "-";

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "entryId": entryId,
    "title": title,
    "users": users.map((UUserResponse x) => x.toMap()).toList(),
    "rank": rank,
    "played": played,
    "won": won,
    "drawn": drawn,
    "lost": lost,
    "setsFor": setsFor,
    "setsAgainst": setsAgainst,
    "scoreFor": scoreFor,
    "scoreAgainst": scoreAgainst,
    "points": points,
    "groupNumber": groupNumber,
    "promotion": promotion,
  };
}
