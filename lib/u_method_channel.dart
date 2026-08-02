import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:u/u_platform_interface.dart";

/// An implementation of [UPlatform] that uses method channels.
class MethodChannelU extends UPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel("u");

  @override
  Future<String?> getPlatformVersion() async {
    final String? version = await methodChannel.invokeMethod<String>(
      "getPlatformVersion",
    );
    return version;
  }
}
