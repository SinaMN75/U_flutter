part of "../data.dart";

// =============================================================================
// _Api — the request/decode/dispatch dance every service method performs.
//
// Each endpoint differs in only four ways: the path, the body, how a success
// envelope is decoded, and how an error envelope is decoded. [call] takes those
// four and nothing else; the decoder factories below cover every shape the API
// returns. Service methods keep their own signatures so callers see no change.
// =============================================================================

abstract class _Api {
  /// Sends [path] under [U.baseUrl] and returns the `(ok, error, exception)` triple
  /// every service method yields, invoking whichever callback applies on the way.
  ///
  /// [body] is sent with `apiKey` and `token` appended, and `locale` too when
  /// [locale] is set. A null [body] sends no body at all.
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
    (S?, E?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: method,
      endpoint: "${U.baseUrl}$path",
      body: body == null ? null : _body(body, locale: locale),
      onProgress: onProgress?.call,
      onSuccess: (Response r) {
        final S value = ok(r.body);
        result = (value, null, null);
        onOk?.call(value);
      },
      onError: (Response r) {
        final E value = err(r.body);
        result = (null, value, null);
        onError?.call(value);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  static Map<String, dynamic> _body(Map<String, dynamic> p, {required bool locale}) {
    final Map<String, dynamic> map = p.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken());
    return locale ? map.add("locale", ULocalStorage.getLocale()) : map;
  }

  // --- success / error decoders -------------------------------------------

  /// An envelope with no `result` payload.
  static UEmptyResponse empty(String json) => UEmptyResponse.fromJson(json);

  /// An envelope whose `result` is passed through untouched.
  static UResponse<dynamic> dyn(String json) => UResponse<dynamic>.fromJson(json, (dynamic i) => i);

  /// An envelope whose `result` is a scalar already of type [T] (`String`, `bool`, `int`, ...).
  static UResponse<T> Function(String json) raw<T>() =>
      (String json) => UResponse<T>.fromJson(json, (dynamic i) => i as T);

  /// An envelope whose `result` is a single object built by [fromMap].
  static UResponse<T> Function(String json) one<T>(T Function(Map<String, dynamic> map) fromMap) =>
      (String json) => UResponse<T>.fromJson(json, (dynamic i) => fromMap(i as Map<String, dynamic>));

  /// An envelope whose `result` is a list of objects each built by [fromMap].
  static UResponse<List<T>> Function(String json) list<T>(T Function(Map<String, dynamic> map) fromMap) =>
      (String json) => UResponse<List<T>>.fromJson(json, (dynamic i) => List<T>.from((i as List<dynamic>).map((dynamic x) => fromMap(x as Map<String, dynamic>))));
}
