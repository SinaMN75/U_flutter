part of "../../../u_admin.dart";

class UAdminTerminalBrokersPage extends StatefulWidget {
  const UAdminTerminalBrokersPage({super.key, this.actions});

  final UAdminActionBuilder<UTerminalBrokerResponse>? actions;

  @override
  State<UAdminTerminalBrokersPage> createState() => _TerminalBrokersPageState();
}

class _TerminalBrokersPageState extends State<UAdminTerminalBrokersPage> {
  final UAdminTerminalBrokerController c = UAdminTerminalBrokerController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.brokers,
    onFilter: _showFilterDialog,
    onCreate: _showCreateDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: _list(),
  );

  Widget _list() => UAdminListView<UTerminalBrokerResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.brokers),
    desktopHeader: () => UAdminTable.header(
      <String>[
        U.s.logo,
        U.s.code,
        U.s.title,
        U.s.representative,
        U.s.phoneNumber,
        U.s.createdAt,
        U.s.operations,
      ],
    ),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _itemDesktop(UTerminalBrokerResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      _thumb(i.jsonData.logoBase64).alignAtCenter().expanded(),
      UAdminTable.cell(i.code),
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.jsonData.representative ?? "---"),
      UAdminTable.cell(i.jsonData.phoneNumber ?? "---"),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UTerminalBrokerResponse i, int index) => UAdminTable.mobileCard(
    leading: SizedBox(width: 44, height: 44, child: _thumb(i.jsonData.logoBase64)),
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.code, i.code),
      UAdminField(U.s.representative, i.jsonData.representative ?? "---"),
      UAdminField(U.s.phoneNumber, i.jsonData.phoneNumber ?? "---"),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _thumb(String? base64) => SizedBox(
    width: 40,
    height: 40,
    child: base64.isNotNullOrEmpty() ? UImage("", fileData: UFileData(bytes: base64!.toBytesFromBase64()), borderRadius: 8) : const Icon(Icons.business_center_outlined),
  );

  Widget _menu(UTerminalBrokerResponse i) => UAdminOps.menu<UTerminalBrokerResponse>(
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UTerminalBrokerResponse>(
      onEdit: _showEditDialog,
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UTerminalBrokerResponse> ctx) => <UAdminAction>[
      ctx.edit(),
      ctx.delete(),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    UAdminForm.filterDialog(
      context,
      title: Text(U.s.filterItem(U.s.brokers)),
      children: <Widget>[
        UDropDownField<TagOrderBy>(
          initialValue: c.tagOrderBy.value,
          onChanged: c.tagOrderBy.call,
          items: <DropdownMenuItem<TagOrderBy>>[
            DropdownMenuItem<TagOrderBy>(
              value: TagOrderBy.createdAt,
              child: Text(TagOrderBy.createdAt.localizedTitle),
            ),
            DropdownMenuItem<TagOrderBy>(
              value: TagOrderBy.createdAtDescending,
              child: Text(TagOrderBy.createdAtDescending.localizedTitle),
            ),
          ],
        ).pSymmetric(vertical: 6),
        UTextField(
          controller: c.codeFilter,
          labelText: U.s.code,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.titleFilter,
          labelText: U.s.title,
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
  );

  void _showCreateDialog() => _showFormDialog();

  void _showEditDialog(UTerminalBrokerResponse i) => _showFormDialog(item: i);

  void _showFormDialog({UTerminalBrokerResponse? item}) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final UAdminFields f = UAdminFields();
    final TextEditingController code = f.text(item?.code);
    final TextEditingController title = f.text(item?.title);
    final TextEditingController registrationNumber = f.text(item?.jsonData.registrationNumber);
    final TextEditingController nationalCode = f.text(item?.jsonData.nationalCode);
    final TextEditingController representative = f.text(item?.jsonData.representative);
    final TextEditingController address = f.text(item?.jsonData.address);
    final TextEditingController postalCode = f.text(item?.jsonData.postalCode);
    final TextEditingController phoneNumber = f.text(item?.jsonData.phoneNumber);
    final TextEditingController sign1Owner = f.text(item?.jsonData.sign1Owner);
    final TextEditingController sign2Owner = f.text(item?.jsonData.sign2Owner);

    String? logoBase64 = item?.jsonData.logoBase64;
    String? sign1Base64 = item?.jsonData.sign1Base64;
    String? sign2Base64 = item?.jsonData.sign2Base64;

    UNavigator.dialog(
      f.scope(
        AlertDialog(
          title: Text(item == null ? U.s.createItem(U.s.brokers) : U.s.editItem(U.s.brokers)),
          content: SizedBox(
            width: context.dialogWidth(max: 520),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(
                      controller: code,
                      labelText: U.s.code,
                      validator: UValidators.required(message: U.s.required),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(
                      controller: title,
                      labelText: U.s.title,
                      validator: UValidators.required(message: U.s.required),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(
                      controller: registrationNumber,
                      labelText: U.s.registrationNumber,
                      validator: UValidators.required(message: U.s.required),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(
                      controller: nationalCode,
                      labelText: U.s.nationalCode,
                      validator: UValidators.required(message: U.s.required),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(
                      controller: representative,
                      labelText: U.s.representative,
                      validator: UValidators.required(message: U.s.required),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(
                      controller: address,
                      labelText: U.s.address,
                      lines: 2,
                      validator: UValidators.required(message: U.s.required),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(
                      controller: postalCode,
                      labelText: U.s.postalCode,
                      validator: UValidators.required(message: U.s.required),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextFieldPhoneNumber(
                      controller: phoneNumber,
                      labelText: U.s.phoneNumber,
                      required: true,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    _Base64ImagePicker(label: U.s.logo, initial: logoBase64, onChanged: (String? v) => logoBase64 = v),
                    const SizedBox(height: 12),
                    UTextBodyLarge(U.s.firstSignatory, margin: const EdgeInsets.only(bottom: 4)),
                    UTextField(
                      controller: sign1Owner,
                      labelText: U.s.signatoryName,
                      validator: UValidators.required(message: U.s.required),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    _Base64ImagePicker(label: U.s.signature, initial: sign1Base64, onChanged: (String? v) => sign1Base64 = v),
                    const SizedBox(height: 12),
                    UTextBodyLarge(U.s.secondSignatory, margin: const EdgeInsets.only(bottom: 4)),
                    UTextField(controller: sign2Owner, labelText: U.s.signatoryName, margin: const EdgeInsets.symmetric(vertical: 6)),
                    _Base64ImagePicker(label: U.s.signature, initial: sign2Base64, onChanged: (String? v) => sign2Base64 = v),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          if (item == null && (logoBase64.isNullOrEmpty() || sign1Base64.isNullOrEmpty())) {
                            UToast.error(message: U.s.required);
                            return;
                          }
                          UNavigator.back();
                          if (item == null) {
                            c.create(
                              p: UTerminalBrokerCreateParams(
                                tags: <int>[TagTerminalBroker.test.number],
                                code: code.text.trim(),
                                title: title.text.trim(),
                                registrationNumber: registrationNumber.text.trim(),
                                nationalCode: nationalCode.text.trim(),
                                representative: representative.text.trim(),
                                address: address.text.trim(),
                                postalCode: postalCode.text.trim(),
                                phoneNumber: phoneNumber.text.trim(),
                                sign1Base64: sign1Base64!,
                                sign1Owner: sign1Owner.text.trim(),
                                sign2Base64: sign2Base64,
                                sign2Owner: sign2Owner.text.trim().nullIfEmpty(),
                                logoBase64: logoBase64!,
                              ),
                            );
                          } else {
                            c.update(
                              p: UTerminalBrokerUpdateParams(
                                id: item.id,
                                code: code.text.trim(),
                                title: title.text.trim(),
                                registrationNumber: registrationNumber.text.trim(),
                                nationalCode: nationalCode.text.trim(),
                                representative: representative.text.trim(),
                                address: address.text.trim(),
                                postalCode: postalCode.text.trim(),
                                phoneNumber: phoneNumber.text.trim(),
                                sign1Base64: sign1Base64,
                                sign1Owner: sign1Owner.text.trim(),
                                sign2Base64: sign2Base64,
                                sign2Owner: sign2Owner.text.trim(),
                                logoBase64: logoBase64,
                              ),
                            );
                          }
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

class _Base64ImagePicker extends StatefulWidget {
  const _Base64ImagePicker({required this.label, required this.initial, required this.onChanged});

  final String label;
  final String? initial;
  final ValueChanged<String?> onChanged;

  @override
  State<_Base64ImagePicker> createState() => _Base64ImagePickerState();
}

class _Base64ImagePickerState extends State<_Base64ImagePicker> {
  String? _value;

  @override
  void initState() {
    _value = widget.initial;
    super.initState();
  }

  Future<void> _pick() => UFile.showFilePicker(
    allowedExtensions: const <String>["jpg", "jpeg", "png", "webp"],
    action: (List<UFileData> files) {
      if (files.isEmpty || files.first.bytes == null) return;
      final String encoded = files.first.bytes!.toBase64();
      setState(() => _value = encoded);
      widget.onChanged(encoded);
    },
  );

  void _clear() {
    setState(() => _value = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextBodySmall(widget.label, color: scheme.onSurfaceVariant, margin: const EdgeInsets.only(bottom: 4)),
        Stack(
          children: <Widget>[
            UContainer(
              onTap: _pick,
              height: 96,
              width: double.infinity,
              radius: 12,
              border: Border.all(color: scheme.outlineVariant, width: 1.5),
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: _value.isNotNullOrEmpty()
                  ? UImage("", fileData: UFileData(bytes: _value!.toBytesFromBase64()), borderRadius: 12)
                  : Icon(Icons.add_photo_alternate_outlined, size: 32, color: scheme.onSurfaceVariant),
            ),
            if (_value.isNotNullOrEmpty())
              Positioned(
                top: 4,
                right: 4,
                child: UContainer(
                  onTap: _clear,
                  color: scheme.error,
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.close, size: 14, color: UAdminTheme.white),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
