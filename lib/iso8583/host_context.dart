import "dart:convert";

/// Terminal and merchant identity as the host reported it at logon. Ported from
/// `TerminalLogicalInfo`.
class TerminalLogicalInfo {
  TerminalLogicalInfo({
    required this.terminalId,
    required this.merchantId,
    this.centerTerminalId,
    this.merchantName,
    this.merchantPostalCode,
    this.merchantPhone,
  });

  factory TerminalLogicalInfo.fromJson(Map<String, dynamic> json) => TerminalLogicalInfo(
    terminalId: json["terminalId"] as String,
    merchantId: json["merchantId"] as String,
    centerTerminalId: json["centerTerminalId"] as String?,
    merchantName: json["merchantName"] as String?,
    merchantPostalCode: json["merchantPostalCode"] as String?,
    merchantPhone: json["merchantPhone"] as String?,
  );

  final String terminalId;
  final String merchantId;

  String? centerTerminalId;
  String? merchantName;
  String? merchantPostalCode;
  String? merchantPhone;

  Map<String, dynamic> toJson() => <String, dynamic>{
    "terminalId": terminalId,
    "merchantId": merchantId,
    if (centerTerminalId != null) "centerTerminalId": centerTerminalId,
    if (merchantName != null) "merchantName": merchantName,
    if (merchantPostalCode != null) "merchantPostalCode": merchantPostalCode,
    if (merchantPhone != null) "merchantPhone": merchantPhone,
  };
}

/// Hardware identity of this terminal, sent as TLV tags C0 and D0.
class TerminalDeviceInfo {
  const TerminalDeviceInfo({this.serialNumber, this.simSerial});

  final String? serialNumber;
  final String? simSerial;
}

/// Where the context is persisted between runs. The app supplies this — the
/// package does no file or preference access of its own.
abstract class HostStateStore {
  Future<String?> read();

  Future<void> write(String state);
}

/// Mutable state that survives a transaction: which keys are loaded, who the
/// terminal is, what the host called it. Ported from `HostContext`.
class HostContext {
  HostContext({this.deviceInfo = const TerminalDeviceInfo(), this.stateStore});

  bool injectKtm = false;
  bool injectSessionKeys = false;
  String? logonMacIndexKey;
  String? ktmGroup;
  TerminalLogicalInfo? terminalLogicalInfo;
  TerminalDeviceInfo deviceInfo;
  HostStateStore? stateStore;

  Map<String, dynamic> toJson() => <String, dynamic>{
    "injectKTM": injectKtm,
    "injectSessionKeys": injectSessionKeys,
    if (logonMacIndexKey != null) "logonMacIndexKey": logonMacIndexKey,
    if (ktmGroup != null) "ktmGroup": ktmGroup,
    if (terminalLogicalInfo != null) "terminalLogicalInfo": terminalLogicalInfo!.toJson(),
  };

  void applyJson(Map<String, dynamic> json) {
    injectKtm = json["injectKTM"] as bool? ?? false;
    injectSessionKeys = json["injectSessionKeys"] as bool? ?? false;
    logonMacIndexKey = json["logonMacIndexKey"] as String?;
    ktmGroup = json["ktmGroup"] as String?;
    final Object? terminal = json["terminalLogicalInfo"];
    terminalLogicalInfo = terminal == null ? null : TerminalLogicalInfo.fromJson(terminal as Map<String, dynamic>);
  }

  Future<void> save() async {
    final HostStateStore? store = stateStore;
    if (store == null) return;
    await store.write(jsonEncode(toJson()));
  }

  Future<void> load() async {
    final HostStateStore? store = stateStore;
    if (store == null) return;
    final String? raw = await store.read();
    if (raw == null || raw.isEmpty) return;
    applyJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
