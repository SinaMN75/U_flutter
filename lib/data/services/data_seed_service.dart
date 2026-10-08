part of "../data.dart";

class UDataSeedService {
  Future<(UResponse<List<UKeyValueData>>?, UEmptyResponse?, String?)> seedDemo({
    Function(UResponse<List<UKeyValueData>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/DataSeeder/Demo", <String, dynamic>{}, _Api.list(UKeyValueData.fromMap), _Api.empty, onOk, onError, onException);
}
