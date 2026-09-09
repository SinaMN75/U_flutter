import "package:u/utilities.dart";

class ULyrics {
  const ULyrics({required this.lines, this.synced = false, this.source});

  final List<USubtitleCue> lines;
  final bool synced;
  final String? source;

  static const ULyrics empty = ULyrics(lines: <USubtitleCue>[]);

  bool get isEmpty => lines.isEmpty;

  String get plainText => lines.map((USubtitleCue cue) => cue.text).join("\n");

  int indexAt(Duration position) {
    if (!synced || lines.isEmpty) return -1;
    int low = 0;
    int high = lines.length - 1;
    int found = -1;
    while (low <= high) {
      final int mid = (low + high) >> 1;
      if (lines[mid].start <= position) {
        found = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return found;
  }

  static ULyrics fromText(String text, {String? source}) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return empty;
    if (USubtitleParser.detectFormat(trimmed) == USubtitleFormat.lrc) {
      final USubtitleData data = USubtitleParser.parse(trimmed, format: USubtitleFormat.lrc);
      if (data.cues.isNotEmpty) return ULyrics(lines: data.cues, synced: true, source: source);
    }
    final List<USubtitleCue> lines = trimmed
        .split("\n")
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .map((String line) => USubtitleCue(start: Duration.zero, end: Duration.zero, spans: <USubtitleSpan>[USubtitleSpan(line)], text: line))
        .toList(growable: false);
    return ULyrics(lines: lines, source: source);
  }

  static Future<ULyrics> load(UMediaSource source) async {
    final String? embedded = source.metadata?.lyrics;
    if (embedded != null && embedded.trim().isNotEmpty) return fromText(embedded, source: "embedded");

    if (kIsWeb || source is! UFileSource) return empty;
    final String path = source.path;
    final int dot = path.lastIndexOf(".");
    if (dot <= 0) return empty;

    for (final String extension in <String>[".lrc", ".txt"]) {
      final File candidate = File(path.substring(0, dot) + extension);
      try {
        final Uint8List bytes = await candidate.readAsBytes();
        return fromText(UTextDecoder.decode(bytes).text, source: candidate.path);
      } on FileSystemException {
        continue;
      }
    }

    final UMediaMetadata tags = await UTagParser.readFile(path);
    final String? fromTags = tags.lyrics;
    return fromTags == null || fromTags.trim().isEmpty ? empty : fromText(fromTags, source: "tags");
  }
}

class ULyricsView extends StatefulWidget {
  const ULyricsView({required this.controller, required this.lyrics, super.key, this.textAlign = TextAlign.center, this.autoScroll = true, this.onSeek});

  final UMediaController controller;
  final ULyrics lyrics;
  final TextAlign textAlign;
  final bool autoScroll;
  final void Function(Duration position)? onSeek;

  @override
  State<ULyricsView> createState() => _ULyricsViewState();
}

class _ULyricsViewState extends State<ULyricsView> {
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(int index) {
    if (!widget.autoScroll || !_scrollController.hasClients || index < 0) return;
    final double target = (index * 46.0 - _scrollController.position.viewportDimension / 2 + 23).clamp(0, _scrollController.position.maxScrollExtent);
    unawaited(_scrollController.animateTo(target, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (widget.lyrics.isEmpty) {
      return Center(child: UTextBodyMedium(U.s.noLyricsFound, color: scheme.onSurfaceVariant));
    }

    return ValueListenableBuilder<UMediaValue>(
      valueListenable: widget.controller,
      builder: (BuildContext context, UMediaValue value, Widget? child) {
        final int index = widget.lyrics.indexAt(value.position);
        if (index != _activeIndex) {
          _activeIndex = index;
          WidgetsBinding.instance.addPostFrameCallback((Duration _) => _scrollTo(index));
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          itemCount: widget.lyrics.lines.length,
          itemBuilder: (BuildContext context, int i) {
            final USubtitleCue line = widget.lyrics.lines[i];
            final bool active = widget.lyrics.synced && i == index;
            return UContainer(
              onTap: widget.lyrics.synced ? () => widget.onSeek?.call(line.start) : null,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Directionality(
                textDirection: UBidi.directionOf(line.text),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: active ? 20 : 17,
                    height: 1.35,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: widget.lyrics.synced ? 0.6 : 1),
                  ),
                  textAlign: widget.textAlign,
                  child: Text(line.text, textAlign: widget.textAlign),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
