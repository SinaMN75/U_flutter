import "dart:typed_data";

/// Key roles the host assigns during logon.
enum IsoKeyType { mpk, ppk, dpk, ktm }

/// Key length in bits, as the PED SDKs expect it.
enum IsoKeyLength {
  des(64),
  des3TwoKey(128),
  des3ThreeKey(192);

  const IsoKeyLength(this.bits);

  final int bits;

  static IsoKeyLength fromBits(int bits) => IsoKeyLength.values.firstWhere((IsoKeyLength value) => value.bits == bits, orElse: () => throw ArgumentError("invalid key length=$bits"));
}

enum IsoMacAlgorithm { iso9807, tripleDesCbc }

enum IsoCipherMode { ecb, cbc }

enum IsoEncryptionStandard { des, aes }

/// Which security-module call failed, so the caller can tell a cancelled PIN
/// entry apart from a real fault.
enum IsoSecurityOperation { generateMac, encryptData, decryptData, getKvc, getPinBlockFail, getPinBlockCancel, injectKey, storeSessionKey }

class IsoSecurityException implements Exception {
  IsoSecurityException(this.operation, this.message, [this.cause]);

  final IsoSecurityOperation operation;
  final String message;
  final Object? cause;

  @override
  String toString() => "IsoSecurityException($operation, $message${cause == null ? "" : ", cause: $cause"})";
}

/// What the PED reports while the cardholder is typing.
sealed class PinInputEvent {
  const PinInputEvent();
}

class PinDigitEntered extends PinInputEvent {
  const PinDigitEntered(this.length);

  final int length;
}

class PinConfirmed extends PinInputEvent {
  const PinConfirmed(this.pinBlock);

  final Uint8List pinBlock;
}

class PinCancelled extends PinInputEvent {
  const PinCancelled();
}

class PinTimedOut extends PinInputEvent {
  const PinTimedOut();
}

class PinFailed extends PinInputEvent {
  const PinFailed(this.errorCode);

  final int errorCode;
}

/// The terminal's PIN entry device. Keys live inside it and never reach Dart —
/// this package hands it bytes and takes back a MAC or an encrypted PIN block.
///
/// Ported from `ISecurityModuleService`.
abstract class IsoSecurityModule {
  String get name;

  Future<Uint8List> generateMac({
    required int keyIndex,
    required Uint8List data,
    required IsoMacAlgorithm algorithm,
    required int macLength,
    required bool useDefaultMac,
  });

  Future<Uint8List> encryptData({
    required int keyIndex,
    required Uint8List data,
    required IsoCipherMode cipherMode,
    required IsoEncryptionStandard standard,
    Uint8List? icv,
  });

  Future<Uint8List> decryptData({
    required int keyIndex,
    required Uint8List data,
    required IsoCipherMode cipherMode,
    required IsoEncryptionStandard standard,
    Uint8List? icv,
  });

  Future<void> injectKtm({
    required int ktmIndex,
    required Uint8List ktm,
    Uint8List? kvc,
    IsoKeyLength keyLength = IsoKeyLength.des3TwoKey,
  });

  Future<void> storeSessionKey({
    required int keyIndex,
    required int ktmIndex,
    required IsoKeyType keyType,
    required Uint8List sessionKey,
    Uint8List? kvc,
    IsoKeyLength keyLength = IsoKeyLength.des3TwoKey,
    bool useDefaultMac = false,
  });

  Future<Uint8List?> getKvc({required IsoKeyType keyType, required int keyIndex});

  /// Opens the PED for online PIN entry. The stream carries keypress feedback
  /// and ends with exactly one terminal event: confirmed, cancelled, timed out
  /// or failed.
  Stream<PinInputEvent> getPinBlock({
    required int ppkIndex,
    required String pan,
    required String hint,
    int min = 4,
    int max = 4,
    int timeoutMillis = 60000,
  });

  Future<void> close();
}
