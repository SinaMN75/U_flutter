import "package:u/utilities.dart";

/// Owns the link to the host: MACs the request, frames it, sends it, and parks
/// until the matching response arrives.
///
/// Ported from `SyncTransactionSender`. The MAC is applied *before* the link
/// header is attached, the header sequence is what pairs request with response,
/// and a response that fails its MAC check is discarded rather than returned —
/// all as in the Java.
class IsoLink {
  IsoLink({
    required this.config,
    required this.macComponent,
    required this.transportFactory,
  });

  final HostConfig config;
  final MacComponent macComponent;
  final IsoTransport Function(HostConnectionInfo info) transportFactory;

  final OssAcqPackager _packager = OssAcqPackager();
  late final OssFrameCodec _codec = OssFrameCodec(_packager);
  late final IsoMultiplexer _multiplexer = IsoMultiplexer(keyOf: OssFrameCodec.messageKey);

  IsoTransport? _transport;
  HostConnectionInfo? _connectionInfo;
  StreamSubscription<Uint8List>? _subscription;

  IsoMultiplexer get multiplexer => _multiplexer;

  Future<void> _ensureConnected(IsoLinkEvents? events) async {
    final HostConnectionInfo info = config.activeConnectionInfo();
    if (_connectionInfo != null && _connectionInfo != info) await dispose();
    IsoTransport? transport = _transport;
    if (transport == null) {
      transport = transportFactory(info);
      _transport = transport;
      _connectionInfo = info;
      _subscription = transport.incoming.listen(
        (Uint8List payload) {
          IsoTrace.log(IsoTraceKind.incoming, "frame in, ${payload.length} bytes", bytes: payload);
          try {
            final IsoMsg decoded = _codec.decode(payload);
            IsoTrace.log(IsoTraceKind.decode, "mti=${decoded.hasField(0) ? decoded.mti : "?"} rc=${decoded.getString(39) ?? "-"} key=${OssFrameCodec.messageKey(decoded)}");
            if (!_multiplexer.notifyResponse(decoded)) {
              IsoTrace.log(IsoTraceKind.decode, "no request is waiting for key ${OssFrameCodec.messageKey(decoded)} — late or mismatched response");
            }
          } catch (error) {
            IsoTrace.log(IsoTraceKind.decode, "could not decode the frame: $error");
            events?.onConnectionEvent("decodeFailed", error);
          }
        },
        onError: (Object error) {
          IsoTrace.log(IsoTraceKind.link, "link error: $error");
          events?.onConnectionEvent("error", error);
          _multiplexer.failAll(error);
        },
        onDone: () {
          IsoTrace.log(IsoTraceKind.link, "host closed the connection");
          events?.onConnectionEvent("disconnected", null);
          _multiplexer.failAll(IsoTransportException("link closed"));
        },
      );
    }
    if (!transport.isConnected) {
      IsoTrace.log(IsoTraceKind.link, "connecting to ${info.hostIp}:${info.hostPort}${info.ssl ? " over TLS" : ""}");
      try {
        await transport.connect();
        IsoTrace.log(IsoTraceKind.link, "connected");
        events?.onConnectionEvent("connected", null);
      } catch (error) {
        IsoTrace.log(IsoTraceKind.link, "connect failed: $error");
        await dispose();
        throw UIsoException(UIsoErrorCode.cannotConnect, "could not reach ${info.hostIp}:${info.hostPort}", error);
      }
    }
  }

  Future<void> init({IsoLinkEvents? events}) => _ensureConnected(events);

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _transport?.dispose();
    _transport = null;
    _connectionInfo = null;
  }

  /// MACs, frames and sends [message], then waits for its response.
  ///
  /// [beforeSend] runs after the header is attached and before the bytes leave,
  /// which is where a reversible transaction stores its reversal record.
  Future<IsoMsg?> sendMessage(
    IsoMsg message, {
    Duration? timeout,
    IsoLinkEvents? events,
    Future<void> Function(IsoMsg request)? beforeSend,
  }) async {
    final Duration effectiveTimeout = timeout ?? Duration(seconds: config.defaultTxnTimeoutSeconds);

    try {
      await macComponent.generateMac(message, 4);
      IsoTrace.log(IsoTraceKind.mac, "request MAC built with the ${macComponent.usesDefaultMac(message) ? "default (KTM) " : "session "}key", bytes: message.getBytes(64));
    } catch (error) {
      IsoTrace.log(IsoTraceKind.mac, "the PED could not build a MAC: $error");
      throw UIsoException(UIsoErrorCode.securityModuleFailed, "could not build the request MAC", error);
    }

    message.recalcBitMap();

    final OssAcqHeader header = OssAcqHeader(source: config.sourceId, destination: config.destinationId)
      ..flags = 0x00
      ..sequence = OssAcqHeader.generateSequence();
    message.isoHeader = header.header;

    await _ensureConnected(events);
    if (beforeSend != null) await beforeSend(message);

    events?.onWaitForReceive();

    final String key = OssFrameCodec.messageKey(message);
    IsoTrace.log(IsoTraceKind.out, "mti=${message.mti} pc=${message.getString(3)} stan=${message.getString(11)} key=$key");

    final IsoMsg? response = await _multiplexer.request(
      key,
      () async {
        final Uint8List frame = _codec.encode(message);
        IsoTrace.log(IsoTraceKind.out, "frame out, ${frame.length} bytes", bytes: frame);
        await _transport!.send(frame);
      },
      effectiveTimeout,
    );

    if (response == null) {
      IsoTrace.log(IsoTraceKind.result, "nothing came back within ${effectiveTimeout.inSeconds}s");
      events?.onReceiveTimeout();
      return null;
    }

    if (!response.isReject) {
      final bool macValid = await macComponent.checkMac(response, 4);
      if (!macValid) {
        IsoTrace.log(IsoTraceKind.result, "the host answered but its MAC did not verify — the response is discarded");
        throw UIsoException(UIsoErrorCode.badResponseMac, "the host answered but the response MAC did not verify");
      }
      IsoTrace.log(IsoTraceKind.mac, "response MAC verified");
    } else {
      IsoTrace.log(IsoTraceKind.result, "the host rejected the message, reject code ${response.rejectCode}");
    }
    return response;
  }
}
