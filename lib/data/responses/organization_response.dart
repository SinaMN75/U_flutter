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
  UOrganizationJson({this.detail1, this.detail2, this.commissionPercent = 0, this.members = const <UOrganizationMember>[], this.settlements = const <UOrganizationSettlement>[], this.logoUrl, this.address, this.phoneNumber, this.nationalId, this.economicCode, this.vatPercent = 0, this.taxServiceId, this.subscriptions = const <UOrganizationSubscription>[]});

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
    subscriptions: json["subscriptions"] == null ? <UOrganizationSubscription>[] : List<UOrganizationSubscription>.from(json["subscriptions"]!.map((dynamic x) => UOrganizationSubscription.fromMap(x))),
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
  final List<UOrganizationSubscription> subscriptions;

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
    "subscriptions": subscriptions.map((UOrganizationSubscription x) => x.toMap()).toList(),
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
    this.modules,
    this.subscriptionEndsAt,
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
    modules: json["modules"] == null ? null : List<int>.from(json["modules"]!.map((dynamic x) => x)),
    subscriptionEndsAt: json["subscriptionEndsAt"] == null ? null : DateTime.parse(json["subscriptionEndsAt"]),
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
  final List<int>? modules;
  final DateTime? subscriptionEndsAt;

  bool hasModule(TagModule m) => modules == null || modules!.contains(m.number);

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

class UPlanPrice {
  UPlanPrice({required this.months, required this.price});

  factory UPlanPrice.fromMap(Map<String, dynamic> json) => UPlanPrice(months: (json["months"] as num).toInt(), price: _num(json["price"]));

  final int months;
  final double price;

  Map<String, dynamic> toMap() => <String, dynamic>{"months": months, "price": price};
}

class UPlanLimit {
  UPlanLimit({required this.kind, required this.value});

  factory UPlanLimit.fromMap(Map<String, dynamic> json) => UPlanLimit(kind: (json["kind"] as num).toInt(), value: (json["value"] as num).toInt());

  final int kind;
  final int value;

  Map<String, dynamic> toMap() => <String, dynamic>{"kind": kind, "value": value};
}

class UOrganizationSubscription {
  UOrganizationSubscription({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.planId,
    this.modules = const <int>[],
    this.limits = const <UPlanLimit>[],
    this.months = 0,
    this.days = 0,
    this.trial = false,
    this.price = 0,
    this.credit = 0,
    this.paid = 0,
    this.startsAt,
    this.expiresAt,
  });

  factory UOrganizationSubscription.fromMap(Map<String, dynamic> json) => UOrganizationSubscription(
    id: json["id"] ?? "",
    planId: json["planId"],
    title: json["title"] ?? "",
    status: json["status"] == null ? 0 : (json["status"] as num).toInt(),
    createdAt: DateTime.parse(json["createdAt"]),
    modules: json["modules"] == null ? <int>[] : List<int>.from(json["modules"]!.map((dynamic x) => x)),
    limits: json["limits"] == null ? <UPlanLimit>[] : List<UPlanLimit>.from(json["limits"]!.map((dynamic x) => UPlanLimit.fromMap(x))),
    months: json["months"] == null ? 0 : (json["months"] as num).toInt(),
    days: json["days"] == null ? 0 : (json["days"] as num).toInt(),
    trial: json["trial"] ?? false,
    price: _num(json["price"]),
    credit: _num(json["credit"]),
    paid: _num(json["paid"]),
    startsAt: json["startsAt"] == null ? null : DateTime.parse(json["startsAt"]),
    expiresAt: json["expiresAt"] == null ? null : DateTime.parse(json["expiresAt"]),
  );

  final String id;
  final String? planId;
  final String title;
  final int status;
  final DateTime createdAt;
  final List<int> modules;
  final List<UPlanLimit> limits;
  final int months;
  final int days;
  final bool trial;
  final double price;
  final double credit;
  final double paid;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  bool get isLive => status == TagSubscription.active.number && startsAt != null && expiresAt != null && !startsAt!.isAfter(DateTime.now()) && expiresAt!.isAfter(DateTime.now());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "planId": planId,
    "title": title,
    "status": status,
    "createdAt": createdAt.toIso8601String(),
    "modules": modules,
    "limits": limits.map((UPlanLimit x) => x.toMap()).toList(),
    "months": months,
    "days": days,
    "trial": trial,
    "price": price,
    "credit": credit,
    "paid": paid,
    "startsAt": startsAt?.toIso8601String(),
    "expiresAt": expiresAt?.toIso8601String(),
  };
}

class USubscriptionPlanResponse {
  USubscriptionPlanResponse({
    required this.id,
    required this.title,
    this.tags = const <int>[],
    this.order = 0,
    this.description,
    this.modules = const <int>[],
    this.prices = const <UPlanPrice>[],
    this.limits = const <UPlanLimit>[],
    this.features = const <String>[],
    this.trialDays = 0,
  });

  factory USubscriptionPlanResponse.fromMap(Map<String, dynamic> json) => USubscriptionPlanResponse(
    id: json["id"] ?? "",
    title: json["title"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    order: json["order"] == null ? 0 : (json["order"] as num).toInt(),
    description: json["jsonData"]?["detail1"],
    modules: json["jsonData"]?["modules"] == null ? <int>[] : List<int>.from(json["jsonData"]!["modules"]!.map((dynamic x) => x)),
    prices: json["jsonData"]?["prices"] == null ? <UPlanPrice>[] : List<UPlanPrice>.from(json["jsonData"]!["prices"]!.map((dynamic x) => UPlanPrice.fromMap(x))),
    limits: json["jsonData"]?["limits"] == null ? <UPlanLimit>[] : List<UPlanLimit>.from(json["jsonData"]!["limits"]!.map((dynamic x) => UPlanLimit.fromMap(x))),
    features: json["jsonData"]?["features"] == null ? <String>[] : List<String>.from(json["jsonData"]!["features"]!.map((dynamic x) => x)),
    trialDays: json["jsonData"]?["trialDays"] == null ? 0 : (json["jsonData"]!["trialDays"] as num).toInt(),
  );

  final String id;
  final String title;
  final List<int> tags;
  final int order;
  final String? description;
  final List<int> modules;
  final List<UPlanPrice> prices;
  final List<UPlanLimit> limits;
  final List<String> features;
  final int trialDays;
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
