import "package:u/utilities.dart";

/// Why an ISO8583 call failed before a host answer: cannotConnect, noResponse, badResponseMac, notLoggedOn, securityModuleFailed, badRequest.
enum UIsoErrorCode { cannotConnect, noResponse, badResponseMac, notLoggedOn, securityModuleFailed, badRequest }

/// Error thrown inside the ISO layer; UIsoClient.send turns it into onException.
class UIsoException implements Exception {
  /// An ISO error with a code and message.
  UIsoException(this.code, this.message, [this.cause]);

  /// Kind of failure.
  final UIsoErrorCode code;

  /// Human-readable reason.
  final String message;

  /// Underlying error, if any.
  final Object? cause;

  @override
  String toString() => message;
}

/// Optional progress callbacks while a message is in flight (show "waiting for host…").
abstract class IsoLinkEvents {
  /// The request was sent; waiting for the answer.
  void onWaitForReceive() {}

  /// No answer in time.
  void onReceiveTimeout() {}

  /// Connection opened/closed/failed.
  void onConnectionEvent(String event, Object? error) {}
}

/// ISO8583 (POS/switch) setup, like U.baseUrl for REST: host config, terminal context, security module, trace counter. `UIso.init(config: c, context: ctx, securityModule: hsm, nextTraceNumber: nextStan)`
abstract class UIso {
  /// Host settings (address, NII, BIN, key slots).
  static late HostConfig config;

  /// Terminal state (terminal/merchant id after logon, device serials).
  static late HostContext context;

  /// Hardware/software security module that holds keys, makes MACs and PIN blocks.
  static late IsoSecurityModule securityModule;

  /// Must keep counting across restarts; the host refuses a number it has
  /// already seen today.
  static late Future<int> Function() nextTraceNumber;

  /// How to open the connection (TCP socket by default; replace for tests).
  static IsoTransport Function(HostConnectionInfo info) transportFactory = SocketIsoTransport.new;

  static IsoLink? _link;

  /// The shared connection to the host.
  static IsoLink get link => _link ??= IsoLink(
    config: config,
    macComponent: MacComponent(config: config, securityModule: securityModule),
    transportFactory: transportFactory,
  );

  /// True after a successful logon (terminal id known).
  static bool get isLoggedOn => context.terminalLogicalInfo != null;

  /// The key slot the security module uses when it encrypts a PIN.
  static int get pinKeyIndex => config.sessionKeyIndexSetting.ppkIndex;

  /// Sets everything UIsoClient needs; call before the first send (again to switch hosts).
  static void init({
    required HostConfig config,
    required HostContext context,
    required IsoSecurityModule securityModule,
    required Future<int> Function() nextTraceNumber,
    IsoTransport Function(HostConnectionInfo info)? transportFactory,
  }) {
    UIso.config = config;
    UIso.context = context;
    UIso.securityModule = securityModule;
    UIso.nextTraceNumber = nextTraceNumber;
    if (transportFactory != null) UIso.transportFactory = transportFactory;
    _link = null;
  }

  /// Drops the open connection so the next send reconnects with new settings.
  static Future<void> reset() async {
    await _link?.dispose();
    _link = null;
  }

  /// Puts the keys a logon returned into the security module, each at the slot
  /// the host settings name. The keys are never readable again afterwards.
  static Future<void> storeSessionKeys(Map<IsoKeyType, IsoSessionKey> keys) async {
    final Map<IsoKeyType, int> slots = <IsoKeyType, int>{
      IsoKeyType.dpk: config.sessionKeyIndexSetting.dpkIndex,
      IsoKeyType.ppk: config.sessionKeyIndexSetting.ppkIndex,
      IsoKeyType.mpk: config.sessionKeyIndexSetting.mpkIndex,
    };

    for (final MapEntry<IsoKeyType, IsoSessionKey> key in keys.entries) {
      try {
        await securityModule.storeSessionKey(
          keyIndex: slots[key.key]!,
          ktmIndex: config.initKeySetting.ktmIndex,
          keyType: key.key,
          sessionKey: key.value.value,
          kvc: key.value.checkValue,
        );
      } catch (error) {
        throw UIsoException(UIsoErrorCode.securityModuleFailed, "could not load a session key into the terminal", error);
      }
    }
  }
}

/// One session key from a logon, with its check value.
class IsoSessionKey {
  /// A session key.
  const IsoSessionKey(this.value, this.checkValue);

  /// Encrypted key bytes.
  final Uint8List value;

  /// Key check value (KCV) to verify the load.
  final Uint8List? checkValue;
}

/// The host's answer to UIsoClient.send (like an HTTP Response): response code, fields, TLV tags.
class UIsoResult {
  /// A host answer.
  UIsoResult({required this.traceNumber, required this.sentAt, required this.raw, required this.tags});

  /// The number this message went out with, ISO field 11. Belongs on receipts.
  final int traceNumber;

  /// When the request was sent (local time).
  final DateTime sentAt;

  /// The raw ISO message.
  final IsoMsg raw;

  /// TLV tags from field 63, if any.
  final TlvList? tags;

  /// `"00"` when the host approved.
  String? get responseCode => field(39);

  /// Set when the link refused the message before the host saw it.
  int? get rejectCode => raw.rejectCode;

  /// True when the host approved (response code "00").
  bool get isSuccess => responseCode == "00";

  /// `0` on success, otherwise the host's own number for what went wrong.
  int get status => rejectCode ?? int.tryParse(responseCode ?? "") ?? -1;

  /// The text the host wants shown to the customer.
  String get message => tag(PrimitiveTags.errorMessage)?.trim() ?? "";

  /// Text of ISO field [number]. `r.field(39)`
  String? field(int number) => raw.getString(number);

  /// Bytes of ISO field [number].
  Uint8List? bytes(int number) => raw.hasField(number) ? raw.getBytes(number) : null;

  /// Text of a field-63 TLV tag.
  String? tag(int tag) => tags?.findFirst(tag)?.asString;

  /// Text of a nested TLV tag.
  String? tagPath(List<int> path) => tags?.findFirstRecursive(path)?.asString;

  /// A TLV group (constructed tag).
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

/// Sends one ISO8583 message and waits for the answer, filling trace number, date/time, terminal id, TLVs and MAC. `UIsoClient.send(mti: "0200", processingCode: "000000", onSuccess: ok, onError: err, onException: fail)`
abstract class UIsoClient {
  /// Sends a request; [fields] adds ISO fields, [tags] adds field-63 TLVs; onError gets host declines, onException gets link failures.
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
