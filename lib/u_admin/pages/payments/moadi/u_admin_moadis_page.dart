import "package:u/utilities.dart";

class UAdminMoadisPage extends StatefulWidget {
  const UAdminMoadisPage({super.key, this.user});

  final UUserResponse? user;

  @override
  State<UAdminMoadisPage> createState() => _MoadisPageState();
}

class _MoadisPageState extends State<UAdminMoadisPage> {
  final UAdminMoadiController c = UAdminMoadiController();

  @override
  void initState() {
    c.init(user: widget.user);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.taxpayerRequests,
    onFilter: _filter,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: _list(),
  );

  Widget _list() => UAdminListView<UMoadiResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.youHaveNotSubmittedAnyTaxpayerRequestYet,
    desktopHeader: () => UAdminTable.header(
      <String>[
        U.s.taxpayerName,
        U.s.economicCode,
        U.s.legalEntityType,
        U.s.pendingApproval,
        U.s.createdAt,
        U.s.operations,
      ],
    ),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _itemDesktop(UMoadiResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.name),
      UAdminTable.cell(i.economicCode),
      UAdminTable.cell(i.legalEntity),
      UAdminTable.cell(_statusLabel(i.tags)),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UMoadiResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.receipt_long_rounded,
    title: i.name,
    badge: UAdminTable.statusChip(label: _statusLabel(i.tags), color: Theme.of(context).colorScheme.primary),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.economicCode, i.economicCode),
      UAdminField(U.s.legalEntityType, i.legalEntity),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  String _statusLabel(List<int> tags) {
    if (tags.contains(TagMoadi.approved.number)) return U.s.approved;
    if (tags.contains(TagMoadi.rejected.number)) return U.s.rejected;
    return U.s.pendingApproval;
  }

  String _tagLabel(TagMoadi t) => switch (t) {
    TagMoadi.approved => U.s.approved,
    TagMoadi.rejected => U.s.rejected,
    TagMoadi.pending => U.s.pendingApproval,
  };

  Widget _menu(UMoadiResponse i) {
    final bool isPending = !i.tags.contains(TagMoadi.approved.number) && !i.tags.contains(TagMoadi.rejected.number);
    return UPopupMenu(
      items: <UPopupMenuItem>[
        UPopupMenuItem(label: U.s.approve, icon: Icons.check_circle_outline, color: UAdminTheme.green, visible: isPending, onTap: () => c.approve(i)),
        UPopupMenuItem(label: U.s.reject, icon: Icons.cancel_outlined, destructive: true, visible: isPending, onTap: () => _reject(i)),
        UPopupMenuItem(label: U.s.viewItem(U.s.details), icon: Icons.info_outline, onTap: () => _detail(i)),
        UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
      ],
    );
  }

  void _reject(UMoadiResponse i) {
    c.rejectReason.clear();
    UAdminForm.editDialog(
      title: U.s.reject,
      formKey: c.formKey,
      onSubmit: () => c.reject(i),
      children: (BuildContext context, StateSetter setState) => <Widget>[UAdminForm.text(c.rejectReason, U.s.rejectionReason, lines: 3)],
    );
  }

  void _detail(UMoadiResponse i) => UNavigator.dialog(
    AlertDialog(
      title: Text(i.name),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _kv(U.s.pendingApproval, _statusLabel(i.tags)),
              _kv(U.s.economicCode, i.economicCode),
              _kv(U.s.legalEntityType, i.legalEntity),
              _kv(U.s.uniqueTaxCode, i.uniqueTaxCode),
              _kv(U.s.nationalCode, i.nationalCode ?? "-"),
              _kv(U.s.postalCode, i.postalCode ?? "-"),
              _kv(U.s.registrationDate, i.registerDate?.toJalaliDate() ?? "-"),
              _kv(U.s.registrationNumber, i.registrationNumber ?? "-"),
              _kv(U.s.address, i.address ?? "-"),
              _kv(U.s.introductionCode, i.introductionCode ?? "-"),
              _kv(U.s.ownerName, i.ownerName),
              _kv(U.s.ownerMobile, i.ownerMobile),
              _kv(U.s.ownerNationalCode, i.ownerNationalCode),
              _kv("UUID", i.jsonData.uuid ?? "-"),
              _kv(U.s.rejectionReason, i.jsonData.rejectReason ?? "-"),
            ],
          ),
        ),
      ),
      actions: <Widget>[UButton(type: UButtonType.text, title: U.s.ok, onTap: UNavigator.back)],
    ),
  );

  Widget _kv(String k, String v) => URow(
    crossAxisAlignment: CrossAxisAlignment.start,
    margin: const EdgeInsets.symmetric(vertical: 6),
    children: <Widget>[
      SizedBox(width: 130, child: UTextBodySmall(k, color: UAdminTheme.grey)),
      Expanded(child: UTextBodyMedium(v, fontWeight: FontWeight.w500)),
    ],
  );

  void _filter() => UAdminForm.filter(
    title: U.s.taxpayerRequests,
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UTextFieldAutoCompleteAsync<UUserResponse>(
        labelBuilder: (UUserResponse i) => "${i.firstName} ${i.lastName} ${i.nationalCode}",
        onChanged: (UUserResponse? v) => c.user = v,
        selectedItem: c.user,
        fetchData: c.searchUsers,
        hintText: U.s.user,
      ).pSymmetric(vertical: 6),
      UTextFieldAutoComplete<TagMoadi?>(
        title: U.s.pendingApproval,
        items: TagMoadi.values,
        labelBuilder: (TagMoadi? i) => i == null ? "" : _tagLabel(i),
        selectedItem: c.status,
        onChanged: (TagMoadi? v) => c.status = v,
      ).pSymmetric(vertical: 6),
      UAdminForm.text(c.nameFilter, U.s.taxpayerName),
      UAdminForm.text(c.economicCodeFilter, U.s.economicCode),
      UAdminForm.text(c.nationalCodeFilter, U.s.nationalCode),
      UAdminForm.text(c.uniqueTaxCodeFilter, U.s.uniqueTaxCode),
      UAdminForm.date(c.controllerStartDate, U.s.fromDate, (DateTime d) => c.startDate = d),
      UAdminForm.date(c.controllerEndDate, U.s.toDate, (DateTime d) => c.endDate = d),
    ],
  );
}
