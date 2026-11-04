part of "../data.dart";

class UExchangeRateService {
  Future<(UResponse<UExchangeRateMarketResponse>?, UEmptyResponse?, String?)> readMarket({
    Function(UResponse<UExchangeRateMarketResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ExchangeRate/ReadMarket", <String, dynamic>{}, _Api.one(UExchangeRateMarketResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UExchangeRateRatesResponse>?, UEmptyResponse?, String?)> readRates({
    required UExchangeRateReadRatesParams p,
    Function(UResponse<UExchangeRateRatesResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ExchangeRate/ReadRates", p.toMap(), _Api.one(UExchangeRateRatesResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UExchangeRateHistoryResponse>?, UEmptyResponse?, String?)> readHistory({
    required UExchangeRateReadHistoryParams p,
    Function(UResponse<UExchangeRateHistoryResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/ExchangeRate/ReadHistory", p.toMap(), _Api.one(UExchangeRateHistoryResponse.fromMap), _Api.empty, onOk, onError, onException);
}
