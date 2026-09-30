import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// ULocalStorage (key/value) and UNetwork.
class StoragePage extends StatelessWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Storage & network",
    children: <Widget>[
      DemoGroup("Basic values", <Widget>[
        Fn("ULocalStorage.init()", ULocalStorage.init),
        Fn('ULocalStorage.set("name", "Sina")', () => ULocalStorage.set("name", "Sina")),
        Fn('ULocalStorage.getString("name")', () => ULocalStorage.getString("name")),
        Fn('ULocalStorage.set("count", 3); getInt', () {
          ULocalStorage.set("count", 3);
          return ULocalStorage.getInt("count");
        }),
        Fn('ULocalStorage.set("ok", true); getBool', () {
          ULocalStorage.set("ok", true);
          return ULocalStorage.getBool("ok");
        }),
        Fn('ULocalStorage.set("pi", 3.14); getDouble', () {
          ULocalStorage.set("pi", 3.14);
          return ULocalStorage.getDouble("pi");
        }),
        Fn('ULocalStorage.set("tags", [..]); getStringList', () {
          ULocalStorage.set("tags", <String>["a", "b"]);
          return ULocalStorage.getStringList("tags");
        }),
        Fn('ULocalStorage.set("otp", "1234", expireTime: 5.seconds)', () {
          ULocalStorage.set("otp", "1234", expireTime: 5.seconds);
          return ULocalStorage.ttlOf("otp");
        }),
        Fn('ULocalStorage.getString("secret", encryptKeyIv: …)', () {
          const (String, String) keyIv = ("01234567890123456789012345678901", "0123456789012345");
          ULocalStorage.set("secret", "hidden", encryptKeyIv: keyIv);
          return ULocalStorage.getString("secret", encryptKeyIv: keyIv);
        }),
        Fn('ULocalStorage.containsKey("name")', () => ULocalStorage.containsKey("name")),
        Fn("ULocalStorage.getKeys()", ULocalStorage.getKeys),
        Fn("ULocalStorage.length / isEmpty", () => <Object>[ULocalStorage.length, ULocalStorage.isEmpty]),
        Fn("ULocalStorage.getAll()", ULocalStorage.getAll),
        Fn('ULocalStorage.remove("name")', () => ULocalStorage.remove("name")),
      ]),
      DemoGroup("Typed values & models", <Widget>[
        Fn('setAndWait("seen", DateTime.now()); getDateTime', () async {
          await ULocalStorage.setAndWait("seen", DateTime.now());
          return ULocalStorage.getDateTime("seen");
        }),
        Fn('set("timeout", 90.seconds); getDuration', () {
          ULocalStorage.set("timeout", 90.seconds);
          return ULocalStorage.getDuration("timeout");
        }),
        Fn('set("raw", bytes); getBytes', () {
          ULocalStorage.set("raw", Uint8List.fromList(<int>[1, 2, 3]));
          return ULocalStorage.getBytes("raw");
        }),
        Fn('set("user", map); getMap', () {
          ULocalStorage.set("user", <String, dynamic>{"id": 1, "name": "Sina"});
          return ULocalStorage.getMap("user");
        }),
        Fn('set("list", […]); getList', () {
          ULocalStorage.set("list", <int>[1, 2, 3]);
          return ULocalStorage.getList("list");
        }),
        Fn('set("mode", ThemeMode.dark); getEnum', () {
          ULocalStorage.set("mode", ThemeMode.dark);
          return ULocalStorage.getEnum("mode", ThemeMode.values);
        }),
        Fn('getObject("user", (j) => j["name"])', () => ULocalStorage.getObject<String>("user", (Map<String, dynamic> j) => j["name"] as String)),
        Fn('set("users", [..]); getObjects', () {
          ULocalStorage.set("users", <Map<String, dynamic>>[
            <String, dynamic>{"name": "A"},
            <String, dynamic>{"name": "B"},
          ]);
          return ULocalStorage.getObjects<String>("users", (Map<String, dynamic> j) => j["name"] as String);
        }),
        Fn("ULocalStorage.get<int>('count')", () => ULocalStorage.get<int>("count")),
        Fn("ULocalStorage.getOr<int>('volume', 50)", () => ULocalStorage.getOr<int>("volume", 50)),
        Fn("ULocalStorage.setAll({...})", () => ULocalStorage.setAll(<String, Object?>{"a": 1, "b": 2})),
        Fn("ULocalStorage.increment('opens')", () => ULocalStorage.increment("opens")),
        Fn("ULocalStorage.update<int>('score', (v) => (v ?? 0) + 10)", () async {
          await ULocalStorage.update<int>("score", (int? v) => (v ?? 0) + 10);
          return ULocalStorage.getInt("score");
        }),
        Fn("ULocalStorage.expire('score', 1.minutes)", () => ULocalStorage.expire("score", 1.minutes)),
        Fn("ULocalStorage.removeAll(['a', 'b'])", () => ULocalStorage.removeAll(<String>["a", "b"])),
        Fn("ULocalStorage.removeWhere((k, v) => k.startsWith('tmp'))", () => ULocalStorage.removeWhere((String k, Object v) => k.startsWith("tmp"))),
        Fn("ULocalStorage.flush()", ULocalStorage.flush),
      ]),
      DemoGroup("Watching changes", <Widget>[
        Demo(
          "ValueListenableBuilder(valueListenable: ULocalStorage.listenable<int>('opens'), …)",
          child: ValueListenableBuilder<int?>(valueListenable: ULocalStorage.listenable<int>("opens"), builder: (BuildContext c, int? v, Widget? _) => Text("opens = ${v ?? 0}")),
        ),
        Fn("ULocalStorage.watch<int>('opens')", () => ULocalStorage.watch<int>("opens")),
        Fn("ULocalStorage.changes (first change)", () {
          Future<void>.delayed(200.ms, () => ULocalStorage.increment("opens"));
          return ULocalStorage.changes.first.timeout(3.seconds);
        }),
        Fn("ULocalStorage.secureChanges (first change)", () {
          Future<void>.delayed(200.ms, () => ULocalStorage.setSecure("pin", "${Random().nextInt(9999)}"));
          return ULocalStorage.secureChanges.first.timeout(3.seconds);
        }),
      ]),
      DemoGroup("Auth, theme, language", <Widget>[
        Fn("ULocalStorage.setToken('demo'); getToken()", () {
          ULocalStorage.setToken("demo-token");
          return ULocalStorage.getToken();
        }),
        Fn("ULocalStorage.hasToken()", ULocalStorage.hasToken),
        Fn("ULocalStorage.setRefreshToken / getRefreshToken", () {
          ULocalStorage.setRefreshToken("refresh");
          return ULocalStorage.getRefreshToken();
        }),
        Fn("ULocalStorage.setRefreshTokenExpiresAt / get…", () {
          ULocalStorage.setRefreshTokenExpiresAt(DateTime.now().add(7.days));
          return ULocalStorage.getRefreshTokenExpiresAt();
        }),
        Fn("ULocalStorage.setUserId / getUserId", () {
          ULocalStorage.setUserId("42");
          return ULocalStorage.getUserId();
        }),
        Fn("ULocalStorage.getLocale() / setLocale", () {
          ULocalStorage.setLocale(ULocalStorage.getLocale() ?? "fa");
          return ULocalStorage.getLocale();
        }),
        Fn("ULocalStorage.isDarkMode() / setDarkMode", () {
          ULocalStorage.setDarkMode(ULocalStorage.isDarkMode());
          return ULocalStorage.isDarkMode();
        }),
      ]),
      DemoGroup("Encrypted & separate stores", <Widget>[
        Fn("ULocalStorage.setSecure('pin', '1234')", () => ULocalStorage.setSecure("pin", "1234")),
        Fn("ULocalStorage.getSecure<String>('pin')", () => ULocalStorage.getSecure<String>("pin")),
        Fn("ULocalStorage.containsSecure('pin')", () => ULocalStorage.containsSecure("pin")),
        Fn("ULocalStorage.removeSecure('pin')", () => ULocalStorage.removeSecure("pin")),
        Fn("ULocalStorage.clearSecure()", () => UNavigator.confirmAsync(title: "Clear secure?", message: "Also removes the login token.").then((bool ok) => ok ? ULocalStorage.clearSecure() : null)),
        Fn("await ULocalStorage.openStore('cache')", () async => (await ULocalStorage.openStore("cache")).length),
        Fn("ULocalStorage.store('cache').set('k', 1)", () => ULocalStorage.store("cache").set("k", 1)),
        Fn("ULocalStorage.deleteStore('cache')", () => ULocalStorage.deleteStore("cache")),
        Fn("ULocalStorage.clear()", () => UNavigator.confirmAsync(title: "Clear all?", message: "Deletes every saved value.").then((bool ok) => ok ? ULocalStorage.clear() : null)),
      ]),
      DemoGroup("Network", <Widget>[
        Fn("UNetwork.isOnline / isOffline", () => <bool>[UNetwork.isOnline, UNetwork.isOffline], auto: true),
        Fn("UNetwork.type / types", () => <Object?>[UNetwork.type, UNetwork.types], auto: true),
        Fn("UNetwork.status", () => UNetwork.status),
        Fn("isWifi / isCellular / isEthernet / isVpn / isBluetooth", () => <bool>[UNetwork.isWifi, UNetwork.isCellular, UNetwork.isEthernet, UNetwork.isVpn, UNetwork.isBluetooth]),
        Fn("isMetered / isUnmetered / isConstrained / isRoaming", () => <bool?>[UNetwork.isMetered, UNetwork.isUnmetered, UNetwork.isConstrained, UNetwork.isRoaming]),
        Fn("isBehindCaptivePortal / isFast", () => <bool>[UNetwork.isBehindCaptivePortal, UNetwork.isFast]),
        Fn(
          "cellularGeneration / downlinkKbps / uplinkKbps / rttMs / signalStrength",
          () => <Object?>[UNetwork.cellularGeneration, UNetwork.downlinkKbps, UNetwork.uplinkKbps, UNetwork.rttMs, UNetwork.signalStrength],
        ),
        Fn("UNetwork.interfaceName", () => UNetwork.interfaceName),
        Fn("await UNetwork.hasInternet()", UNetwork.hasInternet),
        Fn("await UNetwork.refresh()", UNetwork.refresh),
        Fn("await UNetwork.whenOnline(timeout: 3.seconds)", () => UNetwork.whenOnline(timeout: 3.seconds)),
        Fn("await UNetwork.addresses()", UNetwork.addresses),
        Fn("await UNetwork.localIp()", UNetwork.localIp),
        Fn("UNetwork.stream / onlineStream", () => UNetwork.onlineStream),
        Fn("UNetwork.stream (first)", () => UNetwork.stream.first.timeout(2.seconds, onTimeout: () => UNetwork.status)),
        Demo(
          "ValueListenableBuilder(valueListenable: UNetwork.listenable, …)",
          child: ValueListenableBuilder<UNetworkStatus>(valueListenable: UNetwork.listenable, builder: (BuildContext c, UNetworkStatus s, Widget? _) => Text("${s.primary}")),
        ),
        Fn("UNetwork.listen((s) => …)", () {
          final StreamSubscription<UNetworkStatus> sub = UNetwork.listen((UNetworkStatus s) {});
          sub.cancel();
          return "listening works";
        }),
        Fn("UNetwork.init()", UNetwork.init),
        Fn("UNetwork.probeUrls = […]", () {
          final List<Uri>? before = UNetwork.probeUrls;
          UNetwork.probeUrls = <Uri>[Uri.parse("https://www.google.com")];
          UNetwork.probeUrls = before;
          return before;
        }),
        Fn("UNetwork.offlineGrace = 2.seconds", () {
          final Duration before = UNetwork.offlineGrace;
          UNetwork.offlineGrace = before;
          return before;
        }),
      ]),
    ],
  );
}
