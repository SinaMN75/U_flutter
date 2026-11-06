part of "../data.dart";

/// Assets a store keeps for its members, with a ledger per member (backend module Custody).
class UCustodyService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createProgram({
    required UCustodyProgramCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Program/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCustodyProgramResponse>>?, UEmptyResponse?, String?)> readPrograms({
    required UCustodyProgramReadParams p,
    Function(UResponse<List<UCustodyProgramResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Program/Read", p.toMap(), _Api.list(UCustodyProgramResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateProgram({
    required UCustodyProgramUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Program/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createRate({
    required UCustodyRateCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Rate/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCustodyRateResponse>>?, UEmptyResponse?, String?)> readRates({
    required UCustodyRateReadParams p,
    Function(UResponse<List<UCustodyRateResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Rate/Read", p.toMap(), _Api.list(UCustodyRateResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createMember({
    required UCustodyMemberCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Member/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCustodyMemberResponse>>?, UEmptyResponse?, String?)> readMembers({
    required UCustodyMemberReadParams p,
    Function(UResponse<List<UCustodyMemberResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Member/Read", p.toMap(), _Api.list(UCustodyMemberResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateMember({
    required UCustodyMemberUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Member/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UCustodyEntryResponse>?, UEmptyResponse?, String?)> createEntry({
    required UCustodyEntryCreateParams p,
    Function(UResponse<UCustodyEntryResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Entry/Create", p.toMap(), _Api.one(UCustodyEntryResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UCustodyEntryResponse>>?, UEmptyResponse?, String?)> readEntries({
    required UCustodyEntryReadParams p,
    Function(UResponse<List<UCustodyEntryResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Entry/Read", p.toMap(), _Api.list(UCustodyEntryResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UCustodyEntryResponse>?, UEmptyResponse?, String?)> readEntryById({
    required UCustodyEntryReadByIdParams p,
    Function(UResponse<UCustodyEntryResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Custody/Entry/ReadById", p.toMap(), _Api.one(UCustodyEntryResponse.fromMap), _Api.empty, onOk, onError, onException);
}
