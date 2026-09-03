part of "../data.dart";

class HotelService {
  // ==================== Hotel ====================

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createHotel({
    required UHotelCreateParams p,
    required Function(UResponse<String> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UHotelResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UHotelResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<String> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UHotelRoomResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UHotelRoomResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<String> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UDormResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UDormResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<String> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UDormRoomResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UDormRoomResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<String> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UDormBedResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UDormBedResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<String> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UDormBedContractResponse>> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UDormBedContractResponse> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<dynamic> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UDormBedInvoiceResponse> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UDormBedInvoiceResponse>> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UDormBedInvoiceResponse> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<dynamic> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<String> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UHotelReservationResponse>> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UHotelReservationResponse> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
  }) => _reservationAction(action: "Confirm", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> checkInHotelReservation({
    required UIdParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
  }) => _reservationAction(action: "CheckIn", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> checkOutHotelReservation({
    required UIdParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
  }) => _reservationAction(action: "CheckOut", p: p, onOk: onOk, onError: onError, onException: onException);

  Future<(UEmptyResponse?, UResponse<dynamic>?, String?)> cancelHotelReservation({
    required UIdParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
  }) => _reservationAction(action: "Cancel", p: p, onOk: onOk, onError: onError, onException: onException);

  // ==================== HotelInvoice ====================

  Future<(UResponse<String>?, UResponse<dynamic>?, String?)> createHotelInvoice({
    required UHotelInvoiceCreateParams p,
    required Function(UResponse<String> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UHotelInvoiceResponse>> r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UResponse<dynamic> e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<List<UHotelRoomAvailabilityResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UResponse<UHotelReservationResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
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
