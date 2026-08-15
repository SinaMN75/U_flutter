part of "../data.dart";

class DbAdminService {
  Future<(UResponse<List<UDbTableResponse>>?, UEmptyResponse?, String?)> tables({
    required UDbAdminTablesParams p,
    required Function(UResponse<List<UDbTableResponse>> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<List<UDbTableResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/Tables",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UDbTableResponse>> ok = UResponse<List<UDbTableResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UDbTableResponse>.from((i as List<dynamic>).map((dynamic x) => UDbTableResponse.fromMap(x))),
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

  Future<(UResponse<UDbTableSchemaResponse>?, UEmptyResponse?, String?)> schema({
    required UDbAdminSchemaParams p,
    required Function(UResponse<UDbTableSchemaResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<UDbTableSchemaResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/Schema",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDbTableSchemaResponse> ok = UResponse<UDbTableSchemaResponse>.fromJson(r.body, (dynamic i) => UDbTableSchemaResponse.fromMap(i));
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

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> rows({
    required UDbAdminRowsParams p,
    required Function(UResponse<UDbQueryResultResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _query("Rows", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> query({
    required UDbAdminQueryParams p,
    required Function(UResponse<UDbQueryResultResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _query("Query", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> updateRow({
    required UDbAdminUpdateRowParams p,
    required Function(UResponse<UDbQueryResultResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _query("UpdateRow", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> insertRow({
    required UDbAdminInsertRowParams p,
    required Function(UResponse<UDbQueryResultResponse> r) onOk,
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

  // Applies all pending EF Core migrations via the DataSeeder/Migrate endpoint (auth is the apiKey query param).
  Future<void> migrate({
    required Function(List<String> applied) onOk,
    required Function(String e) onError,
  }) async {
    await UHttpClient.send(
      method: "GET",
      endpoint: "${U.baseUrl}/DataSeeder/Migrate?key=${Uri.encodeQueryComponent(U.apiKey)}",
      onSuccess: (Response r) {
        final Map<String, dynamic> body = json.decode(r.body) as Map<String, dynamic>;
        onOk(List<String>.from((body["applied"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x.toString())));
      },
      onError: (Response r) => onError(r.body),
      onException: onError,
    );
  }

  Future<(UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?)> _query(
    String path,
    Map<String, dynamic> body,
    Function(UResponse<UDbQueryResultResponse> r) onOk,
    Function(UEmptyResponse e) onError,
    Function(String e) onException,
  ) async {
    (UResponse<UDbQueryResultResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/DbAdmin/$path",
      body: body.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDbQueryResultResponse> ok = UResponse<UDbQueryResultResponse>.fromJson(r.body, (dynamic i) => UDbQueryResultResponse.fromMap(i));
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
