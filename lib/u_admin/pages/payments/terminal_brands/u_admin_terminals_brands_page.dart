part of "../../../u_admin.dart";

class UAdminTerminalBrandsPage extends StatefulWidget {
  const UAdminTerminalBrandsPage({super.key});

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
    body: _list(),
  );

  Widget _list() => UAdminListView<UTerminalBrandResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.brands),
    desktopHeader: () => UAdminTable.header(
      <String>[
        U.s.code,
        U.s.title,
        U.s.model,
        U.s.deviceType,
        U.s.connectionType,
        U.s.createdAt,
        U.s.operations,
      ],
    ),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _itemDesktop(UTerminalBrandResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.code),
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.model),
      UAdminTable.cell(UAdminTerminalBrandController.deviceTypeOf(i)?.localizedTitle ?? "---"),
      UAdminTable.cell(UAdminTerminalBrandController.connectionTypeOf(i)?.localizedTitle ?? "---"),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UTerminalBrandResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.devices_other_rounded,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.code, i.code),
      UAdminField(U.s.model, i.model),
      UAdminField(U.s.deviceType, UAdminTerminalBrandController.deviceTypeOf(i)?.localizedTitle ?? "---"),
      UAdminField(U.s.connectionType, UAdminTerminalBrandController.connectionTypeOf(i)?.localizedTitle ?? "---"),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UTerminalBrandResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UAdminForm.filter(
    title: U.s.filterItem(U.s.brands),
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
      UAdminForm.text(c.modelFilter, U.s.model),
    ],
  );

  Future<void> _form([UTerminalBrandResponse? b]) async {
    c.loadForm(b);
    await UAdminForm.editDialog(
      title: b == null ? U.s.createItem(U.s.brands) : U.s.editItem(U.s.brands),
      formKey: c.formKey,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UAdminForm.text(c.code, U.s.code, required: true),
        UAdminForm.text(c.title, U.s.title, required: true),
        UAdminForm.text(c.model, U.s.model, required: true),
        UDropDownField<TagTerminalBrand>(
          initialValue: c.deviceType,
          labelText: U.s.deviceType,
          items: UAdminTerminalBrandController.deviceTypes.map((TagTerminalBrand x) => DropdownMenuItem<TagTerminalBrand>(value: x, child: Text(x.localizedTitle))).toList(),
          onChanged: (TagTerminalBrand? v) => c.deviceType = v ?? c.deviceType,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UDropDownField<TagTerminalBrand>(
          initialValue: c.connectionType,
          labelText: U.s.connectionType,
          items: UAdminTerminalBrandController.connectionTypes.map((TagTerminalBrand x) => DropdownMenuItem<TagTerminalBrand>(value: x, child: Text(x.localizedTitle))).toList(),
          onChanged: (TagTerminalBrand? v) => c.connectionType = v ?? c.connectionType,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
      ],
    );
  }
}
