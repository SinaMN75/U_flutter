import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'u_method_channel.dart';

abstract class UPlatform extends PlatformInterface {
  /// Constructs a UPlatform.
  UPlatform() : super(token: _token);

  static final Object _token = Object();

  static UPlatform _instance = MethodChannelU();

  /// The default instance of [UPlatform] to use.
  ///
  /// Defaults to [MethodChannelU].
  static UPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [UPlatform] when
  /// they register themselves.
  static set instance(UPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
