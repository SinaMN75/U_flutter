part of "../data.dart";

class URecentUserItem {
  final String id;
  final String displayName;
  final String? userName;
  final String? phoneNumber;
  final DateTime createdAt;

  URecentUserItem({
    required this.id,
    required this.displayName,
    required this.createdAt,
    this.userName,
    this.phoneNumber,
  });

  factory URecentUserItem.fromMap(Map<String, dynamic> json) => URecentUserItem(
    id: json["id"] as String,
    displayName: json["displayName"] ?? "",
    userName: json["userName"],
    phoneNumber: json["phoneNumber"],
    createdAt: DateTime.parse(json["createdAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "displayName": displayName,
    "userName": userName,
    "phoneNumber": phoneNumber,
    "createdAt": createdAt.toIso8601String(),
  };

  String toJson() => json.encode(toMap());

  factory URecentUserItem.fromJson(String str) => URecentUserItem.fromMap(json.decode(str));
}
