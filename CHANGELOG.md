## 3.2.0

Nine pub plugins are replaced by u's own native code on all six platforms, the admin panel is
removed, and the source tree is reorganised. This release has breaking changes; see
**Breaking changes** and **Upgrade notes** at the end of this entry.

### Native engines replace nine plugins

The plugins below are no longer dependencies and are no longer re-exported. Each one is replaced
by Kotlin, Swift (iOS and macOS), C++ (Windows and Linux) and web code inside u. Every call
returns `false` or `null` instead of throwing when the platform can't do it.

* **`UStorage` replaces `shared_preferences`.**
  * Reads are memory lookups.
  * Writes in the same frame are combined into one atomic file replace.
  * Values keep their type: `DateTime`, `Duration`, `Uint8List`, enums and `toJson` objects.
  * Values can have a TTL.
  * Named stores come from `UStorage.open`.
  * Change streams and `listenable<T>()` are available.
  * Secure stores use ChaCha20-Poly1305 (AES-GCM on web) under a master key held by the
    platform key store.
* **`UDevice` replaces `device_info_plus`.** It covers model, OS, a stable id, type (phone /
  tablet / desktop / TV…), locales, time zone and 24-hour clock. `status()` reports battery,
  charging, power saver, thermal state and free RAM/disk. `integrity()` detects root / jailbreak,
  emulators, Frida/Xposed hooks, a debugger and developer mode. `headers` provides `X-Device-*` /
  `X-App-*` headers.
* **`UPackage` replaces `package_info_plus`.** It gives the version, build, `isAtLeast`, first
  launch, `justUpdated`, `previousVersion` and `launchCount`. `installer` reports Play, App Store,
  TestFlight, Bazaar, Myket, Microsoft Store or sideload. `signatureSha256` detects re-signed
  Android builds.
* **`UConnectivity` / `UNetwork` replace `connectivity_plus`.** They report wifi / cellular / VPN /
  ethernet, metered, roaming, cellular generation, bandwidth, RTT and captive portals.
  `whenOnline()` waits for a connection, and `hasInternet()` makes a real round trip.
  `offlineGrace` stops a Wi-Fi → LTE handoff from flashing an offline state.
  `UNetworkBuilder` rebuilds a widget on network changes.
* **`ULaunch` replaces `url_launcher`.**
  * URL modes: `url`, `inApp` (Custom Tabs on Android without `androidx.browser`, Safari view
    on iOS), `external`, `nativeApp` and `withPackage`.
  * Apps: `canOpen`, `isInstalled` and `openApp`.
  * Settings and stores: system `settings` pages, `store` (auto-detects the store) and
    `requestReview`.
  * Compose screens: `email` with attachments, `sms` and `call` (USSD too).
  * Messengers: `chat` for WhatsApp, Telegram, Eitaa, Rubika, Bale, Soroush, Instagram and X.
  * Maps: `map` and `directions` in Neshan, Balad, Google Maps, Waze or Apple Maps.
  * OAuth: `authenticate`, which uses `ASWebAuthenticationSession` on Apple and a popup on web.
  * Deep links: `initialLink` and `onLink`.
* **`UShare` replaces `share_plus`.** It shares text, links (with a rich preview on Apple), files,
  bytes and widget images. iPad and macOS popovers anchor with `originOf(context)`. `to(...)`
  shares straight to one app, and `canShareTo` checks first. `initialReceived` and `onReceive`
  receive shares and "Open with" files. Linux has no share sheet, so it falls back to the
  clipboard or the file manager.
* **`ULocation` replaces `geolocator`.**
  * Reading position: `current` (with an exact failure reason), `position`, `lastKnown` and
    `stream`, including background updates.
  * Permissions: precise vs approximate, `requestPrecise` and `ensureReady`.
  * Geofences that fire in the background, and events received while the app was closed.
  * Sensors and places: compass `heading`, iOS `visits`, and geocoding with `addressOf` / `find`.
  * Math: `distance` and `bearing`.
  * Android uses no Google Play Services; Linux uses GeoClue2.
* **`UNotification` replaces `flutter_local_notifications`.**
  * Show and schedule: `show`, `showRequest`, `progress`, `schedule`, `after`, `daily`, `weekly`
    and `monthlyJalali`. Monthly and yearly repeats can follow the Jalali calendar.
  * Content: action buttons, inline replies, big pictures, groups and Android channels and
    channel groups.
  * Permissions and alarms: exact alarms, provisional / critical permission on iOS, and the
    `full-screen` permission.
  * Badges: on iOS, macOS, Windows, Linux launchers and PWAs.
  * Events: `listen` and `launchEvent`.
  * Android reschedules after a reboot or a time-zone change. Windows toast clicks work after the
    app has closed.
* **`UUUID` no longer depends on `uuid`.** v1, v4, v5, v6, v7 and v8 are generated in pure Dart
  (RFC 9562).
* `initU()` now fills device, package and network info in **one native round trip**, then starts
  notifications.

### New APIs

* **Facades:** `UDownloads` (downloads), `UMedia` (players, sources, subtitles, HLS/DASH,
  library, playlists), `UCamera` (camera screen, photos, video, scanning) and `UScreenGuard`
  (`set(enabled:)` added). `UIso` / `UIsoClient` moved to `lib/utils`.
* **`UApp`:**
  * Device and power: `deviceStatus`, `batteryLevel`, `isCharging`, `isLowBattery`,
    `isPowerSaveMode`, `shouldSaveEnergy`, `freeDiskSpace` and `freeMemory`.
  * Security: `deviceIntegrity`, `isDeviceCompromised` and `isRooted`.
  * Versions: `isVersionAtLeast`, `isVersionOlderThan` and `compareVersions`.
  * System UI: `haptic` (`UHapticType`), `keepScreenOn`, `setFullScreen`, `setOrientations`,
    `setStatusBarLight`, `hideKeyboard` and `exit`.
  * App info: `initPackageInfo`, plus all the new `UPackage` / `UDevice` fields.
* **`ULocalStorage`:**
  * Typed reads: `get<T>`, `getOr`, `getDateTime`, `getDuration`, `getBytes`, `getEnum`,
    `getMap`, `getList`, `getObject` and `getObjects`.
  * Secure values: `setSecure`, `getSecure`, `removeSecure`, `containsSecure` and
    `clearSecure`.
  * Writing: `setAndWait`, `setAll`, `flush`, `update` and `increment`.
  * Expiry: `expire` and `ttlOf`.
  * Watching: `watch` and `listenable`.
  * Removing: `removeAll` and `removeWhere`.
  * Named stores: `openStore`, `store` and `deleteStore`.
* **`UFile`:**
  * Keyed storage: `saveBytes`, `saveString`, `saveJson`, `saveCache`, `saveSecure` and their
    `read*` counterparts, plus `readStream`.
  * File operations: `copy`, `move`, `delete`, `deleteAll`, `deleteExpired`, `exists`, `sizeOf`
    and `pathOf`.
  * Opening and exporting: `open`, `reveal`, `saveAs`, `saveToDownloads`, `exportFile` and
    `importFile`.
  * Storage management: `excludeFromBackup`, `freeSpace`, `trimCache`, `storageUsage`,
    `storageKeys`, `storageEntries` and `openStoragePage`.
* **`UValidators`:** `cardNumber`, `iban`, `matchController` and `isValid`.
* **Helpers:** `UThrottler`, `URetry`, `UTimezone.offsetText`, and `UEncryption.sha1Bytes`,
  `sha256Bytes`, `hmacSha256Bytes` and `randomBytes`.
* **`UMaterialApp`:** new `title`, `builder`, `routes`, `onGenerateRoute`, `navigatorObservers`
  and `localizationsDelegates` parameters.

### New widgets

* **Async:** `UAsyncBuilder` (loading / error + retry / empty / data), `UStreamView`,
  `UPaginatedList` (infinite scroll with pull-to-refresh), `UOnlineBuilder`, `UOfflineBanner` and
  `UNetworkBuilder`.
* **Building blocks:** `USkeleton`, `UAvatar`, `USearchField` (debounced) and `UCopyText`.

### Extensions

* **`BuildContext`:** `screenSize`, `isRtl`, `locale`, `responsive`, `isKeyboardOpen` and
  `hideKeyboard`.
* **`DateTime`:**
  * Checks: `isToday`, `isYesterday`, `isTomorrow`, `isPast`, `isFuture` and `isSameDay`.
  * Boundaries: `startOfDay`, `endOfDay` and `startOfMonth`.
  * Math: `addMonths`, `age` and `daysUntil`.
  * Other: `copyWith` and `toJalaliFormat`.
* **`Iterable`:** `groupBy`, `distinctBy`, `chunked`, `sumBy`, `averageBy`, `minBy`, `maxBy`,
  `separatedBy`, `orEmpty` and `where`.
* **`List<Widget>`:** `withSpacing` and `withDividers`.
* **`Map`:** `getOr`, `pick`, `omit`, `removeNulls` and `deepMerge`.
* **`num`:**
  * Durations: `ms`, `seconds`, `minutes`, `hours`, `days` and `delay`.
  * Formatting: `toBKMG`, `toHuman`, `withCommas`, `toPersianWords`, `toClock` and `twoDigits`.
  * Percentages and ranges: `toPercent`, `percentOf` and `between`.
  * Other: `toDateTime`.
* **`Duration`:** `toClock`.
* **`String`:**
  * Checks: `isBlank`, `isNullOrBlank`, `isPersian` and `hasPersian`.
  * Transforms: `normalizePersian`, `capitalize`, `toTitleCase`, `toSlug`, `mask`, `reversed`
    and `orIfBlank`.
  * Parsing: `toIntOrNull`, `toDoubleOrNull`, `toDateTime`, `toColor`, `toHex` and `countOf`.
* **`Widget`:**
  * Layout: `center`, `sized`, `flexible`, `sliver` and `opacity`.
  * State: `visible`, `disabled`, `tooltip` and `hero`.
  * Clipping and effects: `clipRadius`, `clipCircle` and `skeleton`.

### CLI (`dart run u:app`)

* **New `share-target`** registers the app to receive shares and "Open with" files on Android, iOS
  and macOS, for `UShare.onReceive`. It takes `image`, `video`, `audio`, `text`, `pdf`, `any` or
  MIME types.
* **New `query-schemes`** adds iOS `LSApplicationQueriesSchemes` and Android `<queries>` packages
  so `ULaunch.canOpen` and `isInstalled` can see other apps.
* **New `full-screen` permission**, bringing the total to 33. Permissions can now add Android
  `<service>` entries, and print store-review notes.

### Platform / build

* **Android manifest:** the plugin now declares `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED`,
  the geofence, notification and boot receivers, and a scoped `<queries>` block for browsers,
  dialer, maps, stores and messengers. It does not use `QUERY_ALL_PACKAGES`.
* **Android build:** `consumer-rules.pro` lets apps without ARCore pass R8.
* **iOS / macOS:** a `PrivacyInfo.xcprivacy` privacy manifest declares the UserDefaults, disk
  space, boot time and file timestamp APIs.
* **Windows:** links `iphlpapi`, `ws2_32`, `version`, `propsys`, `gdi32` and `user32`.
* **Requirements:** Flutter ≥ 3.47.0, Dart ≥ 3.12.0.

### Project layout

* **`lib/src/<feature>/`** holds the engines and channels. It replaces `lib/plugins/`, the
  top-level `lib/cli/` and `lib/iso8583/`, `lib/models/` and `lib/utils/files|web`.
* **`lib/utils/`** holds only the documented static helpers.
* **`lib/components/`** holds the widgets.
* **Engine splits:** the barcode encoders moved to `src/barcode`, the crypto algorithms to
  `src/crypto`, and the media engine was split into `src/media` (controller, library, HLS/DASH
  and playlist parsers, subtitles, tags, text decoding).
* **Docs:** every public member now has a one-line doc comment with an example, and with the
  permission and platforms it needs.

### Breaking changes

* **Re-exports removed.** `connectivity_plus`, `device_info_plus`, `flutter_local_notifications`,
  `geolocator`, `package_info_plus`, `share_plus`, `shared_preferences` and `url_launcher` are no
  longer re-exported. Code that used their types (`Position`, `SharedPreferences`, `launchUrl`,
  `PackageInfo`, `ShareResult`, …) through `package:u/utilities.dart` must use the u APIs or add
  the package itself.
* **`UApp` types changed.** `UApp.packageInfo` is a `UPackageInfo` and `UApp.deviceInfo` is a
  `UDeviceInfo`. `UApp.initDeviceInfo()` is removed, because `initU()` does it.
* **Removed types:** `UInternetConnectionChecker`, `UInternetConnectionStatus`,
  `UAddressCheckOptions`, `UAddressCheckResult`, `UOs` and `UUpdateResponse`.
* **Renamed or replaced members:**

| Before | Now |
| --- | --- |
| `ULocation.getUserLocation()` | `ULocation.position()` / `current()` |
| `UNotification.showNotification(...)` | `UNotification.show(id, title:, body:)` |
| `UNetwork.hasWifi()` / `hasCellular()` / `hasVpn()` / `hasEthernet()` / `hasBluetooth()` (async) | `UNetwork.isWifi` / `isCellular` / `isVpn` / `isEthernet` / `isBluetooth` (sync) |
| `UNetwork.hasAnyConnection()` / `hasNetworkConnection()` | `UNetwork.isOnline`, or `await UNetwork.hasInternet()` |
| `ULaunch.whatsApp` / `telegram` / `instagram` | `ULaunch.chat(UMessenger.whatsapp, …)` |
| `ULaunch.shareText` / `shareFile` / `shareWith*` | `UShare.text` / `file` / `to(UShareTarget.…)` |
| `UShare.xFiles(...)` / `wasShared(result)` | `UShare.files(...)` / `result.isSuccess` |
| `UFile.showImagePicker` / `showFilePicker` | `UFile.pickImage` / `pickFiles` |
| `ULocalStorage.getIfNotExpired` / `setBatch` | `ULocalStorage.get<T>` / `setAll` |
| `context.size` | `context.screenSize` |
| `UUpdateDialog.checkAndShow(UUpdateResponse, …)` | `UUpdateDialog.checkAndShow(U.appSettings.appVersions, …)` |

### Upgrade notes

* **Saved data is not migrated.** Values that earlier versions saved through `shared_preferences`
  (tokens, locale, dark mode and anything written with `ULocalStorage`) are not carried over to
  `UStorage`, so existing users start signed out with default settings after updating.
* **Scheduled notifications are not migrated.** Notifications that `flutter_local_notifications`
  scheduled are not re-armed, so schedule them again after upgrading.
* **Run `dart run u:app doctor` after upgrading.** To use the new features, also run
  `permission add …`, `share-target` and `query-schemes`.

## 3.1.0

* **Drawing on PDFs, EPUBs and videos.** New `UDocShapeLayer` / `UDocDrawToolbar` /
  `UDocDrawController`: pen, highlighter pen, area highlight (manual highlighting anywhere), line,
  arrow, double arrow, rectangle, rounded rectangle, ellipse/circle — each with no fill, light fill,
  solid fill or white "cover" fill — text boxes typed directly on the page, and sticky notes. Colour,
  thickness, opacity, dashes, bold and font size; Shift / "Keep proportions" for squares, circles and
  45° lines. Select to move, drag the corner to resize, recolour, fill or delete; eraser; undo/redo
  (a drag is one undo step); Delete, Esc and Ctrl/Cmd+D shortcuts.
* Drawings are saved in the **same annotation string** as highlights and bookmarks
  (`UDocAnnotationController.export()` → `"shapes"`, `UMediaNotesController.export()` → `"shapes"`),
  so storing that one string (e.g. in SharedPreferences via `ULocalStorage`) and passing it back
  restores everything. Geometry is normalised, so drawings stay in place at any zoom or window size.
* `UPdfViewer`: ✎ button in the toolbar (`enableDrawing`, `drawController`; pass a controller with
  an active tool to open in drawing mode). While drawing, one-finger drags draw and the wheel,
  trackpad and scroll thumb still scroll. The file-writing editor tools (`enableAnnotations: true`,
  `UPdfEditorPage`) are unchanged.
* `UEpubReader`: the same tools per paragraph (anchored to the paragraph, width-normalised, and kept
  in place when a paragraph is split across pages); drawing never starts a text selection.
* `UVideo` / `UVideoWithNotes`: ✎ in the player pauses and draws on the frame (letterboxing
  excluded). Each drawing shows for a chosen time (2 s, 5 s, 10 s, 30 s or until the end) and
  appears on the seek bar.
* Viewer hotkeys (space, arrows…) no longer fire while typing in a text box.

* **Document annotations (PDF & EPUB).** New shared `UDocAnnotationController` with highlight,
  underline, strike-through, squiggly, border and note markups, page/position bookmarks, undo/redo,
  local persistence, `export()`/`import()` (base64 JSON for server sync, newest-wins merge) and import
  of the legacy SinApp `{"markers":…,"pageMarks":…}` format. Reusable `UDocAnnotationsPanel`,
  `UDocBookmarksPanel`, `UDocSelectionMenu`, `UDocMarkupMenu`, `UDocNoteEditor`, `UDocWatermark`,
  `USecureArea`.
* **Fix: Persian/Arabic PDF highlighting.** Text runs are rebuilt with per-character rectangles and
  proper visual→logical bidi reordering (numbers, Latin inside RTL, ZWNJ, diacritics), `/ActualText`
  is honoured, and runs whose glyph metrics look wrong fall back to whole-line boxes (pdfrx approach).
  `UDocTextGeometry.auto | precise | box` is selectable in the viewer settings.
* **`UPdfViewer`**: sidebar (thumbnails, outline, notes, bookmarks, search with snippets), selection
  with mouse/touch/keyboard (double/triple click), two-page & cover spreads, smooth pinch/trackpad/
  ctrl-scroll zoom, scroll thumb, page indicator, `allowCopy`, `secure`, watermark, `pageOverlayBuilder`,
  keyboard shortcuts, legacy-annotation placement.
* **`UEpubReader`**: the same markup tools on reflowable text (anchored to block + offsets, survive
  re-flow and paged mode), grouped multi-paragraph selections, position bookmarks, block-level search,
  exact jump to TOC/footnote anchors, span-preserving pagination, full typography settings, image
  zoom, time-left estimate. Fixes: tap-to-toggle never fired under `SelectionArea`, dark-theme text.
* **Video**: `UMediaNotesController` + `UMediaNotesPanel` (timestamp notes, seek-bar markers, overlays,
  SRT/Markdown export, legacy import), `UVideoWithNotes`, resume position, ±seek buttons, quick speed
  menu and fine speed slider, desktop hover/volume slider/scroll-wheel volume, mouse double-click
  fullscreen, `UMovingWatermark`, `secure`, Android auto picture-in-picture + PiP state events,
  iOS PiP that waits until possible, hls.js on web browsers without native HLS.
* Graceful errors when a platform has no media backend; replay after completion.
* **Fixes after QA:** PDF selection/markup boxes floated above the text (Chrome/Skia writes a positive
  font Descent — metrics are now sanitised; older saved markups are re-placed automatically, guarded
  by a pixel-coverage test); EPUB crash "SelectionListenerNotifier is already registered" when a
  paragraph got its first markup; EPUB markups drawn at the wrong x on short/list paragraphs and
  spilling into margins (painter now uses the paragraph's real width and one trimmed box per line);
  EPUB menu buttons lost the selection on web/desktop; debug assertions from ListTiles on coloured
  sidebars; page counters in RTL; mouse drag selection starting late; search snippet highlight offset.
* **Audio player:** ±seek buttons, timestamp notes with seek-bar markers, resume position, fine speed.

## 3.0.0

* **new `dart run u:app` CLI** to change the host app's native settings on Android, iOS, macOS,
  Linux, Windows and web from one command: `name`, `id` (moves `MainActivity` to the new package),
  `min-sdk`, `target-sdk`, `compile-sdk`, `ndk`, `java`, `version`, `bump`, `description`,
  `permission add/remove/list` (32 friendly names such as `camera` / `location` / `internet`, mapped
  to manifest entries, Info.plist usage strings, background modes and macOS entitlements),
  `orientation`, `deep-link`, `team`, `binary`, `company`, `copyright`, `web-color`, Android release
  `signing`, plus `info` and `doctor`. Supports `--platforms` and `--dry-run`, keeps file formatting,
  and is idempotent.

* **Fix: signing out no longer deletes the user's files on desktop.** `UFileStorage` used
  `getApplicationDocumentsDirectory()`, which is the user's own `~/Documents` on Windows, Linux and
  unsandboxed macOS, and `clear()` (called by `UAuth.signOut`) deleted every `.txt` file there.
  Storage now lives in the app's private support/cache directories; existing data is migrated once.
* new `UDownloadManager` replacing `UDownload` and the media-only download manager: silent fetches,
  a persistent queue, segmented multi-connection downloads with dynamic re-splitting, safe resume
  (`If-Range`), pause/resume across restarts, priorities, per-host limits, speed limits, wifi-only,
  scheduling, mirrors, checksums, `sourceId` downloads whose URL is never stored, and hand-off to
  the OS (Android DownloadManager, Apple background URLSession, Windows BITS).
* destinations: memory, private storage, cache, the encrypted vault (encrypted while downloading),
  the user's Downloads (MediaStore on Android, Files app on iOS, the browser on web), a path, or
  "save as".
* `UFileStorage` rewritten: `support` / `cache` (LRU, size cap) / `vault` (streaming
  ChaCha20-Poly1305 or WebCrypto AES-GCM with per-file keys) / `temp` buckets, hashed file names,
  atomic writes, expiry, MIME types, checksums, ranged streaming reads, and IndexedDB on the web.
* new native `u/files` channel on all platforms: free space, save-as dialogs, open / reveal,
  keep-awake (Android dataSync foreground service with progress), key-store secrets.
* new widgets: `UDownloadManagerPage`, `UDownloadTile`, `USegmentProgressBar`, `UDownloadButton`,
  `UAddDownloadSheet`, `UDownloadSettingsSheet`.
* new `UHasher` (streaming MD5 / SHA-1 / SHA-256) and `UChaCha20Poly1305`.
* breaking: `UFileStorage.getBytesSync`, `getDatKeys` and `getDatPaths` were removed; the other 2.x
  names remain as deprecated aliases. `UDownload` is a deprecated wrapper over `UDownloadManager`.

## 2.0.4

* added AR and 3D with no pub packages: ARCore + a built-in OpenGL ES 3 glTF renderer (Android),
  ARKit + RealityKit (iOS), WebXR + a built-in WebGL2 renderer (web).
* `UArController` / `UArView`: surfaces (floor, table, wall, ceiling), hit testing, anchors, nodes
  (glTF / USDZ models, primitives, images, videos, Flutter widgets), animations, depth and people
  occlusion, light estimation, image / object / face / body tracking, Geospatial and GPS + compass
  anchors, Cloud Anchors, world maps, collaboration, snapshots, recording, OCR and code detection.
* ready-made widgets: `UArScene`, `U3DViewer`, `UArGeoView`, `UArMeasure`, `UArFaceTryOn`,
  `UArImageTrigger`, `UArCodeView`, `UArOverlayLayer`, `UArGate` and `UArExperiences`.
* `UAr.scanRoom` (RoomPlan), `UAr.captureObject` (Object Capture), `UAr.openNativeViewer`
  (Scene Viewer / AR Quick Look).

## 2.0.3

* added `UJalaliDatePicker` with three flavours: `classic` (the original `JalaliDatePickerDialog`),
  `material` (a Jalali clone of Flutter's own Material date picker, with month paging, year grid
  and keyboard entry) and `spinner` (an iOS style three wheel picker as a bottom sheet or dialog).
* `UTextFieldDatePicker` gained `jalaliType`, `spinnerAsDialog` and `helpText`; `jalali: true` now
  opens the material flavour by default.
* `JalaliFormatter` now exposes its month and weekday name tables, plus Latin variants.

## 2.0.2

* added example project

## 2.0.1

* converted the package to Plugin to be able to provide native codes

## 0.1.0

* First release as the `u` **plugin** (successor to the `Utilities-flutter` package), adding
  native platform code alongside the Dart toolkit.
* **ScreenGuard**: native screenshot / screen-recording prevention on Android, iOS, macOS and
  Windows (safe no-op on Linux and web), with `onScreenshot` / `onScreenRecording` callbacks.
* Established the `lib/plugins/<feature>/` + per-platform handler convention for native features.
* Full multi-page example gallery and a complete README covering every capability area.
