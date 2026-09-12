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

  void _showCreateDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController();
    final TextEditingController model = TextEditingController();

    UNavigator.dialog(
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
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.create(
                          p: UTerminalBrandCreateParams(
                            title: title.text.trim(),
                            model: model.text.trim(),
                            tags: <int>[TagTerminalBrand.test.number],
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
    ).whenComplete(() {
      title.dispose();
      model.dispose();
    });
  }

  void _showEditDialog(UTerminalBrandResponse i) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController(text: i.title);
    final TextEditingController model = TextEditingController(text: i.model);

    UNavigator.dialog(
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
    ).whenComplete(() {
      title.dispose();
      model.dispose();
    });
  }
}