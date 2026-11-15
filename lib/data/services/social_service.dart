part of "../data.dart";

class USocialService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createReport({
    required UReportCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Social/Report/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UReportResponse>>?, UEmptyResponse?, String?)> readReports({
    required UReportReadParams p,
    Function(UResponse<List<UReportResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Social/Report/Read", p.toMap(), _Api.list(UReportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateReport({
    required UReportUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Social/Report/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
