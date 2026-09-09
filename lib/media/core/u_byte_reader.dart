import "package:u/utilities.dart";

const int uMaxTagAllocation = 24 * 1024 * 1024;

class UByteReader {
  UByteReader(Uint8List bytes, {int start = 0, int? end})
    : _bytes = bytes,
      _pos = start,
      _end = end ?? bytes.length {
    if (start < 0 || _end > bytes.length || start > _end) throw const UMediaParseException("Invalid reader window");
  }

  final Uint8List _bytes;
  final int _end;
  int _pos;

  int get position => _pos;

  int get end => _end;

  int get remaining => _end - _pos;

  bool get isEmpty => _pos >= _end;

  bool canRead(int count) => count >= 0 && remaining >= count;

  void _require(int count) {
    if (count < 0) throw const UMediaParseException("Negative read length");
    if (remaining < count) throw UMediaParseException("Read of $count exceeds buffer", offset: _pos);
  }

  int guardedLength(int declared, {int cap = uMaxTagAllocation}) {
    if (declared < 0) return 0;
    final int limit = cap < remaining ? cap : remaining;
    return declared > limit ? limit : declared;
  }

  void seek(int absolute) {
    if (absolute < 0 || absolute > _end) throw UMediaParseException("Seek out of range", offset: absolute);
    _pos = absolute;
  }

  void skip(int count) {
    _require(count);
    _pos += count;
  }

  int u8() {
    _require(1);
    return _bytes[_pos++];
  }

  int u16be() {
    _require(2);
    final int value = (_bytes[_pos] << 8) | _bytes[_pos + 1];
    _pos += 2;
    return value;
  }

  int u16le() {
    _require(2);
    final int value = _bytes[_pos] | (_bytes[_pos + 1] << 8);
    _pos += 2;
    return value;
  }

  int u24be() {
    _require(3);
    final int value = (_bytes[_pos] << 16) | (_bytes[_pos + 1] << 8) | _bytes[_pos + 2];
    _pos += 3;
    return value;
  }

  int u32be() {
    _require(4);
    final int value = (_bytes[_pos] << 24) | (_bytes[_pos + 1] << 16) | (_bytes[_pos + 2] << 8) | _bytes[_pos + 3];
    _pos += 4;
    return value;
  }

  int u32le() {
    _require(4);
    final int value = _bytes[_pos] | (_bytes[_pos + 1] << 8) | (_bytes[_pos + 2] << 16) | (_bytes[_pos + 3] << 24);
    _pos += 4;
    return value;
  }

  int u64be() {
    _require(8);
    final int high = u32be();
    final int low = u32be();
    return (high << 32) | low;
  }

  int syncSafe32() {
    _require(4);
    final int a = _bytes[_pos] & 0x7F;
    final int b = _bytes[_pos + 1] & 0x7F;
    final int c = _bytes[_pos + 2] & 0x7F;
    final int d = _bytes[_pos + 3] & 0x7F;
    _pos += 4;
    return (a << 21) | (b << 14) | (c << 7) | d;
  }

  Uint8List take(int count) {
    _require(count);
    final Uint8List view = Uint8List.sublistView(_bytes, _pos, _pos + count);
    _pos += count;
    return view;
  }

  Uint8List takeGuarded(int declared, {int cap = uMaxTagAllocation}) => take(guardedLength(declared, cap: cap));

  Uint8List peek(int count) {
    _require(count);
    return Uint8List.sublistView(_bytes, _pos, _pos + count);
  }

  String ascii(int count) {
    final Uint8List raw = take(count);
    final StringBuffer buffer = StringBuffer();
    for (final int byte in raw) {
      if (byte == 0) continue;
      buffer.writeCharCode(byte < 0x20 || byte > 0x7E ? 0x20 : byte);
    }
    return buffer.toString().trim();
  }

  String latin1Trimmed(int count) => String.fromCharCodes(take(count).where((int b) => b != 0)).trim();

  UByteReader window(int count) {
    _require(count);
    final UByteReader child = UByteReader(_bytes, start: _pos, end: _pos + count);
    _pos += count;
    return child;
  }

  int indexOfByte(int value, {int from = -1}) {
    final int start = from < 0 ? _pos : from;
    for (int i = start; i < _end; i++) {
      if (_bytes[i] == value) return i;
    }
    return -1;
  }
}
