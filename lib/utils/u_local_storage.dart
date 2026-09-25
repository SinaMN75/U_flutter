import "package:u/utilities.dart";

abstract class ULocalStorage {
  static late SharedPreferences _sp;

  static Future<void> init() async => _sp = await SharedPreferences.getInstance();

  static Set<String> getKeys() => _sp.getKeys();

  static void set(String key, dynamic value, {Duration? expireTime, (String, String)? encryptKeyIv}) {
    if (value is String) {
      _sp.setString(
        key,
        encryptKeyIv == null
            ? value
            : UEncryption.aesEncrypt(
                plainText: value,
                key: encryptKeyIv.$1,
                iv: encryptKeyIv.$2,
              ),
      );
    } else if (value is bool) {
      _sp.setBool(key, value);
    } else if (value is double) {
      _sp.setDouble(key, value);
    } else if (value is int) {
      _sp.setInt(key, value);
    } else if (value is List<String>) {
      _sp.setStringList(key, value);
    } else {
      throw ArgumentError("Unsupported value type for key: $key");
    }

    if (expireTime != null) {
      _sp.setInt("_expiry_$key", DateTime.now().add(expireTime).millisecondsSinceEpoch);
    }
  }

  static Future<void> setBatch(Map<String, dynamic> keyValuePairs) async {
    for (final MapEntry<String, dynamic> entry in keyValuePairs.entries) {
      set(entry.key, entry.value);
    }
  }

  static int? getInt(String key) => getIfNotExpired(key);

  static String? getString(String key, {(String, String)? encryptKeyIv}) {
    final String? value = getIfNotExpired(key);
    if (value == null) return null;
    if (encryptKeyIv == null) return value;

    return UEncryption.aesDecrypt(
      base64Encrypted: value,
      key: encryptKeyIv.$1,
      iv: encryptKeyIv.$2,
    );
  }

  static bool? getBool(String key) => getIfNotExpired(key);

  static double? getDouble(String key) => getIfNotExpired(key);

  static List<String>? getStringList(String key) => getIfNotExpired(key);

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

  static String? getToken() => getIfNotExpired(UConstants.token);

  static String? getRefreshToken() => getIfNotExpired(UConstants.refreshToken);

  static DateTime? getRefreshTokenExpiresAt() {
    final int? value = getInt(UConstants.refreshTokenExpiresAt);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  static String? getLocale() => getIfNotExpired(UConstants.locale);

  static bool hasToken() => getIfNotExpired(UConstants.token) != null;

  static bool isDarkMode() => getIfNotExpired(UConstants.isDarkMode) ?? false;

  static String? getUserId() => getIfNotExpired(UConstants.userId);

  static bool containsKey(String key) => _sp.containsKey(key);

  static Future<void> remove(String key) async => _sp.remove(key);

  static Future<void> clear() async => _sp.clear();

  static Map<String, dynamic> getAll() {
    final Set<String> keys = getKeys();
    final Map<String, dynamic> data = <String, dynamic>{};
    for (final String key in keys) {
      data[key] = _sp.get(key);
    }
    return data;
  }

  static dynamic getIfNotExpired(String key) {
    final String expiryKey = "_expiry_$key";
    final int? expiryTime = _sp.getInt(expiryKey);
    if (expiryTime != null && DateTime.now().millisecondsSinceEpoch > expiryTime) {
      remove(key);
      remove(expiryKey);
      return null;
    }
    return _sp.get(key);
  }
}
