import "package:u/utilities.dart";

/// Matches responses to the requests that are waiting for them.
///
/// The Java `DefaultMultiplexer` parks the caller on a cache keyed by the link
/// header sequence; a Dart [Completer] per key does the same thing without the
/// polling loop.
class IsoMultiplexer {
  IsoMultiplexer({required this.keyOf});

  final String Function(IsoMsg message) keyOf;
  final Map<String, Completer<IsoMsg>> _pending = <String, Completer<IsoMsg>>{};

  int _sent = 0;
  int _received = 0;
  int _expired = 0;
  int _unmatched = 0;

  int get sent => _sent;

  int get received => _received;

  int get expired => _expired;

  int get unmatched => _unmatched;

  int get pending => _pending.length;

  /// Registers [key] as awaiting a response, runs [send], then waits.
  Future<IsoMsg?> request(String key, Future<void> Function() send, Duration timeout) async {
    if (_pending.containsKey(key)) throw StateError("duplicate in-flight message key $key");
    final Completer<IsoMsg> completer = Completer<IsoMsg>();
    _pending[key] = completer;
    _sent++;
    try {
      await send();
      final IsoMsg response = await completer.future.timeout(timeout);
      _received++;
      return response;
    } on TimeoutException {
      _expired++;
      return null;
    } finally {
      _pending.remove(key);
    }
  }

  /// Hands an incoming message to whoever is waiting for it. Returns false when
  /// nothing matched, which usually means the request already timed out.
  bool notifyResponse(IsoMsg message) {
    final String key;
    try {
      key = keyOf(message);
    } catch (_) {
      _unmatched++;
      return false;
    }
    final Completer<IsoMsg>? completer = _pending.remove(key);
    if (completer == null || completer.isCompleted) {
      _unmatched++;
      return false;
    }
    completer.complete(message);
    return true;
  }

  /// Fails every waiting request, for use when the link drops.
  void failAll(Object error) {
    final List<Completer<IsoMsg>> waiting = _pending.values.toList();
    _pending.clear();
    for (final Completer<IsoMsg> completer in waiting) {
      if (!completer.isCompleted) completer.completeError(error);
    }
  }
}
