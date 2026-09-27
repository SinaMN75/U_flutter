part of "../../u_admin.dart";

class UAdminPaymentTerminalBrandPage extends StatefulWidget {
  const UAdminPaymentTerminalBrandPage({super.key});

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.brands,
    icon: Icons.point_of_sale_rounded,
    page: () => const UAdminPaymentTerminalBrandPage(),
    roles: roles,
  );

  @override
  State<UAdminPaymentTerminalBrandPage> createState() => _UAdminPaymentTerminalBrandPageState();
}

class _UAdminPaymentTerminalBrandPageState extends State<UAdminPaymentTerminalBrandPage> {
  final UAdminPaymentTerminalBrandController c = UAdminPaymentTerminalBrandController();

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
    title: U.s.brands,
    onFilter: _filter,
    onCreate: _form,
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
      emptyText: U.s.noItemsFound(U.s.brands),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.code),
        UAdminTable.headerCell(U.s.title),
        UAdminTable.headerCell(U.s.model),
        UAdminTable.headerCell(U.s.deviceType),
        UAdminTable.headerCell(U.s.connectionType),
        UAdminTable.headerCell(U.s.createdAt),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
    ),
  );

  Widget _itemDesktop(UTerminalBrandResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.code),
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.model),
      UAdminTable.cell(UAdminPaymentTerminalBrandController.deviceTypeOf(i)?.localizedTitle ?? "---"),
      UAdminTable.cell(UAdminPaymentTerminalBrandController.connectionTypeOf(i)?.localizedTitle ?? "---"),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemMobile(UTerminalBrandResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.devices_other_rounded,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.code, i.code),
      UAdminField(U.s.model, i.model),
      UAdminField(U.s.deviceType, UAdminPaymentTerminalBrandController.deviceTypeOf(i)?.localizedTitle ?? "---"),
      UAdminField(U.s.connectionType, UAdminPaymentTerminalBrandController.connectionTypeOf(i)?.localizedTitle ?? "---"),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UTerminalBrandResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.brands),
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
      UTextField(controller: c.modelFilterController, labelText: U.s.model, margin: const EdgeInsets.symmetric(vertical: 6)),
    ],
  );

  Future<void> _form([UTerminalBrandResponse? b]) async {
    c.loadForm(b);
    await UFormDialog.show(
      title: b == null ? U.s.createItem(U.s.brands) : U.s.editItem(U.s.brands),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.codeController, labelText: U.s.code, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.titleController, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.modelController, labelText: U.s.model, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UDropDownField<TagTerminalBrand>(
          initialValue: c.deviceType,
          labelText: U.s.deviceType,
          items: UAdminPaymentTerminalBrandController.deviceTypes.map((TagTerminalBrand x) => DropdownMenuItem<TagTerminalBrand>(value: x, child: Text(x.localizedTitle))).toList(),
          onChanged: (TagTerminalBrand? v) => c.deviceType = v ?? c.deviceType,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UDropDownField<TagTerminalBrand>(
          initialValue: c.connectionType,
          labelText: U.s.connectionType,
          items: UAdminPaymentTerminalBrandController.connectionTypes.map((TagTerminalBrand x) => DropdownMenuItem<TagTerminalBrand>(value: x, child: Text(x.localizedTitle))).toList(),
          onChanged: (TagTerminalBrand? v) => c.connectionType = v ?? c.connectionType,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
      ],
    );
  }
}
