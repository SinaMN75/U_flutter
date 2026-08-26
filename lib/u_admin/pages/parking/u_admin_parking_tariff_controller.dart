part of "../../u_admin.dart";

/// Tariffs are one row per parking + vehicle type, carrying both the hourly rates and the
/// subscription prices, so the list is short and edited in place.
class UAdminParkingTariffController extends UBaseController {
  List<UParkingTariffResponse> list = <UParkingTariffResponse>[];
  UParkingResponse? parking;

  Future<void> init({UParkingResponse? parking}) {
    this.parking = parking;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParkingTariff(
      p: UParkingTariffReadParams(
        parkingId: parking?.id,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const ParkingTariffSelectorArgs(creator: UserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingTariffResponse>> r) {
        list = r.result ?? <UParkingTariffResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void save({required UParkingTariffCreateParams p}) {
    ULoading.show();
    UServices.parking.createParkingTariff(
      p: p,
      onOk: (UResponse<String> r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        errorCallBack(U.s.errorSubmittingForm, read);
      },
    );
  }

  void delete(UParkingTariffResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.parking.deleteParkingTariff(
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
