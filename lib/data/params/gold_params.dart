part of "../data.dart";

class UGoldQuoteParams {
  final TagGoldAsset baseAsset;
  final TagGoldAsset quoteAsset;

  UGoldQuoteParams({this.baseAsset = TagGoldAsset.gold18, this.quoteAsset = TagGoldAsset.irr});

  factory UGoldQuoteParams.fromJson(String str) => UGoldQuoteParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldQuoteParams.fromMap(Map<String, dynamic> json) => UGoldQuoteParams(
    baseAsset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["baseAsset"]) ?? TagGoldAsset.gold18,
    quoteAsset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["quoteAsset"]) ?? TagGoldAsset.irr,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "baseAsset": baseAsset.number,
    "quoteAsset": quoteAsset.number,
  };
}

// Send exactly one of baseAmount (grams of gold) or quoteAmount (rial); idempotencyKey must be unique per order.
class UGoldCreateOrderParams {
  final String idempotencyKey;
  final TagGoldOrderSide side;
  final TagGoldAsset baseAsset;
  final TagGoldAsset quoteAsset;
  final double? baseAmount;
  final double? quoteAmount;

  UGoldCreateOrderParams({
    required this.idempotencyKey,
    required this.side,
    this.baseAsset = TagGoldAsset.gold18,
    this.quoteAsset = TagGoldAsset.irr,
    this.baseAmount,
    this.quoteAmount,
  });

  factory UGoldCreateOrderParams.fromJson(String str) => UGoldCreateOrderParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldCreateOrderParams.fromMap(Map<String, dynamic> json) => UGoldCreateOrderParams(
    idempotencyKey: json["idempotencyKey"],
    side: TagGoldOrderSide.values.firstWhereOrNull((TagGoldOrderSide e) => e.number == json["side"]) ?? TagGoldOrderSide.buy,
    baseAsset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["baseAsset"]) ?? TagGoldAsset.gold18,
    quoteAsset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["quoteAsset"]) ?? TagGoldAsset.irr,
    baseAmount: json["baseAmount"] == null ? null : (json["baseAmount"] as num).toDouble(),
    quoteAmount: json["quoteAmount"] == null ? null : (json["quoteAmount"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "idempotencyKey": idempotencyKey,
    "side": side.number,
    "baseAsset": baseAsset.number,
    "quoteAsset": quoteAsset.number,
    if (baseAmount != null) "baseAmount": baseAmount,
    if (quoteAmount != null) "quoteAmount": quoteAmount,
  };
}

// Cursor pagination: pass the nextCursor of the previous page, never a parsed or built value.
class UGoldReadOrdersParams {
  final String? cursor;
  final int limit;

  UGoldReadOrdersParams({this.cursor, this.limit = 20});

  factory UGoldReadOrdersParams.fromJson(String str) => UGoldReadOrdersParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldReadOrdersParams.fromMap(Map<String, dynamic> json) => UGoldReadOrdersParams(
    cursor: json["cursor"],
    limit: json["limit"] ?? 20,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    if (cursor != null) "cursor": cursor,
    "limit": limit,
  };
}

class UGoldReadOrderParams {
  final String id;

  UGoldReadOrderParams({required this.id});

  factory UGoldReadOrderParams.fromJson(String str) => UGoldReadOrderParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldReadOrderParams.fromMap(Map<String, dynamic> json) => UGoldReadOrderParams(id: json["id"]);

  Map<String, dynamic> toMap() => <String, dynamic>{"id": id};
}

class UGoldReadBalanceParams {
  final TagGoldAsset asset;

  UGoldReadBalanceParams({this.asset = TagGoldAsset.gold18});

  factory UGoldReadBalanceParams.fromJson(String str) => UGoldReadBalanceParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldReadBalanceParams.fromMap(Map<String, dynamic> json) => UGoldReadBalanceParams(
    asset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["asset"]) ?? TagGoldAsset.gold18,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{"asset": asset.number};
}

class UGoldReadTransactionsParams {
  final String? cursor;
  final int limit;

  UGoldReadTransactionsParams({this.cursor, this.limit = 20});

  factory UGoldReadTransactionsParams.fromJson(String str) => UGoldReadTransactionsParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldReadTransactionsParams.fromMap(Map<String, dynamic> json) => UGoldReadTransactionsParams(
    cursor: json["cursor"],
    limit: json["limit"] ?? 20,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    if (cursor != null) "cursor": cursor,
    "limit": limit,
  };
}

class UGoldCreateApiTokenParams {
  final String? label;
  final List<String> scopes;
  final List<String>? ipWhitelist;

  UGoldCreateApiTokenParams({required this.scopes, this.label, this.ipWhitelist});

  factory UGoldCreateApiTokenParams.fromJson(String str) => UGoldCreateApiTokenParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldCreateApiTokenParams.fromMap(Map<String, dynamic> json) => UGoldCreateApiTokenParams(
    label: json["label"],
    scopes: json["scopes"] == null ? <String>[] : List<String>.from(json["scopes"]!.map((dynamic x) => x)),
    ipWhitelist: json["ipWhitelist"] == null ? null : List<String>.from(json["ipWhitelist"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    if (label != null) "label": label,
    "scopes": List<dynamic>.from(scopes.map((String x) => x)),
    if (ipWhitelist != null) "ipWhitelist": List<dynamic>.from(ipWhitelist!.map((String x) => x)),
  };
}

class UGoldDeleteApiTokenParams {
  final String tokenId;

  UGoldDeleteApiTokenParams({required this.tokenId});

  factory UGoldDeleteApiTokenParams.fromJson(String str) => UGoldDeleteApiTokenParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldDeleteApiTokenParams.fromMap(Map<String, dynamic> json) => UGoldDeleteApiTokenParams(tokenId: json["tokenId"]);

  Map<String, dynamic> toMap() => <String, dynamic>{"tokenId": tokenId};
}
