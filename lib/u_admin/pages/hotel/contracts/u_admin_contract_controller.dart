part of "../../../u_admin.dart";

enum UAdminContractStatusFilter { all, active, upcoming, expired, expiringSoon }

class UAdminContractController extends UBaseController {
  List<UDormBedContractResponse> list = <UDormBedContractResponse>[];

  UDormBedResponse? bed;

  UUserResponse? user;

  final TextEditingController tenantFilter = TextEditingController();
  int? typeFilter;
  UAdminContractStatusFilter statusFilter = UAdminContractStatusFilter.all;

  UDormResponse? dormFilter;
  UDormBedResponse? bedFilter;
  DateTime? startDateFilter;
  DateTime? endDateFilter;

  Future<void> init({UDormBedResponse? bed, UUserResponse? user}) async {
    this.bed = bed;
    this.user = user;
    await read();
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
        startDate: startDateFilter,
        endDate: endDateFilter,
        userName: tenantFilter.text.nullIfEmpty(),
        tags: typeFilter == null ? null : <int>[typeFilter!],
        activeOnly: statusFilter == UAdminContractStatusFilter.active ? true : null,
        upcomingOnly: statusFilter == UAdminContractStatusFilter.upcoming ? true : null,
        expiredOnly: statusFilter == UAdminContractStatusFilter.expired ? true : null,
        expiringWithinDays: statusFilter == UAdminContractStatusFilter.expiringSoon ? 30 : null,
        selectorArgs: const ContractSelectorArgs(
          user: UserSelectorArgs(),
          bed: DormBedSelectorArgs(room: DormRoomSelectorArgs(dorm: DormSelectorArgs())),
          invoice: InvoiceSelectorArgs(),
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
    typeFilter = null;
    dormFilter = null;
    bedFilter = null;
    startDateFilter = null;
    endDateFilter = null;
    statusFilter = UAdminContractStatusFilter.all;
    reloadFirstPage(read);
  }

  void setStatus(UAdminContractStatusFilter f) {
    statusFilter = f;
    reloadFirstPage(read);
  }

  void create({required UDormBedContractCreateParams p}) => UServices.hotel.createDormBedContract(
    p: p,
    onOk: (UResponse<String> r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UDormBedContractUpdateParams p}) => UServices.hotel.updateDormBedContract(
    p: p,
    onOk: (UResponse<UDormBedContractResponse> r) => okCallback(r.message, read),
    onError: (UResponse<dynamic> r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void delete(UDormBedContractResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.deleteDormBedContract(
      p: UIdParams(id: i.id),
      onOk: (UResponse<dynamic> r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UResponse<dynamic> r) {
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
    );
    return result;
  }

  Future<List<UDormBedResponse>> readBeds(String query) async {
    final List<UDormBedResponse> result = <UDormBedResponse>[];
    await UServices.hotel.readDormBeds(
      p: UDormBedReadParams(
        title: query,
        dormId: dormFilter?.id,
        pageSize: 100,
        pageNumber: 1,
        selectorArgs: const DormBedSelectorArgs(room: DormRoomSelectorArgs(dorm: DormSelectorArgs())),
      ),
      onOk: (UResponse<List<UDormBedResponse>> r) => result.addAll(r.result ?? <UDormBedResponse>[]),
    );
    return result;
  }

  Future<List<UDormResponse>> readDorms(String query) async {
    final List<UDormResponse> result = <UDormResponse>[];
    await UServices.hotel.readDorms(
      p: UDormReadParams(title: query, pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UDormResponse>> r) => result.addAll(r.result ?? <UDormResponse>[]),
    );
    return result;
  }
}
