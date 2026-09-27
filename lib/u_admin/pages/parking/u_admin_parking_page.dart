import "package:u/utilities.dart";

class UAdminParkingPage extends StatefulWidget {
  const UAdminParkingPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.parkingManagement, const UAdminParkingPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.parking,
    icon: Icons.local_parking_rounded,
    page: () => const UAdminParkingPage(),
    roles: roles,
  );

  @override
  State<UAdminParkingPage> createState() => _UAdminParkingPageState();
}

class _UAdminParkingPageState extends State<UAdminParkingPage> {
  final UAdminParkingController c = UAdminParkingController();

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
    title: U.s.parkingManagement,
    onCreate: _form,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UParkingResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.parking),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.title, flex: 2),
        UAdminTable.headerCell(U.s.address, flex: 2),
        UAdminTable.headerCell(U.s.capacity),
        UAdminTable.headerCell(U.s.owner, flex: 2),
        UAdminTable.headerCell(U.s.admins),
        UAdminTable.headerCell(U.s.createdAt),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  String _ownerLabel(UParkingResponse i) => i.creator?.displayName.nullIfEmpty() ?? i.creator?.userName ?? "-";

  Widget _itemDesktop(UParkingResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title, flex: 2),
      UAdminTable.cell(i.address.nullIfEmpty() ?? "-", flex: 2),
      UAdminTable.cell(i.capacity.toString()),
      UAdminTable.cell(_ownerLabel(i), flex: 2),
      UAdminTable.cell(i.adminUserIds.length.toString()),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UParkingResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.local_parking_rounded,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.address, i.address.nullIfEmpty() ?? "-"),
      UAdminField(U.s.phoneNumber, i.phoneNumber.nullIfEmpty() ?? "-"),
      UAdminField(U.s.capacity, i.capacity.toString()),
      UAdminField(U.s.owner, _ownerLabel(i)),
      UAdminField(U.s.admins, i.adminUserIds.length.toString()),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UParkingResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.viewItem(U.s.parkingReports), icon: Icons.assessment_outlined, onTap: () => UAdminParkingReportPage.open(parking: i)),
      UPopupMenuItem(label: U.s.tariffs, icon: Icons.request_quote_outlined, onTap: () => UAdminParkingTariffPage.open(parking: i)),
      UPopupMenuItem(label: U.s.subscriptions, icon: Icons.card_membership_outlined, onTap: () => UAdminParkingSubscriptionPage.open(parking: i)),
      UPopupMenuItem(label: U.s.staff, icon: Icons.badge_outlined, onTap: () => UAdminParkingStaffPage.open(parking: i)),
      UPopupMenuItem(label: U.s.specialPlates, icon: Icons.gpp_maybe_outlined, onTap: () => UAdminParkingPlateFlagPage.open(parking: i)),
      UPopupMenuItem(label: U.s.shift, icon: Icons.point_of_sale_outlined, onTap: () => UAdminParkingShiftPage.open(parking: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  Future<void> _form([UParkingResponse? p]) async {
    await c.loadForm(p);
    await UFormDialog.show(
      title: p == null ? U.s.createItem(U.s.parking) : U.s.editItem(U.s.parking),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.titleController, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.addressController, labelText: U.s.address, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.phoneController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.capacityController, labelText: U.s.capacity, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(
          controller: c.entranceController,
          labelText: U.s.entrancePrice,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.hourlyController,
          labelText: U.s.hourlyPrice,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.dailyController,
          labelText: U.s.dailyPrice,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        SwitchListTile(
          value: c.disabled,
          title: UTextBodyMedium(U.s.disabled),
          contentPadding: EdgeInsets.zero,
          onChanged: (bool v) => setState(() => c.disabled = v),
        ),
        UTextFieldAutoCompleteAsync<UUserResponse>(
          hintText: U.s.owner,
          selectedItem: c.owner,
          labelBuilder: (UUserResponse u) => u.userName,
          fetchData: c.searchUsers,
          onChanged: (UUserResponse? u) => setState(() => c.owner = u),
        ).pSymmetric(vertical: 6),
        if (c.owner != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(label: Text(c.owner!.userName), onDeleted: () => setState(() => c.owner = null)),
          ),
        UTextFieldAutoCompleteAsyncMulti<UUserResponse>(
          selected: c.admins,
          hintText: U.s.admins,
          labelBuilder: (UUserResponse u) => u.userName,
          fetchData: c.searchUsers,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
      ],
    );
  }
}
