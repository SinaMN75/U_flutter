part of "../data.dart";

class UBankAccountService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UBankAccountCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/bankAccount/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UBankAccountResponse>>?, UEmptyResponse?, String?)> read({
    required UBankAccountReadParams p,
    Function(UResponse<List<UBankAccountResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/bankAccount/Read", p.toMap(), _Api.list(UBankAccountResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UBankAccountUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/bankAccount/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/bankAccount/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
