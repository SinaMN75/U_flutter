import "package:u/utilities.dart";

class UAdminTransactionsPage extends StatefulWidget {
  const UAdminTransactionsPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.transactions, const UAdminTransactionsPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.transactions,
    icon: Icons.swap_horiz_rounded,
    page: () => const UAdminTransactionsPage(),
    roles: roles,
  );

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
    body: _list(),
  );

  Widget _list() => UAdminListView<UTxnResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.transactions),
    desktopHeader: () => UAdminTable.header(<String>[U.s.amount, U.s.trackingNumber, U.s.status, U.s.user, U.s.created, U.s.operations]),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
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

  Widget _itemResponsive(UTxnResponse i, int index) => UAdminTable.mobileCard(
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

  void _filter() => UAdminForm.filter(
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
      UAdminForm.date(c.controllerStartDate, U.s.fromDate, (DateTime d) => c.startDate = d),
      UAdminForm.date(c.controllerEndDate, U.s.toDate, (DateTime d) => c.endDate = d),
    ],
  );

  Future<void> _form([UTxnResponse? t]) async {
    c.loadForm(t);
    await UAdminForm.editDialog(
      title: t == null ? U.s.createItem(U.s.transactions) : U.s.editItem(U.s.transactions),
      formKey: c.formKey,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UAdminForm.text(c.amount, U.s.amount, number: true, required: t == null),
        UAdminForm.text(c.tracking, U.s.trackingNumber, required: t == null),
        UDropDownField<TagTxn>(
          initialValue: c.tag,
          onChanged: (TagTxn? v) => c.tag = v ?? c.tag,
          items: TagTxn.values.map((TagTxn x) => DropdownMenuItem<TagTxn>(value: x, child: Text(x.localizedTitle))).toList(),
        ).pSymmetric(vertical: 6),
      ],
    );
  }
}
