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
    if (uri.queryParameters["additionalData"] == null) return;
    _finish(uri.queryParameters["additionalData"]!);
  }

  void _onWebMessage(String origin, Map<String, dynamic> data) {
    if (finished || !(data["source"] == "u_ipg")) return;
    _finish(data["additionalData"]);
  }

  Future<void> _finish(String data) async {
    final UIpgAdditionalData i = UIpgAdditionalData.fromJson(data.fromBase58());
    finished = true;
    ULoading.show();
    final bool paid = i.status == 0 && i.rrn != null;
    ULoading.dismiss();
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
