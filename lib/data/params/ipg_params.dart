part of "../data.dart";

class UIpgPayParams {
  final double? amount;
  final TagTxn? tag;
  final String? invoiceId;
  final String? billId;
  final String? paymentId;
  final String? chargeMobileNumber;
  final TagSimOperator? topUpType;
  final List<UIpgMultiplexedAccountParams>? multiplexedAccounts;

  UIpgPayParams({
    this.amount,
    this.tag,
    this.invoiceId,
    this.billId,
    this.paymentId,
    this.chargeMobileNumber,
    this.topUpType,
    this.multiplexedAccounts,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    if (amount != null) "amount": amount,
    if (tag != null) "tag": tag!.number,
    if (invoiceId != null) "invoiceId": invoiceId,
    if (billId != null) "billId": billId,
    if (paymentId != null) "paymentId": paymentId,
    if (chargeMobileNumber != null) "chargeMobileNumber": chargeMobileNumber,
    if (topUpType != null) "topUpType": topUpType!.number,
    if (multiplexedAccounts != null) "multiplexedAccounts": multiplexedAccounts!.map((UIpgMultiplexedAccountParams e) => e.toMap()).toList(),
  };

  factory UIpgPayParams.fromMap(Map<String, dynamic> json) => UIpgPayParams(
    amount: json["amount"] == null ? null : (json["amount"] as num).toDouble(),
    tag: json["tag"] == null ? null : TagTxn.values.firstWhereOrNull((TagTxn e) => e.number == json["tag"]),
    invoiceId: json["invoiceId"],
    billId: json["billId"],
    paymentId: json["paymentId"],
    chargeMobileNumber: json["chargeMobileNumber"],
    topUpType: json["topUpType"] == null ? null : TagSimOperator.values.firstWhereOrNull((TagSimOperator e) => e.number == json["topUpType"]),
    multiplexedAccounts: json["multiplexedAccounts"] == null
        ? null
        : List<UIpgMultiplexedAccountParams>.from(json["multiplexedAccounts"].map((dynamic e) => UIpgMultiplexedAccountParams.fromMap(e))),
  );

  String toJson() => json.encode(toMap());

  factory UIpgPayParams.fromJson(String str) => UIpgPayParams.fromMap(json.decode(str));
}

typedef UIpgSaleParams = UIpgPayParams;

class UIpgMultiplexedAccountParams {
  final String iban;
  final double amount;
  final int? payId;

  UIpgMultiplexedAccountParams({required this.iban, required this.amount, this.payId});

  Map<String, dynamic> toMap() => <String, dynamic>{
    "iban": iban,
    "amount": amount,
    if (payId != null) "payId": payId,
  };

  factory UIpgMultiplexedAccountParams.fromMap(Map<String, dynamic> json) => UIpgMultiplexedAccountParams(
    iban: json["iban"] ?? "",
    amount: (json["amount"] ?? 0).toString().toDouble(),
    payId: json["payId"],
  );

  String toJson() => json.encode(toMap());

  factory UIpgMultiplexedAccountParams.fromJson(String str) => UIpgMultiplexedAccountParams.fromMap(json.decode(str));
}

class UIpgVerifyParams {
  final String trackingNumber;

  UIpgVerifyParams({required this.trackingNumber});

  Map<String, dynamic> toMap() => <String, dynamic>{
    "trackingNumber": trackingNumber,
  };

  factory UIpgVerifyParams.fromMap(Map<String, dynamic> json) => UIpgVerifyParams(
    trackingNumber: json["trackingNumber"],
  );

  String toJson() => json.encode(toMap());

  factory UIpgVerifyParams.fromJson(String str) => UIpgVerifyParams.fromMap(json.decode(str));
}
