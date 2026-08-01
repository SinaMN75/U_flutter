import "package:u/utilities.dart";

class UAdminTransactionsPage extends StatefulWidget {
  const UAdminTransactionsPage({super.key});

  @override
  State<UAdminTransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<UAdminTransactionsPage> {
  final UAdminTransactionsController c = UAdminTransactionsController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.transactions,
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

  Widget _list() => UAdminListView<UTxnResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noTransactionsFound,
    desktopHeader: () => UAdminTable.header(<String>[U.s.amount, U.s.trackingNumber, U.s.status, U.s.user, U.s.created, U.s.operations]),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  String _statusName(UTxnResponse i) => i.tags.isEmpty ? "-" : (TagTxn.values.fromNumber(i.tags.first)?.localizedTitle ?? "-");

  Widget _itemDesktop(UTxnResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    children: <Widget>[
      UAdminTable.cell(i.amount.rial()),
      UAdminTable.cell(i.trackingNumber ?? "-"),
      UAdminTable.cell(_statusName(i)),
      UAdminTable.cell(i.user?.displayName ?? "-"),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UTxnResponse i, int index) => UAdminTable.mobileTile(
    context,
    index: index,
    icon: Icons.receipt_long_rounded,
    title: i.amount.rial(),
    subtitle: <Widget>[
      UTextBodySmall("${_statusName(i)} • ${i.trackingNumber ?? "-"}"),
      UTextBodySmall("${i.user?.displayName ?? "-"} • ${i.createdAt.toJalaliDate()}"),
    ],
    trailing: _menu(i),
  );

  Widget _menu(UTxnResponse i) => UAdminOps.menu<UTxnResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UTxnResponse>(onEdit: _showEditDialog, onDelete: c.delete),
    fallback: (UAdminActionContext<UTxnResponse> ctx) => <UAdminAction>[ctx.edit(), ctx.delete()],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterTransactions),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            spacing: 0,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UDropDownField<TagTxn?>(
                initialValue: c.statusFilter,
                onChanged: (TagTxn? v) => c.statusFilter = v,
                items: <DropdownMenuItem<TagTxn?>>[
                  DropdownMenuItem<TagTxn?>(child: Text(U.s.all)),
                  ...TagTxn.values.map((TagTxn t) => DropdownMenuItem<TagTxn?>(value: t, child: Text(t.localizedTitle))),
                ],
              ),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.fromCreatedController,
                labelText: U.s.fromDate,
                onChange: (DateTime d, Jalali j) {
                  c.fromCreatedController.text = j.formatCompactDate();
                  c.fromCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.toCreatedController,
                labelText: U.s.toDate,
                onChange: (DateTime d, Jalali j) {
                  c.toCreatedController.text = j.formatCompactDate();
                  c.toCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
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
    final TextEditingController amount = TextEditingController();
    final TextEditingController tracking = TextEditingController();
    final Rx<TagTxn> tag = TagTxn.pending.obs;
    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.createTransaction),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                spacing: 0,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: amount,
                    labelText: U.s.amount,
                    keyboardType: TextInputType.number,
                    validator: UValidators.required(message: U.s.required),
                  ).pSymmetric(vertical: 6),
                  UTextField(
                    controller: tracking,
                    labelText: U.s.trackingNumber,
                    validator: UValidators.required(message: U.s.required),
                  ).pSymmetric(vertical: 6),
                  UDropDownField<TagTxn?>(
                    initialValue: tag.value,
                    onChanged: (TagTxn? v) => tag.value = v ?? tag.value,
                    items: TagTxn.values.map((TagTxn t) => DropdownMenuItem<TagTxn?>(value: t, child: Text(t.localizedTitle))).toList(),
                  ),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.create(amount: amount.text.trim().toDouble(), trackingNumber: tracking.text.trim(), tag: tag.value.number);
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

  void _showEditDialog(UTxnResponse i) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController amount = TextEditingController(text: i.amount.toInt().toString());
    final TextEditingController tracking = TextEditingController(text: i.trackingNumber);
    final Rx<TagTxn> tag = (TagTxn.values.fromNumber(i.tags.isEmpty ? TagTxn.pending.number : i.tags.first) ?? TagTxn.pending).obs;
    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.editTransaction),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                spacing: 0,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(controller: amount, labelText: U.s.amount, keyboardType: TextInputType.number).pSymmetric(vertical: 6),
                  UTextField(controller: tracking, labelText: U.s.trackingNumber).pSymmetric(vertical: 6),
                  UDropDownField<TagTxn?>(
                    initialValue: tag.value,
                    onChanged: (TagTxn? v) => tag.value = v ?? tag.value,
                    items: TagTxn.values.map((TagTxn t) => DropdownMenuItem<TagTxn?>(value: t, child: Text(t.localizedTitle))).toList(),
                  ),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.update(
                          id: i.id,
                          amount: amount.text.nullIfEmpty() == null ? null : amount.text.trim().toDouble(),
                          trackingNumber: tracking.text.nullIfEmpty(),
                          tags: <int>[tag.value.number],
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
