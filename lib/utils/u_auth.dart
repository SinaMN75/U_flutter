import "dart:developer" as developer;

import "package:u/utilities.dart";

/// Login session on top of ULocalStorage: JWT expiry, one-at-a-time token refresh, sign-out. UHttpClient uses it automatically. `if (UAuth.isSignedIn) …`
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

  /// Counter bumped on every login/logout; lets requests started before a logout ignore their result.
  static int get epoch => _epoch;

  /// True after the server rejected the refresh token (user was signed out).
  static bool get isSessionEnded => _authFailureHandled;

  /// True for login/register/refresh endpoints (they never need a token).
  static bool isTokenIssuingEndpoint(String endpoint) => _tokenIssuingEndpoints.any((String e) => endpoint.contains(e));

  /// Call after saving new tokens; resets the session-ended flag.
  static void onTokensIssued() {
    _epoch++;
    _authFailureHandled = false;
  }

  /// Expiry read from the JWT "exp" claim; null when the token is not a JWT.
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

  /// True when the access token expires within 30 seconds.
  static bool isAccessTokenExpired() {
    final DateTime? expiresAt = accessTokenExpiresAt();
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().add(_refreshLeeway).isAfter(expiresAt);
  }

  /// True when a refresh token is saved.
  static bool get hasRefreshToken {
    final String? refreshToken = ULocalStorage.getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// True when the saved refresh token has expired.
  static bool get isRefreshTokenExpired {
    final DateTime? expiresAt = ULocalStorage.getRefreshTokenExpiresAt();
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt);
  }

  /// True when a valid refresh token can renew the session.
  static bool get canRefresh => hasRefreshToken && !isRefreshTokenExpired;

  /// True when a token exists and is valid or can be refreshed. `home: UAuth.isSignedIn ? HomePage() : LoginPage()`
  static bool get isSignedIn => ULocalStorage.hasToken() && (!isAccessTokenExpired() || canRefresh);

  static void _log(String message) {
    if (kDebugMode) developer.log("[UAuth] $message");
  }

  /// One-line dump of the session state for logs.
  static String diagnostics() =>
      "hasToken=${ULocalStorage.hasToken()} accessExpiresAt=${accessTokenExpiresAt()} accessExpired=${isAccessTokenExpired()} "
      "hasRefreshToken=$hasRefreshToken refreshExpiresAt=${ULocalStorage.getRefreshTokenExpiresAt()} refreshExpired=$isRefreshTokenExpired "
      "canRefresh=$canRefresh epoch=$_epoch sessionEnded=$_authFailureHandled now=${DateTime.now().toUtc()}";

  /// Refreshes the access token first when it is (nearly) expired; UHttpClient calls it before each request.
  static Future<void> ensureFreshToken() async {
    if (!ULocalStorage.hasToken()) {
      _log("ensureFreshToken: skipped, no access token stored. ${diagnostics()}");
      return;
    }
    if (!isAccessTokenExpired()) return;
    if (!canRefresh) {
      _log("ensureFreshToken: access token expired but cannot refresh. ${diagnostics()}");
      return;
    }
    _log("ensureFreshToken: access token expired, refreshing. ${diagnostics()}");
    await refresh();
  }

  /// Refreshes the tokens now; parallel calls share one request. Returns true on success.
  static Future<bool> refresh() {
    _refreshInFlight ??= _refresh().whenComplete(() => _refreshInFlight = null);
    return _refreshInFlight!;
  }

  static Future<bool> _refresh() async {
    final String? refreshToken = ULocalStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    if (isRefreshTokenExpired) return false;
    final (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = await UAuthService().refreshToken(
      p: URefreshTokenParams(refreshToken: refreshToken),
      onOk: (UResponse<ULoginResponse> r) {},
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    if (result.$1?.result != null) {
      _log("refresh: OK, new token stored. ${diagnostics()}");
      return true;
    }
    final UEmptyResponse? error = result.$2;
    _log("refresh: FAILED status=${error?.status} message=${error?.message} exception=${result.$3}");
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

  /// Signs out: clears storage and files but keeps the language and theme. `await UAuth.signOut(); UNavigator.offAll(LoginPage())`
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

  /// Deletes only the tokens and user id.
  static Future<void> clear() async {
    await ULocalStorage.remove(UConstants.token);
    await ULocalStorage.remove(UConstants.refreshToken);
    await ULocalStorage.remove(UConstants.refreshTokenExpiresAt);
    await ULocalStorage.remove(UConstants.userId);
  }

  /// Signs out once and calls UHttpClient.onAuthFailed (e.g. to show the login page).
  static Future<void> handleAuthFailure() async {
    if (_authFailureHandled) return;
    _log("handleAuthFailure: signing the user out. ${diagnostics()}");
    _authFailureHandled = true;
    await clear();
    ULoading.dismiss();
    await UHttpClient.onAuthFailed?.call();
  }
}
