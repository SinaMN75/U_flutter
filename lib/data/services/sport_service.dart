part of "../data.dart";

class USportService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createSport({
    required USportCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Sport/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<USportResponse>>?, UEmptyResponse?, String?)> readSports({
    required USportReadParams p,
    Function(UResponse<List<USportResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Sport/Read", p.toMap(), _Api.list(USportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<USportResponse>?, UEmptyResponse?, String?)> readSportById({
    required UIdParams p,
    Function(UResponse<USportResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Sport/ReadById", p.toMap(), _Api.one(USportResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateSport({
    required USportUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Sport/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteSport({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Sport/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createPlayerSportProfile({
    required UPlayerSportProfileCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/PlayerSportProfile/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UPlayerSportProfileResponse>>?, UEmptyResponse?, String?)> readPlayerSportProfiles({
    required UPlayerSportProfileReadParams p,
    Function(UResponse<List<UPlayerSportProfileResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/PlayerSportProfile/Read", p.toMap(), _Api.list(UPlayerSportProfileResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updatePlayerSportProfile({
    required UPlayerSportProfileUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/PlayerSportProfile/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deletePlayerSportProfile({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/PlayerSportProfile/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
