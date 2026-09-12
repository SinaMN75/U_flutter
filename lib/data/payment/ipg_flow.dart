part of "../data.dart";

class UPaymentRequest {
  UPaymentRequest({
    required this.title,
    required this.amount,
    required this.onPay,
    this.lines = const <UKeyValue>[],
  });

  final String title;
  final List<UKeyValue> lines;
  final int amount;
  final Future<bool> Function() onPay;
}

abstract class UIpgFlow {
  static Future<bool> pay({
    required double amount,
    Function(bool)? onPaid,
    TagTxn? tag,
    String? invoiceId,
    String? billId,
    String? paymentId,
  }) async {
    final Completer<bool> completer = Completer<bool>();
    bool paid = false;
    if (amount <= 0) UToast.error(message: U.s.invalidAmount);
    ULoading.show();
    if (billId == null || paymentId == null) {
      await UServices.ipg.pay(
        p: UIpgSaleParams(amount: amount, tag: tag, invoiceId: invoiceId),
        onOk: (UResponse<UIpgPayResponse> response) async {
          ULoading.dismiss();
          paid = await UNavigator.push<bool>(UIpgWebViewPage(url: response.result!.url, trackingNumber: response.result!.trackingNumber)) ?? false;
          completer.complete(paid);
          onPaid?.call(paid);
        },
        onError: (UEmptyResponse e) {
          ULoading.dismiss();
          UToast.error(message: e.message);
          onPaid?.call(false);
          completer.complete(false);
        },
        onException: (String e) {
          ULoading.dismiss();
          UToast.error(message: e);
          onPaid?.call(false);
          completer.complete(false);
        },
      );
    } else {
      await UServices.ipg.payBill(
        p: UIpgBillParams(billId: billId, paymentId: paymentId),
        onOk: (UResponse<UIpgPayResponse> response) async {
          ULoading.dismiss();
          paid = await UNavigator.push<bool>(UIpgWebViewPage(url: response.result!.url, trackingNumber: response.result!.trackingNumber)) ?? false;
          completer.complete(paid);
          onPaid?.call(paid);
        },
        onError: (UEmptyResponse e) {
          ULoading.dismiss();
          UToast.error(message: e.message);
          onPaid?.call(false);
          completer.complete(false);
        },
        onException: (String e) {
          ULoading.dismiss();
          UToast.error(message: e);
          onPaid?.call(false);
          completer.complete(false);
        },
      );
    }
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
}
