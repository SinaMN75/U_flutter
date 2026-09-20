part of "../data.dart";

class CategoryService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UCategoryCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/category/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> bulkCreate({
    required List<UCategoryCreateParams> p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/category/BulkCreate", <String, dynamic>{"list": List<dynamic>.from(p.map((UCategoryCreateParams x) => x.toMap()))}, _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCategoryResponse>>?, UEmptyResponse?, String?)> read({
    required UCategoryReadParams p,
    Function(UResponse<List<UCategoryResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/category/Read", p.toMap(), _Api.list(UCategoryResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UCategoryResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UCategoryResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/category/ReadById", p.toMap(), _Api.one(UCategoryResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UCategoryUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/category/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/category/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
