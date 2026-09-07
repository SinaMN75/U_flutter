import "package:u/utilities.dart";

/// The 19-byte OSS link header that precedes every ISO message on the wire.
///
/// Layout: `60 | dest(2) | src(2) | flags | sequence(4) | reserved(6) |
/// rejectCode(2) | rejectedField(1)`.
class OssAcqHeader {
  OssAcqHeader.raw(this.header);

  OssAcqHeader({required String source, required String destination}) : header = Uint8List(length) {
    header[0] = 0x60;
    this.source = source;
    this.destination = destination;
  }

  static const int length = 19;

  static int _trace = 1;
  static final Random _random = Random();

  final Uint8List header;

  /// Two random bytes followed by a 4-digit BCD counter that wraps at 9999.
  static Uint8List generateSequence() {
    int current = _trace++;
    if (current == 9999) {
      current = 1;
      _trace = current;
    }
    final Uint8List counter = IsoUtil.str2bcd(IsoUtil.padLeft(current.toString(), 4, "0"), true);
    final Uint8List sequence = Uint8List(4);
    sequence[0] = _random.nextInt(256);
    sequence[1] = _random.nextInt(256);
    sequence.setRange(2, 4, counter);
    return sequence;
  }

  int get id => header[0];

  bool get isValidId => header[0] == 0x60;

  String get source => IsoUtil.bcd2str(header, 3, 4, false);

  set source(String value) => header.setRange(3, 5, IsoUtil.str2bcd(value, true));

  String get destination => IsoUtil.bcd2str(header, 1, 4, false);

  set destination(String value) => header.setRange(1, 3, IsoUtil.str2bcd(value, true));

  int get flags => header[5];

  set flags(int value) => header[5] = value & 0xFF;

  Uint8List get sequence => Uint8List.fromList(header.sublist(6, 10));

  set sequence(Uint8List value) => header.setRange(6, 10, value);

  int get rejectedField => header[18];

  bool get isReject => rejectCode != 0;

  int get rejectCode => int.parse(IsoUtil.bcd2str(header, 16, 4, false));

  set rejectCode(int value) => header.setRange(16, 18, IsoUtil.str2bcd(IsoUtil.padLeft(value.toString(), 4, "0"), true));

  void swapDirection() {
    if (header.length < 5) return;
    final Uint8List currentSource = Uint8List.fromList(header.sublist(3, 5));
    header.setRange(3, 5, header.sublist(1, 3));
    header.setRange(1, 3, currentSource);
  }
}
