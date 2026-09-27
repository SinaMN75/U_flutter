part of "../../u_admin.dart";

class UAdminTransactionsController extends UBaseController {
  List<UTxnResponse> list = <UTxnResponse>[];

  TagTxn? statusFilter;

  UTxnResponse? editing;
  late final TextEditingController amount = fields.text();
  late final TextEditingController tracking = fields.text();
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
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    clearDates();
    statusFilter = null;
    reloadFirstPage(read);
  }

  void loadForm(UTxnResponse? t) {
    editing = t;
    amount.text = t?.amount.toInt().toString() ?? "";
    tracking.text = t?.trackingNumber ?? "";
    tag = TagTxn.values.fromNumber(t?.tags.firstOrNull ?? TagTxn.pending.number) ?? TagTxn.pending;
  }

  Future<bool> save() async {
    final UTxnResponse? t = editing;
    final dynamic ok = await submit(
      t == null
          ? UServices.txn.create(p: UTxnCreateParams(amount: numOf(amount) ?? 0, trackingNumber: tracking.text.trim(), tags: <int>[tag.number]))
          : UServices.txn.update(p: UTxnUpdateParams(id: t.id, amount: numOf(amount), trackingNumber: tracking.text.nullIfEmpty(), tags: <int>[tag.number])),
      read,
    );
    return ok != null;
  }

  void delete(UTxnResponse i) => confirmAction(
    () => UServices.txn.delete(p: UIdParams(id: i.id)),
    read,
    title: U.s.deleteItem(U.s.transactions),
    message: U.s.areYouSureYouWantToDeleteThisItem(U.s.transactions),
  );
}
