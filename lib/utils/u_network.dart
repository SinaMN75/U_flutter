import "package:u/utilities.dart";

abstract class UNetwork {
  static Future<bool> hasCellular() async {
    if (!kIsWeb) {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile);
    }
    return true;
  }

  static Future<bool> hasWifi() async {
    if (!kIsWeb) {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.wifi);
    }
    return true;
  }

  static Future<bool> hasVpn() async {
    if (!kIsWeb) {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.vpn);
    }
    return true;
  }

  static Future<bool> hasEthernet() async {
    if (!kIsWeb) {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.ethernet);
    }
    return true;
  }

  static Future<bool> hasBluetooth() async {
    if (!kIsWeb) {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.bluetooth);
    }
    return true;
  }

  static Future<bool> hasNetworkConnection() async {
    if (!kIsWeb) {
      return InternetConnectionChecker().hasConnection;
    }
    return true;
  }
}

class AddressCheckOptions {
  AddressCheckOptions(
    this.address, {
    this.port = InternetConnectionChecker.defaultPort,
    this.timeout = InternetConnectionChecker.defaultTimeout,
  });

  final InternetAddress address;
  final int port;
  final Duration timeout;

  @override
  String toString() => "AddressCheckOptions($address, $port, $timeout)";
}

class AddressCheckResult {
  AddressCheckResult(this.options, this.isSuccess);

  final AddressCheckOptions options;

  final bool isSuccess;

  @override
  String toString() => "AddressCheckResult($options, $isSuccess)";
}

class InternetConnectionChecker {
  factory InternetConnectionChecker() => _instance;

  InternetConnectionChecker._() {
    _statusController.onListen = _maybeEmitStatusUpdate;

    _statusController.onCancel = () {
      _timerHandle?.cancel();
      _lastStatus = null;
    };
  }

  static const int defaultPort = 53;

  static const Duration defaultTimeout = Duration(seconds: 10);

  static const Duration defaultInterval = Duration(seconds: 10);

  static final List<AddressCheckOptions> defaultAddresses = List<AddressCheckOptions>.unmodifiable(
    <AddressCheckOptions>[
      AddressCheckOptions(InternetAddress("1.1.1.1", type: InternetAddressType.IPv4)),
      AddressCheckOptions(InternetAddress("2606:4700:4700::1111", type: InternetAddressType.IPv6)),
      AddressCheckOptions(InternetAddress("8.8.4.4", type: InternetAddressType.IPv4)),
      AddressCheckOptions(InternetAddress("2001:4860:4860::8888", type: InternetAddressType.IPv6)),
      AddressCheckOptions(InternetAddress("208.67.222.222", type: InternetAddressType.IPv4)),
      AddressCheckOptions(InternetAddress("2620:0:ccc::2", type: InternetAddressType.IPv6)),
    ],
  );

  List<AddressCheckOptions> addresses = defaultAddresses;

  static final InternetConnectionChecker _instance = InternetConnectionChecker._();

  Future<AddressCheckResult> isHostReachable(final AddressCheckOptions options) async {
    Socket? sock;
    try {
      sock =
          await Socket.connect(
              options.address,
              options.port,
              timeout: options.timeout,
            )
            ..destroy();
      return AddressCheckResult(
        options,
        true,
      );
    } catch (e) {
      sock?.destroy();
      return AddressCheckResult(
        options,
        false,
      );
    }
  }

  Future<bool> get hasConnection async {
    final Completer<bool> result = Completer<bool>();
    int length = addresses.length;

    for (final AddressCheckOptions addressOptions in addresses) {
      await isHostReachable(addressOptions).then(
        (final AddressCheckResult request) {
          length -= 1;
          if (!result.isCompleted) {
            if (request.isSuccess) {
              result.complete(true);
            } else if (length == 0)
              result.complete(false);
          }
        },
      );
    }
    return result.future;
  }

  Future<InternetConnectionStatus> get connectionStatus async => await hasConnection ? InternetConnectionStatus.connected : InternetConnectionStatus.disconnected;

  Duration checkInterval = defaultInterval;

  Future<void> _maybeEmitStatusUpdate([final Timer? timer]) async {
    _timerHandle?.cancel();
    timer?.cancel();
    final InternetConnectionStatus currentStatus = await connectionStatus;
    if (_lastStatus != currentStatus && _statusController.hasListener) _statusController.add(currentStatus);
    if (!_statusController.hasListener) return;
    _timerHandle = Timer(checkInterval, _maybeEmitStatusUpdate);
    _lastStatus = currentStatus;
  }

  InternetConnectionStatus? _lastStatus;
  Timer? _timerHandle;
  final StreamController<InternetConnectionStatus> _statusController = StreamController<InternetConnectionStatus>.broadcast();

  Stream<InternetConnectionStatus> get onStatusChange => _statusController.stream;

  bool get hasListeners => _statusController.hasListener;

  bool get isActivelyChecking => _statusController.hasListener;
}

enum InternetConnectionStatus { connected, disconnected }
