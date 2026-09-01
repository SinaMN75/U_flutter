part of "u_admin.dart";

class UAdminConfig {
  UAdminConfig({
    required this.appName,
    required this.baseUrl,
    required this.primaryColor,
    required this.logo,
    required this.dashboard,
    required this.menu,
    this.apiKey = "",
    this.loginBackground,
    this.font,
    this.defaultLocale = const Locale("fa"),
  });

  final String appName;
  final String logo;
  final String? loginBackground;
  final Color primaryColor;
  final String? font;
  final String baseUrl;
  final String apiKey;
  final Locale defaultLocale;
  final UAdminModule Function() dashboard;
  final List<UAdminGroup> Function() menu;
}

abstract class UAdmin {
  static late UAdminConfig config;
  static String get logo => config.logo;
  static String? get loginBackground => config.loginBackground;

  static bool canAccess(List<TagUser>? roles) {
    if (roles == null || roles.isEmpty) return true;
    try {
      if (U.user.tags.contains(TagUser.superAdmin.number) || U.user.tags.contains(TagUser.systemAdmin.number)) return true;
      return roles.any((TagUser r) => U.user.tags.contains(r.number));
    } catch (_) {
      return false;
    }
  }
}
