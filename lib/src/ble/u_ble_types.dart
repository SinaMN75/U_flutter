import "dart:typed_data";

/// Bluetooth radio and permission state.
enum UBleState { unsupported, unauthorized, poweredOff, poweredOn, unknown }

/// Why a UBle call failed.
enum UBleError { unsupported, unauthorized, poweredOff, notFound, timeout, disconnected, cancelled, failed }

class UBleException implements Exception {
  const UBleException(this.error, [this.message]);

  final UBleError error;
  final String? message;

  @override
  String toString() => "UBleException(${error.name}${message == null ? "" : ", $message"})";
}

/// A device seen while scanning. [id] is what UBle.connect takes (a MAC on Android/Windows/Linux, a per-app UUID on iOS/macOS, a per-site id on web).
class UBleDevice {
  const UBleDevice({required this.id, this.name = "", this.rssi = 0, this.services = const <String>[], this.manufacturerData = const <int, Uint8List>{}});

  factory UBleDevice.fromMap(Map<Object?, Object?> map) => UBleDevice(
    id: map["id"]?.toString() ?? "",
    name: map["name"]?.toString() ?? "",
    rssi: (map["rssi"] as num?)?.toInt() ?? 0,
    services: ((map["services"] as List<Object?>?) ?? const <Object?>[]).map((Object? e) => UBleUuid.normalize(e.toString())).toList(),
    manufacturerData: ((map["manufacturerData"] as Map<Object?, Object?>?) ?? const <Object?, Object?>{}).map(
      (Object? key, Object? value) => MapEntry<int, Uint8List>((key! as num).toInt(), value is Uint8List ? value : Uint8List.fromList((value! as List<Object?>).cast<int>())),
    ),
  );

  final String id;
  final String name;
  final int rssi;
  final List<String> services;
  final Map<int, Uint8List> manufacturerData;

  /// True when the advertised manufacturer data for [companyId] starts with [prefix].
  bool hasManufacturerData(int companyId, List<int> prefix) {
    final Uint8List? data = manufacturerData[companyId];
    if (data == null || data.length < prefix.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }
}

abstract final class UBleUuid {
  /// Lowercase 128-bit form; 16/32-bit short forms get the Bluetooth base UUID. `UBleUuid.normalize("180D")` → "0000180d-0000-1000-8000-00805f9b34fb"
  static String normalize(String uuid) {
    final String u = uuid.trim().toLowerCase();
    if (u.length == 4) return "0000$u-0000-1000-8000-00805f9b34fb";
    if (u.length == 8) return "$u-0000-1000-8000-00805f9b34fb";
    return u;
  }
}
