part of "../data.dart";

class UIpgPayResponse {
  UIpgPayResponse({required this.url, required this.additionalData});

  factory UIpgPayResponse.fromMap(Map<String, dynamic> json) => UIpgPayResponse(
    url: json["url"],
    additionalData: UIpgAdditionalData.fromMap(json["additionalData"]),
  );

  final String url;
  final UIpgAdditionalData additionalData;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "url": url,
    "additionalData": additionalData,
  };

  String toJson() => json.encode(toMap());

  factory UIpgPayResponse.fromJson(String str) => UIpgPayResponse.fromMap(json.decode(str));
}

class UIpgAdditionalData {
  final String? trackingNumber;
  final int? tag;
  final int? kind;
  final String? invoiceId;
  final String? billId;
  final String? paymentId;
  final String? chargeMobileNumber;
  final int? status;
  final String? rrn;
  final String? token;
  final bool paid;

  UIpgAdditionalData({
    this.trackingNumber,
    this.tag,
    this.kind,
    this.invoiceId,
    this.billId,
    this.paymentId,
    this.chargeMobileNumber,
    this.status,
    this.rrn,
    this.token,
    this.paid = false,
  });

  factory UIpgAdditionalData.fromJson(String str) => UIpgAdditionalData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UIpgAdditionalData.fromMap(Map<String, dynamic> json) => UIpgAdditionalData(
    trackingNumber: json["trackingNumber"],
    tag: json["tag"],
    kind: json["kind"],
    invoiceId: json["invoiceId"],
    billId: json["billId"],
    paymentId: json["paymentId"],
    chargeMobileNumber: json["chargeMobileNumber"],
    status: json["status"],
    rrn: json["rrn"],
    token: json["token"],
    paid: json["paid"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "trackingNumber": trackingNumber,
    "tag": tag,
    "kind": kind,
    "invoiceId": invoiceId,
    "billId": billId,
    "paymentId": paymentId,
    "chargeMobileNumber": chargeMobileNumber,
    "status": status,
    "rrn": rrn,
    "token": token,
    "paid": paid,
  };
}
