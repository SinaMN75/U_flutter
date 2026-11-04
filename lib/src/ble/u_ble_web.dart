import "dart:async";
import "dart:js_interop";
import "dart:js_interop_unsafe";
import "dart:typed_data";

import "package:u/src/ble/u_ble_types.dart";
import "package:web/web.dart" as web;

// Browser half of UBle: the Web Bluetooth API (Chrome, Edge, Opera, Samsung Internet; https only; not Safari or Firefox).
// Browsers cannot scan freely: request() opens the browser's device chooser and must run from a user tap.
abstract final class UBleWeb {
  // ignore: close_sinks
  static final StreamController<Map<Object?, Object?>> events = StreamController<Map<Object?, Object?>>.broadcast();
  static final Map<String, JSObject> _devices = <String, JSObject>{};
  static final Map<String, JSObject> _characteristics = <String, JSObject>{};
  static final Set<String> _listening = <String>{};

  static JSObject? get _bluetooth {
    final JSObject navigator = web.window.navigator as JSObject;
    return navigator.has("bluetooth") ? navigator["bluetooth"] as JSObject? : null;
  }

  static Future<UBleState> state() async {
    final JSObject? bluetooth = _bluetooth;
    if (bluetooth == null) return UBleState.unsupported;
    try {
      final JSBoolean available = await bluetooth.callMethod<JSPromise<JSBoolean>>("getAvailability".toJS).toDart;
      return available.toDart ? UBleState.poweredOn : UBleState.poweredOff;
    } catch (_) {
      return UBleState.unknown;
    }
  }

  static Future<UBleDevice> request({required List<String> services, int? manufacturerId, List<int>? manufacturerDataPrefix}) async {
    final JSObject bluetooth = _bluetooth ?? (throw const UBleException(UBleError.unsupported));
    final JSObject filter = JSObject()..["services"] = services.map((String s) => s.toJS).toList().toJS;
    if (manufacturerId != null) {
      final JSObject data = JSObject()..["companyIdentifier"] = manufacturerId.toJS;
      if (manufacturerDataPrefix != null) data["dataPrefix"] = Uint8List.fromList(manufacturerDataPrefix).toJS;
      filter["manufacturerData"] = <JSObject>[data].toJS;
    }
    final JSObject options = JSObject()
      ..["filters"] = <JSObject>[filter].toJS
      ..["optionalServices"] = services.map((String s) => s.toJS).toList().toJS;
    try {
      final JSObject device = await bluetooth.callMethod<JSPromise<JSObject>>("requestDevice".toJS, options).toDart;
      return _remember(device);
    } catch (e) {
      final String text = e.toString();
      if (text.contains("NotFoundError")) throw const UBleException(UBleError.cancelled);
      if (text.contains("SecurityError")) throw UBleException(UBleError.unauthorized, text);
      throw UBleException(UBleError.failed, text);
    }
  }

  /// Devices this site was allowed before (Chrome with getDevices support); no chooser needed for these.
  static Future<List<UBleDevice>> remembered() async {
    final JSObject? bluetooth = _bluetooth;
    if (bluetooth == null || !bluetooth.has("getDevices")) return const <UBleDevice>[];
    try {
      final JSArray<JSObject> devices = await bluetooth.callMethod<JSPromise<JSArray<JSObject>>>("getDevices".toJS).toDart;
      return devices.toDart.map(_remember).toList();
    } catch (_) {
      return const <UBleDevice>[];
    }
  }

  static UBleDevice _remember(JSObject device) {
    final String id = (device["id"] as JSString?)?.toDart ?? "";
    if (!_devices.containsKey(id)) {
      device.callMethod<JSAny?>(
        "addEventListener".toJS,
        "gattserverdisconnected".toJS,
        ((JSObject _) {
          _characteristics.removeWhere((String key, JSObject _) => key.startsWith("$id|"));
          _listening.removeWhere((String key) => key.startsWith("$id|"));
          events.add(<Object?, Object?>{"event": "disconnected", "id": id});
        }).toJS,
      );
    }
    _devices[id] = device;
    return UBleDevice(id: id, name: (device["name"] as JSString?)?.toDart ?? "");
  }

  static JSObject _gatt(String id) {
    final JSObject device = _devices[id] ?? (throw const UBleException(UBleError.notFound));
    return device["gatt"]! as JSObject;
  }

  // Web Bluetooth does not expose the MTU; 20 bytes always fits.
  static Future<int> connect(String id, Duration timeout) async {
    try {
      await _gatt(id).callMethod<JSPromise<JSObject>>("connect".toJS).toDart.timeout(timeout);
      return 20;
    } on TimeoutException {
      throw const UBleException(UBleError.timeout);
    } on UBleException {
      rethrow;
    } catch (e) {
      throw UBleException(UBleError.failed, e.toString());
    }
  }

  static Future<void> disconnect(String id) async {
    if (_devices.containsKey(id)) _gatt(id).callMethod<JSAny?>("disconnect".toJS);
  }

  static Future<JSObject> _characteristic(String id, String service, String characteristic) async {
    final String key = "$id|$service|$characteristic";
    final JSObject? cached = _characteristics[key];
    if (cached != null) return cached;
    try {
      final JSObject primary = await _gatt(id).callMethod<JSPromise<JSObject>>("getPrimaryService".toJS, service.toJS).toDart;
      final JSObject found = await primary.callMethod<JSPromise<JSObject>>("getCharacteristic".toJS, characteristic.toJS).toDart;
      return _characteristics[key] = found;
    } on UBleException {
      rethrow;
    } catch (e) {
      throw UBleException(UBleError.notFound, e.toString());
    }
  }

  static Future<void> setNotify(String id, String service, String characteristic, bool enable) async {
    final JSObject target = await _characteristic(id, service, characteristic);
    final String key = "$id|$service|$characteristic";
    try {
      if (!enable) {
        await target.callMethod<JSPromise<JSAny?>>("stopNotifications".toJS).toDart;
        return;
      }
      if (_listening.add(key)) {
        target.callMethod<JSAny?>(
          "addEventListener".toJS,
          "characteristicvaluechanged".toJS,
          ((JSObject _) {
            final JSObject view = target["value"]! as JSObject;
            final ByteBuffer buffer = (view["buffer"]! as JSArrayBuffer).toDart;
            final int offset = (view["byteOffset"]! as JSNumber).toDartInt;
            final int length = (view["byteLength"]! as JSNumber).toDartInt;
            events.add(<Object?, Object?>{
              "event": "value",
              "id": id,
              "service": service,
              "characteristic": characteristic,
              "value": Uint8List.fromList(buffer.asUint8List(offset, length)),
            });
          }).toJS,
        );
      }
      await target.callMethod<JSPromise<JSAny?>>("startNotifications".toJS).toDart;
    } catch (e) {
      throw UBleException(UBleError.failed, e.toString());
    }
  }

  static Future<void> write(String id, String service, String characteristic, Uint8List value, bool withResponse) async {
    final JSObject target = await _characteristic(id, service, characteristic);
    String method = withResponse ? "writeValueWithResponse" : "writeValueWithoutResponse";
    if (!target.has(method)) method = "writeValue";
    try {
      await target.callMethod<JSPromise<JSAny?>>(method.toJS, value.toJS).toDart;
    } catch (e) {
      throw UBleException(UBleError.failed, e.toString());
    }
  }
}
