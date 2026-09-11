part of "../data.dart";

const List<String> _uIpgWebSources = <String>["u_ipg", "avahamrah_ipg"];

class UIpgWebViewController {
  UIpgWebViewController({required this.trackingNumber}) {
    if (kIsWeb) _webMessageDispose = UWebMessage.listen(_onWebMessage);
  }

  final String trackingNumber;
  bool finished = false;

  void Function()? _webMessageDispose;

  void cancel() {
    if (finished) return;
    finished = true;
    UNavigator.back<bool>(false);
  }

  bool _isCallback(Uri uri) => uri.path.toLowerCase().contains("/ipg/verify") && uri.queryParameters.containsKey("status");

  void onPageFinished(String url) {
    if (finished) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !_isCallback(uri)) return;
    _finish(uri.queryParameters["status"] == "0");
  }

  void _onWebMessage(String origin, Map<String, dynamic> data) {
    if (finished || !_uIpgWebSources.contains(data["source"])) return;
    _finish("${data["status"]}" == "0");
  }

  Future<void> _finish(bool gatewayPaid) async {
    finished = true;
    ULoading.show();
    final bool paid = await _readStatus(gatewayPaid);
    ULoading.dismiss();
    UToast.snackBar(message: paid ? U.s.paymentWasSuccessful : U.s.paymentFailed);
    UNavigator.back<bool>(paid);
  }

  Future<bool> _readStatus(bool fallback) async {
    if (trackingNumber.isEmpty) return fallback;
    bool? paid;
    await UServices.ipg.status(
      p: UIpgVerifyParams(trackingNumber: trackingNumber),
      onOk: (UResponse<UIpgVerifyResponse> r) => paid = r.result?.paid,
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return paid ?? fallback;
  }

  void confirmCancel() {
    UNavigator.back();
    if (finished) return;
    finished = true;
    UNavigator.back<bool>(false);
  }

  void dispose() => _webMessageDispose?.call();
}
