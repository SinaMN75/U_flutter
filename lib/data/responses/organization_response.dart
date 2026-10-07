part of "../data.dart";

class UOrganizationMember {
  UOrganizationMember({required this.userId, this.permissions = const <int>[]});

  factory UOrganizationMember.fromMap(Map<String, dynamic> json) => UOrganizationMember(
    userId: json["userId"] as String,
    permissions: json["permissions"] == null ? <int>[] : List<int>.from(json["permissions"]!.map((dynamic x) => x)),
  );

  final String userId;
  final List<int> permissions;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "permissions": permissions,
  };
}

class UOrganizationJson {
  UOrganizationJson({this.detail1, this.detail2, this.commissionPercent = 0, this.members = const <UOrganizationMember>[], this.settlements = const <UOrganizationSettlement>[]});

  factory UOrganizationJson.fromMap(Map<String, dynamic> json) => UOrganizationJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    commissionPercent: json["commissionPercent"] == null ? 0 : (json["commissionPercent"] as num).toDouble(),
    members: json["members"] == null ? <UOrganizationMember>[] : List<UOrganizationMember>.from(json["members"]!.map((dynamic x) => UOrganizationMember.fromMap(x))),
    settlements: json["settlements"] == null ? <UOrganizationSettlement>[] : List<UOrganizationSettlement>.from(json["settlements"]!.map((dynamic x) => UOrganizationSettlement.fromMap(x))),
  );

  final String? detail1;
  final String? detail2;
  final double commissionPercent;
  final List<UOrganizationMember> members;
  final List<UOrganizationSettlement> settlements;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "commissionPercent": commissionPercent,
    "members": members.map((UOrganizationMember x) => x.toMap()).toList(),
    "settlements": settlements.map((UOrganizationSettlement x) => x.toMap()).toList(),
  };
}

class UOrganizationResponse {
  UOrganizationResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.ownerId,
    this.creatorId,
    this.adminUserIds = const <String>[],
    this.balance = 0,
  });

  factory UOrganizationResponse.fromMap(Map<String, dynamic> json) => UOrganizationResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UOrganizationJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"] as String,
    ownerId: json["ownerId"] as String,
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    balance: json["balance"] == null ? 0 : (json["balance"] as num).toDouble(),
  );

  final String id;
  final DateTime createdAt;
  final UOrganizationJson jsonData;
  final List<int> tags;
  final String title;
  final String ownerId;
  final String? creatorId;
  final List<String> adminUserIds;
  final double balance;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "title": title,
    "ownerId": ownerId,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds,
    "balance": balance,
  };
}

class UOrganizationSettlement {
  UOrganizationSettlement({required this.id, required this.amount, required this.iban, required this.createdAt, this.processedAt, this.approved, this.note});

  factory UOrganizationSettlement.fromMap(Map<String, dynamic> json) => UOrganizationSettlement(
    id: json["id"] as String,
    amount: json["amount"] == null ? 0 : (json["amount"] as num).toDouble(),
    iban: json["iban"] ?? "",
    createdAt: DateTime.parse(json["createdAt"]),
    processedAt: json["processedAt"] == null ? null : DateTime.parse(json["processedAt"]),
    approved: json["approved"],
    note: json["note"],
  );

  final String id;
  final double amount;
  final String iban;
  final DateTime createdAt;
  final DateTime? processedAt;
  final bool? approved;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "amount": amount,
    "iban": iban,
    "createdAt": createdAt.toIso8601String(),
    "processedAt": processedAt?.toIso8601String(),
    "approved": approved,
    "note": note,
  };
}
