part of "../../u_admin.dart";

class UAdminFinancialOpsDashboardController extends UBaseController {
  final Rxn<UFinancialOpsDashboardResponse> report = Rxn<UFinancialOpsDashboardResponse>();

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();

  Future<void> init() => load();

  Future<void> load() async {
    state.loading();
    await UServices.dashboard.readFinancialOpsDashboard(
      p: UDashboardRangeParams(fromDate: fromDate, toDate: toDate),
      onOk: (UResponse<UFinancialOpsDashboardResponse> r) {
        report.value = r.result;
        state.loaded();
      },
      onError: (_) => state.error(),
      onException: (String e) => state.error(),
    );
  }

  Future<void> setRange(DateTime from, DateTime to) async {
    fromDate = from;
    toDate = to;
    await load();
  }
}
