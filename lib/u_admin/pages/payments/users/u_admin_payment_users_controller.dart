part of "../../../u_admin.dart";

class UAdminPaymentUsersController extends UBaseController {
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
  late final TextEditingController firstNameFilter = fields.text();
  late final TextEditingController lastNameFilter = fields.text();
  late final TextEditingController userNameFilter = fields.text();
  late final TextEditingController phoneNumberFilter = fields.text();
  late final TextEditingController nationalCodeFilter = fields.text();
  late final TextEditingController emailFilter = fields.text();
  late final TextEditingController landLineFilter = fields.text();
  late final TextEditingController bioFilter = fields.text();
  late final TextEditingController fromCreatedController = fields.text();
  late final TextEditingController toCreatedController = fields.text();
  late final TextEditingController fromBirthController = fields.text();
  late final TextEditingController toBirthController = fields.text();
  DateTime? fromBirthDate;
  DateTime? toBirthDate;

  UUserResponse? editing;
  late final TextEditingController firstName = fields.text();
  late final TextEditingController lastName = fields.text();
  late final TextEditingController userName = fields.text();
  late final TextEditingController fatherName = fields.text();
  late final TextEditingController nationalCode = fields.text();
  late final TextEditingController birthDate = fields.text();
  late final TextEditingController password = fields.text();
  late final TextEditingController phoneNumber = fields.text();
  late final TextEditingController landLine = fields.text();
  late final TextEditingController email = fields.text();
  late final TextEditingController bio = fields.text();
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
        firstName: firstNameFilter.valueOrNull(),
        lastName: lastNameFilter.valueOrNull(),
        userName: userNameFilter.valueOrNull(),
        phoneNumber: phoneNumberFilter.valueOrNull(),
        nationalCode: nationalCodeFilter.valueOrNull(),
        email: emailFilter.valueOrNull(),
        landLine: landLineFilter.valueOrNull(),
        bio: bioFilter.valueOrNull(),
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
    for (final TextEditingController t in <TextEditingController>[
      firstNameFilter,
      lastNameFilter,
      userNameFilter,
      phoneNumberFilter,
      nationalCodeFilter,
      emailFilter,
      landLineFilter,
      bioFilter,
      fromCreatedController,
      toCreatedController,
      fromBirthController,
      toBirthController,
    ]) {
      t.clear();
    }
    fromCreatedAt = null;
    toCreatedAt = null;
    fromBirthDate = null;
    toBirthDate = null;
    verificationStatus = null;
    reloadFirstPage(read);
  }

  void loadForm(UUserResponse? u) {
    editing = u;
    firstName.text = u?.firstName ?? "";
    lastName.text = u?.lastName ?? "";
    userName.text = u?.userName ?? "";
    fatherName.text = u?.jsonData.fatherName ?? "";
    nationalCode.text = u?.nationalCode ?? "";
    birthDate.text = u?.birthdate?.toJalaliDate() ?? "";
    password.clear();
    phoneNumber.text = u?.phoneNumber ?? "";
    landLine.text = u?.landLine ?? "";
    email.text = u?.email ?? "";
    bio.text = u?.bio ?? "";
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
      final dynamic ok = await submit(
        UServices.user.create(
          p: UUserCreateParams(
            firstName: firstName.text,
            lastName: lastName.text,
            userName: userName.trimmedLatin(),
            password: password.trimmedLatin(),
            fatherName: fatherName.text.nullIfEmpty(),
            nationalCode: nationalCode.valueOrNull()?.toLatinNumber(),
            birthdate: birthdate,
            phoneNumber: phoneNumber.trimmedLatin(),
            landLine: landLine.valueOrNull()?.toLatinNumber(),
            email: email.trimmedLatin().nullIfEmpty(),
            bio: bio.valueOrNull(),
            tags: <int>[
              gender.number,
              if (canManageRoles) role.number,
              if (canManageRoles && role == TagUser.subAdmin) ...permissions.map((TagUser t) => t.number),
            ],
          ),
        ),
        null,
      );
      return ok != null;
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
    final dynamic ok = await submit(
      UServices.user.update(
        p: UUserUpdateParams(
          id: u.id,
          firstName: firstName.text,
          lastName: lastName.text,
          userName: userName.trimmedLatin(),
          password: password.text.nullIfEmpty(),
          fatherName: fatherName.text.nullIfEmpty(),
          nationalCode: nationalCode.valueOrNull()?.toLatinNumber(),
          birthdate: birthdate,
          phoneNumber: phoneNumber.trimmedLatin(),
          landLine: landLine.valueOrNull()?.toLatinNumber(),
          email: email.text.toLatinNumber().nullIfEmpty(),
          bio: bio.valueOrNull(),
          addTags: addTags,
          removeTags: removeTags,
        ),
      ),
      null,
    );
    return ok != null;
  }

  void delete(UUserResponse i) => confirmAction(
    () => UServices.user.delete(p: UIdParams(id: i.id)),
    read,
    title: U.s.deleteItem(U.s.user),
    message: U.s.areYouSureToDeleteThisUser,
  );
}
