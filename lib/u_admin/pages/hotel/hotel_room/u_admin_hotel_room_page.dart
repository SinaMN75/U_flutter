import "package:u/utilities.dart";

class UAdminHotelRoomPage extends StatefulWidget {
  const UAdminHotelRoomPage({this.hotel, super.key});

  static void open({UHotelResponse? hotel}) => U.addOrSwitchTab(hotel == null ? U.s.hotelRooms : "${U.s.rooms} · ${hotel.title}", UAdminHotelRoomPage(hotel: hotel));

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.hotelRooms,
    icon: Icons.meeting_room_rounded,
    page: () => const UAdminHotelRoomPage(),
    roles: roles,
  );

  final UHotelResponse? hotel;

  @override
  State<UAdminHotelRoomPage> createState() => _HotelRoomPageState();
}

class _HotelRoomPageState extends State<UAdminHotelRoomPage> {
  final UAdminHotelRoomController c = UAdminHotelRoomController();

  @override
  void initState() {
    c.init(hotel: widget.hotel);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.hotel == null ? U.s.hotelRooms : "${U.s.rooms} · ${widget.hotel!.title}",
    onFilter: () => UAdminForm.filter(
      title: U.s.filterItem(U.s.rooms),
      children: (_) => <Widget>[
        UAdminForm.text(c.titleFilter, U.s.title),
        UAdminForm.text(c.minPriceFilter, U.s.minPrice, money: true),
        UAdminForm.text(c.maxPriceFilter, U.s.maxPrice, money: true),
      ],
      onApply: c.applyFilters,
      onClear: c.clearFilters,
    ),
    onCreate: U.user.hasPermission(TagUser.permissionManageHotels) ? _form : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UHotelRoomResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.rooms),
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.hotel, U.s.capacity, U.s.priceNight, U.s.operations]),
      desktopRow: (UHotelRoomResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          UAdminTable.cell(i.title),
          UAdminTable.cell(i.hotel?.title ?? "-"),
          UAdminTable.cell(i.capacity.toString()),
          UAdminTable.cell(i.pricePerNight.rial()),
          _menu(i).expanded(),
        ],
      ),
      mobileRow: (UHotelRoomResponse i, int index) => UAdminTable.mobileCard(
        icon: Icons.meeting_room_rounded,
        title: i.title,
        trailing: _menu(i),
        fields: <UAdminField>[
          UAdminField(U.s.hotel, i.hotel?.title ?? "-"),
          UAdminField(U.s.capacity, i.capacity.toString()),
          UAdminField(U.s.priceNight, i.pricePerNight.rial()),
        ],
      ),
    ),
  );

  Widget _menu(UHotelRoomResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.reservations, icon: Icons.event_available_outlined, onTap: () => UAdminReservationPage.open(room: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageHotels]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteHotels]), onTap: () => c.delete(i)),
    ],
  );

  /// Create ([r] == null) and edit share this one dialog.
  Future<void> _form([UHotelRoomResponse? r]) async {
    await c.loadForm(r);
    await UAdminForm.editDialog(
      title: r == null ? U.s.createItem(U.s.room) : "${U.s.editItem(U.s.room)} — ${r.title}",
      formKey: c.formKey,
      maxWidth: 760,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UAdminForm.text(c.title, U.s.title, required: true),
        if (widget.hotel == null)
          UTextFieldAutoCompleteAsync<UHotelResponse>(
            hintText: U.s.hotel,
            labelBuilder: (UHotelResponse i) => i.title,
            selectedItem: c.formHotel,
            fetchData: c.searchHotels,
            onChanged: (UHotelResponse? i) => c.formHotel = i,
          ).pSymmetric(vertical: 6),
        UTagChips<TagRoom>(title: U.s.type, options: TagRoom.values.group(100), tags: c.tags, single: true),
        UAdminForm.pair(context, UAdminForm.text(c.capacity, U.s.capacity, number: true, required: true), UAdminForm.text(c.price, U.s.priceNight, money: true, required: true)),
        UAdminForm.text(c.description, U.s.description, lines: 2),
        UAdminForm.pair(context, UAdminForm.text(c.roomNumber, U.s.roomNumber), UAdminForm.text(c.quantity, U.s.quantity, number: true)),
        UAdminForm.pair(context, UAdminForm.text(c.bedType, U.s.bedType), UAdminForm.text(c.size, U.s.size, number: true)),
        UAdminForm.text(c.floor, U.s.floor, number: true),
        UAdminForm.pair(context, UAdminForm.text(c.extraGuestCapacity, U.s.extraGuestCapacity, number: true), UAdminForm.text(c.extraGuestPrice, U.s.extraGuestPrice, money: true)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(U.s.available), value: c.isAvailable, onChanged: (bool v) => setState(() => c.isAvailable = v)),
        UAdminForm.sectionTitle(U.s.photos),
        UFilePicker.gallery(c.photos),
        UAdminForm.sectionTitle(U.s.details),
        UTagChips<TagRoom>(title: U.s.roomView, options: TagRoom.values.group(400), tags: c.tags, single: true),
        UTagChips<TagRoom>(title: U.s.policies, options: TagRoom.values.group(300), tags: c.tags),
        UTagChips<TagRoom>(title: U.s.amenities, options: TagRoom.values.group(500), tags: c.tags),
      ],
    );
  }
}
