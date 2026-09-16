part of "../data.dart";

class ChargeInternetService {
  Future<(UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?)> pin({
    required UReserveChargeParams p,
    Function(UResponse<UChargeInternetReserveResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/Pin",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UChargeInternetReserveResponse> ok = UResponse<UChargeInternetReserveResponse>.fromJson(r.body, (dynamic i) => UChargeInternetReserveResponse.fromMap(i));
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

  Future<(UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?)> topup({
    required UTopupChargeParams p,
    Function(UResponse<UChargeInternetReserveResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/Topup",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UChargeInternetReserveResponse> ok = UResponse<UChargeInternetReserveResponse>.fromJson(r.body, (dynamic i) => UChargeInternetReserveResponse.fromMap(i));
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

  Future<(UResponse<UInternetPackageResponse>?, UEmptyResponse?, String?)> internetList({
    required UInternetListParams p,
    Function(UResponse<UInternetPackageResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UInternetPackageResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/InternetList",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UInternetPackageResponse> ok = UResponse<UInternetPackageResponse>.fromJson(r.body, (dynamic i) => UInternetPackageResponse.fromMap(i));
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

  Future<(UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?)> internetReserve({
    required UInternetReserveParams p,
    Function(UResponse<UChargeInternetReserveResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UChargeInternetReserveResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/InternetReserve",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UChargeInternetReserveResponse> ok = UResponse<UChargeInternetReserveResponse>.fromJson(r.body, (dynamic i) => UChargeInternetReserveResponse.fromMap(i));
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

  Future<(UResponse<UGetStatusResponse>?, UEmptyResponse?, String?)> getStatus({
    required UGetStatusParams p,
    Function(UResponse<UGetStatusResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UGetStatusResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/GetStatus",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGetStatusResponse> ok = UResponse<UGetStatusResponse>.fromJson(r.body, (dynamic i) => UGetStatusResponse.fromMap(i));
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

  Future<(UResponse<UGetBalanceResponse>?, UEmptyResponse?, String?)> getBalance({
    required UBaseParams p,
    Function(UResponse<UGetBalanceResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UGetBalanceResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/GetBalance",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UGetBalanceResponse> ok = UResponse<UGetBalanceResponse>.fromJson(r.body, (dynamic i) => UGetBalanceResponse.fromMap(i));
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

  Future<(UResponse<UEchoResponse>?, UEmptyResponse?, String?)> echo({
    required UBaseParams p,
    Function(UResponse<UEchoResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UEchoResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/Echo",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UEchoResponse> ok = UResponse<UEchoResponse>.fromJson(r.body, (dynamic i) => UEchoResponse.fromMap(i));
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
