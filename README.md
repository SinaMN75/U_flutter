<div align="center">

# u

### The only package you need.

A batteries-included Flutter **plugin**: UI components, utilities, extension methods, a typed API
layer, and native platform features (device, storage, location, notifications, share, launch,
camera, media, downloads, AR) on **all six platforms**, behind a **single import**.

[![pub package](https://img.shields.io/pub/v/u.svg)](https://pub.dev/packages/u)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue.svg)](https://pub.dev/packages/u)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

</div>

```dart
import "package:u/utilities.dart";
```

That one line brings in `dart:async`, `dart:convert`, `dart:io`, `dart:math`, Flutter's material,
services, gestures, rendering and foundation libraries, **plus** every component, utility,
extension, and native feature listed below.

---

## Contents

- [Why u?](#why-u)
- [Platform support](#platform-support)
- [Install](#install)
- [Quick start](#quick-start)
- [App settings CLI: `dart run u:app`](#app-settings-cli--dart-run-uapp)
- [What's inside](#whats-inside)
- [Host-app setup](#host-app-setup)
- [Complete API reference](#complete-api-reference)
- [Example app](#example-app)
- [Project layout](#project-layout)
- [Conventions](#conventions)

## Why u?

- **One import, everything.** UI kit, formatters, Jalali dates, storage, navigation, an API layer
  and native features all come from `package:u/utilities.dart`.
- **Native code instead of a pile of plugins.** Device info, package info, connectivity, key/value
  storage, URL launching, sharing, location, local notifications and UUIDs are written in Kotlin,
  Swift, C++ and Dart inside u. The package has **12 pub dependencies**, 9 fewer than 3.x.
- **Consistent, themed UI.** `UText*`, `UButton`, `UTextField`, `UScaffold`, `UCard`, `UColumn`,
  `URow` and 200+ more widgets read from your `ThemeData`.
- **Context-free helpers.** `UToast`, `UNavigator` and `ULoading` work from anywhere, with no
  `BuildContext` needed.
- **Small built-in state management.** `.obs` values with `UObx` widgets, in GetX style, with no
  extra dependency.
- **Persian and Iran come first.** Jalali dates and pickers, Persian ⇄ Latin digits, Rial/Toman,
  operator lookup, national code / card / Sheba validation, licence-plate input, Neshan and Balad
  maps, Bazaar and Myket stores, and Eitaa / Rubika / Bale / Soroush messengers.
- **Pure-Dart engines.** PDF and EPUB readers, barcode and QR encoders and decoders, crypto
  (AES, ChaCha20, SHA-3, scrypt…), charts, gauges, an image cropper and a rich-text editor run
  everywhere because they need no native code.

## Platform support

| Feature area | Android | iOS | Web | macOS | Windows | Linux |
| --- | :-: | :-: | :-: | :-: | :-: | :-: |
| UI, utilities, extensions, charts, PDF/EPUB | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Storage (`ULocalStorage`, `UStorage`, `UFileStorage`, vault) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Device / app info (`UDevice`, `UPackage`, `UApp`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Connectivity (`UNetwork`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Launch, deep links, OAuth (`ULaunch`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Share sheet and receiving shares (`UShare`) | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ |
| Location, geofences (`ULocation`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Local notifications (`UNotification`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Camera, QR/barcode scanner (`UCamera`, `UScanner`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Video / audio players (`UMedia`, `UAudio`, `UVideoPlayer`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅¹ |
| Downloads (`UDownloads`, `UDownloadManager`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `UScreenGuard` | ✅ | ✅ | ⬜ | ✅ | ✅ | ⬜ |
| Live AR (`UArScene`, `UArExperiences`, …) | ✅ | ✅ | ✅ | ⬜ | ⬜ | ⬜ |
| 3D viewer (`U3DViewer`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

⬜ = a safe no-op, because the OS has no API for it. ◐ = Linux has no share sheet, so text goes to
the clipboard and files open in the file manager. ¹ Linux playback needs GStreamer installed.

A few individual calls are narrower than their area. Geocoding works on Android, iOS and macOS only.
The compass works on Android, iOS, Windows and mobile web. The equalizer works on Android only.
Each method's doc comment names its platforms.

## Install

```yaml
dependencies:
  u:
    git:
      url: https://github.com/SinaMN75/U_flutter.git
```

Requires Flutter ≥ 3.47.0 and Dart SDK ≥ 3.12.0. Android `minSdk` is 24.

## Quick start

```dart
import "package:u/utilities.dart";

Future<void> main() async {
  // Starts storage, file storage, device/app/network info, notifications, the loading overlay and
  // web update checks. Locks portrait unless you pass deviceOrientations.
  await initU(baseUrl: "https://api.example.com", apiKey: "YOUR_API_KEY");

  runApp(
    UMaterialApp(
      locale: const Locale("fa"),        // used on first launch; the saved language wins later
      lightThemeData: ThemeData.light(),
      darkThemeData: ThemeData.dark(),
      home: const HomePage(),
    ),
  );
}
```

`UMaterialApp` wires up the `navigatorKey`, so `UNavigator`, `UToast` and `ULoading` work
without a context. It also registers u's fa/en localizations (`U.s`) and switches theme and language
live when you call `UApp.toDarkMode()` or `UApp.updateLocale(...)`. It accepts `title`, `builder`,
`routes`, `onGenerateRoute`, `navigatorObservers` and your own `localizationsDelegates`.

To use a plain `MaterialApp`, pass `navigatorKey: navigatorKey` and add
`AppLocalizations.delegate` to its delegates.

## App settings CLI — `dart run u:app`

Change your app's native settings on all 6 platforms with one command, run from the app that depends
on `u`. It edits the real files (Gradle, AndroidManifest, `project.pbxproj`, Info.plist, Podfile,
entitlements, xcconfig, CMake, `Runner.rc`, `main.cpp`, `manifest.json`, `index.html`), keeps their
formatting, and is safe to run again.

```bash
dart run u:app info                                   # current name, ids, SDK levels, permissions…
dart run u:app doctor                                 # template leftovers & cross-platform mismatches
dart run u:app name "My Shop"                         # launcher / home screen / window / tab title
dart run u:app id com.company.shop                    # applicationId + bundle ids (moves MainActivity)
dart run u:app min-sdk android 24 ios 18 macos 14     # minimum OS versions (+ Podfile)
dart run u:app permission add camera location internet
dart run u:app orientation portrait
dart run u:app deep-link myshop                       # myshop:// on Android, iOS, macOS
dart run u:app share-target image pdf                 # receive shares / "Open with" (UShare.onReceive)
dart run u:app query-schemes whatsapp tg              # let ULaunch.canOpen / isInstalled see other apps
dart run u:app bump patch                             # 1.2.3+7 → 1.2.4+8
dart run u:app signing --create                       # asks everything, creates the .jks, signs releases
```

| Command | Android | iOS | macOS | Linux | Windows | Web |
| --- | :-: | :-: | :-: | :-: | :-: | :-: |
| `name`, `id` | ✅ | ✅ | ✅ | ✅ | name | name |
| `min-sdk` | ✅ | ✅ | ✅ | — | — | — |
| `target-sdk`, `compile-sdk`, `ndk`, `java`, `signing` | ✅ | | | | | |
| `permission add/remove/list` | ✅ | ✅ | ✅ | — | — | — |
| `orientation` | ✅ | ✅ | | | | ✅ |
| `deep-link` | ✅ | ✅ | ✅ | | | |
| `share-target` | ✅ | ✅ | ✅ | | | |
| `query-schemes` | ✅ | ✅ | | | | |
| `team` | | ✅ | ✅ | | | |
| `binary`, `company`, `copyright` | | | copyright | binary | ✅ | |
| `web-color` | | | | | | ✅ |
| `version`, `bump`, `description` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

Permissions use 33 friendly names: `internet`, `network-state`, `camera`, `microphone`, `speech`,
`location`, `location-always`, `photos`, `save-photos`, `music`, `storage`, `contacts`, `calendar`,
`reminders`, `bluetooth`, `notifications`, `alarm`, `full-screen`, `vibrate`, `biometric`, `motion`,
`nfc`, `phone`, `sms`, `wake-lock`, `foreground-service`, `background-audio`, `background-fetch`,
`remote-notifications`, `local-network`, `tracking`, `install-apk` and `overlay`.

Each name writes the right entries on every platform:
- Android `<uses-permission>`, `<uses-feature>` and any `<service>` it needs.
- iOS and macOS Info.plist usage strings. Override them with `--message`.
- `UIBackgroundModes`.
- macOS sandbox entitlements.

Where a store reviews a permission (background location, SMS, full-screen intents, APK installs),
the command prints a note.

`share-target` takes `image`, `video`, `audio`, `text`, `pdf`, `any` or any MIME type. With no
arguments, `query-schemes` adds `whatsapp`, `tg`, `instagram`, `comgooglemaps` and `waze`. A dotted
name, such as `ir.eitaa.messenger`, becomes an Android `<queries>` package.

Every command takes `--platforms android,ios` and `--dry-run`. `dart run u:app <command> --help`
shows examples. The full copy-paste list is at the bottom of this package's `pubspec.yaml`.

## What's inside

### App setup — `initU`, `UMaterialApp`, `U`, `UApp`

```dart
U.baseUrl;                      // set by initU
U.s.save;                       // localized strings (fa / en)
U.user = loginResponse.user;    // logged-in user
U.appSettings;                  // settings loaded from the server
U.addOrSwitchTab("Users", const UsersPage());   // desktop/admin tab layouts (UDefaultTabBar)

UApp.version; UApp.buildNumber; UApp.isAndroid; UApp.isDesktopSize();
UApp.toDarkMode(); UApp.updateLocale(const Locale("en"));
UApp.isFirstLaunch; UApp.justUpdated; UApp.installer;      // play, appStore, bazaar, myket, sideload…
await UApp.deviceStatus();      // battery, charging, power saver, thermal, free RAM/disk
await UApp.isDeviceCompromised();   // root/jailbreak, Frida/Xposed hooks, debugger
UApp.deviceHeaders;             // ready-made X-Device-* / X-App-* headers
UApp.haptic(UHapticType.success); UApp.keepScreenOn(true); UApp.setFullScreen(true);
```

### Text — `UText*`

There is one widget per Material 3 type-scale role: `UTextDisplayLarge/Medium/Small`,
`UTextHeadline*`, `UTextTitle*`, `UTextBody*` and `UTextLabel*`, plus `UAnimatedCounter`. The
string is positional; styling (color, weight, maxLines, decoration…) is named.

```dart
UTextTitleLarge("Welcome", fontWeight: FontWeight.w700);
UTextBodyMedium("Body text", maxLines: 2);
```

### Buttons

`UButton` covers every style through `UButtonType` (`elevated`, `filled`, `filledTonal`, `text`,
`outlined`, `icon`, `fab`, `cupertino`, `custom`), with sizes, icons, loading position, full width
and a built-in "resend in 59s" countdown. Also: `UButtonSubmitCancel`, `UPressable`,
`USendAgainCountDown`, `UPopupMenu`.

```dart
UButton(title: "Save", isLoading: saving, onTap: save);
```

### Inputs and forms

- **Text fields:** `UTextField`, `UTextFieldPhoneNumber` (country picker, per-country validation),
  `UTextFieldDatePicker` (Gregorian or Jalali), `UTextFieldAutoComplete`,
  `UTextFieldAutoCompleteAsync`, `UTextFieldAutoCompleteAsyncMulti` and `USearchField` (debounced).
- **Pickers and selectors:** `UDropDownField`, `UCategorySelector`, `UCountryProvincePicker`,
  `UChipChoice`, `UTagChips` and `USegmentedControl`.
- **Codes and keypads:** `UOtpField` (paste, SMS autofill), `UPlateField` (Iranian plate) and
  `UNumericKeyboard`.
- **Rich content:** `USignaturePad`, `URichTextEditor` / `URichTextEditorField` (HTML out) and
  `UListEditor`.
- **Forms and dialogs:** `UFormDialog`, `UFilterDialog` and `UFieldPair`.
- **Formatters:** `UNumberInputFormatter`, `UPhoneInputFormatter` and `UCurrencyInputFormatter`.
- **Validators:** `UValidators` provides `required`, `email`, `phone`, `url`, `number`,
  `numberRange`, length checks, `password` / `complexPassword`, `match` / `matchController`,
  `pattern`, `alphanumeric`, `cardNumber`, `iban`, `iranianNationalCode` and
  `iranianTaxPayerCode`. Combine them with `combineValidators`, and run a form with
  `validateForm`.
- **Jalali pickers:** `UJalaliDatePicker.show(type: …)` in three flavours: `classic`, `material`
  and `spinner`.

```dart
UTextField(labelText: "Email", validator: UValidators.email(), keyboardType: TextInputType.emailAddress);
final UJalali? date = await UJalaliDatePicker.show();
```

### Layout and scaffolding

- **Pages and boxes:** `UScaffold`, `UContainer` / `UAnimatedContainer`, `UColumn`, `URow`,
  `UStack` and `UWrap` (spacing, decoration and tap are built in), `UCard`, `UGlassCard`,
  `UHeaderCard`.
- **Small building blocks:** `UKeyValue`, `UInfoRow`, `UIconTextHorizontal/Vertical`, `UCenter`,
  `UAspectRatio`, `UConstrained` and `UDivider`.
- **Lists and grids:** `UListView`, `UGridView`, `USliverList` and `USliverGrid`.
- **Responsive and desktop:** `UResponsive` (phone / tablet / desktop), `UDefaultTabBar`,
  `UTabBar` (browser-style closable tabs) and `USideMenu` (expanded / rail / drawer, groups,
  badges, search).
- **Tiles and status:** `UListTile`, `UActionTile`, `UStatTile`, `USelectionCard`, `UPill`,
  `UAvatar`, `UCopyText`, `UAlertBanner`, `UEmptyState`, `UErrorRetry` and `USkeleton`.

### Async UI and state

```dart
// Tiny GetX-style state: .obs + UObx, no extra dependency.
final URxInt count = 0.obs;
UObx(() => Text("${count.value}"));

final URxState state = URxState();   // initial / loading / loaded / error / empty / paging

// Loading, error + retry, empty and data, handled for you.
UAsyncBuilder<List<User>>(load: api.users, builder: (BuildContext c, List<User> users) => UserList(users));
UPaginatedList<Post>(fetch: (int page) => api.posts(page), itemBuilder: (c, Post p, int i) => PostTile(p));
UStreamView<int>(stream: counter, builder: (c, int v) => Text("$v"));
UOfflineBanner(child: const HomePage());
UOnlineBuilder(builder: (BuildContext c, bool online) => online ? const Feed() : const OfflinePage());
```

### Feedback — context-free

```dart
UToast.success(message: "Saved");            // also error / warning / info, snackBar, banner, *Toast
final bool ok = await UNavigator.confirmAsync(title: "Delete?", message: "This cannot be undone", destructive: true);
UNavigator.push(const ProfilePage());       // push / off / offAll / back, with URouteTransitions
UNavigator.bottomSheet(...); UNavigator.actionSheet(...); UNavigator.inputDialog(...);
ULoading.show(); await save(); ULoading.dismiss();
```

`UNavigator` also opens date, date-range, time and color pickers, full-screen and draggable
sheets, and overlays. The progress widgets are `UProgressLinear`, `UProgressCircular`,
`UCircularPercentIndicator`, `ULinearPercentIndicator`, `URatingBar` and
`URatingBarIndicator`.

### Formatters and extensions

You call them directly on values:

```dart
1500000.rial();                 // "1,500,000 ﷼"
1500000.toman();
1250000.toKMB();                // "1.25M"
1536.toBKMG();                  // "1.5 KB"
1234567.separate3By3();         // "1,234,567"
"۱۲۳".toLatinNumber();          // "123"
DateTime.now().toJalaliDate();
someDate.toTimeAgo();           // "3 hours ago"
90.seconds.toClock();           // "01:30"
users.groupBy((User u) => u.city);
json.getOr<int>("count", 0);
children: <Widget>[a, b, c].withSpacing(8);
context.colorScheme.primary; context.isRtl; context.hideKeyboard();
myWidget.pAll(16).onTap(open).card();
```

Each type has its own set of helpers. The full list is under
[Extensions](#extensions-available-globally).

### Storage — `ULocalStorage`, `UStorage`, `UFile`

```dart
ULocalStorage.set("cart", items, expireTime: 1.days);
ULocalStorage.get<DateTime>("lastSync");
ULocalStorage.getObject("user", UUserResponse.fromJson);
ULocalStorage.setSecure("pin", pin);                 // encrypted, key in Keychain / Keystore
ULocalStorage.setToken(token);                       // tokens are always encrypted
await ULocalStorage.setAndWait("done", true);        // wait until it is on disk

final UStore cache = await UStorage.open("cache");   // a separate, clearable store
UStorage.listenable<bool>("isDarkMode");             // for ValueListenableBuilder

await UFile.saveJson("profile", profile);            // keyed files: support / cache / vault / temp
final UFileData? img = await UFile.pickSingleImage();
final UFileData? cropped = await UFile.cropImage(bytes: data, options: const UCropOptions(shape: UCropShape.circle));
await UFile.saveToDownloads(sourcePath: path, fileName: "report.pdf");
UFile.openStoragePage();                             // built-in "Storage" screen
```

`UStorage` replaces `shared_preferences`.
- **Fast reads:** every store is in memory after init, so a read is a map lookup.
- **Safe writes:** writes in the same frame are combined into one atomic file replace.
- **Types are kept:** values come back as the type you saved, including `DateTime`, `Duration`,
  `Uint8List`, enums and anything with `toJson`.
- **Secure stores:** these use ChaCha20-Poly1305 (AES-GCM on web) under a key held by the platform
  key store.

`UFileStorage` stores keyed files in four buckets:
- `support`: private and persistent.
- `cache`: an LRU cache with a size cap.
- `vault`: encrypted at rest with per-file keys.
- `temp`: temporary files.

It also handles expiry, MIME types, checksums and ranged reads.

### Device, app and network — `UDevice`, `UPackage`, `UNetwork`

```dart
UDevice.model; UDevice.osVersion; UDevice.type; UDevice.id; UDevice.timeZone;
final UDeviceIntegrity i = await UDevice.integrity();
UPackage.version; UPackage.isAtLeast("2.1.0"); UPackage.signatureSha256;

if (UNetwork.isOffline) …
UNetwork.isWifi; UNetwork.isMetered; UNetwork.cellularGeneration;
await UNetwork.whenOnline();
await UNetwork.hasInternet();        // a real round trip, not just "has an interface"
UNetwork.listen((UNetworkStatus s) => …);
UNetworkBuilder(builder: (BuildContext c, UNetworkStatus s) => s.isOnline ? child : banner);
```

Startup takes one native round trip that fills device, package and network info together. Going
offline must last `UNetwork.offlineGrace` before it is reported, so a Wi-Fi → LTE handoff never
flashes an offline banner.

### Launch, deep links and OAuth — `ULaunch`

```dart
await ULaunch.url("https://sinamn75.com");
ULaunch.inApp(url, toolbarColor: Colors.teal);     // Custom Tabs / Safari view / new tab
ULaunch.external(paymentUrl);
ULaunch.call("*140#"); ULaunch.sms(<String>["09121234567"], body: "Code: 1234");
ULaunch.email(to: <String>["a@b.com"], subject: "Hi", attachments: <String>[path]);
ULaunch.chat(UMessenger.whatsapp, "+989121234567", text: "Hello");   // also telegram, eitaa, rubika, bale…
ULaunch.map(35.7, 51.4, label: "Office", app: UMapApp.neshan);       // neshan, balad, google, waze, apple
ULaunch.directions(35.7, 51.4, app: UMapApp.waze);
ULaunch.store(review: true);                       // Play, Bazaar, Myket, App Store, Microsoft Store, Flathub
ULaunch.requestReview();
ULaunch.settings(USettingsPage.location);
final Uri? redirect = await ULaunch.authenticate(authUrl, callbackScheme: "myapp");
ULaunch.onLink((Uri uri) => UNavigator.push(ProductPage(uri.pathSegments.last)));
```

Every call returns `false` or `null` instead of throwing when the platform can't do it.

### Share — `UShare`

```dart
UShare.text("Check this out", origin: UShare.originOf(context));
UShare.link("https://x.com/p/1", message: "New product");
UShare.bytes(pdfBytes, name: "invoice.pdf");
UShare.widgetImage(receiptController, name: "receipt.png");
UShare.to(UShareTarget.telegram, text: "Hi");      // straight to one app, no sheet
UShare.onReceive((UReceivedShare s) => importFiles(s.files));   // needs `dart run u:app share-target`
```

### Location — `ULocation`

```dart
final UPosition? p = await ULocation.position();
final ULocationResult r = await ULocation.current();     // r.error explains denied / GPS off / timeout
ULocation.stream(const ULocationSettings(distanceFilter: 10)).listen(update);
final ULocationError? err = await ULocation.ensureReady();
ULocation.addGeofence(const UGeofence(id: "home", latitude: 35.7, longitude: 51.4, radius: 200));
ULocation.geofenceEvents().listen((UGeofenceEvent e) => …);   // includes events from while the app was closed
ULocation.heading().listen((UHeading h) => angle = h.degrees);
(await ULocation.addressOf(35.7, 51.4)).first.street;
ULocation.distance(35.7, 51.4, 32.6, 51.6);
```

Each platform uses its own location service:
- **Android:** LocationManager (fused provider on Android 12+), with no Google Play Services.
- **iOS and macOS:** CoreLocation.
- **Windows:** Windows.Devices.Geolocation.
- **Linux:** GeoClue2.
- **Web:** `navigator.geolocation`.

### Notifications — `UNotification`

```dart
await UNotification.requestPermission();
UNotification.show(1, title: "Order shipped", body: "Arrives tomorrow");
UNotification.progress(5, title: "Downloading", value: 40);
UNotification.schedule(const UNotificationRequest(id: 2, title: "Reminder"), DateTime.now().add(1.hours));
UNotification.daily(req, hour: 9);
UNotification.weekly(req, weekday: DateTime.saturday, hour: 10);
UNotification.monthlyJalali(req, day: 1, hour: 9);       // every 1st of the Jalali month
UNotification.listen((UNotificationEvent e) => UNavigator.push(OrderPage(e.payload)));
UNotification.setBadge(3);
```

Notifications support action buttons, inline replies, big pictures, groups, Android channels, exact
alarms and badges.
- **Android:** schedules survive a reboot and are re-armed when the time zone changes.
- **Windows:** toast clicks still work after the app has closed.
- **Linux and web:** there is no OS scheduler, so u keeps the schedule itself and re-arms it in
  `init()`.

### Camera and codes — `UCamera`, `UScanner`, `UBarcode`

```dart
final UFileData? photo = await UCamera.takePhoto();
final List<UFileData> shots = await UCamera.open();          // full camera screen: photo, video, multi-shot
final String? text = await UCamera.scan(formats: <UCodeFormat>[UCodeFormat.qrCode]);
final List<UCode> codes = await UCamera.scanImage(bytes: imageBytes);   // no camera needed

UScanner(onScan: (String text) => print(text));               // live scanner widget
UBarcode(value: "https://x.com", type: UBarcodeType.qrCode, width: 200, height: 200);
```

`UBarcode` draws QR, Data Matrix, Aztec, PDF417, Code 128, EAN/UPC, Code 39/93, ITF, Codabar and
postal codes in pure Dart. It supports gradients, round dots and a center logo.

### Media — `UMedia`, `UAudio`, `USound`, `UVideoPlayer`, `UMusicPlayer`

```dart
UVideoPlayer(url: "https://x.com/v.m3u8", resumeKey: "movie-1");   // drop-in, every feature
final UMediaController c = UMedia.video(); await c.open(UMedia.network(url, headers: <String, String>{"Authorization": token}));
UVideo(controller: c);

UAudio.play("https://x.com/song.mp3", metadata: const UMediaMetadata(title: "Song"));
UAudio.playQueue(<Object>[a, b, c]);
UMusicPlayer(layout: UMusicPlayerLayout.card);                     // artwork, queue, lyrics, equalizer, sleep timer
UMiniPlayerBar(controller: UAudio.controller, onTap: openPlayer);
USound.play("assets/sounds/tap.mp3");                             // effects that mix with the user's music
```

Each platform uses its native player: ExoPlayer, AVPlayer, Media Foundation, GStreamer or HTML5 with
hls.js. Playback covers HLS, DASH, Widevine/FairPlay DRM, picture-in-picture, lock-screen controls
and resume positions. Subtitles come in SRT, VTT, ASS, LRC and MicroDVD, with Windows-1256 Persian
detection.

There are also parsers for HLS, DASH and M3U/PLS/XSPF, plus a music library index and playlists.
The video player adds gestures, A-B repeat, color filters, a stats overlay, time-stamped notes and
drawing on frames (`UVideoWithNotes`). Visual extras are `UVisualizer` and `ULyricsView`.

### Documents — `UPdfViewer`, `UEpubReader`, `UPdfEditorPage`

```dart
UPdfViewer(url: "https://x.com/a.pdf");
UEpubReader(url: "https://x.com/book.epub");
UPdfEditorPage(filePath: path, onSaved: (String p) => print(p));
```

Both readers are pure Dart and support:
- Search, selection and copy, outline / TOC, and thumbnails.
- Night mode and typography settings.
- Highlights, underline, strike-through and notes.
- Bookmarks and resume position.
- Drawing with pen, shapes, arrows, text boxes and sticky notes.
- Watermarks and `secure` mode.

Everything you add is saved in one exportable annotation string through
`UDocAnnotationController`. The PDF editor adds page organisation, form filling, redaction, merging
and saving.

### Charts and gauges

- **Charts:** `ULineChart`, `USplineChart`, `UStepLineChart`, `UAreaChart`, `UBarChart`,
  `UGroupedBarChart`, `UHorizontalBarChart`, `UStackedBarChart`, `UStacked100BarChart`,
  `UStackedAreaChart`, `UPieChart`, `UDonutChart`, `UFunnelChart`, `UTreemapChart`,
  `UScatterChart`, `UBubbleChart`, `URadarChart`, `UCandlestickChart`, `UOhlcChart`,
  `UHistogramChart`, `UHeatmapChart`, `UWaterfallChart` and `USparkline`.
- **Gauges:** `URadialGauge`, `USpeedometerGauge`, `USemiCircleGauge`, `UArcGauge`,
  `UProgressRingGauge`, `ULinearGauge`, `UVerticalLinearGauge`, `UBatteryGauge`,
  `UThermometerGauge`, `UCompassGauge`, `USegmentedGauge` and `UBulletGauge`.

```dart
UBarChart(series: <UChartSeries>[UChartSeries(name: "Sales", values: <double>[4, 7, 3])], categories: <String>["A", "B", "C"]);
URadialGauge(value: 72, bands: <UGaugeBand>[UGaugeBand(start: 80, end: 100, color: Colors.red)]);
```

### Images and media widgets

- **Images:** `UImage` handles asset, cached URL, SVG, Lottie, base64 and `UFileData`. Related
  widgets are `UImageAsset`, `UImageNetwork`, `UImageFile`, `UImageMemory` and `UIconPrimary`.
- **Viewers and pickers:** `UImageViewer`, `UBetterImageViewer`, `UImageGalleryViewer`,
  `UImageCropper`, `UFilePicker` and `UBase64ImagePicker`.
- **Carousels and motion:** `USlider`, `UCarousel`, `UFlipCard`, `UReadMoreText`,
  `UScrollingText` and `UWidgetToImage`.
- **Web and maps:** `UHtmlView`, `UWebView` (in-app browser on all 6 platforms), `UMap` and
  `UJsonViewer`.
- **Cards and pages:** `UCreditCardWidget` / `UCreditCardForm`, `UNumberPagination`,
  `UContentBentoPage` and `UBadgeWidget` / `ULetterBadge`.

### Downloads — `UDownloads`

```dart
await UDownloads.download("https://x.com/a.zip");            // into Downloads, with progress + notification
await UDownloads.toVault(url, "lesson-1");                   // encrypted while downloading
final Uint8List data = await UDownloads.bytes(url);          // silent, in memory
UDownloads.headersProvider = (UDownloadTask t) async => <String, String>{"Authorization": "Bearer ${ULocalStorage.getToken()}"};
UDownloads.urlResolver = (UDownloadTask t) async => (await api.signedUrl(t.request.sourceId!)).url;
UDownloads.openPage();                                       // built-in IDM-style manager screen
UDownloadButton(request: UDownloadRequest(url: url));
```

`UDownloads` runs on top of `UDownloadManager`, which provides:
- Segmented, multi-connection transfers that pause and resume across restarts.
- Priorities, per-host limits, speed limits and wifi-only rules.
- Mirrors and checksums.
- Hand-off to the OS (Android DownloadManager, Apple background URLSession, Windows BITS).

### AR and 3D — `UArExperiences`, `U3DViewer`, …

There are no pub packages involved:
- **Android:** ARCore with a built-in OpenGL ES 3 glTF renderer.
- **iOS:** ARKit with RealityKit.
- **Web:** WebXR with a built-in WebGL2 renderer.

```dart
UArExperiences.place(items: <UArPlaceable>[UArPlaceable(id: "sofa", title: "Sofa", source: UArSource.asset("assets/sofa.glb"))]);
U3DViewer(source: UArSource.url(glbUrl));                    // rotate / zoom / hotspots + "View in AR"
UArExperiences.places(places: <UArPlace>[UArPlace(id: "cafe", latitude: 35.7, longitude: 51.4, title: "Cafe")]);
// Also UArMeasure, UArFaceTryOn, UArImageTrigger, UArCodeView, UAr.scanRoom, UAr.captureObject,
// UAr.openNativeViewer, or build your own with UArController + UArView.
```

### Security and crypto

- **`UScreenGuard`** blocks screenshots and screen recordings with `enable()`, `disable()` and
  `set(enabled:)`. On iOS, `onScreenshot` and `onScreenRecording` report capture attempts. It uses
  `FLAG_SECURE` on Android, a secure field on iOS, `NSWindow.sharingType = .none` on macOS and
  `WDA_EXCLUDEFROMCAPTURE` on Windows.
- **`UEncryption`** is pure Dart:
  - Ciphers: AES (CBC/CFB/CTR/GCM/…), ChaCha20(-Poly1305), XChaCha20-Poly1305, Salsa20, Fernet, RC4.
  - Hashes: MD4/MD5, SHA-1/2/3, SHAKE, BLAKE2b, Keccak, RIPEMD-160, SM3, HMAC.
  - Key derivation: PBKDF2, scrypt, HKDF.
  - Checksums: CRC16/32, Adler-32, FNV-1a.
  - Encodings: Base32/45/58/64/85, hex, Morse, ROT13/47.
  - Helpers: `seal` / `open`, constant-time compare and random keys.
- **`UOtp`** creates offline one-time codes tied to a POS serial (Verhoeff checksums).
- **`UAuth`** handles JWT expiry, single-flight refresh and sign-out.

### Persian / Iran

- **Dates:** `UJalali` and `UGregorian` convert exactly between calendars, with formatters and day
  math.
- **`UPersianTools`:** national code, card and Sheba validation, bank lookup, number ⇄ Persian
  words, digit conversion, operator and SIM details, and tax memory id.
- **`UPhoneNumberUtils`:** E.164, per-country validation, formatting and masks.
- **Datasets:** `U.vazir` (the bundled Vazir font), `UCountries`, Iran's provinces and cities, and
  business categories.

### Payments — ISO 8583

`UIso` and `UIsoClient` talk to POS switches. They handle host config, terminal context, a security
module, the trace counter, MAC, TLVs and session keys. Calls use the same `onSuccess` / `onError` /
`onException` shape as REST.

```dart
UIso.init(config: hostConfig, context: terminalContext, securityModule: hsm, nextTraceNumber: nextStan);
await UIsoClient.send(mti: "0200", processingCode: "000000", onSuccess: ok, onError: declined, onException: failed);
```

### Process engine

`UProcessView` renders server-driven, multi-step processes such as KYC and onboarding. Fields cover
text, image, e-signature and video selfie, with a steps indicator and `UProcessStyle` theming.

### Web helpers

- **`UWebUpdate`** keeps every open tab on the latest build. `initU()` starts it; build with
  `--dart-define=U_BUILD_ID=<version>`.
- **`UPwa`** reports install state and shows the iOS "Add to Home Screen" guide.
- **`UWebMessage`** handles `postMessage` from IPG pages, OAuth popups and parent iframes.

### Everyday utilities

- `UDebouncer`, `UThrottler`, `URetry`, `delay(...)`
- `UUUID`: `uuidV1/4/5/6/7/8`, with no package
- `UConvert`: JSON pretty/minify, JSON ⇄ XML / CSV, query strings
- `UTimezone`: IANA id and offset
- `UClipboard`
- `UCrashlytics`: catches uncaught errors with device context
- `UUpdateDialog`: forced or optional update

```dart
UUpdateDialog.checkAndShow(U.appSettings.appVersions, () => UNavigator.offAll(const HomePage()));
```

## Host-app setup

The plugin's own manifests already declare what u needs. You only add what your features use, and
`dart run u:app permission add …` writes most of it for you.

| Platform | What u declares | What you may add |
| --- | --- | --- |
| **Android** | `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED` (re-arming notifications); `<queries>` for the apps `ULaunch` / `UShare` check (browsers, dialer, maps, stores, WhatsApp, Telegram, Eitaa, Rubika, Bale, Soroush, …); download foreground service, FileProvider, `WRITE_EXTERNAL_STORAGE` (API ≤ 28) | `permission add camera location notifications alarm …`; `POST_NOTIFICATIONS` on 13+; for AR: `implementation("com.google.ar:core:1.45.0")` |
| **iOS** | `PrivacyInfo.xcprivacy` (UserDefaults, disk space, boot time, file timestamps) | Usage strings via `permission add`; `query-schemes` for `canOpen` / `isInstalled`; `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` to show downloads in Files |
| **macOS** | `PrivacyInfo.xcprivacy` | Entitlements: `network.client`, `files.downloads.read-write`, `files.user-selected.read-write`; `permission add location camera …` |
| **Windows** | — | Nothing. |
| **Linux** | — | `libsecret-1-dev` keeps the vault key in the Secret Service (otherwise a private file); GStreamer for media; GeoClue2 for location |
| **Web** | — | HTTPS for location / camera; CORS + `Access-Control-Expose-Headers: Content-Range, Accept-Ranges, ETag` for segmented downloads; a PWA `share_target` for `UShare.onReceive` |

Live AR needs camera (and location for geo content) permissions plus ARCore on Android. The full
setup per platform is documented at the top of `lib/components/u_ar.dart`.

## Complete API reference

Everything below is exported from the single `package:u/utilities.dart` import.

### Utilities (static classes in `lib/utils`)

| Class | Purpose |
| --- | --- |
| `U` | App root config: `baseUrl`, `apiKey`, `s` (l10n), `user`, `appSettings`, `contents`, `categories`, tabs, `vazir` |
| `UApp` / `UAppState` | App, device, platform, size, theme and language info; haptics, orientation, full screen, keep awake |
| `UDevice` / `UPackage` / `UConnectivity` | Device model, integrity, status, headers / app identity, installer, launch history / network state |
| `UHttpClient` | `send`, `upload`, multipart, retries, offline cache, progress, token refresh |
| `UAuth` | JWT expiry, single-flight refresh, sign-out |
| `ULocalStorage` / `UStorage` | Typed key/value storage with expiry, secure store, named stores, change streams |
| `UFile` / `UFileStorage` | Pick, capture, crop, store (support / cache / vault / temp), open, reveal, share, save-as |
| `UDownloads` / `UDownloadManager` | Segmented, resumable downloads to memory, storage, vault, Downloads, a path or "save as" |
| `UNavigator` | `push/off/offAll/back`, `dialog`, `alert`, `confirm(Async)`, `inputDialog`, `bottomSheet`, `actionSheet`, `draggableSheet`, pickers, overlays |
| `UToast` | `success/error/warning/info`, `snackBar`, `banner`, `toast` |
| `ULoading` | Global blocking overlay: `show`, `dismiss`, `setPercent`, `isShowing` |
| `ULaunch` | URLs, in-app browser, apps, settings, stores, maps, messengers, email/SMS/call, OAuth, deep links |
| `UShare` | Share text/links/files/bytes/widget images, share to one app, receive shares |
| `ULocation` | Position, stream, permissions, geofences, compass, visits, geocoding, distance/bearing |
| `UNotification` | Show, schedule (Gregorian/Jalali repeats), progress, actions, replies, channels, badges |
| `UNetwork` | Online/offline, wifi/cellular/vpn, metered, speed, real internet check, streams |
| `UCamera` | Camera screen, photos, videos, scanning (live / image / raw pixels), permissions |
| `UMedia` / `UAudio` / `USound` | Native players, sources, subtitles, tags, HLS/DASH, library, playlists / app-wide music player / sound effects |
| `UArExperiences` / `UAr` | Ready-made AR screens and capability checks |
| `UScreenGuard` | Screenshot / recording prevention |
| `UEncryption` / `UOtp` | Hashes, ciphers, KDFs, encoders / offline POS one-time codes |
| `UIso` / `UIsoClient` | ISO 8583 setup and messaging |
| `UValidators` | Form validators (see [Inputs](#inputs-and-forms)) |
| `UPersianTools` / `UPhoneNumberUtils` | Iranian validation and lookups / international phone numbers |
| `UJalali` / `UGregorian` | Jalali ⇄ Gregorian dates and formatting |
| `UConvert` | JSON, XML, CSV, query-string conversions |
| `UTimezone` | Device IANA zone and offset |
| `UClipboard` | `set`, `getText` |
| `UCrashlytics` | Uncaught-error reports with app / device / screen context |
| `UUpdateDialog` | Force / optional update from `UAppSettingsResponse.appVersions` |
| `UUUID` | `uuidV1/V4/V5/V6/V7/V8` |
| `UDebouncer` / `UThrottler` / `URetry` | Debounce, throttle, retry with back-off |
| `UWebUpdate` / `UPwa` / `UWebMessage` | Web build refresh, PWA install, `postMessage` |
| `UConstants` / `UIcons` | Storage key names / bundled brand icons |
| `URx*` / `UObx` | Observable values and the widget that rebuilds on them |

### Extensions (available globally)

| On | Highlights |
| --- | --- |
| `Widget` | `pAll/pSymmetric/pOnly/pLTRB`, `onTap/onTapInk/onLongPress/onDoubleTap`, `expanded/flexible/fit`, `ltr/rtl`, `scale/rotate/translate/position`, `center/alignAt*`, `safeArea/form/scrollable/sliver`, `card/container/chip`, `sized/opacity/visible/disabled/tooltip/hero`, `clipRadius/clipCircle`, `skeleton`, `fadeSlideIn`, `showMenus` |
| `List<Widget>` | `withSpacing`, `withDividers` |
| `BuildContext` | `theme/colorScheme/textTheme`, `width/height/screenSize`, `isDarkMode/isRtl/locale`, `isMobileSize/isTabletSize/isDesktopSize`, `responsive`, keyboard (`isKeyboardOpen`, `keyboardHeight`, `hideKeyboard`), padding / insets |
| `String` / `String?` | money (`rial/toman`), Jalali (`toJalaliDate/DateTime`), `toPersianNumber/toLatinNumber`, `normalizePersian`, `separateNumbers3By3`, `isNullOrEmpty/isBlank/isNumeric`, `isValidEmail/Phone/Url`, `isStrongPassword`, `toIntOrNull/toDoubleOrNull`, `toColor/toHex`, `capitalize/toTitleCase/toSlug`, `mask`, file name helpers, Base58/Base64 |
| `num` / `int` / `double` (+ nullable) | `rial/toman/rialToToman`, `separate3By3/withCommas`, `toKMB/toBKMG/toHuman`, `toPercent/percentOf/between`, `toPersianWords`, `toClock/twoDigits`, `ms/seconds/minutes/hours/days`, `delay`, month names |
| `Duration` | `toClock` and readable durations |
| `DateTime` | `formatDate`, `toJalali*`, `toTimeAgo`, `isToday/isYesterday/isTomorrow/isPast/isFuture/isSameDay`, `startOfDay/endOfDay/startOfMonth`, `addMonths`, `age`, `daysUntil`, `copyWith` |
| `Iterable<T>` / `Iterable<T>?` | `mapIndexed`, `forEachIndexed`, `firstOrDefault/firstWhereOrNull`, `groupBy`, `distinctBy`, `chunked`, `sumBy/averageBy/minBy/maxBy`, `separatedBy`, `containsAll/Any`, `orEmpty`, `isNullOrEmpty` |
| `Map<K,V>` | `add` (chainable), `getOr`, `pick`, `omit`, `removeNulls`, `deepMerge` |
| `TextEditingController` | `numString/numInt/numDouble`, `valueOrNull`, `appendCharacter`, `dropLastCharacter` |
| `Uint8List` | `toBase64/toBase64Url` |
| `Response?` (http) | `isSuccessful()` and status helpers |

### Widgets (`lib/components`)

| Group | Widgets |
| --- | --- |
| Text | `UTextDisplay*`, `UTextHeadline*`, `UTextTitle*`, `UTextBody*`, `UTextLabel*`, `UAnimatedCounter` |
| Buttons & menus | `UButton`, `UButtonSubmitCancel`, `UPressable`, `USendAgainCountDown`, `UPopupMenu` |
| Inputs | `UTextField`, `UTextFieldPhoneNumber`, `UTextFieldDatePicker`, `UTextFieldAutoComplete(Async)(Multi)`, `USearchField`, `UDropDownField`, `UCategorySelector`, `UCountryProvincePicker`, `UCountryFlag`, `UChipChoice`, `UTagChips`, `USegmentedControl`, `UOtpField`, `UPlateField`, `UNumericKeyboard`, `USignaturePad`, `URichTextEditor(Field)`, `UListEditor`, `UFormDialog`, `UFilterDialog`, `UFieldPair` |
| Dates | `UJalaliDatePicker`, `UJalaliDatePickerDialog`, `UJalaliDatePickerMaterial`, `UJalaliDatePickerSpinner` |
| Layout | `UScaffold`, `UContainer`, `UAnimatedContainer`, `UColumn`, `URow`, `UStack`, `UWrap`, `UCard`, `UCenter`, `UAspectRatio`, `UConstrained`, `UDivider`, `UResponsive`, `UListView`, `UGridView`, `USliverList`, `USliverGrid`, `UKeyValue`, `UInfoRow`, `UIconTextHorizontal/Vertical` |
| Navigation | `USideMenu` (`UMenuItem`, `UMenuGroup`, `UMenuHeader`, `USideMenuController`), `UTabBar`, `UDefaultTabBar`, `UNumberPagination` |
| Display | `UListTile`, `UActionTile`, `UStatTile`, `USelectionCard`, `UHeaderCard`, `UGlassCard`, `UPill`, `UAvatar`, `UCopyText`, `UAlertBanner`, `UIconBackground`, `UImageBackground`, `UBadgeWidget`, `ULetterBadge`, `UEmptyState`, `UErrorRetry`, `USkeleton`, `UReadMoreText`, `UScrollingText`, `UFlipCard`, `UJsonViewer` |
| Async | `UAsyncBuilder`, `UStreamView`, `UPaginatedList`, `UOnlineBuilder`, `UOfflineBanner`, `UNetworkBuilder`, `UObx` |
| Progress & rating | `UProgressLinear`, `UProgressCircular`, `UCircularPercentIndicator`, `ULinearPercentIndicator`, `URatingBar`, `URatingBarIndicator` |
| Images | `UImage`, `UImageAsset`, `UImageNetwork`, `UImageFile`, `UImageMemory`, `UIconPrimary`, `UImageViewer`, `UBetterImageViewer`, `UImageGalleryViewer`, `UImageCropper`, `UBase64ImagePicker`, `UFilePicker`, `USlider`, `UCarousel`, `UWidgetToImage` |
| Camera & codes | `UCameraPage`, `UCameraPreview`, `UCameraGrid`, `UScanner`, `UScannerPage`, `UBarcode` |
| Video | `UVideoPlayer`, `UVideo`, `UVideoView`, `UVideoControls`, `UVideoSeekBar`, `UVideoGestures`, `USubtitleView`, `UVideoStatsOverlay`, `UMediaTrackSheet`, `UVideoSettingsSheet`, `UFloatingMiniPlayer`, `UVideoWithNotes`, `UMediaNotesPanel`, `UMovingWatermark`, `UMediaPipSwitcher` |
| Audio | `UMusicPlayer`, `UMiniPlayerBar`, `UMediaQueueSheet`, `UArtwork`, `ULyricsView`, `UEqualizerSheet`, `UVisualizer` |
| Documents | `UPdfViewer`, `UPdfEditorPage`, `UPdfPageManager`, `UPdfFormPanel`, `UPdfOutlinePanel`, `UPdfThumbnailPanel`, `UPdfAnnotationsPanel`, `UPdfDocumentToolsPanel`, `UEpubReader`, `UEpubSettingsPanel`, `UDocShapeLayer`, `UDocDrawToolbar`, `UDocAnnotationsPanel`, `UDocBookmarksPanel`, `UDocWatermark`, `USecureArea` |
| Charts | `ULineChart`, `USplineChart`, `UStepLineChart`, `UAreaChart`, `UBarChart`, `UGroupedBarChart`, `UHorizontalBarChart`, `UStackedBarChart`, `UStacked100BarChart`, `UStackedAreaChart`, `UPieChart`, `UDonutChart`, `UFunnelChart`, `UTreemapChart`, `UScatterChart`, `UBubbleChart`, `URadarChart`, `UCandlestickChart`, `UOhlcChart`, `UHistogramChart`, `UHeatmapChart`, `UWaterfallChart`, `USparkline` |
| Gauges | `URadialGauge`, `USpeedometerGauge`, `USemiCircleGauge`, `UArcGauge`, `UProgressRingGauge`, `ULinearGauge`, `UVerticalLinearGauge`, `UBatteryGauge`, `UThermometerGauge`, `UCompassGauge`, `USegmentedGauge`, `UBulletGauge` |
| Web & maps | `UWebView`, `UHtmlView`, `UMap`, `UDemoMap` |
| Commerce | `UCreditCardWidget`, `UCreditCardForm`, `UCardBrandDetector`, `UContentBentoPage` |
| Downloads & storage | `UDownloadManagerPage`, `UDownloadTile`, `UDownloadButton`, `USegmentProgressBar`, `UAddDownloadSheet`, `UDownloadSettingsSheet`, `UStorageManagerPage` |
| AR & 3D | `UArScene`, `U3DViewer`, `UArGeoView`, `UArMeasure`, `UArFaceTryOn`, `UArImageTrigger`, `UArCodeView`, `UArOverlayLayer`, `UArGate`, `UArPage`, `UArView` |
| Process | `UProcessView`, `UProcessController`, `UProcessFields`, `UProcessStepsIndicator`, `UProcessTextField`, `UProcessImagePickerField`, `UProcessESignField`, `UProcessVisualAuthField`, `UProcessStyle` |

## Example app

A full **multi-page gallery** lives in [`example/`](example). It covers components (inputs, layout,
charts, documents, media, AR / process), utilities (app, storage, files, launch & share, location
& notifications, crypto, Persian dates, extensions, backend) and showcases (camera studio, scanner,
media player, document reader, downloads, audio and video notes). Each page shows a live widget
next to the code that produced it.

```bash
cd example
flutter run          # mobile
flutter run -d chrome
flutter run -d macos
```

## Project layout

```
lib/
  utilities.dart      the one import
  init.dart           initU(), UMaterialApp, U
  utils/              documented static helpers you call (UApp, ULaunch, ULocation, …)
  utils/extensions/   extension methods
  components/         widgets
  src/<feature>/      engines and platform channels (device, launch, location, notification,
                      share, media, camera, files, doc, barcode, crypto, ar, iso8583, cli, …)
android/ ios/ macos/ linux/ windows/   native code, one folder per feature
bin/app.dart          the `dart run u:app` CLI
```

Every public member has a one-line doc comment that says what it does, gives an example, and names
the permission and platforms it needs.

## Conventions

Projects using `u` follow a few house rules, enforced by `analysis_options.yaml`:
- Use theme colors only, with no hard-coded `Colors.*`.
- Use double quotes and explicit types.
- Use `const` / `final` where possible.
- Put every user-facing string through localization with `U.s`.

## License

[MIT](LICENSE) © [SinaMN75](https://sinamn75.com)
