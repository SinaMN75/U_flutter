import "package:u/src/live/u_live_socket.dart" if (dart.library.js_interop) "package:u/src/live/u_live_socket_web.dart";
import "package:u/utilities.dart";

/// Something the server pushed: the event name and its arguments.
class ULiveEvent {
  const ULiveEvent(this.target, this.arguments);

  /// "notification", "message", "messageChanged", "read", "conversation", "tournament", "openMatch".
  final String target;
  final List<dynamic> arguments;

  dynamic get first => arguments.isEmpty ? null : arguments.first;
}

/// Live updates from the backend's SignalR hub (/hubs/u), over a plain WebSocket with the JSON protocol.
/// `ULive.connect()` after sign-in, `ULive.on("message").listen(...)`, `ULive.joinConversation(id)`; reconnects by itself.
abstract class ULive {
  static const String _separator = "\u001e";
  static final StreamController<ULiveEvent> _events = StreamController<ULiveEvent>.broadcast();
  static final Set<(String, String)> _joined = <(String, String)>{};
  static ULiveSocket? _socket;
  static Timer? _ping;
  static bool _wanted = false;
  static bool _connecting = false;
  static int _invocation = 0;
  static int _retry = 0;

  static Stream<ULiveEvent> get events => _events.stream;

  /// Events with this name. `ULive.on("notification").listen((_) => readCount())`
  static Stream<ULiveEvent> on(String target) => _events.stream.where((ULiveEvent e) => e.target == target);

  static bool get isConnected => _socket != null;

  /// The hub next to the API: https://host/api → wss://host/hubs/u.
  static String get _url {
    final Uri api = Uri.parse(U.baseUrl);
    final String root = api.path.endsWith("/api") || api.path.endsWith("/api/") ? api.path.substring(0, api.path.lastIndexOf("/api")) : "";
    return api
        .replace(
          scheme: api.scheme == "https" ? "wss" : "ws",
          path: "$root/hubs/u",
          queryParameters: <String, String>{"apiKey": U.apiKey, "access_token": ULocalStorage.getToken() ?? ""},
        )
        .toString();
  }

  static Future<void> connect() async {
    _wanted = true;
    if (_socket != null || _connecting) return;
    _connecting = true;
    try {
      final ULiveSocket socket = await ULiveSocket.connect(_url);
      _socket = socket;
      _retry = 0;
      socket.messages.listen(_receive, onDone: _lost, onError: (Object _) => _lost(), cancelOnError: true);
      socket.send('{"protocol":"json","version":1}$_separator');
      _ping = Timer.periodic(const Duration(seconds: 15), (_) => _send(<String, dynamic>{"type": 6}));
      for (final (String method, String id) in _joined) {
        unawaited(_invoke(method, <Object?>[id]));
      }
    } catch (_) {
      _lost();
    } finally {
      _connecting = false;
    }
  }

  static Future<void> disconnect() async {
    _wanted = false;
    _joined.clear();
    _ping?.cancel();
    final ULiveSocket? socket = _socket;
    _socket = null;
    await socket?.close();
  }

  static void _lost() {
    _ping?.cancel();
    _socket = null;
    if (!_wanted) return;
    // Back off a little more after every failure, up to 30 seconds.
    _retry = (_retry + 1).clamp(1, 6);
    Timer(Duration(seconds: <int>[1, 2, 5, 10, 20, 30][_retry - 1]), connect);
  }

  static void _receive(String data) {
    for (final String frame in data.split(_separator).where((String i) => i.trim().isNotEmpty)) {
      final Map<String, dynamic> message = json.decode(frame) as Map<String, dynamic>;
      switch (message["type"]) {
        case 1:
          _events.add(ULiveEvent(message["target"] as String, (message["arguments"] as List<dynamic>?) ?? <dynamic>[]));
        case 7:
          _lost();
      }
    }
  }

  static void _send(Map<String, dynamic> message) => _socket?.send("${json.encode(message)}$_separator");

  static Future<void> _invoke(String method, List<Object?> arguments) async =>
      _send(<String, dynamic>{"type": 1, "invocationId": (++_invocation).toString(), "target": method, "arguments": arguments});

  static Future<void> _join(String method, String id) async {
    _joined.add((method, id));
    await connect();
    await _invoke(method, <Object?>[id]);
  }

  static Future<void> _leave(String join, String leave, String id) async {
    _joined.remove((join, id));
    await _invoke(leave, <Object?>[id]);
  }

  /// New messages of a conversation arrive as "message" (only for its members).
  static Future<void> joinConversation(String id) => _join("JoinConversation", id);

  static Future<void> leaveConversation(String id) => _leave("JoinConversation", "LeaveConversation", id);

  /// "tournament" arrives when its schedule or a score changes.
  static Future<void> joinTournament(String id) => _join("JoinTournament", id);

  static Future<void> leaveTournament(String id) => _leave("JoinTournament", "LeaveTournament", id);
}
