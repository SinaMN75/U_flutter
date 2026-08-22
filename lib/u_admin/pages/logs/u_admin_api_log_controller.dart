part of "../../u_admin.dart";

class UAdminApiLogController extends UBaseController {
  UAdminApiLogController() {
    pageSize = 25;
  }

  final RxList<UApiLogResponse> list = <UApiLogResponse>[].obs;
  final Rxn<UApiLogStatsResponse> stats = Rxn<UApiLogStatsResponse>();
  final Rx<String> bucket = "hour".obs;

  final Rxn<UOsMetricsResponse> osMetrics = Rxn<UOsMetricsResponse>();
  final RxState osMetricsState = RxState();
  Timer? _osMetricsTimer;

  final TextEditingController pathContainsCtrl = TextEditingController();
  final TextEditingController statusCodeCtrl = TextEditingController();
  final TextEditingController userIdCtrl = TextEditingController();
  final TextEditingController ipAddressCtrl = TextEditingController();
  final TextEditingController traceIdCtrl = TextEditingController();
  final TextEditingController minDurationCtrl = TextEditingController();
  final TextEditingController maxDurationCtrl = TextEditingController();
  final Rxn<TagApiLog> methodFilter = Rxn<TagApiLog>();
  final RxBool onlyErrors = false.obs;
  final RxBool onlyExceptions = false.obs;
  final Rx<TagOrderBy> orderBy = TagOrderBy.createdAtDescending.obs;

  Future<void> init() async {
    startOsMetricsPolling();
    await refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait<void>(<Future<void>>[search(), loadStats()]);
  }

  void startOsMetricsPolling() {
    loadOsMetrics();
    _osMetricsTimer = Timer.periodic(const Duration(seconds: 15), (_) => loadOsMetrics());
  }

  Future<void> loadOsMetrics() async {
    if (osMetrics.value == null) osMetricsState.loading();
    await UServices.dashboard.readOsMetrics(
      onOk: (UResponse<UOsMetricsResponse> r) {
        osMetrics.value = r.result;
        osMetricsState.loaded();
      },
      onError: (UEmptyResponse e) => osMetricsState.error(),
      onException: (String e) => osMetricsState.error(),
    );
  }

  void dispose() => _osMetricsTimer?.cancel();

  List<int>? _buildTags() {
    final List<int> tags = <int>[];
    if (methodFilter.value != null) tags.add(methodFilter.value!.number);
    if (onlyExceptions.value) tags.add(TagApiLog.hasException.number);
    return tags.isEmpty ? null : tags;
  }

  UApiLogReadParams _buildSearchParams() => UApiLogReadParams(
    pageSize: pageSize,
    pageNumber: pageNumber.value,
    fromCreatedAt: fromCreatedAt,
    toCreatedAt: toCreatedAt,
    tags: _buildTags(),
    pathContains: pathContainsCtrl.text.nullIfEmpty(),
    statusCode: int.tryParse(statusCodeCtrl.text),
    minDurationMs: int.tryParse(minDurationCtrl.text),
    maxDurationMs: int.tryParse(maxDurationCtrl.text),
    userId: userIdCtrl.text.nullIfEmpty(),
    ipAddress: ipAddressCtrl.text.nullIfEmpty(),
    onlyErrors: onlyErrors.value ? true : null,
    orderBy: orderBy.value.number,
  );

  Future<void> search() async {
    state.loading();
    await UServices.dashboard.readApiLogs(
      p: _buildSearchParams(),
      onOk: (UResponse<List<UApiLogResponse>> r) {
        list(r.result ?? <UApiLogResponse>[]);
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  Future<void> loadStats() async {
    state2.loading();
    await UServices.dashboard.apiLogStats(
      p: UApiLogStatsParams(fromCreatedAt: fromCreatedAt, toCreatedAt: toCreatedAt, bucket: bucket.value),
      onOk: (UResponse<UApiLogStatsResponse> r) {
        stats.value = r.result;
        state2.loaded();
      },
      onError: (UEmptyResponse e) => state2.error(),
      onException: (String e) => state2.error(),
    );
  }

  void refreshList() {
    firstPage();
    search();
  }

  void applyFilters() {
    firstPage();
    refreshAll();
  }

  void clearFilters() {
    pathContainsCtrl.clear();
    statusCodeCtrl.clear();
    userIdCtrl.clear();
    ipAddressCtrl.clear();
    traceIdCtrl.clear();
    minDurationCtrl.clear();
    maxDurationCtrl.clear();
    methodFilter(null);
    onlyErrors(false);
    onlyExceptions(false);
    orderBy(TagOrderBy.createdAtDescending);
    fromCreatedAt = null;
    toCreatedAt = null;
    applyFilters();
  }

  void setBucket(String b) {
    bucket(b);
    loadStats();
  }

  void openDetail(UApiLogResponse item, Function(UApiLogResponse detail) onOk) {
    ULoading.show();
    UServices.dashboard.readApiLogs(
      p: UApiLogReadParams(ids: <String>[item.id], pageSize: 1),
      onOk: (UResponse<List<UApiLogResponse>> r) {
        ULoading.dismiss();
        if (r.result != null && r.result!.isNotEmpty) onOk(r.result!.first);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        UToast.error(message: e.message);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void exportCsv(Function(String csv) onOk) {
    ULoading.show();
    UServices.dashboard.exportApiLogs(
      p: _buildSearchParams(),
      onOk: (String csv) {
        ULoading.dismiss();
        onOk(csv);
      },
      onError: () {
        ULoading.dismiss();
        UToast.error(message: U.s.errorReadingData);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  final RxList<String> appLogs = <String>[].obs;
  final RxState appLogsState = RxState();

  Future<void> loadAppLogs() async {
    appLogsState.loading();
    await UServices.dashboard.readAppLogs(
      onOk: (List<String> r) {
        appLogs(r);
        appLogsState.loaded();
      },
      onError: (UEmptyResponse e) => appLogsState.error(),
      onException: (String e) => appLogsState.error(),
    );
  }

  void clearAppLogs() {
    ULoading.show();
    UServices.dashboard.clearAppLogs(
      onOk: () {
        ULoading.dismiss();
        appLogs(<String>[]);
        UToast.snackBar(message: U.s.done);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        UToast.error(message: e.message);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }
}
