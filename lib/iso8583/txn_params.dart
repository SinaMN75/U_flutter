import "dart:typed_data";

/// How the PAN reached the terminal, ISO field 22. Ported from
/// `EnPANEntryMode`.
enum EnPanEntryMode {
  manual("01"),
  magneticStripRead("02"),
  barCodeRead("03"),
  ocrCodingRead("04"),
  smartCard("05"),
  nfc("07"),
  merchantQr("78"),
  consumerQr("79"),
  fallback("80");

  const EnPanEntryMode(this.value);

  final String value;
}

/// What the card reader produced. Ported from `CardInfo`.
class CardInfo {
  CardInfo({this.entryMode, this.track2, this.panSequenceNumber, this.iccData});

  EnPanEntryMode? entryMode;
  String? track2;
  String? panSequenceNumber;
  Uint8List? iccData;

  String? get pan => track2?.split("=").first;
}

class HostTxnRequestParamBase {
  HostTxnRequestParamBase({this.receivingIin, this.localDateTime, this.location});

  String? receivingIin;
  DateTime? localDateTime;
  String? location;

  /// Terminal-side trace, ISO field 11. Filled in by the transaction.
  int pierTrace = 0;
}

class HostTxnResponseParamBase {
  int? rejectCode;
  String? responseCode;
  String? errorMessage;
  String? reasonCode;
  DateTime? serverDateTime;

  bool get isApproved => responseCode == "00";
}

class HostCardBaseRequestParam extends HostTxnRequestParamBase {
  HostCardBaseRequestParam({super.receivingIin, super.localDateTime, super.location, CardInfo? cardInfo, this.ePinBlock}) : cardInfo = cardInfo ?? CardInfo();

  CardInfo cardInfo;
  Uint8List? ePinBlock;
}

class HostCardBaseResponseParam extends HostTxnResponseParamBase {
  String? issuerName;
  String? rrn;
  String? approvalCode;
  String? maskPan;
}

/// A session key and its check value as the host sent them. Ported from
/// `ESessionKey`.
class ESessionKey {
  const ESessionKey(this.key, this.kvc);

  final Uint8List key;
  final Uint8List? kvc;
}

class LogonRequestParam extends HostTxnRequestParamBase {
  LogonRequestParam({super.receivingIin, super.localDateTime, super.location});
}

class LogonResponseParam extends HostTxnResponseParamBase {
  ESessionKey? mpk;
  ESessionKey? ppk;
  ESessionKey? dpk;
  String? terminalId;
  String? merchantId;
  String? centerTerminalId;
  String? merchantName;
  String? merchantPostalCode;
  String? merchantPhone;
  String? logonMacIndexKey;
  String? terminalSettings;
}

/// The balance kinds the host can report in ISO field 54. Ported from
/// `EnBalanceTypes`.
enum EnBalanceTypes {
  ledger("01"),
  available("02"),
  debit1("03"),
  debit2("04"),
  availableCredit("05"),
  creditLimit("09"),
  blocked("10"),
  service("41"),
  sayeDebit("43");

  const EnBalanceTypes(this.value);

  final String value;

  static EnBalanceTypes? fromValue(String value) {
    for (final EnBalanceTypes type in EnBalanceTypes.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// One 20-character group of ISO field 54. Ported from `AdditionalAmount`.
class AdditionalAmount {
  AdditionalAmount({required this.accountType, required this.balanceType, required this.currency, required this.amount});

  final String accountType;
  final EnBalanceTypes? balanceType;
  final int currency;

  /// Minor units as the host sent them, negative when the sign character is D.
  final int amount;
}

class HostBalanceRequestParam extends HostCardBaseRequestParam {
  HostBalanceRequestParam({super.receivingIin, super.localDateTime, super.location, super.cardInfo, super.ePinBlock});
}

class HostBalanceResponseParam extends HostCardBaseResponseParam {
  List<AdditionalAmount>? balance;
}
