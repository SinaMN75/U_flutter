part of "../data.dart";

class UIpgWebViewController {
  bool finished = false;

  void cancel() {
    if (finished) return;
    finished = true;
    UNavigator.back<bool>(false);
  }

  UIpgWebViewController() {
    if (kIsWeb) _webMessageDispose = UWebMessage.listen(_onWebMessage);
  }

  void Function()? _webMessageDispose;

  bool _isCallback(Uri uri) => uri.path.toLowerCase().contains("/ipg/verify") && uri.queryParameters.containsKey("status");

  void onPageFinished(String url) {
    if (finished) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !_isCallback(uri)) return;
    _finish(uri.queryParameters["status"] == "0");
  }

  void _onWebMessage(String origin, Map<String, dynamic> data) {
    if (finished || data["source"] != "avahamrah_ipg") return;
    _finish("${data["status"]}" == "0");
  }

  void _finish(bool paid) {
    finished = true;
    UToast.snackBar(message: paid ? U.s.paymentWasSuccessful : U.s.paymentFailed);
    UNavigator.back<bool>(paid);
  }

  void confirmCancel() {
    UNavigator.back();
    if (finished) return;
    finished = true;
    UNavigator.back<bool>(false);
  }

  void dispose() => _webMessageDispose?.call();
}
