import "dart:typed_data";

/// Carries framed bytes to and from the acquirer. Implemented with a socket on
/// Android and desktop, a WebSocket relay on the web, or a fake in tests — the
/// protocol layer never learns which.
abstract class IsoTransport {
  bool get isConnected;

  /// Frames the host sends us, already stripped of the length prefix.
  Stream<Uint8List> get incoming;

  Future<void> connect();

  /// Sends one complete frame, length prefix included.
  Future<void> send(Uint8List frame);

  Future<void> close();

  /// Closes the link and releases the stream for good. A transport is not
  /// reusable afterwards, unlike [close].
  Future<void> dispose();
}

class IsoTransportException implements Exception {
  IsoTransportException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => "IsoTransportException($message${cause == null ? "" : ", cause: $cause"})";
}

/// Where and how to reach the host. Ported from `HostConnectionInfo`.
class HostConnectionInfo {
  HostConnectionInfo({
    required this.hostIp,
    required this.hostPort,
    this.ssl = false,
    this.readTimeoutSeconds = 120,
    this.connectTimeoutSeconds = 5,
    this.sslPublicKey,
    this.sslPrivateKey,
    this.sslPrivateKeyPassword,
    this.apn,
    this.tms,
  });

  factory HostConnectionInfo.fromJson(Map<String, dynamic> json) => HostConnectionInfo(
    hostIp: json["hostIp"]?.toString() ?? "",
    hostPort: (json["hostPort"] as num?)?.toInt() ?? 0,
    ssl: json["ssl"] as bool? ?? false,
    readTimeoutSeconds: (json["readTimeout"] as num?)?.toInt() ?? 120,
    connectTimeoutSeconds: (json["connectTimeout"] as num?)?.toInt() ?? 5,
    sslPublicKey: json["sslPublicKey"] as String?,
    sslPrivateKey: json["sslPrivateKey"] as String?,
    sslPrivateKeyPassword: json["sslPrivateKeyPassword"] as String?,
    apn: json["apn"] as bool?,
    tms: json["tms"] == null ? null : HostConnectionInfo.fromJson(json["tms"] as Map<String, dynamic>),
  );

  final String hostIp;
  final int hostPort;
  final bool ssl;
  final int readTimeoutSeconds;
  final int connectTimeoutSeconds;

  /// Base64 PEM of the host certificate to trust.
  final String? sslPublicKey;

  /// Base64 PKCS#12 holding the client certificate and key.
  final String? sslPrivateKey;

  /// Base64 of the PKCS#12 password.
  final String? sslPrivateKeyPassword;

  final bool? apn;
  final HostConnectionInfo? tms;

  Map<String, dynamic> toJson() => <String, dynamic>{
    "hostIp": hostIp,
    "hostPort": hostPort,
    "ssl": ssl,
    "readTimeout": readTimeoutSeconds,
    "connectTimeout": connectTimeoutSeconds,
    if (sslPublicKey != null) "sslPublicKey": sslPublicKey,
    if (sslPrivateKey != null) "sslPrivateKey": sslPrivateKey,
    if (sslPrivateKeyPassword != null) "sslPrivateKeyPassword": sslPrivateKeyPassword,
    if (apn != null) "apn": apn,
    if (tms != null) "tms": tms!.toJson(),
  };

  @override
  bool operator ==(Object other) => other is HostConnectionInfo && other.hostIp == hostIp && other.hostPort == hostPort && other.ssl == ssl;

  @override
  int get hashCode => Object.hash(hostIp, hostPort, ssl);
}
