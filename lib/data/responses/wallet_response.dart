part of "../data.dart";

extension NullableWalletListExtension on Iterable<UWalletResponse>? {
  List<UWalletResponse> whereByTag(int tag) => (this ?? <UWalletResponse>[]).where((UWalletResponse i) => i.tags.contains(tag)).toList();

  UWalletResponse primary() =>
      firstWhereByTagOrNull(TagWallet.primary.number) ??
      (this ?? <UWalletResponse>[]).firstOrNull ??
      UWalletResponse(id: "", tags: <int>[], jsonData: UWalletJson.fromMap(<String, dynamic>{}), balance: 0, creatorId: "", adminUserIds: <String>[]);

  UWalletResponse? firstWhereByTagOrNull(int tag) => (this ?? <UWalletResponse>[]).firstWhereOrNull((UWalletResponse i) => i.tags.contains(tag));
}

extension NullableWalletExtension on UWalletTxnResponse {
  bool isOutgoing({String? userId}) => senderId == (userId ?? U.user.id);

  String title() => tag?.localizedTitle ?? (UApp.locale() == "fa" ? "تراکنش کیف پول" : "Wallet Transaction");

  TagWalletTxn? get tag {
    for (final int t in tags) {
      final TagWalletTxn? tag = TagWalletTxn.values.fromNumber(t);
      if (tag != null) return tag;
    }
    return null;
  }

  String? get reference {
    for (final String d in <String>[jsonData.detail1 ?? "", jsonData.detail2 ?? ""]) {
      if (d.toUpperCase().contains("RRN")) return d.split(":").last.trim();
    }
    return null;
  }

  IconData get icon {
    switch (tag) {
      case TagWalletTxn.charge:
        return Icons.add_card_outlined;
      case TagWalletTxn.transfer:
        return Icons.swap_horiz;
      case TagWalletTxn.chargeSimPin:
      case TagWalletTxn.chargeSimTopup:
        return Icons.sim_card_outlined;
      case TagWalletTxn.internetSim:
        return Icons.wifi;
      case TagWalletTxn.chargeInternetRefund:
        return Icons.replay;
      case TagWalletTxn.vehicleViolationsDetail:
      case TagWalletTxn.licencePlateDetail:
      case TagWalletTxn.freewayTolls:
        return Icons.directions_car_outlined;
      case TagWalletTxn.drivingLicenceStatus:
      case TagWalletTxn.drivingLicenceNegativePoint:
        return Icons.badge_outlined;
      case TagWalletTxn.merchantCreationFee:
        return Icons.storefront_outlined;
      case TagWalletTxn.mobileAndNationalCodeVerification:
      case TagWalletTxn.zipCodeToAddressDetail:
      case TagWalletTxn.iBanToBankAccountDetail:
        return Icons.fact_check_outlined;
      case null:
        return isOutgoing() ? Icons.north_east : Icons.south_west;
      case TagWalletTxn.dormBedInvoice:
        return Icons.fact_check_outlined;
      case TagWalletTxn.hotelReservation:
        return Icons.fact_check_outlined;
      case TagWalletTxn.hotelReservationRefund:
        return Icons.fact_check_outlined;
      case TagWalletTxn.platformCommission:
        return Icons.percent;
      case TagWalletTxn.dormDepositRefund:
      case TagWalletTxn.organizationSettlementRefund:
        return Icons.replay;
      case TagWalletTxn.organizationSettlement:
        return Icons.account_balance_outlined;
      case TagWalletTxn.subscription:
        return Icons.workspace_premium_outlined;
      case TagWalletTxn.goldPurchase:
      case TagWalletTxn.goldSale:
      case TagWalletTxn.goldPurchaseRefund:
        return Icons.savings_outlined;
      case TagWalletTxn.courtBooking:
      case TagWalletTxn.courtBookingSettlement:
        return Icons.sports_tennis_outlined;
      case TagWalletTxn.tournamentEntryFee:
      case TagWalletTxn.tournamentEntrySettlement:
        return Icons.emoji_events_outlined;
      case TagWalletTxn.courtBookingRefund:
      case TagWalletTxn.tournamentEntryRefund:
        return Icons.replay;
    }
  }
}

class UWalletResponse {
  final String id;
  final List<int> tags;
  final UWalletJson jsonData;
  final DateTime? createdAt;
  final double balance;
  final String creatorId;
  final UUserResponse? creator;
  final List<String> adminUserIds;

  UWalletResponse({
    required this.id,
    required this.tags,
    required this.jsonData,
    required this.balance,
    required this.creatorId,
    required this.adminUserIds,
    this.createdAt,
    this.creator,
  });

  factory UWalletResponse.fromJson(String str) => UWalletResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletResponse.fromMap(Map<String, dynamic> json) => UWalletResponse(
    id: json["id"],
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    jsonData: UWalletJson.fromMap(json["jsonData"]),
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    balance: json["balance"].toString().toDouble(),
    creatorId: json["creatorId"] ?? "",
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "jsonData": jsonData.toMap(),
    "createdAt": createdAt?.toIso8601String(),
    "balance": balance,
    "creatorId": creatorId,
    "creator": creator?.toMap(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UWalletTxnResponse {
  final String id;
  final List<int> tags;
  final UWalletTxnJson jsonData;
  final DateTime createdAt;
  final double amount;
  final UUserResponse? sender;
  final String senderId;
  final UUserResponse? receiver;
  final String receiverId;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  UWalletTxnResponse({
    required this.id,
    required this.tags,
    required this.jsonData,
    required this.createdAt,
    required this.amount,
    required this.senderId,
    required this.receiverId,
    required this.adminUserIds,
    this.sender,
    this.receiver,
    this.creator,
    this.creatorId,
  });

  factory UWalletTxnResponse.fromJson(String str) => UWalletTxnResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletTxnResponse.fromMap(Map<String, dynamic> json) => UWalletTxnResponse(
    id: json["id"],
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    jsonData: UWalletTxnJson.fromMap(json["jsonData"]),
    createdAt: DateTime.parse(json["createdAt"]),
    amount: (json["amount"] as num).toDouble(),
    sender: json["sender"] == null ? null : UUserResponse.fromMap(json["sender"]),
    senderId: json["senderId"] as String,
    receiver: json["receiver"] == null ? null : UUserResponse.fromMap(json["receiver"]),
    receiverId: json["receiverId"] as String,
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "jsonData": jsonData.toMap(),
    "createdAt": createdAt.toIso8601String(),
    "amount": amount,
    "sender": sender?.toMap(),
    "senderId": senderId,
    "receiver": receiver?.toMap(),
    "receiverId": receiverId,
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UWalletJson {
  final bool allowMinusBalance;
  final String? detail1;
  final String? detail2;

  UWalletJson({
    this.allowMinusBalance = false,
    this.detail1,
    this.detail2,
  });

  factory UWalletJson.fromJson(String str) => UWalletJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletJson.fromMap(Map<String, dynamic> json) => UWalletJson(
    allowMinusBalance: json["allowMinusBalance"] ?? false,
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "allowMinusBalance": allowMinusBalance,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UWalletTxnJson {
  final List<UKeyValueData> keyValues;
  final String? detail1;
  final String? detail2;

  UWalletTxnJson({
    this.keyValues = const <UKeyValueData>[],
    this.detail1,
    this.detail2,
  });

  factory UWalletTxnJson.fromJson(String str) => UWalletTxnJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletTxnJson.fromMap(Map<String, dynamic> json) => UWalletTxnJson(
    keyValues: json["keyValues"] == null ? <UKeyValueData>[] : List<UKeyValueData>.from(json["keyValues"]!.map((dynamic x) => UKeyValueData.fromMap(x))),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "keyValues": List<dynamic>.from(keyValues.map((UKeyValueData x) => x.toMap())),
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UWalletReportResponse {
  final double totalBalance;
  final double usersBalance;
  final double systemBalance;
  final int walletsCount;
  final int negativeWalletsCount;
  final int mismatchedWalletsCount;
  final double mismatchedAmount;
  final int txnCount;
  final double txnAmount;
  final double chargeAmount;
  final int chargeCount;
  final double paidAmount;
  final int paidCount;
  final List<UWalletReportWallet> systemWallets;
  final List<UBreakdownItem> txnsByTag;
  final List<UBreakdownItem> paymentsByStatus;
  final List<UBreakdownItem> paymentsByKind;
  final List<UWalletReportDay> daily;

  UWalletReportResponse({
    required this.totalBalance,
    required this.usersBalance,
    required this.systemBalance,
    required this.walletsCount,
    required this.negativeWalletsCount,
    required this.mismatchedWalletsCount,
    required this.mismatchedAmount,
    required this.txnCount,
    required this.txnAmount,
    required this.chargeAmount,
    required this.chargeCount,
    required this.paidAmount,
    required this.paidCount,
    required this.systemWallets,
    required this.txnsByTag,
    required this.paymentsByStatus,
    required this.paymentsByKind,
    required this.daily,
  });

  factory UWalletReportResponse.fromJson(String str) => UWalletReportResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletReportResponse.fromMap(Map<String, dynamic> json) => UWalletReportResponse(
    totalBalance: (json["totalBalance"] ?? 0).toString().toDouble(),
    usersBalance: (json["usersBalance"] ?? 0).toString().toDouble(),
    systemBalance: (json["systemBalance"] ?? 0).toString().toDouble(),
    walletsCount: json["walletsCount"] ?? 0,
    negativeWalletsCount: json["negativeWalletsCount"] ?? 0,
    mismatchedWalletsCount: json["mismatchedWalletsCount"] ?? 0,
    mismatchedAmount: (json["mismatchedAmount"] ?? 0).toString().toDouble(),
    txnCount: json["txnCount"] ?? 0,
    txnAmount: (json["txnAmount"] ?? 0).toString().toDouble(),
    chargeAmount: (json["chargeAmount"] ?? 0).toString().toDouble(),
    chargeCount: json["chargeCount"] ?? 0,
    paidAmount: (json["paidAmount"] ?? 0).toString().toDouble(),
    paidCount: json["paidCount"] ?? 0,
    systemWallets: json["systemWallets"] == null ? <UWalletReportWallet>[] : List<UWalletReportWallet>.from(json["systemWallets"]!.map((dynamic x) => UWalletReportWallet.fromMap(x))),
    txnsByTag: json["txnsByTag"] == null ? <UBreakdownItem>[] : List<UBreakdownItem>.from(json["txnsByTag"]!.map((dynamic x) => UBreakdownItem.fromMap(x))),
    paymentsByStatus: json["paymentsByStatus"] == null ? <UBreakdownItem>[] : List<UBreakdownItem>.from(json["paymentsByStatus"]!.map((dynamic x) => UBreakdownItem.fromMap(x))),
    paymentsByKind: json["paymentsByKind"] == null ? <UBreakdownItem>[] : List<UBreakdownItem>.from(json["paymentsByKind"]!.map((dynamic x) => UBreakdownItem.fromMap(x))),
    daily: json["daily"] == null ? <UWalletReportDay>[] : List<UWalletReportDay>.from(json["daily"]!.map((dynamic x) => UWalletReportDay.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "totalBalance": totalBalance,
    "usersBalance": usersBalance,
    "systemBalance": systemBalance,
    "walletsCount": walletsCount,
    "negativeWalletsCount": negativeWalletsCount,
    "mismatchedWalletsCount": mismatchedWalletsCount,
    "mismatchedAmount": mismatchedAmount,
    "txnCount": txnCount,
    "txnAmount": txnAmount,
    "chargeAmount": chargeAmount,
    "chargeCount": chargeCount,
    "paidAmount": paidAmount,
    "paidCount": paidCount,
    "systemWallets": List<dynamic>.from(systemWallets.map((UWalletReportWallet x) => x.toMap())),
    "txnsByTag": List<dynamic>.from(txnsByTag.map((UBreakdownItem x) => x.toMap())),
    "paymentsByStatus": List<dynamic>.from(paymentsByStatus.map((UBreakdownItem x) => x.toMap())),
    "paymentsByKind": List<dynamic>.from(paymentsByKind.map((UBreakdownItem x) => x.toMap())),
    "daily": List<dynamic>.from(daily.map((UWalletReportDay x) => x.toMap())),
  };
}

class UWalletReportWallet {
  final String userId;
  final UUserResponse? user;
  final double balance;
  final double inAmount;
  final double outAmount;
  final int count;

  UWalletReportWallet({
    required this.userId,
    required this.balance,
    required this.inAmount,
    required this.outAmount,
    required this.count,
    this.user,
  });

  factory UWalletReportWallet.fromJson(String str) => UWalletReportWallet.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletReportWallet.fromMap(Map<String, dynamic> json) => UWalletReportWallet(
    userId: json["userId"] ?? "",
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    balance: (json["balance"] ?? 0).toString().toDouble(),
    inAmount: (json["in"] ?? 0).toString().toDouble(),
    outAmount: (json["out"] ?? 0).toString().toDouble(),
    count: json["count"] ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "user": user?.toMap(),
    "balance": balance,
    "in": inAmount,
    "out": outAmount,
    "count": count,
  };
}

class UWalletReportDay {
  final DateTime date;
  final int count;
  final double amount;
  final double chargeAmount;
  final double paidAmount;

  UWalletReportDay({
    required this.date,
    required this.count,
    required this.amount,
    required this.chargeAmount,
    required this.paidAmount,
  });

  factory UWalletReportDay.fromJson(String str) => UWalletReportDay.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletReportDay.fromMap(Map<String, dynamic> json) => UWalletReportDay(
    date: DateTime.parse(json["date"]),
    count: json["count"] ?? 0,
    amount: (json["amount"] ?? 0).toString().toDouble(),
    chargeAmount: (json["chargeAmount"] ?? 0).toString().toDouble(),
    paidAmount: (json["paidAmount"] ?? 0).toString().toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "date": date.toIso8601String(),
    "count": count,
    "amount": amount,
    "chargeAmount": chargeAmount,
    "paidAmount": paidAmount,
  };
}

class UWalletLedgerCheckResponse {
  final double totalBalance;
  final int walletsCount;
  final int mismatchedCount;
  final double mismatchedAmount;
  final List<UWalletLedgerItem> wallets;

  UWalletLedgerCheckResponse({
    required this.totalBalance,
    required this.walletsCount,
    required this.mismatchedCount,
    required this.mismatchedAmount,
    required this.wallets,
  });

  factory UWalletLedgerCheckResponse.fromJson(String str) => UWalletLedgerCheckResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletLedgerCheckResponse.fromMap(Map<String, dynamic> json) => UWalletLedgerCheckResponse(
    totalBalance: (json["totalBalance"] ?? 0).toString().toDouble(),
    walletsCount: json["walletsCount"] ?? 0,
    mismatchedCount: json["mismatchedCount"] ?? 0,
    mismatchedAmount: (json["mismatchedAmount"] ?? 0).toString().toDouble(),
    wallets: json["wallets"] == null ? <UWalletLedgerItem>[] : List<UWalletLedgerItem>.from(json["wallets"]!.map((dynamic x) => UWalletLedgerItem.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "totalBalance": totalBalance,
    "walletsCount": walletsCount,
    "mismatchedCount": mismatchedCount,
    "mismatchedAmount": mismatchedAmount,
    "wallets": List<dynamic>.from(wallets.map((UWalletLedgerItem x) => x.toMap())),
  };
}

class UWalletLedgerItem {
  final String walletId;
  final String userId;
  final UUserResponse? user;
  final double balance;
  final double ledgerBalance;
  final double difference;

  UWalletLedgerItem({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.ledgerBalance,
    required this.difference,
    this.user,
  });

  factory UWalletLedgerItem.fromJson(String str) => UWalletLedgerItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UWalletLedgerItem.fromMap(Map<String, dynamic> json) => UWalletLedgerItem(
    walletId: json["walletId"] ?? "",
    userId: json["userId"] ?? "",
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    balance: (json["balance"] ?? 0).toString().toDouble(),
    ledgerBalance: (json["ledgerBalance"] ?? 0).toString().toDouble(),
    difference: (json["difference"] ?? 0).toString().toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "walletId": walletId,
    "userId": userId,
    "user": user?.toMap(),
    "balance": balance,
    "ledgerBalance": ledgerBalance,
    "difference": difference,
  };
}
