part of "../data.dart";

class UCategoryResponse {
  UCategoryResponse({required this.id, required this.createdAt, required this.tags, required this.title, required this.order, this.color, this.storeId, this.productCount = 0});

  factory UCategoryResponse.fromMap(Map<String, dynamic> json) => UCategoryResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from((json["tags"] as List<dynamic>).map((dynamic x) => x)),
    title: json["title"],
    order: json["order"] ?? 0,
    color: json["color"],
    storeId: json["storeId"],
    productCount: json["productCount"] ?? 0,
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String title;
  final int order;
  final String? color;
  final String? storeId;
  final int productCount;

  bool get isActive => tags.contains(TagCategory.active.number);

  /// The stored `#RRGGBB` color, if it has one; a malformed value falls back to grey.
  Color? get colorValue => color == null ? null : Color(int.tryParse(color!.replaceFirst("#", "").padLeft(8, "F").substring(0, 8), radix: 16) ?? 0xFF808080);
}
