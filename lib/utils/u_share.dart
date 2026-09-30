import "package:u/utilities.dart";

/// Shares text, links and files through the system sheet or straight to one app, and receives shares into the app. All 6 platforms. `UShare.text("Hello")`
abstract final class UShare {
  /// Shares text; [subject] is used by email apps; on iPad/macOS pass [origin]. Linux copies to the clipboard. `UShare.text("Check this out", origin: UShare.originOf(context))`
  static Future<UShareResult> text(String text, {String? subject, String? title, Rect? origin}) => UShareChannel.share(text: text, subject: subject, title: title, origin: origin);

  /// Shares a link with a rich preview on iOS/macOS; [message] goes before it. `UShare.link("https://x.com/p/1", message: "New product")`
  static Future<UShareResult> link(String url, {String? message, String? subject, String? title, Rect? origin}) =>
      UShareChannel.share(text: message, url: Uri.tryParse(url), subject: subject, title: title, origin: origin);

  /// Shares one file from disk (Linux: shows it in the file manager). `UShare.file("/path/report.pdf")`
  static Future<UShareResult> file(String path, {String? text, String? subject, String? name, String? mimeType, Rect? origin}) => UShareChannel.share(
    files: <UShareFile>[UShareFile.path(path, name: name, mimeType: mimeType)],
    text: text,
    subject: subject,
    origin: origin,
  );

  /// Shares several files from disk. `UShare.files([a, b])`
  static Future<UShareResult> files(List<String> paths, {String? text, String? subject, String? title, Rect? origin}) =>
      UShareChannel.share(files: paths.map(UShareFile.path).toList(), text: text, subject: subject, title: title, origin: origin);

  /// Shares bytes as a file called [name]; no temp file handling needed. `UShare.bytes(pdfBytes, name: "invoice.pdf")`
  static Future<UShareResult> bytes(Uint8List bytes, {required String name, String? mimeType, String? text, String? subject, Rect? origin}) => UShareChannel.share(
    files: <UShareFile>[UShareFile.bytes(bytes, name: name, mimeType: mimeType)],
    text: text,
    subject: subject,
    origin: origin,
  );

  /// Shares any mix of text, link and files in one sheet. `UShare.share(text: "Invoice", files: [UShareFile.path(p)])`
  static Future<UShareResult> share({String? text, String? subject, String? title, Uri? url, List<UShareFile> files = const <UShareFile>[], Rect? origin}) =>
      UShareChannel.share(text: text, subject: subject, title: title, url: url, files: files, origin: origin);

  /// Takes a picture of a UWidgetToImage and shares it as PNG (e.g. a receipt). `UShare.widgetImage(controller, name: "receipt.png")`
  static Future<UShareResult?> widgetImage(UWidgetToImageController controller, {String name = "image.png", String? text, String? subject, Rect? origin}) async {
    final Uint8List? captured = await controller.capture();
    if (captured == null) return null;
    return bytes(captured, name: name, mimeType: "image/png", text: text, subject: subject, origin: origin);
  }

  /// Shares straight to WhatsApp, Telegram, Eitaa, Rubika… without the sheet; falls back to the sheet (Android best, iOS text only). `UShare.to(UShareTarget.telegram, text: "Hi")`
  static Future<UShareResult> to(UShareTarget target, {String? text, List<UShareFile> files = const <UShareFile>[]}) => UShareChannel.shareTo(target, text: text, files: files);

  /// True when [target] is installed and can take a direct share. `if (await UShare.canShareTo(UShareTarget.whatsapp)) …`
  static Future<bool> canShareTo(UShareTarget target) => UShareChannel.canShareTo(target);

  /// What was shared into the app when that share opened it, or null. Needs `dart run u:app share-target`. `final share = await UShare.initialReceived();`
  static Future<UReceivedShare?> initialReceived() => UShareChannel.initial();

  /// Shares received while the app runs ("Share to MyApp", "Open with MyApp"). Needs `dart run u:app share-target`.
  static Stream<UReceivedShare> get received => UShareChannel.received;

  /// Calls [onShare] for the launch share and every later one; web needs a PWA with share_target in the manifest. `UShare.onReceive((s) => importFiles(s.files))`
  static Future<StreamSubscription<UReceivedShare>> onReceive(void Function(UReceivedShare share) onShare) async {
    final StreamSubscription<UReceivedShare> subscription = received.listen(onShare);
    final UReceivedShare? first = await initialReceived();
    if (first != null && !first.isEmpty) onShare(first);
    return subscription;
  }

  /// Screen rect of the widget that owns [context]; pass it as origin so the iPad/macOS share popover points at your button. `UShare.originOf(context)`
  static Rect? originOf(BuildContext context) {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
