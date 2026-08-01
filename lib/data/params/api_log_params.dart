part of "../data.dart";

class UApiLogReadParams {
  final String? creatorId;
  final dynamic selectorArgs;
  UApiLogReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.orderBy,
    this.pathContains,
    this.statusCode,
    this.minDurationMs,
    this.maxDurationMs,
    this.userId,
    this.ipAddress,
    this.onlyErrors,
    this.creatorId,
    this.selectorArgs,
  });

  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final String? pathContains;
  final int? statusCode;
  final int? minDurationMs;
  final int? maxDurationMs;
  final String? userId;
  final String? ipAddress;
  final bool? onlyErrors;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "orderBy": orderBy,
    "pathContains": pathContains,
    "statusCode": statusCode,
    "minDurationMs": minDurationMs,
    "maxDurationMs": maxDurationMs,
    "userId": userId,
    "ipAddress": ipAddress,
    "onlyErrors": onlyErrors,
    "creatorId": creatorId,
    "selectorArgs": selectorArgs,
  };

  factory UApiLogReadParams.fromMap(Map<String, dynamic> json) => UApiLogReadParams(
    creatorId: json["creatorId"],
    selectorArgs: json["selectorArgs"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pathContains: json["pathContains"],
    statusCode: json["statusCode"],
    minDurationMs: json["minDurationMs"],
    maxDurationMs: json["maxDurationMs"],
    userId: json["userId"],
    ipAddress: json["ipAddress"],
    onlyErrors: json["onlyErrors"],
  );

  String toJson() => json.encode(toMap());

  factory UApiLogReadParams.fromJson(String str) => UApiLogReadParams.fromMap(json.decode(str));
}

class UApiLogStatsParams {
  UApiLogStatsParams({
    this.fromCreatedAt,
    this.toCreatedAt,
    this.bucket = "hour",
  });

  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final String bucket;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "bucket": bucket,
  };

  factory UApiLogStatsParams.fromMap(Map<String, dynamic> json) => UApiLogStatsParams(
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    bucket: json["bucket"],
  );

  String toJson() => json.encode(toMap());

  factory UApiLogStatsParams.fromJson(String str) => UApiLogStatsParams.fromMap(json.decode(str));
}
