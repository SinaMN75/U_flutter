part of "../data.dart";

class UParkingCreateParams {
  final String title;
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
  final ParkingSelectorArgs? selectorArgs;
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
    selectorArgs: json["selectorArgs"] == null ? null : ParkingSelectorArgs.fromMap(json["selectorArgs"]),
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
  final ParkingReportSelectorArgs? selectorArgs;
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
    selectorArgs: json["selectorArgs"] == null ? null : ParkingReportSelectorArgs.fromMap(json["selectorArgs"]),
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
  final UserSelectorArgs? selectorArgs;

  UParkingUserReadParams({
    required this.parkingId,
    this.selectorArgs,
  });

  factory UParkingUserReadParams.fromJson(String str) => UParkingUserReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UParkingUserReadParams.fromMap(Map<String, dynamic> json) => UParkingUserReadParams(
    parkingId: json["parkingId"],
    selectorArgs: json["selectorArgs"] == null ? null : UserSelectorArgs.fromMap(json["selectorArgs"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "parkingId": parkingId,
    "selectorArgs": selectorArgs?.toMap(),
  };
}
