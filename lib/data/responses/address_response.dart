part of "../data.dart";

class UAddressResponse {
  final String id;
  final List<int> tags;
  final UAddressResponseJsonData jsonData;
  final DateTime? createdAt;
  final String? zipCode;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  UAddressResponse({
    required this.id,
    required this.tags,
    required this.jsonData,
    required this.adminUserIds,
    this.createdAt,
    this.zipCode,
    this.creator,
    this.creatorId,
  });

  factory UAddressResponse.fromJson(String str) => UAddressResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UAddressResponse.fromMap(Map<String, dynamic> json) => UAddressResponse(
    id: json["id"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    jsonData: UAddressResponseJsonData.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    zipCode: json["zipCode"],
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt?.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "zipCode": zipCode,
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UAddressResponseJsonData {
  final String? title;
  final String? province;
  final String? township;
  final String? street;
  final String? street2;
  final String? localityName;
  final String? houseNumber;
  final String? floor;
  final String? description;
  final String? buildingName;
  final String? localityType;
  final String? sideFloor;
  final String? subLocality;
  final String? townShip;
  final String? village;
  final String? localityCode;

  UAddressResponseJsonData({
    this.title,
    this.province,
    this.township,
    this.street,
    this.street2,
    this.localityName,
    this.houseNumber,
    this.floor,
    this.description,
    this.buildingName,
    this.localityCode,
    this.localityType,
    this.sideFloor,
    this.subLocality,
    this.townShip,
    this.village,
  });

  factory UAddressResponseJsonData.fromJson(String str) => UAddressResponseJsonData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UAddressResponseJsonData.fromMap(Map<String, dynamic> json) => UAddressResponseJsonData(
    title: json["title"],
    province: json["province"],
    township: json["township"],
    street: json["street"],
    street2: json["street2"],
    localityName: json["localityName"],
    houseNumber: json["houseNumber"],
    floor: json["floor"],
    description: json["description"],
    buildingName: json["buildingName"],
    localityCode: json["localityCode"],
    localityType: json["localityType"],
    sideFloor: json["sideFloor"],
    subLocality: json["subLocality"],
    townShip: json["townShip"],
    village: json["village"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "title": title,
    "province": province,
    "township": township,
    "street": street,
    "street2": street2,
    "localityName": localityName,
    "houseNumber": houseNumber,
    "floor": floor,
    "description": description,
    "buildingName": buildingName,
    "localityCode": localityCode,
    "localityType": localityType,
    "sideFloor": sideFloor,
    "subLocality": subLocality,
    "townShip": townShip,
    "village": village,
  };
}

class UAddressJson {
  final String? detail1;
  final String? detail2;
  final String? title;
  final String? province;
  final String? township;
  final String? street;
  final String? street2;
  final String? localityName;
  final String? houseNumber;
  final String? floor;
  final String? description;
  final String? buildingName;
  final String? localityType;
  final String? sideFloor;
  final String? subLocality;
  final String? village;

  UAddressJson({
    this.detail1,
    this.detail2,
    this.title,
    this.province,
    this.township,
    this.street,
    this.street2,
    this.localityName,
    this.houseNumber,
    this.floor,
    this.description,
    this.buildingName,
    this.localityType,
    this.sideFloor,
    this.subLocality,
    this.village,
  });

  factory UAddressJson.fromJson(String str) => UAddressJson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UAddressJson.fromMap(Map<String, dynamic> json) => UAddressJson(
    detail1: json["detail1"],
    detail2: json["detail2"],
    title: json["title"],
    province: json["province"],
    township: json["township"],
    street: json["street"],
    street2: json["street2"],
    localityName: json["localityName"],
    houseNumber: json["houseNumber"],
    floor: json["floor"],
    description: json["description"],
    buildingName: json["buildingName"],
    localityType: json["localityType"],
    sideFloor: json["sideFloor"],
    subLocality: json["subLocality"],
    village: json["village"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "detail1": detail1,
    "detail2": detail2,
    "title": title,
    "province": province,
    "township": township,
    "street": street,
    "street2": street2,
    "localityName": localityName,
    "houseNumber": houseNumber,
    "floor": floor,
    "description": description,
    "buildingName": buildingName,
    "localityType": localityType,
    "sideFloor": sideFloor,
    "subLocality": subLocality,
    "village": village,
  };
}
