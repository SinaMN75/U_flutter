part of "../data.dart";

class USystemMetricsResponse {
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final double totalMemory;
  final double freeMemory;
  final double totalDisk;
  final double freeDisk;
  final DateTime date;

  USystemMetricsResponse({
    required this.date,
    this.cpuUsage = 0,
    this.memoryUsage = 0,
    this.diskUsage = 0,
    this.totalMemory = 0,
    this.freeMemory = 0,
    this.totalDisk = 0,
    this.freeDisk = 0,
  });

  factory USystemMetricsResponse.fromJson(String str) => USystemMetricsResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory USystemMetricsResponse.fromMap(Map<String, dynamic> json) => USystemMetricsResponse(
    cpuUsage: json["cpuUsage"].toString().toDouble(),
    memoryUsage: json["memoryUsage"].toString().toDouble(),
    diskUsage: json["diskUsage"].toString().toDouble(),
    totalMemory: json["totalMemory"].toString().toDouble(),
    freeMemory: json["freeMemory"].toString().toDouble(),
    totalDisk: json["totalDisk"].toString().toDouble(),
    freeDisk: json["freeDisk"].toString().toDouble(),
    date: DateTime.parse(json["date"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "cpuUsage": cpuUsage,
    "memoryUsage": memoryUsage,
    "diskUsage": diskUsage,
    "totalMemory": totalMemory,
    "freeMemory": freeMemory,
    "totalDisk": totalDisk,
    "freeDisk": freeDisk,
    "date": date.toIso8601String(),
  };
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
