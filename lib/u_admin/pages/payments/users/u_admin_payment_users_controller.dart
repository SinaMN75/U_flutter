part of "../../../u_admin.dart";

class UAdminPaymentUsersController extends UBaseController {
  List<UUserResponse> list = <UUserResponse>[];

  final TextEditingController firstNameFilterController = TextEditingController();
  final TextEditingController lastNameFilterController = TextEditingController();
  final TextEditingController userNameFilterController = TextEditingController();
  final TextEditingController phoneNumberFilterController = TextEditingController();
  final TextEditingController nationalCodeFilterController = TextEditingController();
  final TextEditingController emailFilterController = TextEditingController();
  final TextEditingController landLineFilterController = TextEditingController();
  final TextEditingController bioFilterController = TextEditingController();

  final TextEditingController fromCreatedController = TextEditingController();
  final TextEditingController toCreatedController = TextEditingController();
  final TextEditingController fromBirthController = TextEditingController();
  final TextEditingController toBirthController = TextEditingController();
  DateTime? fromBirthDate;
  DateTime? toBirthDate;

  Rxn<TagUser> verificationStatus = Rxn<TagUser>();

  Future<void> init() => read();

  List<TagUser> tags = <TagUser>[];

  Future<void> read() async {
    if (verificationStatus.value == TagUser.verified) {
      tags = <TagUser>[TagUser.nationalCardFrontVerified, TagUser.nationalCardBackVerified, TagUser.birthCertificateFirstVerified, TagUser.eSignatureVerified, TagUser.visualAuthenticationVerified];
    }
    if (verificationStatus.value == TagUser.awaitingVerification) {
      tags = <TagUser>[
        TagUser.nationalCardFrontAwaitingVerification,
        TagUser.nationalCardBackAwaitingVerification,
        TagUser.birthCertificateFirstAwaitingVerification,
        TagUser.eSignatureAwaitingVerification,
        TagUser.visualAuthenticationAwaitingVerification,
      ];
    }
    if (verificationStatus.value == null) tags.clear();

    state.loading();
    await UServices.user.read(
      p: UUserReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        firstName: firstNameFilterController.valueOrNull(),
        lastName: lastNameFilterController.valueOrNull(),
        userName: userNameFilterController.valueOrNull(),
        phoneNumber: phoneNumberFilterController.valueOrNull(),
        nationalCode: nationalCodeFilterController.valueOrNull(),
        email: emailFilterController.valueOrNull(),
        landLine: landLineFilterController.valueOrNull(),
        bio: bioFilterController.valueOrNull(),
        tags: tags.map((TagUser i) => i.number).toList(),
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
        startBirthDate: fromBirthDate,
        endBirthDate: toBirthDate,
      ),
      onOk: (UResponse<List<UUserResponse>> r) {
        list = r.result ?? <UUserResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    firstNameFilterController.clear();
    lastNameFilterController.clear();
    userNameFilterController.clear();
    phoneNumberFilterController.clear();
    nationalCodeFilterController.clear();
    emailFilterController.clear();
    landLineFilterController.clear();
    bioFilterController.clear();
    fromCreatedController.clear();
    toCreatedController.clear();
    fromBirthController.clear();
    toBirthController.clear();
    fromCreatedAt = null;
    toCreatedAt = null;
    fromBirthDate = null;
    toBirthDate = null;
    verificationStatus(null);
    reloadFirstPage(read);
  }

  void delete(UUserResponse i) => UNavigator.confirm(
    title: U.s.deleteItem(U.s.user),
    message: U.s.areYouSureToDeleteThisUser,
    onConfirm: () => UServices.user.delete(
      p: UIdParams(id: i.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );
}
