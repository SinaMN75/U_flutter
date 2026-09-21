part of "../data.dart";

class UCommentService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UCommentCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/comment/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCommentResponse>>?, UEmptyResponse?, String?)> read({
    required UCommentReadParams p,
    Function(UResponse<List<UCommentResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/comment/Read", p.toMap(), _Api.list(UCommentResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UCommentResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UCommentResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/comment/ReadById", p.toMap(), _Api.one(UCommentResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UCommentUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/comment/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/comment/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<int>?, UEmptyResponse?, String?)> readProductCommentCount({
    required UIdParams p,
    Function(UResponse<int> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/comment/ReadProductCommentCount", p.toMap(), _Api.raw<int>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<int>?, UEmptyResponse?, String?)> readUserCommentCount({
    required UIdParams p,
    Function(UResponse<int> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/comment/ReadUserCommentCount", p.toMap(), _Api.raw<int>(), _Api.empty, onOk, onError, onException);
}
