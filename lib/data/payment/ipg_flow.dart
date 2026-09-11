part of "../data.dart";

abstract class UIpgFlow {
  static Future<bool> topUp(int amount) => pay(amount: amount.toDouble());

  static Future<bool> pay({required double amount, TagTxn? tag, String? invoiceId}) async {
    if (amount <= 0) {
      UToast.error(message: U.s.invalidAmount);
      return false;
    }
    final Completer<bool> completer = Completer<bool>();
    ULoading.show();
    await UServices.ipg.pay(
      p: UIpgSaleParams(amount: amount, tag: tag, invoiceId: invoiceId),
      onOk: (UResponse<UIpgPayResponse> r) async {
        ULoading.dismiss();
        completer.complete(await _open(r));
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        UToast.error(message: e.message);
        completer.complete(false);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
        completer.complete(false);
      },
    );
    return completer.future;
  }

  static Future<bool> payBill({required String billId, required String paymentId}) async {
    final Completer<bool> completer = Completer<bool>();
    ULoading.show();
    await UServices.ipg.payBill(
      p: UIpgBillParams(billId: billId, paymentId: paymentId),
      onOk: (UResponse<UIpgPayResponse> r) async {
        ULoading.dismiss();
        completer.complete(await _open(r));
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        UToast.error(message: e.message);
        completer.complete(false);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
        completer.complete(false);
      },
    );
    return completer.future;
  }

  static Future<String?> link({required double amount, TagTxn? tag, String? invoiceId}) async {
    if (amount <= 0) {
      UToast.error(message: U.s.invalidAmount);
      return null;
    }
    ULoading.show();
    String? url;
    await UServices.ipg.pay(
      p: UIpgSaleParams(amount: amount, tag: tag, invoiceId: invoiceId),
      onOk: (UResponse<UIpgPayResponse> r) => url = r.result?.url,
      onError: (UEmptyResponse e) => UToast.error(message: e.message),
      onException: (String e) => UToast.error(message: e),
    );
    ULoading.dismiss();
    return url;
  }

  static Future<bool> _open(UResponse<UIpgPayResponse> r) async {
    final UIpgPayResponse? data = r.result;
    if (data == null || data.url.isEmpty) {
      UToast.error(message: r.message);
      return false;
    }
    return await UNavigator.push<bool>(UIpgWebViewPage(url: data.url, trackingNumber: data.trackingNumber)) ?? false;
  }
}
