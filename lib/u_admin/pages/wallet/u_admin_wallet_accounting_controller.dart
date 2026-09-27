part of "../../u_admin.dart";

class UAdminWalletAccountingController extends UAdminBaseController {
  final URxn<UAccountingReportResponse> report = URxn<UAccountingReportResponse>();
  final URxn<UUserResponse> user = URxn<UUserResponse>();

  Future<void> init() => read();

  Future<void> read() async {
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

  void clearFilters() {
    user.value = null;
    clearDates();
    read();
  }

  @override
  void dispose() {
    report.dispose();
    user.dispose();
    super.dispose();
  }
}
