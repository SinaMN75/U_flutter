import "package:u/utilities.dart";

/// What the host sent back, the way `Response` is what an HTTP call returns.
class UIsoResult {
  UIsoResult({required this.traceNumber, required this.sentAt, required this.raw, required this.tags});

  /// The number this message went out with, ISO field 11. Belongs on receipts.
  final int traceNumber;
  final DateTime sentAt;
  final IsoMsg raw;
  final TlvList? tags;

  /// `"00"` when the host approved.
  String? get responseCode => field(39);

  /// Set when the link refused the message before the host saw it.
  int? get rejectCode => raw.rejectCode;

  bool get isSuccess => responseCode == "00";

  /// `0` on success, otherwise the host's own number for what went wrong.
  int get status => rejectCode ?? int.tryParse(responseCode ?? "") ?? -1;

  /// The text the host wants shown to the customer.
  String get message => tag(PrimitiveTags.errorMessage)?.trim() ?? "";

  String? field(int number) => raw.getString(number);

  Uint8List? bytes(int number) => raw.hasField(number) ? raw.getBytes(number) : null;

  String? tag(int tag) => tags?.findFirst(tag)?.asString;

  String? tagPath(List<int> path) => tags?.findFirstRecursive(path)?.asString;

  TlvList? group(int tag) => tags?.find(tag);

  /// The host writes `yyyyMMddHHmmss`; anything shorter is left null.
  DateTime? get hostDateTime {
    final String? value = tag(PrimitiveTags.serverDateTime);
    if (value == null || value.length < 14) return null;
    return DateTime.tryParse(
      "${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)} "
      "${value.substring(8, 10)}:${value.substring(10, 12)}:${value.substring(12, 14)}",
    );
  }
}

/// Sends one ISO message and waits for its answer — the same job [UHttpClient]
/// does for REST, with the same `onSuccess` / `onError` / `onException` shape.
///
/// It fills in everything every message carries, so a service only says what is
/// different about its own call: a fresh trace number, the local date and time,
/// the terminal and merchant id, the device serial, the field 63 wrapper and
/// the MAC.
abstract class UIsoClient {
  static Future<void> send({
    required String mti,
    required String processingCode,
    required FutureOr<void> Function(UIsoResult r) onSuccess,
    required FutureOr<void> Function(UIsoResult r) onError,
    required FutureOr<void> Function(String e) onException,
    Map<int, Object?> fields = const <int, Object?>{},
    Map<int, String> tags = const <int, String>{},
    bool sendTerminalId = true,
    Duration? timeout,
    IsoLinkEvents? events,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final int traceNumber = await UIso.nextTraceNumber();
      final IsoMsg request = _buildRequest(mti, processingCode, fields, tags, sendTerminalId, traceNumber, now);

      final IsoMsg? answer = await UIso.link.sendMessage(request, timeout: timeout, events: events);
      if (answer == null) throw UIsoException(UIsoErrorCode.noResponse, "no answer from the host");

      final UIsoResult result = UIsoResult(
        traceNumber: traceNumber,
        sentAt: now,
        raw: answer,
        tags: answer.hasField(63) ? OssAcqTlvPackager.unpackToTlvMessage(answer.getBytes(63)!) : null,
      );
      if (result.isSuccess) {
        await onSuccess(result);
      } else {
        await onError(result);
      }
    } on UIsoException catch (error) {
      await onException(error.message);
    } catch (error) {
      await onException(error.toString());
    }
  }

  static IsoMsg _buildRequest(
    String mti,
    String processingCode,
    Map<int, Object?> fields,
    Map<int, String> tags,
    bool sendTerminalId,
    int traceNumber,
    DateTime now,
  ) {
    final IsoMsg request = IsoMsg();
    request.setMti(mti);
    request.setString(3, processingCode);
    request.setString(11, traceNumber.toString());
    request.setString(12, "${_two(now.hour)}${_two(now.minute)}${_two(now.second)}");
    request.setString(13, "${_two(now.month)}${_two(now.day)}");
    request.setString(24, UIso.config.nii);
    request.setString(32, UIso.config.bin);

    if (sendTerminalId) {
      final TerminalLogicalInfo? terminal = UIso.context.terminalLogicalInfo;
      if (terminal == null) throw UIsoException(UIsoErrorCode.notLoggedOn, "this call needs a terminal id — run a logon first");
      request.setString(41, terminal.terminalId);
      request.setString(42, terminal.merchantId);
    }

    fields.forEach((int number, Object? value) {
      if (value is Uint8List) {
        request.setBytes(number, value);
      } else if (value != null) {
        request.setString(number, value.toString());
      }
    });

    final TlvList body = TlvList();
    final String? serialNumber = UIso.context.deviceInfo.serialNumber;
    if (serialNumber != null) body.appendText(PrimitiveTags.posSerial, serialNumber);
    final String? simSerial = UIso.context.deviceInfo.simSerial;
    if (simSerial != null) body.appendText(PrimitiveTags.posSerial2, simSerial);
    body.appendText(PrimitiveTags.appVersion, UIso.config.version);
    body.appendText(PrimitiveTags.localDateYear, now.year.toString());
    body.appendText(PrimitiveTags.language, "0");
    tags.forEach(body.appendText);
    if (body.tags.isNotEmpty) request.setBytes(63, OssAcqTlvPackager.packToTlvMessage(body));

    return request;
  }

  static String _two(int value) => value.toString().padLeft(2, "0");
}
