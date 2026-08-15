import "package:u/utilities.dart";

abstract class UClipboard {
  static Future<void> set(String text, {bool snackBar = false}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (snackBar) UToast.snackBar(message: U.s.copiedToClipboard);
  }

  static Future<String?> getText() async {
    final ClipboardData? data = await Clipboard.getData("text/plain");
    return data?.text;
  }
}
