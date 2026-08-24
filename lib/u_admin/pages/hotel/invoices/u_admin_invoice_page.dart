import "package:u/utilities.dart";

class UAdminInvoicePage extends StatefulWidget {
  const UAdminInvoicePage({this.contract, super.key});

  final UDormBedContractResponse? contract;

  @override
  State<UAdminInvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<UAdminInvoicePage> {
  final UAdminInvoiceController c = UAdminInvoiceController();

  static const List<TagDormBedInvoice> _types = <TagDormBedInvoice>[TagDormBedInvoice.deposit, TagDormBedInvoice.rent];

  String _typeLabel(UDormBedInvoiceResponse i) {
    for (final TagDormBedInvoice t in _types) {
      if (i.tags.contains(t.number)) return t.localizedTitle;
    }
    return "-";
  }

  @override
  void initState() {
    c.init(contract: widget.contract);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.contract == null ? U.s.invoices : "${U.s.invoices} · ${widget.contract?.user?.displayName ?? ""}",
    onFilter: _showFilterDialog,
    onCreate: widget.contract != null && U.user.hasPermission(TagUser.permissionManageInvoices) ? _showEditDialog : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UColumn(
      spacing: 0,
      children: <Widget>[
        if (widget.contract != null) Obx(() => c.state.isLoaded() ? _summary() : const SizedBox.shrink()),
        _statusFilter(),
        _list().expanded(),
      ],
    ),
  );

  Widget _summary() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: URow(
      spacing: 0,
      children: <Widget>[
        _summaryCard(U.s.totalDebt, c.totalDebt, UAdminTheme.blueGrey),
        _summaryCard(U.s.totalPaid, c.totalPaid, UAdminTheme.green),
        _summaryCard(U.s.totalRemaining, c.totalRemaining, UAdminTheme.orange),
        _summaryCard(U.s.totalPenalty, c.totalPenalty, UAdminTheme.red),
      ],
    ),
  );

  Widget _summaryCard(String label, double value, Color color) => UContainer(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    radius: 12,
    color: color.withValues(alpha: 0.11),
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UTextBodySmall(label, color: color),
        const SizedBox(height: 4),
        UTextBodyMedium(value.rial(), color: color),
      ],
    ),
  );

  Widget _statusFilter() => Obx(() {
    c.pageNumber.value;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: URow(
        spacing: 0,
        children: <Widget>[
          _chip(U.s.all, UAdminInvoiceStatusFilter.all),
          _chip(U.s.paid, UAdminInvoiceStatusFilter.paid),
          _chip(U.s.unpaid, UAdminInvoiceStatusFilter.unpaid),
          _chip(U.s.overdue, UAdminInvoiceStatusFilter.overdue),
        ],
      ),
    );
  });

  Widget _chip(String label, UAdminInvoiceStatusFilter value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ChoiceChip(label: Text(label), selected: c.statusFilter == value, onSelected: (_) => c.setStatus(value)),
  );

  Widget _list() => UAdminListView<UDormBedInvoiceResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.invoices),
    desktopBreakpoint: 900,
    desktopHeader: () => UAdminTable.header(<String>[U.s.tenant, U.s.invoiceType, U.s.dueDate, U.s.debtAmount, U.s.paidAmount, U.s.penalty, U.s.paymentStatus, U.s.operations]),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _statusChip(UDormBedInvoiceResponse i) {
    final Color color = i.isPaid
        ? UAdminTheme.green
        : i.isOverdue
        ? UAdminTheme.red
        : UAdminTheme.orange;
    final String label = i.isPaid
        ? U.s.paid
        : i.isOverdue
        ? U.s.overdue
        : U.s.unpaid;
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      radius: 20,
      color: color.withValues(alpha: 0.15),
      child: UTextBodySmall(label, color: color),
    );
  }

  String _tenantLabel(UDormBedInvoiceResponse i) => i.contract?.user?.displayName ?? widget.contract?.user?.displayName ?? "-";

  Widget _itemDesktop(UDormBedInvoiceResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(_tenantLabel(i)),
      UAdminTable.cell(_typeLabel(i)),
      UAdminTable.cell(i.dueDate.toJalaliDate()),
      UAdminTable.cell(i.debtAmount.rial()),
      UAdminTable.cell(i.paidAmount.rial()),
      UAdminTable.cell(i.penaltyAmount.rial()),
      Center(child: _statusChip(i)).expanded(),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UDormBedInvoiceResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.receipt_long_rounded,
    title: _tenantLabel(i),
    subtitle: _typeLabel(i),
    badge: _statusChip(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.invoiceType, _typeLabel(i)),
      UAdminField(U.s.dueDate, i.dueDate.toJalaliDate()),
      UAdminField(U.s.debtAmount, i.debtAmount.rial()),
      UAdminField(U.s.paidAmount, i.paidAmount.rial()),
      UAdminField(U.s.penalty, i.penaltyAmount.rial()),
    ],
  );

  Widget _menu(UDormBedInvoiceResponse i) => UAdminOps.menu<UDormBedInvoiceResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UDormBedInvoiceResponse>(
      onEdit: (UDormBedInvoiceResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
      extras: <String, void Function(UDormBedInvoiceResponse)>{
        "pay": c.pay,
        "payLink": (UDormBedInvoiceResponse x) => UAdminPayLink.dormBedInvoice(x, onClosed: c.read),
        "copyLink": UAdminPayLink.copyDormBedInvoiceLink,
      },
    ),
    fallback: (UAdminActionContext<UDormBedInvoiceResponse> ctx) => <UAdminAction>[
      ctx.extra("payLink", label: "${U.s.payment} ${U.s.link}", icon: Icons.link_rounded, visible: !ctx.item.isPaid, roles: <TagUser>[TagUser.permissionPayInvoices]),
      ctx.extra("copyLink", label: "${U.s.copy} ${U.s.link}", icon: Icons.copy_rounded, visible: !ctx.item.isPaid, roles: <TagUser>[TagUser.permissionPayInvoices]),
      ctx.extra("pay", label: U.s.markAsPaid, icon: Icons.payments_rounded, visible: !ctx.item.isPaid, color: UAdminTheme.green.shade700, roles: <TagUser>[TagUser.permissionPayInvoices]),
      ctx.edit(roles: <TagUser>[TagUser.permissionManageInvoices]),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteInvoices]),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filter),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
        child: UColumn(
          spacing: 0,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextFieldDatePicker(
              jalali: true,
              controller: c.minDueDateController,
              labelText: U.s.dueDate,
              onChange: (DateTime d, Jalali j) {
                c.minDueDate = d;
                c.minDueDateController.text = d.toJalaliDate();
              },
            ).pSymmetric(vertical: 6),
            UTextFieldDatePicker(
              jalali: true,
              controller: c.maxDueDateController,
              labelText: U.s.dueDate,
              onChange: (DateTime d, Jalali j) {
                c.maxDueDate = d;
                c.maxDueDateController.text = d.toJalaliDate();
              },
            ).pSymmetric(vertical: 6),
            UTextField(
              controller: c.minDebtController,
              labelText: U.s.minPrice,
              keyboardType: TextInputType.number,
              formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            ).pSymmetric(vertical: 6),
            UTextField(
              controller: c.maxDebtController,
              labelText: U.s.maxPrice,
              keyboardType: TextInputType.number,
              formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            ).pSymmetric(vertical: 6),
            const SizedBox(height: 20),
            UButtonSubmitCancel(
              submitTitle: U.s.filter,
              cancelTitle: U.s.clearFilters,
              onSubmit: () {
                c.applyExtraFilters();
                UNavigator.back();
              },
              onCancel: () {
                c.clearExtraFilters();
                UNavigator.back();
              },
            ),
          ],
        ),
      )),
    ),
  );

  void _showEditDialog({UDormBedInvoiceResponse? p}) {
    final bool isEdit = p != null;
    final TextEditingController debt = TextEditingController(text: p?.debtAmount.toInt().toString());
    final TextEditingController creditor = TextEditingController(text: p?.creditorAmount.toInt().toString());
    final TextEditingController paid = TextEditingController(text: p?.paidAmount.toInt().toString());
    final TextEditingController penalty = TextEditingController(text: p?.penaltyAmount.toInt().toString());
    final TextEditingController dueCtrl = TextEditingController(text: p?.dueDate.toJalaliDate());
    final TextEditingController description = TextEditingController(text: p?.jsonData.detail1);

    final Rxn<UDormBedContractResponse> contract = Rxn<UDormBedContractResponse>();
    DateTime? dueDate = p?.dueDate;
    TagDormBedInvoice type = _types.firstWhere((TagDormBedInvoice t) => p?.tags.contains(t.number) ?? false, orElse: () => TagDormBedInvoice.rent);

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    UNavigator.dialog(
      AlertDialog(
        title: Text(p == null ? U.s.createItem(U.s.invoice) : U.s.editItem(U.s.invoice)),
        content: SizedBox(
          width: context.dialogWidth(max: 480),
          child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setLocal) => Form(
              key: formKey,
              child: UColumn(
                spacing: 0,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (!isEdit && widget.contract == null)
                    UTextFieldAutoCompleteAsync<UDormBedContractResponse>(
                      labelBuilder: (UDormBedContractResponse i) => "${i.user?.displayName ?? "-"} · ${i.bed?.title ?? ""} · ${i.startDate.toJalaliDate()}",
                      onChanged: contract.call,
                      selectedItem: contract.value,
                      fetchData: c.readContracts,
                      hintText: U.s.contract,
                    ).pSymmetric(vertical: 6),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: type.number,
                    decoration: InputDecoration(labelText: U.s.invoiceType, border: const OutlineInputBorder()),
                    items: _types.map((TagDormBedInvoice t) => DropdownMenuItem<int>(value: t.number, child: Text(t.localizedTitle))).toList(),
                    onChanged: (int? v) => setLocal(() => type = _types.firstWhere((TagDormBedInvoice t) => t.number == v)),
                  ).pSymmetric(vertical: 6),
                  UTextField(
                    controller: debt,
                    labelText: U.s.debtAmount,
                    keyboardType: TextInputType.number,
                    validator: UValidators.required(message: ""),
                    formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                  ).pSymmetric(vertical: 6),
                  UTextField(controller: creditor, labelText: U.s.creditor, keyboardType: TextInputType.number, formatters: <TextInputFormatter>[UCurrencyInputFormatter()]).pSymmetric(vertical: 6),
                  UTextField(controller: paid, labelText: U.s.paidAmount, keyboardType: TextInputType.number, formatters: <TextInputFormatter>[UCurrencyInputFormatter()]).pSymmetric(vertical: 6),
                  UTextField(
                    controller: penalty,
                    labelText: U.s.penaltyAmount,
                    keyboardType: TextInputType.number,
                    formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                  ).pSymmetric(vertical: 6),
                  UTextFieldDatePicker(
                    controller: dueCtrl,
                    labelText: U.s.dueDate,
                    jalali: true,
                    initialDate: dueDate,
                    validator: UValidators.required(message: ""),
                    onChange: (DateTime d, Jalali j) {
                      dueDate = d;
                      dueCtrl.text = d.toJalaliDate();
                    },
                  ).pSymmetric(vertical: 6),
                  UTextField(controller: description, labelText: U.s.description, lines: 2).pSymmetric(vertical: 6),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        if (dueDate == null) {
                          UToast.error(message: U.s.errorSubmittingForm);
                          return;
                        }
                        if (isEdit) {
                          c.update(
                            p: UDormBedInvoiceUpdateParams(
                              id: p.id,
                              tags: <int>[type.number],
                              debtAmount: debt.text.isEmpty ? null : debt.numDouble(),
                              creditorAmount: creditor.text.isEmpty ? null : creditor.numDouble(),
                              paidAmount: paid.text.isEmpty ? null : paid.numDouble(),
                              penaltyAmount: penalty.text.isEmpty ? null : penalty.numDouble(),
                              dueDate: dueDate,
                              detail1: description.text.nullIfEmpty(),
                            ),
                          );
                        } else {
                          final String? cid = contract.value?.id ?? widget.contract?.id;
                          if (cid == null) {
                            UToast.error(message: U.s.errorSubmittingForm);
                            return;
                          }
                          c.create(
                            p: UDormBedInvoiceCreateParams(
                              tags: <int>[TagDormBedInvoice.notPaid.number, type.number],
                              debtAmount: debt.text.isEmpty ? 0 : debt.numDouble(),
                              creditorAmount: creditor.text.isEmpty ? 0 : creditor.numDouble(),
                              paidAmount: paid.text.isEmpty ? 0 : paid.numDouble(),
                              penaltyAmount: penalty.text.isEmpty ? 0 : penalty.numDouble(),
                              contractId: cid,
                              dueDate: dueDate!,
                              detail1: description.text.trim(),
                            ),
                          );
                        }
                        UNavigator.back();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ),
    );
  }
}
