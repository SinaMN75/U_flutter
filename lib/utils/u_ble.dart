import "package:u/src/ble/u_ble_web_stub.dart" if (dart.library.js_interop) "package:u/src/ble/u_ble_web.dart";
import "package:u/utilities.dart";

export "package:u/src/ble/u_ble_types.dart";

// =============================================================================
// UBle — Bluetooth Low Energy central: scan, connect, write, notifications ("u/ble" + "u/ble/scan|events").
//
//   Android  BluetoothLeScanner + BluetoothGatt (asks BLUETOOTH_SCAN/CONNECT on 12+, location below)
//   iOS      CoreBluetooth
//   macOS    CoreBluetooth (needs the com.apple.security.device.bluetooth entitlement)
//   Windows  Windows.Devices.Bluetooth (BluetoothLEAdvertisementWatcher + GATT)
//   Linux    BlueZ over D-Bus
//   Web      Web Bluetooth: scan() opens the browser's chooser and must start from a user tap
//
// The app declares the permission: `dart run u:app permission add bluetooth`.
// =============================================================================

/// Bluetooth Low Energy central on all 6 platforms.
/// ```dart
/// final UBleDevice device = await UBle.scan(services: <String>[serviceUuid]).first;
/// final UBleConnection c = await UBle.connect(device.id);
/// (await c.subscribe(serviceUuid, notifyUuid)).listen(print);
/// await c.write(serviceUuid, writeUuid, Uint8List.fromList(<int>[1, 2, 3]));
/// ```
abstract final class UBle {
  static const MethodChannel _channel = MethodChannel("u/ble");
  static const EventChannel _scanChannel = EventChannel("u/ble/scan");
  static const EventChannel _eventsChannel = EventChannel("u/ble/events");
  static Stream<Map<Object?, Object?>>? _events;

  /// True where UBle has an implementation (every platform; on web only browsers with Web Bluetooth).
  static bool get isPlatformSupported => true;

  static Stream<Map<Object?, Object?>> get _allEvents =>
      _events ??= kIsWeb ? UBleWeb.events.stream : _eventsChannel.receiveBroadcastStream().map((dynamic e) => e as Map<Object?, Object?>).asBroadcastStream();

  /// Radio and permission state. `if (await UBle.state() != UBleState.poweredOn) ...`
  static Future<UBleState> state() async {
    if (kIsWeb) return UBleWeb.state();
    return _state(await _invoke<String>("state"));
  }

  /// Asks for Bluetooth access (Android runtime permissions, iOS/macOS system prompt) and returns the new state.
  static Future<UBleState> requestPermission() async {
    if (kIsWeb) return UBleWeb.state();
    return _state(await _invoke<String>("requestPermission"));
  }

  /// Devices advertising any of [services] (all devices when empty). Stops after [timeout] or when you cancel.
  /// [manufacturerId] + [manufacturerDataPrefix] keep only devices whose manufacturer data starts with that prefix.
  /// Web: opens the browser's device chooser once and emits the picked device; call it from a tap.
  static Stream<UBleDevice> scan({List<String> services = const <String>[], Duration timeout = const Duration(seconds: 15), int? manufacturerId, List<int>? manufacturerDataPrefix}) {
    final List<String> uuids = services.map(UBleUuid.normalize).toList();
    if (kIsWeb) return Stream<UBleDevice>.fromFuture(UBleWeb.request(services: uuids, manufacturerId: manufacturerId, manufacturerDataPrefix: manufacturerDataPrefix));
    late final StreamController<UBleDevice> controller;
    StreamSubscription<dynamic>? results;
    Timer? timer;
    Future<void> stop() async {
      timer?.cancel();
      await results?.cancel();
      results = null;
      await _invoke<void>("stopScan");
    }

    controller = StreamController<UBleDevice>(
      onListen: () async {
        try {
          await _invoke<void>("startScan", <String, Object?>{"services": uuids});
        } on UBleException catch (e) {
          controller.addError(e);
          await controller.close();
          return;
        }
        results = _scanChannel.receiveBroadcastStream().listen(
          (dynamic e) {
            final UBleDevice device = UBleDevice.fromMap(e as Map<Object?, Object?>);
            if (manufacturerId != null && !device.hasManufacturerData(manufacturerId, manufacturerDataPrefix ?? const <int>[])) return;
            controller.add(device);
          },
          onError: (Object e) => controller.addError(_mapError(e)),
        );
        timer = Timer(timeout, () async {
          await stop();
          await controller.close();
        });
      },
      onCancel: stop,
    );
    return controller.stream;
  }

  /// Web only: devices this site was allowed before, so they connect without the chooser. Empty elsewhere.
  static Future<List<UBleDevice>> rememberedDevices() async => kIsWeb ? UBleWeb.remembered() : const <UBleDevice>[];

  /// Connects and discovers services. `final UBleConnection c = await UBle.connect(device.id);`
  static Future<UBleConnection> connect(String id, {Duration timeout = const Duration(seconds: 15)}) async {
    final int maxWrite = kIsWeb ? await UBleWeb.connect(id, timeout) : await _invoke<int>("connect", <String, Object?>{"id": id, "timeout": timeout.inMilliseconds}) ?? 20;
    return UBleConnection._(id, maxWrite);
  }

  static Future<void> _disconnect(String id) => kIsWeb ? UBleWeb.disconnect(id) : _invoke<void>("disconnect", <String, Object?>{"id": id});

  static Future<void> _setNotify(String id, String service, String characteristic, bool enable) => kIsWeb
      ? UBleWeb.setNotify(id, service, characteristic, enable)
      : _invoke<void>("setNotify", <String, Object?>{"id": id, "service": service, "characteristic": characteristic, "enable": enable});

  static Future<void> _write(String id, String service, String characteristic, Uint8List value, bool withResponse) => kIsWeb
      ? UBleWeb.write(id, service, characteristic, value, withResponse)
      : _invoke<void>("write", <String, Object?>{"id": id, "service": service, "characteristic": characteristic, "value": value, "withResponse": withResponse});

  static UBleState _state(String? name) => UBleState.values.firstWhere((UBleState s) => s.name == name, orElse: () => UBleState.unsupported);

  static UBleException _mapError(Object e) {
    if (e is UBleException) return e;
    if (e is PlatformException) return UBleException(UBleError.values.firstWhere((UBleError x) => x.name == e.code, orElse: () => UBleError.failed), e.message);
    return UBleException(UBleError.failed, e.toString());
  }

  static Future<T?> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      throw const UBleException(UBleError.unsupported);
    } on PlatformException catch (e) {
      throw _mapError(e);
    }
  }
}

/// An open GATT connection from UBle.connect.
class UBleConnection {
  UBleConnection._(this.id, this.maxWriteLength);

  final String id;

  /// Largest value one write can carry on this link (ATT MTU - 3); split bigger data yourself.
  final int maxWriteLength;

  /// Completes when the device disconnects, from either side.
  late final Future<void> disconnected = UBle._allEvents.firstWhere((Map<Object?, Object?> e) => e["event"] == "disconnected" && e["id"] == id).then((_) {}, onError: (_) {});

  /// Turns notifications on for [characteristic] and returns its values. `(await c.subscribe(s, ch)).listen(onBytes)`
  Future<Stream<Uint8List>> subscribe(String service, String characteristic) async {
    final String s = UBleUuid.normalize(service);
    final String ch = UBleUuid.normalize(characteristic);
    final Stream<Uint8List> values = UBle._allEvents
        .where((Map<Object?, Object?> e) => e["event"] == "value" && e["id"] == id && UBleUuid.normalize(e["service"].toString()) == s && UBleUuid.normalize(e["characteristic"].toString()) == ch)
        .map((Map<Object?, Object?> e) => e["value"]! as Uint8List);
    await UBle._setNotify(id, s, ch, true);
    return values;
  }

  /// Writes [value] (at most [maxWriteLength] bytes); with [withResponse] it completes once the device acknowledged it.
  Future<void> write(String service, String characteristic, Uint8List value, {bool withResponse = true}) =>
      UBle._write(id, UBleUuid.normalize(service), UBleUuid.normalize(characteristic), value, withResponse);

  Future<void> disconnect() => UBle._disconnect(id);
}
