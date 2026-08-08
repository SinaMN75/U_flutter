part of "../../../u_admin.dart";

class UAdminDormRoomController extends UBaseController {
  List<UDormRoomResponse> list = <UDormRoomResponse>[];

  UDormResponse? dorm;

  final TextEditingController titleFilter = TextEditingController();

  Future<void> init({UDormResponse? dorm}) async {
    this.dorm = dorm;
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDormRooms(
      p: UDormRoomReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        dormId: dorm?.id,
        title: titleFilter.text.nullIfEmpty(),
        selectorArgs: const DormRoomSelectorArgs(dorm: DormSelectorArgs(), beds: DormBedSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormRoomResponse>> r) {
        list = r.result ?? <UDormRoomResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    titleFilter.clear();
    reloadFirstPage(read);
  }

  void create({required UDormRoomCreateParams p}) => UServices.hotel.createDormRoom(
    p: p,
    onOk: (UResponse<String> r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(
      U.s.errorSubmittingForm,
      read,
    ),
  );

  void update({required UDormRoomUpdateParams p}) => UServices.hotel.updateDormRoom(
    p: p,
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(
      U.s.errorSubmittingForm,
      read,
    ),
  );

  void delete(UDormRoomResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.deleteDormRoom(
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

  Future<List<UDormResponse>> readDorms(String query) async {
    final List<UDormResponse> result = <UDormResponse>[];
    await UServices.hotel.readDorms(
      p: UDormReadParams(title: query, pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UDormResponse>> r) => result.addAll(r.result ?? <UDormResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }
}
