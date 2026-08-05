part of "../data.dart";

// SystemAdmin-only client for the PgAdmin-style database console. Every call carries the apiKey + token
// so the backend GuardAdmin can reject non-admins.
class DbAdminService {
  Future<(UResponse<List<UDbTableResponse>>?, UEmptyResponse?, String?)> tables({
    required final UDbAdminTablesParams p,
    required final Function(UResponse<List<UDbTableResponse>> r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) async {
    (UResponse<List<UDbTableResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/Tables",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<List<UDbTableResponse>> ok = UResponse<List<UDbTableResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UDbTableResponse>.from((i as List<dynamic>).map((dynamic x) => UDbTableResponse.fromMap(x))),
        );
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

  Future<(UResponse<UDbTableSchemaResponse>?, UEmptyResponse?, String?)> schema({
    required final UDbAdminSchemaParams p,
    required final Function(UResponse<UDbTableSchemaResponse> r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) async {
    (UResponse<UDbTableSchemaResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/Schema",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UDbTableSchemaResponse> ok = UResponse<UDbTableSchemaResponse>.fromJson(r.body, (dynamic i) => UDbTableSchemaResponse.fromMap(i));
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

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> rows({
    required final UDbAdminRowsParams p,
    required final Function(UResponse<UDbQueryResultResponse> r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) => _query("Rows", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> query({
    required final UDbAdminQueryParams p,
    required final Function(UResponse<UDbQueryResultResponse> r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) => _query("Query", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> updateRow({
    required final UDbAdminUpdateRowParams p,
    required final Function(UResponse<UDbQueryResultResponse> r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) => _query("UpdateRow", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> insertRow({
    required final UDbAdminInsertRowParams p,
    required final Function(UResponse<UDbQueryResultResponse> r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) => _query("InsertRow", p.toMap(), onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteRow({
    required final UDbAdminDeleteRowParams p,
    required final Function(UEmptyResponse r) onOk,
    required final Function(UEmptyResponse e) onError,
    required final Function(String e) onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/DeleteRow",
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

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> _query(
    final String path,
    final Map<String, dynamic> body,
    final Function(UResponse<UDbQueryResultResponse> r) onOk,
    final Function(UEmptyResponse e) onError,
    final Function(String e) onException,
  ) async {
    (UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/$path",
      body: body.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UDbQueryResultResponse> ok = UResponse<UDbQueryResultResponse>.fromJson(r.body, (dynamic i) => UDbQueryResultResponse.fromMap(i));
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
