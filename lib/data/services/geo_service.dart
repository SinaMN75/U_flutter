part of "../data.dart";

/// Countries, cities, places and visa rules (backend module Geo).
class UGeoService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createCountry({
    required UCountryCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Country/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCountryResponse>>?, UEmptyResponse?, String?)> readCountries({
    required UCountryReadParams p,
    Function(UResponse<List<UCountryResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Country/Read", p.toMap(), _Api.list(UCountryResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UCountryResponse>?, UEmptyResponse?, String?)> readCountryById({
    required UCountryReadByIdParams p,
    Function(UResponse<UCountryResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Country/ReadById", p.toMap(), _Api.one(UCountryResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateCountry({
    required UCountryUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Country/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteCountry({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Country/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createCity({
    required UCityCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/City/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCityResponse>>?, UEmptyResponse?, String?)> readCities({
    required UCityReadParams p,
    Function(UResponse<List<UCityResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/City/Read", p.toMap(), _Api.list(UCityResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateCity({
    required UCityUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/City/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteCity({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/City/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createPlace({
    required UPlaceCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Place/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UPlaceResponse>>?, UEmptyResponse?, String?)> readPlaces({
    required UPlaceReadParams p,
    Function(UResponse<List<UPlaceResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Place/Read", p.toMap(), _Api.list(UPlaceResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UPlaceResponse>?, UEmptyResponse?, String?)> readPlaceById({
    required UIdParams p,
    Function(UResponse<UPlaceResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Place/ReadById", p.toMap(), _Api.one(UPlaceResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updatePlace({
    required UPlaceUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Place/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deletePlace({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/Place/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createVisaRule({
    required UVisaRuleCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/VisaRule/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UVisaRuleResponse>>?, UEmptyResponse?, String?)> readVisaRules({
    required UVisaRuleReadParams p,
    Function(UResponse<List<UVisaRuleResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/VisaRule/Read", p.toMap(), _Api.list(UVisaRuleResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateVisaRule({
    required UVisaRuleUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/VisaRule/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteVisaRule({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Geo/VisaRule/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
