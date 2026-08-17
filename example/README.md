# u — example gallery

A multi-page showcase for the [`u`](../README.md) plugin. Every page demonstrates one capability
area with a live widget and the exact code that produced it.

## Run

```bash
flutter pub get
flutter run            # mobile
flutter run -d chrome  # web
flutter run -d macos   # desktop
```

## Pages

| Page            | Shows                                                                    |
| --------------- | ----------------------------------------------------------------------- |
| Text            | The `UText*` type scale, styling props, `UAnimatedCounter`               |
| Buttons         | `UButton` variants, submit-cancel, `UPressable`, `USendAgainCountDown`   |
| Inputs          | `UTextField`+`UValidators`, `UOtpField`, `USegmentedControl`, `UChipChoice`, `UPlateField` |
| Layout          | `UColumn`/`URow`, `UCard`, `UGlassCard`, `UHeaderCard`, `UListTile`, empty state |
| Navigation      | `UTabBar`, `USideMenu`                                                    |
| Feedback        | `UToast`, `UNavigator` dialogs/sheets, `ULoading`, progress, `RatingBar` |
| Media & files   | `UImageNetwork`, `CachedNetworkImage`, `USlider`, `UBarcode`, `UFilePicker`, `UHtmlView`, `UWebView`, `UScanner` |
| Data viz        | `UCartesianChart`, `UGauge`, `UJsonViewer`, `UNumberPagination`, `UMap`  |
| Cards & misc    | `FlipCard`, `CreditCardWidget`, `ReadMoreText`, `ScrollingText`, `BadgeWidget`, Jalali picker |
| Advanced forms  | `URichTextEditor`, `USignaturePad`, `UProcessView` (reference)           |
| Utilities       | `UEncryption`, `PersianTools`, `UUUID`, `UClipboard`, `UShare`, `ULaunch`, `ULocalStorage` |
| Formatters      | Money, compact/grouped numbers, Jalali dates, Persian digits             |
| Extensions      | Widget sugar + string/iterable/num extensions                            |
| ScreenGuard     | Native screenshot/recording prevention + detection callbacks             |
| API services    | `UServices` usage and the full service list (reference)                  |
| Admin panel     | `u_admin` modules and how to launch them (reference)                     |

## Structure

```
lib/
  main.dart               MaterialApp: theme, navigatorKey, S localization
  home_page.dart          gallery grid + navigation registry
  widgets/
    gallery_page.dart     shared page scaffold
    demo_section.dart     documented demo block (title + description + live + code)
  pages/                  one file per capability area
```
