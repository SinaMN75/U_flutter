part of "../data.dart";

class UProcessService {
  Future<(UResponse<UProcessStepGet>?, UEmptyResponse?, String?)> get({
    required String processId,
    Function(UResponse<UProcessStepGet> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) =>
      _Api.call("/process/Get", <String, dynamic>{"id": processId}, _Api.one(UProcessStepGet.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UProcessStepGet>?, UEmptyResponse?, String?)> send({
    required UProcessStepSend p,
    Function(UResponse<UProcessStepGet> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
    Function(int percent)? onProgress,
  }) async {
    (UResponse<UProcessStepGet>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      timeout: const Duration(minutes: 2),
      method: "POST",
      endpoint: "${U.baseUrl}/process/Send",
      body: <String, dynamic>{
        ...p.toMap(),
        "apiKey": U.apiKey,
        "token": ULocalStorage.getToken(),
      },
      onSuccess: (Response r) {
        final UResponse<UProcessStepGet> ok = UResponse<UProcessStepGet>.fromJson(r.body, (dynamic i) => UProcessStepGet.fromMap(i));
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
      onProgress: onProgress,
    );
    return result;
  }
}
