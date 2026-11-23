# u_flutter guidance

This is the shared Flutter source repository. Paths beginning with `U/` or an app group name refer to repositories under the broader `Projects` workspace when it is available. The rules below apply in standalone checkouts. Keep any changed shared section in sync with the workspace guide when editing both.

## Coding and replies

- Write code a person can change the next day. Match the neighbouring file and keep the change local. Use ordinary names and the existing call style. Avoid new patterns, one-use helpers, generics or wrappers, duplicate results, and unrelated cleanup.
- Keep each function to one job and about one screen. Split long flows into clearly named steps. Keep the control flow readable. Add comments only when the logic needs them.
- Sina handles commits, pushes, branch switches, and database migrations. Leave existing changes in place. Never run `dart format` on a folder. Format an edited file only if the formatting diff stays within your changes.
- Reply in plain Persian with short sentences and one idea at a time. Put every English name, file, command, or code term alone on the next line. Describe what changed in the order it runs, then list the files and report what you verified.

## Verification

- Run the changed flow as far as the available environment allows. A passing analyzer or build is one check.
- Exercise every affected layout breakpoint, including a phone around 375 px and desktop. Cover empty, loading, error, success, and applicable edges such as zero, excess, missing permission, guest, offline, or a dead server. Open other screens that read the same data, state, or component.
- Call changed API paths for success and for each returned error. Fix failing checks and rerun them. Report what ran and what was unavailable, including a physical card reader, a camera, or a live payment account when needed.

## Shared packages and API contracts

- Put general-purpose backend logic in `U/SinaMN75U_aspnet` and general-purpose Flutter code in `U/u_flutter`. A rule used by one product belongs in that product. Use `AppSettings`, tags, or optional parameters with neutral defaults for per-product behaviour in shared code. Name shared features after what they do.
- Work in the source repositories. Leave all nested backend submodules and all nested `u_flutter` / `U_flutter` copies to Sina. If a consumer still shows old behaviour, check the copy it actually uses and report the difference.
- Use `Tags` enum values in the `Tag<Entity>` hundred-groups for fixed choices and the matching Flutter enum. Keep existing numbers. Use free strings for open values such as names, notes, and standard codes.

## Shared Flutter package

- `U/u_flutter` is the source for shared widgets, utilities, readers, media, native integrations, and shared request params, responses, enums, and `UServices`. Start in `lib/`. The example app in `example/` shows the package APIs. See `README.md` and `COMMANDS.md` in the package for usage and build commands.
- SinApp and AVREEN use their own servers. A general-purpose widget or utility must work without `UServices` and its models. Shared backend features remain opt-in.
- Use theme colours and the existing colour scheme. Prefer explicit types, double quotes, and `final` or `const` where possible. Use `U.s` for user-facing Flutter strings.
- Put Flutter translation keys in `lib/l10n/` in this package. Reuse templates such as `addItem` and `itemType` before adding keys. Use the app's `"@@x-section-<name>"` section for a new app key. Use `general` for package text and move a key there when a second app needs it. Sort within each section, keep `@key` metadata next to its key, and remove unused keys.

## Flutter app structure

Follow AvaHamrah in `AvaPlus/ava_hamrah_flutter` when it is available. This is the app-side pattern that shared APIs should support.

- In `lib/main.dart`, use `initU`, `UHttpClient.onAuthFailed`, locale, themes, `home: const SplashPage()`, `AppColors`, `Core`, `AppConstants`, `AppImages`, and `AppIcons`.
- Keep `lib/utils/` for small non-UI helpers. Use `U.user`, `U.appSettings`, `U.contents`, and `UAuth.isSignedIn`. Avoid session singletons, bottom-sheet login, and extra state classes.
- Put `<feature>_page.dart`, `<feature>_controller.dart`, and feature widgets in `lib/view/pages/<feature>/`. Shared app widgets go in `lib/view/widgets/widgets.dart` with an `App` prefix.
- Use a `StatefulWidget`, `final XController c = XController()`, `c.init()` in `initState`, and `UScaffold`. Add a controller when the page has logic. Use a plain controller or `UBaseController` if it loads data.
- Use `onOk`, `onError`, and `onException` for API calls. Use `ULoading` for actions, `UToast.error` for errors, and `UValidators.validateForm` for forms.
- In the splash flow, read settings, show `UUpdateDialog`, load the user, then navigate with `UNavigator.offAll(const MainPage())`. After login verification, return to `SplashPage`. Use `UNavigator.push`, `off`, and `offAll`. Named routes are for web deep links.

## Resume the PDF viewer

When Sina says “continue”, “resume”, or «ادامه» with no other topic, resume the PDF viewer in `U/u_flutter` and `SinApp/sinapp_flutter` only. Keep the engine pure Dart and leave SinApp's nested package copy alone. If only this repository is open, work on its side of the feature.

- Reported and pending Sina's test: CFF fonts, CMYK and YCCK JPEG, JPEG 2000, soft masks, broken-object isolation, cached page bitmaps with a sharp zoom tile, trackpad scroll, mobile pan, fling, and pinch. The 96-page sample `/Users/sinamn75/Downloads/Glaucoma-soalat-895.pdf` was compared with macOS Preview. Open issues include non-embedded fonts and their unjoined Persian, rare JPEG and JPX options, and anti-aliasing.
- Widget-tested: one finger or pen draws, two fingers scroll, phone dock fits 375 px, desktop toolbar stays. `UDocDrawToolbar` is shared with EPUB and video. Course files 1343, 1426, 1479, and 1569 were accepted. Image tone was slightly lighter than CoreGraphics on 1348, 1347, 1349, 1591, and 1400. The tone fix is pending, and video review has covered only the shared toolbar.
- Finish the render comparison, correct image tone if the difference persists, check large-file timings, then review the videos. Keep the existing renderer.
