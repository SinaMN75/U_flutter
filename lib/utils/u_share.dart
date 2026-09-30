import "package:u/utilities.dart";

/// Sharing out (system share sheet, straight to one app) and receiving shares into the app.
/// Wraps [UShareChannel] (lib/plugins/share). Pass [origin] (the button's global rect) for the iPad / macOS popover.
abstract final class UShare {
  /// Shares text (and an optional [subject] for email targets).
  static Future<UShareResult> text(String text, {String? subject, String? title, Rect? origin}) => UShareChannel.share(text: text, subject: subject, title: title, origin: origin);

  /// Shares a link, with a rich preview on iOS; [message] goes before it.
  static Future<UShareResult> link(String url, {String? message, String? subject, String? title, Rect? origin}) =>
      UShareChannel.share(text: message, url: Uri.tryParse(url), subject: subject, title: title, origin: origin);

  /// Shares one file from disk.
  static Future<UShareResult> file(String path, {String? text, String? subject, String? name, String? mimeType, Rect? origin}) =>
      UShareChannel.share(files: <UShareFile>[UShareFile.path(path, name: name, mimeType: mimeType)], text: text, subject: subject, origin: origin);

  /// Shares several files from disk.
  static Future<UShareResult> files(List<String> paths, {String? text, String? subject, String? title, Rect? origin}) =>
      UShareChannel.share(files: paths.map(UShareFile.path).toList(), text: text, subject: subject, title: title, origin: origin);

  /// Shares bytes as a file named [name] (no temp-file handling needed).
  static Future<UShareResult> bytes(Uint8List bytes, {required String name, String? mimeType, String? text, String? subject, Rect? origin}) =>
      UShareChannel.share(files: <UShareFile>[UShareFile.bytes(bytes, name: name, mimeType: mimeType)], text: text, subject: subject, origin: origin);

  /// Shares any mix of text, link and files.
  static Future<UShareResult> share({String? text, String? subject, String? title, Uri? url, List<UShareFile> files = const <UShareFile>[], Rect? origin}) =>
      UShareChannel.share(text: text, subject: subject, title: title, url: url, files: files, origin: origin);

  /// Captures a widget (UWidgetToImage) and shares it as a PNG.
  static Future<UShareResult?> widgetImage(UWidgetToImageController controller, {String name = "image.png", String? text, String? subject, Rect? origin}) async {
    final Uint8List? captured = await controller.capture();
    if (captured == null) return null;
    return bytes(captured, name: name, mimeType: "image/png", text: text, subject: subject, origin: origin);
  }

  /// Shares straight to WhatsApp, Telegram, Eitaa, Rubika, … without the sheet (falls back to the sheet).
  static Future<UShareResult> to(UShareTarget target, {String? text, List<UShareFile> files = const <UShareFile>[]}) => UShareChannel.shareTo(target, text: text, files: files);

  /// True when [target] is installed and can receive a direct share.
  static Future<bool> canShareTo(UShareTarget target) => UShareChannel.canShareTo(target);

  /// What was shared into the app when a share launched it (null if none).
  static Future<UReceivedShare?> initialReceived() => UShareChannel.initial();

  /// Shares received while the app runs ("Share to MyApp", "Open with MyApp").
  static Stream<UReceivedShare> get received => UShareChannel.received;

  /// Calls [onShare] with the launch share and every later one.
  static Future<StreamSubscription<UReceivedShare>> onReceive(void Function(UReceivedShare share) onShare) async {
    final StreamSubscription<UReceivedShare> subscription = received.listen(onShare);
    final UReceivedShare? first = await initialReceived();
    if (first != null && !first.isEmpty) onShare(first);
    return subscription;
  }

  /// The global rect of the widget [context] belongs to (use as [origin]).
  static Rect? originOf(BuildContext context) {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
