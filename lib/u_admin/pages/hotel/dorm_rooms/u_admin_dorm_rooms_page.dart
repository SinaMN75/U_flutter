import "package:u/utilities.dart";

class UAdminDormRoomPage extends StatefulWidget {
  const UAdminDormRoomPage({this.dorm, super.key});

  final UDormResponse? dorm;

  @override
  State<UAdminDormRoomPage> createState() => _DormRoomPageState();
}

class _DormRoomPageState extends State<UAdminDormRoomPage> {
  final UAdminDormRoomController c = UAdminDormRoomController();

  @override
  void initState() {
    c.init(dorm: widget.dorm);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.dorm == null ? U.s.dormRooms : "${U.s.rooms} · ${widget.dorm!.title}",
    onFilter: () => UAdminForm.filter(
      title: U.s.filterItem(U.s.rooms),
      children: (_) => <Widget>[UAdminForm.text(c.titleFilter, U.s.title)],
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
    body: UAdminListView<UDormRoomResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.room),
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.dorm, U.s.beds, U.s.created, U.s.operations]),
      desktopRow: (UDormRoomResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          UAdminTable.cell(i.title),
          UAdminTable.cell(i.dorm?.title ?? "-"),
          UAdminTable.cell((i.beds?.length ?? 0).toString()),
          UAdminTable.cell(i.createdAt.toJalaliDate()),
          _menu(i).expanded(),
        ],
      ),
      mobileRow: (UDormRoomResponse i, int index) => UAdminTable.mobileCard(
        icon: Icons.meeting_room_rounded,
        title: i.title,
        trailing: _menu(i),
        fields: <UAdminField>[
          UAdminField(U.s.dorm, i.dorm?.title ?? "-"),
          UAdminField(U.s.beds, (i.beds?.length ?? 0).toString()),
          UAdminField(U.s.created, i.createdAt.toJalaliDate()),
        ],
      ),
    ),
  );

  Widget _menu(UDormRoomResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.beds, icon: Icons.bed_outlined, onTap: () => UAdminPageSwitcher.dormBeds(room: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageDorms]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteDorms]), onTap: () => c.delete(i)),
    ],
  );

  /// Create ([r] == null) and edit share this one dialog.
  Future<void> _form([UDormRoomResponse? r]) async {
    await c.loadForm(r);
    await UAdminForm.editDialog(
      title: r == null ? U.s.createItem(U.s.room) : "${U.s.editItem(U.s.room)} — ${r.title}",
      formKey: c.formKey,
      maxWidth: 760,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UAdminForm.text(c.title, U.s.title, required: true),
        if (widget.dorm == null)
          UTextFieldAutoCompleteAsync<UDormResponse>(
            hintText: U.s.dorm,
            labelBuilder: (UDormResponse i) => i.title,
            selectedItem: c.formDorm,
            fetchData: c.searchDorms,
            onChanged: (UDormResponse? i) => c.formDorm = i,
          ).pSymmetric(vertical: 6),
        UTagChips<TagDormRoom>(title: U.s.type, options: TagDormRoom.values.group(100), tags: c.tags, single: true),
        UAdminForm.text(c.description, U.s.description, lines: 2),
        UAdminForm.pair(context, UAdminForm.text(c.capacity, U.s.capacity, number: true), UAdminForm.text(c.floor, U.s.floor, number: true)),
        UAdminForm.sectionTitle(U.s.photos),
        UFilePicker.gallery(c.photos),
        UAdminForm.sectionTitle(U.s.amenities),
        UTagChips<TagDormRoom>(title: U.s.details, options: TagDormRoom.values.group(300), tags: c.tags),
        UTagChips<TagDormRoom>(title: U.s.amenities, options: TagDormRoom.values.group(500), tags: c.tags),
      ],
    );
  }
}
