part of "../data.dart";

class UFollowParams {
  UFollowParams({
    this.userId,
    this.creatorId,
    this.productId,
    this.storeId,
    this.notify,
  });

  factory UFollowParams.fromJson(String str) => UFollowParams.fromMap(json.decode(str));

  factory UFollowParams.fromMap(Map<String, dynamic> json) => UFollowParams(
    userId: json["userId"],
    creatorId: json["creatorId"],
    productId: json["productId"],
    storeId: json["storeId"],
    notify: json["notify"],
  );
  final String? userId;
  final String? creatorId;
  final String? productId;
  final String? storeId;

  /// For a store: notifications on (the server default) or off.
  final bool? notify;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
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
