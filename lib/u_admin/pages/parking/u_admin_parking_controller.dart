part of "../../u_admin.dart";

// Parking management: list, create (with owner + assigned admins), update, delete.
class UAdminParkingController extends UBaseController {
  List<UParkingResponse> list = <UParkingResponse>[];

  // Optional owner/creator filter.
  final Rxn<UUserResponse> creatorFilter = Rxn<UUserResponse>();

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParking(
      p: UParkingReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        creatorId: creatorFilter.value?.id,
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
        selectorArgs: const ParkingSelectorArgs(creator: UserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingResponse>> r) {
        list = r.result ?? <UParkingResponse>[];
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

  void create({required UParkingCreateParams p}) {
    ULoading.show();
    UServices.parking.createParking(
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

  void update({required UParkingUpdateParams p}) {
    ULoading.show();
    UServices.parking.updateParking(
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

  void delete(UParkingResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.parking.deleteParking(
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

  // Query-based user search for the owner / assigned-admins pickers.
  Future<List<UUserResponse>> readUsers(String query) async {
    final List<UUserResponse> result = <UUserResponse>[];
    await UServices.user.read(
      p: UUserReadParams(query: query.nullIfEmpty(), pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UUserResponse>> r) => result.addAll(r.result ?? <UUserResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }

  Future<UUserResponse?> fetchUserById(String id) async {
    final Completer<UUserResponse?> completer = Completer<UUserResponse?>();
    await UServices.user.readById(
      p: UIdParams(id: id),
      onOk: (UResponse<UUserResponse> r) => completer.complete(r.result),
      onError: (_) => completer.complete(null),
      onException: (_) => completer.complete(null),
      onProgress: (int e) {},
    );
    return completer.future;
  }
}
