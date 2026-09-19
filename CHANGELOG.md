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
