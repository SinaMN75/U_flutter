part of "../../u_admin.dart";

class UAdminWalletTransactionController extends UBaseController {
  List<UTxnResponse> list = <UTxnResponse>[];

  TagTxn? statusFilter;

  UTxnResponse? editing;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController trackingController = TextEditingController();
  TagTxn tag = TagTxn.pending;

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.txn.read(
      p: UTxnReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        fromCreatedAt: startDate,
        toCreatedAt: endDate,
        tags: statusFilter == null ? null : <int>[statusFilter!.number],
        selectorArgs: const UTxnSelectorArgs(user: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UTxnResponse>> r) {
        list = r.result ?? <UTxnResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    clearDates();
    statusFilter = null;
    pageNumber(1);
    read();
  }

  void loadForm(UTxnResponse? t) {
    editing = t;
    amountController.text = t?.amount.toInt().toString() ?? "";
    trackingController.text = t?.trackingNumber ?? "";
    tag = TagTxn.values.fromNumber(t?.tags.firstOrNull ?? TagTxn.pending.number) ?? TagTxn.pending;
  }

  Future<bool> save() async {
    final UTxnResponse? t = editing;
    return await submit(
      t == null
          ? UServices.txn.create(p: UTxnCreateParams(amount: numOf(amountController) ?? 0, trackingNumber: trackingController.text.trim(), tags: <int>[tag.number]))
          : UServices.txn.update(p: UTxnUpdateParams(id: t.id, amount: numOf(amountController), trackingNumber: trackingController.text.nullIfEmpty(), tags: <int>[tag.number])),
      read,
    ) !=
        null;
  }

  void delete(UTxnResponse i) => confirmAction(
    () => UServices.txn.delete(p: UIdParams(id: i.id)),
    read,
    title: U.s.deleteItem(U.s.transactions),
    message: U.s.areYouSureYouWantToDeleteThisItem(U.s.transactions),
  );

  @override
  void dispose() {
    amountController.dispose();
    trackingController.dispose();
    super.dispose();
  }
}
