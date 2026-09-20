part of "../data.dart";

class NotificationService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UNotificationCreateParams p,
    Function(UResponse<String> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Notification/Create", p.toMap(), _Api.raw<String>(), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UNotificationResponse>>?, UEmptyResponse?, String?)> read({
    required UNotificationReadParams p,
    Function(UResponse<List<UNotificationResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Notification/Read", p.toMap(), _Api.list(UNotificationResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UNotificationUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Notification/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Notification/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
