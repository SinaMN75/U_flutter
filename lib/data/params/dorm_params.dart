part of "../data.dart";

class UDormBedCreateParams {
  UDormBedCreateParams({
    required this.tags,
    required this.title,
    required this.deposit,
    required this.monthlyRent,
    required this.roomId,
    this.id,
    this.creatorId,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.description,
  });

  factory UDormBedCreateParams.fromJson(String str) => UDormBedCreateParams.fromMap(json.decode(str));

  factory UDormBedCreateParams.fromMap(Map<String, dynamic> json) => UDormBedCreateParams(
    tags: json["tags"] == null ? <int>[] : List<int>.from((json["tags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    id: json["id"],
    creatorId: json["creatorId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from((json["adminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    title: json["title"],
    deposit: (json["deposit"] as num).toDouble(),
    monthlyRent: (json["monthlyRent"] as num).toDouble(),
    roomId: json["roomId"],
    description: json["description"],
  );

  final List<int> tags;
  final String? id;
  final String? creatorId;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final String title;
  final double deposit;
  final double monthlyRent;
  final String roomId;
  final String? description;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "id": id,
    "creatorId": creatorId,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds,
    "title": title,
    "deposit": deposit,
    "monthlyRent": monthlyRent,
    "roomId": roomId,
    "description": description,
  };
}

class UDormBedUpdateParams {
  UDormBedUpdateParams({
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
    this.deposit,
    this.monthlyRent,
    this.roomId,
    this.description,
  });

  factory UDormBedUpdateParams.fromJson(String str) => UDormBedUpdateParams.fromMap(json.decode(str));

  factory UDormBedUpdateParams.fromMap(Map<String, dynamic> json) => UDormBedUpdateParams(
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
    deposit: json["deposit"] == null ? null : (json["deposit"] as num).toDouble(),
    monthlyRent: json["monthlyRent"] == null ? null : (json["monthlyRent"] as num).toDouble(),
    roomId: json["roomId"],
    description: json["description"],
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
  final double? deposit;
  final double? monthlyRent;
  final String? roomId;
  final String? description;

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
    "deposit": deposit,
    "monthlyRent": monthlyRent,
    "roomId": roomId,
    "description": description,
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
  final UDormBedSelectorArgs? selectorArgs;
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
    selectorArgs: json["selectorArgs"] == null ? null : UDormBedSelectorArgs.fromMap(json["selectorArgs"]),
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

class UDormCreateParams {
  UDormCreateParams({
    required this.tags,
    required this.title,
    required this.cityCode,
    this.id,
    this.creatorId,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.address,
    this.phoneNumber,
    this.description,
    this.policies,
    this.highlights,
    this.rules,
    this.requiredDocuments,
    this.nearbyUniversity,
    this.universityWalkMinutes,
    this.visitingHours,
    this.curfewTime,
    this.minimumStayMonths,
    this.howToGetThere,
    this.nearby,
    this.faqs,
    this.website,
    this.whatsapp,
    this.instagram,
    this.telegram,
    this.latitude,
    this.longitude,
    this.organizationId,
  });

  factory UDormCreateParams.fromJson(String str) => UDormCreateParams.fromMap(json.decode(str));

  factory UDormCreateParams.fromMap(Map<String, dynamic> json) => UDormCreateParams(
    tags: json["tags"] == null ? <int>[] : List<int>.from((json["tags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    id: json["id"],
    creatorId: json["creatorId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from((json["adminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    title: json["title"],
    cityCode: json["cityCode"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    description: json["description"],
    policies: json["policies"],
    highlights: json["highlights"] == null ? null : List<String>.from((json["highlights"] as List<dynamic>).map((dynamic e) => e.toString())),
    rules: json["rules"] == null ? null : List<String>.from((json["rules"] as List<dynamic>).map((dynamic e) => e.toString())),
    requiredDocuments: json["requiredDocuments"] == null ? null : List<String>.from((json["requiredDocuments"] as List<dynamic>).map((dynamic e) => e.toString())),
    nearbyUniversity: json["nearbyUniversity"],
    universityWalkMinutes: json["universityWalkMinutes"] == null ? null : (json["universityWalkMinutes"] as num).toInt(),
    visitingHours: json["visitingHours"],
    curfewTime: json["curfewTime"],
    minimumStayMonths: json["minimumStayMonths"] == null ? null : (json["minimumStayMonths"] as num).toInt(),
    howToGetThere: json["howToGetThere"],
    nearby: json["nearby"] == null ? null : List<UPlaceNearby>.from((json["nearby"] as List<dynamic>).map((dynamic e) => UPlaceNearby.fromMap(e))),
    faqs: json["faqs"] == null ? null : List<UPlaceFaq>.from((json["faqs"] as List<dynamic>).map((dynamic e) => UPlaceFaq.fromMap(e))),
    website: json["website"],
    whatsapp: json["whatsapp"],
    instagram: json["instagram"],
    telegram: json["telegram"],
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
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
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? policies;
  final List<String>? highlights;
  final List<String>? rules;
  final List<String>? requiredDocuments;
  final String? nearbyUniversity;
  final int? universityWalkMinutes;
  final String? visitingHours;
  final String? curfewTime;
  final int? minimumStayMonths;
  final String? howToGetThere;
  final List<UPlaceNearby>? nearby;
  final List<UPlaceFaq>? faqs;
  final String? website;
  final String? whatsapp;
  final String? instagram;
  final String? telegram;
  final double? latitude;
  final double? longitude;
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
    "address": address,
    "phoneNumber": phoneNumber,
    "description": description,
    "policies": policies,
    "highlights": highlights,
    "rules": rules,
    "requiredDocuments": requiredDocuments,
    "nearbyUniversity": nearbyUniversity,
    "universityWalkMinutes": universityWalkMinutes,
    "visitingHours": visitingHours,
    "curfewTime": curfewTime,
    "minimumStayMonths": minimumStayMonths,
    "howToGetThere": howToGetThere,
    "nearby": nearby?.map((UPlaceNearby e) => e.toMap()).toList(),
    "faqs": faqs?.map((UPlaceFaq e) => e.toMap()).toList(),
    "website": website,
    "whatsapp": whatsapp,
    "instagram": instagram,
    "telegram": telegram,
    "latitude": latitude,
    "longitude": longitude,
    "organizationId": organizationId,
  };
}

class UDormUpdateParams {
  UDormUpdateParams({
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
    this.address,
    this.phoneNumber,
    this.description,
    this.policies,
    this.highlights,
    this.rules,
    this.requiredDocuments,
    this.nearbyUniversity,
    this.universityWalkMinutes,
    this.visitingHours,
    this.curfewTime,
    this.minimumStayMonths,
    this.howToGetThere,
    this.nearby,
    this.faqs,
    this.website,
    this.whatsapp,
    this.instagram,
    this.telegram,
    this.latitude,
    this.longitude,
    this.organizationId,
  });

  factory UDormUpdateParams.fromJson(String str) => UDormUpdateParams.fromMap(json.decode(str));

  factory UDormUpdateParams.fromMap(Map<String, dynamic> json) => UDormUpdateParams(
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
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    description: json["description"],
    policies: json["policies"],
    highlights: json["highlights"] == null ? null : List<String>.from((json["highlights"] as List<dynamic>).map((dynamic e) => e.toString())),
    rules: json["rules"] == null ? null : List<String>.from((json["rules"] as List<dynamic>).map((dynamic e) => e.toString())),
    requiredDocuments: json["requiredDocuments"] == null ? null : List<String>.from((json["requiredDocuments"] as List<dynamic>).map((dynamic e) => e.toString())),
    nearbyUniversity: json["nearbyUniversity"],
    universityWalkMinutes: json["universityWalkMinutes"] == null ? null : (json["universityWalkMinutes"] as num).toInt(),
    visitingHours: json["visitingHours"],
    curfewTime: json["curfewTime"],
    minimumStayMonths: json["minimumStayMonths"] == null ? null : (json["minimumStayMonths"] as num).toInt(),
    howToGetThere: json["howToGetThere"],
    nearby: json["nearby"] == null ? null : List<UPlaceNearby>.from((json["nearby"] as List<dynamic>).map((dynamic e) => UPlaceNearby.fromMap(e))),
    faqs: json["faqs"] == null ? null : List<UPlaceFaq>.from((json["faqs"] as List<dynamic>).map((dynamic e) => UPlaceFaq.fromMap(e))),
    website: json["website"],
    whatsapp: json["whatsapp"],
    instagram: json["instagram"],
    telegram: json["telegram"],
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
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
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? policies;
  final List<String>? highlights;
  final List<String>? rules;
  final List<String>? requiredDocuments;
  final String? nearbyUniversity;
  final int? universityWalkMinutes;
  final String? visitingHours;
  final String? curfewTime;
  final int? minimumStayMonths;
  final String? howToGetThere;
  final List<UPlaceNearby>? nearby;
  final List<UPlaceFaq>? faqs;
  final String? website;
  final String? whatsapp;
  final String? instagram;
  final String? telegram;
  final double? latitude;
  final double? longitude;
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
    "address": address,
    "phoneNumber": phoneNumber,
    "description": description,
    "policies": policies,
    "highlights": highlights,
    "rules": rules,
    "requiredDocuments": requiredDocuments,
    "nearbyUniversity": nearbyUniversity,
    "universityWalkMinutes": universityWalkMinutes,
    "visitingHours": visitingHours,
    "curfewTime": curfewTime,
    "minimumStayMonths": minimumStayMonths,
    "howToGetThere": howToGetThere,
    "nearby": nearby?.map((UPlaceNearby e) => e.toMap()).toList(),
    "faqs": faqs?.map((UPlaceFaq e) => e.toMap()).toList(),
    "website": website,
    "whatsapp": whatsapp,
    "instagram": instagram,
    "telegram": telegram,
    "latitude": latitude,
    "longitude": longitude,
    "organizationId": organizationId,
  };
}

class UDormReadParams {
  final double? minRent;
  final double? maxRent;
  final bool? availableOnly;
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final String? title;
  final String? cityCode;
  final UDormSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? organizationId;

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
    this.minRent,
    this.maxRent,
    this.availableOnly,
    this.organizationId,
  });

  factory UDormReadParams.fromJson(String str) => UDormReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormReadParams.fromMap(Map<String, dynamic> json) => UDormReadParams(
    minRent: json["minRent"] == null ? null : (json["minRent"] as num).toDouble(),
    maxRent: json["maxRent"] == null ? null : (json["maxRent"] as num).toDouble(),
    availableOnly: json["availableOnly"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    title: json["title"],
    cityCode: json["cityCode"],
    selectorArgs: json["selectorArgs"] == null ? null : UDormSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    organizationId: json["organizationId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "minRent": minRent,
    "maxRent": maxRent,
    "availableOnly": availableOnly,
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
    "organizationId": organizationId,
  };
}

class UDormRoomCreateParams {
  UDormRoomCreateParams({
    required this.tags,
    required this.title,
    required this.dormId,
    this.capacity = 0,
    this.id,
    this.creatorId,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.description,
    this.floor,
    this.sizeSquareMeters,
  });

  factory UDormRoomCreateParams.fromJson(String str) => UDormRoomCreateParams.fromMap(json.decode(str));

  factory UDormRoomCreateParams.fromMap(Map<String, dynamic> json) => UDormRoomCreateParams(
    tags: json["tags"] == null ? <int>[] : List<int>.from((json["tags"] as List<dynamic>).map((dynamic e) => (e as num).toInt())),
    id: json["id"],
    creatorId: json["creatorId"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from((json["adminUserIds"] as List<dynamic>).map((dynamic e) => e.toString())),
    title: json["title"],
    dormId: json["dormId"],
    capacity: json["capacity"] ?? 0,
    description: json["description"],
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
  );

  final List<int> tags;
  final String? id;
  final String? creatorId;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final String title;
  final String dormId;
  final int capacity;
  final String? description;
  final int? floor;
  final double? sizeSquareMeters;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": tags,
    "id": id,
    "creatorId": creatorId,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds,
    "title": title,
    "dormId": dormId,
    "capacity": capacity,
    "description": description,
    "floor": floor,
    "sizeSquareMeters": sizeSquareMeters,
  };
}

class UDormRoomUpdateParams {
  UDormRoomUpdateParams({
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
    this.dormId,
    this.capacity,
    this.description,
    this.floor,
    this.sizeSquareMeters,
  });

  factory UDormRoomUpdateParams.fromJson(String str) => UDormRoomUpdateParams.fromMap(json.decode(str));

  factory UDormRoomUpdateParams.fromMap(Map<String, dynamic> json) => UDormRoomUpdateParams(
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
    dormId: json["dormId"],
    capacity: json["capacity"] == null ? null : (json["capacity"] as num).toInt(),
    description: json["description"],
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
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
  final String? dormId;
  final int? capacity;
  final String? description;
  final int? floor;
  final double? sizeSquareMeters;

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
    "dormId": dormId,
    "capacity": capacity,
    "description": description,
    "floor": floor,
    "sizeSquareMeters": sizeSquareMeters,
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
  final UDormRoomSelectorArgs? selectorArgs;
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
    selectorArgs: json["selectorArgs"] == null ? null : UDormRoomSelectorArgs.fromMap(json["selectorArgs"]),
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
  final UDormBedContractSelectorArgs? selectorArgs;
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
    selectorArgs: json["selectorArgs"] == null ? null : UDormBedContractSelectorArgs.fromMap(json["selectorArgs"]),
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
  final UDormBedInvoiceSelectorArgs? selectorArgs;
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
    selectorArgs: json["selectorArgs"] == null ? null : UDormBedInvoiceSelectorArgs.fromMap(json["selectorArgs"]),
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

class UDormBedContractSettleParams {
  UDormBedContractSettleParams({required this.id, this.endDate, this.deductions = 0, this.deductionReason});

  final String id;
  final DateTime? endDate;
  final double deductions;
  final String? deductionReason;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "endDate": endDate?.toIso8601String(),
    "deductions": deductions,
    "deductionReason": deductionReason,
  };
}

class UDormBedContractRenewParams {
  UDormBedContractRenewParams({required this.id, required this.endDate, this.rent});

  final String id;
  final DateTime endDate;
  final double? rent;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "endDate": endDate.toIso8601String(),
    "rent": rent,
  };
}

class UDormBedContractTransferParams {
  UDormBedContractTransferParams({required this.id, required this.bedId, this.date, this.rent});

  final String id;
  final String bedId;
  final DateTime? date;
  final double? rent;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "bedId": bedId,
    "date": date?.toIso8601String(),
    "rent": rent,
  };
}

class UDormBedInvoiceSplitParams {
  UDormBedInvoiceSplitParams({required this.id, required this.count});

  final String id;
  final int count;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "count": count,
  };
}
