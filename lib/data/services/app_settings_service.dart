part of "../data.dart";

class AppSettingsService {
  Future<(UResponse<UAppSettingsResponse>?, UEmptyResponse?, String?)> read({
    Function(UResponse<UAppSettingsResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/AppSettings/Read", <String, dynamic>{}, _Api.one(UAppSettingsResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UAppSettings>?, UEmptyResponse?, String?)> readAll({
    Function(UResponse<UAppSettings> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) =>
      _Api.call("/AppSettings/ReadAll", <String, dynamic>{}, _Api.one(UAppSettings.fromMap), _Api.empty, onOk, onError, onException);

  // Applies edits live to Core.App on the server (in-memory only).
  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UAppSettingsUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/AppSettings/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
