import "package:u/utilities.dart";

/// An ordered list of [TlvMsg], the shape of ISO field 63 in the OSS protocol.
class TlvList {
  TlvList([List<TlvMsg>? tags]) : tags = tags ?? <TlvMsg>[];

  final List<TlvMsg> tags;

  void append(TlvMsg tag) => tags.add(tag);

  void appendAll(TlvList list) => tags.addAll(list.tags);

  void appendBytes(int tag, Uint8List value) => tags.add(TlvMsg.bytes(tag, value));

  /// Matches the Java `append(int, String)`, which reads the string as hex.
  void appendHex(int tag, String value) => tags.add(TlvMsg.bytes(tag, IsoUtil.hex2byte(value)));

  void appendText(int tag, String value) => tags.add(TlvMsg.text(tag, value));

  void deleteByIndex(int index) => tags.removeAt(index);

  void deleteByTag(int tag) => tags.removeWhere((TlvMsg item) => item.tag == tag);

  bool hasTag(int tag) => tags.any((TlvMsg item) => item.tag == tag);

  TlvList? find(int tag) {
    final List<TlvMsg> matches = tags.where((TlvMsg item) => item.tag == tag).toList();
    return matches.isEmpty ? null : TlvList(matches);
  }

  TlvMsg? findFirst(int tag) {
    for (final TlvMsg item in tags) {
      if (item.tag == tag) return item;
    }
    return null;
  }

  TlvMsg? findFirstRecursive(List<int> path) {
    TlvList? current = this;
    TlvMsg? found;
    for (final int tag in path) {
      found = current?.findFirst(tag);
      if (found == null) return null;
      current = found.value is TlvList ? found.value! as TlvList : null;
    }
    return found;
  }

  TlvList? children(int tag) {
    TlvList? out;
    for (final TlvMsg item in tags) {
      if (item.tag == tag && item.value is TlvList) {
        out ??= TlvList();
        out.appendAll(item.value! as TlvList);
      }
    }
    return out;
  }

  TlvMsg index(int position) => tags[position];

  void rebuildTagsHierarchy([TlvMsg? parent]) {
    for (final TlvMsg item in tags) {
      item.parent = parent;
      final Object? value = item.value;
      if (value is TlvList) value.rebuildTagsHierarchy(item);
    }
  }

  /// Replaces each string value with its packed bytes, using the packager the
  /// tag dictionary assigns to that tag path.
  void packValues(Map<String, ValuePackager> codec, {bool rebuildHierarchy = true}) {
    if (rebuildHierarchy) rebuildTagsHierarchy();
    for (final TlvMsg item in tags) {
      final Object? value = item.value;
      if (value is TlvList) {
        value.packValues(codec, rebuildHierarchy: false);
      } else {
        final ValuePackager? packager = codec[item.completeTagString];
        if (packager != null) item.value = packager.pack(value);
      }
    }
  }

  void unpackValues(Map<String, ValuePackager> codec, {bool rebuildHierarchy = true}) {
    if (rebuildHierarchy) rebuildTagsHierarchy();
    for (final TlvMsg item in tags) {
      final Object? value = item.value;
      if (value is TlvList) {
        value.unpackValues(codec, rebuildHierarchy: false);
      } else {
        final ValuePackager? packager = codec[item.completeTagString];
        if (packager != null) {
          final Uint8List bytes = item.asBytes!;
          item.value = packager.unpack(IsoBuffer.wrap(bytes), bytes.length);
        }
      }
    }
  }

  Uint8List pack(int capacity) {
    final IsoBuffer buffer = IsoBuffer.allocate(capacity);
    for (final TlvMsg item in tags) {
      buffer.putBytes(item.toTlv(capacity));
    }
    return buffer.toBytes();
  }

  void unpackBytes(Uint8List bytes, [int offset = 0]) => unpack(IsoBuffer.wrap(bytes, offset, bytes.length - offset));

  void unpack(IsoBuffer buffer) {
    while (buffer.hasRemaining) {
      final TlvMsg? item = _readTlv(buffer);
      if (item != null) append(item);
    }
  }

  TlvMsg? _readTlv(IsoBuffer buffer) {
    final int tag = _readTag(buffer);
    if (tag == 0) return null;
    if (!buffer.hasRemaining) throw FormatException("BAD TLV FORMAT - tag (${TlvMsg.tagString(tag)}) without length or value");
    final int length = readValueLength(buffer);
    if (length > buffer.remaining) throw FormatException("BAD TLV FORMAT - tag (${TlvMsg.tagString(tag)}) length ($length) exceeds available data.");
    final Uint8List value = buffer.getBytes(length);
    if (TlvMsg.isConstructedTag(tag)) {
      final TlvList nested = TlvList()..unpackBytes(value);
      return TlvMsg.list(tag, nested);
    }
    return TlvMsg.bytes(tag, value);
  }

  int _readTag(IsoBuffer buffer) {
    int byte = buffer.get() & 0xFF;
    if (byte == 0xFF || byte == 0x00) {
      do {
        if (!buffer.hasRemaining) break;
        byte = buffer.get() & 0xFF;
      } while (byte == 0xFF || byte == 0x00);
    }
    int tag = byte;
    if (byte & 0x1F == 0x1F) {
      do {
        tag <<= 8;
        byte = buffer.get();
        tag |= byte & 0xFF;
      } while (byte & 0x80 == 0x80);
    }
    return tag;
  }

  int readValueLength(IsoBuffer buffer) {
    final int first = buffer.get();
    final int count = first & 0x7F;
    if (first & 0x80 == 0 || count == 0) return count;
    final Uint8List bytes = buffer.getBytes(count);
    int length = 0;
    for (final int byte in bytes) {
      length = length << 8 | byte & 0xFF;
    }
    return length;
  }

  @override
  String toString() => "[${tags.join(", ")}]";
}
