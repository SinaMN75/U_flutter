part of "../../u_admin.dart";

class UAdminFinancialOpsDashboardController extends UBaseController {
  final URxn<UFinancialOpsDashboardResponse> report = URxn<UFinancialOpsDashboardResponse>();

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.dashboard.readFinancialOpsDashboard(
      p: UDashboardRangeParams(fromDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)), toDate: endDate ?? DateTime.now()),
      onOk: (UResponse<UFinancialOpsDashboardResponse> r) {
        report.value = r.result;
        state.loaded();
      },
      onError: (_) => state.error(),
      onException: (String e) => state.error(),
    );
  }
}
