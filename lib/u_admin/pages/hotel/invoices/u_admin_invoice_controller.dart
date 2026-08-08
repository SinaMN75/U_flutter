part of "../../../u_admin.dart";

enum UAdminInvoiceStatusFilter { all, paid, unpaid, overdue }

class UAdminInvoiceController extends UBaseController {
  List<UDormBedInvoiceResponse> list = <UDormBedInvoiceResponse>[];
  UAdminInvoiceStatusFilter statusFilter = UAdminInvoiceStatusFilter.all;
  double totalDebt = 0;
  double totalPaid = 0;
  double totalPenalty = 0;
  double totalRemaining = 0;
  UDormBedContractResponse? contract;

  Future<void> init({UDormBedContractResponse? contract}) async {
    this.contract = contract;
    await read();
  }

  final TextEditingController minDueDateController = TextEditingController();
  final TextEditingController maxDueDateController = TextEditingController();
  DateTime? minDueDate;
  DateTime? maxDueDate;
  final TextEditingController minDebtController = TextEditingController();
  final TextEditingController maxDebtController = TextEditingController();

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDormBedInvoice(
      p: UDormBedInvoiceReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        contractId: contract?.id,
        isPaid: statusFilter == UAdminInvoiceStatusFilter.paid ? true : (statusFilter == UAdminInvoiceStatusFilter.all ? null : false),
        isOverdue: statusFilter == UAdminInvoiceStatusFilter.overdue ? true : null,
        minDueDate: minDueDate,
        maxDueDate: maxDueDate,
        minDebtAmount: minDebtController.isNullOrEmpty() ? null : minDebtController.numDouble(),
        maxDebtAmount: maxDebtController.isNullOrEmpty() ? null : maxDebtController.numDouble(),
        selectorArgs: const InvoiceSelectorArgs(contract: ContractSelectorArgs(user: UserSelectorArgs())),
      ),
      onOk: (UResponse<List<UDormBedInvoiceResponse>> r) {
        list = r.result ?? <UDormBedInvoiceResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UResponse<dynamic> e) => setError(e.message),
      onException: (String e) => setError(),
    );
    if (contract != null) await _refreshSummary();
  }

  Future<void> _refreshSummary() async {
    await UServices.hotel.readDormBedInvoice(
      p: UDormBedInvoiceReadParams(contractId: contract?.id, pageNumber: 1, pageSize: 1000),
      onOk: (UResponse<List<UDormBedInvoiceResponse>> r) {
        final List<UDormBedInvoiceResponse> all = r.result ?? <UDormBedInvoiceResponse>[];
        totalDebt = all.fold(0, (double s, UDormBedInvoiceResponse i) => s + i.debtAmount);
        totalPaid = all.fold(0, (double s, UDormBedInvoiceResponse i) => s + i.paidAmount);
        totalPenalty = all.fold(0, (double s, UDormBedInvoiceResponse i) => s + i.penaltyAmount);
        totalRemaining = all.fold(0, (double s, UDormBedInvoiceResponse i) => s + (i.netDue > 0 ? i.netDue : 0));
      },
      onError: (_) {},
      onException: (_) {},
    );
  }

  void applyExtraFilters() => reloadFirstPage(read);

  void clearExtraFilters() {
    minDueDateController.clear();
    maxDueDateController.clear();
    minDueDate = null;
    maxDueDate = null;
    minDebtController.clear();
    maxDebtController.clear();
    reloadFirstPage(read);
  }

  void setStatus(UAdminInvoiceStatusFilter f) {
    statusFilter = f;
    reloadFirstPage(read);
  }

  void create({required UDormBedInvoiceCreateParams p}) => UServices.hotel.createDormBedInvoice(
    p: p,
    onOk: (UResponse<UDormBedInvoiceResponse> r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UDormBedInvoiceUpdateParams p}) => UServices.hotel.updateDormBedInvoice(
    p: p,
    onOk: (UResponse<UDormBedInvoiceResponse> r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void pay(UDormBedInvoiceResponse i) => UNavigator.confirm(
    title: U.s.payInvoice,
    message: U.s.markThisInvoiceAsFullyPaid,
    onConfirm: () => UServices.hotel.payDormBedInvoice(
      p: UIdParams(id: i.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message.nullIfEmpty() ?? U.s.invoiceMarkedAsPaid, read);
      },
      onError: (UResponse<dynamic> r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );

  void delete(UDormBedInvoiceResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.deleteDormBedInvoice(
      p: UIdParams(id: i.id),
      onOk: (UResponse<dynamic> r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UResponse<dynamic> r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );

  Future<List<UDormBedContractResponse>> readContracts(String query) async {
    final List<UDormBedContractResponse> result = <UDormBedContractResponse>[];
    await UServices.hotel.readDormBedContract(
      p: UDormBedContractReadParams(
        userName: query,
        pageSize: 100,
        pageNumber: 1,
        selectorArgs: const ContractSelectorArgs(user: UserSelectorArgs(), bed: DormBedSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormBedContractResponse>> r) => result.addAll(r.result ?? <UDormBedContractResponse>[]),
      onError: (UResponse<dynamic> e) {},
      onException: (String e) {},
    );
    return result;
  }
}
