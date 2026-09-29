import "package:u/utilities.dart";

/// Audio and video: native players, lock-screen session, subtitles, tags, streaming manifests,
/// the on-device music library and playlists. Wraps the engines in lib/plugins/media.
abstract final class UMedia {
  // --- Players ------------------------------------------------------------------------------

  /// Creates a video player; call `open(...)` on it, show it with UVideoView, dispose it when done.
  static UMediaController video({UMediaConfig config = const UMediaConfig()}) => UMediaController(config: config);

  /// Creates an audio player (no video surface).
  static UMediaController audio({UMediaConfig config = const UMediaConfig()}) => UMediaController(kind: UMediaKind.audio, config: config);

  /// Creates a player and starts playing [url] right away.
  static Future<UMediaController> playUrl(String url, {UMediaKind kind = UMediaKind.video, Map<String, String> headers = const <String, String>{}, UMediaConfig config = const UMediaConfig()}) async {
    final UMediaController controller = UMediaController(kind: kind, config: config);
    await controller.open(UMediaSource.network(url, headers: headers), autoPlay: true);
    return controller;
  }

  /// Creates a player and starts playing a local file.
  static Future<UMediaController> playFile(String path, {UMediaKind kind = UMediaKind.video, UMediaConfig config = const UMediaConfig()}) async {
    final UMediaController controller = UMediaController(kind: kind, config: config);
    await controller.open(UMediaSource.file(path), autoPlay: true);
    return controller;
  }

  /// True when this platform has the native player.
  static Future<bool> isAvailable() => UMediaChannel.isAvailable();

  // --- Sources ------------------------------------------------------------------------------

  /// A source from a URL (HLS, DASH, MP4, MP3, …), with optional headers, DRM and subtitles.
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
  }) => UMediaSource.network(
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

  /// A source from a file on disk.
  static UMediaSource file(String path, {String? id, UMediaMetadata? metadata, Duration? startPosition, Duration? endPosition, List<UExternalSubtitle> externalSubtitles = const <UExternalSubtitle>[]}) =>
      UMediaSource.file(path, id: id, metadata: metadata, startPosition: startPosition, endPosition: endPosition, externalSubtitles: externalSubtitles);

  /// A source from a Flutter asset.
  static UMediaSource asset(String assetPath, {String? id, UMediaMetadata? metadata, Duration? startPosition, Duration? endPosition}) =>
      UMediaSource.asset(assetPath, id: id, metadata: metadata, startPosition: startPosition, endPosition: endPosition);

  /// A source from bytes in memory.
  static UMediaSource bytes(Uint8List data, {String? id, String? mimeType, UMediaMetadata? metadata}) => UMediaSource.bytes(data, id: id, mimeType: mimeType, metadata: metadata);

  /// A source from an Android content:// URI.
  static UMediaSource content(String uri, {String? id, UMediaMetadata? metadata, Duration? startPosition}) => UMediaSource.content(uri, id: id, metadata: metadata, startPosition: startPosition);

  // --- Screens ------------------------------------------------------------------------------

  /// Plays a video in a full-height bottom sheet.
  static Future<void> showVideo({String? url, String? base64, Uint8List? bytes, String? filePath, String? assetPath, String? title, bool autoPlay = true}) =>
      UVideoSheet.show(url: url, base64: base64, bytes: bytes, filePath: filePath, assetPath: assetPath, title: title, autoPlay: autoPlay);

  /// Opens [controller] full screen (landscape by default).
  static Future<void> fullscreen(BuildContext context, UMediaController controller, {String? title, bool forceLandscape = true}) =>
      UVideoFullscreen.open(context, controller: controller, title: title, forceLandscape: forceLandscape);

  // --- Session (audio focus, lock screen) ---------------------------------------------------

  /// Pauses every player in the app.
  static Future<void> pauseAll() => UMediaSession.pauseAll();

  /// The player that currently owns audio focus.
  static UMediaController? get nowPlaying => UMediaSession.holder;

  /// Every live player.
  static List<UMediaController> get players => UMediaSession.controllers;

  /// Last playback position saved for [id] (for "continue watching").
  static Duration? resumePosition(String id) => UMediaResume.get(id);

  /// Saves the playback position of [id].
  static void saveResumePosition(String id, Duration position, Duration duration) => UMediaResume.save(id, position, duration);

  /// Forgets the saved position of [id].
  static void clearResumePosition(String id) => UMediaResume.clear(id);

  // --- Subtitles ----------------------------------------------------------------------------

  /// Parses subtitle text (SRT, VTT, ASS/SSA, LRC, MicroDVD; auto-detected).
  static USubtitleData parseSubtitles(String content, {USubtitleFormat? format, String? language, String? label, double fps = 23.976}) =>
      USubtitleParser.parse(content, format: format, language: language, label: label, fps: fps);

  /// Parses subtitle bytes, detecting the text encoding (UTF-8/16, Windows-1256, …).
  static USubtitleData parseSubtitleBytes(Uint8List bytes, {USubtitleFormat? format, String? encoding, String? language, String? label, double fps = 23.976}) =>
      USubtitleParser.parseBytes(bytes, format: format, encoding: encoding, language: language, label: label, fps: fps);

  /// Guesses the subtitle format of [content].
  static USubtitleFormat subtitleFormat(String content) => USubtitleParser.detectFormat(content);

  /// Decodes text bytes with automatic encoding detection.
  static UDecodedText decodeText(Uint8List bytes, {String? forced}) => UTextDecoder.decode(bytes, forced: forced);

  /// True when [text] is mostly right-to-left (Persian, Arabic, Hebrew).
  static bool isRtl(String text) => UBidi.isRtl(text);

  // --- Tags ---------------------------------------------------------------------------------

  /// Reads title, artist, album, artwork and duration from an audio file (MP3, FLAC, OGG, M4A, WAV).
  static Future<UMediaMetadata> readTags(String path) => UTagParser.readFile(path);

  // --- Streaming manifests and playlists -----------------------------------------------------

  /// True when [content] is an HLS (.m3u8) playlist.
  static bool isHls(String content) => UHlsParser.looksLikeHls(content);

  /// Parses an HLS playlist (variants, renditions, segments, keys).
  static UHlsPlaylist parseHls(String content, {String? baseUrl}) => UHlsParser.parse(content, baseUrl: baseUrl);

  /// Parses a DASH manifest (.mpd).
  static UDashManifest? parseDash(String content, {String? baseUrl}) => UDashParser.parse(content, baseUrl: baseUrl);

  /// Parses an M3U / PLS / XSPF playlist.
  static List<UPlaylistEntry> parsePlaylist(String content, {String? baseUri}) => UPlaylistParser.parse(content, baseUri: baseUri);

  /// Writes entries as an M3U playlist.
  static String writePlaylist(List<UPlaylistEntry> entries) => UPlaylistParser.write(entries);

  // --- Music library ------------------------------------------------------------------------

  /// The on-device music library (for listeners and advanced use).
  static UMediaLibrary get library => UMediaLibrary.instance;

  /// Loads the saved library index.
  static Future<void> loadLibrary() => UMediaLibrary.instance.load();

  /// Scans [folders] for audio files and indexes their tags.
  static Future<void> scanLibrary(List<String> folders, {bool replace = true, void Function(int scanned, int total)? onProgress}) =>
      UMediaLibrary.instance.scan(folders, replace: replace, onProgress: onProgress);

  /// Every indexed track.
  static List<UTrackRecord> get tracks => UMediaLibrary.instance.tracks;

  /// Tracks matching [query] (title, artist, album, …).
  static List<UTrackRecord> searchTracks(String query) => UMediaLibrary.instance.search(query);

  /// All album names.
  static List<String> get albums => UMediaLibrary.instance.albums;

  /// All artist names.
  static List<String> get artists => UMediaLibrary.instance.artists;

  /// Tracks of one album.
  static List<UTrackRecord> tracksOfAlbum(String album) => UMediaLibrary.instance.byAlbum(album);

  /// Tracks of one artist.
  static List<UTrackRecord> tracksOfArtist(String artist) => UMediaLibrary.instance.byArtist(artist);

  /// Favourite tracks.
  static List<UTrackRecord> get favoriteTracks => UMediaLibrary.instance.favoriteTracks;

  /// Most played tracks.
  static List<UTrackRecord> get mostPlayed => UMediaLibrary.instance.mostPlayed;

  /// Adds or removes a track from favourites.
  static void toggleFavorite(String path) => UMediaLibrary.instance.toggleFavorite(path);

  /// True when a track is a favourite.
  static bool isFavorite(String path) => UMediaLibrary.instance.isFavorite(path);

  // --- Playlists ----------------------------------------------------------------------------

  /// Saved playlists (for listeners and advanced use).
  static UPlaylistStore get playlistStore => UPlaylistStore.instance;

  /// Every saved playlist.
  static List<UPlaylist> get playlists => UPlaylistStore.instance.playlists;

  /// Creates a playlist.
  static Future<UPlaylist> createPlaylist(String name, {List<String> paths = const <String>[]}) => UPlaylistStore.instance.create(name, paths: paths);

  /// Renames a playlist.
  static Future<void> renamePlaylist(String id, String name) => UPlaylistStore.instance.rename(id, name);

  /// Deletes a playlist.
  static Future<void> deletePlaylist(String id) => UPlaylistStore.instance.delete(id);

  /// Adds tracks to a playlist.
  static Future<void> addToPlaylist(String id, List<String> paths) => UPlaylistStore.instance.addTracks(id, paths);

  /// Removes a track from a playlist.
  static Future<void> removeFromPlaylist(String id, String path) => UPlaylistStore.instance.removeTrack(id, path);

  /// Imports an .m3u file as a playlist.
  static Future<UPlaylist?> importPlaylist(String path) => UPlaylistStore.instance.importM3u(path);

  /// Exports a playlist as an .m3u file into [directoryPath].
  static Future<File?> exportPlaylist(UPlaylist playlist, String directoryPath) => UPlaylistStore.instance.exportM3u(playlist, directoryPath);
}
