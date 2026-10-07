part of "../data.dart";

class UHotelService {
  Future<(UResponse<UHotelDashboardResponse>?, UEmptyResponse?, String?)> readHotelDashboard({
    required UDashboardRangeParams p,
    Function(UResponse<UHotelDashboardResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Dashboard/Read", p.toMap(), _Api.one(UHotelDashboardResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> receiveHotelInvoice({
    required UInvoiceReceiveParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelInvoice/Receive", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createHotel({
    required UHotelCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Hotel/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UHotelResponse>>?, UEmptyResponse?, String?)> readHotels({
    required UHotelReadParams p,
    Function(UResponse<List<UHotelResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Hotel/Read", p.toMap(), _Api.list(UHotelResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UHotelResponse>?, UEmptyResponse?, String?)> readHotelById({
    required UIdParams p,
    Function(UResponse<UHotelResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Hotel/ReadById", p.toMap(), _Api.one(UHotelResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateHotel({
    required UHotelUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Hotel/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteHotel({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Hotel/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createHotelRoom({
    required UHotelRoomCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelRoom/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UHotelRoomResponse>>?, UEmptyResponse?, String?)> readHotelRooms({
    required UHotelRoomReadParams p,
    Function(UResponse<List<UHotelRoomResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelRoom/Read", p.toMap(), _Api.list(UHotelRoomResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UHotelRoomResponse>?, UEmptyResponse?, String?)> readHotelRoomById({
    required UIdParams p,
    Function(UResponse<UHotelRoomResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelRoom/ReadById", p.toMap(), _Api.one(UHotelRoomResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateHotelRoom({
    required UHotelRoomUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelRoom/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteHotelRoom({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelRoom/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createHotelReservation({
    required UHotelReservationCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelReservation/Create", p.toMap(), _Api.raw<String>(), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UHotelReservationResponse>>?, UResponse<dynamic>?, String?)> readHotelReservations({
    required UHotelReservationReadParams p,
    Function(UResponse<List<UHotelReservationResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelReservation/Read", p.toMap(), _Api.list(UHotelReservationResponse.fromMap), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<UHotelReservationResponse>?, UResponse<dynamic>?, String?)> readHotelReservationById({
    required UIdParams p,
    Function(UResponse<UHotelReservationResponse> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelReservation/ReadById", p.toMap(), _Api.one(UHotelReservationResponse.fromMap), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> updateHotelReservation({
    required UHotelReservationUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelReservation/Update", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> deleteHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelReservation/Delete", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> _reservationAction({
    required String action,
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelReservation/$action", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> confirmHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _reservationAction(action: "Confirm", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> checkInHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _reservationAction(action: "CheckIn", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> checkOutHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _reservationAction(action: "CheckOut", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> cancelHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _reservationAction(action: "Cancel", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createHotelInvoice({
    required UHotelInvoiceCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelInvoice/Create", p.toMap(), _Api.raw<String>(), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UHotelInvoiceResponse>>?, UResponse<dynamic>?, String?)> readHotelInvoices({
    required UHotelInvoiceReadParams p,
    Function(UResponse<List<UHotelInvoiceResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelInvoice/Read", p.toMap(), _Api.list(UHotelInvoiceResponse.fromMap), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> updateHotelInvoice({
    required UHotelInvoiceUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelInvoice/Update", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> deleteHotelInvoice({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelInvoice/Delete", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> payHotelInvoice({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelInvoice/Pay", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UHotelRoomAvailabilityResponse>>?, UEmptyResponse?, String?)> readHotelRoomAvailability({
    required UHotelRoomAvailabilityParams p,
    Function(UResponse<List<UHotelRoomAvailabilityResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelRoom/Availability", p.toMap(), _Api.list(UHotelRoomAvailabilityResponse.fromMap), _Api.empty, onOk, onError, onException, locale: true);

  Future<(UResponse<UHotelReservationResponse>?, UEmptyResponse?, String?)> bookHotelReservation({
    required UHotelReservationBookParams p,
    Function(UResponse<UHotelReservationResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelReservation/Book", p.toMap(), _Api.one(UHotelReservationResponse.fromMap), _Api.empty, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> cancelHotelReservationByUser({
    required UHotelReservationCancelParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/HotelReservation/CancelByUser", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException, locale: true);
}
