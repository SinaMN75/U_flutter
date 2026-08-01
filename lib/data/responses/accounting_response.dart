part of "../data.dart";

// Accounting report response: money-in vs money-out with breakdowns and a daily timeline.
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

// One tag-grouped row of a money breakdown.
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

// One day of aggregated in/out totals.
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
