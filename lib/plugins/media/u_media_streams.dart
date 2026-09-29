import "package:u/utilities.dart";

// HLS, DASH and playlist (M3U, PLS, XSPF) parsers.

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
