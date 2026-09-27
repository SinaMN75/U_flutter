part of "../../../u_admin.dart";

class UAdminTerminalsPage extends StatefulWidget {
  const UAdminTerminalsPage({super.key, this.merchant});

  static void open({UMerchantResponse? merchant}) => U.addOrSwitchTab(
    merchant == null ? U.s.terminalsManagement : "${U.s.terminals} · ${merchant.title}",
    UAdminTerminalsPage(merchant: merchant),
  );

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.terminals,
    icon: Icons.point_of_sale_rounded,
    page: () => const UAdminTerminalsPage(),
    roles: roles,
  );

  final UMerchantResponse? merchant;

  @override
  State<UAdminTerminalsPage> createState() => _TerminalsPageState();
}

class _TerminalsPageState extends State<UAdminTerminalsPage> {
  final UAdminTerminalController c = UAdminTerminalController();

  @override
  void initState() {
    c.init(merchant: widget.merchant);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.merchant == null ? U.s.terminalsManagement : "${U.s.terminals} · ${widget.merchant?.title}",
    onFilter: _filter,
    onCreate: _form,
    extraActions: <Widget>[
      if (U.user.isFullAdmin()) IconButton(icon: const Icon(Icons.pin), tooltip: U.s.otpTools, onPressed: _otp),
      IconButton(icon: const Icon(Icons.grid_4x4), tooltip: U.s.bulkImportTerminals, onPressed: () => c.import(_importResult)),
    ],
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: _list(),
  );

  Widget _list() => UAdminListView<UTerminalResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.terminals),
    desktopHeader: () => UAdminTable.header(
      <String>[
        U.s.type,
        U.s.serial,
        U.s.simCardSerial,
        U.s.brands,
        U.s.brokers,
        U.s.merchant,
        U.s.terminalId,
        U.s.createdAt,
        U.s.operations,
      ],
    ),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _statusChip(UTerminalResponse i) {
    final (String label, Color color) = _status(i);
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: color.withValues(alpha: 0.15),
      radius: 20,
      child: UTextBodyMedium(label, color: color, fontWeight: FontWeight.w600),
    );
  }

  (String, Color) _status(UTerminalResponse i) {
    if (i.tags.contains(TagTerminal.pendingApproval.number)) return (U.s.pendingApproval, UAdminTheme.orange);
    if (i.tags.contains(TagTerminal.rejected.number)) return (U.s.rejected, UAdminTheme.red);
    if (i.tags.contains(TagTerminal.approved.number) || i.terminalId.isNotNullOrEmpty()) return (i.terminalId ?? U.s.approved, UAdminTheme.green);
    return (U.s.notAssigned, UAdminTheme.grey);
  }

  bool _isPending(UTerminalResponse i) => i.tags.contains(TagTerminal.pendingApproval.number);

  String _brandLabel(UTerminalBrandResponse x) => "${x.title} (${x.code})";

  String _brokerLabel(UTerminalBrokerResponse x) => "${x.title} (${x.code})";

  Widget _itemDesktop(UTerminalResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(TagTerminal.values.titlesFromNumbers(i.tags).join(" , ")),
      UAdminTable.cell(i.serial),
      UAdminTable.cell(i.simCardSerial ?? "-"),
      UAdminTable.cell(i.terminalBrand == null ? "---" : _brandLabel(i.terminalBrand!)),
      UAdminTable.cell(i.terminalBroker == null ? "---" : _brokerLabel(i.terminalBroker!)),
      UAdminTable.cell(i.merchant?.title ?? U.s.noMerchantSelected),
      _statusChip(i).alignAtCenter().expanded(),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UTerminalResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.point_of_sale_rounded,
    title: "${U.s.serial}: ${i.serial}",
    badge: _statusChip(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.simCardSerial, i.simCardSerial ?? "-"),
      UAdminField(U.s.brand, i.terminalBrand == null ? "---" : _brandLabel(i.terminalBrand!)),
      UAdminField(U.s.broker, i.terminalBroker == null ? "---" : _brokerLabel(i.terminalBroker!)),
      UAdminField(U.s.merchant, i.merchant?.title ?? U.s.noMerchantSelected),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UTerminalResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.approve, icon: Icons.check_circle_outline, color: UAdminTheme.green, visible: _isPending(i), onTap: () => c.approve(i)),
      UPopupMenuItem(label: U.s.reject, icon: Icons.cancel_outlined, destructive: true, visible: _isPending(i), onTap: () => _reject(i)),
      UPopupMenuItem(label: U.s.viewAgreement, icon: Icons.description_outlined, visible: i.merchantId.isNotNullOrEmpty(), onTap: () => c.viewAgreement(i)),
      UPopupMenuItem(label: U.s.getSupportPassword, icon: Icons.password, onTap: () => _supportPassword(i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  void _reject(UTerminalResponse i) {
    c.rejectReasonController.clear();
    UFormDialog.show(
      title: U.s.reject,
      onSubmit: () => c.reject(i),
      children: (BuildContext context, StateSetter setState) => <Widget>[UTextField(
        controller: c.rejectReasonController,
        labelText: U.s.rejectionReason,
        lines: 3,
        margin: const EdgeInsets.symmetric(vertical: 6),
      )],
    );
  }

  Future<void> _supportPassword(UTerminalResponse i) async {
    final String? pass = await c.supportPassword(i);
    if (pass == null) return;
    await UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.supportPassword),
        content: SelectableText(pass, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: <Widget>[
          UButton(
            type: UButtonType.text,
            title: U.s.ok,
            onTap: () {
              UClipboard.set(pass);
              UNavigator.back();
            },
          ),
        ],
      ),
    );
  }

  void _importResult(UTerminalImportResponse r) => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.bulkImportTerminals),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UTextBodyLarge("${U.s.total}: ${r.totalRows}"),
              UTextBodyLarge("${U.s.imported}: ${r.imported}", color: UAdminTheme.green),
              UTextBodyLarge("${U.s.skipped}: ${r.skipped}", color: r.skipped > 0 ? UAdminTheme.red : null),
              if (r.skippedSerials.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                UTextTitleSmall(U.s.skippedRows),
                const SizedBox(height: 4),
                ...r.skippedSerials.map((String x) => SelectableText("• $x")),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (r.skippedSerials.isNotEmpty) UButton(type: UButtonType.text, title: U.s.copy, onTap: () => UClipboard.set(r.skippedSerials.join("\n"), snackBar: true)),
        UButton(type: UButtonType.text, title: U.s.close, onTap: UNavigator.back),
      ],
    ),
  );

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.terminals),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UDropDownField<TagOrderBy>(
        initialValue: c.tagOrderBy.value,
        onChanged: c.tagOrderBy.call,
        items: <TagOrderBy>[TagOrderBy.createdAt, TagOrderBy.createdAtDescending].map((TagOrderBy x) => DropdownMenuItem<TagOrderBy>(value: x, child: Text(x.localizedTitle))).toList(),
      ).pSymmetric(vertical: 6),
      UDropDownField<TagTerminal?>(
        initialValue: c.typeFilter,
        onChanged: (TagTerminal? v) => c.typeFilter = v,
        items: <TagTerminal>[TagTerminal.pendingApproval, TagTerminal.approved, TagTerminal.rejected].map((TagTerminal x) => DropdownMenuItem<TagTerminal>(value: x, child: Text(x.localizedTitle))).toList(),
      ).pSymmetric(vertical: 6),
      UTextField(controller: c.serialFilterController, labelText: U.s.serial, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldAutoCompleteAsync<UTerminalBrandResponse>(
        labelBuilder: _brandLabel,
        onChanged: (UTerminalBrandResponse? v) => c.brandFilter = v,
        selectedItem: c.brandFilter,
        fetchData: c.searchBrands,
        hintText: U.s.brand,
      ).pSymmetric(vertical: 6),
      UTextFieldAutoCompleteAsync<UTerminalBrokerResponse>(
        labelBuilder: _brokerLabel,
        onChanged: (UTerminalBrokerResponse? v) => c.brokerFilter = v,
        selectedItem: c.brokerFilter,
        fetchData: c.searchBrokers,
        hintText: U.s.broker,
      ).pSymmetric(vertical: 6),
      if (widget.merchant == null) UTextField(controller: c.merchantIdFilterController, labelText: U.s.merchantId, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.creatorIdFilterController, labelText: U.s.creatorId, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldDatePicker(
        controller: c.startDateController,
        labelText: U.s.fromDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.startDate = d;
          c.startDateController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.endDateController,
        labelText: U.s.toDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.endDate = d;
          c.endDateController.text = d.toJalaliDate();
        },
      ),
    ],
  );

  Future<void> _form([UTerminalResponse? t]) async {
    c.loadForm(t);
    await UFormDialog.show(
      title: t == null ? U.s.createItem(U.s.terminals) : U.s.editItem(U.s.terminals),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.serialController, labelText: U.s.serial, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.simCardNumberController, labelText: U.s.simCardNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.simCardSerialController, labelText: U.s.simCardSerial, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.imeiController, labelText: U.s.imei, margin: const EdgeInsets.symmetric(vertical: 6)),
        if (t != null) UTextField(controller: c.terminalIdController, labelText: U.s.terminalId, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldAutoCompleteAsync<UTerminalBrandResponse>(
          labelBuilder: _brandLabel,
          onChanged: (UTerminalBrandResponse? v) => c.brand = v,
          selectedItem: c.brand,
          fetchData: c.searchBrands,
          hintText: U.s.brand,
        ).pSymmetric(vertical: 6),
        UTextFieldAutoCompleteAsync<UTerminalBrokerResponse>(
          labelBuilder: _brokerLabel,
          onChanged: (UTerminalBrokerResponse? v) => c.broker = v,
          selectedItem: c.broker,
          fetchData: c.searchBrokers,
          hintText: U.s.broker,
        ).pSymmetric(vertical: 6),
      ],
    );
  }

  void _otp() {
    c.loadOtp();
    UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: Text(U.s.otpTools),
          content: SizedBox(
            width: context.dialogWidth(),
            child: SingleChildScrollView(
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  USegmentedControl<bool>(
                    selectedValue: c.otpGenerate,
                    items: <bool, String>{true: U.s.generateOtp, false: U.s.verifyOtp},
                    onValueChanged: (bool? v) => setState(() {
                      c.otpGenerate = v ?? true;
                      c.otpResult = "";
                      c.otpValid = null;
                    }),
                  ).pSymmetric(vertical: 6),
                  UTextField(controller: c.otpSerialController, labelText: U.s.serial, margin: const EdgeInsets.symmetric(vertical: 6)),
                  if (c.otpGenerate)
                    UTextField(
                      controller: c.otpLengthController,
                      labelText: U.s.otpLength,
                      keyboardType: TextInputType.number,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ) else UTextField(controller: c.otpCodeController, labelText: U.s.otpCode, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                  URow(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    children: <Widget>[
                      UTextBodyMedium(U.s.adminOtp, expanded: 1),
                      Switch(value: c.otpAdmin, onChanged: (bool v) => setState(() => c.otpAdmin = v)),
                    ],
                  ),
                  if (c.otpResult.isNotEmpty)
                    UContainer(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      color: UAdminTheme.green.withValues(alpha: 0.12),
                      radius: 8,
                      child: SelectableText(c.otpResult, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  if (c.otpValid != null)
                    UContainer(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      color: (c.otpValid! ? UAdminTheme.green : UAdminTheme.red).withValues(alpha: 0.12),
                      radius: 8,
                      child: UTextBodyLarge(
                        c.otpValid! ? U.s.otpIsValid : U.s.otpIsInvalid,
                        color: c.otpValid! ? UAdminTheme.green : UAdminTheme.red,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            if (c.otpGenerate && c.otpResult.isNotEmpty) UButton(type: UButtonType.text, title: U.s.copy, onTap: () => UClipboard.set(c.otpResult, snackBar: true)),
            UButton(type: UButtonType.text, title: U.s.cancel, onTap: UNavigator.back),
            UButton(title: c.otpGenerate ? U.s.generate : U.s.verifyOtp, onTap: () => setState(c.runOtp)),
          ],
        ),
      ),
    );
  }
}
