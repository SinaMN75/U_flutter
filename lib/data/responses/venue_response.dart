part of "../data.dart";

class UVenueOpeningHour {
  UVenueOpeningHour({
    required this.day,
    required this.open,
    required this.close,
  });

  factory UVenueOpeningHour.fromJson(String str) => UVenueOpeningHour.fromMap(json.decode(str));

  factory UVenueOpeningHour.fromMap(Map<String, dynamic> json) => UVenueOpeningHour(
    day: json["day"],
    open: json["open"],
    close: json["close"],
  );

  /// 0 = Sunday ... 6 = Saturday.
  final int day;

  /// "08:00"
  final String open;

  /// "23:00"; "24:00" = midnight.
  final String close;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "day": day,
    "open": open,
    "close": close,
  };
}

class UVenueClosure {
  UVenueClosure({
    required this.from,
    required this.to,
    this.reason,
  });

  factory UVenueClosure.fromJson(String str) => UVenueClosure.fromMap(json.decode(str));

  factory UVenueClosure.fromMap(Map<String, dynamic> json) => UVenueClosure(
    from: DateTime.parse(json["from"]),
    to: DateTime.parse(json["to"]),
    reason: json["reason"],
  );

  final DateTime from;
  final DateTime to;
  final String? reason;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "from": from.toUtc().toIso8601String(),
    "to": to.toUtc().toIso8601String(),
    "reason": reason,
  };
}

class UCourtPriceRule {
  UCourtPriceRule({
    required this.from,
    required this.to,
    required this.pricePerHour,
    this.days = const <int>[],
  });

  factory UCourtPriceRule.fromJson(String str) => UCourtPriceRule.fromMap(json.decode(str));

  factory UCourtPriceRule.fromMap(Map<String, dynamic> json) => UCourtPriceRule(
    from: json["from"],
    to: json["to"],
    pricePerHour: json["pricePerHour"].toDouble(),
    days: json["days"] == null ? const <int>[] : List<int>.from(json["days"].map((dynamic x) => x)),
  );

  final String from;
  final String to;
  final double pricePerHour;

  /// Empty = every day.
  final List<int> days;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "from": from,
    "to": to,
    "pricePerHour": pricePerHour,
    "days": days,
  };
}

class UBookingParticipant {
  UBookingParticipant({
    required this.userId,
    required this.share,
    this.paid = false,
  });

  factory UBookingParticipant.fromJson(String str) => UBookingParticipant.fromMap(json.decode(str));

  factory UBookingParticipant.fromMap(Map<String, dynamic> json) => UBookingParticipant(
    userId: json["userId"],
    share: json["share"].toDouble(),
    paid: json["paid"] ?? false,
  );

  final String userId;
  final double share;
  final bool paid;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "share": share,
    "paid": paid,
  };
}

class UVenueJson {
  UVenueJson({
    this.description,
    this.website,
    this.instagram,
    this.whatsapp,
    this.timeZone = "UTC",
    this.currency,
    this.amenities = const <String>[],
    this.openingHours = const <UVenueOpeningHour>[],
    this.closures = const <UVenueClosure>[],
    this.cancellationFreeHours = 24,
    this.cancellationPenaltyPercent = 100,
    this.rejectionReason,
    this.detail1,
    this.detail2,
  });

  factory UVenueJson.fromJson(String str) => UVenueJson.fromMap(json.decode(str));

  factory UVenueJson.fromMap(Map<String, dynamic> json) => UVenueJson(
    description: json["description"],
    website: json["website"],
    instagram: json["instagram"],
    whatsapp: json["whatsapp"],
    timeZone: json["timeZone"] ?? "UTC",
    currency: json["currency"],
    amenities: json["amenities"] == null ? const <String>[] : List<String>.from(json["amenities"].map((dynamic x) => x)),
    openingHours: json["openingHours"] == null ? const <UVenueOpeningHour>[] : List<UVenueOpeningHour>.from(json["openingHours"].map((dynamic x) => UVenueOpeningHour.fromMap(x))),
    closures: json["closures"] == null ? const <UVenueClosure>[] : List<UVenueClosure>.from(json["closures"].map((dynamic x) => UVenueClosure.fromMap(x))),
    cancellationFreeHours: json["cancellationFreeHours"] ?? 24,
    cancellationPenaltyPercent: json["cancellationPenaltyPercent"] ?? 100,
    rejectionReason: json["rejectionReason"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? description;
  final String? website;
  final String? instagram;
  final String? whatsapp;
  final String timeZone;
  final String? currency;
  final List<String> amenities;
  final List<UVenueOpeningHour> openingHours;
  final List<UVenueClosure> closures;
  final int cancellationFreeHours;
  final int cancellationPenaltyPercent;
  final String? rejectionReason;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "description": description,
    "website": website,
    "instagram": instagram,
    "whatsapp": whatsapp,
    "timeZone": timeZone,
    "currency": currency,
    "amenities": amenities,
    "openingHours": openingHours.map((UVenueOpeningHour x) => x.toMap()).toList(),
    "closures": closures.map((UVenueClosure x) => x.toMap()).toList(),
    "cancellationFreeHours": cancellationFreeHours,
    "cancellationPenaltyPercent": cancellationPenaltyPercent,
    "rejectionReason": rejectionReason,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UVenueResponse {
  UVenueResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    this.creatorId,
    this.latitude = 0,
    this.longitude = 0,
    this.address,
    this.phoneNumber,
    this.country,
    this.city,
    this.distanceKm,
    this.rating,
    this.reviewCount = 0,
    this.sportIds = const <String>[],
    this.adminUserIds = const <String>[],
    this.courts,
    this.media,
    this.creator,
  });

  factory UVenueResponse.fromJson(String str) => UVenueResponse.fromMap(json.decode(str));

  factory UVenueResponse.fromMap(Map<String, dynamic> json) => UVenueResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UVenueJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    latitude: json["latitude"]?.toDouble() ?? 0,
    longitude: json["longitude"]?.toDouble() ?? 0,
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    country: json["country"],
    city: json["city"],
    distanceKm: json["distanceKm"]?.toDouble(),
    rating: json["rating"]?.toDouble(),
    reviewCount: json["reviewCount"] ?? 0,
    sportIds: json["sportIds"] == null ? const <String>[] : List<String>.from(json["sportIds"].map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? const <String>[] : List<String>.from(json["adminUserIds"].map((dynamic x) => x)),
    courts: json["courts"] == null ? null : List<UCourtResponse>.from(json["courts"].map((dynamic x) => UCourtResponse.fromMap(x))),
    media: json["media"] == null ? null : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
  );

  final String id;
  final DateTime createdAt;
  final UVenueJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String title;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final double? distanceKm;
  final double? rating;
  final int reviewCount;
  final List<String> sportIds;
  final List<String> adminUserIds;
  final List<UCourtResponse>? courts;
  final List<UMediaResponse>? media;
  final UUserResponse? creator;

  TagVenue? get status => TagVenue.values.group(200).firstWhereOrNull((TagVenue t) => tags.contains(t.number));

  bool get isShop => tags.contains(TagVenue.shop.number);

  bool canManage(String? userId) => userId != null && (creatorId == userId || adminUserIds.contains(userId));

  /// The cover photo, or the first one.
  String? get coverUrl => (media?.firstByTag(TagMedia.cover) ?? media?.firstOrNull)?.url;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "title": title,
    "latitude": latitude,
    "longitude": longitude,
    "address": address,
    "phoneNumber": phoneNumber,
    "country": country,
    "city": city,
    "distanceKm": distanceKm,
    "rating": rating,
    "reviewCount": reviewCount,
    "sportIds": sportIds,
    "adminUserIds": adminUserIds,
    "courts": courts?.map((UCourtResponse x) => x.toMap()).toList(),
    "media": media?.map((UMediaResponse x) => x.toMap()).toList(),
    "creator": creator?.toMap(),
  };
}

class UCourtJson {
  UCourtJson({
    this.description,
    this.surface,
    this.players = 4,
    this.priceRules = const <UCourtPriceRule>[],
    this.detail1,
    this.detail2,
  });

  factory UCourtJson.fromJson(String str) => UCourtJson.fromMap(json.decode(str));

  factory UCourtJson.fromMap(Map<String, dynamic> json) => UCourtJson(
    description: json["description"],
    surface: json["surface"],
    players: json["players"] ?? 4,
    priceRules: json["priceRules"] == null ? const <UCourtPriceRule>[] : List<UCourtPriceRule>.from(json["priceRules"].map((dynamic x) => UCourtPriceRule.fromMap(x))),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? description;
  final String? surface;
  final int players;
  final List<UCourtPriceRule> priceRules;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "description": description,
    "surface": surface,
    "players": players,
    "priceRules": priceRules.map((UCourtPriceRule x) => x.toMap()).toList(),
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UCourtResponse {
  UCourtResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.venueId,
    this.creatorId,
    this.pricePerHour = 0,
    this.slotMinutes = 60,
    this.sportId,
    this.venue,
    this.sport,
  });

  factory UCourtResponse.fromJson(String str) => UCourtResponse.fromMap(json.decode(str));

  factory UCourtResponse.fromMap(Map<String, dynamic> json) => UCourtResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UCourtJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    venueId: json["venueId"],
    pricePerHour: json["pricePerHour"]?.toDouble() ?? 0,
    slotMinutes: json["slotMinutes"] ?? 60,
    sportId: json["sportId"],
    venue: json["venue"] == null ? null : UVenueResponse.fromMap(json["venue"]),
    sport: json["sport"] == null ? null : USportResponse.fromMap(json["sport"]),
  );

  final String id;
  final DateTime createdAt;
  final UCourtJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final String title;
  final String venueId;
  final double pricePerHour;
  final int slotMinutes;
  final String? sportId;
  final UVenueResponse? venue;
  final USportResponse? sport;

  bool get isActive => tags.contains(TagCourt.active.number);

  bool get isIndoor => tags.contains(TagCourt.indoor.number);

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "title": title,
    "venueId": venueId,
    "pricePerHour": pricePerHour,
    "slotMinutes": slotMinutes,
    "sportId": sportId,
    "venue": venue?.toMap(),
    "sport": sport?.toMap(),
  };
}

class UCourtSlotResponse {
  UCourtSlotResponse({
    required this.startAt,
    required this.endAt,
    this.price = 0,
    this.available = false,
  });

  factory UCourtSlotResponse.fromJson(String str) => UCourtSlotResponse.fromMap(json.decode(str));

  factory UCourtSlotResponse.fromMap(Map<String, dynamic> json) => UCourtSlotResponse(
    startAt: DateTime.parse(json["startAt"]),
    endAt: DateTime.parse(json["endAt"]),
    price: json["price"]?.toDouble() ?? 0,
    available: json["available"] ?? false,
  );

  final DateTime startAt;
  final DateTime endAt;
  final double price;
  final bool available;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "startAt": startAt.toIso8601String(),
    "endAt": endAt.toIso8601String(),
    "price": price,
    "available": available,
  };
}

class UCourtAvailabilityResponse {
  UCourtAvailabilityResponse({
    required this.court,
    this.slots = const <UCourtSlotResponse>[],
  });

  factory UCourtAvailabilityResponse.fromJson(String str) => UCourtAvailabilityResponse.fromMap(json.decode(str));

  factory UCourtAvailabilityResponse.fromMap(Map<String, dynamic> json) => UCourtAvailabilityResponse(
    court: UCourtResponse.fromMap(json["court"]),
    slots: json["slots"] == null ? const <UCourtSlotResponse>[] : List<UCourtSlotResponse>.from(json["slots"].map((dynamic x) => UCourtSlotResponse.fromMap(x))),
  );

  final UCourtResponse court;
  final List<UCourtSlotResponse> slots;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "court": court.toMap(),
    "slots": slots.map((UCourtSlotResponse x) => x.toMap()).toList(),
  };
}

class UBookingJson {
  UBookingJson({
    this.code,
    this.notes,
    this.participants = const <UBookingParticipant>[],
    this.paidAmount = 0,
    this.penalty = 0,
    this.refundAmount = 0,
    this.cancelReason,
    this.settled = false,
    this.detail1,
    this.detail2,
  });

  factory UBookingJson.fromJson(String str) => UBookingJson.fromMap(json.decode(str));

  factory UBookingJson.fromMap(Map<String, dynamic> json) => UBookingJson(
    code: json["code"],
    notes: json["notes"],
    participants: json["participants"] == null ? const <UBookingParticipant>[] : List<UBookingParticipant>.from(json["participants"].map((dynamic x) => UBookingParticipant.fromMap(x))),
    paidAmount: json["paidAmount"]?.toDouble() ?? 0,
    penalty: json["penalty"]?.toDouble() ?? 0,
    refundAmount: json["refundAmount"]?.toDouble() ?? 0,
    cancelReason: json["cancelReason"],
    settled: json["settled"] ?? false,
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  final String? code;
  final String? notes;
  final List<UBookingParticipant> participants;
  final double paidAmount;
  final double penalty;
  final double refundAmount;
  final String? cancelReason;
  final bool settled;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "code": code,
    "notes": notes,
    "participants": participants.map((UBookingParticipant x) => x.toMap()).toList(),
    "paidAmount": paidAmount,
    "penalty": penalty,
    "refundAmount": refundAmount,
    "cancelReason": cancelReason,
    "settled": settled,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UBookingResponse {
  UBookingResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.startAt,
    required this.endAt,
    required this.userId,
    required this.courtId,
    required this.venueId,
    this.creatorId,
    this.price = 0,
    this.participantIds = const <String>[],
    this.user,
    this.court,
    this.venue,
  });

  factory UBookingResponse.fromJson(String str) => UBookingResponse.fromMap(json.decode(str));

  factory UBookingResponse.fromMap(Map<String, dynamic> json) => UBookingResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBookingJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    creatorId: json["creatorId"],
    startAt: DateTime.parse(json["startAt"]),
    endAt: DateTime.parse(json["endAt"]),
    userId: json["userId"],
    courtId: json["courtId"],
    venueId: json["venueId"],
    price: json["price"]?.toDouble() ?? 0,
    participantIds: json["participantIds"] == null ? const <String>[] : List<String>.from(json["participantIds"].map((dynamic x) => x)),
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    court: json["court"] == null ? null : UCourtResponse.fromMap(json["court"]),
    venue: json["venue"] == null ? null : UVenueResponse.fromMap(json["venue"]),
  );

  final String id;
  final DateTime createdAt;
  final UBookingJson jsonData;
  final List<int> tags;
  final String? creatorId;
  final DateTime startAt;
  final DateTime endAt;
  final String userId;
  final String courtId;
  final String venueId;
  final double price;
  final List<String> participantIds;
  final UUserResponse? user;
  final UCourtResponse? court;
  final UVenueResponse? venue;

  TagBooking? get status => TagBooking.values.group(100).firstWhereOrNull((TagBooking t) => tags.contains(t.number));

  /// This user's share, if they share the price.
  UBookingParticipant? participant(String? userId) => jsonData.participants.firstWhereOrNull((UBookingParticipant p) => p.userId == userId);

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "creatorId": creatorId,
    "startAt": startAt.toIso8601String(),
    "endAt": endAt.toIso8601String(),
    "userId": userId,
    "courtId": courtId,
    "venueId": venueId,
    "price": price,
    "participantIds": participantIds,
    "user": user?.toMap(),
    "court": court?.toMap(),
    "venue": venue?.toMap(),
  };
}

class UVenueStatsResponse {
  UVenueStatsResponse({
    this.bookings = 0,
    this.upcoming = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.revenue = 0,
    this.occupancyPercent = 0,
  });

  factory UVenueStatsResponse.fromJson(String str) => UVenueStatsResponse.fromMap(json.decode(str));

  factory UVenueStatsResponse.fromMap(Map<String, dynamic> json) => UVenueStatsResponse(
    bookings: json["bookings"] ?? 0,
    upcoming: json["upcoming"] ?? 0,
    completed: json["completed"] ?? 0,
    cancelled: json["cancelled"] ?? 0,
    revenue: json["revenue"]?.toDouble() ?? 0,
    occupancyPercent: json["occupancyPercent"] ?? 0,
  );

  final int bookings;
  final int upcoming;
  final int completed;
  final int cancelled;
  final double revenue;
  final int occupancyPercent;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "bookings": bookings,
    "upcoming": upcoming,
    "completed": completed,
    "cancelled": cancelled,
    "revenue": revenue,
    "occupancyPercent": occupancyPercent,
  };
}
