part of "../data.dart";

class UMetricsResponse {
  UMetricsResponse({
    this.cpuUsage = 0,
    this.memoryUsage = 0,
    this.diskUsage = 0,
    this.totalMemory = 0,
    this.freeMemory = 0,
    this.totalDisk = 0,
    this.freeDisk = 0,
    this.date = "",
  });

  factory UMetricsResponse.fromJson(String str) => UMetricsResponse.fromMap(json.decode(str));

  factory UMetricsResponse.fromMap(Map<String, dynamic> json) => UMetricsResponse(
    cpuUsage: json["cpuUsage"].toString().toDouble(),
    memoryUsage: json["memoryUsage"].toString().toDouble(),
    diskUsage: json["diskUsage"].toString().toDouble(),
    totalMemory: json["totalMemory"].toString().toDouble(),
    freeMemory: json["freeMemory"].toString().toDouble(),
    totalDisk: json["totalDisk"].toString().toDouble(),
    freeDisk: json["freeDisk"].toString().toDouble(),
    date: json["date"],
  );
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double totalMemory;
  final double freeMemory;
  final double totalDisk;
  final double freeDisk;
  final String date;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "cpuUsage": cpuUsage,
    "memoryUsage": memoryUsage,
    "diskUsage": diskUsage,
    "totalMemory": totalMemory,
    "freeMemory": freeMemory,
    "totalDisk": totalDisk,
    "freeDisk": freeDisk,
    "date": date,
  };

  String toJson() => json.encode(toMap());
}

class UDashboardResponse {
  final List<UCommentResponse> newComments;
  final List<UContentResponse> newContents;
  final List<UProductResponse> newProducts;
  UDashboardResponse({
    required this.categories,
    required this.comments,
    required this.contents,
    required this.media,
    required this.products,
    required this.users,
    required this.newUsers,
    required this.newCategories,
    required this.newMedia,
    required this.newComments,
    required this.newContents,
    required this.newProducts,
  });

  factory UDashboardResponse.fromJson(String str) => UDashboardResponse.fromMap(json.decode(str));

  factory UDashboardResponse.fromMap(Map<String, dynamic> json) => UDashboardResponse(
    categories: json["categories"],
    comments: json["comments"],
    contents: json["contents"],
    media: json["media"],
    products: json["products"],
    users: json["users"],
    newUsers: List<UUserResponse>.from(json["newUsers"].map((dynamic x) => UUserResponse.fromMap(x))),
    newCategories: List<UCategoryResponse>.from(json["newCategories"].map((dynamic x) => UCategoryResponse.fromMap(x))),
    newMedia: List<UMediaResponse>.from(json["newMedia"].map((dynamic x) => UMediaResponse.fromMap(x))),
    newComments: json["newComments"] == null ? <UCommentResponse>[] : List<UCommentResponse>.from(json["newComments"]!.map((dynamic x) => UCommentResponse.fromMap(x))),
    newContents: json["newContents"] == null ? <UContentResponse>[] : List<UContentResponse>.from(json["newContents"]!.map((dynamic x) => UContentResponse.fromMap(x))),
    newProducts: json["newProducts"] == null ? <UProductResponse>[] : List<UProductResponse>.from(json["newProducts"]!.map((dynamic x) => UProductResponse.fromMap(x))),
  );
  final int categories;
  final int comments;
  final int contents;
  final int media;
  final int products;
  final int users;
  final List<UUserResponse> newUsers;
  final List<UCategoryResponse> newCategories;
  final List<UMediaResponse> newMedia;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "categories": categories,
    "comments": comments,
    "contents": contents,
    "media": media,
    "products": products,
    "users": users,
    "newUsers": List<dynamic>.from(newUsers.map((UUserResponse x) => x.toMap())),
    "newCategories": List<dynamic>.from(newCategories.map((UCategoryResponse x) => x.toMap())),
    "newMedia": List<dynamic>.from(newMedia.map((UMediaResponse x) => x.toMap())),
    "newComments": List<dynamic>.from(newComments.map((UCommentResponse x) => x.toMap())),
    "newContents": List<dynamic>.from(newContents.map((UContentResponse x) => x.toMap())),
    "newProducts": List<dynamic>.from(newProducts.map((UProductResponse x) => x.toMap())),
  };
}

class LogStructureResponse {
  LogStructureResponse({
    required this.logs,
  });

  factory LogStructureResponse.fromJson(String str) => LogStructureResponse.fromMap(json.decode(str));

  factory LogStructureResponse.fromMap(Map<String, dynamic> json) => LogStructureResponse(
    logs: List<YearLog>.from(json["logs"].map((dynamic x) => YearLog.fromMap(x))),
  );
  final List<YearLog> logs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "logs": List<dynamic>.from(logs.map((YearLog x) => x.toMap())),
  };
}

class YearLog {
  YearLog({
    required this.year,
    required this.months,
  });

  factory YearLog.fromJson(String str) => YearLog.fromMap(json.decode(str));

  factory YearLog.fromMap(Map<String, dynamic> json) => YearLog(
    year: json["year"],
    months: List<MonthLog>.from(json["months"].map((dynamic x) => MonthLog.fromMap(x))),
  );
  final int year;
  final List<MonthLog> months;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "year": year,
    "months": List<dynamic>.from(months.map((MonthLog x) => x.toMap())),
  };
}

class MonthLog {
  MonthLog({
    required this.month,
    required this.days,
  });

  factory MonthLog.fromJson(String str) => MonthLog.fromMap(json.decode(str));

  factory MonthLog.fromMap(Map<String, dynamic> json) => MonthLog(
    month: json["month"],
    days: List<DayLog>.from(json["days"].map((dynamic x) => DayLog.fromMap(x))),
  );
  final int month;
  final List<DayLog> days;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "month": month,
    "days": List<dynamic>.from(days.map((DayLog x) => x.toMap())),
  };
}

class DayLog {
  DayLog({
    required this.day,
    this.success,
    this.failed,
  });

  factory DayLog.fromJson(String str) => DayLog.fromMap(json.decode(str));

  factory DayLog.fromMap(Map<String, dynamic> json) => DayLog(
    day: json["day"],
    success: json["success"],
    failed: json["failed"],
  );
  final int day;
  final String? success;
  final String? failed;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "day": day,
    "success": success,
    "failed": failed,
  };
}
