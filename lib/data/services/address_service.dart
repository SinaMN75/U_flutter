part of "../data.dart";

class AddressService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UAddressCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/address/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UAddressResponse>>?, UEmptyResponse?, String?)> read({
    required UAddressReadParams p,
    Function(UResponse<List<UAddressResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/address/Read", p.toMap(), _Api.list(UAddressResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UAddressUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/address/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/address/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
