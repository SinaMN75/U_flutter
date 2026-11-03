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

/// A link to a page outside the app; [kind] is a [TagLink] number.
class UWebLink {
  UWebLink({required this.kind, required this.url, this.title});

  factory UWebLink.fromMap(Map<String, dynamic> json) => UWebLink(kind: json["kind"], url: json["url"], title: json["title"]);

  final int kind;
  final String url;
  final String? title;

  bool isKind(TagLink tag) => kind == tag.number;

  Map<String, dynamic> toMap() => <String, dynamic>{"kind": kind, "url": url, "title": title};
}

extension WebLinkListExtension on Iterable<UWebLink> {
  UWebLink? ofKind(TagLink tag) => firstWhereOrNull((UWebLink x) => x.isKind(tag));
}

/// How a store's printed poster looks; empty fields use the app's defaults.
class UStorePoster {
  UStorePoster({this.template, this.color, this.headline});

  factory UStorePoster.fromMap(Map<String, dynamic> json) => UStorePoster(template: json["template"], color: json["color"], headline: json["headline"]);

  final String? template;

  /// `#RRGGBB`.
  final String? color;
  final String? headline;

  Map<String, dynamic> toMap() => <String, dynamic>{"template": template, "color": color, "headline": headline};
}

class UStoreReportDay {
  UStoreReportDay({required this.day, this.amount = 0});

  factory UStoreReportDay.fromMap(Map<String, dynamic> json) => UStoreReportDay(day: DateTime.parse(json["day"]), amount: json["amount"] ?? 0);

  final DateTime day;
  final num amount;
}

class UStoreReportSeller {
  UStoreReportSeller({required this.productId, required this.title, this.quantity = 0, this.amount = 0});

  factory UStoreReportSeller.fromMap(Map<String, dynamic> json) => UStoreReportSeller(productId: json["productId"], title: json["title"] ?? "", quantity: json["quantity"] ?? 0, amount: json["amount"] ?? 0);

  final String productId;
  final String title;
  final int quantity;
  final num amount;
}

/// Sales and visits of a store. Amounts count returned items out; profit is null without [TagModule.profitReports].
class UStoreReportResponse {
  UStoreReportResponse({
    this.viewsToday = 0,
    this.scansToday = 0,
    this.salesToday = 0,
    this.salesWeek = 0,
    this.salesMonth = 0,
    this.salesYear = 0,
    this.profitWeek,
    this.profitPeriod,
    this.salesPeriod = 0,
    this.itemsPeriod = 0,
    this.stockValue = 0,
    this.lowStockCount = 0,
    this.days = const <UStoreReportDay>[],
    this.topSellers = const <UStoreReportSeller>[],
  });

  factory UStoreReportResponse.fromMap(Map<String, dynamic> json) => UStoreReportResponse(
    viewsToday: json["viewsToday"] ?? 0,
    scansToday: json["scansToday"] ?? 0,
    salesToday: json["salesToday"] ?? 0,
    salesWeek: json["salesWeek"] ?? 0,
    salesMonth: json["salesMonth"] ?? 0,
    salesYear: json["salesYear"] ?? 0,
    profitWeek: json["profitWeek"],
    profitPeriod: json["profitPeriod"],
    salesPeriod: json["salesPeriod"] ?? 0,
    itemsPeriod: json["itemsPeriod"] ?? 0,
    stockValue: json["stockValue"] ?? 0,
    lowStockCount: json["lowStockCount"] ?? 0,
    days: ((json["days"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic x) => UStoreReportDay.fromMap(x)).toList(),
    topSellers: ((json["topSellers"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic x) => UStoreReportSeller.fromMap(x)).toList(),
  );

  final int viewsToday;
  final int scansToday;
  final num salesToday;
  final num salesWeek;
  final num salesMonth;
  final num salesYear;
  final num? profitWeek;
  final num? profitPeriod;
  final num salesPeriod;
  final int itemsPeriod;
  final num stockValue;
  final int lowStockCount;
  final List<UStoreReportDay> days;
  final List<UStoreReportSeller> topSellers;
}

/// Whole-platform numbers; buyers are users who own no organization, revenue covers the last 30 days.
class UStorePlatformReportResponse {
  UStorePlatformReportResponse({
    this.activeStores = 0,
    this.pendingStores = 0,
    this.blockedStores = 0,
    this.products = 0,
    this.sellers = 0,
    this.buyers = 0,
    this.scansToday = 0,
    this.activeSubscriptions = 0,
    this.subscriptionRevenue30Days = 0,
    this.pendingReports = 0,
    this.storesByType = const <UStorePlatformTypeCount>[],
  });

  factory UStorePlatformReportResponse.fromMap(Map<String, dynamic> json) => UStorePlatformReportResponse(
    activeStores: json["activeStores"] ?? 0,
    pendingStores: json["pendingStores"] ?? 0,
    blockedStores: json["blockedStores"] ?? 0,
    products: json["products"] ?? 0,
    sellers: json["sellers"] ?? 0,
    buyers: json["buyers"] ?? 0,
    scansToday: json["scansToday"] ?? 0,
    activeSubscriptions: json["activeSubscriptions"] ?? 0,
    subscriptionRevenue30Days: json["subscriptionRevenue30Days"] ?? 0,
    pendingReports: json["pendingReports"] ?? 0,
    storesByType: ((json["storesByType"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic x) => UStorePlatformTypeCount.fromMap(x)).toList(),
  );

  final int activeStores;
  final int pendingStores;
  final int blockedStores;
  final int products;
  final int sellers;
  final int buyers;
  final int scansToday;
  final int activeSubscriptions;
  final num subscriptionRevenue30Days;
  final int pendingReports;
  final List<UStorePlatformTypeCount> storesByType;
}

class UStorePlatformTypeCount {
  UStorePlatformTypeCount({required this.storeTypeId, required this.title, required this.color, this.count = 0});

  factory UStorePlatformTypeCount.fromMap(Map<String, dynamic> json) => UStorePlatformTypeCount(
    storeTypeId: json["storeTypeId"],
    title: json["title"] ?? "",
    color: json["color"] ?? "",
    count: json["count"] ?? 0,
  );

  final String storeTypeId;
  final String title;
  final String color;
  final int count;

  Color get colorValue => Color(int.tryParse(color.replaceFirst("#", "").padLeft(8, "F").substring(0, 8), radix: 16) ?? 0xFF808080);
}

class UStockMoveResponse {
  UStockMoveResponse({required this.id, required this.productId, required this.productTitle, required this.createdAt, this.quantity = 0, this.balance = 0, this.unitPrice, this.tags = const <int>[], this.note});

  factory UStockMoveResponse.fromMap(Map<String, dynamic> json) => UStockMoveResponse(
    id: json["id"],
    productId: json["productId"],
    productTitle: json["productTitle"] ?? "",
    createdAt: DateTime.parse(json["createdAt"]),
    quantity: json["quantity"] ?? 0,
    balance: json["balance"] ?? 0,
    unitPrice: json["unitPrice"],
    tags: List<int>.from(json["tags"] ?? <int>[]),
    note: json["jsonData"]?["note"],
  );

  final String id;
  final String productId;
  final String productTitle;
  final DateTime createdAt;

  /// Positive when stock came in, negative when it went out.
  final int quantity;

  /// The stock left after this move.
  final int balance;
  final num? unitPrice;

  /// [TagStockMove] numbers.
  final List<int> tags;
  final String? note;

  TagStockMove get kind => TagStockMove.values.firstWhere((TagStockMove x) => tags.contains(x.number), orElse: () => TagStockMove.adjust);
}

class UStoreScanResponse {
  UStoreScanResponse({this.total = 0, this.last7Days = 0});

  factory UStoreScanResponse.fromMap(Map<String, dynamic> json) => UStoreScanResponse(total: json["total"] ?? 0, last7Days: json["last7Days"] ?? 0);

  final int total;
  final int last7Days;
}

/// A copy of the product at the time of the sale.
class UStoreSaleLine {
  UStoreSaleLine({required this.productId, required this.title, required this.quantity, required this.unitPrice, this.purchasePrice});

  factory UStoreSaleLine.fromMap(Map<String, dynamic> json) => UStoreSaleLine(
    productId: json["productId"],
    title: json["title"] ?? "",
    quantity: json["quantity"] ?? 0,
    unitPrice: json["unitPrice"] ?? 0,
    purchasePrice: json["purchasePrice"],
  );

  final String productId;
  final String title;
  final int quantity;
  final num unitPrice;
  final num? purchasePrice;
}

class UStoreSaleResponse {
  UStoreSaleResponse({required this.id, required this.storeId, required this.createdAt, this.total = 0, this.tags = const <int>[], this.lines = const <UStoreSaleLine>[]});

  factory UStoreSaleResponse.fromMap(Map<String, dynamic> json) => UStoreSaleResponse(
    id: json["id"],
    storeId: json["storeId"],
    createdAt: DateTime.parse(json["createdAt"]),
    total: json["total"] ?? 0,
    tags: List<int>.from(json["tags"] ?? <int>[]),
    lines: ((json["jsonData"]?["lines"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic x) => UStoreSaleLine.fromMap(x)).toList(),
  );

  final String id;
  final String storeId;
  final DateTime createdAt;
  final num total;

  /// [TagStoreSale] numbers.
  final List<int> tags;
  final List<UStoreSaleLine> lines;
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
    this.links = const <UWebLink>[],
    this.poster,
    this.viewCount = 0,
    this.paymentViewCount = 0,
    this.menuIsActive = false,
    this.hasOpenAlert = false,
    this.organizationId,
    this.organizationTitle,
    this.distanceKm,
    this.productCount,
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
    links: ((json["jsonData"]?["links"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic x) => UWebLink.fromMap(x)).toList(),
    poster: json["jsonData"]?["poster"] == null ? null : UStorePoster.fromMap(json["jsonData"]["poster"]),
    viewCount: json["viewCount"] ?? 0,
    paymentViewCount: json["paymentViewCount"] ?? 0,
    menuIsActive: json["menuIsActive"] ?? false,
    hasOpenAlert: json["hasOpenAlert"] ?? false,
    organizationId: json["organizationId"],
    organizationTitle: json["organizationTitle"],
    distanceKm: json["distanceKm"],
    productCount: json["productCount"],
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
  final List<UWebLink> links;
  final int viewCount;
  final UStorePoster? poster;
  final int paymentViewCount;
  final bool menuIsActive;

  /// The caller asked to hear when the store opens (filled by `readByCode`).
  final bool hasOpenAlert;
  final String? organizationId;
  final String? organizationTitle;

  /// Filled by searches: distance from the caller, and listed products (matching the query, if any).
  final num? distanceKm;
  final int? productCount;
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

  /// The next moment the store opens after [from] (now by default) within a week, or null when it has no open day.
  DateTime? nextOpening([DateTime? from]) {
    final DateTime start = from ?? DateTime.now();
    final DateTime after = closedUntil != null && closedUntil!.isAfter(start) ? closedUntil!.toLocal() : start;
    for (int i = 0; i < 8; i++) {
      final DateTime date = DateTime(after.year, after.month, after.day + i);
      final UStoreWorkingDay? day = dayOf(date.weekday);
      if (day == null || !day.isOpen || day.opens == null) continue;
      final DateTime opens = DateTime(date.year, date.month, date.day, int.parse(day.opens!.substring(0, 2)), int.parse(day.opens!.substring(3, 5)));
      if (opens.isAfter(after)) return opens;
    }
    return null;
  }
}

class UProductResponse {
  UProductResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.title,
    this.description,
    this.price,
    this.stock = 0,
    this.purchasePrice,
    this.unit,
    this.measureUnit,
    this.lowStockAlert,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.specs = const <UKeyValueData>[],
    this.links = const <UWebLink>[],
    this.storeId,
    this.storeTitle,
    this.storeCode,
    this.distanceKm,
    this.categoryId,
    this.category,
    this.media,
  });

  factory UProductResponse.fromMap(Map<String, dynamic> json) => UProductResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from((json["tags"] as List<dynamic>).map((dynamic x) => x)),
    title: json["title"],
    description: json["description"],
    price: json["price"],
    stock: json["stock"] ?? 0,
    purchasePrice: json["jsonData"]?["purchasePrice"],
    unit: json["jsonData"]?["unit"],
    measureUnit: json["jsonData"]?["measureUnit"],
    lowStockAlert: json["jsonData"]?["lowStockAlert"],
    lengthCm: json["jsonData"]?["lengthCm"],
    widthCm: json["jsonData"]?["widthCm"],
    heightCm: json["jsonData"]?["heightCm"],
    specs: ((json["jsonData"]?["specs"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic x) => UKeyValueData.fromMap(x)).toList(),
    links: ((json["jsonData"]?["links"] as List<dynamic>?) ?? <dynamic>[]).map((dynamic x) => UWebLink.fromMap(x)).toList(),
    storeId: json["storeId"],
    storeTitle: json["storeTitle"],
    storeCode: json["storeCode"],
    distanceKm: json["distanceKm"],
    categoryId: json["categoryId"],
    category: json["category"] == null ? null : UCategoryResponse.fromMap(json["category"]),
    media: json["media"] == null ? null : List<UMediaResponse>.from((json["media"] as List<dynamic>).map((dynamic x) => UMediaResponse.fromMap(x))),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String title;
  final String? description;
  final num? price;
  final int stock;
  final num? purchasePrice;
  final String? unit;

  /// [TagMeasureUnit] number.
  final int? measureUnit;
  final int? lowStockAlert;
  final num? lengthCm;
  final num? widthCm;
  final num? heightCm;
  final List<UKeyValueData> specs;
  final List<UWebLink> links;
  final String? storeId;
  final String? storeTitle;
  final String? storeCode;

  /// Filled by searches: distance from the caller to the product's store.
  final num? distanceKm;
  final String? categoryId;
  final UCategoryResponse? category;
  final List<UMediaResponse>? media;

  bool get isHidden => tags.contains(TagProduct.hidden.number);

  bool get isBlocked => tags.contains(TagProduct.blocked.number);

  bool get isOutOfStock => stock <= 0;

  TagMeasureUnit? get measure => TagMeasureUnit.values.firstWhereOrNull((TagMeasureUnit x) => x.number == measureUnit);

  /// In stock, and at or under the seller's alert.
  bool get isLowStock => !isOutOfStock && lowStockAlert != null && stock <= lowStockAlert!;

  /// The uploaded video, if any.
  UMediaResponse? get video => media?.firstByTag(TagMedia.video);

  UMediaResponse? _modelFile(String extension) => media?.byTag(TagMedia.model3D).firstWhereOrNull((UMediaResponse m) => m.path.toLowerCase().endsWith(extension));

  /// The 3D model in GLB, which every platform can show.
  UMediaResponse? get model3D => _modelFile(".glb");

  /// The same model in USDZ, for iOS.
  UMediaResponse? get model3DIos => _modelFile(".usdz");

  bool get hasDimensions => lengthCm != null && widthCm != null && heightCm != null;

  Iterable<UMediaResponse> get _photos => media?.where((UMediaResponse m) => !m.tags.contains(TagMedia.video.number) && !m.tags.contains(TagMedia.model3D.number)) ?? const <UMediaResponse>[];

  UMediaResponse? get cover => _photos.firstByTag(TagMedia.cover) ?? _photos.firstOrNull;

  /// All photos with the cover first.
  List<UMediaResponse> get images => <UMediaResponse>[?cover, ..._photos.where((UMediaResponse m) => m.id != cover?.id)];
}

class UStorePaymentResponse {
  UStorePaymentResponse({this.cardNumber, this.iBan, this.accountOwner});

  factory UStorePaymentResponse.fromMap(Map<String, dynamic> json) => UStorePaymentResponse(cardNumber: json["cardNumber"], iBan: json["iBan"], accountOwner: json["accountOwner"]);

  final String? cardNumber;
  final String? iBan;
  final String? accountOwner;

  bool get isEmpty => (cardNumber ?? "").isEmpty && (iBan ?? "").isEmpty;
}
