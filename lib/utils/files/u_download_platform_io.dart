import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:path_provider/path_provider.dart";
import "package:u/plugins/files/u_files_channel.dart";
import "package:u/utils/files/u_crypto_stream.dart";
import "package:u/utils/files/u_download_platform.dart";
import "package:u/utils/files/u_storage_backend.dart";
import "package:url_launcher/url_launcher.dart";

bool get isWeb => false;

UDownloadTransport createTransport(UTransportOptions options) => _IoTransport(options);

class _IoTransport implements UDownloadTransport {
  _IoTransport(this._options)
    : _client = HttpClient()
        ..autoUncompress = false
        ..connectionTimeout = _options.connectTimeout
        ..idleTimeout = const Duration(seconds: 15)
        ..maxConnectionsPerHost = _options.maxConnectionsPerHost {
    if (_options.userAgent != null) _client.userAgent = _options.userAgent;
    final String? proxy = _options.proxy;
    if (proxy != null) _client.findProxy = (Uri _) => "PROXY $proxy";
  }

  final UTransportOptions _options;
  final HttpClient _client;

  @override
  Future<UHttpResponse> get(Uri uri, Map<String, String> headers) async {
    final HttpClientRequest request;
    try {
      request = await _client.getUrl(uri);
    } on SocketException catch (e) {
      throw UTransportException("network", e.message);
    } on TimeoutException {
      throw const UTransportException("timeout");
    } on HandshakeException catch (e) {
      throw UTransportException("certificate", e.message);
    }
    request
      ..followRedirects = true
      ..maxRedirects = 10;
    headers.forEach(request.headers.set);
    // Compressed bodies break byte ranges and length checks; ask for the raw bytes.
    request.headers.set(HttpHeaders.acceptEncodingHeader, "identity");

    final HttpClientResponse response;
    try {
      response = await request.close().timeout(_options.connectTimeout);
    } on SocketException catch (e) {
      throw UTransportException("network", e.message);
    } on TimeoutException {
      request.abort();
      throw const UTransportException("timeout");
    } on HandshakeException catch (e) {
      throw UTransportException("certificate", e.message);
    } on HttpException catch (e) {
      throw UTransportException("network", e.message);
    }

    if (_options.pinnedCertificateSha256.isNotEmpty && uri.scheme == "https") {
      final X509Certificate? certificate = response.certificate;
      final String? fingerprint = certificate == null ? null : UHasher.hex(UHashAlgorithm.sha256, certificate.der);
      if (fingerprint == null || !_options.pinnedCertificateSha256.contains(fingerprint.toLowerCase())) {
        request.abort();
        throw const UTransportException("certificate", "Certificate pin mismatch.");
      }
    }

    final Map<String, String> map = <String, String>{};
    response.headers.forEach((String name, List<String> values) => map[name.toLowerCase()] = values.join(", "));
    return UHttpResponse(
      statusCode: response.statusCode,
      headers: map,
      body: response.map((List<int> chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk)).handleError((Object e) {
        if (e is HttpException || e is SocketException) throw UTransportException("network", "$e");
        throw e;
      }),
      abort: request.abort,
    );
  }

  @override
  void close() => _client.close(force: true);
}

// -----------------------------------------------------------------------------
// Handing files to the user
// -----------------------------------------------------------------------------

String _uniquePath(String directory, String fileName) {
  String candidate = "$directory${Platform.pathSeparator}$fileName";
  if (!File(candidate).existsSync()) return candidate;
  final int dot = fileName.lastIndexOf(".");
  final String stem = dot > 0 ? fileName.substring(0, dot) : fileName;
  final String extension = dot > 0 ? fileName.substring(dot) : "";
  for (int i = 1; i < 10000; i++) {
    candidate = "$directory${Platform.pathSeparator}$stem ($i)$extension";
    if (!File(candidate).existsSync()) return candidate;
  }
  return "$directory${Platform.pathSeparator}$stem ${DateTime.now().millisecondsSinceEpoch}$extension";
}

Future<String?> publishToDownloads(UStorageBackend backend, String sourcePath, String fileName, {String? mimeType, String? subfolder}) async {
  if (Platform.isAndroid) {
    final String? uri = await UFilesChannel.saveToDownloads(sourcePath: sourcePath, fileName: fileName, mimeType: mimeType, subfolder: subfolder);
    if (uri != null) await backend.delete(sourcePath);
    return uri;
  }
  // iOS has no shared Downloads folder: the app's Documents directory is what the Files app
  // shows under "On My iPhone", once the host app sets UIFileSharingEnabled and
  // LSSupportsOpeningDocumentsInPlace in Info.plist.
  final Directory? base = Platform.isIOS ? await getApplicationDocumentsDirectory() : await getDownloadsDirectory();
  if (base == null) return null;
  final Directory directory = Directory(subfolder == null ? base.path : "${base.path}${Platform.pathSeparator}$subfolder");
  if (!directory.existsSync()) await directory.create(recursive: true);
  final String target = _uniquePath(directory.path, fileName);
  await backend.move(sourcePath, target);
  return target;
}

Future<String?> saveAs(UStorageBackend backend, String sourcePath, String fileName, {String? mimeType}) async {
  final String? destination = await UFilesChannel.saveAs(sourcePath: sourcePath, fileName: fileName, mimeType: mimeType);
  if (destination != null) await backend.delete(sourcePath);
  return destination;
}

Future<bool> open(String pathOrUri, {String? mimeType}) async {
  if (await UFilesChannel.open(pathOrUri, mimeType: mimeType)) return true;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return launchUrl(Uri.file(pathOrUri));
  return false;
}

Future<bool> reveal(String pathOrUri) async {
  if (await UFilesChannel.reveal(pathOrUri)) return true;
  try {
    if (Platform.isWindows) {
      await Process.run("explorer.exe", <String>["/select,", pathOrUri]);
      return true;
    }
    if (Platform.isLinux) {
      final ProcessResult result = await Process.run("gdbus", <String>[
        "call",
        "--session",
        "--dest",
        "org.freedesktop.FileManager1",
        "--object-path",
        "/org/freedesktop/FileManager1",
        "--method",
        "org.freedesktop.FileManager1.ShowItems",
        "['${Uri.file(pathOrUri)}']",
        "''",
      ]);
      if (result.exitCode == 0) return true;
      await Process.run("xdg-open", <String>[File(pathOrUri).parent.path]);
      return true;
    }
  } on ProcessException {
    return false;
  }
  return false;
}
