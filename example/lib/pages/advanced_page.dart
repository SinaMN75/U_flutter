import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Rich-text editing, signature capture, and the backend-driven multi-step
/// process engine.
class AdvancedPage extends StatelessWidget {
  const AdvancedPage({super.key});

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "Advanced forms",
    intro: "A full WYSIWYG HTML editor, a signature pad, and UProcessView — a server-driven engine "
        "that renders multi-step forms (text, images, e-sign, visual auth) from your backend.",
    sections: <Widget>[
      DemoSection(
        title: "URichTextEditor",
        description: "A WYSIWYG editor that emits HTML; supports images, tables, auto-save and read-only.",
        code: r'''URichTextEditor(initialHtml: "<p>Edit me…</p>", onChanged: (String html) {});''',
        child: SizedBox(
          height: 320,
          child: URichTextEditor(
            initialHtml: "<h3>Edit me</h3><p>Bold, lists, links, images and tables — output is clean HTML.</p>",
            onChanged: (String html) {},
          ),
        ),
      ),
      DemoSection(
        title: "USignaturePad",
        description: "Capture a signature; onSave returns it as a FileData (PNG bytes).",
        code: r'''USignaturePad(onSave: (FileData f) => upload(f));''',
        child: SizedBox(
          height: 240,
          child: USignaturePad(onSave: (FileData f) => UToast.success(message: "Signature captured")),
        ),
      ),
      DemoSection(
        title: "UProcessView",
        description: "Renders a backend-defined multi-step process by id: UProcessTextField, "
            "UProcessImagePickerField, UProcessESignField and UProcessVisualAuthField, with a "
            "UProcessStepsIndicator. Needs U.baseUrl / U.apiKey and a valid processId.",
        code: r'''UProcessView(processId: "onboarding-kyc");''',
        child: const UTextBodySmall("Reference — drop UProcessView(processId: …) into a page once your backend is configured."),
      ),
    ],
  );
}
