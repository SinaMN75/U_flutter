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
    required UIpgPayParams p,
    Function(bool)? onPaid,
    UReceipt? receipt,
  }) async {
    final Completer<bool> completer = Completer<bool>();
    bool paid = false;
    if (p.amount <= 0) UToast.error(message: U.s.invalidAmount);
    ULoading.show();
    await UServices.ipg.pay(
      p: UIpgPayParams(
        amount: p.amount,
        tag: p.tag,
        invoiceId: p.invoiceId,
        billId: p.billId,
        paymentId: p.paymentId,
        chargeMobileNumber: p.chargeMobileNumber,
        topUpType: p.topUpType,
        multiplexedAccounts: p.multiplexedAccounts,
      ),
      onOk: (UResponse<UIpgPayResponse> response) async {
        ULoading.dismiss();
        final UIpgAdditionalData requested = response.result!.additionalData;
        final UIpgAdditionalData? settled = await UNavigator.push<UIpgAdditionalData>(UIpgWebViewPage(url: response.result!.url, additionalData: requested));
        paid = settled?.paid ?? false;
        if (paid && receipt != null) {
          await _showReceipt(
            amount: p.amount,
            trackingNumber: settled?.trackingNumber ?? requested.trackingNumber ?? "---",
            receipt: receipt,
            rows: UReceiptKeyValues.rows(settled?.keyValues ?? <UKeyValueData>[]),
            title: _title(billId: p.billId, chargeMobileNumber: p.chargeMobileNumber, multiplexedAccounts: p.multiplexedAccounts),
          );
        }
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
    return completer.future;
  }

  static String _title({String? billId, String? chargeMobileNumber, List<UIpgMultiplexedAccountParams>? multiplexedAccounts}) {
    if (billId != null) return U.s.billPayment;
    if (chargeMobileNumber != null) return U.s.directTopUp;
    if (multiplexedAccounts != null && multiplexedAccounts.isNotEmpty) return U.s.multiplexedPayment;
    return U.s.chargeWallet;
  }

  static Future<void> _showReceipt({
    required double amount,
    required String trackingNumber,
    required String title,
    UReceipt? receipt,
    List<UReceiptRow> rows = const <UReceiptRow>[],
  }) => UReceiptSheet.show(
    UReceipt(
      title: receipt?.title ?? title,
      amount: receipt?.amount ?? amount.toInt(),
      icon: receipt?.icon ?? Icons.add_card_outlined,
      method: receipt?.method ?? U.s.onlinePayment,
      trackingNumber: receipt?.trackingNumber ?? trackingNumber,
      date: receipt?.date,
      rows: rows.isNotEmpty ? rows : (receipt?.rows ?? const <UReceiptRow>[]),
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
      p: UIpgPayParams(amount: amount, tag: tag, invoiceId: invoiceId),
      onOk: (UResponse<UIpgPayResponse> r) => url = r.result?.url,
      onError: (UEmptyResponse e) => UToast.error(message: e.message),
      onException: (String e) => UToast.error(message: e),
    );
    ULoading.dismiss();
    return url;
  }
}
