part of "../data.dart";

class HotelService {
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

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDorm({
    required UDormCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Dorm/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UDormResponse>>?, UEmptyResponse?, String?)> readDorms({
    required UDormReadParams p,
    Function(UResponse<List<UDormResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Dorm/Read", p.toMap(), _Api.list(UDormResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDormResponse>?, UEmptyResponse?, String?)> readDormById({
    required UIdParams p,
    Function(UResponse<UDormResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Dorm/ReadById", p.toMap(), _Api.one(UDormResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDorm({
    required UDormUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Dorm/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDorm({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/Dorm/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDormRoom({
    required UDormRoomCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormRoom/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UDormRoomResponse>>?, UEmptyResponse?, String?)> readDormRooms({
    required UDormRoomReadParams p,
    Function(UResponse<List<UDormRoomResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormRoom/Read", p.toMap(), _Api.list(UDormRoomResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDormRoomResponse>?, UEmptyResponse?, String?)> readDormRoomById({
    required UIdParams p,
    Function(UResponse<UDormRoomResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormRoom/ReadById", p.toMap(), _Api.one(UDormRoomResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDormRoom({
    required UDormRoomUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormRoom/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDormRoom({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormRoom/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDormBed({
    required UDormBedCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBed/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UDormBedResponse>>?, UEmptyResponse?, String?)> readDormBeds({
    required UDormBedReadParams p,
    Function(UResponse<List<UDormBedResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBed/Read", p.toMap(), _Api.list(UDormBedResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDormBedResponse>?, UEmptyResponse?, String?)> readDormBedById({
    required UIdParams p,
    Function(UResponse<UDormBedResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBed/ReadById", p.toMap(), _Api.one(UDormBedResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDormBed({
    required UDormBedUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBed/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDormBed({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBed/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createDormBedContract({
    required UDormBedContractCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedContract/Create", p.toMap(), _Api.raw<String>(), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UDormBedContractResponse>>?, UResponse<dynamic>?, String?)> readDormBedContract({
    required UDormBedContractReadParams p,
    Function(UResponse<List<UDormBedContractResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedContract/Read", p.toMap(), _Api.list(UDormBedContractResponse.fromMap), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> updateDormBedContract({
    required UDormBedContractUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedContract/Update", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<dynamic>?, UResponse<dynamic>?, String?)> deleteDormBedContract({
    required UIdParams p,
    Function(UResponse<dynamic> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedContract/Delete", p.toMap(), _Api.dyn, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createDormBedInvoice({
    required UDormBedInvoiceCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedInvoice/Create", p.toMap(), _Api.raw<String>(), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UDormBedInvoiceResponse>>?, UResponse<dynamic>?, String?)> readDormBedInvoice({
    required UDormBedInvoiceReadParams p,
    Function(UResponse<List<UDormBedInvoiceResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedInvoice/Read", p.toMap(), _Api.list(UDormBedInvoiceResponse.fromMap), _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> updateDormBedInvoice({
    required UDormBedInvoiceUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedInvoice/Update", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<dynamic>?, UResponse<dynamic>?, String?)> deleteDormBedInvoice({
    required UIdParams p,
    Function(UResponse<dynamic> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedInvoice/Delete", p.toMap(), _Api.dyn, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> payDormBedInvoice({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedInvoice/Pay", p.toMap(), _Api.empty, _Api.dyn, onOk, onError, onException, locale: true);

  Future<(UResponse<List<UDormBedInvoiceChartResponse>>?, UEmptyResponse?, String?)> readDormBedInvoiceChartData({
    Function(UResponse<List<UDormBedInvoiceChartResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Hotel/DormBedInvoice/ChartData", <String, dynamic>{}, _Api.list(UDormBedInvoiceChartResponse.fromMap), _Api.empty, onOk, onError, onException);

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
