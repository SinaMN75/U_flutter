import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:http/http.dart" as http;
import "package:u/init.dart";
import "package:u/src/device/u_device_channel.dart";
import "package:u/src/web/u_web_native.dart" if (dart.library.js_interop) "package:u/src/web/u_web_browser.dart";

// =============================================================================
// u_connectivity — network state for every platform. Replaces connectivity_plus.
//
//   UConnectivity.isOnline                      // sync, always current
//   UConnectivity.status.isWifi / .isMetered / .cellularGeneration
//   UConnectivity.stream.listen((UNetworkStatus s) => ...)
//   await UConnectivity.whenOnline();           // e.g. before retrying a request
//   await UConnectivity.hasInternet();          // real round trip to your own server
//   UNetworkBuilder(builder: (context, status) => status.isOnline ? child : offlineBanner)
//
// Sources: Android ConnectivityManager (VALIDATED, metered, roaming, bandwidth),
// Apple NWPathMonitor (+ CoreTelephony radio on iOS), Windows Network List Manager
// + IP Helper, Linux GNetworkMonitor + kernel interfaces, and on the web
// navigator.onLine + the Network Information API.
//
// Going offline is confirmed for [UConnectivity.offlineGrace] before it is reported,
// so a Wi-Fi → LTE handoff never flashes an "offline" banner. Coming online is
// reported immediately.
// =============================================================================

/// Connection kind: wifi, cellular, ethernet, vpn, bluetooth, satellite, other.
enum UNetworkType { wifi, cellular, ethernet, vpn, bluetooth, usb, satellite, other }

/// Network snapshot: types, metered, roaming, speed, captive portal… (see UNetwork).
@immutable
class UNetworkStatus {
  const UNetworkStatus({
    this.types = const <UNetworkType>{},
    this.connected = false,
    this.internet,
    this.captivePortal = false,
    this.metered = false,
    this.constrained = false,
    this.roaming,
    this.cellularGeneration,
    this.downlinkKbps,
    this.uplinkKbps,
    this.rttMs,
    this.signalStrength,
    this.interfaceName,
  });

  /// Reads it from the native map.
  factory UNetworkStatus.fromMap(Map<String, Object?> map) => UNetworkStatus(
    types: <UNetworkType>{
      for (final String t in map.strings("types")) UNetworkType.values.firstWhere((UNetworkType v) => v.name == t, orElse: () => UNetworkType.other),
    },
    connected: map.flag("connected") ?? false,
    internet: map.flag("internet"),
    captivePortal: map.flag("captivePortal") ?? false,
    metered: map.flag("metered") ?? false,
    constrained: map.flag("constrained") ?? false,
    roaming: map.flag("roaming"),
    cellularGeneration: map.str("cellular"),
    downlinkKbps: map.integer("downKbps"),
    uplinkKbps: map.integer("upKbps"),
    rttMs: map.integer("rttMs"),
    signalStrength: map.integer("signal"),
    interfaceName: map.str("interface"),
  );

  /// Before the first native snapshot arrives. Treated as online so nothing blocks on startup.
  static const UNetworkStatus unknown = UNetworkStatus(connected: true);

  /// No network at all.
  static const UNetworkStatus offline = UNetworkStatus(internet: false);

  /// Every transport the active network uses (a VPN over Wi-Fi reports both).
  final Set<UNetworkType> types;

  /// A network with a route out exists.
  final bool connected;

  /// The OS verified it reaches the internet (Android VALIDATED, Linux FULL, Windows
  /// NLM internet). Null when the platform cannot tell; use [UConnectivity.hasInternet] then.
  final bool? internet;

  /// Behind a sign-in page (hotel / airport Wi-Fi): connected but not usable yet.
  final bool captivePortal;

  /// The user pays per byte (cellular, hotspot, a Wi-Fi marked metered).
  final bool metered;

  /// Data Saver (Android) / Low Data Mode (iOS) / browser "save-data" is on.
  final bool constrained;

  /// Roaming (null when unknown).
  final bool? roaming;

  /// "2g", "3g", "4g" or "5g" for cellular; on the web the effective type ("slow-2g" … "4g").
  final String? cellularGeneration;

  /// Estimated bandwidth, when the platform provides it.
  final int? downlinkKbps;

  /// Upload speed estimate.
  final int? uplinkKbps;

  /// Estimated round-trip time (web).
  final int? rttMs;

  /// Signal strength in dBm (Android 10+).
  final int? signalStrength;

  /// Name of the interface carrying the default route (wlan0, en0, …), when known.
  final String? interfaceName;

  /// A network is connected.
  bool get isOnline => connected && internet != false && !captivePortal;

  /// No network.
  bool get isOffline => !isOnline;

  /// On Wi-Fi.
  bool get isWifi => types.contains(UNetworkType.wifi);

  /// On mobile data.
  bool get isCellular => types.contains(UNetworkType.cellular);

  /// On a cable.
  bool get isEthernet => types.contains(UNetworkType.ethernet);

  /// VPN active.
  bool get isVpn => types.contains(UNetworkType.vpn);

  /// Bluetooth tethering.
  bool get isBluetooth => types.contains(UNetworkType.bluetooth);

  /// Suitable for large transfers: online, not metered and not in a data-saving mode.
  bool get isUnmetered => isOnline && !metered && !constrained;

  /// The transport carrying traffic; VPN only when it is the sole transport.
  UNetworkType? get primary {
    for (final UNetworkType t in const <UNetworkType>[
      UNetworkType.ethernet,
      UNetworkType.wifi,
      UNetworkType.cellular,
      UNetworkType.satellite,
      UNetworkType.bluetooth,
      UNetworkType.usb,
      UNetworkType.other,
      UNetworkType.vpn,
    ]) {
      if (types.contains(t)) return t;
    }
    return null;
  }

  /// Good enough for video / big downloads by the platform's own estimate.
  bool get isFast {
    if (!isOnline) return false;
    if (downlinkKbps != null) return downlinkKbps! >= 5000;
    return switch (cellularGeneration) {
      "slow-2g" || "2g" || "3g" => false,
      _ => true,
    };
  }

  /// As a map.
  Map<String, Object?> toMap() => <String, Object?>{
    "types": types.map((UNetworkType t) => t.name).toList(),
    "connected": connected,
    "internet": internet,
    "captivePortal": captivePortal,
    "metered": metered,
    "constrained": constrained,
    "roaming": roaming,
    "cellular": cellularGeneration,
    "downKbps": downlinkKbps,
    "upKbps": uplinkKbps,
    "rttMs": rttMs,
    "signal": signalStrength,
    "interface": interfaceName,
  };

  @override
  bool operator ==(Object other) =>
      other is UNetworkStatus &&
      setEquals(other.types, types) &&
      other.connected == connected &&
      other.internet == internet &&
      other.captivePortal == captivePortal &&
      other.metered == metered &&
      other.constrained == constrained &&
      other.roaming == roaming &&
      other.cellularGeneration == cellularGeneration &&
      other.downlinkKbps == downlinkKbps &&
      other.uplinkKbps == uplinkKbps &&
      other.rttMs == rttMs &&
      other.signalStrength == signalStrength &&
      other.interfaceName == interfaceName;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(types),
    connected,
    internet,
    captivePortal,
    metered,
    constrained,
    roaming,
    cellularGeneration,
    downlinkKbps,
    uplinkKbps,
    rttMs,
    signalStrength,
    interfaceName,
  );

  @override
  String toString() => "UNetworkStatus(${isOnline ? "online" : "offline"}, ${types.map((UNetworkType t) => t.name).join("+")}${metered ? ", metered" : ""})";
}

/// A local IP address of this device.
@immutable
class UNetworkAddress {
  const UNetworkAddress({required this.interfaceName, required this.address, required this.isIPv6, required this.isLoopback, required this.isLinkLocal});

  /// Interface, e.g. "wlan0".
  final String interfaceName;

  /// IP address.
  final String address;

  /// True for IPv6.
  final bool isIPv6;

  /// True for 127.0.0.1 / ::1.
  final bool isLoopback;

  /// True for 169.254.x.x / fe80::.
  final bool isLinkLocal;

  @override
  String toString() => "$interfaceName $address";
}

/// Engine behind UNetwork; use UNetwork instead.
abstract final class UConnectivity {
  static final ValueNotifier<UNetworkStatus> _status = ValueNotifier<UNetworkStatus>(UNetworkStatus.unknown);
  static final StreamController<UNetworkStatus> _changes = StreamController<UNetworkStatus>.broadcast();
  static Future<void>? _init;
  static StreamSubscription<Map<String, Object?>>? _native;
  static void Function()? _web;
  static Timer? _grace;

  /// How long "offline" must persist before it is reported. Zero reports every blip.
  static Duration offlineGrace = const Duration(milliseconds: 800);

  /// Checked by [hasInternet], first answer wins. Put your own API first: it is the one
  /// host that matters, and it is reachable on networks that filter public probes.
  /// Defaults to `U.baseUrl` followed by two public 204 endpoints.
  static List<Uri>? probeUrls;

  /// How long a [hasInternet] answer is reused.
  static Duration probeCacheDuration = const Duration(seconds: 5);

  /// Starts listening. Idempotent; `initU()` calls it for you.
  static Future<void> init() => _init ??= _initialize();

  static Future<void> _initialize() async {
    if (kIsWeb) {
      _set(UNetworkStatus.fromMap(UWebBridge.networkStatus()));
      _web = UWebBridge.listenNetwork((Map<String, Object?> m) => _apply(UNetworkStatus.fromMap(m)));
      return;
    }
    final Map<String, Object?> network = (await UDeviceChannel.bootstrap()).child("network");
    if (network.isNotEmpty) _set(UNetworkStatus.fromMap(network));
    _native = UDeviceChannel.networkEvents().listen(
      (Map<String, Object?> m) => _apply(UNetworkStatus.fromMap(m)),
      onError: (Object e) => debugPrint("UConnectivity: network events failed ($e)."),
    );
  }

  /// Current state, updated live. Before [init] completes it reads as online.
  static UNetworkStatus get status => _status.value;

  /// For `ValueListenableBuilder` / `AnimatedBuilder`.
  static ValueListenable<UNetworkStatus> get listenable => _status;

  /// Every change of [status].
  static Stream<UNetworkStatus> get stream => _changes.stream;

  /// Emits only when online ↔ offline flips.
  static Stream<bool> get onlineStream => _changes.stream.map((UNetworkStatus s) => s.isOnline).distinct();

  /// Same as UNetwork.listen.
  static StreamSubscription<UNetworkStatus> listen(void Function(UNetworkStatus status) onChange) => _changes.stream.listen(onChange);

  /// Same as UNetwork.isOnline.
  static bool get isOnline => status.isOnline;

  /// Same as UNetwork.isOffline.
  static bool get isOffline => status.isOffline;

  /// Same as UNetwork.isWifi.
  static bool get isWifi => status.isWifi;

  /// Same as UNetwork.isCellular.
  static bool get isCellular => status.isCellular;

  /// Same as UNetwork.isEthernet.
  static bool get isEthernet => status.isEthernet;

  /// Same as UNetwork.isVpn.
  static bool get isVpn => status.isVpn;

  /// Same as UNetwork.isMetered.
  static bool get isMetered => status.metered;

  /// Asks the OS again right now, skipping [offlineGrace].
  static Future<UNetworkStatus> refresh() async {
    await init();
    final Map<String, Object?>? map = kIsWeb ? UWebBridge.networkStatus() : await UDeviceChannel.network();
    if (map != null && map.isNotEmpty) {
      _grace?.cancel();
      _grace = null;
      _set(UNetworkStatus.fromMap(map));
    }
    return status;
  }

  /// Completes as soon as the device is online (immediately if it already is).
  /// Throws [TimeoutException] after [timeout], when given.
  static Future<void> whenOnline({Duration? timeout}) {
    if (isOnline) return Future<void>.value();
    final Future<void> online = onlineStream.firstWhere((bool v) => v);
    return timeout == null ? online : online.timeout(timeout);
  }

  static bool? _probeResult;
  static DateTime? _probeAt;
  static Future<bool>? _probing;

  /// Whether the internet (by default: your own API) actually answers. Any HTTP response
  /// counts, since a 401 still proves the round trip works. Cached for [probeCacheDuration].
  static Future<bool> hasInternet({bool force = false, Duration timeout = const Duration(seconds: 5)}) {
    if (!status.connected) return Future<bool>.value(false);
    final DateTime? at = _probeAt;
    if (!force && at != null && _probeResult != null && DateTime.now().difference(at) < probeCacheDuration) return Future<bool>.value(_probeResult);
    return _probing ??= _probe(timeout)
        .then((bool ok) {
          _probeResult = ok;
          _probeAt = DateTime.now();
          return ok;
        })
        .whenComplete(() => _probing = null);
  }

  static List<Uri> _defaultProbes() {
    String base = "";
    try {
      base = U.baseUrl;
    } catch (_) {}
    return <Uri>[
      if (base.isNotEmpty) ?Uri.tryParse(base),
      Uri.parse("https://www.gstatic.com/generate_204"),
      Uri.parse("https://cp.cloudflare.com/generate_204"),
    ];
  }

  static Future<bool> _probe(Duration timeout) {
    final List<Uri> urls = probeUrls ?? _defaultProbes();
    if (urls.isEmpty) return Future<bool>.value(status.isOnline);
    final Completer<bool> result = Completer<bool>();
    int remaining = urls.length;
    for (final Uri url in urls) {
      unawaited(
        _reach(url, timeout).then((bool ok) {
          remaining--;
          if (result.isCompleted) return;
          if (ok) {
            result.complete(true);
          } else if (remaining == 0) {
            result.complete(false);
          }
        }),
      );
    }
    return result.future;
  }

  static Future<bool> _reach(Uri url, Duration timeout) async {
    if (kIsWeb) return UWebBridge.probe(url.toString(), timeout.inMilliseconds);
    final http.Client client = http.Client();
    try {
      await client.head(url).timeout(timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// This device's IP addresses (empty on the web). Loopback is skipped unless [includeLoopback].
  static Future<List<UNetworkAddress>> addresses({bool includeLoopback = false}) async {
    if (kIsWeb) return const <UNetworkAddress>[];
    final List<NetworkInterface> interfaces = await NetworkInterface.list(includeLoopback: includeLoopback, includeLinkLocal: true);
    return <UNetworkAddress>[
      for (final NetworkInterface i in interfaces)
        for (final InternetAddress a in i.addresses)
          UNetworkAddress(interfaceName: i.name, address: a.address, isIPv6: a.type == InternetAddressType.IPv6, isLoopback: a.isLoopback, isLinkLocal: a.isLinkLocal),
    ];
  }

  /// The first non-loopback IPv4 address (the one other devices on the LAN would use).
  static Future<String?> localIp() async {
    final List<UNetworkAddress> all = await addresses();
    for (final UNetworkAddress a in all) {
      if (!a.isIPv6 && !a.isLinkLocal) return a.address;
    }
    return all.isEmpty ? null : all.first.address;
  }

  static void _apply(UNetworkStatus next) {
    _grace?.cancel();
    _grace = null;
    if (next.isOffline && status.isOnline && offlineGrace > Duration.zero) {
      _grace = Timer(offlineGrace, () {
        _grace = null;
        _set(next);
      });
      return;
    }
    _set(next);
  }

  static void _set(UNetworkStatus next) {
    if (next == _status.value) return;
    if (next.isOnline != _status.value.isOnline) _probeAt = null;
    _status.value = next;
    _changes.add(next);
  }

  /// Stops listening (tests, or an app that never needs network state again).
  static Future<void> dispose() async {
    _grace?.cancel();
    _web?.call();
    _web = null;
    await _native?.cancel();
    _native = null;
    _init = null;
  }
}

/// Rebuilds whenever the network state changes.
///
/// ```dart
/// UNetworkBuilder(builder: (context, status) => status.isOnline ? const Feed() : const OfflineView())
/// ```
class UNetworkBuilder extends StatelessWidget {
  const UNetworkBuilder({required this.builder, super.key});

  /// Builds the widget from the current network status.
  final Widget Function(BuildContext context, UNetworkStatus status) builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UNetworkStatus>(
    valueListenable: UConnectivity.listenable,
    builder: (BuildContext context, UNetworkStatus status, Widget? _) => builder(context, status),
  );
}
