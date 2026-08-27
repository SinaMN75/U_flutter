import "package:u/utilities.dart";
import "package:u/utils/web/u_web_stub.dart" if (dart.library.html) "package:u/utils/web/u_web_impl.dart";

abstract class UPwa {
  static String get _ua => uPwaUserAgent().toLowerCase();

  static bool get isStandalone => UApp.isWeb && uPwaIsStandalone();

  static bool get isIphoneBrowser => UApp.isWeb && _ua.contains("iphone");

  static bool get isIosBrowser => UApp.isWeb && (_ua.contains("iphone") || _ua.contains("ipad") || _ua.contains("ipod"));

  static bool get isAndroidBrowser => UApp.isWeb && _ua.contains("android");

  static bool get isIosSafari {
    if (!isIosBrowser) return false;
    const List<String> nonSafari = <String>["crios", "fxios", "edgios", "opios", "mercury", "gsa"];
    if (nonSafari.any(_ua.contains)) return false;
    return _ua.contains("safari");
  }

  static bool get canPromptIosInstall => isIosBrowser && !isStandalone;

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

    final bool safari = force || isIosSafari;

    await UNavigator.bottomSheet<void>(
      _IosInstallSheet(
        title: title ?? U.s.openThisPageInSafariThenAddItToYourHomeScreen,
        safari: safari,
        step1: step1 ?? U.s.tapTheShareButtonInSafarisToolbar,
        step2: step2 ?? U.s.scrollDownAndTapAddToHomeScreen,
        step3: step3 ?? U.s.tapAddInTheTopRightCorner,
        safariHint: safariHint ?? U.s.openThisPageInSafariThenAddItToYourHomeScreen,
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
        spacing: 8,
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
              spacing: 8,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, color: scheme.primary),
                UTextBodyMedium(safariHint, expanded: 1),
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
      spacing: 8,
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
        UTextBodyMedium(text, expanded: 1),
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
