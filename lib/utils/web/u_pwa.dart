import "package:u/utilities.dart";
import "package:u/utils/web/u_web_stub.dart" if (dart.library.html) "package:u/utils/web/u_web_impl.dart";

/// Progressive-web-app helpers: detect the current browser environment and guide
/// users on iOS through adding the site to their home screen (installing the PWA).
///
/// All getters return `false` on native builds, so calls are safe to make
/// unconditionally.
abstract class UPwa {
  static String get _ua => uPwaUserAgent().toLowerCase();

  // Already added to the home screen and launched as a standalone PWA.
  static bool get isStandalone => UApp.isWeb && uPwaIsStandalone();

  // Opened in a browser on an iPhone.
  static bool get isIphoneBrowser => UApp.isWeb && _ua.contains("iphone");

  // Opened in a browser on any iOS device (iPhone/iPad/iPod).
  static bool get isIosBrowser => UApp.isWeb && (_ua.contains("iphone") || _ua.contains("ipad") || _ua.contains("ipod"));

  // Opened in a browser on Android.
  static bool get isAndroidBrowser => UApp.isWeb && _ua.contains("android");

  // True only for Safari on iOS — the sole iOS browser that can "Add to Home Screen".
  static bool get isIosSafari {
    if (!isIosBrowser) return false;
    // iOS Chrome/Firefox/Edge/Opera/etc. embed their own tokens; exclude them.
    const List<String> nonSafari = <String>["crios", "fxios", "edgios", "opios", "mercury", "gsa"];
    if (nonSafari.any(_ua.contains)) return false;
    return _ua.contains("safari");
  }

  // Whether it makes sense to prompt an iOS install (iOS browser, not already installed).
  static bool get canPromptIosInstall => isIosBrowser && !isStandalone;

  // Show step-by-step "Add to Home Screen" guidance in a bottom sheet.
  //
  // Does nothing when not on an un-installed iOS browser, unless [force] is set.
  // Every string is overridable so callers can pass their own localized copy;
  // defaults come from the app's l10n.
  static Future<void> promptIosInstall({
    bool force = false,
    String? title,
    String? step1,
    String? step2,
    String? step3,
    String? safariHint,
    String? doneLabel,
  }) async {
    if (!force && !canPromptIosInstall) return;

    // Add to Home Screen is only available in Safari; other iOS browsers get a hint.
    final bool safari = force || isIosSafari;

    await UNavigator.bottomSheet<void>(
      _IosInstallSheet(
        title: title ?? U.s.addToHomeScreenTitle,
        safari: safari,
        step1: step1 ?? U.s.addToHomeScreenStep1,
        step2: step2 ?? U.s.addToHomeScreenStep2,
        step3: step3 ?? U.s.addToHomeScreenStep3,
        safariHint: safariHint ?? U.s.openInSafariToInstall,
        doneLabel: doneLabel ?? U.s.gotIt,
      ),
      showDragHandle: true,
    );
  }
}

class _IosInstallSheet extends StatelessWidget {
  const _IosInstallSheet({
    required this.title,
    required this.safari,
    required this.step1,
    required this.step2,
    required this.step3,
    required this.safariHint,
    required this.doneLabel,
  });

  final String title;
  final bool safari;
  final String step1;
  final String step2;
  final String step3;
  final String safariHint;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: <Widget>[
          Icon(Icons.add_to_home_screen_rounded, size: 40, color: scheme.primary),
          UTextTitleMedium(title, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (safari) ...<Widget>[
            _step(context, 1, Icons.ios_share_rounded, step1),
            _step(context, 2, Icons.add_box_outlined, step2),
            _step(context, 3, Icons.check_circle_outline_rounded, step3),
          ] else
            URow(
              children: <Widget>[
                Icon(Icons.info_outline_rounded, color: scheme.primary),
                UTextBodyMedium(safariHint).expanded(),
              ],
            ),
          const SizedBox(height: 12),
          UButton(title: doneLabel, onTap: UNavigator.back),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, int number, IconData icon, String text) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return URow(
      children: <Widget>[
        UContainer(
          width: 28,
          height: 28,
          radius: 100,
          color: scheme.primaryContainer,
          alignment: Alignment.center,
          child: UTextLabelLarge("$number", color: scheme.onPrimaryContainer),
        ),
        Icon(icon, color: scheme.primary),
        UTextBodyMedium(text).expanded(),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// USAGE EXAMPLES
// -----------------------------------------------------------------------------
//
//   // Show the install hint once when an iPhone user opens the web app in a browser.
//   if (UPwa.canPromptIosInstall) {
//     UPwa.promptIosInstall();
//   }
//
//   // Only iPhone Safari (can actually install):
//   if (UPwa.isIphoneBrowser && UPwa.isIosSafari) UPwa.promptIosInstall();
//
//   // Force-show the instructions (e.g. behind an "How to install" button):
//   UPwa.promptIosInstall(force: true);
//
//   // Skip in-app UI when already installed:
//   if (!UPwa.isStandalone) showInstallBanner();
// -----------------------------------------------------------------------------
