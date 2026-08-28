import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates context-free feedback: UToast, UNavigator dialogs/sheets,
/// ULoading overlay, and the progress / rating widgets.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  double _rating = 3.5;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GalleryPage(
    title: "Feedback",
    intro: "UToast, UNavigator and ULoading all work without a BuildContext because the app "
        "handed its navigatorKey to MaterialApp — so you can call them from anywhere.",
    sections: <Widget>[
      DemoSection(
        title: "UToast",
        description: "Typed snackbars: success, error, warning, info.",
        code: r'''
UToast.success(message: "Saved");
UToast.error(message: "Something failed");
UToast.warning(message: "Careful");''',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            UButton(title: "Success", type: UButtonType.outlined, onTap: () => UToast.success(message: "Saved")),
            UButton(title: "Error", type: UButtonType.outlined, onTap: () => UToast.error(message: "Something failed")),
            UButton(title: "Warning", type: UButtonType.outlined, onTap: () => UToast.warning(message: "Careful")),
            UButton(title: "Info", type: UButtonType.outlined, onTap: () => UToast.info(message: "Just so you know")),
          ],
        ),
      ),
      DemoSection(
        title: "UNavigator dialogs & sheets",
        description: "Confirm dialogs, text-input dialogs and bottom sheets, all context-free.",
        code: r'''
final bool ok = await UNavigator.confirmAsync(title: "Delete?", message: "This cannot be undone");
final String? name = await UNavigator.inputDialog(title: "Your name", hint: "Type here");
UNavigator.bottomSheet(child);''',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            UButton(
              title: "Confirm",
              type: UButtonType.outlined,
              onTap: () async {
                final bool ok = await UNavigator.confirmAsync(title: "Delete?", message: "This cannot be undone");
                UToast.info(message: ok ? "Confirmed" : "Cancelled");
              },
            ),
            UButton(
              title: "Input",
              type: UButtonType.outlined,
              onTap: () async {
                final String? name = await UNavigator.inputDialog(title: "Your name", hint: "Type here");
                if (name != null) UToast.success(message: "Hello, $name");
              },
            ),
            UButton(
              title: "Bottom sheet",
              type: UButtonType.outlined,
              onTap: () => UNavigator.bottomSheet<void>(
                const UTextBodyLarge("A UNavigator bottom sheet.", margin: EdgeInsets.all(24)),
              ),
            ),
          ],
        ),
      ),
      DemoSection(
        title: "ULoading",
        description: "A global blocking spinner overlay — show it, then dismiss when work finishes.",
        code: r'''
ULoading.show();
await doWork();
ULoading.dismiss();''',
        child: UButton(
          title: "Show for 2s",
          onTap: () {
            ULoading.show();
            Future<void>.delayed(const Duration(seconds: 2), ULoading.dismiss);
          },
        ),
      ),
      DemoSection(
        title: "Progress",
        description: "Determinate or indeterminate linear and circular progress.",
        code: r'''
UProgressLinear(value: 65);
UProgressCircular(value: 65);''',
        child: URow(
          spacing: 24,
          children: <Widget>[
            const Expanded(child: UProgressLinear(value: 65)),
            const UProgressCircular(value: 65),
          ],
        ),
      ),
      DemoSection(
        title: "RatingBar",
        description: "A half-step rating input; onRatingUpdate reports the new value.",
        code: r'''
RatingBar.builder(
  initialRating: 3.5,
  allowHalfRating: true,
  itemBuilder: (BuildContext context, int _) => const Icon(Icons.star),
  onRatingUpdate: (double v) => setState(() => _rating = v),
);''',
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            RatingBar.builder(
              initialRating: _rating,
              allowHalfRating: true,
              itemSize: 32,
              itemBuilder: (BuildContext context, int _) => Icon(Icons.star, color: scheme.primary),
              onRatingUpdate: (double v) => setState(() => _rating = v),
            ),
            DemoLabel("Rating: $_rating"),
          ],
        ),
      ),
    ],
    );
  }
}
