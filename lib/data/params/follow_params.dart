part of "../data.dart";

class UFollowParams {
  UFollowParams({
    this.userId,
    this.creatorId,
    this.productId,
    this.categoryId,
  });

  factory UFollowParams.fromJson(String str) => UFollowParams.fromMap(json.decode(str));

  factory UFollowParams.fromMap(Map<String, dynamic> json) => UFollowParams(
    userId: json["userId"],
    creatorId: json["creatorId"],
    productId: json["productId"],
    categoryId: json["categoryId"],
  );
  final String? userId;
  final String? creatorId;
  final String? productId;
  final String? categoryId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "creatorId": creatorId,
    "productId": productId,
    "categoryId": categoryId,
  };
}
