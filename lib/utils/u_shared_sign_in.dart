import "package:u/src/web/u_web_native.dart" if (dart.library.js_interop) "package:u/src/web/u_web_browser.dart";
import "package:u/utilities.dart";

/// The account a sibling app (same publisher, same device) is signed in with, and the key to continue with it.
class USharedAccount {
  USharedAccount({
    required this.userId,
    required this.name,
    required this.appId,
    required this.key,
    required this.expiresAt,
    this.hint = "",
    this.appName = "",
  });

  factory USharedAccount.fromMap(Map<String, dynamic> json) => USharedAccount(
    userId: json["userId"] ?? "",
    name: json["name"] ?? "",
    hint: json["hint"] ?? "",
    appId: json["appId"] ?? "",
    appName: json["appName"] ?? "",
    key: json["key"] ?? "",
    expiresAt: DateTime.tryParse(json["expiresAt"] ?? "")?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final String userId;
  final String name;

  /// A masked phone number or email, e.g. "+98 912 *** 6789".
  final String hint;

  /// The app that wrote the record and its display name ("روی همین گوشی در … وارد هستی").
  final String appId;
  final String appName;

  /// Opaque key the app exchanges for a session; for SinaMN75U a sign-in transfer key.
  final String key;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  Map<String, dynamic> toMap() => <String, dynamic>{
    "userId": userId,
    "name": name,
    "hint": hint,
    "appId": appId,
    "appName": appName,
    "key": key,
    "expiresAt": expiresAt.toIso8601String(),
  };
}

/// "Continue as …" between separately installed apps of one publisher on one device.
///
/// Each app keeps one record (who is signed in and a key to continue) where only its siblings can read it:
/// Android: a ContentProvider guarded by a signature permission (same signing key only);
/// iOS/macOS: a shared keychain access group; web: a cookie on the shared parent domain.
/// A platform that is not set up returns no accounts, so the app simply shows its normal sign-in.
///
/// ```dart
/// USharedSignIn.configure(appId: "com.x.shop", apps: <String>["com.x.shop", "com.x.travel"], webDomain: "x.com", appleAccessGroup: "TEAMID.com.x.family");
/// await USharedSignIn.publish(appName: "Shop"); // after sign-in and at start (SinaMN75U backend)
/// final List<USharedAccount> list = await USharedSignIn.accounts();
/// if (list.isNotEmpty && await USharedSignIn.signIn(list.first)) ...
/// await USharedSignIn.clear(); // on sign-out
/// ```
abstract final class USharedSignIn {
  static const MethodChannel _channel = MethodChannel("u/shared_sign_in");
  static const String _cookiePrefix = "u_ssi_";

  static String _appId = "";
  static List<String> _apps = <String>[];
  static String? _webDomain;
  static String? _appleAccessGroup;

  /// [appId]: this app's id (Android applicationId / bundle id). [apps]: every app of the family, this one included.
  /// [webDomain]: the parent domain the web builds share ("x.com"); other hosts (localhost) keep a host-only cookie.
  /// [appleAccessGroup]: "TeamID.group" listed in every app's keychain-access-groups entitlement; null = off on Apple.
  static void configure({required String appId, required List<String> apps, String? webDomain, String? appleAccessGroup}) {
    _appId = appId;
    _apps = apps;
    _webDomain = webDomain;
    _appleAccessGroup = appleAccessGroup;
  }

  static bool get isConfigured => _appId.isNotEmpty;

  /// The Android authority the app's provider must be declared with.
  static String authorityOf(String appId) => "$appId.u.sharedsignin";

  /// Accounts signed in on sibling apps: newest record per user, expired ones and [exceptUserId] left out.
  static Future<List<USharedAccount>> accounts({String? exceptUserId}) async {
    if (!isConfigured) return <USharedAccount>[];
    final List<String> raw = await _readAll();
    final Map<String, USharedAccount> byUser = <String, USharedAccount>{};
    for (final String json in raw) {
      try {
        final USharedAccount a = USharedAccount.fromMap(jsonDecode(json));
        if (a.appId == _appId || a.userId.isEmpty || a.key.isEmpty || a.isExpired || a.userId == exceptUserId) continue;
        final USharedAccount? old = byUser[a.userId];
        if (old == null || a.expiresAt.isAfter(old.expiresAt)) byUser[a.userId] = a;
      } catch (_) {}
    }
    return byUser.values.toList();
  }

  /// Saves this app's record for its siblings.
  static Future<void> write(USharedAccount account) async {
    if (!isConfigured) return;
    final String json = jsonEncode(account.toMap());
    if (kIsWeb) {
      final int seconds = account.expiresAt.difference(DateTime.now().toUtc()).inSeconds;
      UWebBridge.setCookie(_cookieName, json, domain: _cookieDomain, maxAgeSeconds: seconds < 0 ? 0 : seconds);
      return;
    }
    await _invoke("write", <String, Object?>{"json": json});
  }

  /// Removes this app's record; siblings stop offering this app's account.
  static Future<void> clear() async {
    if (!isConfigured) return;
    if (kIsWeb) return UWebBridge.setCookie(_cookieName, "", domain: _cookieDomain, maxAgeSeconds: 0);
    await _invoke("clear");
  }

  // ---------------------------------------------------------------------------
  // SinaMN75U backend (opt-in): the key is a sign-in transfer key from /auth/CreateSignInTransfer.
  // ---------------------------------------------------------------------------

  /// When signed in, asks the server for a fresh transfer key and saves the record; [appName] is shown by the siblings.
  static Future<void> publish({required String appName}) async {
    if (!isConfigured || !UAuth.isSignedIn) return;
    final (UResponse<USignInTransferResponse>?, UEmptyResponse?, String?) r = await UServices.auth.createSignInTransfer();
    final USignInTransferResponse? transfer = r.$1?.result;
    if (transfer == null) return;
    final UUserResponse user = U.user;
    await write(
      USharedAccount(
        userId: user.id,
        name: user.displayName,
        hint: maskedContact(user.phoneNumber, user.email),
        appId: _appId,
        appName: appName,
        key: transfer.key,
        expiresAt: transfer.expiresAt,
      ),
    );
  }

  /// Exchanges the account's key for a session of the same user (tokens are saved like any login); false when the key is no longer valid.
  static Future<bool> signIn(USharedAccount account) async {
    final (UResponse<ULoginResponse>?, UEmptyResponse?, String?) r = await UServices.auth.redeemSignInTransfer(p: URedeemSignInTransferParams(key: account.key));
    return r.$1?.result != null;
  }

  /// "+98 912 *** 6789" or "sa***@mail.com"; empty when neither is known.
  static String maskedContact(String? phone, String? email) {
    final String digits = (phone ?? "").replaceAll(RegExp("[^0-9+]"), "");
    if (digits.length >= 7) return "${digits.substring(0, digits.length - 7)} *** ${digits.substring(digits.length - 4)}".trim();
    final String mail = (email ?? "").trim();
    final int at = mail.indexOf("@");
    if (at > 0) return "${mail.substring(0, at < 2 ? at : 2)}***${mail.substring(at)}";
    return "";
  }

  static String get _cookieName => "$_cookiePrefix${_appId.replaceAll(RegExp("[^A-Za-z0-9_]"), "_")}";

  static String? get _cookieDomain {
    final String? domain = _webDomain;
    if (domain == null || domain.isEmpty) return null;
    final String host = Uri.base.host;
    return host == domain || host.endsWith(".$domain") ? domain : null;
  }

  static Future<List<String>> _readAll() async {
    if (kIsWeb) {
      return UWebBridge.cookies().entries.where((MapEntry<String, String> e) => e.key.startsWith(_cookiePrefix) && e.key != _cookieName && e.value.isNotEmpty).map((MapEntry<String, String> e) => e.value).toList();
    }
    final List<Object?>? list = await _invoke<List<Object?>>("read", <String, Object?>{
      "authorities": _apps.where((String a) => a != _appId).map(authorityOf).toList(),
    });
    return (list ?? <Object?>[]).whereType<String>().toList();
  }

  static Future<T?> _invoke<T>(String method, [Map<String, Object?> args = const <String, Object?>{}]) async {
    try {
      return await _channel.invokeMethod<T>(method, <String, Object?>{...args, "appId": _appId, "accessGroup": _appleAccessGroup});
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint("u/shared_sign_in.$method failed: ${e.code} ${e.message ?? ""}");
      return null;
    }
  }
}
