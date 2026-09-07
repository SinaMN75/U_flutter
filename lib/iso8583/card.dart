import "package:u/utilities.dart";

/// How the card was read. The value goes into ISO field 22 as-is.
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

/// What the card reader produced.
class CardInfo {
  const CardInfo({required this.track2, this.entryMode = EnPanEntryMode.magneticStripRead, this.panSequenceNumber, this.iccData});

  /// The raw track 2: card number, `=`, then expiry and issuer data.
  final String track2;
  final EnPanEntryMode entryMode;
  final String? panSequenceNumber;
  final Uint8List? iccData;

  String get pan => track2.split("=").first;

  String get maskedPan => PanUtil.maskPan(track2, panSequenceNumber) ?? "";

  /// The ISO fields a card-present message carries. Field 22 is the entry mode
  /// plus one digit: `1` when a PIN was entered, `2` when it was not.
  Map<int, Object?> toFields({Uint8List? pinBlock}) => <int, Object?>{
    22: "${entryMode.value}${pinBlock == null ? "2" : "1"}",
    35: track2,
    23: ?panSequenceNumber,
    if (iccData != null) 55: IsoUtil.hexString(iccData!),
    52: ?pinBlock,
  };
}
