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
  UOrganizationJson({this.detail1, this.detail2, this.commissionPercent = 0, this.members = const <UOrganizationMember>[], this.settlements = const <UOrganizationSettlement>[], this.logoUrl, this.address, this.phoneNumber, this.nationalId, this.economicCode, this.vatPercent = 0, this.taxServiceId, this.plan});

  factory UOrganizationJson.fromMap(Map<String, dynamic> json) => UOrganizationJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    commissionPercent: json["commissionPercent"] == null ? 0 : (json["commissionPercent"] as num).toDouble(),
    members: json["members"] == null ? <UOrganizationMember>[] : List<UOrganizationMember>.from(json["members"]!.map((dynamic x) => UOrganizationMember.fromMap(x))),
    settlements: json["settlements"] == null ? <UOrganizationSettlement>[] : List<UOrganizationSettlement>.from(json["settlements"]!.map((dynamic x) => UOrganizationSettlement.fromMap(x))),
    logoUrl: json["logoUrl"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    nationalId: json["nationalId"],
    economicCode: json["economicCode"],
    vatPercent: json["vatPercent"] == null ? 0 : (json["vatPercent"] as num).toDouble(),
    taxServiceId: json["taxServiceId"],
    plan: json["plan"] == null ? null : UOrganizationPlan.fromMap(json["plan"]),
  );

  final String? detail1;
  final String? detail2;
  final double commissionPercent;
  final List<UOrganizationMember> members;
  final List<UOrganizationSettlement> settlements;
  final String? logoUrl;
  final String? address;
  final String? phoneNumber;
  final String? nationalId;
  final String? economicCode;
  final double vatPercent;
  final String? taxServiceId;
  final UOrganizationPlan? plan;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "commissionPercent": commissionPercent,
    "members": members.map((UOrganizationMember x) => x.toMap()).toList(),
    "settlements": settlements.map((UOrganizationSettlement x) => x.toMap()).toList(),
    "logoUrl": logoUrl,
    "address": address,
    "phoneNumber": phoneNumber,
    "nationalId": nationalId,
    "economicCode": economicCode,
    "vatPercent": vatPercent,
    "taxServiceId": taxServiceId,
    "plan": plan?.toMap(),
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

class UOrganizationPlan {
  UOrganizationPlan({
    this.title,
    this.maxPlaces,
    this.maxRooms,
    this.maxBeds,
    this.expiresAt,
  });

  factory UOrganizationPlan.fromMap(Map<String, dynamic> json) => UOrganizationPlan(
    title: json["title"],
    maxPlaces: json["maxPlaces"] == null ? null : (json["maxPlaces"] as num).toInt(),
    maxRooms: json["maxRooms"] == null ? null : (json["maxRooms"] as num).toInt(),
    maxBeds: json["maxBeds"] == null ? null : (json["maxBeds"] as num).toInt(),
    expiresAt: json["expiresAt"] == null ? null : DateTime.parse(json["expiresAt"]),
  );

  final String? title;
  final int? maxPlaces;
  final int? maxRooms;
  final int? maxBeds;
  final DateTime? expiresAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "maxPlaces": maxPlaces,
    "maxRooms": maxRooms,
    "maxBeds": maxBeds,
    "expiresAt": expiresAt?.toIso8601String(),
  };
}

class UStaffShiftResponse {
  UStaffShiftResponse({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.userId,
    required this.organizationId,
    this.tags = const <int>[],
    this.placeId,
    this.userName,
    this.checkedInAt,
    this.checkedOutAt,
    this.detail1,
  });

  factory UStaffShiftResponse.fromMap(Map<String, dynamic> json) => UStaffShiftResponse(
    id: json["id"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    startAt: DateTime.parse(json["startAt"]),
    endAt: DateTime.parse(json["endAt"]),
    userId: json["userId"] ?? "",
    organizationId: json["organizationId"] ?? "",
    placeId: json["placeId"],
    userName: json["userName"],
    checkedInAt: json["jsonData"]?["checkedInAt"] == null ? null : DateTime.parse(json["jsonData"]?["checkedInAt"]),
    checkedOutAt: json["jsonData"]?["checkedOutAt"] == null ? null : DateTime.parse(json["jsonData"]?["checkedOutAt"]),
    detail1: json["jsonData"]?["detail1"],
  );

  final String id;
  final List<int> tags;
  final DateTime startAt;
  final DateTime endAt;
  final String userId;
  final String organizationId;
  final String? placeId;
  final String? userName;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? detail1;
}

class UStaffTaskResponse {
  UStaffTaskResponse({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.organizationId,
    this.tags = const <int>[],
    this.placeId,
    this.assigneeId,
    this.assigneeName,
    this.requesterName,
    this.dueDate,
    this.description,
    this.location,
    this.doneAt,
    this.doneNote,
    this.cost,
  });

  factory UStaffTaskResponse.fromMap(Map<String, dynamic> json) => UStaffTaskResponse(
    id: json["id"] ?? "",
    createdAt: DateTime.parse(json["createdAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"] ?? "",
    organizationId: json["organizationId"] ?? "",
    placeId: json["placeId"],
    assigneeId: json["assigneeId"],
    assigneeName: json["assigneeName"],
    requesterName: json["requesterName"],
    dueDate: json["dueDate"] == null ? null : DateTime.parse(json["dueDate"]),
    description: json["jsonData"]?["description"],
    location: json["jsonData"]?["location"],
    doneAt: json["jsonData"]?["doneAt"] == null ? null : DateTime.parse(json["jsonData"]?["doneAt"]),
    doneNote: json["jsonData"]?["doneNote"],
    cost: json["jsonData"]?["cost"] == null ? null : (json["jsonData"]?["cost"] as num).toDouble(),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String title;
  final String organizationId;
  final String? placeId;
  final String? assigneeId;
  final String? assigneeName;
  final String? requesterName;
  final DateTime? dueDate;
  final String? description;
  final String? location;
  final DateTime? doneAt;
  final String? doneNote;
  final double? cost;
}

class UOrganizationCustomerResponse {
  UOrganizationCustomerResponse({
    required this.id,
    required this.userId,
    required this.organizationId,
    this.tags = const <int>[],
    this.userName,
    this.phoneNumber,
    this.nationalCode,
    this.note,
  });

  factory UOrganizationCustomerResponse.fromMap(Map<String, dynamic> json) => UOrganizationCustomerResponse(
    id: json["id"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    userId: json["userId"] ?? "",
    organizationId: json["organizationId"] ?? "",
    userName: json["userName"],
    phoneNumber: json["phoneNumber"],
    nationalCode: json["nationalCode"],
    note: json["jsonData"]?["note"],
  );

  final String id;
  final List<int> tags;
  final String userId;
  final String organizationId;
  final String? userName;
  final String? phoneNumber;
  final String? nationalCode;
  final String? note;
}

class UActivityLogResponse {
  UActivityLogResponse({
    required this.id,
    required this.createdAt,
    required this.path,
    this.tags = const <int>[],
    this.creatorId,
    this.organizationId,
    this.entityId,
    this.userName,
    this.body,
  });

  factory UActivityLogResponse.fromMap(Map<String, dynamic> json) => UActivityLogResponse(
    id: json["id"] ?? "",
    createdAt: DateTime.parse(json["createdAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    path: json["path"] ?? "",
    creatorId: json["creatorId"],
    organizationId: json["organizationId"],
    entityId: json["entityId"],
    userName: json["jsonData"]?["userName"],
    body: json["jsonData"]?["body"],
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String path;
  final String? creatorId;
  final String? organizationId;
  final String? entityId;
  final String? userName;
  final String? body;
}
