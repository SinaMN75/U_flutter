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

  UTerminalUpdateParams({
    required this.id,
    this.serial,
    this.simCardNumber,
    this.simCardSerial,
    this.imei,
    this.terminalId,
    this.insId,
    this.merchantId,
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
    tags: json["tags"] == null
        ? <int>[]
        : List<int>.from(
            json["tags"]!.map((dynamic x) => x)
          ),
    ids: json["ids"] == null
        ? <String>[]
        : List<String>.from(
            json["ids"]!.map((dynamic x) => x)
          ),
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

  UTerminalBrandUpdateParams({
    required this.id,
    this.title,
    this.model,
  });

  factory UTerminalBrandUpdateParams.fromJson(String str) => UTerminalBrandUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrandUpdateParams.fromMap(Map<String, dynamic> json) => UTerminalBrandUpdateParams(
    id: json["id"],
    title: json["title"],
    model: json["model"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "model": model,
  };
}

class UTerminalBrokerCreateParams {
  final List<int> tags;
  final String? id;
  final String title;
  final String? sign1Base64;
  final String? sign1Owner;
  final String? sign2Base64;
  final String? sign2Owner;

  UTerminalBrokerCreateParams({
    required this.tags,
    required this.title,
    this.id,
    this.sign1Base64,
    this.sign1Owner,
    this.sign2Base64,
    this.sign2Owner,
  });

  factory UTerminalBrokerCreateParams.fromJson(String str) => UTerminalBrokerCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrokerCreateParams.fromMap(Map<String, dynamic> json) => UTerminalBrokerCreateParams(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    title: json["title"],
    sign1Base64: json["sign1Base64"],
    sign1Owner: json["sign1Owner"],
    sign2Base64: json["sign2Base64"],
    sign2Owner: json["sign2Owner"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "title": title,
    "sign1Base64": sign1Base64,
    "sign1Owner": sign1Owner,
    "sign2Base64": sign2Base64,
    "sign2Owner": sign2Owner,
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
  final String id;
  final String? title;
  final String? sign1Base64;
  final String? sign1Owner;
  final String? sign2Base64;
  final String? sign2Owner;

  UTerminalBrokerUpdateParams({
    required this.id,
    this.title,
    this.sign1Base64,
    this.sign1Owner,
    this.sign2Base64,
    this.sign2Owner,
  });

  factory UTerminalBrokerUpdateParams.fromJson(String str) => UTerminalBrokerUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTerminalBrokerUpdateParams.fromMap(Map<String, dynamic> json) => UTerminalBrokerUpdateParams(
    id: json["id"],
    title: json["title"],
    sign1Base64: json["sign1Base64"],
    sign1Owner: json["sign1Owner"],
    sign2Base64: json["sign2Base64"],
    sign2Owner: json["sign2Owner"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "sign1Base64": sign1Base64,
    "sign1Owner": sign1Owner,
    "sign2Base64": sign2Base64,
    "sign2Owner": sign2Owner,
  };
}
