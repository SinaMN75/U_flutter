import "package:u/utilities.dart";

/// Opens URLs, apps, settings, stores, maps, messengers and compose screens; OAuth sign-in; deep links.
/// Wraps [ULaunchChannel] (lib/plugins/launch).
abstract final class ULaunch {
  /// Opens [url] in the browser or the app that handles it; false if nothing can.
  static Future<bool> url(String url, {ULaunchMode mode = ULaunchMode.platformDefault, Map<String, String> headers = const <String, String>{}}) =>
      ULaunchChannel.open(url, mode: mode, headers: headers);

  /// Opens [url] in the in-app browser (Custom Tabs / Safari view), tinted with [toolbarColor].
  static Future<bool> inApp(String url, {Color? toolbarColor, Color? controlColor, bool showTitle = true, bool readerMode = false}) =>
      ULaunchChannel.open(url, mode: ULaunchMode.inApp, toolbarColor: toolbarColor?.toARGB32(), controlColor: controlColor?.toARGB32(), showTitle: showTitle, readerMode: readerMode);

  /// Opens [url] in the browser, never inside the app.
  static Future<bool> external(String url) => ULaunchChannel.open(url, mode: ULaunchMode.external);

  /// Opens [url] only in a native app that handles it (not a browser); false if none.
  static Future<bool> nativeApp(String url) => ULaunchChannel.open(url, mode: ULaunchMode.nonBrowser);

  /// Opens [url] in a specific Android app ([package]); falls back to any app.
  static Future<bool> withPackage(String url, String package) => ULaunchChannel.open(url, androidPackage: package);

  /// Closes the in-app browser.
  static Future<bool> closeInApp() => ULaunchChannel.closeInApp();

  /// Emits when the user closes the in-app browser.
  static Stream<void> get onInAppClosed => ULaunchChannel.inAppClosed;

  /// True when something on the device can open [url].
  static Future<bool> canOpen(String url) => ULaunchChannel.canOpen(url);

  /// True when an app is installed (Android package name, iOS/Windows URL scheme, macOS bundle id).
  static Future<bool> isInstalled(String id) => ULaunchChannel.isInstalled(id);

  /// Launches an installed app (Android package name, iOS/Windows URL scheme, macOS bundle id).
  static Future<bool> openApp(String id) => ULaunchChannel.openApp(id);

  /// Opens a system settings page (falls back to this app's settings where a page does not exist).
  static Future<bool> settings([USettingsPage page = USettingsPage.app, String? channelId]) => ULaunchChannel.openSettings(page, channelId: channelId);

  /// Opens an email draft; attachments work on Android, iOS, macOS and Windows.
  static Future<UComposeResult> email({
    List<String> to = const <String>[],
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    String? subject,
    String? body,
    bool isHtml = false,
    List<String> attachments = const <String>[],
  }) => ULaunchChannel.email(to: to, cc: cc, bcc: bcc, subject: subject, body: body, isHtml: isHtml, attachments: attachments);

  /// Opens an SMS draft to one or more numbers (attachments on iOS).
  static Future<UComposeResult> sms(List<String> to, {String? body, List<String> attachments = const <String>[]}) => ULaunchChannel.sms(to: to, body: body, attachments: attachments);

  /// Opens the dialer with [number] (USSD codes like *140# work).
  static Future<bool> call(String number) => ULaunchChannel.call(number);

  /// Opens a chat in WhatsApp, Telegram, Eitaa, Rubika, Bale, Soroush, Instagram or X.
  static Future<bool> chat(UMessenger messenger, String target, {String? text}) => ULaunchChannel.openChat(messenger, target, text: text);

  /// Shows a place in a map app (Neshan, Balad, Google, Waze, Apple Maps or the default).
  static Future<bool> map(double latitude, double longitude, {String? label, UMapApp app = UMapApp.system}) => ULaunchChannel.showOnMap(latitude, longitude, label: label, app: app);

  /// Starts navigation to a place in a map app.
  static Future<bool> directions(double latitude, double longitude, {UMapApp app = UMapApp.system, UTravelMode mode = UTravelMode.driving}) =>
      ULaunchChannel.directions(latitude, longitude, app: app, mode: mode);

  /// Opens this app's page in its store (auto-detects Play, Bazaar, Myket, …); [review] opens the rating page.
  static Future<bool> store({UAppStore store = UAppStore.auto, String? appId, bool review = false}) => ULaunchChannel.openStore(store: store, appId: appId, review: review);

  /// Shows the native in-app rating dialog (iOS, macOS); elsewhere opens the store's rating page.
  static Future<bool> requestReview({String? appId}) async => await ULaunchChannel.requestReview() || await ULaunchChannel.openStore(appId: appId, review: true);

  /// Opens a sign-in page and returns the redirect URL to [callbackScheme] (null if cancelled).
  static Future<Uri?> authenticate(String url, {required String callbackScheme, bool ephemeral = false, Duration timeout = const Duration(minutes: 5)}) =>
      ULaunchChannel.authenticate(url, callbackScheme: callbackScheme, ephemeral: ephemeral, timeout: timeout);

  /// The deep link that launched the app (null if none).
  static Future<Uri?> initialLink() => ULaunchChannel.initialLink();

  /// Deep links received while the app runs.
  static Stream<Uri> get links => ULaunchChannel.links;

  /// Calls [onLink] with the launch link and every later deep link.
  static Future<StreamSubscription<Uri>> onLink(void Function(Uri link) onLink) async {
    final StreamSubscription<Uri> subscription = links.listen(onLink);
    final Uri? first = await initialLink();
    if (first != null && !(kIsWeb && first == Uri.base)) onLink(first);
    return subscription;
  }
}
