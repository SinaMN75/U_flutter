part of "../data.dart";

class UAddressCreateParams {
  final String? id;
  final String? detail1;
  final String? detail2;
  final String? title;
  final String? description;
  final String? province;
  final String? township;
  final String? street;
  final String? street2;
  final String? localityName;
  final String? houseNumber;
  final String? floor;
  final String? zipCode;
  final String? creatorId;
  final String? buildingName;
  final String? localityType;
  final String? sideFloor;
  final String? subLocality;
  final String? village;
  final List<int> tags;
  final List<String>? adminUserIds;

  UAddressCreateParams({
    required this.tags,
    required this.zipCode,
    this.title,
    this.description,
    this.detail1,
    this.detail2,
    this.buildingName,
    this.localityType,
    this.sideFloor,
    this.subLocality,
    this.village,
    this.id,
    this.province,
    this.township,
    this.street,
    this.street2,
    this.localityName,
    this.houseNumber,
    this.floor,
    this.creatorId,
    this.adminUserIds,
  });

  factory UAddressCreateParams.fromJson(String str) => UAddressCreateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UAddressCreateParams.fromMap(Map<String, dynamic> json) => UAddressCreateParams(
    tags: List<int>.from(json["tags"]!.map((dynamic x) => x)),
    id: json["id"],
    title: json["title"],
    description: json["description"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    province: json["province"],
    township: json["township"],
    street: json["street"],
    street2: json["street2"],
    localityName: json["localityName"],
    houseNumber: json["houseNumber"],
    floor: json["floor"],
    zipCode: json["zipCode"],
    creatorId: json["creatorId"],
    buildingName: json["buildingName"],
    localityType: json["localityType"],
    sideFloor: json["sideFloor"],
    subLocality: json["subLocality"],
    village: json["village"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "id": id,
    "title": title,
    "description": description,
    "detail1": detail1,
    "detail2": detail2,
    "province": province,
    "township": township,
    "street": street,
    "street2": street2,
    "localityName": localityName,
    "houseNumber": houseNumber,
    "floor": floor,
    "zipCode": zipCode,
    "creatorId": creatorId,
    "buildingName": buildingName,
    "localityType": localityType,
    "sideFloor": sideFloor,
    "subLocality": subLocality,
    "village": village,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UAddressUpdateParams {
  final String id;
  final String? detail1;
  final String? detail2;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? title;
  final String? province;
  final String? township;
  final String? street;
  final String? street2;
  final String? localityName;
  final String? houseNumber;
  final String? floor;
  final String? zipCode;
  final String? description;
  final String? buildingName;
  final String? localityType;
  final String? sideFloor;
  final String? subLocality;
  final String? village;
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  UAddressUpdateParams({
    required this.id,
    this.addTags,
    this.removeTags,
    this.detail1,
    this.detail2,
    this.tags,
    this.title,
    this.province,
    this.township,
    this.street,
    this.street2,
    this.localityName,
    this.houseNumber,
    this.floor,
    this.zipCode,
    this.description,
    this.buildingName,
    this.localityType,
    this.sideFloor,
    this.subLocality,
    this.village,
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UAddressUpdateParams.fromJson(String str) => UAddressUpdateParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UAddressUpdateParams.fromMap(Map<String, dynamic> json) => UAddressUpdateParams(
    id: json["id"],
    addTags: json["addTags"] == null ? <int>[] : List<int>.from(json["addTags"]!.map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? <int>[] : List<int>.from(json["removeTags"]!.map((dynamic x) => x)),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    title: json["title"],
    detail1: json["detail1"],
    detail2: json["detail2"],
    province: json["province"],
    township: json["township"],
    street: json["street"],
    street2: json["street2"],
    localityName: json["localityName"],
    houseNumber: json["houseNumber"],
    floor: json["floor"],
    zipCode: json["zipCode"],
    description: json["description"],
    buildingName: json["buildingName"],
    localityType: json["localityType"],
    sideFloor: json["sideFloor"],
    subLocality: json["subLocality"],
    village: json["village"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "addTags": addTags == null ? <dynamic>[] : List<dynamic>.from(addTags!.map((int x) => x)),
    "removeTags": removeTags == null ? <dynamic>[] : List<dynamic>.from(removeTags!.map((int x) => x)),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "title": title,
    "province": province,
    "township": township,
    "street": street,
    "street2": street2,
    "localityName": localityName,
    "houseNumber": houseNumber,
    "floor": floor,
    "zipCode": zipCode,
    "description": description,
    "buildingName": buildingName,
    "localityType": localityType,
    "sideFloor": sideFloor,
    "subLocality": subLocality,
    "village": village,
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}

class UAddressReadParams {
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final List<String>? ids;
  final String? creatorId;
  final AddressSelectorArgs? selectorArgs;
  final int? orderBy;
  final String? zipCode;

  UAddressReadParams({
    required this.selectorArgs,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.ids,
    this.creatorId,
    this.orderBy,
    this.zipCode,
  });

  factory UAddressReadParams.fromJson(String str) => UAddressReadParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UAddressReadParams.fromMap(Map<String, dynamic> json) => UAddressReadParams(
    pageSize: json["pageSize"],
    pageNumber: json["pageNumber"],
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? <int>[] : List<int>.from(json["tags"]!.map((dynamic x) => x)),
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
    selectorArgs: json["selectorArgs"] == null ? null : AddressSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    zipCode: json["zipCode"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? <dynamic>[] : List<dynamic>.from(tags!.map((int x) => x)),
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "zipCode": zipCode,
  };
}
