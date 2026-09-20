part of "../data.dart";

class InquiryService {
  Future<(UResponse<UBillInfoResponse>?, UEmptyResponse?, String?)> billInfo({
    required UBillInfoParams p,
    Function(UResponse<UBillInfoResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/BillInfo", p.toMap(), _Api.one(UBillInfoResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UZipCodeToAddressDetailResponse>?, UEmptyResponse?, String?)> zipCodeToAddressDetail({
    required UZipCodeToAddressDetailParams p,
    Function(UResponse<UZipCodeToAddressDetailResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/ZipCodeToAddressDetail", p.toMap(), _Api.one(UZipCodeToAddressDetailResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UVehicleViolationDetailResponse>?, UEmptyResponse?, String?)> vehicleViolationDetail({
    required UVehicleViolationDetailParams p,
    Function(UResponse<UVehicleViolationDetailResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/VehicleViolationDetail", p.toMap(), _Api.one(UVehicleViolationDetailResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDrivingLicenceDetailResponse>?, UEmptyResponse?, String?)> drivingLicenceDetail({
    required UDrivingLicenceDetailParams p,
    Function(UResponse<UDrivingLicenceDetailResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/DrivingLicenceDetail", p.toMap(), _Api.one(UDrivingLicenceDetailResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULicencePlateDetailResponse>?, UEmptyResponse?, String?)> licencePlateDetail({
    required ULicencePlateDetailParams p,
    Function(UResponse<ULicencePlateDetailResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/LicencePlateDetail", p.toMap(), _Api.one(ULicencePlateDetailResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UDrivingLicenceNegativePointResponse>?, UEmptyResponse?, String?)> drivingLicenceNegativePoint({
    required UDrivingLicenceNegativePointParams p,
    Function(UResponse<UDrivingLicenceNegativePointResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/DrivingLicenceNegativePoint", p.toMap(), _Api.one(UDrivingLicenceNegativePointResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UFreewayTollsResponse>?, UEmptyResponse?, String?)> freewayTolls({
    required UFreewayTollsParams p,
    Function(UResponse<UFreewayTollsResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/FreewayTolls", p.toMap(), _Api.one(UFreewayTollsResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UInquiryCacheStatusResponse>?, UEmptyResponse?, String?)> cacheStatus({
    required UInquiryCacheStatusParams p,
    Function(UResponse<UInquiryCacheStatusResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/CacheStatus", p.toMap(), _Api.one(UInquiryCacheStatusResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UIBanToBankAccountDetailResponse>?, UEmptyResponse?, String?)> iBanToBankAccountDetail({
    required UIBanToBankAccountDetailParams p,
    Function(UResponse<UIBanToBankAccountDetailResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/inquiry/IBanToBankAccountDetail", p.toMap(), _Api.one(UIBanToBankAccountDetailResponse.fromMap), _Api.empty, onOk, onError, onException);
}
