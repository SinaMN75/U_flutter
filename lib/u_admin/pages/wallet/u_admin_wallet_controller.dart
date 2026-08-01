part of "../../u_admin.dart";

class UAdminWalletController extends UBaseController {
  final Rxn<UUserResponse> selectedUser = Rxn<UUserResponse>();

  final RxList<UWalletResponse> wallets = <UWalletResponse>[].obs;
  final RxList<UWalletTxnResponse> txns = <UWalletTxnResponse>[].obs;

  final Rxn<UAccountingReportResponse> summary = Rxn<UAccountingReportResponse>();

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

  void charge(double amount) {
    final UUserResponse? u = selectedUser.value;
    if (u == null) return;
    ULoading.show();
    UServices.wallet.charge(
      p: UWalletChargeParams(userId: u.id, amount: amount),
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        errorCallBack(e.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void transfer({required String receiverId, required double amount, String? detail}) {
    ULoading.show();
    UServices.wallet.transfer(
      p: UWalletTransferParams(senderId: selectedUser.value?.id, receiverId: receiverId, amount: amount, detail1: detail, tagWalletTxn: <int>[TagWalletTxn.transfer.number]),
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        errorCallBack(e.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }
}

class UAdminTransactionsController extends UBaseController {
  List<UTxnResponse> list = <UTxnResponse>[];

  final TextEditingController trackingFilter = TextEditingController();
  final TextEditingController fromCreatedController = TextEditingController();
  final TextEditingController toCreatedController = TextEditingController();
  TagTxn? statusFilter;

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.txn.read(
      p: UTxnReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
        tags: statusFilter == null ? null : <int>[statusFilter!.number],
        selectorArgs: const TxnSelectorArgs(user: UserSelectorArgs()),
      ),
      onOk: (UResponse<List<UTxnResponse>> r) {
        list = r.result ?? <UTxnResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    trackingFilter.clear();
    fromCreatedController.clear();
    toCreatedController.clear();
    fromCreatedAt = null;
    toCreatedAt = null;
    statusFilter = null;
    reloadFirstPage(read);
  }

  void create({required double amount, required String trackingNumber, required int tag}) {
    ULoading.show();
    UServices.txn.create(
      p: UTxnCreateParams(amount: amount, trackingNumber: trackingNumber, tags: <int>[tag]),
      onOk: (UResponse<String> r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        errorCallBack(e.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void update({required String id, double? amount, String? trackingNumber, List<int>? tags}) {
    ULoading.show();
    UServices.txn.update(
      p: UTxnUpdateParams(id: id, amount: amount, trackingNumber: trackingNumber, tags: tags),
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        errorCallBack(e.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void delete(UTxnResponse i) => UNavigator.confirm(
    title: U.s.deleteTransaction,
    message: U.s.areYouSureToDeleteThisTransaction,
    onConfirm: () => UServices.txn.delete(
      p: UIdParams(id: i.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );
}

class UAdminAccountingController {
  final Rx<PageState> state = PageState.initial.obs;
  final Rxn<UAccountingReportResponse> report = Rxn<UAccountingReportResponse>();

  final Rxn<UUserResponse> user = Rxn<UUserResponse>();

  DateTime? fromDate;
  DateTime? toDate;
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  Future<void> init() => load();

  Future<void> load() async {
    state.loading();
    await UServices.accounting.report(
      p: UAccountingReportParams(userId: user.value?.id, fromDate: fromDate, toDate: toDate),
      onOk: (UResponse<UAccountingReportResponse> r) {
        report.value = r.result;
        state.loaded();
      },
      onError: (UEmptyResponse e) {
        state.error();
        UToast.error(message: e.message);
      },
      onException: (String e) {
        state.error();
        UToast.error(message: e);
      },
    );
  }

  void clear() {
    user.value = null;
    fromDate = null;
    toDate = null;
    fromController.clear();
    toController.clear();
    load();
  }
}
