import "package:u/u_platform_interface.dart";

class U {
  Future<String?> getPlatformVersion() => UPlatform.instance.getPlatformVersion();
}
