import "package:u/utilities.dart";

/// Turns a message into the bytes that go on the wire and back.
///
/// The frame is `LEN(2) || HEADER(19) || BODY`, where LEN counts the header and
/// body but not itself. `HEXMessageLenCodec(2)` in the Java hex-encodes the
/// length and converts it back to bytes, which is a plain two-byte big-endian
/// integer.
class OssFrameCodec {
  OssFrameCodec(this.packager, {this.maxMessageSize = 9999});

  static const int lengthBytes = 2;
  static const int headerLength = OssAcqHeader.length;

  final IsoMsgPackager packager;
  final int maxMessageSize;

  Uint8List encode(IsoMsg message) {
    final Uint8List? header = message.isoHeader;
    if (header == null) throw StateError("message has no link header");
    if (header.length != headerLength) throw StateError("link header must be $headerLength bytes, got ${header.length}");

    message.recalcBitMap();
    final IsoBuffer body = IsoBuffer.allocate(maxMessageSize);
    packager.pack(message, body);
    final Uint8List bodyBytes = body.toBytes();

    final int totalLength = bodyBytes.length + header.length;
    if (totalLength > 0xFFFF) throw StateError("message too long: $totalLength");

    final Uint8List frame = Uint8List(lengthBytes + totalLength);
    frame[0] = totalLength >> 8 & 0xFF;
    frame[1] = totalLength & 0xFF;
    frame.setRange(lengthBytes, lengthBytes + header.length, header);
    frame.setRange(lengthBytes + header.length, frame.length, bodyBytes);
    return frame;
  }

  /// Decodes one frame body — the bytes after the length prefix. A rejected
  /// message carries its reject code in the header and no ISO body.
  IsoMsg decode(Uint8List payload) {
    if (payload.length < headerLength) throw const FormatException("frame shorter than the $headerLength byte header");
    final Uint8List header = Uint8List.fromList(payload.sublist(0, headerLength));
    final OssAcqHeader ossHeader = OssAcqHeader.raw(header);

    final IsoMsg message = packager.createComponent()
      ..isoHeader = header
      ..rawBuffer = payload;

    if (ossHeader.isReject) {
      message.rejectCode = ossHeader.rejectCode;
      return message;
    }

    final Uint8List body = Uint8List.fromList(payload.sublist(headerLength));
    if (body.isNotEmpty) packager.unpack(message, IsoBuffer.wrap(body));
    return message;
  }

  /// The mux key: the four sequence bytes of the link header, in hex. Ported
  /// from `OssMessageKeyProvider`.
  static String messageKey(IsoMsg message) {
    final Uint8List? header = message.isoHeader;
    if (header == null) throw StateError("message has no link header");
    return IsoUtil.hexString(OssAcqHeader.raw(header).sequence);
  }
}
