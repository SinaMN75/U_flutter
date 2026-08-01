part of "../../../u_admin.dart";

class UAdminUsersPageArgs {
  UAdminUsersPageArgs();
}

class UAdminUsersController extends UBaseController {
  late UAdminUsersPageArgs args;
  final GlobalKey<FormState> filterFormKey = GlobalKey<FormState>();
  RxList<UUserResponse> list = <UUserResponse>[].obs;

  TagUser? selectedTag;

  TagUser? selectedGender;
  bool verifiedOnly = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nationalCodeController = TextEditingController();
  final TextEditingController queryController = TextEditingController();
  final TextEditingController fromCreatedAtController = TextEditingController();
  final TextEditingController toCreatedAtController = TextEditingController();

  void init({required final UAdminUsersPageArgs args}) {
    this.args = args;
    read();
  }

  Future<void> read() async {
    state.loading();

    final List<int> tagFilters = <int>[
      if (selectedTag != null) selectedTag!.number,
      if (selectedGender != null) selectedGender!.number,
      if (verifiedOnly) TagUser.verified.number,
    ];

    await UServices.user.read(
      p: UUserReadParams(
        query: queryController.valueOrNull(),
        firstName: firstNameController.valueOrNull(),
        lastName: lastNameController.valueOrNull(),
        userName: userNameController.valueOrNull(),
        phoneNumber: phoneNumberController.valueOrNull(),
        email: emailController.valueOrNull(),
        nationalCode: nationalCodeController.valueOrNull(),
        tags: tagFilters.isEmpty ? null : tagFilters,
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
        orderBy: orderByCreatedAtDesc ? TagOrderBy.createdAtDescending.number : TagOrderBy.createdAt.number,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
      ),
      onOk: (UResponse<List<UUserResponse>> response) {
        list(response.result);
        setTotalPages(response.totalCount);
        state.loaded();
      },
      onError: (UEmptyResponse error) {
        state.error();
        UToast.error(message: error.message);
      },
      onException: (String e) {},
    );
  }

  void applyFilters() {
    read();
  }

  void clearFilters() {
    userNameController.clear();
    phoneNumberController.clear();
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    nationalCodeController.clear();
    queryController.clear();
    fromCreatedAtController.clear();
    toCreatedAtController.clear();
    selectedTag = null;
    selectedGender = null;
    verifiedOnly = false;
    fromCreatedAt = null;
    toCreatedAt = null;
    orderByCreatedAt = false;
    orderByCreatedAtDesc = false;
    read();
  }

  void delete(UUserResponse user) => UNavigator.confirm(
    title: U.s.deleteUser,
    message: U.s.areYouSureToDeleteThisUser,
    onConfirm: () {
      ULoading.show();
      UServices.user.delete(
        p: UIdParams(id: user.id),
        onOk: (final UEmptyResponse r) {
          UNavigator.back();
          UToast.snackBar(message: r.message);
          ULoading.dismiss();
        },
        onError: (final UEmptyResponse r) {
          UToast.error(message: r.message);
          ULoading.dismiss();
        },
        onException: (String e) {},
      );
    },
  );

  void create({
    required GlobalKey<FormState> formKey,
    required UUserCreateParams p,
    List<FileData>? files,
  }) => UValidators.validateForm(
    key: formKey,
    action: () {
      ULoading.show();
      UServices.user.create(
        p: p,
        onOk: (final UResponse<String> r) async {
          files?.forEach(
            (FileData i) async => UServices.media.create(
              p: UMediaCreateParams(file: i, userId: r.result, tag1: TagMedia.image.number),
              onOk: (UResponse<String> r) {},
              onError: (UEmptyResponse r) {},
              onException: (String r) {},
            ),
          );
          ULoading.dismiss();
          UNavigator.back();
          UToast.snackBar(message: U.s.userCreatedSuccessfully);
        },
        onError: (final UEmptyResponse r) {
          ULoading.dismiss();
          UToast.snackBar(message: r.message);
        },
        onException: (String e) {
          ULoading.dismiss();
          UToast.snackBar(message: e);
        },
      );
    },
  );

  void update({
    required final GlobalKey<FormState> formKey,
    required final UUserUpdateParams p,
    List<FileData>? files,
  }) => UValidators.validateForm(
    key: formKey,
    action: () {
      ULoading.show();
      files?.forEach(
        (FileData i) async => UServices.media.create(
          p: UMediaCreateParams(file: i, userId: p.id, tag1: TagMedia.image.number),
          onOk: (UResponse<String> r) {},
          onError: (UEmptyResponse r) {},
          onException: (String r) {},
        ),
      );
      UServices.user.update(
        p: p,
        onOk: (final UEmptyResponse r) {
          read();
          ULoading.dismiss();
          UNavigator.back();
          UToast.snackBar(message: U.s.userCreatedSuccessfully);
        },
        onError: (final UEmptyResponse r) {
          ULoading.dismiss();
          UToast.snackBar(message: r.message);
        },
        onException: (String e) {
          ULoading.dismiss();
          UToast.snackBar(message: e);
        },
      );
    },
  );
}
