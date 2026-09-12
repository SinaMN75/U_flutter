import "package:u/utilities.dart";

class UAdminAgreementTemplatesPage extends StatefulWidget {
  const UAdminAgreementTemplatesPage({super.key, this.actions});

  final UAdminActionBuilder<UAgreementTemplateResponse>? actions;

  @override
  State<UAdminAgreementTemplatesPage> createState() => _AgreementTemplatesPageState();
}

class _AgreementTemplatesPageState extends State<UAdminAgreementTemplatesPage> {
  final UAdminAgreementTemplateController c = UAdminAgreementTemplateController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.agreementTemplatesManagement,
    onFilter: _showFilterDialog,
    onCreate: _showEditDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UAgreementTemplateResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.agreementTemplates),
      desktopHeader: () => UAdminTable.header(<String>[
        U.s.title,
        U.s.code,
        U.s.blocks,
        U.s.createdAt,
        U.s.operations,
      ]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  Widget _itemDesktop(UAgreementTemplateResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.code),
      UAdminTable.cell(i.jsonData.blocks.length.toString()),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UAgreementTemplateResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.description_outlined,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.code, i.code),
      UAdminField(U.s.blocks, i.jsonData.blocks.length.toString()),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UAgreementTemplateResponse i) => UAdminOps.menu<UAgreementTemplateResponse>(
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UAgreementTemplateResponse>(
      onEdit: (UAgreementTemplateResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UAgreementTemplateResponse> ctx) => <UAdminAction>[ctx.edit(), ctx.delete()],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.agreementTemplates)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.titleFilter, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
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

  Future<void> _showEditDialog({UAgreementTemplateResponse? p}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController code = TextEditingController(text: p?.code);
    final TextEditingController headerTitle = TextEditingController(text: p?.jsonData.headerTitle);
    final List<UAgreementTemplateBlock> sourceBlocks = <UAgreementTemplateBlock>[...(p?.jsonData.blocks ?? <UAgreementTemplateBlock>[])]
      ..sort((UAgreementTemplateBlock a, UAgreementTemplateBlock b) => a.order.compareTo(b.order));
    final List<_BlockForm> blocks = sourceBlocks.map(_BlockForm.fromModel).toList();

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createItem(U.s.agreementTemplate) : U.s.editItem(U.s.agreementTemplate)),
          content: SizedBox(
            width: context.dialogWidth(max: 640),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(controller: title, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: code, labelText: U.s.code, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: headerTitle, labelText: U.s.headerTitle, margin: const EdgeInsets.symmetric(vertical: 6)),
                    URow(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        UTextBodyLarge(U.s.blocks),
                        TextButton.icon(
                          onPressed: () => setDialogState(() => blocks.add(_BlockForm())),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(U.s.addItem(U.s.block)),
                        ),
                      ],
                    ),
                    ...blocks.mapIndexed(
                      (int index, _BlockForm e) => _blockCard(
                        index: index,
                        e: e,
                        onRemove: () => setDialogState(() => blocks.removeAt(index)),
                        onMoveUp: index == 0 ? null : () => setDialogState(() => blocks.insert(index - 1, blocks.removeAt(index))),
                        onMoveDown: index == blocks.length - 1 ? null : () => setDialogState(() => blocks.insert(index + 1, blocks.removeAt(index))),
                        onTypeChanged: (TagAgreementBlock v) => setDialogState(() => e.type = v),
                      ),
                    ),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          final List<UAgreementTemplateBlock> models = blocks
                              .mapIndexed(
                                (int index, _BlockForm e) => UAgreementTemplateBlock(type: e.type.number, text: e.text.text, order: index),
                              )
                              .toList();

                          if (p == null) {
                            c.create(
                              p: UAgreementTemplateCreateParams(
                                tags: <int>[TagAgreementTemplate.terminal.number],
                                title: title.text,
                                code: code.text,
                                headerTitle: headerTitle.text.nullIfEmpty(),
                                blocks: models,
                              ),
                            );
                          } else {
                            c.update(
                              p: UAgreementTemplateUpdateParams(
                                id: p.id,
                                title: title.text,
                                code: code.text,
                                headerTitle: headerTitle.text,
                                blocks: models,
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

  Widget _blockCard({
    required int index,
    required _BlockForm e,
    required VoidCallback onRemove,
    required ValueChanged<TagAgreementBlock> onTypeChanged,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
  }) => UContainer(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 6),
    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
    radius: 12,
    child: UColumn(
      children: <Widget>[
        URow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            UTextBodyMedium("${U.s.block} ${index + 1}"),
            URow(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(onPressed: onMoveUp, icon: const Icon(Icons.arrow_upward, size: 18)),
                IconButton(onPressed: onMoveDown, icon: const Icon(Icons.arrow_downward, size: 18)),
                IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, size: 18)),
              ],
            ),
          ],
        ),
        UDropDownField<TagAgreementBlock>(
          initialValue: e.type,
          labelText: U.s.type,
          items: TagAgreementBlock.values
              .map((TagAgreementBlock x) => DropdownMenuItem<TagAgreementBlock>(value: x, child: Text(x.localizedTitle)))
              .toList(),
          onChanged: (TagAgreementBlock? v) => onTypeChanged(v ?? TagAgreementBlock.clause),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        if (e.type != TagAgreementBlock.pageBreak)
          UTextField(controller: e.text, labelText: U.s.text, lines: 4, margin: const EdgeInsets.symmetric(vertical: 6)),
      ],
    ),
  );
}

class _BlockForm {
  _BlockForm({String? text, this.type = TagAgreementBlock.clause}) : text = TextEditingController(text: text);

  factory _BlockForm.fromModel(UAgreementTemplateBlock m) => _BlockForm(
    text: m.text,
    type: TagAgreementBlock.values.firstWhereOrNull((TagAgreementBlock x) => x.number == m.type) ?? TagAgreementBlock.clause,
  );

  final TextEditingController text;
  TagAgreementBlock type;
}
