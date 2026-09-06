import "package:u/utilities.dart";

/// Reassembles length-prefixed frames from a byte stream that may split or
/// merge them arbitrarily.
class IsoFrameReader {
  IsoFrameReader({this.lengthBytes = 2});

  /// Width of the length prefix. Two big-endian bytes is the common case.
  final int lengthBytes;

  final List<int> _buffer = <int>[];

  /// Feeds received bytes in and returns whatever complete frame payloads
  /// (header plus body, without the length prefix) are now available.
  List<Uint8List> add(List<int> chunk) {
    _buffer.addAll(chunk);
    IsoTrace.log(IsoTraceKind.incoming, "${chunk.length} bytes from the socket, ${_buffer.length} buffered", bytes: Uint8List.fromList(chunk));
    final List<Uint8List> frames = <Uint8List>[];
    while (_buffer.length >= lengthBytes) {
      int length = 0;
      for (int i = 0; i < lengthBytes; i++) {
        length = length << 8 | _buffer[i] & 0xFF;
      }
      if (length == 0) {
        _buffer.removeRange(0, lengthBytes);
        continue;
      }
      if (_buffer.length < lengthBytes + length) {
        IsoTrace.log(IsoTraceKind.incoming, "frame says $length bytes, only ${_buffer.length - lengthBytes} arrived so far — waiting");
        break;
      }
      frames.add(Uint8List.fromList(_buffer.sublist(lengthBytes, lengthBytes + length)));
      _buffer.removeRange(0, lengthBytes + length);
    }
    return frames;
  }

  void reset() => _buffer.clear();
}
