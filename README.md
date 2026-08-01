<div align="center">

# u

### The only package you need.

A batteries-included Flutter **plugin** — a curated set of UI components, utilities, extension
methods, a typed API layer, and native platform features, behind a **single import**.

[![pub package](https://img.shields.io/pub/v/u.svg)](https://pub.dev/packages/u)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20macos%20%7C%20windows%20%7C%20linux-blue.svg)](https://pub.dev/packages/u)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

</div>

```dart
import "package:u/utilities.dart";
```

That one line brings in Flutter's material library **plus** every component, utility, extension,
enum, API service, and native feature below. No barrel juggling, no dozens of small imports.

---

## Why u?

- **One import, everything.** UI kit, formatters, date/Jalali tools, storage, navigation, an API
  layer, and native features — all re-exported from `package:u/utilities.dart`.
- **Consistent, themed UI.** `UText*`, `UButton`, `UTextField`, `UScaffold`, `UCard`, `UColumn`,
  `URow`, and 40+ more components that read from your `ThemeData` and stay visually coherent.
- **Context-free helpers.** `UToast`, `UNavigator`, and `ULoading` work from anywhere — no
  `BuildContext` needed.
- **A typed network layer.** `UServices.<area>.<method>(...)` with success / error / exception
  callbacks, automatic token handling, and JWT refresh.
- **Persian / Iran first-class.** Jalali dates, Persian ⇄ Latin digits, Rial/Toman money
  formatting, phone-operator detection, national-code validation, license-plate input.
- **Native platform features.** Screenshot / screen-recording prevention (`ScreenGuard`) with a
  clean, extensible plugin-folder convention for adding more.

## Platform support

| Feature area            | Android | iOS | Web | macOS | Windows | Linux |
| ----------------------- | :-----: | :-: | :-: | :---: | :-----: | :---: |
| UI / utils / extensions |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| API layer (`UServices`) |   ✅    | ✅  | ✅  |  ✅   |   ✅    |  ✅   |
| `ScreenGuard`           |   ✅    | ✅  | ⬜  |  ✅   |   ✅    |  ⬜   |

⬜ = safe no-op (no OS API to prevent capture).

## Install

```yaml
dependencies:
  u:
    git:
      url: https://github.com/SinaMN75/U_flutter.git
```

Requires Flutter ≥ 3.44.8 and Dart SDK ≥ 3.12.2.

## Quick start

```dart
import "package:u/utilities.dart";

void main() {
  // Point the API layer at your backend (only if you use UServices).
  U.baseUrl = "https://api.example.com";
  U.apiKey = "YOUR_API_KEY";
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    // Lets UToast / UNavigator / ULoading work without a BuildContext.
    navigatorKey: navigatorKey,
    // u widgets read localized strings via U.s — register the delegate.
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: const HomePage(),
  );
}
```

## What's inside

### Text — `UText*`
A widget per Material 3 type-scale role: `UTextDisplayLarge/Medium/Small`,
`UTextHeadline*`, `UTextTitle*`, `UTextBody*`, `UTextLabel*`, plus `UAnimatedCounter`.
The string is positional; styling (color, weight, maxLines, decoration…) is named.

```dart
UTextTitleLarge("Welcome", fontWeight: FontWeight.w700);
UTextBodyMedium("Body text", color: Theme.of(context).colorScheme.onSurfaceVariant);
```

### Buttons — `UButton`
Every style via `UButtonType` (`elevated`, `text`, `outlined`, `icon`, `fab`, `cupertino`,
`custom`), with icons, gradients, loading/disabled states, and a built-in tap counter.
Also `UButtonSubmitCancel`, `UPressable`, `USendAgainCountDown`.

```dart
UButton(title: "Save", isLoading: saving, onTap: save);
```

### Inputs
`UTextField`, `UTextFieldPhoneNumber`, `UTextFieldDatePicker`, `UTextFieldAutoComplete(Async)`,
`UDropDownField`, `UCountryProvincePicker`, `UOtpField`, `UPlateField` (Iranian plate),
`UChipChoice`, `USegmentedControl`, `USlider`, `URichTextEditor`, `USignaturePad`, and
`UValidators` (email, phone, length, national code, …) for `validator:`.

### Layout & scaffolding
`UScaffold`, `UContainer`, `UColumn`, `URow` (Column/Row with spacing + decoration built in),
`UCard`, `UGlassCard`, `UHeaderCard`, `UListView`, `UListTile`, `UTabBar`, `USideMenu`,
`UEmptyState`, `UErrorRetry`.

### Feedback — context-free
`UToast.success/error/warning/info`, `UNavigator.confirmAsync/inputDialog/bottomSheet/dialog`,
`ULoading.show/dismiss`, `UProgressLinear/Circular`, `RatingBar`.

### Media, files & viz
`UImage` (network/asset/file/memory), `CachedNetworkImage`, `UImageViewer`, `UFilePicker`,
`UScanner` (QR/barcode), `UBarcode`, `UPdfViewer`, `UHtmlView`, `UWebView`, `UCreditCard`,
`UCartesianChart`, `UGauge`, percent indicators, `UJsonViewer`, `UMap`, `UChat`, `UProcessView`
(multi-step form engine), `WidgetToImage`.

### Formatters & extensions
Call directly on values:

```dart
1500000.rial();                 // "1,500,000 ﷼"
1500000.toman();                // Toman formatting
1250000.toKMB();                // "1.25M"
1234567.separate3By3();         // "1,234,567"
"2026-08-01".toPersianNumber(); // Persian digits
DateTime.now().toJalaliDate();  // Jalali date
someDate.toTimeAgo();           // "3 hours ago"
```

Widget sugar makes layouts fluent:

```dart
myWidget.pAll(16).onTap(onPress).card();   // Padding → tappable → card
row.rtl();                                  // right-to-left subtree
```

There are also rich `String`, `int`/`double`, `Iterable`, `Map`, `DateTime`, and
`TextEditingController` extensions.

### API layer — `UServices`
One shape for every call: `UServices.<area>.<method>(p:, onOk:, onError:, onException:)`.

```dart
await UServices.auth.login(
  p: ULoginParams(email: email, password: password),
  onOk: (UResponse<ULoginResponse> r) => UNavigator.push(const HomePage()),
  onError: (UEmptyResponse e) => UToast.error(message: e.message ?? "Login failed"),
  onException: (String e) => UToast.error(message: e),
);
```

31 service areas: `auth, user, product, content, category, comment, follow, media, wallet, ipg,
txn, merchant, terminal, bankAccount, moadi, inquiry, chargeInternet, sim, vehicle, parking,
hotel, ticket, notification, pn, blog, address, accounting, appSettings, dashboard, process,
fileManager` — each with matching `*Params` / `*Response` models. Payment/IPG flows included.

### `ScreenGuard` — native screenshot / recording prevention

```dart
await ScreenGuard.enable();   // block capture
await ScreenGuard.disable();  // allow again

ScreenGuard.onScreenshot = () => log("screenshot taken");
ScreenGuard.onScreenRecording = (bool active) => setState(() => recording = active);
```

Implemented natively per platform: `FLAG_SECURE` (Android), secure-field + detection callbacks
(iOS), `NSWindow.sharingType = .none` (macOS), `WDA_EXCLUDEFROMCAPTURE` (Windows). Linux and web
are safe no-ops.

Each native feature lives in a self-contained folder with its own method channel `u/<feature>`,
so adding another native capability is a well-defined, repeatable change.

### `u_admin`
A complete GetX-based admin panel bundled with the plugin (login, dashboards, blog, CMS, file
manager, hotel/dorm suite, parking, payments, wallet, users, logs, push, settings). Reuse the
pages (`UAdminSplashPage`, `UAdminLoginPage`, …) instead of rebuilding admin screens.

## Complete API reference

Everything below is exported from the single `package:u/utilities.dart` import.

### Components — Text
`UTextDisplayLarge` · `UTextDisplayMedium` · `UTextDisplaySmall` · `UTextHeadlineLarge` ·
`UTextHeadlineMedium` · `UTextHeadlineSmall` · `UTextTitleLarge` · `UTextTitleMedium` ·
`UTextTitleSmall` · `UTextBodyLarge` · `UTextBodyMedium` · `UTextBodySmall` · `UTextLabelLarge` ·
`UTextLabelMedium` · `UTextLabelSmall` · `UAnimatedCounter`

### Components — Buttons & inputs
`UButton` · `UButtonSubmitCancel` · `UPressable` · `USendAgainCountDown` · `UTextField` ·
`UDropDownField` · `UTextFieldDatePicker` · `UTextFieldAutoComplete` · `UTextFieldAutoCompleteAsync` ·
`UTextFieldPhoneNumber` · `UOtpField` · `UPlateField` · `UChipChoice` · `USegmentedControl` ·
`USlider` · `UCategorySelector` · `UCountryProvincePicker` · `UCurrencyInputFormatter` ·
`URichTextEditor` · `USignaturePad`

### Components — Layout & navigation
`UScaffold` · `UContainer` · `UColumn` · `URow` · `UCard` · `UGlassCard` · `UHeaderCard` ·
`UListView` · `UListTile` · `UDefaultTabBar` · `UIconTextHorizontal` · `UIconTextVertical` ·
`UIconBackground` · `UImageBackground` · `UIconPrimary` · `UEmptyState` · `UErrorRetry` ·
`UAnimationCard` · `USideMenu` (`USideMenuController`, `USideMenuTheme`, `UMenuItem`, `UMenuGroup`,
`UMenuHeader`) · `UTabBar` (`UTab`, `UTabBarTheme`)

### Components — Feedback & indicators
`UProgressLinear` · `UProgressCircular` · `CircularPercentIndicator` · `LinearPercentIndicator` ·
`RatingBar` · `RatingBarIndicator` · `BadgeWidget` · `UProgress`

### Components — Media & files
`UImage` · `UImageNetwork` · `UImageAsset` · `UImageFile` · `UImageMemory` · `CachedNetworkImage` ·
`UImageViewer` · `BetterImageViewer` · `ImageGalleryViewer` · `UFilePicker` · `UScanner`
(`UScannerPage`) · `UBarcode` · `UPdfViewer` · `UHtmlView` · `UWebView` · `WidgetToImage`

### Components — Data viz & motion
`UCartesianChart` · `UGauge` (`UGaugeRange`, `UGaugeAnnotation`) · `UJsonViewer` ·
`UNumberPagination` · `UMap` · `UChat` · `FlipCard` · `ReadMoreText` · `ScrollingText` ·
`CreditCardWidget` (`CreditCardForm`, `CreditCardModel`, `CardBrandDetector`) ·
`JalaliDatePickerDialog`

### Components — Process engine
`UProcessView` · `UProcessController` · `UProcessFields` · `UProcessStepsIndicator` ·
`UProcessTextField` · `UProcessImagePickerField` · `UProcessESignField` ·
`UProcessVisualAuthField` · `UProcessStyle`

### Utilities (`abstract`/static classes)
| Class | Purpose |
| --- | --- |
| `U` | App root config: `baseUrl`, `apiKey`, `user`, `contents`, `categories`, tabs, `s` (l10n) |
| `UServices` | Entry point to all 31 API service areas |
| `UHttpClient` | Low-level HTTP: `send`, `upload`, multipart, `downloadFile`, progress |
| `ULocalStorage` / `UFileStorage` | Key-value + file persistence (expiry, encryption) |
| `UNavigator` | `push/off/offAll`, `dialog`, `alert`, `confirm(Async)`, `inputDialog`, `bottomSheet`, `datePicker`, `colorPicker`, `timePicker`, overlays |
| `UToast` | `success/error/warning/info`, `snackBar`, `banner`, `toast` |
| `ULoading` | Global blocking spinner: `show`, `dismiss`, `isShowing` |
| `UValidators` | `required`, `email`, `phone`, `minLength/maxLength/exactLength`, `iranianNationalCode`, `url`, `password`, `complexPassword`, `match`, `pattern`, `numberRange` |
| `UEncryption` | AES/Salsa20/Fernet, base64/hex, md5/sha1/sha256/384/512, HMAC, key/iv gen |
| `PersianTools` | National-code/card validation, bank lookup, Sheba, number↔words, digit conversion, phone details |
| `UPhoneNumberUtils` | `normalizePhone`, operator/SIM detection |
| `Jalali` / `Gregorian` / `DateFormatter` | Shamsi ⇄ Gregorian conversion and formatting |
| `ULaunch` | `launchURL`, `call`, `sms`, WhatsApp/Telegram/Instagram/maps/email |
| `UShare` | Share text/link/files/bytes/widget image |
| `UClipboard` | `set`, `getText` |
| `ULocation` | `getUserLocation` (geolocator) |
| `UNetwork` | `hasWifi/Cellular/Vpn/Ethernet/Bluetooth/NetworkConnection` |
| `UNotification` | Local notifications |
| `UCrashlytics` | Error reporting |
| `UApp` | Orientation/size/form-factor helpers, theme + locale switch |
| `UUUID` | `uuidV1/V4/V5/V6/V7/V8` |
| `UConstants` | Shared constants, `loremPicsum` |
| `UUpdateDialog` | Force/soft update flow |
| `UDebouncer` | Debounce callbacks |

### Extensions (available globally after import)
| On | Highlights |
| --- | --- |
| `Widget` | `pAll/pSymmetric/pOnly`, `onTap/onTapInk/onLongPress/onDoubleTap`, `expanded/fit`, `ltr/rtl`, `scale/rotate/translate/position`, `safeArea/form/scrollable`, `card/container`, `showMenus`, full `alignAt*` family |
| `String` / `String?` | money (`rial/toman`), Jalali (`toJalaliDate/DateTime`), `toPersianNumber/toLatinNumber`, `separateNumbers3By3`, `isNullOrEmpty/isNumeric`, `toInt/toDouble`, `maxLength`, `getDay/Month/Year`, `toTimeAgo` |
| `int` / `double` (+ nullable) | `rial/toman/rialToToman`, `separate3By3`, `toKMB`, `toStringAsSmartRound`, `secondsToTimeLeft`, month names |
| `num` | `toBKMG` |
| `Iterable<T>` / `Iterable<T>?` | `mapIndexed`, `forEachIndexed`, `firstOrDefault`, `containsAll/Any`, `isNullOrEmpty`, `addAndReturn`, `insertAndReturn`, `takeIfPossible` |
| `Map<K,V>` | `add(k, v)` (chainable request-body builder) |
| `DateTime` | `formatDate`, `toJalali(Date/DateTime)`, `toTimeAgo`, `utcNow` |
| `TextEditingController` | `numString/numInt/numDouble`, `valueOrNull`, `isNullOrEmpty` |
| `Uint8List` | `toBase64/toBase64Url` |

### API services (`UServices.<area>`)
`auth` · `user` · `product` · `content` · `category` · `comment` · `follow` · `media` · `wallet` ·
`ipg` · `txn` · `merchant` · `terminal` · `bankAccount` · `moadi` · `inquiry` · `chargeInternet` ·
`sim` · `vehicle` · `parking` · `hotel` · `ticket` · `notification` · `pn` · `blog` · `address` ·
`accounting` · `appSettings` · `dashboard` · `process` · `fileManager`

## Example

A full **multi-page gallery** app lives in [`example/`](example) demonstrating every area above,
each with a live widget and the exact code that produced it.

```bash
cd example
flutter run          # mobile
flutter run -d chrome
flutter run -d macos
```

## Conventions

Projects using `u` follow a few house rules (enforced by `analysis_options.yaml`): theme colors
only (no hard-coded `Colors.*`), double quotes, explicit types, `const`/`final` where possible,
and localized strings via `U.s` for anything user-facing.

## License

[MIT](LICENSE) © [SinaMN75](https://sinamn75.com)
