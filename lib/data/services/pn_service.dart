part of "../data.dart";

// Thin client for the external-facing Pn API. Backs the admin Pn tester page: every call posts the
// caller-supplied body (which already carries the apiKey and endpoint fields) and hands back the raw
// status code and response body so the tester can render the response exactly as the server sent it.
class PnService {
  Future<UHttpClientResponse> auth({
    required final Map<String, dynamic> body,
    final void Function(int status, String body)? onResponse,
    final void Function(String e)? onException,
  }) => _post("Auth", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> createMerchant({
    required final Map<String, dynamic> body,
    final void Function(int status, String body)? onResponse,
    final void Function(String e)? onException,
  }) => _post("CreateMerchant", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> createTerminal({
    required final Map<String, dynamic> body,
    final void Function(int status, String body)? onResponse,
    final void Function(String e)? onException,
  }) => _post("CreateTerminal", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> userStatus({
    required final Map<String, dynamic> body,
    final void Function(int status, String body)? onResponse,
    final void Function(String e)? onException,
  }) => _post("UserStatus", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> readTerminalSupportPassword({
    required final Map<String, dynamic> body,
    final void Function(int status, String body)? onResponse,
    final void Function(String e)? onException,
  }) => _post("ReadTerminalSupportPassword", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> zipCodeToAddress({
    required final Map<String, dynamic> body,
    final void Function(int status, String body)? onResponse,
    final void Function(String e)? onException,
  }) => _post("ZipCodeToAddress", body, onResponse: onResponse, onException: onException);

  Future<UHttpClientResponse> _post(
    final String path,
    final Map<String, dynamic> body, {
    final void Function(int status, String body)? onResponse,
    final void Function(String e)? onException,
  }) => UHttpClient.send(
    method: "POST",
    endpoint: "${U.baseUrl}/Pn/$path",
    body: body,
    // The Pn API returns a JSON envelope on both success and failure, so surface either verbatim.
    onSuccess: (final Response r) => onResponse?.call(r.statusCode, r.body),
    onError: (final Response r) => onResponse?.call(r.statusCode, r.body),
    onException: (final String e) => onException?.call(e),
  );
}
