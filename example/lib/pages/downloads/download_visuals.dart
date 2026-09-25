import "package:u/utilities.dart";

/// Classic offset / hex / ASCII dump, used to show what actually sits on disk.
class HexDump extends StatelessWidget {
  const HexDump({required this.bytes, super.key, this.highlight, this.rows = 8});

  final Uint8List bytes;

  /// Byte offsets drawn in the error color (e.g. a tampered byte).
  final Set<int>? highlight;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle base = TextStyle(fontFamily: "monospace", fontSize: 11, height: 1.45, color: cs.onSurface);
    final List<TextSpan> spans = <TextSpan>[];
    for (int row = 0; row < rows && row * 16 < bytes.length; row++) {
      final int start = row * 16;
      final int end = min(start + 16, bytes.length);
      spans.add(
        TextSpan(
          text: "${start.toRadixString(16).padLeft(4, "0")}  ",
          style: base.copyWith(color: cs.onSurfaceVariant),
        ),
      );
      for (int i = start; i < start + 16; i++) {
        final bool hot = highlight?.contains(i) ?? false;
        spans.add(
          TextSpan(
            text: i < end ? "${bytes[i].toRadixString(16).padLeft(2, "0")} " : "   ",
            style: hot ? base.copyWith(color: cs.error, fontWeight: FontWeight.bold) : base,
          ),
        );
      }
      final String ascii = String.fromCharCodes(bytes.sublist(start, end).map((int b) => b >= 32 && b < 127 ? b : 46));
      spans.add(
        TextSpan(
          text: " $ascii\n",
          style: base.copyWith(color: cs.primary),
        ),
      );
    }
    return UContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      radius: 10,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text.rich(TextSpan(children: spans)),
      ).ltr(),
    );
  }
}

/// Filled line chart of recent throughput samples.
class SpeedSparkline extends StatelessWidget {
  const SpeedSparkline({required this.samples, super.key, this.height = 64});

  final List<double> samples;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(samples, cs.primary, cs.outlineVariant)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.samples, this.color, this.grid);

  final List<double> samples;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (samples.length < 2) return;
    final double peak = max(1, samples.reduce(max));
    final double step = size.width / (samples.length - 1);
    final Path line = Path();
    for (int i = 0; i < samples.length; i++) {
      final Offset p = Offset(i * step, size.height - samples[i] / peak * (size.height - 4));
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    final Path fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
          ).createShader(Offset.zero & size),
      )
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}

/// One stacked bar across all four storage buckets, with a legend.
class BucketUsageBar extends StatelessWidget {
  const BucketUsageBar({super.key});

  static Color colorOf(ColorScheme cs, UStorageBucket bucket) => switch (bucket) {
    UStorageBucket.support => cs.primary,
    UStorageBucket.cache => cs.tertiary,
    UStorageBucket.vault => cs.error,
    UStorageBucket.temp => cs.outline,
  };

  static IconData iconOf(UStorageBucket bucket) => switch (bucket) {
    UStorageBucket.support => Icons.folder_rounded,
    UStorageBucket.cache => Icons.cached_rounded,
    UStorageBucket.vault => Icons.lock_rounded,
    UStorageBucket.temp => Icons.hourglass_bottom_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return StreamBuilder<UStorageEvent>(
      stream: UFileStorage.changes,
      builder: (BuildContext context, AsyncSnapshot<UStorageEvent> _) {
        final int total = max(1, UFileStorage.usage());
        return UColumn(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: <Widget>[
                    for (final UStorageBucket bucket in UStorageBucket.values)
                      if (UFileStorage.usage(bucket: bucket) > 0)
                        Expanded(
                          flex: max(1, UFileStorage.usage(bucket: bucket) * 1000 ~/ total),
                          child: ColoredBox(color: colorOf(cs, bucket)),
                        ),
                    if (UFileStorage.usage() == 0) Expanded(child: ColoredBox(color: cs.surfaceContainerHighest)),
                  ],
                ),
              ),
            ),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: <Widget>[
                for (final UStorageBucket bucket in UStorageBucket.values)
                  URow(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: <Widget>[
                      Icon(iconOf(bucket), size: 14, color: colorOf(cs, bucket)),
                      UTextLabelSmall("${bucket.name} · ${UFileStorage.keys(bucket: bucket).length} · ${uFormatBytes(UFileStorage.usage(bucket: bucket))}"),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Status transitions from UDownloadManager.events, newest first, like a console.
class DownloadEventLog extends StatefulWidget {
  const DownloadEventLog({super.key, this.maxLines = 12});

  final int maxLines;

  @override
  State<DownloadEventLog> createState() => _DownloadEventLogState();
}

class _DownloadEventLogState extends State<DownloadEventLog> {
  final List<(DateTime, String, UDownloadStatus)> _lines = <(DateTime, String, UDownloadStatus)>[];
  final Map<String, UDownloadStatus> _last = <String, UDownloadStatus>{};
  StreamSubscription<UDownloadTask>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = UDownloadManager.instance.events.listen((UDownloadTask task) {
      if (_last[task.id] == task.status) return;
      _last[task.id] = task.status;
      setState(() {
        _lines.insert(0, (DateTime.now(), task.displayName, task.status));
        if (_lines.length > widget.maxLines) _lines.removeLast();
      });
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Color _colorOf(ColorScheme cs, UDownloadStatus status) => switch (status) {
    UDownloadStatus.completed => cs.tertiary,
    UDownloadStatus.failed || UDownloadStatus.canceled => cs.error,
    UDownloadStatus.downloading || UDownloadStatus.connecting => cs.primary,
    _ => cs.onSurfaceVariant,
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle mono = TextStyle(fontFamily: "monospace", fontSize: 11.5, height: 1.5, color: cs.onSurface);
    return UContainer(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.all(10),
      radius: 10,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      child: _lines.isEmpty
          ? Center(child: UTextBodySmall("Start any download on this page to see its lifecycle here.", color: cs.onSurfaceVariant))
          : ListView(
              children: <Widget>[
                for (final (DateTime time, String name, UDownloadStatus status) in _lines)
                  Text.rich(
                    TextSpan(
                      style: mono,
                      children: <TextSpan>[
                        TextSpan(
                          text: "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}:${time.second.toString().padLeft(2, "0")}  ",
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        TextSpan(
                          text: status.name.padRight(18),
                          style: TextStyle(color: _colorOf(cs, status), fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: name),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ).ltr(),
    );
  }
}

/// Small colored pill used to label states and facts.
class InfoPill extends StatelessWidget {
  const InfoPill(this.text, {super.key, this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color tone = color ?? Theme.of(context).colorScheme.primary;
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      radius: 20,
      color: tone.withValues(alpha: 0.12),
      child: URow(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: <Widget>[
          if (icon != null) Icon(icon, size: 14, color: tone),
          UTextLabelSmall(text, color: tone, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}
