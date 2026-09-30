import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// ULaunch, UShare and UScreenGuard.
class LaunchSharePage extends StatefulWidget {
  const LaunchSharePage({super.key});

  @override
  State<LaunchSharePage> createState() => _LaunchSharePageState();
}

class _LaunchSharePageState extends State<LaunchSharePage> {
  final UWidgetToImageController _capture = UWidgetToImageController();
  StreamSubscription<Uri>? _links;
  StreamSubscription<UReceivedShare>? _shares;
  final List<String> _log = <String>[];

  @override
  void initState() {
    super.initState();
    ULaunch.onLink((Uri link) => setState(() => _log.add("link: $link"))).then((StreamSubscription<Uri> s) => _links = s);
    UShare.onReceive((UReceivedShare s) => setState(() => _log.add("share: ${s.text} ${s.files.length} files"))).then((StreamSubscription<UReceivedShare> s) => _shares = s);
    UScreenGuard.onScreenshot = () => UToast.warning(message: "Screenshot taken");
    UScreenGuard.onScreenRecording = (bool on) => UToast.info(message: "Recording: $on");
  }

  @override
  void dispose() {
    _links?.cancel();
    _shares?.cancel();
    UScreenGuard.onScreenshot = null;
    UScreenGuard.onScreenRecording = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Launch, share, screen guard",
    children: <Widget>[
      DemoGroup("Open", <Widget>[
        Fn('ULaunch.url("https://sinamn75.com")', () => ULaunch.url("https://sinamn75.com")),
        Fn("ULaunch.inApp(url, toolbarColor: …)", () => ULaunch.inApp("https://flutter.dev", toolbarColor: Colors.indigo), note: "Custom Tabs / Safari view; browser on desktop"),
        Fn("ULaunch.closeInApp()", ULaunch.closeInApp),
        Fn("ULaunch.onInAppClosed (first event)", () => ULaunch.onInAppClosed.first.timeout(const Duration(seconds: 5), onTimeout: () {})),
        Fn("ULaunch.external(url)", () => ULaunch.external("https://github.com")),
        Fn("ULaunch.nativeApp(url)", () => ULaunch.nativeApp("https://www.youtube.com"), note: "False when only a browser can open it"),
        Fn('ULaunch.withPackage(url, "org.telegram.messenger")', () => ULaunch.withPackage("https://t.me/flutterdev", "org.telegram.messenger"), note: "Android only"),
        Fn('ULaunch.canOpen("tg://")', () => ULaunch.canOpen("tg://")),
        Fn('ULaunch.isInstalled("com.whatsapp")', () => ULaunch.isInstalled("com.whatsapp")),
        Fn('ULaunch.openApp("com.farsitel.bazaar")', () => ULaunch.openApp("com.farsitel.bazaar")),
        Fn("ULaunch.settings(USettingsPage.notifications)", () => ULaunch.settings(USettingsPage.notifications)),
      ]),
      DemoGroup("Compose", <Widget>[
        Fn("ULaunch.email(to: […], subject: …)", () => ULaunch.email(to: <String>["hi@example.com"], subject: "Hello", body: "From the u example")),
        Fn('ULaunch.sms(["09121234567"], body: …)', () => ULaunch.sms(<String>["09121234567"], body: "Code: 1234")),
        Fn('ULaunch.call("*140#")', () => ULaunch.call("*140#")),
        Fn("ULaunch.chat(UMessenger.telegram, …)", () => ULaunch.chat(UMessenger.telegram, "@flutterdev", text: "Hi")),
      ]),
      DemoGroup("Maps & stores", <Widget>[
        Fn("ULaunch.map(35.6997, 51.3380, label: …)", () => ULaunch.map(35.6997, 51.3380, label: "Azadi Tower")),
        Fn("ULaunch.directions(…, app: UMapApp.google)", () => ULaunch.directions(35.6997, 51.3380, app: UMapApp.google)),
        Fn("ULaunch.store(review: true)", () => ULaunch.store(review: true)),
        Fn("ULaunch.requestReview()", ULaunch.requestReview),
      ]),
      DemoGroup("Sign-in & deep links", <Widget>[
        Fn(
          "ULaunch.authenticate(url, callbackScheme: …)",
          () => ULaunch.authenticate("https://example.com/oauth", callbackScheme: "uexample", timeout: const Duration(seconds: 20)),
          note: "Needs `dart run u:app deep-link uexample`",
        ),
        Fn("await ULaunch.initialLink()", ULaunch.initialLink),
        Fn("ULaunch.links (first event)", () => ULaunch.links.first.timeout(const Duration(seconds: 5), onTimeout: () => Uri())),
        Demo("ULaunch.onLink(…) / UShare.onReceive(…) log", child: Text(_log.isEmpty ? "nothing yet" : _log.join("\n"))),
      ]),
      DemoGroup("Share", <Widget>[
        Builder(builder: (BuildContext c) => Fn('UShare.text("Hello", origin: UShare.originOf(context))', () => UShare.text("Hello from u", origin: UShare.originOf(c)))),
        Fn("UShare.link(url, message: …)", () => UShare.link("https://sinamn75.com", message: "Check this")),
        Fn("UShare.bytes(bytes, name: …)", () => UShare.bytes(Uint8List.fromList(utf8.encode("hello")), name: "hello.txt")),
        Fn("UShare.file(path)", () async => UShare.file((await UFile.writeToFile(Uint8List.fromList(utf8.encode("file")), extension: "txt")).path), note: "Not on web"),
        Fn("UShare.files([a, b])", () async {
          final File a = await UFile.writeToFile(Uint8List.fromList(utf8.encode("a")), extension: "txt");
          final File b = await UFile.writeToFile(Uint8List.fromList(utf8.encode("b")), extension: "txt");
          return UShare.files(<String>[a.path, b.path]);
        }, note: "Not on web"),
        Fn(
          "UShare.share(text: …, files: […])",
          () => UShare.share(
            text: "Invoice",
            files: <UShareFile>[UShareFile.bytes(Uint8List.fromList(utf8.encode("x")), name: "x.txt")],
          ),
        ),
        Demo(
          "UShare.widgetImage(controller, name: …)",
          child: UColumn(
            spacing: 8,
            children: <Widget>[
              UWidgetToImage(
                controller: _capture,
                child: const UPill("Receipt #42", icon: Icons.receipt_long),
              ),
              Fn("share the pill above", () => UShare.widgetImage(_capture, name: "receipt.png")),
            ],
          ),
        ),
        Fn("UShare.to(UShareTarget.telegram, text: …)", () => UShare.to(UShareTarget.telegram, text: "Hi")),
        Fn("UShare.canShareTo(UShareTarget.whatsapp)", () => UShare.canShareTo(UShareTarget.whatsapp)),
        Fn("await UShare.initialReceived()", UShare.initialReceived, note: "Needs `dart run u:app share-target`"),
        Fn("UShare.received (first event)", () => UShare.received.first.timeout(const Duration(seconds: 5), onTimeout: () => UReceivedShare())),
      ]),
      DemoGroup("Screen guard", <Widget>[
        Fn("UScreenGuard.enable()", UScreenGuard.enable, note: "Android, iOS, macOS, Windows"),
        Fn("UScreenGuard.disable()", UScreenGuard.disable),
        Fn("UScreenGuard.set(enabled: true)", () => UScreenGuard.set(enabled: true)),
        Fn("UScreenGuard.isEnabled", () => UScreenGuard.isEnabled),
        Fn("UScreenGuard.onScreenshot / onScreenRecording set?", () => <bool>[UScreenGuard.onScreenshot != null, UScreenGuard.onScreenRecording != null], note: "iOS reports these"),
      ]),
    ],
  );
}
