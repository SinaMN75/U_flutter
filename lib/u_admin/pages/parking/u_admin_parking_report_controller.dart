part of "../../u_admin.dart";

// Parking reports (vehicle sessions): read-only list, optionally scoped to one parking.
class UAdminParkingReportController extends UBaseController {
  List<UParkingReportResponse> list = <UParkingReportResponse>[];

  // Optional page-context scope: only this parking's reports.
  UParkingResponse? parking;

  final Rxn<UUserResponse> creatorFilter = Rxn<UUserResponse>();

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
        creatorId: creatorFilter.value?.id,
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
        selectorArgs: const ParkingReportSelectorArgs(
          parking: ParkingSelectorArgs(creator: UserSelectorArgs()),
          creator: UserSelectorArgs(),
          vehicle: VehicleSelectorArgs(),
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

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    creatorFilter.value = null;
    fromCreatedAt = null;
    toCreatedAt = null;
    reloadFirstPage(read);
  }

  // Convenience totals for the report header.
  double get totalAmount => list.fold(0, (double sum, UParkingReportResponse r) => sum + (r.amount ?? 0));

  void delete(UParkingReportResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.parking.deleteParkingReport(
      p: UIdParams(id: i.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );
}
