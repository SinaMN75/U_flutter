part of "../data.dart";

class UBlogService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UBlogCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Blog/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UBlogResponse>>?, UEmptyResponse?, String?)> read({
    required UBlogReadParams p,
    Function(UResponse<List<UBlogResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Blog/Read", p.toMap(), _Api.list(UBlogResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UBlogResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UBlogResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Blog/ReadById", p.toMap(), _Api.one(UBlogResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UBlogUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Blog/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Blog/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteRange({
    required UIdListParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Blog/DeleteRange", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
