part of "../../../u_admin.dart";

enum UAdminContractStatusFilter { all, active, upcoming, expired, expiringSoon }

class UAdminContractController extends UBaseController {
  List<UDormBedContractResponse> list = <UDormBedContractResponse>[];
  UDormBedResponse? bed;
  UUserResponse? user;

  /// Only two contract kinds exist: monthly (rent + deposit) and daily (one invoice, no deposit).
  static const List<TagDormBedContract> types = <TagDormBedContract>[TagDormBedContract.monthly, TagDormBedContract.daily];

  late final TextEditingController tenantFilter = fields.text();
  int? typeFilter;
  UAdminContractStatusFilter statusFilter = UAdminContractStatusFilter.all;
  UDormResponse? dormFilter;
  UDormBedResponse? bedFilter;

  // ---------------------------------------------------------------- form (create and edit)

  UDormBedContractResponse? editing;
  UDormBedResponse? formBed;
  UUserResponse? formUser;
  TagDormBedContract type = TagDormBedContract.monthly;
  DateTime? contractStart;
  DateTime? contractEnd;
  late final TextEditingController startText = fields.text();
  late final TextEditingController endText = fields.text();
  late final TextEditingController deposit = fields.text();
  late final TextEditingController rent = fields.text();
  late final TextEditingController penalty = fields.text();
  late final TextEditingController description = fields.text();

  void init({UDormBedResponse? bed, UUserResponse? user}) {
    this.bed = bed;
    this.user = user;
    read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDormBedContract(
      p: UDormBedContractReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        bedId: bedFilter?.id ?? bed?.id,
        userId: user?.id,
        dormId: dormFilter?.id,
        startDate: startDate,
        endDate: endDate,
        userName: tenantFilter.valueOrNull(),
        tags: typeFilter == null ? null : <int>[typeFilter!],
        activeOnly: statusFilter == UAdminContractStatusFilter.active ? true : null,
        upcomingOnly: statusFilter == UAdminContractStatusFilter.upcoming ? true : null,
        expiredOnly: statusFilter == UAdminContractStatusFilter.expired ? true : null,
        expiringWithinDays: statusFilter == UAdminContractStatusFilter.expiringSoon ? 30 : null,
        selectorArgs: const UDormBedContractSelectorArgs(
          user: UUserSelectorArgs(),
          bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs(dorm: UDormSelectorArgs())),
          invoice: UDormBedInvoiceSelectorArgs(),
        ),
      ),
      onOk: (UResponse<List<UDormBedContractResponse>> r) {
        list = r.result ?? <UDormBedContractResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UResponse<dynamic> e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    tenantFilter.clear();
    clearDates();
    typeFilter = null;
    dormFilter = null;
    bedFilter = null;
    statusFilter = UAdminContractStatusFilter.all;
    reloadFirstPage(read);
  }

  TagDormBedContract? typeOf(UDormBedContractResponse i) => types.where((TagDormBedContract t) => i.tags.contains(t.number)).firstOrNull;

  bool isActive(UDormBedContractResponse i) => !i.startDate.isAfter(DateTime.now()) && !i.endDate.isBefore(DateTime.now());

  Future<List<UDormBedResponse>> searchBeds(String query) async =>
      (await UServices.hotel.readDormBeds(
        p: UDormBedReadParams(
          title: query,
          dormId: dormFilter?.id,
          pageSize: 100,
          pageNumber: 1,
          selectorArgs: const UDormBedSelectorArgs(room: UDormRoomSelectorArgs(dorm: UDormSelectorArgs())),
        ),
      )).$1?.result ??
      <UDormBedResponse>[];

  Future<List<UDormResponse>> searchDorms(String query) async => (await UServices.hotel.readDorms(p: UDormReadParams(title: query, pageSize: 100, pageNumber: 1))).$1?.result ?? <UDormResponse>[];

  void loadForm(UDormBedContractResponse? i) {
    editing = i;
    formBed = bed;
    formUser = null;
    type = (i == null ? null : typeOf(i)) ?? TagDormBedContract.monthly;
    contractStart = i?.startDate;
    contractEnd = i?.endDate;
    startText.text = i?.startDate.toJalaliDate() ?? "";
    endText.text = i?.endDate.toJalaliDate() ?? "";
    deposit.text = i?.deposit.toInt().toString() ?? "";
    rent.text = i?.rent.toInt().toString() ?? "";
    penalty.clear();
    description.text = i?.jsonData.detail1 ?? "";
  }

  /// Creates or updates the contract. Returns true when the dialog can close.
  Future<bool> save() async {
    // Daily contracts are single-invoice with no deposit; monthly ones keep rent + deposit.
    final bool isDaily = type == TagDormBedContract.daily;
    final List<int> tags = <int>[type.number, if (isDaily) TagDormBedContract.singleInvoice.number];
    if (editing != null) {
      return await submit(
            UServices.hotel.updateDormBedContract(
              p: UDormBedContractUpdateParams(id: editing!.id, tags: tags, startDate: contractStart, endDate: contractEnd, deposit: isDaily ? 0 : numOf(deposit), rent: numOf(rent)),
            ),
            read,
          ) !=
          null;
    }
    if (formBed == null) {
      UToast.error(message: U.s.selectAItem(U.s.bed));
      return false;
    }
    if (formUser == null) {
      UToast.error(message: U.s.selectAItem(U.s.user));
      return false;
    }
    return await submit(
          UServices.hotel.createDormBedContract(
            p: UDormBedContractCreateParams(
              tags: tags,
              startDate: contractStart!,
              endDate: contractEnd!,
              userId: formUser!.id,
              bedId: formBed!.id,
              deposit: isDaily ? null : numOf(deposit),
              rent: numOf(rent),
              penaltyPrecentEveryDate: isDaily ? null : intOf(penalty),
              detail1: description.text.nullIfEmpty(),
            ),
          ),
          read,
        ) !=
        null;
  }

  void delete(UDormBedContractResponse i) => confirmAction(() => UServices.hotel.deleteDormBedContract(p: UIdParams(id: i.id)), read);
}
