part of "../data.dart";

// ==================== DormBed ====================

class UDormBedCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final String title;
  final double deposit;
  final double monthlyRent;
  final String roomId;
  final List<String>? adminUserIds;

  UDormBedCreateParams({
    required this.tags,
    required this.title,
    required this.deposit,
    required this.monthlyRent,
    required this.roomId,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UDormBedCreateParams.fromJson(String str) => UDormBedCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedCreateParams.fromMap(Map<String, dynamic> json) => UDormBedCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    title: json["title"],
    deposit: json["deposit"]?.toDouble(),
    monthlyRent: json["monthlyRent"]?.toDouble(),
    roomId: json["roomId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
    "title": title,
    "deposit": deposit,
    "monthlyRent": monthlyRent,
    "roomId": roomId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UDormBedUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? title;
  final double? deposit;
  final double? monthlyRent;
  final String? roomId;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UDormBedUpdateParams({
    required this.id,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
    this.title,
    this.deposit,
    this.monthlyRent,
    this.roomId,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UDormBedUpdateParams.fromJson(String str) => UDormBedUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedUpdateParams.fromMap(Map<String, dynamic> json) => UDormBedUpdateParams(
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"],
    deposit: json["deposit"]?.toDouble(),
    monthlyRent: json["monthlyRent"]?.toDouble(),
    roomId: json["roomId"],
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
    "title": title,
    "deposit": deposit,
    "monthlyRent": monthlyRent,
    "roomId": roomId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UDormBedReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? title;
  final String? roomId;
  final String? dormId;
  final double? minDeposit;
  final double? maxDeposit;
  final double? minMonthlyRent;
  final double? maxMonthlyRent;
  final DormBedSelectorArgs? selectorArgs;
  final int? orderBy;

  UDormBedReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.title,
    this.roomId,
    this.dormId,
    this.minDeposit,
    this.maxDeposit,
    this.minMonthlyRent,
    this.maxMonthlyRent,
    this.selectorArgs,
    this.orderBy,
  });

  factory UDormBedReadParams.fromJson(String str) => UDormBedReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedReadParams.fromMap(Map<String, dynamic> json) => UDormBedReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    roomId: json["roomId"],
    dormId: json["dormId"],
    minDeposit: json["minDeposit"]?.toDouble(),
    maxDeposit: json["maxDeposit"]?.toDouble(),
    minMonthlyRent: json["minMonthlyRent"]?.toDouble(),
    maxMonthlyRent: json["maxMonthlyRent"]?.toDouble(),
    selectorArgs: json["selectorArgs"] == null ? null : DormBedSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
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
    "roomId": roomId,
    "dormId": dormId,
    "minDeposit": minDeposit,
    "maxDeposit": maxDeposit,
    "minMonthlyRent": minMonthlyRent,
    "maxMonthlyRent": maxMonthlyRent,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
  };
}

// ==================== Dorm ====================

class UDormCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final String title;
  final String cityCode;
  final List<String>? adminUserIds;
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? nearbyUniversity;
  final String? visitingHours;
  final List<String>? amenities;
  final List<String>? rules;
  final List<String>? requiredDocuments;
  final double? latitude;
  final double? longitude;

  UDormCreateParams({
    required this.tags,
    required this.title,
    required this.cityCode,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
    this.address,
    this.phoneNumber,
    this.description,
    this.nearbyUniversity,
    this.visitingHours,
    this.amenities,
    this.rules,
    this.requiredDocuments,
    this.latitude,
    this.longitude,
  });

  factory UDormCreateParams.fromJson(String str) => UDormCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormCreateParams.fromMap(Map<String, dynamic> json) => UDormCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    title: json["title"],
    cityCode: json["cityCode"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    description: json["description"],
    nearbyUniversity: json["nearbyUniversity"],
    visitingHours: json["visitingHours"],
    amenities: json["amenities"] == null ? <String>[] : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
    rules: json["rules"] == null ? <String>[] : List<String>.from(json["rules"]!.map((dynamic x) => x)),
    requiredDocuments: json["requiredDocuments"] == null ? <String>[] : List<String>.from(json["requiredDocuments"]!.map((dynamic x) => x)),
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
    "title": title,
    "cityCode": cityCode,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "address": address,
    "phoneNumber": phoneNumber,
    "description": description,
    "nearbyUniversity": nearbyUniversity,
    "visitingHours": visitingHours,
    "amenities": amenities == null ? <dynamic>[] : List<dynamic>.from(amenities!.map((String x) => x)),
    "rules": rules == null ? <dynamic>[] : List<dynamic>.from(rules!.map((String x) => x)),
    "requiredDocuments": requiredDocuments == null ? <dynamic>[] : List<dynamic>.from(requiredDocuments!.map((String x) => x)),
    "latitude": latitude,
    "longitude": longitude,
  };
}

class UDormUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? title;
  final String? cityCode;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? nearbyUniversity;
  final String? visitingHours;
  final List<String>? amenities;
  final List<String>? rules;
  final List<String>? requiredDocuments;
  final double? latitude;
  final double? longitude;

  UDormUpdateParams({
    required this.id,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
    this.title,
    this.cityCode,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.address,
    this.phoneNumber,
    this.description,
    this.nearbyUniversity,
    this.visitingHours,
    this.amenities,
    this.rules,
    this.requiredDocuments,
    this.latitude,
    this.longitude,
  });

  factory UDormUpdateParams.fromJson(String str) => UDormUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormUpdateParams.fromMap(Map<String, dynamic> json) => UDormUpdateParams(
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"],
    cityCode: json["cityCode"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    description: json["description"],
    nearbyUniversity: json["nearbyUniversity"],
    visitingHours: json["visitingHours"],
    amenities: json["amenities"] == null ? <String>[] : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
    rules: json["rules"] == null ? <String>[] : List<String>.from(json["rules"]!.map((dynamic x) => x)),
    requiredDocuments: json["requiredDocuments"] == null ? <String>[] : List<String>.from(json["requiredDocuments"]!.map((dynamic x) => x)),
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "title": title,
    "cityCode": cityCode,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "address": address,
    "phoneNumber": phoneNumber,
    "description": description,
    "nearbyUniversity": nearbyUniversity,
    "visitingHours": visitingHours,
    "amenities": amenities == null ? <dynamic>[] : List<dynamic>.from(amenities!.map((String x) => x)),
    "rules": rules == null ? <dynamic>[] : List<dynamic>.from(rules!.map((String x) => x)),
    "requiredDocuments": requiredDocuments == null ? <dynamic>[] : List<dynamic>.from(requiredDocuments!.map((String x) => x)),
    "latitude": latitude,
    "longitude": longitude,
  };
}

class UDormReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? title;
  final String? cityCode;
  final DormSelectorArgs? selectorArgs;
  final int? orderBy;

  UDormReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.title,
    this.cityCode,
    this.selectorArgs,
    this.orderBy,
  });

  factory UDormReadParams.fromJson(String str) => UDormReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormReadParams.fromMap(Map<String, dynamic> json) => UDormReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    cityCode: json["cityCode"],
    selectorArgs: json["selectorArgs"] == null ? null : DormSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
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
    "cityCode": cityCode,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
  };
}

// ==================== Hotel ====================

class UHotelCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
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
  final List<String>? amenities;
  final List<String>? adminUserIds;
  final List<String>? rules;
  final double? latitude;
  final double? longitude;
  final int? cancellationFreeHours;
  final int? cancellationPenaltyNights;

  UHotelCreateParams({
    required this.tags,
    required this.title,
    required this.cityCode,
    this.stars = 0,
    this.address,
    this.phoneNumber,
    this.email,
    this.description,
    this.policies,
    this.checkInTime,
    this.checkOutTime,
    this.amenities,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
    this.rules,
    this.latitude,
    this.longitude,
    this.cancellationFreeHours,
    this.cancellationPenaltyNights,
  });

  factory UHotelCreateParams.fromJson(String str) => UHotelCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelCreateParams.fromMap(Map<String, dynamic> json) => UHotelCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    title: json["title"],
    cityCode: json["cityCode"],
    stars: json["stars"] == null ? 0 : (json["stars"] as num).toInt(),
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    description: json["description"],
    policies: json["policies"],
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    amenities: json["amenities"] == null ? null : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    rules: json["rules"] == null ? <String>[] : List<String>.from(json["rules"]!.map((dynamic x) => x)),
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
    cancellationFreeHours: json["cancellationFreeHours"] == null ? null : (json["cancellationFreeHours"] as num).toInt(),
    cancellationPenaltyNights: json["cancellationPenaltyNights"] == null ? null : (json["cancellationPenaltyNights"] as num).toInt(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
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
    "amenities": amenities == null ? null : List<dynamic>.from(amenities!.map((String x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "rules": rules == null ? <dynamic>[] : List<dynamic>.from(rules!.map((String x) => x)),
    "latitude": latitude,
    "longitude": longitude,
    "cancellationFreeHours": cancellationFreeHours,
    "cancellationPenaltyNights": cancellationPenaltyNights,
  };
}

class UHotelUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
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
  final List<String>? amenities;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final List<String>? rules;
  final double? latitude;
  final double? longitude;
  final int? cancellationFreeHours;
  final int? cancellationPenaltyNights;

  UHotelUpdateParams({
    required this.id,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
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
    this.amenities,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.rules,
    this.latitude,
    this.longitude,
    this.cancellationFreeHours,
    this.cancellationPenaltyNights,
  });

  factory UHotelUpdateParams.fromJson(String str) => UHotelUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelUpdateParams.fromMap(Map<String, dynamic> json) => UHotelUpdateParams(
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
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
    amenities: json["amenities"] == null ? null : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    rules: json["rules"] == null ? <String>[] : List<String>.from(json["rules"]!.map((dynamic x) => x)),
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
    cancellationFreeHours: json["cancellationFreeHours"] == null ? null : (json["cancellationFreeHours"] as num).toInt(),
    cancellationPenaltyNights: json["cancellationPenaltyNights"] == null ? null : (json["cancellationPenaltyNights"] as num).toInt(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
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
    "amenities": amenities == null ? null : List<dynamic>.from(amenities!.map((String x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "rules": rules == null ? <dynamic>[] : List<dynamic>.from(rules!.map((String x) => x)),
    "latitude": latitude,
    "longitude": longitude,
    "cancellationFreeHours": cancellationFreeHours,
    "cancellationPenaltyNights": cancellationPenaltyNights,
  };
}

class UHotelReadParams {
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
  final HotelSelectorArgs? selectorArgs;

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
  });

  factory UHotelReadParams.fromJson(String str) => UHotelReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelReadParams.fromMap(Map<String, dynamic> json) => UHotelReadParams(
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
    selectorArgs: json["selectorArgs"] == null ? null : HotelSelectorArgs.fromMap(json["selectorArgs"]),
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
    "cityCode": cityCode,
    "minStars": minStars,
    "orderBy": orderBy,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

// ==================== HotelRoom ====================

class UHotelRoomCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
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
  final List<String>? amenities;
  final List<String>? adminUserIds;
  final int? extraGuestCapacity;
  final double? extraGuestPrice;

  UHotelRoomCreateParams({
    required this.tags,
    required this.title,
    required this.capacity,
    required this.pricePerNight,
    required this.hotelId,
    this.roomNumber,
    this.quantity = 1,
    this.isAvailable = true,
    this.description,
    this.bedType,
    this.sizeSquareMeters,
    this.floor,
    this.amenities,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
    this.extraGuestCapacity,
    this.extraGuestPrice,
  });

  factory UHotelRoomCreateParams.fromJson(String str) => UHotelRoomCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelRoomCreateParams.fromMap(Map<String, dynamic> json) => UHotelRoomCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    title: json["title"],
    capacity: json["capacity"],
    pricePerNight: json["pricePerNight"]?.toDouble(),
    hotelId: json["hotelId"],
    roomNumber: json["roomNumber"],
    quantity: json["quantity"] == null ? 1 : (json["quantity"] as num).toInt(),
    isAvailable: json["isAvailable"] == null || json["isAvailable"] as bool,
    description: json["description"],
    bedType: json["bedType"],
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    amenities: json["amenities"] == null ? null : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    extraGuestCapacity: json["extraGuestCapacity"] == null ? null : (json["extraGuestCapacity"] as num).toInt(),
    extraGuestPrice: json["extraGuestPrice"] == null ? null : (json["extraGuestPrice"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
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
    "amenities": amenities == null ? null : List<dynamic>.from(amenities!.map((String x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "extraGuestCapacity": extraGuestCapacity,
    "extraGuestPrice": extraGuestPrice,
  };
}

class UHotelRoomUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
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
  final List<String>? amenities;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final int? extraGuestCapacity;
  final double? extraGuestPrice;

  UHotelRoomUpdateParams({
    required this.id,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
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
    this.amenities,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.extraGuestCapacity,
    this.extraGuestPrice,
  });

  factory UHotelRoomUpdateParams.fromJson(String str) => UHotelRoomUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelRoomUpdateParams.fromMap(Map<String, dynamic> json) => UHotelRoomUpdateParams(
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"],
    capacity: json["capacity"],
    pricePerNight: json["pricePerNight"]?.toDouble(),
    hotelId: json["hotelId"],
    roomNumber: json["roomNumber"],
    quantity: json["quantity"] == null ? null : (json["quantity"] as num).toInt(),
    isAvailable: json["isAvailable"],
    description: json["description"],
    bedType: json["bedType"],
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    amenities: json["amenities"] == null ? null : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    extraGuestCapacity: json["extraGuestCapacity"] == null ? null : (json["extraGuestCapacity"] as num).toInt(),
    extraGuestPrice: json["extraGuestPrice"] == null ? null : (json["extraGuestPrice"] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
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
    "amenities": amenities == null ? null : List<dynamic>.from(amenities!.map((String x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
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
  final HotelRoomSelectorArgs? selectorArgs;
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
    selectorArgs: json["selectorArgs"] == null ? null : HotelRoomSelectorArgs.fromMap(json["selectorArgs"]),
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

// ==================== DormRoom ====================

class UDormRoomCreateParams {
  final String? detail1;
  final String? detail2;
  final List<int> tags;
  final String? id;
  final String? creatorId;
  final String title;
  final String dormId;
  final List<String>? adminUserIds;
  final int? capacity;
  final String? description;
  final int? floor;
  final double? sizeSquareMeters;
  final List<String>? amenities;

  UDormRoomCreateParams({
    required this.tags,
    required this.title,
    required this.dormId,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
    this.capacity,
    this.description,
    this.floor,
    this.sizeSquareMeters,
    this.amenities,
  });

  factory UDormRoomCreateParams.fromJson(String str) => UDormRoomCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormRoomCreateParams.fromMap(Map<String, dynamic> json) => UDormRoomCreateParams(
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    creatorId: json["creatorId"],
    title: json["title"],
    dormId: json["dormId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    capacity: json["capacity"] == null ? null : (json["capacity"] as num).toInt(),
    description: json["description"],
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
    amenities: json["amenities"] == null ? <String>[] : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "creatorId": creatorId,
    "title": title,
    "dormId": dormId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "capacity": capacity,
    "description": description,
    "floor": floor,
    "sizeSquareMeters": sizeSquareMeters,
    "amenities": amenities == null ? <dynamic>[] : List<dynamic>.from(amenities!.map((String x) => x)),
  };
}

class UDormRoomUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? title;
  final String? dormId;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;
  final int? capacity;
  final String? description;
  final int? floor;
  final double? sizeSquareMeters;
  final List<String>? amenities;

  UDormRoomUpdateParams({
    required this.id,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
    this.title,
    this.dormId,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
    this.capacity,
    this.description,
    this.floor,
    this.sizeSquareMeters,
    this.amenities,
  });

  factory UDormRoomUpdateParams.fromJson(String str) => UDormRoomUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormRoomUpdateParams.fromMap(Map<String, dynamic> json) => UDormRoomUpdateParams(
    id: json["id"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"],
    dormId: json["dormId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
    capacity: json["capacity"] == null ? null : (json["capacity"] as num).toInt(),
    description: json["description"],
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
    amenities: json["amenities"] == null ? <String>[] : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "detail1": detail1,
    "detail2": detail2,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "title": title,
    "dormId": dormId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
    "capacity": capacity,
    "description": description,
    "floor": floor,
    "sizeSquareMeters": sizeSquareMeters,
    "amenities": amenities == null ? <dynamic>[] : List<dynamic>.from(amenities!.map((String x) => x)),
  };
}

class UDormRoomReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? title;
  final String? dormId;
  final DormRoomSelectorArgs? selectorArgs;
  final int? orderBy;

  UDormRoomReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.title,
    this.dormId,
    this.selectorArgs,
    this.orderBy,
  });

  factory UDormRoomReadParams.fromJson(String str) => UDormRoomReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormRoomReadParams.fromMap(Map<String, dynamic> json) => UDormRoomReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    dormId: json["dormId"],
    selectorArgs: json["selectorArgs"] == null ? null : DormRoomSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
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
    "dormId": dormId,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
  };
}

class UDormBedContractCreateParams {
  final List<int> tags;
  final String? id;
  final DateTime startDate;
  final DateTime endDate;
  final String userId;
  final String bedId;
  final double? deposit;
  final double? rent;
  final int? penaltyPrecentEveryDate;
  final String? detail1;
  final String? detail2;
  final String? creatorId;
  final List<String>? adminUserIds;

  UDormBedContractCreateParams({
    required this.tags,
    required this.startDate,
    required this.endDate,
    required this.userId,
    required this.bedId,
    this.id,
    this.deposit,
    this.rent,
    this.penaltyPrecentEveryDate,
    this.detail1,
    this.detail2,
    this.creatorId,
    this.adminUserIds,
  });

  factory UDormBedContractCreateParams.fromJson(String str) => UDormBedContractCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedContractCreateParams.fromMap(Map<String, dynamic> json) => UDormBedContractCreateParams(
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    startDate: DateTime.parse(json["startDate"]),
    endDate: DateTime.parse(json["endDate"]),
    userId: json["userId"] as String,
    bedId: json["bedId"] as String,
    deposit: json["deposit"] == null ? null : (json["deposit"] as num).toDouble(),
    rent: json["rent"] == null ? null : (json["rent"] as num).toDouble(),
    penaltyPrecentEveryDate: json["penaltyPrecentEveryDate"] == null ? null : (json["penaltyPrecentEveryDate"] as num).toInt(),
    detail1: json["detail1"],
    detail2: json["detail2"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
    "userId": userId,
    "bedId": bedId,
    "deposit": deposit,
    "rent": rent,
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
    "detail1": detail1,
    "detail2": detail2,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UDormBedContractReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? userId;
  final String? creatorId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userName;
  final String? bedId;
  final String? dormId;
  final bool? activeOnly;
  final bool? upcomingOnly;
  final bool? expiredOnly;
  final int? expiringWithinDays;
  final ContractSelectorArgs? selectorArgs;
  final int? orderBy;

  UDormBedContractReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.userId,
    this.creatorId,
    this.startDate,
    this.endDate,
    this.userName,
    this.bedId,
    this.dormId,
    this.activeOnly,
    this.upcomingOnly,
    this.expiredOnly,
    this.expiringWithinDays,
    this.selectorArgs,
    this.orderBy,
  });

  factory UDormBedContractReadParams.fromJson(String str) => UDormBedContractReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedContractReadParams.fromMap(Map<String, dynamic> json) => UDormBedContractReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    userId: json["userId"],
    bedId: json["bedId"],
    dormId: json["dormId"],
    creatorId: json["creatorId"],
    userName: json["userName"],
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    activeOnly: json["activeOnly"],
    upcomingOnly: json["upcomingOnly"],
    expiredOnly: json["expiredOnly"],
    expiringWithinDays: json["expiringWithinDays"] == null ? null : (json["expiringWithinDays"] as num).toInt(),
    selectorArgs: json["selectorArgs"] == null ? null : ContractSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "userId": userId,
    "bedId": bedId,
    "dormId": dormId,
    "creatorId": creatorId,
    "userName": userName,
    "startDate": startDate?.toIso8601String(),
    "endDate": endDate?.toIso8601String(),
    "activeOnly": activeOnly,
    "upcomingOnly": upcomingOnly,
    "expiredOnly": expiredOnly,
    "expiringWithinDays": expiringWithinDays,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
  };
}

class UDormBedContractUpdateParams {
  final String id;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? deposit;
  final double? rent;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UDormBedContractUpdateParams({
    required this.id,
    this.addTags,
    this.removeTags,
    this.tags,
    this.startDate,
    this.endDate,
    this.deposit,
    this.rent,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UDormBedContractUpdateParams.fromJson(String str) => UDormBedContractUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedContractUpdateParams.fromMap(Map<String, dynamic> json) => UDormBedContractUpdateParams(
    id: json["id"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    deposit: json["deposit"].toString().toDouble(),
    rent: json["rent"].toString().toDouble(),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "startDate": startDate?.toIso8601String(),
    "endDate": endDate?.toIso8601String(),
    "deposit": deposit,
    "rent": rent,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UDormBedInvoiceCreateParams {
  final List<int> tags;
  final String? id;
  final double debtAmount;
  final double creditorAmount;
  final double paidAmount;
  final double penaltyAmount;
  final String contractId;
  final int? penaltyPrecentEveryDate;
  final DateTime dueDate;
  final String? detail1;
  final String? detail2;
  final String? creatorId;
  final List<String>? adminUserIds;

  UDormBedInvoiceCreateParams({
    required this.tags,
    required this.debtAmount,
    required this.creditorAmount,
    required this.paidAmount,
    required this.penaltyAmount,
    required this.contractId,
    required this.dueDate,
    this.id,
    this.penaltyPrecentEveryDate,
    this.detail1,
    this.detail2,
    this.creatorId,
    this.adminUserIds,
  });

  factory UDormBedInvoiceCreateParams.fromJson(String str) => UDormBedInvoiceCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedInvoiceCreateParams.fromMap(Map<String, dynamic> json) => UDormBedInvoiceCreateParams(
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    debtAmount: json["debtAmount"].toString().toDouble(),
    creditorAmount: json["creditorAmount"].toString().toDouble(),
    paidAmount: json["paidAmount"].toString().toDouble(),
    penaltyAmount: json["penaltyAmount"].toString().toDouble(),
    contractId: json["contractId"],
    penaltyPrecentEveryDate: json["penaltyPrecentEveryDate"] == null ? null : (json["penaltyPrecentEveryDate"] as num).toInt(),
    dueDate: DateTime.parse(json["dueDate"]),
    detail1: json["detail1"],
    detail2: json["detail2"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "debtAmount": debtAmount,
    "creditorAmount": creditorAmount,
    "paidAmount": paidAmount,
    "penaltyAmount": penaltyAmount,
    "contractId": contractId,
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
    "dueDate": dueDate.toIso8601String(),
    "detail1": detail1,
    "detail2": detail2,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UDormBedInvoiceReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? userId;
  final String? contractId;
  final String? dormId;
  final bool? isPaid;
  final bool? isOverdue;
  final DateTime? minDueDate;
  final DateTime? maxDueDate;
  final double? minDebtAmount;
  final double? maxDebtAmount;
  final InvoiceSelectorArgs? selectorArgs;
  final String? creatorId;
  final int? orderBy;

  UDormBedInvoiceReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.userId,
    this.selectorArgs,
    this.contractId,
    this.dormId,
    this.isPaid,
    this.isOverdue,
    this.minDueDate,
    this.maxDueDate,
    this.minDebtAmount,
    this.maxDebtAmount,
    this.creatorId,
    this.orderBy,
  });

  factory UDormBedInvoiceReadParams.fromJson(String str) => UDormBedInvoiceReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedInvoiceReadParams.fromMap(Map<String, dynamic> json) => UDormBedInvoiceReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    userId: json["userId"],
    contractId: json["contractId"],
    dormId: json["dormId"],
    isPaid: json["isPaid"],
    isOverdue: json["isOverdue"],
    minDueDate: json["minDueDate"] == null ? null : DateTime.parse(json["minDueDate"]),
    maxDueDate: json["maxDueDate"] == null ? null : DateTime.parse(json["maxDueDate"]),
    minDebtAmount: json["minDebtAmount"] == null ? null : (json["minDebtAmount"] as num).toDouble(),
    maxDebtAmount: json["maxDebtAmount"] == null ? null : (json["maxDebtAmount"] as num).toDouble(),
    selectorArgs: json["selectorArgs"] == null ? null : InvoiceSelectorArgs.fromMap(json["selectorArgs"]),
    creatorId: json["creatorId"],
    orderBy: json["orderBy"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "userId": userId,
    "contractId": contractId,
    "dormId": dormId,
    "isPaid": isPaid,
    "isOverdue": isOverdue,
    "minDueDate": minDueDate?.toIso8601String(),
    "maxDueDate": maxDueDate?.toIso8601String(),
    "minDebtAmount": minDebtAmount,
    "maxDebtAmount": maxDebtAmount,
    "selectorArgs": selectorArgs?.toMap(),
    "creatorId": creatorId,
    "orderBy": orderBy,
  };
}

class UDormBedInvoiceUpdateParams {
  final String? id;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final double? debtAmount;
  final double? creditorAmount;
  final double? paidAmount;
  final double? penaltyAmount;
  final String? userId;
  final String? contractId;
  final int? penaltyPrecentEveryDate;
  final DateTime? dueDate;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UDormBedInvoiceUpdateParams({
    this.id,
    this.addTags,
    this.removeTags,
    this.tags,
    this.debtAmount,
    this.creditorAmount,
    this.paidAmount,
    this.penaltyAmount,
    this.userId,
    this.contractId,
    this.penaltyPrecentEveryDate,
    this.dueDate,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UDormBedInvoiceUpdateParams.fromJson(String str) => UDormBedInvoiceUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedInvoiceUpdateParams.fromMap(Map<String, dynamic> json) => UDormBedInvoiceUpdateParams(
    id: json["id"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    debtAmount: json["debtAmount"].toString().toDouble(),
    creditorAmount: json["creditorAmount"].toString().toDouble(),
    paidAmount: json["paidAmount"].toString().toDouble(),
    penaltyAmount: json["penaltyAmount"].toString().toDouble(),
    userId: json["userId"],
    contractId: json["contractId"],
    penaltyPrecentEveryDate: json["penaltyPrecentEveryDate"] == null ? null : (json["penaltyPrecentEveryDate"] as num).toInt(),
    dueDate: json["dueDate"] == null ? null : DateTime.parse(json["dueDate"]),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "debtAmount": debtAmount,
    "creditorAmount": creditorAmount,
    "paidAmount": paidAmount,
    "penaltyAmount": penaltyAmount,
    "userId": userId,
    "contractId": contractId,
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
    "dueDate": dueDate?.toIso8601String(),
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

// ==================== HotelReservation ====================

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
  final HotelReservationSelectorArgs? selectorArgs;

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
    selectorArgs: json["selectorArgs"] == null ? null : HotelReservationSelectorArgs.fromMap(json["selectorArgs"]),
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

// ==================== HotelInvoice ====================

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
  final HotelInvoiceSelectorArgs? selectorArgs;

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
    selectorArgs: json["selectorArgs"] == null ? null : HotelInvoiceSelectorArgs.fromMap(json["selectorArgs"]),
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

// ==================== Guest booking ====================

class UReservationGuestParams {
  final String fullName;
  final String? nationalCode;
  final String? phoneNumber;

  UReservationGuestParams({required this.fullName, this.nationalCode, this.phoneNumber});

  factory UReservationGuestParams.fromJson(String str) => UReservationGuestParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UReservationGuestParams.fromMap(Map<String, dynamic> json) => UReservationGuestParams(
    fullName: json["fullName"],
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "fullName": fullName,
    "nationalCode": nationalCode,
    "phoneNumber": phoneNumber,
  };
}

class UHotelRoomAvailabilityParams {
  final String? hotelId;
  final String? roomId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final HotelRoomSelectorArgs? selectorArgs;

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
    selectorArgs: json["selectorArgs"] == null ? null : HotelRoomSelectorArgs.fromMap(json["selectorArgs"]),
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
