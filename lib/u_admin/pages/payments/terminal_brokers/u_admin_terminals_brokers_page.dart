part of "../../../u_admin.dart";

class UAdminTerminalBrokersPage extends StatefulWidget {
  const UAdminTerminalBrokersPage({super.key});

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
    onFilter: _filter,
    onCreate: _form,
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

  Widget _menu(UTerminalBrokerResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UAdminForm.filter(
    title: U.s.filterItem(U.s.brokers),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UDropDownField<TagOrderBy>(
        initialValue: c.tagOrderBy.value,
        onChanged: c.tagOrderBy.call,
        items: <TagOrderBy>[TagOrderBy.createdAt, TagOrderBy.createdAtDescending].map((TagOrderBy x) => DropdownMenuItem<TagOrderBy>(value: x, child: Text(x.localizedTitle))).toList(),
      ).pSymmetric(vertical: 6),
      UAdminForm.text(c.codeFilter, U.s.code),
      UAdminForm.text(c.titleFilter, U.s.title),
    ],
  );

  Future<void> _form([UTerminalBrokerResponse? b]) async {
    c.loadForm(b);
    await UAdminForm.editDialog(
      title: b == null ? U.s.createItem(U.s.brokers) : U.s.editItem(U.s.brokers),
      formKey: c.formKey,
      maxWidth: 520,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UAdminForm.text(c.code, U.s.code, required: true),
        UAdminForm.text(c.title, U.s.title, required: true),
        UAdminForm.text(c.registrationNumber, U.s.registrationNumber, required: true),
        UAdminForm.text(c.nationalCode, U.s.nationalCode, required: true),
        UAdminForm.text(c.representative, U.s.representative, required: true),
        UAdminForm.text(c.address, U.s.address, lines: 2, required: true),
        UAdminForm.text(c.postalCode, U.s.postalCode, required: true),
        UTextFieldPhoneNumber(controller: c.phoneNumber, labelText: U.s.phoneNumber, required: true, margin: const EdgeInsets.symmetric(vertical: 6)),
        _Base64ImagePicker(label: U.s.logo, initial: c.logoBase64, onChanged: (String? v) => c.logoBase64 = v),
        UAdminForm.sectionTitle(U.s.firstSignatory),
        UAdminForm.text(c.sign1Owner, U.s.signatoryName, required: true),
        _Base64ImagePicker(label: U.s.signature, initial: c.sign1Base64, onChanged: (String? v) => c.sign1Base64 = v),
        UAdminForm.sectionTitle(U.s.secondSignatory),
        UAdminForm.text(c.sign2Owner, U.s.signatoryName),
        _Base64ImagePicker(label: U.s.signature, initial: c.sign2Base64, onChanged: (String? v) => c.sign2Base64 = v),
      ],
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
