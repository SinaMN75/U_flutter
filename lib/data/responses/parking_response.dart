part of "../data.dart";

class UParkingResponse {
  UParkingResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.adminUserIds,
    required this.entrancePrice,
    required this.hourlyPrice,
    required this.dailyPrice,
    required this.capacity,
    this.address,
    this.phoneNumber,
    this.creator,
    this.creatorId,
  });

  factory UParkingResponse.fromJson(String str) => UParkingResponse.fromMap(json.decode(str));

  factory UParkingResponse.fromMap(Map<String, dynamic> json) => UParkingResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    title: json["title"],
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    capacity: json["capacity"] ?? 0,
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    entrancePrice: (json["entrancePrice"] as num).toDouble(),
    hourlyPrice: (json["hourlyPrice"] as num).toDouble(),
    dailyPrice: (json["dailyPrice"] as num).toDouble(),
  );

  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final String title;
  final String? address;
  final String? phoneNumber;
  final int capacity;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;
  final double entrancePrice;
  final double hourlyPrice;
  final double dailyPrice;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "title": title,
    "address": address,
    "phoneNumber": phoneNumber,
    "capacity": capacity,
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
    "entrancePrice": entrancePrice,
    "hourlyPrice": hourlyPrice,
    "dailyPrice": dailyPrice,
  };
}

class UParkingReportResponse {
  UParkingReportResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.startDate,
    required this.vehicleId,
    required this.parkingId,
    required this.adminUserIds,
    this.receiptNumber,
    this.spotNumber,
    this.customerPhoneNumber,
    this.discount = 0,
    this.paidAmount = 0,
    this.paymentMethod,
    this.trackingCode,
    this.subscriptionId,
    this.shiftId,
    this.endDate,
    this.amount,
    this.vehicle,
    this.parking,
    this.creator,
    this.creatorId,
  });

  factory UParkingReportResponse.fromJson(String str) => UParkingReportResponse.fromMap(json.decode(str));

  factory UParkingReportResponse.fromMap(Map<String, dynamic> json) => UParkingReportResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    startDate: DateTime.parse(json["startDate"]),
    vehicleId: json["vehicleId"],
    parkingId: json["parkingId"],
    receiptNumber: json["receiptNumber"],
    spotNumber: json["spotNumber"],
    customerPhoneNumber: json["customerPhoneNumber"],
    discount: (json["discount"] as num?)?.toDouble() ?? 0,
    paidAmount: (json["paidAmount"] as num?)?.toDouble() ?? 0,
    paymentMethod: json["paymentMethod"],
    trackingCode: json["trackingCode"],
    subscriptionId: json["subscriptionId"],
    shiftId: json["shiftId"],
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    amount: json["amount"]?.toDouble(),
    vehicle: json["vehicle"] == null ? null : UVehicleResponse.fromMap(json["vehicle"]),
    parking: json["parking"] == null ? null : UParkingResponse.fromMap(json["parking"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final DateTime startDate;
  final String vehicleId;
  final String parkingId;
  final String? receiptNumber;
  final String? spotNumber;
  final String? customerPhoneNumber;
  final double discount;
  final double paidAmount;
  final int? paymentMethod;
  final String? trackingCode;
  final String? subscriptionId;
  final String? shiftId;
  final DateTime? endDate;
  final double? amount;
  final UVehicleResponse? vehicle;
  final UParkingResponse? parking;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "startDate": startDate.toIso8601String(),
    "vehicleId": vehicleId,
    "parkingId": parkingId,
    "receiptNumber": receiptNumber,
    "spotNumber": spotNumber,
    "customerPhoneNumber": customerPhoneNumber,
    "discount": discount,
    "paidAmount": paidAmount,
    "paymentMethod": paymentMethod,
    "trackingCode": trackingCode,
    "subscriptionId": subscriptionId,
    "shiftId": shiftId,
    "endDate": endDate?.toIso8601String(),
    "amount": amount,
    "vehicle": vehicle?.toMap(),
    "parking": parking?.toMap(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UParkingTariffResponse {
  UParkingTariffResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.parkingId,
    required this.vehicleType,
    required this.entrancePrice,
    required this.dayHourlyPrice,
    required this.nightHourlyPrice,
    required this.dailyCap,
    required this.weeklyPrice,
    required this.monthlyPrice,
    required this.quarterlyPrice,
    required this.freeMinutes,
    required this.nightStartHour,
    required this.nightEndHour,
    required this.holidayExtraPercent,
    required this.roundToFullHour,
    required this.perMinuteAfterFirstHour,
    required this.subscriptionDailyEntryLimit,
    required this.subscriptionOfficeHoursOnly,
    required this.subscriptionExpiryReminderDays,
    this.creatorId,
  });

  factory UParkingTariffResponse.fromJson(String str) => UParkingTariffResponse.fromMap(json.decode(str));

  factory UParkingTariffResponse.fromMap(Map<String, dynamic> json) => UParkingTariffResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    parkingId: json["parkingId"],
    vehicleType: json["vehicleType"],
    entrancePrice: (json["entrancePrice"] as num).toDouble(),
    dayHourlyPrice: (json["dayHourlyPrice"] as num).toDouble(),
    nightHourlyPrice: (json["nightHourlyPrice"] as num).toDouble(),
    dailyCap: (json["dailyCap"] as num).toDouble(),
    weeklyPrice: (json["weeklyPrice"] as num).toDouble(),
    monthlyPrice: (json["monthlyPrice"] as num).toDouble(),
    quarterlyPrice: (json["quarterlyPrice"] as num).toDouble(),
    freeMinutes: json["freeMinutes"] ?? 0,
    nightStartHour: json["nightStartHour"] ?? 22,
    nightEndHour: json["nightEndHour"] ?? 6,
    holidayExtraPercent: json["holidayExtraPercent"] ?? 0,
    roundToFullHour: json["roundToFullHour"] ?? false,
    perMinuteAfterFirstHour: json["perMinuteAfterFirstHour"] ?? true,
    subscriptionDailyEntryLimit: json["subscriptionDailyEntryLimit"] ?? 0,
    subscriptionOfficeHoursOnly: json["subscriptionOfficeHoursOnly"] ?? false,
    subscriptionExpiryReminderDays: json["subscriptionExpiryReminderDays"] ?? 5,
    creatorId: json["creatorId"],
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String parkingId;
  final int vehicleType;
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
  final String? creatorId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "parkingId": parkingId,
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
    "creatorId": creatorId,
  };
}

class UParkingSubscriptionResponse {
  UParkingSubscriptionResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.parkingId,
    required this.vehicleId,
    required this.price,
    required this.startDate,
    required this.expiryDate,
    required this.dailyEntryLimit,
    required this.officeHoursOnly,
    required this.remainingDays,
    this.vehicle,
    this.customerName,
    this.customerPhoneNumber,
    this.creatorId,
  });

  factory UParkingSubscriptionResponse.fromJson(String str) => UParkingSubscriptionResponse.fromMap(json.decode(str));

  factory UParkingSubscriptionResponse.fromMap(Map<String, dynamic> json) => UParkingSubscriptionResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    parkingId: json["parkingId"],
    vehicleId: json["vehicleId"],
    price: (json["price"] as num).toDouble(),
    startDate: DateTime.parse(json["startDate"]),
    expiryDate: DateTime.parse(json["expiryDate"]),
    dailyEntryLimit: json["dailyEntryLimit"] ?? 0,
    officeHoursOnly: json["officeHoursOnly"] ?? false,
    remainingDays: json["remainingDays"] ?? 0,
    vehicle: json["vehicle"] == null ? null : UVehicleResponse.fromMap(json["vehicle"]),
    customerName: json["customerName"],
    customerPhoneNumber: json["customerPhoneNumber"],
    creatorId: json["creatorId"],
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String parkingId;
  final String vehicleId;
  final double price;
  final DateTime startDate;
  final DateTime expiryDate;
  final int dailyEntryLimit;
  final bool officeHoursOnly;
  final int remainingDays;
  final UVehicleResponse? vehicle;
  final String? customerName;
  final String? customerPhoneNumber;
  final String? creatorId;

  bool get isExpired => remainingDays < 0;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "parkingId": parkingId,
    "vehicleId": vehicleId,
    "price": price,
    "startDate": startDate.toIso8601String(),
    "expiryDate": expiryDate.toIso8601String(),
    "dailyEntryLimit": dailyEntryLimit,
    "officeHoursOnly": officeHoursOnly,
    "remainingDays": remainingDays,
    "vehicle": vehicle?.toMap(),
    "customerName": customerName,
    "customerPhoneNumber": customerPhoneNumber,
    "creatorId": creatorId,
  };
}

class UParkingPlateFlagResponse {
  UParkingPlateFlagResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.parkingId,
    required this.licencePlate,
    this.reason,
    this.amount,
    this.fromDate,
    this.toDate,
    this.spotNumber,
    this.creatorId,
    this.creator,
  });

  factory UParkingPlateFlagResponse.fromJson(String str) => UParkingPlateFlagResponse.fromMap(json.decode(str));

  factory UParkingPlateFlagResponse.fromMap(Map<String, dynamic> json) => UParkingPlateFlagResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    parkingId: json["parkingId"],
    licencePlate: json["licencePlate"],
    reason: json["reason"],
    amount: (json["amount"] as num?)?.toDouble(),
    fromDate: json["fromDate"] == null ? null : DateTime.parse(json["fromDate"]),
    toDate: json["toDate"] == null ? null : DateTime.parse(json["toDate"]),
    spotNumber: json["spotNumber"],
    creatorId: json["creatorId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String parkingId;
  final String licencePlate;
  final String? reason;
  final double? amount;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? spotNumber;
  final String? creatorId;
  final UUserResponse? creator;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "parkingId": parkingId,
    "licencePlate": licencePlate,
    "reason": reason,
    "amount": amount,
    "fromDate": fromDate?.toIso8601String(),
    "toDate": toDate?.toIso8601String(),
    "spotNumber": spotNumber,
    "creatorId": creatorId,
    "creator": creator?.toMap(),
  };
}

class UParkingStaffResponse {
  UParkingStaffResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.parkingId,
    required this.userId,
    required this.maxDiscountPercent,
    this.user,
    this.shiftTitle,
    this.creatorId,
  });

  factory UParkingStaffResponse.fromJson(String str) => UParkingStaffResponse.fromMap(json.decode(str));

  factory UParkingStaffResponse.fromMap(Map<String, dynamic> json) => UParkingStaffResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    parkingId: json["parkingId"],
    userId: json["userId"],
    maxDiscountPercent: json["maxDiscountPercent"] ?? 0,
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    shiftTitle: json["shiftTitle"],
    creatorId: json["creatorId"],
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String parkingId;
  final String userId;
  final int maxDiscountPercent;
  final UUserResponse? user;
  final String? shiftTitle;
  final String? creatorId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "parkingId": parkingId,
    "userId": userId,
    "maxDiscountPercent": maxDiscountPercent,
    "user": user?.toMap(),
    "shiftTitle": shiftTitle,
    "creatorId": creatorId,
  };
}

class UParkingShiftResponse {
  UParkingShiftResponse({
    required this.id,
    required this.createdAt,
    required this.tags,
    required this.parkingId,
    required this.startDate,
    required this.cashTotal,
    required this.cardTotal,
    required this.ipgTotal,
    required this.countedCash,
    required this.entryCount,
    required this.exitCount,
    this.endDate,
    this.creatorId,
    this.creator,
  });

  factory UParkingShiftResponse.fromJson(String str) => UParkingShiftResponse.fromMap(json.decode(str));

  factory UParkingShiftResponse.fromMap(Map<String, dynamic> json) => UParkingShiftResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    parkingId: json["parkingId"],
    startDate: DateTime.parse(json["startDate"]),
    cashTotal: (json["cashTotal"] as num).toDouble(),
    cardTotal: (json["cardTotal"] as num).toDouble(),
    ipgTotal: (json["ipgTotal"] as num).toDouble(),
    countedCash: (json["countedCash"] as num).toDouble(),
    entryCount: json["entryCount"] ?? 0,
    exitCount: json["exitCount"] ?? 0,
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    creatorId: json["creatorId"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
  );

  final String id;
  final DateTime createdAt;
  final List<int> tags;
  final String parkingId;
  final DateTime startDate;
  final double cashTotal;
  final double cardTotal;
  final double ipgTotal;
  final double countedCash;
  final int entryCount;
  final int exitCount;
  final DateTime? endDate;
  final String? creatorId;
  final UUserResponse? creator;

  double get total => cashTotal + cardTotal + ipgTotal;

  double get cashDifference => countedCash - cashTotal;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "parkingId": parkingId,
    "startDate": startDate.toIso8601String(),
    "cashTotal": cashTotal,
    "cardTotal": cardTotal,
    "ipgTotal": ipgTotal,
    "countedCash": countedCash,
    "entryCount": entryCount,
    "exitCount": exitCount,
    "endDate": endDate?.toIso8601String(),
    "creatorId": creatorId,
    "creator": creator?.toMap(),
  };
}

class UParkingPlateStatusResponse {
  UParkingPlateStatusResponse({
    required this.licencePlate,
    required this.flags,
    required this.hasActiveSubscription,
    required this.isBanned,
    required this.isInside,
    this.vehicle,
    this.subscription,
    this.reservation,
    this.openReport,
    this.tariff,
  });

  factory UParkingPlateStatusResponse.fromJson(String str) => UParkingPlateStatusResponse.fromMap(json.decode(str));

  factory UParkingPlateStatusResponse.fromMap(Map<String, dynamic> json) => UParkingPlateStatusResponse(
    licencePlate: json["licencePlate"],
    flags: json["flags"] == null ? <UParkingPlateFlagResponse>[] : List<UParkingPlateFlagResponse>.from((json["flags"] as List<dynamic>).map((dynamic x) => UParkingPlateFlagResponse.fromMap(x))),
    hasActiveSubscription: json["hasActiveSubscription"] ?? false,
    isBanned: json["isBanned"] ?? false,
    isInside: json["isInside"] ?? false,
    vehicle: json["vehicle"] == null ? null : UVehicleResponse.fromMap(json["vehicle"]),
    subscription: json["subscription"] == null ? null : UParkingSubscriptionResponse.fromMap(json["subscription"]),
    reservation: json["reservation"] == null ? null : UParkingPlateFlagResponse.fromMap(json["reservation"]),
    openReport: json["openReport"] == null ? null : UParkingReportResponse.fromMap(json["openReport"]),
    tariff: json["tariff"] == null ? null : UParkingTariffResponse.fromMap(json["tariff"]),
  );

  final String licencePlate;
  final List<UParkingPlateFlagResponse> flags;
  final bool hasActiveSubscription;
  final bool isBanned;
  final bool isInside;
  final UVehicleResponse? vehicle;
  final UParkingSubscriptionResponse? subscription;
  final UParkingPlateFlagResponse? reservation;
  final UParkingReportResponse? openReport;
  final UParkingTariffResponse? tariff;

  bool get hasAnyWarning => hasActiveSubscription || reservation != null || flags.isNotEmpty;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "licencePlate": licencePlate,
    "flags": List<dynamic>.from(flags.map((UParkingPlateFlagResponse x) => x.toMap())),
    "hasActiveSubscription": hasActiveSubscription,
    "isBanned": isBanned,
    "isInside": isInside,
    "vehicle": vehicle?.toMap(),
    "subscription": subscription?.toMap(),
    "reservation": reservation?.toMap(),
    "openReport": openReport?.toMap(),
    "tariff": tariff?.toMap(),
  };
}

class UParkingBillLineResponse {
  UParkingBillLineResponse({required this.key, required this.amount, required this.isFree, this.minutes});

  factory UParkingBillLineResponse.fromJson(String str) => UParkingBillLineResponse.fromMap(json.decode(str));

  factory UParkingBillLineResponse.fromMap(Map<String, dynamic> json) => UParkingBillLineResponse(
    key: json["key"],
    amount: (json["amount"] as num).toDouble(),
    isFree: json["isFree"] ?? false,
    minutes: json["minutes"],
  );

  final String key;
  final double amount;
  final bool isFree;
  final int? minutes;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{"key": key, "amount": amount, "isFree": isFree, "minutes": minutes};
}

class UParkingBillResponse {
  UParkingBillResponse({
    required this.licencePlate,
    required this.vehicleType,
    required this.startDate,
    required this.endDate,
    required this.totalMinutes,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.payable,
    required this.dailyCap,
    required this.isCapped,
    required this.isSubscription,
    required this.isNightRateApplied,
    this.reportId,
    this.spotNumber,
    this.receiptNumber,
  });

  factory UParkingBillResponse.fromJson(String str) => UParkingBillResponse.fromMap(json.decode(str));

  factory UParkingBillResponse.fromMap(Map<String, dynamic> json) => UParkingBillResponse(
    licencePlate: json["licencePlate"],
    vehicleType: json["vehicleType"],
    startDate: DateTime.parse(json["startDate"]),
    endDate: DateTime.parse(json["endDate"]),
    totalMinutes: json["totalMinutes"] ?? 0,
    lines: json["lines"] == null ? <UParkingBillLineResponse>[] : List<UParkingBillLineResponse>.from((json["lines"] as List<dynamic>).map((dynamic x) => UParkingBillLineResponse.fromMap(x))),
    subtotal: (json["subtotal"] as num).toDouble(),
    discount: (json["discount"] as num).toDouble(),
    payable: (json["payable"] as num).toDouble(),
    dailyCap: (json["dailyCap"] as num).toDouble(),
    isCapped: json["isCapped"] ?? false,
    isSubscription: json["isSubscription"] ?? false,
    isNightRateApplied: json["isNightRateApplied"] ?? false,
    reportId: json["reportId"],
    spotNumber: json["spotNumber"],
    receiptNumber: json["receiptNumber"],
  );

  final String licencePlate;
  final int vehicleType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalMinutes;
  final List<UParkingBillLineResponse> lines;
  final double subtotal;
  final double discount;
  final double payable;
  final double dailyCap;
  final bool isCapped;
  final bool isSubscription;
  final bool isNightRateApplied;
  final String? reportId;
  final String? spotNumber;
  final String? receiptNumber;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "licencePlate": licencePlate,
    "vehicleType": vehicleType,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
    "totalMinutes": totalMinutes,
    "lines": List<dynamic>.from(lines.map((UParkingBillLineResponse x) => x.toMap())),
    "subtotal": subtotal,
    "discount": discount,
    "payable": payable,
    "dailyCap": dailyCap,
    "isCapped": isCapped,
    "isSubscription": isSubscription,
    "isNightRateApplied": isNightRateApplied,
    "reportId": reportId,
    "spotNumber": spotNumber,
    "receiptNumber": receiptNumber,
  };
}

class UParkingDashboardResponse {
  UParkingDashboardResponse({
    required this.parkingId,
    required this.title,
    required this.capacity,
    required this.insideCount,
    required this.shiftRevenue,
    required this.recentReports,
    this.openShift,
  });

  factory UParkingDashboardResponse.fromJson(String str) => UParkingDashboardResponse.fromMap(json.decode(str));

  factory UParkingDashboardResponse.fromMap(Map<String, dynamic> json) => UParkingDashboardResponse(
    parkingId: json["parkingId"],
    title: json["title"],
    capacity: json["capacity"] ?? 0,
    insideCount: json["insideCount"] ?? 0,
    shiftRevenue: (json["shiftRevenue"] as num?)?.toDouble() ?? 0,
    recentReports: json["recentReports"] == null
        ? <UParkingReportResponse>[]
        : List<UParkingReportResponse>.from((json["recentReports"] as List<dynamic>).map((dynamic x) => UParkingReportResponse.fromMap(x))),
    openShift: json["openShift"] == null ? null : UParkingShiftResponse.fromMap(json["openShift"]),
  );

  final String parkingId;
  final String title;
  final int capacity;
  final int insideCount;
  final double shiftRevenue;
  final List<UParkingReportResponse> recentReports;
  final UParkingShiftResponse? openShift;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "title": title,
    "capacity": capacity,
    "insideCount": insideCount,
    "shiftRevenue": shiftRevenue,
    "recentReports": List<dynamic>.from(recentReports.map((UParkingReportResponse x) => x.toMap())),
    "openShift": openShift?.toMap(),
  };
}

class UParkingInsideVehicleResponse {
  UParkingInsideVehicleResponse({
    required this.reportId,
    required this.licencePlate,
    required this.vehicleType,
    required this.startDate,
    required this.stayedMinutes,
    required this.estimatedAmount,
    required this.hasSubscription,
    required this.isCapped,
    this.spotNumber,
  });

  factory UParkingInsideVehicleResponse.fromJson(String str) => UParkingInsideVehicleResponse.fromMap(json.decode(str));

  factory UParkingInsideVehicleResponse.fromMap(Map<String, dynamic> json) => UParkingInsideVehicleResponse(
    reportId: json["reportId"],
    licencePlate: json["licencePlate"],
    vehicleType: json["vehicleType"],
    startDate: DateTime.parse(json["startDate"]),
    stayedMinutes: json["stayedMinutes"] ?? 0,
    estimatedAmount: (json["estimatedAmount"] as num?)?.toDouble() ?? 0,
    hasSubscription: json["hasSubscription"] ?? false,
    isCapped: json["isCapped"] ?? false,
    spotNumber: json["spotNumber"],
  );

  final String reportId;
  final String licencePlate;
  final int vehicleType;
  final DateTime startDate;
  final int stayedMinutes;
  final double estimatedAmount;
  final bool hasSubscription;
  final bool isCapped;
  final String? spotNumber;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reportId": reportId,
    "licencePlate": licencePlate,
    "vehicleType": vehicleType,
    "startDate": startDate.toIso8601String(),
    "stayedMinutes": stayedMinutes,
    "estimatedAmount": estimatedAmount,
    "hasSubscription": hasSubscription,
    "isCapped": isCapped,
    "spotNumber": spotNumber,
  };
}
