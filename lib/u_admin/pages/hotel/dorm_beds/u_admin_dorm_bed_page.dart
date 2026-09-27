import "package:u/utilities.dart";

class UAdminDormBedPage extends StatefulWidget {
  const UAdminDormBedPage({this.room, this.dorm, super.key});

  static void open({UDormRoomResponse? room, UDormResponse? dorm}) => U.addOrSwitchTab(
    room != null
        ? "${U.s.beds} · ${room.title}"
        : dorm != null
        ? "${U.s.beds} · ${dorm.title}"
        : U.s.dormBeds,
    UAdminDormBedPage(room: room, dorm: dorm),
  );

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.beds,
    icon: Icons.bed_rounded,
    page: () => const UAdminDormBedPage(),
    roles: roles,
  );

  final UDormRoomResponse? room;
  final UDormResponse? dorm;

  @override
  State<UAdminDormBedPage> createState() => _DormBedPageState();
}

class _DormBedPageState extends State<UAdminDormBedPage> {
  final UAdminDormBedController c = UAdminDormBedController();

  @override
  void initState() {
    c.init(room: widget.room, dorm: widget.dorm);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.room != null
        ? "${U.s.beds} · ${widget.room!.title}"
        : widget.dorm != null
        ? "${U.s.beds} · ${widget.dorm!.title}"
        : U.s.dormBeds,
    onFilter: () => UFilterDialog.show(
      title: U.s.filterItem(U.s.beds),
      children: (_) => <Widget>[UTextField(controller: c.titleFilterController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6))],
      onApply: c.applyFilters,
      onClear: c.clearFilters,
    ),
    onCreate: U.user.hasPermission(TagUser.permissionManageDorms) ? _form : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UDormBedResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.beds),
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.deposit, U.s.rent, U.s.occupancy, U.s.operations]),
      desktopRow: (UDormBedResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          UAdminTable.cell(i.title),
          UAdminTable.cell(i.deposit.rial()),
          UAdminTable.cell(i.monthlyRent.rial()),
          _occupancy(i).alignAtCenter().expanded(),
          _menu(i).expanded(),
        ],
      ),
      mobileRow: (UDormBedResponse i, int index) => UAdminTable.mobileCard(
        icon: Icons.bed_rounded,
        title: i.title,
        badge: _occupancy(i),
        trailing: _menu(i),
        fields: <UAdminField>[
          UAdminField(U.s.deposit, i.deposit.rial()),
          UAdminField(U.s.rent, i.monthlyRent.rial()),
        ],
      ),
    ),
  );

  Widget _occupancy(UDormBedResponse i) => UAdminTable.statusChip(
    label: c.isFree(i) ? U.s.free : U.s.occupied,
    color: c.isFree(i) ? UAdminTheme.green : UAdminTheme.orange,
  );

  Widget _menu(UDormBedResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.contracts, icon: Icons.description_outlined, onTap: () => UAdminContractPage.open(bed: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageDorms]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteDorms]), onTap: () => c.delete(i)),
    ],
  );

  /// Create ([b] == null) and edit share this one dialog.
  Future<void> _form([UDormBedResponse? b]) async {
    await c.loadForm(b);
    await UFormDialog.show(
      title: b == null ? U.s.createItem(U.s.bed) : "${U.s.editItem(U.s.bed)} — ${b.title}",
      maxWidth: 760,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.titleController, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        if (widget.room == null)
          UTextFieldAutoCompleteAsync<UDormRoomResponse>(
            hintText: U.s.room,
            labelBuilder: (UDormRoomResponse i) => i.dorm == null ? i.title : "${i.dorm!.title} · ${i.title}",
            selectedItem: c.formRoom,
            fetchData: c.searchRooms,
            onChanged: (UDormRoomResponse? i) => c.formRoom = i,
          ).pSymmetric(vertical: 6),
        UTagChips<TagDormBed>(title: U.s.type, options: TagDormBed.values.group(100), tags: c.tags, single: true),
        UFieldPair(
          UTextField(
            controller: c.depositController,
            labelText: U.s.deposit,
            keyboardType: TextInputType.number,
            formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          UTextField(
            controller: c.rentController,
            labelText: U.s.rent,
            keyboardType: TextInputType.number,
            formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        UTextField(controller: c.descriptionController, labelText: U.s.description, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
        const Divider(height: 20),
        UTextBodySmall(U.s.photos, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UFilePicker.gallery(c.photos),
        const Divider(height: 20),
        UTextBodySmall(U.s.details, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTagChips<TagDormBed>(title: U.s.bedLevel, options: TagDormBed.values.group(200), tags: c.tags, single: true),
        UTagChips<TagDormBed>(title: U.s.bedAmenities, options: TagDormBed.values.group(500), tags: c.tags),
      ],
    );
  }
}
