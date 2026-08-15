part of "../data.dart";

class AuthService {
  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> register({
    required URegisterParams p,
    required Function(UResponse<ULoginResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/Register",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> login({
    required ULoginParams p,
    required Function(UResponse<ULoginResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/Login",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> refreshToken({
    required URefreshTokenParams p,
    required Function(UResponse<ULoginResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/RefreshToken",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> getVerificationCodeForLogin({
    required UGetMobileVerificationCodeForLoginParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/GetVerificationCodeForLogin",
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> verifyCodeForLogin({
    required UVerifyMobileForLoginParams p,
    required Function(UResponse<ULoginResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/VerifyCodeForLogin",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> completeProfile({
    required UAuthCompleteProfileParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/CompleteProfile",
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> loginOrRegister({
    required URegisterParams p,
    required Function(UResponse<ULoginResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/LoginOrRegister",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        ULocalStorage.setUserId(response.result!.user.id);
        ULocalStorage.setToken(response.result!.token);
        ULocalStorage.setRefreshToken(response.result!.refreshToken);
        result = (response, null, null);
        onOk?.call(response);
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
