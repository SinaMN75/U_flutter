part of "../data.dart";

class UAccountingReportParams {
  final String? userId;
  final DateTime? fromDate;
  final DateTime? toDate;

  UAccountingReportParams({
    this.userId,
    this.fromDate,
    this.toDate,
  });

  factory UAccountingReportParams.fromJson(String str) => UAccountingReportParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UAccountingReportParams.fromMap(Map<String, dynamic> json) => UAccountingReportParams(
    userId: json["userId"],
    fromDate: json["fromDate"] == null ? null : DateTime.parse(json["fromDate"]),
    toDate: json["toDate"] == null ? null : DateTime.parse(json["toDate"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}

class UOrganizationSettlementRequestParams {
  UOrganizationSettlementRequestParams({required this.organizationId, required this.amount, required this.iban});

  final String organizationId;
  final double amount;
  final String iban;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "amount": amount,
    "iban": iban,
  };
}

class UOrganizationSettlementProcessParams {
  UOrganizationSettlementProcessParams({required this.organizationId, required this.settlementId, required this.approve, this.note});

  final String organizationId;
  final String settlementId;
  final bool approve;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "settlementId": settlementId,
    "approve": approve,
    "note": note,
  };
}

class UAccountCreateParams {
  UAccountCreateParams({required this.organizationId, required this.code, required this.title, required this.tags, this.detail1});

  final String organizationId;
  final String code;
  final String title;
  final List<int> tags;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "code": code,
    "title": title,
    "tags": tags,
    "detail1": detail1 ?? "",
  };
}

class UAccountUpdateParams {
  UAccountUpdateParams({required this.id, this.code, this.title, this.addTags, this.removeTags, this.detail1});

  final String id;
  final String? code;
  final String? title;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "code": code,
    "title": title,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
  };
}

class UAccountReadParams {
  UAccountReadParams({required this.organizationId, this.fromDate, this.toDate, this.placeId, this.tags, this.pageSize = 500});

  final String organizationId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? placeId;
  final List<int>? tags;
  final int pageSize;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
    "placeId": placeId,
    "tags": tags,
    "pageSize": pageSize,
  };
}

class UVoucherLineParams {
  UVoucherLineParams({required this.accountId, this.debit = 0, this.credit = 0, this.personId, this.description});

  final String accountId;
  final double debit;
  final double credit;
  final String? personId;
  final String? description;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "accountId": accountId,
    "debit": debit,
    "credit": credit,
    "personId": personId,
    "description": description,
  };
}

class UVoucherCreateParams {
  UVoucherCreateParams({required this.organizationId, required this.tags, required this.lines, this.date, this.placeId, this.detail1});

  final String organizationId;
  final List<int> tags;
  final List<UVoucherLineParams> lines;
  final DateTime? date;
  final String? placeId;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "tags": tags,
    "lines": lines.map((UVoucherLineParams x) => x.toMap()).toList(),
    "date": date?.toIso8601String(),
    "placeId": placeId,
    "detail1": detail1 ?? "",
  };
}

class UVoucherReadParams {
  UVoucherReadParams({required this.organizationId, this.pageSize, this.pageNumber, this.tags, this.fromDate, this.toDate, this.placeId, this.personId, this.accountId, this.sourceId});

  final String organizationId;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? placeId;
  final String? personId;
  final String? accountId;
  final String? sourceId;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
    "placeId": placeId,
    "personId": personId,
    "accountId": accountId,
    "sourceId": sourceId,
  };
}

class ULedgerReadParams {
  ULedgerReadParams({required this.organizationId, this.accountId, this.accountTags, this.personId, this.placeId, this.fromDate, this.toDate});

  final String organizationId;
  final String? accountId;
  final List<int>? accountTags;
  final String? personId;
  final String? placeId;
  final DateTime? fromDate;
  final DateTime? toDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "accountId": accountId,
    "accountTags": accountTags,
    "personId": personId,
    "placeId": placeId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}

class ULedgerReportParams {
  ULedgerReportParams({required this.organizationId, this.fromDate, this.toDate});

  final String organizationId;
  final DateTime? fromDate;
  final DateTime? toDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}

class UCheckCreateParams {
  UCheckCreateParams({
    required this.organizationId,
    required this.tags,
    required this.amount,
    required this.dueDate,
    required this.number,
    this.bank,
    this.sayadId,
    this.drawer,
    this.personId,
    this.contractId,
    this.placeId,
    this.accountId,
    this.detail1,
  });

  final String organizationId;
  final List<int> tags;
  final double amount;
  final DateTime dueDate;
  final String number;
  final String? bank;
  final String? sayadId;
  final String? drawer;
  final String? personId;
  final String? contractId;
  final String? placeId;
  final String? accountId;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "tags": tags,
    "amount": amount,
    "dueDate": dueDate.toIso8601String(),
    "number": number,
    "bank": bank,
    "sayadId": sayadId,
    "drawer": drawer,
    "personId": personId,
    "contractId": contractId,
    "placeId": placeId,
    "accountId": accountId,
    "detail1": detail1 ?? "",
  };
}

class UCheckReadParams {
  UCheckReadParams({required this.organizationId, this.pageSize, this.pageNumber, this.tags, this.personId, this.contractId, this.fromDueDate, this.toDueDate});

  final String organizationId;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final String? personId;
  final String? contractId;
  final DateTime? fromDueDate;
  final DateTime? toDueDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "personId": personId,
    "contractId": contractId,
    "fromDueDate": fromDueDate?.toIso8601String(),
    "toDueDate": toDueDate?.toIso8601String(),
  };
}

class UCheckStatusParams {
  UCheckStatusParams({required this.id, required this.status, this.accountId, this.date});

  final String id;
  final int status;
  final String? accountId;
  final DateTime? date;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "status": status,
    "accountId": accountId,
    "date": date?.toIso8601String(),
  };
}

class UInvoiceReceiveCheckParams {
  UInvoiceReceiveCheckParams({required this.number, required this.dueDate, this.bank, this.sayadId, this.drawer});

  final String number;
  final DateTime dueDate;
  final String? bank;
  final String? sayadId;
  final String? drawer;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "number": number,
    "dueDate": dueDate.toIso8601String(),
    "bank": bank,
    "sayadId": sayadId,
    "drawer": drawer,
  };
}

class UInvoiceReceiveParams {
  UInvoiceReceiveParams({required this.id, this.amount, this.accountId, this.check});

  final String id;
  final double? amount;
  final String? accountId;
  final UInvoiceReceiveCheckParams? check;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "amount": amount,
    "accountId": accountId,
    "check": check?.toMap(),
  };
}
