part of "../data.dart";

class UTxnCreateParams {
  final double amount;
  final String trackingNumber;
  final List<int> tags;
  final String? id;
  final String? detail1;
  final String? detail2;
  final String? creatorId;
  final List<String>? adminUserIds;

  UTxnCreateParams({
    required this.amount,
    required this.trackingNumber,
    required this.tags,
    this.id,
    this.detail1,
    this.detail2,
    this.creatorId,
    this.adminUserIds,
  });

  factory UTxnCreateParams.fromJson(String str) => UTxnCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTxnCreateParams.fromMap(Map<String, dynamic> json) => UTxnCreateParams(
    amount: json["amount"].toDouble(),
    trackingNumber: json["trackingNumber"],
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "amount": amount,
    "trackingNumber": trackingNumber,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UTxnUpdateParams {
  final String id;
  final double? amount;
  final String? trackingNumber;
  final DateTime? paidAt;
  final String? gatewayName;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UTxnUpdateParams({
    required this.id,
    this.amount,
    this.trackingNumber,
    this.paidAt,
    this.gatewayName,
    this.addTags,
    this.removeTags,
    this.tags,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UTxnUpdateParams.fromJson(String str) => UTxnUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTxnUpdateParams.fromMap(Map<String, dynamic> json) => UTxnUpdateParams(
    id: json["id"],
    amount: json["amount"]?.toDouble(),
    trackingNumber: json["trackingNumber"],
    paidAt: json["paidAt"] == null ? null : DateTime.parse(json["paidAt"]),
    gatewayName: json["gatewayName"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "amount": amount,
    "trackingNumber": trackingNumber,
    "paidAt": paidAt?.toIso8601String(),
    "gatewayName": gatewayName,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UTxnReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final TxnSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? creatorId;

  UTxnReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.selectorArgs,
    this.orderBy,
    this.creatorId,
  });

  factory UTxnReadParams.fromJson(String str) => UTxnReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTxnReadParams.fromMap(Map<String, dynamic> json) => UTxnReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    selectorArgs: json["selectorArgs"] == null ? null : TxnSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    creatorId: json["creatorId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "creatorId": creatorId,
  };
}
