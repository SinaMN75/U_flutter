import "package:u/utilities.dart";

/// Native audio/video players on all 6 platforms (ExoPlayer, AVPlayer, Media Foundation, GStreamer, HTML5), plus subtitles, tags, HLS/DASH parsing, music library and playlists. `final c = await UMedia.playUrl(url);`
abstract final class UMedia {
  // --- Players ------------------------------------------------------------------------------

  /// New video player; call open(), show it with UVideoView, dispose() when done. `final c = UMedia.video(); await c.open(UMedia.network(url));`
  static UMediaController video({UMediaConfig config = const UMediaConfig()}) => UMediaController(config: config);

  /// New audio-only player (no video surface). `final c = UMedia.audio();`
  static UMediaController audio({UMediaConfig config = const UMediaConfig()}) => UMediaController(kind: UMediaKind.audio, config: config);

  /// New player that starts [url] right away (HLS, DASH, MP4, MP3…). `final c = await UMedia.playUrl("https://x.com/a.m3u8")`
  static Future<UMediaController> playUrl(String url, {UMediaKind kind = UMediaKind.video, Map<String, String> headers = const <String, String>{}, UMediaConfig config = const UMediaConfig()}) async {
    final UMediaController controller = UMediaController(kind: kind, config: config);
    await controller.open(UMediaSource.network(url, headers: headers), autoPlay: true);
    return controller;
  }

  /// New player that starts a local file right away (not on web). `await UMedia.playFile("/path/song.mp3")`
  static Future<UMediaController> playFile(String path, {UMediaKind kind = UMediaKind.video, UMediaConfig config = const UMediaConfig()}) async {
    final UMediaController controller = UMediaController(kind: kind, config: config);
    await controller.open(UMediaSource.file(path), autoPlay: true);
    return controller;
  }

  /// True when the native player works on this platform (Linux needs GStreamer installed).
  static Future<bool> isAvailable() => UMediaChannel.isAvailable();

  // --- Sources ------------------------------------------------------------------------------

  /// A source from a URL with optional headers, DRM (Widevine/FairPlay) and subtitles. `UMedia.network(url, headers: {"Authorization": token})`
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

  /// A source from a file path.
  static UMediaSource file(
    String path, {
    String? id,
    UMediaMetadata? metadata,
    Duration? startPosition,
    Duration? endPosition,
    List<UExternalSubtitle> externalSubtitles = const <UExternalSubtitle>[],
  }) => UMediaSource.file(path, id: id, metadata: metadata, startPosition: startPosition, endPosition: endPosition, externalSubtitles: externalSubtitles);

  /// A source from a Flutter asset. `UMedia.asset("assets/intro.mp4")`
  static UMediaSource asset(String assetPath, {String? id, UMediaMetadata? metadata, Duration? startPosition, Duration? endPosition}) =>
      UMediaSource.asset(assetPath, id: id, metadata: metadata, startPosition: startPosition, endPosition: endPosition);

  /// A source from bytes in memory (written to a temp file on native).
  static UMediaSource bytes(Uint8List data, {String? id, String? mimeType, UMediaMetadata? metadata}) => UMediaSource.bytes(data, id: id, mimeType: mimeType, metadata: metadata);

  /// A source from an Android content:// URI (e.g. from the file picker).
  static UMediaSource content(String uri, {String? id, UMediaMetadata? metadata, Duration? startPosition}) => UMediaSource.content(uri, id: id, metadata: metadata, startPosition: startPosition);

  /// A UFileStorage entry (encrypted vault by default), streamed privately; no plaintext file is written. Native only. `UMedia.vault("course.mp4")`
  static UMediaSource vault(String key, {UStorageBucket bucket = UStorageBucket.vault, String? mimeType, String? id, UMediaMetadata? metadata, Duration? startPosition}) =>
      UMediaSource.vault(key, bucket: bucket, mimeType: mimeType, id: id, metadata: metadata, startPosition: startPosition);

  // --- Screens ------------------------------------------------------------------------------

  /// Plays a video in a tall bottom sheet with full controls; give one of url/bytes/base64/filePath/assetPath. `UMedia.showVideo(url: url, title: "Intro")`
  static Future<void> showVideo({String? url, String? base64, Uint8List? bytes, String? filePath, String? assetPath, String? title, bool autoPlay = true}) =>
      UVideoSheet.show(url: url, base64: base64, bytes: bytes, filePath: filePath, assetPath: assetPath, title: title, autoPlay: autoPlay);

  /// Shows [controller] full screen (landscape by default). `UMedia.fullscreen(context, controller)`
  static Future<void> fullscreen(BuildContext context, UMediaController controller, {String? title, bool forceLandscape = true}) =>
      UVideoFullscreen.open(context, controller: controller, title: title, forceLandscape: forceLandscape);

  // --- Session (audio focus, lock screen) ---------------------------------------------------

  /// Pauses every player (e.g. when a call starts).
  static Future<void> pauseAll() => UMediaSession.pauseAll();

  /// The player that currently has audio focus, or null.
  static UMediaController? get nowPlaying => UMediaSession.holder;

  /// Every live player.
  static List<UMediaController> get players => UMediaSession.controllers;

  /// Saved "continue watching" position for [id], or null. `c.seek(UMedia.resumePosition(videoId) ?? Duration.zero)`
  static Duration? resumePosition(String id) => UMediaResume.get(id);

  /// Saves the playback position for [id] (cleared near the end).
  static void saveResumePosition(String id, Duration position, Duration duration) => UMediaResume.save(id, position, duration);

  /// Forgets the saved position of [id].
  static void clearResumePosition(String id) => UMediaResume.clear(id);

  // --- Subtitles ----------------------------------------------------------------------------

  /// Parses subtitle text (SRT, VTT, ASS/SSA, LRC, MicroDVD; auto-detected). `UMedia.parseSubtitles(srtText)`
  static USubtitleData parseSubtitles(String content, {USubtitleFormat? format, String? language, String? label, double fps = 23.976}) =>
      USubtitleParser.parse(content, format: format, language: language, label: label, fps: fps);

  /// Parses subtitle bytes and fixes the encoding (UTF-8/16, Windows-1256 Persian…). `UMedia.parseSubtitleBytes(bytes)`
  static USubtitleData parseSubtitleBytes(Uint8List bytes, {USubtitleFormat? format, String? encoding, String? language, String? label, double fps = 23.976}) =>
      USubtitleParser.parseBytes(bytes, format: format, encoding: encoding, language: language, label: label, fps: fps);

  /// Guesses the subtitle format of [content].
  static USubtitleFormat subtitleFormat(String content) => USubtitleParser.detectFormat(content);

  /// Decodes text bytes, detecting the encoding (handles old Persian Windows-1256 files).
  static UDecodedText decodeText(Uint8List bytes, {String? forced}) => UTextDecoder.decode(bytes, forced: forced);

  /// True when [text] is mostly right-to-left (Persian, Arabic, Hebrew).
  static bool isRtl(String text) => UBidi.isRtl(text);

  // --- Tags ---------------------------------------------------------------------------------

  /// Title, artist, album, artwork and duration from an audio file (MP3, FLAC, OGG, M4A, WAV); not on web. `(await UMedia.readTags(path)).title`
  static Future<UMediaMetadata> readTags(String path) => UTagParser.readFile(path);

  // --- Streaming manifests and playlists -----------------------------------------------------

  /// True when [content] is an HLS (.m3u8) playlist.
  static bool isHls(String content) => UHlsParser.looksLikeHls(content);

  /// Parses an HLS playlist: qualities, audio/subtitle tracks, segments, keys.
  static UHlsPlaylist parseHls(String content, {String? baseUrl}) => UHlsParser.parse(content, baseUrl: baseUrl);

  /// Parses a DASH manifest (.mpd).
  static UDashManifest? parseDash(String content, {String? baseUrl}) => UDashParser.parse(content, baseUrl: baseUrl);

  /// Parses M3U / PLS / XSPF playlist text.
  static List<UPlaylistEntry> parsePlaylist(String content, {String? baseUri}) => UPlaylistParser.parse(content, baseUri: baseUri);

  /// Writes entries as M3U text.
  static String writePlaylist(List<UPlaylistEntry> entries) => UPlaylistParser.write(entries);

  // --- Music library ------------------------------------------------------------------------

  /// The on-device music library object (listeners, advanced use).
  static UMediaLibrary get library => UMediaLibrary.instance;

  /// Loads the saved library index from disk.
  static Future<void> loadLibrary() => UMediaLibrary.instance.load();

  /// Scans [folders] for audio and indexes their tags (not on web). Android: `permission add music`. `await UMedia.scanLibrary(["/storage/emulated/0/Music"])`
  static Future<void> scanLibrary(List<String> folders, {bool replace = true, void Function(int scanned, int total)? onProgress}) =>
      UMediaLibrary.instance.scan(folders, replace: replace, onProgress: onProgress);

  /// Every indexed track.
  static List<UTrackRecord> get tracks => UMediaLibrary.instance.tracks;

  /// Tracks whose title, artist or album match [query]. `UMedia.searchTracks("shajarian")`
  static List<UTrackRecord> searchTracks(String query) => UMediaLibrary.instance.search(query);

  /// Every album name.
  static List<String> get albums => UMediaLibrary.instance.albums;

  /// Every artist name.
  static List<String> get artists => UMediaLibrary.instance.artists;

  /// Tracks of one album.
  static List<UTrackRecord> tracksOfAlbum(String album) => UMediaLibrary.instance.byAlbum(album);

  /// Tracks of one artist.
  static List<UTrackRecord> tracksOfArtist(String artist) => UMediaLibrary.instance.byArtist(artist);

  /// Favourite tracks.
  static List<UTrackRecord> get favoriteTracks => UMediaLibrary.instance.favoriteTracks;

  /// Most played tracks.
  static List<UTrackRecord> get mostPlayed => UMediaLibrary.instance.mostPlayed;

  /// Adds/removes a track from favourites.
  static void toggleFavorite(String path) => UMediaLibrary.instance.toggleFavorite(path);

  /// True when a track is a favourite.
  static bool isFavorite(String path) => UMediaLibrary.instance.isFavorite(path);

  // --- Playlists ----------------------------------------------------------------------------

  /// Saved playlists object (listeners, advanced use).
  static UPlaylistStore get playlistStore => UPlaylistStore.instance;

  /// Every saved playlist.
  static List<UPlaylist> get playlists => UPlaylistStore.instance.playlists;

  /// Creates a playlist, optionally with tracks. `await UMedia.createPlaylist("Road trip")`
  static Future<UPlaylist> createPlaylist(String name, {List<String> paths = const <String>[]}) => UPlaylistStore.instance.create(name, paths: paths);

  /// Renames a playlist.
  static Future<void> renamePlaylist(String id, String name) => UPlaylistStore.instance.rename(id, name);

  /// Deletes a playlist.
  static Future<void> deletePlaylist(String id) => UPlaylistStore.instance.delete(id);

  /// Adds tracks (file paths) to a playlist.
  static Future<void> addToPlaylist(String id, List<String> paths) => UPlaylistStore.instance.addTracks(id, paths);

  /// Removes one track from a playlist.
  static Future<void> removeFromPlaylist(String id, String path) => UPlaylistStore.instance.removeTrack(id, path);

  /// Imports an .m3u file as a playlist.
  static Future<UPlaylist?> importPlaylist(String path) => UPlaylistStore.instance.importM3u(path);

  /// Writes a playlist as .m3u into [directoryPath].
  static Future<File?> exportPlaylist(UPlaylist playlist, String directoryPath) => UPlaylistStore.instance.exportM3u(playlist, directoryPath);
}
