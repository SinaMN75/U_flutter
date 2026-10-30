part of "../data.dart";

class UCategoryCreateParams {
  UCategoryCreateParams({required this.title, this.color, this.storeId, this.tags});

  final String title;
  final String? color;

  /// The owner; without one the category is shared by the whole app.
  final String? storeId;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "color": color,
    "storeId": storeId,
    "tags": tags ?? <int>[TagCategory.active.number],
  };
}

class UCategoryUpdateParams {
  UCategoryUpdateParams({required this.id, this.title, this.color, this.tags});

  final String id;
  final String? title;
  final String? color;
  final List<int>? tags;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "color": color,
    "tags": tags,
  };
}

class UCategoryReadParams {
  UCategoryReadParams({this.storeId, this.tags, this.pageSize, this.pageNumber});

  final String? storeId;
  final List<int>? tags;
  final int? pageSize;
  final int? pageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "storeId": storeId,
    "tags": tags,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  }..removeWhere((String _, dynamic v) => v == null);
}

class UCategoryReorderParams {
  UCategoryReorderParams({required this.ids, this.storeId});

  final String? storeId;

  /// Every category of the same owner, in the new order.
  final List<String> ids;

  Map<String, dynamic> toMap() => <String, dynamic>{"storeId": storeId, "ids": ids};
}
