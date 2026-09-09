import "package:u/utilities.dart";

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
