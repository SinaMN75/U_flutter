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
