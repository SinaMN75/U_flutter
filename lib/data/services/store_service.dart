part of "../data.dart";

class UStoreService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UStoreCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UStoreResponse>>?, UEmptyResponse?, String?)> read({
    required UStoreReadParams p,
    Function(UResponse<List<UStoreResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Read", p.toMap(), _Api.list(UStoreResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UStoreResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UStoreResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/ReadById", p.toMap(), _Api.one(UStoreResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UStoreResponse>?, UEmptyResponse?, String?)> readByCode({
    required UStoreCodeParams p,
    Function(UResponse<UStoreResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/ReadByCode", p.toMap(), _Api.one(UStoreResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> review({
    required UStoreReviewParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Review", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UStoreUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Store/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createType({
    required UStoreTypeCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/StoreType/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UStoreTypeResponse>>?, UEmptyResponse?, String?)> readTypes({
    required UStoreTypeReadParams p,
    Function(UResponse<List<UStoreTypeResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/StoreType/Read", p.toMap(), _Api.list(UStoreTypeResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateType({
    required UStoreTypeUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/StoreType/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteType({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/StoreType/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createProduct({
    required UProductCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UProductResponse>>?, UEmptyResponse?, String?)> readProducts({
    required UProductReadParams p,
    Function(UResponse<List<UProductResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Read", p.toMap(), _Api.list(UProductResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UProductResponse>?, UEmptyResponse?, String?)> readProductById({
    required UIdParams p,
    Function(UResponse<UProductResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/ReadById", p.toMap(), _Api.one(UProductResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateProduct({
    required UProductUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteProduct({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Store/Product/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
