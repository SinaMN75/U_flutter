part of "../data.dart";

class UBillInfoParams {
  final String billId;
  final String paymentId;

  UBillInfoParams({
    required this.billId,
    required this.paymentId,
  });

  factory UBillInfoParams.fromJson(String str) => UBillInfoParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UBillInfoParams.fromMap(Map<String, dynamic> json) => UBillInfoParams(
    billId: json["billId"],
    paymentId: json["paymentId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "billId": billId,
    "paymentId": paymentId,
  };
}

class UZipCodeToAddressDetailParams {
  UZipCodeToAddressDetailParams({
    required this.zipCode,
    this.refresh = false,
  });

  factory UZipCodeToAddressDetailParams.fromJson(String str) => UZipCodeToAddressDetailParams.fromMap(json.decode(str));

  factory UZipCodeToAddressDetailParams.fromMap(Map<String, dynamic> json) => UZipCodeToAddressDetailParams(
    zipCode: json["zipCode"],
    refresh: json["refresh"] ?? false,
  );

  final String zipCode;
  final bool refresh;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "zipCode": zipCode,
    "refresh": refresh,
  };
}

class UVehicleViolationDetailParams {
  UVehicleViolationDetailParams({
    required this.nationalCode,
    required this.phoneNumber,
    required this.licencePlate,
    this.refresh = false,
  });

  factory UVehicleViolationDetailParams.fromJson(String str) => UVehicleViolationDetailParams.fromMap(json.decode(str));

  factory UVehicleViolationDetailParams.fromMap(Map<String, dynamic> json) => UVehicleViolationDetailParams(
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
    licencePlate: json["licencePlate"],
    refresh: json["refresh"] ?? false,
  );

  final String nationalCode;
  final String phoneNumber;
  final String licencePlate;
  final bool refresh;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "nationalCode": nationalCode,
    "phoneNumber": phoneNumber,
    "licencePlate": licencePlate,
    "refresh": refresh,
  };
}

class UDrivingLicenceNegativePointParams {
  final String nationalCode;
  final String phoneNumber;
  final String drivingLicenceNumber;
  final bool refresh;

  UDrivingLicenceNegativePointParams({
    required this.nationalCode,
    required this.phoneNumber,
    required this.drivingLicenceNumber,
    this.refresh = false,
  });

  factory UDrivingLicenceNegativePointParams.fromJson(String str) => UDrivingLicenceNegativePointParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDrivingLicenceNegativePointParams.fromMap(Map<String, dynamic> json) => UDrivingLicenceNegativePointParams(
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
    drivingLicenceNumber: json["drivingLicenceNumber"],
    refresh: json["refresh"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "nationalCode": nationalCode,
    "phoneNumber": phoneNumber,
    "drivingLicenceNumber": drivingLicenceNumber,
    "refresh": refresh,
  };
}

class UDrivingLicenceDetailParams {
  final String nationalCode;
  final String phoneNumber;
  final bool refresh;

  UDrivingLicenceDetailParams({
    required this.nationalCode,
    required this.phoneNumber,
    this.refresh = false,
  });

  factory UDrivingLicenceDetailParams.fromJson(String str) => UDrivingLicenceDetailParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDrivingLicenceDetailParams.fromMap(Map<String, dynamic> json) => UDrivingLicenceDetailParams(
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
    refresh: json["refresh"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "nationalCode": nationalCode,
    "phoneNumber": phoneNumber,
    "refresh": refresh,
  };
}

class UFreewayTollsParams {
  final String licencePlate;
  final bool refresh;

  UFreewayTollsParams({
    required this.licencePlate,
    this.refresh = false,
  });

  factory UFreewayTollsParams.fromJson(String str) => UFreewayTollsParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UFreewayTollsParams.fromMap(Map<String, dynamic> json) => UFreewayTollsParams(
    licencePlate: json["licencePlate"],
    refresh: json["refresh"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "licencePlate": licencePlate,
    "refresh": refresh,
  };
}

class UIBanToBankAccountDetailParams {
  final String iBan;
  final bool refresh;

  UIBanToBankAccountDetailParams({
    required this.iBan,
    this.refresh = false,
  });

  factory UIBanToBankAccountDetailParams.fromJson(String str) => UIBanToBankAccountDetailParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UIBanToBankAccountDetailParams.fromMap(Map<String, dynamic> json) => UIBanToBankAccountDetailParams(
    iBan: json["iBan"],
    refresh: json["refresh"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "iBan": iBan,
    "refresh": refresh,
  };
}

class ULicencePlateDetailParams {
  final String nationalCode;
  final String licencePlate;
  final bool refresh;

  ULicencePlateDetailParams({
    required this.nationalCode,
    required this.licencePlate,
    this.refresh = false,
  });

  factory ULicencePlateDetailParams.fromJson(String str) => ULicencePlateDetailParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ULicencePlateDetailParams.fromMap(Map<String, dynamic> json) => ULicencePlateDetailParams(
    nationalCode: json["nationalCode"],
    licencePlate: json["licencePlate"],
    refresh: json["refresh"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "nationalCode": nationalCode,
    "licencePlate": licencePlate,
    "refresh": refresh,
  };
}

class UInquiryCacheStatusParams {
  final String nationalCode;
  final String phoneNumber;
  final String licencePlate;

  UInquiryCacheStatusParams({required this.nationalCode, required this.phoneNumber, required this.licencePlate});

  factory UInquiryCacheStatusParams.fromJson(String str) => UInquiryCacheStatusParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UInquiryCacheStatusParams.fromMap(Map<String, dynamic> json) => UInquiryCacheStatusParams(
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
    licencePlate: json["licencePlate"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "nationalCode": nationalCode,
    "phoneNumber": phoneNumber,
    "licencePlate": licencePlate,
  };
}
