part of "../data.dart";

// Talks to the backend Gold routes, which front whichever gold provider the server is configured for.
class GoldService {
  Future<(UResponse<UGoldAccountResponse>?, UEmptyResponse?, String?)> readAccount({
    required Function(UResponse<UGoldAccountResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldAccountResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadAccount",
      body: <String, dynamic>{}.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldAccountResponse> ok = UResponse<UGoldAccountResponse>.fromJson(r.body, (dynamic i) => UGoldAccountResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldQuoteResponse>?, UEmptyResponse?, String?)> readQuote({
    required UGoldQuoteParams p,
    required Function(UResponse<UGoldQuoteResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldQuoteResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadQuote",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldQuoteResponse> ok = UResponse<UGoldQuoteResponse>.fromJson(r.body, (dynamic i) => UGoldQuoteResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldOrderResponse>?, UEmptyResponse?, String?)> createOrder({
    required UGoldCreateOrderParams p,
    required Function(UResponse<UGoldOrderResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldOrderResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/CreateOrder",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldOrderResponse> ok = UResponse<UGoldOrderResponse>.fromJson(r.body, (dynamic i) => UGoldOrderResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldOrderListResponse>?, UEmptyResponse?, String?)> readOrders({
    required UGoldReadOrdersParams p,
    required Function(UResponse<UGoldOrderListResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldOrderListResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadOrders",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldOrderListResponse> ok = UResponse<UGoldOrderListResponse>.fromJson(r.body, (dynamic i) => UGoldOrderListResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldOrderResponse>?, UEmptyResponse?, String?)> readOrderById({
    required UGoldReadOrderParams p,
    required Function(UResponse<UGoldOrderResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldOrderResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadOrderById",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldOrderResponse> ok = UResponse<UGoldOrderResponse>.fromJson(r.body, (dynamic i) => UGoldOrderResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<List<UGoldBalanceResponse>>?, UEmptyResponse?, String?)> readBalances({
    required Function(UResponse<List<UGoldBalanceResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<List<UGoldBalanceResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadBalances",
      body: <String, dynamic>{}.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UGoldBalanceResponse>> ok = UResponse<List<UGoldBalanceResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UGoldBalanceResponse>.from((i as List<dynamic>).map((dynamic x) => UGoldBalanceResponse.fromMap(x))),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldBalanceResponse>?, UEmptyResponse?, String?)> readBalance({
    required UGoldReadBalanceParams p,
    required Function(UResponse<UGoldBalanceResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldBalanceResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadBalance",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldBalanceResponse> ok = UResponse<UGoldBalanceResponse>.fromJson(r.body, (dynamic i) => UGoldBalanceResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldTransactionListResponse>?, UEmptyResponse?, String?)> readTransactions({
    required UGoldReadTransactionsParams p,
    required Function(UResponse<UGoldTransactionListResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldTransactionListResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadTransactions",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldTransactionListResponse> ok = UResponse<UGoldTransactionListResponse>.fromJson(
          r.body,
          (dynamic i) => UGoldTransactionListResponse.fromMap(i),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldTradeLimitsResponse>?, UEmptyResponse?, String?)> readTradeLimits({
    required Function(UResponse<UGoldTradeLimitsResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldTradeLimitsResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadTradeLimits",
      body: <String, dynamic>{}.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldTradeLimitsResponse> ok = UResponse<UGoldTradeLimitsResponse>.fromJson(r.body, (dynamic i) => UGoldTradeLimitsResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldCreditFacilitiesResponse>?, UEmptyResponse?, String?)> readCreditFacilities({
    required Function(UResponse<UGoldCreditFacilitiesResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldCreditFacilitiesResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadCreditFacilities",
      body: <String, dynamic>{}.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldCreditFacilitiesResponse> ok = UResponse<UGoldCreditFacilitiesResponse>.fromJson(
          r.body,
          (dynamic i) => UGoldCreditFacilitiesResponse.fromMap(i),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UGoldApiTokenResponse>?, UEmptyResponse?, String?)> createApiToken({
    required UGoldCreateApiTokenParams p,
    required Function(UResponse<UGoldApiTokenResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UGoldApiTokenResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/CreateApiToken",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGoldApiTokenResponse> ok = UResponse<UGoldApiTokenResponse>.fromJson(r.body, (dynamic i) => UGoldApiTokenResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<List<UGoldApiTokenResponse>>?, UEmptyResponse?, String?)> readApiTokens({
    required Function(UResponse<List<UGoldApiTokenResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<List<UGoldApiTokenResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/ReadApiTokens",
      body: <String, dynamic>{}.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UGoldApiTokenResponse>> ok = UResponse<List<UGoldApiTokenResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UGoldApiTokenResponse>.from((i as List<dynamic>).map((dynamic x) => UGoldApiTokenResponse.fromMap(x))),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteApiToken({
    required UGoldDeleteApiTokenParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Gold/DeleteApiToken",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }
}
