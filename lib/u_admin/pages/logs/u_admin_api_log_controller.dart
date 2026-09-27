part of "../../u_admin.dart";

class UAdminApiLogController extends UBaseController {
  UAdminApiLogController() {
    pageSize = 25;
  }

  final URxList<UApiLogResponse> list = <UApiLogResponse>[].obs;
  final URxn<UApiLogStatsResponse> stats = URxn<UApiLogStatsResponse>();
  final URx<String> bucket = "hour".obs;

  final URxn<UOsMetricsResponse> osMetrics = URxn<UOsMetricsResponse>();
  final URxState statsState = URxState();
  final URxState osMetricsState = URxState();
  Timer? _osMetricsTimer;

  final TextEditingController pathContainsController = TextEditingController();
  final TextEditingController statusCodeController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController ipAddressController = TextEditingController();
  final TextEditingController traceIdController = TextEditingController();
  final TextEditingController minDurationController = TextEditingController();
  final TextEditingController maxDurationController = TextEditingController();
  final URxn<TagApiLog> methodFilter = URxn<TagApiLog>();
  final URxBool onlyErrors = false.obs;
  final URxBool onlyExceptions = false.obs;

  Future<void> init() async {
    tagOrderBy(TagOrderBy.createdAtDescending);
    startOsMetricsPolling();
    await read();
  }

  Future<void> read() async {
    await Future.wait<void>(<Future<void>>[search(), readStats()]);
  }

  void startOsMetricsPolling() {
    readOsMetrics();
    _osMetricsTimer = Timer.periodic(const Duration(seconds: 15), (_) => readOsMetrics());
  }

  Future<void> readOsMetrics() async {
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

  @override
  void dispose() {
    statsState.dispose();
    pathContainsController.dispose();
    statusCodeController.dispose();
    userIdController.dispose();
    ipAddressController.dispose();
    traceIdController.dispose();
    minDurationController.dispose();
    maxDurationController.dispose();
    _osMetricsTimer?.cancel();
    super.dispose();
  }

  List<int>? _buildTags() {
    final List<int> tags = <int>[];
    if (methodFilter.value != null) tags.add(methodFilter.value!.number);
    if (onlyExceptions.value) tags.add(TagApiLog.hasException.number);
    return tags.isEmpty ? null : tags;
  }

  UApiLogReadParams _buildSearchParams() => UApiLogReadParams(
    pageSize: pageSize,
    pageNumber: pageNumber.value,
    fromCreatedAt: startDate,
    toCreatedAt: endDate,
    tags: _buildTags(),
    pathContains: pathContainsController.text.nullIfEmpty(),
    statusCode: int.tryParse(statusCodeController.text),
    minDurationMs: int.tryParse(minDurationController.text),
    maxDurationMs: int.tryParse(maxDurationController.text),
    userId: userIdController.text.nullIfEmpty(),
    ipAddress: ipAddressController.text.nullIfEmpty(),
    onlyErrors: onlyErrors.value ? true : null,
    orderBy: tagOrderBy.value.number,
  );

  Future<void> search() async {
    state.loading();
    await UServices.dashboard.readApiLogs(
      p: _buildSearchParams(),
      onOk: (UResponse<List<UApiLogResponse>> r) {
        list(r.result ?? <UApiLogResponse>[]);
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  Future<void> readStats() async {
    statsState.loading();
    await UServices.dashboard.apiLogStats(
      p: UApiLogStatsParams(fromCreatedAt: startDate, toCreatedAt: endDate, bucket: bucket.value),
      onOk: (UResponse<UApiLogStatsResponse> r) {
        stats.value = r.result;
        statsState.loaded();
      },
      onError: (UEmptyResponse e) => statsState.error(),
      onException: (String e) => statsState.error(),
    );
  }

  void refreshList() {
    pageNumber(1);
    search();
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    pathContainsController.clear();
    statusCodeController.clear();
    userIdController.clear();
    ipAddressController.clear();
    traceIdController.clear();
    minDurationController.clear();
    maxDurationController.clear();
    methodFilter(null);
    onlyErrors(false);
    onlyExceptions(false);
    tagOrderBy(TagOrderBy.createdAtDescending);
    startDate = null;
    endDate = null;
    applyFilters();
  }

  void setBucket(String b) {
    bucket(b);
    readStats();
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

  final URxList<String> appLogs = <String>[].obs;
  final URxState appLogsState = URxState();

  Future<void> readAppLogs() async {
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
