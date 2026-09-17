import AVFoundation
import CoreImage
import Vision

#if os(iOS)
    import Flutter
    import UIKit
#else
    import AppKit
    import FlutterMacOS
#endif

// =============================================================================
// UCamera — AVFoundation implementation of the `u` camera plugin for iOS and
// macOS. Preview frames reach Flutter as a CVPixelBuffer texture, stills go
// through AVCapturePhotoOutput, video through AVCaptureMovieFileOutput, and
// barcode scanning can use AVCaptureMetadataOutput, which costs nothing in
// binary size because it ships with the OS.
// =============================================================================

enum UCameraMapper {
    static func deviceTypes() -> [AVCaptureDevice.DeviceType] {
        #if os(iOS)
            var types: [AVCaptureDevice.DeviceType] = [
                .builtInWideAngleCamera,
                .builtInTelephotoCamera,
                .builtInUltraWideCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
                .builtInTrueDepthCamera,
            ]
            if #available(iOS 15.4, *) { types.append(.builtInLiDARDepthCamera) }
            return types
        #else
            if #available(macOS 14.0, *) {
                return [.builtInWideAngleCamera, .external, .continuityCamera]
            }
            return [.builtInWideAngleCamera]
        #endif
    }

    static func facingName(_ position: AVCaptureDevice.Position) -> String {
        switch position {
        case .front: return "front"
        case .back: return "back"
        default: return "external"
        }
    }

    static func lensName(_ device: AVCaptureDevice) -> String {
        #if os(iOS)
            switch device.deviceType {
            case .builtInUltraWideCamera: return "ultraWide"
            case .builtInTelephotoCamera: return "telephoto"
            case .builtInTrueDepthCamera: return "depth"
            default: return "wide"
            }
        #else
            return "wide"
        #endif
    }

    static func preset(_ name: String?) -> AVCaptureSession.Preset {
        switch name {
        case "low": return .low
        case "medium": return .medium
        case "veryHigh": return .hd1920x1080
        case "ultraHigh":
            if #available(iOS 9.0, macOS 10.15, *) { return .hd4K3840x2160 }
            return .hd1920x1080
        case "max": return .photo
        default: return .hd1280x720
        }
    }

    static func metadataTypes(for formats: [String]) -> [AVMetadataObject.ObjectType] {
        var types: [AVMetadataObject.ObjectType] = []
        let wanted = formats.isEmpty ? allFormatNames : formats
        for name in wanted {
            switch name {
            case "qr": types.append(.qr)
            case "aztec": types.append(.aztec)
            case "dataMatrix": types.append(.dataMatrix)
            case "pdf417": types.append(.pdf417)
            case "code128": types.append(.code128)
            case "code39": types.append(.code39)
            case "code93": types.append(.code93)
            case "itf": types.append(.itf14)
            case "ean13": types.append(.ean13)
            case "ean8": types.append(.ean8)
            case "upcE": types.append(.upce)
            case "codabar":
                if #available(iOS 15.4, macOS 12.3, *) { types.append(.codabar) }
            default: break
            }
        }
        return types
    }

    static let allFormatNames = [
        "qr", "aztec", "dataMatrix", "pdf417", "code128", "code39", "code93", "itf", "ean13", "ean8", "upcE", "codabar",
    ]

    static func formatName(_ type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr: return "qr"
        case .aztec: return "aztec"
        case .dataMatrix: return "dataMatrix"
        case .pdf417: return "pdf417"
        case .code128: return "code128"
        case .code39: return "code39"
        case .code93: return "code93"
        case .itf14: return "itf"
        case .ean13: return "ean13"
        case .ean8: return "ean8"
        case .upce: return "upcE"
        default: return "unknown"
        }
    }

    static func visionFormatName(_ symbology: VNBarcodeSymbology) -> String {
        switch symbology {
        case .qr: return "qr"
        case .aztec: return "aztec"
        case .dataMatrix: return "dataMatrix"
        case .pdf417: return "pdf417"
        case .code128: return "code128"
        case .code39, .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum: return "code39"
        case .code93, .code93i: return "code93"
        case .itf14, .i2of5, .i2of5Checksum: return "itf"
        case .ean13: return "ean13"
        case .ean8: return "ean8"
        case .upce: return "upcE"
        case .codabar: return "codabar"
        default: return "unknown"
        }
    }
}

public final class UCameraSession: NSObject {
    private let sessionId: Int
    private let registry: FlutterTextureRegistry
    private let config: [String: Any]

    private let eventChannel: FlutterEventChannel
    private let frameChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    private var frameSink: FlutterEventSink?

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "u.camera.session")
    private let frameQueue = DispatchQueue(label: "u.camera.frames")

    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var metadataOutput = AVCaptureMetadataOutput()

    private var textureId: Int64 = -1
    private var latestBuffer: CVPixelBuffer?
    private let bufferLock = NSLock()

    private var streamingFrames = false
    private var frameInterval: TimeInterval = 0.08
    private var lastFrameAt: TimeInterval = 0
    private var frameFormat = "bgra8888"

    private var photoCompletion: (([String: Any]?, String?) -> Void)?
    private var photoPath: String?
    private var includePhotoBytes = true
    private var recordingCompletion: (([String: Any]?, String?) -> Void)?
    private var recordingStartedAt: Date?
    private var mirrorFront = true

    public var currentTextureId: Int64 { textureId }

    public init(
        sessionId: Int,
        messenger: FlutterBinaryMessenger,
        registry: FlutterTextureRegistry,
        config: [String: Any]
    ) {
        self.sessionId = sessionId
        self.registry = registry
        self.config = config
        eventChannel = FlutterEventChannel(name: "u/camera/events/\(sessionId)", binaryMessenger: messenger)
        frameChannel = FlutterEventChannel(name: "u/camera/frames/\(sessionId)", binaryMessenger: messenger)
        super.init()
        eventChannel.setStreamHandler(UCameraStreamProxy { [weak self] sink in self?.eventSink = sink })
        frameChannel.setStreamHandler(UCameraStreamProxy { [weak self] sink in self?.frameSink = sink })
    }

    // MARK: - Setup

    public func open(completion: @escaping ([String: Any]?, String?) -> Void) {
        queue.async { [weak self] in
            guard let self else { return }
            guard let device = self.resolveDevice() else {
                DispatchQueue.main.async { completion(nil, "notFound") }
                return
            }
            self.device = device
            self.mirrorFront = self.config["mirrorFrontPreview"] as? Bool ?? true

            self.session.beginConfiguration()
            self.session.sessionPreset = UCameraMapper.preset(self.config["resolution"] as? String)

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) { self.session.addInput(input) }
                self.input = input
            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async { completion(nil, error.localizedDescription) }
                return
            }

            if self.config["enableAudio"] as? Bool ?? true, let audio = AVCaptureDevice.default(for: .audio) {
                if let audioInput = try? AVCaptureDeviceInput(device: audio), self.session.canAddInput(audioInput) {
                    self.session.addInput(audioInput)
                    self.audioInput = audioInput
                }
            }

            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.videoOutput.setSampleBufferDelegate(self, queue: self.frameQueue)
            if self.session.canAddOutput(self.videoOutput) { self.session.addOutput(self.videoOutput) }

            if self.session.canAddOutput(self.photoOutput) { self.session.addOutput(self.photoOutput) }
            if self.session.canAddOutput(self.movieOutput) { self.session.addOutput(self.movieOutput) }
            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
                self.metadataOutput.setMetadataObjectsDelegate(self, queue: self.frameQueue)
            }

            self.session.commitConfiguration()
            self.applyInitialSettings()
            self.session.startRunning()

            DispatchQueue.main.async {
                self.textureId = self.registry.register(self)
                completion(self.describe(), nil)
            }
        }
    }

    private func resolveDevice() -> AVCaptureDevice? {
        if let identifier = config["deviceId"] as? String, let found = AVCaptureDevice(uniqueID: identifier) {
            return found
        }
        let position: AVCaptureDevice.Position
        switch config["facing"] as? String {
        case "front": position = .front
        case "external": position = .unspecified
        default: position = .back
        }
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: UCameraMapper.deviceTypes(),
            mediaType: .video,
            position: position
        )
        return discovery.devices.first ?? AVCaptureDevice.default(for: .video)
    }

    private func applyInitialSettings() {
        guard let device else { return }
        try? device.lockForConfiguration()
        if let zoom = config["initialZoom"] as? Double {
            #if os(iOS)
                device.videoZoomFactor = max(1.0, min(CGFloat(zoom), device.activeFormat.videoMaxZoomFactor))
            #endif
        }
        if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
        if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) { device.whiteBalanceMode = .continuousAutoWhiteBalance }
        device.unlockForConfiguration()
        applyFlash(config["flash"] as? String)
        applyMirroring()
    }

    private func applyMirroring() {
        guard let connection = videoOutput.connection(with: .video) else { return }
        let isFront = device?.position == .front
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = isFront && mirrorFront
        }
    }

    public func dispose() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
            self.metadataOutput.setMetadataObjectsDelegate(nil, queue: nil)
            DispatchQueue.main.async {
                if self.textureId >= 0 { self.registry.unregisterTexture(self.textureId) }
                self.textureId = -1
                self.eventChannel.setStreamHandler(nil)
                self.frameChannel.setStreamHandler(nil)
            }
        }
    }

    // MARK: - Description

    public func describe() -> [String: Any] {
        let dimensions = device.map { CMVideoFormatDescriptionGetDimensions($0.activeFormat.formatDescription) }
        return [
            "sessionId": sessionId,
            "textureId": textureId,
            "previewSize": [
                "width": Int(dimensions?.width ?? 1280),
                "height": Int(dimensions?.height ?? 720),
            ],
            "sensorOrientation": 0,
            "mirrored": device?.position == .front && mirrorFront,
            "zoom": zoomFactor(),
            "device": device.map { UCameraEnumerator.describe($0) } as Any,
            "capabilities": capabilities(),
        ]
    }

    private func zoomFactor() -> Double {
        #if os(iOS)
            return Double(device?.videoZoomFactor ?? 1)
        #else
            return 1
        #endif
    }

    private func capabilities() -> [String: Any] {
        guard let device else { return [:] }
        var maxZoom = 1.0
        #if os(iOS)
            maxZoom = Double(device.activeFormat.videoMaxZoomFactor)
        #endif
        var stabilization = ["off", "auto"]
        #if os(iOS)
            if device.activeFormat.isVideoStabilizationModeSupported(.standard) { stabilization.append("standard") }
            if device.activeFormat.isVideoStabilizationModeSupported(.cinematic) { stabilization.append("cinematic") }
            if #available(iOS 13.0, *), device.activeFormat.isVideoStabilizationModeSupported(.cinematicExtended) {
                stabilization.append("cinematicExtended")
            }
        #endif

        var hdr = false
        #if os(iOS)
            hdr = device.activeFormat.isVideoHDRSupported
        #endif

        return [
            "flash": device.hasFlash,
            "torch": device.hasTorch,
            "zoom": range(1, maxZoom, supported: maxZoom > 1),
            "exposureOffset": range(Double(device.minExposureTargetBias), Double(device.maxExposureTargetBias)),
            "iso": range(Double(device.activeFormat.minISO), Double(device.activeFormat.maxISO), supported: device.isExposureModeSupported(.custom)),
            "exposureDuration": range(
                CMTimeGetSeconds(device.activeFormat.minExposureDuration) * 1000,
                CMTimeGetSeconds(device.activeFormat.maxExposureDuration) * 1000,
                supported: device.isExposureModeSupported(.custom)
            ),
            "focusDistance": range(0, 1, supported: device.isLockingFocusWithCustomLensPositionSupported),
            "temperature": range(2000, 8000, supported: device.isWhiteBalanceModeSupported(.locked)),
            "focusPoint": device.isFocusPointOfInterestSupported,
            "exposurePoint": device.isExposurePointOfInterestSupported,
            "manualFocus": device.isLockingFocusWithCustomLensPositionSupported,
            "manualExposure": device.isExposureModeSupported(.custom),
            "whiteBalance": device.isWhiteBalanceModeSupported(.locked),
            "stabilization": stabilization,
            "hdr": hdr,
            "nightMode": false,
            "rawCapture": !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty,
            "depthCapture": photoOutput.isDepthDataDeliverySupported,
            "videoRecording": true,
            "pauseRecording": false,
            "audioRecording": true,
            "imageStream": true,
            "platformScanning": true,
            "multiCamera": false,
            "pictureInPicture": false,
            "lensSwitching": false,
            "orientationLock": true,
            "snapshot": true,
            "videoCodecs": ["h264", "hevc"],
            "photoFormats": ["jpeg", "png", "heic"],
            "frameFormats": ["bgra8888", "gray8"],
            "maxPhotoSize": NSNull(),
            "maxVideoSize": NSNull(),
            "maxFps": Double(device.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30),
        ]
    }

    private func range(_ min: Double, _ max: Double, supported: Bool = true) -> [String: Any] {
        ["min": min, "max": max, "step": 0.0, "supported": supported && max > min]
    }

    private func send(_ payload: [String: Any]) {
        DispatchQueue.main.async { [weak self] in self?.eventSink?(payload) }
    }

    // MARK: - Controls

    private func configure(_ block: (AVCaptureDevice) -> Void) {
        guard let device else { return }
        do {
            try device.lockForConfiguration()
            block(device)
            device.unlockForConfiguration()
        } catch {
            // The device is busy; the setting is skipped rather than failing.
        }
    }

    public func applyFlash(_ mode: String?) {
        configure { device in
            guard device.hasTorch else { return }
            if mode == "torch" {
                if device.isTorchModeSupported(.on) { device.torchMode = .on }
            } else if device.isTorchModeSupported(.off) {
                device.torchMode = .off
            }
        }
        send(["event": "torch", "on": mode == "torch"])
    }

    public func setTorch(_ on: Bool) {
        configure { device in
            guard device.hasTorch else { return }
            device.torchMode = on ? .on : .off
        }
        send(["event": "torch", "on": on])
    }

    public func setZoom(_ zoom: Double) {
        #if os(iOS)
            configure { device in
                device.videoZoomFactor = max(1.0, min(CGFloat(zoom), device.activeFormat.videoMaxZoomFactor))
            }
            send(["event": "zoom", "zoom": zoomFactor()])
        #endif
    }

    public func setExposureOffset(_ offset: Double) {
        configure { device in
            device.setExposureTargetBias(Float(offset), completionHandler: nil)
        }
    }

    public func setExposureMode(_ mode: String?) {
        configure { device in
            switch mode {
            case "locked":
                if device.isExposureModeSupported(.locked) { device.exposureMode = .locked }
            case "manual":
                if device.isExposureModeSupported(.custom) { device.exposureMode = .custom }
            default:
                if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
            }
        }
    }

    public func setPoint(x: Double?, y: Double?, focus: Bool) {
        configure { device in
            guard let x, let y else { return }
            let point = CGPoint(x: x, y: y)
            if focus {
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    if device.isFocusModeSupported(.autoFocus) { device.focusMode = .autoFocus }
                }
            } else if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                if device.isExposureModeSupported(.autoExpose) { device.exposureMode = .autoExpose }
            }
        }
        if focus, let x, let y { send(["event": "focus", "point": [x, y]]) }
    }

    public func setFocusMode(_ mode: String?) {
        configure { device in
            switch mode {
            case "locked", "manual":
                if device.isFocusModeSupported(.locked) { device.focusMode = .locked }
            case "auto":
                if device.isFocusModeSupported(.autoFocus) { device.focusMode = .autoFocus }
            default:
                if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            }
        }
    }

    public func setFocusDistance(_ distance: Double) {
        configure { device in
            guard device.isLockingFocusWithCustomLensPositionSupported else { return }
            device.setFocusModeLocked(lensPosition: Float(max(0, min(1, distance))), completionHandler: nil)
        }
    }

    public func setIso(_ iso: Double) {
        configure { device in
            guard device.isExposureModeSupported(.custom) else { return }
            let clamped = Float(max(Double(device.activeFormat.minISO), min(iso, Double(device.activeFormat.maxISO))))
            device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: clamped, completionHandler: nil)
        }
    }

    public func setExposureDuration(micros: Int64) {
        configure { device in
            guard device.isExposureModeSupported(.custom) else { return }
            let duration = CMTimeMake(value: micros, timescale: 1_000_000)
            device.setExposureModeCustom(duration: duration, iso: AVCaptureDevice.currentISO, completionHandler: nil)
        }
    }

    public func setWhiteBalance(_ mode: String?, temperature: Double?) {
        configure { device in
            if mode == "locked" || mode == "manual" {
                guard device.isWhiteBalanceModeSupported(.locked) else { return }
                if let temperature {
                    let values = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: Float(temperature), tint: 0)
                    var gains = device.deviceWhiteBalanceGains(for: values)
                    let maxGain = device.maxWhiteBalanceGain
                    gains.redGain = max(1, min(gains.redGain, maxGain))
                    gains.greenGain = max(1, min(gains.greenGain, maxGain))
                    gains.blueGain = max(1, min(gains.blueGain, maxGain))
                    device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
                } else {
                    device.whiteBalanceMode = .locked
                }
            } else if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        }
    }

    public func setStabilization(_ mode: String?) {
        #if os(iOS)
            guard let connection = movieOutput.connection(with: .video) else { return }
            guard connection.isVideoStabilizationSupported else { return }
            switch mode {
            case "off": connection.preferredVideoStabilizationMode = .off
            case "cinematic": connection.preferredVideoStabilizationMode = .cinematic
            case "cinematicExtended":
                if #available(iOS 13.0, *) { connection.preferredVideoStabilizationMode = .cinematicExtended }
            case "standard": connection.preferredVideoStabilizationMode = .standard
            default: connection.preferredVideoStabilizationMode = .auto
            }
        #endif
    }

    public func setHdr(_ on: Bool) {
        #if os(iOS)
            configure { device in
                guard device.activeFormat.isVideoHDRSupported else { return }
                device.automaticallyAdjustsVideoHDREnabled = false
                device.isVideoHDREnabled = on
            }
        #endif
    }

    public func setPreviewPaused(_ paused: Bool) {
        queue.async { [weak self] in
            guard let self else { return }
            if paused {
                if self.session.isRunning { self.session.stopRunning() }
            } else if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    public func lockOrientation(_ name: String?) {
        #if os(iOS)
            guard let connection = photoOutput.connection(with: .video) else { return }
            let orientation: AVCaptureVideoOrientation
            switch name {
            case "landscapeRight": orientation = .landscapeRight
            case "portraitDown": orientation = .portraitUpsideDown
            case "landscapeLeft": orientation = .landscapeLeft
            default: orientation = .portrait
            }
            if connection.isVideoOrientationSupported { connection.videoOrientation = orientation }
        #endif
    }

    // MARK: - Capture

    public func takePhoto(arguments: [String: Any], completion: @escaping ([String: Any]?, String?) -> Void) {
        photoCompletion = completion
        photoPath = arguments["path"] as? String
        includePhotoBytes = arguments["includeBytes"] as? Bool ?? true

        var settings = AVCapturePhotoSettings()
        let format = arguments["format"] as? String ?? "jpeg"
        if format == "heic", photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else if format == "png" {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        }
        #if os(iOS)
            if device?.hasFlash == true {
                switch config["flash"] as? String {
                case "on": settings.flashMode = .on
                case "auto": settings.flashMode = .auto
                default: settings.flashMode = .off
                }
            }
        #endif
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    public func takeSnapshot(quality: Int, completion: @escaping ([String: Any]?, String?) -> Void) {
        bufferLock.lock()
        let buffer = latestBuffer
        bufferLock.unlock()
        guard let buffer else {
            completion(nil, "capture")
            return
        }
        let image = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            completion(nil, "capture")
            return
        }
        guard let data = UCameraImageCodec.encodeJpeg(cgImage, quality: Double(quality) / 100.0) else {
            completion(nil, "capture")
            return
        }
        completion(
            [
                "bytes": FlutterStandardTypedData(bytes: data),
                "width": cgImage.width,
                "height": cgImage.height,
                "format": "jpeg",
                "orientation": 0,
                "sizeInBytes": data.count,
            ],
            nil
        )
    }

    public func startRecording(arguments: [String: Any], completion: @escaping (String?) -> Void) {
        guard !movieOutput.isRecording else {
            completion("recording")
            return
        }
        let path = arguments["path"] as? String ?? UCameraSession.temporaryFile(extension: "mov")
        #if os(iOS)
            if let connection = movieOutput.connection(with: .video), connection.isVideoMirroringSupported {
                connection.isVideoMirrored = device?.position == .front && (config["mirrorFrontCapture"] as? Bool ?? false)
            }
            if let codec = arguments["codec"] as? String,
               let connection = movieOutput.connection(with: .video) {
                let type: AVVideoCodecType = codec == "hevc" ? .hevc : .h264
                if movieOutput.availableVideoCodecTypes.contains(type) {
                    movieOutput.setOutputSettings([AVVideoCodecKey: type], for: connection)
                }
            }
        #endif
        if let maxDuration = arguments["maxDurationMs"] as? Int {
            movieOutput.maxRecordedDuration = CMTimeMake(value: Int64(maxDuration), timescale: 1000)
        }
        if let maxBytes = arguments["maxBytes"] as? Int {
            movieOutput.maxRecordedFileSize = Int64(maxBytes)
        }
        recordingStartedAt = Date()
        movieOutput.startRecording(to: URL(fileURLWithPath: path), recordingDelegate: self)
        completion(nil)
    }

    public func stopRecording(completion: @escaping ([String: Any]?, String?) -> Void) {
        guard movieOutput.isRecording else {
            completion(nil, "notFound")
            return
        }
        recordingCompletion = completion
        movieOutput.stopRecording()
    }

    // MARK: - Streaming and scanning

    public func startImageStream(format: String?, maxFps: Double?, downscale _: Int?) {
        frameFormat = format ?? frameFormat
        if let maxFps, maxFps > 0 { frameInterval = 1.0 / maxFps }
        streamingFrames = true
    }

    public func stopImageStream() {
        streamingFrames = false
    }

    public func startScanning(formats: [String]) {
        queue.async { [weak self] in
            guard let self else { return }
            let types = UCameraMapper.metadataTypes(for: formats)
            let available = self.metadataOutput.availableMetadataObjectTypes
            self.metadataOutput.metadataObjectTypes = types.filter { available.contains($0) }
        }
    }

    public func stopScanning() {
        queue.async { [weak self] in self?.metadataOutput.metadataObjectTypes = [] }
    }

    static func temporaryFile(extension ext: String) -> String {
        let directory = NSTemporaryDirectory().appending("u_camera/")
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        return directory.appending("\(Int(Date().timeIntervalSince1970 * 1000)).\(ext)")
    }
}

// MARK: - FlutterTexture

extension UCameraSession: FlutterTexture {
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        guard let buffer = latestBuffer else { return nil }
        return Unmanaged.passRetained(buffer)
    }
}

// MARK: - Frames

extension UCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from _: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        bufferLock.lock()
        latestBuffer = buffer
        bufferLock.unlock()
        if textureId >= 0 { registry.textureFrameAvailable(textureId) }

        guard streamingFrames else { return }
        let now = Date().timeIntervalSince1970
        guard now - lastFrameAt >= frameInterval else { return }
        lastFrameAt = now

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }

        if frameFormat == "gray8" {
            var gray = Data(count: width * height)
            gray.withUnsafeMutableBytes { destination in
                guard let out = destination.bindMemory(to: UInt8.self).baseAddress else { return }
                let source = base.assumingMemoryBound(to: UInt8.self)
                for y in 0 ..< height {
                    let row = source.advanced(by: y * stride)
                    for x in 0 ..< width {
                        let pixel = row.advanced(by: x * 4)
                        let b = Int(pixel[0])
                        let g = Int(pixel[1])
                        let r = Int(pixel[2])
                        out[y * width + x] = UInt8((r * 77 + g * 151 + b * 28) >> 8)
                    }
                }
            }
            emitFrame(planes: [gray], format: "gray8", width: width, height: height, strides: [width])
        } else {
            let data = Data(bytes: base, count: stride * height)
            emitFrame(planes: [data], format: "bgra8888", width: width, height: height, strides: [stride])
        }
    }

    private func emitFrame(planes: [Data], format: String, width: Int, height: Int, strides: [Int]) {
        let payload: [String: Any] = [
            "planes": planes.map { FlutterStandardTypedData(bytes: $0) },
            "format": format,
            "width": width,
            "height": height,
            "rowStrides": strides,
            "pixelStrides": [format == "gray8" ? 1 : 4],
            "rotation": 0,
            "mirrored": device?.position == .front && mirrorFront,
            "timestampUs": Int(Date().timeIntervalSince1970 * 1_000_000),
        ]
        DispatchQueue.main.async { [weak self] in self?.frameSink?(payload) }
    }
}

// MARK: - Barcodes

extension UCameraSession: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(
        _: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from _: AVCaptureConnection
    ) {
        var codes: [[String: Any]] = []
        for object in metadataObjects {
            guard let readable = object as? AVMetadataMachineReadableCodeObject,
                  let value = readable.stringValue else { continue }
            let corners = readable.corners.map { [Double($0.x), Double($0.y)] }
            codes.append([
                "format": UCameraMapper.formatName(readable.type),
                "text": value,
                "bytes": FlutterStandardTypedData(bytes: Data(value.utf8)),
                "corners": corners,
                "inverted": false,
            ])
        }
        guard !codes.isEmpty else { return }
        send(["event": "codes", "codes": codes])
    }
}

// MARK: - Photo

extension UCameraSession: AVCapturePhotoCaptureDelegate {
    public func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let completion = photoCompletion
        photoCompletion = nil
        if let error {
            completion?(nil, error.localizedDescription)
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            completion?(nil, "capture")
            return
        }
        let path = photoPath ?? UCameraSession.temporaryFile(extension: "jpg")
        try? data.write(to: URL(fileURLWithPath: path))
        completion?(
            [
                "path": path,
                "bytes": includePhotoBytes ? FlutterStandardTypedData(bytes: data) : NSNull(),
                "width": photo.resolvedSettings.photoDimensions.width,
                "height": photo.resolvedSettings.photoDimensions.height,
                "format": "jpeg",
                "orientation": 0,
                "sizeInBytes": data.count,
                "mirrored": device?.position == .front,
            ],
            nil
        )
    }
}

// MARK: - Recording

extension UCameraSession: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(
        _: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from _: [AVCaptureConnection],
        error: Error?
    ) {
        let completion = recordingCompletion
        recordingCompletion = nil
        let duration = Date().timeIntervalSince(recordingStartedAt ?? Date())
        recordingStartedAt = nil
        if let error, (error as NSError).code != AVError.maximumDurationReached.rawValue {
            completion?(nil, error.localizedDescription)
            return
        }
        let attributes = try? FileManager.default.attributesOfItem(atPath: outputFileURL.path)
        completion?(
            [
                "path": outputFileURL.path,
                "durationMs": Int(duration * 1000),
                "width": 0,
                "height": 0,
                "sizeInBytes": (attributes?[.size] as? Int) ?? 0,
                "container": "mov",
            ],
            nil
        )
    }
}

final class UCameraStreamProxy: NSObject, FlutterStreamHandler {
    private let onSink: (FlutterEventSink?) -> Void

    init(onSink: @escaping (FlutterEventSink?) -> Void) {
        self.onSink = onSink
    }

    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        onSink(events)
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        onSink(nil)
        return nil
    }
}

enum UCameraImageCodec {
    static func encodeJpeg(_ image: CGImage, quality: Double) -> Data? {
        #if os(iOS)
            return UIImage(cgImage: image).jpegData(compressionQuality: CGFloat(quality))
        #else
            let bitmap = NSBitmapImageRep(cgImage: image)
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        #endif
    }
}

enum UCameraEnumerator {
    static func describe(_ device: AVCaptureDevice) -> [String: Any] {
        var maxZoom = 1.0
        #if os(iOS)
            maxZoom = Double(device.activeFormat.videoMaxZoomFactor)
        #endif
        let formats = device.formats.map { format -> [String: Any] in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return [
                "size": ["width": Int(dimensions.width), "height": Int(dimensions.height)],
                "minFps": Double(format.videoSupportedFrameRateRanges.first?.minFrameRate ?? 0),
                "maxFps": Double(format.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30),
            ]
        }
        return [
            "id": device.uniqueID,
            "name": device.localizedName,
            "facing": UCameraMapper.facingName(device.position),
            "lens": UCameraMapper.lensName(device),
            "sensorOrientation": 0,
            "hasFlash": device.hasFlash,
            "isLogical": device.isVirtualDevice,
            "physicalDeviceIds": device.constituentDevices.map(\.uniqueID),
            "focalLengths": [] as [Double],
            "minFocusDistance": 0.0,
            "formats": formats,
            "minZoom": 1.0,
            "maxZoom": maxZoom,
            "neutralZoom": 1.0,
        ]
    }

    static func list() -> [[String: Any]] {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: UCameraMapper.deviceTypes(),
            mediaType: .video,
            position: .unspecified
        )
        return discovery.devices.map(describe)
    }
}

/// Decodes symbols from a still image with Vision, which is part of the OS and
/// therefore adds nothing to the app bundle.
enum UCameraVision {
    static func analyze(image: CGImage, completion: @escaping ([[String: Any]]) -> Void) {
        let request = VNDetectBarcodesRequest { request, _ in
            let results = (request.results as? [VNBarcodeObservation]) ?? []
            let codes: [[String: Any]] = results.compactMap { observation in
                guard let value = observation.payloadStringValue else { return nil }
                let width = Double(image.width)
                let height = Double(image.height)
                let box = observation.boundingBox
                let corners: [[Double]] = [
                    [box.minX * width, (1 - box.maxY) * height],
                    [box.maxX * width, (1 - box.maxY) * height],
                    [box.maxX * width, (1 - box.minY) * height],
                    [box.minX * width, (1 - box.minY) * height],
                ]
                return [
                    "format": UCameraMapper.visionFormatName(observation.symbology),
                    "text": value,
                    "bytes": FlutterStandardTypedData(bytes: Data(value.utf8)),
                    "corners": corners,
                    "inverted": false,
                ]
            }
            completion(codes)
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

public final class UCameraHandler: NSObject {
    private let channel: FlutterMethodChannel
    private let messenger: FlutterBinaryMessenger
    private let registry: FlutterTextureRegistry
    private var sessions: [Int: UCameraSession] = [:]
    private var nextId = 1

    public init(messenger: FlutterBinaryMessenger, registry: FlutterTextureRegistry) {
        self.messenger = messenger
        self.registry = registry
        channel = FlutterMethodChannel(name: "u/camera", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    public func dispose() {
        sessions.values.forEach { $0.dispose() }
        sessions.removeAll()
        channel.setMethodCallHandler(nil)
    }

    private func arguments(_ call: FlutterMethodCall) -> [String: Any] {
        (call.arguments as? [String: Any]) ?? [:]
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = arguments(call)
        switch call.method {
        case "isSupported":
            result(!AVCaptureDevice.DiscoverySession(
                deviceTypes: UCameraMapper.deviceTypes(),
                mediaType: .video,
                position: .unspecified
            ).devices.isEmpty)
        case "availableCameras":
            result(UCameraEnumerator.list())
        case "permissionStatus":
            result(permissionMap())
        case "requestPermission":
            requestPermission(audio: args["audio"] as? Bool ?? false, result: result)
        case "openSettings":
            result(openSettings())
        case "create":
            createSession(config: args["config"] as? [String: Any] ?? [:], result: result)
        case "analyzeImage":
            analyzeImage(args, result: result)
        default:
            handleSession(call, args: args, result: result)
        }
    }

    private func permissionName(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "granted"
        case .denied: return "permanentlyDenied"
        case .restricted: return "restricted"
        default: return "denied"
        }
    }

    private func permissionMap() -> [String: Any] {
        [
            "camera": permissionName(AVCaptureDevice.authorizationStatus(for: .video)),
            "microphone": permissionName(AVCaptureDevice.authorizationStatus(for: .audio)),
        ]
    }

    private func requestPermission(audio: Bool, result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
            guard let self else { return }
            guard audio else {
                DispatchQueue.main.async { result(self.permissionMap()) }
                return
            }
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                DispatchQueue.main.async { result(self.permissionMap()) }
            }
        }
    }

    private func openSettings() -> Bool {
        #if os(iOS)
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return false }
            DispatchQueue.main.async { UIApplication.shared.open(url) }
            return true
        #else
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") else { return false }
            NSWorkspace.shared.open(url)
            return true
        #endif
    }

    private func createSession(config: [String: Any], result: @escaping FlutterResult) {
        let id = nextId
        nextId += 1
        let session = UCameraSession(sessionId: id, messenger: messenger, registry: registry, config: config)
        sessions[id] = session
        session.open { description, error in
            if let description {
                result(description)
            } else {
                self.sessions.removeValue(forKey: id)?.dispose()
                result(FlutterError(code: error ?? "unknown", message: "Unable to open camera", details: nil))
            }
        }
    }

    private func analyzeImage(_ args: [String: Any], result: @escaping FlutterResult) {
        var image: CGImage?
        if let path = args["path"] as? String, let data = FileManager.default.contents(atPath: path) {
            image = UCameraHandler.decode(data)
        } else if let typed = args["bytes"] as? FlutterStandardTypedData {
            image = UCameraHandler.decode(typed.data)
        }
        guard let image else {
            result([])
            return
        }
        UCameraVision.analyze(image: image) { codes in
            DispatchQueue.main.async { result(codes) }
        }
    }

    private static func decode(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func handleSession(_ call: FlutterMethodCall, args: [String: Any], result: @escaping FlutterResult) {
        guard let id = args["sessionId"] as? Int, let session = sessions[id] else {
            result(FlutterError(code: "notFound", message: "Camera session not found", details: nil))
            return
        }

        switch call.method {
        case "dispose":
            sessions.removeValue(forKey: id)?.dispose()
            result(nil)
        case "takePhoto":
            session.takePhoto(arguments: args) { photo, error in
                if let photo { result(photo) } else { result(FlutterError(code: error ?? "capture", message: "Photo failed", details: nil)) }
            }
        case "takeSnapshot":
            session.takeSnapshot(quality: args["quality"] as? Int ?? 90) { photo, error in
                if let photo { result(photo) } else { result(FlutterError(code: error ?? "capture", message: "Snapshot failed", details: nil)) }
            }
        case "startRecording":
            session.startRecording(arguments: args) { error in
                if let error { result(FlutterError(code: "recording", message: error, details: nil)) } else { result(nil) }
            }
        case "stopRecording":
            session.stopRecording { video, error in
                if let video { result(video) } else { result(FlutterError(code: error ?? "recording", message: "Stop failed", details: nil)) }
            }
        case "pauseRecording", "resumeRecording":
            result(FlutterError(code: "unsupported", message: "Pausing a recording is not supported here", details: nil))
        case "setFlashMode":
            session.applyFlash(args["mode"] as? String)
            result(nil)
        case "setTorch":
            session.setTorch(args["on"] as? Bool ?? false)
            result(nil)
        case "setZoom":
            session.setZoom(args["zoom"] as? Double ?? 1)
            result(nil)
        case "setExposureOffset":
            session.setExposureOffset(args["offset"] as? Double ?? 0)
            result(nil)
        case "setExposureMode":
            session.setExposureMode(args["mode"] as? String)
            result(nil)
        case "setExposurePoint":
            session.setPoint(x: args["x"] as? Double, y: args["y"] as? Double, focus: false)
            result(nil)
        case "setFocusMode":
            session.setFocusMode(args["mode"] as? String)
            result(nil)
        case "setFocusPoint":
            session.setPoint(x: args["x"] as? Double, y: args["y"] as? Double, focus: true)
            result(nil)
        case "setFocusDistance":
            session.setFocusDistance(args["distance"] as? Double ?? 0)
            result(nil)
        case "setIso":
            session.setIso(args["iso"] as? Double ?? 100)
            result(nil)
        case "setExposureDuration":
            session.setExposureDuration(micros: Int64(args["micros"] as? Int ?? 0))
            result(nil)
        case "setWhiteBalance":
            session.setWhiteBalance(args["mode"] as? String, temperature: args["temperature"] as? Double)
            result(nil)
        case "setStabilization":
            session.setStabilization(args["mode"] as? String)
            result(nil)
        case "setHdr":
            session.setHdr(args["mode"] as? String == "on")
            result(nil)
        case "setNightMode":
            result(FlutterError(code: "unsupported", message: "Night mode is handled by the system here", details: nil))
        case "setPreviewPaused":
            session.setPreviewPaused(args["paused"] as? Bool ?? false)
            result(nil)
        case "lockOrientation":
            session.lockOrientation(args["orientation"] as? String)
            result(nil)
        case "unlockOrientation":
            session.lockOrientation(nil)
            result(nil)
        case "startImageStream":
            session.startImageStream(
                format: args["format"] as? String,
                maxFps: args["maxFps"] as? Double,
                downscale: args["downscale"] as? Int
            )
            result(nil)
        case "stopImageStream":
            session.stopImageStream()
            result(nil)
        case "startScanning":
            let options = args["options"] as? [String: Any] ?? [:]
            session.startScanning(formats: options["formats"] as? [String] ?? [])
            result(nil)
        case "stopScanning":
            session.stopScanning()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
