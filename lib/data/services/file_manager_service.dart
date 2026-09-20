part of "../data.dart";

class FileManagerService {
  Future<(UResponse<UFileManagerListResponse>?, UEmptyResponse?, String?)> browse({
    required UFileManagerBrowseParams p,
    required Function(UResponse<UFileManagerListResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/FileManager/Browse", p.toMap(), _Api.one(UFileManagerListResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UResponse<UFileManagerEntryResponse>?, UEmptyResponse?, String?)> createFolder({
    required UFileManagerCreateFolderParams p,
    required Function(UResponse<UFileManagerEntryResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _entry("CreateFolder", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UFileManagerEntryResponse>?, UEmptyResponse?, String?)> rename({
    required UFileManagerRenameParams p,
    required Function(UResponse<UFileManagerEntryResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _entry("Rename", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UFileManagerEntryResponse>?, UEmptyResponse?, String?)> move({
    required UFileManagerMoveParams p,
    required Function(UResponse<UFileManagerEntryResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _entry("Move", p.toMap(), onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UFileManagerDeleteParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _mutate("Delete", p.toMap(), onOk, onError, onException);

  Future<(UResponse<UFileManagerEntryResponse>?, UEmptyResponse?, String?)> upload({
    required UFileManagerUploadParams p,
    required Function(UResponse<UFileManagerEntryResponse> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<UFileManagerEntryResponse>?, UEmptyResponse?, String?) result = (null, null, null);
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
      onSuccess: (Response r) {
        final UResponse<UFileManagerEntryResponse> ok = UResponse<UFileManagerEntryResponse>.fromJson(r.body, (dynamic i) => UFileManagerEntryResponse.fromMap(i));
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (Response r) {
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
  String downloadUrl(String path) => "${U.baseUrl}/FileManager/Download?path=${Uri.encodeQueryComponent(path)}&token=${Uri.encodeQueryComponent(ULocalStorage.getToken() ?? "")}";

  // Fetches raw file contents (for inline text/json/code previews).
  Future<void> fetchText({
    required String url,
    required Function(String content) onOk,
    required Function(String e) onException,
  }) async {
    await UHttpClient.send(
      method: "GET",
      endpoint: url,
      onSuccess: (Response r) => onOk(r.body),
      onError: (Response r) => onException(r.body),
      onException: onException,
    );
  }

  Future<(UResponse<UFileManagerEntryResponse>?, UEmptyResponse?, String?)> _entry(
    String path,
    Map<String, dynamic> body,
    Function(UResponse<UFileManagerEntryResponse> r) onOk,
    Function(UEmptyResponse e) onError,
    Function(String e) onException,
  ) async {
    (UResponse<UFileManagerEntryResponse>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/FileManager/$path",
      body: body.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<UFileManagerEntryResponse> ok = UResponse<UFileManagerEntryResponse>.fromJson(r.body, (dynamic i) => UFileManagerEntryResponse.fromMap(i));
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> _mutate(
    String path,
    Map<String, dynamic> body,
    Function(UEmptyResponse r) onOk,
    Function(UEmptyResponse e) onError,
    Function(String e) onException,
  ) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/FileManager/$path",
      body: body.add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException(e);
      },
    );
    return result;
  }
}
