part of "../data.dart";

class UMediaService {
  Future<(UResponse<String>?, UEmptyResponse?, String?)> create({
    required UMediaCreateParams p,
    required Function(UResponse<String> r)? onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UResponse<String>?, UEmptyResponse?, String?) result = (null, null, null);
    final List<MultipartFile> files = <MultipartFile>[
      if (p.file.path != null)
        await UHttpClient.multipartFileFromFile("File", File(p.file.path!), filename: p.file.path!.split("/").last)
      else if (p.file.bytes != null)
        await UHttpClient.multipartFileFromUint8List("File", p.file.bytes!, filename: p.file.path?.split("/").last ?? "file.${p.file.extension ?? "png"}"),
    ];
    await UHttpClient.upload(
      endpoint: "${U.baseUrl}/Media/Create",
      files: files,
      fields: p.toMap()..addAll(<String, dynamic>{"apiKey": U.apiKey, "token": ULocalStorage.getToken()}),
      onSuccess: (Response r) {
        final UResponse<String> ok = UResponse<String>.fromJson(r.body, (dynamic i) => i);
        result = (ok, null, null);
        onOk?.call(ok);
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

  Future<(UResponse<List<UMediaResponse>>?, UEmptyResponse?, String?)> read({
    required UMediaReadParams p,
    required Function(UResponse<List<UMediaResponse>> r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/Media/Read", p.toMap(), _Api.list(UMediaResponse.fromMap), _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UMediaUpdateParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/Media/Update", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) => _Api.call("/Media/Delete", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteRange({
    required UIdListParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) => _Api.call("/Media/DeleteRange", p.toMap(), _Api.empty, _Api.empty, onOk, onError, onException);
}
