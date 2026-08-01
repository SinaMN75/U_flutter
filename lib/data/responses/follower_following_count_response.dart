part of "../data.dart";

class UFollowerFollowingCountResponse {
  UFollowerFollowingCountResponse({
    required this.followers,
    required this.followedUsers,
    required this.followedProducts,
    required this.followedCategories,
  });

  factory UFollowerFollowingCountResponse.fromJson(String str) => UFollowerFollowingCountResponse.fromMap(json.decode(str));

  factory UFollowerFollowingCountResponse.fromMap(Map<String, dynamic> json) => UFollowerFollowingCountResponse(
    followers: json["followers"],
    followedUsers: json["followedUsers"],
    followedProducts: json["followedProducts"],
    followedCategories: json["followedCategories"],
  );
  final int followers;
  final int followedUsers;
  final int followedProducts;
  final int followedCategories;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "followers": followers,
    "followedUsers": followedUsers,
    "followedProducts": followedProducts,
    "followedCategories": followedCategories,
  };
}
