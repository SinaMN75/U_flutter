part of "../data.dart";

class UReportJson {
  UReportJson({
    this.note,
    this.detail1,
    this.detail2,
  });

  factory UReportJson.fromJson(String str) => UReportJson.fromMap(json.decode(str));

  factory UReportJson.fromMap(Map<String, dynamic> json) => UReportJson(
    note: json["note"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? note;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "note": note,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UReportResponse {
  UReportResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.targetId,
    this.creatorId,
    this.reason,
    this.creator,
    this.targetTitle,
  });

  factory UReportResponse.fromJson(String str) => UReportResponse.fromMap(json.decode(str));

  factory UReportResponse.fromMap(Map<String, dynamic> json) => UReportResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UReportJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    targetId: json["targetId"],
    reason: json["reason"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    targetTitle: json["targetTitle"],
  );

  final String id;
  final DateTime createdAt;
  final UReportJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String targetId;
  final String? reason;
  final UUserResponse? creator;

  /// Name of the reported store or product (staff only).
  final String? targetTitle;

  TagReport? get kind => TagReport.values.group(100).firstWhereOrNull((TagReport t) => tags.contains(t.number));

  TagReport? get status => TagReport.values.group(200).firstWhereOrNull((TagReport t) => tags.contains(t.number));

  TagReport? get reasonTag => TagReport.values.group(300).firstWhereOrNull((TagReport t) => tags.contains(t.number));

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "targetId": targetId,
    "reason": reason,
    "creator": creator?.toMap(),
    "targetTitle": targetTitle,
  };
}
