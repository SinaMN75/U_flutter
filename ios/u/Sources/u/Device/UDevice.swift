// Shared by ios/ and macos/: keep the two copies identical.
#if os(iOS)
import CoreTelephony
import Flutter
import UIKit
#else
import AppKit
import FlutterMacOS
import IOKit
import IOKit.ps
import SystemConfiguration
#endif
import Darwin
import Foundation
import MachO
import Network

/// Native side of UDevice, UPackage and UConnectivity ("u/device").
///
/// One NWPathMonitor runs for the plugin's lifetime on its own queue, so a network snapshot is
/// always a property read. Everything else is cheap sysctl / Bundle / FileManager reads.
final class UDeviceHandler: NSObject, FlutterStreamHandler {
    private let channel: FlutterMethodChannel
    private let events: FlutterEventChannel
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "u.device.network")
    private var sink: FlutterEventSink?
    #if os(iOS)
    private let telephony = CTTelephonyNetworkInfo()
    #endif

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "u/device", binaryMessenger: messenger)
        events = FlutterEventChannel(name: "u/device/network", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
        events.setStreamHandler(self)
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let snapshot = self.snapshot(path)
            DispatchQueue.main.async { self.sink?(snapshot) }
        }
        monitor.start(queue: queue)
    }

    func dispose() {
        monitor.cancel()
        channel.setMethodCallHandler(nil)
        events.setStreamHandler(nil)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "bootstrap":
            result(["device": device(), "package": package(), "network": snapshot(monitor.currentPath)])
        case "network":
            result(snapshot(monitor.currentPath))
        case "status":
            result(status())
        case "integrity":
            DispatchQueue.global(qos: .utility).async {
                let value = self.integrity()
                DispatchQueue.main.async { result(value) }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Device

    private func device() -> [String: Any?] {
        let info = ProcessInfo.processInfo
        var extra: [String: Any?] = [
            "cpuBrand": sysctlString("machdep.cpu.brand_string"),
            "kernel": sysctlString("kern.osrelease"),
            "translated": sysctlInt("sysctl.proc_translated") == 1,
            "thermalState": thermalName(info.thermalState),
        ]
        #if os(iOS)
        let ui = UIDevice.current
        let type: String
        switch ui.userInterfaceIdiom {
        case .pad: type = "tablet"
        case .tv: type = "tv"
        case .carPlay: type = "car"
        case .mac: type = "desktop"
        default: type = "phone"
        }
        #if targetEnvironment(simulator)
        let model = info.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? machine()
        let physical = false
        #else
        let model = machine()
        let physical = true
        #endif
        extra["localizedModel"] = ui.localizedModel
        extra["systemName"] = ui.systemName
        if #available(iOS 14.0, *) { extra["isiOSAppOnMac"] = info.isiOSAppOnMac }
        extra["isMacCatalystApp"] = info.isMacCatalystApp
        let os = ui.systemName == "iPadOS" || ui.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        let name = ui.name
        let osVersion = ui.systemVersion
        let id = ui.identifierForVendor?.uuidString
        #else
        let v = info.operatingSystemVersion
        let osVersion = v.patchVersion == 0 ? "\(v.majorVersion).\(v.minorVersion)" : "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        let model = sysctlString("hw.model") ?? "Mac"
        let physical = sysctlInt("kern.hv_vmm_present") != 1
        let type = "desktop"
        let os = "macOS"
        // Never ProcessInfo.hostName: it resolves through DNS and can block startup for seconds.
        let name = (SCDynamicStoreCopyComputerName(nil, nil) as String?) ?? (SCDynamicStoreCopyLocalHostName(nil) as String?) ?? "Mac"
        let id = platformUUID()
        extra["localHostName"] = SCDynamicStoreCopyLocalHostName(nil) as String?
        #endif
        return [
            "platform": osPlatform,
            "os": os,
            "osVersion": osVersion,
            "osBuild": sysctlString("kern.osversion"),
            "model": model,
            "manufacturer": "Apple",
            "brand": "Apple",
            "name": name,
            "type": type,
            "physical": physical,
            "id": id,
            "arch": arch(),
            "cores": info.activeProcessorCount,
            "memory": Int64(info.physicalMemory),
            "locales": Locale.preferredLanguages,
            "timeZone": TimeZone.current.identifier,
            "is24h": !(DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current) ?? "").contains("a"),
            "extra": extra,
        ]
    }

    private var osPlatform: String {
        #if os(iOS)
        return "ios"
        #else
        return "macos"
        #endif
    }

    private func arch() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return machine()
        #endif
    }

    private func machine() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) { $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) } }
    }

    #if os(macOS)
    private func platformUUID() -> String? {
        let service = IOServiceGetMatchingService(0, IOServiceMatching("IOPlatformExpertDevice"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        return IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
    }
    #endif

    // MARK: - Package

    private func package() -> [String: Any?] {
        let bundle = Bundle.main
        let files = FileManager.default
        let library = files.urls(for: .libraryDirectory, in: .userDomainMask).first
        let installTime = library.flatMap { (try? files.attributesOfItem(atPath: $0.path))?[.creationDate] as? Date }
        let updateTime = (try? files.attributesOfItem(atPath: bundle.bundlePath))?[.creationDate] as? Date
        let receipt = bundle.appStoreReceiptURL
        let testFlight = receipt?.lastPathComponent == "sandboxReceipt"
        var installer: String?
        #if os(iOS)
        #if targetEnvironment(simulator)
        installer = "debug"
        #else
        if testFlight {
            installer = "testflight"
        } else if bundle.path(forResource: "embedded", ofType: "mobileprovision") != nil {
            installer = "debug"
        } else {
            installer = "app_store"
        }
        #endif
        #else
        if let receipt = receipt, files.fileExists(atPath: receipt.path) { installer = testFlight ? "testflight" : "app_store" }
        #endif
        return [
            "appName": (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? bundle.object(forInfoDictionaryKey: "CFBundleName")) as? String,
            "packageName": bundle.bundleIdentifier,
            "version": bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            "buildNumber": bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            "installer": installer,
            "installTime": installTime.map { Int64($0.timeIntervalSince1970 * 1000) },
            "updateTime": updateTime.map { Int64($0.timeIntervalSince1970 * 1000) },
            "testFlight": testFlight,
            "executable": bundle.executablePath,
        ]
    }

    // MARK: - Network

    private func snapshot(_ path: NWPath) -> [String: Any?] {
        var types: [String] = []
        if path.usesInterfaceType(.wifi) { types.append("wifi") }
        if path.usesInterfaceType(.cellular) { types.append("cellular") }
        if path.usesInterfaceType(.wiredEthernet) { types.append("ethernet") }
        if vpnActive() { types.append("vpn") }
        let connected = path.status == .satisfied
        if connected && types.isEmpty { types.append("other") }
        var out: [String: Any?] = [
            "types": connected ? types : [],
            "connected": connected,
            // NWPath "satisfied" means a route exists, not that the internet answers.
            "internet": connected ? nil : false,
            "metered": path.isExpensive,
            "constrained": path.isConstrained,
            "interface": path.availableInterfaces.first?.name,
        ]
        #if os(iOS)
        if types.contains("cellular") { out["cellular"] = cellularGeneration() }
        #endif
        return out
    }

    // Active VPNs publish scoped proxy settings for their tunnel interface.
    private func vpnActive() -> Bool {
        guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scoped = settings["__SCOPED__"] as? [String: Any] else { return false }
        return scoped.keys.contains { key in ["tap", "tun", "ppp", "ipsec", "utun"].contains { key.hasPrefix($0) } }
    }

    #if os(iOS)
    private func cellularGeneration() -> String? {
        guard let tech = telephony.serviceCurrentRadioAccessTechnology?.values.first else { return nil }
        if #available(iOS 14.1, *), tech == CTRadioAccessTechnologyNR || tech == CTRadioAccessTechnologyNRNSA { return "5g" }
        switch tech {
        case CTRadioAccessTechnologyLTE: return "4g"
        case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x: return "2g"
        default: return "3g"
        }
    }
    #endif

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        let current = snapshot(monitor.currentPath)
        DispatchQueue.main.async { events(current) }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }

    // MARK: - Status

    private func status() -> [String: Any?] {
        let info = ProcessInfo.processInfo
        var out: [String: Any?] = [
            "thermal": thermalName(info.thermalState),
            "memTotal": Int64(info.physicalMemory),
            "uptimeMs": Int64(info.systemUptime * 1000),
        ]
        if let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]) {
            out["diskFree"] = values.volumeAvailableCapacityForImportantUsage
            out["diskTotal"] = values.volumeTotalCapacity.map { Int64($0) }
        }
        #if os(iOS)
        let ui = UIDevice.current
        let wasMonitoring = ui.isBatteryMonitoringEnabled
        ui.isBatteryMonitoringEnabled = true
        if ui.batteryLevel >= 0 { out["battery"] = Int((ui.batteryLevel * 100).rounded()) }
        switch ui.batteryState {
        case .charging: out["batteryState"] = "charging"
        case .full: out["batteryState"] = "full"
        case .unplugged: out["batteryState"] = "discharging"
        default: out["batteryState"] = "unknown"
        }
        ui.isBatteryMonitoringEnabled = wasMonitoring
        out["powerSave"] = info.isLowPowerModeEnabled
        out["memFree"] = Int64(os_proc_available_memory())
        #else
        if #available(macOS 12.0, *) { out["powerSave"] = info.isLowPowerModeEnabled }
        out["memFree"] = freeMemory()
        battery(&out)
        #endif
        return out
    }

    private func thermalName(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    #if os(macOS)
    private func freeMemory() -> Int64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let ok = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count) }
        }
        guard ok == KERN_SUCCESS else { return nil }
        return Int64(stats.free_count + stats.inactive_count) * Int64(vm_kernel_page_size)
    }

    private func battery(_ out: inout [String: Any?]) {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else { return }
        for source in sources {
            guard let d = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
                  (d[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType else { continue }
            if let current = d[kIOPSCurrentCapacityKey] as? Int, let max = d[kIOPSMaxCapacityKey] as? Int, max > 0 {
                out["battery"] = current * 100 / max
            }
            let onAC = (d[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            if (d[kIOPSIsChargedKey] as? Bool) == true {
                out["batteryState"] = "full"
            } else if (d[kIOPSIsChargingKey] as? Bool) == true {
                out["batteryState"] = "charging"
            } else {
                out["batteryState"] = onAC ? "notCharging" : "discharging"
            }
            return
        }
        out["batteryState"] = "none"
    }
    #endif

    // MARK: - Integrity

    private func integrity() -> [String: Any?] {
        var reasons: [String] = []
        var rooted = false
        var hooked = false
        #if os(iOS) && !targetEnvironment(simulator)
        for path in ["/Applications/Cydia.app", "/Applications/Sileo.app", "/Library/MobileSubstrate/MobileSubstrate.dylib", "/bin/bash", "/usr/sbin/sshd", "/etc/apt", "/private/var/lib/apt/", "/usr/bin/ssh", "/var/jb", "/private/preboot/jb"]
        where FileManager.default.fileExists(atPath: path) {
            rooted = true
            reasons.append("jailbreak file \(path)")
        }
        let probe = "/private/u_jb_\(UUID().uuidString)"
        if (try? "x".write(toFile: probe, atomically: true, encoding: .utf8)) != nil {
            try? FileManager.default.removeItem(atPath: probe)
            rooted = true
            reasons.append("can write outside the sandbox")
        }
        #endif
        let markers = ["frida", "fridagadget", "mobilesubstrate", "substrateloader", "libhooker", "substitute", "cynject", "sslkillswitch", "tweakinject", "ellekit"]
        for i in 0..<_dyld_image_count() {
            guard let raw = _dyld_get_image_name(i) else { continue }
            let name = String(cString: raw).lowercased()
            if let marker = markers.first(where: { name.contains($0) }) {
                hooked = true
                reasons.append("\(marker) loaded: \((name as NSString).lastPathComponent)")
                break
            }
        }
        if let inserted = ProcessInfo.processInfo.environment["DYLD_INSERT_LIBRARIES"], !inserted.isEmpty {
            hooked = true
            reasons.append("DYLD_INSERT_LIBRARIES set")
        }
        let debugger = debuggerAttached()
        if debugger { reasons.append("debugger attached") }
        #if targetEnvironment(simulator)
        let emulator = true
        reasons.append("iOS simulator")
        #else
        let emulator = false
        #endif
        #if os(macOS)
        let vm = sysctlInt("kern.hv_vmm_present") == 1
        if vm { reasons.append("running in a virtual machine") }
        #else
        let vm = false
        #endif
        return ["rooted": rooted, "emulator": emulator, "debugger": debugger, "hooked": hooked, "vm": vm, "reasons": reasons]
    }

    private func debuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    // MARK: - sysctl

    private func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    private func sysctlInt(_ name: String) -> Int32? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? value : nil
    }
}
