part of "../data.dart";

extension UInvoiceStatusX on UDormBedInvoiceResponse {
  double get netDue => debtAmount + penaltyAmount - creditorAmount - paidAmount;

  bool get isPaid {
    final bool taggedPaid = tags.contains(TagDormBedInvoice.paid.number) || tags.contains(TagDormBedInvoice.paidOnline.number) || tags.contains(TagDormBedInvoice.paidManual.number);
    return taggedPaid || netDue <= 0;
  }

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
}

class UDormBedResponse {
  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String title;
  final double deposit;
  final double monthlyRent;
  final String roomId;
  final UDormRoomResponse? room;
  final List<UMediaResponse>? media;
  final List<UDormBedContractResponse>? contracts;
  final List<String> adminUserIds;

  UDormBedResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.deposit,
    required this.monthlyRent,
    required this.roomId,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
    this.room,
    this.media,
    this.contracts,
  });

  factory UDormBedResponse.fromJson(String str) => UDormBedResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedResponse.fromMap(Map<String, dynamic> json) => UDormBedResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    title: json["title"] as String,
    deposit: (json["deposit"] as num).toDouble(),
    monthlyRent: (json["monthlyRent"] as num).toDouble(),
    roomId: json["roomId"] as String,
    room: json["room"] == null ? null : UDormRoomResponse.fromMap(json["room"]),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"]!.map((dynamic x) => UMediaResponse.fromMap(x))),
    contracts: json["contracts"] == null ? <UDormBedContractResponse>[] : List<UDormBedContractResponse>.from(json["contracts"]!.map((dynamic x) => UDormBedContractResponse.fromMap(x))),
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
    "deposit": deposit,
    "monthlyRent": monthlyRent,
    "roomId": roomId,
    "room": room?.toMap(),
    "media": media == null ? <UMediaResponse>[] : List<UMediaResponse>.from(media!.map((UMediaResponse x) => x.toMap())),
    "contracts": contracts == null ? <UDormBedContractResponse>[] : List<UDormBedContractResponse>.from(contracts!.map((UDormBedContractResponse x) => x.toMap())),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UDormResponse {
  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String title;
  final String cityCode;
  final List<String> adminUserIds;
  final List<UDormRoomResponse>? rooms;
  final List<UDormBedResponse>? beds;
  final List<UMediaResponse>? media;

  UDormResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.cityCode,
    this.adminUserIds = const <String>[],
    this.creator,
    this.creatorId,
    this.rooms,
    this.beds,
    this.media,
  });

  factory UDormResponse.fromJson(String str) => UDormResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormResponse.fromMap(Map<String, dynamic> json) => UDormResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    title: json["title"] as String,
    cityCode: json["cityCode"] as String,
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    rooms: json["rooms"] == null ? <UDormRoomResponse>[] : List<UDormRoomResponse>.from(json["rooms"]!.map((dynamic x) => UDormRoomResponse.fromMap(x))),
    beds: json["beds"] == null ? <UDormBedResponse>[] : List<UDormBedResponse>.from(json["beds"]!.map((dynamic x) => UDormBedResponse.fromMap(x))),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"]!.map((dynamic x) => UMediaResponse.fromMap(x))),
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
    "adminUserIds": List<String>.from(adminUserIds.map((String x) => x)),
    "rooms": rooms == null ? <UDormRoomResponse>[] : List<UDormRoomResponse>.from(rooms!.map((UDormRoomResponse x) => x.toMap())),
    "beds": beds == null ? <UDormBedResponse>[] : List<UDormBedResponse>.from(beds!.map((UDormBedResponse x) => x.toMap())),
    "media": media == null ? <UMediaResponse>[] : List<UMediaResponse>.from(media!.map((UMediaResponse x) => x.toMap())),
  };
}

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
  final List<UHotelRoomResponse>? rooms;
  final List<UHotelReservationResponse>? reservations;
  final List<UMediaResponse>? media;

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
    this.creator,
    this.creatorId,
    this.rooms,
    this.reservations,
    this.media,
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
    rooms: json["rooms"] == null ? <UHotelRoomResponse>[] : List<UHotelRoomResponse>.from(json["rooms"]!.map((dynamic x) => UHotelRoomResponse.fromMap(x))),
    reservations: json["reservations"] == null ? <UHotelReservationResponse>[] : List<UHotelReservationResponse>.from(json["reservations"]!.map((dynamic x) => UHotelReservationResponse.fromMap(x))),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"]!.map((dynamic x) => UMediaResponse.fromMap(x))),
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
    "rooms": rooms == null ? <UHotelRoomResponse>[] : List<UHotelRoomResponse>.from(rooms!.map((UHotelRoomResponse x) => x.toMap())),
    "reservations": reservations == null ? <UHotelReservationResponse>[] : List<UHotelReservationResponse>.from(reservations!.map((UHotelReservationResponse x) => x.toMap())),
    "media": media == null ? <UMediaResponse>[] : List<UMediaResponse>.from(media!.map((UMediaResponse x) => x.toMap())),
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

class UDormRoomResponse {
  final String id;
  final DateTime createdAt;
  final UBaseJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String title;
  final String dormId;
  final UDormResponse? dorm;
  final List<UDormBedResponse>? beds;
  final List<UMediaResponse>? media;
  final List<String> adminUserIds;

  UDormRoomResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.dormId,
    required this.adminUserIds,
    this.creator,
    this.creatorId,
    this.dorm,
    this.beds,
    this.media,
  });

  factory UDormRoomResponse.fromJson(String str) => UDormRoomResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormRoomResponse.fromMap(Map<String, dynamic> json) => UDormRoomResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UBaseJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    title: json["title"] as String,
    dormId: json["dormId"] as String,
    dorm: json["dorm"] == null ? null : UDormResponse.fromMap(json["dorm"]),
    beds: json["beds"] == null ? <UDormBedResponse>[] : List<UDormBedResponse>.from(json["beds"]!.map((dynamic x) => UDormBedResponse.fromMap(x))),
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
    "dormId": dormId,
    "dorm": dorm?.toMap(),
    "beds": beds == null ? <UDormBedResponse>[] : List<UDormBedResponse>.from(beds!.map((UDormBedResponse x) => x.toMap())),
    "media": media == null ? <UMediaResponse>[] : List<UMediaResponse>.from(media!.map((UMediaResponse x) => x.toMap())),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UDormBedContractResponse {
  final String id;
  final DateTime createdAt;
  final UContractJsonData jsonData;
  final List<int> tags;
  final DateTime startDate;
  final DateTime endDate;
  final double deposit;
  final double rent;
  final UUserResponse? user;
  final String userId;
  final String bedId;
  final UDormBedResponse? bed;
  final UUserResponse? creator;
  final String? creatorId;
  final bool isActive;
  final List<UDormBedInvoiceResponse>? invoices;
  final List<String> adminUserIds;

  UDormBedContractResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.startDate,
    required this.endDate,
    required this.deposit,
    required this.rent,
    required this.userId,
    required this.bedId,
    required this.isActive,
    required this.adminUserIds,
    this.user,
    this.bed,
    this.creator,
    this.creatorId,
    this.invoices,
  });

  factory UDormBedContractResponse.fromJson(String str) => UDormBedContractResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedContractResponse.fromMap(Map<String, dynamic> json) => UDormBedContractResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UContractJsonData.fromMap(json["jsonData"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    startDate: DateTime.parse(json["startDate"]),
    endDate: DateTime.parse(json["endDate"]),
    deposit: (json["deposit"] as num).toDouble(),
    rent: (json["rent"] as num).toDouble(),
    user: json["user"] == null ? null : UUserResponse.fromMap(json["user"]),
    userId: json["userId"] as String,
    bedId: json["bedId"] as String,
    bed: json["bed"] == null ? null : UDormBedResponse.fromMap(json["bed"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    isActive: json["isActive"],
    invoices: json["invoices"] == null ? <UDormBedInvoiceResponse>[] : List<UDormBedInvoiceResponse>.from(json["invoices"]!.map((dynamic x) => UDormBedInvoiceResponse.fromMap(x))),
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
    "deposit": deposit,
    "rent": rent,
    "user": user?.toMap(),
    "userId": userId,
    "bedId": bedId,
    "bed": bed?.toMap(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "isActive": isActive,
    "invoices": invoices == null ? <dynamic>[] : List<dynamic>.from(invoices!.map((UDormBedInvoiceResponse x) => x.toMap())),
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UContractJsonData {
  final String? description;

  UContractJsonData({
    this.description,
  });

  factory UContractJsonData.fromJson(String str) => UContractJsonData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UContractJsonData.fromMap(Map<String, dynamic> json) => UContractJsonData(
    description: json["description"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "description": description,
  };
}

class UDormBedInvoiceResponse {
  final String id;
  final DateTime createdAt;
  final UDormBedInvoiceJson jsonData;
  final List<int> tags;
  final double debtAmount;
  final double creditorAmount;
  final double paidAmount;
  final double penaltyAmount;
  final DateTime dueDate;
  final UDormBedContractResponse? contract;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  UDormBedInvoiceResponse({
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
    this.contract,
    this.creator,
    this.creatorId,
  });

  factory UDormBedInvoiceResponse.fromJson(String str) => UDormBedInvoiceResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedInvoiceResponse.fromMap(Map<String, dynamic> json) => UDormBedInvoiceResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UDormBedInvoiceJson.fromMap(json["jsonData"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    debtAmount: (json["debtAmount"] as num).toDouble(),
    creditorAmount: (json["creditorAmount"] as num).toDouble(),
    paidAmount: (json["paidAmount"] as num).toDouble(),
    penaltyAmount: (json["penaltyAmount"] as num).toDouble(),
    dueDate: DateTime.parse(json["dueDate"]),
    contract: json["contract"] == null ? null : UDormBedContractResponse.fromMap(json["contract"]),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "debtAmount": debtAmount,
    "creditorAmount": creditorAmount,
    "paidAmount": paidAmount,
    "penaltyAmount": penaltyAmount,
    "dueDate": dueDate.toIso8601String(),
    "contract": contract?.toMap(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UDormBedInvoiceJson {
  final int? penaltyPrecentEveryDate;
  final String? detail1;
  final String? detail2;

  UDormBedInvoiceJson({
    this.penaltyPrecentEveryDate,
    this.detail1,
    this.detail2,
  });

  factory UDormBedInvoiceJson.fromJson(String str) => UDormBedInvoiceJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedInvoiceJson.fromMap(Map<String, dynamic> json) => UDormBedInvoiceJson(
    penaltyPrecentEveryDate: json["penaltyPrecentEveryDate"] == null ? null : (json["penaltyPrecentEveryDate"] as num).toInt(),
    detail1: json["detail1"],
    detail2: json["detail2"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "penaltyPrecentEveryDate": penaltyPrecentEveryDate,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class UDormBedInvoiceChartResponse {
  final String month;
  final double totalDebt;
  final double totalPaid;
  final double totalPenalty;
  final double totalRemaining;
  final int invoiceCount;

  UDormBedInvoiceChartResponse({
    required this.month,
    required this.totalDebt,
    required this.totalPaid,
    required this.totalPenalty,
    required this.totalRemaining,
    required this.invoiceCount,
  });

  factory UDormBedInvoiceChartResponse.fromJson(String str) => UDormBedInvoiceChartResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormBedInvoiceChartResponse.fromMap(Map<String, dynamic> json) => UDormBedInvoiceChartResponse(
    month: json["month"] as String,
    totalDebt: json["totalDebt"],
    totalPaid: json["totalPaid"],
    totalPenalty: json["totalPenalty"],
    totalRemaining: json["totalRemaining"],
    invoiceCount: json["invoiceCount"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "month": month,
    "totalDebt": totalDebt,
    "totalPaid": totalPaid,
    "totalPenalty": totalPenalty,
    "totalRemaining": totalRemaining,
    "invoiceCount": invoiceCount,
  };
}

class UHotelJson {
  final String? detail1;
  final String? detail2;
  final String? description;
  final String? policies;
  final String? checkInTime;
  final String? checkOutTime;
  final List<String> amenities;

  UHotelJson({
    this.detail1,
    this.detail2,
    this.description,
    this.policies,
    this.checkInTime,
    this.checkOutTime,
    this.amenities = const <String>[],
  });

  factory UHotelJson.fromJson(String str) => UHotelJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelJson.fromMap(Map<String, dynamic> json) => UHotelJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    description: json["description"],
    policies: json["policies"],
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    amenities: json["amenities"] == null ? <String>[] : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "description": description,
    "policies": policies,
    "checkInTime": checkInTime,
    "checkOutTime": checkOutTime,
    "amenities": List<String>.from(amenities.map((String x) => x)),
  };
}

class UHotelRoomJson {
  final String? detail1;
  final String? detail2;
  final String? description;
  final String? bedType;
  final double? sizeSquareMeters;
  final int? floor;
  final List<String> amenities;

  UHotelRoomJson({
    this.detail1,
    this.detail2,
    this.description,
    this.bedType,
    this.sizeSquareMeters,
    this.floor,
    this.amenities = const <String>[],
  });

  factory UHotelRoomJson.fromJson(String str) => UHotelRoomJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UHotelRoomJson.fromMap(Map<String, dynamic> json) => UHotelRoomJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    description: json["description"],
    bedType: json["bedType"],
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    amenities: json["amenities"] == null ? <String>[] : List<String>.from(json["amenities"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "description": description,
    "bedType": bedType,
    "sizeSquareMeters": sizeSquareMeters,
    "floor": floor,
    "amenities": List<String>.from(amenities.map((String x) => x)),
  };
}

class UHotelReservationJson {
  final String? detail1;
  final String? detail2;
  final String? guestName;
  final String? guestPhone;
  final String? notes;
  final int? nightCount;

  UHotelReservationJson({
    this.detail1,
    this.detail2,
    this.guestName,
    this.guestPhone,
    this.notes,
    this.nightCount,
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
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "guestName": guestName,
    "guestPhone": guestPhone,
    "notes": notes,
    "nightCount": nightCount,
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
