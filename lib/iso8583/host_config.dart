import "package:u/utilities.dart";

/// PED slots holding the terminal master key and the key that MACs an init
/// logon. Ported from `TerminalInitKeySetting`.
class TerminalInitKeySetting {
  const TerminalInitKeySetting({required this.ktmIndex, required this.mpkIndex});

  factory TerminalInitKeySetting.fromJson(Map<String, dynamic> json) => TerminalInitKeySetting(ktmIndex: json["KTMIndex"] as int, mpkIndex: json["MPKIndex"] as int);

  final int ktmIndex;
  final int mpkIndex;

  Map<String, dynamic> toJson() => <String, dynamic>{"KTMIndex": ktmIndex, "MPKIndex": mpkIndex};
}

/// PED slots the session keys returned by logon are written into. Ported from
/// `TerminalSessionKeyIndexSetting`.
class TerminalSessionKeyIndexSetting {
  const TerminalSessionKeyIndexSetting({required this.mpkIndex, required this.ppkIndex, required this.dpkIndex});

  factory TerminalSessionKeyIndexSetting.fromJson(Map<String, dynamic> json) =>
      TerminalSessionKeyIndexSetting(mpkIndex: json["MPKIndex"] as int, ppkIndex: json["PPKIndex"] as int, dpkIndex: json["DPKIndex"] as int);

  final int mpkIndex;
  final int ppkIndex;
  final int dpkIndex;

  Map<String, dynamic> toJson() => <String, dynamic>{"MPKIndex": mpkIndex, "PPKIndex": ppkIndex, "DPKIndex": dpkIndex};
}

class HostConfigException implements Exception {
  HostConfigException(this.message);

  final String message;

  @override
  String toString() => "HostConfigException($message)";
}

/// Everything about this terminal's relationship with the acquirer that does
/// not change per transaction. Ported from `HostConfig`.
class HostConfig {
  HostConfig({
    required this.nii,
    required this.bin,
    required this.version,
    required this.initKeySetting,
    required this.sessionKeyIndexSetting,
    required this.allConnectionInfo,
    this.activeConnectionType,
    this.sourceId = "1122",
    this.destinationId = "3344",
    this.defaultTxnTimeoutSeconds = 10,
  });

  /// The Apos_android asset stores `nii` and `bin` as JSON numbers, and
  /// carries no `version`, so every scalar is read leniently.
  factory HostConfig.fromJson(Map<String, dynamic> json) => HostConfig(
    nii: json["nii"]?.toString() ?? "",
    bin: json["bin"]?.toString() ?? "",
    version: json["version"]?.toString() ?? "1.0.0",
    initKeySetting: TerminalInitKeySetting.fromJson(json["initKeySetting"] as Map<String, dynamic>),
    sessionKeyIndexSetting: TerminalSessionKeyIndexSetting.fromJson(json["sessionKeyIndexSetting"] as Map<String, dynamic>),
    allConnectionInfo: (json["allConnectionInfo"] as Map<String, dynamic>).map(
      (String key, dynamic value) => MapEntry<String, HostConnectionInfo>(key, HostConnectionInfo.fromJson(value as Map<String, dynamic>)),
    ),
    activeConnectionType: json["activeConnectionType"] as String?,
    sourceId: json["sourceId"]?.toString() ?? "1122",
    destinationId: json["destinationId"]?.toString() ?? "3344",
    defaultTxnTimeoutSeconds: json["defaultTxnTimeout"] as int? ?? 10,
  );

  /// Network international identifier, ISO field 24.
  final String nii;

  /// Acquiring institution id, ISO field 32.
  final String bin;

  /// Application version, sent as TLV tag C1.
  final String version;

  final TerminalInitKeySetting initKeySetting;
  final TerminalSessionKeyIndexSetting sessionKeyIndexSetting;
  final Map<String, HostConnectionInfo> allConnectionInfo;

  /// Link header source and destination, four BCD digits each.
  final String sourceId;
  final String destinationId;

  final int defaultTxnTimeoutSeconds;

  String? activeConnectionType;

  void checkInit() {
    if (allConnectionInfo.isEmpty) throw HostConfigException("no connection info configured");
  }

  HostConnectionInfo activeConnectionInfo() {
    checkInit();
    final HostConnectionInfo? selected = allConnectionInfo[activeConnectionType];
    if (selected != null && selected.hostIp.isNotEmpty) return selected;
    if (selected != null) throw HostConfigException("connection '$activeConnectionType' has no host address");
    activeConnectionType = allConnectionInfo.keys.first;
    return allConnectionInfo[activeConnectionType]!;
  }

  HostConnectionInfo? fetchTmsHostConnection() => activeConnectionInfo().tms;

  HostConnectionInfo? fetchApnHostConnection() {
    for (final HostConnectionInfo info in allConnectionInfo.values) {
      if (info.apn ?? false) return info;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    "nii": nii,
    "bin": bin,
    "version": version,
    "sourceId": sourceId,
    "destinationId": destinationId,
    "defaultTxnTimeout": defaultTxnTimeoutSeconds,
    if (activeConnectionType != null) "activeConnectionType": activeConnectionType,
    "initKeySetting": initKeySetting.toJson(),
    "sessionKeyIndexSetting": sessionKeyIndexSetting.toJson(),
    "allConnectionInfo": allConnectionInfo.map((String key, HostConnectionInfo value) => MapEntry<String, dynamic>(key, value.toJson())),
  };
}
