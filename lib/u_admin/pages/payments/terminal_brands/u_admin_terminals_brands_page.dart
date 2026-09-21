part of "../../../u_admin.dart";

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
  void dispose() {
    c.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.brands,
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

  Widget _list() => UAdminListView<UTerminalBrandResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.brands),
    desktopHeader: () => UAdminTable.header(
      <String>[
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
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.model),
      UAdminTable.cell(_deviceTypeOf(i)?.localizedTitle ?? "---"),
      UAdminTable.cell(_connectionTypeOf(i)?.localizedTitle ?? "---"),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UTerminalBrandResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.devices_other_rounded,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.model, i.model),
      UAdminField(U.s.deviceType, _deviceTypeOf(i)?.localizedTitle ?? "---"),
      UAdminField(U.s.connectionType, _connectionTypeOf(i)?.localizedTitle ?? "---"),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UTerminalBrandResponse i) => UAdminOps.menu<UTerminalBrandResponse>(
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UTerminalBrandResponse>(
      onEdit: _showEditDialog,
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UTerminalBrandResponse> ctx) => <UAdminAction>[
      ctx.edit(),
      ctx.delete(),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.brands)),
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
                controller: c.titleFilter,
                labelText: U.s.title,
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
              UTextField(
                controller: c.modelFilter,
                labelText: U.s.model,
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

  static const List<TagTerminalBrand> _deviceTypes = <TagTerminalBrand>[
    TagTerminalBrand.atm,
    TagTerminalBrand.wallCashless,
    TagTerminalBrand.deskCashless,
  ];

  static const List<TagTerminalBrand> _connectionTypes = <TagTerminalBrand>[TagTerminalBrand.simCard, TagTerminalBrand.wifi];

  TagTerminalBrand? _deviceTypeOf(UTerminalBrandResponse i) => _deviceTypes.firstWhereOrNull((TagTerminalBrand x) => i.tags.contains(x.number));

  TagTerminalBrand? _connectionTypeOf(UTerminalBrandResponse i) => _connectionTypes.firstWhereOrNull((TagTerminalBrand x) => i.tags.contains(x.number));

  void _showCreateDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final UAdminFields f = UAdminFields();
    final TextEditingController titleController = f.text();
    final TextEditingController modelController = f.text();
    final URx<TagTerminalBrand> deviceType = TagTerminalBrand.wallCashless.obs;
    final URx<TagTerminalBrand> connectionType = TagTerminalBrand.simCard.obs;

    UNavigator.dialog(f.scope(
      AlertDialog(
        title: Text(U.s.createItem(U.s.brands)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: titleController,
                    labelText: U.s.title,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: modelController,
                    labelText: U.s.model,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UObx(
                    () => UDropDownField<TagTerminalBrand>(
                      initialValue: deviceType.value,
                      labelText: U.s.deviceType,
                      items: _deviceTypes
                          .map((TagTerminalBrand x) => DropdownMenuItem<TagTerminalBrand>(value: x, child: Text(x.localizedTitle)))
                          .toList(),
                      onChanged: deviceType.call,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                  UObx(
                    () => UDropDownField<TagTerminalBrand>(
                      initialValue: connectionType.value,
                      labelText: U.s.connectionType,
                      items: _connectionTypes
                          .map((TagTerminalBrand x) => DropdownMenuItem<TagTerminalBrand>(value: x, child: Text(x.localizedTitle)))
                          .toList(),
                      onChanged: connectionType.call,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.create(
                          p: UTerminalBrandCreateParams(
                            title: titleController.text.trim(),
                            model: modelController.text.trim(),
                            tags: <int>[deviceType.value.number, connectionType.value.number],
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
      )),
    );
  }

  void _showEditDialog(UTerminalBrandResponse i) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final UAdminFields f = UAdminFields();
    final TextEditingController title = f.text(i.title);
    final TextEditingController model = f.text(i.model);
    final URx<TagTerminalBrand> deviceType = (_deviceTypeOf(i) ?? TagTerminalBrand.wallCashless).obs;
    final URx<TagTerminalBrand> connectionType = (_connectionTypeOf(i) ?? TagTerminalBrand.simCard).obs;

    UNavigator.dialog(f.scope(
      AlertDialog(
        title: Text(U.s.editItem(U.s.brands)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: title,
                    labelText: U.s.title,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: model,
                    labelText: U.s.model,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UObx(
                    () => UDropDownField<TagTerminalBrand>(
                      initialValue: deviceType.value,
                      labelText: U.s.deviceType,
                      items: _deviceTypes
                          .map((TagTerminalBrand x) => DropdownMenuItem<TagTerminalBrand>(value: x, child: Text(x.localizedTitle)))
                          .toList(),
                      onChanged: deviceType.call,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                  UObx(
                    () => UDropDownField<TagTerminalBrand>(
                      initialValue: connectionType.value,
                      labelText: U.s.connectionType,
                      items: _connectionTypes
                          .map((TagTerminalBrand x) => DropdownMenuItem<TagTerminalBrand>(value: x, child: Text(x.localizedTitle)))
                          .toList(),
                      onChanged: connectionType.call,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.update(
                          p: UTerminalBrandUpdateParams(
                            id: i.id,
                            title: title.text.nullIfEmpty(),
                            model: model.text.nullIfEmpty(),
                            tags: <int>[deviceType.value.number, connectionType.value.number],
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
      )),
    );
  }
}
