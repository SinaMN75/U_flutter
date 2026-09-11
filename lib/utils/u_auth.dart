import "package:u/utilities.dart";

abstract class UAuth {
  static const Duration _refreshLeeway = Duration(seconds: 30);

  static int _epoch = 0;
  static bool _authFailureHandled = false;
  static Future<bool>? _refreshInFlight;

  static const List<String> _tokenIssuingEndpoints = <String>[
    "/auth/Login",
    "/auth/Register",
    "/auth/RefreshToken",
    "/auth/GetVerificationCodeForLogin",
    "/auth/VerifyCodeForLogin",
    "/auth/LoginOrRegister",
  ];

  static int get epoch => _epoch;

  static bool get isSessionEnded => _authFailureHandled;

  static bool isTokenIssuingEndpoint(String endpoint) => _tokenIssuingEndpoints.any((String e) => endpoint.contains(e));

  static void onTokensIssued() {
    _epoch++;
    _authFailureHandled = false;
  }

  static DateTime? accessTokenExpiresAt() {
    final String? token = ULocalStorage.getToken();
    if (token == null || token.isEmpty) return null;
    final List<String> parts = token.split(".");
    if (parts.length != 3) return null;
    try {
      String payload = parts[1].replaceAll("-", "+").replaceAll("_", "/");
      payload = payload.padRight(payload.length + ((4 - payload.length % 4) % 4), "=");
      final Map<String, dynamic> claims = jsonDecode(utf8.decode(base64.decode(payload)));
      final dynamic exp = claims["exp"];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (e) {
      return null;
    }
  }

  static bool isAccessTokenExpired() {
    final DateTime? expiresAt = accessTokenExpiresAt();
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().add(_refreshLeeway).isAfter(expiresAt);
  }

  static bool get hasRefreshToken {
    final String? refreshToken = ULocalStorage.getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  static bool get isRefreshTokenExpired {
    final DateTime? expiresAt = ULocalStorage.getRefreshTokenExpiresAt();
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt);
  }

  static bool get canRefresh => hasRefreshToken && !isRefreshTokenExpired;

  static bool get isSignedIn => ULocalStorage.hasToken() && (!isAccessTokenExpired() || canRefresh);

  static Future<void> ensureFreshToken() async {
    if (!ULocalStorage.hasToken()) return;
    if (!isAccessTokenExpired()) return;
    if (!canRefresh) return;
    await refresh();
  }

  static Future<bool> refresh() {
    _refreshInFlight ??= _refresh().whenComplete(() => _refreshInFlight = null);
    return _refreshInFlight!;
  }

  static Future<bool> _refresh() async {
    final String? refreshToken = ULocalStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    if (isRefreshTokenExpired) return false;
    final (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = await AuthService().refreshToken(
      p: URefreshTokenParams(refreshToken: refreshToken),
      onOk: (UResponse<ULoginResponse> r) {},
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    if (result.$1?.result != null) return true;
    final UEmptyResponse? error = result.$2;
    final bool isRejected =
        error != null &&
        (error.status == Usc.unAuthorized.number ||
            error.status == Usc.expiredRefreshToken.number ||
            error.status == Usc.userNotFound.number ||
            error.status == Usc.notFound.number ||
            error.status == Usc.forbidden.number);
    if (isRejected) await handleAuthFailure();
    return false;
  }

  static Future<void> signOut() async {
    final String? locale = ULocalStorage.getLocale();
    final bool isDarkMode = ULocalStorage.isDarkMode();
    await ULocalStorage.clear();
    await UFileStorage.clear();
    if (locale != null) ULocalStorage.setLocale(locale);
    ULocalStorage.setDarkMode(isDarkMode);
    _authFailureHandled = false;
    _epoch++;
  }

  static Future<void> clear() async {
    await ULocalStorage.remove(UConstants.token);
    await ULocalStorage.remove(UConstants.refreshToken);
    await ULocalStorage.remove(UConstants.refreshTokenExpiresAt);
    await ULocalStorage.remove(UConstants.userId);
  }

  static Future<void> handleAuthFailure() async {
    if (_authFailureHandled) return;
    _authFailureHandled = true;
    await clear();
    ULoading.dismiss();
    await UHttpClient.onAuthFailed?.call();
  }
}
