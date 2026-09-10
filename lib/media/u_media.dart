import "package:u/utilities.dart";

enum UMediaState { idle, loading, buffering, ready, playing, paused, completed, error }

enum UMediaKind { video, audio }

enum URepeatMode { off, one, all }

enum UMediaTrackType { video, audio, subtitle }

enum UMediaSourceKind { network, file, asset, bytes, content, stream }

enum UStreamProtocol { progressive, hls, dash, smoothStreaming, rtsp, rtmp, srt, webrtc }

enum UMediaErrorCode { network, timeout, unsupportedFormat, decoder, drm, notFound, permission, aborted, cancelled, outOfMemory, unknown }

enum UHwAccel { auto, forced, disabled }

enum USubtitleFormat { srt, vtt, ass, ssa, sub, ttml, lrc, pgs, cea608, cea708 }

enum UMediaFit { contain, cover, fill, fitWidth, fitHeight, none, ratio16x9, ratio4x3, ratio21x9, ratio1x1, original }

enum UAudioFocusPolicy { exclusive, duck, mixWithOthers }

enum UDrmScheme { widevine, fairplay, playready, clearkey }

enum UEqualizerPreset { flat, pop, rock, jazz, classical, dance, bass, treble, vocal, custom }

enum UDownloadState { queued, running, paused, completed, failed, removed }

enum UPipState { unavailable, available, active }

enum UMediaLogLevel { none, error, warning, info, verbose }

class UMediaParseException implements Exception {
  const UMediaParseException(this.message, {this.offset});

  final String message;
  final int? offset;

  @override
  String toString() => offset == null ? "UMediaParseException: $message" : "UMediaParseException: $message (at $offset)";
}

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

const int uMaxTagAllocation = 24 * 1024 * 1024;

class UByteReader {
  UByteReader(Uint8List bytes, {int start = 0, int? end})
    : _bytes = bytes,
      _pos = start,
      _end = end ?? bytes.length {
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

class UBufferedRange {
  const UBufferedRange(this.start, this.end);

  final Duration start;
  final Duration end;

  Duration get length => end - start;
}

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

final class UFileSource extends UMediaSource {
  UFileSource(this.path, {String? id, super.metadata, super.startPosition, super.endPosition, super.externalSubtitles}) : super(id: id ?? path);

  final String path;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.file;

  @override
  Map<String, Object?> toMap() => <String, Object?>{..._base(), "path": path};
}

final class UAssetSource extends UMediaSource {
  UAssetSource(this.assetPath, {String? id, super.metadata, super.startPosition, super.endPosition}) : super(id: id ?? assetPath);

  final String assetPath;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.asset;

  @override
  Map<String, Object?> toMap() => <String, Object?>{..._base(), "asset": assetPath};
}

final class UBytesSource extends UMediaSource {
  UBytesSource(this.data, {String? id, this.mimeType, super.metadata}) : super(id: id ?? "bytes:${data.length}:${data.hashCode}");

  final Uint8List data;
  final String? mimeType;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.bytes;

  @override
  Map<String, Object?> toMap() => <String, Object?>{..._base(), "bytes": data, "mimeType": mimeType};
}

final class UContentSource extends UMediaSource {
  UContentSource(this.uri, {String? id, super.metadata, super.startPosition}) : super(id: id ?? uri);

  final String uri;

  @override
  UMediaSourceKind get kind => UMediaSourceKind.content;

  @override
  Map<String, Object?> toMap() => <String, Object?>{..._base(), "uri": uri};
}

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

abstract final class UMediaChannel {
  static const MethodChannel _method = MethodChannel("u/media");

  static Future<int> create({required UMediaKind kind, required UMediaConfig config}) async {
    final int? id = await _method.invokeMethod<int>("create", <String, Object?>{"kind": kind.name, "config": config.toMap()});
    if (id == null) throw const UMediaError(code: UMediaErrorCode.unknown, message: "Player could not be created");
    return id;
  }

  static Future<T?> call<T>(int id, String method, [Map<String, Object?>? arguments]) =>
      _method.invokeMethod<T>(method, <String, Object?>{"id": id, ...?arguments});

  static Stream<Map<Object?, Object?>> events(int id) =>
      EventChannel("u/media/events/$id").receiveBroadcastStream().where((Object? event) => event is Map).cast<Map<Object?, Object?>>();

  static Future<bool> isAvailable() async {
    try {
      return (await _method.invokeMethod<bool>("isAvailable")) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static UMediaError toError(PlatformException exception, {String? sourceId}) => UMediaError(
    code: _codeFrom(exception.code),
    message: exception.message ?? exception.code,
    detail: exception.details?.toString(),
    platformCode: exception.code,
    sourceId: sourceId,
  );

  static UMediaErrorCode _codeFrom(String value) {
    for (final UMediaErrorCode code in UMediaErrorCode.values) {
      if (code.name == value) return code;
    }
    switch (value) {
      case "ERROR_NETWORK":
        return UMediaErrorCode.network;
      case "ERROR_TIMEOUT":
        return UMediaErrorCode.timeout;
      case "ERROR_FORMAT":
      case "ERROR_UNSUPPORTED":
        return UMediaErrorCode.unsupportedFormat;
      case "ERROR_DECODER":
        return UMediaErrorCode.decoder;
      case "ERROR_DRM":
        return UMediaErrorCode.drm;
      case "ERROR_NOT_FOUND":
        return UMediaErrorCode.notFound;
      case "ERROR_PERMISSION":
        return UMediaErrorCode.permission;
      default:
        return UMediaErrorCode.unknown;
    }
  }
}

abstract final class UMediaSession {
  static const MethodChannel _channel = MethodChannel("u/media_session");
  static final List<UMediaController> _registered = <UMediaController>[];
  static UMediaController? _holder;
  static bool _handlerAttached = false;

  static UMediaController? get holder => _holder;

  static List<UMediaController> get controllers => List<UMediaController>.unmodifiable(_registered);

  static void register(UMediaController controller) {
    if (_registered.contains(controller)) return;
    _registered.add(controller);
    _attachHandler();
  }

  static void unregister(UMediaController controller) {
    _registered.remove(controller);
    if (identical(_holder, controller)) _holder = null;
  }

  static Future<bool> requestFocus(UMediaController requester) async {
    if (requester.config.focusPolicy == UAudioFocusPolicy.mixWithOthers) return true;

    for (final UMediaController other in List<UMediaController>.of(_registered)) {
      if (identical(other, requester)) continue;
      if (!other.value.isPlaying) continue;
      if (other.config.focusPolicy == UAudioFocusPolicy.mixWithOthers) continue;
      await other.pause();
    }
    _holder = requester;

    try {
      return (await _channel.invokeMethod<bool>("requestFocus", <String, Object?>{
            "policy": requester.config.focusPolicy.name,
            "kind": requester.kind.name,
          })) ??
          true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  static Future<void> abandonFocus(UMediaController controller) async {
    if (!identical(_holder, controller)) return;
    _holder = null;
    try {
      await _channel.invokeMethod<void>("abandonFocus");
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler(_handle);
  }

  static Future<void> _handle(MethodCall call) async {
    final UMediaController? target = _holder;
    if (target == null) return;
    switch (call.method) {
      case "onFocusLost":
        await target.pause();
        break;
      case "onFocusLostTransient":
        await target.pauseForInterruption();
        break;
      case "onFocusGained":
        await target.resumeAfterInterruption();
        break;
      case "onDuck":
        await target.applyDuck(true);
        break;
      case "onUnduck":
        await target.applyDuck(false);
        break;
      case "onBecomingNoisy":
        if (target.config.pauseOnBecomingNoisy) await target.pause();
        break;
      case "onRemotePlay":
        await target.play();
        break;
      case "onRemotePause":
        await target.pause();
        break;
      case "onRemoteNext":
        await target.next();
        break;
      case "onRemotePrevious":
        await target.previous();
        break;
      case "onRemoteStop":
        await target.stop();
        break;
      case "onRemoteSeek":
        final int ms = (call.arguments as Map<Object?, Object?>?)?["positionMs"] as int? ?? 0;
        await target.seek(Duration(milliseconds: ms));
        break;
    }
  }

  static Future<void> pauseAll() async {
    for (final UMediaController controller in List<UMediaController>.of(_registered)) {
      if (controller.value.isPlaying) await controller.pause();
    }
  }
}

class UMediaController extends ValueNotifier<UMediaValue> {
  UMediaController({this.kind = UMediaKind.video, this._config = const UMediaConfig()})
    : super(const UMediaValue());

  final UMediaKind kind;
  UMediaConfig _config;

  int? _playerId;
  int? _textureId;
  StreamSubscription<Map<Object?, Object?>>? _events;
  final StreamController<UMediaValue> _stateController = StreamController<UMediaValue>.broadcast();
  final ValueNotifier<List<USubtitleCue>> activeCues = ValueNotifier<List<USubtitleCue>>(const <USubtitleCue>[]);
  final ValueNotifier<List<double>> audioSpectrum = ValueNotifier<List<double>>(const <double>[]);

  final List<UMediaSource> _queue = <UMediaSource>[];
  List<int> _shuffleOrder = <int>[];
  int _index = 0;
  int _retries = 0;
  bool _disposed = false;
  bool _pausedByInterruption = false;
  double _volumeBeforeDuck = 1;

  USubtitleData? _subtitles;
  Duration _subtitleDelay = Duration.zero;
  double _subtitleScale = 1;

  UMediaConfig get config => _config;

  int? get textureId => _textureId;

  int? get playerId => _playerId;

  bool get isCreated => _playerId != null;

  Stream<UMediaValue> get stateStream => _stateController.stream;

  Stream<Duration> get positionStream => _stateController.stream.map((UMediaValue v) => v.position).distinct();

  List<UMediaSource> get queue => List<UMediaSource>.unmodifiable(_queue);

  int get currentIndex => _index;

  UMediaSource? get currentSource => _index >= 0 && _index < _queue.length ? _queue[_index] : null;

  USubtitleData? get subtitles => _subtitles;

  Duration get subtitleDelay => _subtitleDelay;

  bool get hasNext => _config.repeat == URepeatMode.all || _index < _queue.length - 1;

  bool get hasPrevious => _config.repeat == URepeatMode.all || _index > 0;

  Future<void> _ensureCreated() async {
    if (_playerId != null || _disposed) return;
    final int id = await UMediaChannel.create(kind: kind, config: _config);
    if (_disposed) {
      await UMediaChannel.call<void>(id, "dispose");
      return;
    }
    _playerId = id;
    _events = UMediaChannel.events(id).listen(_onEvent, onError: _onStreamError);
    UMediaSession.register(this);
  }

  void _emit(UMediaValue next) {
    if (_disposed) return;
    value = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  void _onStreamError(Object error) {
    if (error is PlatformException) {
      _emit(value.copyWith(state: UMediaState.error, error: UMediaChannel.toError(error, sourceId: currentSource?.id)));
    }
  }

  void _onEvent(Map<Object?, Object?> event) {
    if (_disposed) return;
    final String type = (event["event"] as String?) ?? "";
    switch (type) {
      case "initialized":
        _textureId = event["textureId"] as int?;
        _retries = 0;
        _emit(
          value.copyWith(
            state: UMediaState.ready,
            duration: Duration(milliseconds: (event["durationMs"] as int?) ?? 0),
            width: (event["width"] as int?) ?? 0,
            height: (event["height"] as int?) ?? 0,
            rotationDegrees: (event["rotation"] as int?) ?? 0,
            isLive: event["isLive"] == true,
            tracks: _tracksFrom(event["tracks"]),
            clearError: true,
          ),
        );
        break;
      case "position":
        final Duration position = Duration(milliseconds: (event["positionMs"] as int?) ?? 0);
        _emit(
          value.copyWith(
            position: position,
            bufferedPosition: Duration(milliseconds: (event["bufferedMs"] as int?) ?? value.bufferedPosition.inMilliseconds),
          ),
        );
        _updateCues(position);
        break;
      case "state":
        _emit(value.copyWith(state: _stateFrom(event["state"] as String?)));
        break;
      case "tracks":
        _emit(value.copyWith(tracks: _tracksFrom(event["tracks"])));
        break;
      case "size":
        _emit(value.copyWith(width: (event["width"] as int?) ?? 0, height: (event["height"] as int?) ?? 0, rotationDegrees: (event["rotation"] as int?) ?? 0));
        break;
      case "buffered":
        _emit(value.copyWith(buffered: _rangesFrom(event["ranges"]), bufferedPosition: Duration(milliseconds: (event["bufferedMs"] as int?) ?? 0)));
        break;
      case "completed":
        _onCompleted();
        break;
      case "pip":
        _emit(value.copyWith(pip: _pipFrom(event["state"] as String?)));
        break;
      case "spectrum":
        final Object? raw = event["magnitudes"];
        if (raw is List<Object?>) audioSpectrum.value = raw.map((Object? v) => (v as num?)?.toDouble() ?? 0).toList(growable: false);
        break;
      case "error":
        _onNativeError(event);
        break;
    }
  }

  UMediaState _stateFrom(String? raw) {
    for (final UMediaState state in UMediaState.values) {
      if (state.name == raw) return state;
    }
    return value.state;
  }

  UPipState _pipFrom(String? raw) {
    for (final UPipState state in UPipState.values) {
      if (state.name == raw) return state;
    }
    return value.pip;
  }

  List<UMediaTrack> _tracksFrom(Object? raw) {
    if (raw is! List<Object?>) return value.tracks;
    return raw.whereType<Map<Object?, Object?>>().map(UMediaTrack.fromMap).toList(growable: false);
  }

  List<UBufferedRange> _rangesFrom(Object? raw) {
    if (raw is! List<Object?>) return const <UBufferedRange>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> m) => UBufferedRange(Duration(milliseconds: (m["startMs"] as int?) ?? 0), Duration(milliseconds: (m["endMs"] as int?) ?? 0)))
        .toList(growable: false);
  }

  Future<void> _onNativeError(Map<Object?, Object?> event) async {
    final UMediaError error = UMediaError.fromMap(event);
    if (error.isRecoverable && _retries < _config.retryLimit) {
      _retries++;
      await Future<void>.delayed(_config.retryDelay);
      if (_disposed) return;
      final UMediaSource? source = currentSource;
      if (source != null) await _load(source, resumeAt: value.position);
      return;
    }
    _emit(value.copyWith(state: UMediaState.error, error: error));
  }

  Future<void> _onCompleted() async {
    if (_config.repeat == URepeatMode.one) {
      await seek(Duration.zero);
      await play();
      return;
    }
    if (_index < _queue.length - 1) {
      await next();
      return;
    }
    if (_config.repeat == URepeatMode.all && _queue.isNotEmpty) {
      await jumpTo(0);
      return;
    }
    _emit(value.copyWith(state: UMediaState.completed, position: value.duration));
    await UMediaSession.abandonFocus(this);
  }

  void _updateCues(Duration position) {
    final USubtitleData? data = _subtitles;
    if (data == null || data.isEmpty || !_config.subtitlesEnabled) {
      if (activeCues.value.isNotEmpty) activeCues.value = const <USubtitleCue>[];
      return;
    }
    final List<USubtitleCue> next = data.activeAt(position, delay: _subtitleDelay, scale: _subtitleScale);
    final List<USubtitleCue> current = activeCues.value;
    if (next.length == current.length && (next.isEmpty || identical(next.first, current.first))) return;
    activeCues.value = next;
  }

  Future<void> open(UMediaSource source, {bool autoPlay = false}) async {
    _queue
      ..clear()
      ..add(source);
    _index = 0;
    _rebuildShuffle();
    await _load(source, autoPlay: autoPlay || _config.autoPlay);
  }

  Future<void> openQueue(List<UMediaSource> sources, {int startIndex = 0, bool autoPlay = false}) async {
    if (sources.isEmpty) return;
    _queue
      ..clear()
      ..addAll(sources);
    _index = startIndex.clamp(0, sources.length - 1);
    _rebuildShuffle();
    await _load(_queue[_index], autoPlay: autoPlay || _config.autoPlay);
  }

  Future<void> _load(UMediaSource source, {bool autoPlay = false, Duration? resumeAt}) async {
    await _ensureCreated();
    final int? id = _playerId;
    if (id == null) return;

    _emit(value.copyWith(state: UMediaState.loading, position: Duration.zero, duration: Duration.zero, currentIndex: _index, queueLength: _queue.length, clearError: true));
    _subtitles = null;
    activeCues.value = const <USubtitleCue>[];

    try {
      await UMediaChannel.call<void>(id, "open", <String, Object?>{
        "source": source.toMap(),
        "autoPlay": autoPlay,
        "resumeMs": (resumeAt ?? source.startPosition)?.inMilliseconds,
      });
      final UExternalSubtitle? preferred = _preferredSubtitle(source);
      if (preferred != null) await loadSubtitle(preferred);
      if (autoPlay) await play();
    } on PlatformException catch (exception) {
      _emit(value.copyWith(state: UMediaState.error, error: UMediaChannel.toError(exception, sourceId: source.id)));
    }
  }

  UExternalSubtitle? _preferredSubtitle(UMediaSource source) {
    if (source.externalSubtitles.isEmpty) return null;
    final String? language = _config.preferredSubtitleLanguage;
    for (final UExternalSubtitle subtitle in source.externalSubtitles) {
      if (language != null && subtitle.language == language) return subtitle;
    }
    for (final UExternalSubtitle subtitle in source.externalSubtitles) {
      if (subtitle.isDefault) return subtitle;
    }
    return null;
  }

  Future<void> play() async {
    final int? id = _playerId;
    if (id == null) return;
    final bool granted = await UMediaSession.requestFocus(this);
    if (!granted) return;
    _pausedByInterruption = false;
    await UMediaChannel.call<void>(id, "play");
    _emit(value.copyWith(state: UMediaState.playing, clearError: true));
  }

  Future<void> pause() async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "pause");
    _emit(value.copyWith(state: UMediaState.paused));
  }

  Future<void> playPause() => value.isPlaying ? pause() : play();

  Future<void> stop() async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "stop");
    await UMediaSession.abandonFocus(this);
    _emit(value.copyWith(state: UMediaState.idle, position: Duration.zero));
    activeCues.value = const <USubtitleCue>[];
  }

  Future<void> seek(Duration position, {bool precise = true}) async {
    final int? id = _playerId;
    if (id == null) return;
    final Duration clamped = position < Duration.zero ? Duration.zero : (value.duration > Duration.zero && position > value.duration ? value.duration : position);
    await UMediaChannel.call<void>(id, "seek", <String, Object?>{"positionMs": clamped.inMilliseconds, "precise": precise});
    _emit(value.copyWith(position: clamped));
    _updateCues(clamped);
  }

  Future<void> seekBy(Duration delta, {bool precise = true}) => seek(value.position + delta, precise: precise);

  Future<void> seekToProgress(double progress) => seek(Duration(milliseconds: (value.duration.inMilliseconds * progress.clamp(0, 1)).round()));

  Future<void> stepFrame({int frames = 1}) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "stepFrame", <String, Object?>{"frames": frames});
  }

  Future<void> setSpeed(double speed, {bool preservePitch = true}) async {
    final int? id = _playerId;
    if (id == null) return;
    final double clamped = speed.clamp(0.0625, 8).toDouble();
    await UMediaChannel.call<void>(id, "setSpeed", <String, Object?>{"speed": clamped, "preservePitch": preservePitch});
    _emit(value.copyWith(speed: clamped));
  }

  Future<void> setVolume(double volume) async {
    final int? id = _playerId;
    if (id == null) return;
    final double clamped = volume.clamp(0, 2).toDouble();
    await UMediaChannel.call<void>(id, "setVolume", <String, Object?>{"volume": clamped});
    _emit(value.copyWith(volume: clamped, muted: clamped == 0));
  }

  Future<void> setMuted(bool muted) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "setMuted", <String, Object?>{"muted": muted});
    _emit(value.copyWith(muted: muted));
  }

  Future<void> toggleMute() => setMuted(!value.muted);

  Future<void> setRepeat(URepeatMode mode) async {
    _config = _config.copyWith(repeat: mode);
    final int? id = _playerId;
    if (id != null) await UMediaChannel.call<void>(id, "setRepeat", <String, Object?>{"mode": mode.name});
    _emit(value.copyWith(repeat: mode));
  }

  Future<void> setShuffle(bool enabled) async {
    _config = _config.copyWith(shuffle: enabled);
    _rebuildShuffle();
    _emit(value.copyWith(shuffle: enabled));
  }

  Future<void> toggleShuffle() => setShuffle(!_config.shuffle);

  void _rebuildShuffle() {
    if (!_config.shuffle || _queue.length < 2) {
      _shuffleOrder = <int>[];
      return;
    }
    final List<int> order = List<int>.generate(_queue.length, (int i) => i);
    final Random random = Random();
    for (int i = order.length - 1; i > 0; i--) {
      final int j = random.nextInt(i + 1);
      final int temp = order[i];
      order[i] = order[j];
      order[j] = temp;
    }
    final int currentPosition = order.indexOf(_index);
    if (currentPosition > 0) {
      order[currentPosition] = order[0];
      order[0] = _index;
    }
    _shuffleOrder = order;
  }

  int _nextIndex() {
    if (_queue.isEmpty) return _index;
    if (!_config.shuffle || _shuffleOrder.isEmpty) {
      final int candidate = _index + 1;
      return candidate < _queue.length ? candidate : (_config.repeat == URepeatMode.all ? 0 : _index);
    }
    final int position = _shuffleOrder.indexOf(_index);
    final int nextPosition = position + 1;
    if (nextPosition < _shuffleOrder.length) return _shuffleOrder[nextPosition];
    return _config.repeat == URepeatMode.all ? _shuffleOrder.first : _index;
  }

  int _previousIndex() {
    if (_queue.isEmpty) return _index;
    if (!_config.shuffle || _shuffleOrder.isEmpty) {
      final int candidate = _index - 1;
      return candidate >= 0 ? candidate : (_config.repeat == URepeatMode.all ? _queue.length - 1 : 0);
    }
    final int position = _shuffleOrder.indexOf(_index);
    final int previousPosition = position - 1;
    if (previousPosition >= 0) return _shuffleOrder[previousPosition];
    return _config.repeat == URepeatMode.all ? _shuffleOrder.last : _index;
  }

  Future<void> next() async {
    final int target = _nextIndex();
    if (target == _index && _config.repeat != URepeatMode.all) return;
    await jumpTo(target);
  }

  Future<void> previous({Duration restartThreshold = const Duration(seconds: 3)}) async {
    if (value.position > restartThreshold) {
      await seek(Duration.zero);
      return;
    }
    await jumpTo(_previousIndex());
  }

  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    await _load(_queue[index], autoPlay: true);
  }

  Future<void> addToQueue(UMediaSource source) async {
    _queue.add(source);
    _rebuildShuffle();
    _emit(value.copyWith(queueLength: _queue.length));
  }

  Future<void> insertNext(UMediaSource source) async {
    _queue.insert((_index + 1).clamp(0, _queue.length), source);
    _rebuildShuffle();
    _emit(value.copyWith(queueLength: _queue.length));
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _index) _index--;
    _rebuildShuffle();
    _emit(value.copyWith(queueLength: _queue.length, currentIndex: _index));
  }

  Future<void> moveInQueue(int from, int to) async {
    if (from < 0 || from >= _queue.length || to < 0 || to >= _queue.length) return;
    final UMediaSource source = _queue.removeAt(from);
    _queue.insert(to, source);
    if (_index == from) {
      _index = to;
    } else if (from < _index && to >= _index) {
      _index--;
    } else if (from > _index && to <= _index) {
      _index++;
    }
    _rebuildShuffle();
    _emit(value.copyWith(currentIndex: _index));
  }

  Future<void> selectTrack(UMediaTrack track) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "selectTrack", <String, Object?>{"trackId": track.id, "type": track.type.name});
    _emit(value.copyWith(tracks: value.tracks.map((UMediaTrack t) => t.type == track.type ? t.copyWith(isSelected: t.id == track.id) : t).toList(growable: false)));
  }

  Future<void> setAutoQuality() async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "setAutoQuality");
  }

  Future<void> setMaxHeight(int height) async {
    _config = _config.copyWith(maxHeight: height);
    final int? id = _playerId;
    if (id != null) await UMediaChannel.call<void>(id, "setMaxHeight", <String, Object?>{"height": height});
  }

  Future<void> setAudioDelay(Duration delay) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "setAudioDelay", <String, Object?>{"delayMs": delay.inMilliseconds});
  }

  Future<void> loadSubtitle(UExternalSubtitle subtitle) async {
    try {
      final Uint8List bytes = await _fetchBytes(subtitle.uri);
      if (bytes.isEmpty || _disposed) return;
      final USubtitleData data = await compute(_parseSubtitleJob, _SubtitleJob(bytes, subtitle.format, subtitle.encoding, subtitle.language, subtitle.label));
      if (_disposed) return;
      _subtitles = data;
      _updateCues(value.position);
    } on FileSystemException {
      return;
    } on ClientException {
      return;
    }
  }

  Future<void> loadSubtitleData(USubtitleData data) async {
    _subtitles = data;
    _updateCues(value.position);
  }

  Future<Uint8List> _fetchBytes(String uri) async {
    if (uri.startsWith("http://") || uri.startsWith("https://")) {
      final Client client = Client();
      try {
        final Response response = await client.get(Uri.parse(uri)).timeout(_config.connectTimeout);
        return response.statusCode >= 200 && response.statusCode < 300 ? response.bodyBytes : Uint8List(0);
      } on TimeoutException {
        return Uint8List(0);
      } finally {
        client.close();
      }
    }
    if (kIsWeb) return Uint8List(0);
    return File(uri).readAsBytes();
  }

  void clearSubtitles() {
    _subtitles = null;
    activeCues.value = const <USubtitleCue>[];
  }

  void setSubtitleDelay(Duration delay) {
    _subtitleDelay = delay;
    _updateCues(value.position);
  }

  void setSubtitleScale(double scale) {
    _subtitleScale = scale <= 0 ? 1 : scale;
    _updateCues(value.position);
  }

  void setSubtitlesEnabled(bool enabled) {
    _config = _config.copyWith(subtitlesEnabled: enabled);
    _updateCues(value.position);
  }

  Future<void> enterPip({double? aspectRatio}) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "enterPip", <String, Object?>{"aspectRatio": aspectRatio ?? value.aspectRatio});
  }

  Future<void> exitPip() async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "exitPip");
  }

  Future<void> startVisualizer({int bands = 48}) async {
    final int? id = _playerId;
    if (id == null) return;
    try {
      await UMediaChannel.call<void>(id, "startVisualizer", <String, Object?>{"bands": bands});
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<void> stopVisualizer() async {
    final int? id = _playerId;
    if (id == null) return;
    audioSpectrum.value = const <double>[];
    try {
      await UMediaChannel.call<void>(id, "stopVisualizer");
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<Uint8List?> screenshot() async {
    final int? id = _playerId;
    if (id == null) return null;
    return UMediaChannel.call<Uint8List>(id, "screenshot");
  }

  Future<void> setNotification({required UMediaMetadata metadata, bool showSeekBar = true}) async {
    final int? id = _playerId;
    if (id == null) return;
    await UMediaChannel.call<void>(id, "setNotification", <String, Object?>{"metadata": metadata.toMap(), "showSeekBar": showSeekBar});
    _emit(value.copyWith(metadata: metadata));
  }

  Future<void> pauseForInterruption() async {
    if (!value.isPlaying) return;
    _pausedByInterruption = true;
    await pause();
  }

  Future<void> resumeAfterInterruption() async {
    if (!_pausedByInterruption) return;
    _pausedByInterruption = false;
    await play();
  }

  Future<void> applyDuck(bool ducking) async {
    if (ducking) {
      _volumeBeforeDuck = value.volume;
      await setVolume(_volumeBeforeDuck * 0.3);
      return;
    }
    await setVolume(_volumeBeforeDuck);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final int? id = _playerId;
    _playerId = null;
    unawaited(_events?.cancel());
    _events = null;
    UMediaSession.unregister(this);
    if (id != null) unawaited(UMediaChannel.call<void>(id, "dispose"));
    unawaited(_stateController.close());
    activeCues.dispose();
    audioSpectrum.dispose();
    super.dispose();
  }
}

class _SubtitleJob {
  const _SubtitleJob(this.bytes, this.format, this.encoding, this.language, this.label);

  final Uint8List bytes;
  final USubtitleFormat? format;
  final String? encoding;
  final String? language;
  final String? label;
}

USubtitleData _parseSubtitleJob(_SubtitleJob job) => USubtitleParser.parseBytes(job.bytes, format: job.format, encoding: job.encoding, language: job.language, label: job.label);

class UDecodedText {
  const UDecodedText(this.text, this.encoding);

  final String text;
  final String encoding;
}

abstract final class UTextDecoder {
  static const List<String> supported = <String>["utf-8", "utf-16le", "utf-16be", "windows-1256", "windows-1252"];

  static UDecodedText decode(Uint8List bytes, {String? forced}) {
    if (bytes.isEmpty) return const UDecodedText("", "utf-8");
    if (forced != null) return UDecodedText(_decodeAs(bytes, forced.toLowerCase(), _bomLength(bytes)), forced.toLowerCase());

    final int bom = _bomLength(bytes);
    if (bom > 0) {
      final String name = _bomEncoding(bytes);
      return UDecodedText(_decodeAs(bytes, name, bom), name);
    }
    if (_isValidUtf8(bytes)) return UDecodedText(utf8.decode(bytes, allowMalformed: true), "utf-8");
    if (_looksArabic(bytes)) return UDecodedText(Cp1256.decode(bytes), "windows-1256");
    return UDecodedText(latin1.decode(bytes, allowInvalid: true), "windows-1252");
  }

  static int _bomLength(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) return 3;
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) return 2;
    if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) return 2;
    return 0;
  }

  static String _bomEncoding(Uint8List b) {
    if (b[0] == 0xEF) return "utf-8";
    return b[0] == 0xFF ? "utf-16le" : "utf-16be";
  }

  static String _decodeAs(Uint8List bytes, String encoding, int skip) {
    final Uint8List body = skip == 0 ? bytes : Uint8List.sublistView(bytes, skip);
    switch (encoding) {
      case "utf-16le":
        return _decodeUtf16(body, true);
      case "utf-16be":
        return _decodeUtf16(body, false);
      case "windows-1256":
      case "cp1256":
        return Cp1256.decode(body);
      case "windows-1252":
      case "latin1":
      case "iso-8859-1":
        return latin1.decode(body, allowInvalid: true);
      default:
        return utf8.decode(body, allowMalformed: true);
    }
  }

  static String _decodeUtf16(Uint8List bytes, bool little) {
    final int count = bytes.length ~/ 2;
    final List<int> units = List<int>.filled(count, 0);
    for (int i = 0; i < count; i++) {
      final int a = bytes[i * 2];
      final int b = bytes[i * 2 + 1];
      units[i] = little ? (b << 8) | a : (a << 8) | b;
    }
    return String.fromCharCodes(units);
  }

  static bool _isValidUtf8(Uint8List b) {
    int i = 0;
    final int limit = b.length < 65536 ? b.length : 65536;
    while (i < limit) {
      final int c = b[i];
      if (c < 0x80) {
        i++;
        continue;
      }
      int extra;
      if (c >= 0xC2 && c <= 0xDF) {
        extra = 1;
      } else if (c >= 0xE0 && c <= 0xEF) {
        extra = 2;
      } else if (c >= 0xF0 && c <= 0xF4) {
        extra = 3;
      } else {
        return false;
      }
      if (i + extra >= limit) return true;
      for (int k = 1; k <= extra; k++) {
        if ((b[i + k] & 0xC0) != 0x80) return false;
      }
      i += extra + 1;
    }
    return true;
  }

  static bool _looksArabic(Uint8List b) {
    int high = 0;
    int arabic = 0;
    final int limit = b.length < 65536 ? b.length : 65536;
    for (int i = 0; i < limit; i++) {
      final int c = b[i];
      if (c < 0x80) continue;
      high++;
      if ((c >= 0xC1 && c <= 0xDA) || (c >= 0xDE && c <= 0xF3) || c == 0x81 || c == 0x8D || c == 0x8E || c == 0x90 || c == 0x98) arabic++;
    }
    return high > 0 && arabic / high > 0.6;
  }
}

abstract final class UBidi {
  static bool isRtl(String text) {
    for (int i = 0; i < text.length; i++) {
      final int c = text.codeUnitAt(i);
      if ((c >= 0x0590 && c <= 0x08FF) || (c >= 0xFB1D && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF)) return true;
      if (c >= 0x0041 && c <= 0x024F) return false;
    }
    return false;
  }

  static TextDirection directionOf(String text) => isRtl(text) ? TextDirection.rtl : TextDirection.ltr;

  static String normalizePersian(String value) => value
      .replaceAll("\u064A", "\u06CC")
      .replaceAll("\u0649", "\u06CC")
      .replaceAll("\u0643", "\u06A9")
      .replaceAll("\u0629", "\u0647")
      .replaceAll(RegExp("[\u064B-\u0652\u0670]"), "")
      .replaceAll("\u200C", " ")
      .replaceAll(RegExp(r"\s+"), " ")
      .trim();
}

class USubtitleSpan {
  const USubtitleSpan(this.text, {this.bold = false, this.italic = false, this.underline = false, this.strikethrough = false, this.color, this.fontScale});

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final Color? color;
  final double? fontScale;

  bool get isPlain => !bold && !italic && !underline && !strikethrough && color == null && fontScale == null;
}

class USubtitleStyle {
  const USubtitleStyle({
    required this.name,
    this.fontName,
    this.fontSize,
    this.primaryColor,
    this.outlineColor,
    this.backColor,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.alignment = 2,
    this.marginLeft = 0,
    this.marginRight = 0,
    this.marginVertical = 0,
    this.outline = 0,
    this.shadow = 0,
  });

  final String name;
  final String? fontName;
  final double? fontSize;
  final Color? primaryColor;
  final Color? outlineColor;
  final Color? backColor;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final int alignment;
  final int marginLeft;
  final int marginRight;
  final int marginVertical;
  final double outline;
  final double shadow;
}

class USubtitleCue {
  const USubtitleCue({required this.start, required this.end, required this.spans, required this.text, this.alignment = 2, this.position, this.layer = 0, this.styleName});

  final Duration start;
  final Duration end;
  final List<USubtitleSpan> spans;
  final String text;
  final int alignment;
  final Offset? position;
  final int layer;
  final String? styleName;

  bool get isRtl => UBidi.isRtl(text);

  bool contains(Duration time) => time >= start && time < end;
}

class USubtitleData {
  const USubtitleData({required this.format, required this.cues, this.styles = const <String, USubtitleStyle>{}, this.language, this.label, this.playResX = 0, this.playResY = 0, this.encoding = "utf-8"});

  final USubtitleFormat format;
  final List<USubtitleCue> cues;
  final Map<String, USubtitleStyle> styles;
  final String? language;
  final String? label;
  final int playResX;
  final int playResY;
  final String encoding;

  static const USubtitleData empty = USubtitleData(format: USubtitleFormat.srt, cues: <USubtitleCue>[]);

  bool get isEmpty => cues.isEmpty;

  Duration get lastEnd => cues.isEmpty ? Duration.zero : cues.last.end;

  List<USubtitleCue> activeAt(Duration time, {Duration delay = Duration.zero, double scale = 1}) {
    final Duration target = _adjust(time, delay, scale);
    final int index = _floorIndex(target);
    if (index < 0) return const <USubtitleCue>[];
    final List<USubtitleCue> result = <USubtitleCue>[];
    for (int i = index; i >= 0 && i > index - 12; i--) {
      final USubtitleCue cue = cues[i];
      if (cue.contains(target)) result.add(cue);
    }
    if (result.length > 1) result.sort((USubtitleCue a, USubtitleCue b) => a.layer.compareTo(b.layer));
    return result;
  }

  Duration _adjust(Duration time, Duration delay, double scale) {
    final int ms = ((time.inMilliseconds / (scale == 0 ? 1 : scale)) - delay.inMilliseconds).round();
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  int _floorIndex(Duration target) {
    int low = 0;
    int high = cues.length - 1;
    int found = -1;
    while (low <= high) {
      final int mid = (low + high) >> 1;
      if (cues[mid].start <= target) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }
}

abstract final class USubtitleParser {
  static USubtitleData parseBytes(Uint8List bytes, {USubtitleFormat? format, String? encoding, String? language, String? label, double fps = 23.976}) {
    final UDecodedText decoded = UTextDecoder.decode(bytes, forced: encoding);
    final USubtitleData data = parse(decoded.text, format: format, language: language, label: label, fps: fps);
    return USubtitleData(
      format: data.format,
      cues: data.cues,
      styles: data.styles,
      language: data.language,
      label: data.label,
      playResX: data.playResX,
      playResY: data.playResY,
      encoding: decoded.encoding,
    );
  }

  static USubtitleData parse(String content, {USubtitleFormat? format, String? language, String? label, double fps = 23.976}) {
    final String normalized = content.replaceAll("\r\n", "\n").replaceAll("\r", "\n");
    final USubtitleFormat resolved = format ?? detectFormat(normalized);
    switch (resolved) {
      case USubtitleFormat.vtt:
        return _parseVtt(normalized, language, label);
      case USubtitleFormat.ass:
      case USubtitleFormat.ssa:
        return _parseAss(normalized, language, label);
      case USubtitleFormat.lrc:
        return _parseLrc(normalized, language, label);
      case USubtitleFormat.sub:
        return _parseMicroDvd(normalized, language, label, fps);
      case USubtitleFormat.srt:
      case USubtitleFormat.ttml:
      case USubtitleFormat.pgs:
      case USubtitleFormat.cea608:
      case USubtitleFormat.cea708:
        return _parseSrt(normalized, language, label);
    }
  }

  static USubtitleFormat detectFormat(String content) {
    final String head = content.length > 4096 ? content.substring(0, 4096) : content;
    if (head.startsWith("WEBVTT")) return USubtitleFormat.vtt;
    if (head.contains("[Script Info]") || head.contains("[V4+ Styles]") || head.contains("[V4 Styles]")) return USubtitleFormat.ass;
    if (RegExp(r"^\{\d+\}\{\d+\}", multiLine: true).hasMatch(head)) return USubtitleFormat.sub;
    if (RegExp(r"^\[\d{1,3}:\d{2}([.:]\d{1,3})?\]", multiLine: true).hasMatch(head)) return USubtitleFormat.lrc;
    return USubtitleFormat.srt;
  }

  static Duration _srtTime(String value) {
    final RegExpMatch? m = RegExp(r"(\d{1,3}):(\d{1,2}):(\d{1,2})[,.](\d{1,3})").firstMatch(value);
    if (m == null) return Duration.zero;
    return Duration(
      hours: int.parse(m.group(1)!),
      minutes: int.parse(m.group(2)!),
      seconds: int.parse(m.group(3)!),
      milliseconds: int.parse(m.group(4)!.padRight(3, "0")),
    );
  }

  static Duration _vttTime(String value) {
    final RegExpMatch? full = RegExp(r"(\d{1,3}):(\d{2}):(\d{2})[.,](\d{1,3})").firstMatch(value);
    if (full != null) {
      return Duration(
        hours: int.parse(full.group(1)!),
        minutes: int.parse(full.group(2)!),
        seconds: int.parse(full.group(3)!),
        milliseconds: int.parse(full.group(4)!.padRight(3, "0")),
      );
    }
    final RegExpMatch? short = RegExp(r"(\d{1,3}):(\d{2})[.,](\d{1,3})").firstMatch(value);
    if (short == null) return Duration.zero;
    return Duration(minutes: int.parse(short.group(1)!), seconds: int.parse(short.group(2)!), milliseconds: int.parse(short.group(3)!.padRight(3, "0")));
  }

  static Duration _assTime(String value) {
    final RegExpMatch? m = RegExp(r"(\d{1,2}):(\d{2}):(\d{2})[.,](\d{1,2})").firstMatch(value);
    if (m == null) return Duration.zero;
    return Duration(
      hours: int.parse(m.group(1)!),
      minutes: int.parse(m.group(2)!),
      seconds: int.parse(m.group(3)!),
      milliseconds: int.parse(m.group(4)!.padRight(2, "0")) * 10,
    );
  }

  static USubtitleData _parseSrt(String content, String? language, String? label) {
    final List<USubtitleCue> cues = <USubtitleCue>[];
    final List<String> blocks = content.split(RegExp("\n{2,}"));
    for (final String block in blocks) {
      final List<String> lines = block.split("\n").where((String l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      int cursor = 0;
      if (!lines[cursor].contains("-->")) cursor++;
      if (cursor >= lines.length || !lines[cursor].contains("-->")) continue;
      final List<String> parts = lines[cursor].split("-->");
      if (parts.length < 2) continue;
      final Duration start = _srtTime(parts[0]);
      final Duration end = _srtTime(parts[1]);
      final String body = lines.sublist(cursor + 1).join("\n");
      if (body.trim().isEmpty) continue;
      cues.add(_cueFromMarkup(body, start, end));
    }
    cues.sort((USubtitleCue a, USubtitleCue b) => a.start.compareTo(b.start));
    return USubtitleData(format: USubtitleFormat.srt, cues: cues, language: language, label: label);
  }

  static USubtitleData _parseVtt(String content, String? language, String? label) {
    final List<USubtitleCue> cues = <USubtitleCue>[];
    final List<String> blocks = content.split(RegExp("\n{2,}"));
    for (final String block in blocks) {
      if (block.startsWith("WEBVTT") || block.startsWith("NOTE") || block.startsWith("STYLE") || block.startsWith("REGION")) continue;
      final List<String> lines = block.split("\n").where((String l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      int cursor = 0;
      if (!lines[cursor].contains("-->")) cursor++;
      if (cursor >= lines.length || !lines[cursor].contains("-->")) continue;
      final String timeLine = lines[cursor];
      final List<String> parts = timeLine.split("-->");
      final Duration start = _vttTime(parts[0]);
      final Duration end = _vttTime(parts[1]);
      final int alignment = _vttAlignment(parts.length > 1 ? parts[1] : "");
      final String body = lines.sublist(cursor + 1).join("\n");
      if (body.trim().isEmpty) continue;
      final USubtitleCue base = _cueFromMarkup(body, start, end);
      cues.add(USubtitleCue(start: base.start, end: base.end, spans: base.spans, text: base.text, alignment: alignment));
    }
    cues.sort((USubtitleCue a, USubtitleCue b) => a.start.compareTo(b.start));
    return USubtitleData(format: USubtitleFormat.vtt, cues: cues, language: language, label: label);
  }

  static int _vttAlignment(String settings) {
    if (settings.contains("line:0") || settings.contains("line:5%") || settings.contains("line:10%")) return 8;
    if (settings.contains("align:left") || settings.contains("align:start")) return 1;
    if (settings.contains("align:right") || settings.contains("align:end")) return 3;
    return 2;
  }

  static USubtitleData _parseLrc(String content, String? language, String? label) {
    final List<USubtitleCue> cues = <USubtitleCue>[];
    final RegExp stamp = RegExp(r"\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]");
    int offsetMs = 0;
    final List<_LrcLine> collected = <_LrcLine>[];
    for (final String line in content.split("\n")) {
      final RegExpMatch? offsetMatch = RegExp(r"^\[offset:\s*([+-]?\d+)\]").firstMatch(line.trim());
      if (offsetMatch != null) {
        offsetMs = int.tryParse(offsetMatch.group(1)!) ?? 0;
        continue;
      }
      final Iterable<RegExpMatch> stamps = stamp.allMatches(line);
      if (stamps.isEmpty) continue;
      final String text = line.substring(stamps.last.end).trim();
      for (final RegExpMatch m in stamps) {
        final String fraction = m.group(3) ?? "0";
        final int ms = fraction.length == 1 ? int.parse(fraction) * 100 : (fraction.length == 2 ? int.parse(fraction) * 10 : int.parse(fraction.padRight(3, "0")));
        collected.add(_LrcLine(Duration(minutes: int.parse(m.group(1)!), seconds: int.parse(m.group(2)!), milliseconds: ms + offsetMs), text));
      }
    }
    collected.sort((_LrcLine a, _LrcLine b) => a.time.compareTo(b.time));
    for (int i = 0; i < collected.length; i++) {
      final _LrcLine line = collected[i];
      if (line.text.isEmpty) continue;
      final Duration end = i + 1 < collected.length ? collected[i + 1].time : line.time + const Duration(seconds: 5);
      cues.add(USubtitleCue(start: line.time, end: end, spans: <USubtitleSpan>[USubtitleSpan(line.text)], text: line.text));
    }
    return USubtitleData(format: USubtitleFormat.lrc, cues: cues, language: language, label: label);
  }

  static USubtitleData _parseMicroDvd(String content, String? language, String? label, double fps) {
    final List<USubtitleCue> cues = <USubtitleCue>[];
    final RegExp pattern = RegExp(r"^\{(\d+)\}\{(\d+)\}(.*)$");
    final double rate = fps <= 0 ? 23.976 : fps;
    for (final String line in content.split("\n")) {
      final RegExpMatch? m = pattern.firstMatch(line.trim());
      if (m == null) continue;
      final String body = m.group(3)!.replaceAll("|", "\n").replaceAll(RegExp(r"\{[^}]*\}"), "").trim();
      if (body.isEmpty) continue;
      final Duration start = Duration(milliseconds: (int.parse(m.group(1)!) / rate * 1000).round());
      final Duration end = Duration(milliseconds: (int.parse(m.group(2)!) / rate * 1000).round());
      cues.add(USubtitleCue(start: start, end: end, spans: <USubtitleSpan>[USubtitleSpan(body)], text: body));
    }
    return USubtitleData(format: USubtitleFormat.sub, cues: cues, language: language, label: label);
  }

  static USubtitleCue _cueFromMarkup(String body, Duration start, Duration end) {
    final List<USubtitleSpan> spans = _parseMarkup(body);
    final String plain = spans.map((USubtitleSpan s) => s.text).join();
    return USubtitleCue(start: start, end: end, spans: spans, text: plain);
  }

  static List<USubtitleSpan> _parseMarkup(String input) {
    final List<USubtitleSpan> spans = <USubtitleSpan>[];
    final StringBuffer buffer = StringBuffer();
    bool bold = false;
    bool italic = false;
    bool underline = false;
    Color? color;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(USubtitleSpan(buffer.toString(), bold: bold, italic: italic, underline: underline, color: color));
      buffer.clear();
    }

    int i = 0;
    while (i < input.length) {
      if (input[i] == "<") {
        final int close = input.indexOf(">", i);
        if (close < 0) {
          buffer.write(input.substring(i));
          break;
        }
        final String tag = input.substring(i + 1, close).trim().toLowerCase();
        flush();
        if (tag == "b" || tag.startsWith("b ")) {
          bold = true;
        } else if (tag == "/b") {
          bold = false;
        } else if (tag == "i" || tag.startsWith("i ")) {
          italic = true;
        } else if (tag == "/i") {
          italic = false;
        } else if (tag == "u" || tag.startsWith("u ")) {
          underline = true;
        } else if (tag == "/u") {
          underline = false;
        } else if (tag.startsWith("font")) {
          color = _htmlColor(tag);
        } else if (tag == "/font") {
          color = null;
        }
        i = close + 1;
        continue;
      }
      buffer.write(input[i]);
      i++;
    }
    flush();
    return spans.isEmpty ? <USubtitleSpan>[USubtitleSpan(input)] : spans;
  }

  static Color? _htmlColor(String tag) {
    final RegExpMatch? m = RegExp("color\\s*=\\s*[\"']?#?([0-9a-fA-F]{6})").firstMatch(tag);
    if (m == null) return null;
    return Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
  }

  static USubtitleData _parseAss(String content, String? language, String? label) {
    final Map<String, USubtitleStyle> styles = <String, USubtitleStyle>{};
    final List<USubtitleCue> cues = <USubtitleCue>[];
    List<String> styleFormat = <String>[];
    List<String> eventFormat = <String>[];
    String section = "";
    int playResX = 0;
    int playResY = 0;

    for (final String raw in content.split("\n")) {
      final String line = raw.trim();
      if (line.isEmpty || line.startsWith(";") || line.startsWith("!:")) continue;
      if (line.startsWith("[") && line.endsWith("]")) {
        section = line.toLowerCase();
        continue;
      }
      final int colon = line.indexOf(":");
      if (colon < 0) continue;
      final String key = line.substring(0, colon).trim().toLowerCase();
      final String value = line.substring(colon + 1).trim();

      if (section.contains("script info")) {
        if (key == "playresx") playResX = int.tryParse(value) ?? 0;
        if (key == "playresy") playResY = int.tryParse(value) ?? 0;
        continue;
      }
      if (section.contains("styles")) {
        if (key == "format") {
          styleFormat = value.split(",").map((String s) => s.trim().toLowerCase()).toList();
        } else if (key == "style") {
          final USubtitleStyle? style = _assStyle(styleFormat, value);
          if (style != null) styles[style.name] = style;
        }
        continue;
      }
      if (section.contains("events")) {
        if (key == "format") {
          eventFormat = value.split(",").map((String s) => s.trim().toLowerCase()).toList();
        } else if (key == "dialogue") {
          final USubtitleCue? cue = _assDialogue(eventFormat, value, styles);
          if (cue != null) cues.add(cue);
        }
      }
    }
    cues.sort((USubtitleCue a, USubtitleCue b) => a.start.compareTo(b.start));
    return USubtitleData(format: USubtitleFormat.ass, cues: cues, styles: styles, language: language, label: label, playResX: playResX, playResY: playResY);
  }

  static USubtitleStyle? _assStyle(List<String> format, String value) {
    if (format.isEmpty) return null;
    final List<String> parts = value.split(",");
    String field(String name) {
      final int index = format.indexOf(name);
      return index >= 0 && index < parts.length ? parts[index].trim() : "";
    }

    final String name = field("name");
    if (name.isEmpty) return null;
    return USubtitleStyle(
      name: name,
      fontName: field("fontname").isEmpty ? null : field("fontname"),
      fontSize: double.tryParse(field("fontsize")),
      primaryColor: _assColor(field("primarycolour")),
      outlineColor: _assColor(field("outlinecolour")),
      backColor: _assColor(field("backcolour")),
      bold: field("bold") == "-1" || field("bold") == "1",
      italic: field("italic") == "-1" || field("italic") == "1",
      underline: field("underline") == "-1" || field("underline") == "1",
      strikethrough: field("strikeout") == "-1" || field("strikeout") == "1",
      alignment: int.tryParse(field("alignment")) ?? 2,
      marginLeft: int.tryParse(field("marginl")) ?? 0,
      marginRight: int.tryParse(field("marginr")) ?? 0,
      marginVertical: int.tryParse(field("marginv")) ?? 0,
      outline: double.tryParse(field("outline")) ?? 0,
      shadow: double.tryParse(field("shadow")) ?? 0,
    );
  }

  static Color? _assColor(String value) {
    final RegExpMatch? m = RegExp("&H([0-9a-fA-F]{1,8})").firstMatch(value);
    if (m == null) return null;
    final int raw = int.parse(m.group(1)!.padLeft(8, "0"), radix: 16);
    final int alpha = 255 - ((raw >> 24) & 0xFF);
    final int blue = (raw >> 16) & 0xFF;
    final int green = (raw >> 8) & 0xFF;
    final int red = raw & 0xFF;
    return Color.fromARGB(alpha, red, green, blue);
  }

  static USubtitleCue? _assDialogue(List<String> format, String value, Map<String, USubtitleStyle> styles) {
    if (format.isEmpty) return null;
    final int textIndex = format.indexOf("text");
    if (textIndex < 0) return null;
    final List<String> parts = value.split(",");
    if (parts.length <= textIndex) return null;
    final String text = parts.sublist(textIndex).join(",");

    String field(String name) {
      final int index = format.indexOf(name);
      return index >= 0 && index < parts.length ? parts[index].trim() : "";
    }

    final String styleName = field("style");
    final USubtitleStyle? style = styles[styleName];
    final _AssText parsed = _parseAssText(text, style);
    if (parsed.plain.trim().isEmpty) return null;

    return USubtitleCue(
      start: _assTime(field("start")),
      end: _assTime(field("end")),
      spans: parsed.spans,
      text: parsed.plain,
      alignment: parsed.alignment ?? style?.alignment ?? 2,
      position: parsed.position,
      layer: int.tryParse(field("layer")) ?? 0,
      styleName: styleName.isEmpty ? null : styleName,
    );
  }

  static _AssText _parseAssText(String input, USubtitleStyle? style) {
    final List<USubtitleSpan> spans = <USubtitleSpan>[];
    final StringBuffer buffer = StringBuffer();
    bool bold = style?.bold ?? false;
    bool italic = style?.italic ?? false;
    bool underline = style?.underline ?? false;
    bool strike = style?.strikethrough ?? false;
    Color? color = style?.primaryColor;
    int? alignment;
    Offset? position;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(USubtitleSpan(buffer.toString(), bold: bold, italic: italic, underline: underline, strikethrough: strike, color: color));
      buffer.clear();
    }

    int i = 0;
    while (i < input.length) {
      final String ch = input[i];
      if (ch == "{") {
        final int close = input.indexOf("}", i);
        if (close < 0) {
          buffer.write(input.substring(i));
          break;
        }
        flush();
        final String block = input.substring(i + 1, close);
        for (final RegExpMatch tag in RegExp(r"\\([a-zA-Z]+)([^\\]*)").allMatches(block)) {
          final String name = tag.group(1)!.toLowerCase();
          final String arg = tag.group(2)!.trim();
          switch (name) {
            case "b":
              bold = arg != "0";
              break;
            case "i":
              italic = arg != "0";
              break;
            case "u":
              underline = arg != "0";
              break;
            case "s":
              strike = arg != "0";
              break;
            case "an":
              alignment = int.tryParse(arg);
              break;
            case "a":
              alignment = _legacyAlignment(int.tryParse(arg) ?? 2);
              break;
            case "c":
            case "1c":
              color = _assColor(arg) ?? color;
              break;
            case "pos":
              final RegExpMatch? p = RegExp(r"\(\s*([\d.-]+)\s*,\s*([\d.-]+)\s*\)").firstMatch(arg);
              if (p != null) position = Offset(double.parse(p.group(1)!), double.parse(p.group(2)!));
              break;
            case "r":
              bold = style?.bold ?? false;
              italic = style?.italic ?? false;
              underline = style?.underline ?? false;
              strike = style?.strikethrough ?? false;
              color = style?.primaryColor;
              break;
          }
        }
        i = close + 1;
        continue;
      }
      if (ch == "\\" && i + 1 < input.length) {
        final String next = input[i + 1];
        if (next == "N" || next == "n") {
          buffer.write("\n");
          i += 2;
          continue;
        }
        if (next == "h") {
          buffer.write("\u00A0");
          i += 2;
          continue;
        }
      }
      buffer.write(ch);
      i++;
    }
    flush();
    final String plain = spans.map((USubtitleSpan s) => s.text).join();
    return _AssText(spans, plain, alignment, position);
  }

  static int _legacyAlignment(int value) {
    switch (value) {
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 5:
        return 7;
      case 6:
        return 8;
      case 7:
        return 9;
      case 9:
        return 4;
      case 10:
        return 5;
      case 11:
        return 6;
      default:
        return 2;
    }
  }
}

class _LrcLine {
  const _LrcLine(this.time, this.text);

  final Duration time;
  final String text;
}

class _AssText {
  const _AssText(this.spans, this.plain, this.alignment, this.position);

  final List<USubtitleSpan> spans;
  final String plain;
  final int? alignment;
  final Offset? position;
}

const int _kMaxTagBytes = 8 * 1024 * 1024;

class _Window {
  _Window(this._file, this.length);

  final RandomAccessFile _file;
  final int length;

  Future<Uint8List> read(int offset, int count) async {
    if (offset < 0 || offset >= length || count <= 0) return Uint8List(0);
    final int available = length - offset;
    final int capped = count > available ? available : count;
    final int safe = capped > _kMaxTagBytes ? _kMaxTagBytes : capped;
    await _file.setPosition(offset);
    return _file.read(safe);
  }
}

abstract final class UTagParser {
  static Future<UMediaMetadata> readFile(String path) async {
    RandomAccessFile? handle;
    try {
      handle = await File(path).open();
      final int length = await handle.length();
      if (length < 16) return const UMediaMetadata();
      final _Window window = _Window(handle, length);
      final Uint8List head = await window.read(0, 16);
      if (head.length < 12) return const UMediaMetadata();

      if (head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) {
        final UMediaMetadata id3 = await _readId3v2(window, path);
        final UMediaMetadata v1 = await _readId3v1(window);
        return v1.merge(id3);
      }
      if (head[0] == 0x66 && head[1] == 0x4C && head[2] == 0x61 && head[3] == 0x43) return await _readFlac(window, path);
      if (head[0] == 0x4F && head[1] == 0x67 && head[2] == 0x67 && head[3] == 0x53) return await _readOgg(window);
      if (head[4] == 0x66 && head[5] == 0x74 && head[6] == 0x79 && head[7] == 0x70) return await _readMp4(window, path);
      if (head[0] == 0x52 && head[1] == 0x49 && head[2] == 0x46 && head[3] == 0x46) return await _readWav(window);
      return await _readId3v1(window);
    } on FileSystemException {
      return const UMediaMetadata();
    } on UMediaParseException {
      return const UMediaMetadata();
    } finally {
      await handle?.close();
    }
  }

  static String _clean(String value) => value.replaceAll(" ", "").trim();

  static String _decodeText(Uint8List raw, int encodingByte) {
    if (raw.isEmpty) return "";
    if (encodingByte == 3) return _clean(utf8.decode(raw, allowMalformed: true));
    return _clean(UTextDecoder.decode(raw).text);
  }

  static int? _firstInt(String value) {
    final RegExpMatch? m = RegExp(r"\d+").firstMatch(value);
    return m == null ? null : int.tryParse(m.group(0)!);
  }

  static String? _orNull(String? value) => value == null || value.isEmpty ? null : value;

  static Future<UMediaMetadata> _readId3v1(_Window window) async {
    if (window.length < 128) return const UMediaMetadata();
    final Uint8List tail = await window.read(window.length - 128, 128);
    if (tail.length < 128 || tail[0] != 0x54 || tail[1] != 0x41 || tail[2] != 0x47) return const UMediaMetadata();
    final UByteReader reader = UByteReader(tail, start: 3);
    String field(int size) => _clean(UTextDecoder.decode(Uint8List.fromList(reader.take(size).where((int b) => b != 0).toList())).text);
    return UMediaMetadata(
      title: _orNull(field(30)),
      artist: _orNull(field(30)),
      album: _orNull(field(30)),
      year: int.tryParse(field(4)),
    );
  }

  static String _readTextFrame(UByteReader frame) {
    if (frame.remaining < 1) return "";
    final int encoding = frame.u8();
    return _decodeText(frame.take(frame.remaining), encoding);
  }

  static String _readCommentFrame(UByteReader frame) {
    if (frame.remaining < 5) return "";
    final int encoding = frame.u8();
    frame.skip(3);
    final String decoded = _decodeText(frame.take(frame.remaining), encoding);
    final int separator = decoded.indexOf(" ");
    return separator >= 0 ? decoded.substring(separator + 1).trim() : decoded;
  }

  static String? _cleanGenre(String value) {
    if (value.isEmpty) return null;
    final RegExpMatch? m = RegExp(r"^\((\d+)\)$").firstMatch(value.trim());
    if (m == null) return value;
    final int index = int.parse(m.group(1)!);
    return index < _id3Genres.length ? _id3Genres[index] : value;
  }

  static UArtworkRef? _readPictureFrame(UByteReader frame, int absoluteOffset, String path, int major) {
    if (frame.remaining < 4) return null;
    final int startPosition = frame.position;
    frame.u8();
    String mime;
    if (major == 2) {
      mime = "image/${frame.ascii(3).toLowerCase()}";
    } else {
      final int terminator = frame.indexOfByte(0);
      if (terminator < 0) return null;
      mime = frame.ascii(terminator - frame.position);
      frame.skip(1);
    }
    if (frame.remaining < 2) return null;
    frame.u8();
    final int descEnd = frame.indexOfByte(0);
    if (descEnd < 0) return null;
    frame.skip(descEnd - frame.position + 1);
    final int dataLength = frame.remaining;
    if (dataLength <= 0) return null;
    return UArtworkRef.embedded(
      filePath: path,
      offset: absoluteOffset + (frame.position - startPosition),
      length: dataLength,
      mimeType: mime.isEmpty ? "image/jpeg" : mime,
    );
  }

  static Future<UMediaMetadata> _readId3v2(_Window window, String path) async {
    final Uint8List header = await window.read(0, 10);
    if (header.length < 10) return const UMediaMetadata();
    final int major = header[3];
    final int tagSize = UByteReader(header, start: 6).syncSafe32();
    if (tagSize <= 0) return const UMediaMetadata();
    final Uint8List body = await window.read(10, tagSize);
    final UByteReader reader = UByteReader(body);

    String? title;
    String? artist;
    String? album;
    String? albumArtist;
    String? genre;
    String? composer;
    String? comment;
    String? lyrics;
    int? year;
    int? trackNumber;
    int? trackCount;
    int? discNumber;
    UArtworkRef? artwork;

    final int idSize = major == 2 ? 3 : 4;
    final int headerSize = major == 2 ? 6 : 10;
    while (reader.remaining > headerSize) {
      final String frameId = reader.ascii(idSize);
      if (frameId.isEmpty) break;
      final int frameSize = major == 2 ? reader.u24be() : (major >= 4 ? reader.syncSafe32() : reader.u32be());
      if (major != 2) reader.skip(2);
      if (frameSize <= 0 || frameSize > reader.remaining) break;
      final int absoluteOffset = 10 + reader.position;
      final UByteReader frame = reader.window(frameSize);

      switch (frameId) {
        case "TIT2":
        case "TT2":
          title = _readTextFrame(frame);
          break;
        case "TPE1":
        case "TP1":
          artist = _readTextFrame(frame);
          break;
        case "TALB":
        case "TAL":
          album = _readTextFrame(frame);
          break;
        case "TPE2":
        case "TP2":
          albumArtist = _readTextFrame(frame);
          break;
        case "TCON":
        case "TCO":
          genre = _cleanGenre(_readTextFrame(frame));
          break;
        case "TCOM":
        case "TCM":
          composer = _readTextFrame(frame);
          break;
        case "TYER":
        case "TDRC":
        case "TYE":
          year = _firstInt(_readTextFrame(frame));
          break;
        case "TRCK":
        case "TRK":
          final List<String> parts = _readTextFrame(frame).split("/");
          trackNumber = _firstInt(parts.first);
          if (parts.length > 1) trackCount = _firstInt(parts[1]);
          break;
        case "TPOS":
        case "TPA":
          discNumber = _firstInt(_readTextFrame(frame));
          break;
        case "COMM":
        case "COM":
          comment = _readCommentFrame(frame);
          break;
        case "USLT":
        case "ULT":
          lyrics = _readCommentFrame(frame);
          break;
        case "APIC":
        case "PIC":
          artwork = _readPictureFrame(frame, absoluteOffset, path, major);
          break;
      }
    }

    return UMediaMetadata(
      title: _orNull(title),
      artist: _orNull(artist),
      album: _orNull(album),
      albumArtist: _orNull(albumArtist),
      composer: _orNull(composer),
      genre: genre,
      year: year,
      trackNumber: trackNumber,
      trackCount: trackCount,
      discNumber: discNumber,
      artwork: artwork,
      lyrics: _orNull(lyrics),
      comment: _orNull(comment),
    );
  }

  static Future<UMediaMetadata> _readFlac(_Window window, String path) async {
    int offset = 4;
    UMediaMetadata result = const UMediaMetadata();
    Duration? duration;
    UArtworkRef? artwork;
    for (int guard = 0; guard < 64; guard++) {
      final Uint8List header = await window.read(offset, 4);
      if (header.length < 4) break;
      final bool isLast = (header[0] & 0x80) != 0;
      final int type = header[0] & 0x7F;
      final int size = (header[1] << 16) | (header[2] << 8) | header[3];
      final int dataOffset = offset + 4;
      if (size <= 0 || size > _kMaxTagBytes) break;

      if (type == 0) {
        final Uint8List info = await window.read(dataOffset, size < 34 ? size : 34);
        if (info.length >= 18) {
          final int sampleRate = (info[10] << 12) | (info[11] << 4) | (info[12] >> 4);
          final int totalSamples = ((info[13] & 0x0F) << 32) | (info[14] << 24) | (info[15] << 16) | (info[16] << 8) | info[17];
          if (sampleRate > 0 && totalSamples > 0) duration = Duration(milliseconds: (totalSamples / sampleRate * 1000).round());
        }
      } else if (type == 4) {
        result = result.merge(_vorbisComment(await window.read(dataOffset, size)));
      } else if (type == 6) {
        artwork = _flacPicture(await window.read(dataOffset, size < 1024 ? size : 1024), dataOffset, path);
      }
      if (isLast) break;
      offset = dataOffset + size;
    }
    return result.merge(UMediaMetadata(duration: duration, artwork: artwork));
  }

  static UArtworkRef? _flacPicture(Uint8List block, int blockOffset, String path) {
    try {
      final UByteReader reader = UByteReader(block);
      reader.u32be();
      final int mimeLength = reader.u32be();
      final String mime = reader.ascii(reader.guardedLength(mimeLength, cap: 256));
      final int descLength = reader.u32be();
      reader.skip(reader.guardedLength(descLength, cap: 4096));
      reader.skip(16);
      final int dataLength = reader.u32be();
      if (dataLength <= 0) return null;
      return UArtworkRef.embedded(filePath: path, offset: blockOffset + reader.position, length: dataLength, mimeType: mime.isEmpty ? "image/jpeg" : mime);
    } on UMediaParseException {
      return null;
    }
  }

  static UMediaMetadata _vorbisComment(Uint8List block) {
    try {
      final UByteReader reader = UByteReader(block);
      final int vendorLength = reader.u32le();
      reader.skip(reader.guardedLength(vendorLength, cap: 4096));
      final int count = reader.u32le();
      final Map<String, String> fields = <String, String>{};
      final int limit = count > 512 ? 512 : count;
      for (int i = 0; i < limit; i++) {
        if (reader.remaining < 4) break;
        final int length = reader.u32le();
        final Uint8List entry = reader.takeGuarded(length, cap: 65536);
        final String text = utf8.decode(entry, allowMalformed: true);
        final int equals = text.indexOf("=");
        if (equals <= 0) continue;
        fields[text.substring(0, equals).toUpperCase()] = text.substring(equals + 1);
      }
      return UMediaMetadata(
        title: _orNull(fields["TITLE"]),
        artist: _orNull(fields["ARTIST"]),
        album: _orNull(fields["ALBUM"]),
        albumArtist: _orNull(fields["ALBUMARTIST"]),
        composer: _orNull(fields["COMPOSER"]),
        genre: _orNull(fields["GENRE"]),
        year: _firstInt(fields["DATE"] ?? fields["YEAR"] ?? ""),
        trackNumber: _firstInt(fields["TRACKNUMBER"] ?? ""),
        trackCount: _firstInt(fields["TRACKTOTAL"] ?? fields["TOTALTRACKS"] ?? ""),
        discNumber: _firstInt(fields["DISCNUMBER"] ?? ""),
        lyrics: _orNull(fields["LYRICS"] ?? fields["UNSYNCEDLYRICS"]),
        comment: _orNull(fields["COMMENT"]),
      );
    } on UMediaParseException {
      return const UMediaMetadata();
    }
  }

  static Future<UMediaMetadata> _readOgg(_Window window) async {
    final Uint8List head = await window.read(0, 65536);
    final int marker = _indexOfPattern(head, const <int>[0x03, 0x76, 0x6F, 0x72, 0x62, 0x69, 0x73]);
    if (marker >= 0) return _vorbisComment(Uint8List.sublistView(head, marker + 7));
    final int opus = _indexOfPattern(head, const <int>[0x4F, 0x70, 0x75, 0x73, 0x54, 0x61, 0x67, 0x73]);
    if (opus >= 0) return _vorbisComment(Uint8List.sublistView(head, opus + 8));
    return const UMediaMetadata();
  }

  static int _indexOfPattern(Uint8List data, List<int> pattern) {
    final int limit = data.length - pattern.length;
    for (int i = 0; i <= limit; i++) {
      bool matched = true;
      for (int k = 0; k < pattern.length; k++) {
        if (data[i + k] != pattern[k]) {
          matched = false;
          break;
        }
      }
      if (matched) return i;
    }
    return -1;
  }

  static Future<int> _atomSize(_Window window, int offset) async {
    final Uint8List header = await window.read(offset, 8);
    if (header.length < 8) return 0;
    return UByteReader(header).u32be();
  }

  static Future<int?> _findAtom(_Window window, int start, int end, String name) async {
    int cursor = start;
    for (int guard = 0; guard < 256 && cursor + 8 <= end; guard++) {
      final Uint8List header = await window.read(cursor, 8);
      if (header.length < 8) return null;
      final UByteReader reader = UByteReader(header);
      final int size = reader.u32be();
      final String type = reader.ascii(4);
      if (size < 8) return null;
      if (type == name) return cursor;
      cursor += size;
    }
    return null;
  }

  static Future<UMediaMetadata> _readMp4(_Window window, String path) async {
    final int? moov = await _findAtom(window, 0, window.length, "moov");
    if (moov == null) return const UMediaMetadata();
    final int moovSize = await _atomSize(window, moov);
    Duration? duration;

    final int? mvhd = await _findAtom(window, moov + 8, moov + moovSize, "mvhd");
    if (mvhd != null) {
      final Uint8List body = await window.read(mvhd + 8, 24);
      if (body.length >= 20) {
        final UByteReader reader = UByteReader(body);
        final int version = reader.u8();
        reader.skip(3);
        if (version == 0) {
          reader.skip(8);
          final int scale = reader.u32be();
          final int units = reader.u32be();
          if (scale > 0) duration = Duration(milliseconds: (units / scale * 1000).round());
        }
      }
    }

    final int? udta = await _findAtom(window, moov + 8, moov + moovSize, "udta");
    if (udta == null) return UMediaMetadata(duration: duration);
    final int? meta = await _findAtom(window, udta + 8, udta + await _atomSize(window, udta), "meta");
    if (meta == null) return UMediaMetadata(duration: duration);
    final int? ilst = await _findAtom(window, meta + 12, meta + await _atomSize(window, meta), "ilst");
    if (ilst == null) return UMediaMetadata(duration: duration);
    return _parseIlst(window, ilst + 8, ilst + await _atomSize(window, ilst), path, duration);
  }

  static Future<UMediaMetadata> _parseIlst(_Window window, int start, int end, String path, Duration? duration) async {
    String? title;
    String? artist;
    String? album;
    String? albumArtist;
    String? genre;
    String? composer;
    String? lyrics;
    int? year;
    int? trackNumber;
    int? trackCount;
    int? discNumber;
    UArtworkRef? artwork;

    int cursor = start;
    for (int guard = 0; guard < 128 && cursor + 8 <= end; guard++) {
      final Uint8List header = await window.read(cursor, 8);
      if (header.length < 8) break;
      final int size = UByteReader(header).u32be();
      final String key = String.fromCharCodes(Uint8List.sublistView(header, 4, 8));
      if (size < 16) break;

      final int dataOffset = cursor + 16;
      final int dataLength = size - 16;
      if (dataLength <= 0 || dataLength > _kMaxTagBytes) {
        cursor += size;
        continue;
      }

      if (key == "covr") {
        artwork = UArtworkRef.embedded(filePath: path, offset: dataOffset, length: dataLength, mimeType: "image/jpeg");
        cursor += size;
        continue;
      }

      final Uint8List payload = await window.read(dataOffset, dataLength > 8192 ? 8192 : dataLength);
      final String text = _clean(utf8.decode(payload, allowMalformed: true));
      switch (key) {
        case "©nam":
          title = text;
          break;
        case "©ART":
          artist = text;
          break;
        case "©alb":
          album = text;
          break;
        case "aART":
          albumArtist = text;
          break;
        case "©gen":
          genre = text;
          break;
        case "©wrt":
          composer = text;
          break;
        case "©lyr":
          lyrics = text;
          break;
        case "©day":
          year = _firstInt(text);
          break;
        case "trkn":
          if (payload.length >= 6) {
            trackNumber = (payload[2] << 8) | payload[3];
            trackCount = (payload[4] << 8) | payload[5];
          }
          break;
        case "disk":
          if (payload.length >= 4) discNumber = (payload[2] << 8) | payload[3];
          break;
      }
      cursor += size;
    }

    return UMediaMetadata(
      title: _orNull(title),
      artist: _orNull(artist),
      album: _orNull(album),
      albumArtist: _orNull(albumArtist),
      composer: _orNull(composer),
      genre: _orNull(genre),
      year: year,
      trackNumber: trackNumber,
      trackCount: trackCount,
      discNumber: discNumber,
      duration: duration,
      artwork: artwork,
      lyrics: _orNull(lyrics),
    );
  }

  static Future<UMediaMetadata> _readWav(_Window window) async {
    int cursor = 12;
    int byteRate = 0;
    Duration? duration;
    final Map<String, String> info = <String, String>{};

    for (int guard = 0; guard < 64 && cursor + 8 <= window.length; guard++) {
      final Uint8List header = await window.read(cursor, 8);
      if (header.length < 8) break;
      final String id = String.fromCharCodes(Uint8List.sublistView(header, 0, 4));
      final int size = UByteReader(header, start: 4).u32le();
      if (size <= 0) break;

      if (id == "fmt ") {
        final Uint8List body = await window.read(cursor + 8, size < 16 ? size : 16);
        if (body.length >= 16) {
          final UByteReader reader = UByteReader(body, start: 8);
          byteRate = reader.u32le();
        }
      } else if (id == "data") {
        if (byteRate > 0) duration = Duration(milliseconds: (size / byteRate * 1000).round());
      } else if (id == "LIST") {
        info.addAll(_wavInfo(await window.read(cursor + 8, size > 65536 ? 65536 : size)));
      }
      cursor += 8 + size + (size.isOdd ? 1 : 0);
    }

    return UMediaMetadata(
      title: _orNull(info["INAM"]),
      artist: _orNull(info["IART"]),
      album: _orNull(info["IPRD"]),
      genre: _orNull(info["IGNR"]),
      year: _firstInt(info["ICRD"] ?? ""),
      comment: _orNull(info["ICMT"]),
      duration: duration,
    );
  }

  static Map<String, String> _wavInfo(Uint8List block) {
    final Map<String, String> result = <String, String>{};
    if (block.length < 4) return result;
    try {
      final UByteReader reader = UByteReader(block, start: 4);
      while (reader.remaining > 8) {
        final String id = reader.ascii(4);
        final int size = reader.u32le();
        final Uint8List value = reader.takeGuarded(size, cap: 8192);
        result[id] = _clean(UTextDecoder.decode(value).text);
        if (size.isOdd && reader.remaining > 0) reader.skip(1);
      }
    } on UMediaParseException {
      return result;
    }
    return result;
  }

  static const List<String> _id3Genres = <String>[
    "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", "Hip-Hop", "Jazz", "Metal",
    "New Age", "Oldies", "Other", "Pop", "R&B", "Rap", "Reggae", "Rock", "Techno", "Industrial",
    "Alternative", "Ska", "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk",
    "Fusion", "Trance", "Classical", "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise",
    "Alternative Rock", "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic",
    "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta",
    "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret", "New Wave", "Psychedelic", "Rave", "Showtunes",
    "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock",
  ];
}

const int _kMaxDepth = 64;

const int _kMaxNodes = 200000;

class UXmlNode {
  UXmlNode(this.name, this.attributes, this.children, this.text);

  final String name;
  final Map<String, String> attributes;
  final List<UXmlNode> children;
  final String text;

  String? attr(String key) => attributes[key];

  UXmlNode? child(String childName) {
    for (final UXmlNode node in children) {
      if (node.name == childName) return node;
    }
    return null;
  }

  List<UXmlNode> childrenNamed(String childName) => children.where((UXmlNode n) => n.name == childName).toList(growable: false);

  Iterable<UXmlNode> descendants(String childName) sync* {
    for (final UXmlNode node in children) {
      if (node.name == childName) yield node;
      yield* node.descendants(childName);
    }
  }
}

abstract final class UXml {
  static UXmlNode? parse(String source) {
    final _XmlCursor cursor = _XmlCursor(source);
    try {
      return cursor.parseDocument();
    } on UMediaParseException {
      return null;
    }
  }

  static String unescape(String value) {
    if (!value.contains("&")) return value;
    return value
        .replaceAllMapped(RegExp("&#x([0-9a-fA-F]+);"), (Match m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
        .replaceAllMapped(RegExp(r"&#(\d+);"), (Match m) => String.fromCharCode(int.parse(m.group(1)!)))
        .replaceAll("&lt;", "<")
        .replaceAll("&gt;", ">")
        .replaceAll("&quot;", "\"")
        .replaceAll("&apos;", "'")
        .replaceAll("&amp;", "&");
  }
}

class _XmlCursor {
  _XmlCursor(this.source);

  final String source;
  int position = 0;
  int nodeCount = 0;

  UXmlNode? parseDocument() {
    while (position < source.length) {
      _skipWhitespace();
      if (position >= source.length) return null;
      if (!_startsWith("<")) {
        position++;
        continue;
      }
      if (_startsWith("<?") || _startsWith("<!")) {
        _skipDeclaration();
        continue;
      }
      return _parseElement(0);
    }
    return null;
  }

  bool _startsWith(String value) => source.startsWith(value, position);

  void _skipWhitespace() {
    while (position < source.length) {
      final int code = source.codeUnitAt(position);
      if (code == 0x20 || code == 0x09 || code == 0x0A || code == 0x0D) {
        position++;
      } else {
        return;
      }
    }
  }

  void _skipDeclaration() {
    if (_startsWith("<!--")) {
      final int end = source.indexOf("-->", position);
      position = end < 0 ? source.length : end + 3;
      return;
    }
    if (_startsWith("<![CDATA[")) {
      final int end = source.indexOf("]]>", position);
      position = end < 0 ? source.length : end + 3;
      return;
    }
    final int end = source.indexOf(">", position);
    position = end < 0 ? source.length : end + 1;
  }

  UXmlNode _parseElement(int depth) {
    if (depth > _kMaxDepth) throw const UMediaParseException("XML nesting too deep");
    if (++nodeCount > _kMaxNodes) throw const UMediaParseException("XML too large");
    position++;
    final String name = _readName();
    final Map<String, String> attributes = <String, String>{};

    while (position < source.length) {
      _skipWhitespace();
      if (_startsWith("/>")) {
        position += 2;
        return UXmlNode(name, attributes, const <UXmlNode>[], "");
      }
      if (_startsWith(">")) {
        position++;
        break;
      }
      final String key = _readName();
      if (key.isEmpty) {
        position++;
        continue;
      }
      _skipWhitespace();
      if (!_startsWith("=")) {
        attributes[key] = "";
        continue;
      }
      position++;
      _skipWhitespace();
      attributes[key] = _readAttributeValue();
    }

    final List<UXmlNode> children = <UXmlNode>[];
    final StringBuffer text = StringBuffer();

    while (position < source.length) {
      if (_startsWith("</")) {
        final int end = source.indexOf(">", position);
        position = end < 0 ? source.length : end + 1;
        break;
      }
      if (_startsWith("<!--") || _startsWith("<?")) {
        _skipDeclaration();
        continue;
      }
      if (_startsWith("<![CDATA[")) {
        final int end = source.indexOf("]]>", position);
        if (end < 0) {
          position = source.length;
          break;
        }
        text.write(source.substring(position + 9, end));
        position = end + 3;
        continue;
      }
      if (_startsWith("<")) {
        children.add(_parseElement(depth + 1));
        continue;
      }
      final int next = source.indexOf("<", position);
      final int stop = next < 0 ? source.length : next;
      text.write(source.substring(position, stop));
      position = stop;
    }

    return UXmlNode(name, attributes, children, UXml.unescape(text.toString().trim()));
  }

  String _readName() {
    final int start = position;
    while (position < source.length) {
      final int code = source.codeUnitAt(position);
      final bool valid = (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A) || (code >= 0x30 && code <= 0x39) || code == 0x3A || code == 0x5F || code == 0x2D || code == 0x2E;
      if (!valid) break;
      position++;
    }
    return source.substring(start, position);
  }

  String _readAttributeValue() {
    if (position >= source.length) return "";
    final String quote = source[position];
    if (quote != "\"" && quote != "'") {
      final int start = position;
      while (position < source.length && source[position] != " " && source[position] != ">") {
        position++;
      }
      return UXml.unescape(source.substring(start, position));
    }
    position++;
    final int start = position;
    final int end = source.indexOf(quote, position);
    if (end < 0) {
      position = source.length;
      return "";
    }
    position = end + 1;
    return UXml.unescape(source.substring(start, end));
  }
}

class UHlsRendition {
  const UHlsRendition({required this.type, required this.groupId, required this.name, this.language, this.uri, this.isDefault = false, this.autoSelect = false, this.forced = false, this.channels});

  final String type;
  final String groupId;
  final String name;
  final String? language;
  final String? uri;
  final bool isDefault;
  final bool autoSelect;
  final bool forced;
  final int? channels;
}

class UHlsVariant {
  const UHlsVariant({required this.url, required this.bandwidth, this.averageBandwidth, this.width, this.height, this.codecs, this.frameRate, this.audioGroup, this.subtitleGroup, this.name});

  final String url;
  final int bandwidth;
  final int? averageBandwidth;
  final int? width;
  final int? height;
  final String? codecs;
  final double? frameRate;
  final String? audioGroup;
  final String? subtitleGroup;
  final String? name;

  String get qualityLabel => height == null ? "" : "${height}p";
}

class UHlsKey {
  const UHlsKey({required this.method, this.uri, this.iv, this.keyFormat});

  final String method;
  final String? uri;
  final String? iv;
  final String? keyFormat;

  bool get isEncrypted => method != "NONE";
}

class UHlsSegment {
  const UHlsSegment({
    required this.url,
    required this.duration,
    required this.sequence,
    this.title,
    this.byteRangeLength,
    this.byteRangeOffset,
    this.discontinuity = false,
    this.key,
    this.initUrl,
    this.programDateTime,
  });

  final String url;
  final Duration duration;
  final int sequence;
  final String? title;
  final int? byteRangeLength;
  final int? byteRangeOffset;
  final bool discontinuity;
  final UHlsKey? key;
  final String? initUrl;
  final DateTime? programDateTime;
}

class UHlsMediaPlaylist {
  const UHlsMediaPlaylist({required this.segments, required this.targetDuration, required this.mediaSequence, required this.isEndList, this.initUrl, this.version = 3});

  final List<UHlsSegment> segments;
  final Duration targetDuration;
  final int mediaSequence;
  final bool isEndList;
  final String? initUrl;
  final int version;

  bool get isLive => !isEndList;

  Duration get totalDuration => segments.fold(Duration.zero, (Duration sum, UHlsSegment s) => sum + s.duration);
}

class UHlsMasterPlaylist {
  const UHlsMasterPlaylist({required this.variants, required this.renditions, this.independentSegments = false});

  final List<UHlsVariant> variants;
  final List<UHlsRendition> renditions;
  final bool independentSegments;

  List<UHlsRendition> get audioRenditions => renditions.where((UHlsRendition r) => r.type == "AUDIO").toList(growable: false);

  List<UHlsRendition> get subtitleRenditions => renditions.where((UHlsRendition r) => r.type == "SUBTITLES").toList(growable: false);

  UHlsVariant? bestUnder(int maxHeight) {
    UHlsVariant? best;
    for (final UHlsVariant variant in variants) {
      if (maxHeight > 0 && (variant.height ?? 0) > maxHeight) continue;
      if (best == null || variant.bandwidth > best.bandwidth) best = variant;
    }
    return best ?? (variants.isEmpty ? null : variants.first);
  }
}

class UHlsPlaylist {
  const UHlsPlaylist({this.master, this.media});

  final UHlsMasterPlaylist? master;
  final UHlsMediaPlaylist? media;

  bool get isMaster => master != null;
}

abstract final class UHlsParser {
  static bool looksLikeHls(String content) => content.trimLeft().startsWith("#EXTM3U");

  static UHlsPlaylist parse(String content, {String? baseUrl}) {
    final List<String> lines = content.replaceAll("\r\n", "\n").replaceAll("\r", "\n").split("\n");
    final bool isMaster = lines.any((String l) => l.startsWith("#EXT-X-STREAM-INF"));
    return isMaster ? UHlsPlaylist(master: _parseMaster(lines, baseUrl)) : UHlsPlaylist(media: _parseMedia(lines, baseUrl));
  }

  static String resolve(String uri, String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) return uri;
    if (uri.startsWith("http://") || uri.startsWith("https://") || uri.startsWith("data:") || uri.startsWith("file:")) return uri;
    try {
      return Uri.parse(baseUrl).resolve(uri).toString();
    } on FormatException {
      return uri;
    }
  }

  static Map<String, String> _attributes(String line) {
    final Map<String, String> result = <String, String>{};
    final int colon = line.indexOf(":");
    if (colon < 0) return result;
    final String body = line.substring(colon + 1);
    final RegExp pattern = RegExp("([A-Za-z0-9-]+)=(\"[^\"]*\"|[^,]*)");
    for (final RegExpMatch match in pattern.allMatches(body)) {
      String value = match.group(2)!;
      if (value.startsWith("\"") && value.endsWith("\"") && value.length >= 2) value = value.substring(1, value.length - 1);
      result[match.group(1)!.toUpperCase()] = value;
    }
    return result;
  }

  static UHlsMasterPlaylist _parseMaster(List<String> lines, String? baseUrl) {
    final List<UHlsVariant> variants = <UHlsVariant>[];
    final List<UHlsRendition> renditions = <UHlsRendition>[];
    bool independent = false;
    Map<String, String>? pendingVariant;

    for (final String raw in lines) {
      final String line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith("#EXT-X-INDEPENDENT-SEGMENTS")) {
        independent = true;
        continue;
      }
      if (line.startsWith("#EXT-X-MEDIA:")) {
        final Map<String, String> attrs = _attributes(line);
        renditions.add(
          UHlsRendition(
            type: attrs["TYPE"] ?? "AUDIO",
            groupId: attrs["GROUP-ID"] ?? "",
            name: attrs["NAME"] ?? "",
            language: attrs["LANGUAGE"],
            uri: attrs["URI"] == null ? null : resolve(attrs["URI"]!, baseUrl),
            isDefault: attrs["DEFAULT"] == "YES",
            autoSelect: attrs["AUTOSELECT"] == "YES",
            forced: attrs["FORCED"] == "YES",
            channels: int.tryParse(attrs["CHANNELS"] ?? ""),
          ),
        );
        continue;
      }
      if (line.startsWith("#EXT-X-STREAM-INF:")) {
        pendingVariant = _attributes(line);
        continue;
      }
      if (line.startsWith("#")) continue;

      if (pendingVariant != null) {
        final Map<String, String> attrs = pendingVariant;
        final List<String> resolution = (attrs["RESOLUTION"] ?? "").split("x");
        variants.add(
          UHlsVariant(
            url: resolve(line, baseUrl),
            bandwidth: int.tryParse(attrs["BANDWIDTH"] ?? "") ?? 0,
            averageBandwidth: int.tryParse(attrs["AVERAGE-BANDWIDTH"] ?? ""),
            width: resolution.length == 2 ? int.tryParse(resolution[0]) : null,
            height: resolution.length == 2 ? int.tryParse(resolution[1]) : null,
            codecs: attrs["CODECS"],
            frameRate: double.tryParse(attrs["FRAME-RATE"] ?? ""),
            audioGroup: attrs["AUDIO"],
            subtitleGroup: attrs["SUBTITLES"],
            name: attrs["NAME"],
          ),
        );
        pendingVariant = null;
      }
    }

    variants.sort((UHlsVariant a, UHlsVariant b) => b.bandwidth.compareTo(a.bandwidth));
    return UHlsMasterPlaylist(variants: variants, renditions: renditions, independentSegments: independent);
  }

  static UHlsMediaPlaylist _parseMedia(List<String> lines, String? baseUrl) {
    final List<UHlsSegment> segments = <UHlsSegment>[];
    Duration targetDuration = const Duration(seconds: 10);
    int mediaSequence = 0;
    int version = 3;
    bool endList = false;
    bool discontinuity = false;
    Duration pendingDuration = Duration.zero;
    String? pendingTitle;
    int? byteRangeLength;
    int? byteRangeOffset;
    int? lastByteRangeEnd;
    UHlsKey? key;
    String? initUrl;
    DateTime? programDateTime;
    int sequence = 0;

    for (final String raw in lines) {
      final String line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith("#EXT-X-TARGETDURATION:")) {
        targetDuration = Duration(milliseconds: ((double.tryParse(line.split(":")[1]) ?? 10) * 1000).round());
        continue;
      }
      if (line.startsWith("#EXT-X-MEDIA-SEQUENCE:")) {
        mediaSequence = int.tryParse(line.split(":")[1]) ?? 0;
        sequence = mediaSequence;
        continue;
      }
      if (line.startsWith("#EXT-X-VERSION:")) {
        version = int.tryParse(line.split(":")[1]) ?? 3;
        continue;
      }
      if (line.startsWith("#EXT-X-ENDLIST")) {
        endList = true;
        continue;
      }
      if (line.startsWith("#EXT-X-DISCONTINUITY")) {
        discontinuity = true;
        continue;
      }
      if (line.startsWith("#EXT-X-KEY:")) {
        final Map<String, String> attrs = _attributes(line);
        key = UHlsKey(
          method: attrs["METHOD"] ?? "NONE",
          uri: attrs["URI"] == null ? null : resolve(attrs["URI"]!, baseUrl),
          iv: attrs["IV"],
          keyFormat: attrs["KEYFORMAT"],
        );
        continue;
      }
      if (line.startsWith("#EXT-X-MAP:")) {
        final Map<String, String> attrs = _attributes(line);
        if (attrs["URI"] != null) initUrl = resolve(attrs["URI"]!, baseUrl);
        continue;
      }
      if (line.startsWith("#EXT-X-BYTERANGE:")) {
        final List<String> parts = line.split(":")[1].split("@");
        byteRangeLength = int.tryParse(parts[0]);
        byteRangeOffset = parts.length > 1 ? int.tryParse(parts[1]) : lastByteRangeEnd;
        continue;
      }
      if (line.startsWith("#EXT-X-PROGRAM-DATE-TIME:")) {
        programDateTime = DateTime.tryParse(line.substring(25).trim());
        continue;
      }
      if (line.startsWith("#EXTINF:")) {
        final String body = line.substring(8);
        final int comma = body.indexOf(",");
        pendingDuration = Duration(milliseconds: ((double.tryParse(comma < 0 ? body : body.substring(0, comma)) ?? 0) * 1000).round());
        pendingTitle = comma < 0 || comma + 1 >= body.length ? null : body.substring(comma + 1).trim();
        continue;
      }
      if (line.startsWith("#")) continue;

      segments.add(
        UHlsSegment(
          url: resolve(line, baseUrl),
          duration: pendingDuration,
          sequence: sequence++,
          title: pendingTitle == null || pendingTitle.isEmpty ? null : pendingTitle,
          byteRangeLength: byteRangeLength,
          byteRangeOffset: byteRangeOffset,
          discontinuity: discontinuity,
          key: key != null && key.isEncrypted ? key : null,
          initUrl: initUrl,
          programDateTime: programDateTime,
        ),
      );
      if (byteRangeLength != null) lastByteRangeEnd = (byteRangeOffset ?? 0) + byteRangeLength;
      discontinuity = false;
      byteRangeLength = null;
      byteRangeOffset = null;
      pendingTitle = null;
      programDateTime = null;
    }

    return UHlsMediaPlaylist(segments: segments, targetDuration: targetDuration, mediaSequence: mediaSequence, isEndList: endList, initUrl: initUrl, version: version);
  }
}

class UDashSegmentRef {
  const UDashSegmentRef({required this.url, required this.start, required this.duration, this.number, this.rangeStart, this.rangeEnd});

  final String url;
  final Duration start;
  final Duration duration;
  final int? number;
  final int? rangeStart;
  final int? rangeEnd;
}

class UDashSegmentTemplate {
  const UDashSegmentTemplate({this.media, this.initialization, this.timescale = 1, this.duration = 0, this.startNumber = 1, this.timeline = const <List<int>>[], this.presentationTimeOffset = 0});

  final String? media;
  final String? initialization;
  final int timescale;
  final int duration;
  final int startNumber;
  final List<List<int>> timeline;
  final int presentationTimeOffset;

  bool get hasTimeline => timeline.isNotEmpty;
}

class UDashContentProtection {
  const UDashContentProtection({required this.schemeIdUri, this.value, this.defaultKid, this.pssh});

  final String schemeIdUri;
  final String? value;
  final String? defaultKid;
  final String? pssh;

  UDrmScheme? get scheme {
    final String id = schemeIdUri.toLowerCase();
    if (id.contains("edef8ba9-79d6-4ace-a3c8-27dcd51d21ed")) return UDrmScheme.widevine;
    if (id.contains("9a04f079-9840-4286-ab92-e65be0885f95")) return UDrmScheme.playready;
    if (id.contains("1077efec-c0b2-4d02-ace3-3c1e52e2fb4b")) return UDrmScheme.clearkey;
    return null;
  }
}

class UDashRepresentation {
  const UDashRepresentation({
    required this.id,
    required this.bandwidth,
    this.width,
    this.height,
    this.codecs,
    this.mimeType,
    this.frameRate,
    this.audioSamplingRate,
    this.audioChannels,
    this.baseUrl,
    this.template,
    this.indexRange,
    this.initializationRange,
  });

  final String id;
  final int bandwidth;
  final int? width;
  final int? height;
  final String? codecs;
  final String? mimeType;
  final double? frameRate;
  final int? audioSamplingRate;
  final int? audioChannels;
  final String? baseUrl;
  final UDashSegmentTemplate? template;
  final String? indexRange;
  final String? initializationRange;

  String get qualityLabel => height == null ? "" : "${height}p";

  String? initializationUrl(String? parentBase) {
    final UDashSegmentTemplate? t = template;
    if (t?.initialization == null) return null;
    return _resolve(_expand(t!.initialization!, 0, 0), parentBase);
  }

  List<UDashSegmentRef> segments({required Duration periodDuration, String? parentBase}) {
    final UDashSegmentTemplate? t = template;
    if (t == null || t.media == null) return const <UDashSegmentRef>[];
    final int timescale = t.timescale <= 0 ? 1 : t.timescale;
    final List<UDashSegmentRef> result = <UDashSegmentRef>[];

    if (t.hasTimeline) {
      int number = t.startNumber;
      int time = 0;
      for (final List<int> entry in t.timeline) {
        final int startTime = entry[0] >= 0 ? entry[0] : time;
        final int segmentDuration = entry[1];
        final int repeat = entry[2];
        time = startTime;
        for (int i = 0; i <= repeat; i++) {
          result.add(
            UDashSegmentRef(
              url: _resolve(_expand(t.media!, number, time), parentBase),
              start: Duration(milliseconds: (time / timescale * 1000).round()),
              duration: Duration(milliseconds: (segmentDuration / timescale * 1000).round()),
              number: number,
            ),
          );
          time += segmentDuration;
          number++;
          if (result.length > 20000) return result;
        }
      }
      return result;
    }

    if (t.duration <= 0) return const <UDashSegmentRef>[];
    final double segmentSeconds = t.duration / timescale;
    final int count = (periodDuration.inMilliseconds / 1000 / segmentSeconds).ceil();
    final int capped = count > 20000 ? 20000 : count;
    for (int i = 0; i < capped; i++) {
      final int number = t.startNumber + i;
      result.add(
        UDashSegmentRef(
          url: _resolve(_expand(t.media!, number, i * t.duration), parentBase),
          start: Duration(milliseconds: (i * segmentSeconds * 1000).round()),
          duration: Duration(milliseconds: (segmentSeconds * 1000).round()),
          number: number,
        ),
      );
    }
    return result;
  }

  String _expand(String pattern, int number, int time) {
    String output = pattern.replaceAll(r"$RepresentationID$", id).replaceAll(r"$Bandwidth$", "$bandwidth");
    output = output.replaceAllMapped(RegExp(r"\$Number(%0(\d+)d)?\$"), (Match m) => m.group(2) == null ? "$number" : "$number".padLeft(int.parse(m.group(2)!), "0"));
    output = output.replaceAllMapped(RegExp(r"\$Time(%0(\d+)d)?\$"), (Match m) => m.group(2) == null ? "$time" : "$time".padLeft(int.parse(m.group(2)!), "0"));
    return output.replaceAll(r"$$", r"$");
  }

  String _resolve(String uri, String? parentBase) {
    final String base = baseUrl ?? parentBase ?? "";
    if (base.isEmpty) return uri;
    if (uri.startsWith("http://") || uri.startsWith("https://")) return uri;
    try {
      return Uri.parse(base).resolve(uri).toString();
    } on FormatException {
      return uri;
    }
  }
}

class UDashAdaptationSet {
  const UDashAdaptationSet({required this.representations, this.contentType, this.mimeType, this.language, this.roles = const <String>[], this.protections = const <UDashContentProtection>[], this.template, this.baseUrl});

  final List<UDashRepresentation> representations;
  final String? contentType;
  final String? mimeType;
  final String? language;
  final List<String> roles;
  final List<UDashContentProtection> protections;
  final UDashSegmentTemplate? template;
  final String? baseUrl;

  UMediaTrackType get trackType {
    final String type = (contentType ?? mimeType ?? "").toLowerCase();
    if (type.contains("audio")) return UMediaTrackType.audio;
    if (type.contains("text") || type.contains("subtitle")) return UMediaTrackType.subtitle;
    return UMediaTrackType.video;
  }
}

class UDashPeriod {
  const UDashPeriod({required this.adaptationSets, this.id, this.start = Duration.zero, this.duration = Duration.zero, this.baseUrl});

  final List<UDashAdaptationSet> adaptationSets;
  final String? id;
  final Duration start;
  final Duration duration;
  final String? baseUrl;
}

class UDashManifest {
  const UDashManifest({required this.periods, this.isDynamic = false, this.duration = Duration.zero, this.minBufferTime = Duration.zero, this.baseUrl, this.minimumUpdatePeriod});

  final List<UDashPeriod> periods;
  final bool isDynamic;
  final Duration duration;
  final Duration minBufferTime;
  final String? baseUrl;
  final Duration? minimumUpdatePeriod;

  bool get isLive => isDynamic;

  List<UMediaTrack> toTracks() {
    final List<UMediaTrack> tracks = <UMediaTrack>[];
    for (final UDashPeriod period in periods) {
      for (final UDashAdaptationSet set in period.adaptationSets) {
        for (final UDashRepresentation rep in set.representations) {
          tracks.add(
            UMediaTrack(
              id: rep.id,
              type: set.trackType,
              language: set.language,
              codec: rep.codecs,
              bitrate: rep.bandwidth,
              width: rep.width,
              height: rep.height,
              frameRate: rep.frameRate,
              channels: rep.audioChannels,
              sampleRate: rep.audioSamplingRate,
            ),
          );
        }
      }
    }
    return tracks;
  }
}

abstract final class UDashParser {
  static UDashManifest? parse(String content, {String? baseUrl}) {
    final UXmlNode? root = UXml.parse(content);
    if (root == null || !root.name.endsWith("MPD")) return null;

    final String? manifestBase = _joinBase(baseUrl, root.child("BaseURL")?.text);
    final List<UDashPeriod> periods = <UDashPeriod>[];
    final Duration total = parseIso8601(root.attr("mediaPresentationDuration"));

    for (final UXmlNode periodNode in root.childrenNamed("Period")) {
      final String? periodBase = _joinBase(manifestBase, periodNode.child("BaseURL")?.text);
      final Duration periodDuration = parseIso8601(periodNode.attr("duration"));
      final List<UDashAdaptationSet> sets = <UDashAdaptationSet>[];

      for (final UXmlNode setNode in periodNode.childrenNamed("AdaptationSet")) {
        final String? setBase = _joinBase(periodBase, setNode.child("BaseURL")?.text);
        final UDashSegmentTemplate? setTemplate = _template(setNode.child("SegmentTemplate"));
        final List<UDashRepresentation> reps = <UDashRepresentation>[];

        for (final UXmlNode repNode in setNode.childrenNamed("Representation")) {
          final UDashSegmentTemplate? repTemplate = _template(repNode.child("SegmentTemplate")) ?? setTemplate;
          reps.add(
            UDashRepresentation(
              id: repNode.attr("id") ?? "",
              bandwidth: int.tryParse(repNode.attr("bandwidth") ?? "") ?? 0,
              width: int.tryParse(repNode.attr("width") ?? setNode.attr("width") ?? ""),
              height: int.tryParse(repNode.attr("height") ?? setNode.attr("height") ?? ""),
              codecs: repNode.attr("codecs") ?? setNode.attr("codecs"),
              mimeType: repNode.attr("mimeType") ?? setNode.attr("mimeType"),
              frameRate: _frameRate(repNode.attr("frameRate") ?? setNode.attr("frameRate")),
              audioSamplingRate: int.tryParse(repNode.attr("audioSamplingRate") ?? setNode.attr("audioSamplingRate") ?? ""),
              audioChannels: int.tryParse(repNode.child("AudioChannelConfiguration")?.attr("value") ?? setNode.child("AudioChannelConfiguration")?.attr("value") ?? ""),
              baseUrl: _joinBase(setBase, repNode.child("BaseURL")?.text),
              template: repTemplate,
              indexRange: repNode.child("SegmentBase")?.attr("indexRange"),
              initializationRange: repNode.child("SegmentBase")?.child("Initialization")?.attr("range"),
            ),
          );
        }

        sets.add(
          UDashAdaptationSet(
            representations: reps,
            contentType: setNode.attr("contentType"),
            mimeType: setNode.attr("mimeType"),
            language: setNode.attr("lang"),
            roles: setNode.childrenNamed("Role").map((UXmlNode n) => n.attr("value") ?? "").where((String v) => v.isNotEmpty).toList(growable: false),
            protections: setNode
                .childrenNamed("ContentProtection")
                .map(
                  (UXmlNode n) => UDashContentProtection(
                    schemeIdUri: n.attr("schemeIdUri") ?? "",
                    value: n.attr("value"),
                    defaultKid: n.attr("cenc:default_KID") ?? n.attr("default_KID"),
                    pssh: n.child("pssh")?.text ?? n.child("cenc:pssh")?.text,
                  ),
                )
                .toList(growable: false),
            template: setTemplate,
            baseUrl: setBase,
          ),
        );
      }

      periods.add(
        UDashPeriod(
          adaptationSets: sets,
          id: periodNode.attr("id"),
          start: parseIso8601(periodNode.attr("start")),
          duration: periodDuration == Duration.zero ? total : periodDuration,
          baseUrl: periodBase,
        ),
      );
    }

    return UDashManifest(
      periods: periods,
      isDynamic: root.attr("type") == "dynamic",
      duration: total,
      minBufferTime: parseIso8601(root.attr("minBufferTime")),
      baseUrl: manifestBase,
      minimumUpdatePeriod: root.attr("minimumUpdatePeriod") == null ? null : parseIso8601(root.attr("minimumUpdatePeriod")),
    );
  }

  static double? _frameRate(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.contains("/")) return double.tryParse(value);
    final List<String> parts = value.split("/");
    final double? numerator = double.tryParse(parts[0]);
    final double? denominator = parts.length > 1 ? double.tryParse(parts[1]) : 1;
    if (numerator == null || denominator == null || denominator == 0) return null;
    return numerator / denominator;
  }

  static String? _joinBase(String? parent, String? child) {
    if (child == null || child.isEmpty) return parent;
    if (parent == null || parent.isEmpty) return child;
    try {
      return Uri.parse(parent).resolve(child).toString();
    } on FormatException {
      return child;
    }
  }

  static UDashSegmentTemplate? _template(UXmlNode? node) {
    if (node == null) return null;
    final List<List<int>> timeline = <List<int>>[];
    final UXmlNode? timelineNode = node.child("SegmentTimeline");
    if (timelineNode != null) {
      for (final UXmlNode s in timelineNode.childrenNamed("S")) {
        timeline.add(<int>[int.tryParse(s.attr("t") ?? "") ?? -1, int.tryParse(s.attr("d") ?? "") ?? 0, int.tryParse(s.attr("r") ?? "") ?? 0]);
      }
    }
    return UDashSegmentTemplate(
      media: node.attr("media"),
      initialization: node.attr("initialization"),
      timescale: int.tryParse(node.attr("timescale") ?? "") ?? 1,
      duration: int.tryParse(node.attr("duration") ?? "") ?? 0,
      startNumber: int.tryParse(node.attr("startNumber") ?? "") ?? 1,
      timeline: timeline,
      presentationTimeOffset: int.tryParse(node.attr("presentationTimeOffset") ?? "") ?? 0,
    );
  }

  static Duration parseIso8601(String? value) {
    if (value == null || value.isEmpty) return Duration.zero;
    final RegExpMatch? m = RegExp(r"^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:([\d.]+)S)?)?$").firstMatch(value.trim());
    if (m == null) return Duration.zero;
    final double seconds = double.tryParse(m.group(6) ?? "0") ?? 0;
    return Duration(
      days: (int.tryParse(m.group(3) ?? "0") ?? 0) + (int.tryParse(m.group(2) ?? "0") ?? 0) * 30 + (int.tryParse(m.group(1) ?? "0") ?? 0) * 365,
      hours: int.tryParse(m.group(4) ?? "0") ?? 0,
      minutes: int.tryParse(m.group(5) ?? "0") ?? 0,
      milliseconds: (seconds * 1000).round(),
    );
  }
}

class UPlaylistEntry {
  const UPlaylistEntry({required this.uri, this.title, this.duration, this.artist});

  final String uri;
  final String? title;
  final Duration? duration;
  final String? artist;
}

abstract final class UPlaylistParser {
  static List<UPlaylistEntry> parse(String content, {String? baseUri}) {
    final String trimmed = content.trimLeft();
    if (trimmed.startsWith("<?xml") || trimmed.startsWith("<playlist")) return _parseXspf(content, baseUri);
    if (trimmed.startsWith("[playlist]")) return _parsePls(content, baseUri);
    return _parseM3u(content, baseUri);
  }

  static String write(List<UPlaylistEntry> entries) {
    final StringBuffer buffer = StringBuffer("#EXTM3U\n");
    for (final UPlaylistEntry entry in entries) {
      final int seconds = entry.duration?.inSeconds ?? -1;
      final String label = entry.artist == null ? (entry.title ?? "") : "${entry.artist} - ${entry.title ?? ""}";
      buffer.writeln("#EXTINF:$seconds,$label");
      buffer.writeln(entry.uri);
    }
    return buffer.toString();
  }

  static String _resolve(String uri, String? baseUri) {
    if (baseUri == null || baseUri.isEmpty) return uri;
    if (uri.startsWith("http://") || uri.startsWith("https://") || uri.startsWith("/")) return uri;
    try {
      return Uri.parse(baseUri).resolve(uri).toString();
    } on FormatException {
      return uri;
    }
  }

  static List<UPlaylistEntry> _parseM3u(String content, String? baseUri) {
    final List<UPlaylistEntry> entries = <UPlaylistEntry>[];
    String? pendingTitle;
    String? pendingArtist;
    Duration? pendingDuration;

    for (final String raw in content.replaceAll("\r\n", "\n").split("\n")) {
      final String line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith("#EXTINF:")) {
        final String body = line.substring(8);
        final int comma = body.indexOf(",");
        final int seconds = int.tryParse(comma < 0 ? body : body.substring(0, comma)) ?? -1;
        pendingDuration = seconds > 0 ? Duration(seconds: seconds) : null;
        final String label = comma < 0 ? "" : body.substring(comma + 1).trim();
        final int dash = label.indexOf(" - ");
        if (dash > 0) {
          pendingArtist = label.substring(0, dash).trim();
          pendingTitle = label.substring(dash + 3).trim();
        } else {
          pendingTitle = label.isEmpty ? null : label;
          pendingArtist = null;
        }
        continue;
      }
      if (line.startsWith("#")) continue;
      entries.add(UPlaylistEntry(uri: _resolve(line, baseUri), title: pendingTitle, artist: pendingArtist, duration: pendingDuration));
      pendingTitle = null;
      pendingArtist = null;
      pendingDuration = null;
    }
    return entries;
  }

  static List<UPlaylistEntry> _parsePls(String content, String? baseUri) {
    final Map<int, String> files = <int, String>{};
    final Map<int, String> titles = <int, String>{};
    final Map<int, int> lengths = <int, int>{};

    for (final String raw in content.replaceAll("\r\n", "\n").split("\n")) {
      final String line = raw.trim();
      final int equals = line.indexOf("=");
      if (equals <= 0) continue;
      final String key = line.substring(0, equals).toLowerCase();
      final String value = line.substring(equals + 1).trim();
      final int? index = int.tryParse(RegExp(r"\d+$").firstMatch(key)?.group(0) ?? "");
      if (index == null) continue;
      if (key.startsWith("file")) files[index] = value;
      if (key.startsWith("title")) titles[index] = value;
      if (key.startsWith("length")) lengths[index] = int.tryParse(value) ?? -1;
    }

    final List<int> indices = files.keys.toList()..sort();
    return indices
        .map(
          (int i) => UPlaylistEntry(
            uri: _resolve(files[i]!, baseUri),
            title: titles[i],
            duration: (lengths[i] ?? -1) > 0 ? Duration(seconds: lengths[i]!) : null,
          ),
        )
        .toList(growable: false);
  }

  static List<UPlaylistEntry> _parseXspf(String content, String? baseUri) {
    final UXmlNode? root = UXml.parse(content);
    if (root == null) return const <UPlaylistEntry>[];
    final UXmlNode? trackList = root.child("trackList");
    if (trackList == null) return const <UPlaylistEntry>[];
    return trackList
        .childrenNamed("track")
        .map((UXmlNode track) {
          final String location = track.child("location")?.text ?? "";
          final int ms = int.tryParse(track.child("duration")?.text ?? "") ?? 0;
          return UPlaylistEntry(
            uri: _resolve(location, baseUri),
            title: track.child("title")?.text,
            artist: track.child("creator")?.text,
            duration: ms > 0 ? Duration(milliseconds: ms) : null,
          );
        })
        .where((UPlaylistEntry e) => e.uri.isNotEmpty)
        .toList(growable: false);
  }
}

class UTrackRecord {
  UTrackRecord({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.addedAt = 0,
    this.artworkOffset = 0,
    this.artworkLength = 0,
    this.artworkMime,
  }) : searchKey = UBidi.normalizePersian("$title $artist $album").toLowerCase();

  final String path;
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final int durationMs;
  final int sizeBytes;
  final int addedAt;
  final int artworkOffset;
  final int artworkLength;
  final String? artworkMime;
  final String searchKey;

  Duration get duration => Duration(milliseconds: durationMs);

  String get folder {
    final int slash = path.lastIndexOf(Platform.pathSeparator);
    return slash <= 0 ? path : path.substring(0, slash);
  }

  String get fileName {
    final int slash = path.lastIndexOf(Platform.pathSeparator);
    return slash < 0 ? path : path.substring(slash + 1);
  }

  UArtworkRef? get artwork =>
      artworkLength > 0 ? UArtworkRef.embedded(filePath: path, offset: artworkOffset, length: artworkLength, mimeType: artworkMime) : null;

  UMediaMetadata get metadata => UMediaMetadata(
    title: title,
    artist: artist,
    album: album,
    albumArtist: albumArtist,
    genre: genre,
    year: year,
    trackNumber: trackNumber,
    discNumber: discNumber,
    duration: durationMs > 0 ? duration : null,
    artwork: artwork,
  );

  UMediaSource get source => UMediaSource.file(path, metadata: metadata);

  Map<String, Object?> toJson() => <String, Object?>{
    "p": path,
    "t": title,
    "a": artist,
    "b": album,
    "aa": albumArtist,
    "g": genre,
    "y": year,
    "n": trackNumber,
    "d": discNumber,
    "ms": durationMs,
    "sz": sizeBytes,
    "ad": addedAt,
    "ao": artworkOffset,
    "al": artworkLength,
    "am": artworkMime,
  };

  factory UTrackRecord.fromJson(Map<String, Object?> json) => UTrackRecord(
    path: (json["p"] as String?) ?? "",
    title: (json["t"] as String?) ?? "",
    artist: (json["a"] as String?) ?? "",
    album: (json["b"] as String?) ?? "",
    albumArtist: json["aa"] as String?,
    genre: json["g"] as String?,
    year: json["y"] as int?,
    trackNumber: json["n"] as int?,
    discNumber: json["d"] as int?,
    durationMs: (json["ms"] as int?) ?? 0,
    sizeBytes: (json["sz"] as int?) ?? 0,
    addedAt: (json["ad"] as int?) ?? 0,
    artworkOffset: (json["ao"] as int?) ?? 0,
    artworkLength: (json["al"] as int?) ?? 0,
    artworkMime: json["am"] as String?,
  );
}

enum ULibrarySort { title, artist, album, dateAdded, duration, year }

class UMediaLibrary extends ChangeNotifier {
  UMediaLibrary._();

  static final UMediaLibrary instance = UMediaLibrary._();

  static const String _indexFileName = "u_media_library.jsonl";
  static const String _favoritesKey = "u_media_favorites";
  static const String _playCountKey = "u_media_play_counts";

  final List<UTrackRecord> _tracks = <UTrackRecord>[];
  final Set<String> _favorites = <String>{};
  final Map<String, int> _playCounts = <String, int>{};

  bool _loaded = false;
  bool _scanning = false;
  int _scanned = 0;
  int _scanTotal = 0;

  List<UTrackRecord> get tracks => List<UTrackRecord>.unmodifiable(_tracks);

  bool get isLoaded => _loaded;

  bool get isScanning => _scanning;

  int get scannedCount => _scanned;

  int get scanTotal => _scanTotal;

  int get count => _tracks.length;

  Set<String> get favorites => Set<String>.unmodifiable(_favorites);

  Future<File> _indexFile() async {
    final Directory directory = await getApplicationSupportDirectory();
    return File("${directory.path}${Platform.pathSeparator}$_indexFileName");
  }

  Future<void> load() async {
    if (_loaded || kIsWeb) return;
    _loaded = true;
    try {
      final File file = await _indexFile();
      final List<String> lines = await file.readAsLines();
      _tracks
        ..clear()
        ..addAll(
          lines
              .where((String line) => line.trim().isNotEmpty)
              .map((String line) => UTrackRecord.fromJson(jsonDecode(line) as Map<String, Object?>)),
        );
    } on FileSystemException {
      _tracks.clear();
    } on FormatException {
      _tracks.clear();
    }

    _favorites
      ..clear()
      ..addAll((ULocalStorage.getString(_favoritesKey) ?? "").split("\n").where((String p) => p.isNotEmpty));

    final String rawCounts = ULocalStorage.getString(_playCountKey) ?? "";
    _playCounts.clear();
    for (final String entry in rawCounts.split("\n")) {
      final int separator = entry.lastIndexOf("|");
      if (separator <= 0) continue;
      _playCounts[entry.substring(0, separator)] = int.tryParse(entry.substring(separator + 1)) ?? 0;
    }
    notifyListeners();
  }

  Future<void> save() async {
    if (kIsWeb) return;
    final File file = await _indexFile();
    final StringBuffer buffer = StringBuffer();
    for (final UTrackRecord record in _tracks) {
      buffer.writeln(jsonEncode(record.toJson()));
    }
    await file.writeAsString(buffer.toString(), flush: true);
  }

  Future<void> scan(List<String> roots, {bool replace = true, void Function(int scanned, int total)? onProgress}) async {
    if (kIsWeb || _scanning) return;
    _scanning = true;
    _scanned = 0;
    _scanTotal = 0;
    notifyListeners();

    final List<String> files = <String>[];
    for (final String root in roots) {
      try {
        await for (final FileSystemEntity entity in Directory(root).list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          final String lower = entity.path.toLowerCase();
          final int dot = lower.lastIndexOf(".");
          if (dot < 0 || !UAudio.audioExtensions.contains(lower.substring(dot))) continue;
          files.add(entity.path);
        }
      } on FileSystemException {
        continue;
      }
    }

    _scanTotal = files.length;
    notifyListeners();

    final Map<String, UTrackRecord> existing = <String, UTrackRecord>{for (final UTrackRecord record in _tracks) record.path: record};
    final List<UTrackRecord> result = <UTrackRecord>[];
    final int now = DateTime.now().millisecondsSinceEpoch;

    for (final String path in files) {
      _scanned++;
      if (_scanned % 25 == 0) {
        onProgress?.call(_scanned, _scanTotal);
        notifyListeners();
        await Future<void>.delayed(Duration.zero);
      }

      final UTrackRecord? cached = existing[path];
      if (cached != null && !replace) {
        result.add(cached);
        continue;
      }

      final UMediaMetadata tags = await UTagParser.readFile(path);
      int size = 0;
      try {
        size = await File(path).length();
      } on FileSystemException {
        size = 0;
      }

      final String fallbackTitle = path.split(Platform.pathSeparator).last.replaceAll(RegExp(r"\.[^.]+$"), "");
      result.add(
        UTrackRecord(
          path: path,
          title: tags.title ?? fallbackTitle,
          artist: tags.artist ?? "",
          album: tags.album ?? "",
          albumArtist: tags.albumArtist,
          genre: tags.genre,
          year: tags.year,
          trackNumber: tags.trackNumber,
          discNumber: tags.discNumber,
          durationMs: tags.duration?.inMilliseconds ?? 0,
          sizeBytes: size,
          addedAt: cached?.addedAt ?? now,
          artworkOffset: tags.artwork?.offset ?? 0,
          artworkLength: tags.artwork?.length ?? 0,
          artworkMime: tags.artwork?.mimeType,
        ),
      );
    }

    _tracks
      ..clear()
      ..addAll(result);
    _scanning = false;
    _scanned = _scanTotal;
    notifyListeners();
    await save();
  }

  List<UTrackRecord> search(String query) {
    final String normalized = UBidi.normalizePersian(query).toLowerCase().trim();
    if (normalized.isEmpty) return tracks;
    final List<String> terms = normalized.split(" ").where((String t) => t.isNotEmpty).toList(growable: false);
    return _tracks.where((UTrackRecord record) => terms.every((String term) => record.searchKey.contains(term))).toList(growable: false);
  }

  List<UTrackRecord> sorted(List<UTrackRecord> input, ULibrarySort sort, {bool descending = false}) {
    final List<UTrackRecord> copy = List<UTrackRecord>.of(input);
    copy.sort((UTrackRecord a, UTrackRecord b) {
      switch (sort) {
        case ULibrarySort.title:
          return a.title.compareTo(b.title);
        case ULibrarySort.artist:
          return a.artist.compareTo(b.artist);
        case ULibrarySort.album:
          return a.album.compareTo(b.album);
        case ULibrarySort.dateAdded:
          return a.addedAt.compareTo(b.addedAt);
        case ULibrarySort.duration:
          return a.durationMs.compareTo(b.durationMs);
        case ULibrarySort.year:
          return (a.year ?? 0).compareTo(b.year ?? 0);
      }
    });
    return descending ? copy.reversed.toList(growable: false) : copy;
  }

  List<String> groupValues(String Function(UTrackRecord record) selector) {
    final Set<String> values = <String>{};
    for (final UTrackRecord record in _tracks) {
      final String value = selector(record);
      if (value.isNotEmpty) values.add(value);
    }
    final List<String> list = values.toList()..sort();
    return list;
  }

  List<String> get albums => groupValues((UTrackRecord r) => r.album);

  List<String> get artists => groupValues((UTrackRecord r) => r.artist);

  List<String> get genres => groupValues((UTrackRecord r) => r.genre ?? "");

  List<String> get folders => groupValues((UTrackRecord r) => r.folder);

  List<UTrackRecord> where(bool Function(UTrackRecord record) test) => _tracks.where(test).toList(growable: false);

  List<UTrackRecord> byAlbum(String album) => where((UTrackRecord r) => r.album == album);

  List<UTrackRecord> byArtist(String artist) => where((UTrackRecord r) => r.artist == artist);

  List<UTrackRecord> byFolder(String folder) => where((UTrackRecord r) => r.folder == folder);

  List<UTrackRecord> get favoriteTracks => where((UTrackRecord r) => _favorites.contains(r.path));

  List<UTrackRecord> get mostPlayed {
    final List<UTrackRecord> played = where((UTrackRecord r) => (_playCounts[r.path] ?? 0) > 0);
    played.sort((UTrackRecord a, UTrackRecord b) => (_playCounts[b.path] ?? 0).compareTo(_playCounts[a.path] ?? 0));
    return played;
  }

  bool isFavorite(String path) => _favorites.contains(path);

  int playCount(String path) => _playCounts[path] ?? 0;

  void toggleFavorite(String path) {
    if (!_favorites.remove(path)) _favorites.add(path);
    ULocalStorage.set(_favoritesKey, _favorites.join("\n"));
    notifyListeners();
  }

  void registerPlay(String path) {
    _playCounts[path] = (_playCounts[path] ?? 0) + 1;
    ULocalStorage.set(_playCountKey, _playCounts.entries.map((MapEntry<String, int> e) => "${e.key}|${e.value}").join("\n"));
    notifyListeners();
  }

  Future<void> clear() async {
    _tracks.clear();
    notifyListeners();
    await save();
  }
}

class UPlaylist {
  UPlaylist({required this.id, required this.name, required this.paths, this.createdAt = 0, this.updatedAt = 0});

  final String id;
  final String name;
  final List<String> paths;
  final int createdAt;
  final int updatedAt;

  int get length => paths.length;

  UPlaylist copyWith({String? name, List<String>? paths}) => UPlaylist(
    id: id,
    name: name ?? this.name,
    paths: paths ?? this.paths,
    createdAt: createdAt,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );

  Map<String, Object?> toJson() => <String, Object?>{"id": id, "name": name, "paths": paths, "createdAt": createdAt, "updatedAt": updatedAt};

  factory UPlaylist.fromJson(Map<String, Object?> json) => UPlaylist(
    id: (json["id"] as String?) ?? UUUID.uuidV4(),
    name: (json["name"] as String?) ?? "",
    paths: ((json["paths"] as List<Object?>?) ?? const <Object?>[]).whereType<String>().toList(),
    createdAt: (json["createdAt"] as int?) ?? 0,
    updatedAt: (json["updatedAt"] as int?) ?? 0,
  );
}

class UPlaylistStore extends ChangeNotifier {
  UPlaylistStore._();

  static final UPlaylistStore instance = UPlaylistStore._();

  static const String _fileName = "u_media_playlists.json";

  final List<UPlaylist> _playlists = <UPlaylist>[];
  bool _loaded = false;

  List<UPlaylist> get playlists => List<UPlaylist>.unmodifiable(_playlists);

  Future<File> _file() async {
    final Directory directory = await getApplicationSupportDirectory();
    return File("${directory.path}${Platform.pathSeparator}$_fileName");
  }

  Future<void> load() async {
    if (_loaded || kIsWeb) return;
    _loaded = true;
    try {
      final String raw = await (await _file()).readAsString();
      final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
      _playlists
        ..clear()
        ..addAll(decoded.whereType<Map<String, Object?>>().map(UPlaylist.fromJson));
    } on FileSystemException {
      _playlists.clear();
    } on FormatException {
      _playlists.clear();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    if (kIsWeb) return;
    await (await _file()).writeAsString(jsonEncode(_playlists.map((UPlaylist p) => p.toJson()).toList(growable: false)), flush: true);
    notifyListeners();
  }

  Future<UPlaylist> create(String name, {List<String> paths = const <String>[]}) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final UPlaylist playlist = UPlaylist(id: UUUID.uuidV4(), name: name, paths: List<String>.of(paths), createdAt: now, updatedAt: now);
    _playlists.add(playlist);
    await _persist();
    return playlist;
  }

  Future<void> rename(String id, String name) async {
    final int index = _playlists.indexWhere((UPlaylist p) => p.id == id);
    if (index < 0) return;
    _playlists[index] = _playlists[index].copyWith(name: name);
    await _persist();
  }

  Future<void> delete(String id) async {
    _playlists.removeWhere((UPlaylist p) => p.id == id);
    await _persist();
  }

  Future<void> addTracks(String id, List<String> paths) async {
    final int index = _playlists.indexWhere((UPlaylist p) => p.id == id);
    if (index < 0) return;
    final List<String> next = List<String>.of(_playlists[index].paths);
    for (final String path in paths) {
      if (!next.contains(path)) next.add(path);
    }
    _playlists[index] = _playlists[index].copyWith(paths: next);
    await _persist();
  }

  Future<void> removeTrack(String id, String path) async {
    final int index = _playlists.indexWhere((UPlaylist p) => p.id == id);
    if (index < 0) return;
    final List<String> next = List<String>.of(_playlists[index].paths)..remove(path);
    _playlists[index] = _playlists[index].copyWith(paths: next);
    await _persist();
  }

  Future<void> reorder(String id, int from, int to) async {
    final int index = _playlists.indexWhere((UPlaylist p) => p.id == id);
    if (index < 0) return;
    final List<String> next = List<String>.of(_playlists[index].paths);
    if (from < 0 || from >= next.length || to < 0 || to >= next.length) return;
    next.insert(to, next.removeAt(from));
    _playlists[index] = _playlists[index].copyWith(paths: next);
    await _persist();
  }

  List<UTrackRecord> tracksOf(UPlaylist playlist) {
    final Map<String, UTrackRecord> byPath = <String, UTrackRecord>{for (final UTrackRecord record in UMediaLibrary.instance.tracks) record.path: record};
    return playlist.paths.map((String path) => byPath[path]).whereType<UTrackRecord>().toList(growable: false);
  }

  Future<File?> exportM3u(UPlaylist playlist, String directoryPath) async {
    if (kIsWeb) return null;
    final List<UPlaylistEntry> entries = tracksOf(playlist)
        .map((UTrackRecord record) => UPlaylistEntry(uri: record.path, title: record.title, artist: record.artist, duration: record.duration))
        .toList(growable: false);
    final File file = File("$directoryPath${Platform.pathSeparator}${playlist.name}.m3u");
    await file.writeAsString(UPlaylistParser.write(entries), flush: true);
    return file;
  }

  Future<UPlaylist?> importM3u(String path) async {
    if (kIsWeb) return null;
    try {
      final Uint8List bytes = await File(path).readAsBytes();
      final List<UPlaylistEntry> entries = UPlaylistParser.parse(UTextDecoder.decode(bytes).text);
      if (entries.isEmpty) return null;
      final String name = path.split(Platform.pathSeparator).last.replaceAll(RegExp(r"\.[^.]+$"), "");
      return await create(name, paths: entries.map((UPlaylistEntry e) => e.uri).toList(growable: false));
    } on FileSystemException {
      return null;
    }
  }
}

class UDownloadTask {
  UDownloadTask({
    required this.id,
    required this.url,
    required this.destination,
    this.headers = const <String, String>{},
    this.state = UDownloadState.queued,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.wifiOnly = false,
  });

  final String id;
  final String url;
  final String destination;
  final Map<String, String> headers;
  final bool wifiOnly;

  UDownloadState state;
  int receivedBytes;
  int totalBytes;
  String? error;

  double get progress => totalBytes <= 0 ? 0 : (receivedBytes / totalBytes).clamp(0, 1).toDouble();

  String get fileName => destination.split(Platform.pathSeparator).last;

  String get partPath => "$destination.part";

  Map<String, Object?> toJson() => <String, Object?>{
    "id": id,
    "url": url,
    "destination": destination,
    "headers": headers,
    "state": state.name,
    "receivedBytes": receivedBytes,
    "totalBytes": totalBytes,
    "wifiOnly": wifiOnly,
  };

  factory UDownloadTask.fromJson(Map<String, Object?> json) => UDownloadTask(
    id: (json["id"] as String?) ?? UUUID.uuidV4(),
    url: (json["url"] as String?) ?? "",
    destination: (json["destination"] as String?) ?? "",
    headers: <String, String>{...?(json["headers"] as Map<Object?, Object?>?)?.map((Object? k, Object? v) => MapEntry<String, String>("$k", "$v"))},
    state: UDownloadState.values.firstWhere((UDownloadState s) => s.name == json["state"], orElse: () => UDownloadState.queued),
    receivedBytes: (json["receivedBytes"] as int?) ?? 0,
    totalBytes: (json["totalBytes"] as int?) ?? 0,
    wifiOnly: json["wifiOnly"] == true,
  );
}

class UDownloadManager extends ChangeNotifier {
  UDownloadManager._();

  static final UDownloadManager instance = UDownloadManager._();

  static const String _fileName = "u_media_downloads.json";

  final List<UDownloadTask> _tasks = <UDownloadTask>[];
  final Map<String, StreamSubscription<List<int>>> _subscriptions = <String, StreamSubscription<List<int>>>{};
  final Set<String> _cancelling = <String>{};
  bool _loaded = false;
  int _maxConcurrent = 2;

  List<UDownloadTask> get tasks => List<UDownloadTask>.unmodifiable(_tasks);

  int get activeCount => _tasks.where((UDownloadTask t) => t.state == UDownloadState.running).length;

  set maxConcurrent(int value) => _maxConcurrent = value < 1 ? 1 : value;

  Future<File> _indexFile() async {
    final Directory directory = await getApplicationSupportDirectory();
    return File("${directory.path}${Platform.pathSeparator}$_fileName");
  }

  Future<Directory> defaultDirectory() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory directory = Directory("${base.path}${Platform.pathSeparator}downloads");
    if (!directory.existsSync()) await directory.create(recursive: true);
    return directory;
  }

  Future<void> load() async {
    if (_loaded || kIsWeb) return;
    _loaded = true;
    try {
      final String raw = await (await _indexFile()).readAsString();
      final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
      _tasks
        ..clear()
        ..addAll(decoded.whereType<Map<String, Object?>>().map(UDownloadTask.fromJson));
      for (final UDownloadTask task in _tasks) {
        if (task.state == UDownloadState.running) task.state = UDownloadState.paused;
      }
    } on FileSystemException {
      _tasks.clear();
    } on FormatException {
      _tasks.clear();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    if (kIsWeb) return;
    await (await _indexFile()).writeAsString(jsonEncode(_tasks.map((UDownloadTask t) => t.toJson()).toList(growable: false)), flush: true);
    notifyListeners();
  }

  Future<UDownloadTask?> enqueue(String url, {String? fileName, String? directoryPath, Map<String, String> headers = const <String, String>{}, bool wifiOnly = false, bool startNow = true}) async {
    if (kIsWeb) return null;
    final Directory directory = directoryPath == null ? await defaultDirectory() : Directory(directoryPath);
    final String name = fileName ?? Uri.parse(url).pathSegments.last;
    final UDownloadTask task = UDownloadTask(
      id: UUUID.uuidV4(),
      url: url,
      destination: "${directory.path}${Platform.pathSeparator}$name",
      headers: headers,
      wifiOnly: wifiOnly,
    );
    _tasks.add(task);
    await _persist();
    if (startNow) unawaited(_pump());
    return task;
  }

  Future<void> _pump() async {
    while (activeCount < _maxConcurrent) {
      final UDownloadTask? next = _tasks.cast<UDownloadTask?>().firstWhere(
        (UDownloadTask? t) => t != null && t.state == UDownloadState.queued,
        orElse: () => null,
      );
      if (next == null) return;
      unawaited(_run(next));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _run(UDownloadTask task) async {
    if (task.wifiOnly && !await UNetwork.hasWifi()) {
      task.state = UDownloadState.paused;
      task.error = U.s.waitingForWifi;
      await _persist();
      return;
    }

    task.state = UDownloadState.running;
    task.error = null;
    notifyListeners();

    final HttpClient client = HttpClient();
    IOSink? sink;
    try {
      final File partFile = File(task.partPath);
      final int existing = partFile.existsSync() ? await partFile.length() : 0;
      task.receivedBytes = existing;

      final HttpClientRequest request = await client.getUrl(Uri.parse(task.url));
      task.headers.forEach(request.headers.set);
      if (existing > 0) request.headers.set(HttpHeaders.rangeHeader, "bytes=$existing-");

      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.partialContent) {
        throw HttpException("HTTP ${response.statusCode}");
      }

      final bool resuming = response.statusCode == HttpStatus.partialContent;
      task.totalBytes = (resuming ? existing : 0) + (response.contentLength > 0 ? response.contentLength : 0);
      sink = partFile.openWrite(mode: resuming ? FileMode.append : FileMode.write);
      if (!resuming) task.receivedBytes = 0;

      final Completer<void> completer = Completer<void>();
      int sinceNotify = 0;
      _subscriptions[task.id] = response.listen(
        (List<int> chunk) {
          sink!.add(chunk);
          task.receivedBytes += chunk.length;
          sinceNotify += chunk.length;
          if (sinceNotify > 262144) {
            sinceNotify = 0;
            notifyListeners();
          }
        },
        onDone: completer.complete,
        onError: completer.completeError,
        cancelOnError: true,
      );

      await completer.future;
      await sink.flush();
      await sink.close();
      sink = null;
      await _subscriptions.remove(task.id)?.cancel();

      if (_cancelling.remove(task.id)) {
        task.state = UDownloadState.removed;
      } else {
        await partFile.rename(task.destination);
        task.state = UDownloadState.completed;
        task.totalBytes = task.receivedBytes;
      }
    } on Object catch (error) {
      task.error = error.toString();
      task.state = _cancelling.remove(task.id) ? UDownloadState.removed : (task.state == UDownloadState.paused ? UDownloadState.paused : UDownloadState.failed);
    } finally {
      await sink?.close();
      client.close(force: true);
      await _subscriptions.remove(task.id)?.cancel();
      await _persist();
      unawaited(_pump());
    }
  }

  Future<void> pause(String id) async {
    final UDownloadTask? task = _find(id);
    if (task == null || task.state != UDownloadState.running) return;
    task.state = UDownloadState.paused;
    await _subscriptions.remove(id)?.cancel();
    await _persist();
  }

  Future<void> resume(String id) async {
    final UDownloadTask? task = _find(id);
    if (task == null || task.state == UDownloadState.running || task.state == UDownloadState.completed) return;
    task.state = UDownloadState.queued;
    await _persist();
    unawaited(_pump());
  }

  Future<void> cancel(String id, {bool deleteFile = true}) async {
    final UDownloadTask? task = _find(id);
    if (task == null) return;
    _cancelling.add(id);
    await _subscriptions.remove(id)?.cancel();
    if (deleteFile) {
      final File part = File(task.partPath);
      if (part.existsSync()) await part.delete();
    }
    _tasks.remove(task);
    await _persist();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((UDownloadTask t) => t.state == UDownloadState.completed);
    await _persist();
  }

  UDownloadTask? _find(String id) {
    for (final UDownloadTask task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  void dispose() {
    for (final String id in _subscriptions.keys.toList()) {
      unawaited(_subscriptions.remove(id)?.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}
