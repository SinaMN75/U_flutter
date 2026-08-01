part of "../data.dart";

extension TagListExtension on UUserResponse {
  bool isMale() => tags.contains(TagUser.male.number);

  bool isFemaleMale() => tags.contains(TagUser.female.number);

  bool isSuperAdmin() => tags.contains(TagUser.superAdmin.number);

  bool isFullAdmin() => isSuperAdmin() || tags.contains(TagUser.systemAdmin.number) || tags.contains(TagUser.systemUser.number);

  bool isSubAdmin() => tags.contains(TagUser.subAdmin.number);

  bool hasPermission(TagUser permission) => isFullAdmin() || tags.contains(permission.number);

  String get displayName {
    final String full = "${firstName ?? ""} ${lastName ?? ""}".trim();
    if (full.isNotEmpty) return full;
    return userName;
  }
}

class UUserResponse {
  UUserResponse({
    required this.id,
    required this.createdAt,
    required this.jsonData,
    required this.tags,
    required this.userName,
    required this.adminUserIds,
    this.landLine,
    this.phoneNumber,
    this.email,
    this.firstName,
    this.lastName,
    this.nationalCode,
    this.bio,
    this.birthdate,
    this.categories,
    this.media,
    this.addresses,
    this.merchants,
    this.wallets,
    this.txns,
    this.bankAccounts,
    this.simCards,
    this.nationalCardFront,
    this.nationalCardBack,
    this.birthCertificateFirst,
    this.birthCertificateSecond,
    this.birthCertificateThird,
    this.birthCertificateForth,
    this.birthCertificateFifth,
    this.visualAuthentication,
    this.eSignature,
    this.creator,
    this.creatorId,
  });

  factory UUserResponse.fromJson(String str) => UUserResponse.fromMap(json.decode(str));

  factory UUserResponse.fromMap(Map<String, dynamic> json) => UUserResponse(
    id: json["id"],
    createdAt: DateTime.parse(json["createdAt"]),
    jsonData: UUserJson.fromMap(json["jsonData"]),
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    userName: json["userName"],
    landLine: json["landLine"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    nationalCode: json["nationalCode"],
    bio: json["bio"],
    nationalCardFront: json["nationalCardFront"],
    nationalCardBack: json["nationalCardBack"],
    birthCertificateFirst: json["birthCertificateFirst"],
    birthCertificateSecond: json["birthCertificateSecond"],
    birthCertificateThird: json["birthCertificateThird"],
    birthCertificateForth: json["birthCertificateForth"],
    birthCertificateFifth: json["birthCertificateFifth"],
    visualAuthentication: json["visualAuthentication"],
    eSignature: json["eSignature"],
    birthdate: json["birthdate"] == null ? null : DateTime.parse(json["birthdate"]),
    categories: json["categories"] == null ? <UCategoryResponse>[] : List<UCategoryResponse>.from(json["categories"].map((dynamic x) => UCategoryResponse.fromMap(x))),
    media: json["media"] == null ? <UMediaResponse>[] : List<UMediaResponse>.from(json["media"].map((dynamic x) => UMediaResponse.fromMap(x))),
    addresses: json["addresses"] == null ? <UAddressResponse>[] : List<UAddressResponse>.from(json["addresses"].map((dynamic x) => UAddressResponse.fromMap(x))),
    merchants: json["merchants"] == null ? <UMerchantResponse>[] : List<UMerchantResponse>.from(json["merchants"].map((dynamic x) => UMerchantResponse.fromMap(x))),
    wallets: json["wallets"] == null ? <UWalletResponse>[] : List<UWalletResponse>.from(json["wallets"].map((dynamic x) => UWalletResponse.fromMap(x))),
    txns: json["txns"] == null ? <UTxnResponse>[] : List<UTxnResponse>.from(json["txns"].map((dynamic x) => UTxnResponse.fromMap(x))),
    bankAccounts: json["bankAccounts"] == null ? <UBankAccountResponse>[] : List<UBankAccountResponse>.from(json["bankAccounts"].map((dynamic x) => UBankAccountResponse.fromMap(x))),
    simCards: json["simCards"] == null ? <USimCardResponse>[] : List<USimCardResponse>.from(json["simCards"].map((dynamic x) => USimCardResponse.fromMap(x))),
    creator: json["creator"] == null ? null : UUserResponse.fromMap(json["creator"]),
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );
  final String id;
  final DateTime createdAt;
  final UUserJson jsonData;
  final List<int> tags;
  final String userName;
  final String? landLine;
  final String? phoneNumber;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? nationalCode;
  final String? bio;
  final DateTime? birthdate;
  final String? nationalCardFront;
  final String? nationalCardBack;
  final String? birthCertificateFirst;
  final String? birthCertificateSecond;
  final String? birthCertificateThird;
  final String? birthCertificateForth;
  final String? birthCertificateFifth;
  final String? visualAuthentication;
  final String? eSignature;
  final List<UCategoryResponse>? categories;
  final List<UMediaResponse>? media;
  final List<UAddressResponse>? addresses;
  final List<UMerchantResponse>? merchants;
  final List<UWalletResponse>? wallets;
  final List<UTxnResponse>? txns;
  final List<UBankAccountResponse>? bankAccounts;
  final List<USimCardResponse>? simCards;
  final UUserResponse? creator;
  final String? creatorId;
  final List<String> adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "id": id,
    "createdAt": createdAt.toIso8601String(),
    "jsonData": jsonData.toMap(),
    "tags": List<dynamic>.from(tags.map((int x) => x)),
    "userName": userName,
    "landLine": landLine,
    "phoneNumber": phoneNumber,
    "email": email,
    "firstName": firstName,
    "lastName": lastName,
    "nationalCode": nationalCode,
    "bio": bio,
    "birthdate": birthdate?.toIso8601String(),
    "nationalCardFront": nationalCardFront,
    "nationalCardBack": nationalCardBack,
    "birthCertificateFirst": birthCertificateFirst,
    "birthCertificateSecond": birthCertificateSecond,
    "birthCertificateThird": birthCertificateThird,
    "birthCertificateForth": birthCertificateForth,
    "birthCertificateFifth": birthCertificateFifth,
    "visualAuthentication": visualAuthentication,
    "eSignature": eSignature,
    "categories": categories == null ? null : List<dynamic>.from(categories!.map((UCategoryResponse x) => x.toMap())),
    "media": media == null ? null : List<dynamic>.from(media!.map((UMediaResponse x) => x.toMap())),
    "addresses": addresses == null ? null : List<dynamic>.from(addresses!.map((UAddressResponse x) => x.toMap())),
    "merchants": merchants == null ? null : List<dynamic>.from(merchants!.map((UMerchantResponse x) => x.toMap())),
    "wallets": wallets == null ? null : List<dynamic>.from(wallets!.map((UWalletResponse x) => x.toMap())),
    "txns": txns == null ? null : List<dynamic>.from(txns!.map((UTxnResponse x) => x.toMap())),
    "bankAccounts": bankAccounts == null ? null : List<dynamic>.from(bankAccounts!.map((UBankAccountResponse x) => x.toMap())),
    "simCards": simCards == null ? null : List<dynamic>.from(simCards!.map((USimCardResponse x) => x.toMap())),
    "creator": creator?.toMap(),
    "creatorId": creatorId,
    "adminUserIds": List<dynamic>.from(adminUserIds.map((String x) => x)),
  };
}

class UUserJson {
  UUserJson({
    this.fcmToken,
    this.weight,
    this.height,
    this.fatherName,

    this.nationalCardFrontRejectionReason,
    this.nationalCardBackRejectionReason,
    this.birthCertificateFirstRejectionReason,
    this.birthCertificateSecondRejectionReason,
    this.birthCertificateThirdRejectionReason,
    this.birthCertificateForthRejectionReason,
    this.birthCertificateFifthRejectionReason,
    this.visualAuthenticationRejectionReason,
    this.eSignatureRejectionReason,
    this.detail1,
    this.detail2,
  });

  factory UUserJson.fromJson(String str) => UUserJson.fromMap(json.decode(str));

  factory UUserJson.fromMap(Map<String, dynamic> json) => UUserJson(
    fcmToken: json["fcmToken"],
    weight: json["weight"]?.toDouble(),
    height: json["height"]?.toDouble(),
    fatherName: json["fatherName"],
    nationalCardFrontRejectionReason: json["nationalCardFrontRejectionReason"],
    nationalCardBackRejectionReason: json["nationalCardBackRejectionReason"],
    birthCertificateFirstRejectionReason: json["birthCertificateFirstRejectionReason"],
    birthCertificateSecondRejectionReason: json["birthCertificateSecondRejectionReason"],
    birthCertificateThirdRejectionReason: json["birthCertificateThirdRejectionReason"],
    birthCertificateForthRejectionReason: json["birthCertificateForthRejectionReason"],
    birthCertificateFifthRejectionReason: json["birthCertificateFifthRejectionReason"],
    visualAuthenticationRejectionReason: json["visualAuthenticationRejectionReason"],
    eSignatureRejectionReason: json["eSignatureRejectionReason"],
    detail1: json["detail1"],
    detail2: json["detail2"],
  );
  final String? fcmToken;
  final double? weight;
  final double? height;
  final String? fatherName;
  final String? nationalCardFrontRejectionReason;
  final String? nationalCardBackRejectionReason;
  final String? birthCertificateFirstRejectionReason;
  final String? birthCertificateSecondRejectionReason;
  final String? birthCertificateThirdRejectionReason;
  final String? birthCertificateForthRejectionReason;
  final String? birthCertificateFifthRejectionReason;
  final String? visualAuthenticationRejectionReason;
  final String? eSignatureRejectionReason;
  final String? detail1;
  final String? detail2;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "fcmToken": fcmToken,
    "weight": weight,
    "height": height,
    "fatherName": fatherName,
    "nationalCardFrontRejectionReason": nationalCardFrontRejectionReason,
    "nationalCardBackRejectionReason": nationalCardBackRejectionReason,
    "birthCertificateFirstRejectionReason": birthCertificateFirstRejectionReason,
    "birthCertificateSecondRejectionReason": birthCertificateSecondRejectionReason,
    "birthCertificateThirdRejectionReason": birthCertificateThirdRejectionReason,
    "birthCertificateForthRejectionReason": birthCertificateForthRejectionReason,
    "birthCertificateFifthRejectionReason": birthCertificateFifthRejectionReason,
    "visualAuthenticationRejectionReason": visualAuthenticationRejectionReason,
    "eSignatureRejectionReason": eSignatureRejectionReason,
    "detail1": detail1,
    "detail2": detail2,
  };
}

class URegisterResponse {
  URegisterResponse({
    required this.token,
    required this.refreshToken,
    required this.expires,
    required this.user,
  });

  factory URegisterResponse.fromJson(String str) => URegisterResponse.fromMap(json.decode(str));

  factory URegisterResponse.fromMap(Map<String, dynamic> json) => URegisterResponse(
    token: json["token"] as String,
    refreshToken: json["refreshToken"] as String,
    expires: json["expires"] as String,
    user: UUserResponse.fromMap(json["user"]),
  );
  final String token;
  final String refreshToken;
  final String expires;
  final UUserResponse user;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "token": token,
    "refreshToken": refreshToken,
    "expires": expires,
    "user": user.toMap(),
  };
}

class UUserDataDownloadResponse {
  final String link;

  UUserDataDownloadResponse({
    required this.link,
  });

  factory UUserDataDownloadResponse.fromJson(String str) => UUserDataDownloadResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UUserDataDownloadResponse.fromMap(Map<String, dynamic> json) => UUserDataDownloadResponse(
    link: json["link"] as String,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "link": link,
  };
}
