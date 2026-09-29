part of "../../../u_admin.dart";

class UAdminParkingShiftController extends UBaseController {
  List<UParkingShiftResponse> list = <UParkingShiftResponse>[];
  UParkingResponse? parking;

  double get totalRevenue => list.fold(0, (double sum, UParkingShiftResponse i) => sum + i.total);

  Future<void> init({UParkingResponse? parking}) {
    this.parking = parking;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParkingShift(
      p: UParkingShiftReadParams(
        parkingId: parking?.id,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const UParkingShiftSelectorArgs(creator: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingShiftResponse>> r) {
        list = r.result ?? <UParkingShiftResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }
}
