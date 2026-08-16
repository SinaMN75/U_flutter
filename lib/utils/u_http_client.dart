import "dart:developer" as developer;

import "package:u/utilities.dart";

enum URequestBodyType { json, formData }

class UHttpClientResponse {
  final String? response;
  final String? error;
  final String? exception;

  UHttpClientResponse({this.response, this.error, this.exception});

  bool get isSuccessful => response != null;

  bool get isError => error != null;

  bool get isException => exception != null;
}

abstract class UHttpClient {
  static final Client _client = Client();
  static Future<void> Function()? onAuthFailed;
  static Future<bool>? _refreshInFlight;

  static Future<bool> _refreshToken() {
    _refreshInFlight ??= (() async {
      final String? refreshToken = ULocalStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;
      final (UResponse<ULoginResponse>?, UEmptyResponse?, String?) result = await AuthService().refreshToken(
        p: URefreshTokenParams(refreshToken: refreshToken),
        onOk: (UResponse<ULoginResponse> r) {},
        onError: (UEmptyResponse e) {},
        onException: (String e) {},
      );
      return result.$1?.result != null;
    })().whenComplete(() => _refreshInFlight = null);
    return _refreshInFlight!;
  }

  static Future<UHttpClientResponse> send({
    required String method,
    required String endpoint,
    required Function(Response) onSuccess,
    required Function(Response) onError,
    required Function(String) onException,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    dynamic body,
    URequestBodyType bodyType = URequestBodyType.json,
    String? noNetworkMessage,
    String? unexpectedErrorMessage,
    bool offline = false,
    Duration? cacheDuration,
    int retryAmount = 3,
    Duration timeout = const Duration(seconds: 30),
    void Function(int percent)? onProgress,
    bool isRetryAfterRefresh = false,
  }) async {
    int lastPercent = -1;
    void report(num percent) {
      if (onProgress == null) return;
      final int p = percent.clamp(0, 100).toInt();
      if (p <= lastPercent) return;
      lastPercent = p;
      onProgress(p);
    }

    final bool hasNetworkConnection = await UNetwork.hasAnyConnection();

    if (!hasNetworkConnection && offline == false) {
      final String message = noNetworkMessage ?? U.s.connectionToNetworkWasNotPossible;
      onException(message);
      return UHttpClientResponse(exception: message);
    }

    final Uri uri = _buildUri(endpoint, queryParams);
    final bool cacheEnabled = offline || cacheDuration != null;
    final String cacheKey = cacheEnabled ? _cacheKey(method, uri, body) : "";

    if (offline) {
      final String? cachedData = await _readCache(cacheKey);
      if (cachedData != null) {
        final Response response = Response(cachedData, 200, request: Request(method, uri));
        onSuccess(response);
        return UHttpClientResponse(response: cachedData);
      }
    }

    final Response response;
    try {
      final Request request = Request(method, uri);
      if (headers != null) request.headers.addAll(headers);

      if (body != null) {
        if (bodyType == URequestBodyType.json) {
          if (body is Map) {
            request.body = jsonEncode(removeNullEntries(body));
            request.headers["Content-Type"] = "application/json";
            request.headers["Locale"] = UApp.locale();
            request.headers["Timezone"] = UTimezone.getLocalTimezone();
          } else if (body is String) {
            request.body = body;
          } else if (body is List<int>) {
            request.bodyBytes = body;
          }
        } else if (bodyType == URequestBodyType.formData && body is Map<String, dynamic>) {
          final Map<String, String> formFields = <String, String>{};
          body.forEach((String key, dynamic value) {
            if (value != null) {
              formFields[key] = value.toString();
            }
          });
          request.bodyFields = formFields;
          request.headers["Content-Type"] = "application/x-www-form-urlencoded";
        }
      }

      final List<int> uploadBytes = request.bodyBytes;
      final bool hasUpload = uploadBytes.length >= 64 * 1024;
      final int uploadWeight = hasUpload ? 50 : 0;
      final int downloadBand = 100 - uploadWeight;

      final BaseRequest outgoing = !hasUpload || onProgress == null
          ? request
          : (_UProgressRequest(method, uri, uploadBytes, (int uploadPercent) => report((uploadPercent / 100 * uploadWeight).round()))
              ..headers.addAll(request.headers)
              ..contentLength = uploadBytes.length);

      final StreamedResponse streamed = await _client.send(outgoing).timeout(timeout);
      report(uploadWeight);

      final int? totalBytes = streamed.contentLength;
      final BytesBuilder receivedBuilder = BytesBuilder(copy: false);
      int receivedCount = 0;

      Timer? estimateTicker;
      if (onProgress != null && (totalBytes == null || totalBytes <= 0)) {
        const int tauMs = 7000;
        final Stopwatch sw = Stopwatch()..start();
        estimateTicker = Timer.periodic(const Duration(milliseconds: 200), (Timer _) {
          final double frac = sw.elapsedMilliseconds / (sw.elapsedMilliseconds + tauMs);
          report(uploadWeight + (frac * downloadBand).round().clamp(0, downloadBand - 1));
        });
      }

      try {
        await for (final List<int> chunk in streamed.stream) {
          receivedBuilder.add(chunk);
          receivedCount += chunk.length;
          if (totalBytes != null && totalBytes > 0) report(uploadWeight + (receivedCount / totalBytes * downloadBand).round());
        }
      } finally {
        estimateTicker?.cancel();
      }
      report(100);

      response = Response.bytes(
        receivedBuilder.takeBytes(),
        streamed.statusCode,
        request: streamed.request,
        headers: streamed.headers,
        reasonPhrase: streamed.reasonPhrase,
      );
    } catch (e, stack) {
      developer.log(e.toString(), stackTrace: stack);
      if (retryAmount > 0) {
        final int attempt = retryAmount < 1 ? 1 : (4 - retryAmount).clamp(1, 4);
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
        return send(
          method: method,
          endpoint: endpoint,
          onSuccess: onSuccess,
          onError: onError,
          onException: onException,
          headers: headers,
          offline: offline,
          cacheDuration: cacheDuration,
          body: body,
          bodyType: bodyType,
          noNetworkMessage: noNetworkMessage,
          queryParams: queryParams,
          retryAmount: retryAmount - 1,
          unexpectedErrorMessage: unexpectedErrorMessage,
          timeout: timeout,
          onProgress: onProgress,
          isRetryAfterRefresh: isRetryAfterRefresh,
        );
      } else {
        final String message = unexpectedErrorMessage ?? U.s.unexpectedErrorPleaseTryAgain;
        onException(message);
        return UHttpClientResponse(exception: message);
      }
    }

    if (kDebugMode) response.prettyLog(params: jsonEncode(body));

    try {
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        if (cacheEnabled) await _writeCache(cacheKey, response.body, cacheDuration);
        onSuccess(response);
        return UHttpClientResponse(response: response.body);
      } else if (response.statusCode == Usc.expiredToken.number && !isRetryAfterRefresh && !endpoint.contains("/auth/")) {
        final bool refreshed = await _refreshToken();
        if (refreshed) {
          final dynamic retryBody = body is Map ? (Map<String, dynamic>.from(body)..["token"] = ULocalStorage.getToken()) : body;
          return await send(
            method: method,
            endpoint: endpoint,
            onSuccess: onSuccess,
            onError: onError,
            onException: onException,
            headers: headers,
            queryParams: queryParams,
            body: retryBody,
            bodyType: bodyType,
            noNetworkMessage: noNetworkMessage,
            unexpectedErrorMessage: unexpectedErrorMessage,
            offline: offline,
            cacheDuration: cacheDuration,
            retryAmount: retryAmount,
            timeout: timeout,
            onProgress: onProgress,
            isRetryAfterRefresh: true,
          );
        }
        await onAuthFailed?.call();
        onError(response);
        return UHttpClientResponse(error: response.body);
      } else {
        onError(response);
        return UHttpClientResponse(error: response.body);
      }
    } catch (e, stack) {
      developer.log(e.toString(), stackTrace: stack);
      final String message = unexpectedErrorMessage ?? U.s.unexpectedErrorPleaseTryAgain;
      onException(message);
      return UHttpClientResponse(exception: message);
    }
  }

  static Future<void> upload({
    required String endpoint,
    required List<MultipartFile> files,
    required Function(Response)? onSuccess,
    required Function(Response)? onError,
    required VoidCallback onException,
    Map<String, dynamic>? fields,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    String method = "POST",
    Duration timeout = const Duration(minutes: 5),
    void Function(int percent)? onProgress,
  }) async {
    int lastPercent = -1;
    void report(int percent) {
      if (onProgress == null) return;
      final int p = percent.clamp(0, 100).toInt();
      if (p <= lastPercent) return;
      lastPercent = p;
      onProgress(p);
    }

    try {
      final MultipartRequest request = onProgress == null ? MultipartRequest(method, _buildUri(endpoint, queryParams)) : _UProgressMultipartRequest(method, _buildUri(endpoint, queryParams), report);
      request.headers.addAll(<String, String>{...?headers});
      if (fields != null) request.fields.addAll(removeNullEntries(fields)!.map((String key, dynamic value) => MapEntry<String, String>(key, value is String ? value : jsonEncode(value))));
      request.files.addAll(files);
      final Response response = await request.send().timeout(timeout).then(Response.fromStream);
      if (kDebugMode) response.prettyLog(params: jsonEncode(fields));
      if (response.statusCode >= 200 && response.statusCode < 300)
        onSuccess?.call(response);
      else
        onError?.call(response);
    } catch (e, stack) {
      onException();
      developer.log(e.toString(), stackTrace: stack);
    }
  }

  static Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final Uri uri = Uri.parse(endpoint);

    if (queryParams != null) {
      return uri.replace(
        queryParameters: queryParams.map(
          (String key, dynamic value) => MapEntry<String, String>(key, value?.toString() ?? ""),
        ),
      );
    }
    return uri;
  }

  static Future<MultipartFile> multipartFileFromFile(
    String fieldName,
    File file, {
    String? filename,
    MediaType? contentType,
  }) async {
    filename ??= file.path.split("/").last;
    final Stream<List<int>> stream = file.openRead();
    final int length = await file.length();
    return MultipartFile(
      fieldName,
      stream,
      length,
      filename: filename,
      contentType: contentType,
    );
  }

  static Future<MultipartFile> multipartFileFromUint8List(
    String fieldName,
    Uint8List bytes, {
    String? filename,
    MediaType? contentType,
  }) async => MultipartFile.fromBytes(fieldName, bytes, contentType: contentType, filename: filename);

  static T? removeNullEntries<T>(T? json) {
    if (json == null) return null;

    if (json is List) {
      json.removeWhere((dynamic e) => e == null);
      json.forEach(removeNullEntries);
    } else if (json is Map) {
      json.removeWhere((dynamic key, dynamic value) => key == null || value == null);
      json.values.forEach(removeNullEntries);
    }

    return json;
  }

  static final RegExp _nonWord = RegExp(r"[^\w]");

  static String _cacheKey(String method, Uri uri, dynamic body) => "cache_${method}_${uri.toString().replaceAll(_nonWord, "_")}_${body == null ? "" : jsonEncode(body).hashCode}";

  static Future<void> _writeCache(String key, String body, Duration? cacheDuration) async {
    if (kIsWeb) {
      ULocalStorage.set(key, body, expireTime: cacheDuration);
      return;
    }
    await UFileStorage.set(key, body);
    ULocalStorage.set("${key}_exp", cacheDuration == null ? 0 : DateTime.now().add(cacheDuration).millisecondsSinceEpoch);
  }

  static Future<String?> _readCache(String key) async {
    if (kIsWeb) return ULocalStorage.getString(key);
    final int? expiry = ULocalStorage.getInt("${key}_exp");
    if (expiry != null && expiry > 0 && DateTime.now().millisecondsSinceEpoch > expiry) {
      await UFileStorage.remove(key);
      await ULocalStorage.remove("${key}_exp");
      return null;
    }
    return UFileStorage.getString(key);
  }
}

class _UProgressRequest extends BaseRequest {
  _UProgressRequest(super.method, super.url, this._bodyBytes, this._onSendProgress);

  final List<int> _bodyBytes;
  final void Function(int percent) _onSendProgress;

  @override
  ByteStream finalize() {
    super.finalize();
    final int total = _bodyBytes.length;
    if (total == 0) {
      _onSendProgress(100);
      return ByteStream.fromBytes(_bodyBytes);
    }
    // 64KB chunks cut the number of event-loop hops (and progress calls) ~8x versus 8KB, speeding large uploads
    const int chunkSize = 64 * 1024;
    int sent = 0;
    Stream<List<int>> generate() async* {
      for (int i = 0; i < total; i += chunkSize) {
        final int end = (i + chunkSize) < total ? i + chunkSize : total;
        final List<int> chunk = _bodyBytes.sublist(i, end);
        sent += chunk.length;
        _onSendProgress((sent / total * 100).round());
        yield chunk;
      }
    }

    return ByteStream(generate());
  }
}

class _UProgressMultipartRequest extends MultipartRequest {
  _UProgressMultipartRequest(super.method, super.url, this._onSendProgress);

  final void Function(int percent) _onSendProgress;

  @override
  ByteStream finalize() {
    final ByteStream byteStream = super.finalize();
    final int total = contentLength;
    int sent = 0;
    final StreamTransformer<List<int>, List<int>> reporter = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        sent += data.length;
        if (total > 0) _onSendProgress((sent / total * 100).clamp(0, 100).round());
        sink.add(data);
      },
    );

    return ByteStream(byteStream.transform(reporter));
  }
}

extension HTTP on Response? {
  bool isSuccessful() => (this?.statusCode ?? 999) >= 200 && (this?.statusCode ?? 999) <= 299;

  bool isServerError() => (this?.statusCode ?? 999) >= 500 && (this?.statusCode ?? 999) <= 599;

  void prettyLog({String params = ""}) => developer.log(
    "${this?.request?.method} - ${this?.request?.url} - ${this?.statusCode} \nPARAMS: $params \nRESPONSE: ${this?.body}",
  );
}

class UDownload {
  static const int _maxRetries = 10;
  static final Map<String, CancelableOperation<Uint8List>> _operations = <String, CancelableOperation<Uint8List>>{};

  static Future<Uint8List?> downloadFile({
    required String url,
    required String cacheKey,
    required void Function(int progress) onProgress,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (_operations.containsKey(cacheKey)) {
      await _operations[cacheKey]?.cancel();
    }

    final CancelableOperation<Uint8List> op = CancelableOperation<Uint8List>.fromFuture(
      _performDownload(url: url, cacheKey: cacheKey, onProgress: onProgress, timeout: timeout),
      onCancel: () => _operations.remove(cacheKey),
    );

    _operations[cacheKey] = op;

    try {
      final Uint8List data = await op.value;
      _operations.remove(cacheKey);
      return data;
    } catch (e) {
      _operations.remove(cacheKey);
      rethrow;
    }
  }

  static Future<Uint8List> _performDownload({
    required String url,
    required String cacheKey,
    required void Function(int progress) onProgress,
    required Duration timeout,
  }) async {
    final Directory dir = await getTemporaryDirectory();
    final String safeCacheKey = _getSafeCacheKey(cacheKey);
    final File file = File("${dir.path}/$safeCacheKey.tmp");

    int downloadedBytes = 0;
    if (file.existsSync()) {
      try {
        downloadedBytes = await file.length();
      } catch (e) {
        await _safeDelete(file);
        downloadedBytes = 0;
      }
    }

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      final Client client = Client();

      try {
        final Map<String, String> headers = <String, String>{};
        if (Platform.isWindows) headers["User-Agent"] = "Dart/2.0 (Windows)";

        if (downloadedBytes > 0) {
          headers["Range"] = "bytes=$downloadedBytes-";
        }

        final Request request = Request("GET", Uri.parse(url))..headers.addAll(headers);

        final StreamedResponse response = await client
            .send(request)
            .timeout(
              timeout,
              onTimeout: () => throw TimeoutException("Connection timeout on attempt $attempt"),
            );

        if (response.statusCode == 416) {
          if (file.existsSync() && downloadedBytes > 0) {
            return await _readFileWithRetry(file);
          } else {
            await _safeDelete(file);
            downloadedBytes = 0;
            continue;
          }
        }

        if (response.statusCode != 200 && response.statusCode != 206) {
          throw Exception("Bad status: ${response.statusCode}");
        }

        if (response.statusCode == 200 && downloadedBytes > 0) {
          await _safeDelete(file);
          downloadedBytes = 0;
          headers.remove("Range");
        }

        final int? totalBytes = response.contentLength != null ? response.contentLength! + downloadedBytes : null;

        IOSink? sink;
        try {
          sink = file.openWrite(mode: FileMode.append);
        } catch (e) {
          await _safeDelete(file);
          downloadedBytes = 0;
          continue;
        }

        int received = downloadedBytes;
        int chunkCounter = 0;

        await for (final List<int> chunk in response.stream) {
          try {
            sink.add(chunk);
            received += chunk.length;
            chunkCounter++;

            if (chunkCounter % 50 == 0) {
              await sink.flush();
            }

            if (totalBytes != null) {
              final int p = (received / totalBytes * 100).clamp(0, 100).round();
              onProgress(p);
            }
          } catch (e) {
            await sink.close();
            await _safeDelete(file);
            throw Exception("Write error on chunk $chunkCounter: $e");
          }
        }

        await sink.flush();
        await sink.close();
        client.close();

        final int finalSize = await file.length();
        if (totalBytes != null && finalSize != totalBytes) throw Exception("Download incomplete: $finalSize/$totalBytes bytes");

        return await _readFileWithRetry(file);
      } catch (e) {
        client.close();
        if (attempt == _maxRetries) rethrow;
        await Future<void>.delayed(Duration(seconds: attempt * 3));
        if (e.toString().contains("416") || e is TimeoutException) {
          await _safeDelete(file);
          downloadedBytes = 0;
        }
      }
    }

    throw Exception("Failed to download after $_maxRetries retries");
  }

  // FIX 8: Safe filename for Windows
  static String _getSafeCacheKey(String original) {
    if (!Platform.isWindows) return original;

    // Remove invalid Windows characters and limit length
    final String safe = original.replaceAll(RegExp(r'[<>:"/\\|?*]'), "_");
    return safe.length > 50 ? "${safe.substring(0, 45)}_${original.hashCode.abs()}" : safe;
  }

  // FIX 9: Safe file delete with retry for Windows
  static Future<void> _safeDelete(File file) async {
    if (!file.existsSync()) return;

    for (int i = 0; i < 3; i++) {
      try {
        await file.delete();
        break;
      } catch (e) {
        if (i == 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 100 * (i + 1)));
      }
    }
  }

  // FIX 10: Read file with retry for Windows file locks
  static Future<Uint8List> _readFileWithRetry(File file) async {
    for (int i = 0; i < 3; i++) {
      try {
        return await file.readAsBytes();
      } catch (e) {
        if (i == 2) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 100 * (i + 1)));
      }
    }
    throw Exception("Could not read file");
  }

  static bool isDownloading(String cacheKey) => _operations.containsKey(cacheKey);

  static void cancelDownload(String cacheKey) {
    if (_operations.containsKey(cacheKey)) {
      _operations[cacheKey]?.cancel();
      _operations.remove(cacheKey);
    }
  }
}
