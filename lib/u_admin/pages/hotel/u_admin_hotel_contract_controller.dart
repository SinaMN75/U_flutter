part of "../../u_admin.dart";

enum UAdminHotelContractStatusFilter { all, active, upcoming, expired, expiringSoon }

class UAdminHotelContractController extends UAdminBaseController {
  List<UDormBedContractResponse> list = <UDormBedContractResponse>[];
  UDormBedResponse? bed;
  UUserResponse? user;

  /// Only two contract kinds exist: monthly (rent + deposit) and daily (one invoice, no deposit).
  static const List<TagDormBedContract> types = <TagDormBedContract>[TagDormBedContract.monthly, TagDormBedContract.daily];

  final TextEditingController tenantFilterController = TextEditingController();
  int? typeFilter;
  UAdminHotelContractStatusFilter statusFilter = UAdminHotelContractStatusFilter.all;
  UDormResponse? dormFilter;
  UDormBedResponse? bedFilter;

  // ---------------------------------------------------------------- form (create and edit)

  UDormBedContractResponse? editing;
  UDormBedResponse? formBed;
  UUserResponse? formUser;
  TagDormBedContract type = TagDormBedContract.monthly;
  DateTime? contractStart;
  DateTime? contractEnd;
  final TextEditingController contractStartController = TextEditingController();
  final TextEditingController contractEndController = TextEditingController();
  final TextEditingController depositController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController penaltyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

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
        userName: tenantFilterController.valueOrNull(),
        tags: typeFilter == null ? null : <int>[typeFilter!],
        activeOnly: statusFilter == UAdminHotelContractStatusFilter.active ? true : null,
        upcomingOnly: statusFilter == UAdminHotelContractStatusFilter.upcoming ? true : null,
        expiredOnly: statusFilter == UAdminHotelContractStatusFilter.expired ? true : null,
        expiringWithinDays: statusFilter == UAdminHotelContractStatusFilter.expiringSoon ? 30 : null,
        selectorArgs: const UDormBedContractSelectorArgs(
          user: UUserSelectorArgs(),
          bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs(dorm: UDormSelectorArgs())),
          invoice: UDormBedInvoiceSelectorArgs(),
        ),
      ),
      onOk: (UResponse<List<UDormBedContractResponse>> r) {
        list = r.result ?? <UDormBedContractResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UResponse<dynamic> e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    tenantFilterController.clear();
    clearDates();
    typeFilter = null;
    dormFilter = null;
    bedFilter = null;
    statusFilter = UAdminHotelContractStatusFilter.all;
    pageNumber(1);
    read();
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
    contractStartController.text = i?.startDate.toJalaliDate() ?? "";
    contractEndController.text = i?.endDate.toJalaliDate() ?? "";
    depositController.text = i?.deposit.toInt().toString() ?? "";
    rentController.text = i?.rent.toInt().toString() ?? "";
    penaltyController.clear();
    descriptionController.text = i?.jsonData.detail1 ?? "";
  }

  /// Creates or updates the contract. Returns true when the dialog can close.
  Future<bool> save() async {
    // Daily contracts are single-invoice with no deposit; monthly ones keep rent + deposit.
    final bool isDaily = type == TagDormBedContract.daily;
    final List<int> tags = <int>[type.number, if (isDaily) TagDormBedContract.singleInvoice.number];
    if (editing != null) {
      return await submit(
            UServices.hotel.updateDormBedContract(
              p: UDormBedContractUpdateParams(id: editing!.id, tags: tags, startDate: contractStart, endDate: contractEnd, deposit: isDaily ? 0 : numOf(depositController), rent: numOf(rentController)),
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
              deposit: isDaily ? null : numOf(depositController),
              rent: numOf(rentController),
              penaltyPrecentEveryDate: isDaily ? null : intOf(penaltyController),
              detail1: descriptionController.text.nullIfEmpty(),
            ),
          ),
          read,
        ) !=
        null;
  }

  void delete(UDormBedContractResponse i) => confirmAction(() => UServices.hotel.deleteDormBedContract(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    tenantFilterController.dispose();
    contractStartController.dispose();
    contractEndController.dispose();
    depositController.dispose();
    rentController.dispose();
    penaltyController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
