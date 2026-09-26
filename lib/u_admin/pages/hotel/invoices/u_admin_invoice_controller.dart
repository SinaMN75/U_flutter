part of "../../../u_admin.dart";

enum UAdminInvoiceStatusFilter { all, paid, unpaid, overdue }

class UAdminInvoiceController extends UBaseController {
  List<UDormBedInvoiceResponse> list = <UDormBedInvoiceResponse>[];
  UDormBedContractResponse? contract;
  static const List<TagDormBedInvoice> types = <TagDormBedInvoice>[TagDormBedInvoice.deposit, TagDormBedInvoice.rent];

  UAdminInvoiceStatusFilter statusFilter = UAdminInvoiceStatusFilter.all;
  final TextEditingController minDueText = TextEditingController();
  final TextEditingController maxDueText = TextEditingController();
  final TextEditingController minDebtFilter = TextEditingController();
  final TextEditingController maxDebtFilter = TextEditingController();
  DateTime? minDueDate;
  DateTime? maxDueDate;

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
  late final TextEditingController dueText = fields.text();
  late final TextEditingController debt = fields.text();
  late final TextEditingController creditor = fields.text();
  late final TextEditingController paid = fields.text();
  late final TextEditingController penalty = fields.text();
  late final TextEditingController description = fields.text();

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
          UAdminInvoiceStatusFilter.all => null,
          UAdminInvoiceStatusFilter.paid => true,
          _ => false,
        },
        isOverdue: statusFilter == UAdminInvoiceStatusFilter.overdue ? true : null,
        minDueDate: minDueDate,
        maxDueDate: maxDueDate,
        minDebtAmount: numOf(minDebtFilter),
        maxDebtAmount: numOf(maxDebtFilter),
        selectorArgs: const UDormBedInvoiceSelectorArgs(contract: UDormBedContractSelectorArgs(user: UUserSelectorArgs())),
      ),
      onOk: (UResponse<List<UDormBedInvoiceResponse>> r) {
        list = r.result ?? <UDormBedInvoiceResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
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

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    minDueText.clear();
    maxDueText.clear();
    minDebtFilter.clear();
    maxDebtFilter.clear();
    minDueDate = null;
    maxDueDate = null;
    reloadFirstPage(read);
  }

  void setStatus(UAdminInvoiceStatusFilter f) {
    statusFilter = f;
    reloadFirstPage(read);
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
    dueText.text = i?.dueDate.toJalaliDate() ?? "";
    debt.text = i?.debtAmount.toInt().toString() ?? "";
    creditor.text = i?.creditorAmount.toInt().toString() ?? "";
    paid.text = i?.paidAmount.toInt().toString() ?? "";
    penalty.text = i?.penaltyAmount.toInt().toString() ?? "";
    description.text = i?.jsonData.detail1 ?? "";
  }

  /// Creates or updates the invoice. Returns true when the dialog can close.
  Future<bool> save() async {
    if (editing != null) {
      return await submit(
            UServices.hotel.updateDormBedInvoice(
              p: UDormBedInvoiceUpdateParams(
                id: editing!.id,
                tags: <int>[type.number],
                debtAmount: numOf(debt),
                creditorAmount: numOf(creditor),
                paidAmount: numOf(paid),
                penaltyAmount: numOf(penalty),
                dueDate: dueDate,
                detail1: description.text.nullIfEmpty(),
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
    return await submit(
          UServices.hotel.createDormBedInvoice(
            p: UDormBedInvoiceCreateParams(
              tags: <int>[TagDormBedInvoice.notPaid.number, type.number],
              debtAmount: numOf(debt) ?? 0,
              creditorAmount: numOf(creditor) ?? 0,
              paidAmount: numOf(paid) ?? 0,
              penaltyAmount: numOf(penalty) ?? 0,
              contractId: formContract!.id,
              dueDate: dueDate!,
              detail1: description.text.trim(),
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
    minDueText.dispose();
    maxDueText.dispose();
    minDebtFilter.dispose();
    maxDebtFilter.dispose();
    super.dispose();
  }
}
