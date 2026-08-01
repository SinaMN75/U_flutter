part of "../data.dart";

class ProcessService {
  Future<(UResponse<UProcessStepGet>?, UEmptyResponse?, String?)> get({
    required final String processId,
    final Function(UResponse<UProcessStepGet> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UProcessStepGet>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/process/Get",
      body: <String, dynamic>{
        "id": processId,
        "apiKey": U.apiKey,
        "token": ULocalStorage.getToken(),
      },
      onSuccess: (final Response r) {
        final UResponse<UProcessStepGet> ok = UResponse<UProcessStepGet>.fromJson(r.body, (dynamic i) => UProcessStepGet.fromMap(i));
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

  Future<(UResponse<UProcessStepGet>?, UEmptyResponse?, String?)> send({
    required final UProcessStepSend p,
    final Function(UResponse<UProcessStepGet> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UProcessStepGet>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/process/Send",
      body: <String, dynamic>{
        ...p.toMap(),
        "apiKey": U.apiKey,
        "token": ULocalStorage.getToken(),
      },
      onSuccess: (final Response r) {
        final UResponse<UProcessStepGet> ok = UResponse<UProcessStepGet>.fromJson(r.body, (dynamic i) => UProcessStepGet.fromMap(i));
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
