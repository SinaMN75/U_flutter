part of "../../../../u_admin.dart";

class UAdminUserDetailController extends UBaseController {
  final URx<int> loadingProgress = 0.obs;
  late UUserResponse user;

  late final TextEditingController frontReason = fields.text();
  late final TextEditingController backReason = fields.text();
  late final TextEditingController birthReason = fields.text();
  late final TextEditingController videoReason = fields.text();
  late final TextEditingController signatureReason = fields.text();

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
    frontReason.text = user.jsonData.nationalCardFrontRejectionReason ?? "";
    backReason.text = user.jsonData.nationalCardBackRejectionReason ?? "";
    birthReason.text = user.jsonData.birthCertificateFirstRejectionReason ?? "";
    videoReason.text = user.jsonData.visualAuthenticationRejectionReason ?? "";
    signatureReason.text = user.jsonData.eSignatureRejectionReason ?? "";
  }

  Future<bool> reject() async {
    final dynamic ok = await submit(
      UServices.user.update(
        p: UUserUpdateParams(
          id: user.id,
          nationalCardFrontRejectionReason: frontReason.valueOrNull(),
          nationalCardBackRejectionReason: backReason.valueOrNull(),
          birthCertificateFirstRejectionReason: birthReason.valueOrNull(),
          visualAuthenticationRejectionReason: videoReason.valueOrNull(),
          eSignatureRejectionReason: signatureReason.valueOrNull(),
          removeTags: <int>[
            if (frontReason.text.isNotEmpty) TagUser.nationalCardFrontAwaitingVerification.number,
            if (backReason.text.isNotEmpty) TagUser.nationalCardBackAwaitingVerification.number,
            if (birthReason.text.isNotEmpty) TagUser.birthCertificateFirstAwaitingVerification.number,
            if (videoReason.text.isNotEmpty) TagUser.visualAuthenticationAwaitingVerification.number,
            if (signatureReason.text.isNotEmpty) TagUser.eSignatureAwaitingVerification.number,
          ],
        ),
      ),
      read,
    );
    return ok != null;
  }

  @override
  void dispose() {
    loadingProgress.dispose();
    super.dispose();
  }
}
