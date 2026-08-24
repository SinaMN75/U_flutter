import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates `UButton` and its `UButtonType` variants, icons, loading and
/// disabled states, plus the built-in tap counter.
class ButtonsPage extends StatelessWidget {
  const ButtonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color onGradient = Theme.of(context).colorScheme.onPrimary;
    return GalleryPage(
    title: "Buttons",
    intro: "One UButton covers elevated, text, outlined, icon and FAB styles via UButtonType, "
        "with loading/disabled states and an optional counter baked in.",
    sections: <Widget>[
      DemoSection(
        title: "Variants (UButtonType)",
        description: "Switch the whole look with a single enum value.",
        code: r'''
UButton(title: "Elevated", onTap: () {});
UButton(title: "Outlined", type: UButtonType.outlined, onTap: () {});
UButton(title: "Text", type: UButtonType.text, onTap: () {});''',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            UButton(title: "Elevated", onTap: () => UToast.success(message: "Tapped elevated")),
            UButton(title: "Outlined", type: UButtonType.outlined, onTap: () {}),
            UButton(title: "Text", type: UButtonType.text, onTap: () {}),
          ],
        ),
      ),
      DemoSection(
        title: "Icon, gradient & radius",
        description: "Add a leading/trailing icon, a gradient fill, and a custom corner radius.",
        code: r'''
UButton(
  title: "Download",
  icon: const Icon(Icons.download, size: 18),
  gradient: const LinearGradient(colors: <Color>[Color(0xFF3D5AFE), Color(0xFF00B0FF)]),
  borderRadius: 24,
  onTap: () {},
);''',
        child: UButton(
          title: "Download",
          icon: Icon(Icons.download, size: 18, color: onGradient),
          gradient: const LinearGradient(colors: <Color>[Color(0xFF3D5AFE), Color(0xFF00B0FF)]),
          foregroundColor: onGradient,
          borderRadius: 24,
          onTap: () {},
        ),
      ),
      DemoSection(
        title: "Loading & disabled",
        description: "isLoading swaps the label for a spinner; enabled: false greys it out.",
        code: r'''
UButton(title: "Saving…", isLoading: true, onTap: () {});
UButton(title: "Disabled", enabled: false, onTap: () {});''',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            UButton(title: "Saving…", isLoading: true, onTap: () {}),
            UButton(title: "Disabled", enabled: false, onTap: () {}),
          ],
        ),
      ),
      DemoSection(
        title: "Submit / cancel pair",
        description: "UButtonSubmitCancel lays out a confirming and a dismissing action together.",
        code: r'''
UButtonSubmitCancel(
  onSubmit: () {},
  onCancel: () {},
);''',
        child: UButtonSubmitCancel(onSubmit: () {}, onCancel: () {}),
      ),
      DemoSection(
        title: "UPressable",
        description: "Wrap any widget to get a themed ink/scale press effect.",
        code: r'''UPressable(onTap: () {}, child: myCard);''',
        child: UPressable(
          onTap: () => UToast.info(message: "Pressed"),
          child: UContainer(
            color: Theme.of(context).colorScheme.secondaryContainer,
            radius: 12,
            padding: const EdgeInsets.all(16),
            child: const UTextBodyMedium("Press me"),
          ),
        ),
      ),
      DemoSection(
        title: "USendAgainCountDown",
        description: "A resend-code button that counts down before re-enabling.",
        code: r'''
USendAgainCountDown(
  counter: 30,
  buttonTitle: "Resend code",
  counterDescription: "Resend in",
  onSendAgainTap: () {},
);''',
        child: USendAgainCountDown(
          counter: 30,
          buttonTitle: "Resend code",
          counterDescription: "Resend in",
          onSendAgainTap: () => UToast.success(message: "Code resent"),
        ),
      ),
    ],
    );
  }
}
