import "package:u/utilities.dart";

class UAdminReservationPage extends StatefulWidget {
  const UAdminReservationPage({this.hotel, this.room, super.key});

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
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.room != null
        ? "${U.s.reservations} · ${widget.room!.title}"
        : widget.hotel != null
        ? "${U.s.reservations} · ${widget.hotel!.title}"
        : U.s.reservations,
    onFilter: _showFilterDialog,
    onCreate: U.user.hasPermission(TagUser.permissionManageReservations) ? _showEditDialog : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: _list(),
  );

  String _statusFilterLabel(UAdminReservationStatusFilter f) {
    switch (f) {
      case UAdminReservationStatusFilter.all:
        return U.s.all;
      case UAdminReservationStatusFilter.pending:
        return U.s.pending;
      case UAdminReservationStatusFilter.confirmed:
        return U.s.confirmed;
      case UAdminReservationStatusFilter.checkedIn:
        return U.s.checkedIn;
      case UAdminReservationStatusFilter.checkedOut:
        return U.s.checkedOut;
      case UAdminReservationStatusFilter.cancelled:
        return U.s.cancelled;
    }
  }

  Color _statusColor(TagHotelReservation? s) {
    switch (s) {
      case TagHotelReservation.confirmed:
      case TagHotelReservation.checkedIn:
        return UAdminTheme.green;
      case TagHotelReservation.cancelled:
      case TagHotelReservation.noShow:
        return UAdminTheme.red;
      case TagHotelReservation.checkedOut:
        return UAdminTheme.blue;
      case TagHotelReservation.pending:
      case null:
        return UAdminTheme.orange;
    }
  }

  Widget _statusChip(UHotelReservationResponse i) {
    final TagHotelReservation? s = i.status;
    final Color color = _statusColor(s);
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      radius: 20,
      color: color.withValues(alpha: 0.15),
      child: UTextBodySmall(s == null ? "-" : (c.isFa ? s.titleFa : s.titleEn), color: color),
    );
  }

  Widget _list() => UAdminListView<UHotelReservationResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.reservations),
    desktopBreakpoint: 900,
    desktopHeader: () => UAdminTable.header(<String>[U.s.guest, U.s.rooms, U.s.checkInDate, U.s.checkOutDate, U.s.totalPrice, U.s.status, U.s.operations]),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  String _guestLabel(UHotelReservationResponse i) => i.user?.displayName ?? i.jsonData.guestName ?? "-";

  String _roomLabel(UHotelReservationResponse i) => i.room?.title ?? widget.room?.title ?? "-";

  Widget _itemDesktop(UHotelReservationResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(_guestLabel(i)),
      UAdminTable.cell(_roomLabel(i)),
      UAdminTable.cell(i.checkInDate.toJalaliDate()),
      UAdminTable.cell(i.checkOutDate.toJalaliDate()),
      UAdminTable.cell(i.totalPrice.rial()),
      Center(child: _statusChip(i)).expanded(),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UHotelReservationResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.event_available_rounded,
    title: _guestLabel(i),
    badge: _statusChip(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.rooms, _roomLabel(i)),
      UAdminField(U.s.checkInDate, i.checkInDate.toJalaliDate()),
      UAdminField(U.s.checkOutDate, i.checkOutDate.toJalaliDate()),
      UAdminField(U.s.nights, "${i.jsonData.nightCount ?? 0}"),
      UAdminField(U.s.guests, i.guestCount.toString()),
      UAdminField(U.s.totalPrice, i.totalPrice.rial()),
    ],
  );

  Widget _menu(UHotelReservationResponse i) => UAdminOps.menu<UHotelReservationResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UHotelReservationResponse>(
      onEdit: (UHotelReservationResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
      extras: <String, void Function(UHotelReservationResponse)>{
        "guest": (UHotelReservationResponse x) {
          if (x.user != null) UAdminPageSwitcher.hotelUserDetail(user: x.user!);
        },
        "confirm": c.confirm,
        "checkIn": c.checkIn,
        "checkOut": c.checkOut,
        "cancel": c.cancel,
        "pay": (UHotelReservationResponse x) {
          final UHotelInvoiceResponse? unpaid = c.unpaidInvoiceOf(x);
          if (unpaid != null) c.payInvoice(unpaid);
        },
      },
    ),
    fallback: (UAdminActionContext<UHotelReservationResponse> ctx) {
      final TagHotelReservation? s = ctx.item.status;
      final UHotelInvoiceResponse? unpaid = c.unpaidInvoiceOf(ctx.item);
      return <UAdminAction>[
        ctx.extra("guest", label: U.s.guest, icon: Icons.person_outline, visible: ctx.item.user != null),
        ctx.extra("confirm", label: U.s.confirm, icon: Icons.check_circle_outline, visible: s == TagHotelReservation.pending, roles: <TagUser>[TagUser.permissionManageReservations]),
        ctx.extra("checkIn", label: U.s.checkIn, icon: Icons.login_rounded, visible: s == TagHotelReservation.confirmed, roles: <TagUser>[TagUser.permissionManageReservations]),
        ctx.extra("checkOut", label: U.s.checkOut, icon: Icons.logout_rounded, visible: s == TagHotelReservation.checkedIn, roles: <TagUser>[TagUser.permissionManageReservations]),
        ctx.extra(
          "cancel",
          label: U.s.cancel,
          icon: Icons.cancel_outlined,
          visible: s == TagHotelReservation.pending || s == TagHotelReservation.confirmed,
          roles: <TagUser>[TagUser.permissionManageReservations],
        ),
        ctx.extra(
          "pay",
          label: unpaid == null ? U.s.pay : "${U.s.pay} · ${unpaid.netDue.rial()}",
          icon: Icons.payments_outlined,
          visible: unpaid != null,
          roles: <TagUser>[TagUser.permissionPayInvoices],
        ),
        ctx.edit(roles: <TagUser>[TagUser.permissionManageReservations]),
        ctx.delete(roles: <TagUser>[TagUser.permissionDeleteReservations]),
      ];
    },
  );

  void _showFilterDialog() {
    final TextEditingController checkInCtrl = TextEditingController(text: c.checkInFilter?.toJalaliDate());
    final TextEditingController checkOutCtrl = TextEditingController(text: c.checkOutFilter?.toJalaliDate());

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.filterItem(U.s.reservations)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setLocal) => UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(controller: c.guestFilter, labelText: U.s.guest).pSymmetric(vertical: 6),
                  if (widget.hotel == null && widget.room == null)
                    UTextFieldAutoCompleteAsync<UHotelResponse>(
                      labelBuilder: (UHotelResponse i) => i.title,
                      onChanged: (UHotelResponse? i) => setLocal(() => c.hotelFilter = i),
                      selectedItem: c.hotelFilter,
                      fetchData: c.readHotels,
                      hintText: U.s.hotel,
                    ).pSymmetric(vertical: 6),
                  DropdownButtonFormField<UAdminReservationStatusFilter>(
                    isExpanded: true,
                    initialValue: c.statusFilter,
                    decoration: InputDecoration(labelText: U.s.status, border: const OutlineInputBorder()),
                    items: UAdminReservationStatusFilter.values
                        .map((UAdminReservationStatusFilter f) => DropdownMenuItem<UAdminReservationStatusFilter>(value: f, child: Text(_statusFilterLabel(f))))
                        .toList(),
                    onChanged: (UAdminReservationStatusFilter? v) => setLocal(() => c.statusFilter = v ?? UAdminReservationStatusFilter.all),
                  ).pSymmetric(vertical: 6),
                  UTextFieldDatePicker(
                    controller: checkInCtrl,
                    labelText: U.s.checkInDate,
                    jalali: true,
                    initialDate: c.checkInFilter,
                    onChange: (DateTime d, Jalali j) {
                      c.checkInFilter = d;
                      checkInCtrl.text = d.toJalaliDate();
                    },
                  ).pSymmetric(vertical: 6),
                  UTextFieldDatePicker(
                    controller: checkOutCtrl,
                    labelText: U.s.checkOutDate,
                    jalali: true,
                    initialDate: c.checkOutFilter,
                    onChange: (DateTime d, Jalali j) {
                      c.checkOutFilter = d;
                      checkOutCtrl.text = d.toJalaliDate();
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
          ),
        ),
      ),
    );
  }

  void _showEditDialog({UHotelReservationResponse? p}) {
    final bool isEdit = p != null;
    final TextEditingController guestCount = TextEditingController(text: (p?.guestCount ?? 1).toString());
    final TextEditingController totalPrice = TextEditingController(text: p?.totalPrice.toInt().toString());
    final TextEditingController penalty = TextEditingController();
    final TextEditingController guestName = TextEditingController(text: p?.jsonData.guestName);
    final TextEditingController guestPhone = TextEditingController(text: p?.jsonData.guestPhone);
    final TextEditingController notes = TextEditingController(text: p?.jsonData.notes);
    final TextEditingController checkInCtrl = TextEditingController(text: p?.checkInDate.toJalaliDate());
    final TextEditingController checkOutCtrl = TextEditingController(text: p?.checkOutDate.toJalaliDate());

    final Rxn<UHotelRoomResponse> room = Rxn<UHotelRoomResponse>();
    final Rxn<UUserResponse> user = Rxn<UUserResponse>();
    DateTime? checkIn = p?.checkInDate;
    DateTime? checkOut = p?.checkOutDate;

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    UNavigator.dialog(
      AlertDialog(
        title: Text(p == null ? U.s.createItem(U.s.reservation) : U.s.editItem(U.s.reservation)),
        content: SizedBox(
          width: context.dialogWidth(max: 480),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setLocal) => Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (!isEdit && widget.room == null)
                      UTextFieldAutoCompleteAsync<UHotelRoomResponse>(
                        labelBuilder: (UHotelRoomResponse i) => "${i.title} · ${i.pricePerNight.rial()}",
                        onChanged: room.call,
                        selectedItem: room.value,
                        fetchData: c.readRooms,
                        hintText: U.s.rooms,
                      ).pSymmetric(vertical: 6),
                    if (!isEdit)
                      UTextFieldAutoCompleteAsync<UUserResponse>(
                        labelBuilder: (UUserResponse i) => i.phoneNumber == null ? i.displayName : "${i.displayName} · ${i.phoneNumber}",
                        onChanged: user.call,
                        selectedItem: user.value,
                        fetchData: c.readUsers,
                        hintText: U.s.guest,
                      ).pSymmetric(vertical: 6),
                    UTextFieldDatePicker(
                      controller: checkInCtrl,
                      labelText: U.s.checkInDate,
                      jalali: true,
                      initialDate: checkIn,
                      validator: UValidators.required(message: ""),
                      onChange: (DateTime d, Jalali j) {
                        checkIn = d;
                        checkInCtrl.text = d.toJalaliDate();
                      },
                    ).pSymmetric(vertical: 6),
                    UTextFieldDatePicker(
                      controller: checkOutCtrl,
                      labelText: U.s.checkOutDate,
                      jalali: true,
                      initialDate: checkOut,
                      validator: UValidators.required(message: ""),
                      onChange: (DateTime d, Jalali j) {
                        checkOut = d;
                        checkOutCtrl.text = d.toJalaliDate();
                      },
                    ).pSymmetric(vertical: 6),
                    UTextField(
                      controller: guestCount,
                      labelText: U.s.numberOfGuests,
                      keyboardType: TextInputType.number,
                      validator: UValidators.required(message: ""),
                    ).pSymmetric(vertical: 6),
                    UTextField(
                      controller: totalPrice,
                      labelText: U.s.totalPrice,
                      keyboardType: TextInputType.number,
                      formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                    ).pSymmetric(vertical: 6),
                    UTextField(controller: guestName, labelText: U.s.guestName).pSymmetric(vertical: 6),
                    UTextField(controller: guestPhone, labelText: U.s.guestPhone, keyboardType: TextInputType.phone).pSymmetric(vertical: 6),
                    if (!isEdit) UTextField(controller: penalty, labelText: U.s.dailyPenalty, keyboardType: TextInputType.number).pSymmetric(vertical: 6),
                    UTextField(controller: notes, labelText: U.s.notes, lines: 2).pSymmetric(vertical: 6),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          if (checkIn == null || checkOut == null) {
                            UToast.error(message: U.s.errorSubmittingForm);
                            return;
                          }
                          if (isEdit) {
                            c.update(
                              p: UHotelReservationUpdateParams(
                                id: p.id,
                                checkInDate: checkIn,
                                checkOutDate: checkOut,
                                guestCount: guestCount.text.isEmpty ? null : guestCount.numInt(),
                                totalPrice: totalPrice.text.isEmpty ? null : totalPrice.numDouble(),
                                guestName: guestName.text.nullIfEmpty(),
                                guestPhone: guestPhone.text.nullIfEmpty(),
                                notes: notes.text.nullIfEmpty(),
                              ),
                            );
                          } else {
                            final String? rid = room.value?.id ?? widget.room?.id;
                            if (rid == null) {
                              UToast.error(message: U.s.pleaseSelectA(U.s.room));
                              return;
                            }
                            if (user.value?.id == null) {
                              UToast.error(message: U.s.pleaseSelectA(U.s.user));
                              return;
                            }
                            c.create(
                              p: UHotelReservationCreateParams(
                                tags: <int>[TagHotelReservation.pending.number],
                                checkInDate: checkIn!,
                                checkOutDate: checkOut!,
                                guestCount: guestCount.text.isEmpty ? 1 : guestCount.numInt(),
                                userId: user.value!.id,
                                roomId: rid,
                                totalPrice: totalPrice.text.isEmpty ? null : totalPrice.numDouble(),
                                guestName: guestName.text.nullIfEmpty(),
                                guestPhone: guestPhone.text.nullIfEmpty(),
                                notes: notes.text.nullIfEmpty(),
                                penaltyPrecentEveryDate: penalty.text.isEmpty ? null : penalty.text.toInt(),
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
          ),
        ),
      ),
    );
  }
}
