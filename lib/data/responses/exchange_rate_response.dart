part of "../data.dart";

class UExchangeRateMarketResponse {
  final List<UExchangeRateItemResponse> items;
  final DateTime fetchedAt;
  final bool stale;

  UExchangeRateMarketResponse({required this.items, required this.fetchedAt, this.stale = false});

  factory UExchangeRateMarketResponse.fromJson(String str) => UExchangeRateMarketResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UExchangeRateMarketResponse.fromMap(Map<String, dynamic> json) => UExchangeRateMarketResponse(
    items: json["items"] == null ? <UExchangeRateItemResponse>[] : List<UExchangeRateItemResponse>.from(json["items"].map((dynamic x) => UExchangeRateItemResponse.fromMap(x))),
    fetchedAt: DateTime.parse(json["fetchedAt"]),
    stale: json["stale"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "items": List<dynamic>.from(items.map((UExchangeRateItemResponse x) => x.toMap())),
    "fetchedAt": fetchedAt.toIso8601String(),
    "stale": stale,
  };
}

class UExchangeRateItemResponse {
  final String code;
  final TagExchangeRateGroup? group;
  final String title;

  /// Currency the price is in ("IRR", "USD"); empty for an index.
  final String unit;

  /// How many units of the item the price is for (100 for JPY).
  final int per;
  final double price;
  final double? high;
  final double? low;
  final double change;
  final double changePercent;

  /// Value of one unit in rials; null when it can't be priced in rials (an index).
  final double? irrValue;
  final DateTime? updatedAt;

  UExchangeRateItemResponse({
    required this.code,
    required this.title,
    required this.unit,
    required this.price,
    this.group,
    this.per = 1,
    this.high,
    this.low,
    this.change = 0,
    this.changePercent = 0,
    this.irrValue,
    this.updatedAt,
  });

  factory UExchangeRateItemResponse.fromJson(String str) => UExchangeRateItemResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UExchangeRateItemResponse.fromMap(Map<String, dynamic> json) => UExchangeRateItemResponse(
    code: json["code"] ?? "",
    group: TagExchangeRateGroup.values.firstWhereOrNull((TagExchangeRateGroup e) => e.number == json["group"]),
    title: json["title"] ?? "",
    unit: json["unit"] ?? "",
    per: json["per"] ?? 1,
    price: (json["price"] as num? ?? 0).toDouble(),
    high: json["high"] == null ? null : (json["high"] as num).toDouble(),
    low: json["low"] == null ? null : (json["low"] as num).toDouble(),
    change: (json["change"] as num? ?? 0).toDouble(),
    changePercent: (json["changePercent"] as num? ?? 0).toDouble(),
    irrValue: json["irrValue"] == null ? null : (json["irrValue"] as num).toDouble(),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "group": group?.number,
    "title": title,
    "unit": unit,
    "per": per,
    "price": price,
    "high": high,
    "low": low,
    "change": change,
    "changePercent": changePercent,
    "irrValue": irrValue,
    "updatedAt": updatedAt?.toIso8601String(),
  };
}

class UExchangeRateRatesResponse {
  final String base;
  final String baseName;
  final List<UExchangeRateRateResponse> rates;
  final DateTime fetchedAt;
  final bool stale;

  UExchangeRateRatesResponse({required this.base, required this.baseName, required this.rates, required this.fetchedAt, this.stale = false});

  factory UExchangeRateRatesResponse.fromJson(String str) => UExchangeRateRatesResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UExchangeRateRatesResponse.fromMap(Map<String, dynamic> json) => UExchangeRateRatesResponse(
    base: json["base"] ?? "",
    baseName: json["baseName"] ?? "",
    rates: json["rates"] == null ? <UExchangeRateRateResponse>[] : List<UExchangeRateRateResponse>.from(json["rates"].map((dynamic x) => UExchangeRateRateResponse.fromMap(x))),
    fetchedAt: DateTime.parse(json["fetchedAt"]),
    stale: json["stale"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "base": base,
    "baseName": baseName,
    "rates": List<dynamic>.from(rates.map((UExchangeRateRateResponse x) => x.toMap())),
    "fetchedAt": fetchedAt.toIso8601String(),
    "stale": stale,
  };
}

class UExchangeRateRateResponse {
  final String code;
  final String name;

  /// Price of one unit of [code] in the base currency.
  final double price;
  final double? changePercent;

  /// True when the price is the Iranian free-market rate rather than the international one.
  final bool market;

  UExchangeRateRateResponse({required this.code, required this.name, required this.price, this.changePercent, this.market = false});

  factory UExchangeRateRateResponse.fromJson(String str) => UExchangeRateRateResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UExchangeRateRateResponse.fromMap(Map<String, dynamic> json) => UExchangeRateRateResponse(
    code: json["code"] ?? "",
    name: json["name"] ?? "",
    price: (json["price"] as num? ?? 0).toDouble(),
    changePercent: json["changePercent"] == null ? null : (json["changePercent"] as num).toDouble(),
    market: json["market"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "name": name,
    "price": price,
    "changePercent": changePercent,
    "market": market,
  };
}

class UExchangeRateHistoryResponse {
  final String code;
  final String unit;
  final List<UExchangeRateCandleResponse> items;
  final DateTime fetchedAt;
  final bool stale;

  UExchangeRateHistoryResponse({required this.code, required this.unit, required this.items, required this.fetchedAt, this.stale = false});

  factory UExchangeRateHistoryResponse.fromJson(String str) => UExchangeRateHistoryResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UExchangeRateHistoryResponse.fromMap(Map<String, dynamic> json) => UExchangeRateHistoryResponse(
    code: json["code"] ?? "",
    unit: json["unit"] ?? "",
    items: json["items"] == null ? <UExchangeRateCandleResponse>[] : List<UExchangeRateCandleResponse>.from(json["items"].map((dynamic x) => UExchangeRateCandleResponse.fromMap(x))),
    fetchedAt: DateTime.parse(json["fetchedAt"]),
    stale: json["stale"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "unit": unit,
    "items": List<dynamic>.from(items.map((UExchangeRateCandleResponse x) => x.toMap())),
    "fetchedAt": fetchedAt.toIso8601String(),
    "stale": stale,
  };
}

class UExchangeRateCandleResponse {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;

  UExchangeRateCandleResponse({required this.date, required this.open, required this.high, required this.low, required this.close});

  factory UExchangeRateCandleResponse.fromJson(String str) => UExchangeRateCandleResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UExchangeRateCandleResponse.fromMap(Map<String, dynamic> json) => UExchangeRateCandleResponse(
    date: DateTime.parse(json["date"]),
    open: (json["open"] as num).toDouble(),
    high: (json["high"] as num).toDouble(),
    low: (json["low"] as num).toDouble(),
    close: (json["close"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "date": date.toIso8601String(),
    "open": open,
    "high": high,
    "low": low,
    "close": close,
  };
}
