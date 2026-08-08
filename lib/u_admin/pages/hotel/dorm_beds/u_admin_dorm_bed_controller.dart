part of "../../../u_admin.dart";

class UAdminDormBedController extends UBaseController {
  List<UDormBedResponse> list = <UDormBedResponse>[];

  UDormRoomResponse? room;
  UDormResponse? dorm;

  final TextEditingController titleFilter = TextEditingController();

  Future<void> init({UDormRoomResponse? room, UDormResponse? dorm}) async {
    this.room = room;
    this.dorm = dorm;
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDormBeds(
      p: UDormBedReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        roomId: room?.id,
        dormId: dorm?.id,
        title: titleFilter.text.nullIfEmpty(),
        selectorArgs: const DormBedSelectorArgs(contract: ContractSelectorArgs(), room: DormRoomSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormBedResponse>> r) {
        list = r.result ?? <UDormBedResponse>[];
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

  void create({required UDormBedCreateParams p}) => UServices.hotel.createDormBed(
    p: p,
    onOk: (UResponse<String> r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UDormBedUpdateParams p}) => UServices.hotel.updateDormBed(
    p: p,
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void delete(UDormBedResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.deleteDormBed(
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

  Future<List<UDormRoomResponse>> readRooms(String query) async {
    final List<UDormRoomResponse> result = <UDormRoomResponse>[];
    await UServices.hotel.readDormRooms(
      p: UDormRoomReadParams(title: query, dormId: dorm?.id, pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UDormRoomResponse>> r) => result.addAll(r.result ?? <UDormRoomResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }
}
