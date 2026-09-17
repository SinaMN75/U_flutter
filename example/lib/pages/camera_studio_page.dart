import "package:u/utilities.dart";

/// A live camera screen that surfaces every control [UCameraController] exposes,
/// plus a capability readout and frame-stream statistics. Controls the hardware
/// does not support are hidden rather than disabled, which is the same rule the
/// built-in [UCameraPage] follows.
class CameraStudioPage extends StatefulWidget {
  const CameraStudioPage({super.key});

  @override
  State<CameraStudioPage> createState() => _CameraStudioPageState();
}

class _CameraStudioPageState extends State<CameraStudioPage> with WidgetsBindingObserver {
  UCameraController? _controller;
  String? _error;

  List<UCameraDevice> _devices = <UCameraDevice>[];
  int _deviceIndex = 0;
  UCameraResolution _resolution = UCameraResolution.high;

  StreamSubscription<UCameraFrame>? _frames;
  int _frameCount = 0;
  double _fps = 0;
  DateTime _fpsWindowStart = DateTime.now();
  String _frameInfo = "-";

  UCapturedPhoto? _lastPhoto;
  UCapturedVideo? _lastVideo;
  UMediaController? _player;
  bool _showPanel = true;
  double _baseZoom = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_frames?.cancel());
    unawaited(_controller?.dispose());
    _player?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final UCameraController? controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(controller.suspend());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(controller.resume());
    }
  }

  Future<void> _open() async {
    setState(() => _error = null);
    final UCameraPermissionState permission = await UCameraController.requestPermission(audio: true);
    if (!permission.isGranted) {
      setState(() => _error = "Camera permission denied");
      return;
    }
    _devices = await UCameraController.availableCameras();
    if (_devices.isEmpty) {
      setState(() => _error = "No camera found on this device");
      return;
    }

    final UCameraController controller = UCameraController(
      config: UCameraConfig(
        deviceId: _devices[_deviceIndex % _devices.length].id,
        resolution: _resolution,
        imageStream: true,
        frameFormat: UFrameFormat.gray8,
        frameMaxFps: 15,
      ),
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    if (controller.value.hasError) {
      setState(() => _error = controller.value.error?.message);
      await controller.dispose();
      return;
    }

    _frames = controller.frames.listen(_onFrame);
    setState(() => _controller = controller);
  }

  void _onFrame(UCameraFrame frame) {
    _frameCount++;
    final DateTime now = DateTime.now();
    final Duration elapsed = now.difference(_fpsWindowStart);
    if (elapsed.inMilliseconds < 1000) return;
    if (!mounted) return;
    setState(() {
      _fps = _frameCount * 1000 / elapsed.inMilliseconds;
      _frameInfo = "${frame.width}x${frame.height} ${frame.format.name} rot ${frame.rotation}°";
      _frameCount = 0;
      _fpsWindowStart = now;
    });
  }

  Future<void> _reopen() async {
    await _frames?.cancel();
    _frames = null;
    await _controller?.dispose();
    if (!mounted) return;
    setState(() => _controller = null);
    await _open();
  }

  Future<void> _nextDevice() async {
    if (_devices.length < 2) return;
    _deviceIndex = (_deviceIndex + 1) % _devices.length;
    await _reopen();
  }

  Future<void> _setResolution(UCameraResolution resolution) async {
    _resolution = resolution;
    await _reopen();
  }

  Future<void> _takePhoto() async {
    final UCameraController? controller = _controller;
    if (controller == null) return;
    final UCapturedPhoto? photo = await controller.takePhoto();
    if (photo == null || !mounted) return;
    setState(() => _lastPhoto = photo);
    UToast.success(message: "${photo.width}x${photo.height} · ${UCameraUtils.formatBytes(photo.sizeInBytes)}");
  }

  Future<void> _takeSnapshot() async {
    final UCameraController? controller = _controller;
    if (controller == null) return;
    final UCapturedPhoto? photo = await controller.takeSnapshot();
    if (photo == null || !mounted) return;
    setState(() => _lastPhoto = photo);
    UToast.info(message: "Snapshot ${photo.width}x${photo.height}");
  }

  Future<void> _toggleRecording() async {
    final UCameraController? controller = _controller;
    if (controller == null) return;
    if (controller.value.isRecording) {
      final UCapturedVideo? video = await controller.stopVideoRecording();
      if (video == null || !mounted) return;
      setState(() => _lastVideo = video);
      _player?.dispose();
      _player = UMediaController(config: const UMediaConfig(repeat: URepeatMode.one));
      await _player!.open(kIsWeb ? UMediaSource.network(video.path) : UMediaSource.file(video.path), autoPlay: true);
      if (mounted) setState(() {});
    } else {
      await controller.startVideoRecording(maxDuration: const Duration(seconds: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    final UCameraController? controller = _controller;
    return UScaffold(
      safeArea: false,
      color: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text("Camera studio"),
        backgroundColor: const Color(0x66000000),
        foregroundColor: const Color(0xFFFFFFFF),
        actions: <Widget>[
          IconButton(
            icon: Icon(_showPanel ? Icons.visibility_off_rounded : Icons.visibility_rounded),
            onPressed: () => setState(() => _showPanel = !_showPanel),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _error != null
          ? _errorView()
          : controller == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<UCameraValue>(
              valueListenable: controller,
              builder: (BuildContext context, UCameraValue value, Widget? _) => Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _preview(controller, value),
                  if (value.isRecording) _recordingBadge(value),
                  if (_showPanel)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _panel(controller, value),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _errorView() => Center(
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Icon(Icons.no_photography_outlined, color: Color(0xB3FFFFFF), size: 48),
        UTextBodyMedium(_error ?? "", color: const Color(0xFFFFFFFF), textAlign: TextAlign.center),
        URow(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            UButton(title: "Retry", onTap: () => unawaited(_open())),
            UButton(type: UButtonType.outlined, title: "Settings", onTap: () => unawaited(UCameraController.openSettings())),
          ],
        ),
      ],
    ),
  );

  Widget _preview(UCameraController controller, UCameraValue value) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (ScaleStartDetails _) => _baseZoom = value.zoom,
      onScaleUpdate: (ScaleUpdateDetails details) {
        if (details.pointerCount == 2) unawaited(controller.setZoom(_baseZoom * details.scale));
      },
      onTapUp: (TapUpDetails details) => unawaited(
        controller.focusAndMeterAt(
          UCameraUtils.normalizePoint(
            local: details.localPosition,
            widgetSize: Size(box.maxWidth, box.maxHeight),
            previewSize: value.previewSize,
            mirrored: value.mirrored,
          ),
        ),
      ),
      child: UCameraPreview(controller: controller, child: const UCameraGrid()),
    ),
  );

  Widget _recordingBadge(UCameraValue value) => Positioned(
    top: 96,
    left: 0,
    right: 0,
    child: Center(
      child: UContainer(
        color: const Color(0xCCFF3B30),
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: UTextLabelLarge(
          "REC  ${UCameraUtils.formatDuration(value.recordingDuration)}",
          color: const Color(0xFFFFFFFF),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Control panel
  // ---------------------------------------------------------------------------

  Widget _panel(UCameraController controller, UCameraValue value) {
    final UCameraCapabilities capabilities = value.capabilities;
    return UContainer(
      color: const Color(0xCC000000),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.52),
          child: SingleChildScrollView(
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: <Widget>[
                _statusLine(value),
                _captureRow(controller, value),
                _deviceRow(controller, value),
                if (capabilities.flash || capabilities.torch) _flashRow(controller, value),
                if (!capabilities.zoom.isFixed) _slider("Zoom", value.zoom, capabilities.zoom, (double v) => controller.setZoom(v), suffix: "x"),
                if (!capabilities.exposureOffset.isFixed)
                  _slider("Exposure", value.exposureOffset, capabilities.exposureOffset, (double v) => controller.setExposureOffset(v), suffix: "EV"),
                if (!capabilities.iso.isFixed) _slider("ISO", value.iso ?? capabilities.iso.min, capabilities.iso, (double v) => controller.setIso(v)),
                if (!capabilities.exposureDuration.isFixed)
                  _slider(
                    "Shutter",
                    (value.exposureDuration?.inMicroseconds ?? capabilities.exposureDuration.min * 1000) / 1000,
                    capabilities.exposureDuration,
                    (double v) => controller.setExposureDuration(Duration(microseconds: (v * 1000).round())),
                    suffix: "ms",
                  ),
                if (!capabilities.focusDistance.isFixed)
                  _slider("Focus", capabilities.focusDistance.min, capabilities.focusDistance, (double v) => controller.setFocusDistance(v)),
                _modeRow(controller, value),
                _capabilityGrid(capabilities),
                if (_lastPhoto != null || _lastVideo != null) _resultRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusLine(UCameraValue value) => UTextBodySmall(
    "${value.state.name} · ${value.previewSize} · ${_fps.toStringAsFixed(1)} fps · $_frameInfo · "
    "${value.deviceOrientation.degrees}°${value.lockedOrientation != null ? " (locked)" : ""}",
    color: const Color(0xB3FFFFFF),
  );

  Widget _captureRow(UCameraController controller, UCameraValue value) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      UButton(title: "Photo", icon: const Icon(Icons.camera_rounded, size: 18), onTap: () => unawaited(_takePhoto())),
      if (value.capabilities.snapshot)
        UButton(type: UButtonType.outlined, title: "Snapshot", icon: const Icon(Icons.bolt_rounded, size: 18), onTap: () => unawaited(_takeSnapshot())),
      if (value.capabilities.videoRecording)
        UButton(
          type: value.isRecording ? UButtonType.elevated : UButtonType.outlined,
          title: value.isRecording ? "Stop" : "Record",
          icon: Icon(value.isRecording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded, size: 18),
          onTap: () => unawaited(_toggleRecording()),
        ),
      if (value.isRecording && value.capabilities.pauseRecording)
        UButton(
          type: UButtonType.text,
          title: value.isRecordingPaused ? "Resume" : "Pause",
          onTap: () => unawaited(value.isRecordingPaused ? controller.resumeVideoRecording() : controller.pauseVideoRecording()),
        ),
    ],
  );

  Widget _deviceRow(UCameraController controller, UCameraValue value) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      if (_devices.length > 1)
        UButton(
          type: UButtonType.outlined,
          title: _devices[_deviceIndex % _devices.length].name,
          icon: const Icon(Icons.cameraswitch_rounded, size: 18),
          onTap: () => unawaited(_nextDevice()),
        ),
      ...UCameraResolution.values.map(
        (UCameraResolution resolution) => UButton(
          type: _resolution == resolution ? UButtonType.elevated : UButtonType.text,
          size: UButtonSize.small,
          title: UCameraUtils.resolutionLabel(resolution),
          onTap: () => unawaited(_setResolution(resolution)),
        ),
      ),
    ],
  );

  Widget _flashRow(UCameraController controller, UCameraValue value) => Wrap(
    spacing: 8,
    children: UFlashMode.values
        .map(
          (UFlashMode mode) => UButton(
            type: value.flash == mode ? UButtonType.elevated : UButtonType.text,
            size: UButtonSize.small,
            title: mode.name,
            icon: Icon(UCameraUtils.flashIcon(mode), size: 16),
            onTap: () => unawaited(controller.setFlashMode(mode)),
          ),
        )
        .toList(growable: false),
  );

  Widget _modeRow(UCameraController controller, UCameraValue value) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      UButton(
        type: value.isPreviewPaused ? UButtonType.elevated : UButtonType.text,
        size: UButtonSize.small,
        title: value.isPreviewPaused ? "Resume preview" : "Pause preview",
        onTap: () => unawaited(value.isPreviewPaused ? controller.resumePreview() : controller.pausePreview()),
      ),
      if (value.capabilities.orientationLock)
        UButton(
          type: value.lockedOrientation != null ? UButtonType.elevated : UButtonType.text,
          size: UButtonSize.small,
          title: value.lockedOrientation != null ? "Unlock rotation" : "Lock rotation",
          onTap: () => unawaited(value.lockedOrientation != null ? controller.unlockCaptureOrientation() : controller.lockCaptureOrientation()),
        ),
      if (value.capabilities.hdr)
        UButton(
          type: value.hdr == UHdrMode.on ? UButtonType.elevated : UButtonType.text,
          size: UButtonSize.small,
          title: "HDR",
          onTap: () => unawaited(controller.setHdr(value.hdr == UHdrMode.on ? UHdrMode.off : UHdrMode.on)),
        ),
      if (value.capabilities.nightMode)
        UButton(
          type: value.nightMode == UNightMode.on ? UButtonType.elevated : UButtonType.text,
          size: UButtonSize.small,
          title: "Night",
          onTap: () => unawaited(controller.setNightMode(value.nightMode == UNightMode.on ? UNightMode.off : UNightMode.on)),
        ),
      ...value.capabilities.stabilization.map(
        (UStabilizationMode mode) => UButton(
          type: value.stabilization == mode ? UButtonType.elevated : UButtonType.text,
          size: UButtonSize.small,
          title: "IS ${mode.name}",
          onTap: () => unawaited(controller.setStabilization(mode)),
        ),
      ),
      if (value.capabilities.whiteBalance)
        UButton(
          type: UButtonType.text,
          size: UButtonSize.small,
          title: "WB ${value.whiteBalance.name}",
          onTap: () {
            final List<UWhiteBalanceMode> order = UWhiteBalanceMode.values;
            final UWhiteBalanceMode next = order[(order.indexOf(value.whiteBalance) + 1) % order.length];
            unawaited(controller.setWhiteBalance(next));
          },
        ),
      UButton(
        type: UButtonType.text,
        size: UButtonSize.small,
        title: "Focus ${value.focusMode.name}",
        onTap: () {
          final List<UFocusMode> order = UFocusMode.values;
          final UFocusMode next = order[(order.indexOf(value.focusMode) + 1) % order.length];
          unawaited(controller.setFocusMode(next));
        },
      ),
    ],
  );

  Widget _slider(String label, double current, UCameraRange range, Future<void> Function(double) onChanged, {String suffix = ""}) => URow(
    spacing: 8,
    children: <Widget>[
      SizedBox(width: 62, child: UTextLabelSmall(label, color: const Color(0xFFFFFFFF))),
      Expanded(
        child: Slider(
          value: range.clamp(current),
          min: range.min,
          max: range.max,
          onChanged: (double value) => unawaited(onChanged(value)),
        ),
      ),
      SizedBox(
        width: 58,
        child: UTextLabelSmall("${range.clamp(current).toStringAsFixed(1)}$suffix", color: const Color(0xB3FFFFFF)),
      ),
    ],
  );

  Widget _capabilityGrid(UCameraCapabilities capabilities) {
    final Map<String, bool> flags = <String, bool>{
      "flash": capabilities.flash,
      "torch": capabilities.torch,
      "zoom": !capabilities.zoom.isFixed,
      "exposure": !capabilities.exposureOffset.isFixed,
      "manual ISO": !capabilities.iso.isFixed,
      "manual shutter": !capabilities.exposureDuration.isFixed,
      "manual focus": capabilities.manualFocus,
      "focus point": capabilities.focusPoint,
      "exposure point": capabilities.exposurePoint,
      "white balance": capabilities.whiteBalance,
      "HDR": capabilities.hdr,
      "night": capabilities.nightMode,
      "RAW": capabilities.rawCapture,
      "depth": capabilities.depthCapture,
      "video": capabilities.videoRecording,
      "pause rec": capabilities.pauseRecording,
      "audio": capabilities.audioRecording,
      "frames": capabilities.imageStream,
      "native scan": capabilities.platformScanning,
      "multi-cam": capabilities.multiCamera,
      "lens switch": capabilities.lensSwitching,
      "snapshot": capabilities.snapshot,
      "PiP": capabilities.pictureInPicture,
      "orientation lock": capabilities.orientationLock,
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: flags.entries
          .map(
            (MapEntry<String, bool> entry) => UContainer(
              color: entry.value ? const Color(0x3300E676) : const Color(0x1AFFFFFF),
              radius: 6,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              child: UTextLabelSmall(
                entry.key,
                color: entry.value ? const Color(0xFF69F0AE) : const Color(0x80FFFFFF),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _resultRow() => URow(
    spacing: 10,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (_lastPhoto?.bytes != null)
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_lastPhoto!.bytes!, width: 84, height: 84, fit: BoxFit.cover)),
      if (_player != null) SizedBox(width: 120, height: 84, child: UVideoView(controller: _player!, fit: UMediaFit.cover)),
      Expanded(
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: <Widget>[
            if (_lastPhoto != null)
              UTextBodySmall(
                "photo ${_lastPhoto!.width}x${_lastPhoto!.height} ${_lastPhoto!.format.name} "
                "${UCameraUtils.formatBytes(_lastPhoto!.sizeInBytes)}",
                color: const Color(0xB3FFFFFF),
              ),
            if (_lastVideo != null)
              UTextBodySmall(
                "video ${UCameraUtils.formatDuration(_lastVideo!.duration)} "
                "${UCameraUtils.formatBytes(_lastVideo!.sizeInBytes)} ${_lastVideo!.container.name}",
                color: const Color(0xB3FFFFFF),
              ),
          ],
        ),
      ),
    ],
  );
}
