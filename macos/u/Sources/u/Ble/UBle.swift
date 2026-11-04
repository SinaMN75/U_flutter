// Shared by ios/ and macos/: keep the two copies identical.
import CoreBluetooth
import Foundation
#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

/// Native side of UBle ("u/ble" + scan / events): CoreBluetooth central.
/// Device ids are CoreBluetooth's per-app peripheral UUIDs. The app needs NSBluetoothAlwaysUsageDescription
/// (and the com.apple.security.device.bluetooth entitlement on macOS): `dart run u:app permission add bluetooth`.
final class UBleHandler: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let channel: FlutterMethodChannel
    private var streams: [FlutterEventChannel] = []
    private var central: CBCentralManager?
    private var stateWaiters: [FlutterResult] = []
    private var scanSink: FlutterEventSink?
    private var eventsSink: FlutterEventSink?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var connecting: [UUID: (result: FlutterResult, timeout: DispatchWorkItem)] = [:]
    private var discovering: [UUID: Int] = [:]
    private var writeWaiters: [String: [FlutterResult]] = [:]
    private var notifyWaiters: [String: [FlutterResult]] = [:]

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "u/ble", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
        let scan = FlutterEventChannel(name: "u/ble/scan", binaryMessenger: messenger)
        scan.setStreamHandler(UStreamHandler(listen: { [weak self] _, sink in
            self?.scanSink = sink
            return nil
        }, cancel: { [weak self] in self?.scanSink = nil }))
        let events = FlutterEventChannel(name: "u/ble/events", binaryMessenger: messenger)
        events.setStreamHandler(UStreamHandler(listen: { [weak self] _, sink in
            self?.eventsSink = sink
            return nil
        }, cancel: { [weak self] in self?.eventsSink = nil }))
        streams = [scan, events]
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "state": result(stateName())
        case "requestPermission": requestPermission(result)
        case "startScan": startScan(args["services"] as? [String] ?? [], result)
        case "stopScan":
            central?.stopScan()
            result(nil)
        case "connect": connect(args["id"] as? String ?? "", timeout: (args["timeout"] as? NSNumber)?.doubleValue ?? 15000, result)
        case "disconnect":
            if let id = UUID(uuidString: args["id"] as? String ?? ""), let p = peripherals[id] { central?.cancelPeripheralConnection(p) }
            result(nil)
        case "setNotify": setNotify(args, result)
        case "write": write(args, result)
        default: result(FlutterMethodNotImplemented)
        }
    }

    private func manager() -> CBCentralManager {
        if let central { return central }
        let created = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        central = created
        return created
    }

    private func stateName() -> String {
        if #available(iOS 13.1, macOS 10.15, *) {
            switch CBCentralManager.authorization {
            case .denied, .restricted: return "unauthorized"
            case .notDetermined: if central == nil { return "unauthorized" }
            default: break
            }
        }
        switch manager().state {
        case .poweredOn: return "poweredOn"
        case .poweredOff: return "poweredOff"
        case .unauthorized: return "unauthorized"
        case .unsupported: return "unsupported"
        default: return "unknown"
        }
    }

    private func requestPermission(_ result: @escaping FlutterResult) {
        let state = manager().state
        if state == .unknown || state == .resetting {
            stateWaiters.append(result)
        } else {
            result(stateName())
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .unknown || central.state == .resetting { return }
        let waiters = stateWaiters
        stateWaiters = []
        waiters.forEach { $0(stateName()) }
    }

    private func startScan(_ services: [String], _ result: @escaping FlutterResult) {
        let state = stateName()
        if state != "poweredOn" { return result(FlutterError(code: state, message: nil, details: nil)) }
        let uuids = services.map { CBUUID(string: $0) }
        manager().scanForPeripherals(withServices: uuids.isEmpty ? nil : uuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        result(nil)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        peripherals[peripheral.identifier] = peripheral
        var manufacturer: [NSNumber: FlutterStandardTypedData] = [:]
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, data.count >= 2 {
            let company = Int(data[data.startIndex]) | (Int(data[data.startIndex + 1]) << 8)
            manufacturer[NSNumber(value: company)] = FlutterStandardTypedData(bytes: data.subdata(in: (data.startIndex + 2)..<data.endIndex))
        }
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []).map { $0.uuidString.lowercased() }
        scanSink?([
            "id": peripheral.identifier.uuidString,
            "name": advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "",
            "rssi": RSSI.intValue,
            "services": services,
            "manufacturerData": manufacturer,
        ] as [String: Any])
    }

    private func connect(_ id: String, timeout: Double, _ result: @escaping FlutterResult) {
        let state = stateName()
        if state != "poweredOn" { return result(FlutterError(code: state, message: nil, details: nil)) }
        guard let uuid = UUID(uuidString: id), let peripheral = peripherals[uuid] ?? manager().retrievePeripherals(withIdentifiers: [uuid]).first else {
            return result(FlutterError(code: "notFound", message: nil, details: nil))
        }
        peripherals[uuid] = peripheral
        peripheral.delegate = self
        let work = DispatchWorkItem { [weak self] in
            guard let self, let pending = self.connecting.removeValue(forKey: uuid) else { return }
            self.central?.cancelPeripheralConnection(peripheral)
            pending.result(FlutterError(code: "timeout", message: nil, details: nil))
        }
        connecting[uuid] = (result, work)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout / 1000, execute: work)
        manager().connect(peripheral, options: nil)
    }

    private func finishConnect(_ peripheral: CBPeripheral, error: String?) {
        guard let pending = connecting.removeValue(forKey: peripheral.identifier) else { return }
        pending.timeout.cancel()
        if let error {
            central?.cancelPeripheralConnection(peripheral)
            pending.result(FlutterError(code: error, message: nil, details: nil))
        } else {
            pending.result(peripheral.maximumWriteValueLength(for: .withoutResponse))
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        finishConnect(peripheral, error: "failed")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let id = peripheral.identifier.uuidString
        let wasConnecting = connecting[peripheral.identifier] != nil
        finishConnect(peripheral, error: "failed")
        for key in Array(writeWaiters.keys) + Array(notifyWaiters.keys) where key.hasPrefix(id + "|") {
            (writeWaiters.removeValue(forKey: key) ?? []).forEach { $0(FlutterError(code: "disconnected", message: nil, details: nil)) }
            (notifyWaiters.removeValue(forKey: key) ?? []).forEach { $0(FlutterError(code: "disconnected", message: nil, details: nil)) }
        }
        if !wasConnecting { eventsSink?(["event": "disconnected", "id": id]) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let services = peripheral.services ?? []
        if error != nil { return finishConnect(peripheral, error: "failed") }
        if services.isEmpty { return finishConnect(peripheral, error: nil) }
        discovering[peripheral.identifier] = services.count
        services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let left = (discovering[peripheral.identifier] ?? 1) - 1
        discovering[peripheral.identifier] = left
        if left <= 0 {
            discovering.removeValue(forKey: peripheral.identifier)
            finishConnect(peripheral, error: nil)
        }
    }

    private func target(_ args: [String: Any]) -> (CBPeripheral, CBCharacteristic, String)? {
        guard let id = args["id"] as? String, let uuid = UUID(uuidString: id), let peripheral = peripherals[uuid], peripheral.state == .connected else { return nil }
        let serviceId = CBUUID(string: args["service"] as? String ?? "")
        let characteristicId = CBUUID(string: args["characteristic"] as? String ?? "")
        guard let characteristic = peripheral.services?.first(where: { $0.uuid == serviceId })?.characteristics?.first(where: { $0.uuid == characteristicId }) else { return nil }
        return (peripheral, characteristic, key(peripheral, characteristic))
    }

    private func key(_ peripheral: CBPeripheral, _ characteristic: CBCharacteristic) -> String {
        "\(peripheral.identifier.uuidString)|\(characteristic.service?.uuid.uuidString ?? "")|\(characteristic.uuid.uuidString)"
    }

    private func setNotify(_ args: [String: Any], _ result: @escaping FlutterResult) {
        guard let (peripheral, characteristic, key) = target(args) else { return result(FlutterError(code: "notFound", message: nil, details: nil)) }
        notifyWaiters[key, default: []].append(result)
        peripheral.setNotifyValue(args["enable"] as? Bool ?? true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let key = key(peripheral, characteristic)
        guard var waiters = notifyWaiters[key], !waiters.isEmpty else { return }
        let result = waiters.removeFirst()
        notifyWaiters[key] = waiters
        result(error == nil ? nil : FlutterError(code: "failed", message: error?.localizedDescription, details: nil))
    }

    private func write(_ args: [String: Any], _ result: @escaping FlutterResult) {
        guard let (peripheral, characteristic, key) = target(args) else { return result(FlutterError(code: "notFound", message: nil, details: nil)) }
        let data = (args["value"] as? FlutterStandardTypedData)?.data ?? Data()
        if args["withResponse"] as? Bool ?? true {
            writeWaiters[key, default: []].append(result)
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        } else {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            result(nil)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let key = key(peripheral, characteristic)
        guard var waiters = writeWaiters[key], !waiters.isEmpty else { return }
        let result = waiters.removeFirst()
        writeWaiters[key] = waiters
        result(error == nil ? nil : FlutterError(code: "failed", message: error?.localizedDescription, details: nil))
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else { return }
        eventsSink?([
            "event": "value",
            "id": peripheral.identifier.uuidString,
            "service": characteristic.service?.uuid.uuidString.lowercased() ?? "",
            "characteristic": characteristic.uuid.uuidString.lowercased(),
            "value": FlutterStandardTypedData(bytes: value),
        ] as [String: Any])
    }
}
