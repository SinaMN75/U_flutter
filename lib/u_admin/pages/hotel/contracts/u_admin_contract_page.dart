import "package:u/utilities.dart";

class UAdminContractPage extends StatefulWidget {
  const UAdminContractPage({this.bed, this.user, super.key});

  final UDormBedResponse? bed;
  final UUserResponse? user;

  @override
  State<UAdminContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<UAdminContractPage> {
  final UAdminContractController c = UAdminContractController();

  @override
  void initState() {
    c.init(bed: widget.bed, user: widget.user);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.bed != null
        ? "${U.s.contracts} · ${widget.bed!.title}"
        : widget.user != null
        ? "${U.s.contracts} · ${widget.user!.displayName}"
        : U.s.contracts,
    onFilter: _filter,
    onCreate: U.user.hasPermission(TagUser.permissionManageContracts) ? _form : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UDormBedContractResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.contracts),
      desktopBreakpoint: 900,
      desktopHeader: () => UAdminTable.header(<String>[U.s.tenant, U.s.bed, U.s.startDate, U.s.endDate, U.s.rent, U.s.status, U.s.operations]),
      desktopRow: (UDormBedContractResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          UAdminTable.cell(i.user?.displayName ?? "-"),
          UAdminTable.cell(i.bed?.title ?? widget.bed?.title ?? "-"),
          UAdminTable.cell(i.startDate.toJalaliDate()),
          UAdminTable.cell(i.endDate.toJalaliDate()),
          UAdminTable.cell(i.rent.rial()),
          _status(i).alignAtCenter().expanded(),
          _menu(i).expanded(),
        ],
      ),
      mobileRow: (UDormBedContractResponse i, int index) => UAdminTable.mobileCard(
        icon: Icons.description_rounded,
        title: i.user?.displayName ?? "-",
        badge: _status(i),
        trailing: _menu(i),
        fields: <UAdminField>[
          UAdminField(U.s.bed, i.bed?.title ?? widget.bed?.title ?? "-"),
          UAdminField(U.s.startDate, i.startDate.toJalaliDate()),
          UAdminField(U.s.endDate, i.endDate.toJalaliDate()),
          UAdminField(U.s.rent, i.rent.rial()),
          UAdminField(U.s.invoices, "${i.invoices?.length ?? 0}"),
        ],
      ),
    ),
  );

  Widget _status(UDormBedContractResponse i) => UAdminTable.statusChip(label: c.isActive(i) ? U.s.active : U.s.expired, color: c.isActive(i) ? UAdminTheme.green : UAdminTheme.red);

  String _statusLabel(UAdminContractStatusFilter f) => switch (f) {
    UAdminContractStatusFilter.all => U.s.all,
    UAdminContractStatusFilter.active => U.s.active,
    UAdminContractStatusFilter.upcoming => U.s.upcoming,
    UAdminContractStatusFilter.expired => U.s.expired,
    UAdminContractStatusFilter.expiringSoon => U.s.expiringSoon,
  };

  Widget _menu(UDormBedContractResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.tenant, icon: Icons.person_outline, visible: i.user != null, onTap: () => UAdminPageSwitcher.hotelUserDetail(user: i.user!)),
      UPopupMenuItem(label: U.s.viewItem(U.s.invoices), icon: Icons.receipt_long_outlined, onTap: () => UAdminPageSwitcher.invoices(contract: i)),
      UPopupMenuItem(label: U.s.bed, icon: Icons.bed_outlined, visible: i.bed?.room != null, onTap: () => UAdminPageSwitcher.dormBeds(room: i.bed!.room)),
      UPopupMenuItem(label: U.s.dorm, icon: Icons.bedroom_parent_outlined, visible: i.bed?.room?.dorm != null, onTap: () => UAdminPageSwitcher.dormRooms(dorm: i.bed!.room!.dorm)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageContracts]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteContracts]), onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UAdminForm.filter(
    title: U.s.filterItem(U.s.contracts),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UAdminForm.text(c.tenantFilter, U.s.tenant),
      UTextFieldAutoCompleteAsync<UDormResponse>(
        hintText: U.s.dorm,
        labelBuilder: (UDormResponse i) => i.title,
        selectedItem: c.dormFilter,
        fetchData: c.searchDorms,
        onChanged: (UDormResponse? i) => setState(() {
          c.dormFilter = i;
          c.bedFilter = null;
        }),
      ).pSymmetric(vertical: 6),
      UTextFieldAutoCompleteAsync<UDormBedResponse>(
        hintText: U.s.bed,
        labelBuilder: (UDormBedResponse i) => i.room?.dorm == null ? i.title : "${i.room!.dorm!.title} · ${i.title}",
        selectedItem: c.bedFilter,
        fetchData: c.searchBeds,
        onChanged: (UDormBedResponse? i) => setState(() => c.bedFilter = i),
      ).pSymmetric(vertical: 6),
      UDropDownField<int?>(
        labelText: U.s.contractType,
        initialValue: c.typeFilter,
        items: <DropdownMenuItem<int?>>[
          DropdownMenuItem<int?>(child: Text(U.s.all)),
          ...UAdminContractController.types.map((TagDormBedContract t) => DropdownMenuItem<int?>(value: t.number, child: Text(t.localizedTitle))),
        ],
        onChanged: (int? v) => c.typeFilter = v,
      ).pSymmetric(vertical: 6),
      UDropDownField<UAdminContractStatusFilter>(
        labelText: U.s.status,
        initialValue: c.statusFilter,
        items: UAdminContractStatusFilter.values.map((UAdminContractStatusFilter f) => DropdownMenuItem<UAdminContractStatusFilter>(value: f, child: Text(_statusLabel(f)))).toList(),
        onChanged: (UAdminContractStatusFilter? v) => c.statusFilter = v ?? UAdminContractStatusFilter.all,
      ).pSymmetric(vertical: 6),
      UAdminForm.date(c.controllerStartDate, U.s.startDate, (DateTime d) => c.startDate = d, initial: c.startDate),
      UAdminForm.date(c.controllerEndDate, U.s.endDate, (DateTime d) => c.endDate = d, initial: c.endDate),
    ],
  );

  /// Create ([p] == null) and edit share this one dialog.
  void _form([UDormBedContractResponse? p]) {
    c.loadForm(p);
    UAdminForm.editDialog(
      title: p == null ? U.s.createItem(U.s.contract) : U.s.editItem(U.s.contract),
      formKey: c.formKey,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) {
        final bool daily = c.type == TagDormBedContract.daily;
        return <Widget>[
          if (p == null && widget.bed == null)
            UTextFieldAutoCompleteAsync<UDormBedResponse>(
              hintText: U.s.bed,
              labelBuilder: (UDormBedResponse i) => "${i.title} · ${i.monthlyRent.rial()}",
              selectedItem: c.formBed,
              fetchData: c.searchBeds,
              onChanged: (UDormBedResponse? i) => c.formBed = i,
            ).pSymmetric(vertical: 6),
          if (p == null)
            UTextFieldAutoCompleteAsync<UUserResponse>(
              hintText: U.s.tenant,
              labelBuilder: (UUserResponse i) => i.phoneNumber == null ? i.displayName : "${i.displayName} · ${i.phoneNumber}",
              selectedItem: c.formUser,
              fetchData: c.searchUsers,
              onChanged: (UUserResponse? i) => c.formUser = i,
            ).pSymmetric(vertical: 6),
          UDropDownField<TagDormBedContract>(
            labelText: U.s.contractType,
            initialValue: c.type,
            items: UAdminContractController.types.map((TagDormBedContract t) => DropdownMenuItem<TagDormBedContract>(value: t, child: Text(t.localizedTitle))).toList(),
            onChanged: (TagDormBedContract? v) => setState(() => c.type = v ?? c.type),
          ).pSymmetric(vertical: 6),
          UAdminForm.date(c.startText, U.s.startDate, (DateTime d) => c.contractStart = d, initial: c.contractStart, required: true),
          UAdminForm.date(c.endText, U.s.endDate, (DateTime d) => c.contractEnd = d, initial: c.contractEnd, required: true),
          if (!daily) UAdminForm.text(c.deposit, U.s.deposit, money: true),
          // The rent is the fixed per-day price of a daily contract.
          UAdminForm.text(c.rent, daily ? U.s.dailyPrice : U.s.rent, money: true),
          // A late-payment penalty only applies to recurring monthly invoices.
          if (p == null && !daily) UAdminForm.text(c.penalty, U.s.dailyPenalty, number: true),
          UAdminForm.text(c.description, U.s.description, lines: 2),
        ];
      },
    );
  }
}
