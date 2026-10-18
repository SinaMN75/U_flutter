part of "../data.dart";

class UDashboardRangeParams {
  final String? organizationId;
  final DateTime? fromDate;
  final DateTime? toDate;

  UDashboardRangeParams({this.organizationId, this.fromDate, this.toDate});

  factory UDashboardRangeParams.fromJson(String str) => UDashboardRangeParams.fromMap(json.decode(str));

  factory UDashboardRangeParams.fromMap(Map<String, dynamic> json) => UDashboardRangeParams(
    fromDate: json["fromDate"] == null ? null : DateTime.parse(json["fromDate"]),
    toDate: json["toDate"] == null ? null : DateTime.parse(json["toDate"]),
  );

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}
