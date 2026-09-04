part of "../data.dart";

class UGoldAccountResponse {
  final String name;
  final bool active;
  final List<String> ipWhitelist;

  UGoldAccountResponse({required this.name, required this.active, required this.ipWhitelist});

  factory UGoldAccountResponse.fromJson(String str) => UGoldAccountResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldAccountResponse.fromMap(Map<String, dynamic> json) => UGoldAccountResponse(
    name: json["name"] ?? "",
    active: json["active"] ?? false,
    ipWhitelist: json["ipWhitelist"] == null ? <String>[] : List<String>.from(json["ipWhitelist"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "name": name,
    "active": active,
    "ipWhitelist": List<dynamic>.from(ipWhitelist.map((String x) => x)),
  };
}

class UGoldQuoteResponse {
  final TagGoldAsset? baseAsset;
  final TagGoldAsset? quoteAsset;
  final String? unit;
  final double? baseUnitPrice;
  final double? buyUnitPrice;
  final double? sellUnitPrice;
  final DateTime? updatedAt;

  UGoldQuoteResponse({
    this.baseAsset,
    this.quoteAsset,
    this.unit,
    this.baseUnitPrice,
    this.buyUnitPrice,
    this.sellUnitPrice,
    this.updatedAt,
  });

  factory UGoldQuoteResponse.fromJson(String str) => UGoldQuoteResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldQuoteResponse.fromMap(Map<String, dynamic> json) => UGoldQuoteResponse(
    baseAsset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["baseAsset"]),
    quoteAsset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["quoteAsset"]),
    unit: json["unit"],
    baseUnitPrice: json["baseUnitPrice"] == null ? null : (json["baseUnitPrice"] as num).toDouble(),
    buyUnitPrice: json["buyUnitPrice"] == null ? null : (json["buyUnitPrice"] as num).toDouble(),
    sellUnitPrice: json["sellUnitPrice"] == null ? null : (json["sellUnitPrice"] as num).toDouble(),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "baseAsset": baseAsset?.number,
    "quoteAsset": quoteAsset?.number,
    "unit": unit,
    "baseUnitPrice": baseUnitPrice,
    "buyUnitPrice": buyUnitPrice,
    "sellUnitPrice": sellUnitPrice,
    "updatedAt": updatedAt?.toIso8601String(),
  };
}

class UGoldWalletEntryResponse {
  final String? asset;
  final double? amount;

  UGoldWalletEntryResponse({this.asset, this.amount});

  factory UGoldWalletEntryResponse.fromJson(String str) => UGoldWalletEntryResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldWalletEntryResponse.fromMap(Map<String, dynamic> json) => UGoldWalletEntryResponse(
    asset: json["asset"],
    amount: json["amount"] == null ? null : (json["amount"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{"asset": asset, "amount": amount};
}

class UGoldOrderFeeResponse {
  final String? asset;
  final double? amount;
  final String? type;
  final double? rate;

  UGoldOrderFeeResponse({this.asset, this.amount, this.type, this.rate});

  factory UGoldOrderFeeResponse.fromJson(String str) => UGoldOrderFeeResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldOrderFeeResponse.fromMap(Map<String, dynamic> json) => UGoldOrderFeeResponse(
    asset: json["asset"],
    amount: json["amount"] == null ? null : (json["amount"] as num).toDouble(),
    type: json["type"],
    rate: json["rate"] == null ? null : (json["rate"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{"asset": asset, "amount": amount, "type": type, "rate": rate};
}

class UGoldOrderTransactionResponse {
  final String id;
  final DateTime? createdAt;
  final List<UGoldWalletEntryResponse> entries;

  UGoldOrderTransactionResponse({required this.id, required this.entries, this.createdAt});

  factory UGoldOrderTransactionResponse.fromJson(String str) => UGoldOrderTransactionResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldOrderTransactionResponse.fromMap(Map<String, dynamic> json) => UGoldOrderTransactionResponse(
    id: json["id"] ?? "",
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    entries: json["entries"] == null
        ? <UGoldWalletEntryResponse>[]
        : List<UGoldWalletEntryResponse>.from(json["entries"]!.map((dynamic x) => UGoldWalletEntryResponse.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt?.toIso8601String(),
    "entries": List<dynamic>.from(entries.map((UGoldWalletEntryResponse x) => x.toMap())),
  };
}

class UGoldOrderResponse {
  final String id;
  final String? idempotencyKey;
  final TagGoldOrderStatus? status;
  final TagGoldOrderSide? side;
  final TagGoldAsset? baseAsset;
  final TagGoldAsset? quoteAsset;
  final double? requestedBaseAmount;
  final double? requestedQuoteAmount;
  final double? dealtBaseAmount;
  final double? dealtQuoteAmount;
  final double? effectivePrice;
  final double? baseUnitPrice;
  final DateTime? createdAt;
  final List<UGoldOrderFeeResponse> fees;
  final List<UGoldOrderTransactionResponse> transactions;

  UGoldOrderResponse({
    required this.id,
    required this.fees,
    required this.transactions,
    this.idempotencyKey,
    this.status,
    this.side,
    this.baseAsset,
    this.quoteAsset,
    this.requestedBaseAmount,
    this.requestedQuoteAmount,
    this.dealtBaseAmount,
    this.dealtQuoteAmount,
    this.effectivePrice,
    this.baseUnitPrice,
    this.createdAt,
  });

  factory UGoldOrderResponse.fromJson(String str) => UGoldOrderResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldOrderResponse.fromMap(Map<String, dynamic> json) => UGoldOrderResponse(
    id: json["id"] ?? "",
    idempotencyKey: json["idempotencyKey"],
    status: TagGoldOrderStatus.values.firstWhereOrNull((TagGoldOrderStatus e) => e.number == json["status"]),
    side: TagGoldOrderSide.values.firstWhereOrNull((TagGoldOrderSide e) => e.number == json["side"]),
    baseAsset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["baseAsset"]),
    quoteAsset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["quoteAsset"]),
    requestedBaseAmount: json["requestedBaseAmount"] == null ? null : (json["requestedBaseAmount"] as num).toDouble(),
    requestedQuoteAmount: json["requestedQuoteAmount"] == null ? null : (json["requestedQuoteAmount"] as num).toDouble(),
    dealtBaseAmount: json["dealtBaseAmount"] == null ? null : (json["dealtBaseAmount"] as num).toDouble(),
    dealtQuoteAmount: json["dealtQuoteAmount"] == null ? null : (json["dealtQuoteAmount"] as num).toDouble(),
    effectivePrice: json["effectivePrice"] == null ? null : (json["effectivePrice"] as num).toDouble(),
    baseUnitPrice: json["baseUnitPrice"] == null ? null : (json["baseUnitPrice"] as num).toDouble(),
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    fees: json["fees"] == null ? <UGoldOrderFeeResponse>[] : List<UGoldOrderFeeResponse>.from(json["fees"]!.map((dynamic x) => UGoldOrderFeeResponse.fromMap(x))),
    transactions: json["transactions"] == null
        ? <UGoldOrderTransactionResponse>[]
        : List<UGoldOrderTransactionResponse>.from(json["transactions"]!.map((dynamic x) => UGoldOrderTransactionResponse.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "idempotencyKey": idempotencyKey,
    "status": status?.number,
    "side": side?.number,
    "baseAsset": baseAsset?.number,
    "quoteAsset": quoteAsset?.number,
    "requestedBaseAmount": requestedBaseAmount,
    "requestedQuoteAmount": requestedQuoteAmount,
    "dealtBaseAmount": dealtBaseAmount,
    "dealtQuoteAmount": dealtQuoteAmount,
    "effectivePrice": effectivePrice,
    "baseUnitPrice": baseUnitPrice,
    "createdAt": createdAt?.toIso8601String(),
    "fees": List<dynamic>.from(fees.map((UGoldOrderFeeResponse x) => x.toMap())),
    "transactions": List<dynamic>.from(transactions.map((UGoldOrderTransactionResponse x) => x.toMap())),
  };
}

class UGoldOrderListResponse {
  final List<UGoldOrderResponse> items;
  final String? nextCursor;

  UGoldOrderListResponse({required this.items, this.nextCursor});

  factory UGoldOrderListResponse.fromJson(String str) => UGoldOrderListResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldOrderListResponse.fromMap(Map<String, dynamic> json) => UGoldOrderListResponse(
    items: json["items"] == null ? <UGoldOrderResponse>[] : List<UGoldOrderResponse>.from(json["items"]!.map((dynamic x) => UGoldOrderResponse.fromMap(x))),
    nextCursor: json["nextCursor"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "items": List<dynamic>.from(items.map((UGoldOrderResponse x) => x.toMap())),
    "nextCursor": nextCursor,
  };
}

class UGoldBalanceResponse {
  final TagGoldAsset? asset;
  final String assetCode;
  final double? balance;
  final bool locked;

  UGoldBalanceResponse({required this.assetCode, required this.locked, this.asset, this.balance});

  factory UGoldBalanceResponse.fromJson(String str) => UGoldBalanceResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldBalanceResponse.fromMap(Map<String, dynamic> json) => UGoldBalanceResponse(
    asset: TagGoldAsset.values.firstWhereOrNull((TagGoldAsset e) => e.number == json["asset"]),
    assetCode: json["assetCode"] ?? "",
    balance: json["balance"] == null ? null : (json["balance"] as num).toDouble(),
    locked: json["locked"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "asset": asset?.number,
    "assetCode": assetCode,
    "balance": balance,
    "locked": locked,
  };
}

class UGoldTransactionResponse {
  final String id;
  final String? idempotencyKey;
  final DateTime? createdAt;
  final List<UGoldWalletEntryResponse> entries;
  final String? detail;

  UGoldTransactionResponse({required this.id, required this.entries, this.idempotencyKey, this.createdAt, this.detail});

  factory UGoldTransactionResponse.fromJson(String str) => UGoldTransactionResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldTransactionResponse.fromMap(Map<String, dynamic> json) => UGoldTransactionResponse(
    id: json["id"] ?? "",
    idempotencyKey: json["idempotencyKey"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    entries: json["entries"] == null
        ? <UGoldWalletEntryResponse>[]
        : List<UGoldWalletEntryResponse>.from(json["entries"]!.map((dynamic x) => UGoldWalletEntryResponse.fromMap(x))),
    detail: json["detail"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "idempotencyKey": idempotencyKey,
    "createdAt": createdAt?.toIso8601String(),
    "entries": List<dynamic>.from(entries.map((UGoldWalletEntryResponse x) => x.toMap())),
    "detail": detail,
  };
}

class UGoldTransactionListResponse {
  final List<UGoldTransactionResponse> items;
  final String? nextCursor;

  UGoldTransactionListResponse({required this.items, this.nextCursor});

  factory UGoldTransactionListResponse.fromJson(String str) => UGoldTransactionListResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldTransactionListResponse.fromMap(Map<String, dynamic> json) => UGoldTransactionListResponse(
    items: json["items"] == null
        ? <UGoldTransactionResponse>[]
        : List<UGoldTransactionResponse>.from(json["items"]!.map((dynamic x) => UGoldTransactionResponse.fromMap(x))),
    nextCursor: json["nextCursor"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "items": List<dynamic>.from(items.map((UGoldTransactionResponse x) => x.toMap())),
    "nextCursor": nextCursor,
  };
}

// resetsAt / windowStart / windowEnd are local times without offset; read them in the timezone of the parent response.
class UGoldTradeLimitResponse {
  final String? type;
  final String? asset;
  final double? maxVolume;
  final double? usedVolume;
  final double? remainingVolume;
  final String? interval;
  final String? resetsAt;
  final TagGoldOrderSide? side;
  final String? windowStart;
  final String? windowEnd;

  UGoldTradeLimitResponse({
    this.type,
    this.asset,
    this.maxVolume,
    this.usedVolume,
    this.remainingVolume,
    this.interval,
    this.resetsAt,
    this.side,
    this.windowStart,
    this.windowEnd,
  });

  factory UGoldTradeLimitResponse.fromJson(String str) => UGoldTradeLimitResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldTradeLimitResponse.fromMap(Map<String, dynamic> json) => UGoldTradeLimitResponse(
    type: json["type"],
    asset: json["asset"],
    maxVolume: json["maxVolume"] == null ? null : (json["maxVolume"] as num).toDouble(),
    usedVolume: json["usedVolume"] == null ? null : (json["usedVolume"] as num).toDouble(),
    remainingVolume: json["remainingVolume"] == null ? null : (json["remainingVolume"] as num).toDouble(),
    interval: json["interval"],
    resetsAt: json["resetsAt"],
    side: TagGoldOrderSide.values.firstWhereOrNull((TagGoldOrderSide e) => e.number == json["side"]),
    windowStart: json["windowStart"],
    windowEnd: json["windowEnd"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "type": type,
    "asset": asset,
    "maxVolume": maxVolume,
    "usedVolume": usedVolume,
    "remainingVolume": remainingVolume,
    "interval": interval,
    "resetsAt": resetsAt,
    "side": side?.number,
    "windowStart": windowStart,
    "windowEnd": windowEnd,
  };
}

class UGoldTradeLimitsResponse {
  final String? timezone;
  final String? currentTime;
  final List<UGoldTradeLimitResponse> items;
  final List<UGoldTradeLimitResponse> currentLimits;

  UGoldTradeLimitsResponse({required this.items, required this.currentLimits, this.timezone, this.currentTime});

  factory UGoldTradeLimitsResponse.fromJson(String str) => UGoldTradeLimitsResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldTradeLimitsResponse.fromMap(Map<String, dynamic> json) => UGoldTradeLimitsResponse(
    timezone: json["timezone"],
    currentTime: json["currentTime"],
    items: json["items"] == null
        ? <UGoldTradeLimitResponse>[]
        : List<UGoldTradeLimitResponse>.from(json["items"]!.map((dynamic x) => UGoldTradeLimitResponse.fromMap(x))),
    currentLimits: json["currentLimits"] == null
        ? <UGoldTradeLimitResponse>[]
        : List<UGoldTradeLimitResponse>.from(json["currentLimits"]!.map((dynamic x) => UGoldTradeLimitResponse.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "timezone": timezone,
    "currentTime": currentTime,
    "items": List<dynamic>.from(items.map((UGoldTradeLimitResponse x) => x.toMap())),
    "currentLimits": List<dynamic>.from(currentLimits.map((UGoldTradeLimitResponse x) => x.toMap())),
  };
}

class UGoldCreditLimitResponse {
  final String? interval;
  final double? limit;
  final double? used;
  final double? remaining;
  final String? resetsAt;

  UGoldCreditLimitResponse({this.interval, this.limit, this.used, this.remaining, this.resetsAt});

  factory UGoldCreditLimitResponse.fromJson(String str) => UGoldCreditLimitResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldCreditLimitResponse.fromMap(Map<String, dynamic> json) => UGoldCreditLimitResponse(
    interval: json["interval"],
    limit: json["limit"] == null ? null : (json["limit"] as num).toDouble(),
    used: json["used"] == null ? null : (json["used"] as num).toDouble(),
    remaining: json["remaining"] == null ? null : (json["remaining"] as num).toDouble(),
    resetsAt: json["resetsAt"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "interval": interval,
    "limit": limit,
    "used": used,
    "remaining": remaining,
    "resetsAt": resetsAt,
  };
}

class UGoldCreditFacilityResponse {
  final String? type;
  final String? asset;
  final double? creditUsed;
  final double? availableCredit;
  final List<UGoldCreditLimitResponse> limits;

  UGoldCreditFacilityResponse({required this.limits, this.type, this.asset, this.creditUsed, this.availableCredit});

  factory UGoldCreditFacilityResponse.fromJson(String str) => UGoldCreditFacilityResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldCreditFacilityResponse.fromMap(Map<String, dynamic> json) => UGoldCreditFacilityResponse(
    type: json["type"],
    asset: json["asset"],
    creditUsed: json["creditUsed"] == null ? null : (json["creditUsed"] as num).toDouble(),
    availableCredit: json["availableCredit"] == null ? null : (json["availableCredit"] as num).toDouble(),
    limits: json["limits"] == null
        ? <UGoldCreditLimitResponse>[]
        : List<UGoldCreditLimitResponse>.from(json["limits"]!.map((dynamic x) => UGoldCreditLimitResponse.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "type": type,
    "asset": asset,
    "creditUsed": creditUsed,
    "availableCredit": availableCredit,
    "limits": List<dynamic>.from(limits.map((UGoldCreditLimitResponse x) => x.toMap())),
  };
}

class UGoldAssetBalanceResponse {
  final String? asset;
  final double? balance;
  final double? availableToTrade;

  UGoldAssetBalanceResponse({this.asset, this.balance, this.availableToTrade});

  factory UGoldAssetBalanceResponse.fromJson(String str) => UGoldAssetBalanceResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldAssetBalanceResponse.fromMap(Map<String, dynamic> json) => UGoldAssetBalanceResponse(
    asset: json["asset"],
    balance: json["balance"] == null ? null : (json["balance"] as num).toDouble(),
    availableToTrade: json["availableToTrade"] == null ? null : (json["availableToTrade"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "asset": asset,
    "balance": balance,
    "availableToTrade": availableToTrade,
  };
}

class UGoldCreditFacilitiesResponse {
  final String? timezone;
  final String? currentTime;
  final List<UGoldCreditFacilityResponse> items;
  final List<UGoldAssetBalanceResponse> balances;

  UGoldCreditFacilitiesResponse({required this.items, required this.balances, this.timezone, this.currentTime});

  factory UGoldCreditFacilitiesResponse.fromJson(String str) => UGoldCreditFacilitiesResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldCreditFacilitiesResponse.fromMap(Map<String, dynamic> json) => UGoldCreditFacilitiesResponse(
    timezone: json["timezone"],
    currentTime: json["currentTime"],
    items: json["items"] == null
        ? <UGoldCreditFacilityResponse>[]
        : List<UGoldCreditFacilityResponse>.from(json["items"]!.map((dynamic x) => UGoldCreditFacilityResponse.fromMap(x))),
    balances: json["balances"] == null
        ? <UGoldAssetBalanceResponse>[]
        : List<UGoldAssetBalanceResponse>.from(json["balances"]!.map((dynamic x) => UGoldAssetBalanceResponse.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "timezone": timezone,
    "currentTime": currentTime,
    "items": List<dynamic>.from(items.map((UGoldCreditFacilityResponse x) => x.toMap())),
    "balances": List<dynamic>.from(balances.map((UGoldAssetBalanceResponse x) => x.toMap())),
  };
}

// rawToken is returned only by createApiToken and never again; store it at that moment or it is lost.
class UGoldApiTokenResponse {
  final String id;
  final String? tokenPrefix;
  final String? label;
  final List<String> scopes;
  final List<String> ipWhitelist;
  final bool active;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? rawToken;

  UGoldApiTokenResponse({
    required this.id,
    required this.scopes,
    required this.ipWhitelist,
    required this.active,
    this.tokenPrefix,
    this.label,
    this.expiresAt,
    this.createdAt,
    this.rawToken,
  });

  factory UGoldApiTokenResponse.fromJson(String str) => UGoldApiTokenResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGoldApiTokenResponse.fromMap(Map<String, dynamic> json) => UGoldApiTokenResponse(
    id: json["id"] ?? "",
    tokenPrefix: json["tokenPrefix"],
    label: json["label"],
    scopes: json["scopes"] == null ? <String>[] : List<String>.from(json["scopes"]!.map((dynamic x) => x)),
    ipWhitelist: json["ipWhitelist"] == null ? <String>[] : List<String>.from(json["ipWhitelist"]!.map((dynamic x) => x)),
    active: json["active"] ?? false,
    expiresAt: json["expiresAt"] == null ? null : DateTime.parse(json["expiresAt"]),
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    rawToken: json["rawToken"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tokenPrefix": tokenPrefix,
    "label": label,
    "scopes": List<dynamic>.from(scopes.map((String x) => x)),
    "ipWhitelist": List<dynamic>.from(ipWhitelist.map((String x) => x)),
    "active": active,
    "expiresAt": expiresAt?.toIso8601String(),
    "createdAt": createdAt?.toIso8601String(),
    "rawToken": rawToken,
  };
}
