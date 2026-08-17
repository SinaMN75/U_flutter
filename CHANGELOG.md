## 2.0.1

* converted the package to Plugin to be able to provide native codes

## 0.1.0

* First release as the `u` **plugin** (successor to the `Utilities-flutter` package), adding
  native platform code alongside the Dart toolkit.
* **ScreenGuard**: native screenshot / screen-recording prevention on Android, iOS, macOS and
  Windows (safe no-op on Linux and web), with `onScreenshot` / `onScreenRecording` callbacks.
* Established the `lib/plugins/<feature>/` + per-platform handler convention for native features.
* Full multi-page example gallery and a complete README covering every capability area.
