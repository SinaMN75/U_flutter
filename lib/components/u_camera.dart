import "package:u/utilities.dart";

// =============================================================================
// u_camera — the camera UI of the `u` plugin.
//
// [UCameraPreview] renders a live session, [UCameraPage] is a complete camera
// screen, and [UCamera] gives one-call helpers that return [FileData] so
// captures flow through the app like any other picked file. Everything is
// driven by [UCameraController], so every hardware feature the device exposes
// is reachable, and anything it does not support is hidden automatically.
// =============================================================================

enum UCameraMode { photo, video, both }

/// Optional label overrides; anything left null falls back to l10n.
class UCameraLabels {
  const UCameraLabels({this.retake, this.use, this.done, this.cancel, this.noCameraMessage, this.permissionMessage});

  final String? retake;
  final String? use;
  final String? done;
  final String? cancel;
  final String? noCameraMessage;
  final String? permissionMessage;
}

/// Full configuration of [UCameraPage]. Every control can be switched off, and
/// controls the device cannot support hide themselves.
class UCameraOptions {
  const UCameraOptions({
    this.mode = UCameraMode.photo,
    this.allowMultiple = false,
    this.maxCount = 0,
    this.resolution = UCameraResolution.veryHigh,
    this.startFront = false,
    this.enableFlash = true,
    this.enableCameraSwitch = true,
    this.enableGrid = true,
    this.enableLevel = false,
    this.enablePinchZoom = true,
    this.enableZoomSlider = false,
    this.enableZoomPresets = true,
    this.enableTapToFocus = true,
    this.enableExposure = true,
    this.enableSelfTimer = true,
    this.enableAudio = true,
    this.enableStabilization = true,
    this.enableHdr = false,
    this.enableManualControls = false,
    this.enableAspectRatioToggle = false,
    this.confirmCapture = true,
    this.mirrorFrontPreview = true,
    this.mirrorFrontCapture = false,
    this.videoMaxDuration,
    this.videoCodec = UVideoCodec.auto,
    this.photoFormat = UPhotoFormat.jpeg,
    this.photoQuality = 92,
    this.fit = BoxFit.cover,
    this.accentColor,
    this.labels,
    this.overlayBuilder,
  });

  final UCameraMode mode;
  final bool allowMultiple;

  /// Maximum photos in multi mode; 0 means unlimited.
  final int maxCount;
  final UCameraResolution resolution;
  final bool startFront;
  final bool enableFlash;
  final bool enableCameraSwitch;
  final bool enableGrid;

  /// Shows a horizon level line over the preview.
  final bool enableLevel;
  final bool enablePinchZoom;
  final bool enableZoomSlider;

  /// Shows 0.5x / 1x / 2x quick-zoom chips when the lens range allows it.
  final bool enableZoomPresets;
  final bool enableTapToFocus;
  final bool enableExposure;
  final bool enableSelfTimer;
  final bool enableAudio;
  final bool enableStabilization;
  final bool enableHdr;

  /// Reveals ISO, shutter and white-balance sliders on capable devices.
  final bool enableManualControls;
  final bool enableAspectRatioToggle;
  final bool confirmCapture;
  final bool mirrorFrontPreview;
  final bool mirrorFrontCapture;
  final Duration? videoMaxDuration;
  final UVideoCodec videoCodec;
  final UPhotoFormat photoFormat;
  final int photoQuality;
  final BoxFit fit;
  final Color? accentColor;
  final UCameraLabels? labels;

  /// Extra chrome drawn over the preview, below the built-in controls.
  final Widget Function(BuildContext context, UCameraController controller)? overlayBuilder;

  UCameraOptions copyWith({UCameraMode? mode, bool? allowMultiple, int? maxCount, bool? startFront, UCameraResolution? resolution}) => UCameraOptions(
    mode: mode ?? this.mode,
    allowMultiple: allowMultiple ?? this.allowMultiple,
    maxCount: maxCount ?? this.maxCount,
    resolution: resolution ?? this.resolution,
    startFront: startFront ?? this.startFront,
    enableFlash: enableFlash,
    enableCameraSwitch: enableCameraSwitch,
    enableGrid: enableGrid,
    enableLevel: enableLevel,
    enablePinchZoom: enablePinchZoom,
    enableZoomSlider: enableZoomSlider,
    enableZoomPresets: enableZoomPresets,
    enableTapToFocus: enableTapToFocus,
    enableExposure: enableExposure,
    enableSelfTimer: enableSelfTimer,
    enableAudio: enableAudio,
    enableStabilization: enableStabilization,
    enableHdr: enableHdr,
    enableManualControls: enableManualControls,
    enableAspectRatioToggle: enableAspectRatioToggle,
    confirmCapture: confirmCapture,
    mirrorFrontPreview: mirrorFrontPreview,
    mirrorFrontCapture: mirrorFrontCapture,
    videoMaxDuration: videoMaxDuration,
    videoCodec: videoCodec,
    photoFormat: photoFormat,
    photoQuality: photoQuality,
    fit: fit,
    accentColor: accentColor,
    labels: labels,
    overlayBuilder: overlayBuilder,
  );

  UCameraConfig toConfig() => UCameraConfig(
    facing: startFront ? UCameraFacing.front : UCameraFacing.back,
    resolution: resolution,
    enableAudio: enableAudio && mode != UCameraMode.photo,
    photoFormat: photoFormat,
    photoQuality: photoQuality,
    videoCodec: videoCodec,
    stabilization: enableStabilization ? UStabilizationMode.auto : UStabilizationMode.off,
    hdr: enableHdr ? UHdrMode.auto : UHdrMode.off,
    mirrorFrontPreview: mirrorFrontPreview,
    mirrorFrontCapture: mirrorFrontCapture,
    maxRecordingDuration: videoMaxDuration,
  );
}

/// One-call helpers that mirror `UFile.showImagePicker`.
abstract class UCamera {
  /// Opens the full camera page and returns everything captured.
  static Future<List<FileData>> open({UCameraOptions options = const UCameraOptions(), Function(List<FileData>)? action}) async {
    final List<FileData>? result = await UNavigator.push<List<FileData>>(UCameraPage(options: options), fullscreenDialog: true);
    final List<FileData> files = result ?? <FileData>[];
    action?.call(files);
    return files;
  }

  static Future<FileData?> takePhoto({UCameraOptions options = const UCameraOptions(), Function(FileData?)? action}) async {
    final List<FileData> files = await open(options: options.copyWith(mode: UCameraMode.photo, allowMultiple: false));
    final FileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  /// Captures several photos in one session; [maxCount] 0 means unlimited.
  static Future<List<FileData>> takePhotos({int maxCount = 0, UCameraOptions options = const UCameraOptions(), Function(List<FileData>)? action}) async {
    final List<FileData> files = await open(options: options.copyWith(mode: UCameraMode.photo, allowMultiple: true, maxCount: maxCount));
    action?.call(files);
    return files;
  }

  static Future<FileData?> recordVideo({UCameraOptions options = const UCameraOptions(), Function(FileData?)? action}) async {
    final List<FileData> files = await open(options: options.copyWith(mode: UCameraMode.video, allowMultiple: false));
    final FileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  static Future<List<UCameraDevice>> devices() => UCameraController.availableCameras();

  static Future<UCameraPermissionState> permission() => UCameraController.permissionStatus();

  static Future<UCameraPermissionState> requestPermission({bool audio = false}) => UCameraController.requestPermission(audio: audio);
}

/// Renders the live preview of [controller]. Uses a GPU texture everywhere
/// except the web, where the browser's own video element is embedded.
class UCameraPreview extends StatelessWidget {
  const UCameraPreview({required this.controller, this.fit = BoxFit.cover, this.mirror, this.placeholder, this.child, super.key});

  final UCameraController controller;
  final BoxFit fit;

  /// Overrides the automatic front-camera mirroring.
  final bool? mirror;
  final Widget? placeholder;

  /// Drawn on top of the preview, sized to the widget.
  final Widget? child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UCameraValue>(
    valueListenable: controller,
    builder: (BuildContext context, UCameraValue value, Widget? _) {
      if (!value.isInitialized || value.previewSize.width == 0) {
        return placeholder ?? const Center(child: CircularProgressIndicator());
      }

      Widget preview = _surface(value);
      final bool mirrored = mirror ?? value.mirrored;
      if (mirrored) preview = Transform(alignment: Alignment.center, transform: Matrix4.identity()..scaleByDouble(-1, 1, 1, 1), child: preview);

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FittedBox(
                fit: fit,
                child: SizedBox(
                  width: value.previewSize.width.toDouble(),
                  height: value.previewSize.height.toDouble(),
                  child: preview,
                ),
              ),
              if (child != null) child!,
            ],
          ),
        ),
      );
    },
  );

  Widget _surface(UCameraValue value) {
    final String? viewType = value.viewType;
    if (viewType != null) return HtmlElementView(viewType: viewType);
    final int? textureId = value.textureId;
    if (textureId == null) return const ColoredBox(color: Color(0xFF000000));
    return Texture(textureId: textureId);
  }
}

/// Rule-of-thirds grid drawn over the preview.
class UCameraGrid extends StatelessWidget {
  const UCameraGrid({this.color = const Color(0x33FFFFFF), this.divisions = 3, super.key});

  final Color color;
  final int divisions;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(painter: _UGridPainter(color, divisions), size: Size.infinite));
}

class _UGridPainter extends CustomPainter {
  const _UGridPainter(this.color, this.divisions);

  final Color color;
  final int divisions;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (int i = 1; i < divisions; i++) {
      final double dx = size.width * i / divisions;
      final double dy = size.height * i / divisions;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(_UGridPainter oldDelegate) => oldDelegate.color != color || oldDelegate.divisions != divisions;
}

class UCameraPage extends StatefulWidget {
  const UCameraPage({this.options = const UCameraOptions(), super.key});

  final UCameraOptions options;

  @override
  State<UCameraPage> createState() => _UCameraPageState();
}

class _UCameraPageState extends State<UCameraPage> with WidgetsBindingObserver {
  UCameraController? _controller;
  List<UCameraDevice> _devices = <UCameraDevice>[];
  String? _error;
  bool _initializing = true;

  bool _showGrid = false;
  int _selfTimerSeconds = 0;
  int _countdown = 0;
  Timer? _selfTimer;
  double _baseZoom = 1;
  bool _showManual = false;

  late bool _isVideoMode = widget.options.mode == UCameraMode.video;
  final List<FileData> _captured = <FileData>[];
  FileData? _review;

  UCameraOptions get _o => widget.options;

  Color get _accent => _o.accentColor ?? Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selfTimer?.cancel();
    unawaited(_controller?.dispose());
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

  Future<void> _bootstrap() async {
    try {
      final UCameraPermissionState permission = await UCameraController.requestPermission(audio: _o.enableAudio && _o.mode != UCameraMode.photo);
      if (!permission.isGranted) {
        _fail(_o.labels?.permissionMessage ?? U.s.cameraPermissionIsRequired);
        return;
      }
      _devices = await UCameraController.availableCameras();
      if (_devices.isEmpty) {
        _fail(_o.labels?.noCameraMessage ?? U.s.noCameraWasFound);
        return;
      }
      await _openController(_o.startFront ? UCameraFacing.front : UCameraFacing.back);
    } on UCameraException catch (error) {
      _fail(error.message.isEmpty ? U.s.error : error.message);
    }
  }

  Future<void> _openController(UCameraFacing facing) async {
    final UCameraDevice? device = UCameraUtils.pickDevice(_devices, facing: facing);
    final UCameraController controller = UCameraController(
      config: _o.toConfig().copyWith(facing: facing, deviceId: device?.id),
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    if (controller.value.hasError) {
      _fail(controller.value.error?.message ?? U.s.error);
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _initializing = false;
      _error = null;
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _initializing = false;
    });
  }

  bool get _multiPhoto => _o.allowMultiple && _o.mode != UCameraMode.video;

  bool get _atLimit => _o.maxCount > 0 && _captured.length >= _o.maxCount;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _cycleFlash() async {
    final UCameraController? controller = _controller;
    if (controller == null) return;
    await controller.setFlashMode(UCameraUtils.nextFlashMode(controller.value.flash, includeTorch: _isVideoMode));
  }

  Future<void> _switchCamera() async {
    final UCameraController? controller = _controller;
    if (controller == null || controller.value.isRecording || _devices.length < 2) return;
    setState(() => _initializing = true);
    final UCameraFacing next = controller.value.device?.isFront == true ? UCameraFacing.back : UCameraFacing.front;
    await controller.dispose();
    _controller = null;
    await _openController(next);
  }

  Future<void> _onShutter() async {
    final UCameraController? controller = _controller;
    if (controller == null || _countdown > 0) return;
    if (_isVideoMode) {
      await _toggleRecording();
      return;
    }
    if (_o.enableSelfTimer && _selfTimerSeconds > 0) {
      await _runSelfTimer();
    } else {
      await _takePhoto();
    }
  }

  Future<void> _runSelfTimer() async {
    setState(() => _countdown = _selfTimerSeconds);
    _selfTimer?.cancel();
    _selfTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
        await _takePhoto();
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  Future<void> _takePhoto() async {
    final UCameraController? controller = _controller;
    if (controller == null) return;
    final UCapturedPhoto? photo = await controller.takePhoto();
    if (photo == null || !mounted) return;
    final FileData file = UCameraUtils.toFileData(photo);
    if (_multiPhoto) {
      setState(() => _captured.add(file));
      if (_atLimit) _finish();
    } else if (_o.confirmCapture) {
      setState(() => _review = file);
    } else {
      _finishWith(<FileData>[file]);
    }
  }

  Future<void> _toggleRecording() async {
    final UCameraController? controller = _controller;
    if (controller == null) return;
    if (controller.value.isRecording) {
      final UCapturedVideo? video = await controller.stopVideoRecording();
      if (video == null || !mounted) return;
      final FileData file = UCameraUtils.videoToFileData(video);
      if (_o.mode == UCameraMode.both) {
        setState(() => _captured.add(file));
      } else {
        _finishWith(<FileData>[file]);
      }
    } else {
      await controller.startVideoRecording(codec: _o.videoCodec, maxDuration: _o.videoMaxDuration);
    }
  }

  void _finish() => _finishWith(_captured);

  void _finishWith(List<FileData> files) {
    if (!mounted) return;
    Navigator.of(context).pop(files);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final UCameraController? controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: _error != null
          ? _errorView()
          : (_initializing || controller == null)
          ? const Center(child: CircularProgressIndicator())
          : _review != null
          ? _reviewView()
          : _cameraView(controller),
    );
  }

  Widget _errorView() => SafeArea(
    child: Stack(
      children: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.no_photography_outlined, color: Color(0xB3FFFFFF), size: 56),
                const SizedBox(height: 16),
                Text(
                  _error ?? U.s.error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
                const SizedBox(height: 20),
                UButton(title: U.s.retry, onTap: () => unawaited(_bootstrap())),
                const SizedBox(height: 8),
                UButton(type: UButtonType.text, title: U.s.settings, onTap: () => unawaited(UCameraController.openSettings())),
              ],
            ),
          ),
        ),
        Positioned(top: 8, left: 8, child: _roundIcon(Icons.close, () => _finishWith(<FileData>[]))),
      ],
    ),
  );

  Widget _cameraView(UCameraController controller) => ValueListenableBuilder<UCameraValue>(
    valueListenable: controller,
    builder: (BuildContext context, UCameraValue value, Widget? _) => Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _preview(controller, value),
        if (_showGrid) const UCameraGrid(),
        if (value.focusPoint != null) _focusRing(controller, value),
        if (_countdown > 0) _countdownOverlay(),
        if (_o.overlayBuilder != null) _o.overlayBuilder!(context, controller),
        SafeArea(
          child: Column(
            children: <Widget>[
              _topBar(controller, value),
              const Spacer(),
              if (_showManual && _o.enableManualControls) _manualControls(controller, value),
              if (_o.enableExposure && !value.capabilities.exposureOffset.isFixed && !value.isRecording) _exposureSlider(controller, value),
              if (_o.enableZoomSlider && !value.capabilities.zoom.isFixed && !value.isRecording) _zoomSlider(controller, value),
              if (_o.enableZoomPresets && !value.capabilities.zoom.isFixed) _zoomPresets(controller, value),
              if (_multiPhoto && _captured.isNotEmpty) _thumbnailStrip(),
              _bottomBar(controller, value),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _preview(UCameraController controller, UCameraValue value) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _o.enablePinchZoom ? (ScaleStartDetails _) => _baseZoom = value.zoom : null,
      onScaleUpdate: _o.enablePinchZoom
          ? (ScaleUpdateDetails details) {
              if (details.pointerCount == 2) unawaited(controller.setZoom(_baseZoom * details.scale));
            }
          : null,
      onTapUp: _o.enableTapToFocus
          ? (TapUpDetails details) {
              final Offset point = UCameraUtils.normalizePoint(
                local: details.localPosition,
                widgetSize: Size(box.maxWidth, box.maxHeight),
                previewSize: value.previewSize,
                fit: _o.fit,
                mirrored: value.mirrored,
              );
              unawaited(controller.focusAndMeterAt(point));
            }
          : null,
      child: UCameraPreview(controller: controller, fit: _o.fit),
    ),
  );

  Widget _topBar(UCameraController controller, UCameraValue value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: <Widget>[
        _roundIcon(Icons.close, () => _finishWith(_multiPhoto ? _captured : <FileData>[])),
        const Spacer(),
        if (_o.enableFlash && value.capabilities.flash)
          _roundIcon(UCameraUtils.flashIcon(value.flash), () => unawaited(_cycleFlash()), active: value.flash != UFlashMode.off),
        if (_o.enableGrid) _roundIcon(Icons.grid_3x3_rounded, () => setState(() => _showGrid = !_showGrid), active: _showGrid),
        if (_o.enableSelfTimer && !_isVideoMode) _roundIcon(_selfTimerSeconds == 0 ? Icons.timer_off_rounded : Icons.timer_rounded, _cycleSelfTimer, active: _selfTimerSeconds > 0),
        if (_o.enableHdr && value.capabilities.hdr)
          _roundIcon(Icons.hdr_on_rounded, () => unawaited(controller.setHdr(value.hdr == UHdrMode.on ? UHdrMode.off : UHdrMode.on)), active: value.hdr == UHdrMode.on),
        if (_o.enableManualControls && value.capabilities.manualExposure)
          _roundIcon(Icons.tune_rounded, () => setState(() => _showManual = !_showManual), active: _showManual),
      ],
    ),
  );

  Widget _bottomBar(UCameraController controller, UCameraValue value) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SizedBox(width: 72, child: value.isRecording ? _recordTimerLabel(value) : _modeToggle()),
        _shutterButton(controller, value),
        SizedBox(
          width: 72,
          child: value.isRecording
              ? (value.capabilities.pauseRecording
                    ? Center(
                        child: _roundIcon(
                          value.isRecordingPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          () => unawaited(value.isRecordingPaused ? controller.resumeVideoRecording() : controller.pauseVideoRecording()),
                        ),
                      )
                    : const SizedBox())
              : (_o.enableCameraSwitch && _devices.length > 1 ? Center(child: _roundIcon(Icons.cameraswitch_rounded, () => unawaited(_switchCamera()))) : const SizedBox()),
        ),
      ],
    ),
  );

  Widget _modeToggle() {
    if (_o.mode != UCameraMode.both) {
      if (_multiPhoto && _captured.isNotEmpty) {
        return TextButton(
          onPressed: _finish,
          child: Text("${_o.labels?.done ?? U.s.done} (${_captured.length})", style: const TextStyle(color: Color(0xFFFFFFFF))),
        );
      }
      return const SizedBox();
    }
    return UContainer(
      onTap: () => setState(() => _isVideoMode = !_isVideoMode),
      child: Icon(_isVideoMode ? Icons.videocam_rounded : Icons.photo_camera_rounded, color: const Color(0xFFFFFFFF)),
    );
  }

  Widget _shutterButton(UCameraController controller, UCameraValue value) {
    final Color ring = _isVideoMode ? const Color(0xFFFF3B30) : const Color(0xFFFFFFFF);
    return UContainer(
      onTap: () => unawaited(_onShutter()),
      border: Border.all(color: const Color(0xFFFFFFFF), width: 4),
      shape: BoxShape.circle,
      width: 78,
      height: 78,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: ring,
            shape: value.isRecording ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: value.isRecording ? BorderRadius.circular(8) : null,
          ),
          margin: EdgeInsets.all(value.isRecording ? 18 : 0),
        ),
      ),
    );
  }

  Widget _thumbnailStrip() => UContainer(
    height: 72,
    margin: const EdgeInsets.only(bottom: 4),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _captured.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
      itemBuilder: (BuildContext context, int index) {
        final FileData file = _captured[index];
        return Stack(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file.hasBytes ? Image.memory(file.bytes!, width: 60, height: 60, fit: BoxFit.cover) : const SizedBox(width: 60, height: 60),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: IconButton(
                icon: const Icon(Icons.cancel_rounded, color: Color(0xFFFFFFFF), size: 20),
                onPressed: () => setState(() => _captured.removeAt(index)),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _exposureSlider(UCameraController controller, UCameraValue value) {
    final UCameraRange range = value.capabilities.exposureOffset;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: <Widget>[
          const Icon(Icons.brightness_6_rounded, color: Color(0xB3FFFFFF), size: 20),
          Expanded(
            child: Slider(
              value: range.clamp(value.exposureOffset),
              min: range.min,
              max: range.max,
              activeColor: _accent,
              onChanged: (double next) => unawaited(controller.setExposureOffset(next)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomSlider(UCameraController controller, UCameraValue value) {
    final UCameraRange range = value.capabilities.zoom;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: <Widget>[
          const Icon(Icons.zoom_out_rounded, color: Color(0xB3FFFFFF), size: 20),
          Expanded(
            child: Slider(
              value: range.clamp(value.zoom),
              min: range.min,
              max: range.max,
              activeColor: _accent,
              onChanged: (double next) => unawaited(controller.setZoom(next)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomPresets(UCameraController controller, UCameraValue value) {
    final UCameraRange range = value.capabilities.zoom;
    final List<double> presets = <double>[
      if (range.min < 1) range.min,
      1,
      if (range.max >= 2) 2,
      if (range.max >= 5) 5,
    ];
    if (presets.length < 2) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: presets
            .map(
              (double preset) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: UContainer(
                  onTap: () => unawaited(controller.setZoom(preset)),
                  color: (value.zoom - preset).abs() < 0.05 ? _accent : const Color(0x66000000),
                  shape: BoxShape.circle,
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Text(
                      preset == preset.roundToDouble() ? "${preset.toInt()}x" : "${preset.toStringAsFixed(1)}x",
                      style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _manualControls(UCameraController controller, UCameraValue value) {
    final UCameraRange iso = value.capabilities.iso;
    final UCameraRange shutter = value.capabilities.exposureDuration;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          if (!iso.isFixed)
            Row(
              children: <Widget>[
                const SizedBox(width: 44, child: Text("ISO", style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12))),
                Expanded(
                  child: Slider(
                    value: iso.clamp(value.iso ?? iso.min),
                    min: iso.min,
                    max: iso.max,
                    activeColor: _accent,
                    onChanged: (double next) => unawaited(controller.setIso(next)),
                  ),
                ),
              ],
            ),
          if (!shutter.isFixed)
            Row(
              children: <Widget>[
                const SizedBox(width: 44, child: Icon(Icons.shutter_speed_rounded, color: Color(0xFFFFFFFF), size: 18)),
                Expanded(
                  child: Slider(
                    value: shutter.clamp((value.exposureDuration?.inMicroseconds ?? shutter.min * 1000) / 1000),
                    min: shutter.min,
                    max: shutter.max,
                    activeColor: _accent,
                    onChanged: (double next) => unawaited(controller.setExposureDuration(Duration(microseconds: (next * 1000).round()))),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _recordTimerLabel(UCameraValue value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const UContainer(color: Color(0xFFFF3B30), shape: BoxShape.circle, width: 10, height: 10),
      const SizedBox(width: 6),
      Text(
        UCameraUtils.formatDuration(value.recordingDuration),
        style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _focusRing(UCameraController controller, UCameraValue value) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) {
      final Offset at = UCameraUtils.denormalizePoint(
        normalized: value.focusPoint!,
        widgetSize: Size(box.maxWidth, box.maxHeight),
        previewSize: value.previewSize,
        fit: _o.fit,
        mirrored: value.mirrored,
      );
      return Stack(
        children: <Widget>[
          Positioned(
            left: at.dx - 30,
            top: at.dy - 30,
            child: IgnorePointer(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _accent, width: 2)),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _countdownOverlay() => Positioned.fill(
    child: ColoredBox(
      color: const Color(0x61000000),
      child: Center(
        child: Text(
          "$_countdown",
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 96, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );

  Widget _reviewView() {
    final FileData file = _review!;
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(child: Center(child: file.hasBytes ? Image.memory(file.bytes!) : const SizedBox())),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                UButton(type: UButtonType.outlined, title: _o.labels?.retake ?? U.s.retry, onTap: () => setState(() => _review = null)),
                UButton(title: _o.labels?.use ?? U.s.confirm, onTap: () => _finishWith(<FileData>[file])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap, {bool active = false}) => Padding(
    padding: const EdgeInsets.all(4),
    child: InkResponse(
      onTap: onTap,
      child: UContainer(
        color: active ? _accent : const Color(0x61000000),
        shape: BoxShape.circle,
        width: 42,
        height: 42,
        child: Icon(icon, color: const Color(0xFFFFFFFF), size: 22),
      ),
    ),
  );

  void _cycleSelfTimer() {
    const List<int> steps = <int>[0, 3, 5, 10];
    setState(() => _selfTimerSeconds = steps[(steps.indexOf(_selfTimerSeconds) + 1) % steps.length]);
  }
}
