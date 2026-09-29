part of "../../../u_admin.dart";

enum UAdminHotelContractLifecycle { active, upcoming, expired }

/// Hotel users list and the one user dialog: create, or details + edit.
class UAdminHotelUserController extends UBaseController {
  URxList<UUserResponse> list = <UUserResponse>[].obs;

  TagUser? tagFilter;
  TagUser? genderFilter;
  bool verifiedOnly = false;
  final TextEditingController firstNameFilterController = TextEditingController();
  final TextEditingController lastNameFilterController = TextEditingController();
  final TextEditingController userNameFilterController = TextEditingController();
  final TextEditingController phoneFilterController = TextEditingController();
  final TextEditingController emailFilterController = TextEditingController();
  final TextEditingController nationalCodeFilterController = TextEditingController();
  final TextEditingController queryFilterController = TextEditingController();

  // ---------------------------------------------------------------- form (create and edit)

  UUserResponse? editing;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  DateTime birthdate = DateTime.now().toUtc();
  TagUser gender = TagUser.female;
  TagUser role = TagUser.guest;
  Set<TagUser> permissions = <TagUser>{};

  // ---------------------------------------------------------------- one user's details, shown above the edit fields

  final URxState detailState = URxState();
  List<UDormBedContractResponse> contracts = <UDormBedContractResponse>[];
  List<UWalletResponse> wallets = <UWalletResponse>[];
  List<UMerchantResponse> merchants = <UMerchantResponse>[];

  /// Only full admins give roles and permissions.
  bool get canManageRoles => U.user.isFullAdmin();

  void init({UUserResponse? user}) {
    if (user != null) queryFilterController.text = user.userName;
    read();
  }

  Future<void> read() async {
    state.loading();
    final List<int> tags = <int>[?tagFilter?.number, ?genderFilter?.number, if (verifiedOnly) TagUser.verified.number];
    await UServices.user.read(
      p: UUserReadParams(
        query: queryFilterController.valueOrNull(),
        firstName: firstNameFilterController.valueOrNull(),
        lastName: lastNameFilterController.valueOrNull(),
        userName: userNameFilterController.valueOrNull(),
        phoneNumber: phoneFilterController.valueOrNull(),
        email: emailFilterController.valueOrNull(),
        nationalCode: nationalCodeFilterController.valueOrNull(),
        tags: tags.isEmpty ? null : tags,
        fromCreatedAt: startDate,
        toCreatedAt: endDate,
        orderBy: tagOrderBy.value.number,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
      ),
      onOk: (UResponse<List<UUserResponse>> r) {
        list(r.result ?? <UUserResponse>[]);
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    for (final TextEditingController c in <TextEditingController>[
      firstNameFilterController,
      lastNameFilterController,
      userNameFilterController,
      phoneFilterController,
      emailFilterController,
      nationalCodeFilterController,
      queryFilterController,
    ]) {
      c.clear();
    }
    tagFilter = null;
    genderFilter = null;
    verifiedOnly = false;
    clearDates();
    tagOrderBy(TagOrderBy.createdAt);
    pageNumber(1);
    read();
  }

  void delete(UUserResponse u) => confirmAction(
    () => UServices.user.delete(p: UIdParams(id: u.id)),
    read,
    title: U.s.deleteItem(U.s.user),
    message: U.s.areYouSureToDeleteThisUser,
  );

  void loadForm(UUserResponse? u) {
    editing = u;
    firstNameController.text = u?.firstName ?? "";
    lastNameController.text = u?.lastName ?? "";
    userNameController.text = u?.userName ?? "";
    fatherNameController.text = u?.jsonData.fatherName ?? "";
    phoneController.text = u?.phoneNumber ?? "";
    emailController.text = u?.email ?? "";
    passwordController.clear();
    birthDateController.text = u?.birthdate?.toJalaliDate() ?? "";
    birthdate = u?.birthdate ?? DateTime.now().toUtc();
    gender = (u?.isMale() ?? false) ? TagUser.male : TagUser.female;
    role = (u?.isSuperAdmin() ?? false)
        ? TagUser.superAdmin
        : (u?.isSubAdmin() ?? false)
        ? TagUser.subAdmin
        : TagUser.guest;
    permissions = TagUser.permissions.where((TagUser t) => u?.tags.contains(t.number) ?? false).toSet();
  }

  /// Creates or updates the user. Returns true when the dialog can close.
  Future<bool> save() async {
    final List<int> roleTags = <int>[
      if (canManageRoles) role.number,
      if (canManageRoles && role == TagUser.subAdmin) ...permissions.map((TagUser t) => t.number),
    ];
    if (editing == null) {
      return await send(
            UServices.user.create(
              p: UUserCreateParams(
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                password: passwordController.trimmedLatin(),
                email: emailController.trimmedLatin(),
                phoneNumber: phoneController.trimmedLatin(),
                userName: userNameController.trimmedLatin(),
                birthdate: birthdate,
                fatherName: fatherNameController.text,
                tags: <int>[gender.number, ...roleTags],
              ),
            ),
            read,
          ) !=
          null;
    }
    // Tags not picked any more are removed: the other gender, the other roles and the unchecked permissions.
    final List<int> removeTags = <int>[
      if (gender == TagUser.male) TagUser.female.number else TagUser.male.number,
      if (canManageRoles) ...<TagUser>[TagUser.superAdmin, TagUser.subAdmin, TagUser.guest, ...TagUser.permissions].map((TagUser t) => t.number).where((int n) => !roleTags.contains(n)),
    ];
    return await send(
          UServices.user.update(
            p: UUserUpdateParams(
              id: editing!.id,
              firstName: firstNameController.text,
              lastName: lastNameController.text,
              password: passwordController.text,
              email: emailController.text.toLatinNumber(),
              phoneNumber: phoneController.trimmedLatin(),
              userName: userNameController.numString(),
              birthdate: birthdate,
              fatherName: fatherNameController.text,
              addTags: <int>[gender.number, ...roleTags],
              removeTags: removeTags,
            ),
          ),
          read,
        ) !=
        null;
  }

  /// Loads one user's wallets, merchants and dorm contracts for the details part of the dialog.
  Future<void> readDetail(UUserResponse u) async {
    detailState.loading();
    final UUserResponse? full = (await UServices.user.readById(
      p: UIdParams(id: u.id, selectorArgs: const UUserSelectorArgs(wallet: UWalletSelectorArgs(), merchant: UMerchantSelectorArgs())),
    )).$1?.result;
    wallets = full?.wallets ?? <UWalletResponse>[];
    merchants = full?.merchants ?? <UMerchantResponse>[];
    final (UResponse<List<UDormBedContractResponse>>? r, _, _) = await UServices.hotel.readDormBedContract(
      p: UDormBedContractReadParams(
        userId: u.id,
        pageNumber: 1,
        pageSize: 100,
        selectorArgs: const UDormBedContractSelectorArgs(
          bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs(dorm: UDormSelectorArgs())),
          invoice: UDormBedInvoiceSelectorArgs(),
        ),
      ),
    );
    if (r == null) {
      detailState.error();
      return;
    }
    contracts = r.result ?? <UDormBedContractResponse>[];
    detailState.loaded();
  }

  double get totalWalletBalance => wallets.fold(0, (double sum, UWalletResponse w) => sum + w.balance);

  UAdminHotelContractLifecycle lifecycleOf(UDormBedContractResponse c) {
    final DateTime now = DateTime.now();
    if (now.isBefore(c.startDate)) return UAdminHotelContractLifecycle.upcoming;
    if (now.isAfter(c.endDate)) return UAdminHotelContractLifecycle.expired;
    return UAdminHotelContractLifecycle.active;
  }

  double outstandingOf(UDormBedContractResponse c) =>
      (c.invoices ?? <UDormBedInvoiceResponse>[]).fold(0, (double sum, UDormBedInvoiceResponse i) => sum + max(i.debtAmount + i.penaltyAmount - i.paidAmount, 0));

  @override
  void dispose() {
    detailState.dispose();
    firstNameFilterController.dispose();
    lastNameFilterController.dispose();
    userNameFilterController.dispose();
    phoneFilterController.dispose();
    emailFilterController.dispose();
    nationalCodeFilterController.dispose();
    queryFilterController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    userNameController.dispose();
    fatherNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    birthDateController.dispose();
    list.dispose();
    super.dispose();
  }
}
