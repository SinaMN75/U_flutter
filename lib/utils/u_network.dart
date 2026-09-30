import "package:u/utilities.dart";

/// Network state: connection type, metered/roaming, speed, real internet checks. Wraps [UConnectivity].
abstract class UNetwork {
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

}
