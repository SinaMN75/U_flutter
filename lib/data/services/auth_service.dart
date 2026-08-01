part of "../data.dart";

class AuthService {
  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> register({
    required final URegisterParams p,
    final Function(UResponse<ULoginResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/Register",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (final dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> login({
    required final ULoginParams p,
    final Function(UResponse<ULoginResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/Login",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (final dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> refreshToken({
    required final URefreshTokenParams p,
    final Function(UResponse<ULoginResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/RefreshToken",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (final dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> getVerificationCodeForLogin({
    required final UGetMobileVerificationCodeForLoginParams p,
    final Function(UEmptyResponse r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/GetVerificationCodeForLogin",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> verifyCodeForLogin({
    required final UVerifyMobileForLoginParams p,
    final Function(UResponse<ULoginResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/VerifyCodeForLogin",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (final dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> completeProfile({
    required final UAuthCompleteProfileParams p,
    final Function(UEmptyResponse r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/CompleteProfile",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> loginOrRegister({
    required final URegisterParams p,
    final Function(UResponse<ULoginResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/LoginOrRegister",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (final dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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
