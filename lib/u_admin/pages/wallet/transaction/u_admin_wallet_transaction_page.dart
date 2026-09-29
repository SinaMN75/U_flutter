part of "../../../u_admin.dart";

class UAdminWalletTransactionPage extends StatefulWidget {
  const UAdminWalletTransactionPage({super.key});

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.transactions,
    icon: Icons.swap_horiz_rounded,
    page: () => const UAdminWalletTransactionPage(),
    roles: roles,
  );

  @override
  State<UAdminWalletTransactionPage> createState() => _UAdminWalletTransactionPageState();
}

class _UAdminWalletTransactionPageState extends State<UAdminWalletTransactionPage> {
  final UAdminWalletTransactionController c = UAdminWalletTransactionController();

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
    title: U.s.transactions,
    onFilter: _filter,
    onCreate: _form,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UTxnResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.transactions),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.amount),
        UAdminTable.headerCell(U.s.trackingNumber),
        UAdminTable.headerCell(U.s.status),
        UAdminTable.headerCell(U.s.user),
        UAdminTable.headerCell(U.s.created),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
    ),
  );

  String _statusName(UTxnResponse i) => i.tags.isEmpty ? "-" : (TagTxn.values.fromNumber(i.tags.first)?.localizedTitle ?? "-");

  Widget _itemDesktop(UTxnResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.amount.rial()),
      UAdminTable.cell(i.trackingNumber ?? "-"),
      UAdminTable.cell(_statusName(i)),
      UAdminTable.cell(i.user?.displayName ?? "-"),
      UAdminTable.cell(i.createdAt?.toJalaliDate() ?? "-"),
      _menu(i).expanded(),
    ],
  );

  Widget _itemMobile(UTxnResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.receipt_long_rounded,
    title: i.amount.rial(),
    badge: UAdminTable.statusChip(label: _statusName(i), color: Theme.of(context).colorScheme.primary),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.trackingNumber, i.trackingNumber ?? "-"),
      UAdminField(U.s.user, i.user?.displayName ?? "-"),
      UAdminField(U.s.created, i.createdAt?.toJalaliDate() ?? "-"),
    ],
  );

  Widget _menu(UTxnResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.transactions),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UDropDownField<TagTxn?>(
        initialValue: c.statusFilter,
        onChanged: (TagTxn? v) => c.statusFilter = v,
        items: <DropdownMenuItem<TagTxn?>>[
          DropdownMenuItem<TagTxn?>(child: Text(U.s.all)),
          ...TagTxn.values.map((TagTxn t) => DropdownMenuItem<TagTxn?>(value: t, child: Text(t.localizedTitle))),
        ],
      ).pSymmetric(vertical: 6),
      UTextFieldDatePicker(
        controller: c.startDateController,
        labelText: U.s.fromDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.startDate = d;
          c.startDateController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.endDateController,
        labelText: U.s.toDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.endDate = d;
          c.endDateController.text = d.toJalaliDate();
        },
      ),
    ],
  );

  Future<void> _form([UTxnResponse? t]) async {
    c.loadForm(t);
    await UFormDialog.show(
      title: t == null ? U.s.createItem(U.s.transactions) : U.s.editItem(U.s.transactions),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(
          controller: c.amountController,
          labelText: U.s.amount,
          keyboardType: TextInputType.number,
          validator: t == null ? UValidators.required(message: "") : null,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(controller: c.trackingController, labelText: U.s.trackingNumber, validator: t == null ? UValidators.required(message: "") : null, margin: const EdgeInsets.symmetric(vertical: 6)),
        UDropDownField<TagTxn>(
          initialValue: c.tag,
          onChanged: (TagTxn? v) => c.tag = v ?? c.tag,
          items: TagTxn.values.map((TagTxn x) => DropdownMenuItem<TagTxn>(value: x, child: Text(x.localizedTitle))).toList(),
        ).pSymmetric(vertical: 6),
      ],
    );
  }
}
