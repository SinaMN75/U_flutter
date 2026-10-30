part of "../data.dart";

class UStoreCreateParams {
  UStoreCreateParams({
    required this.title,
    required this.storeTypeId,
    this.tags = const <int>[],
    this.organizationId,
    this.description,
    this.address,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.workingHours,
    this.closedUntil,
    this.cardNumber,
    this.iBan,
    this.accountOwner,
  });

  final List<int> tags;
  final String title;
  final String storeTypeId;
  final String? organizationId;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final List<UStoreWorkingDay>? workingHours;
  final DateTime? closedUntil;
  final String? cardNumber;
  final String? iBan;
  final String? accountOwner;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "title": title,
    "storeTypeId": storeTypeId,
    "organizationId": organizationId,
    "description": description,
    "address": address,
    "phoneNumber": phoneNumber,
    "latitude": latitude,
    "longitude": longitude,
    "workingHours": workingHours?.map((UStoreWorkingDay x) => x.toMap()).toList(),
    "closedUntil": closedUntil?.toUtc().toIso8601String(),
    "cardNumber": cardNumber,
    "iBan": iBan,
    "accountOwner": accountOwner,
  };
}

class UStoreUpdateParams {
  UStoreUpdateParams({
    required this.id,
    this.title,
    this.storeTypeId,
    this.description,
    this.address,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.workingHours,
    this.closedUntil,
    this.cardNumber,
    this.iBan,
    this.accountOwner,
    this.addTags,
    this.removeTags,
  });

  final String id;
  final String? title;
  final String? storeTypeId;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final List<UStoreWorkingDay>? workingHours;
  final DateTime? closedUntil;
  final String? cardNumber;
  final String? iBan;
  final String? accountOwner;
  final List<int>? addTags;
  final List<int>? removeTags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "storeTypeId": storeTypeId,
    "description": description,
    "address": address,
    "phoneNumber": phoneNumber,
    "latitude": latitude,
    "longitude": longitude,
    "workingHours": workingHours?.map((UStoreWorkingDay x) => x.toMap()).toList(),
    "closedUntil": closedUntil?.toUtc().toIso8601String(),
    "cardNumber": cardNumber,
    "iBan": iBan,
    "accountOwner": accountOwner,
    "addTags": addTags,
    "removeTags": removeTags,
  };
}

class UStoreReadParams {
  UStoreReadParams({this.manage, this.title, this.storeTypeId, this.organizationId, this.tags, this.ids, this.pageSize, this.pageNumber, this.selectorArgs});

  final bool? manage;
  final String? title;
  final String? storeTypeId;
  final String? organizationId;
  final List<int>? tags;
  final List<String>? ids;
  final int? pageSize;
  final int? pageNumber;
  final UStoreSelectorArgs? selectorArgs;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "manage": manage ?? false,
    "title": title,
    "storeTypeId": storeTypeId,
    "organizationId": organizationId,
    "tags": tags,
    "ids": ids ?? <String>[],
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  }..removeWhere((String _, dynamic v) => v == null);
}

class UStoreCodeParams {
  UStoreCodeParams({required this.code, this.selectorArgs});

  final String code;
  final UStoreSelectorArgs? selectorArgs;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "selectorArgs": selectorArgs?.toMap(),
  }..removeWhere((String _, dynamic v) => v == null);
}

class UStoreReviewParams {
  UStoreReviewParams({required this.id, required this.status, this.message});

  final String id;

  /// [TagStore.approved], [TagStore.rejected] (needs [message]) or [TagStore.blocked].
  final int status;
  final String? message;

  Map<String, dynamic> toMap() => <String, dynamic>{"id": id, "status": status, "message": message};
}

class UStoreSelectorArgs {
  const UStoreSelectorArgs({this.creator, this.media});

  final UUserSelectorArgs? creator;
  final UMediaSelectorArgs? media;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "media": media?.toMap(),
  };
}

class UStoreTypeCreateParams {
  UStoreTypeCreateParams({required this.tags, required this.title, required this.color, required this.icon, this.order = 0, this.hint});

  final List<int> tags;
  final String title;
  final String color;
  final String icon;
  final int order;
  final String? hint;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "title": title,
    "color": color,
    "icon": icon,
    "order": order,
    "hint": hint,
  };
}

class UStoreTypeUpdateParams {
  UStoreTypeUpdateParams({required this.id, this.title, this.color, this.icon, this.order, this.hint, this.tags});

  final String id;
  final String? title;
  final String? color;
  final String? icon;
  final int? order;
  final String? hint;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "color": color,
    "icon": icon,
    "order": order,
    "hint": hint,
    "tags": tags,
  };
}

class UStoreTypeReadParams {
  UStoreTypeReadParams({this.title, this.tags, this.pageSize, this.pageNumber});

  final String? title;
  final List<int>? tags;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "tags": tags,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UStoreCategoryCreateParams {
  UStoreCategoryCreateParams({required this.storeId, required this.title, required this.color, this.tags});

  final String storeId;
  final String title;
  final String color;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "storeId": storeId,
    "title": title,
    "color": color,
    "tags": tags ?? <int>[TagStoreCategory.active.number],
  };
}

class UStoreCategoryUpdateParams {
  UStoreCategoryUpdateParams({required this.id, this.title, this.color, this.tags});

  final String id;
  final String? title;
  final String? color;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "color": color,
    "tags": tags,
  };
}

class UStoreCategoryReadParams {
  UStoreCategoryReadParams({required this.storeId, this.tags, this.pageSize, this.pageNumber});

  final String storeId;
  final List<int>? tags;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "storeId": storeId,
    "tags": tags,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UStoreCategoryReorderParams {
  UStoreCategoryReorderParams({required this.storeId, required this.ids});

  final String storeId;

  /// Every category of the store, in the new order.
  final List<String> ids;

  Map<String, dynamic> toMap() => <String, dynamic>{"storeId": storeId, "ids": ids};
}
