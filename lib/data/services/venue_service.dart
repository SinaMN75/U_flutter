part of "../data.dart";

class UVenueService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createVenue({
    required UVenueCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Venue/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UVenueResponse>>?, UEmptyResponse?, String?)> readVenues({
    required UVenueReadParams p,
    Function(UResponse<List<UVenueResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Venue/Read", p.toMap(), _Api.list(UVenueResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UVenueResponse>?, UEmptyResponse?, String?)> readVenueById({
    required UIdParams p,
    Function(UResponse<UVenueResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Venue/ReadById", p.toMap(), _Api.one(UVenueResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateVenue({
    required UVenueUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Venue/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteVenue({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Venue/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UVenueStatsResponse>?, UEmptyResponse?, String?)> readVenueStats({
    required UVenueStatsParams p,
    Function(UResponse<UVenueStatsResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Venue/Stats", p.toMap(), _Api.one(UVenueStatsResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createCourt({
    required UCourtCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Court/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCourtResponse>>?, UEmptyResponse?, String?)> readCourts({
    required UCourtReadParams p,
    Function(UResponse<List<UCourtResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Court/Read", p.toMap(), _Api.list(UCourtResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateCourt({
    required UCourtUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Court/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteCourt({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Court/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCourtAvailabilityResponse>>?, UEmptyResponse?, String?)> readCourtAvailability({
    required UCourtAvailabilityParams p,
    Function(UResponse<List<UCourtAvailabilityResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Court/Availability", p.toMap(), _Api.list(UCourtAvailabilityResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UBookingResponse>?, UEmptyResponse?, String?)> createBooking({
    required UBookingCreateParams p,
    Function(UResponse<UBookingResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Booking/Create", p.toMap(), _Api.one(UBookingResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UBookingResponse>>?, UEmptyResponse?, String?)> readBookings({
    required UBookingReadParams p,
    Function(UResponse<List<UBookingResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Booking/Read", p.toMap(), _Api.list(UBookingResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateBooking({
    required UBookingUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Booking/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> cancelBooking({
    required UBookingCancelParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Booking/Cancel", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> payBookingShare({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Venue/Booking/PayShare", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
