part of "../../../u_admin.dart";

class UAdminHotelDashboardController extends UBaseController {
  final URxn<UPropertyDashboardResponse> report = URxn<UPropertyDashboardResponse>();

  Future<void> init() => load();

  Future<void> load() async {
    state.loading();
    await UServices.dashboard.readPropertyDashboard(
      p: UDashboardRangeParams(),
      onOk: (UResponse<UPropertyDashboardResponse> r) {
        report.value = r.result;
        state.loaded();
      },
      onError: (_) => state.error(),
      onException: (String e) => state.error(),
    );
  }
}
