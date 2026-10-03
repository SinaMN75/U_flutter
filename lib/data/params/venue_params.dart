part of "../data.dart";

class UVenueCreateParams {
  UVenueCreateParams({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.tags,
    this.address,
    this.phoneNumber,
    this.country,
    this.city,
    this.description,
    this.website,
    this.instagram,
    this.whatsapp,
    this.timeZone,
    this.currency,
    this.amenities,
    this.openingHours,
    this.cancellationFreeHours,
    this.cancellationPenaltyPercent,
    this.adminUserIds,
    this.creatorId,
    this.id,
    this.detail1,
    this.detail2,
  });

  factory UVenueCreateParams.fromJson(String str) => UVenueCreateParams.fromMap(json.decode(str));

  factory UVenueCreateParams.fromMap(Map<String, dynamic> json) => UVenueCreateParams(
    title: json["title"],
    latitude: json["latitude"].toDouble(),
    longitude: json["longitude"].toDouble(),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    country: json["country"],
    city: json["city"],
    description: json["description"],
    website: json["website"],
    instagram: json["instagram"],
    whatsapp: json["whatsapp"],
    timeZone: json["timeZone"],
    currency: json["currency"],
    amenities: json["amenities"] == null ? null : List<String>.from(json["amenities"].map((dynamic x) => x)),
    openingHours: json["openingHours"] == null ? null : List<UVenueOpeningHour>.from(json["openingHours"].map((dynamic x) => UVenueOpeningHour.fromMap(x))),
    cancellationFreeHours: json["cancellationFreeHours"],
    cancellationPenaltyPercent: json["cancellationPenaltyPercent"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String title;
  final double latitude;
  final double longitude;
  final List<int> tags;
  final String? address;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final String? description;
  final String? website;
  final String? instagram;
  final String? whatsapp;
  final String? timeZone;
  final String? currency;
  final List<String>? amenities;
  final List<UVenueOpeningHour>? openingHours;
  final int? cancellationFreeHours;
  final int? cancellationPenaltyPercent;
  final List<String>? adminUserIds;
  final String? creatorId;
  final String? id;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "latitude": latitude,
    "longitude": longitude,
    "tags": tags,
    "address": address,
    "phoneNumber": phoneNumber,
    "country": country,
    "city": city,
    "description": description,
    "website": website,
    "instagram": instagram,
    "whatsapp": whatsapp,
    "timeZone": timeZone,
    "currency": currency,
    "amenities": amenities,
    "openingHours": openingHours?.map((UVenueOpeningHour x) => x.toMap()).toList(),
    "cancellationFreeHours": cancellationFreeHours,
    "cancellationPenaltyPercent": cancellationPenaltyPercent,
    "adminUserIds": adminUserIds,
    "creatorId": creatorId,
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UVenueUpdateParams {
  UVenueUpdateParams({
    required this.id,
    this.title,
    this.latitude,
    this.longitude,
    this.address,
    this.phoneNumber,
    this.country,
    this.city,
    this.description,
    this.website,
    this.instagram,
    this.whatsapp,
    this.timeZone,
    this.currency,
    this.amenities,
    this.openingHours,
    this.closures,
    this.cancellationFreeHours,
    this.cancellationPenaltyPercent,
    this.rejectionReason,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UVenueUpdateParams.fromJson(String str) => UVenueUpdateParams.fromMap(json.decode(str));

  factory UVenueUpdateParams.fromMap(Map<String, dynamic> json) => UVenueUpdateParams(
    id: json["id"],
    title: json["title"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    country: json["country"],
    city: json["city"],
    description: json["description"],
    website: json["website"],
    instagram: json["instagram"],
    whatsapp: json["whatsapp"],
    timeZone: json["timeZone"],
    currency: json["currency"],
    amenities: json["amenities"] == null ? null : List<String>.from(json["amenities"].map((dynamic x) => x)),
    openingHours: json["openingHours"] == null ? null : List<UVenueOpeningHour>.from(json["openingHours"].map((dynamic x) => UVenueOpeningHour.fromMap(x))),
    closures: json["closures"] == null ? null : List<UVenueClosure>.from(json["closures"].map((dynamic x) => UVenueClosure.fromMap(x))),
    cancellationFreeHours: json["cancellationFreeHours"],
    cancellationPenaltyPercent: json["cancellationPenaltyPercent"],
    rejectionReason: json["rejectionReason"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? null : List<String>.from(json["addAdminUserIds"].map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? null : List<String>.from(json["removeAdminUserIds"].map((dynamic x) => x)),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String id;
  final String? title;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final String? description;
  final String? website;
  final String? instagram;
  final String? whatsapp;
  final String? timeZone;
  final String? currency;
  final List<String>? amenities;
  final List<UVenueOpeningHour>? openingHours;
  final List<UVenueClosure>? closures;
  final int? cancellationFreeHours;
  final int? cancellationPenaltyPercent;
  final String? rejectionReason;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "latitude": latitude,
    "longitude": longitude,
    "address": address,
    "phoneNumber": phoneNumber,
    "country": country,
    "city": city,
    "description": description,
    "website": website,
    "instagram": instagram,
    "whatsapp": whatsapp,
    "timeZone": timeZone,
    "currency": currency,
    "amenities": amenities,
    "openingHours": openingHours?.map((UVenueOpeningHour x) => x.toMap()).toList(),
    "closures": closures?.map((UVenueClosure x) => x.toMap()).toList(),
    "cancellationFreeHours": cancellationFreeHours,
    "cancellationPenaltyPercent": cancellationPenaltyPercent,
    "rejectionReason": rejectionReason,
    "adminUserIds": adminUserIds,
    "addAdminUserIds": addAdminUserIds,
    "removeAdminUserIds": removeAdminUserIds,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UVenueReadParams {
  UVenueReadParams({
    this.title,
    this.sportId,
    this.mine = false,
    this.country,
    this.city,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UVenueReadParams.fromJson(String str) => UVenueReadParams.fromMap(json.decode(str));

  factory UVenueReadParams.fromMap(Map<String, dynamic> json) => UVenueReadParams(
    title: json["title"],
    sportId: json["sportId"],
    mine: json["mine"] ?? false,
    country: json["country"],
    city: json["city"],
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    radiusKm: json["radiusKm"]?.toDouble(),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UVenueSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final String? title;

  /// Venues with a court for this sport.
  final String? sportId;

  /// Venues the signed-in user owns or works at (any status).
  final bool mine;
  final String? country;
  final String? city;

  /// Nearest first; with radiusKm only venues inside it.
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UVenueSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "sportId": sportId,
    "mine": mine,
    "country": country,
    "city": city,
    "latitude": latitude,
    "longitude": longitude,
    "radiusKm": radiusKm,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UVenueStatsParams {
  UVenueStatsParams({
    required this.id,
    this.from,
    this.to,
  });

  factory UVenueStatsParams.fromJson(String str) => UVenueStatsParams.fromMap(json.decode(str));

  factory UVenueStatsParams.fromMap(Map<String, dynamic> json) => UVenueStatsParams(
    id: json["id"],
    from: json["from"] == null ? null : DateTime.parse(json["from"]),
    to: json["to"] == null ? null : DateTime.parse(json["to"]),
  );

  final String id;
  final DateTime? from;
  final DateTime? to;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "from": from?.toUtc().toIso8601String(),
    "to": to?.toUtc().toIso8601String(),
  };
}

class UCourtCreateParams {
  UCourtCreateParams({
    required this.title,
    required this.venueId,
    required this.pricePerHour,
    required this.tags,
    this.sportId,
    this.slotMinutes = 60,
    this.description,
    this.surface,
    this.players,
    this.priceRules,
    this.id,
    this.detail1,
    this.detail2,
  });

  factory UCourtCreateParams.fromJson(String str) => UCourtCreateParams.fromMap(json.decode(str));

  factory UCourtCreateParams.fromMap(Map<String, dynamic> json) => UCourtCreateParams(
    title: json["title"],
    venueId: json["venueId"],
    pricePerHour: json["pricePerHour"].toDouble(),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    sportId: json["sportId"],
    slotMinutes: json["slotMinutes"] ?? 60,
    description: json["description"],
    surface: json["surface"],
    players: json["players"],
    priceRules: json["priceRules"] == null ? null : List<UCourtPriceRule>.from(json["priceRules"].map((dynamic x) => UCourtPriceRule.fromMap(x))),
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String title;
  final String venueId;
  final double pricePerHour;
  final List<int> tags;
  final String? sportId;
  final int slotMinutes;
  final String? description;
  final String? surface;
  final int? players;
  final List<UCourtPriceRule>? priceRules;
  final String? id;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "venueId": venueId,
    "pricePerHour": pricePerHour,
    "tags": tags,
    "sportId": sportId,
    "slotMinutes": slotMinutes,
    "description": description,
    "surface": surface,
    "players": players,
    "priceRules": priceRules?.map((UCourtPriceRule x) => x.toMap()).toList(),
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UCourtUpdateParams {
  UCourtUpdateParams({
    required this.id,
    this.title,
    this.sportId,
    this.pricePerHour,
    this.slotMinutes,
    this.description,
    this.surface,
    this.players,
    this.priceRules,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UCourtUpdateParams.fromJson(String str) => UCourtUpdateParams.fromMap(json.decode(str));

  factory UCourtUpdateParams.fromMap(Map<String, dynamic> json) => UCourtUpdateParams(
    id: json["id"],
    title: json["title"],
    sportId: json["sportId"],
    pricePerHour: json["pricePerHour"]?.toDouble(),
    slotMinutes: json["slotMinutes"],
    description: json["description"],
    surface: json["surface"],
    players: json["players"],
    priceRules: json["priceRules"] == null ? null : List<UCourtPriceRule>.from(json["priceRules"].map((dynamic x) => UCourtPriceRule.fromMap(x))),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String id;
  final String? title;
  final String? sportId;
  final double? pricePerHour;
  final int? slotMinutes;
  final String? description;
  final String? surface;
  final int? players;
  final List<UCourtPriceRule>? priceRules;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "sportId": sportId,
    "pricePerHour": pricePerHour,
    "slotMinutes": slotMinutes,
    "description": description,
    "surface": surface,
    "players": players,
    "priceRules": priceRules?.map((UCourtPriceRule x) => x.toMap()).toList(),
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UCourtReadParams {
  UCourtReadParams({
    this.venueId,
    this.sportId,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UCourtReadParams.fromJson(String str) => UCourtReadParams.fromMap(json.decode(str));

  factory UCourtReadParams.fromMap(Map<String, dynamic> json) => UCourtReadParams(
    venueId: json["venueId"],
    sportId: json["sportId"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UCourtSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final String? venueId;
  final String? sportId;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UCourtSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "venueId": venueId,
    "sportId": sportId,
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UCourtAvailabilityParams {
  UCourtAvailabilityParams({
    required this.date,
    this.courtId,
    this.venueId,
    this.sportId,
  });

  factory UCourtAvailabilityParams.fromJson(String str) => UCourtAvailabilityParams.fromMap(json.decode(str));

  factory UCourtAvailabilityParams.fromMap(Map<String, dynamic> json) => UCourtAvailabilityParams(
    date: DateTime.parse(json["date"]),
    courtId: json["courtId"],
    venueId: json["venueId"],
    sportId: json["sportId"],
  );

  /// The day in the venue's time zone.
  final DateTime date;
  final String? courtId;
  final String? venueId;
  final String? sportId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "date": date.toIso8601String().substring(0, 10),
    "courtId": courtId,
    "venueId": venueId,
    "sportId": sportId,
  };
}

class UBookingCreateParams {
  UBookingCreateParams({
    required this.courtId,
    required this.startAt,
    this.durationMinutes = 60,
    this.payFromWallet = true,
    this.splitWithUserIds = const <String>[],
    this.notes,
  });

  factory UBookingCreateParams.fromJson(String str) => UBookingCreateParams.fromMap(json.decode(str));

  factory UBookingCreateParams.fromMap(Map<String, dynamic> json) => UBookingCreateParams(
    courtId: json["courtId"],
    startAt: DateTime.parse(json["startAt"]),
    durationMinutes: json["durationMinutes"] ?? 60,
    payFromWallet: json["payFromWallet"] ?? true,
    splitWithUserIds: json["splitWithUserIds"] == null ? const <String>[] : List<String>.from(json["splitWithUserIds"].map((dynamic x) => x)),
    notes: json["notes"],
  );

  final String courtId;
  final DateTime startAt;
  final int durationMinutes;

  /// Pays the booker's share from the wallet; otherwise at the venue (if it allows that).
  final bool payFromWallet;
  final List<String> splitWithUserIds;
  final String? notes;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "courtId": courtId,
    "startAt": startAt.toUtc().toIso8601String(),
    "durationMinutes": durationMinutes,
    "payFromWallet": payFromWallet,
    "splitWithUserIds": splitWithUserIds,
    "notes": notes,
  };
}

class UBookingReadParams {
  UBookingReadParams({
    this.mine = false,
    this.venueId,
    this.courtId,
    this.from,
    this.to,
    this.tags,
    this.ids,
    this.orderBy,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
  });

  factory UBookingReadParams.fromJson(String str) => UBookingReadParams.fromMap(json.decode(str));

  factory UBookingReadParams.fromMap(Map<String, dynamic> json) => UBookingReadParams(
    mine: json["mine"] ?? false,
    venueId: json["venueId"],
    courtId: json["courtId"],
    from: json["from"] == null ? null : DateTime.parse(json["from"]),
    to: json["to"] == null ? null : DateTime.parse(json["to"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"].map((dynamic x) => x)),
    orderBy: json["orderBy"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UBookingSelectorArgs.fromMap(json["selectorArgs"]),
  );

  final bool mine;
  final String? venueId;
  final String? courtId;
  final DateTime? from;
  final DateTime? to;
  final List<int>? tags;
  final List<String>? ids;
  final int? orderBy;
  final int? pageSize;
  final int? pageNumber;
  final UBookingSelectorArgs? selectorArgs;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "mine": mine,
    "venueId": venueId,
    "courtId": courtId,
    "from": from?.toUtc().toIso8601String(),
    "to": to?.toUtc().toIso8601String(),
    "tags": tags,
    "ids": ids,
    "orderBy": orderBy,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

/// Staff mark a booking completed or no-show (pays the venue out).
class UBookingUpdateParams {
  UBookingUpdateParams({
    required this.id,
    this.notes,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
  });

  factory UBookingUpdateParams.fromJson(String str) => UBookingUpdateParams.fromMap(json.decode(str));

  factory UBookingUpdateParams.fromMap(Map<String, dynamic> json) => UBookingUpdateParams(
    id: json["id"],
    notes: json["notes"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String id;
  final String? notes;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "notes": notes,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UBookingCancelParams {
  UBookingCancelParams({
    required this.id,
    this.reason,
  });

  factory UBookingCancelParams.fromJson(String str) => UBookingCancelParams.fromMap(json.decode(str));

  factory UBookingCancelParams.fromMap(Map<String, dynamic> json) => UBookingCancelParams(
    id: json["id"],
    reason: json["reason"],
  );

  final String id;
  final String? reason;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "reason": reason,
  };
}
