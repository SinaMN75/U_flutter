part of "../data.dart";

class UWalletChargeParams {
  final String userId;
  final String? walletId;
  final double amount;

  UWalletChargeParams({
    required this.userId,
    required this.amount,
    this.walletId,
  });

  factory UWalletChargeParams.fromJson(String str) => UWalletChargeParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletChargeParams.fromMap(Map<String, dynamic> json) => UWalletChargeParams(
    userId: json["userId"],
    walletId: json["walletId"],
    amount: json["amount"].toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "walletId": walletId,
    "amount": amount,
  };
}

class UWalletReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final int? orderBy;

  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? userId;
  final double? minBalance;
  final double? maxBalance;
  final bool? system;
  final String? query;
  final UWalletSelectorArgs? selectorArgs;

  UWalletReadParams({
    this.creatorId,
    this.userId,
    this.minBalance,
    this.maxBalance,
    this.system,
    this.query,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.selectorArgs,
    this.orderBy,
  });

  factory UWalletReadParams.fromJson(String str) => UWalletReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletReadParams.fromMap(Map<String, dynamic> json) => UWalletReadParams(
    creatorId: json["creatorId"],
    userId: json["userId"],
    minBalance: json["minBalance"]?.toDouble(),
    maxBalance: json["maxBalance"]?.toDouble(),
    system: json["system"],
    query: json["query"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    selectorArgs: json["selectorArgs"] == null ? null : UWalletSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "userId": userId,
    "minBalance": minBalance,
    "maxBalance": maxBalance,
    "system": system,
    "query": query,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
  };
}

class UWalletTxnReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? userId;
  final String? senderId;
  final String? receiverId;
  final double? minAmount;
  final double? maxAmount;
  final String? query;
  final UWalletTxnSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? creatorId;

  UWalletTxnReadParams({
    this.userId,
    this.senderId,
    this.receiverId,
    this.minAmount,
    this.maxAmount,
    this.query,
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

  factory UWalletTxnReadParams.fromJson(String str) => UWalletTxnReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletTxnReadParams.fromMap(Map<String, dynamic> json) => UWalletTxnReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    userId: json["userId"],
    senderId: json["senderId"],
    receiverId: json["receiverId"],
    minAmount: json["minAmount"]?.toDouble(),
    maxAmount: json["maxAmount"]?.toDouble(),
    query: json["query"],
    selectorArgs: json["selectorArgs"] == null ? null : UWalletTxnSelectorArgs.fromMap(json["selectorArgs"]),
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
    "userId": userId,
    "senderId": senderId,
    "receiverId": receiverId,
    "minAmount": minAmount,
    "maxAmount": maxAmount,
    "query": query,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "creatorId": creatorId,
  };
}

class UWalletTransferParams {
  final String receiverId;
  final double amount;
  final String? senderId;
  final String? detail1;
  final List<int> tagWalletTxn;
  final List<UKeyValueData>? keyValues;

  UWalletTransferParams({
    required this.receiverId,
    required this.amount,
    required this.tagWalletTxn,
    this.senderId,
    this.detail1,
    this.keyValues,
  });

  factory UWalletTransferParams.fromJson(String str) => UWalletTransferParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletTransferParams.fromMap(Map<String, dynamic> json) => UWalletTransferParams(
    receiverId: json["receiverId"],
    amount: json["amount"].toDouble(),
    tagWalletTxn: List<int>.from(json["tagWalletTxn"]!.map((dynamic x) => x)),
    senderId: json["senderId"],
    detail1: json["detail1"],
    keyValues: json["keyValues"] == null ? null : List<UKeyValueData>.from(json["keyValues"]!.map((dynamic x) => UKeyValueData.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "receiverId": receiverId,
    "amount": amount,
    "tagWalletTxn": List<dynamic>.from(tagWalletTxn.map((int x) => x)),
    "senderId": senderId,
    "detail1": detail1,
    if (keyValues != null) "keyValues": List<dynamic>.from(keyValues!.map((UKeyValueData x) => x.toMap())),
  };
}

class UWalletReportParams {
  final DateTime? fromDate;
  final DateTime? toDate;

  UWalletReportParams({this.fromDate, this.toDate});

  factory UWalletReportParams.fromJson(String str) => UWalletReportParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletReportParams.fromMap(Map<String, dynamic> json) => UWalletReportParams(
    fromDate: json["fromDate"] == null ? null : DateTime.parse(json["fromDate"]),
    toDate: json["toDate"] == null ? null : DateTime.parse(json["toDate"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}
