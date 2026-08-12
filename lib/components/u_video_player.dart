import "package:u/utilities.dart";

/// Full-featured video player supporting network URLs, base64 strings, raw
/// bytes, local files and bundled assets. Handles source resolution, buffering,
/// scrubbing, volume, playback-speed, looping, replay and fullscreen out of the
/// box. `video_player` cannot decode in-memory data directly, so base64/bytes
/// sources are written to a temporary file first.
class UVideoPlayer extends StatefulWidget {
  const UVideoPlayer({
    super.key,
    this.url,
    this.base64,
    this.bytes,
    this.filePath,
    this.assetPath,
    this.autoPlay = false,
    this.looping = false,
    this.muted = false,
    this.showControls = true,
    this.allowFullScreen = true,
    this.allowPlaybackSpeed = true,
    this.autoHideControls = true,
    this.aspectRatio,
    this.fit = BoxFit.contain,
    this.accentColor,
    this.backgroundColor = Colors.black,
    this.borderRadius = 12,
    this.placeholder,
  }) : assert(
         url != null || base64 != null || bytes != null || filePath != null || assetPath != null,
         "Provide one video source",
       );

  final String? url;
  final String? base64;
  final Uint8List? bytes;
  final String? filePath;
  final String? assetPath;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final bool showControls;
  final bool allowFullScreen;
  final bool allowPlaybackSpeed;
  final bool autoHideControls;
  final double? aspectRatio;
  final BoxFit fit;
  final Color? accentColor;
  final Color backgroundColor;
  final double borderRadius;
  final Widget? placeholder;

  @override
  State<UVideoPlayer> createState() => _UVideoPlayerState();
}

class _UVideoPlayerState extends State<UVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;
  bool _muted = false;
  bool _controlsVisible = true;
  double _speed = 1;
  Timer? _hideTimer;

  static const List<double> _speeds = <double>[0.5, 1, 1.5, 2];

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
    _controlsVisible = !widget.autoPlay || !widget.autoHideControls;
    _initialize();
  }

  Future<File> _writeTempFile(Uint8List data) async {
    final Directory dir = await getTemporaryDirectory();
    final File file = File("${dir.path}/uvp_${UUUID.uuidV4()}.mp4");
    await file.writeAsBytes(data);
    return file;
  }

  Future<void> _initialize() async {
    try {
      final VideoPlayerController controller;
      if (widget.bytes != null) {
        controller = VideoPlayerController.file(await _writeTempFile(widget.bytes!));
      } else if (widget.base64 != null) {
        final String raw = widget.base64!.contains(",") ? widget.base64!.split(",").last : widget.base64!;
        controller = VideoPlayerController.file(await _writeTempFile(base64Decode(raw)));
      } else if (widget.filePath != null) {
        controller = VideoPlayerController.file(File(widget.filePath!));
      } else if (widget.assetPath != null) {
        controller = VideoPlayerController.asset(widget.assetPath!);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
      }

      _controller = controller;
      await controller.initialize();
      await controller.setLooping(widget.looping);
      await controller.setVolume(_muted ? 0 : 1);
      controller.addListener(_listener);
      if (widget.autoPlay) await controller.play();

      if (mounted) setState(() => _initialized = true);
      if (widget.autoPlay && widget.autoHideControls) _startHideTimer();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (!widget.autoHideControls) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startHideTimer();
  }

  void _togglePlay() {
    final VideoPlayerController controller = _controller!;
    if (controller.value.position >= controller.value.duration && !controller.value.isLooping) {
      controller.seekTo(Duration.zero);
      controller.play();
    } else if (controller.value.isPlaying) {
      controller.pause();
      _hideTimer?.cancel();
      setState(() => _controlsVisible = true);
    } else {
      controller.play();
      _startHideTimer();
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0 : 1);
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _controller?.setPlaybackSpeed(speed);
  }

  void _openFullScreen() {
    final VideoPlayerController controller = _controller!;
    _hideTimer?.cancel();
    UNavigator.push(_UFullScreenVideo(controller: controller, accentColor: _accent(context), fit: widget.fit));
  }

  Color _accent(BuildContext context) => widget.accentColor ?? Theme.of(context).colorScheme.primary;

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    final String minutes = two(d.inMinutes.remainder(60));
    final String seconds = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? "${two(d.inHours)}:$minutes:$seconds" : "$minutes:$seconds";
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_listener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double ratio = widget.aspectRatio ?? (_controller?.value.isInitialized ?? false ? _controller!.value.aspectRatio : 16 / 9);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: ColoredBox(
        color: widget.backgroundColor,
        child: AspectRatio(aspectRatio: ratio <= 0 ? 16 / 9 : ratio, child: _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error) return _buildError(context);
    if (!_initialized || _controller == null) return widget.placeholder ?? const Center(child: CircularProgressIndicator());

    final VideoPlayerController controller = _controller!;
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: <Widget>[
          FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          if (controller.value.isBuffering) const Center(child: CircularProgressIndicator()),
          if (widget.showControls) _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) => Center(
    child: UColumn(
      spacing: 0,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.error_outline, color: Colors.white70, size: 40),
        const SizedBox(height: 8),
        UTextBodySmall(U.s.errorLoadingVideo, color: Colors.white70),
        const SizedBox(height: 8),
        UButton(
          type: UButtonType.text,
          title: U.s.tryAgain,
          onTap: () {
            setState(() {
              _error = false;
              _initialized = false;
            });
            _initialize();
          },
        ),
      ],
    ),
  );

  Widget _buildControls(BuildContext context) {
    final VideoPlayerController controller = _controller!;
    final bool ended = controller.value.position >= controller.value.duration && !controller.value.isLooping && controller.value.duration > Duration.zero;
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Colors.black.withValues(alpha: 0.35), Colors.transparent, Colors.black.withValues(alpha: 0.55)],
              stops: const <double>[0, 0.5, 1],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                    child: Icon(
                      ended ? Icons.replay : (controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Align(alignment: Alignment.bottomCenter, child: _buildBottomBar(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final VideoPlayerController controller = _controller!;
    final Duration position = controller.value.position;
    final Duration duration = controller.value.duration;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: UColumn(
        spacing: 0,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: _accent(context),
              inactiveTrackColor: Colors.white38,
              thumbColor: _accent(context),
            ),
            child: Slider(
              value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
              max: duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds.toDouble(),
              onChanged: (double v) {
                controller.seekTo(Duration(milliseconds: v.toInt()));
                _startHideTimer();
              },
            ),
          ),
          URow(
            spacing: 0,
            children: <Widget>[
              const SizedBox(width: 8),
              UTextBodySmall("${_fmt(position)} / ${_fmt(duration)}", color: Colors.white),
              const Spacer(),
              IconButton(
                tooltip: _muted ? U.s.unmute : U.s.mute,
                onPressed: _toggleMute,
                icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 20),
              ),
              if (widget.allowPlaybackSpeed)
                PopupMenuButton<double>(
                  tooltip: U.s.playbackSpeed,
                  initialValue: _speed,
                  onSelected: _setSpeed,
                  itemBuilder: (BuildContext context) => _speeds
                      .map((double s) => PopupMenuItem<double>(value: s, child: Text("${s}x")))
                      .toList(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: UTextBodySmall("${_speed}x", color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              if (widget.allowFullScreen)
                IconButton(
                  tooltip: U.s.enterFullscreen,
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fullscreen route that reuses the caller's [VideoPlayerController] so playback
/// position is preserved. Forces landscape while open and restores orientation
/// on exit.
class _UFullScreenVideo extends StatefulWidget {
  const _UFullScreenVideo({required this.controller, required this.accentColor, required this.fit});

  final VideoPlayerController controller;
  final Color accentColor;
  final BoxFit fit;

  @override
  State<_UFullScreenVideo> createState() => _UFullScreenVideoState();
}

class _UFullScreenVideoState extends State<_UFullScreenVideo> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: <Widget>[
        Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: VideoPlayer(widget.controller),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            widget.controller,
            allowScrubbing: true,
            colors: VideoProgressColors(playedColor: widget.accentColor),
          ),
        ),
        Center(
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: widget.controller,
            builder: (BuildContext context, VideoPlayerValue value, _) => GestureDetector(
              onTap: () => value.isPlaying ? widget.controller.pause() : widget.controller.play(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                child: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Convenience helpers for opening a [UVideoPlayer] as an overlay.
abstract class UVideo {
  /// Opens the player full-width inside a bottom sheet. Accepts the same sources
  /// as [UVideoPlayer].
  static Future<void> show({
    String? url,
    String? base64,
    Uint8List? bytes,
    String? filePath,
    String? assetPath,
    bool autoPlay = true,
  }) => UNavigator.bottomSheet(
    UScaffold(
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      color: Colors.black,
      body: Center(
        child: UVideoPlayer(
          url: url,
          base64: base64,
          bytes: bytes,
          filePath: filePath,
          assetPath: assetPath,
          autoPlay: autoPlay,
          borderRadius: 0,
        ),
      ),
    ),
  );
}
