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
    this.links,
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
  final List<UWebLink>? links;

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
    "links": links?.map((UWebLink x) => x.toMap()).toList(),
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
    this.links,
    this.poster,
    this.addTags,
    this.removeTags,
  });

  final String id;
  final UStorePoster? poster;
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
  final List<UWebLink>? links;
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
    "links": links?.map((UWebLink x) => x.toMap()).toList(),
    "poster": poster?.toMap(),
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

/// Filters shared by the public store and product searches.
class UPlaceSearchParams {
  UPlaceSearchParams({
    this.query,
    this.storeTypeIds = const <String>[],
    this.latitude,
    this.longitude,
    this.maxDistanceKm,
    this.openNow = false,
    int? utcOffsetMinutes,
    this.sort = TagSearchSort.nearest,
    this.pageSize = 20,
    this.pageNumber = 1,
  }) : utcOffsetMinutes = utcOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;

  final String? query;
  final List<String> storeTypeIds;
  final double? latitude;
  final double? longitude;
  final double? maxDistanceKm;

  /// Only places open now, in the caller's time zone.
  final bool openNow;
  final int utcOffsetMinutes;
  final TagSearchSort sort;
  final int pageSize;
  final int pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "query": query,
    "storeTypeIds": storeTypeIds,
    "latitude": latitude,
    "longitude": longitude,
    "maxDistanceKm": maxDistanceKm,
    "openNow": openNow,
    "utcOffsetMinutes": utcOffsetMinutes,
    "sort": sort.number,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UStoreExploreParams extends UPlaceSearchParams {
  UStoreExploreParams({
    super.query,
    super.storeTypeIds,
    super.latitude,
    super.longitude,
    super.maxDistanceKm,
    super.openNow,
    super.utcOffsetMinutes,
    super.sort,
    super.pageSize,
    super.pageNumber,
    this.selectorArgs,
  });

  final UStoreSelectorArgs? selectorArgs;

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{...super.toMap(), "selectorArgs": selectorArgs?.toMap()}..removeWhere((String _, dynamic v) => v == null);
}

class UProductSearchParams extends UPlaceSearchParams {
  UProductSearchParams({
    super.query,
    super.storeTypeIds,
    super.latitude,
    super.longitude,
    super.maxDistanceKm,
    super.openNow,
    super.utcOffsetMinutes,
    super.sort,
    super.pageSize,
    super.pageNumber,
    this.minPrice,
    this.maxPrice,
    this.inStock = false,
    this.hasModel = false,
    this.selectorArgs,
  });

  final num? minPrice;
  final num? maxPrice;
  final bool inStock;

  /// Only products with a 3D model, which can be shown in AR.
  final bool hasModel;
  final UProductSelectorArgs? selectorArgs;

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    ...super.toMap(),
    "minPrice": minPrice,
    "maxPrice": maxPrice,
    "inStock": inStock,
    "hasModel": hasModel,
    "selectorArgs": selectorArgs?.toMap(),
  }..removeWhere((String _, dynamic v) => v == null);
}

class UStoreCodeParams {
  UStoreCodeParams({required this.code, this.scanned = false, this.skipView = false, this.selectorArgs});

  final String code;

  /// This read comes from a scanned QR, so the server counts a scan and not a page view.
  final bool scanned;

  /// The scan that led here was already counted, so the server does not count a page view.
  final bool skipView;
  final UStoreSelectorArgs? selectorArgs;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "scanned": scanned,
    "skipView": skipView,
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

class UProductCreateParams {
  UProductCreateParams({required this.storeId, required this.title, required this.price, this.tags, this.categoryId, this.description, this.purchasePrice, this.stock = 0, this.lowStockAlert, this.lengthCm, this.widthCm, this.heightCm, this.unit, this.measureUnit, this.specs, this.links});

  final String storeId;
  final String title;
  final num price;
  final List<int>? tags;
  final String? categoryId;
  final String? description;
  final num? purchasePrice;
  final int stock;
  final int? lowStockAlert;

  /// 0 clears a size.
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final String? unit;

  /// [TagMeasureUnit] number.
  final int? measureUnit;
  final List<UKeyValueData>? specs;
  final List<UWebLink>? links;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "storeId": storeId,
    "title": title,
    "price": price,
    "tags": tags ?? <int>[TagProduct.product.number, TagProduct.released.number],
    "categoryId": categoryId,
    "description": description,
    "purchasePrice": purchasePrice,
    "stock": stock,
    "lowStockAlert": lowStockAlert,
    "lengthCm": lengthCm,
    "widthCm": widthCm,
    "heightCm": heightCm,
    "unit": unit,
    "measureUnit": measureUnit,
    "specs": specs?.map((UKeyValueData x) => x.toMap()).toList(),
    "links": links?.map((UWebLink x) => x.toMap()).toList(),
  };
}

class UProductUpdateParams {
  UProductUpdateParams({required this.id, this.title, this.price, this.categoryId, this.clearCategory = false, this.description, this.purchasePrice, this.stock, this.lowStockAlert, this.lengthCm, this.widthCm, this.heightCm, this.unit, this.measureUnit, this.specs, this.links, this.addTags, this.removeTags});

  final String id;
  final String? title;
  final num? price;
  final String? categoryId;

  /// Takes the product out of its category; wins over [categoryId].
  final bool clearCategory;
  final String? description;
  final num? purchasePrice;
  final int? stock;
  final int? lowStockAlert;

  /// 0 clears a size.
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final String? unit;

  /// [TagMeasureUnit] number.
  final int? measureUnit;
  final List<UKeyValueData>? specs;
  final List<UWebLink>? links;
  final List<int>? addTags;
  final List<int>? removeTags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "price": price,
    "categoryId": categoryId,
    "clearCategory": clearCategory,
    "description": description,
    "purchasePrice": purchasePrice,
    "stock": stock,
    "lowStockAlert": lowStockAlert,
    "lengthCm": lengthCm,
    "widthCm": widthCm,
    "heightCm": heightCm,
    "unit": unit,
    "measureUnit": measureUnit,
    "specs": specs?.map((UKeyValueData x) => x.toMap()).toList(),
    "links": links?.map((UWebLink x) => x.toMap()).toList(),
    "addTags": addTags,
    "removeTags": removeTags,
  };
}

class UProductReadParams {
  UProductReadParams({required this.storeId, this.title, this.categoryId, this.tags, this.pageSize, this.pageNumber, this.selectorArgs});

  final String storeId;
  final String? title;
  final String? categoryId;
  final List<int>? tags;
  final int? pageSize;
  final int? pageNumber;
  final UProductSelectorArgs? selectorArgs;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "storeId": storeId,
    "title": title,
    "categoryId": categoryId,
    "tags": tags,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  }..removeWhere((String _, dynamic v) => v == null);
}

class UProductSelectorArgs {
  const UProductSelectorArgs({this.creator, this.media});

  final UUserSelectorArgs? creator;
  final UMediaSelectorArgs? media;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creator": creator?.toMap(),
    "media": media?.toMap(),
  };
}

class UStoreSaleLineParams {
  UStoreSaleLineParams({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, dynamic> toMap() => <String, dynamic>{"productId": productId, "quantity": quantity};
}

class UStoreSaleCreateParams {
  UStoreSaleCreateParams({required this.storeId, required this.paymentMethod, required this.lines});

  final String storeId;

  /// A [TagStoreSale] number.
  final int paymentMethod;
  final List<UStoreSaleLineParams> lines;

  Map<String, dynamic> toMap() => <String, dynamic>{"storeId": storeId, "paymentMethod": paymentMethod, "lines": lines.map((UStoreSaleLineParams x) => x.toMap()).toList()};
}

class UStoreSaleReadParams {
  UStoreSaleReadParams({required this.storeId, this.pageSize, this.pageNumber});

  final String storeId;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{"storeId": storeId, "pageSize": pageSize, "pageNumber": pageNumber}..removeWhere((String _, dynamic v) => v == null);
}

class UStockMoveCreateParams {
  UStockMoveCreateParams({required this.productId, required this.kind, required this.quantity, this.unitPrice, this.note});

  final String productId;

  /// Any [TagStockMove] but [TagStockMove.sale] and [TagStockMove.adjust], as a number.
  final int kind;
  final int quantity;
  final num? unitPrice;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{"productId": productId, "kind": kind, "quantity": quantity, "unitPrice": unitPrice, "note": note}..removeWhere((String _, dynamic v) => v == null);
}

class UStockMoveReadParams {
  UStockMoveReadParams({required this.storeId, this.productId, this.pageSize, this.pageNumber});

  final String storeId;
  final String? productId;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{"storeId": storeId, "productId": productId, "pageSize": pageSize, "pageNumber": pageNumber}..removeWhere((String _, dynamic v) => v == null);
}

class UStoreReportParams {
  UStoreReportParams({required this.storeId, this.days = 7, int? utcOffsetMinutes}) : utcOffsetMinutes = utcOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;

  final String storeId;

  /// 7, 30 or 365: the length of the chart, top sellers and period totals.
  final int days;
  final int utcOffsetMinutes;

  Map<String, dynamic> toMap() => <String, dynamic>{"storeId": storeId, "days": days, "utcOffsetMinutes": utcOffsetMinutes};
}
