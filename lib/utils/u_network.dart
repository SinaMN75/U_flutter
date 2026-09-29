import "package:u/utilities.dart";

/// The original network helpers, now backed by [UConnectivity] (accurate on the web too).
abstract class UNetwork {
  /// True when on mobile data.
  static Future<bool> hasCellular() async => (await _status()).isCellular;

  /// True when on Wi-Fi.
  static Future<bool> hasWifi() async => (await _status()).isWifi;

  /// True when a VPN is active.
  static Future<bool> hasVpn() async => (await _status()).isVpn;

  /// True when on a wired connection.
  static Future<bool> hasEthernet() async => (await _status()).isEthernet;

  /// True when tethered over Bluetooth.
  static Future<bool> hasBluetooth() async => (await _status()).isBluetooth;

  /// True when the internet really answers (pings your server).
  static Future<bool> hasNetworkConnection() => UConnectivity.hasInternet();

  /// True when there is a usable network connection.
  static Future<bool> hasAnyConnection() async => (await _status()).isOnline;

  // --- UConnectivity, one wrapper each ---------------------------------------------------

  /// Full network snapshot (types, metered, roaming, speed, …).
  static UNetworkStatus get status => UConnectivity.status;

  /// True when connected (instant, no network request).
  static bool get isOnline => UConnectivity.isOnline;

  /// True when not connected (instant, no network request).
  static bool get isOffline => UConnectivity.isOffline;

  /// True when on Wi-Fi.
  static bool get isWifi => UConnectivity.isWifi;

  /// True when on mobile data.
  static bool get isCellular => UConnectivity.isCellular;

  /// True when on a wired connection.
  static bool get isEthernet => UConnectivity.isEthernet;

  /// True when a VPN is active.
  static bool get isVpn => UConnectivity.isVpn;

  /// True when tethered over Bluetooth.
  static bool get isBluetooth => status.isBluetooth;

  /// True when data costs money (mobile data, hotspot).
  static bool get isMetered => UConnectivity.isMetered;

  /// True when Data Saver / Low Data Mode is on.
  static bool get isConstrained => status.constrained;

  /// True when roaming (null when unknown).
  static bool? get isRoaming => status.roaming;

  /// True on Wi-Fi that needs a sign-in page first (hotel, airport).
  static bool get isBehindCaptivePortal => status.captivePortal;

  /// True when online on free data with no data saver: safe for big downloads.
  static bool get isUnmetered => status.isUnmetered;

  /// True when the connection is good enough for video / big files.
  static bool get isFast => status.isFast;

  /// Main connection type: wifi, cellular, ethernet, …
  static UNetworkType? get type => status.primary;

  /// All connection types in use (e.g. wifi + vpn).
  static Set<UNetworkType> get types => status.types;

  /// Mobile network generation: "2g", "3g", "4g" or "5g".
  static String? get cellularGeneration => status.cellularGeneration;

  /// Estimated download speed in kbps.
  static int? get downlinkKbps => status.downlinkKbps;

  /// Estimated upload speed in kbps.
  static int? get uplinkKbps => status.uplinkKbps;

  /// Estimated round-trip time in ms (web).
  static int? get rttMs => status.rttMs;

  /// Signal strength in dBm (Android).
  static int? get signalStrength => status.signalStrength;

  /// Name of the active network interface, e.g. "wlan0".
  static String? get interfaceName => status.interfaceName;

  /// Emits every time the network changes.
  static Stream<UNetworkStatus> get stream => UConnectivity.stream;

  /// Emits true/false only when going online or offline.
  static Stream<bool> get onlineStream => UConnectivity.onlineStream;

  /// Network state for ValueListenableBuilder.
  static ValueListenable<UNetworkStatus> get listenable => UConnectivity.listenable;

  /// Calls [onChange] every time the network changes.
  static StreamSubscription<UNetworkStatus> listen(void Function(UNetworkStatus status) onChange) => UConnectivity.listen(onChange);

  /// Starts watching the network (initU() already does this).
  static Future<void> init() => UConnectivity.init();

  /// Re-reads the network state from the OS right now.
  static Future<UNetworkStatus> refresh() => UConnectivity.refresh();

  /// Waits until the device is online.
  static Future<void> whenOnline({Duration? timeout}) => UConnectivity.whenOnline(timeout: timeout);

  /// True when the internet really answers (pings your server, cached 5s).
  static Future<bool> hasInternet({bool force = false, Duration timeout = const Duration(seconds: 5)}) => UConnectivity.hasInternet(force: force, timeout: timeout);

  /// All IP addresses of this device.
  static Future<List<UNetworkAddress>> addresses({bool includeLoopback = false}) => UConnectivity.addresses(includeLoopback: includeLoopback);

  /// This device's local IPv4 address, e.g. "192.168.1.20".
  static Future<String?> localIp() => UConnectivity.localIp();

  /// URLs hasInternet() pings (null = your baseUrl + 2 public ones).
  static List<Uri>? get probeUrls => UConnectivity.probeUrls;

  /// Changes the URLs hasInternet() pings.
  static set probeUrls(List<Uri>? urls) => UConnectivity.probeUrls = urls;

  /// How long offline must last before it is reported.
  static Duration get offlineGrace => UConnectivity.offlineGrace;

  /// Changes how long offline must last before it is reported.
  static set offlineGrace(Duration value) => UConnectivity.offlineGrace = value;

  /// Stops watching the network.
  static Future<void> dispose() => UConnectivity.dispose();

  static Future<UNetworkStatus> _status() async {
    await UConnectivity.init();
    return UConnectivity.status;
  }
}

class UAddressCheckOptions {
  UAddressCheckOptions(
    this.address, {
    this.port = UInternetConnectionChecker.defaultPort,
    this.timeout = UInternetConnectionChecker.defaultTimeout,
  });

  final InternetAddress address;
  final int port;
  final Duration timeout;

  @override
  String toString() => "AddressCheckOptions($address, $port, $timeout)";
}

class UAddressCheckResult {
  UAddressCheckResult(this.options, this.isSuccess);

  final UAddressCheckOptions options;

  final bool isSuccess;

  @override
  String toString() => "AddressCheckResult($options, $isSuccess)";
}

class UInternetConnectionChecker {
  factory UInternetConnectionChecker() => _instance;

  UInternetConnectionChecker._() {
    _statusController.onListen = _maybeEmitStatusUpdate;

    _statusController.onCancel = () {
      _timerHandle?.cancel();
      _lastStatus = null;
    };
  }

  static const int defaultPort = 53;

  static const Duration defaultTimeout = Duration(seconds: 10);

  static const Duration defaultInterval = Duration(seconds: 10);

  static final List<UAddressCheckOptions> defaultAddresses = List<UAddressCheckOptions>.unmodifiable(
    <UAddressCheckOptions>[
      UAddressCheckOptions(InternetAddress("1.1.1.1", type: InternetAddressType.IPv4)),
      UAddressCheckOptions(InternetAddress("2606:4700:4700::1111", type: InternetAddressType.IPv6)),
      UAddressCheckOptions(InternetAddress("8.8.4.4", type: InternetAddressType.IPv4)),
      UAddressCheckOptions(InternetAddress("2001:4860:4860::8888", type: InternetAddressType.IPv6)),
      UAddressCheckOptions(InternetAddress("208.67.222.222", type: InternetAddressType.IPv4)),
      UAddressCheckOptions(InternetAddress("2620:0:ccc::2", type: InternetAddressType.IPv6)),
    ],
  );

  List<UAddressCheckOptions> addresses = defaultAddresses;

  static final UInternetConnectionChecker _instance = UInternetConnectionChecker._();

  Future<UAddressCheckResult> isHostReachable(UAddressCheckOptions options) async {
    Socket? sock;
    try {
      sock =
          await Socket.connect(
              options.address,
              options.port,
              timeout: options.timeout,
            )
            ..destroy();
      return UAddressCheckResult(
        options,
        true,
      );
    } catch (e) {
      sock?.destroy();
      return UAddressCheckResult(
        options,
        false,
      );
    }
  }

  Future<bool> get hasConnection async {
    final Completer<bool> result = Completer<bool>();
    int length = addresses.length;

    for (final UAddressCheckOptions addressOptions in addresses) {
      await isHostReachable(addressOptions).then(
        (UAddressCheckResult request) {
          length -= 1;
          if (!result.isCompleted) {
            if (request.isSuccess) {
              result.complete(true);
            } else if (length == 0) {
              result.complete(false);
            }
          }
        },
      );
    }
    return result.future;
  }

  Future<UInternetConnectionStatus> get connectionStatus async => await hasConnection ? UInternetConnectionStatus.connected : UInternetConnectionStatus.disconnected;

  Duration checkInterval = defaultInterval;

  Future<void> _maybeEmitStatusUpdate([Timer? timer]) async {
    _timerHandle?.cancel();
    timer?.cancel();
    final UInternetConnectionStatus currentStatus = await connectionStatus;
    if (_lastStatus != currentStatus && _statusController.hasListener) _statusController.add(currentStatus);
    if (!_statusController.hasListener) return;
    _timerHandle = Timer(checkInterval, _maybeEmitStatusUpdate);
    _lastStatus = currentStatus;
  }

  UInternetConnectionStatus? _lastStatus;
  Timer? _timerHandle;
  final StreamController<UInternetConnectionStatus> _statusController = StreamController<UInternetConnectionStatus>.broadcast();

  Stream<UInternetConnectionStatus> get onStatusChange => _statusController.stream;

  bool get hasListeners => _statusController.hasListener;

  bool get isActivelyChecking => _statusController.hasListener;
}

enum UInternetConnectionStatus { connected, disconnected }
