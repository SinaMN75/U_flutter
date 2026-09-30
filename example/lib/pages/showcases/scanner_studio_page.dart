import "package:u/utilities.dart";

/// A live scanning screen that keeps reading instead of popping on the first
/// hit, so you can walk a drawer of products past it and watch the engine work.
/// Every result shows its format, geometry and parsed payload.
class ScannerStudioPage extends StatefulWidget {
  const ScannerStudioPage({super.key});

  @override
  State<ScannerStudioPage> createState() => _ScannerStudioPageState();
}

class _ScannerStudioPageState extends State<ScannerStudioPage> {
  final List<UCode> _results = <UCode>[];
  final Set<UCodeFormat> _enabled = <UCodeFormat>{};
  UScanSpeed _speed = UScanSpeed.normal;
  bool _tryInvert = false;
  bool _restrictWindow = true;
  int _scanCount = 0;
  DateTime? _firstScanAt;

  static const List<UCodeFormat> _selectable = <UCodeFormat>[
    UCodeFormat.qr,
    UCodeFormat.dataMatrix,
    UCodeFormat.aztec,
    UCodeFormat.pdf417,
    UCodeFormat.code128,
    UCodeFormat.code39,
    UCodeFormat.code93,
    UCodeFormat.codabar,
    UCodeFormat.itf,
    UCodeFormat.ean13,
    UCodeFormat.ean8,
    UCodeFormat.upcA,
    UCodeFormat.upcE,
  ];

  void _onCodes(List<UCode> codes) {
    if (codes.isEmpty) return;
    setState(() {
      _firstScanAt ??= DateTime.now();
      _scanCount += codes.length;
      for (final UCode code in codes) {
        _results.insert(0, code);
      }
      if (_results.length > 40) _results.removeRange(40, _results.length);
    });
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(
        title: const Text("Scanner studio"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => setState(() {
              _results.clear();
              _scanCount = 0;
              _firstScanAt = null;
            }),
          ),
        ],
      ),
      body: UColumn(
        children: <Widget>[
          SizedBox(
            height: 340,
            child: UScanner(
              // A fresh key rebuilds the session when the options change.
              key: ValueKey<String>("${_enabled.length}-${_speed.name}-$_tryInvert-$_restrictWindow"),
              formats: _enabled.toList(growable: false),
              speed: _speed,
              tryInvert: _tryInvert,
              restrictToScanWindow: _restrictWindow,
              singleScan: false,
              showTrackingBoxes: true,
              showGalleryButton: true,
              showZoomSlider: true,
              hintText: _enabled.isEmpty ? "All symbologies" : "${_enabled.length} symbologies",
              onCodes: _onCodes,
              onScanError: (Object error, StackTrace _) => UToast.error(message: error.toString()),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: <Widget>[
                _controls(scheme),
                const SizedBox(height: 8),
                if (_results.isEmpty)
                  UContainer(
                    color: scheme.surfaceContainerHighest,
                    radius: 12,
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: UTextBodyMedium(
                      "Point the camera at a code. Restricting the formats above makes decoding "
                      "several times faster — it is the single biggest speed lever there is.",
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  ..._results.map((UCode code) => _resultTile(code, scheme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(ColorScheme scheme) => UCard(
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        URow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const UTextTitleSmall("Formats", fontWeight: FontWeight.w700),
            UTextLabelSmall(
              _scanCount == 0
                  ? "no scans yet"
                  : "$_scanCount scans in ${DateTime.now().difference(_firstScanAt ?? DateTime.now()).inSeconds}s",
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            _formatChip(null, scheme),
            ..._selectable.map((UCodeFormat format) => _formatChip(format, scheme)),
          ],
        ),
        const Divider(height: 1),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ...UScanSpeed.values.map(
              (UScanSpeed speed) => UButton(
                type: _speed == speed ? UButtonType.elevated : UButtonType.text,
                size: UButtonSize.small,
                title: speed.name,
                onTap: () => setState(() => _speed = speed),
              ),
            ),
            UButton(
              type: _tryInvert ? UButtonType.elevated : UButtonType.text,
              size: UButtonSize.small,
              title: "invert",
              onTap: () => setState(() => _tryInvert = !_tryInvert),
            ),
            UButton(
              type: _restrictWindow ? UButtonType.elevated : UButtonType.text,
              size: UButtonSize.small,
              title: "scan window",
              onTap: () => setState(() => _restrictWindow = !_restrictWindow),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _formatChip(UCodeFormat? format, ColorScheme scheme) {
    final bool selected = format == null ? _enabled.isEmpty : _enabled.contains(format);
    return UPressable(
      onTap: () => setState(() {
        if (format == null) {
          _enabled.clear();
        } else if (!_enabled.add(format)) {
          _enabled.remove(format);
        }
      }),
      child: UContainer(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        radius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: UTextLabelSmall(
          format == null ? "all" : format.label,
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _resultTile(UCode code, ColorScheme scheme) {
    final Map<String, String> parsed = code.parsed;
    return UContainer(
      color: scheme.surfaceContainerHighest,
      radius: 12,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      onTap: () => UClipboard.set(code.text),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: <Widget>[
          URow(
            spacing: 8,
            children: <Widget>[
              UContainer(
                color: scheme.primaryContainer,
                radius: 6,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: UTextLabelSmall(code.format.label, color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
              ),
              UTextLabelSmall(code.valueType.name, color: scheme.onSurfaceVariant),
              const Spacer(),
              UTextLabelSmall(code.source == UCodeSource.dart ? "dart" : "platform", color: scheme.onSurfaceVariant),
            ],
          ),
          SelectableText(code.text, style: const TextStyle(fontFamily: "monospace", fontSize: 13)),
          UTextBodySmall(
            <String>[
              "${code.bytes.length} bytes",
              if (code.version != null) "v${code.version}",
              if (code.errorCorrectionLevel != null) "EC ${code.errorCorrectionLevel}",
              if (code.mask != null) "mask ${code.mask}",
              if (code.eci != null) "ECI ${code.eci}",
              if (code.inverted) "inverted",
              if (code.corners.isNotEmpty) "${code.angle.toStringAsFixed(0)}° at ${code.center.dx.toStringAsFixed(0)},${code.center.dy.toStringAsFixed(0)}",
              if (code.structuredAppend != null) "part ${code.structuredAppend!.index + 1}/${code.structuredAppend!.total}",
            ].join(" · "),
            color: scheme.onSurfaceVariant,
          ),
          ...parsed.entries
              .where((MapEntry<String, String> entry) => entry.key != "text")
              .map((MapEntry<String, String> entry) => UTextBodySmall("${entry.key}: ${entry.value}", color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
