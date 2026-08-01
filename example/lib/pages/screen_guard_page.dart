import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates the native ScreenGuard feature: toggle screenshot / recording
/// prevention and observe the detection callbacks.
class ScreenGuardPage extends StatefulWidget {
  const ScreenGuardPage({super.key});

  @override
  State<ScreenGuardPage> createState() => _ScreenGuardPageState();
}

class _ScreenGuardPageState extends State<ScreenGuardPage> {
  bool _enabled = false;
  bool _recording = false;
  int _screenshotCount = 0;

  @override
  void initState() {
    super.initState();
    // Detection callbacks fire even when the OS cannot hard-block capture (iOS).
    ScreenGuard.onScreenshot = () => setState(() => _screenshotCount++);
    ScreenGuard.onScreenRecording = (bool active) => setState(() => _recording = active);
  }

  @override
  void dispose() {
    ScreenGuard.onScreenshot = null;
    ScreenGuard.onScreenRecording = null;
    super.dispose();
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      await ScreenGuard.enable();
    } else {
      await ScreenGuard.disable();
    }
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GalleryPage(
      title: "ScreenGuard",
      intro: "A native plugin feature over the u/screen_guard channel: FLAG_SECURE on Android, "
          "secure-field + detection on iOS, sharingType on macOS, WDA_EXCLUDEFROMCAPTURE on "
          "Windows. Linux and web are safe no-ops.",
      sections: <Widget>[
        DemoSection(
          title: "Enable / disable",
          description: "While enabled, screenshots and recordings of this app are blocked or blanked. "
              "Try taking a screenshot with it on.",
          code: r'''
await ScreenGuard.enable();
await ScreenGuard.disable();''',
          child: URow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              UTextTitleMedium(_enabled ? "Protection ON" : "Protection OFF",
                  color: _enabled ? scheme.primary : scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
              Switch(value: _enabled, onChanged: _toggle),
            ],
          ),
        ),
        DemoSection(
          title: "Detection callbacks",
          description: "onScreenshot and onScreenRecording report events the OS can't fully block.",
          code: r'''
ScreenGuard.onScreenshot = () => setState(() => _screenshotCount++);
ScreenGuard.onScreenRecording = (bool active) => setState(() => _recording = active);''',
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              DemoLabel("Screenshots detected: $_screenshotCount"),
              DemoLabel(_recording ? "Screen recording: ACTIVE" : "Screen recording: idle"),
            ],
          ),
        ),
      ],
    );
  }
}
