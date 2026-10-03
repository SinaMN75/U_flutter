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

class UTournamentCreateParams {
  UTournamentCreateParams({
    required this.tags,
    required this.title,
    required this.sportId,
    required this.startDate,
    required this.capacity,
    this.entryFee = 0,
    this.minLevel,
    this.maxLevel,
    this.description,
    this.prize,
    this.venue,
    this.address,
    this.latitude,
    this.longitude,
    this.pointsForWin,
    this.pointsForDraw,
    this.pointsForLoss,
    this.groupCount,
    this.advancePerGroup,
    this.thirdPlaceMatch,
    this.rounds,
    this.pointsPerMatch,
    this.boxSize,
    this.setsToWin,
    this.raceTo,
    this.superTiebreak,
    this.unrated,
    this.adminUserIds,
  });

  factory UTournamentCreateParams.fromJson(String str) => UTournamentCreateParams.fromMap(json.decode(str));

  factory UTournamentCreateParams.fromMap(Map<String, dynamic> json) => UTournamentCreateParams(
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    sportId: json["sportId"],
    startDate: DateTime.parse(json["startDate"]),
    capacity: json["capacity"],
    entryFee: json["entryFee"]?.toDouble() ?? 0,
    minLevel: json["minLevel"]?.toDouble(),
    maxLevel: json["maxLevel"]?.toDouble(),
    description: json["description"],
    prize: json["prize"],
    venue: json["venue"],
    address: json["address"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    pointsForWin: json["pointsForWin"],
    pointsForDraw: json["pointsForDraw"],
    pointsForLoss: json["pointsForLoss"],
    groupCount: json["groupCount"],
    advancePerGroup: json["advancePerGroup"],
    thirdPlaceMatch: json["thirdPlaceMatch"],
    rounds: json["rounds"],
    pointsPerMatch: json["pointsPerMatch"],
    boxSize: json["boxSize"],
    setsToWin: json["setsToWin"],
    raceTo: json["raceTo"],
    superTiebreak: json["superTiebreak"],
    unrated: json["unrated"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
  );
  final List<int> tags;
  final String title;
  final String sportId;
  final DateTime startDate;
  final int capacity;
  final double entryFee;
  final double? minLevel;
  final double? maxLevel;
  final String? description;
  final String? prize;
  final String? venue;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? pointsForWin;
  final int? pointsForDraw;
  final int? pointsForLoss;
  final int? groupCount;
  final int? advancePerGroup;
  final bool? thirdPlaceMatch;
  final int? rounds;
  final int? pointsPerMatch;
  final int? boxSize;
  final int? setsToWin;
  final int? raceTo;
  final bool? superTiebreak;
  final bool? unrated;
  final List<String>? adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "sportId": sportId,
    "startDate": startDate.toUtc().toIso8601String(),
    "capacity": capacity,
    "entryFee": entryFee,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
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
    "adminUserIds": adminUserIds,
  };
}

class UTournamentUpdateParams {
  UTournamentUpdateParams({
    required this.id,
    this.title,
    this.startDate,
    this.capacity,
    this.entryFee,
    this.minLevel,
    this.maxLevel,
    this.description,
    this.prize,
    this.venue,
    this.address,
    this.latitude,
    this.longitude,
    this.pointsForWin,
    this.pointsForDraw,
    this.pointsForLoss,
    this.groupCount,
    this.advancePerGroup,
    this.thirdPlaceMatch,
    this.rounds,
    this.pointsPerMatch,
    this.boxSize,
    this.setsToWin,
    this.raceTo,
    this.superTiebreak,
    this.unrated,
    this.tags,
    this.addTags,
    this.removeTags,
    this.adminUserIds,
  });

  factory UTournamentUpdateParams.fromJson(String str) => UTournamentUpdateParams.fromMap(json.decode(str));

  factory UTournamentUpdateParams.fromMap(Map<String, dynamic> json) => UTournamentUpdateParams(
    id: json["id"],
    title: json["title"],
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    capacity: json["capacity"],
    entryFee: json["entryFee"]?.toDouble(),
    minLevel: json["minLevel"]?.toDouble(),
    maxLevel: json["maxLevel"]?.toDouble(),
    description: json["description"],
    prize: json["prize"],
    venue: json["venue"],
    address: json["address"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    pointsForWin: json["pointsForWin"],
    pointsForDraw: json["pointsForDraw"],
    pointsForLoss: json["pointsForLoss"],
    groupCount: json["groupCount"],
    advancePerGroup: json["advancePerGroup"],
    thirdPlaceMatch: json["thirdPlaceMatch"],
    rounds: json["rounds"],
    pointsPerMatch: json["pointsPerMatch"],
    boxSize: json["boxSize"],
    setsToWin: json["setsToWin"],
    raceTo: json["raceTo"],
    superTiebreak: json["superTiebreak"],
    unrated: json["unrated"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
  );
  final String id;
  final String? title;
  final DateTime? startDate;
  final int? capacity;
  final double? entryFee;
  final double? minLevel;
  final double? maxLevel;
  final String? description;
  final String? prize;
  final String? venue;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? pointsForWin;
  final int? pointsForDraw;
  final int? pointsForLoss;
  final int? groupCount;
  final int? advancePerGroup;
  final bool? thirdPlaceMatch;
  final int? rounds;
  final int? pointsPerMatch;
  final int? boxSize;
  final int? setsToWin;
  final int? raceTo;
  final bool? superTiebreak;
  final bool? unrated;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<String>? adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "startDate": startDate?.toUtc().toIso8601String(),
    "capacity": capacity,
    "entryFee": entryFee,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
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
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "adminUserIds": adminUserIds,
  };
}

class UTournamentReadParams {
  UTournamentReadParams({
    this.sportId,
    this.userId,
    this.title,
    this.creatorId,
    this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.ids,
    this.orderBy,
  });

  factory UTournamentReadParams.fromJson(String str) => UTournamentReadParams.fromMap(json.decode(str));

  factory UTournamentReadParams.fromMap(Map<String, dynamic> json) => UTournamentReadParams(
    sportId: json["sportId"],
    userId: json["userId"],
    title: json["title"],
    creatorId: json["creatorId"],
    selectorArgs: json["selectorArgs"] == null ? null : UTournamentSelectorArgs.fromMap(json["selectorArgs"]),
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
  );
  final String? sportId;

  /// Only tournaments this user plays in.
  final String? userId;
  final String? title;
  final String? creatorId;
  final UTournamentSelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "sportId": sportId,
    "userId": userId,
    "title": title,
    "creatorId": creatorId,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags ?? <int>[],
    "ids": ids ?? <String>[],
    "orderBy": orderBy,
  };
}

class UTournamentRegisterParams {
  UTournamentRegisterParams({
    required this.tournamentId,
    this.title,
    this.partnerEmail,
    this.payFromWallet = false,
  });

  factory UTournamentRegisterParams.fromJson(String str) => UTournamentRegisterParams.fromMap(json.decode(str));

  factory UTournamentRegisterParams.fromMap(Map<String, dynamic> json) => UTournamentRegisterParams(
    tournamentId: json["tournamentId"],
    title: json["title"],
    partnerEmail: json["partnerEmail"],
    payFromWallet: json["payFromWallet"] ?? false,
  );
  final String tournamentId;
  final String? title;

  /// Doubles only: the partner's account email.
  final String? partnerEmail;

  /// Pays the entry fee from the wallet now; otherwise it is paid to the organizer at the venue.
  final bool payFromWallet;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tournamentId": tournamentId,
    "title": title,
    "partnerEmail": partnerEmail,
    "payFromWallet": payFromWallet,
  };
}

class UTournamentEntryUpdateParams {
  UTournamentEntryUpdateParams({
    required this.id,
    this.title,
    this.seed,
    this.groupNumber,
    this.tags,
    this.addTags,
    this.removeTags,
  });

  factory UTournamentEntryUpdateParams.fromJson(String str) => UTournamentEntryUpdateParams.fromMap(json.decode(str));

  factory UTournamentEntryUpdateParams.fromMap(Map<String, dynamic> json) => UTournamentEntryUpdateParams(
    id: json["id"],
    title: json["title"],
    seed: json["seed"],
    groupNumber: json["groupNumber"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
  );
  final String id;
  final String? title;
  final int? seed;
  final int? groupNumber;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "seed": seed,
    "groupNumber": groupNumber,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
  };
}

class UTournamentMatchUpdateParams {
  UTournamentMatchUpdateParams({
    required this.id,
    this.sets,
    this.scheduledAt,
    this.court,
    this.tags,
  });

  factory UTournamentMatchUpdateParams.fromJson(String str) => UTournamentMatchUpdateParams.fromMap(json.decode(str));

  factory UTournamentMatchUpdateParams.fromMap(Map<String, dynamic> json) => UTournamentMatchUpdateParams(
    id: json["id"],
    sets: json["sets"] == null ? null : List<UMatchSetScore>.from(json["sets"].map((dynamic x) => UMatchSetScore.fromMap(x))),
    scheduledAt: json["scheduledAt"] == null ? null : DateTime.parse(json["scheduledAt"]),
    court: json["court"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
  );
  final String id;

  /// The result; an empty list clears it.
  final List<UMatchSetScore>? sets;
  final DateTime? scheduledAt;
  final String? court;
  final List<int>? tags;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "sets": sets?.map((UMatchSetScore x) => x.toMap()).toList(),
    "scheduledAt": scheduledAt?.toUtc().toIso8601String(),
    "court": court,
    "tags": tags,
  };
}

class UTournamentMatchReadParams {
  UTournamentMatchReadParams({
    this.userId,
    this.tournamentId,
    this.sportId,
    this.upcoming,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UTournamentMatchReadParams.fromJson(String str) => UTournamentMatchReadParams.fromMap(json.decode(str));

  factory UTournamentMatchReadParams.fromMap(Map<String, dynamic> json) => UTournamentMatchReadParams(
    userId: json["userId"],
    tournamentId: json["tournamentId"],
    sportId: json["sportId"],
    upcoming: json["upcoming"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UTournamentMatchSelectorArgs.fromMap(json["selectorArgs"]),
  );

  /// Matches this user plays in.
  final String? userId;
  final String? tournamentId;
  final String? sportId;

  /// true: not played yet, soonest first; false: played, latest first.
  final bool? upcoming;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UTournamentMatchSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "tournamentId": tournamentId,
    "sportId": sportId,
    "upcoming": upcoming,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UPlayerRatingHistoryReadParams {
  UPlayerRatingHistoryReadParams({
    this.userId,
    this.sportId,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
  });

  factory UPlayerRatingHistoryReadParams.fromJson(String str) => UPlayerRatingHistoryReadParams.fromMap(json.decode(str));

  factory UPlayerRatingHistoryReadParams.fromMap(Map<String, dynamic> json) => UPlayerRatingHistoryReadParams(
    userId: json["userId"],
    sportId: json["sportId"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
  );

  final String? userId;
  final String? sportId;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "sportId": sportId,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  };
}

class UPlayerAchievementReadParams {
  UPlayerAchievementReadParams({
    this.userId,
    this.sportId,
    this.tournamentId,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UPlayerAchievementReadParams.fromJson(String str) => UPlayerAchievementReadParams.fromMap(json.decode(str));

  factory UPlayerAchievementReadParams.fromMap(Map<String, dynamic> json) => UPlayerAchievementReadParams(
    userId: json["userId"],
    sportId: json["sportId"],
    tournamentId: json["tournamentId"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UPlayerAchievementSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final String? userId;
  final String? sportId;
  final String? tournamentId;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UPlayerAchievementSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "sportId": sportId,
    "tournamentId": tournamentId,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

/// Only the hidden tag changes: a player shows or hides a trophy.
class UPlayerAchievementUpdateParams {
  UPlayerAchievementUpdateParams({
    required this.id,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UPlayerAchievementUpdateParams.fromJson(String str) => UPlayerAchievementUpdateParams.fromMap(json.decode(str));

  factory UPlayerAchievementUpdateParams.fromMap(Map<String, dynamic> json) => UPlayerAchievementUpdateParams(
    id: json["id"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String id;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class ULeaderboardParams {
  ULeaderboardParams({
    required this.sportId,
    this.byPoints = false,
    this.year,
    this.country,
    this.city,
    this.pageSize,
    this.pageNumber,
  });

  factory ULeaderboardParams.fromJson(String str) => ULeaderboardParams.fromMap(json.decode(str));

  factory ULeaderboardParams.fromMap(Map<String, dynamic> json) => ULeaderboardParams(
    sportId: json["sportId"],
    byPoints: json["byPoints"] ?? false,
    year: json["year"],
    country: json["country"],
    city: json["city"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
  );

  final String sportId;

  /// Ranking points from tournament placements; otherwise the level.
  final bool byPoints;

  /// Points of this year only (the season); null = all time.
  final int? year;
  final String? country;
  final String? city;
  final int? pageSize;
  final int? pageNumber;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "sportId": sportId,
    "byPoints": byPoints,
    "year": year,
    "country": country,
    "city": city,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  };
}

class UPlayerStatsParams {
  UPlayerStatsParams({
    this.userId,
    this.sportId,
  });

  factory UPlayerStatsParams.fromJson(String str) => UPlayerStatsParams.fromMap(json.decode(str));

  factory UPlayerStatsParams.fromMap(Map<String, dynamic> json) => UPlayerStatsParams(
    userId: json["userId"],
    sportId: json["sportId"],
  );

  /// null = the signed-in user.
  final String? userId;
  final String? sportId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "sportId": sportId,
  };
}

class UOpenMatchCreateParams {
  UOpenMatchCreateParams({
    required this.sportId,
    required this.startAt,
    this.tags = const <int>[],
    this.durationMinutes = 90,
    this.capacity = 4,
    this.minLevel,
    this.maxLevel,
    this.pricePerPlayer = 0,
    this.venueId,
    this.bookingId,
    this.title,
    this.description,
    this.place,
    this.latitude,
    this.longitude,
    this.invitedUserIds = const <String>[],
    this.adminUserIds,
    this.id,
    this.detail1,
    this.detail2,
  });

  factory UOpenMatchCreateParams.fromJson(String str) => UOpenMatchCreateParams.fromMap(json.decode(str));

  factory UOpenMatchCreateParams.fromMap(Map<String, dynamic> json) => UOpenMatchCreateParams(
    sportId: json["sportId"],
    startAt: DateTime.parse(json["startAt"]),
    tags: json["tags"] == null ? const <int>[] : List<int>.from(json["tags"].map((dynamic x) => x)),
    durationMinutes: json["durationMinutes"] ?? 90,
    capacity: json["capacity"] ?? 4,
    minLevel: json["minLevel"]?.toDouble(),
    maxLevel: json["maxLevel"]?.toDouble(),
    pricePerPlayer: json["pricePerPlayer"]?.toDouble() ?? 0,
    venueId: json["venueId"],
    bookingId: json["bookingId"],
    title: json["title"],
    description: json["description"],
    place: json["place"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    invitedUserIds: json["invitedUserIds"] == null ? const <String>[] : List<String>.from(json["invitedUserIds"].map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String sportId;
  final DateTime startAt;
  final List<int> tags;
  final int durationMinutes;
  final int capacity;
  final double? minLevel;
  final double? maxLevel;
  final double pricePerPlayer;
  final String? venueId;
  final String? bookingId;
  final String? title;
  final String? description;
  final String? place;
  final double? latitude;
  final double? longitude;

  /// They may join without approval (a challenge invites its opponents).
  final List<String> invitedUserIds;
  final List<String>? adminUserIds;
  final String? id;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "sportId": sportId,
    "startAt": startAt.toUtc().toIso8601String(),
    "tags": tags,
    "durationMinutes": durationMinutes,
    "capacity": capacity,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
    "pricePerPlayer": pricePerPlayer,
    "venueId": venueId,
    "bookingId": bookingId,
    "title": title,
    "description": description,
    "place": place,
    "latitude": latitude,
    "longitude": longitude,
    "invitedUserIds": invitedUserIds,
    "adminUserIds": adminUserIds,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UOpenMatchUpdateParams {
  UOpenMatchUpdateParams({
    required this.id,
    this.startAt,
    this.durationMinutes,
    this.capacity,
    this.minLevel,
    this.maxLevel,
    this.pricePerPlayer,
    this.venueId,
    this.title,
    this.description,
    this.place,
    this.latitude,
    this.longitude,
    this.approveUserIds,
    this.removeUserIds,
    this.inviteUserIds,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UOpenMatchUpdateParams.fromJson(String str) => UOpenMatchUpdateParams.fromMap(json.decode(str));

  factory UOpenMatchUpdateParams.fromMap(Map<String, dynamic> json) => UOpenMatchUpdateParams(
    id: json["id"],
    startAt: json["startAt"] == null ? null : DateTime.parse(json["startAt"]),
    durationMinutes: json["durationMinutes"],
    capacity: json["capacity"],
    minLevel: json["minLevel"]?.toDouble(),
    maxLevel: json["maxLevel"]?.toDouble(),
    pricePerPlayer: json["pricePerPlayer"]?.toDouble(),
    venueId: json["venueId"],
    title: json["title"],
    description: json["description"],
    place: json["place"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    approveUserIds: json["approveUserIds"] == null ? null : List<String>.from(json["approveUserIds"].map((dynamic x) => x)),
    removeUserIds: json["removeUserIds"] == null ? null : List<String>.from(json["removeUserIds"].map((dynamic x) => x)),
    inviteUserIds: json["inviteUserIds"] == null ? null : List<String>.from(json["inviteUserIds"].map((dynamic x) => x)),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String id;
  final DateTime? startAt;
  final int? durationMinutes;
  final int? capacity;
  final double? minLevel;
  final double? maxLevel;
  final double? pricePerPlayer;
  final String? venueId;
  final String? title;
  final String? description;
  final String? place;
  final double? latitude;
  final double? longitude;

  /// Players who asked to join a private game.
  final List<String>? approveUserIds;
  final List<String>? removeUserIds;
  final List<String>? inviteUserIds;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "startAt": startAt?.toUtc().toIso8601String(),
    "durationMinutes": durationMinutes,
    "capacity": capacity,
    "minLevel": minLevel,
    "maxLevel": maxLevel,
    "pricePerPlayer": pricePerPlayer,
    "venueId": venueId,
    "title": title,
    "description": description,
    "place": place,
    "latitude": latitude,
    "longitude": longitude,
    "approveUserIds": approveUserIds,
    "removeUserIds": removeUserIds,
    "inviteUserIds": inviteUserIds,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UOpenMatchReadParams {
  UOpenMatchReadParams({
    this.sportId,
    this.userId,
    this.venueId,
    this.upcoming,
    this.forMyLevel = false,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UOpenMatchReadParams.fromJson(String str) => UOpenMatchReadParams.fromMap(json.decode(str));

  factory UOpenMatchReadParams.fromMap(Map<String, dynamic> json) => UOpenMatchReadParams(
    sportId: json["sportId"],
    userId: json["userId"],
    venueId: json["venueId"],
    upcoming: json["upcoming"],
    forMyLevel: json["forMyLevel"] ?? false,
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    radiusKm: json["radiusKm"]?.toDouble(),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UOpenMatchSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final String? sportId;

  /// Games this user plays in or organizes.
  final String? userId;
  final String? venueId;
  final bool? upcoming;
  final bool forMyLevel;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UOpenMatchSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "sportId": sportId,
    "userId": userId,
    "venueId": venueId,
    "upcoming": upcoming,
    "forMyLevel": forMyLevel,
    "latitude": latitude,
    "longitude": longitude,
    "radiusKm": radiusKm,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UOpenMatchResultParams {
  UOpenMatchResultParams({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.sets,
  });

  factory UOpenMatchResultParams.fromJson(String str) => UOpenMatchResultParams.fromMap(json.decode(str));

  factory UOpenMatchResultParams.fromMap(Map<String, dynamic> json) => UOpenMatchResultParams(
    id: json["id"],
    teamA: List<String>.from(json["teamA"].map((dynamic x) => x)),
    teamB: List<String>.from(json["teamB"].map((dynamic x) => x)),
    sets: List<UMatchSetScore>.from(json["sets"].map((dynamic x) => UMatchSetScore.fromMap(x))),
  );

  final String id;
  final List<String> teamA;
  final List<String> teamB;

  /// An empty list clears the result.
  final List<UMatchSetScore> sets;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "teamA": teamA,
    "teamB": teamB,
    "sets": sets.map((UMatchSetScore x) => x.toMap()).toList(),
  };
}
