part of "../data.dart";

class UCustodyProgramJson {
  UCustodyProgramJson({
    this.description,
    this.rules,
    this.minPurchase,
    this.maxPurchase,
    this.deliveryFee,
    this.makingChargePercent,
    this.feePercent = 0,
    this.deliveryHours = const <UStoreWorkingDay>[],
    this.declaredStock,
  });

  factory UCustodyProgramJson.fromMap(Map<String, dynamic> json) => UCustodyProgramJson(
    description: json["description"],
    rules: json["rules"],
    minPurchase: json["minPurchase"]?.toDouble(),
    maxPurchase: json["maxPurchase"]?.toDouble(),
    deliveryFee: json["deliveryFee"]?.toDouble(),
    makingChargePercent: json["makingChargePercent"]?.toDouble(),
    feePercent: json["feePercent"]?.toDouble() ?? 0,
    deliveryHours: json["deliveryHours"] == null ? const <UStoreWorkingDay>[] : List<UStoreWorkingDay>.from(json["deliveryHours"].map((dynamic x) => UStoreWorkingDay.fromMap(x))),
    declaredStock: json["declaredStock"]?.toDouble(),
  );

  final String? description;
  final String? rules;
  final double? minPurchase;
  final double? maxPurchase;
  final double? deliveryFee;
  final double? makingChargePercent;

  /// The platform's share of each purchase, in percent.
  final double feePercent;

  /// Empty = the store's working hours.
  final List<UStoreWorkingDay> deliveryHours;

  /// What the store says it physically holds, in units.
  final double? declaredStock;
}

/// A store keeping an asset (gold, coins…) for its members; the store holds it, the platform keeps the ledger.
class UCustodyProgramResponse {
  UCustodyProgramResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.jsonData,
    required this.title,
    required this.storeId,
    this.memberCount = 0,
    this.heldQuantity = 0,
    this.rate,
    this.store,
  });

  factory UCustodyProgramResponse.fromMap(Map<String, dynamic> json) => UCustodyProgramResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    jsonData: UCustodyProgramJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
    title: json["title"],
    storeId: json["storeId"],
    memberCount: json["memberCount"] ?? 0,
    heldQuantity: json["heldQuantity"]?.toDouble() ?? 0,
    rate: json["rate"] == null ? null : UCustodyRateResponse.fromMap(json["rate"]),
    store: json["store"] == null ? null : UStoreResponse.fromMap(json["store"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final UCustodyProgramJson jsonData;
  final String title;
  final String storeId;
  final int memberCount;

  /// The sum of every member's balance.
  final double heldQuantity;

  /// The latest rate.
  final UCustodyRateResponse? rate;
  final UStoreResponse? store;

  /// The unit the asset is counted in (a 2xx value).
  TagCustodyProgram get unit => TagCustodyProgram.values.group(200).firstWhereOrNull((TagCustodyProgram x) => tags.contains(x.number)) ?? TagCustodyProgram.gram;

  TagCustodyProgram get status => TagCustodyProgram.values.group(100).firstWhereOrNull((TagCustodyProgram x) => tags.contains(x.number)) ?? TagCustodyProgram.active;
}

class UCustodyRateResponse {
  UCustodyRateResponse({required this.id, required this.createdAt, required this.programId, required this.price});

  factory UCustodyRateResponse.fromMap(Map<String, dynamic> json) => UCustodyRateResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    programId: json["programId"],
    price: json["price"]?.toDouble() ?? 0,
  );

  final String id;
  final DateTime createdAt;
  final String programId;
  final double price;
}

class UCustodyMemberResponse {
  UCustodyMemberResponse({required this.id, required this.createdAt, required this.tags, required this.programId, required this.userId, this.note, this.balance = 0, this.program, this.user});

  factory UCustodyMemberResponse.fromMap(Map<String, dynamic> json) => UCustodyMemberResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    programId: json["programId"],
    userId: json["userId"],
    note: json["jsonData"]?["note"],
    balance: json["balance"]?.toDouble() ?? 0,
    program: json["program"] == null ? null : UCustodyProgramResponse.fromMap(json["program"]),
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String programId;
  final String userId;
  final String? note;

  /// The sum of the member's entries.
  final double balance;
  final UCustodyProgramResponse? program;
  final UUserResponse? user;

  bool get isActive => tags.contains(TagCustodyMember.active.number);
}

/// A ledger entry; it is also the receipt.
class UCustodyEntryResponse {
  UCustodyEntryResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.programId,
    required this.memberId,
    required this.quantity,
    required this.receiptNumber,
    this.unitPrice,
    this.amount = 0,
    this.fee = 0,
    this.note,
    this.balanceAfter,
    this.program,
    this.member,
  });

  factory UCustodyEntryResponse.fromMap(Map<String, dynamic> json) => UCustodyEntryResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    programId: json["programId"],
    memberId: json["memberId"],
    quantity: json["quantity"]?.toDouble() ?? 0,
    receiptNumber: json["receiptNumber"] ?? "",
    unitPrice: json["unitPrice"]?.toDouble(),
    amount: json["amount"]?.toDouble() ?? 0,
    fee: json["fee"]?.toDouble() ?? 0,
    note: json["jsonData"]?["note"],
    balanceAfter: json["balanceAfter"]?.toDouble(),
    program: json["program"] == null ? null : UCustodyProgramResponse.fromMap(json["program"]),
    member: json["member"] == null ? null : UCustodyMemberResponse.fromMap(json["member"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String programId;
  final String memberId;

  /// Positive when units came in for the member, negative when they went out.
  final double quantity;
  final String receiptNumber;
  final double? unitPrice;
  final double amount;

  /// The platform's share of [amount].
  final double fee;
  final String? note;

  /// The member's balance after this entry (on create and read by id).
  final double? balanceAfter;
  final UCustodyProgramResponse? program;
  final UCustodyMemberResponse? member;

  TagCustodyEntry? get kind => TagCustodyEntry.values.firstWhereOrNull((TagCustodyEntry x) => tags.contains(x.number));
}
