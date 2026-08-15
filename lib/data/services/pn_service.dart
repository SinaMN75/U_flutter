part of "../data.dart";

class PnService {
  Future<UHttpClientResponse> auth({
    required Map<String, dynamic> body,
    void Function(int status, String body)? onResponse,
    void Function(String e)? onException,
  }) => _post("Auth", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> createMerchant({
    required Map<String, dynamic> body,
    void Function(int status, String body)? onResponse,
    void Function(String e)? onException,
  }) => _post("CreateMerchant", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> createTerminal({
    required Map<String, dynamic> body,
    void Function(int status, String body)? onResponse,
    void Function(String e)? onException,
  }) => _post("CreateTerminal", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> userStatus({
    required Map<String, dynamic> body,
    void Function(int status, String body)? onResponse,
    void Function(String e)? onException,
  }) => _post("UserStatus", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> readTerminalSupportPassword({
    required Map<String, dynamic> body,
    void Function(int status, String body)? onResponse,
    void Function(String e)? onException,
  }) => _post("ReadTerminalSupportPassword", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> zipCodeToAddress({
    required Map<String, dynamic> body,
    void Function(int status, String body)? onResponse,
    void Function(String e)? onException,
  }) => _post("ZipCodeToAddress", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> _post(
    String path,
    Map<String, dynamic> body, {
    void Function(int status, String body)? onResponse,
    void Function(String e)? onException,
  }) => UHttpClient.send(
    method: "POST",
    endpoint: "${U.baseUrl}/Pn/$path",
    body: body,
    // The Pn API returns a JSON envelope on both success and failure, so surface either verbatim.
    onSuccess: (Response r) => onResponse?.call(r.statusCode, r.body),
    onError: (Response r) => onResponse?.call(r.statusCode, r.body),
    onException: (String e) => onException?.call(e),
  );
}
