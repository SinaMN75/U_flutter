part of "../data.dart";

class ULoginResponse {
  ULoginResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
    this.refreshTokenExpiresAt,
  });

  factory ULoginResponse.fromJson(String str) => ULoginResponse.fromMap(json.decode(str));

  factory ULoginResponse.fromMap(Map<String, dynamic> json) => ULoginResponse(
    token: json["token"],
    refreshToken: json["refreshToken"],
    refreshTokenExpiresAt: json["refreshTokenExpiresAt"] == null ? null : DateTime.tryParse(json["refreshTokenExpiresAt"])?.toUtc(),
    user: UUserResponse.fromMap(json["user"]),
  );
  final String token;
  final String refreshToken;
  final DateTime? refreshTokenExpiresAt;
  final UUserResponse user;

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => <String, dynamic>{
    "token": token,
    "refreshToken": refreshToken,
    "refreshTokenExpiresAt": refreshTokenExpiresAt?.toIso8601String(),
    "user": user.toMap(),
  };
}
