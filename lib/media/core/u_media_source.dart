import "package:u/utilities.dart";

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
