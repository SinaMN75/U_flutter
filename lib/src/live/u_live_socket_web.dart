import "dart:async";
import "dart:js_interop";

import "package:web/web.dart" as web;

/// A text WebSocket (the browser's).
class ULiveSocket {
  ULiveSocket._(this._socket);

  final web.WebSocket _socket;
  final StreamController<String> _messages = StreamController<String>.broadcast();

  static Future<ULiveSocket> connect(String url) {
    final web.WebSocket socket = web.WebSocket(url);
    final ULiveSocket live = ULiveSocket._(socket);
    final Completer<ULiveSocket> opened = Completer<ULiveSocket>();
    socket.onopen = ((web.Event _) => opened.complete(live)).toJS;
    socket.onerror = ((web.Event _) {
      if (!opened.isCompleted) opened.completeError(StateError("WebSocket failed"));
      live._messages.addError(StateError("WebSocket failed"));
    }).toJS;
    socket.onmessage = ((web.MessageEvent e) {
      final JSAny? data = e.data;
      if (data.isA<JSString>()) live._messages.add((data! as JSString).toDart);
    }).toJS;
    socket.onclose = ((web.CloseEvent _) {
      unawaited(live._messages.close());
    }).toJS;
    return opened.future;
  }

  Stream<String> get messages => _messages.stream;

  void send(String text) => _socket.send(text.toJS);

  Future<void> close() async {
    _socket.close();
    await _messages.close();
  }
}
