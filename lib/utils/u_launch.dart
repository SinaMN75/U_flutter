import "package:u/utilities.dart";

/// Opens URLs, apps, settings, stores, maps, messengers, email/SMS/call screens; OAuth sign-in; deep links. All 6 platforms, returns false instead of crashing. `ULaunch.url("https://x.com")`
abstract final class ULaunch {
  /// Opens [url] in the browser or the app that handles it (tel:, mailto:, geo:, myapp://…); false if nothing can. `await ULaunch.url("https://sinamn75.com")`
  static Future<bool> url(String url, {ULaunchMode mode = ULaunchMode.platformDefault, Map<String, String> headers = const <String, String>{}}) =>
      ULaunchChannel.open(url, mode: mode, headers: headers);

  /// Opens [url] inside the app: Custom Tabs (Android), Safari view (iOS), new tab (web); macOS/Windows/Linux use the browser. `ULaunch.inApp(url, toolbarColor: Colors.teal)`
  static Future<bool> inApp(String url, {Color? toolbarColor, Color? controlColor, bool showTitle = true, bool readerMode = false}) =>
      ULaunchChannel.open(url, mode: ULaunchMode.inApp, toolbarColor: toolbarColor?.toARGB32(), controlColor: controlColor?.toARGB32(), showTitle: showTitle, readerMode: readerMode);

  /// Opens [url] in the browser, never inside the app. `ULaunch.external(paymentUrl)`
  static Future<bool> external(String url) => ULaunchChannel.open(url, mode: ULaunchMode.external);

  /// Opens [url] only in a non-browser app (Android 11+, iOS universal links); false otherwise, so you can fall back. `if (!await ULaunch.nativeApp(url)) ULaunch.inApp(url)`
  static Future<bool> nativeApp(String url) => ULaunchChannel.open(url, mode: ULaunchMode.nonBrowser);

  /// Opens [url] in a specific Android app, e.g. "com.farsitel.bazaar"; other platforms ignore [package]. `ULaunch.withPackage(url, "org.telegram.messenger")`
  static Future<bool> withPackage(String url, String package) => ULaunchChannel.open(url, androidPackage: package);

  /// Closes the in-app browser opened by inApp() (Android, iOS); false elsewhere. `ULaunch.closeInApp()`
  static Future<bool> closeInApp() => ULaunchChannel.closeInApp();

  /// Fires when the user closes the in-app browser (iOS; Android when the app comes back). `ULaunch.onInAppClosed.listen((_) => refreshPayment())`
  static Stream<void> get onInAppClosed => ULaunchChannel.inAppClosed;

  /// True when something can open [url]. iOS needs the scheme listed: `dart run u:app query-schemes`. `await ULaunch.canOpen("tg://")`
  static Future<bool> canOpen(String url) => ULaunchChannel.canOpen(url);

  /// True when an app is installed: Android package, iOS/Windows URL scheme, macOS bundle id; always false on web. `ULaunch.isInstalled("com.whatsapp")` · iOS/Android: `dart run u:app query-schemes`
  static Future<bool> isInstalled(String id) => ULaunchChannel.isInstalled(id);

  /// Launches an installed app by the same id as isInstalled; false on web. `ULaunch.openApp("com.farsitel.bazaar")`
  static Future<bool> openApp(String id) => ULaunchChannel.openApp(id);

  /// Opens a system settings page (wifi, bluetooth, location, notifications…); falls back to this app's settings. Web: false. `ULaunch.settings(USettingsPage.location)`
  static Future<bool> settings([USettingsPage page = USettingsPage.app, String? channelId]) => ULaunchChannel.openSettings(page, channelId: channelId);

  /// Opens an email draft; attachments work on Android, iOS, macOS and Windows (not Linux/web). `ULaunch.email(to: ["a@b.com"], subject: "Hi", attachments: [path])`
  static Future<UComposeResult> email({
    List<String> to = const <String>[],
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    String? subject,
    String? body,
    bool isHtml = false,
    List<String> attachments = const <String>[],
  }) => ULaunchChannel.email(to: to, cc: cc, bcc: bcc, subject: subject, body: body, isHtml: isHtml, attachments: attachments);

  /// Opens an SMS draft to one or more numbers; attachments only on iOS; desktops open the phone link app. `ULaunch.sms(["09121234567"], body: "Code: 1234")`
  static Future<UComposeResult> sms(List<String> to, {String? body, List<String> attachments = const <String>[]}) => ULaunchChannel.sms(to: to, body: body, attachments: attachments);

  /// Opens the dialer with [number]; USSD like *140# works (Android/iOS; desktops need a phone app). `ULaunch.call("*140#")`
  static Future<bool> call(String number) => ULaunchChannel.call(number);

  /// Opens a chat in WhatsApp, Telegram, Eitaa, Rubika, Bale, Soroush, Instagram or X (app, else web). `ULaunch.chat(UMessenger.whatsapp, "+989121234567", text: "Hello")`
  static Future<bool> chat(UMessenger messenger, String target, {String? text}) => ULaunchChannel.openChat(messenger, target, text: text);

  /// Shows a place in Neshan, Balad, Google Maps, Waze, Apple Maps or the default map app (web: Google Maps). `ULaunch.map(35.7, 51.4, label: "Office", app: UMapApp.neshan)`
  static Future<bool> map(double latitude, double longitude, {String? label, UMapApp app = UMapApp.system}) => ULaunchChannel.showOnMap(latitude, longitude, label: label, app: app);

  /// Starts navigation to a place in the chosen map app. `ULaunch.directions(35.7, 51.4, app: UMapApp.waze)`
  static Future<bool> directions(double latitude, double longitude, {UMapApp app = UMapApp.system, UTravelMode mode = UTravelMode.driving}) =>
      ULaunchChannel.directions(latitude, longitude, app: app, mode: mode);

  /// Opens this app's store page (auto-detects Play, Bazaar, Myket, App Store, Microsoft Store, Flathub); [review] opens the rating tab. `ULaunch.store(review: true)`
  static Future<bool> store({UAppStore store = UAppStore.auto, String? appId, bool review = false}) => ULaunchChannel.openStore(store: store, appId: appId, review: review);

  /// Native rating popup on iOS/macOS (the OS may skip it); elsewhere opens the store rating page. `ULaunch.requestReview()`
  static Future<bool> requestReview({String? appId}) async => await ULaunchChannel.requestReview() || await ULaunchChannel.openStore(appId: appId, review: true);

  /// OAuth / SSO: opens [url] and returns the redirect to [callbackScheme], null if cancelled. Android/desktop custom schemes: `dart run u:app deep-link myapp`. `await ULaunch.authenticate(authUrl, callbackScheme: "myapp")`
  static Future<Uri?> authenticate(String url, {required String callbackScheme, bool ephemeral = false, Duration timeout = const Duration(minutes: 5)}) =>
      ULaunchChannel.authenticate(url, callbackScheme: callbackScheme, ephemeral: ephemeral, timeout: timeout);

  /// Deep link that launched the app, or null (web: the page URL). Needs `dart run u:app deep-link myapp`. `final Uri? link = await ULaunch.initialLink();`
  static Future<Uri?> initialLink() => ULaunchChannel.initialLink();

  /// Deep links that arrive while the app is running. `ULaunch.links.listen(openLink)`
  static Stream<Uri> get links => ULaunchChannel.links;

  /// Calls [onLink] for the launch link and every later one; the easy way to route deep links. `ULaunch.onLink((uri) => UNavigator.push(ProductPage(uri.pathSegments.last)))`
  static Future<StreamSubscription<Uri>> onLink(void Function(Uri link) onLink) async {
    final StreamSubscription<Uri> subscription = links.listen(onLink);
    final Uri? first = await initialLink();
    if (first != null && !(kIsWeb && first == Uri.base)) onLink(first);
    return subscription;
  }
}
