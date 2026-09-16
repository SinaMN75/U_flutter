part of "../data.dart";

class DbAdminService {
  Future<(UResponse<List<UDbAdminTableResponse>>?, UEmptyResponse?, String?)> tables({
    required UDbAdminTablesParams p,
    required Function(UResponse<List<UDbAdminTableResponse>> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<List<UDbAdminTableResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/Tables",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UDbAdminTableResponse>> ok = UResponse<List<UDbAdminTableResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UDbAdminTableResponse>.from((i as List<dynamic>).map((dynamic x) => UDbAdminTableResponse.fromMap(x))),
        );
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }

  Future<(UResponse<UDbAdminTableSchemaResponse>?, UEmptyResponse?, String?)> schema({
    required UDbAdminTableSchemaParams p,
    required Function(UResponse<UDbAdminTableSchemaResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<UDbAdminTableSchemaResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/Schema",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDbAdminTableSchemaResponse> ok = UResponse<UDbAdminTableSchemaResponse>.fromJson(r.body, (dynamic i) => UDbAdminTableSchemaResponse.fromMap(i));
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }

  Future<(UResponse<UDbAdminQueryResultResponse>?, UEmptyResponse?, String?)> rows({
    required UDbAdminRowsParams p,
    required Function(UResponse<UDbAdminQueryResultResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _query("Rows", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbAdminQueryResultResponse>?, UEmptyResponse?, String?)> query({
    required UDbAdminQueryParams p,
    required Function(UResponse<UDbAdminQueryResultResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _query("Query", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbAdminQueryResultResponse>?, UEmptyResponse?, String?)> updateRow({
    required UDbAdminUpdateRowParams p,
    required Function(UResponse<UDbAdminQueryResultResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _query("UpdateRow", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbAdminQueryResultResponse>?, UEmptyResponse?, String?)> insertRow({
    required UDbAdminInsertRowParams p,
    required Function(UResponse<UDbAdminQueryResultResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _query("InsertRow", p.toMap(), onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteRow({
    required UDbAdminDeleteRowParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/DeleteRow",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }

  Future<(UResponse<UDbAdminQueryResultResponse>?, UEmptyResponse?, String?)> _query(
    String path,
    Map<String, dynamic> body,
    Function(UResponse<UDbAdminQueryResultResponse> r) onOk,
    Function(UEmptyResponse e) onError,
    Function(String e) onException,
  ) async {
    (UResponse<UDbAdminQueryResultResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/$path",
      body: body.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDbAdminQueryResultResponse> ok = UResponse<UDbAdminQueryResultResponse>.fromJson(r.body, (dynamic i) => UDbAdminQueryResultResponse.fromMap(i));
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }
}
