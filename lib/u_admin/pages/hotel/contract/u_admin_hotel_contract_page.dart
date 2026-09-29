part of "../../../u_admin.dart";

class UAdminHotelContractPage extends StatefulWidget {
  const UAdminHotelContractPage({this.bed, this.user, super.key});

  static UAdminModule module({List<TagUser>? roles, UDormBedResponse? bed, UUserResponse? user}) => UAdminModule(
    title: bed != null ? "${U.s.contracts} · ${bed.title}" : user != null ? "${U.s.contracts} · ${user.displayName}" : U.s.contracts,
    icon: Icons.description_rounded,
    page: () => UAdminHotelContractPage(bed: bed, user: user),
    roles: roles,
  );

  final UDormBedResponse? bed;
  final UUserResponse? user;

  @override
  State<UAdminHotelContractPage> createState() => _UAdminHotelContractPageState();
}

class _UAdminHotelContractPageState extends State<UAdminHotelContractPage> {
  final UAdminHotelContractController c = UAdminHotelContractController();

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
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.tenant),
        UAdminTable.headerCell(U.s.bed),
        UAdminTable.headerCell(U.s.startDate),
        UAdminTable.headerCell(U.s.endDate),
        UAdminTable.headerCell(U.s.rent),
        UAdminTable.headerCell(U.s.status),
        UAdminTable.headerCell(U.s.operations),
      ],
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

  Widget _menu(UDormBedContractResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.tenant, icon: Icons.person_outline, visible: i.user != null, onTap: () => UAdminHotelUserPage.module(user: i.user).open()),
      UPopupMenuItem(label: U.s.viewItem(U.s.invoices), icon: Icons.receipt_long_outlined, onTap: () => UAdminHotelInvoicePage.module(contract: i).open()),
      UPopupMenuItem(label: U.s.bed, icon: Icons.bed_outlined, visible: i.bed?.room != null, onTap: () => UAdminHotelDormBedPage.module(room: i.bed!.room).open()),
      UPopupMenuItem(label: U.s.dorm, icon: Icons.bedroom_parent_outlined, visible: i.bed?.room?.dorm != null, onTap: () => UAdminHotelDormRoomPage.module(dorm: i.bed!.room!.dorm).open()),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageContracts]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteContracts]), onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.contracts),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UTextField(controller: c.tenantFilterController, labelText: U.s.tenant, margin: const EdgeInsets.symmetric(vertical: 6)),
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
          ...UAdminHotelContractController.types.map((TagDormBedContract t) => DropdownMenuItem<int?>(value: t.number, child: Text(t.localizedTitle))),
        ],
        onChanged: (int? v) => c.typeFilter = v,
      ).pSymmetric(vertical: 6),
      UDropDownField<UAdminHotelContractStatusFilter>(
        labelText: U.s.status,
        initialValue: c.statusFilter,
        items: UAdminHotelContractStatusFilter.values
            .map(
              (UAdminHotelContractStatusFilter f) => DropdownMenuItem<UAdminHotelContractStatusFilter>(
                value: f,
                child: Text(switch (f) {
                UAdminHotelContractStatusFilter.all => U.s.all,
                UAdminHotelContractStatusFilter.active => U.s.active,
                UAdminHotelContractStatusFilter.upcoming => U.s.upcoming,
                UAdminHotelContractStatusFilter.expired => U.s.expired,
                UAdminHotelContractStatusFilter.expiringSoon => U.s.expiringSoon,
                
                }),
              ),
            )
            .toList(),
        onChanged: (UAdminHotelContractStatusFilter? v) => c.statusFilter = v ?? UAdminHotelContractStatusFilter.all,
      ).pSymmetric(vertical: 6),
      UTextFieldDatePicker(
        controller: c.startDateController,
        labelText: U.s.startDate,
        jalali: true,
        initialDate: c.startDate,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.startDate = d;
          c.startDateController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.endDateController,
        labelText: U.s.endDate,
        jalali: true,
        initialDate: c.endDate,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.endDate = d;
          c.endDateController.text = d.toJalaliDate();
        },
      ),
    ],
  );

  /// Create ([p] == null) and edit share this one dialog.
  void _form([UDormBedContractResponse? p]) {
    c.loadForm(p);
    UFormDialog.show(
      title: p == null ? U.s.createItem(U.s.contract) : U.s.editItem(U.s.contract),
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
            items: UAdminHotelContractController.types.map((TagDormBedContract t) => DropdownMenuItem<TagDormBedContract>(value: t, child: Text(t.localizedTitle))).toList(),
            onChanged: (TagDormBedContract? v) => setState(() => c.type = v ?? c.type),
          ).pSymmetric(vertical: 6),
          UTextFieldDatePicker(
            controller: c.contractStartController,
            labelText: U.s.startDate,
            jalali: true,
            initialDate: c.contractStart,
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
            onChange: (DateTime d, UJalali j) {
              c.contractStart = d;
              c.contractStartController.text = d.toJalaliDate();
            },
          ),
          UTextFieldDatePicker(
            controller: c.contractEndController,
            labelText: U.s.endDate,
            jalali: true,
            initialDate: c.contractEnd,
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
            onChange: (DateTime d, UJalali j) {
              c.contractEnd = d;
              c.contractEndController.text = d.toJalaliDate();
            },
          ),
          if (!daily)
            UTextField(
              controller: c.depositController,
              labelText: U.s.deposit,
              keyboardType: TextInputType.number,
              formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
              margin: const EdgeInsets.symmetric(vertical: 6),
            ),
          // The rent is the fixed per-day price of a daily contract.
          UTextField(
            controller: c.rentController,
            labelText: daily ? U.s.dailyPrice : U.s.rent,
            keyboardType: TextInputType.number,
            formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          // A late-payment penalty only applies to recurring monthly invoices.
          if (p == null && !daily) UTextField(controller: c.penaltyController, labelText: U.s.dailyPenalty, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.descriptionController, labelText: U.s.description, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
        ];
      },
    );
  }
}
