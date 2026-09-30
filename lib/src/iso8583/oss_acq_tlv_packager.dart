import "package:u/utilities.dart";

/// The tag dictionary for ISO field 63 and the pack/unpack entry points.
///
/// Groups are merged in the same order as the Java static block, which matters:
/// [StatementKeyTags] and [CisKeyTags] share root E1 and the later merge wins.
abstract class OssAcqTlvPackager {
  static const int defaultCapacity = 999;

  static final Map<String, ValuePackager> allTags = <String, ValuePackager>{
    ...PrimitiveTags.tagFormatMap,
    ...SessionKeyTags.tagFormatMap,
    ...VasKeyTags.tagFormatMap,
    ...OrderKeyTags.tagFormatMap,
    ...AcceptorKeyTags.tagFormatMap,
    ...CisKeyTags.tagFormatMap,
    ...ReportSaleTags.tagFormatMap,
    ...ServiceKeyTags.tagFormatMap,
    ...LoanKeyTags.tagFormatMap,
    ...CardHolderAccountInfoTags.tagFormatMap,
    ...StatementKeyTags.tagFormatMap,
    ...OfflineOrTmsTxnKeyTags.tagFormatMap,
  };

  static TlvList unpackToTlvMessage(Uint8List bytes) {
    final TlvList list = TlvList()..unpackBytes(bytes);
    list.unpackValues(allTags);
    return list;
  }

  static Uint8List packToTlvMessage(TlvList list, [int capacity = defaultCapacity]) {
    list.packValues(allTags);
    return list.pack(capacity);
  }
}
