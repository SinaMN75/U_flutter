part of "../data.dart";

class UOrganizationCreateParams {
  UOrganizationCreateParams({
    required this.title,
    required this.ownerId,
    this.tags = const <int>[101],
    this.ownerPassword,
    this.commissionPercent = 0,
    this.logoUrl,
    this.address,
    this.phoneNumber,
    this.nationalId,
    this.economicCode,
    this.vatPercent,
    this.taxServiceId,
    this.cardNumber,
    this.accountNumber,
    this.iBanNumber,
  });

  final String title;
  final String ownerId;
  final List<int> tags;
  final String? ownerPassword;
  final double commissionPercent;
  final String? logoUrl;
  final String? address;
  final String? phoneNumber;
  final String? nationalId;
  final String? economicCode;
  final double? vatPercent;
  final String? taxServiceId;
  final String? cardNumber;
  final String? accountNumber;
  final String? iBanNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "ownerId": ownerId,
    "tags": tags,
    "ownerPassword": ownerPassword,
    "commissionPercent": commissionPercent,
    "logoUrl": logoUrl,
    "address": address,
    "phoneNumber": phoneNumber,
    "nationalId": nationalId,
    "economicCode": economicCode,
    "vatPercent": vatPercent,
    "taxServiceId": taxServiceId,
    "cardNumber": cardNumber,
    "accountNumber": accountNumber,
    "iBanNumber": iBanNumber,
  };
}

class UOrganizationUpdateParams {
  UOrganizationUpdateParams({
    required this.id,
    this.title,
    this.ownerId,
    this.ownerPassword,
    this.commissionPercent,
    this.tags,
    this.addTags,
    this.removeTags,
    this.logoUrl,
    this.address,
    this.phoneNumber,
    this.nationalId,
    this.economicCode,
    this.vatPercent,
    this.taxServiceId,
    this.cardNumber,
    this.accountNumber,
    this.iBanNumber,
  });

  final String id;
  final String? title;
  final String? ownerId;
  final String? ownerPassword;
  final double? commissionPercent;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? logoUrl;
  final String? address;
  final String? phoneNumber;
  final String? nationalId;
  final String? economicCode;
  final double? vatPercent;
  final String? taxServiceId;
  final String? cardNumber;
  final String? accountNumber;
  final String? iBanNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "ownerId": ownerId,
    "ownerPassword": ownerPassword,
    "commissionPercent": commissionPercent,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "logoUrl": logoUrl,
    "address": address,
    "phoneNumber": phoneNumber,
    "nationalId": nationalId,
    "economicCode": economicCode,
    "vatPercent": vatPercent,
    "taxServiceId": taxServiceId,
    "cardNumber": cardNumber,
    "accountNumber": accountNumber,
    "iBanNumber": iBanNumber,
  };
}

class UOrganizationReadParams {
  UOrganizationReadParams({this.pageSize, this.pageNumber, this.title, this.ids, this.tags, this.fromDate, this.toDate});

  final int? pageSize;
  final int? pageNumber;
  final String? title;
  final List<String>? ids;
  final List<int>? tags;
  final DateTime? fromDate;
  final DateTime? toDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "title": title,
    "ids": ids ?? <String>[],
    "tags": tags,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}

class UOrganizationMemberParams {
  UOrganizationMemberParams({required this.organizationId, required this.userId, this.permissions = const <int>[], this.password});

  final String organizationId;
  final String userId;
  final List<int> permissions;
  final String? password;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "userId": userId,
    "permissions": permissions,
    "password": password,
  };
}

class UStaffShiftCreateParams {
  UStaffShiftCreateParams({
    required this.organizationId,
    required this.userId,
    required this.startAt,
    required this.endAt,
    this.tags = const <int>[],
    this.placeId,
    this.detail1,
  });

  final String organizationId;
  final String userId;
  final DateTime startAt;
  final DateTime endAt;
  final List<int> tags;
  final String? placeId;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "userId": userId,
    "startAt": startAt.toIso8601String(),
    "endAt": endAt.toIso8601String(),
    "tags": tags,
    "placeId": placeId,
    "detail1": detail1,
  };
}

class UStaffShiftUpdateParams {
  UStaffShiftUpdateParams({
    required this.id,
    this.userId,
    this.startAt,
    this.endAt,
    this.placeId,
    this.tags,
    this.detail1,
  });

  final String id;
  final String? userId;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? placeId;
  final List<int>? tags;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "userId": userId,
    "startAt": startAt?.toIso8601String(),
    "endAt": endAt?.toIso8601String(),
    "placeId": placeId,
    "tags": tags,
    "detail1": detail1,
  };
}

class UStaffShiftReadParams {
  UStaffShiftReadParams({
    this.organizationId,
    this.pageSize,
    this.pageNumber,
    this.userId,
    this.placeId,
    this.fromDate,
    this.toDate,
  });

  final String? organizationId;
  final int? pageSize;
  final int? pageNumber;
  final String? userId;
  final String? placeId;
  final DateTime? fromDate;
  final DateTime? toDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "userId": userId,
    "placeId": placeId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}

class UStaffTaskCreateParams {
  UStaffTaskCreateParams({
    required this.title,
    this.tags = const <int>[],
    this.organizationId,
    this.placeId,
    this.assigneeId,
    this.dueDate,
    this.description,
    this.location,
    this.roomId,
    this.bedId,
  });

  final String title;
  final List<int> tags;
  final String? organizationId;
  final String? placeId;
  final String? assigneeId;
  final DateTime? dueDate;
  final String? description;
  final String? location;
  final String? roomId;
  final String? bedId;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "tags": tags,
    "organizationId": organizationId,
    "placeId": placeId,
    "assigneeId": assigneeId,
    "dueDate": dueDate?.toIso8601String(),
    "description": description,
    "location": location,
    "roomId": roomId,
    "bedId": bedId,
  };
}

class UStaffTaskUpdateParams {
  UStaffTaskUpdateParams({
    required this.id,
    this.title,
    this.placeId,
    this.assigneeId,
    this.dueDate,
    this.description,
    this.location,
    this.doneNote,
    this.cost,
    this.tags,
  });

  final String id;
  final String? title;
  final String? placeId;
  final String? assigneeId;
  final DateTime? dueDate;
  final String? description;
  final String? location;
  final String? doneNote;
  final double? cost;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "placeId": placeId,
    "assigneeId": assigneeId,
    "dueDate": dueDate?.toIso8601String(),
    "description": description,
    "location": location,
    "doneNote": doneNote,
    "cost": cost,
    "tags": tags,
  };
}

class UStaffTaskReadParams {
  UStaffTaskReadParams({
    this.organizationId,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.placeId,
    this.assigneeId,
    this.mine = false,
  });

  final String? organizationId;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final String? placeId;
  final String? assigneeId;
  final bool mine;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "placeId": placeId,
    "assigneeId": assigneeId,
    "mine": mine,
  };
}

class UOrganizationCustomerSetParams {
  UOrganizationCustomerSetParams({
    required this.organizationId,
    required this.userId,
    this.tags = const <int>[],
    this.note,
  });

  final String organizationId;
  final String userId;
  final List<int> tags;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "userId": userId,
    "tags": tags,
    "note": note,
  };
}

class UOrganizationCustomerReadParams {
  UOrganizationCustomerReadParams({
    required this.organizationId,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.userId,
  });

  final String organizationId;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final String? userId;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "userId": userId,
  };
}

class UActivityLogReadParams {
  UActivityLogReadParams({
    this.organizationId,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.userId,
    this.path,
    this.fromCreatedAt,
    this.toCreatedAt,
  });

  final String? organizationId;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final String? userId;
  final String? path;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "userId": userId,
    "path": path,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
  };
}

class USubscriptionPlanCreateParams {
  USubscriptionPlanCreateParams({
    required this.title,
    required this.modules,
    required this.prices,
    this.tags = const <int>[101],
    this.order = 0,
    this.detail1,
    this.limits = const <UPlanLimit>[],
    this.features = const <String>[],
    this.trialDays = 0,
  });

  final String title;
  final List<int> modules;
  final List<UPlanPrice> prices;
  final List<int> tags;
  final int order;
  final String? detail1;
  final List<UPlanLimit> limits;
  final List<String> features;
  final int trialDays;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "modules": modules,
    "prices": prices.map((UPlanPrice x) => x.toMap()).toList(),
    "tags": tags,
    "order": order,
    "detail1": detail1,
    "limits": limits.map((UPlanLimit x) => x.toMap()).toList(),
    "features": features,
    "trialDays": trialDays,
  };
}

class USubscriptionPlanUpdateParams {
  USubscriptionPlanUpdateParams({required this.id, this.title, this.modules, this.prices, this.tags, this.order, this.detail1, this.limits, this.features, this.trialDays});

  final String id;
  final String? title;
  final List<int>? modules;
  final List<UPlanPrice>? prices;
  final List<int>? tags;
  final int? order;
  final String? detail1;
  final List<UPlanLimit>? limits;
  final List<String>? features;
  final int? trialDays;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "modules": modules,
    "prices": prices?.map((UPlanPrice x) => x.toMap()).toList(),
    "tags": tags,
    "order": order,
    "detail1": detail1,
    "limits": limits?.map((UPlanLimit x) => x.toMap()).toList(),
    "features": features,
    "trialDays": trialDays,
  };
}

class USubscriptionPlanReadParams {
  USubscriptionPlanReadParams({this.module, this.tags});

  final int? module;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{"module": module, "tags": tags, "pageSize": 100, "pageNumber": 1};
}

class USubscriptionGrantParams {
  USubscriptionGrantParams({required this.organizationId, this.planId, this.title, this.modules, this.limits, this.months = 0, this.days = 0});

  final String organizationId;
  final String? planId;
  final String? title;
  final List<int>? modules;
  final List<UPlanLimit>? limits;
  final int months;
  final int days;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "planId": planId,
    "title": title,
    "modules": modules,
    "limits": limits?.map((UPlanLimit x) => x.toMap()).toList(),
    "months": months,
    "days": days,
  };
}

class USubscriptionCancelParams {
  USubscriptionCancelParams({required this.organizationId, required this.subscriptionId});

  final String organizationId;
  final String subscriptionId;

  Map<String, dynamic> toMap() => <String, dynamic>{"organizationId": organizationId, "subscriptionId": subscriptionId};
}
