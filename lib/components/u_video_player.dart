import "package:u/utilities.dart";

/// Backwards-compatible wrapper kept so existing call sites keep working after
/// the move off the `video_player` package. New code should use [UVideo] with
/// its own [UMediaController], which exposes the full engine.
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
    this.backgroundColor = const Color(0xFF000000),
    this.borderRadius = 12,
    this.placeholder,
    this.title,
    this.gestures = const UVideoGestureConfig(),
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
  final String? title;
  final UVideoGestureConfig gestures;

  static UMediaFit fitOf(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return UMediaFit.cover;
      case BoxFit.fill:
        return UMediaFit.fill;
      case BoxFit.fitWidth:
        return UMediaFit.fitWidth;
      case BoxFit.fitHeight:
        return UMediaFit.fitHeight;
      case BoxFit.none:
        return UMediaFit.none;
      case BoxFit.contain:
      case BoxFit.scaleDown:
        return UMediaFit.contain;
    }
  }

  @override
  State<UVideoPlayer> createState() => _UVideoPlayerState();
}

class _UVideoPlayerState extends State<UVideoPlayer> {
  late final UMediaController _controller;
  late final UVideoSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = UVideoSettings(fit: UVideoPlayer.fitOf(widget.fit));
    _controller = UMediaController(
      config: UMediaConfig(
        autoPlay: widget.autoPlay,
        muted: widget.muted,
        repeat: widget.looping ? URepeatMode.one : URepeatMode.off,
      ),
    );
    unawaited(_controller.open(_source(), autoPlay: widget.autoPlay));
  }

  @override
  void didUpdateWidget(covariant UVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.filePath != widget.filePath || oldWidget.assetPath != widget.assetPath) {
      unawaited(_controller.open(_source(), autoPlay: widget.autoPlay));
    }
    if (oldWidget.fit != widget.fit) _settings.fit = UVideoPlayer.fitOf(widget.fit);
  }

  UMediaSource _source() {
    final Uint8List? raw = widget.bytes;
    if (raw != null) return UMediaSource.bytes(raw);

    final String? encoded = widget.base64;
    if (encoded != null) {
      final String payload = encoded.contains(",") ? encoded.split(",").last : encoded;
      return UMediaSource.bytes(base64Decode(payload));
    }

    final String? path = widget.filePath;
    if (path != null) return UMediaSource.file(path);

    final String? asset = widget.assetPath;
    if (asset != null) return UMediaSource.asset(asset);

    return UMediaSource.network(widget.url ?? "");
  }

  @override
  void dispose() {
    _controller.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UVideo(
    controller: _controller,
    settings: _settings,
    title: widget.title,
    gestures: widget.gestures,
    accentColor: widget.accentColor,
    backgroundColor: widget.backgroundColor,
    borderRadius: widget.borderRadius,
    showControls: widget.showControls,
    showFullscreenButton: widget.allowFullScreen,
    autoHide: widget.autoHideControls ? const Duration(seconds: 3) : Duration.zero,
    aspectRatio: widget.aspectRatio,
    placeholder: widget.placeholder,
  );
}

/// Opens a player full-width inside a bottom sheet. Accepts the same sources as
/// [UVideoPlayer].
abstract final class UVideoSheet {
  static Future<void> show({
    String? url,
    String? base64,
    Uint8List? bytes,
    String? filePath,
    String? assetPath,
    String? title,
    bool autoPlay = true,
  }) => UNavigator.bottomSheet(
    UScaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF000000), iconTheme: const IconThemeData(color: Color(0xFFFFFFFF))),
      color: const Color(0xFF000000),
      body: Center(
        child: UVideoPlayer(
          url: url,
          base64: base64,
          bytes: bytes,
          filePath: filePath,
          assetPath: assetPath,
          title: title,
          autoPlay: autoPlay,
          borderRadius: 0,
        ),
      ),
    ),
  );
}
