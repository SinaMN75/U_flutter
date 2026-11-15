part of "../data.dart";

class UFollowParams {
  UFollowParams({
    this.creatorId,
    this.productId,
    this.storeId,
    this.notify,
  });

  factory UFollowParams.fromJson(String str) => UFollowParams.fromMap(json.decode(str));

  factory UFollowParams.fromMap(Map<String, dynamic> json) => UFollowParams(
    creatorId: json["creatorId"],
    productId: json["productId"],
    storeId: json["storeId"],
    notify: json["notify"],
  );
  final String? creatorId;
  final String? productId;
  final String? storeId;

  /// For a store or a product: notifications on (the server default) or off.
  final bool? notify;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "creatorId": creatorId,
    "productId": productId,
    "storeId": storeId,
    "notify": notify,
  };
}

/// The signed-in user's follows and bookmarks; pass [store] or [product] to include them.
class UFollowReadParams {
  UFollowReadParams({this.tags, this.store, this.product, this.pageSize = 100, this.pageNumber = 1});

  /// [TagFollow] numbers.
  final List<int>? tags;
  final UStoreSelectorArgs? store;
  final UProductSelectorArgs? product;
  final int pageSize;
  final int pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "store": store?.toMap(),
    "product": product?.toMap(),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}
