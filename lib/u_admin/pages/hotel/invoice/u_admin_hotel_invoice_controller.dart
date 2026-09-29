part of "../../../u_admin.dart";

enum UAdminHotelInvoiceStatusFilter { all, paid, unpaid, overdue }

class UAdminHotelInvoiceController extends UBaseController {
  List<UDormBedInvoiceResponse> list = <UDormBedInvoiceResponse>[];
  UDormBedContractResponse? contract;
  static const List<TagDormBedInvoice> types = <TagDormBedInvoice>[TagDormBedInvoice.deposit, TagDormBedInvoice.rent];

  UAdminHotelInvoiceStatusFilter statusFilter = UAdminHotelInvoiceStatusFilter.all;
  final TextEditingController minDebtFilterController = TextEditingController();
  final TextEditingController maxDebtFilterController = TextEditingController();

  /// Totals of the whole contract, shown when the page is opened for one contract.
  double totalDebt = 0;
  double totalPaid = 0;
  double totalPenalty = 0;
  double totalRemaining = 0;

  // ---------------------------------------------------------------- form (create and edit)

  UDormBedInvoiceResponse? editing;
  UDormBedContractResponse? formContract;
  TagDormBedInvoice type = TagDormBedInvoice.rent;
  DateTime? dueDate;
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController debtController = TextEditingController();
  final TextEditingController creditorController = TextEditingController();
  final TextEditingController paidController = TextEditingController();
  final TextEditingController penaltyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  void init({UDormBedContractResponse? contract}) {
    this.contract = contract;
    read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDormBedInvoice(
      p: UDormBedInvoiceReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        contractId: contract?.id,
        isPaid: switch (statusFilter) {
          UAdminHotelInvoiceStatusFilter.all => null,
          UAdminHotelInvoiceStatusFilter.paid => true,
          _ => false,
        },
        isOverdue: statusFilter == UAdminHotelInvoiceStatusFilter.overdue ? true : null,
        minDueDate: startDate,
        maxDueDate: endDate,
        minDebtAmount: numOf(minDebtFilterController),
        maxDebtAmount: numOf(maxDebtFilterController),
        selectorArgs: const UDormBedInvoiceSelectorArgs(contract: UDormBedContractSelectorArgs(user: UUserSelectorArgs())),
      ),
      onOk: (UResponse<List<UDormBedInvoiceResponse>> r) {
        list = r.result ?? <UDormBedInvoiceResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UResponse<dynamic> e) => setError(e.message),
      onException: (String e) => setError(),
    );
    if (contract == null) return;
    final List<UDormBedInvoiceResponse> all =
        (await UServices.hotel.readDormBedInvoice(p: UDormBedInvoiceReadParams(contractId: contract!.id, pageNumber: 1, pageSize: 1000))).$1?.result ?? <UDormBedInvoiceResponse>[];
    totalDebt = all.fold(0, (double s, UDormBedInvoiceResponse i) => s + i.debtAmount);
    totalPaid = all.fold(0, (double s, UDormBedInvoiceResponse i) => s + i.paidAmount);
    totalPenalty = all.fold(0, (double s, UDormBedInvoiceResponse i) => s + i.penaltyAmount);
    totalRemaining = all.fold(0, (double s, UDormBedInvoiceResponse i) => s + max(i.netDue, 0));
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    clearDates();
    minDebtFilterController.clear();
    maxDebtFilterController.clear();
    pageNumber(1);
    read();
  }

  void setStatus(UAdminHotelInvoiceStatusFilter f) {
    statusFilter = f;
    pageNumber(1);
    read();
  }

  TagDormBedInvoice? typeOf(UDormBedInvoiceResponse i) => types.where((TagDormBedInvoice t) => i.tags.contains(t.number)).firstOrNull;

  Future<List<UDormBedContractResponse>> searchContracts(String query) async =>
      (await UServices.hotel.readDormBedContract(
        p: UDormBedContractReadParams(
          userName: query,
          pageSize: 100,
          pageNumber: 1,
          selectorArgs: const UDormBedContractSelectorArgs(user: UUserSelectorArgs(), bed: UDormBedSelectorArgs()),
        ),
      )).$1?.result ??
      <UDormBedContractResponse>[];

  void loadForm(UDormBedInvoiceResponse? i) {
    editing = i;
    formContract = contract;
    type = (i == null ? null : typeOf(i)) ?? TagDormBedInvoice.rent;
    dueDate = i?.dueDate;
    dueDateController.text = i?.dueDate.toJalaliDate() ?? "";
    debtController.text = i?.debtAmount.toInt().toString() ?? "";
    creditorController.text = i?.creditorAmount.toInt().toString() ?? "";
    paidController.text = i?.paidAmount.toInt().toString() ?? "";
    penaltyController.text = i?.penaltyAmount.toInt().toString() ?? "";
    descriptionController.text = i?.jsonData.detail1 ?? "";
  }

  /// Creates or updates the invoice. Returns true when the dialog can close.
  Future<bool> save() async {
    if (editing != null) {
      return await send(
            UServices.hotel.updateDormBedInvoice(
              p: UDormBedInvoiceUpdateParams(
                id: editing!.id,
                tags: <int>[type.number],
                debtAmount: numOf(debtController),
                creditorAmount: numOf(creditorController),
                paidAmount: numOf(paidController),
                penaltyAmount: numOf(penaltyController),
                dueDate: dueDate,
                detail1: descriptionController.text.nullIfEmpty(),
              ),
            ),
            read,
          ) !=
          null;
    }
    if (formContract == null) {
      UToast.error(message: U.s.selectAItem(U.s.contract));
      return false;
    }
    return await send(
          UServices.hotel.createDormBedInvoice(
            p: UDormBedInvoiceCreateParams(
              tags: <int>[TagDormBedInvoice.notPaid.number, type.number],
              debtAmount: numOf(debtController) ?? 0,
              creditorAmount: numOf(creditorController) ?? 0,
              paidAmount: numOf(paidController) ?? 0,
              penaltyAmount: numOf(penaltyController) ?? 0,
              contractId: formContract!.id,
              dueDate: dueDate!,
              detail1: descriptionController.text.trim(),
            ),
          ),
          read,
        ) !=
        null;
  }

  /// Marks the invoice fully paid, without an online payment.
  void markPaid(UDormBedInvoiceResponse i) => confirmAction(
    () => UServices.hotel.payDormBedInvoice(p: UIdParams(id: i.id)),
    read,
    title: U.s.payInvoice,
    message: U.s.markThisInvoiceAsFullyPaid,
  );

  /// Pays the invoice online through the payment gateway.
  Future<void> pay(UDormBedInvoiceResponse i) async {
    if (await UIpgFlow.pay(
      p: UIpgPayParams(amount: i.netDue, tag: TagTxn.dormInvoice, invoiceId: i.id),
    ))
      await read();
  }

  /// Copies a payment-gateway link the tenant can pay with.
  Future<void> copyPayLink(UDormBedInvoiceResponse i) async {
    final String? url = await UIpgFlow.link(amount: i.netDue, tag: TagTxn.dormInvoice, invoiceId: i.id);
    if (url.isNotNullOrEmpty()) await UClipboard.set(url!, snackBar: true);
  }

  void delete(UDormBedInvoiceResponse i) => confirmAction(() => UServices.hotel.deleteDormBedInvoice(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    minDebtFilterController.dispose();
    maxDebtFilterController.dispose();
    dueDateController.dispose();
    debtController.dispose();
    creditorController.dispose();
    paidController.dispose();
    penaltyController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
