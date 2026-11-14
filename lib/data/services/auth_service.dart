part of "../data.dart";

class UAuthService {
  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> register({
    required URegisterParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/Register", p.toMap(), _session, _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> login({
    required ULoginParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/Login", p.toMap(), _session, _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> refreshToken({
    required URefreshTokenParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/RefreshToken", p.toMap(), _session, _Api.empty, onOk, onError, onException);

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
  }) => _Api.call("/auth/VerifyCodeForLogin", p.toMap(), _session, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> getEmailVerificationCodeForLogin({
    required UGetEmailVerificationCodeForLoginParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/GetEmailVerificationCodeForLogin", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> verifyEmailCodeForLogin({
    required UVerifyEmailForLoginParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/VerifyEmailCodeForLogin", p.toMap(), _session, _Api.empty, onOk, onError, onException);

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
  }) => _Api.call("/auth/LoginOrRegister", p.toMap(), _session, _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> loginWithGoogle({
    required UGoogleLoginParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/LoginWithGoogle", p.toMap(), _session, _Api.empty, onOk, onError, onException);

  Future<(UResponse<USignInTransferResponse>?, UEmptyResponse?, String?)> createSignInTransfer({
    Function(UResponse<USignInTransferResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/CreateSignInTransfer", <String, dynamic>{}, _Api.one(USignInTransferResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULoginResponse>?, UEmptyResponse?, String?)> redeemSignInTransfer({
    required URedeemSignInTransferParams p,
    Function(UResponse<ULoginResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/auth/RedeemSignInTransfer", p.toMap(), _session, _Api.empty, onOk, onError, onException);

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

  UResponse<ULoginResponse> _session(String body) {
    final UResponse<ULoginResponse> response = UResponse<ULoginResponse>.fromJson(body, (dynamic i) => ULoginResponse.fromMap(i));
    setUserData(response.result!);
    return response;
  }

  void setUserData(ULoginResponse response) {
    ULocalStorage.setUserId(response.user.id);
    ULocalStorage.setToken(response.token);
    ULocalStorage.setRefreshToken(response.refreshToken);
    ULocalStorage.setRefreshTokenExpiresAt(response.refreshTokenExpiresAt);
    U.user = response.user;
    UAuth.onTokensIssued();
  }
}
