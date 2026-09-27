part of "../../u_admin.dart";

class UAdminAccountingController extends UBaseController {
  final URxn<UAccountingReportResponse> report = URxn<UAccountingReportResponse>();
  final URxn<UUserResponse> user = URxn<UUserResponse>();

  Future<void> init() => load();

  Future<void> load() async {
    state.loading();
    await UServices.accounting.report(
      p: UAccountingReportParams(userId: user.value?.id, fromDate: startDate, toDate: endDate),
      onOk: (UResponse<UAccountingReportResponse> r) {
        report.value = r.result;
        state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void clear() {
    user.value = null;
    clearDates();
    load();
  }

  @override
  void dispose() {
    report.dispose();
    user.dispose();
    super.dispose();
  }
}
