part of "../data.dart";

class UFollowService {
  Future<(UEmptyResponse?, UEmptyResponse?, String?)> follow({
    required UFollowParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/follow/Follow", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> unfollow({
    required UFollowParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/follow/Unfollow", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UUserResponse>>?, UEmptyResponse?, String?)> readFollowedUsers({
    required UIdParams p,
    Function(UResponse<List<UUserResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/follow/ReadFollowedUsers", p.toMap(), _Api.list(UUserResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<bool>?, UEmptyResponse?, String?)> isFollowingUser({
    required UFollowParams p,
    Function(UResponse<bool> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/follow/IsFollowingUser", p.toMap(), _Api.raw<bool>(), _Api.empty, onOk, onError, onException);
}
