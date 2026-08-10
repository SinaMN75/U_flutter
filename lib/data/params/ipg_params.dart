part of "../data.dart";

// Request body for starting an IPG charge; apiKey/token are attached by the service, server derives the user.
class UIpgSaleParams {
  final double amount;

  // Optional: for anything other than a plain wallet top-up (e.g. paying a dorm invoice). The server rides
  // these in additionalData; omit them and the server treats it as a normal wallet charge.
  final TagTxn? tag;
  final String? invoiceId;

  UIpgSaleParams({required this.amount, this.tag, this.invoiceId});

  Map<String, dynamic> toMap() => <String, dynamic>{
    "amount": amount,
    if (tag != null) "tag": tag!.number,
    if (invoiceId != null) "invoiceId": invoiceId,
  };

  factory UIpgSaleParams.fromMap(Map<String, dynamic> json) => UIpgSaleParams(
    amount: (json["amount"] as num).toDouble(),
    tag: json["tag"] == null ? null : TagTxn.values.firstWhereOrNull((TagTxn e) => e.number == json["tag"]),
    invoiceId: json["invoiceId"],
  );

  String toJson() => json.encode(toMap());

  factory UIpgSaleParams.fromJson(String str) => UIpgSaleParams.fromMap(json.decode(str));
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
