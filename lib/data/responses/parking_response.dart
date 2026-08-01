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
    "endDate": endDate?.toIso8601String(),
    "amount": amount,
    "vehicle": vehicle?.toMap(),
    "parking": parking?.toMap(),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}
