part of "../data.dart";

class UHotelCreateParams {
  UHotelCreateParams({
    required this.tags,
    required this.title,
    required this.cityCode,
    this.stars = 0,
    this.id,
    this.creatorId,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.address,
    this.phoneNumber,
    this.email,
    this.description,
    this.policies,
    this.checkInTime,
    this.checkOutTime,
    this.highlights,
    this.rules,
    this.howToGetThere,
    this.nearby,
    this.faqs,
    this.website,
    this.whatsapp,
    this.instagram,
    this.telegram,
    this.latitude,
    this.longitude,
    this.cancellationFreeHours,
    this.cancellationPenaltyNights,
    this.organizationId,
  });

  factory UHotelCreateParams.fromJson(String str) => UHotelCreateParams.fromMap(json.decode(str));

  factory UHotelCreateParams.fromMap(Map<String, dynamic> json) => UHotelCreateParams(
    tags: json["tags"] == null ? <int>[] : List<int>.from((json["tags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    id: json["id"],
    creatorId: json["creatorId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from((json["adminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    title: json["title"],
    cityCode: json["cityCode"],
    stars: json["stars"] ?? 0,
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    description: json["description"],
    policies: json["policies"],
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    highlights: json["highlights"] == null ? null : List<String>.from((json["highlights"] as List<dynamic>).map((dynamic e) => e.toString())),
    rules: json["rules"] == null ? null : List<String>.from((json["rules"] as List<dynamic>).map((dynamic e) => e.toString())),
    howToGetThere: json["howToGetThere"],
    nearby: json["nearby"] == null ? null : List<UPlaceNearby>.from((json["nearby"] as List<dynamic>).map((dynamic e) => UPlaceNearby.fromMap(e))),
    faqs: json["faqs"] == null ? null : List<UPlaceFaq>.from((json["faqs"] as List<dynamic>).map((dynamic e) => UPlaceFaq.fromMap(e))),
    website: json["website"],
    whatsapp: json["whatsapp"],
    instagram: json["instagram"],
    telegram: json["telegram"],
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
    cancellationFreeHours: json["cancellationFreeHours"] == null ? null : (json["cancellationFreeHours"] as num).toInt(),
    cancellationPenaltyNights: json["cancellationPenaltyNights"] == null ? null : (json["cancellationPenaltyNights"] as num).toInt(),
    organizationId: json["organizationId"],
  );

  final List<int> tags;
  final String? id;
  final String? creatorId;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final String title;
  final String cityCode;
  final int stars;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? description;
  final String? policies;
  final String? checkInTime;
  final String? checkOutTime;
  final List<String>? highlights;
  final List<String>? rules;
  final String? howToGetThere;
  final List<UPlaceNearby>? nearby;
  final List<UPlaceFaq>? faqs;
  final String? website;
  final String? whatsapp;
  final String? instagram;
  final String? telegram;
  final double? latitude;
  final double? longitude;
  final int? cancellationFreeHours;
  final int? cancellationPenaltyNights;
  final String? organizationId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "id": id,
    "creatorId": creatorId,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds,
    "title": title,
    "cityCode": cityCode,
    "stars": stars,
    "address": address,
    "phoneNumber": phoneNumber,
    "email": email,
    "description": description,
    "policies": policies,
    "checkInTime": checkInTime,
    "checkOutTime": checkOutTime,
    "highlights": highlights,
    "rules": rules,
    "howToGetThere": howToGetThere,
    "nearby": nearby?.map((UPlaceNearby e) => e.toMap()).toList(),
    "faqs": faqs?.map((UPlaceFaq e) => e.toMap()).toList(),
    "website": website,
    "whatsapp": whatsapp,
    "instagram": instagram,
    "telegram": telegram,
    "latitude": latitude,
    "longitude": longitude,
    "cancellationFreeHours": cancellationFreeHours,
    "cancellationPenaltyNights": cancellationPenaltyNights,
    "organizationId": organizationId,
  };
}

class UHotelUpdateParams {
  UHotelUpdateParams({
    required this.id,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.title,
    this.cityCode,
    this.stars,
    this.address,
    this.phoneNumber,
    this.email,
    this.description,
    this.policies,
    this.checkInTime,
    this.checkOutTime,
    this.highlights,
    this.rules,
    this.howToGetThere,
    this.nearby,
    this.faqs,
    this.website,
    this.whatsapp,
    this.instagram,
    this.telegram,
    this.latitude,
    this.longitude,
    this.cancellationFreeHours,
    this.cancellationPenaltyNights,
    this.organizationId,
  });

  factory UHotelUpdateParams.fromJson(String str) => UHotelUpdateParams.fromMap(json.decode(str));

  factory UHotelUpdateParams.fromMap(Map<String, dynamic> json) => UHotelUpdateParams(
    id: json["id"],
    tags: json["tags"] == null ? null : List<int>.from((json["tags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    addTags: json["addTags"] == null ? null : List<int>.from((json["addTags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    removeTags: json["removeTags"] == null ? null : List<int>.from((json["removeTags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from((json["adminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    addAdminUserIds: json["addAdminUserIds"] == null ? null : List<String>.from((json["addAdminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? null : List<String>.from((json["removeAdminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    title: json["title"],
    cityCode: json["cityCode"],
    stars: json["stars"] == null ? null : (json["stars"] as num).toInt(),
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    description: json["description"],
    policies: json["policies"],
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    highlights: json["highlights"] == null ? null : List<String>.from((json["highlights"] as List<dynamic>).map((dynamic e) => e.toString())),
    rules: json["rules"] == null ? null : List<String>.from((json["rules"] as List<dynamic>).map((dynamic e) => e.toString())),
    howToGetThere: json["howToGetThere"],
    nearby: json["nearby"] == null ? null : List<UPlaceNearby>.from((json["nearby"] as List<dynamic>).map((dynamic e) => UPlaceNearby.fromMap(e))),
    faqs: json["faqs"] == null ? null : List<UPlaceFaq>.from((json["faqs"] as List<dynamic>).map((dynamic e) => UPlaceFaq.fromMap(e))),
    website: json["website"],
    whatsapp: json["whatsapp"],
    instagram: json["instagram"],
    telegram: json["telegram"],
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
    cancellationFreeHours: json["cancellationFreeHours"] == null ? null : (json["cancellationFreeHours"] as num).toInt(),
    cancellationPenaltyNights: json["cancellationPenaltyNights"] == null ? null : (json["cancellationPenaltyNights"] as num).toInt(),
    organizationId: json["organizationId"],
  );

  final String id;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final String? title;
  final String? cityCode;
  final int? stars;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? description;
  final String? policies;
  final String? checkInTime;
  final String? checkOutTime;
  final List<String>? highlights;
  final List<String>? rules;
  final String? howToGetThere;
  final List<UPlaceNearby>? nearby;
  final List<UPlaceFaq>? faqs;
  final String? website;
  final String? whatsapp;
  final String? instagram;
  final String? telegram;
  final double? latitude;
  final double? longitude;
  final int? cancellationFreeHours;
  final int? cancellationPenaltyNights;
  final String? organizationId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds,
    "addAdminUserIds": addAdminUserIds,
    "removeAdminUserIds": removeAdminUserIds,
    "title": title,
    "cityCode": cityCode,
    "stars": stars,
    "address": address,
    "phoneNumber": phoneNumber,
    "email": email,
    "description": description,
    "policies": policies,
    "checkInTime": checkInTime,
    "checkOutTime": checkOutTime,
    "highlights": highlights,
    "rules": rules,
    "howToGetThere": howToGetThere,
    "nearby": nearby?.map((UPlaceNearby e) => e.toMap()).toList(),
    "faqs": faqs?.map((UPlaceFaq e) => e.toMap()).toList(),
    "website": website,
    "whatsapp": whatsapp,
    "instagram": instagram,
    "telegram": telegram,
    "latitude": latitude,
    "longitude": longitude,
    "cancellationFreeHours": cancellationFreeHours,
    "cancellationPenaltyNights": cancellationPenaltyNights,
    "organizationId": organizationId,
  };
}

class UHotelReadParams {
  final double? minPrice;
  final double? maxPrice;
  final double? minScore;
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? title;
  final String? cityCode;
  final int? minStars;
  final int? orderBy;
  final UHotelSelectorArgs? selectorArgs;
  final String? organizationId;

  UHotelReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.title,
    this.cityCode,
    this.minStars,
    this.orderBy,
    this.selectorArgs,
    this.minPrice,
    this.maxPrice,
    this.minScore,
    this.organizationId,
  });

  factory UHotelReadParams.fromJson(String str) => UHotelReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReadParams.fromMap(Map<String, dynamic> json) => UHotelReadParams(
    minPrice: json["minPrice"] == null ? null : (json["minPrice"] as num).toDouble(),
    maxPrice: json["maxPrice"] == null ? null : (json["maxPrice"] as num).toDouble(),
    minScore: json["minScore"] == null ? null : (json["minScore"] as num).toDouble(),
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    cityCode: json["cityCode"],
    minStars: json["minStars"],
    orderBy: json["orderBy"],
    selectorArgs: json["selectorArgs"] == null ? null : UHotelSelectorArgs.fromMap(json["selectorArgs"]),
    organizationId: json["organizationId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "minPrice": minPrice,
    "maxPrice": maxPrice,
    "minScore": minScore,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "title": title,
    "cityCode": cityCode,
    "minStars": minStars,
    "orderBy": orderBy,
    "selectorArgs": selectorArgs?.toMap(),
    "organizationId": organizationId,
  };
}

class UHotelRoomCreateParams {
  UHotelRoomCreateParams({
    required this.tags,
    required this.title,
    required this.capacity,
    required this.pricePerNight,
    required this.hotelId,
    this.quantity = 1,
    this.isAvailable = true,
    this.id,
    this.creatorId,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.roomNumber,
    this.description,
    this.bedType,
    this.sizeSquareMeters,
    this.floor,
    this.extraGuestCapacity,
    this.extraGuestPrice,
  });

  factory UHotelRoomCreateParams.fromJson(String str) => UHotelRoomCreateParams.fromMap(json.decode(str));

  factory UHotelRoomCreateParams.fromMap(Map<String, dynamic> json) => UHotelRoomCreateParams(
    tags: json["tags"] == null ? <int>[] : List<int>.from((json["tags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    id: json["id"],
    creatorId: json["creatorId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from((json["adminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    title: json["title"],
    capacity: (json["capacity"] as num).toInt(),
    pricePerNight: (json["pricePerNight"] as num).toDouble(),
    hotelId: json["hotelId"],
    roomNumber: json["roomNumber"],
    quantity: json["quantity"] ?? 1,
    isAvailable: json["isAvailable"] ?? true,
    description: json["description"],
    bedType: json["bedType"],
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    extraGuestCapacity: json["extraGuestCapacity"] == null ? null : (json["extraGuestCapacity"] as num).toInt(),
    extraGuestPrice: json["extraGuestPrice"] == null ? null : (json["extraGuestPrice"] as num).toDouble(),
  );

  final List<int> tags;
  final String? id;
  final String? creatorId;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final String title;
  final int capacity;
  final double pricePerNight;
  final String hotelId;
  final String? roomNumber;
  final int quantity;
  final bool isAvailable;
  final String? description;
  final String? bedType;
  final double? sizeSquareMeters;
  final int? floor;
  final int? extraGuestCapacity;
  final double? extraGuestPrice;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "id": id,
    "creatorId": creatorId,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds,
    "title": title,
    "capacity": capacity,
    "pricePerNight": pricePerNight,
    "hotelId": hotelId,
    "roomNumber": roomNumber,
    "quantity": quantity,
    "isAvailable": isAvailable,
    "description": description,
    "bedType": bedType,
    "sizeSquareMeters": sizeSquareMeters,
    "floor": floor,
    "extraGuestCapacity": extraGuestCapacity,
    "extraGuestPrice": extraGuestPrice,
  };
}

class UHotelRoomUpdateParams {
  UHotelRoomUpdateParams({
    required this.id,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.title,
    this.capacity,
    this.pricePerNight,
    this.hotelId,
    this.roomNumber,
    this.quantity,
    this.isAvailable,
    this.description,
    this.bedType,
    this.sizeSquareMeters,
    this.floor,
    this.extraGuestCapacity,
    this.extraGuestPrice,
  });

  factory UHotelRoomUpdateParams.fromJson(String str) => UHotelRoomUpdateParams.fromMap(json.decode(str));

  factory UHotelRoomUpdateParams.fromMap(Map<String, dynamic> json) => UHotelRoomUpdateParams(
    id: json["id"],
    tags: json["tags"] == null ? null : List<int>.from((json["tags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    addTags: json["addTags"] == null ? null : List<int>.from((json["addTags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    removeTags: json["removeTags"] == null ? null : List<int>.from((json["removeTags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from((json["adminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    addAdminUserIds: json["addAdminUserIds"] == null ? null : List<String>.from((json["addAdminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? null : List<String>.from((json["removeAdminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    title: json["title"],
    capacity: json["capacity"] == null ? null : (json["capacity"] as num).toInt(),
    pricePerNight: json["pricePerNight"] == null ? null : (json["pricePerNight"] as num).toDouble(),
    hotelId: json["hotelId"],
    roomNumber: json["roomNumber"],
    quantity: json["quantity"] == null ? null : (json["quantity"] as num).toInt(),
    isAvailable: json["isAvailable"],
    description: json["description"],
    bedType: json["bedType"],
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    extraGuestCapacity: json["extraGuestCapacity"] == null ? null : (json["extraGuestCapacity"] as num).toInt(),
    extraGuestPrice: json["extraGuestPrice"] == null ? null : (json["extraGuestPrice"] as num).toDouble(),
  );

  final String id;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final String? title;
  final int? capacity;
  final double? pricePerNight;
  final String? hotelId;
  final String? roomNumber;
  final int? quantity;
  final bool? isAvailable;
  final String? description;
  final String? bedType;
  final double? sizeSquareMeters;
  final int? floor;
  final int? extraGuestCapacity;
  final double? extraGuestPrice;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "tags": tags,
    "addTags": addTags,
    "removeTags": removeTags,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds,
    "addAdminUserIds": addAdminUserIds,
    "removeAdminUserIds": removeAdminUserIds,
    "title": title,
    "capacity": capacity,
    "pricePerNight": pricePerNight,
    "hotelId": hotelId,
    "roomNumber": roomNumber,
    "quantity": quantity,
    "isAvailable": isAvailable,
    "description": description,
    "bedType": bedType,
    "sizeSquareMeters": sizeSquareMeters,
    "floor": floor,
    "extraGuestCapacity": extraGuestCapacity,
    "extraGuestPrice": extraGuestPrice,
  };
}

class UHotelRoomReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? title;
  final String? hotelId;
  final double? minPrice;
  final double? maxPrice;
  final bool? availableOnly;
  final UHotelRoomSelectorArgs? selectorArgs;
  final int? orderBy;
  final int? minCapacity;
  final int? maxCapacity;

  UHotelRoomReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.title,
    this.hotelId,
    this.minPrice,
    this.maxPrice,
    this.availableOnly,
    this.selectorArgs,
    this.orderBy,
    this.minCapacity,
    this.maxCapacity,
  });

  factory UHotelRoomReadParams.fromJson(String str) => UHotelRoomReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelRoomReadParams.fromMap(Map<String, dynamic> json) => UHotelRoomReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    hotelId: json["hotelId"],
    minPrice: json["minPrice"]?.toDouble(),
    maxPrice: json["maxPrice"]?.toDouble(),
    availableOnly: json["availableOnly"],
    selectorArgs: json["selectorArgs"] == null ? null : UHotelRoomSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    minCapacity: json["minCapacity"],
    maxCapacity: json["maxCapacity"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "title": title,
    "hotelId": hotelId,
    "minPrice": minPrice,
    "maxPrice": maxPrice,
    "availableOnly": availableOnly,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "minCapacity": minCapacity,
    "maxCapacity": maxCapacity,
  };
}

class UHotelReservationCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final String userId;
  final String roomId;
  final double? totalPrice;
  final String? guestName;
  final String? guestPhone;
  final String? notes;
  final int? penaltyPrecentEveryDate;
  final List<String>? adminUserIds;
  final List<UReservationGuestParams>? guests;
  final String? roomNumber;

  UHotelReservationCreateParams({
    required this.tags,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.userId,
    required this.roomId,
    this.totalPrice,
    this.guestName,
    this.guestPhone,
    this.notes,
    this.penaltyPrecentEveryDate,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
    this.guests,
    this.roomNumber,
  });

  factory UHotelReservationCreateParams.fromJson(String str) => UHotelReservationCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReservationCreateParams.fromMap(Map<String, dynamic> json) => UHotelReservationCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    checkInDate: DateTime.parse(json["checkInDate"]),
    checkOutDate: DateTime.parse(json["checkOutDate"]),
    guestCount: json["guestCount"],
    userId: json["userId"],
    roomId: json["roomId"],
    totalPrice: json["totalPrice"]?.toDouble(),
    guestName: json["guestName"],
    guestPhone: json["guestPhone"],
    notes: json["notes"],
    penaltyPrecentEveryDate: json["penaltyPrecentEveryDate"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    guests: json["guests"] == null ? null : List<UReservationGuestParams>.from(json["guests"]!.map((dynamic x) => UReservationGuestParams.fromMap(x))),
    roomNumber: json["roomNumber"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
    "checkInDate": checkInDate.toIso8601String(),
    "checkOutDate": checkOutDate.toIso8601String(),
    "guestCount": guestCount,
    "userId": userId,
    "roomId": roomId,
    "totalPrice": totalPrice,
    "guestName": guestName,
    "guestPhone": guestPhone,
    "notes": notes,
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "guests": guests == null ? <dynamic>[] : List<dynamic>.from(guests!.map((UReservationGuestParams x) => x.toMap())),
    "roomNumber": roomNumber,
  };
}

class UHotelReservationUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int? guestCount;
  final double? totalPrice;
  final String? guestName;
  final String? guestPhone;
  final String? notes;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final List<UReservationGuestParams>? guests;
  final String? roomNumber;

  UHotelReservationUpdateParams({
    required this.id,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
    this.checkInDate,
    this.checkOutDate,
    this.guestCount,
    this.totalPrice,
    this.guestName,
    this.guestPhone,
    this.notes,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.guests,
    this.roomNumber,
  });

  factory UHotelReservationUpdateParams.fromJson(String str) => UHotelReservationUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReservationUpdateParams.fromMap(Map<String, dynamic> json) => UHotelReservationUpdateParams(
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    checkInDate: json["checkInDate"] == null ? null : DateTime.parse(json["checkInDate"]),
    checkOutDate: json["checkOutDate"] == null ? null : DateTime.parse(json["checkOutDate"]),
    guestCount: json["guestCount"],
    totalPrice: json["totalPrice"]?.toDouble(),
    guestName: json["guestName"],
    guestPhone: json["guestPhone"],
    notes: json["notes"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    guests: json["guests"] == null ? null : List<UReservationGuestParams>.from(json["guests"]!.map((dynamic x) => UReservationGuestParams.fromMap(x))),
    roomNumber: json["roomNumber"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "checkInDate": checkInDate?.toIso8601String(),
    "checkOutDate": checkOutDate?.toIso8601String(),
    "guestCount": guestCount,
    "totalPrice": totalPrice,
    "guestName": guestName,
    "guestPhone": guestPhone,
    "notes": notes,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "guests": guests == null ? <dynamic>[] : List<dynamic>.from(guests!.map((UReservationGuestParams x) => x.toMap())),
    "roomNumber": roomNumber,
  };
}

class UHotelReservationReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? userId;
  final String? userName;
  final String? roomId;
  final String? hotelId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final bool? activeOnly;
  final bool? upcomingOnly;
  final bool? pastOnly;
  final int? orderBy;
  final UHotelReservationSelectorArgs? selectorArgs;

  UHotelReservationReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.userId,
    this.userName,
    this.roomId,
    this.hotelId,
    this.checkInDate,
    this.checkOutDate,
    this.activeOnly,
    this.upcomingOnly,
    this.pastOnly,
    this.orderBy,
    this.selectorArgs,
  });

  factory UHotelReservationReadParams.fromJson(String str) => UHotelReservationReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReservationReadParams.fromMap(Map<String, dynamic> json) => UHotelReservationReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    userId: json["userId"],
    userName: json["userName"],
    roomId: json["roomId"],
    hotelId: json["hotelId"],
    checkInDate: json["checkInDate"] == null ? null : DateTime.parse(json["checkInDate"]),
    checkOutDate: json["checkOutDate"] == null ? null : DateTime.parse(json["checkOutDate"]),
    activeOnly: json["activeOnly"],
    upcomingOnly: json["upcomingOnly"],
    pastOnly: json["pastOnly"],
    orderBy: json["orderBy"],
    selectorArgs: json["selectorArgs"] == null ? null : UHotelReservationSelectorArgs.fromMap(json["selectorArgs"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "userId": userId,
    "userName": userName,
    "roomId": roomId,
    "hotelId": hotelId,
    "checkInDate": checkInDate?.toIso8601String(),
    "checkOutDate": checkOutDate?.toIso8601String(),
    "activeOnly": activeOnly,
    "upcomingOnly": upcomingOnly,
    "pastOnly": pastOnly,
    "orderBy": orderBy,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UHotelInvoiceCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final double debtAmount;
  final double creditorAmount;
  final double paidAmount;
  final double penaltyAmount;
  final int? penaltyPrecentEveryDate;
  final String reservationId;
  final DateTime dueDate;
  final List<String>? adminUserIds;

  UHotelInvoiceCreateParams({
    required this.tags,
    required this.debtAmount,
    required this.reservationId,
    required this.dueDate,
    this.creditorAmount = 0,
    this.paidAmount = 0,
    this.penaltyAmount = 0,
    this.penaltyPrecentEveryDate,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UHotelInvoiceCreateParams.fromJson(String str) => UHotelInvoiceCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelInvoiceCreateParams.fromMap(Map<String, dynamic> json) => UHotelInvoiceCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    debtAmount: (json["debtAmount"] as num).toDouble(),
    creditorAmount: json["creditorAmount"] == null ? 0 : (json["creditorAmount"] as num).toDouble(),
    paidAmount: json["paidAmount"] == null ? 0 : (json["paidAmount"] as num).toDouble(),
    penaltyAmount: json["penaltyAmount"] == null ? 0 : (json["penaltyAmount"] as num).toDouble(),
    penaltyPrecentEveryDate: json["penaltyPrecentEveryDate"],
    reservationId: json["reservationId"],
    dueDate: DateTime.parse(json["dueDate"]),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
    "debtAmount": debtAmount,
    "creditorAmount": creditorAmount,
    "paidAmount": paidAmount,
    "penaltyAmount": penaltyAmount,
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
    "reservationId": reservationId,
    "dueDate": dueDate.toIso8601String(),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UHotelInvoiceUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final double? debtAmount;
  final double? creditorAmount;
  final double? paidAmount;
  final double? penaltyAmount;
  final int? penaltyPrecentEveryDate;
  final DateTime? dueDate;
  final String? reservationId;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UHotelInvoiceUpdateParams({
    required this.id,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
    this.debtAmount,
    this.creditorAmount,
    this.paidAmount,
    this.penaltyAmount,
    this.penaltyPrecentEveryDate,
    this.dueDate,
    this.reservationId,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UHotelInvoiceUpdateParams.fromJson(String str) => UHotelInvoiceUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelInvoiceUpdateParams.fromMap(Map<String, dynamic> json) => UHotelInvoiceUpdateParams(
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    debtAmount: json["debtAmount"]?.toDouble(),
    creditorAmount: json["creditorAmount"]?.toDouble(),
    paidAmount: json["paidAmount"]?.toDouble(),
    penaltyAmount: json["penaltyAmount"]?.toDouble(),
    penaltyPrecentEveryDate: json["penaltyPrecentEveryDate"],
    dueDate: json["dueDate"] == null ? null : DateTime.parse(json["dueDate"]),
    reservationId: json["reservationId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "debtAmount": debtAmount,
    "creditorAmount": creditorAmount,
    "paidAmount": paidAmount,
    "penaltyAmount": penaltyAmount,
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
    "dueDate": dueDate?.toIso8601String(),
    "reservationId": reservationId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UHotelInvoiceReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? reservationId;
  final String? userId;
  final String? hotelId;
  final bool? isPaid;
  final bool? isOverdue;
  final DateTime? minDueDate;
  final DateTime? maxDueDate;
  final double? minDebtAmount;
  final double? maxDebtAmount;
  final int? orderBy;
  final UHotelInvoiceSelectorArgs? selectorArgs;

  UHotelInvoiceReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.reservationId,
    this.userId,
    this.hotelId,
    this.isPaid,
    this.isOverdue,
    this.minDueDate,
    this.maxDueDate,
    this.minDebtAmount,
    this.maxDebtAmount,
    this.orderBy,
    this.selectorArgs,
  });

  factory UHotelInvoiceReadParams.fromJson(String str) => UHotelInvoiceReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelInvoiceReadParams.fromMap(Map<String, dynamic> json) => UHotelInvoiceReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    reservationId: json["reservationId"],
    userId: json["userId"],
    hotelId: json["hotelId"],
    isPaid: json["isPaid"],
    isOverdue: json["isOverdue"],
    minDueDate: json["minDueDate"] == null ? null : DateTime.parse(json["minDueDate"]),
    maxDueDate: json["maxDueDate"] == null ? null : DateTime.parse(json["maxDueDate"]),
    minDebtAmount: json["minDebtAmount"]?.toDouble(),
    maxDebtAmount: json["maxDebtAmount"]?.toDouble(),
    orderBy: json["orderBy"],
    selectorArgs: json["selectorArgs"] == null ? null : UHotelInvoiceSelectorArgs.fromMap(json["selectorArgs"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "reservationId": reservationId,
    "userId": userId,
    "hotelId": hotelId,
    "isPaid": isPaid,
    "isOverdue": isOverdue,
    "minDueDate": minDueDate?.toIso8601String(),
    "maxDueDate": maxDueDate?.toIso8601String(),
    "minDebtAmount": minDebtAmount,
    "maxDebtAmount": maxDebtAmount,
    "orderBy": orderBy,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UReservationGuestParams {
  final String fullName;
  final String? nationalCode;
  final String? phoneNumber;
  final String? nationality;
  final String? passportNumber;
  final DateTime? birthDate;
  final String? fatherName;
  final String? gender;

  UReservationGuestParams({required this.fullName, this.nationalCode, this.phoneNumber, this.nationality, this.passportNumber, this.birthDate, this.fatherName, this.gender});

  factory UReservationGuestParams.fromJson(String str) => UReservationGuestParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UReservationGuestParams.fromMap(Map<String, dynamic> json) => UReservationGuestParams(
    fullName: json["fullName"],
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
    nationality: json["nationality"],
    passportNumber: json["passportNumber"],
    birthDate: json["birthDate"] == null ? null : DateTime.parse(json["birthDate"]),
    fatherName: json["fatherName"],
    gender: json["gender"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "fullName": fullName,
    "nationalCode": nationalCode,
    "phoneNumber": phoneNumber,
    "nationality": nationality,
    "passportNumber": passportNumber,
    "birthDate": birthDate?.toIso8601String(),
    "fatherName": fatherName,
    "gender": gender,
  };
}

class UHotelRoomAvailabilityParams {
  final String? hotelId;
  final String? roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final UHotelRoomSelectorArgs? selectorArgs;

  UHotelRoomAvailabilityParams({
    required this.checkInDate,
    required this.checkOutDate,
    this.hotelId,
    this.roomId,
    this.guestCount = 1,
    this.selectorArgs,
  });

  factory UHotelRoomAvailabilityParams.fromJson(String str) => UHotelRoomAvailabilityParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelRoomAvailabilityParams.fromMap(Map<String, dynamic> json) => UHotelRoomAvailabilityParams(
    hotelId: json["hotelId"],
    roomId: json["roomId"],
    checkInDate: DateTime.parse(json["checkInDate"]),
    checkOutDate: DateTime.parse(json["checkOutDate"]),
    guestCount: json["guestCount"] == null ? 1 : (json["guestCount"] as num).toInt(),
    selectorArgs: json["selectorArgs"] == null ? null : UHotelRoomSelectorArgs.fromMap(json["selectorArgs"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "hotelId": hotelId,
    "roomId": roomId,
    "checkInDate": checkInDate.toIso8601String(),
    "checkOutDate": checkOutDate.toIso8601String(),
    "guestCount": guestCount,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UHotelReservationBookParams {
  final String roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final List<UReservationGuestParams>? guests;
  final String? guestName;
  final String? guestPhone;
  final String? notes;
  final bool payFromWallet;

  UHotelReservationBookParams({
    required this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    this.guests,
    this.guestName,
    this.guestPhone,
    this.notes,
    this.payFromWallet = false,
  });

  factory UHotelReservationBookParams.fromJson(String str) => UHotelReservationBookParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReservationBookParams.fromMap(Map<String, dynamic> json) => UHotelReservationBookParams(
    roomId: json["roomId"],
    checkInDate: DateTime.parse(json["checkInDate"]),
    checkOutDate: DateTime.parse(json["checkOutDate"]),
    guestCount: (json["guestCount"] as num).toInt(),
    guests: json["guests"] == null ? null : List<UReservationGuestParams>.from(json["guests"]!.map((dynamic x) => UReservationGuestParams.fromMap(x))),
    guestName: json["guestName"],
    guestPhone: json["guestPhone"],
    notes: json["notes"],
    payFromWallet: json["payFromWallet"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "roomId": roomId,
    "checkInDate": checkInDate.toIso8601String(),
    "checkOutDate": checkOutDate.toIso8601String(),
    "guestCount": guestCount,
    "guests": guests == null ? <dynamic>[] : List<dynamic>.from(guests!.map((UReservationGuestParams x) => x.toMap())),
    "guestName": guestName,
    "guestPhone": guestPhone,
    "notes": notes,
    "payFromWallet": payFromWallet,
  };
}

class UHotelReservationCancelParams {
  final String id;
  final String? reason;

  UHotelReservationCancelParams({required this.id, this.reason});

  factory UHotelReservationCancelParams.fromJson(String str) => UHotelReservationCancelParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReservationCancelParams.fromMap(Map<String, dynamic> json) => UHotelReservationCancelParams(
    id: json["id"],
    reason: json["reason"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "reason": reason,
  };
}

class UHotelRateCreateParams {
  UHotelRateCreateParams({
    required this.hotelId,
    required this.startDate,
    required this.endDate,
    this.tags = const <int>[],
    this.roomId,
    this.price,
    this.percent,
    this.weekdays,
    this.minNights,
    this.detail1,
  });

  final String hotelId;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> tags;
  final String? roomId;
  final double? price;
  final double? percent;
  final List<int>? weekdays;
  final int? minNights;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "hotelId": hotelId,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
    "tags": tags,
    "roomId": roomId,
    "price": price,
    "percent": percent,
    "weekdays": weekdays,
    "minNights": minNights,
    "detail1": detail1,
  };
}

class UHotelRateUpdateParams {
  UHotelRateUpdateParams({
    required this.id,
    this.startDate,
    this.endDate,
    this.price,
    this.percent,
    this.weekdays,
    this.minNights,
    this.tags,
    this.detail1,
  });

  final String id;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? price;
  final double? percent;
  final List<int>? weekdays;
  final int? minNights;
  final List<int>? tags;
  final String? detail1;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "startDate": startDate?.toIso8601String(),
    "endDate": endDate?.toIso8601String(),
    "price": price,
    "percent": percent,
    "weekdays": weekdays,
    "minNights": minNights,
    "tags": tags,
    "detail1": detail1,
  };
}

class UHotelRateReadParams {
  UHotelRateReadParams({
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.hotelId,
    this.roomId,
    this.fromDate,
    this.toDate,
  });

  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final String? hotelId;
  final String? roomId;
  final DateTime? fromDate;
  final DateTime? toDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "tags": tags,
    "hotelId": hotelId,
    "roomId": roomId,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
  };
}

class UHotelRoomCalendarParams {
  UHotelRoomCalendarParams({
    required this.roomId,
    required this.fromDate,
    this.days = 31,
  });

  final String roomId;
  final DateTime fromDate;
  final int days;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "roomId": roomId,
    "fromDate": fromDate.toIso8601String(),
    "days": days,
  };
}

class UHotelHousekeepingParams {
  UHotelHousekeepingParams({
    required this.roomId,
    required this.number,
    required this.status,
    this.note,
  });

  final String roomId;
  final String number;
  final int status;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "roomId": roomId,
    "number": number,
    "status": status,
    "note": note,
  };
}

class UHotelGroupRoomParams {
  UHotelGroupRoomParams({
    required this.roomId,
    this.count = 1,
    this.guestCount = 1,
  });

  final String roomId;
  final int count;
  final int guestCount;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "roomId": roomId,
    "count": count,
    "guestCount": guestCount,
  };
}

class UHotelReservationGroupParams {
  UHotelReservationGroupParams({
    required this.userId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.groupName,
    this.rooms = const <UHotelGroupRoomParams>[],
    this.guestPhone,
    this.notes,
    this.penaltyPrecentEveryDate = 0,
  });

  final String userId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String groupName;
  final List<UHotelGroupRoomParams> rooms;
  final String? guestPhone;
  final String? notes;
  final int penaltyPrecentEveryDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "checkInDate": checkInDate.toIso8601String(),
    "checkOutDate": checkOutDate.toIso8601String(),
    "groupName": groupName,
    "rooms": rooms.map((UHotelGroupRoomParams x) => x.toMap()).toList(),
    "guestPhone": guestPhone,
    "notes": notes,
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
  };
}

class UHotelReservationExtendParams {
  UHotelReservationExtendParams({
    required this.id,
    required this.checkOutDate,
  });

  final String id;
  final DateTime checkOutDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "checkOutDate": checkOutDate.toIso8601String(),
  };
}

class UHotelReservationChangeRoomParams {
  UHotelReservationChangeRoomParams({
    required this.id,
    required this.roomId,
    this.keepPrice = false,
    this.roomNumber,
  });

  final String id;
  final String roomId;
  final bool keepPrice;
  final String? roomNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "roomId": roomId,
    "keepPrice": keepPrice,
    "roomNumber": roomNumber,
  };
}

class UHotelNightAuditParams {
  UHotelNightAuditParams({
    required this.hotelId,
    this.date,
  });

  final String hotelId;
  final DateTime? date;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "hotelId": hotelId,
    "date": date?.toIso8601String(),
  };
}

class UHotelGuestExportParams {
  UHotelGuestExportParams({
    required this.hotelId,
    required this.fromDate,
    required this.toDate,
  });

  final String hotelId;
  final DateTime fromDate;
  final DateTime toDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "hotelId": hotelId,
    "fromDate": fromDate.toIso8601String(),
    "toDate": toDate.toIso8601String(),
  };
}
