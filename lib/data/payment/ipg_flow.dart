part of "../data.dart";

class UPaymentRequest {
  UPaymentRequest({
    required this.title,
    required this.amount,
    required this.onPay,
    this.lines = const <UKeyValue>[],
    this.receiptRows = const <UReceiptRow>[],
    this.icon = Icons.receipt_long_outlined,
  });

  final String title;
  final List<UKeyValue> lines;
  final List<UReceiptRow> receiptRows;
  final IconData icon;
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
    UReceipt? receipt,
    bool showReceipt = true,
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
          final String trackingNumber = response.result!.trackingNumber;
          paid = await UNavigator.push<bool>(UIpgWebViewPage(url: response.result!.url, trackingNumber: trackingNumber)) ?? false;
          if (paid && showReceipt) await _showReceipt(amount: amount, trackingNumber: trackingNumber, receipt: receipt);
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
          final String trackingNumber = response.result!.trackingNumber;
          paid = await UNavigator.push<bool>(UIpgWebViewPage(url: response.result!.url, trackingNumber: trackingNumber)) ?? false;
          if (paid && showReceipt) await _showReceipt(amount: amount, trackingNumber: trackingNumber, receipt: receipt);
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

  static Future<void> _showReceipt({required double amount, required String trackingNumber, UReceipt? receipt}) => UReceiptSheet.show(
    UReceipt(
      title: receipt?.title ?? U.s.chargeWallet,
      amount: receipt?.amount ?? amount.toInt(),
      icon: receipt?.icon ?? Icons.add_card_outlined,
      method: receipt?.method ?? U.s.onlinePayment,
      trackingNumber: receipt?.trackingNumber ?? trackingNumber,
      date: receipt?.date,
      rows: receipt?.rows ?? const <UReceiptRow>[],
    ),
  );

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
