import "package:path/path.dart" as path;
import "package:u/utilities.dart";

// =============================================================================
// u_camera — a fully-featured, cross-platform camera page for the `u` plugin,
// built directly on the `camera` plugin. Returns [FileData] (the same model
// UFile uses) so captured photos/videos flow through the app like any other
// picked file. Every hardware feature is optional and degrades gracefully on
// platforms/devices that do not support it.
// =============================================================================

enum UCameraMode { photo, video, both }

/// Optional label overrides. Anything left null falls back to an existing
/// localized string, so the page needs no new l10n keys.
class UCameraLabels {
  const UCameraLabels({this.retake, this.use, this.done, this.cancel, this.noCameraMessage, this.permissionMessage});

  final String? retake;
  final String? use;
  final String? done;
  final String? cancel;
  final String? noCameraMessage;
  final String? permissionMessage;
}

/// Full configuration for [UCameraPage]. Sensible defaults enable the common
/// camera-app feature set; turn individual controls off as needed.
class UCameraOptions {
  const UCameraOptions({
    this.mode = UCameraMode.photo,
    this.allowMultiple = false,
    this.maxCount = 0,
    this.resolution = ResolutionPreset.high,
    this.startFront = false,
    this.enableFlash = true,
    this.enableCameraSwitch = true,
    this.enableGrid = true,
    this.enablePinchZoom = true,
    this.enableZoomSlider = false,
    this.enableTapToFocus = true,
    this.enableExposure = true,
    this.enableSelfTimer = true,
    this.enableAudio = true,
    this.confirmCapture = true,
    this.mirrorFrontPreview = false,
    this.videoMaxDuration,
    this.accentColor,
    this.labels,
  });

  final UCameraMode mode;
  final bool allowMultiple;

  /// Max photos in multi mode; 0 means unlimited.
  final int maxCount;
  final ResolutionPreset resolution;
  final bool startFront;
  final bool enableFlash;
  final bool enableCameraSwitch;
  final bool enableGrid;
  final bool enablePinchZoom;
  final bool enableZoomSlider;
  final bool enableTapToFocus;
  final bool enableExposure;
  final bool enableSelfTimer;
  final bool enableAudio;
  final bool confirmCapture;
  final bool mirrorFrontPreview;
  final Duration? videoMaxDuration;
  final Color? accentColor;
  final UCameraLabels? labels;

  UCameraOptions copyWith({UCameraMode? mode, bool? allowMultiple, int? maxCount, bool? startFront}) => UCameraOptions(
    mode: mode ?? this.mode,
    allowMultiple: allowMultiple ?? this.allowMultiple,
    maxCount: maxCount ?? this.maxCount,
    resolution: resolution,
    startFront: startFront ?? this.startFront,
    enableFlash: enableFlash,
    enableCameraSwitch: enableCameraSwitch,
    enableGrid: enableGrid,
    enablePinchZoom: enablePinchZoom,
    enableZoomSlider: enableZoomSlider,
    enableTapToFocus: enableTapToFocus,
    enableExposure: enableExposure,
    enableSelfTimer: enableSelfTimer,
    enableAudio: enableAudio,
    confirmCapture: confirmCapture,
    mirrorFrontPreview: mirrorFrontPreview,
    videoMaxDuration: videoMaxDuration,
    accentColor: accentColor,
    labels: labels,
  );
}

/// One-call helpers to capture media, mirroring `UFile.showImagePicker`.
abstract class UCamera {
  /// Opens the full camera page and returns everything captured. Also invokes
  /// [action] with the result (empty list if cancelled).
  static Future<List<FileData>> open({UCameraOptions options = const UCameraOptions(), Function(List<FileData>)? action}) async {
    final List<FileData>? result = await UNavigator.push<List<FileData>>(UCameraPage(options: options), fullscreenDialog: true);
    final List<FileData> files = result ?? <FileData>[];
    action?.call(files);
    return files;
  }

  /// Captures a single photo. Returns null if cancelled.
  static Future<FileData?> takePhoto({UCameraOptions options = const UCameraOptions(), Function(FileData?)? action}) async {
    final List<FileData> files = await open(options: options.copyWith(mode: UCameraMode.photo, allowMultiple: false));
    final FileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }

  /// Captures multiple photos in one session. [maxCount] 0 means unlimited.
  static Future<List<FileData>> takePhotos({int maxCount = 0, UCameraOptions options = const UCameraOptions(), Function(List<FileData>)? action}) async {
    final List<FileData> files = await open(
      options: options.copyWith(mode: UCameraMode.photo, allowMultiple: true, maxCount: maxCount),
    );
    action?.call(files);
    return files;
  }

  /// Records a single video. Returns null if cancelled.
  static Future<FileData?> recordVideo({UCameraOptions options = const UCameraOptions(), Function(FileData?)? action}) async {
    final List<FileData> files = await open(options: options.copyWith(mode: UCameraMode.video, allowMultiple: false));
    final FileData? file = files.isEmpty ? null : files.first;
    action?.call(file);
    return file;
  }
}

class UCameraPage extends StatefulWidget {
  const UCameraPage({this.options = const UCameraOptions(), super.key});

  final UCameraOptions options;

  @override
  State<UCameraPage> createState() => _UCameraPageState();
}

class _UCameraPageState extends State<UCameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  bool _initializing = true;
  String? _error;

  FlashMode _flash = FlashMode.off;
  bool _showGrid = false;

  bool _zoomSupported = false;
  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoom = 1;
  double _baseZoom = 1;

  bool _exposureSupported = false;
  double _minExposure = 0;
  double _maxExposure = 0;
  double _exposure = 0;

  late bool _isVideoMode = widget.options.mode == UCameraMode.video;
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;

  Timer? _selfTimer;
  int _countdown = 0;

  Offset? _focusIndicator;
  Timer? _focusTimer;

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
    _recordTimer?.cancel();
    _selfTimer?.cancel();
    _focusTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initController(_cameraIndex));
    }
  }

  Future<void> _bootstrap() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _fail(_o.labels?.noCameraMessage ?? U.s.noData);
        return;
      }
      _cameraIndex = _cameras.indexWhere((CameraDescription d) => d.lensDirection == (_o.startFront ? CameraLensDirection.front : CameraLensDirection.back));
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _initController(_cameraIndex);
    } on CameraException catch (_) {
      _fail(_o.labels?.permissionMessage ?? U.s.error);
    } catch (_) {
      _fail(_o.labels?.noCameraMessage ?? U.s.error);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _initializing = false;
    });
  }

  Future<void> _initController(int index) async {
    final CameraController controller = CameraController(
      _cameras[index],
      _o.resolution,
      enableAudio: _o.enableAudio && _o.mode != UCameraMode.photo,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
      await _readCapabilities(controller);
      if (_o.enableFlash) {
        await _safe(() => controller.setFlashMode(FlashMode.off));
      }
    } on CameraException catch (_) {
      _fail(_o.labels?.permissionMessage ?? U.s.error);
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _cameraIndex = index;
      _initializing = false;
      _error = null;
      _flash = FlashMode.off;
    });
  }

  Future<void> _readCapabilities(CameraController controller) async {
    try {
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _zoom = _minZoom;
      _baseZoom = _minZoom;
      _zoomSupported = _maxZoom > _minZoom;
    } catch (_) {
      _zoomSupported = false;
    }
    try {
      _minExposure = await controller.getMinExposureOffset();
      _maxExposure = await controller.getMaxExposureOffset();
      _exposure = 0;
      _exposureSupported = _maxExposure > _minExposure;
    } catch (_) {
      _exposureSupported = false;
    }
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Feature unsupported on this platform/device — ignore.
    }
  }

  bool get _ready => _controller != null && _controller!.value.isInitialized;

  bool get _multiPhoto => _o.allowMultiple && _o.mode != UCameraMode.video;

  bool get _atLimit => _o.maxCount > 0 && _captured.length >= _o.maxCount;

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _cycleFlash() async {
    if (!_ready) return;
    const List<FlashMode> order = <FlashMode>[FlashMode.off, FlashMode.auto, FlashMode.always, FlashMode.torch];
    final FlashMode next = order[(order.indexOf(_flash) + 1) % order.length];
    await _safe(() => _controller!.setFlashMode(next));
    if (mounted) setState(() => _flash = next);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording) return;
    final int next = (_cameraIndex + 1) % _cameras.length;
    setState(() => _initializing = true);
    await _controller?.dispose();
    await _initController(next);
  }

  Future<void> _handleZoom(double target) async {
    if (!_zoomSupported || !_ready) return;
    final double clamped = target.clamp(_minZoom, _maxZoom).toDouble();
    await _safe(() => _controller!.setZoomLevel(clamped));
    if (mounted) setState(() => _zoom = clamped);
  }

  Future<void> _handleExposure(double value) async {
    if (!_exposureSupported || !_ready) return;
    final double clamped = value.clamp(_minExposure, _maxExposure).toDouble();
    await _safe(() => _controller!.setExposureOffset(clamped));
    if (mounted) setState(() => _exposure = clamped);
  }

  Future<void> _focusAt(Offset local, Size size) async {
    if (!_o.enableTapToFocus || !_ready) return;
    final Offset point = Offset((local.dx / size.width).clamp(0, 1).toDouble(), (local.dy / size.height).clamp(0, 1).toDouble());
    await _safe(() => _controller!.setFocusPoint(point));
    await _safe(() => _controller!.setExposurePoint(point));
    _focusTimer?.cancel();
    setState(() => _focusIndicator = local);
    _focusTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _focusIndicator = null);
    });
  }

  Future<void> _onShutter() async {
    if (!_ready || _countdown > 0) return;
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

  int _selfTimerSeconds = 0;

  Future<void> _runSelfTimer() async {
    setState(() => _countdown = _selfTimerSeconds);
    _selfTimer?.cancel();
    _selfTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
        await _takePhoto();
      } else {
        setState(() => _countdown -= 1);
      }
    });
  }

  Future<void> _takePhoto() async {
    if (!_ready || _controller!.value.isTakingPicture) return;
    try {
      final XFile shot = await _controller!.takePicture();
      final FileData file = await _toFileData(shot, "jpg");
      if (!mounted) return;
      if (_multiPhoto) {
        setState(() => _captured.add(file));
        if (_atLimit) _finish();
      } else if (_o.confirmCapture) {
        setState(() => _review = file);
      } else {
        _finishWith(<FileData>[file]);
      }
    } catch (_) {
      _snack(U.s.error);
    }
  }

  Future<void> _toggleRecording() async {
    if (!_ready) return;
    if (_isRecording) {
      _recordTimer?.cancel();
      try {
        final XFile clip = await _controller!.stopVideoRecording();
        final FileData file = await _toFileData(clip, "mp4");
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _recordElapsed = Duration.zero;
        });
        if (_o.mode == UCameraMode.both) {
          setState(() => _captured.add(file));
        } else {
          _finishWith(<FileData>[file]);
        }
      } catch (_) {
        _snack(U.s.error);
      }
    } else {
      try {
        await _controller!.startVideoRecording();
        if (!mounted) return;
        setState(() {
          _isRecording = true;
          _recordElapsed = Duration.zero;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (Timer _) {
          if (!mounted || _isPaused) return;
          setState(() => _recordElapsed += const Duration(seconds: 1));
          final Duration? max = _o.videoMaxDuration;
          if (max != null && _recordElapsed >= max) unawaited(_toggleRecording());
        });
      } catch (_) {
        _snack(U.s.error);
      }
    }
  }

  Future<void> _togglePause() async {
    if (!_isRecording) return;
    if (_isPaused) {
      await _safe(() => _controller!.resumeVideoRecording());
      if (mounted) setState(() => _isPaused = false);
    } else {
      await _safe(() => _controller!.pauseVideoRecording());
      if (mounted) setState(() => _isPaused = true);
    }
  }

  Future<FileData> _toFileData(XFile file, String extension) async {
    final Uint8List bytes = await file.readAsBytes();
    return FileData(bytes: bytes, path: kIsWeb ? null : file.path, extension: _extensionOf(file.name, extension));
  }

  static String _extensionOf(String source, String fallback) {
    final String raw = path.extension(source);
    final String clean = raw.startsWith(".") ? raw.substring(1) : raw;
    return (clean.isEmpty ? fallback : clean).toLowerCase();
  }

  void _snack(String message) {
    if (mounted) UToast.error(message: message);
  }

  void _finish() => _finishWith(_captured);

  void _finishWith(List<FileData> files) {
    if (!mounted) return;
    Navigator.of(context).pop(files);
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: _error != null
        ? _errorView()
        : _initializing || !_ready
        ? const Center(child: CircularProgressIndicator())
        : _review != null
        ? _reviewView()
        : _cameraView(),
  );

  Widget _errorView() => SafeArea(
    child: Stack(
      children: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 56),
                const SizedBox(height: 16),
                Text(
                  _error ?? U.s.error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                UButton(title: U.s.retry, onTap: () => unawaited(_bootstrap())),
              ],
            ),
          ),
        ),
        _closeButton(),
      ],
    ),
  );

  Widget _cameraView() => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      _preview(),
      if (_showGrid)
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
        ),
      if (_focusIndicator != null) _focusRing(_focusIndicator!),
      if (_countdown > 0) _countdownOverlay(),
      SafeArea(
        child: Column(
          children: <Widget>[
            _topBar(),
            const Spacer(),
            if (_exposureSupported && _o.enableExposure && !_isRecording) _exposureSlider(),
            if (_zoomSupported && _o.enableZoomSlider && !_isRecording) _zoomSlider(),
            if (_multiPhoto && _captured.isNotEmpty) _thumbnailStrip(),
            _bottomBar(),
          ],
        ),
      ),
    ],
  );

  Widget _preview() {
    final CameraController controller = _controller!;
    final Size size = MediaQuery.of(context).size;
    double scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    final bool mirror = _o.mirrorFrontPreview && _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
    Widget preview = Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(controller)),
    );
    if (mirror) preview = Transform.scale(scaleX: -1, child: preview);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _o.enablePinchZoom ? (ScaleStartDetails _) => _baseZoom = _zoom : null,
        onScaleUpdate: _o.enablePinchZoom
            ? (ScaleUpdateDetails d) {
                if (d.pointerCount == 2) unawaited(_handleZoom(_baseZoom * d.scale));
              }
            : null,
        onTapUp: _o.enableTapToFocus ? (TapUpDetails d) => unawaited(_focusAt(d.localPosition, Size(box.maxWidth, box.maxHeight))) : null,
        child: preview,
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: <Widget>[
        _roundIcon(Icons.close, () => _finishWith(_multiPhoto ? _captured : <FileData>[])),
        const Spacer(),
        if (_o.enableFlash) _roundIcon(_flashIcon(), () => unawaited(_cycleFlash()), active: _flash != FlashMode.off),
        if (_o.enableGrid) _roundIcon(Icons.grid_3x3, () => setState(() => _showGrid = !_showGrid), active: _showGrid),
        if (_o.enableSelfTimer && !_isVideoMode) _roundIcon(_timerIcon(), _cycleSelfTimer, active: _selfTimerSeconds > 0),
      ],
    ),
  );

  Widget _bottomBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SizedBox(width: 64, child: _isRecording ? _recordTimerLabel() : _modeToggle()),
        _shutterButton(),
        SizedBox(
          width: 64,
          child: _isRecording
              ? (_o.enableFlash ? Center(child: _roundIcon(_isPaused ? Icons.play_arrow : Icons.pause, () => unawaited(_togglePause()))) : const SizedBox())
              : (_o.enableCameraSwitch && _cameras.length > 1 ? Center(child: _roundIcon(Icons.cameraswitch, () => unawaited(_switchCamera()))) : const SizedBox()),
        ),
      ],
    ),
  );

  Widget _modeToggle() {
    if (_o.mode != UCameraMode.both) {
      if (_multiPhoto && _captured.isNotEmpty) {
        return TextButton(
          onPressed: _finish,
          child: Text("${_o.labels?.done ?? U.s.done} (${_captured.length})", style: const TextStyle(color: Colors.white)),
        );
      }
      return const SizedBox();
    }
    return GestureDetector(
      onTap: () => setState(() => _isVideoMode = !_isVideoMode),
      child: Icon(_isVideoMode ? Icons.videocam : Icons.photo_camera, color: Colors.white),
    );
  }

  Widget _shutterButton() {
    final Color ring = _isVideoMode ? const Color(0xFFFF3B30) : Colors.white;
    return GestureDetector(
      onTap: () => unawaited(_onShutter()),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: ring,
              shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: _isRecording ? BorderRadius.circular(8) : null,
            ),
            margin: EdgeInsets.all(_isRecording ? 18 : 0),
          ),
        ),
      ),
    );
  }

  Widget _thumbnailStrip() => Container(
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
                icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
                onPressed: () => setState(() => _captured.removeAt(index)),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _exposureSlider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Row(
      children: <Widget>[
        const Icon(Icons.brightness_6, color: Colors.white70, size: 20),
        Expanded(
          child: Slider(
            value: _exposure.clamp(_minExposure, _maxExposure).toDouble(),
            min: _minExposure,
            max: _maxExposure,
            activeColor: _accent,
            onChanged: (double v) => unawaited(_handleExposure(v)),
          ),
        ),
      ],
    ),
  );

  Widget _zoomSlider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Row(
      children: <Widget>[
        const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
        Expanded(
          child: Slider(
            value: _zoom.clamp(_minZoom, _maxZoom).toDouble(),
            min: _minZoom,
            max: _maxZoom,
            activeColor: _accent,
            onChanged: (double v) => unawaited(_handleZoom(v)),
          ),
        ),
      ],
    ),
  );

  Widget _recordTimerLabel() => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        _formatDuration(_recordElapsed),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _focusRing(Offset at) => Positioned(
    left: at.dx - 30,
    top: at.dy - 30,
    child: IgnorePointer(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _accent, width: 2),
        ),
      ),
    ),
  );

  Widget _countdownOverlay() => Positioned.fill(
    child: ColoredBox(
      color: Colors.black38,
      child: Center(
        child: Text(
          "$_countdown",
          style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.bold),
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

  Widget _closeButton() => Positioned(top: 8, left: 8, child: _roundIcon(Icons.close, () => _finishWith(<FileData>[])));

  Widget _roundIcon(IconData icon, VoidCallback onTap, {bool active = false}) => Padding(
    padding: const EdgeInsets.all(4),
    child: InkResponse(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: active ? _accent : Colors.black38, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    ),
  );

  void _cycleSelfTimer() {
    const List<int> steps = <int>[0, 3, 5, 10];
    setState(() => _selfTimerSeconds = steps[(steps.indexOf(_selfTimerSeconds) + 1) % steps.length]);
  }

  IconData _flashIcon() {
    switch (_flash) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  IconData _timerIcon() => _selfTimerSeconds == 0 ? Icons.timer_off : Icons.timer;

  static String _formatDuration(Duration d) {
    final String m = d.inMinutes.remainder(60).toString().padLeft(2, "0");
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$m:$s";
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (int i = 1; i < 3; i++) {
      final double dx = size.width * i / 3;
      final double dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
