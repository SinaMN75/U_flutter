part of "../../../../u_admin.dart";

class UAdminUserDetailController extends UBaseController {
  final URx<int> loadingProgress = 0.obs;
  late UUserResponse user;

  final TextEditingController frontReasonController = TextEditingController();
  final TextEditingController backReasonController = TextEditingController();
  final TextEditingController birthReasonController = TextEditingController();
  final TextEditingController videoReasonController = TextEditingController();
  final TextEditingController signatureReasonController = TextEditingController();

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
        selectorArgs: const UUserSelectorArgs(address: UAddressSelectorArgs(), media: UMediaSelectorArgs()),
      ),
      onOk: (UResponse<UUserResponse> r) {
        user = r.result!;
        state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  bool get isFullyVerified => user.tags.contains(TagUser.verified.number);

  void approve() => confirmAction(
    () => UServices.user.update(
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
    ),
    read,
    title: U.s.finalApproval,
    message: U.s.areYouSureYouWantToApproveThisUserWithAllOfTheirDocuments,
  );

  void loadRejectForm() {
    frontReasonController.text = user.jsonData.nationalCardFrontRejectionReason ?? "";
    backReasonController.text = user.jsonData.nationalCardBackRejectionReason ?? "";
    birthReasonController.text = user.jsonData.birthCertificateFirstRejectionReason ?? "";
    videoReasonController.text = user.jsonData.visualAuthenticationRejectionReason ?? "";
    signatureReasonController.text = user.jsonData.eSignatureRejectionReason ?? "";
  }

  Future<bool> reject() async {
    final dynamic ok = await submit(
      UServices.user.update(
        p: UUserUpdateParams(
          id: user.id,
          nationalCardFrontRejectionReason: frontReasonController.valueOrNull(),
          nationalCardBackRejectionReason: backReasonController.valueOrNull(),
          birthCertificateFirstRejectionReason: birthReasonController.valueOrNull(),
          visualAuthenticationRejectionReason: videoReasonController.valueOrNull(),
          eSignatureRejectionReason: signatureReasonController.valueOrNull(),
          removeTags: <int>[
            if (frontReasonController.text.isNotEmpty) TagUser.nationalCardFrontAwaitingVerification.number,
            if (backReasonController.text.isNotEmpty) TagUser.nationalCardBackAwaitingVerification.number,
            if (birthReasonController.text.isNotEmpty) TagUser.birthCertificateFirstAwaitingVerification.number,
            if (videoReasonController.text.isNotEmpty) TagUser.visualAuthenticationAwaitingVerification.number,
            if (signatureReasonController.text.isNotEmpty) TagUser.eSignatureAwaitingVerification.number,
          ],
        ),
      ),
      read,
    );
    return ok != null;
  }

  @override
  void dispose() {
    frontReasonController.dispose();
    backReasonController.dispose();
    birthReasonController.dispose();
    videoReasonController.dispose();
    signatureReasonController.dispose();
    loadingProgress.dispose();
    super.dispose();
  }
}
