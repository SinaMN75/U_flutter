part of "../data.dart";

class UBankAccountResponse {
  final String? cardNumber;
  final List<int> tags;
  final String? id;
  final String? accountNumber;
  final String? iBanNumber;
  final String? bankName;
  final String? ownerName;
  final UBaseJson jsonData;
  final DateTime createdAt;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  UBankAccountResponse({
    required this.tags,
    required this.jsonData,
    required this.createdAt,
    required this.adminUserIds,
    this.cardNumber,
    this.id,
    this.accountNumber,
    this.bankName,
    this.ownerName,
    this.iBanNumber,
    this.creator,
    this.creatorId,
  });

  factory UBankAccountResponse.fromJson(String str) => UBankAccountResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBankAccountResponse.fromMap(Map<String, dynamic> json) => UBankAccountResponse(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    cardNumber: json["cardNumber"],
    accountNumber: json["accountNumber"],
    iBanNumber: json["iBanNumber"],
    bankName: json["bankName"],
    ownerName: json["ownerName"],
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    createdAt: DateTime.parse(json["createdAt"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "cardNumber": cardNumber,
    "accountNumber": accountNumber,
    "iBanNumber": iBanNumber,
    "bankName": bankName,
    "ownerName": ownerName,
    "jsonData": jsonData.toMap(),
    "createdAt": createdAt.toIso8601String(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}
