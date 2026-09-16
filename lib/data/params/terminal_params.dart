part of "../data.dart";

class UTerminalCreateParams {
  final List<int> tags;
  final String? id;
  final String? simCardNumber;
  final String serial;
  final String? simCardSerial;
  final String? imei;
  final String? terminalId;
  final String? insId;
  final String? merchantId;
  final String terminalBrandId;
  final String terminalBrokerId;

  UTerminalCreateParams({
    required this.tags,
    required this.serial,
    required this.terminalBrandId,
    required this.terminalBrokerId,
    this.id,
    this.simCardNumber,
    this.simCardSerial,
    this.imei,
    this.terminalId,
    this.insId,
    this.merchantId,
  });

  factory UTerminalCreateParams.fromJson(String str) => UTerminalCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalCreateParams.fromMap(Map<String, dynamic> json) => UTerminalCreateParams(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    simCardNumber: json["simCardNumber"],
    serial: json["serial"] as String,
    simCardSerial: json["simCardSerial"],
    imei: json["imei"],
    terminalId: json["terminalId"],
    insId: json["insId"],
    merchantId: json["merchantId"],
    terminalBrandId: json["terminalBrandId"] as String,
    terminalBrokerId: json["terminalBrokerId"] as String,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "simCardNumber": simCardNumber,
    "serial": serial,
    "simCardSerial": simCardSerial,
    "imei": imei,
    "terminalId": terminalId,
    "insId": insId,
    "merchantId": merchantId,
    "terminalBrandId": terminalBrandId,
    "terminalBrokerId": terminalBrokerId,
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
  final String? terminalBrandId;
  final String? terminalBrokerId;

  UTerminalUpdateParams({
    required this.id,
    this.serial,
    this.simCardNumber,
    this.simCardSerial,
    this.imei,
    this.terminalId,
    this.insId,
    this.merchantId,
    this.terminalBrandId,
    this.terminalBrokerId,
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
    terminalBrandId: json["terminalBrandId"],
    terminalBrokerId: json["terminalBrokerId"],
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
    "terminalBrandId": terminalBrandId,
    "terminalBrokerId": terminalBrokerId,
  };
}

class UTerminalCheckAvailabilityParams {
  final String serial;
  final String? simCardSerial;
  final String? merchantId;
  final String? terminalBrandId;
  final String? terminalBrokerId;

  UTerminalCheckAvailabilityParams({
    required this.serial,
    this.simCardSerial,
    this.merchantId,
    this.terminalBrandId,
    this.terminalBrokerId,
  });

  factory UTerminalCheckAvailabilityParams.fromJson(String str) => UTerminalCheckAvailabilityParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalCheckAvailabilityParams.fromMap(
    Map<String, dynamic> json,
  ) => UTerminalCheckAvailabilityParams(
    serial: json["serial"] as String,
    simCardSerial: json["simCardSerial"],
    merchantId: json["merchantId"],
    terminalBrandId: json["terminalBrandId"],
    terminalBrokerId: json["terminalBrokerId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "serial": serial,
    "simCardSerial": simCardSerial,
    "merchantId": merchantId,
    "terminalBrandId": terminalBrandId,
    "terminalBrokerId": terminalBrokerId,
  };
}

class UTerminalAssignParams {
  final String? title;
  final String serial;
  final String? simCardSerial;
  final String? merchantId;
  final bool acceptedAgreement;
  final String? terminalBrandId;
  final String? terminalBrokerId;

  UTerminalAssignParams({
    required this.serial,
    this.title,
    this.simCardSerial,
    this.merchantId,
    this.acceptedAgreement = false,
    this.terminalBrandId,
    this.terminalBrokerId,
  });

  factory UTerminalAssignParams.fromJson(String str) => UTerminalAssignParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalAssignParams.fromMap(Map<String, dynamic> json) => UTerminalAssignParams(
    title: json["title"],
    serial: json["serial"] as String,
    simCardSerial: json["simCardSerial"],
    merchantId: json["merchantId"],
    acceptedAgreement: json["acceptedAgreement"] ?? false,
    terminalBrandId: json["terminalBrandId"],
    terminalBrokerId: json["terminalBrokerId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "serial": serial,
    "simCardSerial": simCardSerial,
    "merchantId": merchantId,
    "acceptedAgreement": acceptedAgreement,
    "terminalBrandId": terminalBrandId,
    "terminalBrokerId": terminalBrokerId,
  };
}

class UTerminalRejectParams {
  final String id;
  final String? reason;

  UTerminalRejectParams({
    required this.id,
    this.reason,
  });

  factory UTerminalRejectParams.fromJson(String str) => UTerminalRejectParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalRejectParams.fromMap(Map<String, dynamic> json) => UTerminalRejectParams(
    id: json["id"],
    reason: json["reason"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "reason": reason,
  };
}

class UTerminalBulkCreateParams {
  final List<UTerminalCreateParams> list;

  UTerminalBulkCreateParams({
    required this.list,
  });

  factory UTerminalBulkCreateParams.fromJson(String str) => UTerminalBulkCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBulkCreateParams.fromMap(Map<String, dynamic> json) => UTerminalBulkCreateParams(
    list: List<UTerminalCreateParams>.from(
      json["list"].map(
        (dynamic x) => UTerminalCreateParams.fromMap(x),
      ),
    ),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "list": List<dynamic>.from(
      list.map((UTerminalCreateParams x) => x.toMap()),
    ),
  };
}

class UTerminalImportParams {
  final String file;

  UTerminalImportParams({
    required this.file,
  });

  factory UTerminalImportParams.fromJson(String str) => UTerminalImportParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalImportParams.fromMap(Map<String, dynamic> json) => UTerminalImportParams(
    file: json["file"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "file": file,
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
  final String? simCardNumber;
  final String? simCardSerial;
  final String? imei;
  final String? terminalId;
  final String? insId;
  final String? merchantId;
  final TerminalSelectorArgs selectorArgs;
  final int? orderBy;

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
    this.simCardNumber,
    this.simCardSerial,
    this.imei,
    this.terminalId,
    this.insId,
    this.merchantId,
    this.orderBy,
  });

  factory UTerminalReadParams.fromJson(String str) => UTerminalReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalReadParams.fromMap(Map<String, dynamic> json) => UTerminalReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null
        ? <int>[]
        : List<int>.from(
            json["tags"]!.map((dynamic x) => x),
          ),
    ids: json["ids"] == null
        ? <String>[]
        : List<String>.from(
            json["ids"]!.map((dynamic x) => x),
          ),
    creatorId: json["creatorId"],
    serial: json["serial"],
    simCardNumber: json["simCardNumber"],
    simCardSerial: json["simCardSerial"],
    imei: json["imei"],
    terminalId: json["terminalId"],
    insId: json["insId"],
    merchantId: json["merchantId"],
    selectorArgs: json["selectorArgs"] == null ? const TerminalSelectorArgs() : TerminalSelectorArgs.fromMap(json["selectorArgs"]),
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
    "serial": serial,
    "simCardNumber": simCardNumber,
    "simCardSerial": simCardSerial,
    "imei": imei,
    "terminalId": terminalId,
    "insId": insId,
    "merchantId": merchantId,
    "selectorArgs": selectorArgs.toMap(),
    "orderBy": orderBy,
  };
}

class UTerminalBrandCreateParams {
  final List<int> tags;
  final String? id;
  final String title;
  final String model;

  UTerminalBrandCreateParams({
    required this.tags,
    required this.title,
    required this.model,
    this.id,
  });

  factory UTerminalBrandCreateParams.fromJson(String str) => UTerminalBrandCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrandCreateParams.fromMap(Map<String, dynamic> json) => UTerminalBrandCreateParams(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    title: json["title"] as String,
    model: json["model"] as String,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "title": title,
    "model": model,
  };
}

class UTerminalBrandReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? title;
  final String? model;
  final TerminalBrandSelectorArgs selectorArgs;
  final int? orderBy;

  UTerminalBrandReadParams({
    required this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.title,
    this.model,
    this.orderBy,
  });

  factory UTerminalBrandReadParams.fromJson(String str) => UTerminalBrandReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrandReadParams.fromMap(Map<String, dynamic> json) => UTerminalBrandReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    model: json["model"],
    selectorArgs: json["selectorArgs"] == null ? const TerminalBrandSelectorArgs() : TerminalBrandSelectorArgs.fromMap(json["selectorArgs"]),
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
    "title": title,
    "model": model,
    "selectorArgs": selectorArgs.toMap(),
    "orderBy": orderBy,
  };
}

class UTerminalBrandUpdateParams {
  final String id;
  final String? title;
  final String? model;
  final List<int>? tags;

  UTerminalBrandUpdateParams({
    required this.id,
    this.title,
    this.model,
    this.tags,
  });

  factory UTerminalBrandUpdateParams.fromJson(String str) => UTerminalBrandUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrandUpdateParams.fromMap(Map<String, dynamic> json) => UTerminalBrandUpdateParams(
    id: json["id"],
    title: json["title"],
    model: json["model"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "model": model,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
  };
}

class UTerminalBrokerCreateParams {
  final String title;
  final String registrationNumber;
  final String nationalCode;
  final String representative;
  final String address;
  final String postalCode;
  final String phoneNumber;
  final String sign1Base64;
  final String sign1Owner;
  final String? sign2Base64;
  final String? sign2Owner;
  final String logoBase64;
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;


  UTerminalBrokerCreateParams({
    required this.title,
    required this.registrationNumber,
    required this.nationalCode,
    required this.representative,
    required this.address,
    required this.postalCode,
    required this.phoneNumber,
    required this.sign1Base64,
    required this.sign1Owner,
    required this.logoBase64,
    required this.tags,
    this.id,
    this.creatorId,
    this.adminUserIds,
    this.sign2Base64,
    this.sign2Owner,
    this.detail1,
    this.detail2,
  });

  factory UTerminalBrokerCreateParams.fromJson(String str) => UTerminalBrokerCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrokerCreateParams.fromMap(Map<String, dynamic> json) => UTerminalBrokerCreateParams(
    title: json["title"],
    registrationNumber: json["registrationNumber"],
    nationalCode: json["nationalCode"],
    representative: json["representative"],
    address: json["address"],
    postalCode: json["postalCode"],
    phoneNumber: json["phoneNumber"],
    sign1Base64: json["sign1Base64"],
    sign1Owner: json["sign1Owner"],
    sign2Base64: json["sign2Base64"],
    sign2Owner: json["sign2Owner"],
    logoBase64: json["logoBase64"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "registrationNumber": registrationNumber,
    "nationalCode": nationalCode,
    "representative": representative,
    "address": address,
    "postalCode": postalCode,
    "phoneNumber": phoneNumber,
    "sign1Base64": sign1Base64,
    "sign1Owner": sign1Owner,
    "sign2Base64": sign2Base64,
    "sign2Owner": sign2Owner,
    "logoBase64": logoBase64,
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UTerminalBrokerReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? title;
  final TerminalBrokerSelectorArgs selectorArgs;
  final int? orderBy;

  UTerminalBrokerReadParams({
    required this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.title,
    this.orderBy,
  });

  factory UTerminalBrokerReadParams.fromJson(String str) => UTerminalBrokerReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrokerReadParams.fromMap(Map<String, dynamic> json) => UTerminalBrokerReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    selectorArgs: json["selectorArgs"] == null ? const TerminalBrokerSelectorArgs() : TerminalBrokerSelectorArgs.fromMap(json["selectorArgs"]),
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
    "title": title,
    "selectorArgs": selectorArgs.toMap(),
    "orderBy": orderBy,
  };
}

class UTerminalBrokerUpdateParams {
  final String? title;
  final String? registrationNumber;
  final String? nationalCode;
  final String? representative;
  final String? address;
  final String? postalCode;
  final String? phoneNumber;
  final String? sign1Base64;
  final String? sign1Owner;
  final String? sign2Base64;
  final String? sign2Owner;
  final String? logoBase64;
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UTerminalBrokerUpdateParams({
    required this.id,
    this.title,
    this.registrationNumber,
    this.nationalCode,
    this.representative,
    this.address,
    this.postalCode,
    this.phoneNumber,
    this.sign1Base64,
    this.sign1Owner,
    this.sign2Base64,
    this.sign2Owner,
    this.logoBase64,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UTerminalBrokerUpdateParams.fromJson(String str) => UTerminalBrokerUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrokerUpdateParams.fromMap(Map<String, dynamic> json) => UTerminalBrokerUpdateParams(
    title: json["title"],
    registrationNumber: json["registrationNumber"],
    nationalCode: json["nationalCode"],
    representative: json["representative"],
    address: json["address"],
    postalCode: json["postalCode"],
    phoneNumber: json["phoneNumber"],
    sign1Base64: json["sign1Base64"],
    sign1Owner: json["sign1Owner"],
    sign2Base64: json["sign2Base64"],
    sign2Owner: json["sign2Owner"],
    logoBase64: json["logoBase64"],
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "registrationNumber": registrationNumber,
    "nationalCode": nationalCode,
    "representative": representative,
    "address": address,
    "postalCode": postalCode,
    "phoneNumber": phoneNumber,
    "sign1Base64": sign1Base64,
    "sign1Owner": sign1Owner,
    "sign2Base64": sign2Base64,
    "sign2Owner": sign2Owner,
    "logoBase64": logoBase64,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}