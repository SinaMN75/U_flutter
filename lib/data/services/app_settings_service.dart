part of "../data.dart";

class AppSettingsService {
  Future<(UResponse<UAppSettingsResponse>?, UEmptyResponse?, String?)> read({
    required final UAppSettingsReadParams p,
    final Function(UResponse<UAppSettingsResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UAppSettingsResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/AppSettings/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UAppSettingsResponse> ok = UResponse<UAppSettingsResponse>.fromJson(r.body, (final dynamic i) => UAppSettingsResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  // Full config for the SystemAdmin editor (secrets masked).
  Future<(UResponse<UAppSettings>?, UEmptyResponse?, String?)> readAll({
    required final Function(UResponse<UAppSettings> r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) async {
    (UResponse<UAppSettings>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/AppSettings/ReadAll",
      body: <String, dynamic>{"apiKey": U.apiKey, "token": ULocalStorage.getToken()},
      onSuccess: (final Response r) {
        final UResponse<UAppSettings> ok = UResponse<UAppSettings>.fromJson(r.body, (final dynamic i) => UAppSettings.fromMap(i));
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }

  // Applies edits live to Core.App on the server (in-memory only).
  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required final UAppSettingsUpdateParams p,
    required final Function(UEmptyResponse r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/AppSettings/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }
}
