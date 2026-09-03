part of "../data.dart";

extension NullableWalletListExtension on Iterable<UWalletResponse>? {
  List<UWalletResponse> whereByTag(int tag) => (this ?? <UWalletResponse>[]).where((UWalletResponse i) => i.tags.contains(tag)).toList();

  UWalletResponse primary() => (this ?? <UWalletResponse>[]).firstWhere((UWalletResponse i) => i.tags.contains(TagWallet.primary.number));

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
    }
  }
}

class UWalletResponse {
  final String id;
  final List<int> tags;
  final UBaseJson jsonData;
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
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    balance: json["balance"].toString().toDouble(),
    creatorId: json["creatorId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt?.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "balance": balance,
    "creatorId": creatorId,
    "creator": creator?.toMap(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UWalletTxnResponse {
  final String id;
  final List<int> tags;
  final UBaseJson jsonData;
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
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
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
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
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
