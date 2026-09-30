import "package:u/utilities.dart";

/// Connection state on all 6 platforms: online, wifi/cellular/vpn, metered, speed, real internet checks, change streams. `if (UNetwork.isOffline) …`
abstract class UNetwork {
  /// Full snapshot (types, metered, roaming, speed, captive portal…). `UNetwork.status.types`
  static UNetworkStatus get status => UConnectivity.status;

  /// True when a network is connected (instant, no request; use hasInternet() to be sure). `if (UNetwork.isOnline) sync()`
  static bool get isOnline => UConnectivity.isOnline;

  /// True when no network is connected.
  static bool get isOffline => UConnectivity.isOffline;

  /// True on Wi-Fi.
  static bool get isWifi => UConnectivity.isWifi;

  /// True on mobile data.
  static bool get isCellular => UConnectivity.isCellular;

  /// True on a cable.
  static bool get isEthernet => UConnectivity.isEthernet;

  /// True while a VPN is active (web: never detectable).
  static bool get isVpn => UConnectivity.isVpn;

  /// True when tethered over Bluetooth.
  static bool get isBluetooth => status.isBluetooth;

  /// True when data may cost money (mobile data, hotspot). `if (!UNetwork.isMetered) autoDownload()`
  static bool get isMetered => UConnectivity.isMetered;

  /// True when Data Saver / Low Data Mode is on (Android, Apple, web Save-Data).
  static bool get isConstrained => status.constrained;

  /// True when roaming; null when the platform cannot tell (Android only).
  static bool? get isRoaming => status.roaming;

  /// True on Wi-Fi that wants a sign-in page first (hotel, airport); Android/Linux/Windows.
  static bool get isBehindCaptivePortal => status.captivePortal;

  /// True when online on free data without a data saver: safe for big downloads.
  static bool get isUnmetered => status.isUnmetered;

  /// True when good enough for video / big files (wifi, ethernet, 4G+, or fast web downlink).
  static bool get isFast => status.isFast;

  /// Main connection type (wifi, cellular, ethernet…); null when offline.
  static UNetworkType? get type => status.primary;

  /// Every connection type in use, e.g. {wifi, vpn}.
  static Set<UNetworkType> get types => status.types;

  /// Mobile generation "2g"/"3g"/"4g"/"5g" (Android, iOS; web effectiveType); null elsewhere.
  static String? get cellularGeneration => status.cellularGeneration;

  /// Estimated download speed in kbps (Android, web); null elsewhere.
  static int? get downlinkKbps => status.downlinkKbps;

  /// Estimated upload speed in kbps (Android); null elsewhere.
  static int? get uplinkKbps => status.uplinkKbps;

  /// Estimated round trip in ms (web only).
  static int? get rttMs => status.rttMs;

  /// Wi-Fi/cell signal in dBm (Android only).
  static int? get signalStrength => status.signalStrength;

  /// Active interface name, e.g. "wlan0", "en0"; null on web.
  static String? get interfaceName => status.interfaceName;

  /// Emits the full status every time the network changes. `UNetwork.stream.listen((s) => print(s.primary))`
  static Stream<UNetworkStatus> get stream => UConnectivity.stream;

  /// Emits true/false only when going online or offline. `UNetwork.onlineStream.listen((on) => on ? retry() : null)`
  static Stream<bool> get onlineStream => UConnectivity.onlineStream;

  /// Network status for ValueListenableBuilder. `ValueListenableBuilder(valueListenable: UNetwork.listenable, builder: (c, s, _) => Text("${s.primary}"))`
  static ValueListenable<UNetworkStatus> get listenable => UConnectivity.listenable;

  /// Calls [onChange] on every network change; cancel the returned subscription in dispose(). `final sub = UNetwork.listen(update);`
  static StreamSubscription<UNetworkStatus> listen(void Function(UNetworkStatus status) onChange) => UConnectivity.listen(onChange);

  /// Starts watching the network; initU() already does it.
  static Future<void> init() => UConnectivity.init();

  /// Reads the state from the OS again right now. `await UNetwork.refresh()`
  static Future<UNetworkStatus> refresh() => UConnectivity.refresh();

  /// Waits until the device is online ([timeout] throws TimeoutException). `await UNetwork.whenOnline(); upload();`
  static Future<void> whenOnline({Duration? timeout}) => UConnectivity.whenOnline(timeout: timeout);

  /// True when the internet really answers (pings your baseUrl + 2 public hosts, cached 5s). `if (await UNetwork.hasInternet()) …`
  static Future<bool> hasInternet({bool force = false, Duration timeout = const Duration(seconds: 5)}) => UConnectivity.hasInternet(force: force, timeout: timeout);

  /// Every IP address of this device (empty on web). `await UNetwork.addresses()`
  static Future<List<UNetworkAddress>> addresses({bool includeLoopback = false}) => UConnectivity.addresses(includeLoopback: includeLoopback);

  /// Local IPv4, e.g. "192.168.1.20" (null on web). `await UNetwork.localIp()`
  static Future<String?> localIp() => UConnectivity.localIp();

  /// URLs hasInternet() pings; null means your baseUrl + 2 public hosts. Set it to use your own. `UNetwork.probeUrls = [Uri.parse("https://api.x.com/health")]`
  static List<Uri>? get probeUrls => UConnectivity.probeUrls;

  /// URLs hasInternet() pings; null means your baseUrl + 2 public hosts. Set it to use your own. `UNetwork.probeUrls = [Uri.parse("https://api.x.com/health")]`
  static set probeUrls(List<Uri>? urls) => UConnectivity.probeUrls = urls;

  /// How long "offline" must last before it is reported (hides short drops). `UNetwork.offlineGrace = 2.seconds`
  static Duration get offlineGrace => UConnectivity.offlineGrace;

  /// How long "offline" must last before it is reported (hides short drops). `UNetwork.offlineGrace = 2.seconds`
  static set offlineGrace(Duration value) => UConnectivity.offlineGrace = value;

  /// Stops watching the network.
  static Future<void> dispose() => UConnectivity.dispose();
}
