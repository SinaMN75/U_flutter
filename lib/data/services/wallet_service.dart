part of "../data.dart";

class WalletService {
  Future<(UEmptyResponse?, UEmptyResponse?, String?)> charge({
    required UWalletChargeParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/Charge", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UWalletTxnResponse>?, UEmptyResponse?, String?)> transfer({
    required UWalletTransferParams p,
    Function(UResponse<UWalletTxnResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/Transfer", p.toMap(), _Api.one(UWalletTxnResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> purchase({
    required UWalletPurchaseParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/Purchase", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UWalletResponse>>?, UEmptyResponse?, String?)> read({
    required UWalletReadParams p,
    Function(UResponse<List<UWalletResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/Read", p.toMap(), _Api.list(UWalletResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UWalletResponse>>?, UEmptyResponse?, String?)> readByUserId({
    required UIdParams p,
    Function(UResponse<List<UWalletResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/ReadByUserId", p.toMap(), _Api.list(UWalletResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UWalletTxnResponse>>?, UEmptyResponse?, String?)> readTxn({
    required UWalletTxnReadParams p,
    Function(UResponse<List<UWalletTxnResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/ReadTxn", p.toMap(), _Api.list(UWalletTxnResponse.fromMap), _Api.empty, onOk, onError, onException);
}
