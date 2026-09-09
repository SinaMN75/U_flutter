import "package:u/utilities.dart";

abstract final class UArtworkCache {
  static const int _maxEntries = 30;
  static const int _maxBytes = 16 * 1024 * 1024;
  static const int _maxSingleArtwork = 8 * 1024 * 1024;

  static final Map<String, Uint8List> _memory = <String, Uint8List>{};
  static int _bytesHeld = 0;

  static int get bytesHeld => _bytesHeld;

  static void clear() {
    _memory.clear();
    _bytesHeld = 0;
  }

  static Uint8List? peek(UArtworkRef ref) {
    final Uint8List? cached = _memory.remove(ref.cacheKey);
    if (cached == null) return null;
    _memory[ref.cacheKey] = cached;
    return cached;
  }

  static Future<Uint8List?> load(UArtworkRef ref) async {
    if (ref.isEmpty) return null;
    final Uint8List? cached = peek(ref);
    if (cached != null) return cached;
    if (!ref.isEmbedded) return null;

    RandomAccessFile? handle;
    try {
      handle = await File(ref.filePath!).open();
      final int length = await handle.length();
      if (ref.offset < 0 || ref.offset >= length) return null;
      final int available = length - ref.offset;
      final int requested = ref.length > available ? available : ref.length;
      if (requested <= 0 || requested > _maxSingleArtwork) return null;
      await handle.setPosition(ref.offset);
      final Uint8List bytes = await handle.read(requested);
      _store(ref.cacheKey, bytes);
      return bytes;
    } on FileSystemException {
      return null;
    } finally {
      await handle?.close();
    }
  }

  static void _store(String key, Uint8List bytes) {
    _memory[key] = bytes;
    _bytesHeld += bytes.length;
    while (_memory.length > _maxEntries || _bytesHeld > _maxBytes) {
      if (_memory.isEmpty) break;
      final String oldest = _memory.keys.first;
      final Uint8List? removed = _memory.remove(oldest);
      _bytesHeld -= removed?.length ?? 0;
    }
    if (_bytesHeld < 0) _bytesHeld = 0;
  }
}

class UArtwork extends StatefulWidget {
  const UArtwork({super.key, this.artwork, this.size = 56, this.borderRadius = 8, this.placeholder, this.fit = BoxFit.cover});

  final UArtworkRef? artwork;
  final double size;
  final double borderRadius;
  final Widget? placeholder;
  final BoxFit fit;

  @override
  State<UArtwork> createState() => _UArtworkState();
}

class _UArtworkState extends State<UArtwork> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant UArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artwork?.cacheKey != widget.artwork?.cacheKey) {
      _bytes = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final UArtworkRef? ref = widget.artwork;
    if (ref == null || ref.isEmpty) return;
    final Uint8List? cached = UArtworkCache.peek(ref);
    if (cached != null) {
      setState(() => _bytes = cached);
      return;
    }
    if (!ref.isEmbedded || _loading) return;
    _loading = true;
    final Uint8List? loaded = await UArtworkCache.load(ref);
    _loading = false;
    if (!mounted) return;
    setState(() => _bytes = loaded);
  }

  @override
  Widget build(BuildContext context) {
    final double pixels = widget.size * MediaQuery.of(context).devicePixelRatio;
    final int cacheSize = pixels.round().clamp(32, 1024);
    final UArtworkRef? ref = widget.artwork;

    Widget child;
    if (_bytes != null) {
      child = Image.memory(_bytes!, width: widget.size, height: widget.size, fit: widget.fit, cacheWidth: cacheSize, cacheHeight: cacheSize, gaplessPlayback: true);
    } else if (ref != null && ref.uri != null && ref.uri!.isNotEmpty) {
      child = Image.network(ref.uri!, width: widget.size, height: widget.size, fit: widget.fit, cacheWidth: cacheSize, cacheHeight: cacheSize, errorBuilder: (BuildContext context, Object error, StackTrace? stack) => _fallback(context));
    } else {
      child = _fallback(context);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(widget.borderRadius), child: SizedBox(width: widget.size, height: widget.size, child: child));
  }

  Widget _fallback(BuildContext context) =>
      widget.placeholder ??
      ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.music_note, size: widget.size * 0.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}
