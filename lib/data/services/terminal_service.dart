part of "../data.dart";

class TerminalService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UTerminalCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> bulkCreate({
    required UTerminalBulkCreateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/BulkCreate", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UTerminalImportResponse>?, UEmptyResponse?, String?)> import({
    required UTerminalImportParams p,
    Function(UResponse<UTerminalImportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/Import", p.toMap(), _Api.one(UTerminalImportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UTerminalResponse>>?, UEmptyResponse?, String?)> read({
    required UTerminalReadParams p,
    Function(UResponse<List<UTerminalResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) =>
      _Api.call("/terminal/Read", p.toMap(), _Api.list(UTerminalResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UTerminalSupportPasswordResponse>?, UEmptyResponse?, String?)> readSupportPassword({
    required UIdParams p,
    Function(UResponse<UTerminalSupportPasswordResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/ReadSupportPassword", p.toMap(), _Api.one(UTerminalSupportPasswordResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UTerminalAvailabilityResponse>?, UEmptyResponse?, String?)> checkAvailability({
    required UTerminalAssignParams p,
    Function(UResponse<UTerminalAvailabilityResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/CheckAvailability", p.toMap(), _Api.one(UTerminalAvailabilityResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UTerminalResponse>?, UEmptyResponse?, String?)> assign({
    required UTerminalAssignParams p,
    Function(UResponse<UTerminalResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/Assign", p.toMap(), _Api.one(UTerminalResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UTerminalResponse>?, UEmptyResponse?, String?)> approve({
    required UIdParams p,
    Function(UResponse<UTerminalResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/Approve", p.toMap(), _Api.one(UTerminalResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> reject({
    required UTerminalRejectParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/Reject", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UTerminalUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createBrand({
    required UTerminalBrandCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/CreateBrand", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UTerminalBrandResponse>>?, UEmptyResponse?, String?)> readBrand({
    required UTerminalBrandReadParams p,
    Function(UResponse<List<UTerminalBrandResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) =>
      _Api.call("/terminal/ReadBrand", p.toMap(), _Api.list(UTerminalBrandResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateBrand({
    required UTerminalBrandUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/UpdateBrand", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteBrand({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/DeleteBrand", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createBroker({
    required UTerminalBrokerCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/CreateBroker", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UTerminalBrokerResponse>>?, UEmptyResponse?, String?)> readBroker({
    required UTerminalBrokerReadParams p,
    Function(UResponse<List<UTerminalBrokerResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) =>
      _Api.call("/terminal/ReadBroker", p.toMap(), _Api.list(UTerminalBrokerResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateBroker({
    required UTerminalBrokerUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/UpdateBroker", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteBroker({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/terminal/DeleteBroker", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
