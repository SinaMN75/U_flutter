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

class UIdListParams {
  UIdListParams({
    required this.ids,
  });

  factory UIdListParams.fromJson(String str) => UIdListParams.fromMap(
    json.decode(str),
  );

  factory UIdListParams.fromMap(Map<String, dynamic> json) => UIdListParams(
    ids: List<String>.from(json["ids"]!.map((dynamic x) => x)),
  );
  final List<String> ids;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "ids": List<dynamic>.from(ids.map((String x) => x)),
  };
}

class UIdStringParams {
  final String id;

  UIdStringParams({
    required this.id,
  });

  factory UIdStringParams.fromJson(String str) => UIdStringParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UIdStringParams.fromMap(Map<String, dynamic> json) => UIdStringParams(
    id: json["id"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
  };
}
