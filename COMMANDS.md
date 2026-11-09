# Commands

Every command you need for an app that uses `u`, with no extra package. Run them in the **app's
folder** (the one with the app's `pubspec.yaml`), not in this plugin.

- **`dart run u:app …`** is u's own CLI (`bin/app.dart`, `lib/src/cli`). It is plain Dart, so the
  same command works on **Windows, macOS and Linux**. It edits the native files of all 6 platforms
  (Android, iOS, macOS, Linux, Windows, web), keeps their formatting and is safe to run again: a
  second run prints `Nothing to change`.
- **`flutter …` / `dart …`** are the official tools. They are the same on every OS too.
- Only a few build steps need a specific OS (iOS and macOS need a Mac, Windows apps need Windows,
  Linux apps need Linux). That is a Flutter rule, not a u rule.

Contents

1. [Options every u:app command takes](#1-options-every-uapp-command-takes)
2. [Look around: help, info, doctor](#2-look-around-help-info-doctor)
3. [App icon (replaces flutter_launcher_icons)](#3-app-icon-replaces-flutter_launcher_icons)
4. [Splash screen (replaces flutter_native_splash)](#4-splash-screen-replaces-flutter_native_splash)
5. [Release builds: `u:app build`](#5-release-builds-uapp-build)
6. [Name, id and version](#6-name-id-and-version)
7. [SDK levels](#7-sdk-levels)
8. [Permissions](#8-permissions)
9. [Orientation, deep links, sharing, other apps](#9-orientation-deep-links-sharing-other-apps)
10. [Apple: team, Swift Package Manager](#10-apple-team-swift-package-manager)
11. [Desktop and web identity](#11-desktop-and-web-identity)
12. [Android release signing](#12-android-release-signing)
13. [Official Flutter and Dart commands](#13-official-flutter-and-dart-commands)
14. [Release builds without u:app (per OS)](#14-release-builds-without-uapp-per-os)
15. [Moving off flutter_launcher_icons and flutter_native_splash](#15-moving-off-flutter_launcher_icons-and-flutter_native_splash)

---

## 1. Options every u:app command takes

| Option | What it does |
| --- | --- |
| `--platforms android,ios` (or `--platform`) | Only touch these platforms. Names: `android`, `ios`, `macos` (`mac`, `osx`), `linux`, `windows` (`win`), `web`. |
| `--dry-run` (or `-n`) | Print what would change and write nothing. For `build`, print the commands without running them. |
| `--help` (or `-h`) | Usage, aliases and examples of that command. |

Options take a value as `--key value` or `--key=value`. Use the `=` form when the value itself
starts with `--`.

```bash
dart run u:app permission add camera --platforms android,ios
dart run u:app name "My Shop" --dry-run
dart run u:app icon --help
```

---

## 2. Look around: help, info, doctor

| Command | What it does |
| --- | --- |
| `dart run u:app` / `dart run u:app help` | All commands with a one-line summary. |
| `dart run u:app help <command>` / `dart run u:app <command> --help` | Usage, aliases and examples of one command. |
| `dart run u:app info` (aliases `show`, `status`) | Name, id, version, SDK levels, permissions, deep links… of every platform. |
| `dart run u:app doctor` (alias `check`) | Template leftovers (`com.example`, debug signing, missing INTERNET…) and settings that disagree between platforms, each with the command that fixes it. |

```bash
dart run u:app help
dart run u:app help permission
dart run u:app info
dart run u:app info --platforms android
dart run u:app doctor
```

---

## 3. App icon (replaces flutter_launcher_icons)

```
dart run u:app icon <image.png> [--background <#hex|image.png>] [--foreground <image.png>]
                                [--monochrome [image.png]] [--inset <percent>] [--ios-background <#hex>]
```

Aliases: `icons`, `launcher-icon`, `app-icon`. Give it one square PNG, 1024×1024 or larger (a
non-square image is centered on a transparent square). Any PNG works: RGB, RGBA, gray, palette,
16-bit, interlaced. The PNG decoder, resizer and the `.ico` writer are part of u, so there is
nothing to install.

What it writes:

| Platform | Files |
| --- | --- |
| Android | `mipmap-*dpi/ic_launcher.png` (48–192 px) and `android:icon="@mipmap/ic_launcher"` in the manifest. With `--background`: an adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml`, `drawable-*dpi/ic_launcher_foreground.png` 108–432 px, the background color in `values/ic_launcher_background.xml` or a background image). With `--monochrome`: the Android 13+ themed icon. |
| iOS | Every size of `AppIcon.appiconset` plus `Contents.json`. Transparent parts are filled with a color (the App Store rejects icons with alpha), and the PNGs are saved without an alpha channel. |
| macOS | `AppIcon.appiconset` 16–1024 px plus `Contents.json` (transparency kept). |
| Windows | `windows/runner/resources/app_icon.ico` with 16, 20, 24, 32, 40, 48, 64, 96, 128 and 256 px. |
| Linux | `linux/runner/resources/app_icon.png` (512 px), an install rule in `linux/CMakeLists.txt` and the window icon in `my_application.cc`. Flutter's template has no Linux icon at all. |
| Web | `favicon.png` (32 px), `icons/Icon-192.png`, `Icon-512.png` and the maskable `Icon-maskable-192.png` / `Icon-maskable-512.png` (logo inside the 80% safe zone on the background). |

| Option | Meaning |
| --- | --- |
| `--background <#hex>` | Makes the Android icon adaptive with this background color. Also the iOS fill color and the web maskable background. |
| `--background <image.png>` | Same, with an image as the adaptive background (scaled to cover). |
| `--foreground <image.png>` | The adaptive foreground (and web maskable logo). Default: the main image. |
| `--monochrome` | Android 13+ themed icon made from the foreground's shape (every pixel white, alpha kept). |
| `--monochrome <image.png>` | Themed icon from your own single-color image. |
| `--inset <percent>` | Empty margin around the adaptive foreground, per side. Default `16` (the same as flutter_launcher_icons). Use `20`–`25` if launchers cut your logo. |
| `--ios-background <#hex>` | iOS fill color for transparent parts. Default: the `--background` color, otherwise white. |

Without `--background` the Android icon is the plain image, and any old adaptive icon files are
deleted (otherwise Android 8+ would keep showing the old adaptive icon).

```bash
# one image, plain icon everywhere
dart run u:app icon assets/icon.png

# adaptive Android icon on white
dart run u:app icon assets/icon.png --background "#FFFFFF"

# adaptive icon with a separate foreground and the Android 13+ themed icon
dart run u:app icon assets/icon.png --background "#0175C2" --foreground assets/icon_foreground.png --monochrome

# themed icon from your own image
dart run u:app icon assets/icon.png --background "#0175C2" --monochrome assets/icon_mono.png

# background image and a bigger safe margin
dart run u:app icon assets/icon.png --background assets/icon_background.png --inset 20

# black fill on iOS instead of white
dart run u:app icon assets/icon.png --ios-background "#000000"

# only some platforms
dart run u:app icon assets/icon.png --platforms android,ios
dart run u:app icon assets/icon.png --platforms web
dart run u:app icon assets/icon.png --platforms windows,linux,macos

# preview
dart run u:app icon assets/icon.png --background "#FFFFFF" --dry-run
```

---

## 4. Splash screen (replaces flutter_native_splash)

```
dart run u:app splash [--color <#hex>] [--image <png>] [--size <dp>] [--background-image <png>]
                      [--branding <png>] [--android12-image <png>] [--icon-background <#hex>]
                      [--dark-color <#hex>] [--dark-image <png>] [--dark-background-image <png>]
                      [--dark-branding <png>] [--android12-dark-image <png>] [--dark-icon-background <#hex>]
                      [--fullscreen]
dart run u:app splash remove
```

Aliases: `launch-screen`, `splash-screen`. The native splash is what the OS shows before Flutter
draws its first frame. It disappears by itself on that first frame, so no Dart code is needed.
Every run rewrites the whole splash from the options you give, so options you leave out are
turned off.

What it writes:

| Platform | Files |
| --- | --- |
| Android (up to 11) | `drawable/launch_background.xml` and `drawable-v21/launch_background.xml` (color or background image, centered logo, branding at the bottom), the logo in every density, `values/splash.xml` with the colors. |
| Android 12+ | `values-v31/styles.xml` and `values-night-v31/styles.xml` with `windowSplashScreenBackground`, `windowSplashScreenAnimatedIcon`, the icon background and the branding image. The 12+ icon is your logo fitted inside the 192 dp circle Android masks it with, so it is never cut. |
| iOS | `LaunchBackground`, `LaunchImage` and `BrandingImage` image sets (@1x, @2x, @3x, with dark variants) and a new `LaunchScreen.storyboard`. |
| Web | Logo and branding images in `web/splash/` (1x–4x) and a block in `web/index.html` (between `<!-- u:splash -->` markers) that shows them and removes itself on `flutter-first-frame`. |
| macOS, Linux, Windows | Nothing: desktop windows only open on Flutter's first frame. |

| Option | Meaning |
| --- | --- |
| `--color <#hex>` | Background color. Default white. |
| `--image <png>` | Centered logo. It is treated as a 4x image (a 640 px wide PNG shows 160 dp wide). |
| `--size <dp>` | Logo width in dp / points / CSS px. Overrides the 4x rule. |
| `--background-image <png>` | Full-screen background image, scaled to cover (Android up to 11, iOS, web). Android 12+ only supports a color, so it uses `--color` there. |
| `--branding <png>` | Small image at the bottom (also a 4x image). |
| `--android12-image <png>` | Your own Android 12+ icon: a square canvas of 288 dp whose content stays inside the center 192 dp circle. Default: made from `--image`. |
| `--icon-background <#hex>` | Android 12+ circle behind the icon. |
| `--dark-color`, `--dark-image`, `--dark-background-image`, `--dark-branding`, `--android12-dark-image`, `--dark-icon-background` | The same for dark mode. Anything you leave out uses the light value. |
| `--fullscreen` | Hides the status bar during launch (Android `windowFullscreen`, iOS `UIStatusBarHidden`). |
| `remove` | Restores Flutter's default white launch screen and deletes every file the command made. |

```bash
# just a color
dart run u:app splash --color "#FFFFFF"

# color and logo
dart run u:app splash --color "#FFFFFF" --image assets/logo.png

# logo 160 dp wide whatever its pixel size
dart run u:app splash --color "#FFFFFF" --image assets/logo.png --size 160

# dark mode with its own color and logo
dart run u:app splash --color "#FFFFFF" --image assets/logo.png --dark-color "#121212" --dark-image assets/logo_dark.png

# dark mode with only another color
dart run u:app splash --color "#FFFFFF" --image assets/logo.png --dark-color "#000000"

# branding at the bottom, no status bar
dart run u:app splash --color "#FFFFFF" --image assets/logo.png --branding assets/brand.png --fullscreen

# full-screen background image
dart run u:app splash --background-image assets/splash_bg.png --image assets/logo.png
dart run u:app splash --background-image assets/splash_bg.png --dark-background-image assets/splash_bg_dark.png

# Android 12+: own icon and a colored circle behind it
dart run u:app splash --color "#FFFFFF" --image assets/logo.png --android12-image assets/logo_a12.png --icon-background "#0175C2"

# only some platforms
dart run u:app splash --color "#FFFFFF" --image assets/logo.png --platforms android,ios
dart run u:app splash --color "#FFFFFF" --image assets/logo.png --platforms web

# back to Flutter's default
dart run u:app splash remove
dart run u:app splash remove --platforms web

# preview
dart run u:app splash --color "#FFFFFF" --image assets/logo.png --dry-run
```

---

## 5. Release builds: `u:app build`

```
dart run u:app build <apk|aab|ios|ipa|macos|windows|linux|web|all>... [--out <folder>] [--no-clean]
                     [--fail-fast] [--web <variants>] [--args="<extra flutter build flags>"]
```

Alias: `release`. One command for any mix of targets, on any OS. It runs `flutter clean` and
`flutter pub get` once, builds each target in release mode and copies the result to your Desktop
as `<name>-<version>` (from `pubspec.yaml`; `1.2.3+7` gives `123`). The zip files are made by u
itself, so no `zip` tool is needed (Linux bundles keep their file permissions).

A target (or one web variant) that fails does not stop the others. The error is printed, the next target builds, and the
end of the output lists what was created, what failed and why, and the command that rebuilds only
the failed targets (for example `dart run u:app build ios --no-clean`). The command then exits with
code 1, so scripts and CI still see the failure. Add `--fail-fast` to stop at the first failure
instead. A failing `flutter clean` or `flutter pub get` always stops everything, because no target
can build without them.

| Target | Aliases | Runs | You get | Needs |
| --- | --- | --- | --- | --- |
| `apk` | `android` | `flutter build apk --target-platform android-arm64,android-arm --release` | `<name>-<v>.apk` | any OS |
| `aab` | `appbundle`, `bundle` | `flutter build appbundle --release` | `<name>-<v>.aab` (Google Play) | any OS |
| `ios` | `archive`, `xcarchive` | `flutter build ios --release --no-codesign`, then `xcodebuild … archive`, then opens Xcode | an archive in Xcode → Window → Organizer, ready to distribute | macOS |
| `ipa` | | `flutter build ipa --release` | `<name>-<v>.ipa` | macOS, signing set up |
| `macos` | `mac`, `osx` | `flutter build macos --release`, then `ditto` | `<name>-<v>-macos.zip` with the `.app` | macOS |
| `windows` | `win` | `flutter build windows --release` | `<name>-<v>-windows.zip` | Windows |
| `linux` | | `flutter build linux --release` | `<name>-<v>-linux.zip` | Linux |
| `web` | | `flutter build web --release --dart-define=U_BUILD_ID=<version>` four times (see the table below) | four zips: JavaScript and WebAssembly, each with the renderer from Google's CDN and bundled | any OS |
| `all` | | every target above that this OS can build and the app has (apk, ios, macos, windows, linux, web) | | |

| Option | Meaning |
| --- | --- |
| `--out <folder>` | Where the files go. Default: your Desktop (`%USERPROFILE%\Desktop` on Windows, `~/Desktop` elsewhere), or `build/release` when there is no Desktop folder. |
| `--no-clean` | Skip `flutter clean` (faster, for a second build of the same code or to retry the failed targets). |
| `--fail-fast` | Stop at the first target that fails. By default the other targets still build. |
| `--web <variants>` | Which web builds to make, comma separated. Default `all`. See the table below. |
| `--args="…"` | Extra flags for every `flutter build`, e.g. `--obfuscate --split-debug-info=build/symbols`, `--flavor prod`, `--dart-define=KEY=VALUE`. |
| `--dry-run` | Print the commands without running anything. |

Targets can be separate words or comma separated (`build apk,web`).

Web builds (`--web`):

| Variant | Extra flags | Zip | Use it when |
| --- | --- | --- | --- |
| `cdn` | none | `<name>-<v>-web.zip` | Normal hosting. The renderer (CanvasKit) loads from Google's CDN. |
| `no-cdn` | `--no-web-resources-cdn` | `<name>-<v>-web-no-cdn.zip` | Networks that block Google's CDN (or no internet). The renderer is inside the zip. |
| `wasm` | `--wasm` | `<name>-<v>-web-wasm.zip` | Faster start and smoother frames in browsers with WasmGC (Chrome, Edge, Firefox, Safari 18.2+). Other browsers get the JavaScript build in the same zip. Needs the server to send the `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers for multi-threaded rendering. |
| `wasm-no-cdn` | `--wasm --no-web-resources-cdn` | `<name>-<v>-web-wasm-no-cdn.zip` | WebAssembly where Google's CDN is blocked. |
| `all` | | all four | The default. |
| `js` (or `both`) | | `cdn` + `no-cdn` | The two JavaScript builds only. |
| `wasm-all` | | `wasm` + `wasm-no-cdn` | The two WebAssembly builds only. |

Each web build starts from an empty `build/web` and is zipped right away. A variant that fails (for
example a package that does not compile to WebAssembly) doesn't stop the others; the retry command
names only the failed variants, e.g. `dart run u:app build web --web wasm,wasm-no-cdn --no-clean`.

Every combination, the same on every OS (iOS and macOS need a Mac):

```bash
# one target
dart run u:app build apk
dart run u:app build aab
dart run u:app build ios
dart run u:app build ipa
dart run u:app build web
dart run u:app build macos
dart run u:app build windows
dart run u:app build linux

# Android + one more
dart run u:app build apk aab
dart run u:app build apk ios
dart run u:app build apk web
dart run u:app build apk macos
dart run u:app build apk windows
dart run u:app build apk linux

# three or more
dart run u:app build apk ios web
dart run u:app build apk macos web
dart run u:app build apk ios macos
dart run u:app build apk ios macos web
dart run u:app build apk aab ios macos web
dart run u:app build apk windows web
dart run u:app build apk linux web

# everything this computer can build
dart run u:app build all

# variations
dart run u:app build web                                  # all four web zips
dart run u:app build web --web js                         # JavaScript, with and without the CDN
dart run u:app build web --web wasm-all                   # WebAssembly, with and without the CDN
dart run u:app build web --web cdn
dart run u:app build web --web no-cdn
dart run u:app build web --web wasm
dart run u:app build web --web wasm-no-cdn
dart run u:app build web --web cdn,wasm                   # any mix, comma separated
dart run u:app build apk web --web js
dart run u:app build apk --no-clean
dart run u:app build all --fail-fast
dart run u:app build apk web --out build/release
dart run u:app build apk --args="--obfuscate --split-debug-info=build/symbols"
dart run u:app build apk aab --args="--flavor prod"
dart run u:app build apk ios web --dry-run
```

`U_BUILD_ID` is passed to web builds so u can tell a new deployment from a cached one. To raise the
version first: `dart run u:app bump`, then build.

---

## 6. Name, id and version

| Command | What it does | Platforms |
| --- | --- | --- |
| `name <name> [--short <web short name>]` (aliases `rename`, `label`) | The name users see: launcher, home screen, window title, browser tab. | all 6 |
| `id <com.company.app> [--android <id>] [--ios <id>] [--macos <id>] [--linux <id>]` (aliases `bundle-id`, `package`, `app-id`) | applicationId / bundle id. On Android it also moves `MainActivity` into the new package. | Android, iOS, macOS, Linux |
| `version <x.y.z+build>` | Sets `version:` in pubspec.yaml (every platform reads it). | all 6 |
| `bump [build\|patch\|minor\|major]` | Raises the version. The build number always goes up. | all 6 |
| `description <text>` | pubspec description, web manifest and `<meta name="description">`. | all 6 |

```bash
dart run u:app name "My Shop"
dart run u:app name "فروشگاه من"
dart run u:app name "My Shop" --short "Shop"
dart run u:app name "My Shop" --platforms android,ios
dart run u:app id com.company.shop
dart run u:app id com.company.shop --ios com.company.shopIos
dart run u:app id com.company.shop --ios com.company.shopIos --macos com.company.shopMac
dart run u:app id com.company.shop --android com.company.shop.android --linux com.company.shop.linux
dart run u:app version 1.0.0+1
dart run u:app bump            # 1.2.3+7 → 1.2.3+8
dart run u:app bump build      # same as above
dart run u:app bump patch      # 1.2.3+7 → 1.2.4+8
dart run u:app bump minor      # 1.2.3+7 → 1.3.0+8
dart run u:app bump major      # 1.2.3+7 → 2.0.0+8
dart run u:app description "Order food in two taps"
```

---

## 7. SDK levels

| Command | What it does |
| --- | --- |
| `min-sdk <platform> <version> [<platform> <version> …]` (aliases `min`, `minsdk`, `min-os`) | Minimum OS: `android` (API level), `ios`, `macos`. Also updates the Podfile. `android default` restores Flutter's value. |
| `target-sdk <level\|default>` | Android targetSdk. |
| `compile-sdk <level\|default>` | Android compileSdk. |
| `ndk <version\|default>` | Android ndkVersion (fixes "plugin requires a newer NDK"). |
| `java <8\|11\|17\|21>` | Android Java source/target and Kotlin jvmTarget. |

```bash
dart run u:app min-sdk android 24
dart run u:app min-sdk ios 18
dart run u:app min-sdk macos 15
dart run u:app min-sdk android 24 ios 18
dart run u:app min-sdk android 24 ios 18 macos 14
dart run u:app min-sdk android default
dart run u:app target-sdk 36
dart run u:app target-sdk default
dart run u:app compile-sdk 36
dart run u:app compile-sdk default
dart run u:app ndk 27.0.12077973
dart run u:app ndk default
dart run u:app java 17
```

---

## 8. Permissions

```
dart run u:app permission [list|add|remove] <names...> [--message <iOS/macOS prompt text>]
```

Aliases: `permissions`, `perm`. One friendly name writes everything that permission needs:
Android `<uses-permission>`, `<uses-feature>` and services, iOS/macOS Info.plist usage strings,
`UIBackgroundModes` and macOS sandbox entitlements. Names can be separate words or comma
separated. Where a store reviews a permission (background location, SMS, full-screen intents, APK
installs) the command prints a note.

Names: `internet`, `network-state`, `camera`, `microphone`, `speech`, `location`,
`location-always`, `photos`, `save-photos`, `music`, `storage`, `contacts`, `calendar`,
`reminders`, `bluetooth`, `notifications`, `alarm`, `full-screen`, `vibrate`, `biometric`,
`motion`, `nfc`, `phone`, `sms`, `wake-lock`, `foreground-service`, `background-audio`,
`background-fetch`, `remote-notifications`, `local-network`, `tracking`, `install-apk`, `overlay`.

```bash
dart run u:app permission list
dart run u:app permission add internet
dart run u:app permission add camera microphone
dart run u:app permission add internet,location,notifications
dart run u:app permission add location
dart run u:app permission add location-always
dart run u:app permission add photos save-photos
dart run u:app permission add notifications alarm vibrate
dart run u:app permission add bluetooth
dart run u:app permission add nfc
dart run u:app permission add camera --message "We need the camera to scan QR codes"
dart run u:app permission add location --message "We show stores near you"
dart run u:app permission remove contacts
dart run u:app permission remove camera microphone
dart run u:app permission add camera --platforms android
```

---

## 9. Orientation, deep links, sharing, other apps

| Command | What it does | Platforms |
| --- | --- | --- |
| `orientation <portrait\|landscape\|all>` | Locks or frees the screen orientation. | Android, iOS, web |
| `deep-link [add\|remove] <scheme> [--host <host>]` (aliases `scheme`, `url-scheme`) | Registers `myapp://` links. | Android, iOS, macOS |
| `share-target [add\|remove] [image\|video\|audio\|text\|pdf\|any\|<mime>…]` (aliases `open-with`, `receive-share`) | Lets the app receive shares and "Open with" files (for `UShare.onReceive`). No type means `any`. | Android, iOS, macOS |
| `query-schemes [add\|remove] [<scheme>\|<android.package>…]` (aliases `can-open`, `queries`) | Lets `ULaunch.canOpen` / `isInstalled` see other apps. No argument adds `whatsapp`, `tg`, `instagram`, `comgooglemaps`, `waze`. A dotted name is an Android package. | Android, iOS |

```bash
dart run u:app orientation portrait
dart run u:app orientation landscape
dart run u:app orientation all
dart run u:app deep-link myapp
dart run u:app deep-link add myapp
dart run u:app deep-link myapp --host open
dart run u:app deep-link remove myapp
dart run u:app share-target
dart run u:app share-target image
dart run u:app share-target image pdf
dart run u:app share-target text video audio
dart run u:app share-target application/zip
dart run u:app share-target remove
dart run u:app query-schemes
dart run u:app query-schemes whatsapp tg
dart run u:app query-schemes ir.eitaa.messenger
dart run u:app query-schemes remove waze
```

---

## 10. Apple: team, Swift Package Manager

| Command | What it does |
| --- | --- |
| `team <TEAM_ID>` | Apple `DEVELOPMENT_TEAM` for iOS and macOS signing. |
| `spm [--force]` (aliases `swift-package-manager`, `no-pods`) | Moves iOS and macOS from CocoaPods to Swift Package Manager, so `pod` is not needed. A platform with a plugin that still has no `Package.swift` is skipped, unless `--force`. |

```bash
dart run u:app team ABCDE12345
dart run u:app spm
dart run u:app spm --platforms macos
dart run u:app spm --force
dart run u:app spm --dry-run
```

---

## 11. Desktop and web identity

| Command | What it does | Platforms |
| --- | --- | --- |
| `binary <name>` (alias `exe`) | Executable file name. | Linux, Windows |
| `company <name>` | Windows CompanyName. | Windows |
| `copyright <text>` | macOS PRODUCT_COPYRIGHT and Windows LegalCopyright. | macOS, Windows |
| `web-color <#hex> [--background <#hex>]` | Web manifest theme/background color and `<meta name="theme-color">`. | web |

```bash
dart run u:app binary my_shop
dart run u:app company "My Company"
dart run u:app copyright "© 2026 My Company"
dart run u:app web-color "#0175C2"
dart run u:app web-color "#0175C2" --background "#FFFFFF"
```

---

## 12. Android release signing

| Command | What it does |
| --- | --- |
| `signing --create` | Asks every question Android Studio asks (store password, key alias, key password, validity, name, organization, city, country…), creates `upload-keystore.jks` in the project root, writes `android/key.properties` and the Gradle `signingConfig`. Every release build is signed after that. |
| `signing` | Same, with a `.jks` you already have. |

It needs `keytool` from a JDK. It finds the one Android Studio or Flutter installed by itself.

```bash
dart run u:app signing --create
dart run u:app signing
```

Keep the `.jks` and its passwords safe and out of git: Google Play only accepts updates signed with
the same key.

---

## 13. Official Flutter and Dart commands

These are the same on Windows, macOS and Linux.

### Setup

```bash
flutter doctor                                  # what is installed and what is missing
flutter doctor -v                               # the same, with details
flutter --version
flutter upgrade                                 # newest Flutter on your channel
flutter channel                                 # show the channel
flutter channel stable                          # switch channel (stable, beta, main)
flutter config --enable-swift-package-manager   # SPM for every project on this computer
flutter config --no-analytics
flutter precache                                # download every platform's engine now
flutter devices                                 # connected phones, simulators, desktop, Chrome
flutter emulators                               # list emulators
flutter emulators --launch <id>
```

### Create a project or add platforms

```bash
flutter create my_app
flutter create --org com.company my_app
flutter create --platforms=android,ios,web my_app
flutter create --platforms=windows,macos,linux .   # add platforms to an existing app
flutter create --template=plugin --platforms=android,ios my_plugin
flutter create --template=package my_package
```

### Dependencies

```bash
flutter pub get                                   # install what pubspec.yaml lists
flutter pub upgrade                               # newest versions allowed by pubspec.yaml
flutter pub upgrade --major-versions              # also raise the major versions in pubspec.yaml
flutter pub upgrade --major-versions --tighten    # and raise the lower bounds to what you have now
flutter pub outdated                              # what can be upgraded
flutter pub add <package>
flutter pub add dev:<package>
flutter pub remove <package>
flutter pub deps                                  # dependency tree
flutter pub cache repair                          # fix a broken pub cache
flutter pub cache clean
```

### Run and debug

```bash
flutter run
flutter run -d <device id>
flutter run -d chrome
flutter run -d macos                    # windows, linux
flutter run --release
flutter run --profile
flutter run --dart-define=KEY=VALUE
flutter run --flavor prod
flutter attach                          # attach to an app already running
flutter logs
flutter install                         # install the last build on a device
flutter screenshot
```

### Code quality and generated code

```bash
flutter analyze
dart format .
dart format --line-length 200 lib        # this plugin's line length (analysis_options.yaml)
dart fix --dry-run
dart fix --apply
flutter test
flutter test test/some_test.dart
flutter gen-l10n                        # regenerate localizations (u does it on pub get with generate: true)
flutter clean                           # delete build/ and .dart_tool/
```

### Builds, one platform at a time

```bash
# Android
flutter build apk --release
flutter build apk --target-platform android-arm64,android-arm --release
flutter build apk --split-per-abi --release
flutter build appbundle --release
flutter build apk --obfuscate --split-debug-info=build/symbols

# iOS (macOS only)
flutter build ios --release --no-codesign
flutter build ipa --release
flutter build ipa --export-method ad-hoc
flutter build ios --config-only        # only refresh Xcode settings

# macOS / Windows / Linux (each on its own OS)
flutter build macos --release
flutter build windows --release
flutter build linux --release

# Web
flutter build web --release
flutter build web --release --no-web-resources-cdn
flutter build web --release --base-href /my-app/
flutter build web --release --wasm
flutter build web --release --wasm --no-web-resources-cdn
flutter build web --release --dart-define=U_BUILD_ID=1.0.0+1
```

Output folders: `build/app/outputs/flutter-apk/`, `build/app/outputs/bundle/release/`,
`build/ios/ipa/`, `build/macos/Build/Products/Release/`, `build/windows/x64/runner/Release/`,
`build/linux/x64/release/bundle/`, `build/web/`.

### Publishing this plugin

```bash
flutter pub publish --dry-run
flutter pub publish
```

---

## 14. Release builds without u:app (per OS)

`dart run u:app build` does all of this on every OS. If you want plain shell commands instead,
these are the same steps. Shell syntax differs, so there is one version per OS.

### macOS and Linux (bash / zsh)

```bash
# Android
N=$(sed -n 's/^name: *//p' pubspec.yaml) V=$(sed -n 's/^version: *//p' pubspec.yaml | cut -d+ -f1 | tr -d .) && flutter clean && flutter pub get && flutter build apk --target-platform android-arm64,android-arm --release && cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/$N-$V.apk
```

```bash
# Web (with and without the CDN)
N=$(sed -n 's/^name: *//p' pubspec.yaml) V=$(sed -n 's/^version: *//p' pubspec.yaml | cut -d+ -f1 | tr -d .) B=$(sed -n 's/^version: *//p' pubspec.yaml) && flutter clean && flutter pub get && flutter build web --release --dart-define=U_BUILD_ID="$B" && (cd build/web && zip -r ~/Desktop/$N-$V-web.zip .) && flutter build web --release --no-web-resources-cdn --dart-define=U_BUILD_ID="$B" && (cd build/web && zip -r ~/Desktop/$N-$V-web-no-cdn.zip .)
```

```bash
# Web WebAssembly (with and without the CDN)
N=$(sed -n 's/^name: *//p' pubspec.yaml) V=$(sed -n 's/^version: *//p' pubspec.yaml | cut -d+ -f1 | tr -d .) B=$(sed -n 's/^version: *//p' pubspec.yaml) && flutter clean && flutter pub get && rm -rf build/web && flutter build web --release --wasm --dart-define=U_BUILD_ID="$B" && (cd build/web && zip -r ~/Desktop/$N-$V-web-wasm.zip .) && rm -rf build/web && flutter build web --release --wasm --no-web-resources-cdn --dart-define=U_BUILD_ID="$B" && (cd build/web && zip -r ~/Desktop/$N-$V-web-wasm-no-cdn.zip .)
```

```bash
# iOS → Xcode Organizer (macOS only)
N=$(sed -n 's/^name: *//p' pubspec.yaml) V=$(sed -n 's/^version: *//p' pubspec.yaml | cut -d+ -f1 | tr -d .) && flutter clean && flutter pub get && flutter build ios --release --no-codesign && xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath ~/Library/Developer/Xcode/Archives/$(date '+%Y-%m-%d')/$N-$V.xcarchive archive && open -a Xcode
```

```bash
# macOS (macOS only)
N=$(sed -n 's/^name: *//p' pubspec.yaml) V=$(sed -n 's/^version: *//p' pubspec.yaml | cut -d+ -f1 | tr -d .) && flutter clean && flutter pub get && flutter build macos --release && ditto -c -k --keepParent build/macos/Build/Products/Release/*.app ~/Desktop/$N-$V-macos.zip
```

```bash
# Linux (Linux only)
N=$(sed -n 's/^name: *//p' pubspec.yaml) V=$(sed -n 's/^version: *//p' pubspec.yaml | cut -d+ -f1 | tr -d .) && flutter clean && flutter pub get && flutter build linux --release && (cd build/linux/x64/release/bundle && zip -r ~/Desktop/$N-$V-linux.zip .)
```

To combine platforms, run `flutter clean && flutter pub get` once, then chain the build and copy
parts with `&&`.

### Windows (PowerShell)

```powershell
# Android
$N = (Select-String '^name:\s*(\S+)' pubspec.yaml).Matches[0].Groups[1].Value; $B = (Select-String '^version:\s*(\S+)' pubspec.yaml).Matches[0].Groups[1].Value; $V = $B.Split('+')[0].Replace('.', ''); flutter clean; flutter pub get; flutter build apk --target-platform android-arm64,android-arm --release; Copy-Item build\app\outputs\flutter-apk\app-release.apk "$env:USERPROFILE\Desktop\$N-$V.apk"
```

```powershell
# Web (with and without the CDN)
$N = (Select-String '^name:\s*(\S+)' pubspec.yaml).Matches[0].Groups[1].Value; $B = (Select-String '^version:\s*(\S+)' pubspec.yaml).Matches[0].Groups[1].Value; $V = $B.Split('+')[0].Replace('.', ''); flutter clean; flutter pub get; flutter build web --release --dart-define=U_BUILD_ID=$B; Compress-Archive -Path build\web\* -DestinationPath "$env:USERPROFILE\Desktop\$N-$V-web.zip" -Force; flutter build web --release --no-web-resources-cdn --dart-define=U_BUILD_ID=$B; Compress-Archive -Path build\web\* -DestinationPath "$env:USERPROFILE\Desktop\$N-$V-web-no-cdn.zip" -Force
```

```powershell
# Web WebAssembly (with and without the CDN)
$N = (Select-String '^name:\s*(\S+)' pubspec.yaml).Matches[0].Groups[1].Value; $B = (Select-String '^version:\s*(\S+)' pubspec.yaml).Matches[0].Groups[1].Value; $V = $B.Split('+')[0].Replace('.', ''); flutter clean; flutter pub get; Remove-Item build\web -Recurse -Force -ErrorAction SilentlyContinue; flutter build web --release --wasm --dart-define=U_BUILD_ID=$B; Compress-Archive -Path build\web\* -DestinationPath "$env:USERPROFILE\Desktop\$N-$V-web-wasm.zip" -Force; Remove-Item build\web -Recurse -Force; flutter build web --release --wasm --no-web-resources-cdn --dart-define=U_BUILD_ID=$B; Compress-Archive -Path build\web\* -DestinationPath "$env:USERPROFILE\Desktop\$N-$V-web-wasm-no-cdn.zip" -Force
```

```powershell
# Windows app
$N = (Select-String '^name:\s*(\S+)' pubspec.yaml).Matches[0].Groups[1].Value; $B = (Select-String '^version:\s*(\S+)' pubspec.yaml).Matches[0].Groups[1].Value; $V = $B.Split('+')[0].Replace('.', ''); flutter clean; flutter pub get; flutter build windows --release; Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath "$env:USERPROFILE\Desktop\$N-$V-windows.zip" -Force
```

PowerShell 7 can chain with `&&` too; Windows PowerShell 5 runs each `;` step even if the one before
failed, so check the output (or use `dart run u:app build`, which stops at the first error).

---

## 15. Moving off flutter_launcher_icons and flutter_native_splash

1. Remove them from `dev_dependencies` (and `dependencies`) in the app's `pubspec.yaml`, and delete
   their config (`flutter_launcher_icons:` / `flutter_native_splash:` sections, or
   `flutter_launcher_icons.yaml` / `flutter_native_splash.yaml`).
2. If the app calls `FlutterNativeSplash.preserve()` / `FlutterNativeSplash.remove()`, delete those
   calls. The native splash goes away by itself on the first frame; keep showing your own Flutter
   `SplashPage` while the app loads.
3. `flutter pub get`, then run the u commands below once.

| flutter_launcher_icons | u:app icon |
| --- | --- |
| `dart run flutter_launcher_icons` | `dart run u:app icon <image.png>` |
| `image_path` | the first argument |
| `adaptive_icon_background: "#FFFFFF"` or an image path | `--background "#FFFFFF"` or `--background <image.png>` |
| `adaptive_icon_foreground` | `--foreground <image.png>` |
| `adaptive_icon_foreground_inset` | `--inset <percent>` |
| `adaptive_icon_monochrome` | `--monochrome <image.png>` (or just `--monochrome`) |
| `remove_alpha_ios: true`, `background_color_ios` | always on; `--ios-background "#hex"` |
| `android: false`, `ios: false`, `web: generate: false`, … | `--platforms android,ios,…` |
| `windows: icon_size`, `macos: image_path` | all sizes are always written; use `--platforms macos` with another image for a different macOS icon |

| flutter_native_splash | u:app splash |
| --- | --- |
| `dart run flutter_native_splash:create` | `dart run u:app splash …` |
| `dart run flutter_native_splash:remove` | `dart run u:app splash remove` |
| `color`, `color_dark` | `--color`, `--dark-color` |
| `image`, `image_dark` | `--image`, `--dark-image` |
| `background_image`, `background_image_dark` | `--background-image`, `--dark-background-image` |
| `branding`, `branding_dark` | `--branding`, `--dark-branding` |
| `android_12: image`, `image_dark` | `--android12-image`, `--android12-dark-image` |
| `android_12: icon_background_color`, `icon_background_color_dark` | `--icon-background`, `--dark-icon-background` |
| `android_12: color` | `--color` (used for Android 12+ as well) |
| `fullscreen: true` | `--fullscreen` |
| `android: false`, `ios: false`, `web: false` | `--platforms …` |
| image size (always 4x) | 4x by default, or `--size <dp>` |
