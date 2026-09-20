part of "../data.dart";

class AccountingService {
  Future<(UResponse<UAccountingReportResponse>?, UEmptyResponse?, String?)> report({
    required UAccountingReportParams p,
    Function(UResponse<UAccountingReportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Report", p.toMap(), _Api.one(UAccountingReportResponse.fromMap), _Api.empty, onOk, onError, onException);
}
