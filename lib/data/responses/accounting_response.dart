part of "../data.dart";

class UAccountingReportResponse {
  final double totalIn;
  final double totalOut;
  final double net;
  final double totalWalletBalance;
  final int walletTxnCount;
  final int txnCount;
  final List<UAccountingBreakdownItem> incomeByType;
  final List<UAccountingBreakdownItem> spendingByType;
  final List<UAccountingBreakdownItem> gatewayByType;
  final List<UAccountingTimelineItem> timeline;

  UAccountingReportResponse({
    required this.totalIn,
    required this.totalOut,
    required this.net,
    required this.totalWalletBalance,
    required this.walletTxnCount,
    required this.txnCount,
    required this.incomeByType,
    required this.spendingByType,
    required this.gatewayByType,
    required this.timeline,
  });

  factory UAccountingReportResponse.fromJson(String str) => UAccountingReportResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UAccountingReportResponse.fromMap(Map<String, dynamic> json) => UAccountingReportResponse(
    totalIn: (json["totalIn"] ?? 0).toString().toDouble(),
    totalOut: (json["totalOut"] ?? 0).toString().toDouble(),
    net: (json["net"] ?? 0).toString().toDouble(),
    totalWalletBalance: (json["totalWalletBalance"] ?? 0).toString().toDouble(),
    walletTxnCount: json["walletTxnCount"] ?? 0,
    txnCount: json["txnCount"] ?? 0,
    incomeByType: ((json["incomeByType"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UAccountingBreakdownItem.fromMap(x)).toList(),
    spendingByType: ((json["spendingByType"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UAccountingBreakdownItem.fromMap(x)).toList(),
    gatewayByType: ((json["gatewayByType"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UAccountingBreakdownItem.fromMap(x)).toList(),
    timeline: ((json["timeline"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UAccountingTimelineItem.fromMap(x)).toList(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "totalIn": totalIn,
    "totalOut": totalOut,
    "net": net,
    "totalWalletBalance": totalWalletBalance,
    "walletTxnCount": walletTxnCount,
    "txnCount": txnCount,
    "incomeByType": incomeByType.map((UAccountingBreakdownItem x) => x.toMap()).toList(),
    "spendingByType": spendingByType.map((UAccountingBreakdownItem x) => x.toMap()).toList(),
    "gatewayByType": gatewayByType.map((UAccountingBreakdownItem x) => x.toMap()).toList(),
    "timeline": timeline.map((UAccountingTimelineItem x) => x.toMap()).toList(),
  };
}

class UAccountingBreakdownItem {
  final int tag;
  final String tagName;
  final double amount;
  final int count;

  UAccountingBreakdownItem({
    required this.tag,
    required this.tagName,
    required this.amount,
    required this.count,
  });

  factory UAccountingBreakdownItem.fromMap(Map<String, dynamic> json) => UAccountingBreakdownItem(
    tag: json["tag"] ?? 0,
    tagName: json["tagName"] ?? "",
    amount: (json["amount"] ?? 0).toString().toDouble(),
    count: json["count"] ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tag": tag,
    "tagName": tagName,
    "amount": amount,
    "count": count,
  };

  String toJson() => json.encode(toMap());

  factory UAccountingBreakdownItem.fromJson(String str) => UAccountingBreakdownItem.fromMap(json.decode(str));
}

class UAccountingTimelineItem {
  final DateTime date;
  final double inAmount;
  final double outAmount;

  UAccountingTimelineItem({
    required this.date,
    required this.inAmount,
    required this.outAmount,
  });

  factory UAccountingTimelineItem.fromMap(Map<String, dynamic> json) => UAccountingTimelineItem(
    date: DateTime.parse(json["date"]),
    inAmount: (json["in"] ?? 0).toString().toDouble(),
    outAmount: (json["out"] ?? 0).toString().toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "date": date.toIso8601String(),
    "in": inAmount,
    "out": outAmount,
  };

  String toJson() => json.encode(toMap());

  factory UAccountingTimelineItem.fromJson(String str) => UAccountingTimelineItem.fromMap(json.decode(str));
}

double _num(dynamic x) => x == null ? 0 : (x as num).toDouble();

class UAccountResponse {
  UAccountResponse({
    required this.id,
    required this.tags,
    required this.code,
    required this.title,
    required this.organizationId,
    this.detail1,
    this.debit = 0,
    this.credit = 0,
    this.balance = 0,
  });

  factory UAccountResponse.fromMap(Map<String, dynamic> json) => UAccountResponse(
    id: json["id"] as String,
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    code: json["code"] as String,
    title: json["title"] as String,
    organizationId: json["organizationId"] as String,
    detail1: json["jsonData"]?["detail1"],
    debit: _num(json["debit"]),
    credit: _num(json["credit"]),
    balance: _num(json["balance"]),
  );

  final String id;
  final List<int> tags;
  final String code;
  final String title;
  final String organizationId;
  final String? detail1;
  final double debit;
  final double credit;
  final double balance;

  bool has(TagAccount t) => tags.contains(t.number);

  bool get isMoneyBox => TagAccount.moneyBoxes.any(has);

  bool get isSystem => tags.any((int x) => x >= 300);

  TagAccount? get kind => TagAccount.kinds.where(has).firstOrNull;
}

class UVoucherLineResponse {
  UVoucherLineResponse({
    required this.id,
    required this.accountId,
    required this.accountCode,
    required this.accountTitle,
    this.personId,
    this.personName,
    this.debit = 0,
    this.credit = 0,
    this.description,
  });

  factory UVoucherLineResponse.fromMap(Map<String, dynamic> json) => UVoucherLineResponse(
    id: json["id"] as String,
    accountId: json["accountId"] as String,
    accountCode: json["accountCode"] ?? "",
    accountTitle: json["accountTitle"] ?? "",
    personId: json["personId"],
    personName: json["personName"],
    debit: _num(json["debit"]),
    credit: _num(json["credit"]),
    description: json["description"],
  );

  final String id;
  final String accountId;
  final String accountCode;
  final String accountTitle;
  final String? personId;
  final String? personName;
  final double debit;
  final double credit;
  final String? description;
}

class UVoucherResponse {
  UVoucherResponse({
    required this.id,
    required this.tags,
    required this.number,
    required this.date,
    required this.organizationId,
    this.placeId,
    this.sourceId,
    this.detail1,
    this.total = 0,
    this.lines = const <UVoucherLineResponse>[],
  });

  factory UVoucherResponse.fromMap(Map<String, dynamic> json) => UVoucherResponse(
    id: json["id"] as String,
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    number: json["number"] as int,
    date: DateTime.parse(json["date"]),
    organizationId: json["organizationId"] as String,
    placeId: json["placeId"],
    sourceId: json["sourceId"],
    detail1: json["jsonData"]?["detail1"],
    total: _num(json["total"]),
    lines: json["lines"] == null ? <UVoucherLineResponse>[] : List<UVoucherLineResponse>.from(json["lines"]!.map((dynamic x) => UVoucherLineResponse.fromMap(x))),
  );

  final String id;
  final List<int> tags;
  final int number;
  final DateTime date;
  final String organizationId;
  final String? placeId;
  final String? sourceId;
  final String? detail1;
  final double total;
  final List<UVoucherLineResponse> lines;

  bool get isManual => tags.contains(TagVoucher.manual.number);
}

class ULedgerLineResponse {
  ULedgerLineResponse({
    required this.voucherId,
    required this.number,
    required this.date,
    required this.tags,
    required this.accountId,
    required this.accountTitle,
    this.description,
    this.personId,
    this.personName,
    this.debit = 0,
    this.credit = 0,
    this.balance = 0,
  });

  factory ULedgerLineResponse.fromMap(Map<String, dynamic> json) => ULedgerLineResponse(
    voucherId: json["voucherId"] as String,
    number: json["number"] as int,
    date: DateTime.parse(json["date"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    accountId: json["accountId"] as String,
    accountTitle: json["accountTitle"] ?? "",
    description: json["description"],
    personId: json["personId"],
    personName: json["personName"],
    debit: _num(json["debit"]),
    credit: _num(json["credit"]),
    balance: _num(json["balance"]),
  );

  final String voucherId;
  final int number;
  final DateTime date;
  final List<int> tags;
  final String accountId;
  final String accountTitle;
  final String? description;
  final String? personId;
  final String? personName;
  final double debit;
  final double credit;
  final double balance;
}

class ULedgerResponse {
  ULedgerResponse({this.opening = 0, this.totalDebit = 0, this.totalCredit = 0, this.closing = 0, this.lines = const <ULedgerLineResponse>[]});

  factory ULedgerResponse.fromMap(Map<String, dynamic> json) => ULedgerResponse(
    opening: _num(json["opening"]),
    totalDebit: _num(json["totalDebit"]),
    totalCredit: _num(json["totalCredit"]),
    closing: _num(json["closing"]),
    lines: json["lines"] == null ? <ULedgerLineResponse>[] : List<ULedgerLineResponse>.from(json["lines"]!.map((dynamic x) => ULedgerLineResponse.fromMap(x))),
  );

  final double opening;
  final double totalDebit;
  final double totalCredit;
  final double closing;
  final List<ULedgerLineResponse> lines;
}

class ULedgerReportItem {
  ULedgerReportItem({required this.accountId, required this.code, required this.title, this.amount = 0});

  factory ULedgerReportItem.fromMap(Map<String, dynamic> json) => ULedgerReportItem(
    accountId: json["accountId"] as String,
    code: json["code"] ?? "",
    title: json["title"] ?? "",
    amount: _num(json["amount"]),
  );

  final String accountId;
  final String code;
  final String title;
  final double amount;
}

class ULedgerMoneyBoxItem {
  ULedgerMoneyBoxItem({required this.accountId, required this.title, this.tags = const <int>[], this.opening = 0, this.inAmount = 0, this.outAmount = 0, this.closing = 0});

  factory ULedgerMoneyBoxItem.fromMap(Map<String, dynamic> json) => ULedgerMoneyBoxItem(
    accountId: json["accountId"] as String,
    title: json["title"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    opening: _num(json["opening"]),
    inAmount: _num(json["in"]),
    outAmount: _num(json["out"]),
    closing: _num(json["closing"]),
  );

  final String accountId;
  final String title;
  final List<int> tags;
  final double opening;
  final double inAmount;
  final double outAmount;
  final double closing;
}

class ULedgerPlaceItem {
  ULedgerPlaceItem({this.placeId, this.title = "", this.income = 0, this.expense = 0});

  factory ULedgerPlaceItem.fromMap(Map<String, dynamic> json) => ULedgerPlaceItem(
    placeId: json["placeId"],
    title: json["title"] ?? "",
    income: _num(json["income"]),
    expense: _num(json["expense"]),
  );

  final String? placeId;
  final String title;
  final double income;
  final double expense;
}

class ULedgerAgingItem {
  ULedgerAgingItem({required this.personId, this.personName, this.phoneNumber, this.days0 = 0, this.days30 = 0, this.days60 = 0, this.days90 = 0, this.total = 0});

  factory ULedgerAgingItem.fromMap(Map<String, dynamic> json) => ULedgerAgingItem(
    personId: json["personId"] as String,
    personName: json["personName"],
    phoneNumber: json["phoneNumber"],
    days0: _num(json["days0"]),
    days30: _num(json["days30"]),
    days60: _num(json["days60"]),
    days90: _num(json["days90"]),
    total: _num(json["total"]),
  );

  final String personId;
  final String? personName;
  final String? phoneNumber;
  final double days0;
  final double days30;
  final double days60;
  final double days90;
  final double total;
}

class ULedgerReportResponse {
  ULedgerReportResponse({
    this.income = const <ULedgerReportItem>[],
    this.expense = const <ULedgerReportItem>[],
    this.netProfit = 0,
    this.vatSales = 0,
    this.vatPurchases = 0,
    this.vatDue = 0,
    this.moneyBoxes = const <ULedgerMoneyBoxItem>[],
    this.places = const <ULedgerPlaceItem>[],
    this.aging = const <ULedgerAgingItem>[],
  });

  factory ULedgerReportResponse.fromMap(Map<String, dynamic> json) => ULedgerReportResponse(
    income: List<ULedgerReportItem>.from((json["income"] ?? <dynamic>[]).map((dynamic x) => ULedgerReportItem.fromMap(x))),
    expense: List<ULedgerReportItem>.from((json["expense"] ?? <dynamic>[]).map((dynamic x) => ULedgerReportItem.fromMap(x))),
    netProfit: _num(json["netProfit"]),
    vatSales: _num(json["vatSales"]),
    vatPurchases: _num(json["vatPurchases"]),
    vatDue: _num(json["vatDue"]),
    moneyBoxes: List<ULedgerMoneyBoxItem>.from((json["moneyBoxes"] ?? <dynamic>[]).map((dynamic x) => ULedgerMoneyBoxItem.fromMap(x))),
    places: List<ULedgerPlaceItem>.from((json["places"] ?? <dynamic>[]).map((dynamic x) => ULedgerPlaceItem.fromMap(x))),
    aging: List<ULedgerAgingItem>.from((json["aging"] ?? <dynamic>[]).map((dynamic x) => ULedgerAgingItem.fromMap(x))),
  );

  final List<ULedgerReportItem> income;
  final List<ULedgerReportItem> expense;
  final double netProfit;
  final double vatSales;
  final double vatPurchases;
  final double vatDue;
  final List<ULedgerMoneyBoxItem> moneyBoxes;
  final List<ULedgerPlaceItem> places;
  final List<ULedgerAgingItem> aging;
}

class UCheckResponse {
  UCheckResponse({
    required this.id,
    required this.tags,
    required this.amount,
    required this.dueDate,
    required this.number,
    required this.organizationId,
    this.bank,
    this.personId,
    this.personName,
    this.contractId,
    this.placeId,
    this.sayadId,
    this.drawer,
    this.detail1,
  });

  factory UCheckResponse.fromMap(Map<String, dynamic> json) => UCheckResponse(
    id: json["id"] as String,
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    amount: _num(json["amount"]),
    dueDate: DateTime.parse(json["dueDate"]),
    number: json["number"] ?? "",
    organizationId: json["organizationId"] as String,
    bank: json["bank"],
    personId: json["personId"],
    personName: json["personName"],
    contractId: json["contractId"],
    placeId: json["placeId"],
    sayadId: json["jsonData"]?["sayadId"],
    drawer: json["jsonData"]?["drawer"],
    detail1: json["jsonData"]?["detail1"],
  );

  final String id;
  final List<int> tags;
  final double amount;
  final DateTime dueDate;
  final String number;
  final String organizationId;
  final String? bank;
  final String? personId;
  final String? personName;
  final String? contractId;
  final String? placeId;
  final String? sayadId;
  final String? drawer;
  final String? detail1;

  bool has(TagCheck t) => tags.contains(t.number);
}

class UTaxInvoiceItem {
  UTaxInvoiceItem({
    required this.sourceId,
    required this.number,
    required this.date,
    this.personId,
    this.personName,
    this.nationalCode,
    this.phoneNumber,
    this.placeTitle,
    this.description,
    this.serviceId,
    this.amount = 0,
    this.vatPercent = 0,
    this.vat = 0,
    this.total = 0,
  });

  factory UTaxInvoiceItem.fromMap(Map<String, dynamic> json) => UTaxInvoiceItem(
    sourceId: json["sourceId"] ?? "",
    number: json["number"] == null ? 0 : (json["number"] as num).toInt(),
    date: DateTime.parse(json["date"]),
    personId: json["personId"],
    personName: json["personName"],
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
    placeTitle: json["placeTitle"],
    description: json["description"],
    serviceId: json["serviceId"],
    amount: _num(json["amount"]),
    vatPercent: _num(json["vatPercent"]),
    vat: _num(json["vat"]),
    total: _num(json["total"]),
  );

  final String sourceId;
  final int number;
  final DateTime date;
  final String? personId;
  final String? personName;
  final String? nationalCode;
  final String? phoneNumber;
  final String? placeTitle;
  final String? description;
  final String? serviceId;
  final double amount;
  final double vatPercent;
  final double vat;
  final double total;
}
