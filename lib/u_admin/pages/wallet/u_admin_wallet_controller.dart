part of "../../u_admin.dart";

class UAdminWalletController extends UBaseController {
  final URxn<UUserResponse> selectedUser = URxn<UUserResponse>();

  final URxList<UWalletResponse> wallets = <UWalletResponse>[].obs;
  final URxList<UWalletTxnResponse> txns = <UWalletTxnResponse>[].obs;

  final URxn<UAccountingReportResponse> summary = URxn<UAccountingReportResponse>();

  final TextEditingController chargeAmountController = TextEditingController();
  final TextEditingController transferAmountController = TextEditingController();
  final TextEditingController transferDetailController = TextEditingController();
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
      onOk: (UResponse<List<UWalletResponse>> r) async {
        wallets.value = r.result ?? <UWalletResponse>[];
        state.loaded();
        final (UResponse<List<UWalletTxnResponse>>? t, UEmptyResponse? e, String? x) = await UServices.wallet.readTxn(p: UWalletTxnReadParams(userId: u.id, pageSize: 50, pageNumber: 1));
        if (t == null) UToast.error(message: e?.message ?? x ?? U.s.errorReadingData);
        txns.value = t?.result ?? <UWalletTxnResponse>[];
        summary.value = (await UServices.accounting.report(p: UAccountingReportParams(userId: u.id))).$1?.result;
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  Future<bool> charge() async {
    final UUserResponse? u = selectedUser.value;
    if (u == null) return false;
    return await submit(UServices.wallet.charge(p: UWalletChargeParams(userId: u.id, amount: numOf(chargeAmountController) ?? 0)), read) != null;
  }

  Future<bool> transfer() async {
    final UUserResponse? r = receiver;
    if (r == null) {
      UToast.error(message: U.s.selectAItem(U.s.receiver));
      return false;
    }
    return await submit(
      UServices.wallet.transfer(
        p: UWalletTransferParams(
          senderId: selectedUser.value?.id,
          receiverId: r.id,
          amount: numOf(transferAmountController) ?? 0,
          detail1: transferDetailController.text.nullIfEmpty(),
          tagWalletTxn: <int>[TagWalletTxn.transfer.number],
        ),
      ),
      read,
    ) !=
        null;
  }

  @override
  void dispose() {
    chargeAmountController.dispose();
    transferAmountController.dispose();
    transferDetailController.dispose();
    super.dispose();
  }
}
