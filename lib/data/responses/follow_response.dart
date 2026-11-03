part of "../data.dart";

class UFollowResponse {
  UFollowResponse({required this.id, required this.createdAt, required this.tags, this.notify = false, this.userId, this.productId, this.storeId, this.store, this.product});

  factory UFollowResponse.fromMap(Map<String, dynamic> json) => UFollowResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from((json["tags"] as List<dynamic>).map((dynamic x) => x)),
    notify: json["jsonData"]?["notify"] ?? false,
    userId: json["userId"],
    productId: json["productId"],
    storeId: json["storeId"],
    store: json["store"] == null ? null : UStoreResponse.fromMap(json["store"]),
    product: json["product"] == null ? null : UProductResponse.fromMap(json["product"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final bool notify;
  final String? userId;
  final String? productId;
  final String? storeId;
  final UStoreResponse? store;
  final UProductResponse? product;
}
