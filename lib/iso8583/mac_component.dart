import "package:u/utilities.dart";

/// Builds the MAC over the selected fields and writes it into field 64.
///
/// Ported from `MACComponent`. The field list, the pack/unpack round trip that
/// normalises each value, and the "init logon uses the default MAC key" rule
/// are all reproduced exactly — a single byte out of place and the host rejects
/// the message.
class MacComponent {
  MacComponent({required this.config, required this.securityModule});

  static const List<int> selectedFields = <int>[2, 3, 4, 6, 7, 10, 11, 12, 13, 15, 17, 22, 25, 32, 33, 37, 39, 41, 42, 48, 49, 51, 60];

  final HostConfig config;
  final IsoSecurityModule securityModule;

  final OssAcqPackager _packager = OssAcqPackager();

  /// Packs the selected fields, unpacks them again, then concatenates the
  /// normalised values. The round trip is what makes the terminal and the host
  /// agree on padding.
  Uint8List buildMacData(IsoMsg message) {
    final IsoMsg applied = IsoMsg();
    for (final int field in selectedFields) {
      final IsoComponent<Object>? component = message.getComponent(field);
      if (component != null) applied.setComponent(field, component);
    }
    applied.setComponent(0, message.getComponent(0));
    applied.markDirty();
    applied.recalcBitMap();

    final IsoBuffer buffer = IsoBuffer.allocate(9999);
    _packager.pack(applied, buffer);
    buffer.flip();
    _packager.unpack(applied, buffer);
    applied.setComponent(0, message.getComponent(0));

    final List<int> out = <int>[];
    for (final int field in selectedFields) {
      final IsoComponent<Object>? component = applied.getComponent(field);
      if (component == null) continue;
      final Object? value = component.value;
      if (value is Uint8List) {
        out.addAll(value);
      } else if (value is String) {
        out.addAll(value.codeUnits.map((int unit) => unit & 0xFF));
      }
    }
    return Uint8List.fromList(out);
  }

  /// Init logon (0800/0810 with processing code 920000 or 920001) is MACed with
  /// the key derived from the KTM; everything else uses the session MAC key.
  bool usesDefaultMac(IsoMsg message) {
    final String? mti = message.hasField(0) ? message.mti : null;
    if (mti != "0800" && mti != "0810") return false;
    final String? processingCode = message.getString(3);
    return processingCode == "920000" || processingCode == "920001";
  }

  Future<Uint8List> _generate(IsoMsg message, int macLength) async {
    message.markDirty();
    message.recalcBitMap();
    final Uint8List data = buildMacData(message);
    final bool useDefaultMac = usesDefaultMac(message);
    final int keyIndex = useDefaultMac ? config.initKeySetting.mpkIndex : config.sessionKeyIndexSetting.mpkIndex;
    final Uint8List mac = await securityModule.generateMac(
      keyIndex: keyIndex,
      data: data,
      algorithm: IsoMacAlgorithm.iso9807,
      macLength: macLength,
      useDefaultMac: useDefaultMac,
    );
    return mac.length > macLength ? Uint8List.sublistView(mac, 0, macLength) : mac;
  }

  Future<void> generateMac(IsoMsg message, int macLength) async {
    final int macField = message.maxField > 64 ? 128 : 64;
    message.setBytes(macField, await _generate(message, macLength));
    message.markDirty();
    message.recalcBitMap();
  }

  /// Recomputes the MAC over the response and compares. The MAC field is
  /// removed only when it matched, as in the Java, so a failed check leaves the
  /// message untouched for logging.
  Future<bool> checkMac(IsoMsg message, int macLength) async {
    final Uint8List expected = await _generate(message, macLength);
    final int macField = message.maxField > 64 ? 128 : 64;
    final Uint8List? received = message.getBytes(macField);
    if (received == null || received.length != expected.length) return false;
    for (int i = 0; i < expected.length; i++) {
      if (received[i] != expected[i]) return false;
    }
    message.unset(macField);
    return true;
  }
}
