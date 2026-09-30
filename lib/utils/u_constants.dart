/// Storage key names used by ULocalStorage and UAuth; change them before initU() if your app needs other names.
abstract class UConstants {
  /// Key of the access token.
  static String token = "token";

  /// Key of the refresh token.
  static String refreshToken = "refreshToken";

  /// Key of the refresh-token expiry.
  static String refreshTokenExpiresAt = "refreshTokenExpiresAt";

  /// Key of the user id.
  static String userId = "userId";

  /// Key of the saved language.
  static String locale = "locale";

  /// Key of the saved theme.
  static String isDarkMode = "isDarkMode";
}

/// Brand icons bundled with u (SVG asset paths). `SvgPicture.asset(UIcons.telegram, package: "u")`
abstract class UIcons {
  static const String _base = "lib/assets/icons";

  /// Instagram logo.
  static const String instagram = "$_base/instagram.svg";

  /// Phone icon.
  static const String phone = "$_base/phone.svg";

  /// Telegram logo.
  static const String telegram = "$_base/telegram.svg";

  /// Website/globe icon.
  static const String website = "$_base/website.svg";

  /// WhatsApp logo.
  static const String whatsapp = "$_base/whatsapp.svg";
}
