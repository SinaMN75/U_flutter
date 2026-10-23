part of "../data.dart";

class UVehicleCreateParams {
  final String licencePlate;
  final List<int> tags;
  final String? id;
  final String? title;
  final String? brand;
  final String? color;
  final String? detail1;
  final String? detail2;
  final String? creatorId;
  final List<String>? adminUserIds;

  UVehicleCreateParams({
    required this.licencePlate,
    required this.tags,
    this.id,
    this.title,
    this.brand,
    this.color,
    this.detail1,
    this.detail2,
    this.creatorId,
    this.adminUserIds,
  });

  factory UVehicleCreateParams.fromJson(String str) => UVehicleCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UVehicleCreateParams.fromMap(Map<String, dynamic> json) => UVehicleCreateParams(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    licencePlate: json["licencePlate"],
    title: json["title"],
    brand: json["brand"],
    color: json["color"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "licencePlate": licencePlate,
    "title": title,
    "brand": brand,
    "color": color,
    "detail1": detail1,
    "detail2": detail2,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UVehicleReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final UVehicleSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? licencePlate;
  final String? brand;
  final String? color;

  UVehicleReadParams({
    required this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.orderBy,
    this.licencePlate,
    this.brand,
    this.color,
  });

  factory UVehicleReadParams.fromJson(String str) => UVehicleReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UVehicleReadParams.fromMap(Map<String, dynamic> json) => UVehicleReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    selectorArgs: json["selectorArgs"] == null ? null : UVehicleSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    licencePlate: json["licencePlate"],
    brand: json["brand"],
    color: json["color"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "licencePlate": licencePlate,
    "brand": brand,
    "color": color,
  };
}
