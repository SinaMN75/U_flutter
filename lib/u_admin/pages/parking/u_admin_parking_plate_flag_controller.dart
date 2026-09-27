part of "../../u_admin.dart";

class UAdminParkingPlateFlagController extends UBaseController {
  List<UParkingPlateFlagResponse> list = <UParkingPlateFlagResponse>[];
  UParkingResponse? parking;

  final TextEditingController reasonController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController spotNumberController = TextEditingController();
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
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void loadForm() {
    reasonController.clear();
    amountController.clear();
    spotNumberController.clear();
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
          reason: reasonController.text.nullIfEmpty(),
          amount: numOf(amountController),
          spotNumber: spotNumberController.text.nullIfEmpty(),
        ),
      ),
      read,
    );
    return ok != null;
  }

  void delete(UParkingPlateFlagResponse i) => confirmAction(() => UServices.parking.deleteParkingPlateFlag(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    reasonController.dispose();
    amountController.dispose();
    spotNumberController.dispose();
    super.dispose();
  }
}
