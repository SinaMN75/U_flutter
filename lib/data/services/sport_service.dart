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

  Future<(UResponse<String>?, UEmptyResponse?, String?)> createTournament({
    required UTournamentCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Tournament/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UTournamentResponse>>?, UEmptyResponse?, String?)> readTournaments({
    required UTournamentReadParams p,
    Function(UResponse<List<UTournamentResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Tournament/Read", p.toMap(), _Api.list(UTournamentResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UTournamentResponse>?, UEmptyResponse?, String?)> readTournamentById({
    required UIdParams p,
    Function(UResponse<UTournamentResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Tournament/ReadById", p.toMap(), _Api.one(UTournamentResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateTournament({
    required UTournamentUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Tournament/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteTournament({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Tournament/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UTournamentStandingResponse>>?, UEmptyResponse?, String?)> readTournamentStandings({
    required UIdParams p,
    Function(UResponse<List<UTournamentStandingResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Tournament/Standings", p.toMap(), _Api.list(UTournamentStandingResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> generateTournamentMatches({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Tournament/GenerateMatches", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  /// Box league: a new period with the same players, box winners moved up and the last of each box moved down.
  Future<(UResponse<String>?, UEmptyResponse?, String?)> createNextTournamentSeason({
    required UIdParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/Tournament/NextSeason", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> registerTournamentEntry({
    required UTournamentRegisterParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/TournamentEntry/Register", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateTournamentEntry({
    required UTournamentEntryUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/TournamentEntry/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteTournamentEntry({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/TournamentEntry/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateTournamentMatch({
    required UTournamentMatchUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Sport/TournamentMatch/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
