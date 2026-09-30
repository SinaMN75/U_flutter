import "package:u/utilities.dart";

const String _mp4Url = "https://docs.evostream.com/sample_content/assets/bun33s.mp4";
const String _longMp4Url = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
const String _hlsUrl = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8";

/// SinApp's previous video-notes payload (base64 of this JSON).
const String _legacyNotes = '{"markers":[{"color":4294198070,"type":"text","text":"معرفی شخصیت اصلی","seconds":4},{"color":4280391411,"type":"text","text":"نکته‌ی مهم برای امتحان","seconds":15}]}';

/// A course-style player: video + time-stamped notes side by side (stacked on phones).
class VideoNotesPage extends StatefulWidget {
  const VideoNotesPage({super.key});

  @override
  State<VideoNotesPage> createState() => _VideoNotesPageState();
}

class _VideoNotesPageState extends State<VideoNotesPage> {
  final UMediaController _controller = UMediaController(config: const UMediaConfig(subtitlesEnabled: true));
  final UVideoSettings _settings = UVideoSettings();
  late final UMediaNotesController _notes = UMediaNotesController(storageKey: "demo_video_notes", onChanged: (UMediaNotesController notes) => setState(() => _payload = notes.export()));

  String _source = _mp4Url;
  bool _watermark = true;
  bool _secure = false;
  bool _autoPip = true;
  String _payload = "";

  @override
  void initState() {
    super.initState();
    unawaited(_notes.load());
    unawaited(_open());
  }

  Future<void> _open() => _controller.open(
    UMediaSource.network(
      _source,
      metadata: const UMediaMetadata(title: "Big Buck Bunny", artist: "Blender Foundation"),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    _settings.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: const UTextTitleLarge("Video course player", fontWeight: FontWeight.w700),
      actions: <Widget>[
        PopupMenuButton<String>(
          icon: const Icon(Icons.tune_rounded),
          onSelected: (String value) {
            if (value == "legacy") {
              _notes.import(_legacyNotes.toBase64(), merge: true);
              return;
            }
            setState(() => _source = value);
            unawaited(_open());
          },
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: _mp4Url, child: Text("Short MP4 (33 s)")),
            PopupMenuItem<String>(value: _longMp4Url, child: Text("Long MP4 (10 min)")),
            PopupMenuItem<String>(value: _hlsUrl, child: Text("HLS stream (.m3u8)")),
            PopupMenuDivider(),
            PopupMenuItem<String>(value: "legacy", child: Text("Import SinApp legacy notes")),
          ],
        ),
      ],
    ),
    body: Column(
      children: <Widget>[
        Expanded(
          child: UVideoWithNotes(
            controller: _controller,
            notes: _notes,
            settings: _settings,
            title: "Big Buck Bunny",
            watermark: _watermark ? const UDocWatermark(lines: <String>["کاربر نمونه", "0900 000 0000"], opacity: 0.35, color: Color(0xFFFFFFFF), fontSize: 13) : null,
            secure: _secure,
            autoPip: _autoPip,
            resumeKey: _source,
          ),
        ),
        Material(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilterChip(label: const Text("Watermark"), selected: _watermark, onSelected: (bool value) => setState(() => _watermark = value)),
                FilterChip(label: const Text("Secure"), selected: _secure, onSelected: (bool value) => setState(() => _secure = value)),
                FilterChip(label: const Text("Auto PiP"), selected: _autoPip, onSelected: (bool value) => setState(() => _autoPip = value)),
                const UTextLabelSmall("✎ in the player pauses and draws on the frame; drawings show for the chosen time and are saved with the notes."),
                if (_payload.isNotEmpty) UTextLabelSmall("sync payload: ${_payload.length} chars"),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
