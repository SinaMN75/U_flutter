part of "../../../u_admin.dart";

class UAdminTerminalsPage extends StatefulWidget {
  const UAdminTerminalsPage({super.key, this.merchant, this.actions});

  final UMerchantResponse? merchant;
  final UAdminActionBuilder<UTerminalResponse>? actions;

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
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.merchant == null ? U.s.terminalsManagement : "${U.s.terminals} · ${widget.merchant?.title}",
    onFilter: _showFilterDialog,
    onCreate: _showCreateDialog,
    extraActions: <Widget>[
      if (U.user.isFullAdmin()) IconButton(icon: const Icon(Icons.pin), tooltip: U.s.otpTools, onPressed: _showOtpDialog),
      IconButton(icon: const Icon(Icons.grid_4x4), tooltip: U.s.bulkImportTerminals, onPressed: c.import),
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
        U.s.imei,
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

  Widget _itemDesktop(UTerminalResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(TagTerminal.values.titlesFromNumbers(i.tags).join(" , ")),
      UAdminTable.cell(i.serial),
      UAdminTable.cell(i.simCardSerial ?? "-"),
      UAdminTable.cell(i.imei ?? U.s.noMerchantSelected),
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
      UAdminField(U.s.merchant, i.merchant?.title ?? U.s.noMerchantSelected),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UTerminalResponse i) => UAdminOps.menu<UTerminalResponse>(
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UTerminalResponse>(
      onEdit: _showEditDialog,
      onDelete: c.delete,
      extras: <String, void Function(UTerminalResponse)>{
        "supportPassword": c.supportPassword,
        "approve": c.approve,
        "reject": _showRejectDialog,
        "viewAgreement": c.viewAgreement,
      },
    ),
    fallback: (UAdminActionContext<UTerminalResponse> ctx) => <UAdminAction>[
      ctx.extra("approve", label: U.s.approve, icon: Icons.check_circle_outline, visible: _isPending(i), color: UAdminTheme.green),
      ctx.extra("reject", label: U.s.reject, icon: Icons.cancel_outlined, visible: _isPending(i), destructive: true),
      ctx.extra("viewAgreement", label: U.s.viewAgreement, icon: Icons.description_outlined, visible: i.merchantId.isNotNullOrEmpty()),
      ctx.extra("supportPassword", label: U.s.getSupportPassword, icon: Icons.password),
      ctx.edit(),
      ctx.delete(),
    ],
  );

  void _showRejectDialog(UTerminalResponse i) {
    final TextEditingController reason = TextEditingController();
    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.reject),
        content: SizedBox(
          width: context.dialogWidth(),
          child: UTextField(controller: reason, labelText: U.s.rejectionReason, lines: 3),
        ),
        actions: <Widget>[
          UButtonSubmitCancel(
            onSubmit: () {
              UNavigator.back();
              c.reject(i: i, reason: reason.text.nullIfEmpty());
            },
            onCancel: UNavigator.back,
          ),
        ],
      ),
    ).whenComplete(reason.dispose);
  }

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.terminals)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UDropDownField<TagOrderBy>(
                initialValue: c.tagOrderBy.value,
                onChanged: c.tagOrderBy.call,
                items: <DropdownMenuItem<TagOrderBy>>[
                  DropdownMenuItem<TagOrderBy>(value: TagOrderBy.createdAt, child: Text(TagOrderBy.createdAt.localizedTitle)),
                  DropdownMenuItem<TagOrderBy>(value: TagOrderBy.createdAtDescending, child: Text(TagOrderBy.createdAtDescending.localizedTitle)),
                ],
              ).pSymmetric(vertical: 6),
              UDropDownField<TagTerminal?>(
                initialValue: c.typeFilter.value,
                onChanged: c.typeFilter.call,
                items: <DropdownMenuItem<TagTerminal>>[
                  DropdownMenuItem<TagTerminal>(value: TagTerminal.pendingApproval, child: Text(TagTerminal.pendingApproval.localizedTitle)),
                  DropdownMenuItem<TagTerminal>(value: TagTerminal.approved, child: Text(TagTerminal.approved.localizedTitle)),
                  DropdownMenuItem<TagTerminal>(value: TagTerminal.rejected, child: Text(TagTerminal.rejected.localizedTitle)),
                ],
              ).pSymmetric(vertical: 6),
              UTextField(controller: c.serialFilter, labelText: U.s.serial, margin: const EdgeInsets.symmetric(vertical: 6)),
              if (widget.merchant == null) UTextField(controller: c.merchantIdFilter, labelText: U.s.merchantId, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.creatorIdFilter, labelText: U.s.creatorId, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.fromCreatedController,
                labelText: U.s.fromDate,
                onChange: (DateTime d, Jalali j) {
                  c.fromCreatedController.text = j.formatCompactDate();
                  c.fromCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.toCreatedController,
                labelText: U.s.toDate,
                onChange: (DateTime d, Jalali j) {
                  c.toCreatedController.text = j.formatCompactDate();
                  c.toCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              const SizedBox(height: 20),
              UButtonSubmitCancel(
                submitTitle: U.s.filter,
                cancelTitle: U.s.clearFilters,
                onSubmit: () {
                  c.applyFilters();
                  UNavigator.back();
                },
                onCancel: () {
                  c.clearFilters();
                  UNavigator.back();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _showCreateDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController serial = TextEditingController();
    final TextEditingController simCardNumber = TextEditingController();
    final TextEditingController simCardSerial = TextEditingController();
    final TextEditingController imei = TextEditingController();
    final TextEditingController terminalId = TextEditingController();
    final Rx<TagTerminal> type = TagTerminal.atm.obs;
    final Rxn<UTerminalBrandResponse> brand = Rxn<UTerminalBrandResponse>();
    final Rxn<UTerminalBrokerResponse> broker = Rxn<UTerminalBrokerResponse>();

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.createItem(U.s.terminals)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: serial,
                    labelText: U.s.serial,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: simCardNumber,
                    labelText: U.s.simCardNumber,
                    keyboardType: TextInputType.phone,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(controller: simCardSerial, labelText: U.s.simCardSerial, margin: const EdgeInsets.symmetric(vertical: 6)),
                  UTextField(controller: imei, labelText: U.s.imei, margin: const EdgeInsets.symmetric(vertical: 6)),
                  UDropDownField<TagTerminal>(
                    initialValue: type.value,
                    onChanged: type.call,
                    items: <DropdownMenuItem<TagTerminal>>[
                      DropdownMenuItem<TagTerminal>(value: TagTerminal.atm, child: Text(TagTerminal.atm.localizedTitle)),
                      DropdownMenuItem<TagTerminal>(value: TagTerminal.deskCashless, child: Text(TagTerminal.deskCashless.localizedTitle)),
                      DropdownMenuItem<TagTerminal>(value: TagTerminal.wallCashless, child: Text(TagTerminal.wallCashless.localizedTitle)),
                    ],
                  ),
                  UTextFieldAutoCompleteAsync<UTerminalBrandResponse>(
                    labelBuilder: (UTerminalBrandResponse i) => i.title,
                    onChanged: brand.call,
                    selectedItem: brand.value,
                    fetchData: c.readBrand,
                    hintText: U.s.bed,
                  ).pSymmetric(vertical: 6),
                  UTextFieldAutoCompleteAsync<UTerminalBrokerResponse>(
                    labelBuilder: (UTerminalBrokerResponse i) => i.title,
                    onChanged: broker.call,
                    selectedItem: broker.value,
                    fetchData: c.readBroker,
                    hintText: U.s.bed,
                  ).pSymmetric(vertical: 6),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        if (brand.value == null || broker.value == null) {
                          UToast.error(message: U.s.required);
                          return;
                        }
                        UNavigator.back();
                        c.create(
                          p: UTerminalCreateParams(
                            tags: <int>[type.value.number],
                            serial: serial.text.trim(),
                            simCardNumber: simCardNumber.text.nullIfEmpty(),
                            simCardSerial: simCardSerial.text.nullIfEmpty(),
                            imei: imei.text.nullIfEmpty(),
                            terminalId: terminalId.text.nullIfEmpty(),
                            terminalBrandId: brand.value!.id,
                            terminalBrokerId: broker.value!.id,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(UTerminalResponse i) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController serial = TextEditingController(text: i.serial);
    final TextEditingController simCardNumber = TextEditingController(text: i.simCardNumber);
    final TextEditingController simCardSerial = TextEditingController(text: i.simCardSerial);
    final TextEditingController imei = TextEditingController(text: i.imei);
    final TextEditingController terminalId = TextEditingController(text: i.terminalId);

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.editItem(U.s.terminals)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: serial,
                    labelText: U.s.serial,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: simCardNumber,
                    labelText: U.s.simCardNumber,
                    keyboardType: TextInputType.phone,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(controller: simCardSerial, labelText: U.s.simCardSerial, margin: const EdgeInsets.symmetric(vertical: 6)),
                  UTextField(controller: imei, labelText: U.s.imei, margin: const EdgeInsets.symmetric(vertical: 6)),
                  UTextField(controller: terminalId, labelText: U.s.terminalId, margin: const EdgeInsets.symmetric(vertical: 6)),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.update(
                          p: UTerminalUpdateParams(
                            id: i.id,
                            serial: serial.text.nullIfEmpty(),
                            simCardNumber: simCardNumber.text.nullIfEmpty(),
                            simCardSerial: simCardSerial.text.nullIfEmpty(),
                            imei: imei.text.nullIfEmpty(),
                            terminalId: terminalId.text.nullIfEmpty(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOtpDialog() {
    final TextEditingController serial = TextEditingController();
    final TextEditingController length = TextEditingController(text: "6");
    final TextEditingController otp = TextEditingController();
    final Rx<bool> generateMode = true.obs;
    final Rx<bool> admin = false.obs;
    final Rx<String> result = "".obs;
    final Rx<bool?> valid = Rx<bool?>(null);

    void run() {
      final String serialText = serial.text.trim();
      if (serialText.isEmpty) {
        UToast.error(message: U.s.required);
        return;
      }
      if (generateMode.value) {
        final int len = int.tryParse(length.text.trim()) ?? 6;
        result(admin.value ? UOtp.generateAdminOtp(serialText, len) : UOtp.generateOtp(serialText, len));
        valid(null);
      } else {
        final String otpText = otp.text.trim();
        if (otpText.isEmpty) {
          UToast.error(message: U.s.required);
          return;
        }
        valid(admin.value ? UOtp.verifyAdminOtp(serialText, otpText) : UOtp.verifyOtp(serialText, otpText));
        result("");
      }
    }

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.otpTools),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Obx(
                  () => UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  USegmentedControl<bool>(
                    selectedValue: generateMode.value,
                    items: <bool, String>{true: U.s.generateOtp, false: U.s.verifyOtp},
                    onValueChanged: (bool? v) {
                      generateMode(v ?? true);
                      result("");
                      valid(null);
                    },
                  ).pSymmetric(vertical: 6),
                  UTextField(
                    controller: serial,
                    labelText: U.s.serial,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  if (generateMode.value)
                    UTextField(
                      controller: length,
                      labelText: U.s.otpLength,
                      keyboardType: TextInputType.number,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    )
                  else
                    UTextField(
                      controller: otp,
                      labelText: U.s.otpCode,
                      keyboardType: TextInputType.number,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  URow(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    children: <Widget>[
                      UTextBodyMedium(U.s.adminOtp, expanded: 1),
                      Switch(value: admin.value, onChanged: admin.call),
                    ],
                  ),
                  if (result.value.isNotEmpty)
                    UContainer(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      color: UAdminTheme.green.withValues(alpha: 0.12),
                      radius: 8,
                      child: SelectableText(
                        result.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                  if (valid.value != null)
                    UContainer(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      color: (valid.value! ? UAdminTheme.green : UAdminTheme.red).withValues(alpha: 0.12),
                      radius: 8,
                      child: UTextBodyLarge(
                        valid.value! ? U.s.otpIsValid : U.s.otpIsInvalid,
                        color: valid.value! ? UAdminTheme.green : UAdminTheme.red,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: <Widget>[
          Obx(
                () => generateMode.value && result.value.isNotEmpty
                ? UButton(
              type: UButtonType.text,
              title: U.s.copy,
              onTap: () => UClipboard.set(result.value, snackBar: true),
            )
                : const SizedBox.shrink(),
          ),
          UButton(type: UButtonType.text, title: U.s.cancel, onTap: UNavigator.back),
          Obx(() => UButton(title: generateMode.value ? U.s.generate : U.s.verifyOtp, onTap: run)),
        ],
      ),
    );
  }
}
