part of "../data.dart";

class DashboardService {
  Future<(UMetricsResponse?, UEmptyResponse?, String?)> readSystemMetrics({
    required Function(UMetricsResponse r)? onOk,
    required VoidCallback? onError,
    required Function(String e)? onException,
  }) async {
    (UMetricsResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadSystemMetrics",
      onSuccess: (Response r) {
        final UMetricsResponse ok = UMetricsResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UDashboardResponse?, UEmptyResponse?, String?)> read({
    required Function(UDashboardResponse r)? onOk,
    required VoidCallback? onError,
    required Function(String e)? onException,
  }) async {
    (UDashboardResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/Read",
      onSuccess: (Response r) {
        final UDashboardResponse ok = UDashboardResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UFinancialOpsDashboardResponse>?, UEmptyResponse?, String?)> readFinancialOpsDashboard({
    required UDashboardRangeParams p,
    required Function(UResponse<UFinancialOpsDashboardResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UFinancialOpsDashboardResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadFinancialOpsDashboard",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UFinancialOpsDashboardResponse> ok = UResponse<UFinancialOpsDashboardResponse>.fromJson(
          r.body,
          (dynamic i) => UFinancialOpsDashboardResponse.fromMap(i),
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

  Future<(UResponse<UPropertyDashboardResponse>?, UEmptyResponse?, String?)> readPropertyDashboard({
    required UDashboardRangeParams p,
    required Function(UResponse<UPropertyDashboardResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UPropertyDashboardResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadPropertyDashboard",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UPropertyDashboardResponse> ok = UResponse<UPropertyDashboardResponse>.fromJson(
          r.body,
          (dynamic i) => UPropertyDashboardResponse.fromMap(i),
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

  Future<(UResponse<UOsMetricsResponse>?, UEmptyResponse?, String?)> readOsMetrics({
    required Function(UResponse<UOsMetricsResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UOsMetricsResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadOsMetrics",
      body: <String, dynamic>{}.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UOsMetricsResponse> ok = UResponse<UOsMetricsResponse>.fromJson(
          r.body,
          (dynamic i) => UOsMetricsResponse.fromMap(i),
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

  Future<(LogStructureResponse?, UEmptyResponse?, String?)> getLogStructure({
    required Function(LogStructureResponse r)? onOk,
    required VoidCallback? onError,
    required Function(String e)? onException,
  }) async {
    (LogStructureResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/Logs/structure",
      onSuccess: (Response r) {
        final LogStructureResponse ok = LogStructureResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(String?, UEmptyResponse?, String?)> getLogContent({
    required String logId,
    required Function(String r)? onOk,
    required VoidCallback? onError,
    required Function(String e)? onException,
  }) async {
    (String?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/Logs/content",
      body: <String, String>{"id": logId},
      onSuccess: (Response r) {
        final String ok = r.body;
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<List<UApiLogResponse>>?, UEmptyResponse?, String?)> readApiLogs({
    required UApiLogReadParams p,
    required Function(UResponse<List<UApiLogResponse>> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<List<UApiLogResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadApiLogs",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UApiLogResponse>> ok = UResponse<List<UApiLogResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UApiLogResponse>.from((i as List<dynamic>).map((dynamic x) => UApiLogResponse.fromMap(x))),
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

  Future<(UResponse<UApiLogStatsResponse>?, UEmptyResponse?, String?)> apiLogStats({
    required UApiLogStatsParams p,
    required Function(UResponse<UApiLogStatsResponse> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UResponse<UApiLogStatsResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ApiLogStats",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UApiLogStatsResponse> ok = UResponse<UApiLogStatsResponse>.fromJson(r.body, (dynamic i) => UApiLogStatsResponse.fromMap(i));
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

  Future<(String?, UEmptyResponse?, String?)> exportApiLogs({
    required UApiLogReadParams p,
    required Function(String csv)? onOk,
    required VoidCallback? onError,
    required Function(String e)? onException,
  }) async {
    (String?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ApiLogExport",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final String ok = r.body;
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(List<String>?, UEmptyResponse?, String?)> readAppLogs({
    required Function(List<String> r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (List<String>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "GET",
      endpoint: "${U.baseUrl}/Log/Read",
      onSuccess: (Response r) {
        final UResponse<List<String>> ok = UResponse<List<String>>.fromJson(
          r.body,
          (dynamic i) => List<String>.from((i as List<dynamic>).map((dynamic x) => x.toString())),
        );
        final List<String> logs = ok.result ?? <String>[];
        result = (logs, null, null);
        onOk?.call(logs);
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

  Future<(bool, UEmptyResponse?, String?)> clearAppLogs({
    required VoidCallback? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (bool, UEmptyResponse?, String?) result = (false, null, null);
    await UHttpClient.send(
      method: "DELETE",
      endpoint: "${U.baseUrl}/Log/Clear",
      onSuccess: (Response r) {
        result = (true, null, null);
        onOk?.call();
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (false, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (false, null, e);
        onException?.call(e);
      },
    );
    return result;
  }
}
