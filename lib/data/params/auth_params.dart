part of "../data.dart";

class URefreshTokenParams {
  URefreshTokenParams({
    required this.refreshToken,
  });

  factory URefreshTokenParams.fromJson(String str) => URefreshTokenParams.fromMap(json.decode(str));

  factory URefreshTokenParams.fromMap(Map<String, dynamic> json) => URefreshTokenParams(
    refreshToken: json["refreshToken"],
  );
  final String refreshToken;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "refreshToken": refreshToken,
  };
}

class UGetMobileVerificationCodeForLoginParams {
  UGetMobileVerificationCodeForLoginParams({
    required this.phoneNumber,
  });

  factory UGetMobileVerificationCodeForLoginParams.fromJson(String str) => UGetMobileVerificationCodeForLoginParams.fromMap(
    json.decode(str),
  );

  factory UGetMobileVerificationCodeForLoginParams.fromMap(Map<String, dynamic> json) => UGetMobileVerificationCodeForLoginParams(
    phoneNumber: json["phoneNumber"],
  );
  final String phoneNumber;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "phoneNumber": phoneNumber,
  };
}

class ULoginParams {
  ULoginParams({
    required this.password,
    this.userName,
    this.email,
  });

  factory ULoginParams.fromJson(String str) => ULoginParams.fromMap(json.decode(str));

  factory ULoginParams.fromMap(Map<String, dynamic> json) => ULoginParams(
    userName: json["userName"],
    email: json["email"],
    password: json["password"],
  );
  final String? userName;
  final String? email;
  final String password;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userName": userName,
    "email": email,
    "password": password,
  };
}

class URegisterParams {
  URegisterParams({
    required this.userName,
    required this.password,
    required this.tags,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.nationalCode,
  });

  factory URegisterParams.fromJson(String str) => URegisterParams.fromMap(json.decode(str));

  factory URegisterParams.fromMap(Map<String, dynamic> json) => URegisterParams(
    userName: json["userName"],
    email: json["email"],
    phoneNumber: json["phoneNumber"],
    password: json["password"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    nationalCode: json["nationalCode"],
    tags: List<int>.from(json["tags"].map((dynamic x) => x)),
  );
  final String userName;
  final String? email;
  final String? phoneNumber;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? nationalCode;
  final List<int> tags;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userName": userName,
    "email": email,
    "phoneNumber": phoneNumber,
    "password": password,
    "firstName": firstName,
    "lastName": lastName,
    "nationalCode": nationalCode,
    "tags": List<dynamic>.from(tags.map((int x) => x)),
  };
}

class UVerifyMobileForLoginParams {
  UVerifyMobileForLoginParams({
    required this.phoneNumber,
    required this.otp,
  });

  factory UVerifyMobileForLoginParams.fromJson(String str) => UVerifyMobileForLoginParams.fromMap(json.decode(str));

  factory UVerifyMobileForLoginParams.fromMap(Map<String, dynamic> json) => UVerifyMobileForLoginParams(
    phoneNumber: json["phoneNumber"],
    otp: json["otp"],
  );
  final String phoneNumber;
  final String otp;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "phoneNumber": phoneNumber,
    "otp": otp,
  };
}

class UAuthCompleteProfileParams {
  UAuthCompleteProfileParams({
    required this.nationalCode,
    required this.firstName,
    required this.lastName,
  });

  factory UAuthCompleteProfileParams.fromJson(String str) => UAuthCompleteProfileParams.fromMap(json.decode(str));

  factory UAuthCompleteProfileParams.fromMap(Map<String, dynamic> json) => UAuthCompleteProfileParams(
    nationalCode: json["nationalCode"],
    firstName: json["firstName"],
    lastName: json["lastName"],
  );
  final String nationalCode;
  final String firstName;
  final String lastName;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "nationalCode": nationalCode,
    "firstName": firstName,
    "lastName": lastName,
  };
}
