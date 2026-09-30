import "package:u/utilities.dart";

// Media enums, errors, sources, tracks, metadata, value and config.

/// Player state: idle, loading, ready, playing, paused, buffering, completed, error.
enum UMediaState { idle, loading, buffering, ready, playing, paused, completed, error }

/// Player kind: video or audio.
enum UMediaKind { video, audio }

/// Repeat: off, one, all.
enum URepeatMode { off, one, all }

/// Track type: video, audio, subtitle.
enum UMediaTrackType { video, audio, subtitle }

/// Source type: network, file, asset, bytes, content.
enum UMediaSourceKind { network, file, asset, bytes, content, stream }

/// Stream type: progressive, hls, dash, rtsp, rtmp.
enum UStreamProtocol { progressive, hls, dash, smoothStreaming, rtsp, rtmp, srt, webrtc }

/// Why playback failed.
enum UMediaErrorCode { network, timeout, unsupportedFormat, decoder, drm, notFound, permission, aborted, cancelled, outOfMemory, unknown }

/// Hardware decoding preference.
enum UHwAccel { auto, forced, disabled }

/// Subtitle format: srt, vtt, ass, lrc, microdvd.
enum USubtitleFormat { srt, vtt, ass, ssa, sub, ttml, lrc, pgs, cea608, cea708 }

/// Video fit: contain, cover, fill, 16:9, 4:3…
enum UMediaFit { contain, cover, fill, fitWidth, fitHeight, none, ratio16x9, ratio4x3, ratio21x9, ratio1x1, original }

/// What to do when another app plays audio.
enum UAudioFocusPolicy { exclusive, duck, mixWithOthers }

/// DRM: widevine, playready, clearkey, fairplay.
enum UDrmScheme { widevine, fairplay, playready, clearkey }

/// Built-in equalizer presets.
enum UEqualizerPreset { flat, pop, rock, jazz, classical, dance, bass, treble, vocal, custom }

/// Picture-in-picture state.
enum UPipState { unavailable, available, active }

/// Player log verbosity.
enum UMediaLogLevel { none, error, warning, info, verbose }

/// A playlist/subtitle/tag could not be parsed.
class UMediaParseException implements Exception {
  const UMediaParseException(this.message, {this.offset});

  final String message;
  final int? offset;

  @override
  String toString() => offset == null ? "UMediaParseException: $message" : "UMediaParseException: $message (at $offset)";
}

/// A playback error with a code and message.
class UMediaError implements Exception {
  const UMediaError({required this.code, required this.message, this.detail, this.platformCode, this.sourceId});

  final UMediaErrorCode code;
  final String message;
  final String? detail;
  final String? platformCode;
  final String? sourceId;

  bool get isRecoverable => code == UMediaErrorCode.network || code == UMediaErrorCode.timeout;

  factory UMediaError.fromMap(Map<Object?, Object?> map) => UMediaError(
    code: UMediaErrorCode.values.firstWhere(
      (UMediaErrorCode e) => e.name == map["code"],
      orElse: () => UMediaErrorCode.unknown,
    ),
    message: (map["message"] as String?) ?? "",
    detail: map["detail"] as String?,
    platformCode: map["platformCode"] as String?,
    sourceId: map["sourceId"] as String?,
  );

  @override
  String toString() => "UMediaError(${code.name}): $message${detail == null ? "" : " — $detail"}";
}

/// Internal: safety limit for tag parsing.
const int uMaxTagAllocation = 24 * 1024 * 1024;

/// Internal: byte reader.
class UByteReader {
  UByteReader(Uint8List bytes, {int start = 0, int? end}) : _bytes = bytes, _pos = start, _end = end ?? bytes.length {
    if (start < 0 || _end > bytes.length || start > _end) throw const UMediaParseException("Invalid reader window");
  }

  final Uint8List _bytes;
  final int _end;
  int _pos;

  int get position => _pos;

  int get end => _end;

  int get remaining => _end - _pos;

  bool get isEmpty => _pos >= _end;

  bool canRead(int count) => count >= 0 && remaining >= count;

  void _require(int count) {
    if (count < 0) throw const UMediaParseException("Negative read length");
    if (remaining < count) throw UMediaParseException("Read of $count exceeds buffer", offset: _pos);
  }

  int guardedLength(int declared, {int cap = uMaxTagAllocation}) {
    if (declared < 0) return 0;
    final int limit = cap < remaining ? cap : remaining;
    return declared > limit ? limit : declared;
  }

  void seek(int absolute) {
    if (absolute < 0 || absolute > _end) throw UMediaParseException("Seek out of range", offset: absolute);
    _pos = absolute;
  }

  void skip(int count) {
    _require(count);
    _pos += count;
  }

  int u8() {
    _require(1);
    return _bytes[_pos++];
  }

  int u16be() {
    _require(2);
    final int value = (_bytes[_pos] << 8) | _bytes[_pos + 1];
    _pos += 2;
    return value;
  }

  int u16le() {
    _require(2);
    final int value = _bytes[_pos] | (_bytes[_pos + 1] << 8);
    _pos += 2;
    return value;
  }

  int u24be() {
    _require(3);
    final int value = (_bytes[_pos] << 16) | (_bytes[_pos + 1] << 8) | _bytes[_pos + 2];
    _pos += 3;
    return value;
  }

  int u32be() {
    _require(4);
    final int value = (_bytes[_pos] << 24) | (_bytes[_pos + 1] << 16) | (_bytes[_pos + 2] << 8) | _bytes[_pos + 3];
    _pos += 4;
    return value;
  }

  int u32le() {
    _require(4);
    final int value = _bytes[_pos] | (_bytes[_pos + 1] << 8) | (_bytes[_pos + 2] << 16) | (_bytes[_pos + 3] << 24);
    _pos += 4;
    return value;
  }

  int u64be() {
    _require(8);
    final int high = u32be();
    final int low = u32be();
    return (high << 32) | low;
  }

  int syncSafe32() {
    _require(4);
    final int a = _bytes[_pos] & 0x7F;
    final int b = _bytes[_pos + 1] & 0x7F;
    final int c = _bytes[_pos + 2] & 0x7F;
    final int d = _bytes[_pos + 3] & 0x7F;
    _pos += 4;
    return (a << 21) | (b << 14) | (c << 7) | d;
  }

  Uint8List take(int count) {
    _require(count);
    final Uint8List view = Uint8List.sublistView(_bytes, _pos, _pos + count);
    _pos += count;
    return view;
  }

  Uint8List takeGuarded(int declared, {int cap = uMaxTagAllocation}) => take(guardedLength(declared, cap: cap));

  Uint8List peek(int count) {
    _require(count);
    return Uint8List.sublistView(_bytes, _pos, _pos + count);
  }

  String ascii(int count) {
    final Uint8List raw = take(count);
    final StringBuffer buffer = StringBuffer();
    for (final int byte in raw) {
      if (byte == 0) continue;
      buffer.writeCharCode(byte < 0x20 || byte > 0x7E ? 0x20 : byte);
    }
    return buffer.toString().trim();
  }

  String latin1Trimmed(int count) => String.fromCharCodes(take(count).where((int b) => b != 0)).trim();

  UByteReader window(int count) {
    _require(count);
    final UByteReader child = UByteReader(_bytes, start: _pos, end: _pos + count);
    _pos += count;
    return child;
  }

  int indexOfByte(int value, {int from = -1}) {
    final int start = from < 0 ? _pos : from;
    for (int i = start; i < _end; i++) {
      if (_bytes[i] == value) return i;
    }
    return -1;
  }
}

/// Where artwork comes from (URL, file tag, bytes).
class UArtworkRef {
  const UArtworkRef.uri(this.uri) : filePath = null, offset = 0, length = 0, mimeType = null;

  const UArtworkRef.embedded({required this.filePath, required this.offset, required this.length, this.mimeType}) : uri = null;

  final String? uri;
  final String? filePath;
  final int offset;
  final int length;
  final String? mimeType;

  bool get isEmbedded => filePath != null && length > 0;

  bool get isEmpty => uri == null && !isEmbedded;

  String get cacheKey => isEmbedded ? "$filePath:$offset:$length" : (uri ?? "");
}

/// Title, artist, album, artwork and duration (shown on the lock screen). `const UMediaMetadata(title: "Song", artist: "Me")`
class UMediaMetadata {
  const UMediaMetadata({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.composer,
    this.genre,
    this.year,
    this.trackNumber,
    this.trackCount,
    this.discNumber,
    this.duration,
    this.artwork,
    this.lyrics,
    this.comment,
    this.extras = const <String, String>{},
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? composer;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? trackCount;
  final int? discNumber;
  final Duration? duration;
  final UArtworkRef? artwork;
  final String? lyrics;
  final String? comment;
  final Map<String, String> extras;

  bool get isEmpty => title == null && artist == null && album == null;

  String get displayTitle => title ?? "";

  String get displaySubtitle {
    if (artist != null && album != null) return "$artist — $album";
    return artist ?? album ?? "";
  }

  UMediaMetadata merge(UMediaMetadata other) => UMediaMetadata(
    title: other.title ?? title,
    artist: other.artist ?? artist,
    album: other.album ?? album,
    albumArtist: other.albumArtist ?? albumArtist,
    composer: other.composer ?? composer,
    genre: other.genre ?? genre,
    year: other.year ?? year,
    trackNumber: other.trackNumber ?? trackNumber,
    trackCount: other.trackCount ?? trackCount,
    discNumber: other.discNumber ?? discNumber,
    duration: other.duration ?? duration,
    artwork: other.artwork ?? artwork,
    lyrics: other.lyrics ?? lyrics,
    comment: other.comment ?? comment,
    extras: <String, String>{...extras, ...other.extras},
  );

  Map<String, Object?> toMap() => <String, Object?>{
    "title": title,
    "artist": artist,
    "album": album,
    "albumArtist": albumArtist,
    "genre": genre,
    "year": year,
    "trackNumber": trackNumber,
    "durationMs": duration?.inMilliseconds,
    "artworkUri": artwork?.uri,
  };
}

/// A buffered part of the media.
class UBufferedRange {
  const UBufferedRange(this.start, this.end);

  final Duration start;
  final Duration end;

  Duration get length => end - start;
}

/// An audio/video/subtitle track.
class UMediaTrack {
  const UMediaTrack({
    required this.id,
    required this.type,
    this.label,
    this.language,
    this.codec,
    this.bitrate,
    this.width,
    this.height,
    this.frameRate,
    this.channels,
    this.sampleRate,
    this.isDefault = false,
    this.isForced = false,
    this.isSelected = false,
    this.isAuto = false,
  });

  final String id;
  final UMediaTrackType type;
  final String? label;
  final String? language;
  final String? codec;
  final int? bitrate;
  final int? width;
  final int? height;
  final double? frameRate;
  final int? channels;
  final int? sampleRate;
  final bool isDefault;
  final bool isForced;
  final bool isSelected;
  final bool isAuto;

  String get qualityLabel {
    if (height == null || height == 0) return "";
    return "${height}p";
  }

  String get bitrateLabel {
    final int? value = bitrate;
    if (value == null || value <= 0) return "";
    return value >= 1000000 ? "${(value / 1000000).toStringAsFixed(1)} Mbps" : "${(value / 1000).round()} kbps";
  }

  String get channelLabel {
    switch (channels) {
      case 1:
        return "Mono";
      case 2:
        return "Stereo";
      case 6:
        return "5.1";
      case 8:
        return "7.1";
      default:
        return channels == null ? "" : "$channels ch";
    }
  }

  factory UMediaTrack.fromMap(Map<Object?, Object?> map) => UMediaTrack(
    id: (map["id"] as String?) ?? "",
    type: UMediaTrackType.values.firstWhere((UMediaTrackType t) => t.name == map["type"], orElse: () => UMediaTrackType.video),
    label: map["label"] as String?,
    language: map["language"] as String?,
    codec: map["codec"] as String?,
    bitrate: map["bitrate"] as int?,
    width: map["width"] as int?,
    height: map["height"] as int?,
    frameRate: (map["frameRate"] as num?)?.toDouble(),
    channels: map["channels"] as int?,
    sampleRate: map["sampleRate"] as int?,
    isDefault: map["isDefault"] == true,
    isForced: map["isForced"] == true,
    isSelected: map["isSelected"] == true,
    isAuto: map["isAuto"] == true,
  );

  UMediaTrack copyWith({bool? isSelected}) => UMediaTrack(
    id: id,
    type: type,
    label: label,
    language: language,
    codec: codec,
    bitrate: bitrate,
    width: width,
    height: height,
    frameRate: frameRate,
    channels: channels,
    sampleRate: sampleRate,
    isDefault: isDefault,
    isForced: isForced,
    isSelected: isSelected ?? this.isSelected,
    isAuto: isAuto,
  );
}

/// DRM license settings.
class UDrmConfig {
  const UDrmConfig({required this.scheme, this.licenseUrl, this.headers = const <String, String>{}, this.clearKeys = const <String, String>{}, this.offlineLicenseId, this.multiSession = false});

  final UDrmScheme scheme;
  final String? licenseUrl;
  final Map<String, String> headers;
  final Map<String, String> clearKeys;
  final String? offlineLicenseId;
  final bool multiSession;

  Map<String, Object?> toMap() => <String, Object?>{
    "scheme": scheme.name,
    "licenseUrl": licenseUrl,
    "headers": headers,
    "clearKeys": clearKeys,
    "offlineLicenseId": offlineLicenseId,
    "multiSession": multiSession,
  };
}

/// A subtitle file added to a video (URL or path). `UExternalSubtitle(uri: "https://x.com/fa.srt", language: "fa")`
class UExternalSubtitle {
  const UExternalSubtitle({required this.uri, this.label, this.language, this.format, this.encoding, this.isDefault = false});

  final String uri;
  final String? label;
  final String? language;
  final USubtitleFormat? format;
  final String? encoding;
  final bool isDefault;

  Map<String, Object?> toMap() => <String, Object?>{
    "uri": uri,
    "label": label,
    "language": language,
    "format": format?.name,
    "encoding": encoding,
    "isDefault": isDefault,
  };
}

/// What to play: network, file, asset, bytes or content URI (see UMedia.network…).
sealed class UMediaSource {
  const UMediaSource({
    required this.id,
    this.metadata,
    this.startPosition,
    this.endPosition,
    this.externalSubtitles = const <UExternalSubtitle>[],
    this.drm,
  });

  final String id;
  final UMediaMetadata? metadata;
  final Duration? startPosition;
  final Duration? endPosition;
  final List<UExternalSubtitle> externalSubtitles;
  final UDrmConfig? drm;

  UMediaSourceKind get kind;

  static UMediaSource network(
    String url, {
    String? id,
    UMediaMetadata? metadata,
    Map<String, String> headers = const <String, String>{},
    String? userAgent,
    UStreamProtocol? protocol,
    Duration? startPosition,
    Duration? endPosition,
    List<UExternalSubtitle> externalSubtitles = const <UExternalSubtitle>[],
    UDrmConfig? drm,
  }) => UNetworkSource(
    url,
    id: id,
    metadata: metadata,
    headers: headers,
    userAgent: userAgent,
    protocol: protocol,
    startPosition: startPosition,
    endPosition: endPosition,
    externalSubtitles: externalSubtitles,
    drm: drm,
  );

  static UMediaSource file(
    String path, {
    String? id,
    UMediaMetadata? metadata,
    Duration? startPosition,
    Duration? endPosition,
    List<UExternalSubtitle> externalSubtitles = const <UExternalSubtitle>[],
  }) => UFileSource(path, id: id, metadata: metadata, startPosition: startPosition, endPosition: endPosition, externalSubtitles: externalSubtitles);

  static UMediaSource asset(String assetPath, {String? id, UMediaMetadata? metadata, Duration? startPosition, Duration? endPosition}) =>
      UAssetSource(assetPath, id: id, metadata: metadata, startPosition: startPosition, endPosition: endPosition);

  static UMediaSource bytes(Uint8List data, {String? id, String? mimeType, UMediaMetadata? metadata}) => UBytesSource(data, id: id, mimeType: mimeType, metadata: metadata);

  static UMediaSource content(String uri, {String? id, UMediaMetadata? metadata, Duration? startPosition}) => UContentSource(uri, id: id, metadata: metadata, startPosition: startPosition);

  Map<String, Object?> toMap();

  Map<String, Object?> _base() => <String, Object?>{
    "id": id,
    "kind": kind.name,
    "startMs": startPosition?.inMilliseconds,
    "endMs": endPosition?.inMilliseconds,
    "metadata": metadata?.toMap(),
    "drm": drm?.toMap(),
    "subtitles": externalSubtitles.map((UExternalSubtitle s) => s.toMap()).toList(),
  };
}

/// Media from a URL.
final class UNetworkSource extends UMediaSource {
  UNetworkSource(
    this.url, {
    String? id,
    super.metadata,
    this.headers = const <String, String>{},
    this.userAgent,
    this.protocol,
    super.startPosition,
    super.endPosition,
    super.externalSubtitles,
    super.drm,
  }) : super(id: id ?? url);

  final String url;
  final Map<String, String> headers;
  final String? userAgent;
  final UStreamProtocol? protocol;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.network;

  UStreamProtocol get resolvedProtocol => protocol ?? _sniff(url);

  static UStreamProtocol _sniff(String url) {
    final String lower = url.toLowerCase().split("?").first;
    if (lower.endsWith(".m3u8")) return UStreamProtocol.hls;
    if (lower.endsWith(".mpd")) return UStreamProtocol.dash;
    if (lower.endsWith(".ism") || lower.contains("/manifest")) return UStreamProtocol.smoothStreaming;
    if (lower.startsWith("rtsp://")) return UStreamProtocol.rtsp;
    if (lower.startsWith("rtmp://") || lower.startsWith("rtmps://")) return UStreamProtocol.rtmp;
    if (lower.startsWith("srt://")) return UStreamProtocol.srt;
    return UStreamProtocol.progressive;
  }

  @override
  Map<String, Object?> toMap() => <String, Object?>{
    ..._base(),
    "url": url,
    "headers": headers,
    "userAgent": userAgent,
    "protocol": resolvedProtocol.name,
  };
}

/// Media from a file.
final class UFileSource extends UMediaSource {
  UFileSource(this.path, {String? id, super.metadata, super.startPosition, super.endPosition, super.externalSubtitles}) : super(id: id ?? path);

  final String path;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.file;

  @override
  Map<String, Object?> toMap() => <String, Object?>{..._base(), "path": path};
}

/// Media from an asset.
final class UAssetSource extends UMediaSource {
  UAssetSource(this.assetPath, {String? id, super.metadata, super.startPosition, super.endPosition}) : super(id: id ?? assetPath);

  final String assetPath;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.asset;

  @override
  Map<String, Object?> toMap() => <String, Object?>{..._base(), "asset": assetPath};
}

/// Media from bytes.
final class UBytesSource extends UMediaSource {
  UBytesSource(this.data, {String? id, this.mimeType, super.metadata}) : super(id: id ?? "bytes:${data.length}:${data.hashCode}");

  final Uint8List data;
  final String? mimeType;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.bytes;

  @override
  Map<String, Object?> toMap() => <String, Object?>{..._base(), "bytes": data, "mimeType": mimeType};
}

/// Media from an Android content URI.
final class UContentSource extends UMediaSource {
  UContentSource(this.uri, {String? id, super.metadata, super.startPosition}) : super(id: id ?? uri);

  final String uri;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.content;

  @override
  Map<String, Object?> toMap() => <String, Object?>{..._base(), "uri": uri};
}

/// Player state snapshot: state, position, duration, buffered, volume, speed, tracks.
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

/// Player settings: buffering, hardware decoding, audio focus, wake lock, notification. `UMediaConfig.music`
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

  UMediaConfig copyWith({
    bool? autoPlay,
    bool? muted,
    double? volume,
    double? speed,
    URepeatMode? repeat,
    bool? shuffle,
    int? maxHeight,
    bool? abrEnabled,
    bool? allowBackgroundPlayback,
    bool? subtitlesEnabled,
    String? preferredSubtitleLanguage,
    String? preferredAudioLanguage,
    Duration? crossfade,
  }) => UMediaConfig(
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
