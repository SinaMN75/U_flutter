part of "../data.dart";

class ProductService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UProductCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/product/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> bulkCreate({
    required List<UProductCreateParams> p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/product/BulkCreate", <String, dynamic>{"list": List<dynamic>.from(p.map((UProductCreateParams x) => x.toMap()))}, _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UProductResponse>>?, UEmptyResponse?, String?)> read({
    required UProductReadParams p,
    Function(UResponse<List<UProductResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/product/Read", p.toMap(), _Api.list(UProductResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UProductResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UProductResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/product/ReadById", p.toMap(), _Api.one(UProductResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UProductUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/product/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/product/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteRange({
    required UIdListParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/product/DeleteRange", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
