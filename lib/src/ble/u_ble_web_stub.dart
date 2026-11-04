import "dart:async";
import "dart:typed_data";

import "package:u/src/ble/u_ble_types.dart";

// Off the web these are never called; UBle checks kIsWeb first.
abstract final class UBleWeb {
  // ignore: close_sinks
  static final StreamController<Map<Object?, Object?>> events = StreamController<Map<Object?, Object?>>.broadcast();

  static Future<UBleState> state() async => UBleState.unsupported;

  static Future<UBleDevice> request({required List<String> services, int? manufacturerId, List<int>? manufacturerDataPrefix}) async => throw const UBleException(UBleError.unsupported);

  static Future<List<UBleDevice>> remembered() async => const <UBleDevice>[];

  static Future<int> connect(String id, Duration timeout) async => throw const UBleException(UBleError.unsupported);

  static Future<void> disconnect(String id) async {}

  static Future<void> setNotify(String id, String service, String characteristic, bool enable) async => throw const UBleException(UBleError.unsupported);

  static Future<void> write(String id, String service, String characteristic, Uint8List value, bool withResponse) async => throw const UBleException(UBleError.unsupported);
}
