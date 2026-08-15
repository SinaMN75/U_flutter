part of "../data.dart";

class FollowService {
  Future<(UEmptyResponse?, UEmptyResponse?, String?)> follow({
    required UFollowParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/Follow",
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> unfollow({
    required UFollowParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/Unfollow",
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

  Future<(UResponse<List<UUserResponse>>?, UEmptyResponse?, String?)> readFollowers({
    required UIdParams p,
    required Function(UResponse<List<UUserResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<List<UUserResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/ReadFollowers",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UUserResponse>> ok = UResponse<List<UUserResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UUserResponse>.from((i as List<dynamic>).map((dynamic x) => UUserResponse.fromMap(x))),
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

  Future<(UResponse<List<UUserResponse>>?, UEmptyResponse?, String?)> readFollowedUsers({
    required UIdParams p,
    required Function(UResponse<List<UUserResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<List<UUserResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/ReadFollowedUsers",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UUserResponse>> ok = UResponse<List<UUserResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UUserResponse>.from((i as List<dynamic>).map((dynamic x) => UUserResponse.fromMap(x))),
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

  Future<(UResponse<List<UProductResponse>>?, UEmptyResponse?, String?)> readFollowedProducts({
    required UIdParams p,
    required Function(UResponse<List<UProductResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<List<UProductResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/ReadFollowedProducts",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UProductResponse>> ok = UResponse<List<UProductResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UProductResponse>.from((i as List<dynamic>).map((dynamic x) => UProductResponse.fromMap(x))),
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

  Future<(UResponse<List<UCategoryResponse>>?, UEmptyResponse?, String?)> readFollowedCategories({
    required UIdParams p,
    required Function(UResponse<List<UCategoryResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<List<UCategoryResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/ReadFollowedCategories",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UCategoryResponse>> ok = UResponse<List<UCategoryResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UCategoryResponse>.from((i as List<dynamic>).map((dynamic x) => UCategoryResponse.fromMap(x))),
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

  Future<(UResponse<UFollowerFollowingCountResponse>?, UEmptyResponse?, String?)> readFollowerFollowingCount({
    required UIdParams p,
    required Function(UResponse<UFollowerFollowingCountResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UFollowerFollowingCountResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/ReadFollowerFollowingCount",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UFollowerFollowingCountResponse> ok = UResponse<UFollowerFollowingCountResponse>.fromJson(r.body, (dynamic i) => UFollowerFollowingCountResponse.fromMap(i));
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

  Future<(UResponse<bool>?, UEmptyResponse?, String?)> isFollowingUser({
    required UFollowParams p,
    required Function(UResponse<bool> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<bool>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/IsFollowingUser",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<bool> ok = UResponse<bool>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<bool>?, UEmptyResponse?, String?)> isFollowingProduct({
    required UFollowParams p,
    required Function(UResponse<bool> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<bool>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/isFollowingProduct",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<bool> ok = UResponse<bool>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<bool>?, UEmptyResponse?, String?)> isFollowingCategory({
    required UFollowParams p,
    required Function(UResponse<bool> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<bool>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/follow/isFollowingCategory",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<bool> ok = UResponse<bool>.fromJson(r.body, (dynamic i) => i);
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
