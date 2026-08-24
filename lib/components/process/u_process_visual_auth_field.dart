part of "u_process.dart";

class UProcessVisualAuthField extends StatefulWidget {
  const UProcessVisualAuthField({
    required this.field,
    required this.processStepSend,
    this.style = const UProcessStyle(),
    super.key,
  });

  final UProcessField field;
  final UProcessStepSend processStepSend;
  final UProcessStyle style;

  @override
  State<UProcessVisualAuthField> createState() => _UProcessVisualAuthFieldState();
}

class _UProcessVisualAuthFieldState extends State<UProcessVisualAuthField> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  VideoPlayerController? _videoController;
  XFile? _recordedVideo;

  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;
  DateTime? _recordingStartTime;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _hasInitialValue = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(_progressController);

    if (widget.field.value != null && widget.field.value!.isNotEmpty) {
      _hasInitialValue = true;
      _loadInitialVideo(widget.field.value!);
    } else {
      _initCamera();
    }
  }

  Future<void> _loadInitialVideo(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading initial video: $e");
    }
  }

  void _setValue(String? value) {
    try {
      widget.processStepSend.fields.firstWhere((UProcessField f) => f.key == widget.field.key).value = value;
    } catch (e) {
      debugPrint("Field key not found in processStepSend: $e");
    }
  }

  Future<void> _initCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final CameraDescription frontCamera = cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(frontCamera, ResolutionPreset.high);
      await _cameraController!.initialize();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isRecording) return;

    try {
      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _seconds = 0;
        _recordedVideo = null;
        _hasInitialValue = false;
      });

      _recordingStartTime = DateTime.now();

      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }

      await _progressController.forward(from: 0);

      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        _seconds++;
        if (_seconds >= 10) _stopRecording();
      });
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _timer?.cancel();
    _progressController.stop();

    try {
      final XFile xFile = await _cameraController!.stopVideoRecording();

      setState(() => _isRecording = false);

      // Use the exact elapsed time rather than the coarse per-second counter.
      final Duration duration = DateTime.now().difference(_recordingStartTime ?? DateTime.now());

      if (duration.inMilliseconds < 4000) {
        UToast.error(message: U.s.theVideoMustBeAtLeast4Seconds);
        return;
      }

      setState(() => _recordedVideo = xFile);

      final Uint8List bytes = await xFile.readAsBytes();
      _setValue(base64Encode(bytes));

      // Preview the just-recorded clip: it lives on the device (web uses a blob
      // URL), so play it from a file on native and from the URL on web.
      _videoController = kIsWeb ? VideoPlayerController.networkUrl(Uri.parse(xFile.path)) : VideoPlayerController.file(File(xFile.path));
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    }
  }

  Future<void> _reRecord() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }
    setState(() {
      _recordedVideo = null;
      _hasInitialValue = false;
      _seconds = 0;
    });
    _setValue(null);
    await _initCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _cameraController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 240,
          width: 240,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                height: 240,
                width: 240,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (BuildContext context, Widget? child) => CircularProgressIndicator(
                    value: _isRecording ? _progressAnimation.value : 0,
                    strokeWidth: 6,
                    color: scheme.primary,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ),
              ClipOval(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: _buildMediaPreview(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        UTextBodyMedium(widget.field.text1 ?? "", textAlign: TextAlign.center).pSymmetric(horizontal: 24),
        const SizedBox(height: 12),
        if (widget.field.rejectionReason != null)
          UIconTextHorizontal(
            leading: Icon(Icons.error_outline, color: scheme.error),
            trailing: UTextBodyMedium("${U.s.adminMessage}: ${widget.field.rejectionReason}", color: scheme.error),
          ).pOnly(bottom: 16),
        _buildControls(),
      ],
    );
  }

  Widget _buildMediaPreview() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (_videoController != null && _videoController!.value.isInitialized) {
      // Cover the square frame without stretching by preserving the video's aspect ratio.
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else if (_cameraController != null && _cameraController!.value.isInitialized) {
      // Cover the square frame without stretching by preserving the camera's preview aspect ratio.
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 220,
          height: _cameraController!.value.previewSize?.width ?? 220,
          child: CameraPreview(_cameraController!),
        ),
      );
    } else if (_hasInitialValue) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator()),
      );
    } else {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(child: Icon(Icons.person, size: 64, color: scheme.onSurfaceVariant)),
      );
    }
  }

  Widget _buildControls() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color onAccent = widget.style.onAccent(context);
    if (_recordedVideo != null || _hasInitialValue) {
      return ElevatedButton.icon(
        onPressed: _reRecord,
        icon: const Icon(Icons.refresh),
        label: Text(U.s.recordAgain),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: onAccent,
        ),
      );
    } else {
      return GestureDetector(
        onLongPressStart: (_) => _startRecording(),
        onLongPressEnd: (_) => _stopRecording(),
        child: UContainer(
          width: 80,
          height: 80,
          shape: BoxShape.circle,
          color: _isRecording ? scheme.error : scheme.primary,
          child: Icon(
            _isRecording ? Icons.stop : Icons.fiber_manual_record,
            color: onAccent,
            size: 40,
          ),
        ),
      );
    }
  }
}
