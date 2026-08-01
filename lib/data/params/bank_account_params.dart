part of "../data.dart";

class UBankAccountCreateParams {
  final String? cardNumber;
  final List<int> tags;
  final String? id;
  final String? accountNumber;
  final String? iBanNumber;
  final String? bankName;
  final String? ownerName;
  final String? detail1;
  final String? detail2;
  final String? creatorId;
  final List<String>? adminUserIds;

  UBankAccountCreateParams({
    required this.tags,
    this.cardNumber,
    this.id,
    this.accountNumber,
    this.bankName,
    this.ownerName,
    this.iBanNumber,
    this.detail1,
    this.detail2,
    this.creatorId,
    this.adminUserIds,
  });

  factory UBankAccountCreateParams.fromJson(String str) => UBankAccountCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBankAccountCreateParams.fromMap(Map<String, dynamic> json) => UBankAccountCreateParams(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    cardNumber: json["cardNumber"],
    accountNumber: json["accountNumber"],
    iBanNumber: json["iBanNumber"],
    bankName: json["bankName"],
    ownerName: json["ownerName"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "cardNumber": cardNumber,
    "accountNumber": accountNumber,
    "iBanNumber": iBanNumber,
    "bankName": bankName,
    "ownerName": ownerName,
    "detail1": detail1,
    "detail2": detail2,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UBankAccountUpdateParams {
  final String id;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? cardNumber;
  final String? accountNumber;
  final String? iBanNumber;
  final String? bankName;
  final String? ownerName;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UBankAccountUpdateParams({
    required this.id,
    this.addTags,
    this.removeTags,
    this.tags,
    this.cardNumber,
    this.accountNumber,
    this.iBanNumber,
    this.bankName,
    this.ownerName,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UBankAccountUpdateParams.fromJson(String str) => UBankAccountUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBankAccountUpdateParams.fromMap(Map<String, dynamic> json) => UBankAccountUpdateParams(
    id: json["id"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    cardNumber: json["cardNumber"],
    accountNumber: json["accountNumber"],
    iBanNumber: json["iBanNumber"],
    bankName: json["bankName"],
    ownerName: json["ownerName"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "cardNumber": cardNumber,
    "accountNumber": accountNumber,
    "iBanNumber": iBanNumber,
    "bankName": bankName,
    "ownerName": ownerName,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UBankAccountReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? cardNumber;
  final String? accountNumber;
  final String? iBanNumber;
  final String? bankName;
  final String? ownerName;
  final BankAccountSelectorArgs? selectorArgs;
  final int? orderBy;

  UBankAccountReadParams({
    required this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.cardNumber,
    this.accountNumber,
    this.iBanNumber,
    this.bankName,
    this.ownerName,
    this.orderBy,
  });

  factory UBankAccountReadParams.fromJson(String str) => UBankAccountReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBankAccountReadParams.fromMap(Map<String, dynamic> json) => UBankAccountReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    cardNumber: json["cardNumber"],
    accountNumber: json["accountNumber"],
    iBanNumber: json["iBanNumber"],
    bankName: json["bankName"],
    ownerName: json["ownerName"],
    selectorArgs: json["selectorArgs"] == null ? null : BankAccountSelectorArgs.fromMap(json["selectorArgs"]),
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
    "cardNumber": cardNumber,
    "accountNumber": accountNumber,
    "iBanNumber": iBanNumber,
    "bankName": bankName,
    "ownerName": ownerName,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
  };
}
