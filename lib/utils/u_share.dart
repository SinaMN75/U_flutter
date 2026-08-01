import "package:u/utilities.dart";

abstract class UShare {
  static Future<ShareResult> text({
    required String text,
    String? subject,
    String? title,
    Rect? sharePositionOrigin,
  }) => SharePlus.instance.share(ShareParams(text: text, subject: subject, title: title, sharePositionOrigin: sharePositionOrigin));

  static Future<ShareResult> link({
    required String url,
    String? message,
    String? subject,
    String? title,
    Rect? sharePositionOrigin,
  }) {
    if (message != null && message.isNotEmpty) return text(text: "$message\n$url", subject: subject, title: title, sharePositionOrigin: sharePositionOrigin);
    return SharePlus.instance.share(ShareParams(uri: Uri.parse(url), sharePositionOrigin: sharePositionOrigin));
  }

  static Future<ShareResult> files({
    required List<String> paths,
    String? text,
    String? subject,
    String? title,
    List<String>? fileNames,
    Rect? sharePositionOrigin,
  }) => SharePlus.instance.share(
    ShareParams(
      files: paths.map(XFile.new).toList(),
      fileNameOverrides: fileNames,
      text: text,
      subject: subject,
      title: title,
      sharePositionOrigin: sharePositionOrigin,
    ),
  );

  static Future<ShareResult> file({
    required String path,
    String? text,
    String? subject,
    String? fileName,
    Rect? sharePositionOrigin,
  }) => files(
    paths: <String>[path],
    text: text,
    subject: subject,
    fileNames: fileName != null ? <String>[fileName] : null,
    sharePositionOrigin: sharePositionOrigin,
  );

  static Future<ShareResult> xFiles({
    required List<XFile> files,
    String? text,
    String? subject,
    String? title,
    Rect? sharePositionOrigin,
  }) => SharePlus.instance.share(ShareParams(files: files, text: text, subject: subject, title: title, sharePositionOrigin: sharePositionOrigin));

  static Future<ShareResult> bytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    String? text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    final Directory dir = await getTemporaryDirectory();
    final File tempFile = await File("${dir.path}/$fileName").writeAsBytes(bytes);
    return SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(tempFile.path, mimeType: mimeType, name: fileName)],
        text: text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  static Future<ShareResult?> widgetImage({
    required WidgetToImageController controller,
    String fileName = "image.png",
    String? text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    final Uint8List? captured = await controller.capture();
    if (captured == null) return null;
    return bytes(
      bytes: captured,
      fileName: fileName,
      mimeType: "image/png",
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static bool wasShared(ShareResult result) => result.status == ShareResultStatus.success;
}

// -----------------------------------------------------------------------------
// USAGE EXAMPLES
// -----------------------------------------------------------------------------
//
// Text & links
// ------------
//   await UShare.text(text: U.s.checkOutThisApp, subject: U.s.invitation);
//   await UShare.link(url: "https://example.com/post/42");
//   await UShare.link(url: "https://example.com/post/42", message: U.s.readThis);
//
// Files
// -----
//   await UShare.file(path: pdfPath, fileName: "invoice.pdf", text: U.s.yourInvoice);
//   await UShare.files(paths: <String>[img1, img2], subject: U.s.photos);
//   await UShare.xFiles(files: pickedImages); // XFiles straight from the picker
//
// Bytes & captured widgets
// ------------------------
//   // Share an in-memory PDF/image without touching the file system yourself.
//   await UShare.bytes(bytes: pdfBytes, fileName: "receipt.pdf", mimeType: "application/pdf");
//
//   // Capture a receipt/card widget and share it as a PNG.
//   final WidgetToImageController controller = WidgetToImageController();
//   // ... WidgetToImage(controller: controller, child: ReceiptCard()) somewhere in the tree
//   await UShare.widgetImage(controller: controller, fileName: "receipt.png", text: U.s.myReceipt);
//
// Reacting to the outcome
// -----------------------
//   final ShareResult result = await UShare.text(text: link);
//   if (UShare.wasShared(result)) UToast.success(message: U.s.shared);
//
// Note: on iPad the OS requires an anchor rect — pass `sharePositionOrigin`
// (e.g. the button's global rect) to position the share popover.
// -----------------------------------------------------------------------------
