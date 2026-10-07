part of "../data.dart";

class UOrganizationService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createOrganization({
    required UOrganizationCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Organization/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UOrganizationResponse>>?, UEmptyResponse?, String?)> readOrganizations({
    required UOrganizationReadParams p,
    Function(UResponse<List<UOrganizationResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Organization/Read", p.toMap(), _Api.list(UOrganizationResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateOrganization({
    required UOrganizationUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Organization/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> setOrganizationMember({
    required UOrganizationMemberParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Organization/SetMember", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> removeOrganizationMember({
    required UOrganizationMemberParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Organization/RemoveMember", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
