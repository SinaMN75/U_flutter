part of "../data.dart";

class ChargeInternetReserveResponse {
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

  ChargeInternetReserveResponse({
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

  factory ChargeInternetReserveResponse.fromJson(String str) => ChargeInternetReserveResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ChargeInternetReserveResponse.fromMap(Map<String, dynamic> json) => ChargeInternetReserveResponse(
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

class ApproveResponse {
  final int? reserve;
  final String? serverDateTime;
  final bool? status;
  final int? code;
  final String? message;
  final int? reference;
  final String? serial; // PIN serial or operator reference
  final String? pin; // PIN code for recharge
  final String? traceId;
  final String? help;
  final String? messageSource;
  final String? extCode;

  ApproveResponse({
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

  factory ApproveResponse.fromJson(String str) => ApproveResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ApproveResponse.fromMap(Map<String, dynamic> json) => ApproveResponse(
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

class GetStatusResponse {
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

  GetStatusResponse({
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

  factory GetStatusResponse.fromJson(String str) => GetStatusResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory GetStatusResponse.fromMap(Map<String, dynamic> json) => GetStatusResponse(
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

class GetBalanceResponse {
  final int? reserve;
  final String? serverDateTime;
  final bool? status;
  final int? code;
  final String? message;
  final int? balance; // Account balance
  final int? wallet; // Consumable balance
  final int? credit; // Credit
  final int? limit; // Daily consumable limit
  final String? help;
  final String? messageSource;
  final String? extCode;

  GetBalanceResponse({
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

  factory GetBalanceResponse.fromJson(String str) => GetBalanceResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory GetBalanceResponse.fromMap(Map<String, dynamic> json) => GetBalanceResponse(
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

class EchoResponse {
  final int? reserve;
  final String? serverDateTime;
  final bool? status; // true = service is up
  final int? code;
  final String? message;
  final bool? mciTopup; // MCI Topup server status
  final bool? mtn; // Irancel server status
  final bool? rightel; // Rightel server status
  final bool? shatel; // Shatel server status
  final bool? mciInternet; // MCI Internet server status

  EchoResponse({
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

  factory EchoResponse.fromJson(String str) => EchoResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory EchoResponse.fromMap(Map<String, dynamic> json) => EchoResponse(
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
