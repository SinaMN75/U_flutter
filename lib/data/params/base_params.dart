part of "../data.dart";

class UBaseParams {
  UBaseParams();

  factory UBaseParams.fromJson(String str) => UBaseParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBaseParams.fromMap(Map<String, dynamic> _) => UBaseParams();

  Map<String, dynamic> toMap() => <String, dynamic>{};
}

class UIdParams {
  UIdParams({
    required this.id,
    this.selectorArgs,
  });

  final String id;
  final dynamic selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "selectorArgs": selectorArgs?.toMap(),
  };

  factory UIdParams.fromMap(Map<String, dynamic> json) => UIdParams(
    id: json["id"],
    selectorArgs: json["selectorArgs"],
  );

  factory UIdParams.fromJson(String str) => UIdParams.fromMap(json.decode(str));
}
