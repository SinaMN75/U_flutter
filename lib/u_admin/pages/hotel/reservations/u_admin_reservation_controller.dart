part of "../../../u_admin.dart";

enum UAdminReservationStatusFilter { all, pending, confirmed, checkedIn, checkedOut, cancelled }

class UAdminReservationController extends UBaseController {
  List<UHotelReservationResponse> list = <UHotelReservationResponse>[];

  UHotelResponse? hotel;
  UHotelRoomResponse? room;

  final TextEditingController guestFilter = TextEditingController();
  UHotelResponse? hotelFilter;
  UAdminReservationStatusFilter statusFilter = UAdminReservationStatusFilter.all;
  DateTime? checkInFilter;
  DateTime? checkOutFilter;

  Future<void> init({UHotelResponse? hotel, UHotelRoomResponse? room}) async {
    this.hotel = hotel;
    this.room = room;
    await read();
  }

  int? get _statusTag {
    switch (statusFilter) {
      case UAdminReservationStatusFilter.pending:
        return TagHotelReservation.pending.number;
      case UAdminReservationStatusFilter.confirmed:
        return TagHotelReservation.confirmed.number;
      case UAdminReservationStatusFilter.checkedIn:
        return TagHotelReservation.checkedIn.number;
      case UAdminReservationStatusFilter.checkedOut:
        return TagHotelReservation.checkedOut.number;
      case UAdminReservationStatusFilter.cancelled:
        return TagHotelReservation.cancelled.number;
      case UAdminReservationStatusFilter.all:
        return null;
    }
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readHotelReservations(
      p: UHotelReservationReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        hotelId: hotelFilter?.id ?? hotel?.id,
        roomId: room?.id,
        userName: guestFilter.text.nullIfEmpty(),
        tags: _statusTag == null ? null : <int>[_statusTag!],
        checkInDate: checkInFilter,
        checkOutDate: checkOutFilter,
        selectorArgs: const HotelReservationSelectorArgs(
          user: UserSelectorArgs(),
          room: HotelRoomSelectorArgs(hotel: HotelSelectorArgs()),
          hotel: HotelSelectorArgs(),
          invoice: HotelInvoiceSelectorArgs(),
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
    guestFilter.clear();
    hotelFilter = null;
    statusFilter = UAdminReservationStatusFilter.all;
    checkInFilter = null;
    checkOutFilter = null;
    reloadFirstPage(read);
  }

  void setStatus(UAdminReservationStatusFilter f) {
    statusFilter = f;
    reloadFirstPage(read);
  }

  void create({required UHotelReservationCreateParams p}) => UServices.hotel.createHotelReservation(
    p: p,
    onOk: (UResponse<String> r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UHotelReservationUpdateParams p}) => UServices.hotel.updateHotelReservation(
    p: p,
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void delete(UHotelReservationResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.deleteHotelReservation(
      p: UIdParams(id: i.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UResponse<dynamic> r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );

  void confirm(UHotelReservationResponse i) => UServices.hotel.confirmHotelReservation(
    p: UIdParams(id: i.id),
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void checkIn(UHotelReservationResponse i) => UServices.hotel.checkInHotelReservation(
    p: UIdParams(id: i.id),
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void checkOut(UHotelReservationResponse i) => UServices.hotel.checkOutHotelReservation(
    p: UIdParams(id: i.id),
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void cancel(UHotelReservationResponse i) => UNavigator.confirm(
    title: U.s.cancel,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.cancelHotelReservation(
      p: UIdParams(id: i.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UResponse<dynamic> r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );

  void payInvoice(UHotelInvoiceResponse inv) => UServices.hotel.payHotelInvoice(
    p: UIdParams(id: inv.id),
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  UHotelInvoiceResponse? unpaidInvoiceOf(UHotelReservationResponse i) {
    final List<UHotelInvoiceResponse> invoices = i.invoices ?? <UHotelInvoiceResponse>[];
    for (final UHotelInvoiceResponse inv in invoices) {
      if (!inv.isPaid) return inv;
    }
    return null;
  }

  Future<List<UHotelRoomResponse>> readRooms(String query) async {
    final List<UHotelRoomResponse> result = <UHotelRoomResponse>[];
    await UServices.hotel.readHotelRooms(
      p: UHotelRoomReadParams(
        title: query,
        hotelId: hotelFilter?.id ?? hotel?.id,
        availableOnly: true,
        pageSize: 100,
        pageNumber: 1,
        selectorArgs: const HotelRoomSelectorArgs(hotel: HotelSelectorArgs()),
      ),
      onOk: (UResponse<List<UHotelRoomResponse>> r) => result.addAll(r.result ?? <UHotelRoomResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }

  Future<List<UUserResponse>> readUsers(String query) async {
    final List<UUserResponse> result = <UUserResponse>[];
    await UServices.user.read(
      p: UUserReadParams(query: query.nullIfEmpty(), pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UUserResponse>> r) => result.addAll(r.result ?? <UUserResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }

  Future<List<UHotelResponse>> readHotels(String query) async {
    final List<UHotelResponse> result = <UHotelResponse>[];
    await UServices.hotel.readHotels(
      p: UHotelReadParams(title: query, pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UHotelResponse>> r) => result.addAll(r.result ?? <UHotelResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }
}
