import "package:u/utilities.dart";

class UAdminParkingStaffPage extends StatefulWidget {
  const UAdminParkingStaffPage({super.key, this.parking});

  final UParkingResponse? parking;

  @override
  State<UAdminParkingStaffPage> createState() => _UAdminParkingStaffPageState();
}

class _UAdminParkingStaffPageState extends State<UAdminParkingStaffPage> {
  final UAdminParkingStaffController c = UAdminParkingStaffController();

  @override
  void initState() {
    c.init(parking: widget.parking);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.staffManagement : "${U.s.staff} · ${widget.parking!.title}",
    onCreate: widget.parking == null ? null : _showCreateDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UParkingStaffResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.staff),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.fullName, flex: 2),
        UAdminTable.headerCell(U.s.username),
        UAdminTable.headerCell(U.s.shift),
        UAdminTable.headerCell(U.s.permissions, flex: 2),
        UAdminTable.headerCell(U.s.maxDiscountAllowed),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  String _name(UParkingStaffResponse i) => i.user?.displayName.nullIfEmpty() ?? i.user?.userName ?? "-";

  String _permissions(UParkingStaffResponse i) =>
      TagParkingStaff.values.where((TagParkingStaff t) => t != TagParkingStaff.disabled && i.tags.contains(t.number)).map((TagParkingStaff t) => t.localizedTitle).join("، ").nullIfEmpty() ??
      U.s.fullAccess;

  Widget _itemDesktop(UParkingStaffResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(_name(i), flex: 2),
      UAdminTable.cell(i.user?.userName ?? "-"),
      UAdminTable.cell(i.shiftTitle.nullIfEmpty() ?? "-"),
      UAdminTable.cell(_permissions(i), flex: 2),
      UAdminTable.cell("${i.maxDiscountPercent}%"),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UParkingStaffResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.badge_outlined,
    title: _name(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.username, i.user?.userName ?? "-"),
      UAdminField(U.s.shift, i.shiftTitle.nullIfEmpty() ?? "-"),
      UAdminField(U.s.permissions, _permissions(i)),
      UAdminField(U.s.maxDiscountAllowed, "${i.maxDiscountPercent}%"),
      if (i.tags.contains(TagParkingStaff.disabled.number)) UAdminField(U.s.disabled, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UParkingStaffResponse i) => UAdminOps.menu<UParkingStaffResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UParkingStaffResponse>(onEdit: _showEditDialog, onDelete: c.delete),
    fallback: (UAdminActionContext<UParkingStaffResponse> ctx) => <UAdminAction>[ctx.edit(), ctx.delete()],
  );

  static const List<TagParkingStaff> _selectablePermissions = <TagParkingStaff>[
    TagParkingStaff.registerEntryExit,
    TagParkingStaff.applyManualDiscount,
    TagParkingStaff.manageSubscriptions,
    TagParkingStaff.changeTariff,
    TagParkingStaff.viewFinancialReports,
  ];

  Future<void> _showCreateDialog() async {
    final String? parkingId = widget.parking?.id;
    if (parkingId == null) return;

    final TextEditingController firstName = TextEditingController();
    final TextEditingController lastName = TextEditingController();
    final TextEditingController userName = TextEditingController();
    final TextEditingController password = TextEditingController();
    final TextEditingController phone = TextEditingController();
    final TextEditingController shiftTitle = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final Set<TagParkingStaff> permissions = <TagParkingStaff>{TagParkingStaff.registerEntryExit};
    double maxDiscount = 0;

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(U.s.newStaffMember),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(controller: firstName, labelText: U.s.firstName, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: lastName, labelText: U.s.lastName, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(
                      controller: userName,
                      labelText: U.s.username,
                      validator: UValidators.required(message: ""),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(
                      controller: password,
                      labelText: U.s.password,
                      validator: UValidators.required(message: ""),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone, maxLength: 15, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: shiftTitle, labelText: U.s.shift, margin: const EdgeInsets.symmetric(vertical: 6)),
                    const SizedBox(height: 8),
                    ..._selectablePermissions.map(
                      (TagParkingStaff permission) => CheckboxListTile(
                        value: permissions.contains(permission),
                        title: UTextBodyMedium(permission.localizedTitle),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? value) => setDialogState(() => value ?? false ? permissions.add(permission) : permissions.remove(permission)),
                      ),
                    ),
                    UTextBodyMedium("${U.s.maxDiscountAllowed}: ${maxDiscount.round()}%"),
                    Slider(
                      value: maxDiscount,
                      max: 100,
                      divisions: 20,
                      label: "${maxDiscount.round()}%",
                      onChanged: (double value) => setDialogState(() => maxDiscount = value),
                    ),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          c.create(
                            p: UParkingStaffCreateParams(
                              parkingId: parkingId,
                              userName: userName.trimmedLatin(),
                              password: password.trimmedLatin(),
                              tags: permissions.isEmpty ? <int>[TagParkingStaff.registerEntryExit.number] : permissions.map((TagParkingStaff t) => t.number).toList(),
                              firstName: firstName.text.nullIfEmpty(),
                              lastName: lastName.text.nullIfEmpty(),
                              phoneNumber: phone.trimmedLatin().nullIfEmpty(),
                              shiftTitle: shiftTitle.text.nullIfEmpty(),
                              maxDiscountPercent: maxDiscount.round(),
                            ),
                          );
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

  Future<void> _showEditDialog(UParkingStaffResponse staff) async {
    final TextEditingController shiftTitle = TextEditingController(text: staff.shiftTitle);
    final TextEditingController password = TextEditingController();
    final Set<TagParkingStaff> permissions = <TagParkingStaff>{
      ...TagParkingStaff.values.where((TagParkingStaff t) => staff.tags.contains(t.number)),
    };
    double maxDiscount = staff.maxDiscountPercent.toDouble();

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(U.s.editItem(U.s.staff)),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(controller: shiftTitle, labelText: U.s.shift, margin: const EdgeInsets.symmetric(vertical: 6)),
                  UTextField(controller: password, labelText: U.s.newPassword, margin: const EdgeInsets.symmetric(vertical: 6)),
                  const SizedBox(height: 8),
                  ..._selectablePermissions.map(
                    (TagParkingStaff permission) => CheckboxListTile(
                      value: permissions.contains(permission),
                      title: UTextBodyMedium(permission.localizedTitle),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) => setDialogState(() => value ?? false ? permissions.add(permission) : permissions.remove(permission)),
                    ),
                  ),
                  SwitchListTile(
                    value: permissions.contains(TagParkingStaff.disabled),
                    title: UTextBodyMedium(U.s.disabled),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool value) => setDialogState(
                      () => value ? permissions.add(TagParkingStaff.disabled) : permissions.remove(TagParkingStaff.disabled),
                    ),
                  ),
                  UTextBodyMedium("${U.s.maxDiscountAllowed}: ${maxDiscount.round()}%"),
                  Slider(
                    value: maxDiscount,
                    max: 100,
                    divisions: 20,
                    label: "${maxDiscount.round()}%",
                    onChanged: (double value) => setDialogState(() => maxDiscount = value),
                  ),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () {
                      c.update(
                        p: UParkingStaffUpdateParams(
                          id: staff.id,
                          shiftTitle: shiftTitle.text.nullIfEmpty(),
                          password: password.text.nullIfEmpty(),
                          maxDiscountPercent: maxDiscount.round(),
                          tags: permissions.map((TagParkingStaff t) => t.number).toList(),
                        ),
                      );
                      UNavigator.back();
                    },
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
