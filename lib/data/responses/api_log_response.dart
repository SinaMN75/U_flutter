part of "../data.dart";

class UApiLogResponse {
  final List<String> adminUserIds;
  UApiLogResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.creatorId,
    required this.path,
    required this.statusCode,
    required this.durationMs,
    required this.adminUserIds,
    this.creator,
    this.userId,
    this.ipAddress,
  });

  factory UApiLogResponse.fromMap(Map<String, dynamic> json) => UApiLogResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UApiLogJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]),
    creatorId: json["creatorId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    path: json["path"] ?? "",
    statusCode: json["statusCode"] ?? 0,
    durationMs: json["durationMs"] is int ? json["durationMs"] : int.tryParse(json["durationMs"].toString()) ?? 0,
    userId: json["userId"],
    ipAddress: json["ipAddress"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  final String id;
  final DateTime createdAt;
  final UApiLogJson jsonData;
  final List<int> tags;
  final String creatorId;
  final UUserResponse? creator;
  final String path;
  final int statusCode;
  final int durationMs;
  final String? userId;
  final String? ipAddress;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "creatorId": creatorId,
    "creator": creator?.toMap(),
    "path": path,
    "statusCode": statusCode,
    "durationMs": durationMs,
    "userId": userId,
    "ipAddress": ipAddress,
  };

  String toJson() => json.encode(toMap());

  factory UApiLogResponse.fromJson(String str) => UApiLogResponse.fromMap(json.decode(str));
}

class UApiLogJson {
  UApiLogJson({
    required this.method,
    this.queryString,
    this.requestBody,
    this.responseBody,
    this.requestHeaders,
    this.responseHeaders,
    this.userAgent,
    this.host,
    this.userName,
    this.userEmail,
    this.userRoles,
    this.userFirstName,
    this.userLastName,
    this.userPhoneNumber,
    this.exceptionType,
    this.exceptionMessage,
    this.stackTrace,
    this.requestSizeBytes = 0,
    this.responseSizeBytes = 0,
    this.detail1,
    this.detail2,
  });

  factory UApiLogJson.fromMap(Map<String, dynamic> json) => UApiLogJson(
    method: json["method"] ?? "",
    queryString: json["queryString"],
    requestBody: json["requestBody"],
    responseBody: json["responseBody"],
    requestHeaders: json["requestHeaders"],
    responseHeaders: json["responseHeaders"],
    userAgent: json["userAgent"],
    host: json["host"],
    userName: json["userName"],
    userEmail: json["userEmail"],
    userRoles: json["userRoles"],
    userFirstName: json["userFirstName"],
    userLastName: json["userLastName"],
    userPhoneNumber: json["userPhoneNumber"],
    exceptionType: json["exceptionType"],
    exceptionMessage: json["exceptionMessage"],
    stackTrace: json["stackTrace"],
    requestSizeBytes: json["requestSizeBytes"] ?? 0,
    responseSizeBytes: json["responseSizeBytes"] ?? 0,
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? detail1;
  final String? detail2;
  final String method;
  final String? queryString;
  final String? requestBody;
  final String? responseBody;
  final String? requestHeaders;
  final String? responseHeaders;
  final String? userAgent;
  final String? host;
  final String? userName;
  final String? userEmail;
  final String? userRoles;
  final String? userFirstName;
  final String? userLastName;
  final String? userPhoneNumber;
  final String? exceptionType;
  final String? exceptionMessage;
  final String? stackTrace;
  final int requestSizeBytes;
  final int responseSizeBytes;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "method": method,
    "queryString": queryString,
    "requestBody": requestBody,
    "responseBody": responseBody,
    "requestHeaders": requestHeaders,
    "responseHeaders": responseHeaders,
    "userAgent": userAgent,
    "host": host,
    "userName": userName,
    "userEmail": userEmail,
    "userRoles": userRoles,
    "userFirstName": userFirstName,
    "userLastName": userLastName,
    "userPhoneNumber": userPhoneNumber,
    "exceptionType": exceptionType,
    "exceptionMessage": exceptionMessage,
    "stackTrace": stackTrace,
    "requestSizeBytes": requestSizeBytes,
    "responseSizeBytes": responseSizeBytes,
  };

  String toJson() => json.encode(toMap());

  factory UApiLogJson.fromJson(String str) => UApiLogJson.fromMap(json.decode(str));
}

class UApiLogBucketResponse {
  UApiLogBucketResponse({
    required this.time,
    required this.count,
    required this.errorCount,
    required this.averageDurationMs,
  });

  factory UApiLogBucketResponse.fromMap(Map<String, dynamic> json) => UApiLogBucketResponse(
    time: DateTime.parse(json["time"]),
    count: json["count"] ?? 0,
    errorCount: json["errorCount"] ?? 0,
    averageDurationMs: (json["averageDurationMs"] as num?)?.toDouble() ?? 0,
  );

  final DateTime time;
  final int count;
  final int errorCount;
  final double averageDurationMs;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "time": time.toIso8601String(),
    "count": count,
    "errorCount": errorCount,
    "averageDurationMs": averageDurationMs,
  };

  String toJson() => json.encode(toMap());

  factory UApiLogBucketResponse.fromJson(String str) => UApiLogBucketResponse.fromMap(json.decode(str));
}

class UApiLogEndpointResponse {
  UApiLogEndpointResponse({
    required this.path,
    required this.count,
    required this.averageDurationMs,
  });

  factory UApiLogEndpointResponse.fromMap(Map<String, dynamic> json) => UApiLogEndpointResponse(
    path: json["path"] ?? "",
    count: json["count"] ?? 0,
    averageDurationMs: (json["averageDurationMs"] as num?)?.toDouble() ?? 0,
  );

  final String path;
  final int count;
  final double averageDurationMs;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "path": path,
    "count": count,
    "averageDurationMs": averageDurationMs,
  };

  String toJson() => json.encode(toMap());

  factory UApiLogEndpointResponse.fromJson(String str) => UApiLogEndpointResponse.fromMap(json.decode(str));
}

class UApiLogStatsResponse {
  UApiLogStatsResponse({
    required this.totalCount,
    required this.successCount,
    required this.errorCount,
    required this.averageDurationMs,
    required this.p50DurationMs,
    required this.p95DurationMs,
    required this.p99DurationMs,
    required this.timeline,
    required this.slowestEndpoints,
    required this.failingEndpoints,
    required this.slowestRequests,
  });

  factory UApiLogStatsResponse.fromMap(Map<String, dynamic> json) => UApiLogStatsResponse(
    totalCount: json["totalCount"] ?? 0,
    successCount: json["successCount"] ?? 0,
    errorCount: json["errorCount"] ?? 0,
    averageDurationMs: (json["averageDurationMs"] as num?)?.toDouble() ?? 0,
    p50DurationMs: (json["p50DurationMs"] as num?)?.toDouble() ?? 0,
    p95DurationMs: (json["p95DurationMs"] as num?)?.toDouble() ?? 0,
    p99DurationMs: (json["p99DurationMs"] as num?)?.toDouble() ?? 0,
    timeline: List<UApiLogBucketResponse>.from((json["timeline"] ?? <dynamic>[]).map((dynamic x) => UApiLogBucketResponse.fromMap(x))),
    slowestEndpoints: List<UApiLogEndpointResponse>.from((json["slowestEndpoints"] ?? <dynamic>[]).map((dynamic x) => UApiLogEndpointResponse.fromMap(x))),
    failingEndpoints: List<UApiLogEndpointResponse>.from((json["failingEndpoints"] ?? <dynamic>[]).map((dynamic x) => UApiLogEndpointResponse.fromMap(x))),
    slowestRequests: List<UApiLogResponse>.from((json["slowestRequests"] ?? <dynamic>[]).map((dynamic x) => UApiLogResponse.fromMap(x))),
  );

  final int totalCount;
  final int successCount;
  final int errorCount;
  final double averageDurationMs;
  final double p50DurationMs;
  final double p95DurationMs;
  final double p99DurationMs;
  final List<UApiLogBucketResponse> timeline;
  final List<UApiLogEndpointResponse> slowestEndpoints;
  final List<UApiLogEndpointResponse> failingEndpoints;
  final List<UApiLogResponse> slowestRequests;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "totalCount": totalCount,
    "successCount": successCount,
    "errorCount": errorCount,
    "averageDurationMs": averageDurationMs,
    "p50DurationMs": p50DurationMs,
    "p95DurationMs": p95DurationMs,
    "p99DurationMs": p99DurationMs,
    "timeline": List<dynamic>.from(timeline.map((UApiLogBucketResponse x) => x.toMap())),
    "slowestEndpoints": List<dynamic>.from(slowestEndpoints.map((UApiLogEndpointResponse x) => x.toMap())),
    "failingEndpoints": List<dynamic>.from(failingEndpoints.map((UApiLogEndpointResponse x) => x.toMap())),
    "slowestRequests": List<dynamic>.from(slowestRequests.map((UApiLogResponse x) => x.toMap())),
  };

  String toJson() => json.encode(toMap());

  factory UApiLogStatsResponse.fromJson(String str) => UApiLogStatsResponse.fromMap(json.decode(str));
}
