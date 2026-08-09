part of "../../../../u_admin.dart";

class UAdminUserDetailController {
  final Rx<int> loadingProgress = 0.obs;
  final RxState state = RxState();
  late UUserResponse user;

  void init({required UUserResponse user}) {
    this.user = user;
    read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.user.readById(
      onProgress: loadingProgress.call,
      p: UIdParams(
        id: user.id,
        selectorArgs: const UserSelectorArgs(
          address: AddressSelectorArgs(),
          nationalCardFront: true,
          nationalCardBack: true,
          birthCertificateFirst: true,
          eSignature: true,
          visualAuthentication: true,
        ),
      ),
      onOk: (UResponse<UUserResponse> response) {
        user = response.result!;
        state.loaded();
      },
      onError: (UEmptyResponse response) {
        state.error();
        UToast.error(message: response.message);
      },
      onException: (String response) {
        state.error();
        UToast.error(message: response);
      },
    );
  }

  bool get isFullyVerified => user.tags.contains(TagUser.verified.number);

  void approve() {
    ULoading.show();
    UServices.user.update(
      p: UUserUpdateParams(
        id: user.id,
        birthCertificateFirstRejectionReason: "",
        nationalCardBackRejectionReason: "",
        nationalCardFrontRejectionReason: "",
        visualAuthenticationRejectionReason: "",
        eSignatureRejectionReason: "",
        addTags: <int>[
          TagUser.verified.number,
          TagUser.nationalCardBackVerified.number,
          TagUser.nationalCardFrontVerified.number,
          TagUser.birthCertificateFirstVerified.number,
          TagUser.eSignatureVerified.number,
          TagUser.visualAuthenticationVerified.number,
        ],
        removeTags: <int>[
          TagUser.awaitingVerification.number,
          TagUser.nationalCardBackAwaitingVerification.number,
          TagUser.nationalCardFrontAwaitingVerification.number,
          TagUser.birthCertificateFirstAwaitingVerification.number,
          TagUser.eSignatureAwaitingVerification.number,
          TagUser.visualAuthenticationAwaitingVerification.number,
        ],
      ),
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        UToast.snackBar(message: r.message);
        UNavigator.back();
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        UToast.error(message: r.message);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void reject({required UUserUpdateParams p}) {
    ULoading.show();
    UServices.user.update(
      p: p,
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        UToast.snackBar(message: r.message);
        UNavigator.back();
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        UToast.error(message: r.message);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }
}
