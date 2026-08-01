part of "../data.dart";

// Result of Pay: the gateway url to open and our tracking number to verify against later.
class UIpgPayResponse {
  UIpgPayResponse({required this.url, required this.trackingNumber});

  factory UIpgPayResponse.fromMap(Map<String, dynamic> json) => UIpgPayResponse(
    url: json["url"] ?? "",
    trackingNumber: json["trackingNumber"] ?? "",
  );

  final String url;
  final String trackingNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "url": url,
    "trackingNumber": trackingNumber,
  };

  String toJson() => json.encode(toMap());

  factory UIpgPayResponse.fromJson(String str) => UIpgPayResponse.fromMap(json.decode(str));
}

// Result of Verify: final state of the charge plus the refreshed wallet balance.
class UIpgVerifyResponse {
  UIpgVerifyResponse({required this.paid, required this.failed, required this.balance});

  factory UIpgVerifyResponse.fromMap(Map<String, dynamic> json) => UIpgVerifyResponse(
    paid: json["paid"] ?? false,
    failed: json["failed"] ?? false,
    balance: (json["balance"] ?? 0).toString().toDouble(),
  );

  final bool paid;
  final bool failed;
  final double balance;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "paid": paid,
    "failed": failed,
    "balance": balance,
  };

  String toJson() => json.encode(toMap());

  factory UIpgVerifyResponse.fromJson(String str) => UIpgVerifyResponse.fromMap(json.decode(str));
}
