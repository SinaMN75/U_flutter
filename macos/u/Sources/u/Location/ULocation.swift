// Shared by ios/ and macos/: keep the two copies identical.
import Contacts
import CoreLocation
import Foundation
import UserNotifications
#if os(iOS)
import Flutter
import UIKit
#else
import AppKit
import FlutterMacOS
#endif

/// A FlutterStreamHandler made of two closures.
final class UStreamHandler: NSObject, FlutterStreamHandler {
    private let listen: (Any?, @escaping FlutterEventSink) -> FlutterError?
    private let cancel: () -> Void

    init(listen: @escaping (Any?, @escaping FlutterEventSink) -> FlutterError?, cancel: @escaping () -> Void) {
        self.listen = listen
        self.cancel = cancel
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? { listen(arguments, events) }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancel()
        return nil
    }
}

/// Native side of ULocation ("u/location" + updates / heading / geofence / visits): CoreLocation
/// for permissions, positions, background and significant-change tracking, visits, regions,
/// heading, and CLGeocoder.
final class ULocationHandler: NSObject, CLLocationManagerDelegate {
    private let channel: FlutterMethodChannel
    private var streams: [FlutterEventChannel] = []
    private let single = CLLocationManager()
    private let tracker = CLLocationManager()
    private let monitor = CLLocationManager()
    private var pendingCurrent: [FlutterResult] = []
    private var currentTimeout: DispatchWorkItem?
    private var pendingPermission: [FlutterResult] = []
    private var updatesSink: FlutterEventSink?
    private var headingSink: FlutterEventSink?
    private var visitsSink: FlutterEventSink?
    private var geofenceSink: FlutterEventSink?
    private var significantOnly = false
    private let defaults = UserDefaults.standard
    private static let fencesKey = "u_geofences"
    private static let eventsKey = "u_geofence_events"

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "u/location", binaryMessenger: messenger)
        super.init()
        [single, tracker, monitor].forEach { $0.delegate = self }
        channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
        stream(messenger, "u/location/updates", listen: { [weak self] args, sink in self?.startUpdates(args as? [String: Any] ?? [:], sink) }, cancel: { [weak self] in self?.stopUpdates() })
        stream(messenger, "u/location/heading", listen: { [weak self] _, sink in self?.startHeading(sink) }, cancel: { [weak self] in self?.stopHeading() })
        stream(messenger, "u/location/visits", listen: { [weak self] _, sink in self?.startVisits(sink) }, cancel: { [weak self] in self?.stopVisits() })
        stream(messenger, "u/location/geofence", listen: { [weak self] _, sink in self?.listenGeofences(sink) }, cancel: { [weak self] in self?.geofenceSink = nil })
        #if os(iOS)
        // A dismissed "Always" upgrade prompt changes nothing and sends no callback: settle on return.
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self?.settlePermission() }
        }
        #endif
    }

    private func stream(_ messenger: FlutterBinaryMessenger, _ name: String, listen: @escaping (Any?, @escaping FlutterEventSink) -> FlutterError?, cancel: @escaping () -> Void) {
        let events = FlutterEventChannel(name: name, binaryMessenger: messenger)
        events.setStreamHandler(UStreamHandler(listen: listen, cancel: cancel))
        streams.append(events)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "permission": permission(result)
        case "requestPermission": requestPermission(always: args["always"] as? Bool ?? false, result: result)
        case "requestPrecise": requestPrecise(args["purposeKey"] as? String ?? "", result: result)
        case "current": current(args, result: result)
        case "lastKnown": result(single.location.map(Self.toMap))
        case "addGeofence": result(addGeofence(args))
        case "removeGeofence":
            removeGeofence(args["id"] as? String ?? "")
            result(nil)
        case "clearGeofences":
            monitor.monitoredRegions.forEach { monitor.stopMonitoring(for: $0) }
            defaults.removeObject(forKey: Self.fencesKey)
            result(nil)
        case "geofences": result(fences())
        case "reverseGeocode": reverseGeocode(args, result: result)
        case "geocode": geocode(args, result: result)
        case "geocodingAvailable": result(true)
        default: result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Permission

    private var authorization: CLAuthorizationStatus {
        if #available(iOS 14.0, macOS 11.0, *) { return single.authorizationStatus }
        return CLLocationManager.authorizationStatus()
    }

    private static func declared(_ key: String) -> Bool { Bundle.main.object(forInfoDictionaryKey: key) != nil }

    private var declaredWhenInUse: Bool {
        #if os(iOS)
        return Self.declared("NSLocationWhenInUseUsageDescription")
        #else
        return Self.declared("NSLocationUsageDescription") || Self.declared("NSLocationWhenInUseUsageDescription")
        #endif
    }

    private func statusName() -> String {
        switch authorization {
        case .notDetermined: return declaredWhenInUse ? "notDetermined" : "notDeclared"
        case .restricted: return "restricted"
        // Apple never shows the prompt again after a denial.
        case .denied: return "deniedForever"
        case .authorizedAlways: return "always"
        #if os(iOS)
        case .authorizedWhenInUse: return "whileInUse"
        #endif
        @unknown default: return "notDetermined"
        }
    }

    private var precise: Bool? {
        guard authorization != .notDetermined, authorization != .denied else { return nil }
        if #available(iOS 14.0, macOS 11.0, *) { return single.accuracyAuthorization == .fullAccuracy }
        return true
    }

    // locationServicesEnabled() can stall the main thread: ask it on a background queue.
    private func permission(_ result: @escaping FlutterResult) {
        let status = statusName()
        let precise = self.precise
        DispatchQueue.global(qos: .userInitiated).async {
            let enabled = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async { result(["status": status, "precise": precise as Any, "serviceEnabled": enabled]) }
        }
    }

    private func requestPermission(always: Bool, result: @escaping FlutterResult) {
        let status = authorization
        guard declaredWhenInUse else { return permission(result) }
        #if os(iOS)
        let canUpgrade = always && status == .authorizedWhenInUse && Self.declared("NSLocationAlwaysAndWhenInUseUsageDescription")
        guard status == .notDetermined || canUpgrade else { return permission(result) }
        pendingPermission.append(result)
        if always && Self.declared("NSLocationAlwaysAndWhenInUseUsageDescription") {
            single.requestAlwaysAuthorization()
        } else {
            single.requestWhenInUseAuthorization()
        }
        #else
        guard status == .notDetermined else { return permission(result) }
        pendingPermission.append(result)
        if always { single.requestAlwaysAuthorization() } else { single.requestWhenInUseAuthorization() }
        #endif
    }

    private func settlePermission() {
        guard !pendingPermission.isEmpty, authorization != .notDetermined else { return }
        let waiting = pendingPermission
        pendingPermission.removeAll()
        waiting.forEach { permission($0) }
    }

    @available(iOS 14.0, macOS 11.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager === single { settlePermission() }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if manager === single { settlePermission() }
    }

    private func requestPrecise(_ purposeKey: String, result: @escaping FlutterResult) {
        guard #available(iOS 14.0, macOS 11.0, *) else { return result(true) }
        let purposes = Bundle.main.object(forInfoDictionaryKey: "NSLocationTemporaryUsageDescriptionDictionary") as? [String: Any]
        // An undeclared purpose key is an error: report false instead of asking.
        guard purposes?[purposeKey] != nil else { return result(single.accuracyAuthorization == .fullAccuracy) }
        single.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey) { [weak self] _ in
            DispatchQueue.main.async { result(self?.single.accuracyAuthorization == .fullAccuracy) }
        }
    }

    // MARK: - Positions

    private static func accuracy(_ name: String?) -> CLLocationAccuracy {
        switch name {
        case "lowest": return kCLLocationAccuracyThreeKilometers
        case "low": return kCLLocationAccuracyKilometer
        case "balanced": return kCLLocationAccuracyHundredMeters
        case "best": return kCLLocationAccuracyBest
        case "navigation": return kCLLocationAccuracyBestForNavigation
        default: return kCLLocationAccuracyNearestTenMeters
        }
    }

    private var authorized: Bool {
        #if os(iOS)
        return authorization == .authorizedWhenInUse || authorization == .authorizedAlways
        #else
        return authorization == .authorizedAlways
        #endif
    }

    private func current(_ args: [String: Any], result: @escaping FlutterResult) {
        guard authorized else { return result(FlutterError(code: "permissionDenied", message: nil, details: nil)) }
        if let maxAge = args["maxAgeMs"] as? Int, let last = single.location, -last.timestamp.timeIntervalSinceNow * 1000 <= Double(maxAge) {
            return result(Self.toMap(last))
        }
        single.desiredAccuracy = Self.accuracy(args["accuracy"] as? String)
        pendingCurrent.append(result)
        currentTimeout?.cancel()
        let timeout = DispatchWorkItem { [weak self] in self?.finishCurrent(nil, error: "timeout") }
        currentTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(args["timeoutMs"] as? Int ?? 20000), execute: timeout)
        single.requestLocation()
    }

    private func finishCurrent(_ location: CLLocation?, error: String?) {
        currentTimeout?.cancel()
        currentTimeout = nil
        let waiting = pendingCurrent
        pendingCurrent.removeAll()
        waiting.forEach { result in
            if let location = location { result(Self.toMap(location)) } else { result(FlutterError(code: error ?? "unavailable", message: nil, details: nil)) }
        }
    }

    private func startUpdates(_ args: [String: Any], _ sink: @escaping FlutterEventSink) -> FlutterError? {
        guard authorized else { return FlutterError(code: "permissionDenied", message: nil, details: nil) }
        stopUpdates()
        updatesSink = sink
        tracker.desiredAccuracy = Self.accuracy(args["accuracy"] as? String)
        let distance = args["distanceFilter"] as? Double ?? 0
        tracker.distanceFilter = distance > 0 ? distance : kCLDistanceFilterNone
        #if os(iOS)
        switch args["activity"] as? String {
        case "automotive": tracker.activityType = .automotiveNavigation
        case "fitness": tracker.activityType = .fitness
        case "navigation": tracker.activityType = .otherNavigation
        case "airborne": if #available(iOS 12.0, *) { tracker.activityType = .airborne }
        default: tracker.activityType = .other
        }
        tracker.pausesLocationUpdatesAutomatically = args["pause"] as? Bool ?? false
        if args["background"] as? Bool == true {
            // Setting this without the "location" background mode crashes the app.
            let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
            if modes.contains("location") {
                tracker.allowsBackgroundLocationUpdates = true
                tracker.showsBackgroundLocationIndicator = args["indicator"] as? Bool ?? true
            } else {
                sink(FlutterError(code: "notDeclared", message: "Add \"location\" to UIBackgroundModes in Info.plist", details: nil))
            }
        }
        #endif
        significantOnly = args["significant"] as? Bool ?? false
        if significantOnly && CLLocationManager.significantLocationChangeMonitoringAvailable() {
            tracker.startMonitoringSignificantLocationChanges()
        } else {
            significantOnly = false
            tracker.startUpdatingLocation()
        }
        return nil
    }

    private func stopUpdates() {
        tracker.stopUpdatingLocation()
        tracker.stopMonitoringSignificantLocationChanges()
        #if os(iOS)
        if tracker.allowsBackgroundLocationUpdates { tracker.allowsBackgroundLocationUpdates = false }
        #endif
        updatesSink = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        if manager === single {
            finishCurrent(last, error: nil)
        } else if manager === tracker {
            locations.forEach { updatesSink?(Self.toMap($0)) }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let code: String
        switch (error as? CLError)?.code {
        case .denied?: code = "permissionDenied"
        case .locationUnknown?: code = "unavailable"
        default: code = "unavailable"
        }
        if manager === single {
            finishCurrent(nil, error: code)
        } else if manager === tracker, code == "permissionDenied" {
            updatesSink?(FlutterError(code: code, message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Heading and visits (iOS)

    private func startHeading(_ sink: @escaping FlutterEventSink) -> FlutterError? {
        #if os(iOS)
        guard CLLocationManager.headingAvailable() else { return FlutterError(code: "unsupported", message: "No compass", details: nil) }
        headingSink = sink
        tracker.headingFilter = 1
        tracker.startUpdatingHeading()
        return nil
        #else
        return FlutterError(code: "unsupported", message: "No compass on macOS", details: nil)
        #endif
    }

    private func stopHeading() {
        #if os(iOS)
        tracker.stopUpdatingHeading()
        #endif
        headingSink = nil
    }

    #if os(iOS)
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingSink?([
            "magnetic": newHeading.magneticHeading,
            "true": newHeading.trueHeading >= 0 ? newHeading.trueHeading : nil,
            "accuracy": newHeading.headingAccuracy >= 0 ? newHeading.headingAccuracy : nil,
            "time": Int64(newHeading.timestamp.timeIntervalSince1970 * 1000),
        ] as [String: Any?])
    }

    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        visitsSink?([
            "latitude": visit.coordinate.latitude,
            "longitude": visit.coordinate.longitude,
            "accuracy": visit.horizontalAccuracy,
            "arrival": visit.arrivalDate == .distantPast ? nil : Int64(visit.arrivalDate.timeIntervalSince1970 * 1000),
            "departure": visit.departureDate == .distantFuture ? nil : Int64(visit.departureDate.timeIntervalSince1970 * 1000),
        ] as [String: Any?])
    }
    #endif

    private func startVisits(_ sink: @escaping FlutterEventSink) -> FlutterError? {
        #if os(iOS)
        visitsSink = sink
        monitor.startMonitoringVisits()
        #endif
        return nil
    }

    private func stopVisits() {
        #if os(iOS)
        monitor.stopMonitoringVisits()
        #endif
        visitsSink = nil
    }

    // MARK: - Geofences

    private func fences() -> [[String: Any]] { defaults.array(forKey: Self.fencesKey) as? [[String: Any]] ?? [] }

    private func addGeofence(_ args: [String: Any]) -> Bool {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self),
              let id = args["id"] as? String, let lat = args["latitude"] as? Double, let lng = args["longitude"] as? Double else { return false }
        let radius = min(args["radius"] as? Double ?? 100, monitor.maximumRegionMonitoringDistance)
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), radius: radius, identifier: id)
        region.notifyOnEntry = args["onEnter"] as? Bool ?? true
        region.notifyOnExit = args["onExit"] as? Bool ?? true
        monitor.startMonitoring(for: region)
        let stored = args.compactMapValues { $0 is NSNull ? nil : $0 }
        defaults.set(fences().filter { $0["id"] as? String != id } + [stored], forKey: Self.fencesKey)
        return true
    }

    private func removeGeofence(_ id: String) {
        monitor.monitoredRegions.filter { $0.identifier == id }.forEach { monitor.stopMonitoring(for: $0) }
        defaults.set(fences().filter { $0["id"] as? String != id }, forKey: Self.fencesKey)
    }

    private func listenGeofences(_ sink: @escaping FlutterEventSink) -> FlutterError? {
        geofenceSink = sink
        // Transitions that woke the app in the background before Dart listened.
        (defaults.array(forKey: Self.eventsKey) as? [[String: Any]] ?? []).forEach { sink($0) }
        defaults.removeObject(forKey: Self.eventsKey)
        return nil
    }

    private func transition(_ region: CLRegion, enter: Bool) {
        let event: [String: Any] = ["id": region.identifier, "transition": enter ? "enter" : "exit", "time": Int64(Date().timeIntervalSince1970 * 1000)]
        if let sink = geofenceSink {
            sink(event)
        } else {
            defaults.set((defaults.array(forKey: Self.eventsKey) ?? []) + [event], forKey: Self.eventsKey)
        }
        guard let fence = fences().first(where: { $0["id"] as? String == region.identifier }), let title = fence["notificationTitle"] as? String else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = fence["notificationText"] as? String ?? ""
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "u_geofence_\(region.identifier)", content: content, trigger: nil))
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) { transition(region, enter: true) }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) { transition(region, enter: false) }

    // MARK: - Geocoding

    private func reverseGeocode(_ args: [String: Any], result: @escaping FlutterResult) {
        let location = CLLocation(latitude: args["latitude"] as? Double ?? 0, longitude: args["longitude"] as? Double ?? 0)
        let locale = (args["locale"] as? String).map { Locale(identifier: $0) }
        CLGeocoder().reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, _ in
            result((placemarks ?? []).map(Self.placemark))
        }
    }

    private func geocode(_ args: [String: Any], result: @escaping FlutterResult) {
        let locale = (args["locale"] as? String).map { Locale(identifier: $0) }
        CLGeocoder().geocodeAddressString(args["address"] as? String ?? "", in: nil, preferredLocale: locale) { placemarks, _ in
            result((placemarks ?? []).map(Self.placemark))
        }
    }

    private static func placemark(_ p: CLPlacemark) -> [String: Any?] {
        var lines: [String] = []
        if let address = p.postalAddress {
            lines = CNPostalAddressFormatter.string(from: address, style: .mailingAddress).components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        return [
            "name": p.name,
            "street": p.thoroughfare,
            "houseNumber": p.subThoroughfare,
            "city": p.locality,
            "district": p.subLocality,
            "state": p.administrativeArea,
            "county": p.subAdministrativeArea,
            "postalCode": p.postalCode,
            "country": p.country,
            "countryCode": p.isoCountryCode,
            "latitude": p.location?.coordinate.latitude,
            "longitude": p.location?.coordinate.longitude,
            "lines": lines,
        ]
    }

    // MARK: - Mapping

    static func toMap(_ l: CLLocation) -> [String: Any?] {
        var map: [String: Any?] = [
            "latitude": l.coordinate.latitude,
            "longitude": l.coordinate.longitude,
            "time": Int64(l.timestamp.timeIntervalSince1970 * 1000),
            "accuracy": l.horizontalAccuracy >= 0 ? l.horizontalAccuracy : nil,
            "altitude": l.verticalAccuracy >= 0 ? l.altitude : nil,
            "altitudeAccuracy": l.verticalAccuracy >= 0 ? l.verticalAccuracy : nil,
            "heading": l.course >= 0 ? l.course : nil,
            "speed": l.speed >= 0 ? l.speed : nil,
            "speedAccuracy": l.speedAccuracy >= 0 ? l.speedAccuracy : nil,
            "floor": l.floor?.level,
        ]
        if #available(iOS 13.4, macOS 10.15.4, *), l.courseAccuracy >= 0 { map["headingAccuracy"] = l.courseAccuracy }
        if #available(iOS 15.0, macOS 12.0, *) { map["mocked"] = l.sourceInformation?.isSimulatedBySoftware ?? false }
        return map
    }
}
