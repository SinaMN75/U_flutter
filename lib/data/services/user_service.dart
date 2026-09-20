part of "../data.dart";

class UserService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UUserCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/user/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> bulkCreate({
    required UUserBulkCreateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/user/BulkCreate", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UUserResponse>>?, UEmptyResponse?, String?)> read({
    required UUserReadParams p,
    Function(UResponse<List<UUserResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/User/Read", p.toMap(), _Api.list(UUserResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UUserResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UUserResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
    Function(int e)? onProgress,
  }) =>
      _Api.call("/user/ReadById", p.toMap(), _Api.one(UUserResponse.fromMap), _Api.empty, onOk, onError, onException, onProgress: onProgress);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UUserUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/user/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/user/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> downloadUserData({
    required UIdParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/user/DownloadUserData", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);
}
