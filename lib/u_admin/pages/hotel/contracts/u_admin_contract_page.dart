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

  // only two contract kinds are supported: monthly (rent + deposit) and daily (single invoice, no deposit)
  static const List<TagDormBedContract> _types = <TagDormBedContract>[TagDormBedContract.monthly, TagDormBedContract.daily];

  TagDormBedContract? _typeOf(UDormBedContractResponse i) {
    for (final TagDormBedContract t in _types) {
      if (i.tags.contains(t.number)) return t;
    }
    return null;
  }

  @override
  void initState() {
    c.init(bed: widget.bed, user: widget.user);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.bed != null
        ? "${U.s.contracts} · ${widget.bed!.title}"
        : widget.user != null
        ? "${U.s.contracts} · ${widget.user!.displayName}"
        : U.s.contracts,
    onFilter: _showFilterDialog,
    onCreate: U.user.hasPermission(TagUser.permissionManageContracts) ? _showEditDialog : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: _list(),
  );

  String _statusLabel(UAdminContractStatusFilter f) {
    switch (f) {
      case UAdminContractStatusFilter.all:
        return U.s.all;
      case UAdminContractStatusFilter.active:
        return U.s.active;
      case UAdminContractStatusFilter.upcoming:
        return U.s.upcoming;
      case UAdminContractStatusFilter.expired:
        return U.s.expired;
      case UAdminContractStatusFilter.expiringSoon:
        return U.s.expiringSoon;
    }
  }

  Widget _list() => UAdminListView<UDormBedContractResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.contracts),
    desktopBreakpoint: 900,
    desktopHeader: () => UAdminTable.header(<String>[U.s.tenant, U.s.bed, U.s.startDate, U.s.endDate, U.s.rent, U.s.status, U.s.operations]),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _statusChip(UDormBedContractResponse i) {
    final DateTime now = DateTime.now();
    final bool active = !i.startDate.isAfter(now) && !i.endDate.isBefore(now);
    final Color color = active ? UAdminTheme.green : UAdminTheme.red;
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      radius: 20,
      color: color.withValues(alpha: 0.15),
      child: UTextBodySmall(active ? U.s.active : U.s.expired, color: color),
    );
  }

  String _bedLabel(UDormBedContractResponse i) => i.bed?.title ?? widget.bed?.title ?? "-";

  String _tenantLabel(UDormBedContractResponse i) => i.user?.displayName ?? "-";

  Widget _itemDesktop(UDormBedContractResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(_tenantLabel(i)),
      UAdminTable.cell(_bedLabel(i)),
      UAdminTable.cell(i.startDate.toJalaliDate()),
      UAdminTable.cell(i.endDate.toJalaliDate()),
      UAdminTable.cell(i.rent.rial()),
      Center(child: _statusChip(i)).expanded(),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UDormBedContractResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.description_rounded,
    title: _tenantLabel(i),
    badge: _statusChip(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.bed, _bedLabel(i)),
      UAdminField(U.s.startDate, i.startDate.toJalaliDate()),
      UAdminField(U.s.endDate, i.endDate.toJalaliDate()),
      UAdminField(U.s.rent, i.rent.rial()),
      UAdminField(U.s.invoices, "${i.invoices?.length ?? 0}"),
    ],
  );

  Widget _menu(UDormBedContractResponse i) => UAdminOps.menu<UDormBedContractResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UDormBedContractResponse>(
      onEdit: (UDormBedContractResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
      extras: <String, void Function(UDormBedContractResponse)>{
        "tenant": (UDormBedContractResponse x) {
          if (x.user != null) UAdminPageSwitcher.hotelUserDetail(user: x.user!);
        },
        "invoices": (UDormBedContractResponse x) => UAdminPageSwitcher.invoices(contract: x),
        "payLinks": (UDormBedContractResponse x) => UAdminPayLink.dormBedInvoiceList(x, onClosed: c.read),
        "bed": (UDormBedContractResponse x) {
          if (x.bed?.room != null) UAdminPageSwitcher.dormBeds(room: x.bed!.room);
        },
        "dorm": (UDormBedContractResponse x) {
          if (x.bed?.room?.dorm != null) UAdminPageSwitcher.dormRooms(dorm: x.bed!.room!.dorm);
        },
      },
    ),
    fallback: (UAdminActionContext<UDormBedContractResponse> ctx) => <UAdminAction>[
      ctx.extra("tenant", label: U.s.tenant, icon: Icons.person_outline, visible: ctx.item.user != null),
      ctx.extra("invoices", label: U.s.viewItem(U.s.invoices), icon: Icons.receipt_long_outlined),
      ctx.extra("payLinks", label: "${U.s.payment} ${U.s.link}", icon: Icons.link_rounded, visible: ctx.item.invoices?.isNotEmpty ?? false, roles: <TagUser>[TagUser.permissionPayInvoices]),
      ctx.extra("bed", label: U.s.bed, icon: Icons.bed_outlined, visible: ctx.item.bed?.room != null),
      ctx.extra("dorm", label: U.s.dorm, icon: Icons.bedroom_parent_outlined, visible: ctx.item.bed?.room?.dorm != null),
      ctx.edit(roles: <TagUser>[TagUser.permissionManageContracts]),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteContracts]),
    ],
  );

  void _showFilterDialog() {
    final TextEditingController startCtrl = TextEditingController(text: c.startDateFilter?.toJalaliDate());
    final TextEditingController endCtrl = TextEditingController(text: c.endDateFilter?.toJalaliDate());

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.filterItem(U.s.contracts)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setLocal) => UColumn(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextField(controller: c.tenantFilter, labelText: U.s.tenant).pSymmetric(vertical: 6),
                UTextFieldAutoCompleteAsync<UDormResponse>(
                  labelBuilder: (UDormResponse i) => i.title,
                  onChanged: (UDormResponse? i) => setLocal(() {
                    c.dormFilter = i;
                    c.bedFilter = null;
                  }),
                  selectedItem: c.dormFilter,
                  fetchData: c.readDorms,
                  hintText: U.s.dorm,
                ).pSymmetric(vertical: 6),
                UTextFieldAutoCompleteAsync<UDormBedResponse>(
                  labelBuilder: (UDormBedResponse i) => i.room?.dorm == null ? i.title : "${i.room!.dorm!.title} · ${i.title}",
                  onChanged: (UDormBedResponse? i) => setLocal(() => c.bedFilter = i),
                  selectedItem: c.bedFilter,
                  fetchData: c.readBeds,
                  hintText: U.s.bed,
                ).pSymmetric(vertical: 6),
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: c.typeFilter,
                  decoration: InputDecoration(labelText: U.s.contractType, border: const OutlineInputBorder()),
                  items: <DropdownMenuItem<int?>>[
                    DropdownMenuItem<int?>(child: Text(U.s.all)),
                    ..._types.map((TagDormBedContract t) => DropdownMenuItem<int?>(value: t.number, child: Text(c.isFa ? t.titleFa : t.titleEn))),
                  ],
                  onChanged: (int? v) => setLocal(() => c.typeFilter = v),
                ).pSymmetric(vertical: 6),
                DropdownButtonFormField<UAdminContractStatusFilter>(
                  isExpanded: true,
                  initialValue: c.statusFilter,
                  decoration: InputDecoration(labelText: U.s.status, border: const OutlineInputBorder()),
                  items: UAdminContractStatusFilter.values.map((UAdminContractStatusFilter f) => DropdownMenuItem<UAdminContractStatusFilter>(value: f, child: Text(_statusLabel(f)))).toList(),
                  onChanged: (UAdminContractStatusFilter? v) => setLocal(() => c.statusFilter = v ?? UAdminContractStatusFilter.all),
                ).pSymmetric(vertical: 6),
                UTextFieldDatePicker(
                  controller: startCtrl,
                  labelText: U.s.startDate,
                  jalali: true,
                  initialDate: c.startDateFilter,
                  onChange: (DateTime d, Jalali j) {
                    c.startDateFilter = d;
                    startCtrl.text = d.toJalaliDate();
                  },
                ).pSymmetric(vertical: 6),
                UTextFieldDatePicker(
                  controller: endCtrl,
                  labelText: U.s.endDate,
                  jalali: true,
                  initialDate: c.endDateFilter,
                  onChange: (DateTime d, Jalali j) {
                    c.endDateFilter = d;
                    endCtrl.text = d.toJalaliDate();
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
        )),
      ),
    );
  }

  void _showEditDialog({UDormBedContractResponse? p}) {
    final bool isEdit = p != null;
    final TextEditingController deposit = TextEditingController(text: p?.deposit.toInt().toString());
    final TextEditingController rent = TextEditingController(text: p?.rent.toInt().toString());
    final TextEditingController penalty = TextEditingController();
    final TextEditingController description = TextEditingController(text: p?.jsonData.description);
    final TextEditingController startCtrl = TextEditingController(text: p?.startDate.toJalaliDate());
    final TextEditingController endCtrl = TextEditingController(text: p?.endDate.toJalaliDate());

    final Rxn<UDormBedResponse> bed = Rxn<UDormBedResponse>();
    final Rxn<UUserResponse> user = Rxn<UUserResponse>();
    DateTime? startDate = p?.startDate;
    DateTime? endDate = p?.endDate;
    TagDormBedContract type = _typeOf(p ?? _empty()) ?? TagDormBedContract.monthly;

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    UNavigator.dialog(
      AlertDialog(
        title: Text(isEdit ? U.s.editItem(U.s.contract) : U.s.createItem(U.s.contract)),
        content: SizedBox(
          width: context.dialogWidth(max: 480),
          child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setLocal) => Form(
              key: formKey,
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (!isEdit && widget.bed == null)
                    UTextFieldAutoCompleteAsync<UDormBedResponse>(
                      labelBuilder: (UDormBedResponse i) => "${i.title} · ${i.monthlyRent.rial()}",
                      onChanged: bed.call,
                      selectedItem: bed.value,
                      fetchData: c.readBeds,
                      hintText: U.s.bed,
                    ).pSymmetric(vertical: 6),
                  if (!isEdit)
                    UTextFieldAutoCompleteAsync<UUserResponse>(
                      labelBuilder: (UUserResponse i) => i.phoneNumber == null ? i.displayName : "${i.displayName} · ${i.phoneNumber}",
                      onChanged: user.call,
                      selectedItem: user.value,
                      fetchData: c.readUsers,
                      hintText: U.s.tenant,
                    ).pSymmetric(vertical: 6),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: type.number,
                    decoration: InputDecoration(labelText: U.s.contractType, border: const OutlineInputBorder()),
                    items: _types.map((TagDormBedContract t) => DropdownMenuItem<int>(value: t.number, child: Text(c.isFa ? t.titleFa : t.titleEn))).toList(),
                    onChanged: (int? v) => setLocal(() => type = _types.firstWhere((TagDormBedContract t) => t.number == v)),
                  ).pSymmetric(vertical: 6),
                  UTextFieldDatePicker(
                    controller: startCtrl,
                    labelText: U.s.startDate,
                    jalali: true,
                    initialDate: startDate,
                    validator: UValidators.required(message: ""),
                    onChange: (DateTime d, Jalali j) {
                      startDate = d;
                      startCtrl.text = d.toJalaliDate();
                    },
                  ).pSymmetric(vertical: 6),
                  UTextFieldDatePicker(
                    controller: endCtrl,
                    labelText: U.s.endDate,
                    jalali: true,
                    initialDate: endDate,
                    validator: UValidators.required(message: ""),
                    onChange: (DateTime d, Jalali j) {
                      endDate = d;
                      endCtrl.text = d.toJalaliDate();
                    },
                  ).pSymmetric(vertical: 6),
                  // deposit only applies to monthly contracts; daily contracts have no deposit
                  if (type != TagDormBedContract.daily)
                    UTextField(controller: deposit, labelText: U.s.deposit, keyboardType: TextInputType.number, formatters: <TextInputFormatter>[UCurrencyInputFormatter()]).pSymmetric(vertical: 6),
                  // the rent field doubles as the fixed per-day price when the contract is daily
                  UTextField(
                    controller: rent,
                    labelText: type == TagDormBedContract.daily ? U.s.dailyPrice : U.s.rent,
                    keyboardType: TextInputType.number,
                    formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                  ).pSymmetric(vertical: 6),
                  // late-payment penalty only makes sense for recurring monthly invoices
                  if (!isEdit && type != TagDormBedContract.daily) UTextField(controller: penalty, labelText: U.s.dailyPenalty, keyboardType: TextInputType.number).pSymmetric(vertical: 6),
                  UTextField(controller: description, labelText: U.s.description, lines: 2).pSymmetric(vertical: 6),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        if (startDate == null || endDate == null) {
                          UToast.error(message: U.s.errorSubmittingForm);
                          return;
                        }
                        // daily contracts are single-invoice with no deposit; monthly keep rent + deposit
                        final bool isDaily = type == TagDormBedContract.daily;
                        final List<int> tags = <int>[type.number, if (isDaily) TagDormBedContract.singleInvoice.number];
                        if (isEdit) {
                          c.update(
                            p: UDormBedContractUpdateParams(
                              id: p.id,
                              tags: tags,
                              startDate: startDate,
                              endDate: endDate,
                              deposit: isDaily ? 0 : (deposit.text.isEmpty ? null : deposit.numDouble()),
                              rent: rent.text.isEmpty ? null : rent.numDouble(),
                            ),
                          );
                        } else {
                          final String? bid = bed.value?.id ?? widget.bed?.id;
                          if (bid == null) {
                            UToast.error(message: U.s.selectA(U.s.bed));
                            return;
                          }
                          if (user.value?.id == null) {
                            UToast.error(message: U.s.selectA(U.s.user));
                            return;
                          }
                          c.create(
                            p: UDormBedContractCreateParams(
                              tags: tags,
                              startDate: startDate!,
                              endDate: endDate!,
                              userId: user.value!.id,
                              bedId: bid,
                              deposit: isDaily ? null : (deposit.text.isEmpty ? null : deposit.numDouble()),
                              rent: rent.text.isEmpty ? null : rent.numDouble(),
                              penaltyPrecentEveryDate: isDaily ? null : (penalty.text.isEmpty ? null : penalty.text.toInt()),
                              detail1: description.text.nullIfEmpty(),
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
        )),
      ),
    );
  }

  UDormBedContractResponse _empty() => UDormBedContractResponse(
    isActive: false,
    id: "",
    createdAt: DateTime.now(),
    jsonData: UContractJsonData(),
    tags: <int>[],
    startDate: DateTime.now(),
    endDate: DateTime.now(),
    deposit: 0,
    rent: 0,
    userId: "",
    bedId: "",
    adminUserIds: <String>[],
  );
}
