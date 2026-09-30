import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:u/plugins/launch/u_launch_web_stub.dart" if (dart.library.js_interop) "package:u/plugins/launch/u_launch_web.dart";

// =============================================================================
// u_launch_channel — opening URLs, apps, settings, stores and compose screens,
// OAuth sign-in, and receiving deep links ("u/launch" + "u/launch/events").
//
//   Android  Intents; in-app browser through the Custom Tabs protocol (no androidx.browser)
//   iOS      UIApplication.open, SFSafariViewController, MessageUI, StoreKit review,
//            ASWebAuthenticationSession; links from the app delegate and the scene delegate
//   macOS    NSWorkspace, NSSharingService compose, StoreKit review, ASWebAuthenticationSession
//   Windows  ShellExecute, MAPI (mail with attachments), ms-settings:, links from argv
//   Linux    GIO default handlers (portal-aware), xdg-email, GNOME Settings panels, links from argv
//   Web      window.open, popup-based OAuth, the page URL as the initial link
//
// Every call returns false / null instead of throwing when the platform cannot do it.
// =============================================================================

enum ULaunchMode {
  /// http(s) in the browser, everything else in the app that handles it.
  platformDefault,

  /// Always leave the app (browser or handling app).
  external,

  /// In-app browser: Custom Tabs (Android), Safari view (iOS), new tab (web). External elsewhere.
  inApp,

  /// Only open if a non-browser app handles the link (Android 11+, iOS universal links); false otherwise.
  nonBrowser,
}

enum USettingsPage {
  app,
  notifications,
  notificationChannel,
  location,
  wifi,
  bluetooth,
  battery,
  display,
  sound,
  dateTime,
  language,
  security,
  nfc,
  dataUsage,
  accessibility,
  developer,
  storage,
  vpn,
  airplaneMode,
  apps,
  exactAlarms,
  overlay,
  allFilesAccess,
  installUnknownApps,
  usageAccess,
  defaultApps,
  fullScreenIntents,
}

enum UMapApp { system, google, apple, waze, neshan, balad }

enum UTravelMode { driving, walking, transit, cycling }

enum UAppStore { auto, googlePlay, bazaar, myket, galaxy, huawei, appStore, microsoft, flathub }

enum UMessenger { whatsapp, telegram, eitaa, rubika, bale, soroush, instagram, x }

enum UComposeResult { sent, saved, cancelled, failed, opened, unavailable }

abstract final class ULaunchChannel {
  static const MethodChannel _channel = MethodChannel("u/launch");
  static const EventChannel _events = EventChannel("u/launch/events");

  static final StreamController<Uri> _links = StreamController<Uri>.broadcast();
  static final StreamController<void> _closed = StreamController<void>.broadcast();
  static StreamSubscription<dynamic>? _subscription;
  static Future<Uri?>? _initial;

  static bool get _isNative => !kIsWeb;

  static Future<T?> _call<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint("u/launch.$method failed: ${e.code} ${e.message ?? ""}");
      return null;
    }
  }

  static void _listen() {
    if (_subscription != null || !_isNative) return;
    _subscription = _events.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;
        switch (event["type"]) {
          case "link":
            final Uri? uri = Uri.tryParse("${event["url"]}");
            if (uri != null) _links.add(uri);
          case "closed":
            _closed.add(null);
        }
      },
      onError: (Object e) => debugPrint("u/launch events failed: $e"),
    );
  }

  // --- Opening ---------------------------------------------------------------

  static Future<bool> open(
    String url, {
    ULaunchMode mode = ULaunchMode.platformDefault,
    Map<String, String> headers = const <String, String>{},
    String? androidPackage,
    int? toolbarColor,
    int? controlColor,
    bool showTitle = true,
    bool readerMode = false,
    String? webWindowName,
  }) async {
    if (kIsWeb) return ULaunchWeb.open(url, webWindowName ?? (mode == ULaunchMode.inApp || mode == ULaunchMode.external ? "_blank" : _webTarget(url)));
    _listen();
    return await _call<bool>("open", <String, Object?>{
          "url": url,
          "mode": mode.name,
          "headers": headers,
          "package": androidPackage,
          "toolbarColor": toolbarColor,
          "controlColor": controlColor,
          "showTitle": showTitle,
          "readerMode": readerMode,
        }) ??
        false;
  }

  static String _webTarget(String url) => url.startsWith("http") ? "_blank" : "_self";

  static Future<bool> canOpen(String url) async {
    if (kIsWeb) return ULaunchWeb.canOpen(url);
    return await _call<bool>("canOpen", <String, Object?>{"url": url}) ?? false;
  }

  static Future<bool> isInstalled(String id) async => !kIsWeb && (await _call<bool>("isInstalled", <String, Object?>{"id": id}) ?? false);

  static Future<bool> openApp(String id) async => !kIsWeb && (await _call<bool>("openApp", <String, Object?>{"id": id}) ?? false);

  static Future<bool> openSettings(USettingsPage page, {String? channelId}) async =>
      !kIsWeb && (await _call<bool>("openSettings", <String, Object?>{"page": page.name, "channelId": channelId}) ?? false);

  static Future<bool> closeInApp() async => !kIsWeb && (await _call<bool>("closeInApp") ?? false);

  static Stream<void> get inAppClosed {
    _listen();
    return _closed.stream;
  }

  // --- Compose ---------------------------------------------------------------

  static Future<UComposeResult> email({
    List<String> to = const <String>[],
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    String? subject,
    String? body,
    bool isHtml = false,
    List<String> attachments = const <String>[],
  }) async {
    final Uri mailto = Uri(
      scheme: "mailto",
      path: to.join(","),
      query: _query(<String, String?>{"cc": cc.isEmpty ? null : cc.join(","), "bcc": bcc.isEmpty ? null : bcc.join(","), "subject": subject, "body": body}),
    );
    if (kIsWeb) return await ULaunchWeb.open(mailto.toString(), "_self") ? UComposeResult.opened : UComposeResult.unavailable;
    final String? result = await _call<String>("email", <String, Object?>{
      "to": to,
      "cc": cc,
      "bcc": bcc,
      "subject": subject,
      "body": body,
      "html": isHtml,
      "attachments": attachments,
      "mailto": mailto.toString(),
    });
    return _compose(result);
  }

  static Future<UComposeResult> sms({required List<String> to, String? body, List<String> attachments = const <String>[]}) async {
    final bool apple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    // iOS separates the body with "&", everyone else with "?".
    final String url = "sms:${to.join(",")}${body == null ? "" : "${apple ? "&" : "?"}body=${Uri.encodeComponent(body)}"}";
    if (kIsWeb) return await ULaunchWeb.open(url, "_self") ? UComposeResult.opened : UComposeResult.unavailable;
    return _compose(await _call<String>("sms", <String, Object?>{"to": to, "body": body, "attachments": attachments, "url": url}));
  }

  static Future<bool> call(String number) {
    // '#' starts a URI fragment; USSD codes like *140# must encode it.
    final String cleaned = number.replaceAll(RegExp(r"[\s()-]"), "").replaceAll("#", "%23");
    return open("tel:$cleaned");
  }

  static UComposeResult _compose(String? raw) => UComposeResult.values.firstWhere((UComposeResult r) => r.name == raw, orElse: () => UComposeResult.unavailable);

  static String? _query(Map<String, String?> values) {
    final List<String> parts = <String>[
      for (final MapEntry<String, String?> e in values.entries)
        if (e.value != null && e.value!.isNotEmpty) "${e.key}=${Uri.encodeComponent(e.value!)}",
    ];
    return parts.isEmpty ? null : parts.join("&");
  }

  // --- Stores ----------------------------------------------------------------

  static Future<bool> openStore({UAppStore store = UAppStore.auto, String? appId, bool review = false}) async {
    if (kIsWeb) {
      final String? url = _storeWebUrl(store, appId);
      return url != null && await ULaunchWeb.open(url, "_blank");
    }
    return await _call<bool>("openStore", <String, Object?>{"store": store.name, "appId": appId, "review": review}) ?? false;
  }

  static String? _storeWebUrl(UAppStore store, String? appId) => switch (store) {
    _ when appId == null => null,
    UAppStore.appStore => "https://apps.apple.com/app/id$appId",
    UAppStore.bazaar => "https://cafebazaar.ir/app/$appId",
    UAppStore.myket => "https://myket.ir/app/$appId",
    UAppStore.microsoft => "https://apps.microsoft.com/detail/$appId",
    UAppStore.flathub => "https://flathub.org/apps/$appId",
    _ => "https://play.google.com/store/apps/details?id=$appId",
  };

  static Future<bool> requestReview() async => !kIsWeb && (await _call<bool>("requestReview") ?? false);

  // --- Maps and messengers -----------------------------------------------------

  static Future<bool> showOnMap(double latitude, double longitude, {String? label, UMapApp app = UMapApp.system}) {
    final String q = "$latitude,$longitude";
    final String named = label == null ? q : "$q(${Uri.encodeComponent(label)})";
    final String web = "https://www.google.com/maps/search/?api=1&query=$q";
    if (kIsWeb || Platform.isWindows || Platform.isLinux) return open(web);
    if (Platform.isAndroid) {
      return switch (app) {
        UMapApp.waze => open("https://waze.com/ul?ll=$q", androidPackage: "com.waze"),
        _ => open("geo:$q?q=$named", androidPackage: _androidMapPackage(app)),
      };
    }
    return switch (app) {
      UMapApp.google => _openFirst(<String>["comgooglemaps://?q=$q&center=$q", web]),
      UMapApp.waze => _openFirst(<String>["waze://?ll=$q", "https://waze.com/ul?ll=$q"]),
      _ => open("maps://?ll=$q&q=${Uri.encodeComponent(label ?? q)}"),
    };
  }

  static Future<bool> directions(double latitude, double longitude, {UMapApp app = UMapApp.system, UTravelMode mode = UTravelMode.driving}) {
    final String q = "$latitude,$longitude";
    final String googleMode = switch (mode) {
      UTravelMode.driving => "driving",
      UTravelMode.walking => "walking",
      UTravelMode.transit => "transit",
      UTravelMode.cycling => "bicycling",
    };
    final String web = "https://www.google.com/maps/dir/?api=1&destination=$q&travelmode=$googleMode";
    if (kIsWeb || Platform.isWindows || Platform.isLinux) return open(web);
    if (Platform.isAndroid) {
      return switch (app) {
        UMapApp.google => open("google.navigation:q=$q&mode=${mode == UTravelMode.walking ? "w" : (mode == UTravelMode.cycling ? "b" : "d")}", androidPackage: "com.google.android.apps.maps"),
        UMapApp.waze => open("https://waze.com/ul?ll=$q&navigate=yes", androidPackage: "com.waze"),
        _ => open("geo:$q?q=$q", androidPackage: _androidMapPackage(app)),
      };
    }
    final String appleMode = switch (mode) {
      UTravelMode.walking => "w",
      UTravelMode.transit => "r",
      _ => "d",
    };
    return switch (app) {
      UMapApp.google => _openFirst(<String>["comgooglemaps://?daddr=$q&directionsmode=$googleMode", web]),
      UMapApp.waze => _openFirst(<String>["waze://?ll=$q&navigate=yes", "https://waze.com/ul?ll=$q&navigate=yes"]),
      _ => open("maps://?daddr=$q&dirflg=$appleMode"),
    };
  }

  static String? _androidMapPackage(UMapApp app) => switch (app) {
    UMapApp.google => "com.google.android.apps.maps",
    UMapApp.neshan => "org.rajman.neshan.traffic.tehran",
    UMapApp.balad => "ir.balad",
    UMapApp.waze => "com.waze",
    _ => null,
  };

  static Future<bool> _openFirst(List<String> urls) async {
    for (final String url in urls) {
      if (await open(url, mode: ULaunchMode.external)) return true;
    }
    return false;
  }

  static Future<bool> openChat(UMessenger messenger, String target, {String? text}) {
    final String t = text == null ? "" : Uri.encodeComponent(text);
    final String digits = target.replaceAll(RegExp("[^0-9]"), "");
    final String url = switch (messenger) {
      UMessenger.whatsapp => "https://wa.me/$digits${t.isEmpty ? "" : "?text=$t"}",
      UMessenger.telegram => target.startsWith("+") ? "https://t.me/$target" : "https://t.me/${target.replaceFirst("@", "")}${t.isEmpty ? "" : "?text=$t"}",
      UMessenger.eitaa => "https://eitaa.com/${target.replaceFirst("@", "")}",
      UMessenger.rubika => "https://rubika.ir/${target.replaceFirst("@", "")}",
      UMessenger.bale => "https://ble.ir/${target.replaceFirst("@", "")}",
      UMessenger.soroush => "https://splus.ir/${target.replaceFirst("@", "")}",
      UMessenger.instagram => "https://instagram.com/${target.replaceFirst("@", "")}",
      UMessenger.x => "https://x.com/${target.replaceFirst("@", "")}",
    };
    return open(url, mode: ULaunchMode.external);
  }

  // --- OAuth -------------------------------------------------------------------

  /// Opens [url] for sign-in and returns the redirect back to [callbackScheme] (or null if cancelled).
  static Future<Uri?> authenticate(String url, {required String callbackScheme, bool ephemeral = false, Duration timeout = const Duration(minutes: 5)}) async {
    if (kIsWeb) return ULaunchWeb.authenticate(url, callbackScheme, timeout);
    if (Platform.isIOS || Platform.isMacOS) {
      final String? result = await _call<String>("authenticate", <String, Object?>{"url": url, "scheme": callbackScheme, "ephemeral": ephemeral});
      return result == null ? null : Uri.tryParse(result);
    }
    if ((Platform.isWindows || Platform.isLinux) && callbackScheme.startsWith("http://localhost")) return _loopback(url, Uri.parse(callbackScheme), timeout);
    // Android and desktop custom schemes: wait for the redirect to come back as a deep link.
    _listen();
    final Future<Uri?> redirect = _links.stream.firstWhere((Uri u) => u.scheme == callbackScheme).then<Uri?>((Uri u) => u).timeout(timeout, onTimeout: () => null);
    if (!await open(url, mode: Platform.isAndroid ? ULaunchMode.inApp : ULaunchMode.external)) return null;
    final Uri? result = await redirect;
    unawaited(closeInApp());
    return result;
  }

  // Desktop OAuth via a one-shot HTTP server on the redirect port (RFC 8252 loopback redirect).
  static Future<Uri?> _loopback(String url, Uri callback, Duration timeout) async {
    final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, callback.hasPort ? callback.port : 0);
    try {
      if (!await open(url, mode: ULaunchMode.external)) return null;
      final HttpRequest request = await server.first.timeout(timeout);
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write("<html><body style='font-family:sans-serif;text-align:center;margin-top:20vh'>You can close this window.</body></html>");
      await request.response.close();
      return callback.replace(path: request.uri.path, query: request.uri.query);
    } on TimeoutException {
      return null;
    } finally {
      await server.close(force: true);
    }
  }

  // --- Deep links --------------------------------------------------------------

  /// The link that launched the app (deep link, universal / app link, custom scheme), once.
  static Future<Uri?> initialLink() => _initial ??= () async {
    if (kIsWeb) return Uri.base;
    _listen();
    final String? raw = await _call<String>("initialLink");
    return raw == null ? null : Uri.tryParse(raw);
  }();

  /// Links received while the app is running.
  static Stream<Uri> get links {
    _listen();
    return _links.stream;
  }

  /// Stops listening for links and in-app browser events.
  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
