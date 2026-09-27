part of "../../u_admin.dart";

class UAdminWalletController extends UBaseController {
  final URxn<UUserResponse> selectedUser = URxn<UUserResponse>();

  final URxList<UWalletResponse> wallets = <UWalletResponse>[].obs;
  final URxList<UWalletTxnResponse> txns = <UWalletTxnResponse>[].obs;

  final URxn<UAccountingReportResponse> summary = URxn<UAccountingReportResponse>();

  late final TextEditingController chargeAmount = fields.text();
  late final TextEditingController transferAmount = fields.text();
  late final TextEditingController transferDetail = fields.text();
  UUserResponse? receiver;

  double get totalBalance => wallets.fold<double>(0, (double sum, UWalletResponse w) => sum + w.balance);

  void selectUser(UUserResponse? u) {
    selectedUser.value = u;
    if (u == null) {
      wallets.clear();
      txns.clear();
      summary.value = null;
      state.loaded();
      return;
    }
    read();
  }

  Future<void> read() async {
    final UUserResponse? u = selectedUser.value;
    if (u == null) return;
    state.loading();
    await UServices.wallet.readByUserId(
      p: UIdParams(id: u.id),
      onOk: (UResponse<List<UWalletResponse>> r) {
        wallets.value = r.result ?? <UWalletResponse>[];
        state.loaded();
        _loadTxns();
        _loadSummary();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  Future<void> _loadTxns() async {
    final UUserResponse? u = selectedUser.value;
    if (u == null) return;
    await UServices.wallet.readTxn(
      p: UWalletTxnReadParams(userId: u.id, pageSize: 50, pageNumber: 1),
      onOk: (UResponse<List<UWalletTxnResponse>> r) => txns.value = r.result ?? <UWalletTxnResponse>[],
      onError: (UEmptyResponse e) => UToast.error(message: e.message),
      onException: (String e) => UToast.error(message: e),
    );
  }

  Future<void> _loadSummary() async {
    final UUserResponse? u = selectedUser.value;
    if (u == null) return;
    await UServices.accounting.report(
      p: UAccountingReportParams(userId: u.id),
      onOk: (UResponse<UAccountingReportResponse> r) => summary.value = r.result,
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
  }

  Future<bool> charge() async {
    final UUserResponse? u = selectedUser.value;
    if (u == null) return false;
    return await submit(UServices.wallet.charge(p: UWalletChargeParams(userId: u.id, amount: numOf(chargeAmount) ?? 0)), read) != null;
  }

  Future<bool> transfer() async {
    final UUserResponse? r = receiver;
    if (r == null) {
      UToast.error(message: U.s.selectAItem(U.s.receiver));
      return false;
    }
    final dynamic ok = await submit(
      UServices.wallet.transfer(
        p: UWalletTransferParams(
          senderId: selectedUser.value?.id,
          receiverId: r.id,
          amount: numOf(transferAmount) ?? 0,
          detail1: transferDetail.text.nullIfEmpty(),
          tagWalletTxn: <int>[TagWalletTxn.transfer.number],
        ),
      ),
      read,
    );
    return ok != null;
  }
}
