part of "../../u_admin.dart";

class UAdminLoginController extends UBaseController {
  final TextEditingController controllerUserName = TextEditingController(
    text: kDebugMode ? "SystemAdmin" : "",
  );
  final TextEditingController controllerPassword = TextEditingController(
    text: kDebugMode ? "SystemAdmin" : "",
  );

  void init() {}

  void login({required Function(UUserResponse) onFinish}) => UValidators.validateForm(
    key: formKey,
    action: () {
      ULoading.show();
      UServices.auth.login(
        p: ULoginParams(
          userName: controllerUserName.text,
          password: controllerPassword.text,
        ),
        onOk: (UResponse<ULoginResponse> r) {
          ULocalStorage.set(UConstants.token, r.result!.token);
          ULocalStorage.set(UConstants.userId, r.result!.user.id);
          ULoading.dismiss();
          onFinish(r.result!.user);
        },
        onError: (UEmptyResponse r) {
          ULoading.dismiss();
          UToast.error(message: r.message);
        },
        onException: (String e) => ULoading.dismiss(),
      );
    },
  );
}
