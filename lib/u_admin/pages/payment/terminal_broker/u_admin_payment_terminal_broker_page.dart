part of "../../../u_admin.dart";

class UAdminPaymentTerminalBrokerPage extends StatefulWidget {
  const UAdminPaymentTerminalBrokerPage({super.key});

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.brokers,
    icon: Icons.point_of_sale_rounded,
    page: () => const UAdminPaymentTerminalBrokerPage(),
    roles: roles,
  );

  @override
  State<UAdminPaymentTerminalBrokerPage> createState() => _UAdminPaymentTerminalBrokerPageState();
}

class _UAdminPaymentTerminalBrokerPageState extends State<UAdminPaymentTerminalBrokerPage> {
  final UAdminPaymentTerminalBrokerController c = UAdminPaymentTerminalBrokerController();

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
    body: UAdminListView<UTerminalBrokerResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.brokers),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.logo),
        UAdminTable.headerCell(U.s.code),
        UAdminTable.headerCell(U.s.title),
        UAdminTable.headerCell(U.s.representative),
        UAdminTable.headerCell(U.s.phoneNumber),
        UAdminTable.headerCell(U.s.createdAt),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
    ),
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

  Widget _itemMobile(UTerminalBrokerResponse i, int index) => UAdminTable.mobileCard(
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

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.brokers),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UDropDownField<TagOrderBy>(
        initialValue: c.tagOrderBy.value,
        onChanged: c.tagOrderBy.call,
        items: <TagOrderBy>[TagOrderBy.createdAt, TagOrderBy.createdAtDescending].map((TagOrderBy x) => DropdownMenuItem<TagOrderBy>(value: x, child: Text(x.localizedTitle))).toList(),
      ).pSymmetric(vertical: 6),
      UTextField(controller: c.codeFilterController, labelText: U.s.code, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.titleFilterController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
    ],
  );

  Future<void> _form([UTerminalBrokerResponse? b]) async {
    c.loadForm(b);
    await UFormDialog.show(
      title: b == null ? U.s.createItem(U.s.brokers) : U.s.editItem(U.s.brokers),
      maxWidth: 520,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.codeController, labelText: U.s.code, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.titleController, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.registrationNumberController, labelText: U.s.registrationNumber, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.nationalCodeController, labelText: U.s.nationalCode, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.representativeController, labelText: U.s.representative, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.addressController, labelText: U.s.address, lines: 2, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.postalCodeController, labelText: U.s.postalCode, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.phoneNumberController, labelText: U.s.phoneNumber, required: true, margin: const EdgeInsets.symmetric(vertical: 6)),
        UBase64ImagePicker(label: U.s.logo, initial: c.logoBase64, onChanged: (String? v) => c.logoBase64 = v),
        const Divider(height: 20),
        UTextBodySmall(U.s.firstSignatory, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTextField(controller: c.sign1OwnerController, labelText: U.s.signatoryName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UBase64ImagePicker(label: U.s.signature, initial: c.sign1Base64, onChanged: (String? v) => c.sign1Base64 = v),
        const Divider(height: 20),
        UTextBodySmall(U.s.secondSignatory, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTextField(controller: c.sign2OwnerController, labelText: U.s.signatoryName, margin: const EdgeInsets.symmetric(vertical: 6)),
        UBase64ImagePicker(label: U.s.signature, initial: c.sign2Base64, onChanged: (String? v) => c.sign2Base64 = v),
      ],
    );
  }
}
