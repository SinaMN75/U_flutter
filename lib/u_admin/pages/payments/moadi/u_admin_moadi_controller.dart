part of "../../../u_admin.dart";

class UAdminMoadiController extends UBaseController {
  List<UMoadiResponse> list = <UMoadiResponse>[];

  UUserResponse? user;
  TagMoadi? status;
  late final TextEditingController nameFilter = fields.text();
  late final TextEditingController economicCodeFilter = fields.text();
  late final TextEditingController nationalCodeFilter = fields.text();
  late final TextEditingController uniqueTaxCodeFilter = fields.text();

  late final TextEditingController rejectReason = fields.text();

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
        name: nameFilter.text.nullIfEmpty(),
        economicCode: economicCodeFilter.text.nullIfEmpty(),
        nationalCode: nationalCodeFilter.text.nullIfEmpty(),
        uniqueTaxCode: uniqueTaxCodeFilter.text.nullIfEmpty(),
        tags: status == null ? null : <int>[status!.number],
        userId: user?.id,
        fromCreatedAt: startDate,
        toCreatedAt: endDate,
        selectorArgs: const UMoadiSelectorArgs(user: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UMoadiResponse>> r) {
        list = r.result ?? <UMoadiResponse>[];
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
    status = null;
    user = null;
    clearDates();
    reloadFirstPage(read);
  }

  void approve(UMoadiResponse i) => confirmAction(
    () => UServices.moadi.approve(p: UIdParams(id: i.id)),
    read,
    title: U.s.approve,
    message: U.s.areYouSureYouWantToApproveAndRegisterThisTaxpayerInTheNamatSystem,
  );

  Future<bool> reject(UMoadiResponse i) async => await submit(UServices.moadi.reject(p: UMoadiRejectParams(id: i.id, reason: rejectReason.text.nullIfEmpty())), read) != null;

  void delete(UMoadiResponse i) => confirmAction(() => UServices.moadi.delete(p: UIdParams(id: i.id)), read);
}
