part of "../data.dart";

class ContentService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UContentCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/content/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UContentResponse>>?, UEmptyResponse?, String?)> read({
    required UContentReadParams p,
    Function(UResponse<List<UContentResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/content/Read", p.toMap(), _Api.list(UContentResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UContentResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UContentResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/content/ReadById", p.toMap(), _Api.one(UContentResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UContentUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/content/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/content/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteRange({
    required UIdListParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/content/DeleteRange", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
