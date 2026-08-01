part of "../data.dart";

class UTerminalCreateParams {
  final List<int> tags;
  final String? id;
  final String? simCardNumber;
  final String serial;
  final String? simCardSerial;
  final String? imei;
  final String? terminalId;
  final String? detail1;
  final String? detail2;
  final String? creatorId;
  final List<String>? adminUserIds;
  final String? insId;
  final String? agreement;
  final String? merchantId;

  UTerminalCreateParams({
    required this.tags,
    required this.serial,
    this.id,
    this.simCardNumber,
    this.simCardSerial,
    this.imei,
    this.terminalId,
    this.detail1,
    this.detail2,
    this.creatorId,
    this.adminUserIds,
    this.insId,
    this.agreement,
    this.merchantId,
  });

  factory UTerminalCreateParams.fromJson(String str) => UTerminalCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalCreateParams.fromMap(Map<String, dynamic> json) => UTerminalCreateParams(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    serial: json["serial"] as String,
    simCardNumber: json["simCardNumber"],
    simCardSerial: json["simCardSerial"],
    imei: json["imei"],
    terminalId: json["terminalId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    insId: json["insId"],
    agreement: json["agreement"],
    merchantId: json["merchantId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "serial": serial,
    "simCardNumber": simCardNumber,
    "simCardSerial": simCardSerial,
    "imei": imei,
    "terminalId": terminalId,
    "detail1": detail1,
    "detail2": detail2,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "insId": insId,
    "agreement": agreement,
    "merchantId": merchantId,
  };
}

class UTerminalAssignParams {
  final String serial;
  final String? simCardSerial;
  final String? merchantId;
  final String? title;

  UTerminalAssignParams({
    required this.serial,
    this.simCardSerial,
    this.merchantId,
    this.title,
  });

  factory UTerminalAssignParams.fromJson(String str) => UTerminalAssignParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalAssignParams.fromMap(Map<String, dynamic> json) => UTerminalAssignParams(
    serial: json["serial"] as String,
    simCardSerial: json["simCardSerial"],
    merchantId: json["merchantId"],
    title: json["title"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "serial": serial,
    "simCardSerial": simCardSerial,
    "merchantId": merchantId,
    "title": title,
  };
}

class UTerminalUpdateParams {
  final String id;
  final String? serial;
  final String? simCardNumber;
  final String? simCardSerial;
  final String? imei;
  final String? terminalId;
  final String? insId;
  final String? merchantId;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UTerminalUpdateParams({
    required this.id,
    this.serial,
    this.simCardNumber,
    this.simCardSerial,
    this.imei,
    this.terminalId,
    this.insId,
    this.merchantId,
    this.addTags,
    this.removeTags,
    this.tags,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UTerminalUpdateParams.fromJson(String str) => UTerminalUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalUpdateParams.fromMap(Map<String, dynamic> json) => UTerminalUpdateParams(
    id: json["id"],
    serial: json["serial"],
    simCardNumber: json["simCardNumber"],
    simCardSerial: json["simCardSerial"],
    imei: json["imei"],
    terminalId: json["terminalId"],
    insId: json["insId"],
    merchantId: json["merchantId"],
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
    "serial": serial,
    "simCardNumber": simCardNumber,
    "simCardSerial": simCardSerial,
    "imei": imei,
    "terminalId": terminalId,
    "insId": insId,
    "merchantId": merchantId,
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

class UTerminalBulkCreateParams {
  final List<UTerminalCreateParams> list;

  UTerminalBulkCreateParams({required this.list});

  factory UTerminalBulkCreateParams.fromJson(String str) => UTerminalBulkCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBulkCreateParams.fromMap(Map<String, dynamic> json) => UTerminalBulkCreateParams(
    list: List<UTerminalCreateParams>.from(json["list"].map((dynamic x) => UTerminalCreateParams.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "list": List<dynamic>.from(list.map((UTerminalCreateParams x) => x.toMap())),
  };
}

class UTerminalReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? serial;
  final String? merchantId;
  final TerminalSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? simCardNumber;
  final String? simCardSerial;
  final String? imei;
  final String? terminalId;
  final String? insId;

  UTerminalReadParams({
    required this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.serial,
    this.merchantId,
    this.orderBy,
    this.simCardNumber,
    this.simCardSerial,
    this.imei,
    this.terminalId,
    this.insId,
  });

  factory UTerminalReadParams.fromJson(String str) => UTerminalReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalReadParams.fromMap(Map<String, dynamic> json) => UTerminalReadParams(
    pageSize: json["pageSize"],
    serial: json["serial"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    merchantId: json["merchantId"],
    selectorArgs: json["selectorArgs"] == null ? null : TerminalSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    simCardNumber: json["simCardNumber"],
    simCardSerial: json["simCardSerial"],
    imei: json["imei"],
    terminalId: json["terminalId"],
    insId: json["insId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "serial": serial,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "merchantId": merchantId,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "simCardNumber": simCardNumber,
    "simCardSerial": simCardSerial,
    "imei": imei,
    "terminalId": terminalId,
    "insId": insId,
  };
}

class UTerminalImportParams {
  UTerminalImportParams({
    required this.file,
  });

  final String file;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "file": file,
  };

  factory UTerminalImportParams.fromMap(Map<String, dynamic> json) => UTerminalImportParams(
    file: json["file"],
  );

  factory UTerminalImportParams.fromJson(String str) => UTerminalImportParams.fromMap(json.decode(str));
}
