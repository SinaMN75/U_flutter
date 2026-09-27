part of "../../u_admin.dart";

// Parking reports (vehicle sessions): read-only list, optionally scoped to one parking.
class UAdminParkingReportController extends UBaseController {
  List<UParkingReportResponse> list = <UParkingReportResponse>[];

  // Optional page-context scope: only this parking's reports.
  UParkingResponse? parking;

  Future<void> init({UParkingResponse? parking}) async {
    this.parking = parking;
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParkingReport(
      p: UParkingReportReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        parkingId: parking?.id,
        selectorArgs: const UParkingReportSelectorArgs(
          parking: UParkingSelectorArgs(creator: UUserSelectorArgs()),
          creator: UUserSelectorArgs(),
          vehicle: UVehicleSelectorArgs(),
        ),
      ),
      onOk: (UResponse<List<UParkingReportResponse>> r) {
        list = r.result ?? <UParkingReportResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  // Convenience totals for the report header.
  double get totalAmount => list.fold(0, (double sum, UParkingReportResponse r) => sum + (r.amount ?? 0));

  void delete(UParkingReportResponse i) => confirmAction(() => UServices.parking.deleteParkingReport(p: UIdParams(id: i.id)), read);
}
