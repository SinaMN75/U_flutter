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
