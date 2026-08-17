part of "../../../u_admin.dart";

class UAdminMoadiController extends UBaseController {
  List<UMoadiResponse> list = <UMoadiResponse>[];

  final Rxn<UUserResponse> user = Rxn<UUserResponse>();
  final Rxn<TagMoadi> status = Rxn<TagMoadi>();

  final TextEditingController nameFilter = TextEditingController();
  final TextEditingController economicCodeFilter = TextEditingController();
  final TextEditingController nationalCodeFilter = TextEditingController();
  final TextEditingController uniqueTaxCodeFilter = TextEditingController();
  final TextEditingController fromCreatedController = TextEditingController();
  final TextEditingController toCreatedController = TextEditingController();

  Future<void> init({UUserResponse? user}) {
    if (user != null) this.user.value = user;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.moadi.read(
      p: UMoadiReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        name: nameFilter.text.nullIfEmpty(),
        economicCode: economicCodeFilter.text.nullIfEmpty(),
        nationalCode: nationalCodeFilter.text.nullIfEmpty(),
        uniqueTaxCode: uniqueTaxCodeFilter.text.nullIfEmpty(),
        tags: status.value == null ? null : <int>[status.value!.number],
        userId: user.value?.id,
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
        selectorArgs: const MoadiSelectorArgs(user: UserSelectorArgs()),
      ),
      onOk: (UResponse<List<UMoadiResponse>> r) {
        list = r.result ?? <UMoadiResponse>[];
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
    nameFilter.clear();
    economicCodeFilter.clear();
    nationalCodeFilter.clear();
    uniqueTaxCodeFilter.clear();
    status.value = null;
    user.value = null;
    fromCreatedController.clear();
    toCreatedController.clear();
    fromCreatedAt = null;
    toCreatedAt = null;
    reloadFirstPage(read);
  }

  void approve(UMoadiResponse i) => UNavigator.confirm(
    title: U.s.approve,
    message: U.s.areYouSureYouWantToApproveAndRegisterThisTaxpayerInTheNamatSystem,
    onConfirm: () {
      ULoading.show();
      UServices.moadi.approve(
        p: UIdParams(id: i.id),
        onOk: (UResponse<UMoadiResponse> r) {
          ULoading.dismiss();
          UNavigator.back();
          okCallback(r.message, read);
        },
        onError: (UEmptyResponse r) {
          ULoading.dismiss();
          UNavigator.back();
          errorCallBack(r.message, read);
        },
        onException: (String e) {
          ULoading.dismiss();
          UNavigator.back();
          UToast.error(message: e);
        },
      );
    },
  );

  void reject(UMoadiResponse i, String? reason) {
    ULoading.show();
    UServices.moadi.reject(
      p: UMoadiRejectParams(id: i.id, reason: reason),
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
        UToast.error(message: e);
      },
    );
  }

  void delete(UMoadiResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.moadi.delete(
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

  Future<List<UUserResponse>> readUsers(String query) async {
    final List<UUserResponse> result = <UUserResponse>[];
    await UServices.user.read(
      p: UUserReadParams(query: query, pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UUserResponse>> r) => result.addAll(r.result ?? <UUserResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }
}
