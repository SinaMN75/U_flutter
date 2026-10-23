part of "../data.dart";

abstract class _Api {
  static const int _isolateThreshold = 128 * 1024;
  static final Expando<bool> _pure = Expando<bool>();

  static Future<(S?, E?, String?)> call<S, E>(
    String path,
    Map<String, dynamic>? body,
    S Function(String json) ok,
    E Function(String json) err,
    Function(S r)? onOk,
    Function(E e)? onError,
    Function(String e)? onException, {
    String method = "POST",
    bool locale = false,
    Function(int percent)? onProgress,
  }) async {
    String? okBody;
    String? errorBody;
    String? exception;
    await UHttpClient.send(
      method: method,
      endpoint: "${U.baseUrl}$path",
      body: body == null ? null : _body(body, locale: locale),
      onProgress: onProgress?.call,
      onSuccess: (Response r) => okBody = r.body,
      onError: (Response r) => errorBody = r.body,
      onException: (String e) => exception = e,
    );
    try {
      if (okBody != null) {
        final S value = await _parse(ok, okBody!);
        onOk?.call(value);
        return (value, null, null);
      }
      if (errorBody != null) {
        final E value = await _parse(err, errorBody!);
        onError?.call(value);
        return (null, value, null);
      }
    } catch (e, stack) {
      developer.log(e.toString(), stackTrace: stack);
      exception = U.s.unexpectedErrorPleaseTryAgain;
    }
    if (exception != null) onException?.call(exception!);
    return (null, null, exception);
  }

  static FutureOr<T> _parse<T>(T Function(String json) parse, String json) {
    if (json.length < _isolateThreshold || _pure[parse] != true) return parse(json);
    return compute(parse, json, debugLabel: "UApi.parse").catchError((Object _) => parse(json));
  }

  static T Function(String json) _markPure<T>(T Function(String json) parse) {
    _pure[parse] = true;
    return parse;
  }

  static Map<String, dynamic> _body(Map<String, dynamic> p, {required bool locale}) {
    final Map<String, dynamic> map = p.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken());
    return locale ? map.add("locale", ULocalStorage.getLocale()) : map;
  }

  static UEmptyResponse empty(String json) => UEmptyResponse.fromJson(json);

  static UResponse<dynamic> dyn(String json) => UResponse<dynamic>.fromJson(json, (dynamic i) => i);

  static UResponse<T> Function(String json) raw<T>() => _markPure((String json) => UResponse<T>.fromJson(json, (dynamic i) => i as T));

  static UResponse<T> Function(String json) one<T>(T Function(Map<String, dynamic> map) fromMap) =>
      _markPure((String json) => UResponse<T>.fromJson(json, (dynamic i) => fromMap(i as Map<String, dynamic>)));

  static UResponse<List<T>> Function(String json) list<T>(T Function(Map<String, dynamic> map) fromMap) => _markPure(
    (String json) => UResponse<List<T>>.fromJson(json, (dynamic i) => <T>[for (final dynamic x in i as List<dynamic>) fromMap(x as Map<String, dynamic>)]),
  );
}
