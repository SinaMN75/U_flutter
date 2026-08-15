part of "../data.dart";

class InquiryService {
  Future<(UResponse<UBillInfoResponse>?, UEmptyResponse?, String?)> billInfo({
    required UBillInfoParams p,
    required Function(UResponse<UBillInfoResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UBillInfoResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/BillInfo",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UBillInfoResponse> ok = UResponse<UBillInfoResponse>.fromJson(r.body, (dynamic i) => UBillInfoResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UZipCodeToAddressDetailResponse>?, UEmptyResponse?, String?)> zipCodeToAddressDetail({
    required UZipCodeToAddressDetailParams p,
    required Function(UResponse<UZipCodeToAddressDetailResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UZipCodeToAddressDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/ZipCodeToAddressDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UZipCodeToAddressDetailResponse> ok = UResponse<UZipCodeToAddressDetailResponse>.fromJson(r.body, (dynamic i) => UZipCodeToAddressDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UVehicleViolationDetailResponse>?, UEmptyResponse?, String?)> vehicleViolationDetail({
    required UVehicleViolationDetailParams p,
    required Function(UResponse<UVehicleViolationDetailResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UVehicleViolationDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/VehicleViolationDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UVehicleViolationDetailResponse> ok = UResponse<UVehicleViolationDetailResponse>.fromJson(r.body, (dynamic i) => UVehicleViolationDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UDrivingLicenceDetailResponse>?, UEmptyResponse?, String?)> drivingLicenceDetail({
    required UDrivingLicenceDetailParams p,
    required Function(UResponse<UDrivingLicenceDetailResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UDrivingLicenceDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/DrivingLicenceDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDrivingLicenceDetailResponse> ok = UResponse<UDrivingLicenceDetailResponse>.fromJson(r.body, (dynamic i) => UDrivingLicenceDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<ULicencePlateDetailResponse>?, UEmptyResponse?, String?)> licencePlateDetail({
    required ULicencePlateDetailParams p,
    required Function(UResponse<ULicencePlateDetailResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<ULicencePlateDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/LicencePlateDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<ULicencePlateDetailResponse> ok = UResponse<ULicencePlateDetailResponse>.fromJson(r.body, (dynamic i) => ULicencePlateDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UDrivingLicenceNegativePointResponse>?, UEmptyResponse?, String?)> drivingLicenceNegativePoint({
    required UDrivingLicenceNegativePointParams p,
    required Function(UResponse<UDrivingLicenceNegativePointResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UDrivingLicenceNegativePointResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/DrivingLicenceNegativePoint",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDrivingLicenceNegativePointResponse> ok = UResponse<UDrivingLicenceNegativePointResponse>.fromJson(
          r.body,
          (dynamic i) => UDrivingLicenceNegativePointResponse.fromMap(i),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UFreewayTollsResponse>?, UEmptyResponse?, String?)> freewayTolls({
    required UFreewayTollsParams p,
    required Function(UResponse<UFreewayTollsResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UFreewayTollsResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/FreewayTolls",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UFreewayTollsResponse> ok = UResponse<UFreewayTollsResponse>.fromJson(r.body, (dynamic i) => UFreewayTollsResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UInquiryCacheStatusResponse>?, UEmptyResponse?, String?)> cacheStatus({
    required UInquiryCacheStatusParams p,
    required Function(UResponse<UInquiryCacheStatusResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UInquiryCacheStatusResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/CacheStatus",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UInquiryCacheStatusResponse> ok = UResponse<UInquiryCacheStatusResponse>.fromJson(r.body, (dynamic i) => UInquiryCacheStatusResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UIBanToBankAccountDetailResponse>?, UEmptyResponse?, String?)> iBanToBankAccountDetail({
    required UIBanToBankAccountDetailParams p,
    required Function(UResponse<UIBanToBankAccountDetailResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UIBanToBankAccountDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/IBanToBankAccountDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UIBanToBankAccountDetailResponse> ok = UResponse<UIBanToBankAccountDetailResponse>.fromJson(r.body, (dynamic i) => UIBanToBankAccountDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }
}
