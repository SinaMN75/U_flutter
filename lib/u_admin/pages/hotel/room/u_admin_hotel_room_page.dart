part of "../../../u_admin.dart";

class UAdminHotelRoomPage extends StatefulWidget {
  const UAdminHotelRoomPage({this.hotel, super.key});

  static UAdminModule module({List<TagUser>? roles, UHotelResponse? hotel}) => UAdminModule(
    title: hotel == null ? U.s.hotelRooms : "${U.s.rooms} · ${hotel.title}",
    icon: Icons.meeting_room_rounded,
    page: () => UAdminHotelRoomPage(hotel: hotel),
    roles: roles,
  );

  final UHotelResponse? hotel;

  @override
  State<UAdminHotelRoomPage> createState() => _UAdminHotelRoomPageState();
}

class _UAdminHotelRoomPageState extends State<UAdminHotelRoomPage> {
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
    onFilter: () => UFilterDialog.show(
      title: U.s.filterItem(U.s.rooms),
      children: (_) => <Widget>[
        UTextField(controller: c.titleFilterController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(
          controller: c.minPriceFilterController,
          labelText: U.s.minPrice,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.maxPriceFilterController,
          labelText: U.s.maxPrice,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
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
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.title),
        UAdminTable.headerCell(U.s.hotel),
        UAdminTable.headerCell(U.s.capacity),
        UAdminTable.headerCell(U.s.priceNight),
        UAdminTable.headerCell(U.s.operations),
      ],
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
      UPopupMenuItem(label: U.s.reservations, icon: Icons.event_available_outlined, onTap: () => UAdminHotelReservationPage.module(room: i).open()),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageHotels]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteHotels]), onTap: () => c.delete(i)),
    ],
  );

  /// Create ([r] == null) and edit share this one dialog.
  Future<void> _form([UHotelRoomResponse? r]) async {
    await c.loadForm(r);
    await UFormDialog.show(
      title: r == null ? U.s.createItem(U.s.room) : "${U.s.editItem(U.s.room)} — ${r.title}",
      maxWidth: 760,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.titleController, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        if (widget.hotel == null)
          UTextFieldAutoCompleteAsync<UHotelResponse>(
            hintText: U.s.hotel,
            labelBuilder: (UHotelResponse i) => i.title,
            selectedItem: c.formHotel,
            fetchData: c.searchHotels,
            onChanged: (UHotelResponse? i) => c.formHotel = i,
          ).pSymmetric(vertical: 6),
        UTagChips<TagRoom>(title: U.s.type, options: TagRoom.values.group(100), tags: c.tags, single: true),
        UFieldPair(
          UTextField(
            controller: c.capacityController,
            labelText: U.s.capacity,
            keyboardType: TextInputType.number,
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          UTextField(
            controller: c.priceController,
            labelText: U.s.priceNight,
            keyboardType: TextInputType.number,
            formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        UTextField(controller: c.descriptionController, labelText: U.s.description, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
        UFieldPair(
          UTextField(controller: c.roomNumberController, labelText: U.s.roomNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.quantityController, labelText: U.s.quantity, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UFieldPair(
          UTextField(controller: c.bedTypeController, labelText: U.s.bedType, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.sizeController, labelText: U.s.size, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UTextField(controller: c.floorController, labelText: U.s.floor, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        UFieldPair(
          UTextField(controller: c.extraGuestCapacityController, labelText: U.s.extraGuestCapacity, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(
            controller: c.extraGuestPriceController,
            labelText: U.s.extraGuestPrice,
            keyboardType: TextInputType.number,
            formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(U.s.available), value: c.isAvailable, onChanged: (bool v) => setState(() => c.isAvailable = v)),
        const Divider(height: 20),
        UTextBodySmall(U.s.photos, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UFilePicker.gallery(c.photos),
        const Divider(height: 20),
        UTextBodySmall(U.s.details, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTagChips<TagRoom>(title: U.s.roomView, options: TagRoom.values.group(400), tags: c.tags, single: true),
        UTagChips<TagRoom>(title: U.s.policies, options: TagRoom.values.group(300), tags: c.tags),
        UTagChips<TagRoom>(title: U.s.amenities, options: TagRoom.values.group(500), tags: c.tags),
      ],
    );
  }
}
