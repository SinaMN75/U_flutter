part of "../data.dart";

// Talks to the backend Gold routes, which front whichever gold provider the server is configured for.
class GoldService {
  Future<(UResponse<UGoldAccountResponse>?, UEmptyResponse?, String?)> readAccount({
    Function(UResponse<UGoldAccountResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadAccount", <String, dynamic>{}, _Api.one(UGoldAccountResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldQuoteResponse>?, UEmptyResponse?, String?)> readQuote({
    required UGoldQuoteParams p,
    Function(UResponse<UGoldQuoteResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadQuote", p.toMap(), _Api.one(UGoldQuoteResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldUserBalanceResponse>?, UEmptyResponse?, String?)> readUserBalance({
    Function(UResponse<UGoldUserBalanceResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
    UGoldReadUserBalanceParams? p,
  }) => _Api.call("/Gold/ReadUserBalance", (p ?? UGoldReadUserBalanceParams()).toMap(), _Api.one(UGoldUserBalanceResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldTxnResponse>?, UEmptyResponse?, String?)> buy({
    required UGoldBuyParams p,
    Function(UResponse<UGoldTxnResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/Buy", p.toMap(), _Api.one(UGoldTxnResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldTxnResponse>?, UEmptyResponse?, String?)> sell({
    required UGoldSellParams p,
    Function(UResponse<UGoldTxnResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/Sell", p.toMap(), _Api.one(UGoldTxnResponse.fromMap), _Api.empty, onOk, onError, onException);

  // Settles a transaction the provider left pending; call it when the user opens the order, never on a timer.
  Future<(UResponse<UGoldTxnResponse>?, UEmptyResponse?, String?)> syncTxn({
    required UIdParams p,
    Function(UResponse<UGoldTxnResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/SyncTxn", p.toMap(), _Api.one(UGoldTxnResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UGoldTxnResponse>>?, UEmptyResponse?, String?)> readUserTxns({
    required UGoldReadUserTxnsParams p,
    Function(UResponse<List<UGoldTxnResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadUserTxns", p.toMap(), _Api.list(UGoldTxnResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldOrderResponse>?, UEmptyResponse?, String?)> createOrder({
    required UGoldCreateOrderParams p,
    Function(UResponse<UGoldOrderResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/CreateOrder", p.toMap(), _Api.one(UGoldOrderResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldOrderListResponse>?, UEmptyResponse?, String?)> readOrders({
    required UGoldReadOrdersParams p,
    Function(UResponse<UGoldOrderListResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadOrders", p.toMap(), _Api.one(UGoldOrderListResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldOrderResponse>?, UEmptyResponse?, String?)> readOrderById({
    required UGoldReadOrderParams p,
    Function(UResponse<UGoldOrderResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadOrderById", p.toMap(), _Api.one(UGoldOrderResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UGoldBalanceResponse>>?, UEmptyResponse?, String?)> readBalances({
    Function(UResponse<List<UGoldBalanceResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadBalances", <String, dynamic>{}, _Api.list(UGoldBalanceResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldBalanceResponse>?, UEmptyResponse?, String?)> readBalance({
    required UGoldReadBalanceParams p,
    Function(UResponse<UGoldBalanceResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadBalance", p.toMap(), _Api.one(UGoldBalanceResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldTransactionListResponse>?, UEmptyResponse?, String?)> readTransactions({
    required UGoldReadTransactionsParams p,
    Function(UResponse<UGoldTransactionListResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadTransactions", p.toMap(), _Api.one(UGoldTransactionListResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldTradeLimitsResponse>?, UEmptyResponse?, String?)> readTradeLimits({
    Function(UResponse<UGoldTradeLimitsResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadTradeLimits", <String, dynamic>{}, _Api.one(UGoldTradeLimitsResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldCreditFacilitiesResponse>?, UEmptyResponse?, String?)> readCreditFacilities({
    Function(UResponse<UGoldCreditFacilitiesResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadCreditFacilities", <String, dynamic>{}, _Api.one(UGoldCreditFacilitiesResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UGoldApiTokenResponse>?, UEmptyResponse?, String?)> createApiToken({
    required UGoldCreateApiTokenParams p,
    Function(UResponse<UGoldApiTokenResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/CreateApiToken", p.toMap(), _Api.one(UGoldApiTokenResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UGoldApiTokenResponse>>?, UEmptyResponse?, String?)> readApiTokens({
    Function(UResponse<List<UGoldApiTokenResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/ReadApiTokens", <String, dynamic>{}, _Api.list(UGoldApiTokenResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteApiToken({
    required UGoldDeleteApiTokenParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Gold/DeleteApiToken", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
