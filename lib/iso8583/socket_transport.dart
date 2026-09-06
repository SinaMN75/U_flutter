import "package:u/utilities.dart";

/// An [IsoTransport] backed by a real TCP socket, with optional mutual TLS.
///
/// Replaces the Netty client in `ISONettyClient`: the pipeline there is a
/// length-prefix decoder plus an SSL handler, which is a [SecureSocket] and an
/// [OssFrameReader] here.
class SocketIsoTransport implements IsoTransport {
  SocketIsoTransport(this.info);

  final HostConnectionInfo info;

  final StreamController<Uint8List> _incoming = StreamController<Uint8List>.broadcast();
  final IsoFrameReader _reader = IsoFrameReader();

  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;

  @override
  bool get isConnected => _socket != null;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  Future<void> connect() async {
    if (_socket != null) return;
    _reader.reset();

    final Duration connectTimeout = Duration(seconds: info.connectTimeoutSeconds);
    _socket = info.ssl
        ? await SecureSocket.connect(info.hostIp, info.hostPort, context: _buildSecurityContext(), timeout: connectTimeout, supportedProtocols: const <String>["http/1.1"])
        : await Socket.connect(info.hostIp, info.hostPort, timeout: connectTimeout);

    _socket!.setOption(SocketOption.tcpNoDelay, true);
    IsoTrace.log(
      IsoTraceKind.link,
      "socket open, local ${_socket!.address.address}:${_socket!.port} -> ${_socket!.remoteAddress.address}:${_socket!.remotePort}",
    );

    _subscription = _socket!.listen(
      (Uint8List chunk) {
        for (final Uint8List frame in _reader.add(chunk)) {
          _incoming.add(frame);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        IsoTrace.log(IsoTraceKind.link, "socket error: $error");
        _incoming.addError(IsoTransportException("socket error", error), stackTrace);
        unawaited(close());
      },
      onDone: () {
        IsoTrace.log(IsoTraceKind.link, "socket closed by the host");
        unawaited(close());
      },
      cancelOnError: true,
    );
  }

  /// Builds the TLS context from the base64 material in [HostConnectionInfo]:
  /// a PEM host certificate to trust and a PKCS#12 holding the client
  /// certificate, exactly what `HostConnectionBuilder` reads on the Java side.
  SecurityContext? _buildSecurityContext() {
    final String? publicKey = info.sslPublicKey;
    final String? privateKey = info.sslPrivateKey;
    if (publicKey == null && privateKey == null) return null;

    final SecurityContext context = SecurityContext();
    if (publicKey != null) context.setTrustedCertificatesBytes(base64Decode(publicKey));
    if (privateKey != null) {
      final String? password = info.sslPrivateKeyPassword == null ? null : utf8.decode(base64Decode(info.sslPrivateKeyPassword!));
      final Uint8List keyBytes = base64Decode(privateKey);
      context.useCertificateChainBytes(keyBytes, password: password);
      context.usePrivateKeyBytes(keyBytes, password: password);
    }
    return context;
  }

  @override
  Future<void> send(Uint8List frame) async {
    if (_socket == null) throw IsoTransportException("not connected");
    _socket!.add(frame);
    await _socket!.flush();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    _reader.reset();
    if (_socket != null) {
      try {
        await _socket!.close();
      } catch (_) {
        _socket!.destroy();
      }
      _socket = null;
    }
  }

  @override
  Future<void> dispose() async {
    await close();
    await _incoming.close();
  }
}
