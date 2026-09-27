part of "../../../u_admin.dart";

enum UAdminReservationStatusFilter { all, pending, confirmed, checkedIn, checkedOut, cancelled }

class UAdminReservationController extends UBaseController {
  List<UHotelReservationResponse> list = <UHotelReservationResponse>[];
  UHotelResponse? hotel;
  UHotelRoomResponse? room;

  final TextEditingController guestFilterController = TextEditingController();
  UHotelResponse? hotelFilter;
  UAdminReservationStatusFilter statusFilter = UAdminReservationStatusFilter.all;

  // ---------------------------------------------------------------- form (create and edit)

  UHotelReservationResponse? editing;
  UHotelRoomResponse? formRoom;
  UUserResponse? formUser;
  DateTime? checkIn;
  DateTime? checkOut;
  final TextEditingController checkInController = TextEditingController();
  final TextEditingController checkOutController = TextEditingController();
  final TextEditingController guestCountController = TextEditingController();
  final TextEditingController totalPriceController = TextEditingController();
  final TextEditingController penaltyController = TextEditingController();
  final TextEditingController guestNameController = TextEditingController();
  final TextEditingController guestPhoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  void init({UHotelResponse? hotel, UHotelRoomResponse? room}) {
    this.hotel = hotel;
    this.room = room;
    read();
  }

  int? get _statusTag => switch (statusFilter) {
    UAdminReservationStatusFilter.all => null,
    UAdminReservationStatusFilter.pending => TagHotelReservation.pending.number,
    UAdminReservationStatusFilter.confirmed => TagHotelReservation.confirmed.number,
    UAdminReservationStatusFilter.checkedIn => TagHotelReservation.checkedIn.number,
    UAdminReservationStatusFilter.checkedOut => TagHotelReservation.checkedOut.number,
    UAdminReservationStatusFilter.cancelled => TagHotelReservation.cancelled.number,
  };

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readHotelReservations(
      p: UHotelReservationReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        hotelId: hotelFilter?.id ?? hotel?.id,
        roomId: room?.id,
        userName: guestFilterController.valueOrNull(),
        tags: _statusTag == null ? null : <int>[_statusTag!],
        checkInDate: startDate,
        checkOutDate: endDate,
        selectorArgs: const UHotelReservationSelectorArgs(
          user: UUserSelectorArgs(),
          room: UHotelRoomSelectorArgs(hotel: UHotelSelectorArgs()),
          hotel: UHotelSelectorArgs(),
          invoice: UHotelInvoiceSelectorArgs(),
        ),
      ),
      onOk: (UResponse<List<UHotelReservationResponse>> r) {
        list = r.result ?? <UHotelReservationResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UResponse<dynamic> e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    guestFilterController.clear();
    clearDates();
    hotelFilter = null;
    statusFilter = UAdminReservationStatusFilter.all;
    reloadFirstPage(read);
  }

  UHotelInvoiceResponse? unpaidInvoiceOf(UHotelReservationResponse i) => i.invoices?.where((UHotelInvoiceResponse inv) => !inv.isPaid).firstOrNull;

  Future<List<UHotelRoomResponse>> searchRooms(String query) async =>
      (await UServices.hotel.readHotelRooms(
        p: UHotelRoomReadParams(
          title: query,
          hotelId: hotelFilter?.id ?? hotel?.id,
          availableOnly: true,
          pageSize: 100,
          pageNumber: 1,
          selectorArgs: const UHotelRoomSelectorArgs(hotel: UHotelSelectorArgs()),
        ),
      )).$1?.result ??
      <UHotelRoomResponse>[];

  Future<List<UHotelResponse>> searchHotels(String query) async => (await UServices.hotel.readHotels(p: UHotelReadParams(title: query, pageSize: 100, pageNumber: 1))).$1?.result ?? <UHotelResponse>[];

  void loadForm(UHotelReservationResponse? i) {
    editing = i;
    formRoom = room;
    formUser = null;
    checkIn = i?.checkInDate;
    checkOut = i?.checkOutDate;
    checkInController.text = i?.checkInDate.toJalaliDate() ?? "";
    checkOutController.text = i?.checkOutDate.toJalaliDate() ?? "";
    guestCountController.text = (i?.guestCount ?? 1).toString();
    totalPriceController.text = i?.totalPrice.toInt().toString() ?? "";
    penaltyController.clear();
    guestNameController.text = i?.jsonData.guestName ?? "";
    guestPhoneController.text = i?.jsonData.guestPhone ?? "";
    notesController.text = i?.jsonData.notes ?? "";
  }

  /// Creates or updates the reservation. Returns true when the dialog can close.
  Future<bool> save() async {
    if (editing != null) {
      return await submit(
            UServices.hotel.updateHotelReservation(
              p: UHotelReservationUpdateParams(
                id: editing!.id,
                checkInDate: checkIn,
                checkOutDate: checkOut,
                guestCount: intOf(guestCountController),
                totalPrice: numOf(totalPriceController),
                guestName: guestNameController.text.nullIfEmpty(),
                guestPhone: guestPhoneController.text.nullIfEmpty(),
                notes: notesController.text.nullIfEmpty(),
              ),
            ),
            read,
          ) !=
          null;
    }
    if (formRoom == null) {
      UToast.error(message: U.s.pleaseSelectAItem(U.s.room));
      return false;
    }
    if (formUser == null) {
      UToast.error(message: U.s.pleaseSelectAItem(U.s.user));
      return false;
    }
    return await submit(
          UServices.hotel.createHotelReservation(
            p: UHotelReservationCreateParams(
              tags: <int>[TagHotelReservation.pending.number],
              checkInDate: checkIn!,
              checkOutDate: checkOut!,
              guestCount: intOf(guestCountController) ?? 1,
              userId: formUser!.id,
              roomId: formRoom!.id,
              totalPrice: numOf(totalPriceController),
              guestName: guestNameController.text.nullIfEmpty(),
              guestPhone: guestPhoneController.text.nullIfEmpty(),
              notes: notesController.text.nullIfEmpty(),
              penaltyPrecentEveryDate: intOf(penaltyController),
            ),
          ),
          read,
        ) !=
        null;
  }

  void confirm(UHotelReservationResponse i) => submit(UServices.hotel.confirmHotelReservation(p: UIdParams(id: i.id)), read);

  void checkInGuest(UHotelReservationResponse i) => submit(UServices.hotel.checkInHotelReservation(p: UIdParams(id: i.id)), read);

  void checkOutGuest(UHotelReservationResponse i) => submit(UServices.hotel.checkOutHotelReservation(p: UIdParams(id: i.id)), read);

  void cancel(UHotelReservationResponse i) => confirmAction(
    () => UServices.hotel.cancelHotelReservation(p: UIdParams(id: i.id)),
    read,
    title: U.s.cancel,
  );

  void payInvoice(UHotelInvoiceResponse inv) => submit(UServices.hotel.payHotelInvoice(p: UIdParams(id: inv.id)), read);

  void delete(UHotelReservationResponse i) => confirmAction(() => UServices.hotel.deleteHotelReservation(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    guestFilterController.dispose();
    checkInController.dispose();
    checkOutController.dispose();
    guestCountController.dispose();
    totalPriceController.dispose();
    penaltyController.dispose();
    guestNameController.dispose();
    guestPhoneController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
