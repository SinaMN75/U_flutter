part of "../data.dart";

class MerchantService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UMerchantCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Merchant/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UMerchantResponse>>?, UEmptyResponse?, String?)> read({
    required UMerchantReadParams p,
    Function(UResponse<List<UMerchantResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Merchant/Read", p.toMap(), _Api.list(UMerchantResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UMerchantResponse>?, UEmptyResponse?, String?)> readById({
    required UIdParams p,
    Function(UResponse<UMerchantResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Merchant/ReadById", p.toMap(), _Api.one(UMerchantResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Merchant/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
