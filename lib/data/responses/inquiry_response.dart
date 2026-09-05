part of "../data.dart";

class UBillInfoResponse {
  final String billId;
  final String paymentId;
  final String? caseCode;
  final String? companyCode;
  final String? serviceType;
  final String? checkDigit;
  final String? companyName;
  final String? serviceName;
  final int? billAmount;
  final int? yearDigit;
  final int? periodCode;
  final int? controlDigit1;
  final int? controlDigit2;
  final int? expectedCheckDigit;
  final int? expectedControlDigit1;
  final int? expectedControlDigit2;
  final List<String> warnings;
  final bool isValid;

  UBillInfoResponse({
    required this.billId,
    required this.paymentId,
    required this.warnings,
    required this.isValid,
    this.caseCode,
    this.companyCode,
    this.serviceType,
    this.checkDigit,
    this.companyName,
    this.serviceName,
    this.billAmount,
    this.yearDigit,
    this.periodCode,
    this.controlDigit1,
    this.controlDigit2,
    this.expectedCheckDigit,
    this.expectedControlDigit1,
    this.expectedControlDigit2,
  });

  factory UBillInfoResponse.fromJson(String str) => UBillInfoResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBillInfoResponse.fromMap(Map<String, dynamic> json) => UBillInfoResponse(
    billId: json["billId"],
    paymentId: json["paymentId"],
    caseCode: json["caseCode"],
    companyCode: json["companyCode"],
    serviceType: json["serviceType"],
    checkDigit: json["checkDigit"],
    companyName: json["companyName"],
    serviceName: json["serviceName"],
    billAmount: json["billAmount"],
    yearDigit: json["yearDigit"],
    periodCode: json["periodCode"],
    controlDigit1: json["controlDigit1"],
    controlDigit2: json["controlDigit2"],
    expectedCheckDigit: json["expectedCheckDigit"],
    expectedControlDigit1: json["expectedControlDigit1"],
    expectedControlDigit2: json["expectedControlDigit2"],
    warnings: List<String>.from(json["warnings"]!.map((dynamic x) => x)),
    isValid: json["isValid"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "billId": billId,
    "paymentId": paymentId,
    "caseCode": caseCode,
    "companyCode": companyCode,
    "serviceType": serviceType,
    "checkDigit": checkDigit,
    "companyName": companyName,
    "serviceName": serviceName,
    "billAmount": billAmount,
    "yearDigit": yearDigit,
    "periodCode": periodCode,
    "controlDigit1": controlDigit1,
    "controlDigit2": controlDigit2,
    "expectedCheckDigit": expectedCheckDigit,
    "expectedControlDigit1": expectedControlDigit1,
    "expectedControlDigit2": expectedControlDigit2,
    "warnings": List<dynamic>.from(warnings.map((String x) => x)),
    "isValid": isValid,
  };
}

class UZipCodeToAddressDetailResponse {
  UZipCodeToAddressDetailResponse({
    required this.buildingName,
    required this.description,
    required this.floor,
    required this.houseNumber,
    required this.localityName,
    required this.localityType,
    required this.zipCode,
    required this.province,
    required this.sideFloor,
    required this.street,
    required this.street2,
    required this.subLocality,
    required this.townShip,
    required this.traceId,
    required this.village,
    this.isCached = false,
    this.cachedAt,
    this.cacheExpiresAt,
  });

  factory UZipCodeToAddressDetailResponse.fromJson(String str) => UZipCodeToAddressDetailResponse.fromMap(json.decode(str));

  factory UZipCodeToAddressDetailResponse.fromMap(Map<String, dynamic> json) => UZipCodeToAddressDetailResponse(
    buildingName: json["buildingName"],
    description: json["description"],
    floor: json["floor"],
    houseNumber: json["houseNumber"],
    localityName: json["localityName"],
    localityType: json["localityType"],
    zipCode: json["zipCode"],
    province: json["province"],
    sideFloor: json["sideFloor"],
    street: json["street"],
    street2: json["street2"],
    subLocality: json["subLocality"],
    townShip: json["townShip"],
    traceId: json["traceId"],
    village: json["village"],
    isCached: json["isCached"] ?? false,
    cachedAt: json["cachedAt"] == null ? null : DateTime.tryParse(json["cachedAt"]),
    cacheExpiresAt: json["cacheExpiresAt"] == null ? null : DateTime.tryParse(json["cacheExpiresAt"]),
  );
  final String? buildingName;
  final String? description;
  final String? floor;
  final String? houseNumber;
  final String? localityName;
  final String? localityType;
  final String? zipCode;
  final String? province;
  final String? sideFloor;
  final String? street;
  final String? street2;
  final String? subLocality;
  final String? townShip;
  final String? traceId;
  final String? village;
  final bool isCached;
  final DateTime? cachedAt;
  final DateTime? cacheExpiresAt;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "buildingName": buildingName,
    "description": description,
    "floor": floor,
    "houseNumber": houseNumber,
    "localityName": localityName,
    "localityType": localityType,
    "zipCode": zipCode,
    "province": province,
    "sideFloor": sideFloor,
    "street": street,
    "street2": street2,
    "subLocality": subLocality,
    "townShip": townShip,
    "traceId": traceId,
    "village": village,
    "isCached": isCached,
    "cachedAt": cachedAt?.toIso8601String(),
    "cacheExpiresAt": cacheExpiresAt?.toIso8601String(),
  };
}

class UVehicleViolationDetailResponse {
  final String? plateDictation;
  final String? plateChar;
  final String? complaintStatus;
  final String? complaint;
  final String? dateTime;
  final String? priceStatus;
  final String? traceId;
  final String? paperId;
  final String? paymentId;
  final String? warningPrice;
  final String? inquirePrice;
  final String? ejrInquireNo;
  final String? warningId;
  final String? inquirePriceDictation;
  final List<UVehicleViolationDetailItem> items;
  final bool isCached;
  final DateTime? cachedAt;
  final DateTime? cacheExpiresAt;

  UVehicleViolationDetailResponse({
    required this.items,
    this.plateDictation,
    this.plateChar,
    this.complaintStatus,
    this.complaint,
    this.dateTime,
    this.priceStatus,
    this.traceId,
    this.paperId,
    this.paymentId,
    this.warningPrice,
    this.inquirePrice,
    this.ejrInquireNo,
    this.warningId,
    this.inquirePriceDictation,
    this.isCached = false,
    this.cachedAt,
    this.cacheExpiresAt,
  });

  factory UVehicleViolationDetailResponse.fromJson(String str) => UVehicleViolationDetailResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UVehicleViolationDetailResponse.fromMap(Map<String, dynamic> json) => UVehicleViolationDetailResponse(
    plateDictation: json["plateDictation"],
    plateChar: json["plateChar"],
    complaintStatus: json["complaintStatus"],
    complaint: json["complaint"],
    dateTime: json["dateTime"],
    priceStatus: json["priceStatus"],
    traceId: json["traceId"],
    paperId: json["paperId"],
    paymentId: json["paymentId"],
    warningPrice: json["warningPrice"],
    inquirePrice: json["inquirePrice"],
    ejrInquireNo: json["ejrInquireNo"],
    warningId: json["warningId"],
    inquirePriceDictation: json["inquirePriceDictation"],
    isCached: json["isCached"] ?? false,
    cachedAt: json["cachedAt"] == null ? null : DateTime.tryParse(json["cachedAt"]),
    cacheExpiresAt: json["cacheExpiresAt"] == null ? null : DateTime.tryParse(json["cacheExpiresAt"]),
    items: json["items"] == null ? <UVehicleViolationDetailItem>[] : List<UVehicleViolationDetailItem>.from(json["items"]!.map((dynamic x) => UVehicleViolationDetailItem.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "plateDictation": plateDictation,
    "plateChar": plateChar,
    "complaintStatus": complaintStatus,
    "complaint": complaint,
    "dateTime": dateTime,
    "priceStatus": priceStatus,
    "traceId": traceId,
    "paperId": paperId,
    "paymentId": paymentId,
    "warningPrice": warningPrice,
    "inquirePrice": inquirePrice,
    "ejrInquireNo": ejrInquireNo,
    "warningId": warningId,
    "inquirePriceDictation": inquirePriceDictation,
    "isCached": isCached,
    "cachedAt": cachedAt?.toIso8601String(),
    "cacheExpiresAt": cacheExpiresAt?.toIso8601String(),
    "items": List<dynamic>.from(items.map((UVehicleViolationDetailItem x) => x.toMap())),
  };
}

class UVehicleViolationDetailItem {
  final String? serialNo;
  final String? date;
  final String? type;
  final String? address;
  final String? violationType;
  final String? finalPrice;
  final String? paperId;
  final String? paymentId;
  final String? warningId;
  final String? investigationAbility;
  final bool? hasImage;

  UVehicleViolationDetailItem({
    this.serialNo,
    this.date,
    this.type,
    this.address,
    this.violationType,
    this.finalPrice,
    this.paperId,
    this.paymentId,
    this.warningId,
    this.investigationAbility,
    this.hasImage,
  });

  factory UVehicleViolationDetailItem.fromJson(String str) => UVehicleViolationDetailItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UVehicleViolationDetailItem.fromMap(Map<String, dynamic> json) => UVehicleViolationDetailItem(
    serialNo: json["serialNo"],
    date: json["date"],
    type: json["type"],
    address: json["address"],
    violationType: json["violationType"],
    finalPrice: json["finalPrice"],
    paperId: json["paperId"],
    paymentId: json["paymentId"],
    warningId: json["warningId"],
    investigationAbility: json["investigationAbility"],
    hasImage: json["hasImage"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "serialNo": serialNo,
    "date": date,
    "type": type,
    "address": address,
    "violationType": violationType,
    "finalPrice": finalPrice,
    "paperId": paperId,
    "paymentId": paymentId,
    "warningId": warningId,
    "investigationAbility": investigationAbility,
    "hasImage": hasImage,
  };
}

class UDrivingLicenceNegativePointResponse {
  final String? point;
  final bool? allowable;
  final String? ruleId;
  final bool isCached;
  final DateTime? cachedAt;
  final DateTime? cacheExpiresAt;

  UDrivingLicenceNegativePointResponse({
    this.point,
    this.allowable,
    this.ruleId,
    this.isCached = false,
    this.cachedAt,
    this.cacheExpiresAt,
  });

  factory UDrivingLicenceNegativePointResponse.fromJson(String str) => UDrivingLicenceNegativePointResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDrivingLicenceNegativePointResponse.fromMap(Map<String, dynamic> json) => UDrivingLicenceNegativePointResponse(
    point: json["point"],
    allowable: json["allowable"],
    ruleId: json["ruleId"],
    isCached: json["isCached"] ?? false,
    cachedAt: json["cachedAt"] == null ? null : DateTime.tryParse(json["cachedAt"]),
    cacheExpiresAt: json["cacheExpiresAt"] == null ? null : DateTime.tryParse(json["cacheExpiresAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "point": point,
    "allowable": allowable,
    "ruleId": ruleId,
    "isCached": isCached,
    "cachedAt": cachedAt?.toIso8601String(),
    "cacheExpiresAt": cacheExpiresAt?.toIso8601String(),
  };
}

class UDrivingLicenceDetailResponse {
  final String? nationalCode;
  final String? firstName;
  final String? lastName;
  final String? requestDate;
  final String? title;
  final String? confirmDate;
  final String? rahvarStatus;
  final String? packetNo;
  final String? barcode;
  final String? printNnumber;
  final String? printDate;
  final String? validYears;
  final bool isCached;
  final DateTime? cachedAt;
  final DateTime? cacheExpiresAt;

  UDrivingLicenceDetailResponse({
    this.nationalCode,
    this.firstName,
    this.lastName,
    this.requestDate,
    this.title,
    this.confirmDate,
    this.rahvarStatus,
    this.packetNo,
    this.barcode,
    this.printNnumber,
    this.printDate,
    this.validYears,
    this.isCached = false,
    this.cachedAt,
    this.cacheExpiresAt,
  });

  factory UDrivingLicenceDetailResponse.fromJson(String str) => UDrivingLicenceDetailResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDrivingLicenceDetailResponse.fromMap(Map<String, dynamic> json) => UDrivingLicenceDetailResponse(
    nationalCode: json["nationalCode"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    requestDate: json["requestDate"],
    title: json["title"],
    confirmDate: json["confirmDate"],
    rahvarStatus: json["rahvarStatus"],
    packetNo: json["packetNo"],
    barcode: json["barcode"],
    printNnumber: json["printNnumber"],
    printDate: json["printDate"],
    validYears: json["validYears"],
    isCached: json["isCached"] ?? false,
    cachedAt: json["cachedAt"] == null ? null : DateTime.tryParse(json["cachedAt"]),
    cacheExpiresAt: json["cacheExpiresAt"] == null ? null : DateTime.tryParse(json["cacheExpiresAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "nationalCode": nationalCode,
    "firstName": firstName,
    "lastName": lastName,
    "requestDate": requestDate,
    "title": title,
    "confirmDate": confirmDate,
    "rahvarStatus": rahvarStatus,
    "packetNo": packetNo,
    "barcode": barcode,
    "printNnumber": printNnumber,
    "printDate": printDate,
    "validYears": validYears,
    "isCached": isCached,
    "cachedAt": cachedAt?.toIso8601String(),
    "cacheExpiresAt": cacheExpiresAt?.toIso8601String(),
  };
}

class UFreewayTollsResponse {
  final String? totalPrice;
  final List<UFreewayTollsItem>? items;
  final bool isCached;
  final DateTime? cachedAt;
  final DateTime? cacheExpiresAt;

  UFreewayTollsResponse({
    this.totalPrice,
    this.items,
    this.isCached = false,
    this.cachedAt,
    this.cacheExpiresAt,
  });

  factory UFreewayTollsResponse.fromJson(String str) => UFreewayTollsResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UFreewayTollsResponse.fromMap(Map<String, dynamic> json) => UFreewayTollsResponse(
    totalPrice: json["totalPrice"],
    items: json["items"] == null ? <UFreewayTollsItem>[] : List<UFreewayTollsItem>.from(json["items"]!.map((dynamic x) => UFreewayTollsItem.fromMap(x))),
    isCached: json["isCached"] ?? false,
    cachedAt: json["cachedAt"] == null ? null : DateTime.tryParse(json["cachedAt"]),
    cacheExpiresAt: json["cacheExpiresAt"] == null ? null : DateTime.tryParse(json["cacheExpiresAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "totalPrice": totalPrice,
    "items": items == null ? <dynamic>[] : List<dynamic>.from(items!.map((UFreewayTollsItem x) => x.toMap())),
    "isCached": isCached,
    "cachedAt": cachedAt?.toIso8601String(),
    "cacheExpiresAt": cacheExpiresAt?.toIso8601String(),
  };
}

class UFreewayTollsItem {
  final String? id;
  final String? date;
  final String? price;
  final String? gateway;
  final String? freeway;

  UFreewayTollsItem({
    this.id,
    this.date,
    this.price,
    this.gateway,
    this.freeway,
  });

  factory UFreewayTollsItem.fromJson(String str) => UFreewayTollsItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UFreewayTollsItem.fromMap(Map<String, dynamic> json) => UFreewayTollsItem(
    id: json["id"],
    date: json["date"],
    price: json["price"],
    gateway: json["gateway"],
    freeway: json["freeway"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "date": date,
    "price": price,
    "gateway": gateway,
    "freeway": freeway,
  };
}

class UIBanToBankAccountDetailResponse {
  final String? depositNumber;
  final String? iBanType;
  final String? bankCode;
  final String? bankName;
  final String? ownerName;
  final bool isCached;
  final DateTime? cachedAt;
  final DateTime? cacheExpiresAt;

  UIBanToBankAccountDetailResponse({
    this.depositNumber,
    this.iBanType,
    this.bankCode,
    this.bankName,
    this.ownerName,
    this.isCached = false,
    this.cachedAt,
    this.cacheExpiresAt,
  });

  factory UIBanToBankAccountDetailResponse.fromJson(String str) => UIBanToBankAccountDetailResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UIBanToBankAccountDetailResponse.fromMap(Map<String, dynamic> json) => UIBanToBankAccountDetailResponse(
    depositNumber: json["depositNumber"],
    iBanType: json["iBanType"],
    bankCode: json["bankCode"],
    bankName: json["bankName"],
    ownerName: json["ownerName"],
    isCached: json["isCached"] ?? false,
    cachedAt: json["cachedAt"] == null ? null : DateTime.tryParse(json["cachedAt"]),
    cacheExpiresAt: json["cacheExpiresAt"] == null ? null : DateTime.tryParse(json["cacheExpiresAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "depositNumber": depositNumber,
    "iBanType": iBanType,
    "bankCode": bankCode,
    "bankName": bankName,
    "ownerName": ownerName,
    "isCached": isCached,
    "cachedAt": cachedAt?.toIso8601String(),
    "cacheExpiresAt": cacheExpiresAt?.toIso8601String(),
  };
}

class ULicencePlateDetailResponse {
  final String? status;
  final String? tracePlate;
  final List<ULicencePlateHistoryItem>? items;
  final bool isCached;
  final DateTime? cachedAt;
  final DateTime? cacheExpiresAt;

  ULicencePlateDetailResponse({
    this.status,
    this.tracePlate,
    this.items,
    this.isCached = false,
    this.cachedAt,
    this.cacheExpiresAt,
  });

  factory ULicencePlateDetailResponse.fromJson(String str) => ULicencePlateDetailResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ULicencePlateDetailResponse.fromMap(Map<String, dynamic> json) => ULicencePlateDetailResponse(
    status: json["status"],
    tracePlate: json["tracePlate"],
    items: json["items"] == null ? <ULicencePlateHistoryItem>[] : List<ULicencePlateHistoryItem>.from(json["items"]!.map((dynamic x) => ULicencePlateHistoryItem.fromMap(x))),
    isCached: json["isCached"] ?? false,
    cachedAt: json["cachedAt"] == null ? null : DateTime.tryParse(json["cachedAt"]),
    cacheExpiresAt: json["cacheExpiresAt"] == null ? null : DateTime.tryParse(json["cacheExpiresAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "status": status,
    "tracePlate": tracePlate,
    "items": items == null ? <dynamic>[] : List<dynamic>.from(items!.map((ULicencePlateHistoryItem x) => x.toMap())),
    "isCached": isCached,
    "cachedAt": cachedAt?.toIso8601String(),
    "cacheExpiresAt": cacheExpiresAt?.toIso8601String(),
  };
}

class ULicencePlateHistoryItem {
  final String? system;
  final String? type;
  final String? installDate;
  final String? model;

  ULicencePlateHistoryItem({
    this.system,
    this.type,
    this.installDate,
    this.model,
  });

  factory ULicencePlateHistoryItem.fromJson(String str) => ULicencePlateHistoryItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ULicencePlateHistoryItem.fromMap(Map<String, dynamic> json) => ULicencePlateHistoryItem(
    system: json["system"],
    type: json["type"],
    installDate: json["installDate"],
    model: json["model"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "system": system,
    "type": type,
    "installDate": installDate,
    "model": model,
  };
}

class UInquiryCacheStatusResponse {
  final UCacheStatusItem? vehicleViolation;
  final UCacheStatusItem? drivingLicence;
  final UCacheStatusItem? licencePlate;
  final UCacheStatusItem? freewayTolls;

  UInquiryCacheStatusResponse({this.vehicleViolation, this.drivingLicence, this.licencePlate, this.freewayTolls});

  factory UInquiryCacheStatusResponse.fromJson(String str) => UInquiryCacheStatusResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UInquiryCacheStatusResponse.fromMap(Map<String, dynamic> json) => UInquiryCacheStatusResponse(
    vehicleViolation: json["vehicleViolation"] == null ? null : UCacheStatusItem.fromMap(json["vehicleViolation"]),
    drivingLicence: json["drivingLicence"] == null ? null : UCacheStatusItem.fromMap(json["drivingLicence"]),
    licencePlate: json["licencePlate"] == null ? null : UCacheStatusItem.fromMap(json["licencePlate"]),
    freewayTolls: json["freewayTolls"] == null ? null : UCacheStatusItem.fromMap(json["freewayTolls"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "vehicleViolation": vehicleViolation?.toMap(),
    "drivingLicence": drivingLicence?.toMap(),
    "licencePlate": licencePlate?.toMap(),
    "freewayTolls": freewayTolls?.toMap(),
  };
}

class UCacheStatusItem {
  final DateTime? cachedAt;
  final DateTime? cacheExpiresAt;

  UCacheStatusItem({this.cachedAt, this.cacheExpiresAt});

  factory UCacheStatusItem.fromJson(String str) => UCacheStatusItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UCacheStatusItem.fromMap(Map<String, dynamic> json) => UCacheStatusItem(
    cachedAt: json["cachedAt"] == null ? null : DateTime.tryParse(json["cachedAt"]),
    cacheExpiresAt: json["cacheExpiresAt"] == null ? null : DateTime.tryParse(json["cacheExpiresAt"]),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "cachedAt": cachedAt?.toIso8601String(),
    "cacheExpiresAt": cacheExpiresAt?.toIso8601String(),
  };
}
