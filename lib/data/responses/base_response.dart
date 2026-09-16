part of "../data.dart";

class UEmptyResponse {
  UEmptyResponse({
    required this.status,
    required this.message,
  });

  factory UEmptyResponse.fromJson(String str) {
    final Map<String, dynamic> jsonMap = json.decode(str);
    return UEmptyResponse(
      status: jsonMap["status"] ?? 0,
      message: jsonMap["message"] ?? "",
    );
  }

  final int status;
  final String message;
}

class UResponse<T> {
  UResponse({
    required this.result,
    required this.status,
    required this.message,
    this.pageSize = 0,
    this.pageCount = 0,
    this.totalCount = 0,
  });

  factory UResponse.fromJson(String str, T Function(dynamic) fromMapT) {
    final Map<String, dynamic> jsonMap = json.decode(str);
    final dynamic rawResult = jsonMap["result"];
    final T? parsedResult = rawResult == null ? null : fromMapT(rawResult);
    return UResponse<T>(
      result: parsedResult,
      status: jsonMap["status"] ?? 0,
      pageSize: jsonMap["pageSize"] ?? 0,
      pageCount: jsonMap["pageCount"] ?? 0,
      totalCount: jsonMap["totalCount"] ?? 0,
      message: jsonMap["message"] ?? "",
    );
  }

  final T? result;
  final int status;
  final int pageSize;
  final int pageCount;
  final int totalCount;
  final String message;
}

class UBaseJson {
  UBaseJson({
    this.detail1,
    this.detail2,
  });

  factory UBaseJson.fromJson(String str) => UBaseJson.fromMap(json.decode(str));

  factory UBaseJson.fromMap(Map<String, dynamic> json) => UBaseJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UKeyValueData {
  final String key;
  final String value;

  UKeyValueData({
    this.key = "",
    this.value = "",
  });

  factory UKeyValueData.fromJson(String str) => UKeyValueData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UKeyValueData.fromMap(Map<String, dynamic> json) => UKeyValueData(
    key: json["key"] ?? "",
    value: json["value"] ?? "",
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "key": key,
    "value": value,
  };
}
