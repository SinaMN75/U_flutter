import "package:u/utilities.dart";

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
