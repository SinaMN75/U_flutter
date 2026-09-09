import "package:u/utilities.dart";

class UMediaValue {
  const UMediaValue({
    this.state = UMediaState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.buffered = const <UBufferedRange>[],
    this.isLive = false,
    this.liveOffset = Duration.zero,
    this.speed = 1,
    this.volume = 1,
    this.muted = false,
    this.width = 0,
    this.height = 0,
    this.rotationDegrees = 0,
    this.tracks = const <UMediaTrack>[],
    this.currentIndex = 0,
    this.queueLength = 0,
    this.shuffle = false,
    this.repeat = URepeatMode.off,
    this.pip = UPipState.unavailable,
    this.metadata,
    this.error,
  });

  final UMediaState state;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final List<UBufferedRange> buffered;
  final bool isLive;
  final Duration liveOffset;
  final double speed;
  final double volume;
  final bool muted;
  final int width;
  final int height;
  final int rotationDegrees;
  final List<UMediaTrack> tracks;
  final int currentIndex;
  final int queueLength;
  final bool shuffle;
  final URepeatMode repeat;
  final UPipState pip;
  final UMediaMetadata? metadata;
  final UMediaError? error;

  bool get isPlaying => state == UMediaState.playing;

  bool get isBuffering => state == UMediaState.buffering || state == UMediaState.loading;

  bool get isReady => state != UMediaState.idle && state != UMediaState.loading && state != UMediaState.error;

  bool get hasError => error != null;

  bool get hasVideo => width > 0 && height > 0;

  double get aspectRatio {
    if (!hasVideo) return 16 / 9;
    final bool swapped = rotationDegrees == 90 || rotationDegrees == 270;
    final double w = (swapped ? height : width).toDouble();
    final double h = (swapped ? width : height).toDouble();
    return h == 0 ? 16 / 9 : w / h;
  }

  double get progress {
    final int total = duration.inMilliseconds;
    return total <= 0 ? 0 : (position.inMilliseconds / total).clamp(0, 1).toDouble();
  }

  List<UMediaTrack> tracksOf(UMediaTrackType type) => tracks.where((UMediaTrack t) => t.type == type).toList(growable: false);

  UMediaTrack? selectedTrack(UMediaTrackType type) {
    for (final UMediaTrack track in tracks) {
      if (track.type == type && track.isSelected) return track;
    }
    return null;
  }

  UMediaValue copyWith({
    UMediaState? state,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    List<UBufferedRange>? buffered,
    bool? isLive,
    Duration? liveOffset,
    double? speed,
    double? volume,
    bool? muted,
    int? width,
    int? height,
    int? rotationDegrees,
    List<UMediaTrack>? tracks,
    int? currentIndex,
    int? queueLength,
    bool? shuffle,
    URepeatMode? repeat,
    UPipState? pip,
    UMediaMetadata? metadata,
    UMediaError? error,
    bool clearError = false,
  }) => UMediaValue(
    state: state ?? this.state,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    bufferedPosition: bufferedPosition ?? this.bufferedPosition,
    buffered: buffered ?? this.buffered,
    isLive: isLive ?? this.isLive,
    liveOffset: liveOffset ?? this.liveOffset,
    speed: speed ?? this.speed,
    volume: volume ?? this.volume,
    muted: muted ?? this.muted,
    width: width ?? this.width,
    height: height ?? this.height,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    tracks: tracks ?? this.tracks,
    currentIndex: currentIndex ?? this.currentIndex,
    queueLength: queueLength ?? this.queueLength,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
    pip: pip ?? this.pip,
    metadata: metadata ?? this.metadata,
    error: clearError ? null : (error ?? this.error),
  );
}
