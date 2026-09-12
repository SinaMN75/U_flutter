part of "../../../u_admin.dart";

class UAdminTerminalBrandController extends UBaseController {
  List<UTerminalBrandResponse> list = <UTerminalBrandResponse>[];

  final TextEditingController titleFilter = TextEditingController();
  final TextEditingController modelFilter = TextEditingController();

  Future<void> init() async {
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.terminal.readBrand(
      p: UTerminalBrandReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.text.nullIfEmpty(),
        model: modelFilter.text.nullIfEmpty(),
        orderBy: tagOrderBy.value.number,
        selectorArgs: const TerminalBrandSelectorArgs(),
      ),
      onOk: (UResponse<List<UTerminalBrandResponse>> r) {
        list = r.result ?? <UTerminalBrandResponse>[];
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
    modelFilter.clear();
    reloadFirstPage(read);
  }

  void create({required UTerminalBrandCreateParams p}) {
    ULoading.show();
    UServices.terminal.createBrand(
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

  void update({required UTerminalBrandUpdateParams p}) {
    ULoading.show();
    UServices.terminal.updateBrand(
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

  void delete(UTerminalBrandResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.terminal.deleteBrand(
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