part of "../data.dart";

class MediaService {
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
  }) async {
    (UResponse<List<UMediaResponse>>?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Media/Read",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UResponse<List<UMediaResponse>> ok = UResponse<List<UMediaResponse>>.fromJson(
          r.body,
          (dynamic i) => List<UMediaResponse>.from((i as List<dynamic>).map((dynamic x) => UMediaResponse.fromMap(x))),
        );
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> update({
    required UMediaUpdateParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Media/Update",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> delete({
    required UIdParams p,
    required Function(UEmptyResponse r) onOk,
    required Function(UEmptyResponse e) onError,
    required Function(String e) onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Media/Delete",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
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

  Future<(UEmptyResponse?, UEmptyResponse?, String?)> deleteRange({
    required UIdListParams p,
    required Function(UEmptyResponse r)? onOk,
    required Function(UEmptyResponse e)? onError,
    required Function(String e)? onException,
  }) async {
    (UEmptyResponse?, UEmptyResponse?, String?) result = (null, null, null);
    await UHttpClient.send(
      method: "POST",
      endpoint: "${U.baseUrl}/Media/DeleteRange",
      body: p.toMap().add("apiKey", U.apiKey).add("token", ULocalStorage.getToken()),
      onSuccess: (Response r) {
        final UEmptyResponse ok = UEmptyResponse.fromJson(r.body);
        result = (ok, null, null);
        onOk?.call(ok);
      },
      onError: (Response r) {
        final UEmptyResponse err = UEmptyResponse.fromJson(r.body);
        result = (null, err, null);
        onError?.call(err);
      },
      onException: (String e) {
        result = (null, null, e);
        onException?.call(e);
      },
    );
    return result;
  }
}
