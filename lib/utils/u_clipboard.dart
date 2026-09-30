import "package:u/utilities.dart";

/// Copy and paste text on all 6 platforms (web: needs a user gesture and, for reading, browser permission). `UClipboard.set(code, snackBar: true)`
abstract class UClipboard {
  /// Copies [text]; [snackBar] shows "Copied to clipboard". `await UClipboard.set(iban, snackBar: true)`
  static Future<void> set(String text, {bool snackBar = false}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (snackBar) UToast.successToast(message: U.s.copiedToClipboard);
  }

  /// Reads text from the clipboard, or null. `final String? pasted = await UClipboard.getText();`
  static Future<String?> getText() async {
    final ClipboardData? data = await Clipboard.getData("text/plain");
    return data?.text;
  }
}
