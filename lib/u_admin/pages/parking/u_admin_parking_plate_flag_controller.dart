part of "../../u_admin.dart";

class UAdminParkingPlateFlagController extends UBaseController {
  List<UParkingPlateFlagResponse> list = <UParkingPlateFlagResponse>[];
  UParkingResponse? parking;

  late final TextEditingController reason = fields.text();
  late final TextEditingController amount = fields.text();
  late final TextEditingController spotNumber = fields.text();
  String plate = "";
  TagParkingPlateFlag kind = TagParkingPlateFlag.debt;

  Future<void> init({UParkingResponse? parking}) {
    this.parking = parking;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParkingPlateFlag(
      p: UParkingPlateFlagReadParams(
        parkingId: parking?.id,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const UParkingPlateFlagSelectorArgs(creator: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingPlateFlagResponse>> r) {
        list = r.result ?? <UParkingPlateFlagResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void loadForm() {
    reason.clear();
    amount.clear();
    spotNumber.clear();
    plate = "";
    kind = TagParkingPlateFlag.debt;
  }

  Future<bool> save() async {
    if (plate.length < 6) return false;
    final dynamic ok = await submit(
      UServices.parking.createParkingPlateFlag(
        p: UParkingPlateFlagCreateParams(
          parkingId: parking?.id ?? "",
          licencePlate: plate,
          tags: <int>[kind.number],
          reason: reason.text.nullIfEmpty(),
          amount: numOf(amount),
          spotNumber: spotNumber.text.nullIfEmpty(),
        ),
      ),
      read,
    );
    return ok != null;
  }

  void delete(UParkingPlateFlagResponse i) => confirmAction(() => UServices.parking.deleteParkingPlateFlag(p: UIdParams(id: i.id)), read);
}
