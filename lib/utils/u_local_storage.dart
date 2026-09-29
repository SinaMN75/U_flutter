import "package:u/utilities.dart";

/// The original key/value API, now backed by [UStorage]. Signatures are unchanged.
/// Keys in [UStorage.secureKeys] (token, refresh token and its expiry) live in the
/// encrypted [UStorage.secure] store; everything else in the default store.
abstract class ULocalStorage {
  static Future<void> init() => UStorage.init();

  static UStore _storeFor(String key) => UStorage.secureKeys.contains(key) ? UStorage.secure : UStorage.instance;

  static Set<String> getKeys() => <String>{...UStorage.instance.keys, ...UStorage.secure.keys};

  static void set(String key, dynamic value, {Duration? expireTime, (String, String)? encryptKeyIv}) {
    if (value is! String && value is! bool && value is! double && value is! int && value is! List<String>) {
      throw ArgumentError("Unsupported value type for key: $key");
    }
    final Object stored = value is String && encryptKeyIv != null ? UEncryption.aesEncrypt(plainText: value, key: encryptKeyIv.$1, iv: encryptKeyIv.$2) : value as Object;
    unawaited(_storeFor(key).set(key, stored, ttl: expireTime));
  }

  static Future<void> setBatch(Map<String, dynamic> keyValuePairs) async {
    for (final MapEntry<String, dynamic> entry in keyValuePairs.entries) {
      set(entry.key, entry.value);
    }
    await UStorage.flushAll();
  }

  static int? getInt(String key) => _storeFor(key).get<int>(key);

  static String? getString(String key, {(String, String)? encryptKeyIv}) {
    final String? value = _storeFor(key).get<String>(key);
    if (value == null) return null;
    if (encryptKeyIv == null) return value;

    return UEncryption.aesDecrypt(
      base64Encrypted: value,
      key: encryptKeyIv.$1,
      iv: encryptKeyIv.$2,
    );
  }

  static bool? getBool(String key) => _storeFor(key).get<bool>(key);

  static double? getDouble(String key) => _storeFor(key).get<double>(key);

  static List<String>? getStringList(String key) => _storeFor(key).get<List<String>>(key);

  static void setToken(String value, {Duration? expireTime}) => set(UConstants.token, value, expireTime: expireTime);

  static void setRefreshToken(String value) => set(UConstants.refreshToken, value);

  static void setRefreshTokenExpiresAt(DateTime? value) {
    if (value == null) {
      remove(UConstants.refreshTokenExpiresAt);
      return;
    }
    set(UConstants.refreshTokenExpiresAt, value.toUtc().millisecondsSinceEpoch);
  }

  static void setLocale(String value) => set(UConstants.locale, value);

  static void setDarkMode(bool isDarkMode) => set(UConstants.isDarkMode, isDarkMode);

  static void setUserId(String userId) => set(UConstants.userId, userId);

  static String? getToken() => getString(UConstants.token);

  static String? getRefreshToken() => getString(UConstants.refreshToken);

  static DateTime? getRefreshTokenExpiresAt() {
    final int? value = getInt(UConstants.refreshTokenExpiresAt);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  static String? getLocale() => getString(UConstants.locale);

  static bool hasToken() => getToken() != null;

  static bool isDarkMode() => getBool(UConstants.isDarkMode) ?? false;

  static String? getUserId() => getString(UConstants.userId);

  static bool containsKey(String key) => _storeFor(key).has(key);

  static Future<void> remove(String key) => _storeFor(key).remove(key);

  static Future<void> clear() => Future.wait(<Future<void>>[UStorage.instance.clear(), UStorage.secure.clear()]);

  static Map<String, dynamic> getAll() => <String, dynamic>{...UStorage.instance.toMap(), ...UStorage.secure.toMap()};

  static dynamic getIfNotExpired(String key) => _storeFor(key).get<Object>(key);
}
