import "package:u/utilities.dart";

class UAdminPaymentUserCreateUpdateArgs {
  final UUserResponse? user;

  UAdminPaymentUserCreateUpdateArgs({this.user});
}

class UAdminPaymentUserCreateUpdateController {
  late UAdminPaymentUserCreateUpdateArgs args;

  late TextEditingController controllerFirstName;
  late TextEditingController controllerLastName;
  late TextEditingController controllerUserName;
  late TextEditingController controllerFatherName;
  late TextEditingController controllerNationalCode;
  late TextEditingController controllerBirthDate;
  late TextEditingController controllerPassword;
  late TextEditingController controllerPhoneNumber;
  late TextEditingController controllerLandLine;
  late TextEditingController controllerEmail;
  late TextEditingController controllerBio;
  late Rx<TagUser> gender = TagUser.unspecified.obs;
  late Rx<TagUser> role = TagUser.guest.obs;
  late DateTime birthdate;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void init({required UAdminPaymentUserCreateUpdateArgs args}) {
    this.args = args;
    final UUserResponse? user = args.user;
    controllerFirstName = TextEditingController(text: user?.firstName);
    controllerLastName = TextEditingController(text: user?.lastName);
    controllerUserName = TextEditingController(text: user?.userName);
    controllerFatherName = TextEditingController(text: user?.jsonData.fatherName);
    controllerNationalCode = TextEditingController(text: user?.nationalCode);
    controllerBirthDate = TextEditingController(text: user?.birthdate?.toJalaliDate());
    controllerPassword = TextEditingController();
    controllerPhoneNumber = TextEditingController(text: user?.phoneNumber);
    controllerLandLine = TextEditingController(text: user?.landLine);
    controllerEmail = TextEditingController(text: user?.email);
    controllerBio = TextEditingController(text: user?.bio);
    gender(
      (user?.isMale() ?? false)
          ? TagUser.male
          : (user?.isFemaleMale() ?? false)
          ? TagUser.female
          : TagUser.unspecified,
    );
    role(
      (user?.isSuperAdmin() ?? false)
          ? TagUser.superAdmin
          : (user?.isSubAdmin() ?? false)
          ? TagUser.subAdmin
          : TagUser.guest,
    );
    birthdate = user?.birthdate ?? DateTime.now().toUtc();
  }

  void create({
    required GlobalKey<FormState> formKey,
    required UUserCreateParams p,
  }) => UValidators.validateForm(
    key: formKey,
    action: () {
      ULoading.show();
      UServices.user.create(
        p: p,
        onOk: (UResponse<String> r) async {
          ULoading.dismiss();
          UNavigator.back();
          UToast.snackBar(message: U.s.userCreatedSuccessfully);
        },
        onError: (UEmptyResponse r) {
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
    required GlobalKey<FormState> formKey,
    required UUserUpdateParams p,
  }) => UValidators.validateForm(
    key: formKey,
    action: () {
      ULoading.show();
      UServices.user.update(
        p: p,
        onOk: (UEmptyResponse r) {
          ULoading.dismiss();
          UNavigator.back();
          UToast.snackBar(message: U.s.userUpdatedSuccessfully);
        },
        onError: (UEmptyResponse r) {
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
