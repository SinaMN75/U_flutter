part of "../../u_admin.dart";

class UAdminParkingStaffController extends UBaseController {
  List<UParkingStaffResponse> list = <UParkingStaffResponse>[];
  UParkingResponse? parking;

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
        selectorArgs: const ParkingStaffSelectorArgs(user: UserSelectorArgs(), creator: UserSelectorArgs()),
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

  void create({required UParkingStaffCreateParams p}) {
    ULoading.show();
    UServices.parking.createParkingStaff(
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

  void update({required UParkingStaffUpdateParams p}) {
    ULoading.show();
    UServices.parking.updateParkingStaff(
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

  void delete(UParkingStaffResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureToDeleteThisUser,
    onConfirm: () => UServices.parking.deleteParkingStaff(
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

class UAdminParkingPlateFlagController extends UBaseController {
  List<UParkingPlateFlagResponse> list = <UParkingPlateFlagResponse>[];
  UParkingResponse? parking;

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
        selectorArgs: const ParkingPlateFlagSelectorArgs(creator: UserSelectorArgs()),
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

  void create({required UParkingPlateFlagCreateParams p}) {
    ULoading.show();
    UServices.parking.createParkingPlateFlag(
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

  void delete(UParkingPlateFlagResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.parking.deleteParkingPlateFlag(
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
        selectorArgs: const ParkingShiftSelectorArgs(creator: UserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingShiftResponse>> r) {
        list = r.result ?? <UParkingShiftResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }
}
