import "package:u/utilities.dart";

enum IsoTraceKind { link, out, incoming, mac, decode, result }

class IsoTraceEntry {
  IsoTraceEntry(this.kind, this.message, {this.hex}) : at = DateTime.now();

  final DateTime at;
  final IsoTraceKind kind;
  final String message;
  final String? hex;

  String get time => "${at.hour.toString().padLeft(2, "0")}:${at.minute.toString().padLeft(2, "0")}:${at.second.toString().padLeft(2, "0")}.${at.millisecond.toString().padLeft(3, "0")}";

  @override
  String toString() => "$time  ${kind.name.padRight(8)}  $message${hex == null ? "" : "\n          $hex"}";
}

/// A ring buffer of what actually happened on the wire.
///
/// Without this, a failed transaction is indistinguishable from a lost one:
/// you cannot tell "the host never answered" from "the host answered and we
/// could not frame it" from "we framed it and the MAC did not match".
abstract class IsoTrace {
  static const int maxEntries = 300;
  static bool enabled = true;

  static final List<IsoTraceEntry> _entries = <IsoTraceEntry>[];

  static List<IsoTraceEntry> get entries => List<IsoTraceEntry>.unmodifiable(_entries);

  static void clear() => _entries.clear();

  static void log(IsoTraceKind kind, String message, {Uint8List? bytes}) {
    if (!enabled) return;
    _entries.add(IsoTraceEntry(kind, message, hex: bytes == null ? null : IsoUtil.hexString(bytes)));
    if (_entries.length > maxEntries) _entries.removeRange(0, _entries.length - maxEntries);
  }

  static String dump() => _entries.map((IsoTraceEntry entry) => entry.toString()).join("\n");
}
