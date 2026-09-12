import "package:u/utilities.dart";

class UAdminTerminalBrandsPage extends StatefulWidget {
  const UAdminTerminalBrandsPage({super.key, this.actions});

  final UAdminActionBuilder<UTerminalBrandResponse>? actions;

  @override
  State<UAdminTerminalBrandsPage> createState() => _TerminalBrandsPageState();
}

class _TerminalBrandsPageState extends State<UAdminTerminalBrandsPage> {
  final UAdminTerminalBrandController c = UAdminTerminalBrandController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.brandsManagement,
    onFilter: _showFilterDialog,
    onCreate: _showEditDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UTerminalBrandResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.terminalBrands),
      desktopHeader: () => UAdminTable.header(<String>[
        U.s.title,
        U.s.code,
        U.s.broker,
        U.s.simCardSerial,
        U.s.status,
        U.s.createdAt,
        U.s.operations,
      ]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  bool _isActive(UTerminalBrandResponse i) => i.tags.contains(TagTerminalBrand.active.number);

  Widget _statusChip(UTerminalBrandResponse i) => UAdminTable.statusChip(
    label: _isActive(i) ? U.s.active : U.s.inactive,
    color: _isActive(i) ? UAdminTheme.green : UAdminTheme.grey,
  );

  Widget _itemDesktop(UTerminalBrandResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.code),
      UAdminTable.cell(i.broker?.title ?? "-"),
      UAdminTable.cell(i.jsonData.requiresSimCardSerial ? U.s.yes : U.s.no),
      _statusChip(i).alignAtCenter().expanded(),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UTerminalBrandResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.devices_other_rounded,
    title: i.title,
    badge: _statusChip(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.code, i.code),
      UAdminField(U.s.broker, i.broker?.title ?? "-"),
      UAdminField(U.s.simCardSerial, i.jsonData.requiresSimCardSerial ? U.s.yes : U.s.no),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UTerminalBrandResponse i) => UAdminOps.menu<UTerminalBrandResponse>(
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UTerminalBrandResponse>(
      onEdit: (UTerminalBrandResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UTerminalBrandResponse> ctx) => <UAdminAction>[ctx.edit(), ctx.delete()],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.terminalBrands)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.titleFilter, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.codeFilter, labelText: U.s.code, margin: const EdgeInsets.symmetric(vertical: 6)),
              UDropDownField<UBrokerResponse?>(
                initialValue: c.brokerFilter.value,
                labelText: U.s.broker,
                items: <DropdownMenuItem<UBrokerResponse?>>[
                  DropdownMenuItem<UBrokerResponse?>(child: Text(U.s.all)),
                  ...c.brokers.map((UBrokerResponse b) => DropdownMenuItem<UBrokerResponse?>(value: b, child: Text(b.title))),
                ],
                onChanged: c.brokerFilter.call,
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
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

  Future<void> _showEditDialog({UTerminalBrandResponse? p}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController code = TextEditingController(text: p?.code);
    final TextEditingController order = TextEditingController(text: p?.jsonData.order?.toString());

    final List<UBrokerResponse> brokers = c.brokers.isEmpty ? await c.fetchBrokers() : c.brokers;
    final List<UAgreementTemplateResponse> templates = await c.fetchTemplates();

    String? imageBase64 = p?.jsonData.imageBase64;
    bool isActive = p == null || p.tags.contains(TagTerminalBrand.active.number);
    bool requiresSimCardSerial = p?.jsonData.requiresSimCardSerial ?? true;
    bool requiresImei = p?.jsonData.requiresImei ?? false;
    String? brokerId = brokers.any((UBrokerResponse b) => b.id == p?.brokerId) ? p?.brokerId : brokers.firstOrNull?.id;
    String? agreementTemplateId = templates.any((UAgreementTemplateResponse t) => t.id == p?.jsonData.agreementTemplateId) ? p?.jsonData.agreementTemplateId : null;

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createItem(U.s.terminalBrand) : U.s.editItem(U.s.terminalBrand)),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(controller: title, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: code, labelText: U.s.code, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
                    UDropDownField<String?>(
                      initialValue: brokerId,
                      labelText: U.s.broker,
                      items: brokers.map((UBrokerResponse b) => DropdownMenuItem<String?>(value: b.id, child: Text(b.title))).toList(),
                      onChanged: (String? v) => brokerId = v,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UDropDownField<String?>(
                      initialValue: agreementTemplateId,
                      labelText: U.s.agreementTemplate,
                      items: <DropdownMenuItem<String?>>[
                        DropdownMenuItem<String?>(child: Text(U.s.broker)),
                        ...templates.map((UAgreementTemplateResponse t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.title))),
                      ],
                      onChanged: (String? v) => agreementTemplateId = v,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(controller: order, labelText: U.s.order, margin: const EdgeInsets.symmetric(vertical: 6)),
                    const SizedBox(height: 8),
                    UBase64ImageField(label: U.s.image, initial: imageBase64, onChanged: (String? v) => imageBase64 = v),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(U.s.requiresSimCardSerial),
                      value: requiresSimCardSerial,
                      onChanged: (bool v) => setDialogState(() => requiresSimCardSerial = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(U.s.requiresImei),
                      value: requiresImei,
                      onChanged: (bool v) => setDialogState(() => requiresImei = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(U.s.active),
                      value: isActive,
                      onChanged: (bool v) => setDialogState(() => isActive = v),
                    ),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          if (brokerId == null) {
                            UToast.error(message: U.s.brokerIsRequired);
                            return;
                          }
                          final List<int> tags = <int>[if (isActive) TagTerminalBrand.active.number else TagTerminalBrand.inactive.number];

                          if (p == null) {
                            c.create(
                              p: UTerminalBrandCreateParams(
                                tags: tags,
                                title: title.text,
                                code: code.text,
                                brokerId: brokerId!,
                                requiresSimCardSerial: requiresSimCardSerial,
                                requiresImei: requiresImei,
                                imageBase64: imageBase64,
                                order: int.tryParse(order.text),
                                agreementTemplateId: agreementTemplateId,
                              ),
                            );
                          } else {
                            c.update(
                              p: UTerminalBrandUpdateParams(
                                id: p.id,
                                tags: tags,
                                title: title.text,
                                code: code.text,
                                brokerId: brokerId,
                                requiresSimCardSerial: requiresSimCardSerial,
                                requiresImei: requiresImei,
                                imageBase64: imageBase64,
                                order: int.tryParse(order.text),
                                agreementTemplateId: agreementTemplateId,
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
          ),
        ),
      ),
    );
  }
}
