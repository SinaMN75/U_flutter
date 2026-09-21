part of "../data.dart";

class UChargeInternetService {
  Future<(UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?)> pin({
    required UReserveChargeParams p,
    Function(UResponse<UChargeInternetReserveResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ChargeInternet/Pin", p.toMap(), _Api.one(UChargeInternetReserveResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?)> topup({
    required UTopupChargeParams p,
    Function(UResponse<UChargeInternetReserveResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ChargeInternet/Topup", p.toMap(), _Api.one(UChargeInternetReserveResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UInternetPackageResponse>?, UEmptyResponse?, String?)> internetList({
    required UInternetListParams p,
    Function(UResponse<UInternetPackageResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ChargeInternet/InternetList", p.toMap(), _Api.one(UInternetPackageResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?)> internetReserve({
    required UInternetReserveParams p,
    Function(UResponse<UChargeInternetReserveResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ChargeInternet/InternetReserve", p.toMap(), _Api.one(UChargeInternetReserveResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGetStatusResponse>?, UEmptyResponse?, String?)> getStatus({
    required UGetStatusParams p,
    Function(UResponse<UGetStatusResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ChargeInternet/GetStatus", p.toMap(), _Api.one(UGetStatusResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGetBalanceResponse>?, UEmptyResponse?, String?)> getBalance({
    required UBaseParams p,
    Function(UResponse<UGetBalanceResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ChargeInternet/GetBalance", p.toMap(), _Api.one(UGetBalanceResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UEchoResponse>?, UEmptyResponse?, String?)> echo({
    required UBaseParams p,
    Function(UResponse<UEchoResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ChargeInternet/Echo", p.toMap(), _Api.one(UEchoResponse.fromMap), _Api.empty, onOk, onError, onException);
}
