part of "../../u_admin.dart";

class UAdminParkingStaffController extends UBaseController {
  List<UParkingStaffResponse> list = <UParkingStaffResponse>[];
  UParkingResponse? parking;

  static const List<TagParkingStaff> selectablePermissions = <TagParkingStaff>[
    TagParkingStaff.registerEntryExit,
    TagParkingStaff.applyManualDiscount,
    TagParkingStaff.manageSubscriptions,
    TagParkingStaff.changeTariff,
    TagParkingStaff.viewFinancialReports,
  ];

  UParkingStaffResponse? editing;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController shiftTitleController = TextEditingController();
  Set<TagParkingStaff> permissions = <TagParkingStaff>{};
  double maxDiscount = 0;

  Future<void> init({UParkingResponse? parking}) {
    this.parking = parking;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParkingStaff(
      p: UParkingStaffReadParams(
        parkingId: parking?.id,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const UParkingStaffSelectorArgs(user: UUserSelectorArgs(), creator: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingStaffResponse>> r) {
        list = r.result ?? <UParkingStaffResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void loadForm(UParkingStaffResponse? s) {
    editing = s;
    firstNameController.clear();
    lastNameController.clear();
    userNameController.clear();
    passwordController.clear();
    phoneController.clear();
    shiftTitleController.text = s?.shiftTitle ?? "";
    permissions = s == null
        ? <TagParkingStaff>{TagParkingStaff.registerEntryExit}
        : TagParkingStaff.values.where((TagParkingStaff t) => s.tags.contains(t.number)).toSet();
    maxDiscount = s?.maxDiscountPercent.toDouble() ?? 0;
  }

  void togglePermission(TagParkingStaff t, bool on) => on ? permissions.add(t) : permissions.remove(t);

  Future<bool> save() async {
    final UParkingStaffResponse? s = editing;
    return await send(
      s == null
          ? UServices.parking.createParkingStaff(
              p: UParkingStaffCreateParams(
                parkingId: parking?.id ?? "",
                userName: userNameController.trimmedLatin(),
                password: passwordController.trimmedLatin(),
                tags: permissions.isEmpty ? <int>[TagParkingStaff.registerEntryExit.number] : permissions.map((TagParkingStaff t) => t.number).toList(),
                firstName: firstNameController.text.nullIfEmpty(),
                lastName: lastNameController.text.nullIfEmpty(),
                phoneNumber: phoneController.trimmedLatin().nullIfEmpty(),
                shiftTitle: shiftTitleController.text.nullIfEmpty(),
                maxDiscountPercent: maxDiscount.round(),
              ),
            )
          : UServices.parking.updateParkingStaff(
              p: UParkingStaffUpdateParams(
                id: s.id,
                shiftTitle: shiftTitleController.text.nullIfEmpty(),
                password: passwordController.text.nullIfEmpty(),
                maxDiscountPercent: maxDiscount.round(),
                tags: permissions.map((TagParkingStaff t) => t.number).toList(),
              ),
            ),
      read,
    ) !=
        null;
  }

  void delete(UParkingStaffResponse i) => confirmAction(() => UServices.parking.deleteParkingStaff(p: UIdParams(id: i.id)), read, message: U.s.areYouSureToDeleteThisUser);

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    shiftTitleController.dispose();
    super.dispose();
  }
}
