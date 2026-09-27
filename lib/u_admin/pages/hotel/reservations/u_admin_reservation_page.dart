import "package:u/utilities.dart";

class UAdminReservationPage extends StatefulWidget {
  const UAdminReservationPage({this.hotel, this.room, super.key});

  static void open({UHotelResponse? hotel, UHotelRoomResponse? room}) => U.addOrSwitchTab(
    room != null
        ? "${U.s.reservations} · ${room.title}"
        : hotel != null
        ? "${U.s.reservations} · ${hotel.title}"
        : U.s.reservations,
    UAdminReservationPage(hotel: hotel, room: room),
  );

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.reservations,
    icon: Icons.event_available_rounded,
    page: () => const UAdminReservationPage(),
    roles: roles,
  );

  final UHotelResponse? hotel;
  final UHotelRoomResponse? room;

  @override
  State<UAdminReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<UAdminReservationPage> {
  final UAdminReservationController c = UAdminReservationController();

  @override
  void initState() {
    c.init(hotel: widget.hotel, room: widget.room);
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
        ? "${U.s.reservations} · ${widget.room!.title}"
        : widget.hotel != null
        ? "${U.s.reservations} · ${widget.hotel!.title}"
        : U.s.reservations,
    onFilter: _filter,
    onCreate: U.user.hasPermission(TagUser.permissionManageReservations) ? _form : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UHotelReservationResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.reservations),
      desktopBreakpoint: 900,
      desktopHeader: () => UAdminTable.header(<String>[U.s.guest, U.s.rooms, U.s.checkInDate, U.s.checkOutDate, U.s.totalPrice, U.s.status, U.s.operations]),
      desktopRow: (UHotelReservationResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          UAdminTable.cell(_guest(i)),
          UAdminTable.cell(i.room?.title ?? widget.room?.title ?? "-"),
          UAdminTable.cell(i.checkInDate.toJalaliDate()),
          UAdminTable.cell(i.checkOutDate.toJalaliDate()),
          UAdminTable.cell(i.totalPrice.rial()),
          _status(i).alignAtCenter().expanded(),
          _menu(i).expanded(),
        ],
      ),
      mobileRow: (UHotelReservationResponse i, int index) => UAdminTable.mobileCard(
        icon: Icons.event_available_rounded,
        title: _guest(i),
        badge: _status(i),
        trailing: _menu(i),
        fields: <UAdminField>[
          UAdminField(U.s.rooms, i.room?.title ?? widget.room?.title ?? "-"),
          UAdminField(U.s.checkInDate, i.checkInDate.toJalaliDate()),
          UAdminField(U.s.checkOutDate, i.checkOutDate.toJalaliDate()),
          UAdminField(U.s.nights, "${i.jsonData.nightCount ?? 0}"),
          UAdminField(U.s.guests, i.guestCount.toString()),
          UAdminField(U.s.totalPrice, i.totalPrice.rial()),
        ],
      ),
    ),
  );

  String _guest(UHotelReservationResponse i) => i.user?.displayName ?? i.jsonData.guestName ?? "-";

  Widget _status(UHotelReservationResponse i) => UAdminTable.statusChip(
    label: i.status?.localizedTitle ?? "-",
    color: switch (i.status) {
      TagHotelReservation.confirmed || TagHotelReservation.checkedIn => UAdminTheme.green,
      TagHotelReservation.cancelled || TagHotelReservation.noShow => UAdminTheme.red,
      TagHotelReservation.checkedOut => UAdminTheme.blue,
      TagHotelReservation.pending || null => UAdminTheme.orange,
    },
  );

  String _statusLabel(UAdminReservationStatusFilter f) => switch (f) {
    UAdminReservationStatusFilter.all => U.s.all,
    UAdminReservationStatusFilter.pending => U.s.pending,
    UAdminReservationStatusFilter.confirmed => U.s.confirmed,
    UAdminReservationStatusFilter.checkedIn => U.s.checkedIn,
    UAdminReservationStatusFilter.checkedOut => U.s.checkedOut,
    UAdminReservationStatusFilter.cancelled => U.s.cancelled,
  };

  Widget _menu(UHotelReservationResponse i) {
    final TagHotelReservation? s = i.status;
    final UHotelInvoiceResponse? unpaid = c.unpaidInvoiceOf(i);
    final bool canManage = UAdmin.canAccess(<TagUser>[TagUser.permissionManageReservations]);
    return UPopupMenu(
      items: <UPopupMenuItem>[
        UPopupMenuItem(label: U.s.guest, icon: Icons.person_outline, visible: i.user != null, onTap: () => UAdminHotelUserDetailPage.open(user: i.user!)),
        UPopupMenuItem(label: U.s.confirm, icon: Icons.check_circle_outline, visible: canManage && s == TagHotelReservation.pending, onTap: () => c.confirm(i)),
        UPopupMenuItem(label: U.s.checkIn, icon: Icons.login_rounded, visible: canManage && s == TagHotelReservation.confirmed, onTap: () => c.checkInGuest(i)),
        UPopupMenuItem(label: U.s.checkOut, icon: Icons.logout_rounded, visible: canManage && s == TagHotelReservation.checkedIn, onTap: () => c.checkOutGuest(i)),
        UPopupMenuItem(label: U.s.cancel, icon: Icons.cancel_outlined, visible: canManage && (s == TagHotelReservation.pending || s == TagHotelReservation.confirmed), onTap: () => c.cancel(i)),
        if (unpaid != null)
          UPopupMenuItem(label: "${U.s.pay} · ${unpaid.netDue.rial()}", icon: Icons.payments_outlined, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionPayInvoices]), onTap: () => c.payInvoice(unpaid)),
        UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: canManage, onTap: () => _form(i)),
        UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteReservations]), onTap: () => c.delete(i)),
      ],
    );
  }

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.reservations),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UTextField(controller: c.guestFilterController, labelText: U.s.guest, margin: const EdgeInsets.symmetric(vertical: 6)),
      if (widget.hotel == null && widget.room == null)
        UTextFieldAutoCompleteAsync<UHotelResponse>(
          hintText: U.s.hotel,
          labelBuilder: (UHotelResponse i) => i.title,
          selectedItem: c.hotelFilter,
          fetchData: c.searchHotels,
          onChanged: (UHotelResponse? i) => c.hotelFilter = i,
        ).pSymmetric(vertical: 6),
      UDropDownField<UAdminReservationStatusFilter>(
        labelText: U.s.status,
        initialValue: c.statusFilter,
        items: UAdminReservationStatusFilter.values.map((UAdminReservationStatusFilter f) => DropdownMenuItem<UAdminReservationStatusFilter>(value: f, child: Text(_statusLabel(f)))).toList(),
        onChanged: (UAdminReservationStatusFilter? v) => c.statusFilter = v ?? UAdminReservationStatusFilter.all,
      ).pSymmetric(vertical: 6),
      UTextFieldDatePicker(
        controller: c.startDateController,
        labelText: U.s.checkInDate,
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
        labelText: U.s.checkOutDate,
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
  void _form([UHotelReservationResponse? p]) {
    c.loadForm(p);
    UFormDialog.show(
      title: p == null ? U.s.createItem(U.s.reservation) : U.s.editItem(U.s.reservation),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        if (p == null && widget.room == null)
          UTextFieldAutoCompleteAsync<UHotelRoomResponse>(
            hintText: U.s.rooms,
            labelBuilder: (UHotelRoomResponse i) => "${i.title} · ${i.pricePerNight.rial()}",
            selectedItem: c.formRoom,
            fetchData: c.searchRooms,
            onChanged: (UHotelRoomResponse? i) => c.formRoom = i,
          ).pSymmetric(vertical: 6),
        if (p == null)
          UTextFieldAutoCompleteAsync<UUserResponse>(
            hintText: U.s.guest,
            labelBuilder: (UUserResponse i) => i.phoneNumber == null ? i.displayName : "${i.displayName} · ${i.phoneNumber}",
            selectedItem: c.formUser,
            fetchData: c.searchUsers,
            onChanged: (UUserResponse? i) => c.formUser = i,
          ).pSymmetric(vertical: 6),
        UFieldPair(UTextFieldDatePicker(
            controller: c.checkInController,
            labelText: U.s.checkInDate,
            jalali: true,
            initialDate: c.checkIn,
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
            onChange: (DateTime d, UJalali j) {
              c.checkIn = d;
              c.checkInController.text = d.toJalaliDate();
            },
          ), UTextFieldDatePicker(
            controller: c.checkOutController,
            labelText: U.s.checkOutDate,
            jalali: true,
            initialDate: c.checkOut,
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
            onChange: (DateTime d, UJalali j) {
              c.checkOut = d;
              c.checkOutController.text = d.toJalaliDate();
            },
          )),
        UFieldPair(
          UTextField(
            controller: c.guestCountController,
            labelText: U.s.numberOfGuests,
            keyboardType: TextInputType.number,
            validator: UValidators.required(message: ""),
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          UTextField(
            controller: c.totalPriceController,
            labelText: U.s.totalPrice,
            keyboardType: TextInputType.number,
            formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        UTextField(controller: c.guestNameController, labelText: U.s.guestName, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.guestPhoneController, labelText: U.s.guestPhone, margin: const EdgeInsets.symmetric(vertical: 6)),
        if (p == null) UTextField(controller: c.penaltyController, labelText: U.s.dailyPenalty, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.notesController, labelText: U.s.notes, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
      ],
    );
  }
}
