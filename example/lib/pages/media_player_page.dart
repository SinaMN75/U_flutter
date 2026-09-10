import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

const String _mp4Url = "https://docs.evostream.com/sample_content/assets/bun33s.mp4";
const String _hlsUrl = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8";
const String _audioUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
const String _audioUrl2 = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3";

const String _sampleSrt = """
1
00:00:01,000 --> 00:00:06,000
<i>Persian and English render from the same engine.</i>

2
00:00:06,000 --> 00:00:12,000
سلام دنیا — این یک زیرنویس راست‌به‌چپ است.

3
00:00:12,000 --> 00:00:20,000
{\\an8}Top-positioned cue via an ASS override tag.
""";

const String _sampleM3u8 = """
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720,CODECS="avc1.64001f,mp4a.40.2"
720p/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=640000,RESOLUTION=854x480,CODECS="avc1.4d401e,mp4a.40.2"
480p/index.m3u8
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",NAME="English",LANGUAGE="en",DEFAULT=YES,URI="audio/en.m3u8"
""";

class MediaPlayerPage extends StatefulWidget {
  const MediaPlayerPage({super.key});

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  final UMediaController _video = UMediaController(config: const UMediaConfig(autoPlay: false, subtitlesEnabled: true));
  final UVideoSettings _settings = UVideoSettings();
  final List<UVideoMarker> _markers = <UVideoMarker>[
    const UVideoMarker(start: Duration(seconds: 20), end: Duration(seconds: 35), label: "Intro", skippable: true),
    const UVideoMarker(start: Duration(seconds: 90), label: "Chapter 2"),
  ];

  String _parseOutput = "";
  String _tagOutput = "";
  bool _libraryScanning = false;

  @override
  void initState() {
    super.initState();
    unawaited(_video.open(UMediaSource.network(_mp4Url, metadata: const UMediaMetadata(title: "Big Buck Bunny", artist: "Blender Foundation"))));
  }

  @override
  void dispose() {
    _video.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "u_media",
    intro:
        "The native-first media engine: one controller for audio and video on all six platforms. "
        "Media3 on Android, AVFoundation on Apple, Media Foundation on Windows, GStreamer on Linux and "
        "HTMLVideoElement on web — containers, manifests, tags and subtitles are all parsed in Dart.",
    sections: <Widget>[
      _videoSection(),
      _fullscreenSection(),
      _subtitleSection(),
      _gestureSection(),
      _viewSection(),
      _audioSection(),
      _nowPlayingSection(),
      _queueSection(),
      _equalizerSection(),
      _visualizerSection(),
      _librarySection(),
      _downloadSection(),
      _tagSection(),
      _parserSection(),
      _sizeSection(),
    ],
  );

  DemoSection _videoSection() => DemoSection(
    title: "UVideo — the whole player",
    description:
        "Controls, gestures, subtitles, chapters, quality, PiP and fullscreen in one widget. "
        "The seek bar shows the yellow chapter markers passed in below.",
    code: r'''
final UMediaController controller = UMediaController();
await controller.open(UMediaSource.network(url));

UVideo(
  controller: controller,
  title: "Big Buck Bunny",
  markers: <UVideoMarker>[
    UVideoMarker(start: Duration(seconds: 20), end: Duration(seconds: 35), label: "Intro"),
  ],
)''',
    child: UVideo(controller: _video, settings: _settings, title: "Big Buck Bunny", markers: _markers, showQueueButton: true),
  );

  DemoSection _fullscreenSection() => DemoSection(
    title: "Fullscreen & sources",
    description: "Fullscreen reuses the same controller, so position, tracks and subtitles survive the transition. "
        "HLS resolves through the Dart manifest layer, which is what makes it work on Windows and macOS too.",
    code: r'''
await UVideoFullscreen.open(context, controller: controller);
await controller.open(UMediaSource.network(hlsUrl));''',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        UButton(type: UButtonType.outlined, title: "Fullscreen", onTap: () => unawaited(UVideoFullscreen.open(context, controller: _video, settings: _settings, title: "Big Buck Bunny", markers: _markers))),
        UButton(type: UButtonType.outlined, title: "Load MP4", onTap: () => unawaited(_video.open(UMediaSource.network(_mp4Url), autoPlay: true))),
        UButton(type: UButtonType.outlined, title: "Load HLS", onTap: () => unawaited(_video.open(UMediaSource.network(_hlsUrl), autoPlay: true))),
        UButton(type: UButtonType.outlined, title: "Picture in picture", onTap: () => unawaited(_video.enterPip())),
        UButton(type: UButtonType.outlined, title: "Screenshot", onTap: () => unawaited(_screenshot())),
      ],
    ),
  );

  DemoSection _subtitleSection() => DemoSection(
    title: "Subtitles — SRT, VTT, ASS, LRC",
    description:
        "Parsed and rendered by us in Flutter on every platform, so ASS styling, outlines and Persian RTL shaping "
        "look identical everywhere. Encoding is auto-detected, including Windows-1256 Persian files.",
    code: r'''
final USubtitleData data = USubtitleParser.parse(srtText);
await controller.loadSubtitleData(data);
controller.setSubtitleDelay(const Duration(milliseconds: -250));

// From a file or URL, parsed off the UI isolate:
await controller.loadSubtitle(UExternalSubtitle(uri: path, language: "fa"));''',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        UButton(
          type: UButtonType.outlined,
          title: "Load sample subtitles",
          onTap: () async {
            await _video.loadSubtitleData(USubtitleParser.parse(_sampleSrt));
            UToast.success(message: "3 cues loaded");
          },
        ),
        UButton(type: UButtonType.outlined, title: "Clear", onTap: _video.clearSubtitles),
        UButton(type: UButtonType.outlined, title: "Delay −0.5s", onTap: () => _settings.setSubtitleDelay(_video, _settings.subtitleDelay - const Duration(milliseconds: 500))),
        UButton(type: UButtonType.outlined, title: "Delay +0.5s", onTap: () => _settings.setSubtitleDelay(_video, _settings.subtitleDelay + const Duration(milliseconds: 500))),
        UButton(type: UButtonType.outlined, title: "Bigger", onTap: () => _settings.subtitleScale = _settings.subtitleScale + 0.15),
        UButton(type: UButtonType.outlined, title: "Smaller", onTap: () => _settings.subtitleScale = _settings.subtitleScale - 0.15),
      ],
    ),
  );

  DemoSection _gestureSection() => DemoSection(
    title: "Gestures",
    description: "All of these are live on the player above.",
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: const <Widget>[
        UTextBodySmall("• Double-tap left / right — seek ∓10s, tap again to accumulate to 20s, 30s"),
        UTextBodySmall("• Drag horizontally — scrub with a time preview"),
        UTextBodySmall("• Drag vertically, left half — brightness · right half — volume"),
        UTextBodySmall("• Long-press — 2× speed while held"),
        UTextBodySmall("• Pinch — zoom · single tap — toggle controls · swipe down — dismiss"),
        UTextBodySmall("• Keyboard — space, J/K/L, ←/→, ↑/↓, F, M, 0–9, [ and ]"),
      ],
    ),
  );

  DemoSection _viewSection() => DemoSection(
    title: "Aspect, rotation & colour filters",
    description: "Fit modes, rotation and mirroring are view-level. The colour filters are a single ColorFilter matrix, "
        "so brightness, contrast, saturation and hue cost nothing at runtime and work on every platform.",
    code: r'''
settings.fit = UMediaFit.cover;
settings.rotateQuarter();
settings.saturation = 1.4;
settings.hue = 25;''',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        UButton(type: UButtonType.outlined, title: "Cycle fit", onTap: _settings.cycleFit),
        UButton(type: UButtonType.outlined, title: "Rotate 90°", onTap: _settings.rotateQuarter),
        UButton(type: UButtonType.outlined, title: "Mirror", onTap: () => _settings.mirrored = !_settings.mirrored),
        UButton(type: UButtonType.outlined, title: "Warm", onTap: () => _settings..saturation = 1.4..hue = 20),
        UButton(type: UButtonType.outlined, title: "Cool", onTap: () => _settings..saturation = 0.9..hue = -25),
        UButton(type: UButtonType.outlined, title: "Reset", onTap: () => _settings..resetFilters()..resetView()),
        UButton(type: UButtonType.outlined, title: "Stats overlay", onTap: () => _settings.showStats = !_settings.showStats),
      ],
    ),
  );

  DemoSection _audioSection() => DemoSection(
    title: "UAudio — one line to play",
    description: "The music facade wraps the same engine with a music-tuned config: bigger buffers, background playback, "
        "no wake lock. The mini bar below is a drop-in widget.",
    code: r'''
await UAudio.play("https://example.com/song.mp3");
await UAudio.playQueue(<String>[a, b, c], startAt: 1);
UAudio.next(); UAudio.setRepeat(URepeatMode.all);''',
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            UButton(type: UButtonType.outlined, title: "Play track", onTap: () => unawaited(UAudio.play(UMediaSource.network(_audioUrl, metadata: const UMediaMetadata(title: "SoundHelix Song 1", artist: "T. Schürger"))))),
            UButton(type: UButtonType.outlined, title: "Play queue", onTap: () => unawaited(_playQueue())),
            UButton(type: UButtonType.outlined, title: "Pause", onTap: () => unawaited(UAudio.pause())),
            UButton(type: UButtonType.outlined, title: "Next", onTap: () => unawaited(UAudio.next())),
            UButton(type: UButtonType.outlined, title: "Shuffle", onTap: () => unawaited(UAudio.toggleShuffle())),
          ],
        ),
        UMiniPlayerBar(controller: UAudio.controller, onTap: () => UNavigator.bottomSheet(const SizedBox(height: 620, child: UMusicPlayer()))),
      ],
    ),
  );

  DemoSection _nowPlayingSection() => DemoSection(
    title: "Now playing screen",
    description: "Artwork, seek bar, transport, speed, sleep timer, equalizer and synced lyrics. "
        "Lyrics come from an embedded USLT tag, a sidecar .lrc file, or plain text.",
    code: r'''
UNavigator.bottomSheet(const UMusicPlayer());

final ULyrics lyrics = await ULyrics.load(source);
ULyricsView(controller: controller, lyrics: lyrics);''',
    child: UButton(type: UButtonType.elevated, title: "Open now playing", onTap: () => UNavigator.bottomSheet(const SizedBox(height: 620, child: UMusicPlayer()))),
  );

  DemoSection _queueSection() => DemoSection(
    title: "Queue, shuffle & repeat",
    description: "The queue is reorderable, shuffle keeps a stable order so turning it off restores the original sequence, "
        "and gapless preloads the next item only in the last few seconds.",
    code: r'''
UNavigator.bottomSheet(UMediaQueueSheet(controller: UAudio.controller));
await UAudio.playNext(source);
await UAudio.move(0, 2);''',
    child: UButton(type: UButtonType.outlined, title: "Open queue", onTap: () => UNavigator.bottomSheet(UMediaQueueSheet(controller: UAudio.controller))),
  );

  DemoSection _equalizerSection() => DemoSection(
    title: "Equalizer & audio effects",
    description: "Native equalizer bands, bass boost, virtualizer and loudness. Android reports the real device bands; "
        "platforms without an effects API report unavailable rather than faking it.",
    code: r'''
final UEqualizer equalizer = UEqualizer(UAudio.controller);
final UEqualizerState state = await equalizer.read();
await equalizer.setBand(0, 6.0);
await equalizer.setPreset("Rock");''',
    child: UButton(type: UButtonType.outlined, title: "Open equalizer", onTap: () => UNavigator.bottomSheet(UEqualizerSheet(controller: UAudio.controller))),
  );

  DemoSection _visualizerSection() => DemoSection(
    title: "Spectrum visualizer",
    description: "PCM is tapped straight out of the Media3 audio pipeline and FFT'd natively, so this needs no "
        "microphone permission — the platform Visualizer API would have required one.",
    code: r'''
UVisualizer(controller: UAudio.controller, style: UVisualizerStyle.mirroredBars)''',
    child: UVisualizer(controller: UAudio.controller, style: UVisualizerStyle.mirroredBars, height: 110),
  );

  DemoSection _librarySection() => DemoSection(
    title: "Music library",
    description: "Scans folders, reads tags with targeted file reads, and keeps a compact index. "
        "Search is Persian-normalized, so «کتاب» matches «كتاب» and diacritics are ignored.",
    code: r'''
await UMediaLibrary.instance.load();
await UMediaLibrary.instance.scan(<String>[musicFolder]);
final List<UTrackRecord> hits = UMediaLibrary.instance.search("شجریان");''',
    child: AnimatedBuilder(
      animation: UMediaLibrary.instance,
      builder: (BuildContext context, Widget? child) => UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: <Widget>[
          UTextBodySmall(
            _libraryScanning
                ? "Scanning ${UMediaLibrary.instance.scannedCount} / ${UMediaLibrary.instance.scanTotal}"
                : "${UMediaLibrary.instance.count} tracks · ${UMediaLibrary.instance.albums.length} albums · ${UMediaLibrary.instance.artists.length} artists",
          ),
          UButton(type: UButtonType.outlined, title: "Pick a folder and scan", onTap: () => unawaited(_scanLibrary())),
        ],
      ),
    ),
  );

  DemoSection _downloadSection() => DemoSection(
    title: "Offline downloads",
    description: "Range-request downloads that resume after a restart, with pause, cancel and a wifi-only guard.",
    code: r'''
await UDownloadManager.instance.load();
await UDownloadManager.instance.enqueue(url, wifiOnly: true);''',
    child: AnimatedBuilder(
      animation: UDownloadManager.instance,
      builder: (BuildContext context, Widget? child) => UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: <Widget>[
          UButton(type: UButtonType.outlined, title: "Download the sample track", onTap: () => unawaited(UDownloadManager.instance.enqueue(_audioUrl))),
          ...UDownloadManager.instance.tasks.map(
            (UDownloadTask task) => UColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UTextLabelSmall("${task.fileName} · ${task.state.name} · ${(task.progress * 100).toStringAsFixed(0)}%"),
                LinearProgressIndicator(value: task.progress),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  DemoSection _tagSection() => DemoSection(
    title: "Tag reader",
    description: "ID3v1/v2, Vorbis comments, MP4 atoms, FLAC blocks and WAV LIST — parsed in Dart with a bounds-checked "
        "reader, so a malformed tag throws instead of corrupting memory. Artwork is returned as an offset, never loaded.",
    code: r'''
final UMediaMetadata tags = await UTagParser.readFile(path);
UArtwork(artwork: tags.artwork, size: 72);''',
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        UButton(type: UButtonType.outlined, title: "Pick an audio file", onTap: () => unawaited(_readTags())),
        if (_tagOutput.isNotEmpty) UTextBodySmall(_tagOutput),
      ],
    ),
  );

  DemoSection _parserSection() => DemoSection(
    title: "Manifest & playlist parsers",
    description: "HLS, DASH, M3U, PLS and XSPF are parsed in Dart. This is what gives Windows and macOS adaptive "
        "streaming that their native stacks do not provide.",
    code: r'''
final UHlsPlaylist playlist = UHlsParser.parse(manifestText, baseUrl: url);
playlist.master!.bestUnder(720);
final UDashManifest? mpd = UDashParser.parse(xml);''',
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        UButton(type: UButtonType.outlined, title: "Parse a sample HLS manifest", onTap: _parseManifest),
        if (_parseOutput.isNotEmpty) UTextBodySmall(_parseOutput),
      ],
    ),
  );

  DemoSection _sizeSection() => const DemoSection(
    title: "Why it stays small",
    description: "Every OS already ships a hardware media stack, so we use it rather than bundling one. "
        "Containers, manifests, protocols, tags and subtitles are Dart; only pixel and PCM decoding go native.",
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        UTextBodySmall("Android — Media3 · about 2.5 MB of DEX, no bundled .so"),
        UTextBodySmall("iOS / macOS — AVFoundation · 0, plus 0.6 MB only if the Ogg codec pack is added"),
        UTextBodySmall("Windows — Media Foundation · about 0.35 MB"),
        UTextBodySmall("Linux — system GStreamer · 0"),
        UTextBodySmall("Web — HTMLVideoElement · 0"),
        UTextBodySmall("media_kit, for comparison, added about 40 MB."),
      ],
    ),
  );

  Future<void> _playQueue() async {
    await UAudio.playQueue(<Object>[
      UMediaSource.network(_audioUrl, metadata: const UMediaMetadata(title: "SoundHelix Song 1", artist: "T. Schürger", album: "Demo")),
      UMediaSource.network(_audioUrl2, metadata: const UMediaMetadata(title: "SoundHelix Song 2", artist: "T. Schürger", album: "Demo")),
    ]);
  }

  Future<void> _screenshot() async {
    final Uint8List? bytes = await _video.screenshot();
    if (!mounted) return;
    if (bytes == null) {
      UToast.warning(message: "No frame available for this source");
      return;
    }
    await UNavigator.dialog(Image.memory(bytes));
  }

  Future<void> _scanLibrary() async {
    final String? directory = await FilePicker.getDirectoryPath();
    if (directory == null) return;
    setState(() => _libraryScanning = true);
    await UMediaLibrary.instance.load();
    await UMediaLibrary.instance.scan(<String>[directory]);
    if (!mounted) return;
    setState(() => _libraryScanning = false);
    UToast.success(message: "${UMediaLibrary.instance.count} tracks indexed");
  }

  Future<void> _readTags() async {
    final List<PlatformFile>? picked = await FilePicker.pickFiles(type: FileType.audio);
    final String? path = picked?.single.path;
    if (path == null) return;
    final UMediaMetadata tags = await UTagParser.readFile(path);
    if (!mounted) return;
    setState(
      () => _tagOutput =
          "title: ${tags.title ?? "-"}\nartist: ${tags.artist ?? "-"}\nalbum: ${tags.album ?? "-"}\n"
          "year: ${tags.year ?? "-"} · track: ${tags.trackNumber ?? "-"} · genre: ${tags.genre ?? "-"}\n"
          "duration: ${tags.duration == null ? "-" : uFormatDuration(tags.duration!)}\n"
          "artwork: ${tags.artwork == null ? "none" : "${tags.artwork!.length} bytes at offset ${tags.artwork!.offset}"}",
    );
  }

  void _parseManifest() {
    final UHlsPlaylist playlist = UHlsParser.parse(_sampleM3u8, baseUrl: "https://cdn.example.com/stream/master.m3u8");
    final UHlsMasterPlaylist? master = playlist.master;
    if (master == null) return;
    setState(
      () => _parseOutput =
          "${master.variants.length} variants, ${master.renditions.length} renditions\n"
          "${master.variants.map((UHlsVariant v) => "${v.qualityLabel} @ ${(v.bandwidth / 1000).round()} kbps").join("\n")}\n"
          "best under 600p: ${master.bestUnder(600)?.qualityLabel ?? "-"}\n"
          "resolved: ${master.variants.first.url}",
    );
  }
}
