

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
