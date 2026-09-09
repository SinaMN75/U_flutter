import "package:u/utilities.dart";

class UMediaConfig {
  const UMediaConfig({
    this.autoPlay = false,
    this.muted = false,
    this.volume = 1,
    this.speed = 1,
    this.repeat = URepeatMode.off,
    this.shuffle = false,
    this.hwAccel = UHwAccel.auto,
    this.minBufferMs = 15000,
    this.maxBufferMs = 50000,
    this.bufferForPlaybackMs = 2500,
    this.bufferForPlaybackAfterRebufferMs = 5000,
    this.maxCacheBytes = 0,
    this.positionUpdateInterval = const Duration(milliseconds: 250),
    this.focusPolicy = UAudioFocusPolicy.exclusive,
    this.pauseOnBecomingNoisy = true,
    this.wakeLock = true,
    this.allowBackgroundPlayback = false,
    this.preloadNext = true,
    this.gapless = true,
    this.crossfade,
    this.preferredAudioLanguage,
    this.preferredSubtitleLanguage,
    this.subtitlesEnabled = true,
    this.maxHeight = 0,
    this.maxCellularHeight = 0,
    this.abrEnabled = true,
    this.preferredHeight = 0,
    this.retryLimit = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.connectTimeout = const Duration(seconds: 15),
    this.logLevel = UMediaLogLevel.error,
  });

  final bool autoPlay;
  final bool muted;
  final double volume;
  final double speed;
  final URepeatMode repeat;
  final bool shuffle;
  final UHwAccel hwAccel;
  final int minBufferMs;
  final int maxBufferMs;
  final int bufferForPlaybackMs;
  final int bufferForPlaybackAfterRebufferMs;
  final int maxCacheBytes;
  final Duration positionUpdateInterval;
  final UAudioFocusPolicy focusPolicy;
  final bool pauseOnBecomingNoisy;
  final bool wakeLock;
  final bool allowBackgroundPlayback;
  final bool preloadNext;
  final bool gapless;
  final Duration? crossfade;
  final String? preferredAudioLanguage;
  final String? preferredSubtitleLanguage;
  final bool subtitlesEnabled;
  final int maxHeight;
  final int maxCellularHeight;
  final bool abrEnabled;
  final int preferredHeight;
  final int retryLimit;
  final Duration retryDelay;
  final Duration connectTimeout;
  final UMediaLogLevel logLevel;

  static const UMediaConfig video = UMediaConfig();

  static const UMediaConfig music = UMediaConfig(
    allowBackgroundPlayback: true,
    wakeLock: false,
    minBufferMs: 30000,
    maxBufferMs: 120000,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    "autoPlay": autoPlay,
    "muted": muted,
    "volume": volume,
    "speed": speed,
    "repeat": repeat.name,
    "shuffle": shuffle,
    "hwAccel": hwAccel.name,
    "minBufferMs": minBufferMs,
    "maxBufferMs": maxBufferMs,
    "bufferForPlaybackMs": bufferForPlaybackMs,
    "bufferForPlaybackAfterRebufferMs": bufferForPlaybackAfterRebufferMs,
    "maxCacheBytes": maxCacheBytes,
    "positionUpdateMs": positionUpdateInterval.inMilliseconds,
    "focusPolicy": focusPolicy.name,
    "pauseOnBecomingNoisy": pauseOnBecomingNoisy,
    "wakeLock": wakeLock,
    "allowBackgroundPlayback": allowBackgroundPlayback,
    "preloadNext": preloadNext,
    "gapless": gapless,
    "crossfadeMs": crossfade?.inMilliseconds,
    "preferredAudioLanguage": preferredAudioLanguage,
    "preferredSubtitleLanguage": preferredSubtitleLanguage,
    "subtitlesEnabled": subtitlesEnabled,
    "maxHeight": maxHeight,
    "maxCellularHeight": maxCellularHeight,
    "abrEnabled": abrEnabled,
    "preferredHeight": preferredHeight,
    "retryLimit": retryLimit,
    "retryDelayMs": retryDelay.inMilliseconds,
    "connectTimeoutMs": connectTimeout.inMilliseconds,
    "logLevel": logLevel.name,
  };

  UMediaConfig copyWith({bool? autoPlay, bool? muted, double? volume, double? speed, URepeatMode? repeat, bool? shuffle, int? maxHeight, bool? abrEnabled, bool? allowBackgroundPlayback, bool? subtitlesEnabled, String? preferredSubtitleLanguage, String? preferredAudioLanguage, Duration? crossfade}) => UMediaConfig(
    autoPlay: autoPlay ?? this.autoPlay,
    muted: muted ?? this.muted,
    volume: volume ?? this.volume,
    speed: speed ?? this.speed,
    repeat: repeat ?? this.repeat,
    shuffle: shuffle ?? this.shuffle,
    hwAccel: hwAccel,
    minBufferMs: minBufferMs,
    maxBufferMs: maxBufferMs,
    bufferForPlaybackMs: bufferForPlaybackMs,
    bufferForPlaybackAfterRebufferMs: bufferForPlaybackAfterRebufferMs,
    maxCacheBytes: maxCacheBytes,
    positionUpdateInterval: positionUpdateInterval,
    focusPolicy: focusPolicy,
    pauseOnBecomingNoisy: pauseOnBecomingNoisy,
    wakeLock: wakeLock,
    allowBackgroundPlayback: allowBackgroundPlayback ?? this.allowBackgroundPlayback,
    preloadNext: preloadNext,
    gapless: gapless,
    crossfade: crossfade ?? this.crossfade,
    preferredAudioLanguage: preferredAudioLanguage ?? this.preferredAudioLanguage,
    preferredSubtitleLanguage: preferredSubtitleLanguage ?? this.preferredSubtitleLanguage,
    subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
    maxHeight: maxHeight ?? this.maxHeight,
    maxCellularHeight: maxCellularHeight,
    abrEnabled: abrEnabled ?? this.abrEnabled,
    preferredHeight: preferredHeight,
    retryLimit: retryLimit,
    retryDelay: retryDelay,
    connectTimeout: connectTimeout,
    logLevel: logLevel,
  );
}
