part of "../data.dart";

class UIpgWebViewController {
  UIpgWebViewController({required this.additionalData}) {
    if (kIsWeb) _webMessageDispose = UWebMessage.listen(_onWebMessage);
  }

  final UIpgAdditionalData additionalData;
  bool finished = false;

  void Function()? _webMessageDispose;

  void cancel() {
    if (finished) return;
    finished = true;
    UNavigator.back<bool>(false);
  }

  void onPageFinished(String url) {
    if (finished) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.path.toLowerCase().contains("/ipg/verify")) return;
    if (uri.queryParameters["done"] != "true" || uri.queryParameters["additionalData"] == null) return;
    _finish(uri.queryParameters["additionalData"]!);
  }

  void _onWebMessage(String origin, Map<String, dynamic> data) {
    if (finished || !(data["source"] == "u_ipg")) return;
    _finish(data["additionalData"]);
  }

  void _finish(String data) {
    final UIpgAdditionalData i = UIpgAdditionalData.fromJson(data.fromBase58());
    finished = true;
    UToast.snackBar(message: i.paid ? U.s.paymentWasSuccessful : U.s.paymentFailed);
    UNavigator.back<bool>(i.paid);
  }

  void confirmCancel() {
    UNavigator.back();
    if (finished) return;
    finished = true;
    UNavigator.back<bool>(false);
  }

  void dispose() => _webMessageDispose?.call();
}
