part of "../data.dart";

class InquiryService {
  Future<(UResponse<UBillInfoResponse>?, UEmptyResponse?, String?)> billInfo({
    required final UBillInfoParams p,
    final Function(UResponse<UBillInfoResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UBillInfoResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/BillInfo",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UBillInfoResponse> ok = UResponse<UBillInfoResponse>.fromJson(r.body, (final dynamic i) => UBillInfoResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UZipCodeToAddressDetailResponse>?, UEmptyResponse?, String?)> zipCodeToAddressDetail({
    required final UZipCodeToAddressDetailParams p,
    final Function(UResponse<UZipCodeToAddressDetailResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UZipCodeToAddressDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/ZipCodeToAddressDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UZipCodeToAddressDetailResponse> ok = UResponse<UZipCodeToAddressDetailResponse>.fromJson(r.body, (final dynamic i) => UZipCodeToAddressDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UVehicleViolationDetailResponse>?, UEmptyResponse?, String?)> vehicleViolationDetail({
    required final UVehicleViolationDetailParams p,
    final Function(UResponse<UVehicleViolationDetailResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UVehicleViolationDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/VehicleViolationDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UVehicleViolationDetailResponse> ok = UResponse<UVehicleViolationDetailResponse>.fromJson(r.body, (final dynamic i) => UVehicleViolationDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UDrivingLicenceDetailResponse>?, UEmptyResponse?, String?)> drivingLicenceDetail({
    required final UDrivingLicenceDetailParams p,
    final Function(UResponse<UDrivingLicenceDetailResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UDrivingLicenceDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/DrivingLicenceDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UDrivingLicenceDetailResponse> ok = UResponse<UDrivingLicenceDetailResponse>.fromJson(r.body, (final dynamic i) => UDrivingLicenceDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<ULicencePlateDetailResponse>?, UEmptyResponse?, String?)> licencePlateDetail({
    required final ULicencePlateDetailParams p,
    final Function(UResponse<ULicencePlateDetailResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<ULicencePlateDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/LicencePlateDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<ULicencePlateDetailResponse> ok = UResponse<ULicencePlateDetailResponse>.fromJson(r.body, (final dynamic i) => ULicencePlateDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UDrivingLicenceNegativePointResponse>?, UEmptyResponse?, String?)> drivingLicenceNegativePoint({
    required final UDrivingLicenceNegativePointParams p,
    final Function(UResponse<UDrivingLicenceNegativePointResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UDrivingLicenceNegativePointResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/DrivingLicenceNegativePoint",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UDrivingLicenceNegativePointResponse> ok = UResponse<UDrivingLicenceNegativePointResponse>.fromJson(
          r.body,
          (final dynamic i) => UDrivingLicenceNegativePointResponse.fromMap(i),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UFreewayTollsResponse>?, UEmptyResponse?, String?)> freewayTolls({
    required final UFreewayTollsParams p,
    final Function(UResponse<UFreewayTollsResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UFreewayTollsResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/FreewayTolls",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UFreewayTollsResponse> ok = UResponse<UFreewayTollsResponse>.fromJson(r.body, (final dynamic i) => UFreewayTollsResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UInquiryCacheStatusResponse>?, UEmptyResponse?, String?)> cacheStatus({
    required final UInquiryCacheStatusParams p,
    final Function(UResponse<UInquiryCacheStatusResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UInquiryCacheStatusResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/CacheStatus",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UInquiryCacheStatusResponse> ok = UResponse<UInquiryCacheStatusResponse>.fromJson(r.body, (final dynamic i) => UInquiryCacheStatusResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UIBanToBankAccountDetailResponse>?, UEmptyResponse?, String?)> iBanToBankAccountDetail({
    required final UIBanToBankAccountDetailParams p,
    final Function(UResponse<UIBanToBankAccountDetailResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UIBanToBankAccountDetailResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/inquiry/IBanToBankAccountDetail",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UIBanToBankAccountDetailResponse> ok = UResponse<UIBanToBankAccountDetailResponse>.fromJson(r.body, (final dynamic i) => UIBanToBankAccountDetailResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }
}
