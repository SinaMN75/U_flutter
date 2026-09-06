/// Pads a field value out to its fixed length before interpretation.
abstract class IsoPadder<T> {
  T pad(T data, int maxLength);
}

class LeftPadder implements IsoPadder<String> {
  const LeftPadder(this.padCharacter);

  static const LeftPadder zeroPadder = LeftPadder("0");

  final String padCharacter;

  @override
  String pad(String data, int maxLength) {
    if (data.length > maxLength) throw ArgumentError("Data is too long. Max = $maxLength");
    final StringBuffer buffer = StringBuffer();
    for (int i = maxLength - data.length; i > 0; i--) {
      buffer.write(padCharacter);
    }
    buffer.write(data);
    return buffer.toString();
  }
}

class RightPadder implements IsoPadder<String> {
  const RightPadder(this.padCharacter);

  static const RightPadder spacePadder = RightPadder(" ");

  final String padCharacter;

  @override
  String pad(String data, int maxLength) {
    if (data.length > maxLength) throw ArgumentError("Data is too long. Max = $maxLength");
    if (data.length == maxLength) return data;
    final StringBuffer buffer = StringBuffer(data);
    for (int i = data.length; i < maxLength; i++) {
      buffer.write(padCharacter);
    }
    return buffer.toString();
  }
}

/// Right padder that truncates instead of throwing when the value is too long.
class RightTruncatingPadder extends RightPadder {
  const RightTruncatingPadder(super.padCharacter);

  static const RightTruncatingPadder spacePadder = RightTruncatingPadder(" ");

  @override
  String pad(String data, int maxLength) => data.length > maxLength ? super.pad(data.substring(0, maxLength), maxLength) : super.pad(data, maxLength);
}
