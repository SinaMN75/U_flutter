part of "../data.dart";

class ReserveChargeParams {
  final String amount;
  final String simType;

  ReserveChargeParams({
    required this.amount,
    required this.simType,
  });

  factory ReserveChargeParams.fromJson(String str) => ReserveChargeParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReserveChargeParams.fromMap(Map<String, dynamic> json) => ReserveChargeParams(
    amount: json["amount"],
    simType: json["simType"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "amount": amount,
    "simType": simType,
  };
}

class TopupChargeParams {
  final String amount;
  final String operatorId;
  final String chargeType;
  final String phoneNumber;

  TopupChargeParams({
    required this.amount,
    required this.operatorId,
    required this.chargeType,
    required this.phoneNumber,
  });

  factory TopupChargeParams.fromJson(String str) => TopupChargeParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TopupChargeParams.fromMap(Map<String, dynamic> json) => TopupChargeParams(
    amount: json["amount"],
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

class InternetListParams {
  final String operatorId;

  InternetListParams({
    required this.operatorId,
  });

  factory InternetListParams.fromJson(String str) => InternetListParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory InternetListParams.fromMap(Map<String, dynamic> json) => InternetListParams(
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

class GetStatusParams {
  final String reference;

  GetStatusParams({
    required this.reference,
  });

  factory GetStatusParams.fromJson(String str) => GetStatusParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory GetStatusParams.fromMap(Map<String, dynamic> json) => GetStatusParams(
    reference: json["reference"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reference": reference,
  };
}

class MCITopOfferParams {
  final String subscriber; // Phone number

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

class InternetReserveParams {
  final String subscriber; // Phone number
  final String operatorId;
  final String packageId; // Id from InternetList
  final String amount; // Amount from InternetList
  final String device; // e.g., "05"
  final String? bank;

  InternetReserveParams({
    required this.subscriber,
    required this.operatorId,
    required this.packageId,
    required this.amount,
    required this.device,
    this.bank,
  });

  factory InternetReserveParams.fromJson(String str) => InternetReserveParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory InternetReserveParams.fromMap(Map<String, dynamic> json) => InternetReserveParams(
    subscriber: json["subscriber"],
    operatorId: json["operatorId"],
    packageId: json["packageId"],
    amount: json["amount"],
    device: json["device"],
    bank: json["bank"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "subscriber": subscriber,
    "operatorId": operatorId,
    "packageId": packageId,
    "amount": amount,
    "device": device,
    "bank": bank,
  };
}
