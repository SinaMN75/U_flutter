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
    "user": user?.toMap(),
    "sport": sport?.toMap(),
  };
}
