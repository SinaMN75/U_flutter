part of "../data.dart";

class UHotelResponse {
  final String id;
  final DateTime createdAt;
  final UHotelJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String title;
  final String cityCode;
  final int stars;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final List<String> adminUserIds;
  final double averageScore;
  final int commentCount;
  final double? minPricePerNight;
  final int roomCount;
  final List<UHotelRoomResponse>? rooms;
  final List<UHotelReservationResponse>? reservations;
  final List<UCommentResponse>? comments;
  final List<UMediaResponse>? media;
  final String? organizationId;

  UHotelResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.cityCode,
    this.stars = 0,
    this.address,
    this.phoneNumber,
    this.email,
    this.adminUserIds = const <String>[],
    this.averageScore = 0,
    this.commentCount = 0,
    this.minPricePerNight,
    this.roomCount = 0,
    this.creator,
    this.creatorId,
    this.rooms,
    this.reservations,
    this.comments,
    this.media,
    this.organizationId,
  });

  factory UHotelResponse.fromJson(String str) => UHotelResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelResponse.fromMap(Map<String, dynamic> json) => UHotelResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UHotelJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    title: json["title"] as String,
    cityCode: json["cityCode"] as String,
    stars: json["stars"] == null ? 0 : (json["stars"] as num).toInt(),
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    averageScore: json["averageScore"] == null ? 0 : (json["averageScore"] as num).toDouble(),
    commentCount: json["commentCount"] == null ? 0 : (json["commentCount"] as num).toInt(),
    minPricePerNight: json["minPricePerNight"] == null ? null : (json["minPricePerNight"] as num).toDouble(),
    roomCount: json["roomCount"] ?? 0,
    rooms: json["rooms"] == null ? <UHotelRoomResponse>[] : List<UHotelRoomResponse>.from(json["rooms"]!.map((dynamic x) => UHotelRoomResponse.fromMap(x))),
    reservations: json["reservations"] == null ? <UHotelReservationResponse>[] : List<UHotelReservationResponse>.from(json["reservations"]!.map((dynamic x) => UHotelReservationResponse.fromMap(x))),
    comments: json["comments"] == null ? <UCommentResponse>[] : List<UCommentResponse>.from(json["comments"]!.map((dynamic x) => UCommentResponse.fromMap(x))),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"]!.map((dynamic x) => UMediaResponse.fromMap(x))),
    organizationId: json["organizationId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<int>.from(tags.map((int x) => x)),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "title": title,
    "cityCode": cityCode,
    "stars": stars,
    "address": address,
    "phoneNumber": phoneNumber,
    "email": email,
    "adminUserIds": List<String>.from(adminUserIds.map((String x) => x)),
    "averageScore": averageScore,
    "commentCount": commentCount,
    "minPricePerNight": minPricePerNight,
    "roomCount": roomCount,
    "rooms": rooms == null ? <UHotelRoomResponse>[] : List<UHotelRoomResponse>.from(rooms!.map((UHotelRoomResponse x) => x.toMap())),
    "reservations": reservations == null ? <UHotelReservationResponse>[] : List<UHotelReservationResponse>.from(reservations!.map((UHotelReservationResponse x) => x.toMap())),
    "comments": comments == null ? <UCommentResponse>[] : List<UCommentResponse>.from(comments!.map((UCommentResponse x) => x.toMap())),
    "media": media == null ? <UMediaResponse>[] : List<UMediaResponse>.from(media!.map((UMediaResponse x) => x.toMap())),
    "organizationId": organizationId,
  };
}

class UHotelRoomResponse {
  final String id;
  final DateTime createdAt;
  final UHotelRoomJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String title;
  final int capacity;
  final double pricePerNight;
  final String? roomNumber;
  final int quantity;
  final bool isAvailable;
  final String hotelId;
  final UHotelResponse? hotel;
  final List<UHotelReservationResponse>? reservations;
  final List<UMediaResponse>? media;
  final List<String> adminUserIds;

  UHotelRoomResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.capacity,
    required this.pricePerNight,
    required this.hotelId,
    required this.adminUserIds,
    this.roomNumber,
    this.quantity = 1,
    this.isAvailable = true,
    this.creator,
    this.creatorId,
    this.hotel,
    this.reservations,
    this.media,
  });

  factory UHotelRoomResponse.fromJson(String str) => UHotelRoomResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelRoomResponse.fromMap(Map<String, dynamic> json) => UHotelRoomResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UHotelRoomJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    title: json["title"] as String,
    capacity: json["capacity"] as int,
    pricePerNight: (json["pricePerNight"] as num).toDouble(),
    roomNumber: json["roomNumber"],
    quantity: json["quantity"] == null ? 1 : (json["quantity"] as num).toInt(),
    isAvailable: json["isAvailable"] == null || json["isAvailable"] as bool,
    hotelId: json["hotelId"] as String,
    hotel: json["hotel"] == null ? null : UHotelResponse.fromMap(json["hotel"]),
    reservations: json["reservations"] == null ? <UHotelReservationResponse>[] : List<UHotelReservationResponse>.from(json["reservations"]!.map((dynamic x) => UHotelReservationResponse.fromMap(x))),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"]!.map((dynamic x) => UMediaResponse.fromMap(x))),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<int>.from(tags.map((int x) => x)),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "title": title,
    "capacity": capacity,
    "pricePerNight": pricePerNight,
    "roomNumber": roomNumber,
    "quantity": quantity,
    "isAvailable": isAvailable,
    "hotelId": hotelId,
    "hotel": hotel?.toMap(),
    "reservations": reservations == null ? <UHotelReservationResponse>[] : List<UHotelReservationResponse>.from(reservations!.map((UHotelReservationResponse x) => x.toMap())),
    "media": media == null ? <UMediaResponse>[] : List<UMediaResponse>.from(media!.map((UMediaResponse x) => x.toMap())),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UHotelJson {
  UHotelJson({
    this.detail1,
    this.detail2,
    this.description,
    this.policies,
    this.checkInTime,
    this.checkOutTime,
    this.highlights = const <String>[],
    this.rules = const <String>[],
    this.howToGetThere,
    this.nearby = const <UPlaceNearby>[],
    this.faqs = const <UPlaceFaq>[],
    this.website,
    this.whatsapp,
    this.instagram,
    this.telegram,
    this.latitude,
    this.longitude,
    this.cancellationFreeHours = 24,
    this.cancellationPenaltyNights = 1,
  });

  factory UHotelJson.fromJson(String str) => UHotelJson.fromMap(json.decode(str));

  factory UHotelJson.fromMap(Map<String, dynamic> json) => UHotelJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    description: json["description"],
    policies: json["policies"],
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    highlights: json["highlights"] == null ? <String>[] : List<String>.from((json["highlights"] as List<dynamic>).map((dynamic e) => e.toString())),
    rules: json["rules"] == null ? <String>[] : List<String>.from((json["rules"] as List<dynamic>).map((dynamic e) => e.toString())),
    howToGetThere: json["howToGetThere"],
    nearby: json["nearby"] == null ? <UPlaceNearby>[] : List<UPlaceNearby>.from((json["nearby"] as List<dynamic>).map((dynamic e) => UPlaceNearby.fromMap(e))),
    faqs: json["faqs"] == null ? <UPlaceFaq>[] : List<UPlaceFaq>.from((json["faqs"] as List<dynamic>).map((dynamic e) => UPlaceFaq.fromMap(e))),
    website: json["website"],
    whatsapp: json["whatsapp"],
    instagram: json["instagram"],
    telegram: json["telegram"],
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
    cancellationFreeHours: json["cancellationFreeHours"] == null ? 24 : (json["cancellationFreeHours"] as num).toInt(),
    cancellationPenaltyNights: json["cancellationPenaltyNights"] == null ? 1 : (json["cancellationPenaltyNights"] as num).toInt(),
  );

  final String? detail1;
  final String? detail2;
  final String? description;
  final String? policies;
  final String? checkInTime;
  final String? checkOutTime;
  final List<String> highlights;
  final List<String> rules;
  final String? howToGetThere;
  final List<UPlaceNearby> nearby;
  final List<UPlaceFaq> faqs;
  final String? website;
  final String? whatsapp;
  final String? instagram;
  final String? telegram;
  final double? latitude;
  final double? longitude;
  final int cancellationFreeHours;
  final int cancellationPenaltyNights;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "description": description,
    "policies": policies,
    "checkInTime": checkInTime,
    "checkOutTime": checkOutTime,
    "highlights": highlights,
    "rules": rules,
    "howToGetThere": howToGetThere,
    "nearby": nearby.map((UPlaceNearby e) => e.toMap()).toList(),
    "faqs": faqs.map((UPlaceFaq e) => e.toMap()).toList(),
    "website": website,
    "whatsapp": whatsapp,
    "instagram": instagram,
    "telegram": telegram,
    "latitude": latitude,
    "longitude": longitude,
    "cancellationFreeHours": cancellationFreeHours,
    "cancellationPenaltyNights": cancellationPenaltyNights,
  };
}

class UHotelRoomJson {
  UHotelRoomJson({
    this.detail1,
    this.detail2,
    this.description,
    this.bedType,
    this.sizeSquareMeters,
    this.floor,
    this.extraGuestCapacity,
    this.extraGuestPrice,
  });

  factory UHotelRoomJson.fromJson(String str) => UHotelRoomJson.fromMap(json.decode(str));

  factory UHotelRoomJson.fromMap(Map<String, dynamic> json) => UHotelRoomJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    description: json["description"],
    bedType: json["bedType"],
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    extraGuestCapacity: json["extraGuestCapacity"] == null ? null : (json["extraGuestCapacity"] as num).toInt(),
    extraGuestPrice: json["extraGuestPrice"] == null ? null : (json["extraGuestPrice"] as num).toDouble(),
  );

  final String? detail1;
  final String? detail2;
  final String? description;
  final String? bedType;
  final double? sizeSquareMeters;
  final int? floor;
  final int? extraGuestCapacity;
  final double? extraGuestPrice;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "description": description,
    "bedType": bedType,
    "sizeSquareMeters": sizeSquareMeters,
    "floor": floor,
    "extraGuestCapacity": extraGuestCapacity,
    "extraGuestPrice": extraGuestPrice,
  };
}

class UHotelReservationJson {
  final String? detail1;
  final String? detail2;
  final String? guestName;
  final String? guestPhone;
  final String? notes;
  final int? nightCount;
  final String? reservationCode;
  final List<UReservationGuestJson> guests;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final double? cancellationPenalty;
  final double? refundAmount;

  UHotelReservationJson({
    this.detail1,
    this.detail2,
    this.guestName,
    this.guestPhone,
    this.notes,
    this.nightCount,
    this.reservationCode,
    this.guests = const <UReservationGuestJson>[],
    this.cancelledAt,
    this.cancelReason,
    this.cancellationPenalty,
    this.refundAmount,
  });

  factory UHotelReservationJson.fromJson(String str) => UHotelReservationJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReservationJson.fromMap(Map<String, dynamic> json) => UHotelReservationJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    guestName: json["guestName"],
    guestPhone: json["guestPhone"],
    notes: json["notes"],
    nightCount: json["nightCount"] == null ? null : (json["nightCount"] as num).toInt(),
    reservationCode: json["reservationCode"],
    guests: json["guests"] == null ? <UReservationGuestJson>[] : List<UReservationGuestJson>.from(json["guests"]!.map((dynamic x) => UReservationGuestJson.fromMap(x))),
    cancelledAt: json["cancelledAt"] == null ? null : DateTime.parse(json["cancelledAt"]),
    cancelReason: json["cancelReason"],
    cancellationPenalty: json["cancellationPenalty"] == null ? null : (json["cancellationPenalty"] as num).toDouble(),
    refundAmount: json["refundAmount"] == null ? null : (json["refundAmount"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "guestName": guestName,
    "guestPhone": guestPhone,
    "notes": notes,
    "nightCount": nightCount,
    "reservationCode": reservationCode,
    "guests": List<dynamic>.from(guests.map((UReservationGuestJson x) => x.toMap())),
    "cancelledAt": cancelledAt?.toIso8601String(),
    "cancelReason": cancelReason,
    "cancellationPenalty": cancellationPenalty,
    "refundAmount": refundAmount,
  };
}

class UReservationGuestJson {
  final String fullName;
  final String? nationalCode;
  final String? phoneNumber;

  UReservationGuestJson({required this.fullName, this.nationalCode, this.phoneNumber});

  factory UReservationGuestJson.fromJson(String str) => UReservationGuestJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UReservationGuestJson.fromMap(Map<String, dynamic> json) => UReservationGuestJson(
    fullName: json["fullName"] as String,
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "fullName": fullName,
    "nationalCode": nationalCode,
    "phoneNumber": phoneNumber,
  };
}

class UHotelInvoiceJson {
  final String? detail1;
  final String? detail2;
  final int? penaltyPrecentEveryDate;

  UHotelInvoiceJson({
    this.detail1,
    this.detail2,
    this.penaltyPrecentEveryDate,
  });

  factory UHotelInvoiceJson.fromJson(String str) => UHotelInvoiceJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelInvoiceJson.fromMap(Map<String, dynamic> json) => UHotelInvoiceJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    penaltyPrecentEveryDate: json["penaltyPrecentEveryDate"] == null ? null : (json["penaltyPrecentEveryDate"] as num).toInt(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
  };
}

extension UHotelReservationStatusX on UHotelReservationResponse {
  TagHotelReservation? get status {
    for (final TagHotelReservation t in TagHotelReservation.values) {
      if (tags.contains(t.number)) return t;
    }
    return null;
  }

  bool get isCancelled => tags.contains(TagHotelReservation.cancelled.number) || tags.contains(TagHotelReservation.noShow.number);
}

extension UHotelInvoiceStatusX on UHotelInvoiceResponse {
  double get netDue => debtAmount + penaltyAmount - creditorAmount - paidAmount;

  bool get isPaid {
    final bool taggedPaid = tags.contains(TagHotelInvoice.paid.number) || tags.contains(TagHotelInvoice.paidOnline.number) || tags.contains(TagHotelInvoice.paidManual.number);
    return taggedPaid || netDue <= 0;
  }

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
}

class UHotelReservationResponse {
  final String id;
  final DateTime createdAt;
  final UHotelReservationJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final double totalPrice;
  final String userId;
  final UUserResponse? user;
  final String roomId;
  final UHotelRoomResponse? room;
  final String hotelId;
  final UHotelResponse? hotel;
  final bool isActive;
  final List<UHotelInvoiceResponse>? invoices;
  final List<String> adminUserIds;

  UHotelReservationResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.totalPrice,
    required this.userId,
    required this.roomId,
    required this.hotelId,
    required this.isActive,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
    this.user,
    this.room,
    this.hotel,
    this.invoices,
  });

  factory UHotelReservationResponse.fromJson(String str) => UHotelReservationResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReservationResponse.fromMap(Map<String, dynamic> json) => UHotelReservationResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UHotelReservationJson.fromMap(json["jsonData"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    checkInDate: DateTime.parse(json["checkInDate"]),
    checkOutDate: DateTime.parse(json["checkOutDate"]),
    guestCount: json["guestCount"] == null ? 1 : (json["guestCount"] as num).toInt(),
    totalPrice: (json["totalPrice"] as num).toDouble(),
    userId: json["userId"] as String,
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    roomId: json["roomId"] as String,
    room: json["room"] == null ? null : UHotelRoomResponse.fromMap(json["room"]),
    hotelId: json["hotelId"] as String,
    hotel: json["hotel"] == null ? null : UHotelResponse.fromMap(json["hotel"]),
    isActive: !(json["isActive"] == null) && json["isActive"] as bool,
    invoices: json["invoices"] == null ? <UHotelInvoiceResponse>[] : List<UHotelInvoiceResponse>.from(json["invoices"]!.map((dynamic x) => UHotelInvoiceResponse.fromMap(x))),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "checkInDate": checkInDate.toIso8601String(),
    "checkOutDate": checkOutDate.toIso8601String(),
    "guestCount": guestCount,
    "totalPrice": totalPrice,
    "userId": userId,
    "user": user?.toMap(),
    "roomId": roomId,
    "room": room?.toMap(),
    "hotelId": hotelId,
    "hotel": hotel?.toMap(),
    "isActive": isActive,
    "invoices": invoices == null ? <dynamic>[] : List<dynamic>.from(invoices!.map((UHotelInvoiceResponse x) => x.toMap())),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UHotelInvoiceResponse {
  final String id;
  final DateTime createdAt;
  final UHotelInvoiceJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final double debtAmount;
  final double creditorAmount;
  final double paidAmount;
  final double penaltyAmount;
  final DateTime dueDate;
  final String? reservationId;
  final UHotelReservationResponse? reservation;
  final List<String> adminUserIds;

  UHotelInvoiceResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.dueDate,
    required this.debtAmount,
    required this.creditorAmount,
    required this.paidAmount,
    required this.penaltyAmount,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
    this.reservationId,
    this.reservation,
  });

  factory UHotelInvoiceResponse.fromJson(String str) => UHotelInvoiceResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelInvoiceResponse.fromMap(Map<String, dynamic> json) => UHotelInvoiceResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UHotelInvoiceJson.fromMap(json["jsonData"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    debtAmount: (json["debtAmount"] as num).toDouble(),
    creditorAmount: (json["creditorAmount"] as num).toDouble(),
    paidAmount: (json["paidAmount"] as num).toDouble(),
    penaltyAmount: (json["penaltyAmount"] as num).toDouble(),
    dueDate: DateTime.parse(json["dueDate"]),
    reservationId: json["reservationId"],
    reservation: json["reservation"] == null ? null : UHotelReservationResponse.fromMap(json["reservation"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "debtAmount": debtAmount,
    "creditorAmount": creditorAmount,
    "paidAmount": paidAmount,
    "penaltyAmount": penaltyAmount,
    "dueDate": dueDate.toIso8601String(),
    "reservationId": reservationId,
    "reservation": reservation?.toMap(),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UHotelRoomAvailabilityResponse {
  final UHotelRoomResponse room;
  final int availableQuantity;
  final int nightCount;
  final double totalPrice;
  final bool fitsGuestCount;

  UHotelRoomAvailabilityResponse({
    required this.room,
    required this.availableQuantity,
    required this.nightCount,
    required this.totalPrice,
    required this.fitsGuestCount,
  });

  bool get isBookable => availableQuantity > 0 && fitsGuestCount;

  factory UHotelRoomAvailabilityResponse.fromJson(String str) => UHotelRoomAvailabilityResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelRoomAvailabilityResponse.fromMap(Map<String, dynamic> json) => UHotelRoomAvailabilityResponse(
    room: UHotelRoomResponse.fromMap(json["room"]),
    availableQuantity: (json["availableQuantity"] as num).toInt(),
    nightCount: (json["nightCount"] as num).toInt(),
    totalPrice: (json["totalPrice"] as num).toDouble(),
    fitsGuestCount: json["fitsGuestCount"] ?? true,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "room": room.toMap(),
    "availableQuantity": availableQuantity,
    "nightCount": nightCount,
    "totalPrice": totalPrice,
    "fitsGuestCount": fitsGuestCount,
  };
}

class UHotelDashboardResponse {
  UHotelDashboardResponse({
    required this.generatedAt,
    this.guestsCount = 0,
    this.newGuestsCount = 0,
    this.hotelsCount = 0,
    this.hotelRoomsCount = 0,
    this.hotelRoomsAvailableCount = 0,
    this.hotelRoomsOccupiedCount = 0,
    this.hotelOccupancyRate = 0,
    this.reservationsCount = 0,
    this.recentGuests = const <URecentUserItem>[],
    this.hotelsByCity = const <UHotelCityItem>[],
  });

  factory UHotelDashboardResponse.fromMap(Map<String, dynamic> json) => UHotelDashboardResponse(
    generatedAt: DateTime.parse(json["generatedAt"]),
    guestsCount: json["guestsCount"] ?? 0,
    newGuestsCount: json["newGuestsCount"] ?? 0,
    hotelsCount: json["hotelsCount"] ?? 0,
    hotelRoomsCount: json["hotelRoomsCount"] ?? 0,
    hotelRoomsAvailableCount: json["hotelRoomsAvailableCount"] ?? 0,
    hotelRoomsOccupiedCount: json["hotelRoomsOccupiedCount"] ?? 0,
    hotelOccupancyRate: (json["hotelOccupancyRate"] ?? 0).toString().toDouble(),
    reservationsCount: json["reservationsCount"] ?? 0,
    recentGuests: ((json["recentGuests"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => URecentUserItem.fromMap(x)).toList(),
    hotelsByCity: ((json["hotelsByCity"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UHotelCityItem.fromMap(x)).toList(),
  );

  final DateTime generatedAt;
  final int guestsCount;
  final int newGuestsCount;
  final int hotelsCount;
  final int hotelRoomsCount;
  final int hotelRoomsAvailableCount;
  final int hotelRoomsOccupiedCount;
  final double hotelOccupancyRate;
  final int reservationsCount;
  final List<URecentUserItem> recentGuests;
  final List<UHotelCityItem> hotelsByCity;
}

class UHotelCityItem {
  UHotelCityItem({required this.name, required this.count});

  factory UHotelCityItem.fromMap(Map<String, dynamic> json) => UHotelCityItem(name: json["name"] ?? "", count: json["count"] ?? 0);

  final String name;
  final int count;
}
