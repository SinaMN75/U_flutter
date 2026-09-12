part of "../../../u_admin.dart";

class UAdminTerminalBrokerController extends UBaseController {
  List<UTerminalBrokerResponse> list = <UTerminalBrokerResponse>[];

  final TextEditingController titleFilter = TextEditingController();

  Future<void> init() async {
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.terminal.readBroker(
      p: UTerminalBrokerReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.text.nullIfEmpty(),
        orderBy: tagOrderBy.value.number,
        selectorArgs: const TerminalBrokerSelectorArgs(),
      ),
      onOk: (UResponse<List<UTerminalBrokerResponse>> r) {
        list = r.result ?? <UTerminalBrokerResponse>[];
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
    titleFilter.clear();
    reloadFirstPage(read);
  }

  void create({required UTerminalBrokerCreateParams p}) {
    ULoading.show();
    UServices.terminal.createBroker(
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

  void update({required UTerminalBrokerUpdateParams p}) {
    ULoading.show();
    UServices.terminal.updateBroker(
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

  void delete(UTerminalBrokerResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.terminal.deleteBroker(
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