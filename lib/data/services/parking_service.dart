part of "../data.dart";

class ParkingService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createParking({
    required UParkingCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CreateParking", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UParkingResponse>>?, UEmptyResponse?, String?)> readParking({
    required UParkingReadParams p,
    Function(UResponse<List<UParkingResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParking", p.toMap(), _Api.list(UParkingResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateParking({
    required UParkingUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/UpdateParking", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteParking({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/DeleteParking", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createParkingReport({
    required UParkingReportCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CreateParkingReport", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UParkingReportResponse>>?, UEmptyResponse?, String?)> readParkingReport({
    required UParkingReportReadParams p,
    Function(UResponse<List<UParkingReportResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingReport", p.toMap(), _Api.list(UParkingReportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateParkingReport({
    required UParkingReportUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/UpdateParkingReport", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteParkingReport({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/DeleteParkingReport", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createParkingUser({
    required UParkingUserCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CreateParkingUser", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UUserResponse>>?, UEmptyResponse?, String?)> readParkingUsers({
    required UParkingUserReadParams p,
    Function(UResponse<List<UUserResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingUsers", p.toMap(), _Api.list(UUserResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> removeParkingUser({
    required UParkingUserDeleteParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/RemoveParkingUser", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createParkingTariff({
    required UParkingTariffCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CreateParkingTariff", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UParkingTariffResponse>>?, UEmptyResponse?, String?)> readParkingTariff({
    required UParkingTariffReadParams p,
    Function(UResponse<List<UParkingTariffResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingTariff", p.toMap(), _Api.list(UParkingTariffResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateParkingTariff({
    required UParkingTariffUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/UpdateParkingTariff", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteParkingTariff({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/DeleteParkingTariff", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createParkingSubscription({
    required UParkingSubscriptionCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CreateParkingSubscription", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UParkingSubscriptionResponse>>?, UEmptyResponse?, String?)> readParkingSubscription({
    required UParkingSubscriptionReadParams p,
    Function(UResponse<List<UParkingSubscriptionResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingSubscription", p.toMap(), _Api.list(UParkingSubscriptionResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateParkingSubscription({
    required UParkingSubscriptionUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/UpdateParkingSubscription", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteParkingSubscription({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/DeleteParkingSubscription", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createParkingPlateFlag({
    required UParkingPlateFlagCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CreateParkingPlateFlag", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UParkingPlateFlagResponse>>?, UEmptyResponse?, String?)> readParkingPlateFlag({
    required UParkingPlateFlagReadParams p,
    Function(UResponse<List<UParkingPlateFlagResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingPlateFlag", p.toMap(), _Api.list(UParkingPlateFlagResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateParkingPlateFlag({
    required UParkingPlateFlagUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/UpdateParkingPlateFlag", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteParkingPlateFlag({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/DeleteParkingPlateFlag", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createParkingStaff({
    required UParkingStaffCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CreateParkingStaff", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UParkingStaffResponse>>?, UEmptyResponse?, String?)> readParkingStaff({
    required UParkingStaffReadParams p,
    Function(UResponse<List<UParkingStaffResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingStaff", p.toMap(), _Api.list(UParkingStaffResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateParkingStaff({
    required UParkingStaffUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/UpdateParkingStaff", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteParkingStaff({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/DeleteParkingStaff", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UParkingShiftResponse>?, UEmptyResponse?, String?)> openParkingShift({
    required UParkingShiftOpenParams p,
    Function(UResponse<UParkingShiftResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/OpenParkingShift", p.toMap(), _Api.one(UParkingShiftResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UParkingShiftResponse>>?, UEmptyResponse?, String?)> readParkingShift({
    required UParkingShiftReadParams p,
    Function(UResponse<List<UParkingShiftResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingShift", p.toMap(), _Api.list(UParkingShiftResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UParkingShiftResponse>?, UEmptyResponse?, String?)> closeParkingShift({
    required UParkingShiftCloseParams p,
    Function(UResponse<UParkingShiftResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CloseParkingShift", p.toMap(), _Api.one(UParkingShiftResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UParkingPlateStatusResponse>?, UEmptyResponse?, String?)> readParkingPlateStatus({
    required UParkingPlateStatusParams p,
    Function(UResponse<UParkingPlateStatusResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingPlateStatus", p.toMap(), _Api.one(UParkingPlateStatusResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UParkingReportResponse>?, UEmptyResponse?, String?)> registerParkingEntry({
    required UParkingEntryParams p,
    Function(UResponse<UParkingReportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/RegisterParkingEntry", p.toMap(), _Api.one(UParkingReportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UParkingBillResponse>?, UEmptyResponse?, String?)> calculateParkingExit({
    required UParkingExitCalculateParams p,
    Function(UResponse<UParkingBillResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/CalculateParkingExit", p.toMap(), _Api.one(UParkingBillResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UParkingReportResponse>?, UEmptyResponse?, String?)> registerParkingExit({
    required UParkingExitParams p,
    Function(UResponse<UParkingReportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/RegisterParkingExit", p.toMap(), _Api.one(UParkingReportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UParkingDashboardResponse>?, UEmptyResponse?, String?)> readParkingDashboard({
    required UParkingDashboardParams p,
    Function(UResponse<UParkingDashboardResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingDashboard", p.toMap(), _Api.one(UParkingDashboardResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UParkingInsideVehicleResponse>>?, UEmptyResponse?, String?)> readParkingInsideVehicles({
    required UParkingInsideVehiclesParams p,
    Function(UResponse<List<UParkingInsideVehicleResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/parking/ReadParkingInsideVehicles", p.toMap(), _Api.list(UParkingInsideVehicleResponse.fromMap), _Api.empty, onOk, onError, onException);
}
