part of "../data.dart";

/// Icons a store type can use; the key is what the server stores.
abstract class UStoreTypeIcons {
  static const Map<String, IconData> values = <String, IconData>{
    "shop": Icons.shopping_bag_outlined,
    "cafe": Icons.local_cafe,
    "restaurant": Icons.restaurant,
    "market": Icons.local_grocery_store,
    "stall": Icons.storefront_outlined,
    "bakery": Icons.bakery_dining,
    "book": Icons.menu_book_rounded,
    "pharmacy": Icons.local_pharmacy,
    "beauty": Icons.face_retouching_natural,
    "tools": Icons.handyman_outlined,
  };

  static IconData of(String key) => values[key] ?? Icons.storefront_outlined;
}

class UStoreTypeResponse {
  UStoreTypeResponse({required this.id, required this.createdAt, required this.tags, required this.title, required this.color, required this.icon, required this.order, this.hint});

  factory UStoreTypeResponse.fromMap(Map<String, dynamic> json) => UStoreTypeResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from((json["tags"] as List<dynamic>).map((dynamic x) => x)),
    title: json["title"],
    color: json["color"],
    icon: json["icon"],
    order: json["order"] ?? 0,
    hint: json["jsonData"]?["hint"],
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String title;
  final String color;
  final String icon;
  final int order;
  final String? hint;

  bool get isActive => tags.contains(TagStoreType.active.number);

  IconData get iconData => UStoreTypeIcons.of(icon);

  /// The stored `#RRGGBB` color; a malformed value falls back to grey.
  Color get colorValue => Color(int.tryParse(color.replaceFirst("#", "").padLeft(8, "F").substring(0, 8), radix: 16) ?? 0xFF808080);
}

class UStoreResponse {
  UStoreResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.title,
    required this.code,
    required this.storeTypeId,
    this.description,
    this.organizationId,
    this.organizationTitle,
    this.storeType,
    this.media,
    this.creator,
  });

  factory UStoreResponse.fromMap(Map<String, dynamic> json) => UStoreResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from((json["tags"] as List<dynamic>).map((dynamic x) => x)),
    title: json["title"],
    code: json["code"],
    storeTypeId: json["storeTypeId"],
    description: json["jsonData"]?["description"],
    organizationId: json["organizationId"],
    organizationTitle: json["organizationTitle"],
    storeType: json["storeType"] == null ? null : UStoreTypeResponse.fromMap(json["storeType"]),
    media: json["media"] == null ? null : List<UMediaResponse>.from((json["media"] as List<dynamic>).map((dynamic x) => UMediaResponse.fromMap(x))),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String title;
  final String code;
  final String storeTypeId;
  final String? description;
  final String? organizationId;
  final String? organizationTitle;
  final UStoreTypeResponse? storeType;
  final List<UMediaResponse>? media;
  final UUserResponse? creator;

  UMediaResponse? get logo => media?.firstByTag(TagMedia.logo);

  UMediaResponse? get cover => media?.firstByTag(TagMedia.cover);

  bool get isApproved => tags.contains(TagStore.approved.number);

  bool get isRejected => tags.contains(TagStore.rejected.number);

  bool get isPending => tags.contains(TagStore.pendingApproval.number);

  bool get isActive => tags.contains(TagStore.active.number);
}
