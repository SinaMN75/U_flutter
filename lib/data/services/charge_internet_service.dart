part of "../data.dart";

class ChargeInternetService {
  Future<(UResponse<ChargeInternetReserveResponse>?, UEmptyResponse?, String?)> pin({
    required final ReserveChargeParams p,
    required Function(UResponse<ChargeInternetReserveResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ChargeInternetReserveResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/Pin",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ChargeInternetReserveResponse> ok = UResponse<ChargeInternetReserveResponse>.fromJson(r.body, (final dynamic i) => ChargeInternetReserveResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<ChargeInternetReserveResponse>?, UEmptyResponse?, String?)> topup({
    required final TopupChargeParams p,
    required Function(UResponse<ChargeInternetReserveResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ChargeInternetReserveResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/Topup",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ChargeInternetReserveResponse> ok = UResponse<ChargeInternetReserveResponse>.fromJson(r.body, (final dynamic i) => ChargeInternetReserveResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UInternetPackageResponse>?, UEmptyResponse?, String?)> internetList({
    required final InternetListParams p,
    required Function(UResponse<UInternetPackageResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UInternetPackageResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/InternetList",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UInternetPackageResponse> ok = UResponse<UInternetPackageResponse>.fromJson(r.body, (final dynamic i) => UInternetPackageResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<ChargeInternetReserveResponse>?, UEmptyResponse?, String?)> internetReserve({
    required final InternetReserveParams p,
    required Function(UResponse<ChargeInternetReserveResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ChargeInternetReserveResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/InternetReserve",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ChargeInternetReserveResponse> ok = UResponse<ChargeInternetReserveResponse>.fromJson(r.body, (final dynamic i) => ChargeInternetReserveResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<GetStatusResponse>?, UEmptyResponse?, String?)> getStatus({
    required final GetStatusParams p,
    required Function(UResponse<GetStatusResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<GetStatusResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/GetStatus",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<GetStatusResponse> ok = UResponse<GetStatusResponse>.fromJson(r.body, (final dynamic i) => GetStatusResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<GetBalanceResponse>?, UEmptyResponse?, String?)> getBalance({
    required final UBaseParams p,
    required Function(UResponse<GetBalanceResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<GetBalanceResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/GetBalance",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<GetBalanceResponse> ok = UResponse<GetBalanceResponse>.fromJson(r.body, (final dynamic i) => GetBalanceResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<EchoResponse>?, UEmptyResponse?, String?)> echo({
    required final UBaseParams p,
    required Function(UResponse<EchoResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<EchoResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ChargeInternet/Echo",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<EchoResponse> ok = UResponse<EchoResponse>.fromJson(r.body, (final dynamic i) => EchoResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }
}
