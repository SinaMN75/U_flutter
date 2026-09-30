import "package:u/utilities.dart";

// On-device music library index and saved playlists.

/// An indexed audio file with its tags and play stats.
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

  UArtworkRef? get artwork => artworkLength > 0 ? UArtworkRef.embedded(filePath: path, offset: artworkOffset, length: artworkLength, mimeType: artworkMime) : null;

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

/// Library sort: title, artist, album, date, plays.
enum ULibrarySort { title, artist, album, dateAdded, duration, year }

/// The on-device music library index (see UMedia).
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
          lines.where((String line) => line.trim().isNotEmpty).map((String line) => UTrackRecord.fromJson(jsonDecode(line) as Map<String, Object?>)),
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

/// A saved playlist.
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

/// Saved playlists (see UMedia).
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
    final List<UPlaylistEntry> entries = tracksOf(
      playlist,
    ).map((UTrackRecord record) => UPlaylistEntry(uri: record.path, title: record.title, artist: record.artist, duration: record.duration)).toList(growable: false);
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
