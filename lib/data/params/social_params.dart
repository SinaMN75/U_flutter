part of "../data.dart";

class UReportCreateParams {
  UReportCreateParams({
    required this.targetId,
    required this.tags,
    this.reason,
  });

  factory UReportCreateParams.fromJson(String str) => UReportCreateParams.fromMap(json.decode(str));

  factory UReportCreateParams.fromMap(Map<String, dynamic> json) => UReportCreateParams(
    targetId: json["targetId"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    reason: json["reason"],
  );

  final String targetId;
  final List<int> tags;
  final String? reason;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "targetId": targetId,
    "tags": tags,
    "reason": reason,
  };
}

class UReportUpdateParams {
  UReportUpdateParams({
    required this.id,
    this.note,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UReportUpdateParams.fromJson(String str) => UReportUpdateParams.fromMap(json.decode(str));

  factory UReportUpdateParams.fromMap(Map<String, dynamic> json) => UReportUpdateParams(
    id: json["id"],
    note: json["note"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String id;
  final String? note;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "note": note,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UReportReadParams {
  UReportReadParams({
    this.targetId,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UReportReadParams.fromJson(String str) => UReportReadParams.fromMap(json.decode(str));

  factory UReportReadParams.fromMap(Map<String, dynamic> json) => UReportReadParams(
    targetId: json["targetId"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UReportSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final String? targetId;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UReportSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "targetId": targetId,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}
