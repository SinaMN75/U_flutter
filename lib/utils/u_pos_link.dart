import "package:u/utilities.dart";

export "package:u/src/pos_link/u_pos_link_session.dart" show UPosLinkProtocol, UPosLinkSession, UPosLinkMessage, UPosLinkAuthException;

enum UPosLinkStatus { notPaired, disconnected, connecting, connected }

/// Why a UPosLink call failed; [UPosLinkException.message] is the localized text to show.
enum UPosLinkError { invalidCode, notPaired, notFound, rejected, authFailed, bluetoothOff, unauthorized, unsupported, disconnected, timeout }

class UPosLinkException implements Exception {
  const UPosLinkException(this.error, [this.detail]);

  final UPosLinkError error;
  final String? detail;

  String get message => switch (error) {
    UPosLinkError.invalidCode => U.s.theCardReaderCodeIsNotValid,
    UPosLinkError.notPaired => U.s.pairACardReaderFirst,
    UPosLinkError.notFound => U.s.cardReaderNotFoundNearby,
    UPosLinkError.rejected => U.s.theCardReaderRejectedThisPhonePairAgain,
    UPosLinkError.authFailed => U.s.secureConnectionToTheCardReaderFailed,
    UPosLinkError.bluetoothOff => U.s.bluetoothIsOff,
    UPosLinkError.unauthorized => U.s.bluetoothPermissionWasDenied,
    UPosLinkError.unsupported => U.s.bluetoothIsNotSupportedOnThisDevice,
    UPosLinkError.disconnected => U.s.theCardReaderDisconnected,
    UPosLinkError.timeout => U.s.theCardReaderDidNotRespond,
  };

  @override
  String toString() => "UPosLinkException(${error.name}${detail == null ? "" : ", $detail"})";
}

/// One account from a balance inquiry (`accountInfoList`).
class UPosAccount {
  const UPosAccount({this.id, this.title, this.balance, this.type});

  factory UPosAccount.fromMap(Map<String, dynamic> map) => UPosAccount(
    id: map["accountId"]?.toString(),
    title: map["accountTitle"]?.toString(),
    balance: map["balance"] is num ? map["balance"] as num : num.tryParse(map["balance"]?.toString() ?? ""),
    type: map["accountType"]?.toString() ?? map["accountTypeCode"]?.toString(),
  );

  final String? id;
  final String? title;
  final num? balance;
  final String? type;
}

/// The terminal's reply to a PC-POS command; [raw] holds every field it sent.
class UPosResult {
  const UPosResult(this.raw);

  final Map<String, dynamic> raw;

  String? get errorCode => raw["errorCode"]?.toString();

  String? get errorMessage => raw["errorMessage"]?.toString();

  /// "00" when the bank approved a card transaction; null for commands without a bank response.
  String? get responseCode => raw["responseCode"]?.toString();

  String? get rrn => raw["rrn"]?.toString();

  String? get cardNumber => raw["cardNumber"]?.toString();

  /// True when the terminal reported no error and the bank (if asked) approved.
  bool get isApproved => errorCode == null && (responseCode == null || responseCode == "00");

  /// The terminal refused because another transaction is running.
  bool get isBusy => errorCode == "429";

  List<UPosAccount> get accounts =>
      ((raw["accountInfoList"] as List<dynamic>?) ?? const <dynamic>[]).whereType<Map<dynamic, dynamic>>().map((Map<dynamic, dynamic> e) => UPosAccount.fromMap(e.cast<String, dynamic>())).toList();

  Map<String, dynamic> get deviceInfo => ((raw["deviceInfo"] as Map<dynamic, dynamic>?) ?? const <dynamic, dynamic>{}).cast<String, dynamic>();
}

class _UPosLinkPairing {
  const _UPosLinkPairing({required this.keyId, required this.key, required this.tag, this.name = ""});

  factory _UPosLinkPairing.fromJson(Map<String, dynamic> json) => _UPosLinkPairing(
    keyId: UEncryption.hexToBytes(json["keyId"] as String),
    key: base64.decode(json["key"] as String),
    tag: UEncryption.hexToBytes(json["tag"] as String),
    name: json["name"]?.toString() ?? "",
  );

  final List<int> keyId;
  final List<int> key;
  final List<int> tag;
  final String name;

  _UPosLinkPairing copyWith({List<int>? key, String? name}) => _UPosLinkPairing(keyId: keyId, key: key ?? this.key, tag: tag, name: name ?? this.name);

  Map<String, dynamic> toJson() => <String, dynamic>{"keyId": UEncryption.hexEncode(keyId), "key": base64.encode(key), "tag": UEncryption.hexEncode(tag), "name": name};
}

/// Encrypted Bluetooth LE link to a payment terminal that speaks PC-POS JSON (`{"rt": "/sale", ...}`),
/// the same commands a PC sends over HTTP or a COM port. Pair once by scanning the terminal's QR code;
/// after that [connect] finds the terminal by itself, on every platform UBle supports.
/// ```dart
/// await UPosLink.init();
/// await UPosLink.pair(scannedCode);              // once
/// final UPosResult r = await UPosLink.sale(250000); // rial
/// if (r.isApproved) print(r.rrn);
/// ```
abstract final class UPosLink {
  static const String _storageKey = "u_pos_link";

  /// Pairing, connection and terminal name; rebuilds UObx.
  static final URx<UPosLinkStatus> status = URx<UPosLinkStatus>(UPosLinkStatus.notPaired);

  /// Shown on the terminal's list of paired devices; defaults to the device name.
  static String clientName = "";

  static _UPosLinkPairing? _pairing;
  static UBleConnection? _connection;
  static UPosLinkSession? _session;
  static Future<void>? _connecting;
  static final Map<int, Completer<Map<String, dynamic>>> _pending = <int, Completer<Map<String, dynamic>>>{};
  static int _number = 0;

  static bool get isPaired => _pairing != null;

  /// Terminal name from the pairing code (its Bluetooth name).
  static String get terminalName => _pairing?.name ?? "";

  /// Loads the saved pairing. `initU()` does not call it; call it once before use.
  static Future<void> init() async {
    final String? saved = UStorage.secure.get<String>(_storageKey);
    _pairing = saved == null ? null : _UPosLinkPairing.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    if (_session == null) status(_pairing == null ? UPosLinkStatus.notPaired : UPosLinkStatus.disconnected);
  }

  /// True when [code] looks like a terminal pairing code (`poslink://pair?...`).
  static bool isPairingCode(String code) => _parse(code) != null;

  /// Saves the pairing from the terminal's QR code and connects (the terminal only accepts a code once, for 3 minutes).
  static Future<void> pair(String code) async {
    final _UPosLinkPairing pairing = _parse(code) ?? (throw const UPosLinkException(UPosLinkError.invalidCode));
    await disconnect();
    await _save(pairing);
    await connect();
  }

  static _UPosLinkPairing? _parse(String code) {
    final Uri? uri = Uri.tryParse(code.trim());
    if (uri == null || uri.scheme != UPosLinkProtocol.qrScheme || uri.host != "pair") return null;
    try {
      final List<int> keyId = UEncryption.hexToBytes(uri.queryParameters["i"] ?? "");
      final List<int> key = base64Url.decode(base64Url.normalize(uri.queryParameters["k"] ?? ""));
      final List<int> tag = UEncryption.hexToBytes(uri.queryParameters["t"] ?? "");
      if (keyId.length != UPosLinkProtocol.keyIdSize || key.length != UPosLinkProtocol.keySize || tag.length != UPosLinkProtocol.tagSize) return null;
      return _UPosLinkPairing(keyId: keyId, key: key, tag: tag, name: uri.queryParameters["n"] ?? "");
    } catch (_) {
      return null;
    }
  }

  /// Finds the paired terminal and opens the secure link; does nothing when already connected.
  /// Web: may open the browser's device chooser, so call it from a tap.
  static Future<void> connect() => _connecting ??= _connect().whenComplete(() => _connecting = null);

  static Future<void> _connect() async {
    if (_session != null && !_session!.isClosed) return;
    final _UPosLinkPairing pairing = _pairing ?? (throw const UPosLinkException(UPosLinkError.notPaired));
    status(UPosLinkStatus.connecting);
    try {
      await _ensureBluetooth();
      Object? lastError;
      for (final UBleDevice device in await _candidates(pairing)) {
        try {
          return await _open(device, pairing);
        } on UPosLinkException catch (e) {
          if (e.error == UPosLinkError.rejected) rethrow;
          lastError = e;
        } catch (e) {
          lastError = e;
        }
      }
      throw lastError is UPosLinkException ? lastError : UPosLinkException(UPosLinkError.notFound, lastError?.toString());
    } catch (_) {
      status(_pairing == null ? UPosLinkStatus.notPaired : UPosLinkStatus.disconnected);
      rethrow;
    }
  }

  static Future<void> _ensureBluetooth() async {
    final UBleState state = await UBle.requestPermission();
    switch (state) {
      case UBleState.unsupported:
        throw const UPosLinkException(UPosLinkError.unsupported);
      case UBleState.unauthorized:
        throw const UPosLinkException(UPosLinkError.unauthorized);
      case UBleState.poweredOff:
        throw const UPosLinkException(UPosLinkError.bluetoothOff);
      case UBleState.poweredOn:
      case UBleState.unknown:
        return;
    }
  }

  static Future<List<UBleDevice>> _candidates(_UPosLinkPairing pairing) async {
    final List<UBleDevice> remembered = await UBle.rememberedDevices();
    if (remembered.isNotEmpty) return <UBleDevice>[...remembered, ...await _scan(pairing)];
    return _scan(pairing);
  }

  static Future<List<UBleDevice>> _scan(_UPosLinkPairing pairing) async {
    try {
      final UBleDevice device = await UBle.scan(
        services: const <String>[UPosLinkProtocol.serviceUuid],
        timeout: const Duration(seconds: 12),
        manufacturerId: UPosLinkProtocol.manufacturerId,
        manufacturerDataPrefix: pairing.tag,
      ).first;
      return <UBleDevice>[device];
    } on StateError {
      throw const UPosLinkException(UPosLinkError.notFound);
    } on UBleException catch (e) {
      throw _fromBle(e);
    }
  }

  static Future<void> _open(UBleDevice device, _UPosLinkPairing pairing) async {
    final UBleConnection connection;
    try {
      connection = await UBle.connect(device.id);
    } on UBleException catch (e) {
      throw _fromBle(e);
    }
    final UPosLinkSession session = UPosLinkSession(
      write: (Uint8List bytes) => connection.write(UPosLinkProtocol.serviceUuid, UPosLinkProtocol.rxUuid, bytes),
      chunkSize: connection.maxWriteLength,
    );
    unawaited(connection.disconnected.then((_) => session.close(const UPosLinkException(UPosLinkError.disconnected))));
    try {
      (await connection.subscribe(UPosLinkProtocol.serviceUuid, UPosLinkProtocol.txUuid)).listen(session.receive);
      final Future<UPosLinkMessage> welcome = session.messages.first;
      final Uint8List nextKey = await session.handshake(pairing.keyId, pairing.key).timeout(const Duration(seconds: 15));
      final UPosLinkMessage message = await welcome.timeout(const Duration(seconds: 10));
      if (message.type != UPosLinkProtocol.welcome) throw const UPosLinkException(UPosLinkError.authFailed);
      final Map<String, dynamic> info = jsonDecode(utf8.decode(message.body)) as Map<String, dynamic>;
      await _save(pairing.copyWith(key: info["rotated"] == true ? nextKey : null, name: info["name"]?.toString()));
      await session.send(UPosLinkProtocol.clientInfo, 0, utf8.encode(_clientLabel()));
    } on UPosLinkAuthException catch (e) {
      await connection.disconnect();
      throw UPosLinkException(e.reason == "rejected" ? UPosLinkError.rejected : UPosLinkError.authFailed, e.reason);
    } on TimeoutException {
      await connection.disconnect();
      throw const UPosLinkException(UPosLinkError.timeout);
    } catch (e) {
      await connection.disconnect();
      throw e is UPosLinkException ? e : UPosLinkException(UPosLinkError.disconnected, e.toString());
    }
    _connection = connection;
    _session = session;
    session.messages.listen(
      (UPosLinkMessage m) {
        if (m.type == UPosLinkProtocol.response) _pending.remove(m.number)?.complete((jsonDecode(utf8.decode(m.body)) as Map<dynamic, dynamic>).cast<String, dynamic>());
      },
      onError: (_) {},
      onDone: () => _onClosed(session),
    );
    status(UPosLinkStatus.connected);
  }

  static void _onClosed(UPosLinkSession session) {
    if (_session != session) return;
    _session = null;
    _connection = null;
    for (final Completer<Map<String, dynamic>> c in _pending.values) {
      c.completeError(const UPosLinkException(UPosLinkError.disconnected));
    }
    _pending.clear();
    status(_pairing == null ? UPosLinkStatus.notPaired : UPosLinkStatus.disconnected);
  }

  static String _clientLabel() {
    if (clientName.isNotEmpty) return clientName;
    if (UDevice.isReady && UDevice.name.isNotEmpty) return UDevice.name;
    return defaultTargetPlatform.name;
  }

  static Future<void> _save(_UPosLinkPairing pairing) async {
    _pairing = pairing;
    await UStorage.secure.set(_storageKey, jsonEncode(pairing.toJson()));
  }

  static UPosLinkException _fromBle(UBleException e) => switch (e.error) {
    UBleError.unsupported => const UPosLinkException(UPosLinkError.unsupported),
    UBleError.unauthorized => const UPosLinkException(UPosLinkError.unauthorized),
    UBleError.poweredOff => const UPosLinkException(UPosLinkError.bluetoothOff),
    UBleError.timeout => const UPosLinkException(UPosLinkError.timeout),
    UBleError.notFound || UBleError.cancelled => const UPosLinkException(UPosLinkError.notFound),
    _ => UPosLinkException(UPosLinkError.disconnected, e.message),
  };

  static Future<void> disconnect() async {
    final UBleConnection? connection = _connection;
    _session?.close();
    if (connection != null) await connection.disconnect();
  }

  /// Removes the pairing from this device (remove it on the terminal too).
  static Future<void> forget() async {
    await disconnect();
    _pairing = null;
    await UStorage.secure.remove(_storageKey);
    status(UPosLinkStatus.notPaired);
  }

  /// Sends any PC-POS command and returns the terminal's JSON. Connects first when needed.
  /// [timeout] covers the customer's time at the terminal (card, PIN).
  static Future<Map<String, dynamic>> send(Map<String, dynamic> request, {Duration timeout = const Duration(minutes: 3)}) async {
    await connect();
    final UPosLinkSession session = _session ?? (throw const UPosLinkException(UPosLinkError.disconnected));
    final int number = ++_number;
    final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();
    _pending[number] = completer;
    try {
      await session.send(UPosLinkProtocol.request, number, utf8.encode(jsonEncode(request)));
    } catch (_) {
      _pending.remove(number);
      throw const UPosLinkException(UPosLinkError.disconnected);
    }
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(number);
        throw const UPosLinkException(UPosLinkError.timeout);
      },
    );
  }

  static Future<UPosResult> _command(Map<String, dynamic> request, {Duration timeout = const Duration(minutes: 3)}) async => UPosResult(await send(request, timeout: timeout));

  /// Card purchase of [amount] rial. With [needConfirm] the terminal waits [confirmDuration] seconds for [confirm].
  static Future<UPosResult> sale(int amount, {bool needConfirm = false, int confirmDuration = 60, bool autoCustomerPrint = false}) => _command(<String, dynamic>{
    "rt": "/sale",
    "amount": amount,
    "needConfirm": needConfirm,
    "confirmDuration": confirmDuration,
    "autoCustomerPrint": autoCustomerPrint,
  });

  /// Balance inquiry (`/balancecredit`); the balances are in [UPosResult.accounts].
  static Future<UPosResult> balance({bool requirePin = false, bool showReceipt = false}) => _command(<String, dynamic>{"rt": "/balancecredit", "requirePin": requirePin, "showReceipt": showReceipt});

  static Future<UPosResult> confirm() => _command(<String, dynamic>{"rt": "/confirm"}, timeout: const Duration(seconds: 30));

  /// Cancels what the terminal is doing (allowed while another command is running).
  static Future<UPosResult> cancel() => _command(<String, dynamic>{"rt": "/cancel"}, timeout: const Duration(seconds: 30));

  static Future<UPosResult> voidSale(String refundKey, {bool autoCustomerPrint = false}) => _command(<String, dynamic>{"rt": "/void", "refundKey": refundKey, "autoCustomerPrint": autoCustomerPrint});

  static Future<UPosResult> refund(String refundKey, int amount, {bool autoCustomerPrint = false}) =>
      _command(<String, dynamic>{"rt": "/refund", "refundKey": refundKey, "amount": amount, "autoCustomerPrint": autoCustomerPrint});

  static Future<UPosResult> deviceInfo() => _command(<String, dynamic>{"rt": "/deviceinfo"}, timeout: const Duration(seconds: 30));
}
