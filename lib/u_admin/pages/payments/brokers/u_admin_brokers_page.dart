import "package:u/utilities.dart";

class UAdminBrokersPage extends StatefulWidget {
  const UAdminBrokersPage({super.key, this.actions});

  final UAdminActionBuilder<UBrokerResponse>? actions;

  @override
  State<UAdminBrokersPage> createState() => _BrokersPageState();
}

class _BrokersPageState extends State<UAdminBrokersPage> {
  final UAdminBrokerController c = UAdminBrokerController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.brokersManagement,
    onFilter: _showFilterDialog,
    onCreate: _showEditDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UBrokerResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.brokers),
      desktopHeader: () => UAdminTable.header(<String>[
        U.s.title,
        U.s.code,
        U.s.terminalBrands,
        U.s.phoneNumber,
        U.s.status,
        U.s.createdAt,
        U.s.operations,
      ]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  bool _isActive(UBrokerResponse i) => i.tags.contains(TagBroker.active.number);

  Widget _statusChip(UBrokerResponse i) => UAdminTable.statusChip(
    label: _isActive(i) ? U.s.active : U.s.inactive,
    color: _isActive(i) ? UAdminTheme.green : UAdminTheme.grey,
  );

  Widget _itemDesktop(UBrokerResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.code),
      UAdminTable.cell(i.brands.length.toString()),
      UAdminTable.cell(i.jsonData.phoneNumber ?? "-"),
      _statusChip(i).alignAtCenter().expanded(),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UBrokerResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.apartment_rounded,
    title: i.title,
    badge: _statusChip(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.code, i.code),
      UAdminField(U.s.terminalBrands, i.brands.length.toString()),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UBrokerResponse i) => UAdminOps.menu<UBrokerResponse>(
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UBrokerResponse>(
      onEdit: (UBrokerResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UBrokerResponse> ctx) => <UAdminAction>[ctx.edit(), ctx.delete()],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.brokers)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.titleFilter, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.codeFilter, labelText: U.s.code, margin: const EdgeInsets.symmetric(vertical: 6)),
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

  Future<void> _showEditDialog({UBrokerResponse? p}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController code = TextEditingController(text: p?.code);
    final TextEditingController legalName = TextEditingController(text: p?.jsonData.legalName);
    final TextEditingController registrationNumber = TextEditingController(text: p?.jsonData.registrationNumber);
    final TextEditingController nationalId = TextEditingController(text: p?.jsonData.nationalId);
    final TextEditingController address = TextEditingController(text: p?.jsonData.address);
    final TextEditingController postalCode = TextEditingController(text: p?.jsonData.postalCode);
    final TextEditingController phoneNumber = TextEditingController(text: p?.jsonData.phoneNumber);
    final TextEditingController supportPhoneNumber = TextEditingController(text: p?.jsonData.supportPhoneNumber);
    final TextEditingController callCenterPhoneNumber = TextEditingController(text: p?.jsonData.callCenterPhoneNumber);
    final TextEditingController representativeName = TextEditingController(text: p?.jsonData.representativeName);
    final TextEditingController representativeRole = TextEditingController(text: p?.jsonData.representativeRole);
    final TextEditingController themeColor = TextEditingController(text: p?.jsonData.themeColor);
    final TextEditingController contractNumberSuffix = TextEditingController(text: p?.jsonData.contractNumberSuffix);
    final TextEditingController providerBaseUrl = TextEditingController(text: p?.jsonData.providerBaseUrl);
    final TextEditingController providerAuthHeader = TextEditingController(text: p?.jsonData.providerAuthHeader);
    final TextEditingController providerProject = TextEditingController(text: p?.jsonData.providerProject);
    final TextEditingController providerDefinitionTemplate = TextEditingController(text: (p?.jsonData.providerDefinitionTemplate ?? 1).toString());

    String? logoBase64 = p?.jsonData.logoBase64;
    bool isActive = p == null || p.tags.contains(TagBroker.active.number);
    TagBrokerProvider provider = TagBrokerProvider.values.firstWhereOrNull((TagBrokerProvider x) => x.number == p?.jsonData.provider) ?? TagBrokerProvider.avreen;
    String? agreementTemplateId = p?.agreementTemplateId;
    final List<_SignatoryForm> signatories = <_SignatoryForm>[
      ...(p?.jsonData.signatories ?? <UBrokerSignatory>[]).map(_SignatoryForm.fromModel),
    ];
    final List<UAgreementTemplateResponse> templates = await c.fetchTemplates();

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createItem(U.s.broker) : U.s.editItem(U.s.broker)),
          content: SizedBox(
            width: context.dialogWidth(max: 520),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(controller: title, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: code, labelText: U.s.code, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: legalName, labelText: U.s.legalName, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: registrationNumber, labelText: U.s.registrationNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: nationalId, labelText: U.s.nationalId, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: address, labelText: U.s.address, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: postalCode, labelText: U.s.postalCode, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: phoneNumber, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: supportPhoneNumber, labelText: U.s.supportPhoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: callCenterPhoneNumber, labelText: U.s.callCenterPhoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: representativeName, labelText: U.s.representativeName, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: representativeRole, labelText: U.s.representativeRole, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: themeColor, labelText: U.s.themeColor, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: contractNumberSuffix, labelText: U.s.contractNumberSuffix, margin: const EdgeInsets.symmetric(vertical: 6)),
                    const SizedBox(height: 8),
                    UBase64ImageField(label: U.s.logo, initial: logoBase64, onChanged: (String? v) => logoBase64 = v),
                    const SizedBox(height: 12),
                    UDropDownField<String?>(
                      initialValue: agreementTemplateId,
                      labelText: U.s.agreementTemplate,
                      items: <DropdownMenuItem<String?>>[
                        DropdownMenuItem<String?>(child: Text(U.s.agreementTemplate)),
                        ...templates.map((UAgreementTemplateResponse t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.title))),
                      ],
                      onChanged: (String? v) => agreementTemplateId = v,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UDropDownField<TagBrokerProvider>(
                      initialValue: provider,
                      labelText: U.s.serviceProvider,
                      items: TagBrokerProvider.values
                          .map((TagBrokerProvider x) => DropdownMenuItem<TagBrokerProvider>(value: x, child: Text(x.localizedTitle)))
                          .toList(),
                      onChanged: (TagBrokerProvider? v) => provider = v ?? TagBrokerProvider.avreen,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(controller: providerBaseUrl, labelText: U.s.providerBaseUrl, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: providerAuthHeader, labelText: U.s.providerAuthHeader, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: providerProject, labelText: U.s.providerProject, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: providerDefinitionTemplate, labelText: U.s.providerDefinitionTemplate, margin: const EdgeInsets.symmetric(vertical: 6)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(U.s.active),
                      value: isActive,
                      onChanged: (bool v) => setDialogState(() => isActive = v),
                    ),
                    URow(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        UTextBodyLarge(U.s.signatories),
                        TextButton.icon(
                          onPressed: () => setDialogState(() => signatories.add(_SignatoryForm())),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(U.s.addItem(U.s.signatory)),
                        ),
                      ],
                    ),
                    ...signatories.mapIndexed(
                      (int index, _SignatoryForm e) => _signatoryCard(index, e, () => setDialogState(() => signatories.removeAt(index))),
                    ),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          final List<UBrokerSignatory> models = signatories
                              .mapIndexed(
                                (int index, _SignatoryForm e) => UBrokerSignatory(
                                  name: e.name.text.nullIfEmpty(),
                                  role: e.role.text.nullIfEmpty(),
                                  signatureBase64: e.signatureBase64,
                                  order: index + 1,
                                ),
                              )
                              .toList();
                          final List<int> tags = <int>[if (isActive) TagBroker.active.number else TagBroker.inactive.number];

                          if (p == null) {
                            c.create(
                              p: UBrokerCreateParams(
                                tags: tags,
                                title: title.text,
                                code: code.text,
                                legalName: legalName.text.nullIfEmpty(),
                                registrationNumber: registrationNumber.text.nullIfEmpty(),
                                nationalId: nationalId.text.nullIfEmpty(),
                                address: address.text.nullIfEmpty(),
                                postalCode: postalCode.text.nullIfEmpty(),
                                phoneNumber: phoneNumber.text.nullIfEmpty(),
                                supportPhoneNumber: supportPhoneNumber.text.nullIfEmpty(),
                                callCenterPhoneNumber: callCenterPhoneNumber.text.nullIfEmpty(),
                                representativeName: representativeName.text.nullIfEmpty(),
                                representativeRole: representativeRole.text.nullIfEmpty(),
                                logoBase64: logoBase64,
                                themeColor: themeColor.text.nullIfEmpty(),
                                contractNumberSuffix: contractNumberSuffix.text.nullIfEmpty(),
                                provider: provider.number,
                                providerBaseUrl: providerBaseUrl.text.nullIfEmpty(),
                                providerAuthHeader: providerAuthHeader.text.nullIfEmpty(),
                                providerProject: providerProject.text.nullIfEmpty(),
                                providerDefinitionTemplate: int.tryParse(providerDefinitionTemplate.text),
                                agreementTemplateId: agreementTemplateId,
                                signatories: models,
                              ),
                            );
                          } else {
                            c.update(
                              p: UBrokerUpdateParams(
                                id: p.id,
                                tags: tags,
                                title: title.text,
                                code: code.text,
                                legalName: legalName.text,
                                registrationNumber: registrationNumber.text,
                                nationalId: nationalId.text,
                                address: address.text,
                                postalCode: postalCode.text,
                                phoneNumber: phoneNumber.text,
                                supportPhoneNumber: supportPhoneNumber.text,
                                callCenterPhoneNumber: callCenterPhoneNumber.text,
                                representativeName: representativeName.text,
                                representativeRole: representativeRole.text,
                                logoBase64: logoBase64,
                                themeColor: themeColor.text,
                                contractNumberSuffix: contractNumberSuffix.text,
                                provider: provider.number,
                                providerBaseUrl: providerBaseUrl.text,
                                providerAuthHeader: providerAuthHeader.text.nullIfEmpty(),
                                providerProject: providerProject.text,
                                providerDefinitionTemplate: int.tryParse(providerDefinitionTemplate.text),
                                agreementTemplateId: agreementTemplateId,
                                signatories: models,
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

  Widget _signatoryCard(int index, _SignatoryForm e, VoidCallback onRemove) => UContainer(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 6),
    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
    radius: 12,
    child: UColumn(
      children: <Widget>[
        URow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            UTextBodyMedium("${U.s.signatory} ${index + 1}"),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, size: 18)),
          ],
        ),
        UTextField(controller: e.name, labelText: U.s.name, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: e.role, labelText: U.s.role, margin: const EdgeInsets.symmetric(vertical: 6)),
        UBase64ImageField(label: U.s.signature, initial: e.signatureBase64, onChanged: (String? v) => e.signatureBase64 = v),
      ],
    ),
  );
}

class _SignatoryForm {
  _SignatoryForm({String? name, String? role, this.signatureBase64})
    : name = TextEditingController(text: name),
      role = TextEditingController(text: role);

  factory _SignatoryForm.fromModel(UBrokerSignatory m) => _SignatoryForm(name: m.name, role: m.role, signatureBase64: m.signatureBase64);

  final TextEditingController name;
  final TextEditingController role;
  String? signatureBase64;
}
