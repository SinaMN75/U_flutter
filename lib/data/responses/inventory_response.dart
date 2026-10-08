part of "../data.dart";

class UWarehouseResponse {
  UWarehouseResponse({
    required this.id,
    required this.title,
    required this.organizationId,
    this.tags = const <int>[],
    this.placeId,
    this.address,
    this.keeperId,
    this.detail1,
  });

  factory UWarehouseResponse.fromMap(Map<String, dynamic> json) => UWarehouseResponse(
    id: json["id"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"] ?? "",
    organizationId: json["organizationId"] ?? "",
    placeId: json["placeId"],
    address: json["jsonData"]?["address"],
    keeperId: json["jsonData"]?["keeperId"],
    detail1: json["jsonData"]?["detail1"],
  );

  final String id;
  final List<int> tags;
  final String title;
  final String organizationId;
  final String? placeId;
  final String? address;
  final String? keeperId;
  final String? detail1;
}

class UInventoryItemResponse {
  UInventoryItemResponse({
    required this.id,
    required this.title,
    required this.unit,
    required this.organizationId,
    required this.minStock,
    required this.stock,
    this.tags = const <int>[],
    this.code,
    this.description,
  });

  factory UInventoryItemResponse.fromMap(Map<String, dynamic> json) => UInventoryItemResponse(
    id: json["id"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"] ?? "",
    unit: json["unit"] ?? "",
    organizationId: json["organizationId"] ?? "",
    code: json["code"],
    minStock: _num(json["minStock"]),
    stock: _num(json["stock"]),
    description: json["jsonData"]?["description"],
  );

  final String id;
  final List<int> tags;
  final String title;
  final String unit;
  final String organizationId;
  final String? code;
  final double minStock;
  final double stock;
  final String? description;
}

class UStockMovementResponse {
  UStockMovementResponse({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.date,
    required this.itemId,
    required this.warehouseId,
    this.tags = const <int>[],
    this.itemTitle,
    this.unit,
    this.warehouseTitle,
    this.detail1,
    this.purchaseId,
  });

  factory UStockMovementResponse.fromMap(Map<String, dynamic> json) => UStockMovementResponse(
    id: json["id"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    quantity: _num(json["quantity"]),
    unitPrice: _num(json["unitPrice"]),
    date: DateTime.parse(json["date"]),
    itemId: json["itemId"] ?? "",
    warehouseId: json["warehouseId"] ?? "",
    itemTitle: json["itemTitle"],
    unit: json["unit"],
    warehouseTitle: json["warehouseTitle"],
    detail1: json["jsonData"]?["detail1"],
    purchaseId: json["jsonData"]?["purchaseId"],
  );

  final String id;
  final List<int> tags;
  final double quantity;
  final double unitPrice;
  final DateTime date;
  final String itemId;
  final String warehouseId;
  final String? itemTitle;
  final String? unit;
  final String? warehouseTitle;
  final String? detail1;
  final String? purchaseId;
}

class UStockResponse {
  UStockResponse({
    required this.itemId,
    required this.itemTitle,
    required this.unit,
    required this.warehouseId,
    required this.warehouseTitle,
    required this.quantity,
    required this.minStock,
    required this.averageCost,
    required this.value,
    required this.low,
    this.code,
  });

  factory UStockResponse.fromMap(Map<String, dynamic> json) => UStockResponse(
    itemId: json["itemId"] ?? "",
    itemTitle: json["itemTitle"] ?? "",
    unit: json["unit"] ?? "",
    warehouseId: json["warehouseId"] ?? "",
    warehouseTitle: json["warehouseTitle"] ?? "",
    code: json["code"],
    quantity: _num(json["quantity"]),
    minStock: _num(json["minStock"]),
    averageCost: _num(json["averageCost"]),
    value: _num(json["value"]),
    low: json["low"] == true,
  );

  final String itemId;
  final String itemTitle;
  final String unit;
  final String warehouseId;
  final String warehouseTitle;
  final String? code;
  final double quantity;
  final double minStock;
  final double averageCost;
  final double value;
  final bool low;
}

class USupplierResponse {
  USupplierResponse({
    required this.id,
    required this.title,
    required this.organizationId,
    this.tags = const <int>[],
    this.phoneNumber,
    this.contactName,
    this.address,
    this.nationalId,
    this.iban,
  });

  factory USupplierResponse.fromMap(Map<String, dynamic> json) => USupplierResponse(
    id: json["id"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"] ?? "",
    organizationId: json["organizationId"] ?? "",
    phoneNumber: json["phoneNumber"],
    contactName: json["jsonData"]?["contactName"],
    address: json["jsonData"]?["address"],
    nationalId: json["jsonData"]?["nationalId"],
    iban: json["jsonData"]?["iban"],
  );

  final String id;
  final List<int> tags;
  final String title;
  final String organizationId;
  final String? phoneNumber;
  final String? contactName;
  final String? address;
  final String? nationalId;
  final String? iban;
}

class UPurchaseLine {
  UPurchaseLine({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
  });

  factory UPurchaseLine.fromMap(Map<String, dynamic> json) => UPurchaseLine(
    itemId: json["itemId"] ?? "",
    quantity: _num(json["quantity"]),
    unitPrice: _num(json["unitPrice"]),
  );

  final String itemId;
  final double quantity;
  final double unitPrice;
}

class UPurchaseResponse {
  UPurchaseResponse({
    required this.id,
    required this.number,
    required this.date,
    required this.total,
    required this.warehouseId,
    required this.organizationId,
    this.tags = const <int>[],
    this.supplierId,
    this.supplierTitle,
    this.warehouseTitle,
    this.lines = const <UPurchaseLine>[],
    this.detail1,
    this.reviewNote,
    this.receivedAt,
    this.vat = 0,
  });

  factory UPurchaseResponse.fromMap(Map<String, dynamic> json) => UPurchaseResponse(
    id: json["id"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    number: json["number"] == null ? 0 : (json["number"] as num).toInt(),
    date: DateTime.parse(json["date"]),
    total: _num(json["total"]),
    warehouseId: json["warehouseId"] ?? "",
    organizationId: json["organizationId"] ?? "",
    supplierId: json["supplierId"],
    supplierTitle: json["supplierTitle"],
    warehouseTitle: json["warehouseTitle"],
    lines: json["jsonData"]?["lines"] == null ? <UPurchaseLine>[] : List<UPurchaseLine>.from(json["jsonData"]?["lines"]!.map((dynamic x) => UPurchaseLine.fromMap(x))),
    detail1: json["jsonData"]?["detail1"],
    reviewNote: json["jsonData"]?["reviewNote"],
    receivedAt: json["jsonData"]?["receivedAt"] == null ? null : DateTime.parse(json["jsonData"]?["receivedAt"]),
    vat: _num(json["jsonData"]?["vat"]),
  );

  final String id;
  final List<int> tags;
  final int number;
  final DateTime date;
  final double total;
  final String warehouseId;
  final String organizationId;
  final String? supplierId;
  final String? supplierTitle;
  final String? warehouseTitle;
  final List<UPurchaseLine> lines;
  final String? detail1;
  final String? reviewNote;
  final DateTime? receivedAt;
  final double vat;
}

class UAssetResponse {
  UAssetResponse({
    required this.id,
    required this.title,
    required this.code,
    required this.organizationId,
    this.tags = const <int>[],
    this.placeId,
    this.location,
    this.serialNumber,
    this.purchaseDate,
    this.price,
    this.assignedUserId,
    this.detail1,
  });

  factory UAssetResponse.fromMap(Map<String, dynamic> json) => UAssetResponse(
    id: json["id"] ?? "",
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"] ?? "",
    code: json["code"] ?? "",
    organizationId: json["organizationId"] ?? "",
    placeId: json["placeId"],
    location: json["jsonData"]?["location"],
    serialNumber: json["jsonData"]?["serialNumber"],
    purchaseDate: json["jsonData"]?["purchaseDate"] == null ? null : DateTime.parse(json["jsonData"]?["purchaseDate"]),
    price: json["jsonData"]?["price"] == null ? null : (json["jsonData"]?["price"] as num).toDouble(),
    assignedUserId: json["jsonData"]?["assignedUserId"],
    detail1: json["jsonData"]?["detail1"],
  );

  final String id;
  final List<int> tags;
  final String title;
  final String code;
  final String organizationId;
  final String? placeId;
  final String? location;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? price;
  final String? assignedUserId;
  final String? detail1;
}
