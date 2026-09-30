part of "../data.dart";

// Opens the gateway in the system browser (a new tab on web) and learns the outcome from the txn that
// ipg/Pay created, so no page ever has to report back and no backend change is needed.
class UIpgBrowserController {
  UIpgBrowserController({required this.url, required this.additionalData}) {
    _lifecycle = AppLifecycleListener(onResume: check);
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => check());
    open();
  }

  final String url;
  final UIpgAdditionalData additionalData;
  bool finished = false;
  bool _checking = false;

  late final AppLifecycleListener _lifecycle;
  late final Timer _poll;

  Future<void> open() => ULaunch.external(url);

  Future<void> check({bool showPending = false}) async {
    if (finished || _checking) return;
    _checking = true;
    final (UResponse<List<UTxnResponse>>? r, _, _) = await UServices.txn.read(
      p: UTxnReadParams(creatorId: U.user.id, orderBy: TagOrderBy.createdAtDescending.number, pageNumber: 1, pageSize: 10),
    );
    _checking = false;
    if (finished) return;

    final UTxnResponse? txn = r?.result?.firstWhereOrNull((UTxnResponse e) => e.trackingNumber == additionalData.trackingNumber);
    if (txn != null && txn.tags.contains(TagTxn.paid.number)) return _finish(txn, paid: true);
    if (txn != null && txn.tags.contains(TagTxn.failed.number)) return _finish(txn, paid: false);
    if (showPending) UToast.snackBar(message: U.s.thePaymentHasNotBeenConfirmedYet);
  }

  void _finish(UTxnResponse txn, {required bool paid}) {
    finished = true;
    UToast.snackBar(message: paid ? U.s.paymentWasSuccessful : U.s.paymentFailed);
    UNavigator.back<UIpgAdditionalData>(UIpgAdditionalData(trackingNumber: txn.trackingNumber, paid: paid, keyValues: txn.jsonData.keyValues));
  }

  void cancel() {
    if (finished) return;
    finished = true;
    UNavigator.back<UIpgAdditionalData>();
  }

  void dispose() {
    _lifecycle.dispose();
    _poll.cancel();
  }
}
