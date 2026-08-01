import "package:u/utils/web/u_web_stub.dart" if (dart.library.html) "package:u/utils/web/u_web_impl.dart" as impl;

typedef UWebMessageHandler = void Function(String origin, Map<String, dynamic> data);

abstract class UWebMessage {
  static void Function() listen(UWebMessageHandler onMessage) => impl.listenWebMessage(onMessage);
}
