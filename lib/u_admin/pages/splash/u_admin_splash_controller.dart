part of "../../u_admin.dart";

class UAdminSplashController extends UBaseController {
  void init({
    required VoidCallback onFinish,
    required VoidCallback onError,
  }) {
    if (ULocalStorage.getString(UConstants.token) == null) {
      onError();
    } else {
      UServices.user.readById(
        p: UIdParams(
          id: ULocalStorage.getString(UConstants.userId)!,
        ),
        onOk: (final UResponse<UUserResponse> user) {
          U.user = user.result!;
          onFinish();
        },
        onError: (final UEmptyResponse r) => onError.call,
        onException: (String e) => onError.call,
      );
    }
  }
}
