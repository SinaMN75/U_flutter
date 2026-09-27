part of "../../u_admin.dart";

class UAdminSplashController extends UBaseController {
  void init({
    required VoidCallback onFinish,
    required VoidCallback onError,
  }) {
    if (!UAuth.isSignedIn) {
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
        onError: (UEmptyResponse r) => onError(),
        onException: (String e) => onError(),
        onProgress: (int e) {},
      );
    }
  }
}
