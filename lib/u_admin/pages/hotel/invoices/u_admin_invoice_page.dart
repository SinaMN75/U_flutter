import "package:u/utilities.dart";

class UAdminInvoicePage extends StatefulWidget {
  const UAdminInvoicePage({this.contract, super.key});

  static void open({UDormBedContractResponse? contract}) => U.addOrSwitchTab(
    contract == null ? U.s.invoices : "${U.s.invoices} · ${contract.user?.displayName ?? ""}",
    UAdminInvoicePage(contract: contract),
  );

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.invoices,
    icon: Icons.receipt_long_rounded,
    page: () => const UAdminInvoicePage(),
    roles: roles,
  );

  final UDormBedContractResponse? contract;

  @override
  State<UAdminInvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<UAdminInvoicePage> {
  final UAdminInvoiceController c = UAdminInvoiceController();

  @override
  void initState() {
    c.init(contract: widget.contract);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.contract == null ? U.s.invoices : "${U.s.invoices} · ${widget.contract?.user?.displayName ?? ""}",
    onFilter: () => UFilterDialog.show(
      title: U.s.filter,
      onApply: c.applyFilters,
      onClear: c.clearFilters,
      children: (_) => <Widget>[
        UTextFieldDatePicker(
          controller: c.startDateController,
          labelText: U.s.dueDate,
          jalali: true,
          initialDate: c.startDate,
          margin: const EdgeInsets.symmetric(vertical: 6),
          onChange: (DateTime d, UJalali j) {
            c.startDate = d;
            c.startDateController.text = d.toJalaliDate();
          },
        ),
        UTextFieldDatePicker(
          controller: c.endDateController,
          labelText: U.s.dueDate,
          jalali: true,
          initialDate: c.endDate,
          margin: const EdgeInsets.symmetric(vertical: 6),
          onChange: (DateTime d, UJalali j) {
            c.endDate = d;
            c.endDateController.text = d.toJalaliDate();
          },
        ),
        UTextField(
          controller: c.minDebtFilterController,
          labelText: U.s.minPrice,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.maxDebtFilterController,
          labelText: U.s.maxPrice,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
      ],
    ),
    onCreate: widget.contract != null && U.user.hasPermission(TagUser.permissionManageInvoices) ? _form : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UColumn(
      children: <Widget>[
        if (widget.contract != null)
          UObx(
            () => !c.state.isLoaded()
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: URow(
                      spacing: 8,
                      children: <Widget>[
                        _total(U.s.totalDebt, c.totalDebt, UAdminTheme.blueGrey),
                        _total(U.s.totalPaid, c.totalPaid, UAdminTheme.green),
                        _total(U.s.totalRemaining, c.totalRemaining, UAdminTheme.orange),
                        _total(U.s.totalPenalty, c.totalPenalty, UAdminTheme.red),
                      ],
                    ),
                  ),
          ),
        // Rebuilt by the loading state, which every status change goes through.
        UObx(() {
          c.state.value;
          return Wrap(
            spacing: 8,
            children: <(String, UAdminInvoiceStatusFilter)>[
              (U.s.all, UAdminInvoiceStatusFilter.all),
              (U.s.paid, UAdminInvoiceStatusFilter.paid),
              (U.s.unpaid, UAdminInvoiceStatusFilter.unpaid),
              (U.s.overdue, UAdminInvoiceStatusFilter.overdue),
            ].map(((String, UAdminInvoiceStatusFilter) f) => ChoiceChip(label: Text(f.$1), selected: c.statusFilter == f.$2, onSelected: (_) => c.setStatus(f.$2))).toList(),
          ).pSymmetric(horizontal: 12, vertical: 6);
        }),
        UAdminListView<UDormBedInvoiceResponse>(
          state: c.state,
          items: () => c.list,
          totalCount: () => c.totalCount,
          onRetry: c.read,
          emptyText: U.s.noItemsFound(U.s.invoices),
          desktopBreakpoint: 900,
          desktopHeader: () => UAdminTable.header(<String>[U.s.tenant, U.s.invoiceType, U.s.dueDate, U.s.debtAmount, U.s.paidAmount, U.s.penalty, U.s.paymentStatus, U.s.operations]),
          desktopRow: (UDormBedInvoiceResponse i, int index) => URow(
            spacing: 8,
            color: UAdminTable.rowColor(context, index),
            padding: UAdminTable.rowPadding,
            children: <Widget>[
              UAdminTable.cell(_tenant(i)),
              UAdminTable.cell(c.typeOf(i)?.localizedTitle ?? "-"),
              UAdminTable.cell(i.dueDate.toJalaliDate()),
              UAdminTable.cell(i.debtAmount.rial()),
              UAdminTable.cell(i.paidAmount.rial()),
              UAdminTable.cell(i.penaltyAmount.rial()),
              _status(i).alignAtCenter().expanded(),
              _menu(i).expanded(),
            ],
          ),
          mobileRow: (UDormBedInvoiceResponse i, int index) => UAdminTable.mobileCard(
            icon: Icons.receipt_long_rounded,
            title: _tenant(i),
            subtitle: c.typeOf(i)?.localizedTitle ?? "-",
            badge: _status(i),
            trailing: _menu(i),
            fields: <UAdminField>[
              UAdminField(U.s.dueDate, i.dueDate.toJalaliDate()),
              UAdminField(U.s.debtAmount, i.debtAmount.rial()),
              UAdminField(U.s.paidAmount, i.paidAmount.rial()),
              UAdminField(U.s.penalty, i.penaltyAmount.rial()),
            ],
          ),
        ).expanded(),
      ],
    ),
  );

  String _tenant(UDormBedInvoiceResponse i) => i.contract?.user?.displayName ?? widget.contract?.user?.displayName ?? "-";

  Widget _total(String label, double value, Color color) => UContainer(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    radius: 12,
    color: color.withValues(alpha: 0.11),
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        UTextBodySmall(label, color: color),
        UTextBodyMedium(value.rial(), color: color),
      ],
    ),
  );

  Widget _status(UDormBedInvoiceResponse i) => i.isPaid
      ? UAdminTable.statusChip(label: U.s.paid, color: UAdminTheme.green)
      : i.isOverdue
      ? UAdminTable.statusChip(label: U.s.overdue, color: UAdminTheme.red)
      : UAdminTable.statusChip(label: U.s.unpaid, color: UAdminTheme.orange);

  Widget _menu(UDormBedInvoiceResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: "${U.s.payment} ${U.s.link}", icon: Icons.link_rounded, visible: !i.isPaid && UAdmin.canAccess(<TagUser>[TagUser.permissionPayInvoices]), onTap: () => c.pay(i)),
      UPopupMenuItem(label: "${U.s.copy} ${U.s.link}", icon: Icons.copy_rounded, visible: !i.isPaid && UAdmin.canAccess(<TagUser>[TagUser.permissionPayInvoices]), onTap: () => c.copyPayLink(i)),
      UPopupMenuItem(label: U.s.markAsPaid, icon: Icons.payments_rounded, color: UAdminTheme.green.shade700, visible: !i.isPaid && UAdmin.canAccess(<TagUser>[TagUser.permissionPayInvoices]), onTap: () => c.markPaid(i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageInvoices]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteInvoices]), onTap: () => c.delete(i)),
    ],
  );

  /// Create ([p] == null) and edit share this one dialog.
  void _form([UDormBedInvoiceResponse? p]) {
    c.loadForm(p);
    UFormDialog.show(
      title: p == null ? U.s.createItem(U.s.invoice) : U.s.editItem(U.s.invoice),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        if (p == null && widget.contract == null)
          UTextFieldAutoCompleteAsync<UDormBedContractResponse>(
            hintText: U.s.contract,
            labelBuilder: (UDormBedContractResponse i) => "${i.user?.displayName ?? "-"} · ${i.bed?.title ?? ""} · ${i.startDate.toJalaliDate()}",
            selectedItem: c.formContract,
            fetchData: c.searchContracts,
            onChanged: (UDormBedContractResponse? i) => c.formContract = i,
          ).pSymmetric(vertical: 6),
        UDropDownField<TagDormBedInvoice>(
          labelText: U.s.invoiceType,
          initialValue: c.type,
          items: UAdminInvoiceController.types.map((TagDormBedInvoice t) => DropdownMenuItem<TagDormBedInvoice>(value: t, child: Text(t.localizedTitle))).toList(),
          onChanged: (TagDormBedInvoice? v) => c.type = v ?? c.type,
        ).pSymmetric(vertical: 6),
        UTextField(
          controller: c.debtController,
          labelText: U.s.debtAmount,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          validator: UValidators.required(message: ""),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UFieldPair(
          UTextField(
            controller: c.creditorController,
            labelText: U.s.creditor,
            keyboardType: TextInputType.number,
            formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          UTextField(
            controller: c.paidController,
            labelText: U.s.paidAmount,
            keyboardType: TextInputType.number,
            formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        UTextField(
          controller: c.penaltyController,
          labelText: U.s.penaltyAmount,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextFieldDatePicker(
          controller: c.dueDateController,
          labelText: U.s.dueDate,
          jalali: true,
          initialDate: c.dueDate,
          validator: UValidators.required(message: ""),
          margin: const EdgeInsets.symmetric(vertical: 6),
          onChange: (DateTime d, UJalali j) {
            c.dueDate = d;
            c.dueDateController.text = d.toJalaliDate();
          },
        ),
        UTextField(controller: c.descriptionController, labelText: U.s.description, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
      ],
    );
  }
}
