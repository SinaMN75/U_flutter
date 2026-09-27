part of "../../u_admin.dart";

class UAdminPaymentUserController extends UBaseController {
  List<UUserResponse> list = <UUserResponse>[];

  static const List<TagUser> verifiedTags = <TagUser>[
    TagUser.nationalCardFrontVerified,
    TagUser.nationalCardBackVerified,
    TagUser.birthCertificateFirstVerified,
    TagUser.eSignatureVerified,
    TagUser.visualAuthenticationVerified,
  ];
  static const List<TagUser> awaitingTags = <TagUser>[
    TagUser.nationalCardFrontAwaitingVerification,
    TagUser.nationalCardBackAwaitingVerification,
    TagUser.birthCertificateFirstAwaitingVerification,
    TagUser.eSignatureAwaitingVerification,
    TagUser.visualAuthenticationAwaitingVerification,
  ];

  TagUser? verificationStatus;
  final TextEditingController firstNameFilterController = TextEditingController();
  final TextEditingController lastNameFilterController = TextEditingController();
  final TextEditingController userNameFilterController = TextEditingController();
  final TextEditingController phoneNumberFilterController = TextEditingController();
  final TextEditingController nationalCodeFilterController = TextEditingController();
  final TextEditingController emailFilterController = TextEditingController();
  final TextEditingController landLineFilterController = TextEditingController();
  final TextEditingController bioFilterController = TextEditingController();
  final TextEditingController fromBirthController = TextEditingController();
  final TextEditingController toBirthController = TextEditingController();
  DateTime? fromBirthDate;
  DateTime? toBirthDate;

  UUserResponse? editing;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController nationalCodeController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController landLineController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  DateTime birthdate = DateTime.now().toUtc();
  TagUser gender = TagUser.unspecified;
  TagUser role = TagUser.guest;
  Set<TagUser> permissions = <TagUser>{};

  bool get canManageRoles => U.user.isFullAdmin();

  Future<void> init() => read();

  Future<void> read() async {
    final List<TagUser> tags = switch (verificationStatus) {
      TagUser.verified => verifiedTags,
      TagUser.awaitingVerification => awaitingTags,
      _ => <TagUser>[],
    };
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
        fromCreatedAt: startDate,
        toCreatedAt: endDate,
        startBirthDate: fromBirthDate,
        endBirthDate: toBirthDate,
      ),
      onOk: (UResponse<List<UUserResponse>> r) {
        list = r.result ?? <UUserResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    for (final TextEditingController t in <TextEditingController>[
      firstNameFilterController,
      lastNameFilterController,
      userNameFilterController,
      phoneNumberFilterController,
      nationalCodeFilterController,
      emailFilterController,
      landLineFilterController,
      bioFilterController,
      fromBirthController,
      toBirthController,
    ]) {
      t.clear();
    }
    clearDates();
    fromBirthDate = null;
    toBirthDate = null;
    verificationStatus = null;
    pageNumber(1);
    read();
  }

  void loadForm(UUserResponse? u) {
    editing = u;
    firstNameController.text = u?.firstName ?? "";
    lastNameController.text = u?.lastName ?? "";
    userNameController.text = u?.userName ?? "";
    fatherNameController.text = u?.jsonData.fatherName ?? "";
    nationalCodeController.text = u?.nationalCode ?? "";
    birthDateController.text = u?.birthdate?.toJalaliDate() ?? "";
    passwordController.clear();
    phoneNumberController.text = u?.phoneNumber ?? "";
    landLineController.text = u?.landLine ?? "";
    emailController.text = u?.email ?? "";
    bioController.text = u?.bio ?? "";
    birthdate = u?.birthdate ?? DateTime.now().toUtc();
    gender = (u?.isMale() ?? false)
        ? TagUser.male
        : (u?.isFemaleMale() ?? false)
        ? TagUser.female
        : TagUser.unspecified;
    role = (u?.isSuperAdmin() ?? false)
        ? TagUser.superAdmin
        : (u?.isSubAdmin() ?? false)
        ? TagUser.subAdmin
        : TagUser.guest;
    permissions = TagUser.permissions.where((TagUser t) => (u?.tags ?? <int>[]).contains(t.number)).toSet();
  }

  void togglePermission(TagUser t, bool on) => on ? permissions.add(t) : permissions.remove(t);

  Future<bool> save() async {
    final UUserResponse? u = editing;
    if (u == null) {
      return await send(
        UServices.user.create(
          p: UUserCreateParams(
            firstName: firstNameController.text,
            lastName: lastNameController.text,
            userName: userNameController.trimmedLatin(),
            password: passwordController.trimmedLatin(),
            fatherName: fatherNameController.text.nullIfEmpty(),
            nationalCode: nationalCodeController.valueOrNull()?.toLatinNumber(),
            birthdate: birthdate,
            phoneNumber: phoneNumberController.trimmedLatin(),
            landLine: landLineController.valueOrNull()?.toLatinNumber(),
            email: emailController.trimmedLatin().nullIfEmpty(),
            bio: bioController.valueOrNull(),
            tags: <int>[
              gender.number,
              if (canManageRoles) role.number,
              if (canManageRoles && role == TagUser.subAdmin) ...permissions.map((TagUser t) => t.number),
            ],
          ),
        ),
        null,
      ) !=
          null;
    }
    final List<int> addTags = <int>[gender.number];
    final List<int> removeTags = <TagUser>[TagUser.male, TagUser.female, TagUser.unspecified].where((TagUser t) => t != gender).map((TagUser t) => t.number).toList();
    if (canManageRoles) {
      addTags.add(role.number);
      removeTags.addAll(<TagUser>[TagUser.superAdmin, TagUser.subAdmin, TagUser.guest].where((TagUser t) => t != role).map((TagUser t) => t.number));
      if (role == TagUser.subAdmin) {
        addTags.addAll(permissions.map((TagUser t) => t.number));
        removeTags.addAll(TagUser.permissions.where((TagUser t) => !permissions.contains(t)).map((TagUser t) => t.number));
      } else {
        removeTags.addAll(TagUser.permissions.map((TagUser t) => t.number));
      }
    }
    return await send(
      UServices.user.update(
        p: UUserUpdateParams(
          id: u.id,
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          userName: userNameController.trimmedLatin(),
          password: passwordController.text.nullIfEmpty(),
          fatherName: fatherNameController.text.nullIfEmpty(),
          nationalCode: nationalCodeController.valueOrNull()?.toLatinNumber(),
          birthdate: birthdate,
          phoneNumber: phoneNumberController.trimmedLatin(),
          landLine: landLineController.valueOrNull()?.toLatinNumber(),
          email: emailController.text.toLatinNumber().nullIfEmpty(),
          bio: bioController.valueOrNull(),
          addTags: addTags,
          removeTags: removeTags,
        ),
      ),
      null,
    ) !=
        null;
  }

  void delete(UUserResponse i) => confirmAction(
    () => UServices.user.delete(p: UIdParams(id: i.id)),
    read,
    title: U.s.deleteItem(U.s.user),
    message: U.s.areYouSureToDeleteThisUser,
  );

  @override
  void dispose() {
    firstNameFilterController.dispose();
    lastNameFilterController.dispose();
    userNameFilterController.dispose();
    phoneNumberFilterController.dispose();
    nationalCodeFilterController.dispose();
    emailFilterController.dispose();
    landLineFilterController.dispose();
    bioFilterController.dispose();
    fromBirthController.dispose();
    toBirthController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    userNameController.dispose();
    fatherNameController.dispose();
    nationalCodeController.dispose();
    birthDateController.dispose();
    passwordController.dispose();
    phoneNumberController.dispose();
    landLineController.dispose();
    emailController.dispose();
    bioController.dispose();
    super.dispose();
  }
}
