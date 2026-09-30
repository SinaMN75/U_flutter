import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// UMedia, UAudio, USound, UCamera and UArExperiences.
class MediaCameraPage extends StatelessWidget {
  const MediaCameraPage({super.key});

  static const String _video = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8";
  static const String _mp3 = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
  static const String _mp3b = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3";
  static const String _glb = "https://modelviewer.dev/shared-assets/models/Astronaut.glb";
  static const String _srt = "1\n00:00:01,000 --> 00:00:03,000\nسلام دنیا\n\n2\n00:00:04,000 --> 00:00:06,000\nHello world\n";
  static const String _m3u8 = "#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360\nlow.m3u8\n#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1280x720\nhigh.m3u8\n";
  static const String _mpd =
      '<MPD xmlns="urn:mpeg:dash:schema:mpd:2011" type="static"><Period><AdaptationSet mimeType="video/mp4"><Representation id="1" bandwidth="800000" width="640" height="360"/></AdaptationSet></Period></MPD>';

  static Future<String?> _musicDir() async => kIsWeb ? null : (await getApplicationDocumentsDirectory()).path;

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Media, camera, AR",
    intro: "Native players on all 6 platforms (Linux needs GStreamer). Camera needs `permission add camera`, AR runs on Android (ARCore), iOS and web.",
    children: <Widget>[
      DemoGroup("Players", <Widget>[
        Fn("UMedia.isAvailable()", UMedia.isAvailable),
        Fn("UMedia.showVideo(url: …)", () => UMedia.showVideo(url: _video, title: "HLS stream")),
        Fn("UMedia.video() + open(UMedia.network(url)) + fullscreen", () async {
          final UMediaController c = UMedia.video();
          await c.open(UMedia.network(_video), autoPlay: true);
          if (context.mounted) {
            await UMedia.fullscreen(context, c, title: "Fullscreen");
          }
          c.dispose();
          return "closed";
        }),
        Fn("UMedia.audio()", () async {
          final UMediaController c = UMedia.audio();
          await c.open(UMedia.network(_mp3), autoPlay: true);
          await Future<void>.delayed(3.seconds);
          c.dispose();
          return "played 3 s";
        }),
        Fn("UMedia.playUrl(url, kind: audio)", () async {
          final UMediaController c = await UMedia.playUrl(_mp3, kind: UMediaKind.audio);
          await Future<void>.delayed(2.seconds);
          c.dispose();
          return "played 2 s";
        }),
        Fn("UMedia.playFile(path)", () async => kIsWeb ? "not on web" : (await UMedia.playFile("/does/not/exist.mp3", kind: UMediaKind.audio)).value.state),
        Fn(
          "UMedia.file / asset / bytes / content sources",
          () => <String>[
            UMedia.file("/a.mp4").runtimeType.toString(),
            UMedia.asset("assets/a.mp3").runtimeType.toString(),
            UMedia.bytes(Uint8List(0)).runtimeType.toString(),
            UMedia.content("content://x").runtimeType.toString(),
          ],
        ),
        Fn("UMedia.pauseAll()", UMedia.pauseAll),
        Fn("UMedia.nowPlaying / players", () => <Object?>[UMedia.nowPlaying?.value.state, UMedia.players.length]),
        Fn("UMedia.saveResumePosition / resumePosition / clearResumePosition", () {
          UMedia.saveResumePosition("movie-1", 42.seconds, 10.minutes);
          final Duration? at = UMedia.resumePosition("movie-1");
          UMedia.clearResumePosition("movie-1");
          return at;
        }),
      ]),
      DemoGroup("Subtitles, text, tags, streams", <Widget>[
        Fn("UMedia.parseSubtitles(srt)", () => UMedia.parseSubtitles(_srt).cues.map((USubtitleCue c) => c.text).toList(), auto: true),
        Fn("UMedia.parseSubtitleBytes(bytes)", () => UMedia.parseSubtitleBytes(Uint8List.fromList(utf8.encode(_srt))).cues.length),
        Fn("UMedia.subtitleFormat(srt)", () => UMedia.subtitleFormat(_srt), auto: true),
        Fn("UMedia.decodeText(bytes)", () => UMedia.decodeText(Uint8List.fromList(utf8.encode("سلام"))).text),
        Fn('UMedia.isRtl("سلام دنیا")', () => UMedia.isRtl("سلام دنیا"), auto: true),
        Fn("UMedia.readTags(path)", () => UMedia.readTags("/does/not/exist.mp3"), note: "Not on web"),
        Fn("UMedia.isHls / parseHls", () => <Object>[UMedia.isHls(_m3u8), UMedia.parseHls(_m3u8, baseUrl: "https://x.com/").runtimeType]),
        Fn("UMedia.parseDash(mpd)", () => UMedia.parseDash(_mpd)?.periods.length),
        Fn("UMedia.parsePlaylist / writePlaylist", () => UMedia.writePlaylist(UMedia.parsePlaylist("#EXTM3U\n#EXTINF:120,Song\nsong.mp3\n"))),
      ]),
      DemoGroup("Music library & playlists", <Widget>[
        Fn("UMedia.loadLibrary()", UMedia.loadLibrary),
        Fn("UMedia.scanLibrary([dir])", () async {
          final String? dir = await _musicDir();
          if (dir == null) return "not on web";
          await UMedia.scanLibrary(<String>[dir]);
          return UMedia.tracks.length;
        }, note: "Android: `permission add music`"),
        Fn("UMedia.library / tracks / albums / artists", () => <Object>[UMedia.library.runtimeType, UMedia.tracks.length, UMedia.albums, UMedia.artists]),
        Fn('UMedia.searchTracks("song")', () => UMedia.searchTracks("song").length),
        Fn("UMedia.tracksOfAlbum / tracksOfArtist", () => <int>[UMedia.tracksOfAlbum("x").length, UMedia.tracksOfArtist("x").length]),
        Fn("UMedia.favoriteTracks / mostPlayed", () => <int>[UMedia.favoriteTracks.length, UMedia.mostPlayed.length]),
        Fn("UMedia.toggleFavorite / isFavorite", () {
          UMedia.toggleFavorite("/a.mp3");
          final bool fav = UMedia.isFavorite("/a.mp3");
          UMedia.toggleFavorite("/a.mp3");
          return fav;
        }),
        Fn("UMedia.createPlaylist / rename / add / remove / delete", () async {
          final UPlaylist p = await UMedia.createPlaylist("Road trip");
          await UMedia.renamePlaylist(p.id, "Road trip 2");
          await UMedia.addToPlaylist(p.id, <String>["/a.mp3"]);
          await UMedia.removeFromPlaylist(p.id, "/a.mp3");
          final int count = UMedia.playlists.length;
          await UMedia.deletePlaylist(p.id);
          return "had $count playlists (store: ${UMedia.playlistStore.runtimeType})";
        }),
        Fn("UMedia.exportPlaylist / importPlaylist", () async {
          final String? dir = await _musicDir();
          if (dir == null) return "not on web";
          final UPlaylist p = await UMedia.createPlaylist("Export me", paths: <String>["/a.mp3"]);
          final File? file = await UMedia.exportPlaylist(p, dir);
          final UPlaylist? back = file == null ? null : await UMedia.importPlaylist(file.path);
          await UMedia.deletePlaylist(p.id);
          if (back != null) await UMedia.deletePlaylist(back.id);
          return back?.name;
        }),
      ]),
      DemoGroup("UAudio (one app-wide player)", <Widget>[
        Fn(
          "UAudio.play(url, metadata: …)",
          () => UAudio.play(
            _mp3,
            metadata: const UMediaMetadata(title: "SoundHelix 1", artist: "SoundHelix"),
          ),
        ),
        Fn("UAudio.playQueue([a, b])", () => UAudio.playQueue(<Object>[_mp3, _mp3b])),
        Fn("UAudio.pause() / resume() / toggle()", () async {
          await UAudio.pause();
          await UAudio.resume();
          await UAudio.toggle();
          return UAudio.isPlaying;
        }),
        Fn("UAudio.next() / previous() / jumpTo(0)", () async {
          await UAudio.next();
          await UAudio.previous();
          await UAudio.jumpTo(0);
          return UAudio.currentIndex;
        }),
        Fn("UAudio.seek(30.seconds) / seekBy(-10.seconds)", () async {
          await UAudio.seek(30.seconds);
          await UAudio.seekBy(-10.seconds);
          return UAudio.position;
        }),
        Fn("UAudio.add / playNext / move / removeAt", () async {
          await UAudio.add(_mp3b);
          await UAudio.playNext(_mp3);
          await UAudio.move(0, 1);
          await UAudio.removeAt(UAudio.queue.length - 1);
          return UAudio.queue.length;
        }),
        Fn("UAudio.setSpeed / setVolume / setMuted", () async {
          await UAudio.setSpeed(1.25);
          await UAudio.setVolume(0.8);
          await UAudio.setMuted(false);
          return UAudio.value.speed;
        }),
        Fn("UAudio.setRepeat / setShuffle / toggleShuffle", () async {
          await UAudio.setRepeat(URepeatMode.all);
          await UAudio.setShuffle(true);
          await UAudio.toggleShuffle();
          return "ok";
        }),
        Fn(
          "UAudio.notification(metadata: …)",
          () => UAudio.notification(
            metadata: const UMediaMetadata(title: "Now playing", artist: "u"),
          ),
        ),
        Fn("UAudio.state / value / nowPlaying / duration", () => <Object?>[UAudio.state.value.state, UAudio.value.position, UAudio.nowPlaying?.title, UAudio.duration]),
        Fn("UAudio.positionStream", () => UAudio.positionStream),
        Fn("UAudio.stateStream", () => UAudio.stateStream),
        Fn("UAudio.controller / source(url)", () => <Object>[UAudio.controller.runtimeType, UAudio.source(_mp3).runtimeType]),
        Fn("UAudio.scanFolder(dir) / playFolder(dir)", () async {
          final String? dir = await _musicDir();
          if (dir == null) return "not on web";
          final List<UMediaSource> found = await UAudio.scanFolder(dir);
          if (found.isNotEmpty) await UAudio.playFolder(dir);
          return found.length;
        }),
        Fn("UAudio.readTags(path)", () => UAudio.readTags("/does/not/exist.mp3")),
        Fn("UAudio.stop()", UAudio.stop),
        Fn("USound.preload([...]) / resolve", () async {
          await USound.preload(<Object>[_mp3]);
          return USound.resolve(_mp3).runtimeType;
        }),
        Fn("USound.play(url, volume: 0.3)", () => USound.play(_mp3, volume: 0.3)),
        Fn("USound.stopAll()", USound.stopAll),
      ]),
      DemoGroup("Camera & scanning", <Widget>[
        Fn("await UCamera.isSupported()", UCamera.isSupported),
        Fn("await UCamera.permission()", UCamera.permission),
        Fn("await UCamera.requestPermission()", UCamera.requestPermission),
        Fn("UCamera.openSettings()", UCamera.openSettings),
        Fn("await UCamera.devices()", UCamera.devices),
        Fn("await UCamera.open()", () async => (await UCamera.open()).length),
        Fn("await UCamera.takePhoto()", () async => (await UCamera.takePhoto())?.name),
        Fn("await UCamera.takePhotos(maxCount: 2)", () async => (await UCamera.takePhotos(maxCount: 2)).length),
        Fn("await UCamera.recordVideo()", () async => (await UCamera.recordVideo())?.name, note: "Needs `permission add microphone` too"),
        Fn("await UCamera.scan()", UCamera.scan),
        Fn("await UCamera.scanCode()", () async => (await UCamera.scanCode())?.text),
        Fn("await UCamera.scanImage(bytes: QR png)", () async {
          final Uint8List? png = await UBarcode.toPng(value: "u-example", width: 300, height: 300);
          return png == null ? "no png" : (await UCamera.scanImage(bytes: png)).map((UCode c) => c.text).toList();
        }),
        Fn("UCamera.decodePixels(rgba, w, h)", () => UCamera.decodePixels(Uint8List(4 * 16 * 16), 16, 16).length),
        Fn("UCamera.controller()", () {
          final UCameraController c = UCamera.controller();
          c.dispose();
          return "created";
        }),
      ]),
      DemoGroup("AR", <Widget>[
        Fn("await UArExperiences.availability()", UArExperiences.availability),
        Fn("await UArExperiences.capabilities()", UArExperiences.capabilities),
        Fn("await UArExperiences.isSupported()", UArExperiences.isSupported),
        Fn("UArExperiences.requestInstall()", UArExperiences.requestInstall, note: "Android"),
        Fn("await UArExperiences.permission()", UArExperiences.permission),
        Fn("UArExperiences.requestPermission()", UArExperiences.requestPermission),
        Fn("UArExperiences.openSettings()", UArExperiences.openSettings),
        Fn(
          "UArExperiences.place(items: …)",
          () => UArExperiences.place(
            items: <UArPlaceable>[UArPlaceable(id: "astronaut", title: "Astronaut", source: UArSource.url(_glb))],
          ),
        ),
        Fn("UArExperiences.viewProduct(source: …)", () => UArExperiences.viewProduct(source: UArSource.url(_glb), title: "Astronaut")),
        Fn("UArExperiences.measure()", UArExperiences.measure),
        Fn(
          "UArExperiences.tryOn(items: …)",
          () => UArExperiences.tryOn(
            items: <UArTryOnItem>[UArTryOnItem(id: "a", title: "Astronaut", source: UArSource.url(_glb))],
          ),
        ),
        Fn(
          "UArExperiences.images(targets: …)",
          () => UArExperiences.images(
            targets: <UArImageTarget>[UArImageTarget(name: "poster", source: UArSource.url("https://picsum.photos/400"))],
          ),
        ),
        Fn(
          "UArExperiences.places(places: …)",
          () => UArExperiences.places(
            places: const <UArPlace>[UArPlace(id: "azadi", latitude: 35.6997, longitude: 51.3380, title: "Azadi Tower")],
          ),
        ),
        Fn("UArExperiences.codes(cardBuilder: …)", () => UArExperiences.codes(cardBuilder: (BuildContext c, String code, UArProjection p) => UPill(code))),
        Fn("UArExperiences.scanRoom()", UArExperiences.scanRoom, note: "iOS LiDAR"),
        Fn("UArExperiences.captureObject()", UArExperiences.captureObject, note: "iOS 17+ LiDAR"),
        Fn("UArExperiences.openNativeViewer(…)", () => UArExperiences.openNativeViewer(UArNativeViewerOptions(source: UArSource.url(_glb), title: "Astronaut"))),
        Fn("UArExperiences.renderWidget(widget)", () async => (await UArExperiences.renderWidget(const UPill("AR label")))?.length.toBKMG()),
      ]),
    ],
  );
}
