part of "../data.dart";

class UUserBulkCreateParams {
  UUserBulkCreateParams({
    required this.users,
  });

  factory UUserBulkCreateParams.fromJson(String str) => UUserBulkCreateParams.fromMap(json.decode(str));

  factory UUserBulkCreateParams.fromMap(Map<String, dynamic> json) => UUserBulkCreateParams(
    users: List<UUserCreateParams>.from(json["users"].map((dynamic x) => UUserCreateParams.fromMap(x))),
  );
  final List<UUserCreateParams> users;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "users": List<dynamic>.from(users.map((UUserCreateParams x) => x.toMap())),
  };
}

class UUserCreateParams {
  UUserCreateParams({
    required this.userName,
    required this.password,
    required this.tags,
    this.phoneNumber,
    this.email,
    this.landLine,
    this.firstName,
    this.lastName,
    this.nationalCode,
    this.bio,
    this.birthdate,
    this.weight,
    this.height,
    this.fatherName,
    this.fcmToken,
    this.categories,
    this.nationalCardFront,
    this.nationalCardBack,
    this.birthCertificateFirst,
    this.birthCertificateSecond,
    this.birthCertificateThird,
    this.birthCertificateForth,
    this.birthCertificateFifth,
    this.visualAuthentication,
    this.eSignature,
    this.detail1,
    this.detail2,
    this.id,
    this.creatorId,
    this.adminUserIds,
  });

  factory UUserCreateParams.fromJson(String str) => UUserCreateParams.fromMap(json.decode(str));

  factory UUserCreateParams.fromMap(Map<String, dynamic> json) => UUserCreateParams(
    userName: json["userName"],
    password: json["password"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    landLine: json["landLine"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    nationalCode: json["nationalCode"],
    bio: json["bio"],
    birthdate: json["birthdate"] == null ? null : DateTime.parse(json["birthdate"]),
    weight: json["weight"]?.toDouble(),
    height: json["height"]?.toDouble(),
    fatherName: json["fatherName"],
    fcmToken: json["fcmToken"],
    nationalCardFront: json["nationalCardFront"],
    nationalCardBack: json["nationalCardBack"],
    birthCertificateFirst: json["birthCertificateFirst"],
    birthCertificateSecond: json["birthCertificateSecond"],
    birthCertificateThird: json["birthCertificateThird"],
    birthCertificateForth: json["birthCertificateForth"],
    birthCertificateFifth: json["birthCertificateFifth"],
    visualAuthentication: json["visualAuthentication"],
    eSignature: json["eSignature"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
    categories: json["categories"] == null ? null : List<String>.from(json["categories"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    id: json["id"],
    creatorId: json["creatorId"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
  );
  final String userName;
  final String password;
  final String? phoneNumber;
  final String? email;
  final String? landLine;
  final String? firstName;
  final String? lastName;
  final String? nationalCode;
  final String? bio;
  final DateTime? birthdate;
  final double? weight;
  final double? height;
  final String? fatherName;
  final String? fcmToken;
  final String? nationalCardFront;
  final String? nationalCardBack;
  final String? birthCertificateFirst;
  final String? birthCertificateSecond;
  final String? birthCertificateThird;
  final String? birthCertificateForth;
  final String? birthCertificateFifth;
  final String? visualAuthentication;
  final String? eSignature;
  final List<int> tags;
  final List<String>? categories;
  final String? detail1;
  final String? detail2;
  final String? id;
  final String? creatorId;
  final List<String>? adminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userName": userName,
    "password": password,
    "phoneNumber": phoneNumber,
    "email": email,
    "landLine": landLine,
    "firstName": firstName,
    "lastName": lastName,
    "nationalCode": nationalCode,
    "bio": bio,
    "birthdate": birthdate?.toIso8601String(),
    "weight": weight,
    "height": height,
    "fatherName": fatherName,
    "fcmToken": fcmToken,
    "nationalCardFront": nationalCardFront,
    "nationalCardBack": nationalCardBack,
    "birthCertificateFirst": birthCertificateFirst,
    "birthCertificateSecond": birthCertificateSecond,
    "birthCertificateThird": birthCertificateThird,
    "birthCertificateForth": birthCertificateForth,
    "birthCertificateFifth": birthCertificateFifth,
    "visualAuthentication": visualAuthentication,
    "eSignature": eSignature,
    "tags": List<dynamic>.from(tags.map((dynamic x) => x)),
    "categories": categories == null ? null : List<dynamic>.from(categories!.map((dynamic x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "id": id,
    "creatorId": creatorId,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
  };
}

class UUserReadParams {
  UUserReadParams({
    this.query,
    this.userName,
    this.landLine,
    this.firstName,
    this.lastName,
    this.nationalCode,
    this.phoneNumber,
    this.email,
    this.bio,
    this.startBirthDate,
    this.endBirthDate,
    this.categories,
    this.pageSize,
    this.pageNumber,
    this.fromCreatedAt,
    this.toCreatedAt,
    this.tags,
    this.selectorArgs,
    this.orderBy,
    this.ids,
    this.creatorId,
  });

  factory UUserReadParams.fromJson(String str) => UUserReadParams.fromMap(json.decode(str));

  factory UUserReadParams.fromMap(Map<String, dynamic> json) => UUserReadParams(
    query: json["query"],
    userName: json["userName"],
    landLine: json["landLine"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    nationalCode: json["nationalCode"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    bio: json["bio"],
    startBirthDate: json["startBirthDate"] == null ? null : DateTime.parse(json["startBirthDate"]),
    endBirthDate: json["endBirthDate"] == null ? null : DateTime.parse(json["endBirthDate"]),
    categories: json["categories"] == null ? null : List<String>.from(json["categories"].map((dynamic x) => x)),
    pageSize: json["pageSize"] ?? 0,
    pageNumber: json["pageNumber"] ?? 0,
    fromCreatedAt: json["fromCreatedAt"] == null ? null : DateTime.parse(json["fromCreatedAt"]),
    toCreatedAt: json["toCreatedAt"] == null ? null : DateTime.parse(json["toCreatedAt"]),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    selectorArgs: json["selectorArgs"] == null ? null : UserSelectorArgs.fromMap(json["selectorArgs"]),
    orderBy: json["orderBy"],
    ids: json["ids"] == null ? <String>[] : List<String>.from(json["ids"]!.map((dynamic x) => x)),
    creatorId: json["creatorId"],
  );
  final String? query;
  final String? userName;
  final String? landLine;
  final String? firstName;
  final String? lastName;
  final String? nationalCode;
  final String? phoneNumber;
  final String? email;
  final String? bio;
  final DateTime? startBirthDate;
  final DateTime? endBirthDate;
  final List<String>? categories;
  final int? pageSize;
  final int? pageNumber;
  final DateTime? fromCreatedAt;
  final DateTime? toCreatedAt;
  final List<int>? tags;
  final UserSelectorArgs? selectorArgs;
  final int? orderBy;
  final List<String>? ids;
  final String? creatorId;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "query": query,
    "userName": userName,
    "landLine": landLine,
    "firstName": firstName,
    "lastName": lastName,
    "nationalCode": nationalCode,
    "phoneNumber": phoneNumber,
    "email": email,
    "bio": bio,
    "startBirthDate": startBirthDate?.toIso8601String(),
    "endBirthDate": endBirthDate?.toIso8601String(),
    "categories": categories == null ? null : List<dynamic>.from(categories!.map((dynamic x) => x)),
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "fromCreatedAt": fromCreatedAt?.toIso8601String(),
    "toCreatedAt": toCreatedAt?.toIso8601String(),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((dynamic x) => x)),
    "selectorArgs": selectorArgs?.toMap(),
    "orderBy": orderBy,
    "ids": ids == null ? <dynamic>[] : List<dynamic>.from(ids!.map((String x) => x)),
    "creatorId": creatorId,
  };
}

class UUserUpdateParams {
  UUserUpdateParams({
    required this.id,
    this.password,
    this.landLine,
    this.firstName,
    this.lastName,
    this.nationalCode,
    this.userName,
    this.phoneNumber,
    this.email,
    this.bio,
    this.birthdate,
    this.fcmToken,
    this.fatherName,
    this.weight,
    this.height,
    this.categories,
    this.addTags,
    this.removeTags,
    this.tags,
    this.nationalCardFront,
    this.nationalCardBack,
    this.birthCertificateFirst,
    this.birthCertificateSecond,
    this.birthCertificateThird,
    this.birthCertificateForth,
    this.birthCertificateFifth,
    this.visualAuthentication,
    this.eSignature,
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
    this.adminUserIds,
    this.addAdminUserIds,
    this.removeAdminUserIds,
  });

  factory UUserUpdateParams.fromJson(String str) => UUserUpdateParams.fromMap(json.decode(str));

  factory UUserUpdateParams.fromMap(Map<String, dynamic> json) => UUserUpdateParams(
    password: json["password"],
    landLine: json["landLine"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    nationalCode: json["nationalCode"],
    userName: json["userName"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    bio: json["bio"],
    birthdate: json["birthdate"] == null ? null : DateTime.parse(json["birthdate"]),
    fcmToken: json["fcmToken"],
    fatherName: json["fatherName"],
    weight: json["weight"]?.toDouble(),
    height: json["height"]?.toDouble(),
    nationalCardFront: json["nationalCardFront"],
    nationalCardBack: json["nationalCardBack"],
    birthCertificateFirst: json["birthCertificateFirst"],
    birthCertificateSecond: json["birthCertificateSecond"],
    birthCertificateThird: json["birthCertificateThird"],
    birthCertificateForth: json["birthCertificateForth"],
    birthCertificateFifth: json["birthCertificateFifth"],
    visualAuthentication: json["visualAuthentication"],
    eSignature: json["eSignature"],
    nationalCardFrontRejectionReason: json["nationalCardFrontRejectionReason"],
    nationalCardBackRejectionReason: json["nationalCardBackRejectionReason"],
    birthCertificateFirstRejectionReason: json["birthCertificateFirstRejectionReason"],
    birthCertificateSecondRejectionReason: json["birthCertificateSecondRejectionReason"],
    birthCertificateThirdRejectionReason: json["birthCertificateThirdRejectionReason"],
    birthCertificateForthRejectionReason: json["birthCertificateForthRejectionReason"],
    birthCertificateFifthRejectionReason: json["birthCertificateFifthRejectionReason"],
    visualAuthenticationRejectionReason: json["visualAuthenticationRejectionReason"],
    eSignatureRejectionReason: json["eSignatureRejectionReason"],
    categories: json["categories"] == null ? null : List<String>.from(json["categories"].map((dynamic x) => x)),
    id: json["id"],
    addTags: json["addTags"] == null ? null : List<int>.from(json["addTags"].map((dynamic x) => x)),
    removeTags: json["removeTags"] == null ? null : List<int>.from(json["removeTags"].map((dynamic x) => x)),
    tags: json["tags"] == null ? null : List<int>.from(json["tags"].map((dynamic x) => x)),
    detail1: json["detail1"],
    detail2: json["detail2"],
    adminUserIds: json["adminUserIds"] == null ? <String>[] : List<String>.from(json["adminUserIds"]!.map((dynamic x) => x)),
    addAdminUserIds: json["addAdminUserIds"] == null ? <String>[] : List<String>.from(json["addAdminUserIds"]!.map((dynamic x) => x)),
    removeAdminUserIds: json["removeAdminUserIds"] == null ? <String>[] : List<String>.from(json["removeAdminUserIds"]!.map((dynamic x) => x)),
  );
  final String? password;
  final String? landLine;
  final String? firstName;
  final String? lastName;
  final String? nationalCode;
  final String? userName;
  final String? phoneNumber;
  final String? email;
  final String? bio;
  final DateTime? birthdate;
  final String? fcmToken;
  final String? fatherName;
  final double? weight;
  final double? height;
  final List<String>? categories;
  final String id;
  final List<int>? addTags;
  final List<int>? removeTags;
  final List<int>? tags;
  final String? nationalCardFront;
  final String? nationalCardBack;
  final String? birthCertificateFirst;
  final String? birthCertificateSecond;
  final String? birthCertificateThird;
  final String? birthCertificateForth;
  final String? birthCertificateFifth;
  final String? visualAuthentication;
  final String? eSignature;
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
  final List<String>? adminUserIds;
  final List<String>? addAdminUserIds;
  final List<String>? removeAdminUserIds;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "password": password,
    "landLine": landLine,
    "firstName": firstName,
    "lastName": lastName,
    "nationalCode": nationalCode,
    "userName": userName,
    "phoneNumber": phoneNumber,
    "email": email,
    "bio": bio,
    "birthdate": birthdate?.toIso8601String(),
    "fcmToken": fcmToken,
    "fatherName": fatherName,
    "weight": weight,
    "height": height,
    "nationalCardFront": nationalCardFront,
    "nationalCardBack": nationalCardBack,
    "birthCertificateFirst": birthCertificateFirst,
    "birthCertificateSecond": birthCertificateSecond,
    "birthCertificateThird": birthCertificateThird,
    "birthCertificateForth": birthCertificateForth,
    "birthCertificateFifth": birthCertificateFifth,
    "visualAuthentication": visualAuthentication,
    "eSignature": eSignature,
    "nationalCardFrontRejectionReason": nationalCardFrontRejectionReason,
    "nationalCardBackRejectionReason": nationalCardBackRejectionReason,
    "birthCertificateFirstRejectionReason": birthCertificateFirstRejectionReason,
    "birthCertificateSecondRejectionReason": birthCertificateSecondRejectionReason,
    "birthCertificateThirdRejectionReason": birthCertificateThirdRejectionReason,
    "birthCertificateForthRejectionReason": birthCertificateForthRejectionReason,
    "birthCertificateFifthRejectionReason": birthCertificateFifthRejectionReason,
    "visualAuthenticationRejectionReason": visualAuthenticationRejectionReason,
    "eSignatureRejectionReason": eSignatureRejectionReason,
    "categories": categories == null ? null : List<dynamic>.from(categories!.map((dynamic x) => x)),
    "id": id,
    "addTags": addTags == null ? null : List<dynamic>.from(addTags!.map((dynamic x) => x)),
    "removeTags": removeTags == null ? null : List<dynamic>.from(removeTags!.map((dynamic x) => x)),
    "tags": tags == null ? null : List<dynamic>.from(tags!.map((dynamic x) => x)),
    "detail1": detail1,
    "detail2": detail2,
    "adminUserIds": adminUserIds == null ? <dynamic>[] : List<dynamic>.from(adminUserIds!.map((String x) => x)),
    "addAdminUserIds": addAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(addAdminUserIds!.map((String x) => x)),
    "removeAdminUserIds": removeAdminUserIds == null ? <dynamic>[] : List<dynamic>.from(removeAdminUserIds!.map((String x) => x)),
  };
}
