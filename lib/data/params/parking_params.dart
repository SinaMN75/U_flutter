part of "../data.dart";

class UParkingCreateParams {
  final String title;
  final String? address;
  final String? phoneNumber;
  final int capacity;
  final double entrancePrice;
  final double hourlyPrice;
  final double dailyPrice;
  final List<int> tags;
  final String? detail1;
  final String? detail2;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;

  UParkingCreateParams({
    required this.title,
    required this.entrancePrice,
    required this.hourlyPrice,
    required this.dailyPrice,
    required this.tags,
    this.address,
    this.phoneNumber,
    this.capacity = 0,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UParkingCreateParams.fromJson(String str) => UParkingCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingCreateParams.fromMap(Map<String, dynamic> json) => UParkingCreateParams(
    title: json["title"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    capacity: json["capacity"] ?? 0,
    entrancePrice: json["entrancePrice"].toDouble(),
    hourlyPrice: json["hourlyPrice"].toDouble(),
    dailyPrice: json["dailyPrice"].toDouble(),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "address": address,
    "phoneNumber": phoneNumber,
    "capacity": capacity,
    "entrancePrice": entrancePrice,
    "hourlyPrice": hourlyPrice,
    "dailyPrice": dailyPrice,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "id": id,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UParkingUpdateParams {
  final String id;
  final String? title;
  final String? address;
  final String? phoneNumber;
  final int? capacity;
  final double? entrancePrice;
  final double? hourlyPrice;
  final double? dailyPrice;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;
  final List<int>? tags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UParkingUpdateParams({
    required this.id,
    this.title,
    this.address,
    this.phoneNumber,
    this.capacity,
    this.entrancePrice,
    this.hourlyPrice,
    this.dailyPrice,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
    this.tags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UParkingUpdateParams.fromJson(String str) => UParkingUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingUpdateParams.fromMap(Map<String, dynamic> json) => UParkingUpdateParams(
    id: json["id"],
    title: json["title"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    capacity: json["capacity"],
    entrancePrice: json["entrancePrice"]?.toDouble(),
    hourlyPrice: json["hourlyPrice"]?.toDouble(),
    dailyPrice: json["dailyPrice"]?.toDouble(),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "address": address,
    "phoneNumber": phoneNumber,
    "capacity": capacity,
    "entrancePrice": entrancePrice,
    "hourlyPrice": hourlyPrice,
    "dailyPrice": dailyPrice,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UParkingReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final UParkingSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? creatorId;

  UParkingReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.selectorArgs,
    this.orderBy,
    this.creatorId,
  });

  factory UParkingReadParams.fromJson(String str) => UParkingReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingReadParams.fromMap(Map<String, dynamic> json) => UParkingReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    selectorArgs: json["selectorArgs"] == null ? null : UParkingSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    creatorId: json["creatorId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "creatorId": creatorId,
  };
}

class UParkingReportCreateParams {
  final String parkingId;
  final DateTime startDate;
  final String numberPlate;
  final List<int> tags;
  final DateTime? endDate;
  final double? amount;
  final String? detail1;
  final String? detail2;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;

  UParkingReportCreateParams({
    required this.parkingId,
    required this.startDate,
    required this.numberPlate,
    required this.tags,
    this.endDate,
    this.amount,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UParkingReportCreateParams.fromJson(String str) => UParkingReportCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingReportCreateParams.fromMap(Map<String, dynamic> json) => UParkingReportCreateParams(
    parkingId: json["parkingId"],
    startDate: DateTime.parse(json["startDate"]),
    numberPlate: json["numberPlate"],
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    amount: json["amount"]?.toDouble(),
    detail1: json["detail1"],
    detail2: json["detail2"],
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "startDate": startDate.toIso8601String(),
    "numberPlate": numberPlate,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "endDate": endDate?.toIso8601String(),
    "amount": amount,
    "detail1": detail1,
    "detail2": detail2,
    "id": id,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UParkingReportUpdateParams {
  final String id;
  final String? creatorId;
  final String? vehicleId;
  final String? parkingId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? amount;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;
  final List<int>? tags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UParkingReportUpdateParams({
    required this.id,
    this.creatorId,
    this.vehicleId,
    this.parkingId,
    this.startDate,
    this.endDate,
    this.amount,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
    this.tags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UParkingReportUpdateParams.fromJson(String str) => UParkingReportUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingReportUpdateParams.fromMap(Map<String, dynamic> json) => UParkingReportUpdateParams(
    id: json["id"],
    creatorId: json["creatorId"],
    vehicleId: json["vehicleId"],
    parkingId: json["parkingId"],
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    amount: json["amount"]?.toDouble(),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "creatorId": creatorId,
    "vehicleId": vehicleId,
    "parkingId": parkingId,
    "startDate": startDate?.toIso8601String(),
    "endDate": endDate?.toIso8601String(),
    "amount": amount,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UParkingReportReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? vehicleId;
  final String? parkingId;
  final DateTime? startDate;
  final DateTime? endDate;
  final UParkingReportSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? creatorId;

  UParkingReportReadParams({
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.vehicleId,
    this.parkingId,
    this.startDate,
    this.endDate,
    this.selectorArgs,
    this.orderBy,
    this.creatorId,
  });

  factory UParkingReportReadParams.fromJson(String str) => UParkingReportReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingReportReadParams.fromMap(Map<String, dynamic> json) => UParkingReportReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    vehicleId: json["vehicleId"],
    parkingId: json["parkingId"],
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    selectorArgs: json["selectorArgs"] == null ? null : UParkingReportSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    creatorId: json["creatorId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "vehicleId": vehicleId,
    "parkingId": parkingId,
    "startDate": startDate?.toIso8601String(),
    "endDate": endDate?.toIso8601String(),
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "creatorId": creatorId,
  };
}

class UParkingUserCreateParams {
  final String parkingId;
  final String userName;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;

  UParkingUserCreateParams({
    required this.parkingId,
    required this.userName,
    required this.password,
    this.firstName,
    this.lastName,
    this.phoneNumber,
  });

  factory UParkingUserCreateParams.fromJson(String str) => UParkingUserCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingUserCreateParams.fromMap(Map<String, dynamic> json) => UParkingUserCreateParams(
    parkingId: json["parkingId"],
    userName: json["userName"],
    password: json["password"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    phoneNumber: json["phoneNumber"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "userName": userName,
    "password": password,
    "firstName": firstName,
    "lastName": lastName,
    "phoneNumber": phoneNumber,
  };
}

class UParkingUserDeleteParams {
  final String parkingId;
  final String userId;

  UParkingUserDeleteParams({
    required this.parkingId,
    required this.userId,
  });

  factory UParkingUserDeleteParams.fromJson(String str) => UParkingUserDeleteParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingUserDeleteParams.fromMap(Map<String, dynamic> json) => UParkingUserDeleteParams(
    parkingId: json["parkingId"],
    userId: json["userId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "userId": userId,
  };
}

class UParkingUserReadParams {
  final String parkingId;
  final UUserSelectorArgs? selectorArgs;

  UParkingUserReadParams({
    required this.parkingId,
    this.selectorArgs,
  });

  factory UParkingUserReadParams.fromJson(String str) => UParkingUserReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingUserReadParams.fromMap(Map<String, dynamic> json) => UParkingUserReadParams(
    parkingId: json["parkingId"],
    selectorArgs: json["selectorArgs"] == null ? null : UUserSelectorArgs.fromMap(json["selectorArgs"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "selectorArgs": selectorArgs?.toMap(),
  };
}

class UParkingTariffCreateParams {
  final String parkingId;
  final int vehicleType;
  final List<int> tags;
  final double entrancePrice;
  final double dayHourlyPrice;
  final double nightHourlyPrice;
  final double dailyCap;
  final double weeklyPrice;
  final double monthlyPrice;
  final double quarterlyPrice;
  final int freeMinutes;
  final int nightStartHour;
  final int nightEndHour;
  final int holidayExtraPercent;
  final bool roundToFullHour;
  final bool perMinuteAfterFirstHour;
  final int subscriptionDailyEntryLimit;
  final bool subscriptionOfficeHoursOnly;
  final int subscriptionExpiryReminderDays;
  final String detail1;
  final String detail2;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;

  UParkingTariffCreateParams({
    required this.parkingId,
    required this.vehicleType,
    required this.tags,
    this.entrancePrice = 0,
    this.dayHourlyPrice = 0,
    this.nightHourlyPrice = 0,
    this.dailyCap = 0,
    this.weeklyPrice = 0,
    this.monthlyPrice = 0,
    this.quarterlyPrice = 0,
    this.freeMinutes = 0,
    this.nightStartHour = 22,
    this.nightEndHour = 6,
    this.holidayExtraPercent = 0,
    this.roundToFullHour = false,
    this.perMinuteAfterFirstHour = true,
    this.subscriptionDailyEntryLimit = 0,
    this.subscriptionOfficeHoursOnly = false,
    this.subscriptionExpiryReminderDays = 5,
    this.detail1 = "",
    this.detail2 = "",
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UParkingTariffCreateParams.fromJson(String str) => UParkingTariffCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingTariffCreateParams.fromMap(Map<String, dynamic> json) => UParkingTariffCreateParams(
    parkingId: json["parkingId"],
    vehicleType: json["vehicleType"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    entrancePrice: (json["entrancePrice"] as num?)?.toDouble() ?? 0,
    dayHourlyPrice: (json["dayHourlyPrice"] as num?)?.toDouble() ?? 0,
    nightHourlyPrice: (json["nightHourlyPrice"] as num?)?.toDouble() ?? 0,
    dailyCap: (json["dailyCap"] as num?)?.toDouble() ?? 0,
    weeklyPrice: (json["weeklyPrice"] as num?)?.toDouble() ?? 0,
    monthlyPrice: (json["monthlyPrice"] as num?)?.toDouble() ?? 0,
    quarterlyPrice: (json["quarterlyPrice"] as num?)?.toDouble() ?? 0,
    freeMinutes: json["freeMinutes"] ?? 0,
    nightStartHour: json["nightStartHour"] ?? 22,
    nightEndHour: json["nightEndHour"] ?? 6,
    holidayExtraPercent: json["holidayExtraPercent"] ?? 0,
    roundToFullHour: json["roundToFullHour"] ?? false,
    perMinuteAfterFirstHour: json["perMinuteAfterFirstHour"] ?? true,
    subscriptionDailyEntryLimit: json["subscriptionDailyEntryLimit"] ?? 0,
    subscriptionOfficeHoursOnly: json["subscriptionOfficeHoursOnly"] ?? false,
    subscriptionExpiryReminderDays: json["subscriptionExpiryReminderDays"] ?? 5,
    detail1: json["detail1"] ?? "",
    detail2: json["detail2"] ?? "",
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "vehicleType": vehicleType,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "entrancePrice": entrancePrice,
    "dayHourlyPrice": dayHourlyPrice,
    "nightHourlyPrice": nightHourlyPrice,
    "dailyCap": dailyCap,
    "weeklyPrice": weeklyPrice,
    "monthlyPrice": monthlyPrice,
    "quarterlyPrice": quarterlyPrice,
    "freeMinutes": freeMinutes,
    "nightStartHour": nightStartHour,
    "nightEndHour": nightEndHour,
    "holidayExtraPercent": holidayExtraPercent,
    "roundToFullHour": roundToFullHour,
    "perMinuteAfterFirstHour": perMinuteAfterFirstHour,
    "subscriptionDailyEntryLimit": subscriptionDailyEntryLimit,
    "subscriptionOfficeHoursOnly": subscriptionOfficeHoursOnly,
    "subscriptionExpiryReminderDays": subscriptionExpiryReminderDays,
    "detail1": detail1,
    "detail2": detail2,
    if (id != null) "id": id,
    if (creatorId != null) "creatorId": creatorId,
    if (adminUserIds != null) "adminUserIds": List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UParkingTariffUpdateParams {
  final String id;
  final int? vehicleType;
  final double? entrancePrice;
  final double? dayHourlyPrice;
  final double? nightHourlyPrice;
  final double? dailyCap;
  final double? weeklyPrice;
  final double? monthlyPrice;
  final double? quarterlyPrice;
  final int? freeMinutes;
  final int? nightStartHour;
  final int? nightEndHour;
  final int? holidayExtraPercent;
  final bool? roundToFullHour;
  final bool? perMinuteAfterFirstHour;
  final int? subscriptionDailyEntryLimit;
  final bool? subscriptionOfficeHoursOnly;
  final int? subscriptionExpiryReminderDays;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UParkingTariffUpdateParams({
    required this.id,
    this.vehicleType,
    this.entrancePrice,
    this.dayHourlyPrice,
    this.nightHourlyPrice,
    this.dailyCap,
    this.weeklyPrice,
    this.monthlyPrice,
    this.quarterlyPrice,
    this.freeMinutes,
    this.nightStartHour,
    this.nightEndHour,
    this.holidayExtraPercent,
    this.roundToFullHour,
    this.perMinuteAfterFirstHour,
    this.subscriptionDailyEntryLimit,
    this.subscriptionOfficeHoursOnly,
    this.subscriptionExpiryReminderDays,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.tags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UParkingTariffUpdateParams.fromJson(String str) => UParkingTariffUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingTariffUpdateParams.fromMap(Map<String, dynamic> json) => UParkingTariffUpdateParams(
    id: json["id"],
    vehicleType: json["vehicleType"],
    entrancePrice: json["entrancePrice"] == null ? null : (json["entrancePrice"] as num).toDouble(),
    dayHourlyPrice: json["dayHourlyPrice"] == null ? null : (json["dayHourlyPrice"] as num).toDouble(),
    nightHourlyPrice: json["nightHourlyPrice"] == null ? null : (json["nightHourlyPrice"] as num).toDouble(),
    dailyCap: json["dailyCap"] == null ? null : (json["dailyCap"] as num).toDouble(),
    weeklyPrice: json["weeklyPrice"] == null ? null : (json["weeklyPrice"] as num).toDouble(),
    monthlyPrice: json["monthlyPrice"] == null ? null : (json["monthlyPrice"] as num).toDouble(),
    quarterlyPrice: json["quarterlyPrice"] == null ? null : (json["quarterlyPrice"] as num).toDouble(),
    freeMinutes: json["freeMinutes"],
    nightStartHour: json["nightStartHour"],
    nightEndHour: json["nightEndHour"],
    holidayExtraPercent: json["holidayExtraPercent"],
    roundToFullHour: json["roundToFullHour"],
    perMinuteAfterFirstHour: json["perMinuteAfterFirstHour"],
    subscriptionDailyEntryLimit: json["subscriptionDailyEntryLimit"],
    subscriptionOfficeHoursOnly: json["subscriptionOfficeHoursOnly"],
    subscriptionExpiryReminderDays: json["subscriptionExpiryReminderDays"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? null : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? null : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "vehicleType": vehicleType,
    "entrancePrice": entrancePrice,
    "dayHourlyPrice": dayHourlyPrice,
    "nightHourlyPrice": nightHourlyPrice,
    "dailyCap": dailyCap,
    "weeklyPrice": weeklyPrice,
    "monthlyPrice": monthlyPrice,
    "quarterlyPrice": quarterlyPrice,
    "freeMinutes": freeMinutes,
    "nightStartHour": nightStartHour,
    "nightEndHour": nightEndHour,
    "holidayExtraPercent": holidayExtraPercent,
    "roundToFullHour": roundToFullHour,
    "perMinuteAfterFirstHour": perMinuteAfterFirstHour,
    "subscriptionDailyEntryLimit": subscriptionDailyEntryLimit,
    "subscriptionOfficeHoursOnly": subscriptionOfficeHoursOnly,
    "subscriptionExpiryReminderDays": subscriptionExpiryReminderDays,
    if (detail1 != null) "detail1": detail1,
    if (detail2 != null) "detail2": detail2,
    if (addTags != null) "addTags": List<dynamic>.from(addTags!.map((int x) => x)),
    if (removeTags != null) "removeTags": List<dynamic>.from(removeTags!.map((int x) => x)),
    if (tags != null) "tags": List<dynamic>.from(tags!.map((int x) => x)),
    if (adminUserIds != null) "adminUserIds": List<dynamic>.from(adminUserIds!.map((String x) => x)),
    if (addAdminUserIds != null) "addAdminUserIds": List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    if (removeAdminUserIds != null) "removeAdminUserIds": List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UParkingTariffReadParams {
  final String? parkingId;
  final int? vehicleType;
  final int? pageSize;
  final int? pageNumber;
  final UParkingTariffSelectorArgs? selectorArgs;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final TagOrderBy orderBy;

  UParkingTariffReadParams({
    this.parkingId,
    this.vehicleType,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.orderBy = TagOrderBy.createdAt,
  });

  factory UParkingTariffReadParams.fromJson(String str) => UParkingTariffReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingTariffReadParams.fromMap(Map<String, dynamic> json) => UParkingTariffReadParams(
    parkingId: json["parkingId"],
    vehicleType: json["vehicleType"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UParkingTariffSelectorArgs.fromMap(json["selectorArgs"]),
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    orderBy: TagOrderBy.values.firstWhereOrNull((TagOrderBy e) => e.number == json["orderBy"]) ?? TagOrderBy.createdAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "vehicleType": vehicleType,
    if (pageSize != null) "pageSize": pageSize,
    if (pageNumber != null) "pageNumber": pageNumber,
    if (selectorArgs != null) "selectorArgs": selectorArgs?.toMap(),
    if (fromCreatedAt != null) "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    if (toCreatedAt != null) "toCreatedAt": toCreatedAt?.toIso8601String(),
    if (tags != null) "tags": List<dynamic>.from(tags!.map((int x) => x)),
    if (ids != null) "ids": List<dynamic>.from(ids!.map((String x) => x)),
    if (creatorId != null) "creatorId": creatorId,
    "orderBy": orderBy.number,
  };
}

class UParkingSubscriptionCreateParams {
  final String parkingId;
  final String licencePlate;
  final int vehicleType;
  final List<int> tags;
  final String? customerName;
  final String? customerPhoneNumber;
  final double price;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final int dailyEntryLimit;
  final bool officeHoursOnly;
  final String detail1;
  final String detail2;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;

  UParkingSubscriptionCreateParams({
    required this.parkingId,
    required this.licencePlate,
    required this.vehicleType,
    required this.tags,
    this.customerName,
    this.customerPhoneNumber,
    this.price = 0,
    this.startDate,
    this.expiryDate,
    this.dailyEntryLimit = 0,
    this.officeHoursOnly = false,
    this.detail1 = "",
    this.detail2 = "",
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UParkingSubscriptionCreateParams.fromJson(String str) => UParkingSubscriptionCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingSubscriptionCreateParams.fromMap(Map<String, dynamic> json) => UParkingSubscriptionCreateParams(
    parkingId: json["parkingId"],
    licencePlate: json["licencePlate"],
    vehicleType: json["vehicleType"] ?? TagVehicle.car,
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    customerName: json["customerName"],
    customerPhoneNumber: json["customerPhoneNumber"],
    price: (json["price"] as num?)?.toDouble() ?? 0,
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    expiryDate: json["expiryDate"] == null ? null : DateTime.parse(json["expiryDate"]),
    dailyEntryLimit: json["dailyEntryLimit"] ?? 0,
    officeHoursOnly: json["officeHoursOnly"] ?? false,
    detail1: json["detail1"] ?? "",
    detail2: json["detail2"] ?? "",
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "licencePlate": licencePlate,
    "vehicleType": vehicleType,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "customerName": customerName,
    "customerPhoneNumber": customerPhoneNumber,
    "price": price,
    "startDate": startDate?.toIso8601String(),
    "expiryDate": expiryDate?.toIso8601String(),
    "dailyEntryLimit": dailyEntryLimit,
    "officeHoursOnly": officeHoursOnly,
    "detail1": detail1,
    "detail2": detail2,
    if (id != null) "id": id,
    if (creatorId != null) "creatorId": creatorId,
    if (adminUserIds != null) "adminUserIds": List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UParkingSubscriptionUpdateParams {
  final String id;
  final String? customerName;
  final String? customerPhoneNumber;
  final double? price;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final int? dailyEntryLimit;
  final bool? officeHoursOnly;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;
  final List<int>? tags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UParkingSubscriptionUpdateParams({
    required this.id,
    this.customerName,
    this.customerPhoneNumber,
    this.price,
    this.startDate,
    this.expiryDate,
    this.dailyEntryLimit,
    this.officeHoursOnly,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
    this.tags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UParkingSubscriptionUpdateParams.fromJson(String str) => UParkingSubscriptionUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingSubscriptionUpdateParams.fromMap(Map<String, dynamic> json) => UParkingSubscriptionUpdateParams(
    id: json["id"],
    customerName: json["customerName"],
    customerPhoneNumber: json["customerPhoneNumber"],
    price: json["price"] == null ? null : (json["price"] as num).toDouble(),
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    expiryDate: json["expiryDate"] == null ? null : DateTime.parse(json["expiryDate"]),
    dailyEntryLimit: json["dailyEntryLimit"],
    officeHoursOnly: json["officeHoursOnly"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? null : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? null : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "customerName": customerName,
    "customerPhoneNumber": customerPhoneNumber,
    "price": price,
    "startDate": startDate?.toIso8601String(),
    "expiryDate": expiryDate?.toIso8601String(),
    "dailyEntryLimit": dailyEntryLimit,
    "officeHoursOnly": officeHoursOnly,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    if (detail1 != null) "detail1": detail1,
    if (detail2 != null) "detail2": detail2,
    if (tags != null) "tags": List<dynamic>.from(tags!.map((int x) => x)),
    if (adminUserIds != null) "adminUserIds": List<dynamic>.from(adminUserIds!.map((String x) => x)),
    if (addAdminUserIds != null) "addAdminUserIds": List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    if (removeAdminUserIds != null) "removeAdminUserIds": List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UParkingSubscriptionReadParams {
  final String? parkingId;
  final String? licencePlate;
  final String? query;
  final bool? isActive;
  final bool? isExpiringSoon;
  final bool? isExpired;
  final int expiringInDays;
  final int? pageSize;
  final int? pageNumber;
  final List<int>? tags;
  final UParkingSubscriptionSelectorArgs? selectorArgs;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<String>? ids;
  final String? creatorId;
  final TagOrderBy orderBy;

  UParkingSubscriptionReadParams({
    this.parkingId,
    this.licencePlate,
    this.query,
    this.isActive,
    this.isExpiringSoon,
    this.isExpired,
    this.expiringInDays = 7,
    this.pageSize,
    this.pageNumber,
    this.tags,
    this.selectorArgs,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.ids,
    this.creatorId,
    this.orderBy = TagOrderBy.createdAt,
  });

  factory UParkingSubscriptionReadParams.fromJson(String str) => UParkingSubscriptionReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingSubscriptionReadParams.fromMap(Map<String, dynamic> json) => UParkingSubscriptionReadParams(
    parkingId: json["parkingId"],
    licencePlate: json["licencePlate"],
    query: json["query"],
    isActive: json["isActive"],
    isExpiringSoon: json["isExpiringSoon"],
    isExpired: json["isExpired"],
    expiringInDays: json["expiringInDays"] ?? 7,
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    selectorArgs: json["selectorArgs"] == null ? null : UParkingSubscriptionSelectorArgs.fromMap(json["selectorArgs"]),
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    orderBy: TagOrderBy.values.firstWhereOrNull((TagOrderBy e) => e.number == json["orderBy"]) ?? TagOrderBy.createdAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "licencePlate": licencePlate,
    "query": query,
    "isActive": isActive,
    "isExpiringSoon": isExpiringSoon,
    "isExpired": isExpired,
    "expiringInDays": expiringInDays,
    if (pageSize != null) "pageSize": pageSize,
    if (pageNumber != null) "pageNumber": pageNumber,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    if (selectorArgs != null) "selectorArgs": selectorArgs?.toMap(),
    if (fromCreatedAt != null) "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    if (toCreatedAt != null) "toCreatedAt": toCreatedAt?.toIso8601String(),
    if (ids != null) "ids": List<dynamic>.from(ids!.map((String x) => x)),
    if (creatorId != null) "creatorId": creatorId,
    "orderBy": orderBy.number,
  };
}

class UParkingPlateFlagCreateParams {
  final String parkingId;
  final String licencePlate;
  final List<int> tags;
  final String? reason;
  final double? amount;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? spotNumber;
  final String detail1;
  final String detail2;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;

  UParkingPlateFlagCreateParams({
    required this.parkingId,
    required this.licencePlate,
    required this.tags,
    this.reason,
    this.amount,
    this.fromDate,
    this.toDate,
    this.spotNumber,
    this.detail1 = "",
    this.detail2 = "",
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UParkingPlateFlagCreateParams.fromJson(String str) => UParkingPlateFlagCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingPlateFlagCreateParams.fromMap(Map<String, dynamic> json) => UParkingPlateFlagCreateParams(
    parkingId: json["parkingId"],
    licencePlate: json["licencePlate"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    reason: json["reason"],
    amount: json["amount"] == null ? null : (json["amount"] as num).toDouble(),
    fromDate: json["fromDate"] == null ? null : DateTime.parse(json["fromDate"]),
    toDate: json["toDate"] == null ? null : DateTime.parse(json["toDate"]),
    spotNumber: json["spotNumber"],
    detail1: json["detail1"] ?? "",
    detail2: json["detail2"] ?? "",
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "licencePlate": licencePlate,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "reason": reason,
    "amount": amount,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
    "spotNumber": spotNumber,
    "detail1": detail1,
    "detail2": detail2,
    if (id != null) "id": id,
    if (creatorId != null) "creatorId": creatorId,
    if (adminUserIds != null) "adminUserIds": List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UParkingPlateFlagUpdateParams {
  final String id;
  final String? reason;
  final double? amount;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? spotNumber;
  final List<int>? tags;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UParkingPlateFlagUpdateParams({
    required this.id,
    this.reason,
    this.amount,
    this.fromDate,
    this.toDate,
    this.spotNumber,
    this.tags,
    this.detail1,
    this.detail2,
    this.addTags,
    this.removeTags,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UParkingPlateFlagUpdateParams.fromJson(String str) => UParkingPlateFlagUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingPlateFlagUpdateParams.fromMap(Map<String, dynamic> json) => UParkingPlateFlagUpdateParams(
    id: json["id"],
    reason: json["reason"],
    amount: json["amount"] == null ? null : (json["amount"] as num).toDouble(),
    fromDate: json["fromDate"] == null ? null : DateTime.parse(json["fromDate"]),
    toDate: json["toDate"] == null ? null : DateTime.parse(json["toDate"]),
    spotNumber: json["spotNumber"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? null : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? null : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "reason": reason,
    "amount": amount,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
    "spotNumber": spotNumber,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    if (detail1 != null) "detail1": detail1,
    if (detail2 != null) "detail2": detail2,
    if (addTags != null) "addTags": List<dynamic>.from(addTags!.map((int x) => x)),
    if (removeTags != null) "removeTags": List<dynamic>.from(removeTags!.map((int x) => x)),
    if (adminUserIds != null) "adminUserIds": List<dynamic>.from(adminUserIds!.map((String x) => x)),
    if (addAdminUserIds != null) "addAdminUserIds": List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    if (removeAdminUserIds != null) "removeAdminUserIds": List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UParkingPlateFlagReadParams {
  final String? parkingId;
  final String? licencePlate;
  final List<int>? tags;
  final int? pageSize;
  final int? pageNumber;
  final UParkingPlateFlagSelectorArgs? selectorArgs;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<String>? ids;
  final String? creatorId;
  final TagOrderBy orderBy;

  UParkingPlateFlagReadParams({
    this.parkingId,
    this.licencePlate,
    this.tags,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.ids,
    this.creatorId,
    this.orderBy = TagOrderBy.createdAt,
  });

  factory UParkingPlateFlagReadParams.fromJson(String str) => UParkingPlateFlagReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingPlateFlagReadParams.fromMap(Map<String, dynamic> json) => UParkingPlateFlagReadParams(
    parkingId: json["parkingId"],
    licencePlate: json["licencePlate"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UParkingPlateFlagSelectorArgs.fromMap(json["selectorArgs"]),
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    orderBy: TagOrderBy.values.firstWhereOrNull((TagOrderBy e) => e.number == json["orderBy"]) ?? TagOrderBy.createdAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "licencePlate": licencePlate,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    if (pageSize != null) "pageSize": pageSize,
    if (pageNumber != null) "pageNumber": pageNumber,
    if (selectorArgs != null) "selectorArgs": selectorArgs?.toMap(),
    if (fromCreatedAt != null) "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    if (toCreatedAt != null) "toCreatedAt": toCreatedAt?.toIso8601String(),
    if (ids != null) "ids": List<dynamic>.from(ids!.map((String x) => x)),
    if (creatorId != null) "creatorId": creatorId,
    "orderBy": orderBy.number,
  };
}

class UParkingStaffCreateParams {
  final String parkingId;
  final String userName;
  final String password;
  final List<int> tags;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? shiftTitle;
  final int maxDiscountPercent;
  final String detail1;
  final String detail2;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;

  UParkingStaffCreateParams({
    required this.parkingId,
    required this.userName,
    required this.password,
    required this.tags,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.shiftTitle,
    this.maxDiscountPercent = 0,
    this.detail1 = "",
    this.detail2 = "",
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UParkingStaffCreateParams.fromJson(String str) => UParkingStaffCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingStaffCreateParams.fromMap(Map<String, dynamic> json) => UParkingStaffCreateParams(
    parkingId: json["parkingId"],
    userName: json["userName"],
    password: json["password"],
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    firstName: json["firstName"],
    lastName: json["lastName"],
    phoneNumber: json["phoneNumber"],
    shiftTitle: json["shiftTitle"],
    maxDiscountPercent: json["maxDiscountPercent"] ?? 0,
    detail1: json["detail1"] ?? "",
    detail2: json["detail2"] ?? "",
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "userName": userName,
    "password": password,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "firstName": firstName,
    "lastName": lastName,
    "phoneNumber": phoneNumber,
    "shiftTitle": shiftTitle,
    "maxDiscountPercent": maxDiscountPercent,
    "detail1": detail1,
    "detail2": detail2,
    if (id != null) "id": id,
    if (creatorId != null) "creatorId": creatorId,
    if (adminUserIds != null) "adminUserIds": List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UParkingStaffUpdateParams {
  final String id;
  final String? shiftTitle;
  final int? maxDiscountPercent;
  final String? password;
  final List<int>? tags;
  final List<int>? addTags;
  final List<int>? removeTags;
  final String? detail1;
  final String? detail2;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UParkingStaffUpdateParams({
    required this.id,
    this.shiftTitle,
    this.maxDiscountPercent,
    this.password,
    this.tags,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UParkingStaffUpdateParams.fromJson(String str) => UParkingStaffUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingStaffUpdateParams.fromMap(Map<String, dynamic> json) => UParkingStaffUpdateParams(
    id: json["id"],
    shiftTitle: json["shiftTitle"],
    maxDiscountPercent: json["maxDiscountPercent"],
    password: json["password"],
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? null : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? null : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? null : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "shiftTitle": shiftTitle,
    "maxDiscountPercent": maxDiscountPercent,
    "password": password,
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((int x) => x)),
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((int x) => x)),
    if (detail1 != null) "detail1": detail1,
    if (detail2 != null) "detail2": detail2,
    if (adminUserIds != null) "adminUserIds": List<dynamic>.from(adminUserIds!.map((String x) => x)),
    if (addAdminUserIds != null) "addAdminUserIds": List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    if (removeAdminUserIds != null) "removeAdminUserIds": List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UParkingStaffReadParams {
  final String? parkingId;
  final int? pageSize;
  final int? pageNumber;
  final UParkingStaffSelectorArgs? selectorArgs;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final TagOrderBy orderBy;

  UParkingStaffReadParams({
    this.parkingId,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.orderBy = TagOrderBy.createdAt,
  });

  factory UParkingStaffReadParams.fromJson(String str) => UParkingStaffReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingStaffReadParams.fromMap(Map<String, dynamic> json) => UParkingStaffReadParams(
    parkingId: json["parkingId"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UParkingStaffSelectorArgs.fromMap(json["selectorArgs"]),
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    orderBy: TagOrderBy.values.firstWhereOrNull((TagOrderBy e) => e.number == json["orderBy"]) ?? TagOrderBy.createdAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    if (pageSize != null) "pageSize": pageSize,
    if (pageNumber != null) "pageNumber": pageNumber,
    if (selectorArgs != null) "selectorArgs": selectorArgs?.toMap(),
    if (fromCreatedAt != null) "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    if (toCreatedAt != null) "toCreatedAt": toCreatedAt?.toIso8601String(),
    if (tags != null) "tags": List<dynamic>.from(tags!.map((int x) => x)),
    if (ids != null) "ids": List<dynamic>.from(ids!.map((String x) => x)),
    if (creatorId != null) "creatorId": creatorId,
    "orderBy": orderBy.number,
  };
}

class UParkingShiftOpenParams {
  final String parkingId;

  UParkingShiftOpenParams({
    required this.parkingId,
  });

  factory UParkingShiftOpenParams.fromJson(String str) => UParkingShiftOpenParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingShiftOpenParams.fromMap(Map<String, dynamic> json) => UParkingShiftOpenParams(
    parkingId: json["parkingId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
  };
}

class UParkingShiftCloseParams {
  final String id;
  final double countedCash;

  UParkingShiftCloseParams({
    required this.id,
    this.countedCash = 0,
  });

  factory UParkingShiftCloseParams.fromJson(String str) => UParkingShiftCloseParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingShiftCloseParams.fromMap(Map<String, dynamic> json) => UParkingShiftCloseParams(
    id: json["id"],
    countedCash: (json["countedCash"] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "countedCash": countedCash,
  };
}

class UParkingShiftReadParams {
  final String? parkingId;
  final bool? isOpen;
  final int? pageSize;
  final int? pageNumber;
  final UParkingShiftSelectorArgs? selectorArgs;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final TagOrderBy orderBy;

  UParkingShiftReadParams({
    this.parkingId,
    this.isOpen,
    this.pageSize,
    this.pageNumber,
    this.selectorArgs,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.orderBy = TagOrderBy.createdAt,
  });

  factory UParkingShiftReadParams.fromJson(String str) => UParkingShiftReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingShiftReadParams.fromMap(Map<String, dynamic> json) => UParkingShiftReadParams(
    parkingId: json["parkingId"],
    isOpen: json["isOpen"],
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    selectorArgs: json["selectorArgs"] == null ? null : UParkingShiftSelectorArgs.fromMap(json["selectorArgs"]),
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? null : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    orderBy: TagOrderBy.values.firstWhereOrNull((TagOrderBy e) => e.number == json["orderBy"]) ?? TagOrderBy.createdAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "isOpen": isOpen,
    if (pageSize != null) "pageSize": pageSize,
    if (pageNumber != null) "pageNumber": pageNumber,
    if (selectorArgs != null) "selectorArgs": selectorArgs?.toMap(),
    if (fromCreatedAt != null) "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    if (toCreatedAt != null) "toCreatedAt": toCreatedAt?.toIso8601String(),
    if (tags != null) "tags": List<dynamic>.from(tags!.map((int x) => x)),
    if (ids != null) "ids": List<dynamic>.from(ids!.map((String x) => x)),
    if (creatorId != null) "creatorId": creatorId,
    "orderBy": orderBy.number,
  };
}

class UParkingPlateStatusParams {
  final String parkingId;
  final String licencePlate;
  final int vehicleType;

  UParkingPlateStatusParams({
    required this.parkingId,
    required this.licencePlate,
    required this.vehicleType,
  });

  factory UParkingPlateStatusParams.fromJson(String str) => UParkingPlateStatusParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingPlateStatusParams.fromMap(Map<String, dynamic> json) => UParkingPlateStatusParams(
    parkingId: json["parkingId"],
    licencePlate: json["licencePlate"],
    vehicleType: json["vehicleType"] ?? TagVehicle.car,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "licencePlate": licencePlate,
    "vehicleType": vehicleType,
  };
}

class UParkingEntryParams {
  final String parkingId;
  final String licencePlate;
  final int vehicleType;
  final DateTime? startDate;
  final String? spotNumber;
  final String? customerPhoneNumber;
  final bool isOffline;

  UParkingEntryParams({
    required this.parkingId,
    required this.licencePlate,
    required this.vehicleType,
    this.startDate,
    this.spotNumber,
    this.customerPhoneNumber,
    this.isOffline = false,
  });

  factory UParkingEntryParams.fromJson(String str) => UParkingEntryParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingEntryParams.fromMap(Map<String, dynamic> json) => UParkingEntryParams(
    parkingId: json["parkingId"],
    licencePlate: json["licencePlate"],
    vehicleType: json["vehicleType"] ?? TagVehicle.car,
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    spotNumber: json["spotNumber"],
    customerPhoneNumber: json["customerPhoneNumber"],
    isOffline: json["isOffline"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "licencePlate": licencePlate,
    "vehicleType": vehicleType,
    "startDate": startDate?.toIso8601String(),
    "spotNumber": spotNumber,
    "customerPhoneNumber": customerPhoneNumber,
    "isOffline": isOffline,
  };
}

class UParkingExitCalculateParams {
  final String? reportId;
  final String? parkingId;
  final String? licencePlate;
  final DateTime? endDate;
  final DateTime? correctedStartDate;
  final double discount;

  UParkingExitCalculateParams({
    this.reportId,
    this.parkingId,
    this.licencePlate,
    this.endDate,
    this.correctedStartDate,
    this.discount = 0,
  });

  factory UParkingExitCalculateParams.fromJson(String str) => UParkingExitCalculateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingExitCalculateParams.fromMap(Map<String, dynamic> json) => UParkingExitCalculateParams(
    reportId: json["reportId"],
    parkingId: json["parkingId"],
    licencePlate: json["licencePlate"],
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    correctedStartDate: json["correctedStartDate"] == null ? null : DateTime.parse(json["correctedStartDate"]),
    discount: (json["discount"] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reportId": reportId,
    "parkingId": parkingId,
    "licencePlate": licencePlate,
    "endDate": endDate?.toIso8601String(),
    "correctedStartDate": correctedStartDate?.toIso8601String(),
    "discount": discount,
  };
}

class UParkingExitParams {
  final String reportId;
  final DateTime? endDate;
  final DateTime? correctedStartDate;
  final double discount;
  final int paymentMethod;
  final String? trackingCode;
  final bool isOffline;

  UParkingExitParams({
    required this.reportId,
    required this.paymentMethod,
    this.endDate,
    this.correctedStartDate,
    this.discount = 0,
    this.trackingCode,
    this.isOffline = false,
  });

  factory UParkingExitParams.fromJson(String str) => UParkingExitParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingExitParams.fromMap(Map<String, dynamic> json) => UParkingExitParams(
    reportId: json["reportId"],
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    correctedStartDate: json["correctedStartDate"] == null ? null : DateTime.parse(json["correctedStartDate"]),
    discount: (json["discount"] as num?)?.toDouble() ?? 0,
    paymentMethod: json["paymentMethod"] ?? TagParkingPayment.cash,
    trackingCode: json["trackingCode"],
    isOffline: json["isOffline"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reportId": reportId,
    "endDate": endDate?.toIso8601String(),
    "correctedStartDate": correctedStartDate?.toIso8601String(),
    "discount": discount,
    "paymentMethod": paymentMethod,
    "trackingCode": trackingCode,
    "isOffline": isOffline,
  };
}

class UParkingDashboardParams {
  final String parkingId;
  final int recentCount;

  UParkingDashboardParams({
    required this.parkingId,
    this.recentCount = 10,
  });

  factory UParkingDashboardParams.fromJson(String str) => UParkingDashboardParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingDashboardParams.fromMap(Map<String, dynamic> json) => UParkingDashboardParams(
    parkingId: json["parkingId"],
    recentCount: json["recentCount"] ?? 10,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "recentCount": recentCount,
  };
}

class UParkingInsideVehiclesParams {
  final String parkingId;
  final String? query;
  final bool? longerThanADay;
  final bool? hasSubscription;
  final int pageSize;
  final int pageNumber;

  UParkingInsideVehiclesParams({
    required this.parkingId,
    this.query,
    this.longerThanADay,
    this.hasSubscription,
    this.pageSize = 50,
    this.pageNumber = 1,
  });

  factory UParkingInsideVehiclesParams.fromJson(String str) => UParkingInsideVehiclesParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingInsideVehiclesParams.fromMap(Map<String, dynamic> json) => UParkingInsideVehiclesParams(
    parkingId: json["parkingId"],
    query: json["query"],
    longerThanADay: json["longerThanADay"],
    hasSubscription: json["hasSubscription"],
    pageSize: json["pageSize"] ?? 50,
    pageNumber: json["pageNumber"] ?? 1,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "query": query,
    "longerThanADay": longerThanADay,
    "hasSubscription": hasSubscription,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
  };
}
