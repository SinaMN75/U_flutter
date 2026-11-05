part of "../data.dart";

class UWalletService {
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

  /// Opens (or returns) a wallet in [UWalletOpenParams.currency] for the user; empty currency means the server's default.
  Future<(UResponse<UWalletResponse>?, UEmptyResponse?, String?)> open({
    required UWalletOpenParams p,
    Function(UResponse<UWalletResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/Open", p.toMap(), _Api.one(UWalletResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UWalletReportResponse>?, UEmptyResponse?, String?)> readReport({
    required UWalletReportParams p,
    Function(UResponse<UWalletReportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/ReadReport", p.toMap(), _Api.one(UWalletReportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UWalletLedgerCheckResponse>?, UEmptyResponse?, String?)> readLedgerCheck({
    Function(UResponse<UWalletLedgerCheckResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/ReadLedgerCheck", <String, dynamic>{}, _Api.one(UWalletLedgerCheckResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> resolveMismatch({
    required UWalletResolveMismatchParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/wallet/ResolveMismatch", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
