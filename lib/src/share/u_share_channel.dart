import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:path_provider/path_provider.dart";
import "package:u/src/files/u_files_channel.dart";
import "package:u/src/share/u_share_web_stub.dart" if (dart.library.js_interop) "package:u/src/share/u_share_web.dart";

// =============================================================================
// u_share_channel — the system share sheet, sharing straight to one app, and
// receiving what other apps share to this one ("u/share" + "u/share/received").
//
//   Android  ACTION_SEND chooser with the chosen app reported back; FileProvider URIs
//   iOS      UIActivityViewController (iPad popover anchored), rich link preview, subject
//   macOS    NSSharingServicePicker anchored to the given rect
//   Windows  Windows share sheet (DataTransferManager)
//   Linux    no share sheet exists: text goes to the clipboard, files are shown in the file manager
//   Web      navigator.share (files where supported), clipboard fallback; received files via launchQueue
// =============================================================================

/// Share result: success, dismissed, shown (no result on this platform), copied (Linux clipboard), unavailable.
enum UShareStatus {
  /// The user picked a target (see [UShareResult.target]).
  success,

  /// The user closed the sheet without sharing.
  dismissed,

  /// The sheet was shown but the platform does not say what happened (Windows, macOS services).
  shown,

  /// No share sheet here: the text was copied to the clipboard instead.
  copied,

  /// Nothing could be shared.
  unavailable,
}

/// App for UShare.to: whatsapp, telegram, eitaa, rubika, bale, soroush, instagram, x, email, sms…
enum UShareTarget { whatsapp, telegram, eitaa, rubika, bale, soroush, instagram, x, email, sms }

/// Result of a share: status and the chosen app (Android/iOS/macOS).
@immutable
class UShareResult {
  const UShareResult(this.status, [this.target]);

  /// What happened.
  final UShareStatus status;

  /// The app or service the user chose (Android package, iOS activity type, macOS service name).
  final String? target;

  /// True when the content was shared.
  bool get isSuccess => status == UShareStatus.success || status == UShareStatus.shown || status == UShareStatus.copied;

  @override
  String toString() => "UShareResult(${status.name}${target == null ? "" : ", $target"})";
}

/// A file to share: a path on disk, or bytes with a [name].
@immutable
class UShareFile {
  /// A file from disk. `UShareFile.path("/path/a.pdf")`
  const UShareFile.path(String this.path, {this.mimeType, this.name}) : bytes = null;

  /// A file from bytes. `UShareFile.bytes(data, name: "a.pdf")`
  const UShareFile.bytes(Uint8List this.bytes, {required String this.name, this.mimeType}) : path = null;

  /// A file from disk. `UShareFile.path("/path/a.pdf")`
  final String? path;

  /// A file from bytes. `UShareFile.bytes(data, name: "a.pdf")`
  final Uint8List? bytes;

  /// File name shown to the receiving app.
  final String? name;

  /// MIME type (guessed from the name when null).
  final String? mimeType;

  /// Name used for the file.
  String get fileName => name ?? path?.split(RegExp(r"[/\\]")).last ?? "file";
}

/// What another app shared into this one.
@immutable
class UReceivedShare {
  const UReceivedShare({this.text, this.subject, this.files = const <UShareFile>[]});

  /// Reads it from the native map.
  factory UReceivedShare.fromMap(Map<Object?, Object?> map) => UReceivedShare(
    text: map["text"] as String?,
    subject: map["subject"] as String?,
    files: <UShareFile>[
      for (final Object? f in (map["files"] as List<Object?>?) ?? <Object?>[])
        if (f is Map && f["bytes"] is Uint8List)
          UShareFile.bytes(f["bytes"]! as Uint8List, name: "${f["name"] ?? "file"}", mimeType: f["mimeType"] as String?)
        else if (f is Map && f["path"] != null)
          UShareFile.path("${f["path"]}", mimeType: f["mimeType"] as String?, name: f["name"] as String?),
    ],
  );

  /// Shared text or link.
  final String? text;

  /// Shared subject.
  final String? subject;

  /// Shared files (copied into the app's cache).
  final List<UShareFile> files;

  /// The shared text when it is a single link.
  Uri? get link {
    final String? t = text?.trim();
    if (t == null || t.contains(RegExp(r"\s"))) return null;
    final Uri? uri = Uri.tryParse(t);
    return uri != null && uri.hasScheme ? uri : null;
  }

  /// True when nothing was shared.
  bool get isEmpty => (text == null || text!.isEmpty) && files.isEmpty;

  @override
  String toString() => "UReceivedShare(text: $text, files: ${files.map((UShareFile f) => f.fileName).join(", ")})";
}

/// Engine behind UShare; use UShare instead.
abstract final class UShareChannel {
  static const MethodChannel _channel = MethodChannel("u/share");
  static const EventChannel _events = EventChannel("u/share/received");

  static final StreamController<UReceivedShare> _received = StreamController<UReceivedShare>.broadcast();
  static StreamSubscription<dynamic>? _subscription;
  static Future<UReceivedShare?>? _initial;

  static Future<T?> _call<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint("u/share.$method failed: ${e.code} ${e.message ?? ""}");
      return null;
    }
  }

  static UShareResult _result(Object? raw) {
    if (raw is! Map) return const UShareResult(UShareStatus.unavailable);
    final UShareStatus status = UShareStatus.values.firstWhere((UShareStatus s) => s.name == raw["status"], orElse: () => UShareStatus.unavailable);
    return UShareResult(status, raw["target"] as String?);
  }

  // Bytes become temporary files so every native share sheet gets a real path.
  static Future<List<Map<String, Object?>>> _files(List<UShareFile> files) async {
    final List<Map<String, Object?>> out = <Map<String, Object?>>[];
    Directory? dir;
    for (final UShareFile f in files) {
      String? path = f.path;
      if (path == null && f.bytes != null) {
        dir ??= await Directory("${(await getTemporaryDirectory()).path}${Platform.pathSeparator}u_share_${DateTime.now().microsecondsSinceEpoch}").create(recursive: true);
        path = "${dir.path}${Platform.pathSeparator}${f.fileName}";
        await File(path).writeAsBytes(f.bytes!, flush: true);
      }
      if (path != null) out.add(<String, Object?>{"path": path, "mimeType": f.mimeType, "name": f.fileName});
    }
    return out;
  }

  /// Engine call behind UShare.share.
  static Future<UShareResult> share({String? text, String? subject, String? title, Uri? url, List<UShareFile> files = const <UShareFile>[], Rect? origin}) async {
    if (text == null && url == null && files.isEmpty) return const UShareResult(UShareStatus.unavailable);
    if (kIsWeb) return UShareWeb.share(text: text, subject: subject, title: title, url: url?.toString(), files: files);
    final Object? raw = await _call<Object?>("share", <String, Object?>{
      "text": text,
      "subject": subject,
      "title": title,
      "url": url?.toString(),
      "files": await _files(files),
      if (origin != null) "origin": <double>[origin.left, origin.top, origin.width, origin.height],
    });
    final UShareResult result = _result(raw);
    if (result.status != UShareStatus.unavailable || !Platform.isLinux) return result;
    return _linuxFallback(text: text, url: url, files: files);
  }

  // Linux has no share sheet: copy the text, show files in the file manager.
  static Future<UShareResult> _linuxFallback({String? text, Uri? url, List<UShareFile> files = const <UShareFile>[]}) async {
    final String joined = <String?>[text, url?.toString()].whereType<String>().join("\n");
    if (joined.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: joined));
      return const UShareResult(UShareStatus.copied);
    }
    final List<Map<String, Object?>> paths = await _files(files);
    if (paths.isEmpty) return const UShareResult(UShareStatus.unavailable);
    final bool shown = await UFilesChannel.reveal("${paths.first["path"]}");
    return UShareResult(shown ? UShareStatus.shown : UShareStatus.unavailable);
  }

  /// Engine call behind UShare.to.
  static Future<UShareResult> shareTo(UShareTarget target, {String? text, List<UShareFile> files = const <UShareFile>[]}) async {
    if (kIsWeb) return share(text: text, files: files);
    final Object? raw = await _call<Object?>("shareTo", <String, Object?>{"target": target.name, "text": text, "files": await _files(files)});
    final UShareResult result = _result(raw);
    // Target missing or not directly addressable here: fall back to the share sheet.
    return result.status == UShareStatus.unavailable ? share(text: text, files: files) : result;
  }

  /// Engine call behind UShare.canShareTo.
  static Future<bool> canShareTo(UShareTarget target) async => !kIsWeb && (await _call<bool>("canShareTo", <String, Object?>{"target": target.name}) ?? false);

  static void _listen() {
    if (_subscription != null) return;
    if (kIsWeb) {
      UShareWeb.listenLaunchQueue(_received.add);
      _subscription = const Stream<void>.empty().listen(null);
      return;
    }
    _subscription = _events.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) _received.add(UReceivedShare.fromMap(event));
      },
      onError: (Object e) => debugPrint("u/share received failed: $e"),
    );
  }

  /// What was shared into the app when it was launched by a share (once).
  static Future<UReceivedShare?> initial() => _initial ??= () async {
    _listen();
    if (kIsWeb) return null;
    final Object? raw = await _call<Object?>("initialShare");
    return raw is Map ? UReceivedShare.fromMap(raw) : null;
  }();

  /// Shares received while the app runs.
  static Stream<UReceivedShare> get received {
    _listen();
    return _received.stream;
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
