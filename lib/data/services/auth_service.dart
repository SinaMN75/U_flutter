part of "../data.dart";

class UAuthService {
  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> register({
    required URegisterParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/Register",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        setUserData(response.result!);
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
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/Login",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        setUserData(response.result!);
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
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/RefreshToken",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        setUserData(response.result!);
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
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/GetVerificationCodeForLogin", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> verifyCodeForLogin({
    required UVerifyMobileForLoginParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/VerifyCodeForLogin",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        setUserData(response.result!);
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
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/CompleteProfile", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> loginOrRegister({
    required URegisterParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/auth/LoginOrRegister",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(r.body, (dynamic i) => ULoginResponse.fromMap(i));
        setUserData(response.result!);
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

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> loginWithGoogle({
    required UGoogleLoginParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call(
    "/auth/LoginWithGoogle",
    p.toMap(),
    (String body) {
      final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(body, (dynamic i) => ULoginResponse.fromMap(i));
      setUserData(response.result!);
      return response;
    },
    _Api.empty,
    onOk,
    onError,
    onException,
  );

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> forgotPassword({
    required UForgotPasswordParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/ForgotPassword", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> resetPassword({
    required UResetPasswordParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/ResetPassword", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  void setUserData(ULoginResponse response) {
    ULocalStorage.setUserId(response.user.id);
    ULocalStorage.setToken(response.token);
    ULocalStorage.setRefreshToken(response.refreshToken);
    ULocalStorage.setRefreshTokenExpiresAt(response.refreshTokenExpiresAt);
    U.user = response.user;
    UAuth.onTokensIssued();
  }
}
