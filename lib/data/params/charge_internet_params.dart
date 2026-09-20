part of "../data.dart";

class UReserveChargeParams {
  final double amount;
  final String simType;

  UReserveChargeParams({
    required this.amount,
    required this.simType,
  });

  factory UReserveChargeParams.fromJson(String str) => UReserveChargeParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UReserveChargeParams.fromMap(Map<String, dynamic> json) => UReserveChargeParams(
    amount: (json["amount"] as num?)?.toDouble() ?? 0,
    simType: json["simType"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "amount": amount,
    "simType": simType,
  };
}

class UTopupChargeParams {
  final double amount;
  final String operatorId;
  final String chargeType;
  final String phoneNumber;

  UTopupChargeParams({
    required this.amount,
    required this.operatorId,
    required this.chargeType,
    required this.phoneNumber,
  });

  factory UTopupChargeParams.fromJson(String str) => UTopupChargeParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UTopupChargeParams.fromMap(Map<String, dynamic> json) => UTopupChargeParams(
    amount: (json["amount"] as num?)?.toDouble() ?? 0,
    operatorId: json["operatorId"],
    chargeType: json["chargeType"],
    phoneNumber: json["phoneNumber"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "amount": amount,
    "operatorId": operatorId,
    "chargeType": chargeType,
    "phoneNumber": phoneNumber,
  };
}

class UInternetListParams {
  final String operatorId;

  UInternetListParams({
    required this.operatorId,
  });

  factory UInternetListParams.fromJson(String str) => UInternetListParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UInternetListParams.fromMap(Map<String, dynamic> json) => UInternetListParams(
    operatorId: json["operatorId"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "operatorId": operatorId,
  };
}

class ApproveParams {
  final String reference;
  final String? cardNumber;
  final String? nationalCode;

  ApproveParams({
    required this.reference,
    this.cardNumber,
    this.nationalCode,
  });

  factory ApproveParams.fromJson(String str) => ApproveParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ApproveParams.fromMap(Map<String, dynamic> json) => ApproveParams(
    reference: json["reference"],
    cardNumber: json["cardNumber"],
    nationalCode: json["nationalCode"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reference": reference,
    "cardNumber": cardNumber,
    "nationalCode": nationalCode,
  };
}

class UGetStatusParams {
  final String reference;

  UGetStatusParams({
    required this.reference,
  });

  factory UGetStatusParams.fromJson(String str) => UGetStatusParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGetStatusParams.fromMap(Map<String, dynamic> json) => UGetStatusParams(
    reference: json["reference"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reference": reference,
  };
}

class MCITopOfferParams {
  final String subscriber;

  MCITopOfferParams({
    required this.subscriber,
  });

  factory MCITopOfferParams.fromJson(String str) => MCITopOfferParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MCITopOfferParams.fromMap(Map<String, dynamic> json) => MCITopOfferParams(
    subscriber: json["subscriber"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "subscriber": subscriber,
  };
}

class UInternetReserveParams {
  final String subscriber;
  final String operatorId;
  final String packageId;
  final double amount;
  final String device;

  UInternetReserveParams({
    required this.subscriber,
    required this.operatorId,
    required this.packageId,
    required this.amount,
    required this.device,
  });

  factory UInternetReserveParams.fromJson(String str) => UInternetReserveParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UInternetReserveParams.fromMap(Map<String, dynamic> json) => UInternetReserveParams(
    subscriber: json["subscriber"],
    operatorId: json["operatorId"],
    packageId: json["packageId"],
    amount: (json["amount"] as num?)?.toDouble() ?? 0,
    device: json["device"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "subscriber": subscriber,
    "operatorId": operatorId,
    "packageId": packageId,
    "amount": amount,
    "device": device,
  };
}
