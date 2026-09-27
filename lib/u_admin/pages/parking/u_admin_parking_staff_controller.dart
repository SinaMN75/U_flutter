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
  late final TextEditingController firstName = fields.text();
  late final TextEditingController lastName = fields.text();
  late final TextEditingController userName = fields.text();
  late final TextEditingController password = fields.text();
  late final TextEditingController phone = fields.text();
  late final TextEditingController shiftTitle = fields.text();
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
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void loadForm(UParkingStaffResponse? s) {
    editing = s;
    firstName.clear();
    lastName.clear();
    userName.clear();
    password.clear();
    phone.clear();
    shiftTitle.text = s?.shiftTitle ?? "";
    permissions = s == null
        ? <TagParkingStaff>{TagParkingStaff.registerEntryExit}
        : TagParkingStaff.values.where((TagParkingStaff t) => s.tags.contains(t.number)).toSet();
    maxDiscount = s?.maxDiscountPercent.toDouble() ?? 0;
  }

  void togglePermission(TagParkingStaff t, bool on) => on ? permissions.add(t) : permissions.remove(t);

  Future<bool> save() async {
    final UParkingStaffResponse? s = editing;
    final dynamic ok = await submit(
      s == null
          ? UServices.parking.createParkingStaff(
              p: UParkingStaffCreateParams(
                parkingId: parking?.id ?? "",
                userName: userName.trimmedLatin(),
                password: password.trimmedLatin(),
                tags: permissions.isEmpty ? <int>[TagParkingStaff.registerEntryExit.number] : permissions.map((TagParkingStaff t) => t.number).toList(),
                firstName: firstName.text.nullIfEmpty(),
                lastName: lastName.text.nullIfEmpty(),
                phoneNumber: phone.trimmedLatin().nullIfEmpty(),
                shiftTitle: shiftTitle.text.nullIfEmpty(),
                maxDiscountPercent: maxDiscount.round(),
              ),
            )
          : UServices.parking.updateParkingStaff(
              p: UParkingStaffUpdateParams(
                id: s.id,
                shiftTitle: shiftTitle.text.nullIfEmpty(),
                password: password.text.nullIfEmpty(),
                maxDiscountPercent: maxDiscount.round(),
                tags: permissions.map((TagParkingStaff t) => t.number).toList(),
              ),
            ),
      read,
    );
    return ok != null;
  }

  void delete(UParkingStaffResponse i) => confirmAction(() => UServices.parking.deleteParkingStaff(p: UIdParams(id: i.id)), read, message: U.s.areYouSureToDeleteThisUser);
}
