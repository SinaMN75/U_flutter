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
