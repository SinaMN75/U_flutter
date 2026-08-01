part of "../data.dart";

class DashboardService {
  Future<(UMetricsResponse?, UEmptyResponse?, String?)> readSystemMetrics({
    final Function(UMetricsResponse r)? onOk,
    final VoidCallback? onError,
    final Function(String e)? onException,
  }) async {
    (UMetricsResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadSystemMetrics",
      onSuccess: (final Response r) {
        final UMetricsResponse ok = UMetricsResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UDashboardResponse?, UEmptyResponse?, String?)> read({
    final Function(UDashboardResponse r)? onOk,
    final VoidCallback? onError,
    final Function(String e)? onException,
  }) async {
    (UDashboardResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/Read",
      onSuccess: (final Response r) {
        final UDashboardResponse ok = UDashboardResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<UFinancialOpsDashboardResponse>?, UEmptyResponse?, String?)> readFinancialOpsDashboard({
    required final UDashboardRangeParams p,
    final Function(UResponse<UFinancialOpsDashboardResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UFinancialOpsDashboardResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadFinancialOpsDashboard",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UFinancialOpsDashboardResponse> ok = UResponse<UFinancialOpsDashboardResponse>.fromJson(
          r.body,
          (final dynamic i) => UFinancialOpsDashboardResponse.fromMap(i),
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

  Future<(UResponse<UPropertyDashboardResponse>?, UEmptyResponse?, String?)> readPropertyDashboard({
    required final UDashboardRangeParams p,
    final Function(UResponse<UPropertyDashboardResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UPropertyDashboardResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadPropertyDashboard",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UPropertyDashboardResponse> ok = UResponse<UPropertyDashboardResponse>.fromJson(
          r.body,
          (final dynamic i) => UPropertyDashboardResponse.fromMap(i),
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

  Future<(UResponse<UOsMetricsResponse>?, UEmptyResponse?, String?)> readOsMetrics({
    final Function(UResponse<UOsMetricsResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UOsMetricsResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadOsMetrics",
      body: <String, dynamic>{}.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UOsMetricsResponse> ok = UResponse<UOsMetricsResponse>.fromJson(
          r.body,
          (final dynamic i) => UOsMetricsResponse.fromMap(i),
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

  Future<(LogStructureResponse?, UEmptyResponse?, String?)> getLogStructure({
    final Function(LogStructureResponse r)? onOk,
    final VoidCallback? onError,
    final Function(String e)? onException,
  }) async {
    (LogStructureResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/Logs/structure",
      onSuccess: (final Response r) {
        final LogStructureResponse ok = LogStructureResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(String?, UEmptyResponse?, String?)> getLogContent({
    required final String logId,
    final Function(String r)? onOk,
    final VoidCallback? onError,
    final Function(String e)? onException,
  }) async {
    (String?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/Logs/content",
      body: <String, String>{"id": logId},
      onSuccess: (final Response r) {
        final String ok = r.body;
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }

  Future<(UResponse<List<UApiLogResponse>>?, UEmptyResponse?, String?)> readApiLogs({
    required final UApiLogReadParams p,
    final Function(UResponse<List<UApiLogResponse>> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<List<UApiLogResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ReadApiLogs",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<List<UApiLogResponse>> ok = UResponse<List<UApiLogResponse>>.fromJson(
          r.body,
          (final dynamic i) => List<UApiLogResponse>.from((i as List<dynamic>).map((final dynamic x) => UApiLogResponse.fromMap(x))),
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

  Future<(UResponse<UApiLogStatsResponse>?, UEmptyResponse?, String?)> apiLogStats({
    required final UApiLogStatsParams p,
    final Function(UResponse<UApiLogStatsResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UApiLogStatsResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ApiLogStats",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UApiLogStatsResponse> ok = UResponse<UApiLogStatsResponse>.fromJson(r.body, (final dynamic i) => UApiLogStatsResponse.fromMap(i));
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

  Future<(String?, UEmptyResponse?, String?)> exportApiLogs({
    required final UApiLogReadParams p,
    final Function(String csv)? onOk,
    final VoidCallback? onError,
    final Function(String e)? onException,
  }) async {
    (String?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/dashboard/ApiLogExport",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final String ok = r.body;
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call();
      },
      onException: (final String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }
}
