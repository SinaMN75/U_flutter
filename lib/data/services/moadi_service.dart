part of "../data.dart";

class MoadiService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UMoadiCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Moadi/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UMoadiResponse>>?, UEmptyResponse?, String?)> read({
    required UMoadiReadParams p,
    Function(UResponse<List<UMoadiResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Moadi/Read", p.toMap(), _Api.list(UMoadiResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UMoadiResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UMoadiResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Moadi/ReadById", p.toMap(), _Api.one(UMoadiResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UMoadiUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Moadi/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UMoadiResponse>?, UEmptyResponse?, String?)> approve({
    required UIdParams p,
    Function(UResponse<UMoadiResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Moadi/Approve", p.toMap(), _Api.one(UMoadiResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> reject({
    required UMoadiRejectParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Moadi/Reject", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Moadi/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
