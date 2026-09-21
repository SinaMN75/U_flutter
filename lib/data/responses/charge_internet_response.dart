part of "../data.dart";

class UChargeInternetReserveResponse {
  final int? reserve;
  final String? serverDateTime;
  final bool? status;
  final int? code;
  final String? message;
  final String? reference;
  final String? traceId;
  final int? affectiveAmount;
  final String? help;
  final String? messageSource;
  final String? pin;

  UChargeInternetReserveResponse({
    this.reserve,
    this.serverDateTime,
    this.status,
    this.code,
    this.message,
    this.reference,
    this.traceId,
    this.affectiveAmount,
    this.help,
    this.messageSource,
    this.pin,
  });

  factory UChargeInternetReserveResponse.fromJson(String str) => UChargeInternetReserveResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UChargeInternetReserveResponse.fromMap(Map<String, dynamic> json) => UChargeInternetReserveResponse(
    reserve: json["reserve"],
    serverDateTime: json["serverDateTime"],
    status: json["status"],
    code: json["code"],
    message: json["message"],
    reference: json["reference"],
    traceId: json["traceId"],
    affectiveAmount: json["affectiveAmount"],
    help: json["help"],
    messageSource: json["messageSource"],
    pin: json["pin"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reserve": reserve,
    "serverDateTime": serverDateTime,
    "status": status,
    "code": code,
    "message": message,
    "reference": reference,
    "traceId": traceId,
    "affectiveAmount": affectiveAmount,
    "help": help,
    "messageSource": messageSource,
    "pin": pin,
  };
}

class UInternetPackageResponse {
  final bool? status;
  final String? message;
  final List<UInternetPackageItem>? list;

  UInternetPackageResponse({
    this.status,
    this.message,
    this.list,
  });

  factory UInternetPackageResponse.fromJson(String str) => UInternetPackageResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UInternetPackageResponse.fromMap(Map<String, dynamic> json) => UInternetPackageResponse(
    status: json["status"],
    message: json["message"],
    list: json["list"] == null ? <UInternetPackageItem>[] : List<UInternetPackageItem>.from(json["list"]!.map((dynamic x) => UInternetPackageItem.fromMap(x))),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "status": status,
    "message": message,
    "list": list == null ? <dynamic>[] : List<dynamic>.from(list!.map((UInternetPackageItem x) => x.toMap())),
  };
}

class UInternetPackageItem {
  final String? id;
  final String? title;
  final int? amount;
  final int? simType;
  final String? duration;
  final String? offerCode;
  final int? packageDType;
  final String? capacity;

  UInternetPackageItem({
    this.id,
    this.title,
    this.amount,
    this.simType,
    this.duration,
    this.offerCode,
    this.packageDType,
    this.capacity,
  });

  factory UInternetPackageItem.fromJson(String str) => UInternetPackageItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UInternetPackageItem.fromMap(Map<String, dynamic> json) => UInternetPackageItem(
    id: json["id"],
    title: json["title"],
    amount: json["amount"],
    simType: json["simType"],
    duration: json["duration"],
    offerCode: json["offerCode"],
    packageDType: json["packageDType"],
    capacity: json["capacity"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "title": title,
    "amount": amount,
    "simType": simType,
    "duration": duration,
    "offerCode": offerCode,
    "packageDType": packageDType,
    "capacity": capacity,
  };
}

class UApproveResponse {
  final int? reserve;
  final String? serverDateTime;
  final bool? status;
  final int? code;
  final String? message;
  final int? reference;
  final String? serial;
  final String? pin;
  final String? traceId;
  final String? help;
  final String? messageSource;
  final String? extCode;

  UApproveResponse({
    this.reserve,
    this.serverDateTime,
    this.status,
    this.code,
    this.message,
    this.reference,
    this.serial,
    this.pin,
    this.traceId,
    this.help,
    this.messageSource,
    this.extCode,
  });

  factory UApproveResponse.fromJson(String str) => UApproveResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UApproveResponse.fromMap(Map<String, dynamic> json) => UApproveResponse(
    reserve: json["reserve"],
    serverDateTime: json["serverDateTime"],
    status: json["status"],
    code: json["code"],
    message: json["message"],
    reference: json["reference"],
    serial: json["serial"],
    pin: json["pin"],
    traceId: json["traceId"],
    help: json["help"],
    messageSource: json["messageSource"],
    extCode: json["extCode"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reserve": reserve,
    "serverDateTime": serverDateTime,
    "status": status,
    "code": code,
    "message": message,
    "reference": reference,
    "serial": serial,
    "pin": pin,
    "traceId": traceId,
    "help": help,
    "messageSource": messageSource,
    "extCode": extCode,
  };
}

class UGetStatusResponse {
  final int? reserve;
  final String? serverDateTime;
  final bool? status;
  final int? code;
  final String? message;
  final int? reference;
  final String? subscriber;
  final String? serial;
  final String? pin;
  final String? txnTime;
  final String? help;
  final String? messageSource;
  final String? extCode;

  UGetStatusResponse({
    this.reserve,
    this.serverDateTime,
    this.status,
    this.code,
    this.message,
    this.reference,
    this.subscriber,
    this.serial,
    this.pin,
    this.txnTime,
    this.help,
    this.messageSource,
    this.extCode,
  });

  factory UGetStatusResponse.fromJson(String str) => UGetStatusResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGetStatusResponse.fromMap(Map<String, dynamic> json) => UGetStatusResponse(
    reserve: json["reserve"],
    serverDateTime: json["serverDateTime"],
    status: json["status"],
    code: json["code"],
    message: json["message"],
    reference: json["reference"],
    subscriber: json["subscriber"],
    serial: json["serial"],
    pin: json["pin"],
    txnTime: json["txnTime"],
    help: json["help"],
    messageSource: json["messageSource"],
    extCode: json["extCode"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reserve": reserve,
    "serverDateTime": serverDateTime,
    "status": status,
    "code": code,
    "message": message,
    "reference": reference,
    "subscriber": subscriber,
    "serial": serial,
    "pin": pin,
    "txnTime": txnTime,
    "help": help,
    "messageSource": messageSource,
    "extCode": extCode,
  };
}

class UGetBalanceResponse {
  final int? reserve;
  final String? serverDateTime;
  final bool? status;
  final int? code;
  final String? message;
  final int? balance;
  final int? wallet;
  final int? credit;
  final int? limit;
  final String? help;
  final String? messageSource;
  final String? extCode;

  UGetBalanceResponse({
    this.reserve,
    this.serverDateTime,
    this.status,
    this.code,
    this.message,
    this.balance,
    this.wallet,
    this.credit,
    this.limit,
    this.help,
    this.messageSource,
    this.extCode,
  });

  factory UGetBalanceResponse.fromJson(String str) => UGetBalanceResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UGetBalanceResponse.fromMap(Map<String, dynamic> json) => UGetBalanceResponse(
    reserve: json["reserve"],
    serverDateTime: json["serverDateTime"],
    status: json["status"],
    code: json["code"],
    message: json["message"],
    balance: json["balance"],
    wallet: json["wallet"],
    credit: json["credit"],
    limit: json["limit"],
    help: json["help"],
    messageSource: json["messageSource"],
    extCode: json["extCode"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reserve": reserve,
    "serverDateTime": serverDateTime,
    "status": status,
    "code": code,
    "message": message,
    "balance": balance,
    "wallet": wallet,
    "credit": credit,
    "limit": limit,
    "help": help,
    "messageSource": messageSource,
    "extCode": extCode,
  };
}

class UEchoResponse {
  final int? reserve;
  final String? serverDateTime;
  final bool? status;
  final int? code;
  final String? message;
  final bool? mciTopup;
  final bool? mtn;
  final bool? rightel;
  final bool? shatel;
  final bool? mciInternet;

  UEchoResponse({
    this.reserve,
    this.serverDateTime,
    this.status,
    this.code,
    this.message,
    this.mciTopup,
    this.mtn,
    this.rightel,
    this.shatel,
    this.mciInternet,
  });

  factory UEchoResponse.fromJson(String str) => UEchoResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UEchoResponse.fromMap(Map<String, dynamic> json) => UEchoResponse(
    reserve: json["reserve"],
    serverDateTime: json["serverDateTime"],
    status: json["status"],
    code: json["code"],
    message: json["message"],
    mciTopup: json["mciTopup"],
    mtn: json["mtn"],
    rightel: json["rightel"],
    shatel: json["shatel"],
    mciInternet: json["mciInternet"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "reserve": reserve,
    "serverDateTime": serverDateTime,
    "status": status,
    "code": code,
    "message": message,
    "mciTopup": mciTopup,
    "mtn": mtn,
    "rightel": rightel,
    "shatel": shatel,
    "mciInternet": mciInternet,
  };
}
