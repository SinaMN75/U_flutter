part of "../data.dart";

class UAccountingService {
  Future<(UResponse<UAccountingReportResponse>?, UEmptyResponse?, String?)> report({
    required UAccountingReportParams p,
    Function(UResponse<UAccountingReportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Report", p.toMap(), _Api.one(UAccountingReportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> requestOrganizationSettlement({
    required UOrganizationSettlementRequestParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Settlement/Request", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> processOrganizationSettlement({
    required UOrganizationSettlementProcessParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Settlement/Process", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createAccount({
    required UAccountCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Account/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UAccountResponse>>?, UEmptyResponse?, String?)> readAccounts({
    required UAccountReadParams p,
    Function(UResponse<List<UAccountResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Account/Read", p.toMap(), _Api.list(UAccountResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateAccount({
    required UAccountUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Account/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteAccount({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Account/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createVoucher({
    required UVoucherCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Voucher/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UVoucherResponse>>?, UEmptyResponse?, String?)> readVouchers({
    required UVoucherReadParams p,
    Function(UResponse<List<UVoucherResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Voucher/Read", p.toMap(), _Api.list(UVoucherResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteVoucher({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Voucher/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULedgerResponse>?, UEmptyResponse?, String?)> readLedger({
    required ULedgerReadParams p,
    Function(UResponse<ULedgerResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Ledger/Read", p.toMap(), _Api.one(ULedgerResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<ULedgerReportResponse>?, UEmptyResponse?, String?)> readLedgerReport({
    required ULedgerReportParams p,
    Function(UResponse<ULedgerReportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Ledger/Report", p.toMap(), _Api.one(ULedgerReportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UTaxInvoiceItem>>?, UEmptyResponse?, String?)> readTaxInvoices({
    required ULedgerReportParams p,
    Function(UResponse<List<UTaxInvoiceItem>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Ledger/TaxInvoices", p.toMap(), _Api.list(UTaxInvoiceItem.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createCheck({
    required UCheckCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Check/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCheckResponse>>?, UEmptyResponse?, String?)> readChecks({
    required UCheckReadParams p,
    Function(UResponse<List<UCheckResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Check/Read", p.toMap(), _Api.list(UCheckResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> setCheckStatus({
    required UCheckStatusParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/accounting/Check/SetStatus", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
