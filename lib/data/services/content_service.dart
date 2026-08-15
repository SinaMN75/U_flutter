part of "../data.dart";

class ContentService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UContentCreateParams p,
    required Function(UResponse<String> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/content/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UContentResponse>>?, UEmptyResponse?, String?)> read({
    required UContentReadParams p,
    required Function(UResponse<List<UContentResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<List<UContentResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/content/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UContentResponse>> ok = UResponse<List<UContentResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UContentResponse>.from((i as List<dynamic>).map((dynamic x) => UContentResponse.fromMap(x))),
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UContentUpdateParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/content/Update",
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/content/Delete",
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
