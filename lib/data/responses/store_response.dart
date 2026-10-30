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

class UStoreWorkingDay {
  UStoreWorkingDay({required this.day, this.isOpen = false, this.opens, this.closes});

  factory UStoreWorkingDay.fromMap(Map<String, dynamic> json) => UStoreWorkingDay(
    day: json["day"],
    isOpen: json["isOpen"] ?? false,
    opens: json["opens"],
    closes: json["closes"],
  );

  /// Same numbering as [DateTime.weekday]: 1 = Monday … 7 = Sunday.
  final int day;
  final bool isOpen;
  final String? opens;
  final String? closes;

  Map<String, dynamic> toMap() => <String, dynamic>{"day": day, "isOpen": isOpen, "opens": opens, "closes": closes};
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
    this.address,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.workingHours = const <UStoreWorkingDay>[],
    this.closedUntil,
    this.cardNumber,
    this.iBan,
    this.accountOwner,
    this.reviewMessage,
    this.viewCount = 0,
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
    address: json["jsonData"]?["address"],
    phoneNumber: json["jsonData"]?["phoneNumber"],
    latitude: (json["jsonData"]?["latitude"] as num?)?.toDouble(),
    longitude: (json["jsonData"]?["longitude"] as num?)?.toDouble(),
    workingHours: ((json["jsonData"]?["workingHours"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic x) => UStoreWorkingDay.fromMap(x)).toList(),
    closedUntil: json["jsonData"]?["closedUntil"] == null ? null : DateTime.parse(json["jsonData"]["closedUntil"]),
    cardNumber: json["jsonData"]?["cardNumber"],
    iBan: json["jsonData"]?["iBan"],
    accountOwner: json["jsonData"]?["accountOwner"],
    reviewMessage: json["jsonData"]?["reviewMessage"],
    viewCount: json["viewCount"] ?? 0,
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
  final String? address;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final List<UStoreWorkingDay> workingHours;
  final DateTime? closedUntil;
  final String? cardNumber;
  final String? iBan;
  final String? accountOwner;
  final String? reviewMessage;
  final int viewCount;
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

  bool get isMenu => tags.contains(TagStore.menu.number);

  bool get isBlocked => tags.contains(TagStore.blocked.number);

  bool get isClosedForNow => closedUntil?.isAfter(DateTime.now()) ?? false;

  UStoreWorkingDay? dayOf(int weekday) => workingHours.where((UStoreWorkingDay d) => d.day == weekday).firstOrNull;

  /// The day whose hours cover [at], counting a night that runs past midnight into the next day.
  UStoreWorkingDay? _openDayAt(DateTime at) {
    if (isClosedForNow) return null;
    final int now = at.hour * 60 + at.minute;
    int? minutes(String? t) => t == null ? null : int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));
    final UStoreWorkingDay? today = dayOf(at.weekday);
    final UStoreWorkingDay? yesterday = dayOf(at.weekday == DateTime.monday ? DateTime.sunday : at.weekday - 1);
    if (today != null && today.isOpen) {
      final int opens = minutes(today.opens) ?? 0;
      final int closes = minutes(today.closes) ?? 0;
      if (closes <= opens ? now >= opens : now >= opens && now < closes) return today;
    }
    if (yesterday != null && yesterday.isOpen) {
      final int opens = minutes(yesterday.opens) ?? 0;
      final int closes = minutes(yesterday.closes) ?? 0;
      if (closes <= opens && now < closes) return yesterday;
    }
    return null;
  }

  bool get isOpenNow => _openDayAt(DateTime.now()) != null;

  /// When the store closes today, while it is open.
  String? get closesAtNow => _openDayAt(DateTime.now())?.closes;
}
