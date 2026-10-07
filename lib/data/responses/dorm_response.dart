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

class UDormDashboardResponse {
  UDormDashboardResponse({
    required this.generatedAt,
    this.residentsCount = 0,
    this.newResidentsCount = 0,
    this.dormsCount = 0,
    this.dormRoomsCount = 0,
    this.dormBedsCount = 0,
    this.dormBedsAvailableCount = 0,
    this.dormBedsOccupiedCount = 0,
    this.dormOccupancyRate = 0,
    this.contractsCount = 0,
    this.activeContractsCount = 0,
    this.upcomingContractsCount = 0,
    this.expiredContractsCount = 0,
    this.expiringSoonContractsCount = 0,
    this.invoicesCount = 0,
    this.paidInvoicesCount = 0,
    this.unpaidInvoicesCount = 0,
    this.overdueInvoicesCount = 0,
    this.totalDebt = 0,
    this.totalPaid = 0,
    this.totalPenalty = 0,
    this.totalOutstanding = 0,
    this.monthlyRevenue = const <UDormBedInvoiceChartResponse>[],
    this.expiringContracts = const <UExpiringContractItem>[],
    this.overdueInvoices = const <UOverdueInvoiceItem>[],
    this.recentContracts = const <URecentContractItem>[],
    this.recentResidents = const <URecentUserItem>[],
    this.dormsByCity = const <UDormCityItem>[],
  });

  factory UDormDashboardResponse.fromMap(Map<String, dynamic> json) => UDormDashboardResponse(
    generatedAt: DateTime.parse(json["generatedAt"]),
    residentsCount: json["residentsCount"] ?? 0,
    newResidentsCount: json["newResidentsCount"] ?? 0,
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
    recentResidents: ((json["recentResidents"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => URecentUserItem.fromMap(x)).toList(),
    dormsByCity: ((json["dormsByCity"] ?? <dynamic>[]) as List<dynamic>).map((dynamic x) => UDormCityItem.fromMap(x)).toList(),
  );

  final DateTime generatedAt;
  final int residentsCount;
  final int newResidentsCount;
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
  final List<URecentUserItem> recentResidents;
  final List<UDormCityItem> dormsByCity;
}

class UDormCityItem {
  UDormCityItem({required this.name, required this.count});

  factory UDormCityItem.fromMap(Map<String, dynamic> json) => UDormCityItem(name: json["name"] ?? "", count: json["count"] ?? 0);

  final String name;
  final int count;
}
