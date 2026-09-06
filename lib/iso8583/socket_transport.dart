import "package:u/utilities.dart";

/// An [IsoTransport] backed by a real TCP socket, with optional mutual TLS.
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
        ? await SecureSocket.connect(
            info.hostIp,
            info.hostPort,
            context: _buildSecurityContext(),
            timeout: connectTimeout,

            // This is ALPN, NOT TLS version selection.
            supportedProtocols: const <String>["http/1.1"],

            // Java's custom trust store does not perform normal hostname
            // verification in the same way Dart's TLS implementation does.
            //
            // Only accept the certificate if it is exactly the certificate
            // configured in sslPublicKey.
            onBadCertificate: _validateServerCertificate,
          )
        : await Socket.connect(
            info.hostIp,
            info.hostPort,
            timeout: connectTimeout,
          );

    _socket!.setOption(SocketOption.tcpNoDelay, true);

    IsoTrace.log(
      IsoTraceKind.link,
      "socket open, local "
      "${_socket!.address.address}:${_socket!.port} -> "
      "${_socket!.remoteAddress.address}:${_socket!.remotePort}",
    );

    _subscription = _socket!.listen(
      (Uint8List chunk) {
        for (final Uint8List frame in _reader.add(chunk)) {
          _incoming.add(frame);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        IsoTrace.log(
          IsoTraceKind.link,
          "socket error: $error",
        );

        _incoming.addError(
          IsoTransportException("socket error", error),
          stackTrace,
        );

        unawaited(close());
      },
      onDone: () {
        IsoTrace.log(
          IsoTraceKind.link,
          "socket closed by the host",
        );

        unawaited(close());
      },
      cancelOnError: true,
    );
  }

  /// Builds the TLS context using the exact same material as the Java
  /// HostConnectionBuilder:
  ///
  /// sslPublicKey:
  ///   Base64 -> PEM X.509 certificate
  ///
  /// sslPrivateKey:
  ///   Base64 -> PKCS#12 containing client certificate/private key
  ///
  /// sslPrivateKeyPassword:
  ///   Base64 -> UTF-8 password
  SecurityContext? _buildSecurityContext() {
    final String? publicKey = info.sslPublicKey;
    final String? privateKey = info.sslPrivateKey;

    if (publicKey == null && privateKey == null) {
      return null;
    }

    final SecurityContext context = SecurityContext();

    if (publicKey != null && publicKey.isNotEmpty) {
      final Uint8List certificateBytes = base64Decode(publicKey);

      context.setTrustedCertificatesBytes(certificateBytes);
    }

    if (privateKey != null && privateKey.isNotEmpty) {
      final String? password = info.sslPrivateKeyPassword == null
          ? null
          : utf8.decode(
              base64Decode(info.sslPrivateKeyPassword!),
            );

      final Uint8List keyStoreBytes = base64Decode(privateKey);

      // The Java implementation loads sslPrivateKey as PKCS12.
      //
      // Dart SecurityContext accepts PKCS12 directly here.
      context.useCertificateChainBytes(
        keyStoreBytes,
        password: password,
      );

      context.usePrivateKeyBytes(
        keyStoreBytes,
        password: password,
      );
    }

    return context;
  }

  /// Validates the server certificate.
  ///
  /// This specifically handles the case where the connection is made using
  /// an IP address but the certificate does not contain that IP in its SAN.
  ///
  /// We do NOT blindly return true.
  ///
  /// The certificate presented by the server must exactly match the
  /// certificate configured in sslPublicKey.
  bool _validateServerCertificate(X509Certificate certificate) {
    final String? publicKey = info.sslPublicKey;

    if (publicKey == null || publicKey.isEmpty) {
      return false;
    }

    try {
      final Uint8List configuredBytes = base64Decode(publicKey);

      final Uint8List expectedDer = _certificateToDer(configuredBytes);

      final Uint8List actualDer = certificate.der;

      return _bytesEqual(actualDer, expectedDer);
    } catch (error) {
      IsoTrace.log(
        IsoTraceKind.link,
        "server certificate validation failed: $error",
      );

      return false;
    }
  }

  /// Converts the configured certificate to DER.
  ///
  /// Java receives sslPublicKey as:
  ///
  /// Base64 -> PEM text -> CertificateFactory("X.509")
  ///
  /// So normally this is a Base64 encoded PEM certificate.
  ///
  /// This method also supports Base64 encoded raw DER just in case.
  Uint8List _certificateToDer(Uint8List bytes) {
    final String text = utf8.decode(
      bytes,
      allowMalformed: true,
    );

    if (!text.contains("-----BEGIN CERTIFICATE-----")) {
      // Already DER.
      return bytes;
    }

    final String pem = text
        .replaceAll(
          "-----BEGIN CERTIFICATE-----",
          "",
        )
        .replaceAll(
          "-----END CERTIFICATE-----",
          "",
        )
        .replaceAll(
          RegExp(r"\s"),
          "",
        );

    return Uint8List.fromList(
      base64Decode(pem),
    );
  }

  bool _bytesEqual(
    Uint8List a,
    Uint8List b,
  ) {
    if (a.length != b.length) {
      return false;
    }

    int difference = 0;

    for (int i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }

  @override
  Future<void> send(Uint8List frame) async {
    if (_socket == null) {
      throw IsoTransportException("not connected");
    }

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
