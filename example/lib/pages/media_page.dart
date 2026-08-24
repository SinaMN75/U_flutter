import "package:u/components/cached_image.dart";
import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates image, file, barcode, HTML and web widgets.
class MediaPage extends StatelessWidget {
  const MediaPage({super.key});

  static const String _img = "https://picsum.photos/seed/uplugin/600/400";

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "Media & files",
    intro: "Network/asset/file/memory images with caching and placeholders, a file picker, "
        "barcode generation, an HTML renderer, an image carousel and an embedded web view.",
    sections: <Widget>[
      DemoSection(
        title: "UImageNetwork / CachedNetworkImage",
        description: "Network images with rounded corners, sizing and disk caching.",
        code: r'''
UImageNetwork("https://…/photo.jpg", width: 140, height: 100, borderRadius: 12, fit: BoxFit.cover);
CachedNetworkImage(imageUrl: "https://…/photo.jpg", width: 140, height: 100);''',
        child: URow(
          spacing: 12,
          children: <Widget>[
            const UImageNetwork(_img, width: 140, height: 100, fit: BoxFit.cover),
            const CachedNetworkImage(imageUrl: _img, width: 140, height: 100, fit: BoxFit.cover),
          ],
        ),
      ),
      DemoSection(
        title: "USlider",
        description: "An auto-playing image carousel with page indicators.",
        code: r'''
USlider(
  height: 160,
  images: <Widget>[UImageNetwork(a, fit: BoxFit.cover), UImageNetwork(b, fit: BoxFit.cover)],
);''',
        child: SizedBox(
          height: 160,
          child: USlider(
            height: 160,
            radius: 12,
            images: const <Widget>[
              UImageNetwork("https://picsum.photos/seed/a/600/300", fit: BoxFit.cover),
              UImageNetwork("https://picsum.photos/seed/b/600/300", fit: BoxFit.cover),
              UImageNetwork("https://picsum.photos/seed/c/600/300", fit: BoxFit.cover),
            ],
          ),
        ),
      ),
      DemoSection(
        title: "UBarcode",
        description: "Generate a QR code (or other symbologies via UBarcodeType).",
        code: r'''UBarcode(value: "https://sinamn75.com", type: UBarcodeType.qrCode, showValue: true);''',
        child: const SizedBox(
          height: 140,
          width: 140,
          child: UBarcode(value: "https://sinamn75.com", showValue: true),
        ),
      ),
      DemoSection(
        title: "UFilePicker",
        description: "Pick one or more files/images; onFilesChanged returns the selection.",
        code: r'''UFilePicker(onFilesChanged: (List<FileData> files) => setState(...));''',
        child: UFilePicker(onFilesChanged: (List<FileData> files) => UToast.info(message: "${files.length} file(s)")),
      ),
      DemoSection(
        title: "UHtmlView",
        description: "Render an HTML string with selectable text and code-copy buttons.",
        code: r'''UHtmlView(html: "<h3>Title</h3><p>Rich <b>HTML</b> content.</p>");''',
        child: const UHtmlView(html: "<h3>Title</h3><p>Rich <b>HTML</b> content with a <a href='#'>link</a>.</p>"),
      ),
      DemoSection(
        title: "UWebView",
        description: "A full in-app browser with optional URL bar and navigation controls.",
        code: r'''UWebView(initialUrl: "https://flutter.dev");''',
        child: SizedBox(
          height: 260,
          child: UWebView(initialUrl: "https://flutter.dev", showUrlBar: false),
        ),
      ),
      DemoSection(
        title: "UScanner",
        description: "A full-screen QR/barcode scanner page — push it and await the result.",
        code: r'''UNavigator.push(const UScannerPage());''',
        child: UButton(
          title: "Open scanner",
          icon: const Icon(Icons.qr_code_scanner, size: 18),
          onTap: () => UNavigator.push<void>(const UScannerPage()),
        ),
      ),
    ],
  );
}
