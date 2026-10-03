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
    jsonData: UTournamentEntryJson.fromMap(json["jsonData"]),
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
  final UTournamentEntryJson jsonData;
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
      title.nullIfEmpty() ??
      (users ?? <UUserResponse>[]).map((UUserResponse u) => "${u.firstName ?? ""} ${u.lastName ?? ""}".trim()).where((String i) => i.isNotEmpty).join(" / ").nullIfEmpty() ??
      "-";

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
    this.tournament,
    this.entryA,
    this.entryB,
    this.partnerA,
    this.partnerB,
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
    tournament: json["tournament"] == null ? null : UTournamentResponse.fromMap(json["tournament"]),
    entryA: json["entryA"] == null ? null : UTournamentEntryResponse.fromMap(json["entryA"]),
    entryB: json["entryB"] == null ? null : UTournamentEntryResponse.fromMap(json["entryB"]),
    partnerA: json["partnerA"] == null ? null : UTournamentEntryResponse.fromMap(json["partnerA"]),
    partnerB: json["partnerB"] == null ? null : UTournamentEntryResponse.fromMap(json["partnerB"]),
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

  /// Filled when read with the match history (UTournamentMatchSelectorArgs.tournament / entries).
  final UTournamentResponse? tournament;
  final UTournamentEntryResponse? entryA;
  final UTournamentEntryResponse? entryB;
  final UTournamentEntryResponse? partnerA;
  final UTournamentEntryResponse? partnerB;

  /// Side A's name from the read entries. `match.sideAName` → "Sara / Ali"
  String get sideAName => <UTournamentEntryResponse?>[entryA, partnerA].whereType<UTournamentEntryResponse>().map((UTournamentEntryResponse e) => e.displayName).join(" / ").nullIfEmpty() ?? "-";

  String get sideBName => <UTournamentEntryResponse?>[entryB, partnerB].whereType<UTournamentEntryResponse>().map((UTournamentEntryResponse e) => e.displayName).join(" / ").nullIfEmpty() ?? "-";

  /// 1 won, 0 drawn, -1 lost, null if the user isn't in it (read with entries).
  int? resultFor(String? userId) {
    bool has(UTournamentEntryResponse? e) => e?.users?.any((UUserResponse u) => u.id == userId) ?? false;
    final bool onA = has(entryA) || has(partnerA);
    final bool onB = has(entryB) || has(partnerB);
    if (!onA && !onB || !isFinished) return null;
    final int scoreA = jsonData.sets.fold(0, (int s, UMatchSetScore x) => s + x.a);
    final int scoreB = jsonData.sets.fold(0, (int s, UMatchSetScore x) => s + x.b);
    final int resultA = winnerEntryId != null
        ? (winnerEntryId == entryAId ? 1 : -1)
        : partnerAId != null
        ? (scoreA - scoreB).sign
        : 0;
    return onA ? resultA : -resultA;
  }

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
    "tournament": tournament?.toMap(),
    "entryA": entryA?.toMap(),
    "entryB": entryB?.toMap(),
    "partnerA": partnerA?.toMap(),
    "partnerB": partnerB?.toMap(),
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

  String get displayName => title.nullIfEmpty() ?? users.map((UUserResponse u) => "${u.firstName ?? ""} ${u.lastName ?? ""}".trim()).where((String i) => i.isNotEmpty).join(" / ").nullIfEmpty() ?? "-";

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

class UTournamentEntryJson {
  UTournamentEntryJson({
    this.paidAmount = 0,
    this.refunded = false,
    this.settled = false,
    this.detail1,
    this.detail2,
  });

  factory UTournamentEntryJson.fromJson(String str) => UTournamentEntryJson.fromMap(json.decode(str));

  factory UTournamentEntryJson.fromMap(Map<String, dynamic> json) => UTournamentEntryJson(
    paidAmount: json["paidAmount"]?.toDouble() ?? 0,
    refunded: json["refunded"] ?? false,
    settled: json["settled"] ?? false,
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  /// The entry fee paid from the wallet.
  final double paidAmount;
  final bool refunded;
  final bool settled;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "paidAmount": paidAmount,
    "refunded": refunded,
    "settled": settled,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UPlayerRatingHistoryResponse {
  UPlayerRatingHistoryResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.userId,
    required this.sportId,
    required this.matchId,
    this.creatorId,
    this.levelBefore = 0,
    this.levelAfter = 0,
  });

  factory UPlayerRatingHistoryResponse.fromJson(String str) => UPlayerRatingHistoryResponse.fromMap(json.decode(str));

  factory UPlayerRatingHistoryResponse.fromMap(Map<String, dynamic> json) => UPlayerRatingHistoryResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    userId: json["userId"],
    sportId: json["sportId"],
    matchId: json["matchId"],
    levelBefore: json["levelBefore"]?.toDouble() ?? 0,
    levelAfter: json["levelAfter"]?.toDouble() ?? 0,
  );

  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String userId;
  final String sportId;
  final String matchId;
  final double levelBefore;
  final double levelAfter;

  double get change => levelAfter - levelBefore;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "userId": userId,
    "sportId": sportId,
    "matchId": matchId,
    "levelBefore": levelBefore,
    "levelAfter": levelAfter,
  };
}

class UPlayerAchievementJson {
  UPlayerAchievementJson({
    this.title,
    this.badge,
    this.entryCount = 0,
    this.detail1,
    this.detail2,
  });

  factory UPlayerAchievementJson.fromJson(String str) => UPlayerAchievementJson.fromMap(json.decode(str));

  factory UPlayerAchievementJson.fromMap(Map<String, dynamic> json) => UPlayerAchievementJson(
    title: json["title"],
    badge: json["badge"],
    entryCount: json["entryCount"] ?? 0,
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  /// The tournament's title when it was won.
  final String? title;

  /// A badge key (UBadges); translate it with UBadges.label.
  final String? badge;
  final int entryCount;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "badge": badge,
    "entryCount": entryCount,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UPlayerAchievementResponse {
  UPlayerAchievementResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.userId,
    this.creatorId,
    this.sportId,
    this.tournamentId,
    this.rank,
    this.points = 0,
    this.user,
    this.sport,
  });

  factory UPlayerAchievementResponse.fromJson(String str) => UPlayerAchievementResponse.fromMap(json.decode(str));

  factory UPlayerAchievementResponse.fromMap(Map<String, dynamic> json) => UPlayerAchievementResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UPlayerAchievementJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    userId: json["userId"],
    sportId: json["sportId"],
    tournamentId: json["tournamentId"],
    rank: json["rank"],
    points: json["points"] ?? 0,
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    sport: json["sport"] == null ? null : USportResponse.fromMap(json["sport"]),
  );

  final String id;
  final DateTime createdAt;
  final UPlayerAchievementJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String userId;
  final String? sportId;
  final String? tournamentId;
  final int? rank;
  final int points;
  final UUserResponse? user;
  final USportResponse? sport;

  bool get isHidden => tags.contains(TagPlayerAchievement.hidden.number);

  bool get isBadge => tags.contains(TagPlayerAchievement.badge.number);

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "userId": userId,
    "sportId": sportId,
    "tournamentId": tournamentId,
    "rank": rank,
    "points": points,
    "user": user?.toMap(),
    "sport": sport?.toMap(),
  };
}

class ULeaderboardRowResponse {
  ULeaderboardRowResponse({
    required this.rank,
    required this.user,
    this.level = 0,
    this.points = 0,
    this.matchesPlayed = 0,
  });

  factory ULeaderboardRowResponse.fromJson(String str) => ULeaderboardRowResponse.fromMap(json.decode(str));

  factory ULeaderboardRowResponse.fromMap(Map<String, dynamic> json) => ULeaderboardRowResponse(
    rank: json["rank"],
    user: UUserResponse.fromMap(json["user"]),
    level: json["level"]?.toDouble() ?? 0,
    points: json["points"] ?? 0,
    matchesPlayed: json["matchesPlayed"] ?? 0,
  );

  final int rank;
  final UUserResponse user;
  final double level;
  final int points;
  final int matchesPlayed;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "rank": rank,
    "user": user.toMap(),
    "level": level,
    "points": points,
    "matchesPlayed": matchesPlayed,
  };
}

class UPlayerStatsResponse {
  UPlayerStatsResponse({
    this.user,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winRate = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
    this.weeklyStreak = 0,
    this.tournamentsPlayed = 0,
    this.tournamentWins = 0,
    this.podiums = 0,
    this.rankingPoints = 0,
    this.followers = 0,
    this.following = 0,
    this.referralCode,
    this.referralCount = 0,
  });

  factory UPlayerStatsResponse.fromJson(String str) => UPlayerStatsResponse.fromMap(json.decode(str));

  factory UPlayerStatsResponse.fromMap(Map<String, dynamic> json) => UPlayerStatsResponse(
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    matchesPlayed: json["matchesPlayed"] ?? 0,
    wins: json["wins"] ?? 0,
    losses: json["losses"] ?? 0,
    draws: json["draws"] ?? 0,
    winRate: json["winRate"] ?? 0,
    currentWinStreak: json["currentWinStreak"] ?? 0,
    bestWinStreak: json["bestWinStreak"] ?? 0,
    weeklyStreak: json["weeklyStreak"] ?? 0,
    tournamentsPlayed: json["tournamentsPlayed"] ?? 0,
    tournamentWins: json["tournamentWins"] ?? 0,
    podiums: json["podiums"] ?? 0,
    rankingPoints: json["rankingPoints"] ?? 0,
    followers: json["followers"] ?? 0,
    following: json["following"] ?? 0,
    referralCode: json["referralCode"],
    referralCount: json["referralCount"] ?? 0,
  );

  /// Public fields only.
  final UUserResponse? user;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;

  /// Percent.
  final int winRate;
  final int currentWinStreak;
  final int bestWinStreak;

  /// Weeks in a row with at least one match.
  final int weeklyStreak;
  final int tournamentsPlayed;
  final int tournamentWins;
  final int podiums;
  final int rankingPoints;
  final int followers;
  final int following;

  /// The signed-in user's own only.
  final String? referralCode;
  final int referralCount;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "user": user?.toMap(),
    "matchesPlayed": matchesPlayed,
    "wins": wins,
    "losses": losses,
    "draws": draws,
    "winRate": winRate,
    "currentWinStreak": currentWinStreak,
    "bestWinStreak": bestWinStreak,
    "weeklyStreak": weeklyStreak,
    "tournamentsPlayed": tournamentsPlayed,
    "tournamentWins": tournamentWins,
    "podiums": podiums,
    "rankingPoints": rankingPoints,
    "followers": followers,
    "following": following,
    "referralCode": referralCode,
    "referralCount": referralCount,
  };
}

class UOpenMatchJson {
  UOpenMatchJson({
    this.title,
    this.description,
    this.place,
    this.latitude,
    this.longitude,
    this.bookingId,
    this.pendingUserIds = const <String>[],
    this.invitedUserIds = const <String>[],
    this.teamA = const <String>[],
    this.teamB = const <String>[],
    this.sets = const <UMatchSetScore>[],
    this.detail1,
    this.detail2,
  });

  factory UOpenMatchJson.fromJson(String str) => UOpenMatchJson.fromMap(json.decode(str));

  factory UOpenMatchJson.fromMap(Map<String, dynamic> json) => UOpenMatchJson(
    title: json["title"],
    description: json["description"],
    place: json["place"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    bookingId: json["bookingId"],
    pendingUserIds: json["pendingUserIds"] == null ? const <String>[] : List<String>.from(json["pendingUserIds"].map((dynamic x) => x)),
    invitedUserIds: json["invitedUserIds"] == null ? const <String>[] : List<String>.from(json["invitedUserIds"].map((dynamic x) => x)),
    teamA: json["teamA"] == null ? const <String>[] : List<String>.from(json["teamA"].map((dynamic x) => x)),
    teamB: json["teamB"] == null ? const <String>[] : List<String>.from(json["teamB"].map((dynamic x) => x)),
    sets: json["sets"] == null ? const <UMatchSetScore>[] : List<UMatchSetScore>.from(json["sets"].map((dynamic x) => UMatchSetScore.fromMap(x))),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? title;
  final String? description;
  final String? place;
  final double? latitude;
  final double? longitude;
  final String? bookingId;
  final List<String> pendingUserIds;
  final List<String> invitedUserIds;
  final List<String> teamA;
  final List<String> teamB;
  final List<UMatchSetScore> sets;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "description": description,
    "place": place,
    "latitude": latitude,
    "longitude": longitude,
    "bookingId": bookingId,
    "pendingUserIds": pendingUserIds,
    "invitedUserIds": invitedUserIds,
    "teamA": teamA,
    "teamB": teamB,
    "sets": sets.map((UMatchSetScore x) => x.toMap()).toList(),
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UOpenMatchResponse {
  UOpenMatchResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.startAt,
    required this.capacity,
    required this.sportId,
    this.creatorId,
    this.durationMinutes = 90,
    this.minLevel,
    this.maxLevel,
    this.pricePerPlayer = 0,
    this.venueId,
    this.playerCount = 0,
    this.adminUserIds = const <String>[],
    this.sport,
    this.venue,
    this.users,
    this.creator,
  });

  factory UOpenMatchResponse.fromJson(String str) => UOpenMatchResponse.fromMap(json.decode(str));

  factory UOpenMatchResponse.fromMap(Map<String, dynamic> json) => UOpenMatchResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UOpenMatchJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    startAt: DateTime.parse(json["startAt"]),
    capacity: json["capacity"],
    sportId: json["sportId"],
    durationMinutes: json["durationMinutes"] ?? 90,
    minLevel: json["minLevel"]?.toDouble(),
    maxLevel: json["maxLevel"]?.toDouble(),
    pricePerPlayer: json["pricePerPlayer"]?.toDouble() ?? 0,
    venueId: json["venueId"],
    playerCount: json["playerCount"] ?? 0,
    adminUserIds: json["adminUserIds"] == null ? const <String>[] : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
    sport: json["sport"] == null ? null : USportResponse.fromMap(json["sport"]),
    venue: json["venue"] == null ? null : UVenueResponse.fromMap(json["venue"]),
    users: json["users"] == null ? null : List<UUserResponse>.from(json["users"].map((dynamic x) => UUserResponse.fromMap(x))),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
  );

  final String id;
  final DateTime createdAt;
  final UOpenMatchJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final DateTime startAt;
  final int capacity;
  final String sportId;
  final int durationMinutes;
  final double? minLevel;
  final double? maxLevel;
  final double pricePerPlayer;
  final String? venueId;
  final int playerCount;
  final List<String> adminUserIds;
  final USportResponse? sport;
  final UVenueResponse? venue;

  /// Only public fields.
  final List<UUserResponse>? users;
  final UUserResponse? creator;

  TagOpenMatch? get status => TagOpenMatch.values.group(100).firstWhereOrNull((TagOpenMatch t) => tags.contains(t.number));

  bool get isPrivate => tags.contains(TagOpenMatch.private.number);

  bool get isCompetitive => tags.contains(TagOpenMatch.competitive.number);

  bool get isChallenge => tags.contains(TagOpenMatch.challenge.number);

  bool isOrganizer(String? userId) => userId != null && (creatorId == userId || adminUserIds.contains(userId));

  bool hasPlayer(String? userId) => users?.any((UUserResponse u) => u.id == userId) ?? false;

  /// Where it is played: the venue's title or the typed place.
  String get placeTitle => venue?.title ?? jsonData.place ?? "-";

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "startAt": startAt.toIso8601String(),
    "capacity": capacity,
    "sportId": sportId,
    "durationMinutes": durationMinutes,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
    "pricePerPlayer": pricePerPlayer,
    "venueId": venueId,
    "playerCount": playerCount,
    "adminUserIds": adminUserIds,
    "sport": sport?.toMap(),
    "venue": venue?.toMap(),
    "users": users?.map((UUserResponse x) => x.toMap()).toList(),
    "creator": creator?.toMap(),
  };
}

/// Badge keys from the server and their texts. `UBadges.label(a.jsonData.badge)` → "First win"
abstract class UBadges {
  static const List<String> all = <String>["firstMatch", "tenMatches", "fiftyMatches", "firstWin", "winStreak5", "champion", "podium", "organizer", "recruiter", "regular"];

  static String label(String? key) => switch (key) {
    "firstMatch" => U.s.badgeFirstMatch,
    "tenMatches" => U.s.badgeTenMatches,
    "fiftyMatches" => U.s.badgeFiftyMatches,
    "firstWin" => U.s.badgeFirstWin,
    "winStreak5" => U.s.badgeWinStreak5,
    "champion" => U.s.badgeChampion,
    "podium" => U.s.badgePodium,
    "organizer" => U.s.badgeOrganizer,
    "recruiter" => U.s.badgeRecruiter,
    "regular" => U.s.badgeRegular,
    _ => key ?? "-",
  };

  static String description(String? key) => switch (key) {
    "firstMatch" => U.s.badgeFirstMatchDescription,
    "tenMatches" => U.s.badgeTenMatchesDescription,
    "fiftyMatches" => U.s.badgeFiftyMatchesDescription,
    "firstWin" => U.s.badgeFirstWinDescription,
    "winStreak5" => U.s.badgeWinStreak5Description,
    "champion" => U.s.badgeChampionDescription,
    "podium" => U.s.badgePodiumDescription,
    "organizer" => U.s.badgeOrganizerDescription,
    "recruiter" => U.s.badgeRecruiterDescription,
    "regular" => U.s.badgeRegularDescription,
    _ => "",
  };
}
