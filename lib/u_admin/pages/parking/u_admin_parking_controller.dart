part of "../../u_admin.dart";

class UAdminParkingController extends UBaseController {
  List<UParkingResponse> list = <UParkingResponse>[];

  UParkingResponse? editing;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController entranceController = TextEditingController();
  final TextEditingController hourlyController = TextEditingController();
  final TextEditingController dailyController = TextEditingController();
  bool disabled = false;
  UUserResponse? owner;
  List<UUserResponse> admins = <UUserResponse>[];

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParking(
      p: UParkingReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const UParkingSelectorArgs(creator: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingResponse>> r) {
        list = r.result ?? <UParkingResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  Future<void> loadForm(UParkingResponse? p) async {
    editing = p;
    titleController.text = p?.title ?? "";
    addressController.text = p?.address ?? "";
    phoneController.text = p?.phoneNumber ?? "";
    capacityController.text = p?.capacity.toString() ?? "";
    entranceController.text = p?.entrancePrice.toStringAsSmartRound() ?? "";
    hourlyController.text = p?.hourlyPrice.toStringAsSmartRound() ?? "";
    dailyController.text = p?.dailyPrice.toStringAsSmartRound() ?? "";
    disabled = p?.tags.contains(TagParking.disabled.number) ?? false;
    owner = p?.creator;
    admins = await readUsersById(p?.adminUserIds ?? <String>[]);
  }

  Future<bool> save() async {
    final UParkingResponse? p = editing;
    final TagParking on = disabled ? TagParking.disabled : TagParking.active;
    final TagParking off = disabled ? TagParking.active : TagParking.disabled;
    final List<String> adminUserIds = admins.map((UUserResponse u) => u.id).toList();
    final dynamic ok = await submit(
      p == null
          ? UServices.parking.createParking(
              p: UParkingCreateParams(
                tags: <int>[on.number],
                title: titleController.text,
                address: addressController.text.nullIfEmpty(),
                phoneNumber: phoneController.text.nullIfEmpty(),
                capacity: intOf(capacityController) ?? 0,
                entrancePrice: numOf(entranceController) ?? 0,
                hourlyPrice: numOf(hourlyController) ?? 0,
                dailyPrice: numOf(dailyController) ?? 0,
                creatorId: owner?.id,
                adminUserIds: adminUserIds,
              ),
            )
          : UServices.parking.updateParking(
              p: UParkingUpdateParams(
                id: p.id,
                title: titleController.text.nullIfEmpty(),
                address: addressController.text,
                phoneNumber: phoneController.text,
                capacity: intOf(capacityController),
                addTags: <int>[on.number],
                removeTags: <int>[off.number],
                entrancePrice: numOf(entranceController),
                hourlyPrice: numOf(hourlyController),
                dailyPrice: numOf(dailyController),
                adminUserIds: adminUserIds,
              ),
            ),
      read,
    );
    return ok != null;
  }

  void delete(UParkingResponse i) => confirmAction(() => UServices.parking.deleteParking(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleController.dispose();
    addressController.dispose();
    phoneController.dispose();
    capacityController.dispose();
    entranceController.dispose();
    hourlyController.dispose();
    dailyController.dispose();
    super.dispose();
  }
}
