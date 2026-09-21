part of "../data.dart";

class UVehicleService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UVehicleCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/vehicle/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UVehicleResponse>>?, UEmptyResponse?, String?)> read({
    required UVehicleReadParams p,
    Function(UResponse<List<UVehicleResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/vehicle/Read", p.toMap(), _Api.list(UVehicleResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UVehicleUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/vehicle/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/vehicle/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
