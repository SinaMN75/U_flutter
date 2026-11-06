part of "../data.dart";

class UCustodyProgramCreateParams {
  UCustodyProgramCreateParams({
    required this.storeId,
    required this.title,
    required this.unit,
    this.status = TagCustodyProgram.active,
    this.description,
    this.rules,
    this.minPurchase,
    this.maxPurchase,
    this.deliveryFee,
    this.makingChargePercent,
    this.feePercent,
    this.deliveryHours,
    this.declaredStock,
  });

  final String storeId;
  final String title;

  /// One of the 2xx values of [TagCustodyProgram] (gram, coin…).
  final TagCustodyProgram unit;
  final TagCustodyProgram status;
  final String? description;
  final String? rules;
  final double? minPurchase;
  final double? maxPurchase;
  final double? deliveryFee;
  final double? makingChargePercent;

  /// Platform managers only; anybody else's value is ignored.
  final double? feePercent;
  final List<UStoreWorkingDay>? deliveryHours;
  final double? declaredStock;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "storeId": storeId,
    "title": title,
    "tags": <int>[status.number, unit.number],
    "description": description,
    "rules": rules,
    "minPurchase": minPurchase,
    "maxPurchase": maxPurchase,
    "deliveryFee": deliveryFee,
    "makingChargePercent": makingChargePercent,
    "feePercent": feePercent,
    "deliveryHours": deliveryHours?.map((UStoreWorkingDay x) => x.toMap()).toList(),
    "declaredStock": declaredStock,
  };
}

class UCustodyProgramUpdateParams {
  UCustodyProgramUpdateParams({
    required this.id,
    this.title,
    this.unit,
    this.status,
    this.description,
    this.rules,
    this.minPurchase,
    this.maxPurchase,
    this.deliveryFee,
    this.makingChargePercent,
    this.feePercent,
    this.deliveryHours,
    this.declaredStock,
  });

  final String id;
  final String? title;

  /// One of the 2xx values of [TagCustodyProgram].
  final TagCustodyProgram? unit;

  /// Only platform managers suspend a program or lift a suspension.
  final TagCustodyProgram? status;
  final String? description;
  final String? rules;

  /// A negative number clears the limit.
  final double? minPurchase;
  final double? maxPurchase;
  final double? deliveryFee;
  final double? makingChargePercent;

  /// Platform managers only.
  final double? feePercent;
  final List<UStoreWorkingDay>? deliveryHours;
  final double? declaredStock;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "addTags": <int>[?status?.number, ?unit?.number],
    "removeTags": <int>[
      if (status != null) ...TagCustodyProgram.values.group(100).where((TagCustodyProgram x) => x != status).map((TagCustodyProgram x) => x.number),
      if (unit != null) ...TagCustodyProgram.values.group(200).where((TagCustodyProgram x) => x != unit).map((TagCustodyProgram x) => x.number),
    ],
    "description": description,
    "rules": rules,
    "minPurchase": minPurchase,
    "maxPurchase": maxPurchase,
    "deliveryFee": deliveryFee,
    "makingChargePercent": makingChargePercent,
    "feePercent": feePercent,
    "deliveryHours": deliveryHours?.map((UStoreWorkingDay x) => x.toMap()).toList(),
    "declaredStock": declaredStock,
  };
}

class UCustodyProgramReadParams {
  UCustodyProgramReadParams({this.storeId, this.joined, this.tags, this.selectorArgs, this.pageSize, this.pageNumber});

  final String? storeId;

  /// Only the programs the signed-in user is a member of.
  final bool? joined;
  final List<int>? tags;
  final UCustodyProgramSelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "storeId": storeId,
    "joined": joined,
    "tags": tags,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UCustodyRateCreateParams {
  UCustodyRateCreateParams({required this.programId, required this.price});

  final String programId;

  /// The price of one unit.
  final double price;

  Map<String, dynamic> toMap() => <String, dynamic>{"programId": programId, "price": price};
}

class UCustodyRateReadParams {
  UCustodyRateReadParams({required this.programId, this.pageSize, this.pageNumber});

  final String programId;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{"programId": programId, "pageSize": pageSize, "pageNumber": pageNumber}..removeWhere((String _, dynamic v) => v == null);
}

class UCustodyMemberCreateParams {
  UCustodyMemberCreateParams({required this.programId, this.userId, this.note});

  final String programId;

  /// Store managers: the user to add; null = the signed-in user joins.
  final String? userId;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{"programId": programId, "userId": userId, "note": note};
}

class UCustodyMemberUpdateParams {
  UCustodyMemberUpdateParams({required this.id, this.status, this.note});

  final String id;
  final TagCustodyMember? status;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{"id": id, "tags": status == null ? null : <int>[status!.number], "note": note};
}

class UCustodyMemberReadParams {
  UCustodyMemberReadParams({this.programId, this.userId, this.tags, this.selectorArgs, this.pageSize, this.pageNumber});

  final String? programId;
  final String? userId;
  final List<int>? tags;
  final UCustodyMemberSelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "programId": programId,
    "userId": userId,
    "tags": tags,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UCustodyEntryCreateParams {
  UCustodyEntryCreateParams({required this.memberId, required this.kind, required this.quantity, this.unitPrice, this.amount, this.note});

  final String memberId;
  final TagCustodyEntry kind;

  /// Units; positive for a purchase or a delivery, either sign for an adjustment.
  final double quantity;

  /// Purchase: null = the current rate.
  final double? unitPrice;

  /// Purchase: null = quantity × unit price. Delivery: the fees the member paid.
  final double? amount;

  /// Required for an adjustment.
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "memberId": memberId,
    "tags": <int>[kind.number],
    "quantity": quantity,
    "unitPrice": unitPrice,
    "amount": amount,
    "note": note,
  };
}

class UCustodyEntryReadParams {
  UCustodyEntryReadParams({this.programId, this.memberId, this.tags, this.selectorArgs, this.pageSize, this.pageNumber});

  final String? programId;
  final String? memberId;
  final List<int>? tags;
  final UCustodyEntrySelectorArgs? selectorArgs;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "programId": programId,
    "memberId": memberId,
    "tags": tags,
    "selectorArgs": selectorArgs?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UCustodyEntryReadByIdParams {
  UCustodyEntryReadByIdParams({this.id, this.receiptNumber, this.selectorArgs});

  final String? id;

  /// Instead of [id].
  final String? receiptNumber;
  final UCustodyEntrySelectorArgs? selectorArgs;

  Map<String, dynamic> toMap() => <String, dynamic>{"id": id, "receiptNumber": receiptNumber, "selectorArgs": selectorArgs?.toMap()}..removeWhere((String _, dynamic v) => v == null);
}
