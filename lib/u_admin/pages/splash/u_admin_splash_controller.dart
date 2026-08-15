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
        onOk: (UResponse<UUserResponse> user) {
          U.user = user.result!;
          onFinish();
        },
        onError: (UEmptyResponse r) => onError.call,
        onException: (String e) => onError.call,
        onProgress: (int e) {},
      );
    }
  }
}
