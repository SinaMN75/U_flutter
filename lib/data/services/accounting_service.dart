part of "../data.dart";

class AccountingService {
  Future<(UResponse<UAccountingReportResponse>?, UEmptyResponse?, String?)> report({
    required final UAccountingReportParams p,
    final Function(UResponse<UAccountingReportResponse> r)? onOk,
    final Function(UEmptyResponse e)? onError,
    final Function(String e)? onException,
  }) async {
    (UResponse<UAccountingReportResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/accounting/Report",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UAccountingReportResponse> ok = UResponse<UAccountingReportResponse>.fromJson(
          r.body,
          (final dynamic i) => UAccountingReportResponse.fromMap(i),
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
}
