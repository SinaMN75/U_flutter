part of "../../u_admin.dart";

class UAdminParkingSubscriptionController extends UBaseController {
  List<UParkingSubscriptionResponse> list = <UParkingSubscriptionResponse>[];
  UParkingResponse? parking;
  final RxnBool isActive = RxnBool(true);
  final TextEditingController controllerQuery = TextEditingController();

  Future<void> init({UParkingResponse? parking}) {
    this.parking = parking;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParkingSubscription(
      p: UParkingSubscriptionReadParams(
        parkingId: parking?.id,
        query: controllerQuery.trimmedLatin().nullIfEmpty(),
        isActive: isActive.value == true ? true : null,
        isExpired: isActive.value == false ? true : null,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const ParkingSubscriptionSelectorArgs(vehicle: VehicleSelectorArgs(), creator: UserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingSubscriptionResponse>> r) {
        list = r.result ?? <UParkingSubscriptionResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void create({required UParkingSubscriptionCreateParams p}) {
    ULoading.show();
    UServices.parking.createParkingSubscription(
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

  void update({required UParkingSubscriptionUpdateParams p}) {
    ULoading.show();
    UServices.parking.updateParkingSubscription(
      p: p,
      onOk: (UEmptyResponse r) {
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

  void delete(UParkingSubscriptionResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.parking.deleteParkingSubscription(
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
