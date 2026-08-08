part of "../data.dart";

class FileManagerService {
  Future<(UResponse<UFileManagerListResponse>?, UEmptyResponse?, String?)> browse({
    required final UFileManagerBrowseParams p,
    required Function(UResponse<UFileManagerListResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<UFileManagerListResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/FileManager/Browse",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UResponse<UFileManagerListResponse> ok = UResponse<UFileManagerListResponse>.fromJson(r.body, (dynamic i) => UFileManagerListResponse.fromMap(i));
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> createFolder({
    required final UFileManagerCreateFolderParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _mutate("CreateFolder", p.toMap(), onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> rename({
    required final UFileManagerRenameParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _mutate("Rename", p.toMap(), onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> move({
    required final UFileManagerMoveParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _mutate("Move", p.toMap(), onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required final UFileManagerDeleteParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _mutate("Delete", p.toMap(), onOk, onError, onException);

  Future<(UResponse<String>?, UEmptyResponse?, String?)> upload({
    required final UFileManagerUploadParams p,
    required Function(UResponse<String> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    final List<MultipartFile> files = <MultipartFile>[
      if (p.file.path != null)
        await UHttpClient.multipartFileFromFile("File", File(p.file.path!), filename: p.file.path!.split("/").last)
      else if (p.file.bytes != null)
        await UHttpClient.multipartFileFromUint8List("File", p.file.bytes!, filename: p.file.path?.split("/").last ?? "file.${p.file.extension ?? "bin"}"),
    ];
    await UHttpClient.upload(
      endpoint: "${U.baseUrl}/FileManager/Upload",
      files: files,
      fields: p.toMap()..addAll(<String, dynamic>{"apiKey": U.apiKey, "token": ULocalStorage.getToken()}),
      onSuccess: (final Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (final dynamic i) => i);
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: () {
        result = (null, null, "");
        onException("");
      },
    );
    return result;
  }

  // Public URL used to open/download a file through the browser (token carried as a query param).
  String downloadUrl(final String path) => "${U.baseUrl}/FileManager/Download?path=${Uri.encodeQueryComponent(path)}&token=${Uri.encodeQueryComponent(ULocalStorage.getToken() ?? "")}";

  // Fetches raw file contents (for inline text/json/code previews).
  Future<void> fetchText({
    required final String url,
    required Function(String content) onOk,
    required Function(String e) onException,
  }) async {
    await UHttpClient.send(
      method: "GET",
      endpoint: url,
      onSuccess: (final Response r) => onOk(r.body),
      onError: (final Response r) => onException(r.body),
      onException: onException,
    );
  }

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> _mutate(
    final String path,
    final Map<String, dynamic> body,
    Function(UEmptyResponse r) onOk,
    Function(UEmptyResponse e) onError,
    Function(String e) onException,
  ) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/FileManager/$path",
      body: body.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (final Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (final Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (final String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }
}
