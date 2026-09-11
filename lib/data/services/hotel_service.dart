part of "../data.dart";

class HotelService {
  // ==================== Hotel ====================

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createHotel({
    required UHotelCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Hotel/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UHotelResponse>>?, UEmptyResponse?, String?)> readHotels({
    required UHotelReadParams p,
    Function(UResponse<List<UHotelResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UHotelResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Hotel/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UHotelResponse>> ok = UResponse<List<UHotelResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UHotelResponse>.from((i as List<dynamic>).map((dynamic x) => UHotelResponse.fromMap(x))),
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

  Future<(UResponse<UHotelResponse>?, UEmptyResponse?, String?)> readHotelById({
    required UIdParams p,
    Function(UResponse<UHotelResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UHotelResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Hotel/ReadById",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UHotelResponse> ok = UResponse<UHotelResponse>.fromJson(r.body, (dynamic i) => UHotelResponse.fromMap(i));
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateHotel({
    required UHotelUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Hotel/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteHotel({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Hotel/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  // ==================== HotelRoom ====================

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createHotelRoom({
    required UHotelRoomCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelRoom/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UHotelRoomResponse>>?, UEmptyResponse?, String?)> readHotelRooms({
    required UHotelRoomReadParams p,
    Function(UResponse<List<UHotelRoomResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UHotelRoomResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelRoom/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UHotelRoomResponse>> ok = UResponse<List<UHotelRoomResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UHotelRoomResponse>.from((i as List<dynamic>).map((dynamic x) => UHotelRoomResponse.fromMap(x))),
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

  Future<(UResponse<UHotelRoomResponse>?, UEmptyResponse?, String?)> readHotelRoomById({
    required UIdParams p,
    Function(UResponse<UHotelRoomResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UHotelRoomResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelRoom/ReadById",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UHotelRoomResponse> ok = UResponse<UHotelRoomResponse>.fromJson(r.body, (dynamic i) => UHotelRoomResponse.fromMap(i));
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateHotelRoom({
    required UHotelRoomUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelRoom/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteHotelRoom({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelRoom/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  // ==================== Dorm ====================

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDorm({
    required UDormCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Dorm/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UDormResponse>>?, UEmptyResponse?, String?)> readDorms({
    required UDormReadParams p,
    Function(UResponse<List<UDormResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UDormResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Dorm/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UDormResponse>> ok = UResponse<List<UDormResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UDormResponse>.from((i as List<dynamic>).map((dynamic x) => UDormResponse.fromMap(x))),
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

  Future<(UResponse<UDormResponse>?, UEmptyResponse?, String?)> readDormById({
    required UIdParams p,
    Function(UResponse<UDormResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UDormResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Dorm/ReadById",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDormResponse> ok = UResponse<UDormResponse>.fromJson(r.body, (dynamic i) => UDormResponse.fromMap(i));
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDorm({
    required UDormUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Dorm/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDorm({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/Dorm/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  // ==================== DormRoom ====================

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDormRoom({
    required UDormRoomCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormRoom/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UDormRoomResponse>>?, UEmptyResponse?, String?)> readDormRooms({
    required UDormRoomReadParams p,
    Function(UResponse<List<UDormRoomResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UDormRoomResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormRoom/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UDormRoomResponse>> ok = UResponse<List<UDormRoomResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UDormRoomResponse>.from((i as List<dynamic>).map((dynamic x) => UDormRoomResponse.fromMap(x))),
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

  Future<(UResponse<UDormRoomResponse>?, UEmptyResponse?, String?)> readDormRoomById({
    required UIdParams p,
    Function(UResponse<UDormRoomResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UDormRoomResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormRoom/ReadById",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDormRoomResponse> ok = UResponse<UDormRoomResponse>.fromJson(r.body, (dynamic i) => UDormRoomResponse.fromMap(i));
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDormRoom({
    required UDormRoomUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormRoom/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDormRoom({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormRoom/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  // ==================== DormBed ====================

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createDormBed({
    required UDormBedCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBed/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UDormBedResponse>>?, UEmptyResponse?, String?)> readDormBeds({
    required UDormBedReadParams p,
    Function(UResponse<List<UDormBedResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UDormBedResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBed/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UDormBedResponse>> ok = UResponse<List<UDormBedResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UDormBedResponse>.from((i as List<dynamic>).map((dynamic x) => UDormBedResponse.fromMap(x))),
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

  Future<(UResponse<UDormBedResponse>?, UEmptyResponse?, String?)> readDormBedById({
    required UIdParams p,
    Function(UResponse<UDormBedResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UDormBedResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBed/ReadById",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UDormBedResponse> ok = UResponse<UDormBedResponse>.fromJson(r.body, (dynamic i) => UDormBedResponse.fromMap(i));
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateDormBed({
    required UDormBedUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBed/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteDormBed({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBed/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createDormBedContract({
    required UDormBedContractCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<String>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedContract/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UDormBedContractResponse>>?, UResponse<dynamic>?, String?)> readDormBedContract({
    required UDormBedContractReadParams p,
    Function(UResponse<List<UDormBedContractResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UDormBedContractResponse>>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedContract/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<List<UDormBedContractResponse>> ok = UResponse<List<UDormBedContractResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UDormBedContractResponse>.from((i as List<dynamic>).map((dynamic x) => UDormBedContractResponse.fromMap(x))),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<UDormBedContractResponse>?, UResponse<dynamic>?, String?)> updateDormBedContract({
    required UDormBedContractUpdateParams p,
    Function(UResponse<UDormBedContractResponse> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UDormBedContractResponse>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedContract/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<UDormBedContractResponse> ok = UResponse<UDormBedContractResponse>.fromJson(r.body, (dynamic i) => UDormBedContractResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<dynamic>?, UResponse<dynamic>?, String?)> deleteDormBedContract({
    required UIdParams p,
    Function(UResponse<dynamic> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<dynamic>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedContract/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<dynamic> ok = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<UDormBedInvoiceResponse>?, UResponse<dynamic>?, String?)> createDormBedInvoice({
    required UDormBedInvoiceCreateParams p,
    Function(UResponse<UDormBedInvoiceResponse> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UDormBedInvoiceResponse>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedInvoice/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<UDormBedInvoiceResponse> ok = UResponse<UDormBedInvoiceResponse>.fromJson(r.body, (dynamic i) => UDormBedInvoiceResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UDormBedInvoiceResponse>>?, UResponse<dynamic>?, String?)> readDormBedInvoice({
    required UDormBedInvoiceReadParams p,
    Function(UResponse<List<UDormBedInvoiceResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UDormBedInvoiceResponse>>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedInvoice/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<List<UDormBedInvoiceResponse>> ok = UResponse<List<UDormBedInvoiceResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UDormBedInvoiceResponse>.from((i as List<dynamic>).map((dynamic x) => UDormBedInvoiceResponse.fromMap(x))),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<UDormBedInvoiceResponse>?, UResponse<dynamic>?, String?)> updateDormBedInvoice({
    required UDormBedInvoiceUpdateParams p,
    Function(UResponse<UDormBedInvoiceResponse> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UDormBedInvoiceResponse>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedInvoice/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<UDormBedInvoiceResponse> ok = UResponse<UDormBedInvoiceResponse>.fromJson(r.body, (dynamic i) => UDormBedInvoiceResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<dynamic>?, UResponse<dynamic>?, String?)> deleteDormBedInvoice({
    required UIdParams p,
    Function(UResponse<dynamic> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<dynamic>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedInvoice/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<dynamic> ok = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> payDormBedInvoice({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/DormBedInvoice/Pay",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  // ==================== HotelReservation ====================

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createHotelReservation({
    required UHotelReservationCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<String>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelReservation/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UHotelReservationResponse>>?, UResponse<dynamic>?, String?)> readHotelReservations({
    required UHotelReservationReadParams p,
    Function(UResponse<List<UHotelReservationResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UHotelReservationResponse>>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelReservation/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<List<UHotelReservationResponse>> ok = UResponse<List<UHotelReservationResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UHotelReservationResponse>.from((i as List<dynamic>).map((dynamic x) => UHotelReservationResponse.fromMap(x))),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<UHotelReservationResponse>?, UResponse<dynamic>?, String?)> readHotelReservationById({
    required UIdParams p,
    Function(UResponse<UHotelReservationResponse> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UHotelReservationResponse>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelReservation/ReadById",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<UHotelReservationResponse> ok = UResponse<UHotelReservationResponse>.fromJson(r.body, (dynamic i) => UHotelReservationResponse.fromMap(i));
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> updateHotelReservation({
    required UHotelReservationUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelReservation/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> deleteHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelReservation/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> _reservationAction({
    required String action,
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelReservation/$action",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> confirmHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _reservationAction(action: "Confirm", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> checkInHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _reservationAction(action: "CheckIn", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> checkOutHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _reservationAction(action: "CheckOut", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> cancelHotelReservation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) => _reservationAction(action: "Cancel", p: p, onOk: onOk, onError: onError, onException: onException);

  // ==================== HotelInvoice ====================

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createHotelInvoice({
    required UHotelInvoiceCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<String>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelInvoice/Create",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UResponse<List<UHotelInvoiceResponse>>?, UResponse<dynamic>?, String?)> readHotelInvoices({
    required UHotelInvoiceReadParams p,
    Function(UResponse<List<UHotelInvoiceResponse>> r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UHotelInvoiceResponse>>?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelInvoice/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<List<UHotelInvoiceResponse>> ok = UResponse<List<UHotelInvoiceResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UHotelInvoiceResponse>.from((i as List<dynamic>).map((dynamic x) => UHotelInvoiceResponse.fromMap(x))),
        );
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> updateHotelInvoice({
    required UHotelInvoiceUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelInvoice/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> deleteHotelInvoice({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelInvoice/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> payHotelInvoice({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UResponse<dynamic> e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UResponse<dynamic>?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelInvoice/Pay",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UResponse<dynamic> err = UResponse<dynamic>.fromJson(r.body, (dynamic i) => i);
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

  // ==================== Guest booking ====================

  Future<(UResponse<List<UHotelRoomAvailabilityResponse>>?, UEmptyResponse?, String?)> readHotelRoomAvailability({
    required UHotelRoomAvailabilityParams p,
    Function(UResponse<List<UHotelRoomAvailabilityResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<List<UHotelRoomAvailabilityResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelRoom/Availability",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<List<UHotelRoomAvailabilityResponse>> ok = UResponse<List<UHotelRoomAvailabilityResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UHotelRoomAvailabilityResponse>.from((i as List<dynamic>).map((dynamic x) => UHotelRoomAvailabilityResponse.fromMap(x))),
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

  Future<(UResponse<UHotelReservationResponse>?, UEmptyResponse?, String?)> bookHotelReservation({
    required UHotelReservationBookParams p,
    Function(UResponse<UHotelReservationResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UResponse<UHotelReservationResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelReservation/Book",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UResponse<UHotelReservationResponse> ok = UResponse<UHotelReservationResponse>.fromJson(r.body, (dynamic i) => UHotelReservationResponse.fromMap(i));
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> cancelHotelReservationByUser({
    required UHotelReservationCancelParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Hotel/HotelReservation/CancelByUser",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()).add("locale", ULocalStorage.getLocale()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
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
