
import 'u_platform_interface.dart';

class U {
  Future<String?> getPlatformVersion() {
    return UPlatform.instance.getPlatformVersion();
  }
}
