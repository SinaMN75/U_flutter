part of "../data.dart";

extension UInvoiceStatusX on UDormBedInvoiceResponse {
  double get netDue => debtAmount + penaltyAmount - creditorAmount - paidAmount;

  bool get isPaid {
    final bool taggedPaid = tags.contains(TagDormBedInvoice.paid.number) || tags.contains(TagDormBedInvoice.paidOnline.number) || tags.contains(TagDormBedInvoice.paidManual.number);
    return taggedPaid || netDue <= 0;
  }

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
}

class UDormBedJson {
  UDormBedJson({this.detail1, this.detail2, this.description});

  factory UDormBedJson.fromMap(Map<String, dynamic> json) => UDormBedJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    description: json["description"],
  );

  final String? detail1;
  final String? detail2;
  final String? description;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "description": description,
  };
}

class UDormBedResponse {
  final String id;
  final DateTime createdAt;
  final UDormBedJson jsonData;
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
    jsonData: UDormBedJson.fromMap(json["jsonData"] ?? <String, dynamic>{}),
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
  final UDormJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String title;
  final String cityCode;
  final String? address;
  final String? phoneNumber;
  final List<String> adminUserIds;
  final double averageScore;
  final int commentCount;
  final double? minMonthlyRent;
  final int bedCount;
  final int availableBedCount;
  final List<UDormRoomResponse>? rooms;
  final List<UDormBedResponse>? beds;
  final List<UCommentResponse>? comments;
  final List<UMediaResponse>? media;
  final String? organizationId;

  UDormResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.cityCode,
    this.address,
    this.phoneNumber,
    this.adminUserIds = const <String>[],
    this.averageScore = 0,
    this.commentCount = 0,
    this.minMonthlyRent,
    this.bedCount = 0,
    this.availableBedCount = 0,
    this.creator,
    this.creatorId,
    this.rooms,
    this.beds,
    this.comments,
    this.media,
    this.organizationId,
  });

  factory UDormResponse.fromJson(String str) => UDormResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDormResponse.fromMap(Map<String, dynamic> json) => UDormResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UDormJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    title: json["title"] as String,
    cityCode: json["cityCode"] as String,
    address: json["address"],
    phoneNumber: json["phoneNumber"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    averageScore: json["averageScore"] == null ? 0 : (json["averageScore"] as num).toDouble(),
    commentCount: json["commentCount"] == null ? 0 : (json["commentCount"] as num).toInt(),
    minMonthlyRent: json["minMonthlyRent"] == null ? null : (json["minMonthlyRent"] as num).toDouble(),
    bedCount: json["bedCount"] ?? 0,
    availableBedCount: json["availableBedCount"] ?? 0,
    rooms: json["rooms"] == null ? <UDormRoomResponse>[] : List<UDormRoomResponse>.from(json["rooms"]!.map((dynamic x) => UDormRoomResponse.fromMap(x))),
    beds: json["beds"] == null ? <UDormBedResponse>[] : List<UDormBedResponse>.from(json["beds"]!.map((dynamic x) => UDormBedResponse.fromMap(x))),
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
    "address": address,
    "phoneNumber": phoneNumber,
    "adminUserIds": List<String>.from(adminUserIds.map((String x) => x)),
    "averageScore": averageScore,
    "commentCount": commentCount,
    "minMonthlyRent": minMonthlyRent,
    "bedCount": bedCount,
    "availableBedCount": availableBedCount,
    "rooms": rooms == null ? <UDormRoomResponse>[] : List<UDormRoomResponse>.from(rooms!.map((UDormRoomResponse x) => x.toMap())),
    "beds": beds == null ? <UDormBedResponse>[] : List<UDormBedResponse>.from(beds!.map((UDormBedResponse x) => x.toMap())),
    "comments": comments == null ? <UCommentResponse>[] : List<UCommentResponse>.from(comments!.map((UCommentResponse x) => x.toMap())),
    "media": media == null ? <UMediaResponse>[] : List<UMediaResponse>.from(media!.map((UMediaResponse x) => x.toMap())),
    "organizationId": organizationId,
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

class UDormRoomResponse {
  final String id;
  final DateTime createdAt;
  final UDormRoomJson jsonData;
  final List<int> tags;
  final UUserResponse? creator;
  final String? creatorId;
  final String title;
  final int capacity;
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
    this.capacity = 0,
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
    jsonData: UDormRoomJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    title: json["title"] as String,
    capacity: json["capacity"] == null ? 0 : (json["capacity"] as num).toInt(),
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
    "capacity": capacity,
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
  final UDormBedContractJson jsonData;
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
    jsonData: UDormBedContractJson.fromMap(json["jsonData"]),
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
    totalDebt: (json["totalDebt"] as num?)?.toDouble() ?? 0,
    totalPaid: (json["totalPaid"] as num?)?.toDouble() ?? 0,
    totalPenalty: (json["totalPenalty"] as num?)?.toDouble() ?? 0,
    totalRemaining: (json["totalRemaining"] as num?)?.toDouble() ?? 0,
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

class UPlaceNearby {
  UPlaceNearby({this.title = "", this.distanceMeters, this.minutes});

  factory UPlaceNearby.fromMap(Map<String, dynamic> json) => UPlaceNearby(
    title: json["title"] ?? "",
    distanceMeters: json["distanceMeters"] == null ? null : (json["distanceMeters"] as num).toInt(),
    minutes: json["minutes"] == null ? null : (json["minutes"] as num).toInt(),
  );

  final String title;
  final int? distanceMeters;
  final int? minutes;

  Map<String, dynamic> toMap() => <String, dynamic>{"title": title, "distanceMeters": distanceMeters, "minutes": minutes};
}

class UPlaceFaq {
  UPlaceFaq({this.question = "", this.answer = ""});

  factory UPlaceFaq.fromMap(Map<String, dynamic> json) => UPlaceFaq(question: json["question"] ?? "", answer: json["answer"] ?? "");

  final String question;
  final String answer;

  Map<String, dynamic> toMap() => <String, dynamic>{"question": question, "answer": answer};
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

class UDormJson {
  UDormJson({
    this.detail1,
    this.detail2,
    this.description,
    this.policies,
    this.highlights = const <String>[],
    this.rules = const <String>[],
    this.requiredDocuments = const <String>[],
    this.nearbyUniversity,
    this.universityWalkMinutes,
    this.visitingHours,
    this.curfewTime,
    this.minimumStayMonths,
    this.howToGetThere,
    this.nearby = const <UPlaceNearby>[],
    this.faqs = const <UPlaceFaq>[],
    this.website,
    this.whatsapp,
    this.instagram,
    this.telegram,
    this.latitude,
    this.longitude,
  });

  factory UDormJson.fromJson(String str) => UDormJson.fromMap(json.decode(str));

  factory UDormJson.fromMap(Map<String, dynamic> json) => UDormJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    description: json["description"],
    policies: json["policies"],
    highlights: json["highlights"] == null ? <String>[] : List<String>.from((json["highlights"] as List<dynamic>).map((dynamic e) => e.toString())),
    rules: json["rules"] == null ? <String>[] : List<String>.from((json["rules"] as List<dynamic>).map((dynamic e) => e.toString())),
    requiredDocuments: json["requiredDocuments"] == null ? <String>[] : List<String>.from((json["requiredDocuments"] as List<dynamic>).map((dynamic e) => e.toString())),
    nearbyUniversity: json["nearbyUniversity"],
    universityWalkMinutes: json["universityWalkMinutes"] == null ? null : (json["universityWalkMinutes"] as num).toInt(),
    visitingHours: json["visitingHours"],
    curfewTime: json["curfewTime"],
    minimumStayMonths: json["minimumStayMonths"] == null ? null : (json["minimumStayMonths"] as num).toInt(),
    howToGetThere: json["howToGetThere"],
    nearby: json["nearby"] == null ? <UPlaceNearby>[] : List<UPlaceNearby>.from((json["nearby"] as List<dynamic>).map((dynamic e) => UPlaceNearby.fromMap(e))),
    faqs: json["faqs"] == null ? <UPlaceFaq>[] : List<UPlaceFaq>.from((json["faqs"] as List<dynamic>).map((dynamic e) => UPlaceFaq.fromMap(e))),
    website: json["website"],
    whatsapp: json["whatsapp"],
    instagram: json["instagram"],
    telegram: json["telegram"],
    latitude: json["latitude"] == null ? null : (json["latitude"] as num).toDouble(),
    longitude: json["longitude"] == null ? null : (json["longitude"] as num).toDouble(),
  );

  final String? detail1;
  final String? detail2;
  final String? description;
  final String? policies;
  final List<String> highlights;
  final List<String> rules;
  final List<String> requiredDocuments;
  final String? nearbyUniversity;
  final int? universityWalkMinutes;
  final String? visitingHours;
  final String? curfewTime;
  final int? minimumStayMonths;
  final String? howToGetThere;
  final List<UPlaceNearby> nearby;
  final List<UPlaceFaq> faqs;
  final String? website;
  final String? whatsapp;
  final String? instagram;
  final String? telegram;
  final double? latitude;
  final double? longitude;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
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
    "nearby": nearby.map((UPlaceNearby e) => e.toMap()).toList(),
    "faqs": faqs.map((UPlaceFaq e) => e.toMap()).toList(),
    "website": website,
    "whatsapp": whatsapp,
    "instagram": instagram,
    "telegram": telegram,
    "latitude": latitude,
    "longitude": longitude,
  };
}

class UDormRoomJson {
  UDormRoomJson({this.detail1, this.detail2, this.description, this.floor, this.sizeSquareMeters});

  factory UDormRoomJson.fromJson(String str) => UDormRoomJson.fromMap(json.decode(str));

  factory UDormRoomJson.fromMap(Map<String, dynamic> json) => UDormRoomJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    description: json["description"],
    floor: json["floor"] == null ? null : (json["floor"] as num).toInt(),
    sizeSquareMeters: json["sizeSquareMeters"] == null ? null : (json["sizeSquareMeters"] as num).toDouble(),
  );

  final String? detail1;
  final String? detail2;
  final String? description;
  final int? floor;
  final double? sizeSquareMeters;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "description": description,
    "floor": floor,
    "sizeSquareMeters": sizeSquareMeters,
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

class UOrganizationMember {
  UOrganizationMember({required this.userId, this.permissions = const <int>[]});

  factory UOrganizationMember.fromMap(Map<String, dynamic> json) => UOrganizationMember(
    userId: json["userId"] as String,
    permissions: json["permissions"] == null ? <int>[] : List<int>.from(json["permissions"]!.map((dynamic x) => x)),
  );

  final String userId;
  final List<int> permissions;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "permissions": permissions,
  };
}

class UOrganizationJson {
  UOrganizationJson({this.detail1, this.detail2, this.commissionPercent = 0, this.members = const <UOrganizationMember>[], this.settlements = const <UOrganizationSettlement>[]});

  factory UOrganizationJson.fromMap(Map<String, dynamic> json) => UOrganizationJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    commissionPercent: json["commissionPercent"] == null ? 0 : (json["commissionPercent"] as num).toDouble(),
    members: json["members"] == null ? <UOrganizationMember>[] : List<UOrganizationMember>.from(json["members"]!.map((dynamic x) => UOrganizationMember.fromMap(x))),
    settlements: json["settlements"] == null ? <UOrganizationSettlement>[] : List<UOrganizationSettlement>.from(json["settlements"]!.map((dynamic x) => UOrganizationSettlement.fromMap(x))),
  );

  final String? detail1;
  final String? detail2;
  final double commissionPercent;
  final List<UOrganizationMember> members;
  final List<UOrganizationSettlement> settlements;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "commissionPercent": commissionPercent,
    "members": members.map((UOrganizationMember x) => x.toMap()).toList(),
    "settlements": settlements.map((UOrganizationSettlement x) => x.toMap()).toList(),
  };
}

class UOrganizationResponse {
  UOrganizationResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.title,
    required this.ownerId,
    this.creatorId,
    this.adminUserIds = const <String>[],
    this.balance = 0,
  });

  factory UOrganizationResponse.fromMap(Map<String, dynamic> json) => UOrganizationResponse(
    id: json["id"] as String,
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UOrganizationJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"] as String,
    ownerId: json["ownerId"] as String,
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    balance: json["balance"] == null ? 0 : (json["balance"] as num).toDouble(),
  );

  final String id;
  final DateTime createdAt;
  final UOrganizationJson jsonData;
  final List<int> tags;
  final String title;
  final String ownerId;
  final String? creatorId;
  final List<String> adminUserIds;
  final double balance;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": tags,
    "title": title,
    "ownerId": ownerId,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds,
    "balance": balance,
  };
}

class UPropertyDashboardResponse {
  final DateTime generatedAt;

  final int usersCount;
  final int newUsersCount;

  final int hotelsCount;
  final int hotelRoomsCount;
  final int hotelRoomsAvailableCount;
  final int hotelRoomsOccupiedCount;
  final double hotelOccupancyRate;

  final int dormsCount;
  final int dormRoomsCount;
  final int dormBedsCount;
  final int dormBedsAvailableCount;
  final int dormBedsOccupiedCount;
  final double dormOccupancyRate;

  final int contractsCount;
  final int activeContractsCount;
  final int upcomingContractsCount;
  final int expiredContractsCount;
  final int expiringSoonContractsCount;

  final int invoicesCount;
  final int paidInvoicesCount;
  final int unpaidInvoicesCount;
  final int overdueInvoicesCount;

  final double totalDebt;
  final double totalPaid;
  final double totalPenalty;
  final double totalOutstanding;

  final List<UDormBedInvoiceChartResponse> monthlyRevenue;
  final List<UExpiringContractItem> expiringContracts;
  final List<UOverdueInvoiceItem> overdueInvoices;
  final List<URecentContractItem> recentContracts;
  final List<URecentUserItem> recentUsers;
  final List<UPropertyBreakdownItem> hotelsByCity;
  final List<UPropertyBreakdownItem> dormsByCity;

  UPropertyDashboardResponse({
    required this.generatedAt,
    required this.usersCount,
    required this.newUsersCount,
    required this.hotelsCount,
    required this.hotelRoomsCount,
    required this.hotelRoomsAvailableCount,
    required this.hotelRoomsOccupiedCount,
    required this.hotelOccupancyRate,
    required this.dormsCount,
    required this.dormRoomsCount,
    required this.dormBedsCount,
    required this.dormBedsAvailableCount,
    required this.dormBedsOccupiedCount,
    required this.dormOccupancyRate,
    required this.contractsCount,
    required this.activeContractsCount,
    required this.upcomingContractsCount,
    required this.expiredContractsCount,
    required this.expiringSoonContractsCount,
    required this.invoicesCount,
    required this.paidInvoicesCount,
    required this.unpaidInvoicesCount,
    required this.overdueInvoicesCount,
    required this.totalDebt,
    required this.totalPaid,
    required this.totalPenalty,
    required this.totalOutstanding,
    required this.monthlyRevenue,
    required this.expiringContracts,
    required this.overdueInvoices,
    required this.recentContracts,
    required this.recentUsers,
    required this.hotelsByCity,
    required this.dormsByCity,
  });

  factory UPropertyDashboardResponse.fromMap(Map<String, dynamic> json) => UPropertyDashboardResponse(
    generatedAt: DateTime.parse(json["generatedAt"]),
    usersCount: json["usersCount"] ?? 0,
    newUsersCount: json["newUsersCount"] ?? 0,
    hotelsCount: json["hotelsCount"] ?? 0,
    hotelRoomsCount: json["hotelRoomsCount"] ?? 0,
    hotelRoomsAvailableCount: json["hotelRoomsAvailableCount"] ?? 0,
    hotelRoomsOccupiedCount: json["hotelRoomsOccupiedCount"] ?? 0,
    hotelOccupancyRate: (json["hotelOccupancyRate"] ?? 0).toString().toDouble(),
    dormsCount: json["dormsCount"] ?? 0,
    dormRoomsCount: json["dormRoomsCount"] ?? 0,
    dormBedsCount: json["dormBedsCount"] ?? 0,
    dormBedsAvailableCount: json["dormBedsAvailableCount"] ?? 0,
    dormBedsOccupiedCount: json["dormBedsOccupiedCount"] ?? 0,
    dormOccupancyRate: (json["dormOccupancyRate"] ?? 0).toString().toDouble(),
    contractsCount: json["contractsCount"] ?? 0,
    activeContractsCount: json["activeContractsCount"] ?? 0,
    upcomingContractsCount: json["upcomingContractsCount"] ?? 0,
    expiredContractsCount: json["expiredContractsCount"] ?? 0,
    expiringSoonContractsCount: json["expiringSoonContractsCount"] ?? 0,
    invoicesCount: json["invoicesCount"] ?? 0,
    paidInvoicesCount: json["paidInvoicesCount"] ?? 0,
    unpaidInvoicesCount: json["unpaidInvoicesCount"] ?? 0,
    overdueInvoicesCount: json["overdueInvoicesCount"] ?? 0,
    totalDebt: (json["totalDebt"] ?? 0).toString().toDouble(),
    totalPaid: (json["totalPaid"] ?? 0).toString().toDouble(),
    totalPenalty: (json["totalPenalty"] ?? 0).toString().toDouble(),
    totalOutstanding: (json["totalOutstanding"] ?? 0).toString().toDouble(),
    monthlyRevenue: ((json["monthlyRevenue"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UDormBedInvoiceChartResponse.fromMap(x)).toList(),
    expiringContracts: ((json["expiringContracts"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UExpiringContractItem.fromMap(x)).toList(),
    overdueInvoices: ((json["overdueInvoices"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UOverdueInvoiceItem.fromMap(x)).toList(),
    recentContracts: ((json["recentContracts"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => URecentContractItem.fromMap(x)).toList(),
    recentUsers: ((json["recentUsers"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => URecentUserItem.fromMap(x)).toList(),
    hotelsByCity: ((json["hotelsByCity"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UPropertyBreakdownItem.fromMap(x)).toList(),
    dormsByCity: ((json["dormsByCity"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UPropertyBreakdownItem.fromMap(x)).toList(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "generatedAt": generatedAt.toIso8601String(),
    "usersCount": usersCount,
    "newUsersCount": newUsersCount,
    "hotelsCount": hotelsCount,
    "hotelRoomsCount": hotelRoomsCount,
    "hotelRoomsAvailableCount": hotelRoomsAvailableCount,
    "hotelRoomsOccupiedCount": hotelRoomsOccupiedCount,
    "hotelOccupancyRate": hotelOccupancyRate,
    "dormsCount": dormsCount,
    "dormRoomsCount": dormRoomsCount,
    "dormBedsCount": dormBedsCount,
    "dormBedsAvailableCount": dormBedsAvailableCount,
    "dormBedsOccupiedCount": dormBedsOccupiedCount,
    "dormOccupancyRate": dormOccupancyRate,
    "contractsCount": contractsCount,
    "activeContractsCount": activeContractsCount,
    "upcomingContractsCount": upcomingContractsCount,
    "expiredContractsCount": expiredContractsCount,
    "expiringSoonContractsCount": expiringSoonContractsCount,
    "invoicesCount": invoicesCount,
    "paidInvoicesCount": paidInvoicesCount,
    "unpaidInvoicesCount": unpaidInvoicesCount,
    "overdueInvoicesCount": overdueInvoicesCount,
    "totalDebt": totalDebt,
    "totalPaid": totalPaid,
    "totalPenalty": totalPenalty,
    "totalOutstanding": totalOutstanding,
    "monthlyRevenue": List<dynamic>.from(monthlyRevenue.map((UDormBedInvoiceChartResponse x) => x.toMap())),
    "expiringContracts": List<dynamic>.from(expiringContracts.map((UExpiringContractItem x) => x.toMap())),
    "overdueInvoices": List<dynamic>.from(overdueInvoices.map((UOverdueInvoiceItem x) => x.toMap())),
    "recentContracts": List<dynamic>.from(recentContracts.map((URecentContractItem x) => x.toMap())),
    "recentUsers": List<dynamic>.from(recentUsers.map((URecentUserItem x) => x.toMap())),
    "hotelsByCity": List<dynamic>.from(hotelsByCity.map((UPropertyBreakdownItem x) => x.toMap())),
    "dormsByCity": List<dynamic>.from(dormsByCity.map((UPropertyBreakdownItem x) => x.toMap())),
  };

  String toJson() => json.encode(toMap());

  factory UPropertyDashboardResponse.fromJson(String str) => UPropertyDashboardResponse.fromMap(json.decode(str));
}

class UExpiringContractItem {
  final String id;
  final String? userName;
  final String bedTitle;
  final String dormTitle;
  final DateTime endDate;
  final double rent;

  UExpiringContractItem({required this.id, required this.bedTitle, required this.dormTitle, required this.endDate, required this.rent, this.userName});

  factory UExpiringContractItem.fromMap(Map<String, dynamic> json) => UExpiringContractItem(
    id: json["id"] as String,
    userName: json["userName"],
    bedTitle: json["bedTitle"] ?? "",
    dormTitle: json["dormTitle"] ?? "",
    endDate: DateTime.parse(json["endDate"]),
    rent: (json["rent"] ?? 0).toString().toDouble(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "userName": userName,
    "bedTitle": bedTitle,
    "dormTitle": dormTitle,
    "endDate": endDate.toIso8601String(),
    "rent": rent,
  };

  String toJson() => json.encode(toMap());

  factory UExpiringContractItem.fromJson(String str) => UExpiringContractItem.fromMap(json.decode(str));
}

class UOverdueInvoiceItem {
  final String id;
  final String? userName;
  final double debtAmount;
  final double paidAmount;
  final double penaltyAmount;
  final DateTime dueDate;
  final int daysOverdue;

  UOverdueInvoiceItem({
    required this.id,
    required this.debtAmount,
    required this.paidAmount,
    required this.penaltyAmount,
    required this.dueDate,
    required this.daysOverdue,
    this.userName,
  });

  factory UOverdueInvoiceItem.fromMap(Map<String, dynamic> json) => UOverdueInvoiceItem(
    id: json["id"] as String,
    userName: json["userName"],
    debtAmount: (json["debtAmount"] ?? 0).toString().toDouble(),
    paidAmount: (json["paidAmount"] ?? 0).toString().toDouble(),
    penaltyAmount: (json["penaltyAmount"] ?? 0).toString().toDouble(),
    dueDate: DateTime.parse(json["dueDate"]),
    daysOverdue: json["daysOverdue"] ?? 0,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "userName": userName,
    "debtAmount": debtAmount,
    "paidAmount": paidAmount,
    "penaltyAmount": penaltyAmount,
    "dueDate": dueDate.toIso8601String(),
    "daysOverdue": daysOverdue,
  };

  String toJson() => json.encode(toMap());

  factory UOverdueInvoiceItem.fromJson(String str) => UOverdueInvoiceItem.fromMap(json.decode(str));
}

class URecentContractItem {
  final String id;
  final String? userName;
  final String bedTitle;
  final String dormTitle;
  final DateTime startDate;
  final DateTime endDate;
  final double rent;
  final DateTime createdAt;

  URecentContractItem({
    required this.id,
    required this.bedTitle,
    required this.dormTitle,
    required this.startDate,
    required this.endDate,
    required this.rent,
    required this.createdAt,
    this.userName,
  });

  factory URecentContractItem.fromMap(Map<String, dynamic> json) => URecentContractItem(
    id: json["id"] as String,
    userName: json["userName"],
    bedTitle: json["bedTitle"] ?? "",
    dormTitle: json["dormTitle"] ?? "",
    startDate: DateTime.parse(json["startDate"]),
    endDate: DateTime.parse(json["endDate"]),
    rent: (json["rent"] ?? 0).toString().toDouble(),
    createdAt: DateTime.parse(json["createdAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "userName": userName,
    "bedTitle": bedTitle,
    "dormTitle": dormTitle,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
    "rent": rent,
    "createdAt": createdAt.toIso8601String(),
  };

  String toJson() => json.encode(toMap());

  factory URecentContractItem.fromJson(String str) => URecentContractItem.fromMap(json.decode(str));
}

class UPropertyBreakdownItem {
  final String name;
  final int count;

  UPropertyBreakdownItem({required this.name, required this.count});

  factory UPropertyBreakdownItem.fromMap(Map<String, dynamic> json) => UPropertyBreakdownItem(name: json["name"] ?? "", count: json["count"] ?? 0);

  Map<String, dynamic> toMap() => <String, dynamic>{
    "name": name,
    "count": count,
  };

  String toJson() => json.encode(toMap());

  factory UPropertyBreakdownItem.fromJson(String str) => UPropertyBreakdownItem.fromMap(json.decode(str));
}

class UOrganizationSettlement {
  UOrganizationSettlement({required this.id, required this.amount, required this.iban, required this.createdAt, this.processedAt, this.approved, this.note});

  factory UOrganizationSettlement.fromMap(Map<String, dynamic> json) => UOrganizationSettlement(
    id: json["id"] as String,
    amount: json["amount"] == null ? 0 : (json["amount"] as num).toDouble(),
    iban: json["iban"] ?? "",
    createdAt: DateTime.parse(json["createdAt"]),
    processedAt: json["processedAt"] == null ? null : DateTime.parse(json["processedAt"]),
    approved: json["approved"],
    note: json["note"],
  );

  final String id;
  final double amount;
  final String iban;
  final DateTime createdAt;
  final DateTime? processedAt;
  final bool? approved;
  final String? note;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "amount": amount,
    "iban": iban,
    "createdAt": createdAt.toIso8601String(),
    "processedAt": processedAt?.toIso8601String(),
    "approved": approved,
    "note": note,
  };
}

class UContractBedChange {
  UContractBedChange({required this.bedId, required this.from, required this.to});

  factory UContractBedChange.fromMap(Map<String, dynamic> json) => UContractBedChange(
    bedId: json["bedId"] as String,
    from: DateTime.parse(json["from"]),
    to: DateTime.parse(json["to"]),
  );

  final String bedId;
  final DateTime from;
  final DateTime to;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "bedId": bedId,
    "from": from.toIso8601String(),
    "to": to.toIso8601String(),
  };
}

class UDormBedContractJson {
  UDormBedContractJson({this.detail1, this.detail2, this.settledAt, this.deductions, this.deductionReason, this.depositRefund, this.bedHistory = const <UContractBedChange>[]});

  factory UDormBedContractJson.fromMap(Map<String, dynamic> json) => UDormBedContractJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    settledAt: json["settledAt"] == null ? null : DateTime.parse(json["settledAt"]),
    deductions: json["deductions"] == null ? null : (json["deductions"] as num).toDouble(),
    deductionReason: json["deductionReason"],
    depositRefund: json["depositRefund"] == null ? null : (json["depositRefund"] as num).toDouble(),
    bedHistory: json["bedHistory"] == null ? <UContractBedChange>[] : List<UContractBedChange>.from(json["bedHistory"]!.map((dynamic x) => UContractBedChange.fromMap(x))),
  );

  final String? detail1;
  final String? detail2;
  final DateTime? settledAt;
  final double? deductions;
  final String? deductionReason;
  final double? depositRefund;
  final List<UContractBedChange> bedHistory;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "settledAt": settledAt?.toIso8601String(),
    "deductions": deductions,
    "deductionReason": deductionReason,
    "depositRefund": depositRefund,
    "bedHistory": bedHistory.map((UContractBedChange x) => x.toMap()).toList(),
  };
}
