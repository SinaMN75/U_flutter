part of "../data.dart";

class UInventoryReadParams {
  UInventoryReadParams({
    required this.organizationId,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.title,
    this.placeId,
  });

  final String organizationId;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final String? title;
  final String? placeId;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "title": title,
    "placeId": placeId,
  };
}

class UWarehouseCreateParams {
  UWarehouseCreateParams({
    required this.organizationId,
    required this.title,
    this.tags = const <int>[],
    this.placeId,
    this.address,
    this.keeperId,
    this.detail1,
  });

  final String organizationId;
  final String title;
  final List<int> tags;
  final String? placeId;
  final String? address;
  final String? keeperId;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "title": title,
    "tags": tags,
    "placeId": placeId,
    "address": address,
    "keeperId": keeperId,
    "detail1": detail1,
  };
}

class UWarehouseUpdateParams {
  UWarehouseUpdateParams({
    required this.id,
    this.title,
    this.placeId,
    this.address,
    this.keeperId,
    this.tags,
    this.detail1,
  });

  final String id;
  final String? title;
  final String? placeId;
  final String? address;
  final String? keeperId;
  final List<int>? tags;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "placeId": placeId,
    "address": address,
    "keeperId": keeperId,
    "tags": tags,
    "detail1": detail1,
  };
}

class UInventoryItemCreateParams {
  UInventoryItemCreateParams({
    required this.organizationId,
    required this.title,
    required this.unit,
    this.tags = const <int>[],
    this.code,
    this.minStock = 0,
    this.description,
  });

  final String organizationId;
  final String title;
  final String unit;
  final List<int> tags;
  final String? code;
  final double minStock;
  final String? description;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "title": title,
    "unit": unit,
    "tags": tags,
    "code": code,
    "minStock": minStock,
    "description": description,
  };
}

class UInventoryItemUpdateParams {
  UInventoryItemUpdateParams({
    required this.id,
    this.title,
    this.unit,
    this.code,
    this.minStock,
    this.description,
    this.tags,
  });

  final String id;
  final String? title;
  final String? unit;
  final String? code;
  final double? minStock;
  final String? description;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "unit": unit,
    "code": code,
    "minStock": minStock,
    "description": description,
    "tags": tags,
  };
}

class UStockMovementCreateParams {
  UStockMovementCreateParams({
    required this.organizationId,
    required this.itemId,
    required this.warehouseId,
    required this.quantity,
    this.tags = const <int>[],
    this.unitPrice = 0,
    this.targetWarehouseId,
    this.date,
    this.placeId,
    this.accountId,
    this.detail1,
  });

  final String organizationId;
  final String itemId;
  final String warehouseId;
  final List<int> tags;
  final double quantity;
  final double unitPrice;
  final String? targetWarehouseId;
  final DateTime? date;
  final String? placeId;
  final String? accountId;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "itemId": itemId,
    "warehouseId": warehouseId,
    "tags": tags,
    "quantity": quantity,
    "unitPrice": unitPrice,
    "targetWarehouseId": targetWarehouseId,
    "date": date?.toIso8601String(),
    "placeId": placeId,
    "accountId": accountId,
    "detail1": detail1,
  };
}

class UStockMovementReadParams {
  UStockMovementReadParams({
    required this.organizationId,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.itemId,
    this.warehouseId,
    this.fromDate,
    this.toDate,
  });

  final String organizationId;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final String? itemId;
  final String? warehouseId;
  final DateTime? fromDate;
  final DateTime? toDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "itemId": itemId,
    "warehouseId": warehouseId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}

class UStockReadParams {
  UStockReadParams({
    required this.organizationId,
    this.warehouseId,
    this.itemId,
    this.lowOnly = false,
  });

  final String organizationId;
  final String? warehouseId;
  final String? itemId;
  final bool lowOnly;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "warehouseId": warehouseId,
    "itemId": itemId,
    "lowOnly": lowOnly,
  };
}

class USupplierCreateParams {
  USupplierCreateParams({
    required this.organizationId,
    required this.title,
    this.tags = const <int>[101],
    this.phoneNumber,
    this.contactName,
    this.address,
    this.nationalId,
    this.iban,
  });

  final String organizationId;
  final String title;
  final List<int> tags;
  final String? phoneNumber;
  final String? contactName;
  final String? address;
  final String? nationalId;
  final String? iban;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "title": title,
    "tags": tags,
    "phoneNumber": phoneNumber,
    "contactName": contactName,
    "address": address,
    "nationalId": nationalId,
    "iban": iban,
  };
}

class USupplierUpdateParams {
  USupplierUpdateParams({
    required this.id,
    this.title,
    this.phoneNumber,
    this.contactName,
    this.address,
    this.nationalId,
    this.iban,
    this.tags,
  });

  final String id;
  final String? title;
  final String? phoneNumber;
  final String? contactName;
  final String? address;
  final String? nationalId;
  final String? iban;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "phoneNumber": phoneNumber,
    "contactName": contactName,
    "address": address,
    "nationalId": nationalId,
    "iban": iban,
    "tags": tags,
  };
}

class UPurchaseLineParams {
  UPurchaseLineParams({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
  });

  final String itemId;
  final double quantity;
  final double unitPrice;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "itemId": itemId,
    "quantity": quantity,
    "unitPrice": unitPrice,
  };
}

class UPurchaseCreateParams {
  UPurchaseCreateParams({
    required this.organizationId,
    required this.warehouseId,
    this.lines = const <UPurchaseLineParams>[],
    this.supplierId,
    this.date,
    this.detail1,
    this.vat = 0,
  });

  final String organizationId;
  final String warehouseId;
  final List<UPurchaseLineParams> lines;
  final String? supplierId;
  final DateTime? date;
  final String? detail1;
  final double vat;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "warehouseId": warehouseId,
    "lines": lines.map((UPurchaseLineParams x) => x.toMap()).toList(),
    "supplierId": supplierId,
    "date": date?.toIso8601String(),
    "detail1": detail1,
    "vat": vat,
  };
}

class UPurchaseReadParams {
  UPurchaseReadParams({
    required this.organizationId,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.supplierId,
    this.warehouseId,
  });

  final String organizationId;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final String? supplierId;
  final String? warehouseId;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "supplierId": supplierId,
    "warehouseId": warehouseId,
  };
}

class UPurchaseReviewParams {
  UPurchaseReviewParams({
    required this.id,
    required this.approve,
    this.note,
  });

  final String id;
  final bool approve;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "approve": approve,
    "note": note,
  };
}

class UPurchaseReceiveParams {
  UPurchaseReceiveParams({
    required this.id,
    this.accountId,
    this.date,
  });

  final String id;
  final String? accountId;
  final DateTime? date;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "accountId": accountId,
    "date": date?.toIso8601String(),
  };
}

class UAssetCreateParams {
  UAssetCreateParams({
    required this.organizationId,
    required this.title,
    required this.code,
    this.tags = const <int>[],
    this.placeId,
    this.location,
    this.serialNumber,
    this.purchaseDate,
    this.price,
    this.assignedUserId,
    this.detail1,
  });

  final String organizationId;
  final String title;
  final String code;
  final List<int> tags;
  final String? placeId;
  final String? location;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? price;
  final String? assignedUserId;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "organizationId": organizationId,
    "title": title,
    "code": code,
    "tags": tags,
    "placeId": placeId,
    "location": location,
    "serialNumber": serialNumber,
    "purchaseDate": purchaseDate?.toIso8601String(),
    "price": price,
    "assignedUserId": assignedUserId,
    "detail1": detail1,
  };
}

class UAssetUpdateParams {
  UAssetUpdateParams({
    required this.id,
    this.title,
    this.code,
    this.placeId,
    this.location,
    this.serialNumber,
    this.purchaseDate,
    this.price,
    this.assignedUserId,
    this.tags,
    this.detail1,
  });

  final String id;
  final String? title;
  final String? code;
  final String? placeId;
  final String? location;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? price;
  final String? assignedUserId;
  final List<int>? tags;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "code": code,
    "placeId": placeId,
    "location": location,
    "serialNumber": serialNumber,
    "purchaseDate": purchaseDate?.toIso8601String(),
    "price": price,
    "assignedUserId": assignedUserId,
    "tags": tags,
    "detail1": detail1,
  };
}
