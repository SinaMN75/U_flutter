import "package:flutter_web_plugins/flutter_web_plugins.dart";
import "package:u/u_platform_interface.dart";
import "package:web/web.dart" as web;

class UWeb extends UPlatform {
  UWeb();

  static void registerWith(Registrar registrar) {
    UPlatform.instance = UWeb();
  }

  @override
  Future<String?> getPlatformVersion() async {
    final String version = web.window.navigator.userAgent;
    return version;
  }
}
