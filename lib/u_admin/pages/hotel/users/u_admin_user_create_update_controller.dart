import "package:u/utilities.dart";

class UAdminUserCreateUpdateArgs {
  final UUserResponse? user;

  UAdminUserCreateUpdateArgs({this.user});
}

class UAdminUserCreateUpdateController {
  late UAdminUserCreateUpdateArgs args;

  late TextEditingController controllerFirstName;
  late TextEditingController controllerLastName;
  late TextEditingController controllerUserName;
  late TextEditingController controllerBirthDate;
  late TextEditingController controllerPassword;
  late TextEditingController controllerEmail;
  late TextEditingController controllerPhoneNumber;
  late TextEditingController controllerFatherName;
  late Rx<TagUser> gender = TagUser.female.obs;
  late Rx<TagUser> role = TagUser.guest.obs;
  late DateTime birthdate;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void init({required UAdminUserCreateUpdateArgs args}) {
    this.args = args;
    controllerFirstName = TextEditingController(text: args.user?.firstName);
    controllerLastName = TextEditingController(text: args.user?.lastName);
    controllerUserName = TextEditingController(text: args.user?.userName);
    controllerBirthDate = TextEditingController(text: args.user?.birthdate?.toJalaliDate());
    controllerPassword = TextEditingController();
    controllerEmail = TextEditingController(text: args.user?.email);
    controllerPhoneNumber = TextEditingController(text: args.user?.phoneNumber);
    controllerFatherName = TextEditingController(text: args.user?.jsonData.fatherName);
    gender((args.user?.isMale() ?? false) ? TagUser.male : TagUser.female);
    role((args.user?.isSuperAdmin() ?? false) ? TagUser.superAdmin : TagUser.guest);
    birthdate = args.user?.birthdate ?? DateTime.now().toUtc();
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
}
