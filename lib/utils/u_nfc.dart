import "package:u/utilities.dart";

/// NFC for every purpose: read cards/tags/phones ([UNfcReader]) or make this phone act as a contactless card ([UNfcCard]).
/// Android only (iOS: see [UNfc.status]); the app needs `dart run u:app permission add nfc`.
///
/// Phone → POS/phone in one line each:
/// ```dart
/// await UNfcCard.start(aids: <String>["F0010203040506"], text: "hello");     // phone A (card)
/// final UNfcResponse? r = await UNfcReader.readAid("F0010203040506"); // phone B / POS (reader) → r?.text == "hello"
/// ```
abstract final class UNfc {
  static const MethodChannel _channel = MethodChannel("u/nfc");
  static bool _handlerAttached = false;

  /// True on platforms with a native NFC implementation (Android).
  static bool get isPlatformSupported => !kIsWeb && Platform.isAndroid;

  /// What this device can do right now. `final UNfcStatus s = await UNfc.status(); if (!s.isEnabled) UNfc.openSettings();`
  static Future<UNfcStatus> status() async {
    if (!isPlatformSupported) return const UNfcStatus._unsupported();
    try {
      final Map<Object?, Object?>? map = await _channel.invokeMapMethod<Object?, Object?>("status");
      return map == null ? const UNfcStatus._unsupported() : UNfcStatus._fromMap(map);
    } on MissingPluginException {
      return const UNfcStatus._unsupported();
    }
  }

  /// Opens the system NFC settings so the user can turn NFC on. `await UNfc.openSettings()`
  static Future<bool> openSettings() async {
    if (!isPlatformSupported) return false;
    return await _invoke<bool>("openSettings") ?? false;
  }

  /// Bytes → uppercase hex. `UNfc.toHex(<int>[0xF0, 0x01])` → "F001"
  static String toHex(List<int> bytes) => bytes.map((int b) => (b & 0xFF).toRadixString(16).padLeft(2, "0")).join().toUpperCase();

  /// Hex (spaces/colons allowed) → bytes. `UNfc.fromHex("F0 01")` → [0xF0, 0x01]
  static Uint8List fromHex(String hex) {
    final String clean = hex.replaceAll(RegExp(r"[\s:-]"), "");
    if (clean.length.isOdd) throw FormatException("Odd-length hex", hex);
    return Uint8List.fromList(List<int>.generate(clean.length ~/ 2, (int i) => int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16)));
  }

  static void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "tag":
          await UNfcReader._onTag(UNfcTag._fromMap(call.arguments as Map<Object?, Object?>));
          return null;
        case "cardEvent":
          UNfcCard._onEvent(UNfcCardEvent._fromMap(call.arguments as Map<Object?, Object?>));
          return null;
        case "command":
          return UNfcCard._onCommand(UNfcApdu(call.arguments as Uint8List));
      }
      return null;
    });
  }

  static Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    if (!isPlatformSupported) throw const UNfcException("unsupported", "NFC is only available on Android.");
    _attachHandler();
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw UNfcException(e.code, e.message ?? e.code);
    } on MissingPluginException {
      throw const UNfcException("unsupported", "NFC is not available on this platform.");
    }
  }
}

/// NFC adapter state.
enum UNfcState { unsupported, disabled, enabled }

/// Result of [UNfc.status].
class UNfcStatus {
  const UNfcStatus._({
    required this.state,
    required this.cardEmulation,
    required this.reader,
    required this.permission,
    required this.cardActive,
    required this.readerActive,
  });

  const UNfcStatus._unsupported() : this._(state: UNfcState.unsupported, cardEmulation: false, reader: false, permission: false, cardActive: false, readerActive: false);

  factory UNfcStatus._fromMap(Map<Object?, Object?> m) => UNfcStatus._(
    state: UNfcState.values.firstWhere((UNfcState s) => s.name == m["nfc"], orElse: () => UNfcState.unsupported),
    cardEmulation: m["cardEmulation"] == true,
    reader: m["reader"] == true,
    permission: m["permission"] == true,
    cardActive: m["cardActive"] == true,
    readerActive: m["readerActive"] == true,
  );

  final UNfcState state;

  /// The hardware can emulate a card (Android HCE).
  final bool cardEmulation;

  /// The hardware can read tags/cards/phones.
  final bool reader;

  /// The app declares the NFC permission (`dart run u:app permission add nfc`).
  final bool permission;

  /// [UNfcCard] is currently answering readers.
  final bool cardActive;

  /// [UNfcReader] is currently polling.
  final bool readerActive;

  bool get isEnabled => state == UNfcState.enabled;

  bool get canEmulateCard => isEnabled && cardEmulation && permission;

  bool get canRead => isEnabled && reader && permission;

  @override
  String toString() => "UNfcStatus(${state.name}, cardEmulation: $cardEmulation, reader: $reader, permission: $permission)";
}

/// NFC failure. [code]: unsupported, permission, disabled, aid, noActivity, tagLost, io, timeout, error.
class UNfcException implements Exception {
  const UNfcException(this.code, this.message);

  final String code;
  final String message;

  bool get isTagLost => code == "tagLost";

  @override
  String toString() => "UNfcException($code): $message";
}

// ================================================================================================ card emulation

/// Makes this phone a contactless card (Android Host Card Emulation) that POS terminals or other phones can read.
///
/// The reader must SELECT one of [start]'s AIDs. Use proprietary AIDs starting with "F" (5–16 bytes) for your own
/// protocols; they are registered in the "other" category, so this doesn't need to be the default payment app.
/// The screen must be on. While [UNfcReader] is running, card emulation is paused by Android.
abstract final class UNfcCard {
  static FutureOr<Uint8List> Function(UNfcApdu command)? _commandHandler;
  static void Function(UNfcCardEvent event)? _eventHandler;
  static final StreamController<UNfcCardEvent> _events = StreamController<UNfcCardEvent>.broadcast();
  static bool _active = false;

  /// Starts answering readers.
  ///
  /// - [data] / [text]: answered natively to the SELECT (with 90 00 appended). Fastest; works without Dart.
  /// - [onCommand]: answers every other APDU (and the SELECT too when no [data]/[text]). Return [UNfcApdu.ok] / [UNfcApdu.error].
  /// - [persist]: keep answering [data]/[text] after the app is closed (until [stop]), e.g. access/loyalty cards.
  ///
  /// ```dart
  /// await UNfcCard.start(aids: <String>["F041565245454E01"], text: track2, onEvent: (UNfcCardEvent e) {
  ///   if (e.type == UNfcCardEventType.read) UToast.success(message: "Sent");
  /// });
  /// ```
  static Future<void> start({
    required List<String> aids,
    Uint8List? data,
    String? text,
    FutureOr<Uint8List> Function(UNfcApdu command)? onCommand,
    void Function(UNfcCardEvent event)? onEvent,
    bool persist = false,
  }) async {
    final Uint8List? response = data ?? (text == null ? null : Uint8List.fromList(utf8.encode(text)));
    if (response == null && onCommand == null) throw ArgumentError("Pass data, text or onCommand.");
    if (persist && response == null) throw ArgumentError("persist needs data or text (Dart isn't running when the app is closed).");
    final List<String> normalized = aids.map(_normalizeAid).toList();
    if (normalized.isEmpty) throw ArgumentError("Pass at least one AID.");
    _commandHandler = onCommand;
    _eventHandler = onEvent;
    await UNfc._invoke<void>("startCard", <String, Object?>{
      "aids": normalized,
      "response": response,
      "forward": onCommand != null,
      "persist": persist,
    });
    _active = true;
  }

  /// Stops answering readers and unregisters the AIDs. `await UNfcCard.stop()`
  static Future<void> stop() async {
    _commandHandler = null;
    _eventHandler = null;
    _active = false;
    if (UNfc.isPlatformSupported) await UNfc._invoke<void>("stopCard");
  }

  /// True between [start] and [stop] in this run of the app.
  static bool get isActive => _active;

  /// Every card event: selected, read, deactivated. `UNfcCard.events.listen((UNfcCardEvent e) => ...)`
  static Stream<UNfcCardEvent> get events => _events.stream;

  static void _onEvent(UNfcCardEvent event) {
    _eventHandler?.call(event);
    _events.add(event);
  }

  static Future<Uint8List> _onCommand(UNfcApdu command) async {
    final FutureOr<Uint8List> Function(UNfcApdu command)? handler = _commandHandler;
    if (handler == null) return UNfcApdu.error(0x6D00);
    try {
      return await handler(command);
    } catch (_) {
      return UNfcApdu.error(0x6F00);
    }
  }

  static String _normalizeAid(String aid) {
    final bool prefix = aid.endsWith("*");
    final String hex = UNfc.toHex(UNfc.fromHex(prefix ? aid.substring(0, aid.length - 1) : aid));
    if (hex.length < 10 || hex.length > 32) throw ArgumentError.value(aid, "aid", "An AID is 5 to 16 bytes");
    return prefix ? "$hex*" : hex;
  }
}

enum UNfcCardEventType { selected, read, deactivated }

/// Something a reader did to [UNfcCard].
class UNfcCardEvent {
  const UNfcCardEvent({required this.type, this.aid, this.reason});

  factory UNfcCardEvent._fromMap(Map<Object?, Object?> m) => UNfcCardEvent(
    type: UNfcCardEventType.values.firstWhere((UNfcCardEventType t) => t.name == m["type"], orElse: () => UNfcCardEventType.deactivated),
    aid: m["aid"] as String?,
    reason: m["reason"] as String?,
  );

  final UNfcCardEventType type;

  /// The selected AID.
  final String? aid;

  /// For [UNfcCardEventType.deactivated]: "deselected" or "linkLoss" (moved away).
  final String? reason;

  @override
  String toString() => "UNfcCardEvent(${type.name}, aid: $aid${reason == null ? "" : ", reason: $reason"})";
}

// ================================================================================================ reader

enum UNfcPolling { a, b, f, v }

/// Technology used by [UNfcTag.transceive]. [isoDep] = ISO 14443-4 / ISO 7816 APDUs (bank cards, ID cards, phones).
enum UNfcTech { isoDep, nfcA, nfcB, nfcF, nfcV }

/// Turns this phone into a reader for NFC tags, contactless cards and phones running [UNfcCard].
abstract final class UNfcReader {
  static FutureOr<void> Function(UNfcTag tag)? _tagHandler;
  static bool _active = false;

  /// Starts polling; [onTag] runs for each tag and the tag is released when it returns.
  /// Needs the app in the foreground. Pauses this phone's own [UNfcCard] while running.
  ///
  /// ```dart
  /// await UNfcReader.start(onTag: (UNfcTag tag) async {
  ///   final UNfcResponse r = await tag.selectAid("F041565245454E01");
  ///   if (r.isOk) UToast.success(message: r.text);
  /// });
  /// ```
  static Future<void> start({
    required FutureOr<void> Function(UNfcTag tag) onTag,
    Set<UNfcPolling> polling = const <UNfcPolling>{UNfcPolling.a, UNfcPolling.b, UNfcPolling.f, UNfcPolling.v},
    bool skipNdef = false,
    bool sound = true,
    Duration? presenceCheck,
  }) async {
    _tagHandler = onTag;
    await UNfc._invoke<void>("startReader", <String, Object?>{
      "techs": polling.map((UNfcPolling p) => p.name).toList(),
      "skipNdef": skipNdef,
      "sound": sound,
      "presenceCheckMs": presenceCheck?.inMilliseconds,
    });
    _active = true;
  }

  /// Stops polling. `await UNfcReader.stop()`
  static Future<void> stop() async {
    _tagHandler = null;
    _active = false;
    if (UNfc.isPlatformSupported) await UNfc._invoke<void>("stopReader");
  }

  static bool get isActive => _active;

  /// Waits for one tag, runs [action] on it and stops. Returns null on [timeout].
  /// If the tag leaves the field mid-way, it keeps waiting for the next tap.
  /// `final String? id = await UNfcReader.readOnce((UNfcTag t) async => t.idHex);`
  static Future<T?> readOnce<T>(
    Future<T> Function(UNfcTag tag) action, {
    Duration timeout = const Duration(seconds: 30),
    Set<UNfcPolling> polling = const <UNfcPolling>{UNfcPolling.a, UNfcPolling.b, UNfcPolling.f, UNfcPolling.v},
    bool skipNdef = false,
  }) async {
    final Completer<T?> done = Completer<T?>();
    await start(
      polling: polling,
      skipNdef: skipNdef,
      onTag: (UNfcTag tag) async {
        if (done.isCompleted) return;
        try {
          final T value = await action(tag);
          if (!done.isCompleted) done.complete(value);
        } on UNfcException catch (e) {
          if (!e.isTagLost && !done.isCompleted) done.completeError(e);
        } catch (e, s) {
          if (!done.isCompleted) done.completeError(e, s);
        }
      },
    );
    try {
      return await done.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await stop();
    }
  }

  /// Reads a phone running [UNfcCard] (or any ISO-DEP card) by selecting [aid]. Returns the response, or null on timeout.
  /// `final String? track2 = (await UNfcReader.readAid("F041565245454E01"))?.text;`
  static Future<UNfcResponse?> readAid(String aid, {Duration timeout = const Duration(seconds: 30)}) => readOnce<UNfcResponse>(
    (UNfcTag tag) => tag.selectAid(aid),
    timeout: timeout,
    polling: const <UNfcPolling>{UNfcPolling.a, UNfcPolling.b},
    skipNdef: true,
  );

  /// Reads the NDEF message of one tag. Returns null on timeout. `final List<UNfcNdefRecord>? records = await UNfcReader.readNdef();`
  static Future<List<UNfcNdefRecord>?> readNdef({Duration timeout = const Duration(seconds: 30)}) =>
      readOnce<List<UNfcNdefRecord>>((UNfcTag tag) async => tag.ndef ?? await tag.readNdef() ?? <UNfcNdefRecord>[], timeout: timeout);

  /// Writes [records] to one tag. Returns false on timeout. `await UNfcReader.writeNdef(<UNfcNdefRecord>[UNfcNdefRecord.uri("https://sinamn75.com")])`
  static Future<bool> writeNdef(List<UNfcNdefRecord> records, {bool lock = false, Duration timeout = const Duration(seconds: 30)}) async =>
      await readOnce<bool>((UNfcTag tag) async {
        await tag.writeNdef(records, lock: lock);
        return true;
      }, timeout: timeout) ??
      false;

  static Future<void> _onTag(UNfcTag tag) async {
    try {
      await _tagHandler?.call(tag);
    } finally {
      await UNfc._channel.invokeMethod<void>("tagDone", <String, Object?>{"handle": tag._handle});
    }
  }
}

/// A tag/card/phone in the reader's field. Only valid inside [UNfcReader.start]'s `onTag`.
class UNfcTag {
  const UNfcTag._({
    required this._handle,
    required this.id,
    required this.techs,
    required this.ndef,
    required this.ndefWritable,
    required this.ndefMaxSize,
    required this.ndefFormatable,
    required this.historicalBytes,
  });

  factory UNfcTag._fromMap(Map<Object?, Object?> m) => UNfcTag._(
    handle: m["handle"]! as int,
    id: m["id"] as Uint8List? ?? Uint8List(0),
    techs: (m["techs"] as List<Object?>? ?? <Object?>[]).cast<String>(),
    ndef: (m["ndef"] as List<Object?>?)?.map((Object? r) => UNfcNdefRecord._fromMap(r! as Map<Object?, Object?>)).toList(),
    ndefWritable: m["ndefWritable"] == true,
    ndefMaxSize: m["ndefMaxSize"] as int? ?? 0,
    ndefFormatable: m["ndefFormatable"] == true,
    historicalBytes: m["historicalBytes"] as Uint8List?,
  );

  final int _handle;

  /// UID (random per tap for phones and many bank cards).
  final Uint8List id;

  /// Android tech names, e.g. ["IsoDep", "NfcA", "Ndef"].
  final List<String> techs;

  /// NDEF records read on discovery (null if none or `skipNdef`).
  final List<UNfcNdefRecord>? ndef;
  final bool ndefWritable;
  final int ndefMaxSize;
  final bool ndefFormatable;

  /// ISO-DEP historical bytes (type A) or higher-layer response (type B).
  final Uint8List? historicalBytes;

  String get idHex => UNfc.toHex(id);

  /// Speaks ISO 7816 APDUs: bank/ID cards and phones running [UNfcCard].
  bool get isIsoDep => techs.contains("IsoDep");

  bool get isNdef => techs.contains("Ndef") || ndefFormatable;

  /// Raw exchange with the tag. `final Uint8List raw = await tag.transceive(Uint8List.fromList(<int>[0x30, 0x04]), tech: UNfcTech.nfcA);`
  Future<Uint8List> transceive(Uint8List data, {UNfcTech tech = UNfcTech.isoDep, Duration? timeout}) async =>
      await UNfc._invoke<Uint8List>("transceive", <String, Object?>{
        "handle": _handle,
        "data": data,
        "tech": tech.name,
        "timeoutMs": timeout?.inMilliseconds,
      }) ??
      Uint8List(0);

  /// Sends an ISO 7816 APDU and splits the answer into data + status word. `await tag.send(UNfcApdu.build(cla: 0x80, ins: 0xCA))`
  Future<UNfcResponse> send(Uint8List apdu, {Duration? timeout}) async => UNfcResponse.parse(await transceive(apdu, timeout: timeout));

  /// SELECTs an application by AID (hex). `final UNfcResponse r = await tag.selectAid("F041565245454E01");`
  Future<UNfcResponse> selectAid(String aid, {Duration? timeout}) => send(UNfcApdu.select(aid), timeout: timeout);

  /// Reads the current NDEF message from the tag.
  Future<List<UNfcNdefRecord>?> readNdef() async {
    final List<Object?>? raw = await UNfc._invoke<List<Object?>>("readNdef", <String, Object?>{"handle": _handle});
    return raw?.map((Object? r) => UNfcNdefRecord._fromMap(r! as Map<Object?, Object?>)).toList();
  }

  /// Writes (formatting if needed) an NDEF message. [lock] makes the tag permanently read-only.
  Future<void> writeNdef(List<UNfcNdefRecord> records, {bool lock = false}) => UNfc._invoke<void>("writeNdef", <String, Object?>{
    "handle": _handle,
    "records": records.map((UNfcNdefRecord r) => r._toMap()).toList(),
    "lock": lock,
  });

  @override
  String toString() => "UNfcTag($idHex, $techs)";
}

// ================================================================================================ APDU

/// An ISO 7816 command APDU (received by [UNfcCard], or built to send with [UNfcTag.send]).
class UNfcApdu {
  UNfcApdu(this.bytes);

  /// `00 A4 04 00 Lc <AID> 00`
  static Uint8List select(String aid) {
    final Uint8List id = UNfc.fromHex(aid);
    return build(cla: 0x00, ins: 0xA4, p1: 0x04, data: id, le: 0);
  }

  /// Builds a short APDU. `UNfcApdu.build(cla: 0x80, ins: 0xCA, p1: 0x9F, p2: 0x7F, le: 0)`
  static Uint8List build({required int cla, required int ins, int p1 = 0, int p2 = 0, List<int>? data, int? le}) => Uint8List.fromList(<int>[
    cla,
    ins,
    p1,
    p2,
    if (data != null && data.isNotEmpty) ...<int>[data.length, ...data],
    ?le,
  ]);

  /// Response: [data] followed by 90 00. `return UNfcApdu.ok(utf8.encode("hi"));`
  static Uint8List ok([List<int> data = const <int>[]]) => Uint8List.fromList(<int>[...data, 0x90, 0x00]);

  /// Error response with status word [sw], e.g. 0x6A82 (not found), 0x6D00 (INS not supported), 0x6982 (security).
  static Uint8List error(int sw) => Uint8List.fromList(<int>[(sw >> 8) & 0xFF, sw & 0xFF]);

  final Uint8List bytes;

  int get cla => bytes.isNotEmpty ? bytes[0] : 0;

  int get ins => bytes.length > 1 ? bytes[1] : 0;

  int get p1 => bytes.length > 2 ? bytes[2] : 0;

  int get p2 => bytes.length > 3 ? bytes[3] : 0;

  /// Command data (short APDUs).
  Uint8List get data {
    if (bytes.length <= 5) return Uint8List(0);
    final int lc = bytes[4];
    return bytes.length >= 5 + lc ? Uint8List.sublistView(bytes, 5, 5 + lc) : Uint8List(0);
  }

  bool get isSelect => ins == 0xA4 && p1 == 0x04;

  /// The AID of a SELECT (uppercase hex), else null.
  String? get selectedAid => isSelect && data.isNotEmpty ? UNfc.toHex(data) : null;

  String get hex => UNfc.toHex(bytes);

  @override
  String toString() => "UNfcApdu($hex)";
}

/// An APDU response: data + SW1 SW2.
class UNfcResponse {
  const UNfcResponse({required this.data, required this.sw1, required this.sw2});

  factory UNfcResponse.parse(Uint8List raw) => raw.length < 2
      ? UNfcResponse(data: raw, sw1: 0x6F, sw2: 0x00)
      : UNfcResponse(data: Uint8List.sublistView(raw, 0, raw.length - 2), sw1: raw[raw.length - 2], sw2: raw[raw.length - 1]);

  final Uint8List data;
  final int sw1;
  final int sw2;

  /// Status word, e.g. 0x9000.
  int get sw => (sw1 << 8) | sw2;

  bool get isOk => sw == 0x9000;

  /// [data] decoded as UTF-8.
  String get text => utf8.decode(data, allowMalformed: true);

  String get hex => UNfc.toHex(data);

  String get swHex => sw.toRadixString(16).padLeft(4, "0").toUpperCase();

  @override
  String toString() => "UNfcResponse($swHex, $hex)";
}

// ================================================================================================ NDEF

/// One NDEF record (tags, stickers, business cards).
class UNfcNdefRecord {
  const UNfcNdefRecord({required this.tnf, required this.type, required this.payload, this.id});

  factory UNfcNdefRecord._fromMap(Map<Object?, Object?> m) => UNfcNdefRecord(
    tnf: m["tnf"] as int? ?? 0,
    type: m["type"] as Uint8List? ?? Uint8List(0),
    id: m["id"] as Uint8List?,
    payload: m["payload"] as Uint8List? ?? Uint8List(0),
  );

  /// Well-known text record. `UNfcNdefRecord.text("سلام", languageCode: "fa")`
  factory UNfcNdefRecord.text(String text, {String languageCode = "en"}) {
    final List<int> lang = ascii.encode(languageCode);
    return UNfcNdefRecord(tnf: tnfWellKnown, type: Uint8List.fromList(<int>[0x54]), payload: Uint8List.fromList(<int>[lang.length, ...lang, ...utf8.encode(text)]));
  }

  /// Well-known URI record (links, tel:, mailto:, geo:). `UNfcNdefRecord.uri("https://sinamn75.com")`
  factory UNfcNdefRecord.uri(String uri) {
    int code = 0;
    for (int i = 1; i < _uriPrefixes.length; i++) {
      if (uri.startsWith(_uriPrefixes[i]) && _uriPrefixes[i].length > _uriPrefixes[code].length) code = i;
    }
    return UNfcNdefRecord(
      tnf: tnfWellKnown,
      type: Uint8List.fromList(<int>[0x55]),
      payload: Uint8List.fromList(<int>[code, ...utf8.encode(uri.substring(_uriPrefixes[code].length))]),
    );
  }

  /// MIME record. `UNfcNdefRecord.mime("application/json", utf8.encode(jsonEncode(data)))`
  factory UNfcNdefRecord.mime(String mimeType, List<int> data) =>
      UNfcNdefRecord(tnf: tnfMime, type: Uint8List.fromList(ascii.encode(mimeType)), payload: Uint8List.fromList(data));

  /// Android Application Record: opens (or installs) [packageName] when tapped.
  factory UNfcNdefRecord.androidApp(String packageName) =>
      UNfcNdefRecord(tnf: tnfExternal, type: Uint8List.fromList(ascii.encode("android.com:pkg")), payload: Uint8List.fromList(ascii.encode(packageName)));

  static const int tnfEmpty = 0;
  static const int tnfWellKnown = 1;
  static const int tnfMime = 2;
  static const int tnfAbsoluteUri = 3;
  static const int tnfExternal = 4;

  final int tnf;
  final Uint8List type;
  final Uint8List? id;
  final Uint8List payload;

  String get typeString => ascii.decode(type, allowInvalid: true);

  /// Text of a well-known "T" record, else null.
  String? get text {
    if (tnf != tnfWellKnown || typeString != "T" || payload.isEmpty) return null;
    final int langLength = payload[0] & 0x3F;
    final bool utf16 = payload[0] & 0x80 != 0;
    final Uint8List body = Uint8List.sublistView(payload, 1 + langLength);
    return utf16 ? _decodeUtf16(body) : utf8.decode(body, allowMalformed: true);
  }

  // NDEF UTF-16 text is big-endian unless it starts with a little-endian BOM (FF FE).
  static String _decodeUtf16(Uint8List b) {
    final bool little = b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE;
    final int start = b.length >= 2 && ((b[0] == 0xFE && b[1] == 0xFF) || little) ? 2 : 0;
    final List<int> units = <int>[for (int i = start; i + 1 < b.length; i += 2) if (little) b[i] | (b[i + 1] << 8) else (b[i] << 8) | b[i + 1]];
    return String.fromCharCodes(units);
  }

  /// URI of a well-known "U" or absolute-URI record, else null.
  String? get uri {
    if (tnf == tnfAbsoluteUri) return utf8.decode(type, allowMalformed: true);
    if (tnf != tnfWellKnown || typeString != "U" || payload.isEmpty) return null;
    final int code = payload[0];
    return (code < _uriPrefixes.length ? _uriPrefixes[code] : "") + utf8.decode(payload.sublist(1), allowMalformed: true);
  }

  Map<String, Object?> _toMap() => <String, Object?>{"tnf": tnf, "type": type, "id": id ?? Uint8List(0), "payload": payload};

  @override
  String toString() => "UNfcNdefRecord(tnf: $tnf, type: $typeString, ${text ?? uri ?? "${payload.length} bytes"})";

  static const List<String> _uriPrefixes = <String>[
    "",
    "http://www.",
    "https://www.",
    "http://",
    "https://",
    "tel:",
    "mailto:",
    "ftp://anonymous:anonymous@",
    "ftp://ftp.",
    "ftps://",
    "sftp://",
    "smb://",
    "nfs://",
    "ftp://",
    "dav://",
    "news:",
    "telnet://",
    "imap:",
    "rtsp://",
    "urn:",
    "pop:",
    "sip:",
    "sips:",
    "tftp:",
    "btspp://",
    "btl2cap://",
    "btgoep://",
    "tcpobex://",
    "irdaobex://",
    "file://",
    "urn:epc:id:",
    "urn:epc:tag:",
    "urn:epc:pat:",
    "urn:epc:raw:",
    "urn:epc:",
    "urn:nfc:",
  ];
}
