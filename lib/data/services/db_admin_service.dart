part of "../data.dart";

class UDbAdminService {
  Future<(UResponse<List<UDbAdminTableResponse>>?, UEmptyResponse?, String?)> tables({
    required UDbAdminTablesParams p,
    required Function(UResponse<List<UDbAdminTableResponse>> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/DbAdmin/Tables", p.toMap(), _Api.list(UDbAdminTableResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDbAdminTableSchemaResponse>?, UEmptyResponse?, String?)> schema({
    required UDbAdminTableSchemaParams p,
    required Function(UResponse<UDbAdminTableSchemaResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/DbAdmin/Schema", p.toMap(), _Api.one(UDbAdminTableSchemaResponse.fromMap), _Api.empty, onOk, onError, onException);

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
  }) => _Api.call("/DbAdmin/DeleteRow", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDbAdminQueryResultResponse>?, UEmptyResponse?, String?)> _query(
    String path,
    Map<String, dynamic> body,
    Function(UResponse<UDbAdminQueryResultResponse> r) onOk,
    Function(UEmptyResponse e) onError,
    Function(String e) onException,
  ) => _Api.call("/DbAdmin/$path", body, _Api.one(UDbAdminQueryResultResponse.fromMap), _Api.empty, onOk, onError, onException);
}
