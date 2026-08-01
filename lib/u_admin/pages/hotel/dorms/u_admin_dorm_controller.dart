part of "../../../u_admin.dart";

class UAdminDormController extends UBaseController {
  List<UDormResponse> list = <UDormResponse>[];

  final TextEditingController titleFilter = TextEditingController();

  void init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDorms(
      p: UDormReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.text.nullIfEmpty(),
        selectorArgs: const DormSelectorArgs(rooms: DormRoomSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormResponse>> r) {
        list = r.result ?? <UDormResponse>[];
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

  void create({required UDormCreateParams p}) => UServices.hotel.createDorm(
    p: p,
    onOk: (UResponse<String> r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UDormUpdateParams p}) => UServices.hotel.updateDorm(
    p: p,
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void delete(UDormResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.deleteDorm(
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
