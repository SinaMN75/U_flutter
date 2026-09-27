part of "../../u_admin.dart";

class UAdminParkingStaffPage extends StatefulWidget {
  const UAdminParkingStaffPage({super.key, this.parking});

  static void open({UParkingResponse? parking}) => U.addOrSwitchTab(
    parking == null ? U.s.staffManagement : "${U.s.staff} · ${parking.title}",
    UAdminParkingStaffPage(parking: parking),
  );

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.staffManagement,
    icon: Icons.badge_rounded,
    page: () => const UAdminParkingStaffPage(),
    roles: roles,
  );

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
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.staffManagement : "${U.s.staff} · ${widget.parking!.title}",
    onCreate: widget.parking == null ? null : _form,
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
        UAdminTable.headerCell(U.s.maximumDiscountAllowed),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
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

  Widget _itemMobile(UParkingStaffResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.badge_outlined,
    title: _name(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.username, i.user?.userName ?? "-"),
      UAdminField(U.s.shift, i.shiftTitle.nullIfEmpty() ?? "-"),
      UAdminField(U.s.permissions, _permissions(i)),
      UAdminField(U.s.maximumDiscountAllowed, "${i.maxDiscountPercent}%"),
      if (i.tags.contains(TagParkingStaff.disabled.number)) UAdminField(U.s.disabled, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UParkingStaffResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  Future<void> _form([UParkingStaffResponse? staff]) async {
    c.loadForm(staff);
    final bool isNew = staff == null;
    await UFormDialog.show(
      title: isNew ? U.s.newStaffMember : U.s.editItem(U.s.staff),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        if (isNew) ...<Widget>[
          UTextField(controller: c.firstNameController, labelText: U.s.firstName, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.lastNameController, labelText: U.s.lastName, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.userNameController, labelText: U.s.username, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        ],
        UTextField(
          controller: c.passwordController,
          labelText: isNew ? U.s.password : U.s.newPassword,
          validator: isNew ? UValidators.required(message: "") : null,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        if (isNew) UTextFieldPhoneNumber(controller: c.phoneController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.shiftTitleController, labelText: U.s.shift, margin: const EdgeInsets.symmetric(vertical: 6)),
        ...UAdminParkingStaffController.selectablePermissions.map(
          (TagParkingStaff t) => CheckboxListTile(
            value: c.permissions.contains(t),
            title: UTextBodyMedium(t.localizedTitle),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? v) => setState(() => c.togglePermission(t, v ?? false)),
          ),
        ),
        if (!isNew)
          SwitchListTile(
            value: c.permissions.contains(TagParkingStaff.disabled),
            title: UTextBodyMedium(U.s.disabled),
            contentPadding: EdgeInsets.zero,
            onChanged: (bool v) => setState(() => c.togglePermission(TagParkingStaff.disabled, v)),
          ),
        UTextBodyMedium("${U.s.maximumDiscountAllowed}: ${c.maxDiscount.round()}%"),
        Slider(
          value: c.maxDiscount,
          max: 100,
          divisions: 20,
          label: "${c.maxDiscount.round()}%",
          onChanged: (double v) => setState(() => c.maxDiscount = v),
        ),
      ],
    );
  }
}
