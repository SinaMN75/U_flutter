part of "../data.dart";

class UExchangeRateReadRatesParams {
  final String base;

  UExchangeRateReadRatesParams({this.base = "irr"});

  factory UExchangeRateReadRatesParams.fromJson(String str) => UExchangeRateReadRatesParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UExchangeRateReadRatesParams.fromMap(Map<String, dynamic> json) => UExchangeRateReadRatesParams(base: json["base"] ?? "irr");

  Map<String, dynamic> toMap() => <String, dynamic>{"base": base};
}

class UExchangeRateReadHistoryParams {
  final String code;
  final int days;

  UExchangeRateReadHistoryParams({required this.code, this.days = 30});

  factory UExchangeRateReadHistoryParams.fromJson(String str) => UExchangeRateReadHistoryParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UExchangeRateReadHistoryParams.fromMap(Map<String, dynamic> json) => UExchangeRateReadHistoryParams(code: json["code"], days: json["days"] ?? 30);

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "days": days,
  };
}
