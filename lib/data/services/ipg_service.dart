part of "../data.dart";

class IpgService {
  Future<(UResponse<UIpgPayResponse>?, UEmptyResponse?, String?)> pay({
    required final UIpgSaleParams p,
    final Function(UResponse<UIpgPayResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UIpgPayResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ipg/Pay",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UIpgPayResponse> ok = UResponse<UIpgPayResponse>.fromJson(r.body, (final dynamic i) => UIpgPayResponse.fromMap(i));
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

  // Polls the outcome of a started payment by tracking number. The backend already did the work; this only reads the result.
  Future<(UResponse<UIpgVerifyResponse>?, UEmptyResponse?, String?)> status({
    required final UIpgVerifyParams p,
    final Function(UResponse<UIpgVerifyResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UIpgVerifyResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/ipg/Status",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UIpgVerifyResponse> ok = UResponse<UIpgVerifyResponse>.fromJson(r.body, (final dynamic i) => UIpgVerifyResponse.fromMap(i));
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
