import "package:plugin_platform_interface/plugin_platform_interface.dart";
import "package:u/u_method_channel.dart";

abstract class UPlatform extends PlatformInterface {
  UPlatform() : super(token: _token);
  static final Object _token = Object();
  static UPlatform _instance = MethodChannelU();

  static UPlatform get instance => _instance;

  static set instance(UPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() => throw UnimplementedError("platformVersion() has not been implemented.");
}
