import "package:u/utilities.dart";

// Wire protocol shared with the terminal (Apos: integration/edge/bluetooth/BluetoothPosProtocol.kt); keep both byte-compatible.
//
//   frame      = int32 BE length + bytes
//   handshake  client → "PLK1" + keyId(8) + clientNonce(32)
//              server → serverNonce(32) + HMAC(key, "server" | keyId | cN | sN)   (or a single 0 byte: unknown key)
//              client → HMAC(key, "client" | keyId | cN | sN)
//   session    AES-256-GCM, key HMAC(key, "c2s"|"s2c" | cN | sN), nonce = 4 zero bytes + int64 BE counter per direction
//   message    type(1) + number(int32 BE) + body
abstract final class UPosLinkProtocol {
  static const String serviceUuid = "6f1c2b7e-4a8d-4c55-9b3e-2d7f0a91c5e4";
  static const String rxUuid = "6f1c2b7e-4a8d-4c55-9b3e-2d7f0a91c5e5";
  static const String txUuid = "6f1c2b7e-4a8d-4c55-9b3e-2d7f0a91c5e6";
  static const int manufacturerId = 0xFFFF;
  static const String qrScheme = "poslink";
  static const int keySize = 32;
  static const int keyIdSize = 8;
  static const int tagSize = 4;
  static const int nonceSize = 32;
  static const int maxFrame = 256 * 1024;

  static const int request = 1;
  static const int response = 2;
  static const int ping = 3;
  static const int pong = 4;
  static const int welcome = 5;
  static const int clientInfo = 6;

  static final Uint8List magic = Uint8List.fromList(utf8.encode("PLK1"));

  static Uint8List hmac(List<int> key, String label, List<List<int>> parts) =>
      UEncryption.hmacSha256Bytes(<int>[...utf8.encode(label), for (final List<int> p in parts) ...p], key);
}

class UPosLinkMessage {
  const UPosLinkMessage(this.type, this.number, this.body);

  final int type;
  final int number;
  final Uint8List body;
}

class UPosLinkAuthException implements Exception {
  const UPosLinkAuthException(this.reason);

  /// "rejected" when the terminal does not know this pairing, otherwise a proof failure.
  final String reason;

  @override
  String toString() => "UPosLinkAuthException($reason)";
}

class _UPosLinkCipher {
  _UPosLinkCipher(this.key);

  final Uint8List key;
  int _counter = 0;

  Uint8List _nonce() {
    final ByteData nonce = ByteData(12)..setInt64(4, _counter++);
    return nonce.buffer.asUint8List();
  }

  Uint8List seal(List<int> plain) => UEncryption.aesGcmEncryptBytes(key, _nonce(), plain);

  Uint8List open(List<int> sealed) => UEncryption.aesGcmDecryptBytes(key, _nonce(), sealed);
}

/// Client side of the protocol over any byte transport: feed incoming bytes to [receive], [write] sends bytes out
/// in pieces of at most [chunkSize]. Used by UPosLink over BLE; works over a socket too.
class UPosLinkSession {
  UPosLinkSession({required this.write, this.chunkSize = 20});

  final Future<void> Function(Uint8List bytes) write;
  final int chunkSize;

  final BytesBuilder _incoming = BytesBuilder();
  final StreamController<Uint8List> _frames = StreamController<Uint8List>();
  late final StreamQueue<Uint8List> _queue = StreamQueue<Uint8List>(_frames.stream);
  final StreamController<UPosLinkMessage> _messages = StreamController<UPosLinkMessage>.broadcast();
  Future<void> _writing = Future<void>.value();
  _UPosLinkCipher? _sender;
  _UPosLinkCipher? _receiver;
  bool _closed = false;

  /// Decrypted messages after the handshake; closes when the link does.
  Stream<UPosLinkMessage> get messages => _messages.stream;

  bool get isClosed => _closed;

  void receive(List<int> bytes) {
    if (_closed) return;
    _incoming.add(bytes);
    while (true) {
      final Uint8List data = _incoming.toBytes();
      if (data.length < 4) return;
      final int size = ByteData.sublistView(data, 0, 4).getInt32(0);
      if (size < 1 || size > UPosLinkProtocol.maxFrame) return close(const FormatException("bad frame size"));
      if (data.length < 4 + size) return;
      _incoming.clear();
      _incoming.add(data.sublist(4 + size));
      _onFrame(Uint8List.sublistView(data, 4, 4 + size));
    }
  }

  void _onFrame(Uint8List frame) {
    final _UPosLinkCipher? receiver = _receiver;
    if (receiver == null) return _frames.add(Uint8List.fromList(frame));
    try {
      final Uint8List plain = receiver.open(frame);
      if (plain.length < 5) throw const FormatException("bad message");
      final ByteData header = ByteData.sublistView(plain, 0, 5);
      _messages.add(UPosLinkMessage(header.getUint8(0), header.getInt32(1), Uint8List.sublistView(plain, 5)));
    } catch (e) {
      close(e);
    }
  }

  Future<void> _writeFrame(List<int> bytes) {
    final ByteData header = ByteData(4)..setInt32(0, bytes.length);
    final Uint8List frame = Uint8List.fromList(<int>[...header.buffer.asUint8List(), ...bytes]);
    return _writing = _writing.then((_) async {
      for (int i = 0; i < frame.length; i += chunkSize) {
        await write(Uint8List.sublistView(frame, i, i + chunkSize > frame.length ? frame.length : i + chunkSize));
      }
    });
  }

  Future<Uint8List> _readFrame() async {
    if (!await _queue.hasNext) throw const UPosLinkAuthException("closed");
    return _queue.next;
  }

  /// Proves both sides hold [key]; returns the key to keep if the terminal rotates it on first use.
  Future<Uint8List> handshake(List<int> keyId, List<int> key) async {
    final Uint8List clientNonce = UEncryption.randomBytes(UPosLinkProtocol.nonceSize);
    await _writeFrame(<int>[...UPosLinkProtocol.magic, ...keyId, ...clientNonce]);
    final Uint8List reply = await _readFrame();
    if (reply.length == 1 && reply[0] == 0) throw const UPosLinkAuthException("rejected");
    if (reply.length != UPosLinkProtocol.nonceSize + 32) throw const UPosLinkAuthException("bad reply");
    final Uint8List serverNonce = reply.sublist(0, UPosLinkProtocol.nonceSize);
    final Uint8List proof = reply.sublist(UPosLinkProtocol.nonceSize);
    if (!UEncryption.constantTimeEqualsBytes(proof, UPosLinkProtocol.hmac(key, "server", <List<int>>[keyId, clientNonce, serverNonce]))) throw const UPosLinkAuthException("bad server proof");
    await _writeFrame(UPosLinkProtocol.hmac(key, "client", <List<int>>[keyId, clientNonce, serverNonce]));
    _sender = _UPosLinkCipher(UPosLinkProtocol.hmac(key, "c2s", <List<int>>[clientNonce, serverNonce]));
    _receiver = _UPosLinkCipher(UPosLinkProtocol.hmac(key, "s2c", <List<int>>[clientNonce, serverNonce]));
    return UPosLinkProtocol.hmac(key, "next", <List<int>>[clientNonce, serverNonce]);
  }

  Future<void> send(int type, int number, List<int> body) {
    final _UPosLinkCipher sender = _sender ?? (throw StateError("handshake first"));
    final ByteData header = ByteData(5)
      ..setUint8(0, type)
      ..setInt32(1, number);
    return _writeFrame(sender.seal(<int>[...header.buffer.asUint8List(), ...body]));
  }

  void close([Object? error]) {
    if (_closed) return;
    _closed = true;
    if (error != null) _messages.addError(error);
    _messages.close();
    _frames.close();
  }
}
