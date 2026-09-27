part of "../../u_admin.dart";

class UAdminParkingController extends UBaseController {
  List<UParkingResponse> list = <UParkingResponse>[];

  UParkingResponse? editing;
  late final TextEditingController title = fields.text();
  late final TextEditingController address = fields.text();
  late final TextEditingController phone = fields.text();
  late final TextEditingController capacity = fields.text();
  late final TextEditingController entrance = fields.text();
  late final TextEditingController hourly = fields.text();
  late final TextEditingController daily = fields.text();
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
    title.text = p?.title ?? "";
    address.text = p?.address ?? "";
    phone.text = p?.phoneNumber ?? "";
    capacity.text = p?.capacity.toString() ?? "";
    entrance.text = p?.entrancePrice.toStringAsSmartRound() ?? "";
    hourly.text = p?.hourlyPrice.toStringAsSmartRound() ?? "";
    daily.text = p?.dailyPrice.toStringAsSmartRound() ?? "";
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
                title: title.text,
                address: address.text.nullIfEmpty(),
                phoneNumber: phone.text.nullIfEmpty(),
                capacity: intOf(capacity) ?? 0,
                entrancePrice: numOf(entrance) ?? 0,
                hourlyPrice: numOf(hourly) ?? 0,
                dailyPrice: numOf(daily) ?? 0,
                creatorId: owner?.id,
                adminUserIds: adminUserIds,
              ),
            )
          : UServices.parking.updateParking(
              p: UParkingUpdateParams(
                id: p.id,
                title: title.text.nullIfEmpty(),
                address: address.text,
                phoneNumber: phone.text,
                capacity: intOf(capacity),
                addTags: <int>[on.number],
                removeTags: <int>[off.number],
                entrancePrice: numOf(entrance),
                hourlyPrice: numOf(hourly),
                dailyPrice: numOf(daily),
                adminUserIds: adminUserIds,
              ),
            ),
      read,
    );
    return ok != null;
  }

  void delete(UParkingResponse i) => confirmAction(() => UServices.parking.deleteParking(p: UIdParams(id: i.id)), read);
}
