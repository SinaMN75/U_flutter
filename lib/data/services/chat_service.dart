part of "../data.dart";

class UChatService {
  Future<(UResponse<UConversationResponse>?, UEmptyResponse?, String?)> createConversation({
    required UConversationCreateParams p,
    Function(UResponse<UConversationResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Conversation/Create", p.toMap(), _Api.one(UConversationResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UConversationResponse>>?, UEmptyResponse?, String?)> readConversations({
    required UConversationReadParams p,
    Function(UResponse<List<UConversationResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Conversation/Read", p.toMap(), _Api.list(UConversationResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UConversationResponse>?, UEmptyResponse?, String?)> readConversationById({
    required UIdParams p,
    Function(UResponse<UConversationResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Conversation/ReadById", p.toMap(), _Api.one(UConversationResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateConversation({
    required UConversationUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Conversation/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> leaveConversation({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Conversation/Leave", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> markConversationRead({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Conversation/MarkRead", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UResponse<UMessageResponse>?, UEmptyResponse?, String?)> createMessage({
    required UMessageCreateParams p,
    Function(UResponse<UMessageResponse> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Message/Create", p.toMap(), _Api.one(UMessageResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<List<UMessageResponse>>?, UEmptyResponse?, String?)> readMessages({
    required UMessageReadParams p,
    Function(UResponse<List<UMessageResponse>> r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Message/Read", p.toMap(), _Api.list(UMessageResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> updateMessage({
    required UMessageUpdateParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Message/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteMessage({
    required UIdParams p,
    Function(UEmptyResponse r)? onOk,
    Function(UEmptyResponse e)? onError,
    Function(String e)? onException,
  }) => _Api.call("/Chat/Message/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
