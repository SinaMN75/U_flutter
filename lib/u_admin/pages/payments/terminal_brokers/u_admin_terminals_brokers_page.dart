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
        U.s.title,
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
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UTerminalBrokerResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.business_center_outlined,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
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
    AlertDialog(
      title: Text(U.s.filterItem(U.s.brokers)),
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
    String sign1Base64 = "";
    String sign2Base64 = "";
    final TextEditingController sign1Owner = TextEditingController();
    final TextEditingController sign2Owner = TextEditingController();

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.createItem(U.s.brokers)),
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
                    controller: sign1Owner,
                    labelText: "Sign 1 Owner",
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UFilePicker(
                    allowMultipleSelection: false,
                    fileType: FileType.image,
                    onFilesChanged: (List<FileData> i) => sign1Base64 = i.first.bytes!.toBase64(),
                  ).pSymmetric(vertical: 6),
                  UTextField(
                    controller: sign2Owner,
                    labelText: "Sign 2 Owner",
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UFilePicker(
                    allowMultipleSelection: false,
                    fileType: FileType.image,
                    onFilesChanged: (List<FileData> i) => sign2Base64 = i.first.bytes!.toBase64(),
                  ).pSymmetric(vertical: 6),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.create(
                          p: UTerminalBrokerCreateParams(
                            title: title.text.trim(),
                            sign1Base64: sign1Base64.nullIfEmpty(),
                            sign1Owner: sign1Owner.text.nullIfEmpty(),
                            sign2Base64: sign2Base64.nullIfEmpty(),
                            sign2Owner: sign2Owner.text.nullIfEmpty(),
                            tags: <int>[TagTerminalBroker.test.number],
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

  void _showEditDialog(UTerminalBrokerResponse i) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController(text: i.title);
    String sign1Base64 = "";
    String sign2Base64 = "";
    final TextEditingController sign1Owner = TextEditingController();
    final TextEditingController sign2Owner = TextEditingController();

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.editItem(U.s.brokers)),
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
                    controller: sign1Owner,
                    labelText: "Sign 1 Owner",
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UFilePicker(
                    allowMultipleSelection: false,
                    fileType: FileType.image,
                    onFilesChanged: (List<FileData> i) => sign1Base64 = i.first.bytes!.toBase64(),
                  ).pSymmetric(vertical: 6),
                  UTextField(
                    controller: sign2Owner,
                    labelText: "Sign 2 Owner",
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UFilePicker(
                    allowMultipleSelection: false,
                    fileType: FileType.image,
                    onFilesChanged: (List<FileData> i) => sign2Base64 = i.first.bytes!.toBase64(),
                  ).pSymmetric(vertical: 6),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.update(
                          p: UTerminalBrokerUpdateParams(
                            id: i.id,
                            title: title.text.nullIfEmpty(),
                            sign1Base64: sign1Base64.nullIfEmpty(),
                            sign1Owner: sign1Owner.text.nullIfEmpty(),
                            sign2Base64: sign2Base64.nullIfEmpty(),
                            sign2Owner: sign2Owner.text.nullIfEmpty(),
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
}
