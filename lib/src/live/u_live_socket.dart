import "dart:async";
import "dart:io";

/// A text WebSocket (dart:io on Android, iOS and desktop).
class ULiveSocket {
  ULiveSocket._(this._socket);

  final WebSocket _socket;

  static Future<ULiveSocket> connect(String url) async => ULiveSocket._(await WebSocket.connect(url));

  Stream<String> get messages => _socket.where((dynamic i) => i is String).cast<String>();

  void send(String text) => _socket.add(text);

  Future<void> close() => _socket.close();
}
