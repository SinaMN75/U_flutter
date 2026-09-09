import "package:u/utilities.dart";

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
