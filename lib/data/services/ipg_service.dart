part of "../data.dart";

class IpgService {
  Future<(UResponse<UIpgPayResponse>?, UEmptyResponse?, String?)> pay({
    required UIpgPayParams p,
    Function(UResponse<UIpgPayResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ipg/Pay", p.toMap(), _Api.one(UIpgPayResponse.fromMap), _Api.empty, onOk, onError, onException);
}
