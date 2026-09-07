import "package:u/utilities.dart";

enum UIsoErrorCode { cannotConnect, noResponse, badResponseMac, notLoggedOn, securityModuleFailed, badRequest }

class UIsoException implements Exception {
  UIsoException(this.code, this.message, [this.cause]);

  final UIsoErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Progress callbacks while a message is in flight. Optional.
abstract class IsoLinkEvents {
  void onWaitForReceive() {}

  void onReceiveTimeout() {}

  void onConnectionEvent(String event, Object? error) {}
}

/// What [UIso] needs before anything can be sent, the way [U] holds `baseUrl`
/// and `apiKey` for the REST client.
abstract class UIso {
  static late HostConfig config;
  static late HostContext context;
  static late IsoSecurityModule securityModule;

  /// Must keep counting across restarts; the host refuses a number it has
  /// already seen today.
  static late Future<int> Function() nextTraceNumber;

  static IsoTransport Function(HostConnectionInfo info) transportFactory = SocketIsoTransport.new;

  static IsoLink? _link;

  static IsoLink get link => _link ??= IsoLink(
    config: config,
    macComponent: MacComponent(config: config, securityModule: securityModule),
    transportFactory: transportFactory,
  );

  static bool get isLoggedOn => context.terminalLogicalInfo != null;

  /// The key slot the security module uses when it encrypts a PIN.
  static int get pinKeyIndex => config.sessionKeyIndexSetting.ppkIndex;

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

/// One secret key as the host sent it.
class IsoSessionKey {
  const IsoSessionKey(this.value, this.checkValue);

  final Uint8List value;
  final Uint8List? checkValue;
}
