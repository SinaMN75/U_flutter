import "package:u/utilities.dart";

const String _lectureUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3";

/// Voice / lecture player: ±15 s, fine speed, resume, timestamp notes with seek-bar markers.
class AudioNotesPage extends StatefulWidget {
  const AudioNotesPage({super.key});

  @override
  State<AudioNotesPage> createState() => _AudioNotesPageState();
}

class _AudioNotesPageState extends State<AudioNotesPage> {
  final UMediaController _controller = UMediaController(kind: UMediaKind.audio, config: UMediaConfig.music);
  final UMediaNotesController _notes = UMediaNotesController(storageKey: "demo_audio_notes");

  @override
  void initState() {
    super.initState();
    unawaited(_notes.load());
    unawaited(_controller.open(UMediaSource.network(_lectureUrl, metadata: const UMediaMetadata(title: "Lecture 3", artist: "SoundHelix"))));
  }

  @override
  void dispose() {
    _controller.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: const UTextTitleLarge("Audio lecture", fontWeight: FontWeight.w700)),
    body: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget player = UMusicPlayer(
          controller: _controller,
          notes: _notes,
          resumeKey: _lectureUrl,
          theme: const UMusicPlayerTheme(showShuffle: false, showRepeat: false, showQueue: false, showLyrics: false, showEqualizer: false),
        );
        final Widget panel = UMediaNotesPanel(notes: _notes, controller: _controller);
        if (constraints.maxWidth >= 860) {
          return Row(children: <Widget>[Expanded(child: player), SizedBox(width: 360, child: panel)]);
        }
        return Column(children: <Widget>[SizedBox(height: constraints.maxHeight * 0.58, child: player), Expanded(child: panel)]);
      },
    ),
  );
}
