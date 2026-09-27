part of "../../u_admin.dart";

class UAdminPaymentMoadiController extends UAdminBaseController {
  List<UMoadiResponse> list = <UMoadiResponse>[];

  UUserResponse? user;
  TagMoadi? status;
  final TextEditingController nameFilterController = TextEditingController();
  final TextEditingController economicCodeFilterController = TextEditingController();
  final TextEditingController nationalCodeFilterController = TextEditingController();
  final TextEditingController uniqueTaxCodeFilterController = TextEditingController();

  final TextEditingController rejectReasonController = TextEditingController();

  Future<void> init({UUserResponse? user}) {
    this.user = user;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.moadi.read(
      p: UMoadiReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        name: nameFilterController.text.nullIfEmpty(),
        economicCode: economicCodeFilterController.text.nullIfEmpty(),
        nationalCode: nationalCodeFilterController.text.nullIfEmpty(),
        uniqueTaxCode: uniqueTaxCodeFilterController.text.nullIfEmpty(),
        tags: status == null ? null : <int>[status!.number],
        userId: user?.id,
        fromCreatedAt: startDate,
        toCreatedAt: endDate,
        selectorArgs: const UMoadiSelectorArgs(user: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UMoadiResponse>> r) {
        list = r.result ?? <UMoadiResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    nameFilterController.clear();
    economicCodeFilterController.clear();
    nationalCodeFilterController.clear();
    uniqueTaxCodeFilterController.clear();
    status = null;
    user = null;
    clearDates();
    pageNumber(1);
    read();
  }

  void approve(UMoadiResponse i) => confirmAction(
    () => UServices.moadi.approve(p: UIdParams(id: i.id)),
    read,
    title: U.s.approve,
    message: U.s.areYouSureYouWantToApproveAndRegisterThisTaxpayerInTheNamatSystem,
  );

  Future<bool> reject(UMoadiResponse i) async => await submit(UServices.moadi.reject(p: UMoadiRejectParams(id: i.id, reason: rejectReasonController.text.nullIfEmpty())), read) != null;

  void delete(UMoadiResponse i) => confirmAction(() => UServices.moadi.delete(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    nameFilterController.dispose();
    economicCodeFilterController.dispose();
    nationalCodeFilterController.dispose();
    uniqueTaxCodeFilterController.dispose();
    rejectReasonController.dispose();
    super.dispose();
  }
}
