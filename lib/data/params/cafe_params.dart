part of "../data.dart";

class UCafeSelectorArgs {
  const UCafeSelectorArgs({this.comments, this.media});

  final UCommentSelectorArgs? comments;
  final bool? media;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "comments": comments?.toMap(),
    "media": media,
  };
}

class UCafeCreateParams {
  UCafeCreateParams({
    required this.title,
    required this.cityCode,
    required this.tags,
    this.address,
    this.phoneNumber,
    this.organizationId,
    this.description,
    this.openHours,
    this.latitude,
    this.longitude,
    this.instagram,
    this.website,
  });

  final String title;
  final String cityCode;
  final List<int> tags;
  final String? address;
  final String? phoneNumber;
  final String? organizationId;
  final String? description;
  final String? openHours;
  final double? latitude;
  final double? longitude;
  final String? instagram;
  final String? website;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "cityCode": cityCode,
    "tags": tags,
    "address": address,
    "phoneNumber": phoneNumber,
    "organizationId": organizationId,
    "description": description,
    "openHours": openHours,
    "latitude": latitude,
    "longitude": longitude,
    "instagram": instagram,
    "website": website,
  };
}

class UCafeUpdateParams {
  UCafeUpdateParams({
    required this.id,
    this.title,
    this.cityCode,
    this.address,
    this.phoneNumber,
    this.description,
    this.openHours,
    this.latitude,
    this.longitude,
    this.instagram,
    this.website,
    this.tags,
    this.addTags,
    this.removeTags,
  });

  final String id;
  final String? title;
  final String? cityCode;
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? openHours;
  final double? latitude;
  final double? longitude;
  final String? instagram;
  final String? website;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "cityCode": cityCode,
    "address": address,
    "phoneNumber": phoneNumber,
    "description": description,
    "openHours": openHours,
    "latitude": latitude,
    "longitude": longitude,
    "instagram": instagram,
    "website": website,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
  };
}

class UCafeReadParams {
  UCafeReadParams({this.pageSize, this.pageNumber, this.ids, this.tags, this.title, this.cityCode, this.organizationId, this.manage, this.selectorArgs});

  final int? pageSize;
  final int? pageNumber;
  final List<String>? ids;
  final List<int>? tags;
  final String? title;
  final String? cityCode;
  final String? organizationId;
  final bool? manage;
  final UCafeSelectorArgs? selectorArgs;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "ids": ids ?? <String>[],
    "tags": tags,
    "title": title,
    "cityCode": cityCode,
    "organizationId": organizationId,
    "manage": manage,
    "selectorArgs": (selectorArgs ?? const UCafeSelectorArgs()).toMap(),
  };
}

class UMenuCreateParams {
  UMenuCreateParams({required this.title, required this.placeId, this.tags = const <int>[101, 201, 301], this.tagline});

  final String title;
  final String placeId;
  final List<int> tags;
  final String? tagline;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "placeId": placeId,
    "tags": tags,
    "tagline": tagline,
  };
}

class UMenuCategoryParams {
  UMenuCategoryParams({required this.title, this.id});

  final String? id;
  final String title;

  Map<String, dynamic> toMap() => <String, dynamic>{"id": id, "title": title};
}

class UMenuTableParams {
  UMenuTableParams({required this.number, this.title});

  final int number;
  final String? title;

  Map<String, dynamic> toMap() => <String, dynamic>{"number": number, "title": title};
}

class UMenuUpdateParams {
  UMenuUpdateParams({required this.id, this.title, this.tagline, this.theme, this.accent, this.font, this.categories, this.tables, this.tags, this.addTags, this.removeTags});

  final String id;
  final String? title;
  final String? tagline;
  final String? theme;
  final String? accent;
  final String? font;
  final List<UMenuCategoryParams>? categories;
  final List<UMenuTableParams>? tables;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "tagline": tagline,
    "theme": theme,
    "accent": accent,
    "font": font,
    "categories": categories?.map((UMenuCategoryParams x) => x.toMap()).toList(),
    "tables": tables?.map((UMenuTableParams x) => x.toMap()).toList(),
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
  };
}

class UMenuReadParams {
  UMenuReadParams({this.pageSize, this.pageNumber, this.placeId, this.organizationId});

  final int? pageSize;
  final int? pageNumber;
  final String? placeId;
  final String? organizationId;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "placeId": placeId,
    "organizationId": organizationId,
  };
}

class UMenuOpenParams {
  UMenuOpenParams({required this.id, this.table, this.manage});

  final String id;
  final int? table;
  final bool? manage;

  Map<String, dynamic> toMap() => <String, dynamic>{"id": id, "table": table, "manage": manage};
}

class UMenuItemCreateParams {
  UMenuItemCreateParams({
    required this.menuId,
    required this.title,
    required this.price,
    this.tags = const <int>[101],
    this.order = 0,
    this.categoryId,
    this.description,
    this.calories,
    this.prepMinutes,
    this.options,
  });

  final String menuId;
  final String title;
  final double price;
  final List<int> tags;
  final int order;
  final String? categoryId;
  final String? description;
  final int? calories;
  final int? prepMinutes;
  final List<UMenuItemOption>? options;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "menuId": menuId,
    "title": title,
    "price": price,
    "tags": tags,
    "order": order,
    "categoryId": categoryId,
    "description": description,
    "calories": calories,
    "prepMinutes": prepMinutes,
    "options": options?.map((UMenuItemOption x) => x.toMap()).toList(),
  };
}

class UMenuItemUpdateParams {
  UMenuItemUpdateParams({
    required this.id,
    this.title,
    this.price,
    this.order,
    this.categoryId,
    this.description,
    this.calories,
    this.prepMinutes,
    this.options,
    this.tags,
    this.addTags,
    this.removeTags,
  });

  final String id;
  final String? title;
  final double? price;
  final int? order;
  final String? categoryId;
  final String? description;
  final int? calories;
  final int? prepMinutes;
  final List<UMenuItemOption>? options;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "price": price,
    "order": order,
    "categoryId": categoryId,
    "description": description,
    "calories": calories,
    "prepMinutes": prepMinutes,
    "options": options?.map((UMenuItemOption x) => x.toMap()).toList(),
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
  };
}

class UMenuOrderLineParams {
  UMenuOrderLineParams({required this.itemId, this.quantity = 1, this.choices = const <String>[], this.note});

  final String itemId;
  final int quantity;
  final List<String> choices;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{"itemId": itemId, "quantity": quantity, "choices": choices, "note": note};
}

class UMenuOrderCreateParams {
  UMenuOrderCreateParams({required this.menuId, required this.type, required this.lines, this.table, this.room, this.note});

  final String menuId;
  final int type;
  final List<UMenuOrderLineParams> lines;
  final int? table;
  final String? room;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "menuId": menuId,
    "type": type,
    "lines": lines.map((UMenuOrderLineParams x) => x.toMap()).toList(),
    "table": table,
    "room": room,
    "note": note,
  };
}

class UMenuOrderReadParams {
  UMenuOrderReadParams({this.pageSize, this.pageNumber, this.tags, this.statuses, this.manage, this.menuId, this.placeId, this.organizationId, this.fromDate, this.toDate, this.ids});

  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final List<int>? statuses;
  final bool? manage;
  final String? menuId;
  final String? placeId;
  final String? organizationId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String>? ids;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "statuses": statuses,
    "manage": manage,
    "menuId": menuId,
    "placeId": placeId,
    "organizationId": organizationId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
    "ids": ids ?? <String>[],
  };
}

class UMenuOrderStatusParams {
  UMenuOrderStatusParams({required this.id, required this.status, this.reason});

  final String id;
  final int status;
  final String? reason;

  Map<String, dynamic> toMap() => <String, dynamic>{"id": id, "status": status, "reason": reason};
}
