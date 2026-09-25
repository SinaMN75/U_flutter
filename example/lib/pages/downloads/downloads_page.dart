import "package:u/utilities.dart";

import "../../widgets/demo_section.dart";
import "download_visuals.dart";

/// A public file to try each feature with.
class DemoSample {
  const DemoSample(this.name, this.url, this.icon);

  final String name;
  final String url;
  final IconData icon;
}

// All of these send CORS headers, so every demo also works in the browser. jsDelivr also exposes
// Content-Range, which is what lets the web build split a download into ranges.
const DemoSample kPhoto = DemoSample("Photo · JPG", "https://picsum.photos/id/237/1200/800.jpg", Icons.image_rounded);
const DemoSample kPdf = DemoSample("PDF · 1 MB", "https://cdn.jsdelivr.net/gh/mozilla/pdf.js@master/web/compressed.tracemonkey-pldi-09.pdf", Icons.picture_as_pdf_rounded);
const DemoSample kSong = DemoSample("Audio · MP3", "https://cdn.jsdelivr.net/gh/mdn/webaudio-examples@main/audio-analyser/viper.mp3", Icons.music_note_rounded);
const DemoSample kVideo = DemoSample("Video · MP4 · 5.5 MB", "https://cdn.jsdelivr.net/gh/mediaelement/mediaelement-files@master/big_buck_bunny.mp4", Icons.movie_rounded);

// jsDelivr brotli-compresses this one. Native asks for identity and splits it; a browser cannot
// refuse compression, so there the engine notices and falls back to a single stream.
const DemoSample kWasm = DemoSample("WebAssembly · 32 MB · brotli on the web", "https://cdn.jsdelivr.net/npm/@ffmpeg/core@0.12.6/dist/umd/ffmpeg-core.wasm", Icons.memory_rounded);
const DemoSample kSpeedTest = DemoSample("Speed test · 100 MB · no ranges", "https://speed.cloudflare.com/__down?bytes=104857600", Icons.network_check_rounded);

// No CORS headers: native platforms only.
const DemoSample k10Mb = DemoSample("Test file · 10 MB", "https://proof.ovh.net/files/10Mb.dat", Icons.insert_drive_file_rounded);

List<DemoSample> get kLargeSamples => <DemoSample>[kVideo, kWasm, kSpeedTest, if (!kIsWeb) k10Mb];
const List<DemoSample> kSmallSamples = <DemoSample>[kPhoto, kPdf, kSong];

/// Everything UDownloadManager and UFileStorage can do, live.
class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  // A Column rather than GalleryPage's ListView: sections hold running downloads, and a lazy list
  // would dispose them (and their progress) as soon as they scroll out of view.
  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: const UTextTitleLarge("Downloads & storage", fontWeight: FontWeight.w700)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: UTextBodyMedium(
              "One engine for every kind of download on all six platforms, and keyed storage in four buckets. "
              "Every block below runs for real — start a few and watch the dashboard and the event log.",
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              maxLines: 6,
            ),
          ),
          ..._sections,
        ],
      ),
    ).ltr(), // The demo copy is English; keep it left-to-right even when the app runs in Persian.
  );

  static const List<Widget> _sections = <Widget>[
    _OverviewSection(),
    _EventLogSection(),
    _SegmentedSection(),
    _DestinationsSection(),
    _VaultSection(),
    _SilentSection(),
    _HiddenSourceSection(),
    _ResilienceSection(),
    _RulesSection(),
    _ButtonsSection(),
    _StorageSection(),
  ];
}

Widget _statTile(ColorScheme cs, String label, String value, IconData icon) => Expanded(
  child: UContainer(
    padding: const EdgeInsets.all(10),
    radius: 12,
    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: <Widget>[
        Icon(icon, size: 18, color: cs.primary),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: UTextTitleMedium(value, fontWeight: FontWeight.w800),
        ),
        UTextLabelSmall(label, color: cs.onSurfaceVariant),
      ],
    ),
  ),
);

// =============================================================================
// 1. Overview
// =============================================================================

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final UDownloadManager manager = UDownloadManager.instance;
    return DemoSection(
      title: "Live dashboard",
      description:
          "UDownloadManager is a ChangeNotifier and UFileStorage emits a changes stream, so any widget can "
          "follow the whole system. The ready-made manager page and storage inspector are one tap away.",
      code: r'''
ListenableBuilder(listenable: UDownloadManager.instance, builder: ...);
UNavigator.push(const UDownloadManagerPage());
UNavigator.push(const UStorageManagerPage());''',
      child: UColumn(
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ListenableBuilder(
            listenable: manager,
            builder: (BuildContext context, Widget? child) {
              final List<UDownloadTask> all = manager.tasks;
              return URow(
                spacing: 8,
                children: <Widget>[
                  _statTile(cs, "speed", "${uFormatBytes(manager.totalSpeed.round())}/s", Icons.speed_rounded),
                  _statTile(cs, "active", "${manager.active.length}", Icons.downloading_rounded),
                  _statTile(cs, "done", "${all.where((UDownloadTask t) => t.status == UDownloadStatus.completed).length}", Icons.task_alt_rounded),
                  _statTile(cs, "failed", "${all.where((UDownloadTask t) => t.status == UDownloadStatus.failed).length}", Icons.error_outline_rounded),
                ],
              );
            },
          ),
          const UTextLabelLarge("Storage by bucket"),
          const BucketUsageBar(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UButton(title: "Download manager", icon: const Icon(Icons.download_rounded), onTap: () => UNavigator.push<void>(const UDownloadManagerPage())),
              UButton(type: UButtonType.outlined, title: "Storage inspector", icon: const Icon(Icons.storage_rounded), onTap: () => UNavigator.push<void>(const UStorageManagerPage())),
              UButton(type: UButtonType.text, title: "Paste a URL", icon: const Icon(Icons.add_link_rounded), onTap: () => unawaited(UAddDownloadSheet.show())),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2. Segmented, IDM-style
// =============================================================================

class _SegmentedSection extends StatefulWidget {
  const _SegmentedSection();

  @override
  State<_SegmentedSection> createState() => _SegmentedSectionState();
}

class _SegmentedSectionState extends State<_SegmentedSection> {
  DemoSample _sample = kVideo;
  int _connections = 8;
  int _limit = 0;
  UDownloadTask? _task;
  final List<double> _speeds = <double>[];
  Timer? _sampler;

  @override
  void dispose() {
    _sampler?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final UDownloadTask task = await UDownloadManager.instance.enqueue(
      UDownloadRequest(
        url: _sample.url,
        title: _sample.name,
        connections: _connections,
        speedLimit: _limit,
        destination: UDownloadDestination.storage("demo/segmented/${_sample.name}"),
        conflict: UDownloadConflict.overwrite,
      ),
    );
    _speeds.clear();
    _sampler?.cancel();
    _sampler = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _speeds.add(task.speed);
        if (_speeds.length > 40) _speeds.removeAt(0);
      });
      if (task.isFinished) _sampler?.cancel();
    });
    setState(() => _task = task);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final UDownloadTask? task = _task;
    return DemoSection(
      title: "Segmented download (IDM-style)",
      description:
          "The file is split into byte ranges fetched over parallel connections. When a connection finishes, "
          "the largest remaining range is halved and handed to it, so every connection stays busy to the end. "
          "Pause keeps the part file; resume sends If-Range and continues from the saved offsets, even after a restart.",
      code: r'''
await UDownloadManager.instance.enqueue(UDownloadRequest(
  url: url,
  connections: 8,              // parallel ranges
  speedLimit: 512 * 1024,      // bytes per second, 0 = unlimited
  destination: const UDownloadDestination.storage("big-file"),
));''',
      child: UColumn(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final DemoSample sample in kLargeSamples)
                ChoiceChip(avatar: Icon(sample.icon, size: 16), label: UTextLabelMedium(sample.name), selected: _sample == sample, onSelected: (_) => setState(() => _sample = sample)),
            ],
          ),
          URow(
            children: <Widget>[
              UTextBodyMedium("Connections: $_connections"),
              Expanded(
                child: Slider(value: _connections.toDouble(), min: 1, max: 16, divisions: 15, label: "$_connections", onChanged: (double v) => setState(() => _connections = v.round())),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final int limit in <int>[0, 256 * 1024, 1024 * 1024])
                ChoiceChip(label: UTextLabelMedium(limit == 0 ? "Unlimited" : "${uFormatBytes(limit)}/s"), selected: _limit == limit, onSelected: (_) => setState(() => _limit = limit)),
            ],
          ),
          UButton(title: "Start", icon: const Icon(Icons.play_arrow_rounded), onTap: () => unawaited(_start())),
          if (task != null) ListenableBuilder(listenable: task, builder: (BuildContext context, Widget? child) => _live(cs, task)),
        ],
      ),
    );
  }

  Widget _live(ColorScheme cs, UDownloadTask task) {
    final int running = task.segments.where((UDownloadSegment s) => !s.isDone).length;
    final UDownloadManager manager = UDownloadManager.instance;
    return UColumn(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        URow(
          spacing: 8,
          children: <Widget>[
            Expanded(child: UTextTitleSmall(task.displayName, fontWeight: FontWeight.w700)),
            InfoPill(task.status.name, color: task.status == UDownloadStatus.failed ? cs.error : cs.primary),
          ],
        ),
        if (task.total > 0) USegmentProgressBar(task: task, height: 18) else UProgressLinear(height: 18, progressColor: cs.primary),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            InfoPill("${uFormatBytes(task.received)} / ${uFormatBytes(task.total)}", icon: Icons.data_usage_rounded),
            InfoPill("${uFormatBytes(task.speed.round())}/s", icon: Icons.speed_rounded),
            if (task.eta != null) InfoPill("ETA ${task.eta!.inSeconds}s", icon: Icons.timer_outlined),
            InfoPill("$running live connection${running == 1 ? "" : "s"}", icon: Icons.cable_rounded),
            if (task.status != UDownloadStatus.queued && task.status != UDownloadStatus.connecting)
              InfoPill(task.acceptsRanges ? "server supports ranges" : "no range support: one connection", icon: Icons.call_split_rounded, color: task.acceptsRanges ? cs.tertiary : cs.error),
          ],
        ),
        SpeedSparkline(samples: _speeds),
        if (task.segments.length > 1)
          UContainer(
            padding: const EdgeInsets.all(10),
            radius: 10,
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            child: UColumn(
              spacing: 4,
              children: <Widget>[
                for (final (int i, UDownloadSegment s) in task.segments.indexed)
                  URow(
                    spacing: 8,
                    children: <Widget>[
                      SizedBox(width: 28, child: UTextLabelSmall("#${i + 1}", color: cs.onSurfaceVariant)),
                      SizedBox(width: 150, child: UTextLabelSmall("${uFormatBytes(s.start)} → ${uFormatBytes(s.end)}")),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: s.end <= s.start ? 1 : (s.position - s.start) / (s.end - s.start),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: s.isDone ? cs.tertiary : cs.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          children: <Widget>[
            if (task.canPause) UButton(type: UButtonType.outlined, title: "Pause", onTap: () => unawaited(manager.pause(task.id))),
            if (task.canResume) UButton(type: UButtonType.outlined, title: "Resume from ${uFormatBytes(task.received)}", onTap: () => unawaited(manager.resume(task.id))),
            if (!task.isFinished) UButton(type: UButtonType.text, title: "Cancel", onTap: () => unawaited(manager.cancel(task.id))),
            if (task.status == UDownloadStatus.failed) UTextBodySmall(uDownloadErrorLabel(task.error), color: cs.error, maxLines: 4),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// 3. Destinations
// =============================================================================

enum _Target { memory, storage, cache, vault, downloads, saveAs, file }

class _DestinationsSection extends StatefulWidget {
  const _DestinationsSection();

  @override
  State<_DestinationsSection> createState() => _DestinationsSectionState();
}

class _DestinationsSectionState extends State<_DestinationsSection> {
  _Target _target = _Target.downloads;
  DemoSample _sample = kPhoto;
  UDownloadTask? _task;

  static String _describe(_Target target) => switch (target) {
    _Target.memory => "Bytes stay in RAM (task.bytes). For small files.",
    _Target.storage => "Hidden, persistent app storage, read back with UFileStorage.",
    _Target.cache => "Re-creatable storage with LRU eviction under a size cap.",
    _Target.vault => "Encrypted chunk by chunk while downloading; plaintext never hits the disk.",
    _Target.downloads => "The user's Downloads: MediaStore (Android), Files app (iOS), ~/Downloads (desktop), the browser (web).",
    _Target.saveAs => "Asks where to save when finished: SAF, document picker, NSSavePanel, IFileSaveDialog, GTK, File System Access API.",
    _Target.file => "An explicit path; existing files get a \" (1)\" suffix.",
  };

  Future<UDownloadDestination> _destination() async {
    final String key = "demo/destinations/${_sample.name}";
    switch (_target) {
      case _Target.memory:
        return const UDownloadDestination.memory();
      case _Target.storage:
        return UDownloadDestination.storage(key);
      case _Target.cache:
        return UDownloadDestination.cache(key);
      case _Target.vault:
        return UDownloadDestination.vault(key);
      case _Target.downloads:
        return const UDownloadDestination.downloads(subfolder: "u demo");
      case _Target.saveAs:
        return const UDownloadDestination.saveAs();
      case _Target.file:
        final Directory base = await getApplicationSupportDirectory();
        return UDownloadDestination.file("${base.path}${Platform.pathSeparator}u_demo${Platform.pathSeparator}${Uri.parse(_sample.url).pathSegments.last}");
    }
  }

  Future<void> _start() async {
    final UDownloadTask task = await UDownloadManager.instance.enqueue(
      UDownloadRequest(url: _sample.url, title: "${_sample.name} → ${_target.name}", destination: await _destination(), conflict: UDownloadConflict.overwrite),
    );
    setState(() => _task = task);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final UDownloadTask? task = _task;
    return DemoSection(
      title: "Seven destinations",
      description: "The same request can end up anywhere. Pick a target and a file, then open, reveal or share the result.",
      code: r'''
UDownloadDestination.memory()
UDownloadDestination.storage("key")           // or .cache("key"), .vault("key")
UDownloadDestination.downloads(subfolder: "My App")
UDownloadDestination.saveAs()
UDownloadDestination.file("/path/to/file.pdf")''',
      child: UColumn(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final _Target target in _Target.values)
                if (target != _Target.file || !kIsWeb) ChoiceChip(label: UTextLabelMedium(target.name), selected: _target == target, onSelected: (_) => setState(() => _target = target)),
            ],
          ),
          UTextBodySmall(_describe(_target), color: cs.onSurfaceVariant, maxLines: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final DemoSample sample in kSmallSamples)
                ChoiceChip(avatar: Icon(sample.icon, size: 16), label: UTextLabelMedium(sample.name), selected: _sample == sample, onSelected: (_) => setState(() => _sample = sample)),
            ],
          ),
          UButton(title: "Download", icon: const Icon(Icons.download_rounded), onTap: () => unawaited(_start())),
          if (task != null) ...<Widget>[UDownloadTile(task: task), ListenableBuilder(listenable: task, builder: (BuildContext context, Widget? child) => _result(cs, task))],
        ],
      ),
    );
  }

  Widget _result(ColorScheme cs, UDownloadTask task) {
    if (task.status != UDownloadStatus.completed) return const SizedBox.shrink();
    final Uint8List? bytes = task.bytes;
    final bool isImage = (task.mimeType ?? "").startsWith("image/");
    return UColumn(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UContainer(
          padding: const EdgeInsets.all(10),
          radius: 10,
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          child: SelectableText(
            bytes != null ? "In memory: ${uFormatBytes(bytes.length)} · sha256 ${UHasher.hex(UHashAlgorithm.sha256, bytes).substring(0, 16)}…" : "Result: ${task.result}",
            style: TextStyle(fontFamily: "monospace", fontSize: 12, color: cs.onSurface),
          ),
        ),
        if (bytes != null && isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, height: 160, fit: BoxFit.cover),
          ),
        if (bytes == null)
          Wrap(
            spacing: 8,
            children: <Widget>[
              UButton(type: UButtonType.outlined, title: "Open", onTap: () => unawaited(UDownloadManager.instance.open(task))),
              if (!kIsWeb) UButton(type: UButtonType.outlined, title: "Show in folder", onTap: () => unawaited(UDownloadManager.instance.reveal(task))),
              if (!kIsWeb) UButton(type: UButtonType.text, title: "Share", onTap: () => unawaited(UDownloadManager.instance.share(task))),
            ],
          ),
      ],
    );
  }
}

// =============================================================================
// 4. Vault
// =============================================================================

class _VaultSection extends StatefulWidget {
  const _VaultSection();

  @override
  State<_VaultSection> createState() => _VaultSectionState();
}

class _VaultSectionState extends State<_VaultSection> {
  static const String _key = "demo/vault/photo";

  bool _busy = false;
  Uint8List? _raw;
  Uint8List? _plain;
  UVaultHeader? _header;
  bool? _intact;
  int? _tampered;
  Uint8List? _slice;

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _raw = null;
      _plain = null;
      _intact = null;
      _tampered = null;
      _slice = null;
    });
    await UDownloadManager.instance.fetchToStorage(kPhoto.url, _key, bucket: UStorageBucket.vault);
    await _inspect();
  }

  Future<void> _inspect() async {
    final String? path = UFileStorage.storedPath(_key, bucket: UStorageBucket.vault);
    if (path == null) {
      setState(() => _busy = false);
      return;
    }
    final BytesBuilder head = BytesBuilder();
    await for (final Uint8List chunk in UFileStorage.backend.read(path, end: 160)) {
      head.add(chunk);
    }
    final Uint8List raw = head.takeBytes();
    final BytesBuilder slice = BytesBuilder();
    await for (final Uint8List chunk in UFileStorage.read(_key, bucket: UStorageBucket.vault, start: 100000, end: 100048)) {
      slice.add(chunk);
    }
    final Uint8List? plain = await UFileStorage.getBytes(_key, bucket: UStorageBucket.vault);
    setState(() {
      _raw = raw;
      _header = UVaultHeader.decode(raw);
      _plain = plain;
      _slice = slice.takeBytes();
      _busy = false;
    });
  }

  Future<void> _verify() async {
    final bool ok = await UFileStorage.verify(_key, bucket: UStorageBucket.vault);
    setState(() => _intact = ok);
  }

  // Flips one ciphertext bit inside the first chunk: the Poly1305/GCM tag no longer matches.
  Future<void> _tamper() async {
    final String? path = UFileStorage.storedPath(_key, bucket: UStorageBucket.vault);
    final UVaultHeader? header = _header;
    if (path == null || header == null) return;
    final int offset = header.length + 40;
    final Uint8List original = await UFileStorage.backend.read(path, start: offset, end: offset + 1).first;
    final UStorageSink sink = await UFileStorage.backend.open(path);
    await sink.writeAt(offset, <int>[original[0] ^ 0x01]);
    await sink.close();
    final BytesBuilder head = BytesBuilder();
    await for (final Uint8List chunk in UFileStorage.backend.read(path, end: 160)) {
      head.add(chunk);
    }
    setState(() {
      _tampered = offset;
      _raw = head.takeBytes();
    });
    await _verify();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final UVaultHeader? header = _header;
    return DemoSection(
      title: "Encrypted vault",
      description:
          "Vault downloads are sealed in 64 KiB chunks as they arrive (ChaCha20-Poly1305 natively, AES-GCM via "
          "WebCrypto on the web), each file with its own key wrapped by a master key in the platform key store. "
          "Left: the bytes on disk. Right: the same entry read through UFileStorage. Then flip a single bit.",
      code: r'''
await UDownloadManager.instance.fetchToStorage(url, "photo", bucket: UStorageBucket.vault);
final Uint8List? photo = await UFileStorage.getBytes("photo", bucket: UStorageBucket.vault);
UFileStorage.read("video", bucket: UStorageBucket.vault, start: 1 << 20); // seek: decrypts only what it needs
await UFileStorage.verify("photo", bucket: UStorageBucket.vault);         // checks every tag''',
      child: UColumn(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UButton(title: _busy ? "Encrypting…" : "Download photo into the vault", icon: const Icon(Icons.lock_rounded), onTap: _busy ? null : () => unawaited(_download())),
              if (_raw != null) UButton(type: UButtonType.outlined, title: "Verify", onTap: () => unawaited(_verify())),
              if (_raw != null && _tampered == null) UButton(type: UButtonType.outlined, title: "Tamper one bit", foregroundColor: cs.error, onTap: () => unawaited(_tamper())),
            ],
          ),
          if (header != null)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                const InfoPill("magic UVLT", icon: Icons.fingerprint_rounded),
                InfoPill(header.algorithmId == 1 ? "ChaCha20-Poly1305" : "AES-256-GCM", icon: Icons.enhanced_encryption_rounded),
                InfoPill("chunk ${uFormatBytes(header.chunkSize)}", icon: Icons.view_module_rounded),
                InfoPill("wrapped key ${header.wrappedKey.length} B", icon: Icons.key_rounded),
                if (_intact != null)
                  InfoPill(_intact! ? "all tags valid" : "tampering detected", icon: _intact! ? Icons.verified_rounded : Icons.gpp_bad_rounded, color: _intact! ? cs.tertiary : cs.error),
              ],
            ),
          if (_raw != null)
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget onDisk = UColumn(
                  spacing: 6,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const DemoLabel("On disk (ciphertext)"),
                    HexDump(bytes: _raw!, highlight: _tampered == null ? null : <int>{_tampered!}, rows: 10),
                  ],
                );
                final Widget decrypted = UColumn(
                  spacing: 6,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const DemoLabel("Through UFileStorage (decrypted in memory)"),
                    if (_plain != null && _intact != false)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_plain!, height: 170, fit: BoxFit.cover),
                      )
                    else
                      UContainer(
                        height: 170,
                        radius: 10,
                        alignment: Alignment.center,
                        color: cs.error.withValues(alpha: 0.08),
                        child: UTextBodySmall("Refused: the data no longer authenticates.", color: cs.error, maxLines: 4),
                      ),
                  ],
                );
                return constraints.maxWidth > 640
                    ? URow(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: <Widget>[
                          Expanded(child: onDisk),
                          Expanded(child: decrypted),
                        ],
                      )
                    : UColumn(spacing: 12, children: <Widget>[onDisk, decrypted]);
              },
            ),
          if (_slice != null && _slice!.isNotEmpty) ...<Widget>[
            const DemoLabel("Random access: plaintext bytes 100000–100048, only the chunk that holds them was decrypted"),
            HexDump(bytes: _slice!, rows: 3),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 5. Silent downloads
// =============================================================================

class _SilentSection extends StatefulWidget {
  const _SilentSection();

  @override
  State<_SilentSection> createState() => _SilentSectionState();
}

class _SilentSectionState extends State<_SilentSection> {
  double _progress = 0;
  Uint8List? _bytes;
  Duration? _took;
  String? _cached;

  Future<void> _fetch() async {
    final Stopwatch watch = Stopwatch()..start();
    setState(() => _progress = 0);
    final Uint8List bytes = await UDownloadManager.instance.fetchBytes(kPhoto.url, onProgress: (double p) => setState(() => _progress = p));
    setState(() {
      _bytes = bytes;
      _took = watch.elapsed;
    });
  }

  Future<void> _cache() async {
    final String key = await UDownloadManager.instance.fetchToStorage(kPdf.url, "demo/silent/pdf", bucket: UStorageBucket.cache, expireIn: const Duration(minutes: 1));
    final UStorageEntry? entry = UFileStorage.entry(key, bucket: UStorageBucket.cache);
    setState(() => _cached = "cache/$key · ${uFormatBytes(entry?.size ?? 0)} · expires ${entry?.expires?.toIso8601String().substring(11, 19)}");
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DemoSection(
      title: "Silent downloads",
      description:
          "No list entry, no notification, no persistence: fetch into memory, or straight into a storage bucket "
          "with an expiry. Same engine, so retries and resume still apply while it runs.",
      code: r'''
final Uint8List bytes = await UDownloadManager.instance.fetchBytes(url, onProgress: (p) => ...);
await UDownloadManager.instance.fetchToStorage(url, "key", bucket: UStorageBucket.cache, expireIn: const Duration(minutes: 1));''',
      child: UColumn(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UButton(title: "fetchBytes(photo)", onTap: () => unawaited(_fetch())),
              UButton(type: UButtonType.outlined, title: "fetchToStorage(pdf → cache, 1 min)", onTap: () => unawaited(_cache())),
            ],
          ),
          if (_progress > 0 && _progress < 1) LinearProgressIndicator(value: _progress),
          if (_bytes != null)
            URow(
              spacing: 12,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(_bytes!, width: 96, height: 64, fit: BoxFit.cover),
                ),
                Expanded(child: UTextBodySmall("${uFormatBytes(_bytes!.length)} in ${_took!.inMilliseconds} ms\nmd5 ${UHasher.hex(UHashAlgorithm.md5, _bytes!)}", color: cs.onSurfaceVariant, maxLines: 4)),
              ],
            ),
          if (_cached != null) UTextBodySmall(_cached!, color: cs.onSurfaceVariant, maxLines: 4),
        ],
      ),
    );
  }
}

// =============================================================================
// 6. Hidden sources
// =============================================================================

class _HiddenSourceSection extends StatefulWidget {
  const _HiddenSourceSection();

  @override
  State<_HiddenSourceSection> createState() => _HiddenSourceSectionState();
}

class _HiddenSourceSectionState extends State<_HiddenSourceSection> {
  final List<String> _calls = <String>[];
  UDownloadTask? _task;

  Future<void> _start() async {
    final UDownloadManager manager = UDownloadManager.instance;
    // In a real app this asks your API for a short-lived signed URL.
    manager.urlResolver = (UDownloadTask task) async {
      setState(() => _calls.add("urlResolver(${task.request.sourceId}) at ${DateTime.now().toIso8601String().substring(11, 19)}"));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return kPhoto.url;
    };
    manager.headersProvider = (UDownloadTask task) async => <String, String>{"x-demo-session": "abc123"};
    final UDownloadTask task = await manager.enqueue(
      const UDownloadRequest(sourceId: "photo-237", title: "Photo by id", fileName: "photo-237.jpg", destination: UDownloadDestination.storage("demo/hidden/photo-237")),
    );
    setState(() => _task = task);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final UDownloadTask? task = _task;
    return DemoSection(
      title: "Download by id — the URL is never stored",
      description:
          "The request carries an opaque sourceId. The URL is resolved per attempt (so signed URLs refresh "
          "after a 403) and is never written to the saved queue, shown in the UI or included in errors.",
      code: r'''
UDownloadManager.instance.urlResolver = (task) async => (await api.signedUrl(task.request.sourceId!)).url;
UDownloadManager.instance.headersProvider = (task) async => {"Authorization": "Bearer ${token()}"};
await UDownloadManager.instance.enqueue(const UDownloadRequest(sourceId: "file-42"));''',
      child: UColumn(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          UButton(title: "Download sourceId \"photo-237\"", icon: const Icon(Icons.visibility_off_rounded), onTap: () => unawaited(_start())),
          for (final String call in _calls) UTextLabelSmall(call, color: cs.primary),
          if (task != null)
            ListenableBuilder(
              listenable: task,
              builder: (BuildContext context, Widget? child) => UColumn(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  UDownloadTile(task: task),
                  const DemoLabel("What gets persisted — note: no URL anywhere"),
                  UContainer(
                    padding: const EdgeInsets.all(10),
                    radius: 10,
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: SelectableText(
                      const JsonEncoder.withIndent("  ").convert(task.toJson()["request"]),
                      style: TextStyle(fontFamily: "monospace", fontSize: 11.5, color: cs.onSurface),
                    ).ltr(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// 7. Resilience
// =============================================================================

class _ResilienceSection extends StatefulWidget {
  const _ResilienceSection();

  @override
  State<_ResilienceSection> createState() => _ResilienceSectionState();
}

class _ResilienceSectionState extends State<_ResilienceSection> {
  final List<(String, bool, String)> _results = <(String, bool, String)>[];

  Future<void> _run(String name, UDownloadRequest request) async {
    final UDownloadTask task = await UDownloadManager.instance.enqueue(request);
    await task.done;
    final bool ok = task.status == UDownloadStatus.completed;
    setState(() => _results.insert(0, (name, ok, ok ? "completed · ${uFormatBytes(task.total)}" : uDownloadErrorLabel(task.error))));
  }

  Future<void> _checksum({required bool correct}) async {
    final String sha = correct ? UHasher.hex(UHashAlgorithm.sha256, await UDownloadManager.instance.fetchBytes(kPhoto.url)) : "0" * 64;
    await _run(
      correct ? "Checksum matches" : "Checksum wrong",
      UDownloadRequest(url: kPhoto.url, title: "checksum", checksum: UChecksum.sha256(sha), destination: UDownloadDestination.storage("demo/checksum/$correct"), conflict: UDownloadConflict.overwrite),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DemoSection(
      title: "Checksums, mirrors, permanent vs. temporary errors",
      description:
          "Integrity is checked after the transfer (streamed, never in memory). A dead source falls back to the "
          "next mirror. 404/403 fail at once; timeouts and 5xx retry with backoff; a file that changes mid-download "
          "is restarted instead of stitched together from two versions.",
      code: r'''
UDownloadRequest(url: url, checksum: const UChecksum.sha256("e3b0c4…"))
UDownloadRequest(url: primary, mirrors: <String>[backup1, backup2])''',
      child: UColumn(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UButton(type: UButtonType.outlined, title: "Checksum OK", onTap: () => unawaited(_checksum(correct: true))),
              UButton(type: UButtonType.outlined, title: "Checksum wrong", onTap: () => unawaited(_checksum(correct: false))),
              UButton(
                type: UButtonType.outlined,
                title: "404 → mirror",
                onTap: () => unawaited(
                  _run(
                    "Mirror fallback",
                    UDownloadRequest(url: "https://httpbin.org/status/404", mirrors: <String>[kPhoto.url], title: "mirror", destination: const UDownloadDestination.storage("demo/mirror")),
                  ),
                ),
              ),
              UButton(
                type: UButtonType.outlined,
                title: "Plain 404",
                onTap: () => unawaited(_run("Not found", const UDownloadRequest(url: "https://httpbin.org/status/404", title: "404", destination: UDownloadDestination.memory()))),
              ),
            ],
          ),
          for (final (String name, bool ok, String detail) in _results)
            URow(
              spacing: 8,
              children: <Widget>[
                Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18, color: ok ? cs.tertiary : cs.error),
                UTextBodyMedium(name, fontWeight: FontWeight.w600),
                Expanded(child: UTextBodySmall(detail, color: cs.onSurfaceVariant, maxLines: 4)),
              ],
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// 8. Queue rules
// =============================================================================

class _RulesSection extends StatefulWidget {
  const _RulesSection();

  @override
  State<_RulesSection> createState() => _RulesSectionState();
}

class _RulesSectionState extends State<_RulesSection> {
  final List<UDownloadTask> _tasks = <UDownloadTask>[];
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _tasks.any((UDownloadTask t) => t.status == UDownloadStatus.scheduled)) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _add(UDownloadRequest request) async {
    final UDownloadTask task = await UDownloadManager.instance.enqueue(request);
    setState(() => _tasks.insert(0, task));
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DemoSection(
      title: "Scheduling, wifi-only, priorities and OS-owned downloads",
      description:
          "Tasks can wait for a time or for Wi-Fi, jump the queue, or be handed to the operating system "
          "(DownloadManager, background URLSession, BITS) so they finish even if the app is killed. The queue is "
          "saved, so all of this survives a restart.",
      code: r'''
UDownloadRequest(url: url, startAt: DateTime.now().add(const Duration(seconds: 10)))
UDownloadRequest(url: url, wifiOnly: true)
UDownloadRequest(url: url, priority: UDownloadPriority.high)
UDownloadRequest(url: url, useSystemDownloader: true, notifyWhenDone: true)''',
      child: UColumn(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UButton(
                type: UButtonType.outlined,
                title: "Start in 10 s",
                icon: const Icon(Icons.schedule_rounded),
                onTap: () => unawaited(
                  _add(
                    UDownloadRequest(
                      url: kPdf.url,
                      title: "Scheduled PDF",
                      startAt: DateTime.now().add(const Duration(seconds: 10)),
                      destination: const UDownloadDestination.storage("demo/rules/scheduled"),
                    ),
                  ),
                ),
              ),
              UButton(
                type: UButtonType.outlined,
                title: "Wi-Fi only",
                icon: const Icon(Icons.wifi_rounded),
                onTap: () => unawaited(_add(UDownloadRequest(url: kSong.url, title: "Wi-Fi only song", wifiOnly: true, destination: const UDownloadDestination.storage("demo/rules/wifi")))),
              ),
              UButton(
                type: UButtonType.outlined,
                title: "High priority",
                icon: const Icon(Icons.bolt_rounded),
                onTap: () =>
                    unawaited(_add(UDownloadRequest(url: kPhoto.url, title: "Urgent photo", priority: UDownloadPriority.high, destination: const UDownloadDestination.storage("demo/rules/urgent")))),
              ),
              if (!kIsWeb)
                UButton(
                  type: UButtonType.outlined,
                  title: "Hand to the OS",
                  icon: const Icon(Icons.phonelink_lock_rounded),
                  onTap: () => unawaited(
                    _add(
                      UDownloadRequest(
                        url: kSong.url,
                        title: "OS-owned song",
                        useSystemDownloader: true,
                        notifyWhenDone: true,
                        destination: const UDownloadDestination.downloads(subfolder: "u demo"),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final UDownloadTask task in _tasks)
            UColumn(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                UDownloadTile(task: task),
                ListenableBuilder(
                  listenable: task,
                  builder: (BuildContext context, Widget? child) => Wrap(
                    spacing: 6,
                    children: <Widget>[
                      if (task.status == UDownloadStatus.scheduled && task.request.startAt != null)
                        InfoPill("starts in ${max(0, task.request.startAt!.difference(DateTime.now()).inSeconds)} s", icon: Icons.schedule_rounded),
                      if (task.request.wifiOnly) const InfoPill("wifi only", icon: Icons.wifi_rounded),
                      if (task.request.priority == UDownloadPriority.high) const InfoPill("high priority", icon: Icons.bolt_rounded),
                      if (task.system) InfoPill("owned by the OS", icon: Icons.phonelink_lock_rounded, color: cs.tertiary),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// 9. Download buttons
// =============================================================================

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection();

  @override
  Widget build(BuildContext context) => DemoSection(
    title: "UDownloadButton",
    description:
        "A single control for lists and cards: tap to download, the ring shows progress, tap again to pause "
        "or resume, and once finished it opens the file. It re-attaches to an existing task after a rebuild or restart.",
    code: r'''
UDownloadButton(request: UDownloadRequest(url: url, destination: const UDownloadDestination.downloads()))''',
    child: Wrap(
      spacing: 24,
      runSpacing: 16,
      children: <Widget>[
        for (final DemoSample sample in <DemoSample>[kPhoto, kPdf, kSong, kVideo])
          UColumn(
            spacing: 6,
            children: <Widget>[
              UDownloadButton(
                request: UDownloadRequest(url: sample.url, title: sample.name, destination: UDownloadDestination.storage("demo/button/${sample.name}")),
              ),
              DemoLabel(sample.name),
            ],
          ),
      ],
    ),
  );
}

// =============================================================================
// 10. UFileStorage playground
// =============================================================================

class _StorageSection extends StatefulWidget {
  const _StorageSection();

  @override
  State<_StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends State<_StorageSection> {
  final TextEditingController _key = TextEditingController(text: "greeting");
  final TextEditingController _value = TextEditingController(text: "سلام دنیا 👋");
  UStorageBucket _bucket = UStorageBucket.support;
  Duration? _ttl;
  String? _readBack;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // Re-render once a second so expiry countdowns move and expired entries disappear.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && UFileStorage.entries().any((UStorageEntry e) => e.expires != null)) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await UFileStorage.setString("demo/kv/${_key.text}", _value.text, bucket: _bucket, expireIn: _ttl);
    final String? back = await UFileStorage.getString("demo/kv/${_key.text}", bucket: _bucket);
    setState(() => _readBack = back);
  }

  // Shrinks the cache cap, writes more than fits, and lets LRU eviction do the rest.
  Future<void> _lruDemo() async {
    final int previous = UFileStorage.cacheMaxBytes;
    UFileStorage.cacheMaxBytes = UFileStorage.usage(bucket: UStorageBucket.cache) + 300 * 1024;
    for (int i = 1; i <= 6; i++) {
      await UFileStorage.setBytes("demo/lru/blob-$i", Uint8List(100 * 1024), bucket: UStorageBucket.cache);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) setState(() {});
    }
    UFileStorage.cacheMaxBytes = previous;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<UStorageEntry> demo = UFileStorage.entries().where((UStorageEntry e) => e.key.startsWith("demo/")).toList()
      ..sort((UStorageEntry a, UStorageEntry b) => b.accessed.compareTo(a.accessed));
    return DemoSection(
      title: "UFileStorage playground",
      description:
          "Any key (even \"../../etc\") maps to a hashed file name inside the bucket, writes are atomic, and "
          "each entry carries size, MIME type, times and an optional expiry. The LRU demo caps the cache and overfills it.",
      code: r'''
await UFileStorage.setString("greeting", "hello", bucket: UStorageBucket.vault, expireIn: const Duration(seconds: 30));
await UFileStorage.getString("greeting", bucket: UStorageBucket.vault);
UFileStorage.entries(bucket: UStorageBucket.cache);   // synchronous, from the index
UFileStorage.changes.listen((UStorageEvent e) => ...);''',
      child: UColumn(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          URow(
            spacing: 8,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _key,
                  decoration: const InputDecoration(labelText: "key", isDense: true),
                ),
              ),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _value,
                  decoration: const InputDecoration(labelText: "value", isDense: true),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final UStorageBucket bucket in UStorageBucket.values)
                ChoiceChip(
                  avatar: Icon(BucketUsageBar.iconOf(bucket), size: 16, color: BucketUsageBar.colorOf(cs, bucket)),
                  label: UTextLabelMedium(bucket.name),
                  selected: _bucket == bucket,
                  onSelected: (_) => setState(() => _bucket = bucket),
                ),
              const SizedBox(width: 8),
              for (final Duration? ttl in <Duration?>[null, const Duration(seconds: 15), const Duration(minutes: 1)])
                ChoiceChip(label: UTextLabelMedium(ttl == null ? "no expiry" : "expires ${ttl.inSeconds}s"), selected: _ttl == ttl, onSelected: (_) => setState(() => _ttl = ttl)),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UButton(title: "Save & read back", onTap: () => unawaited(_save())),
              UButton(type: UButtonType.outlined, title: "LRU: overfill the cache", onTap: () => unawaited(_lruDemo())),
              UButton(
                type: UButtonType.text,
                title: "Clear demo entries",
                onTap: () async {
                  for (final UStorageEntry entry in UFileStorage.entries().where((UStorageEntry e) => e.key.startsWith("demo/")).toList()) {
                    await UFileStorage.remove(entry.key, bucket: entry.bucket);
                  }
                  if (mounted) setState(() => _readBack = null);
                },
              ),
            ],
          ),
          if (_readBack != null) UTextBodySmall("Read back: $_readBack", color: cs.tertiary, maxLines: 4),
          StreamBuilder<UStorageEvent>(
            stream: UFileStorage.changes,
            builder: (BuildContext context, AsyncSnapshot<UStorageEvent> _) => UColumn(
              spacing: 4,
              children: <Widget>[
                for (final UStorageEntry entry in demo.take(14))
                  URow(
                    spacing: 8,
                    children: <Widget>[
                      Icon(BucketUsageBar.iconOf(entry.bucket), size: 16, color: BucketUsageBar.colorOf(cs, entry.bucket)),
                      Expanded(child: UTextBodySmall(entry.key.substring(5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      UTextLabelSmall(uFormatBytes(entry.size), color: cs.onSurfaceVariant),
                      if (entry.expires != null) InfoPill("${max(0, entry.expires!.difference(DateTime.now()).inSeconds)}s", icon: Icons.timer_outlined, color: cs.error),
                    ],
                  ),
                if (demo.length > 14) UTextLabelSmall("…and ${demo.length - 14} more", color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 11. Event log
// =============================================================================

class _EventLogSection extends StatelessWidget {
  const _EventLogSection();

  @override
  Widget build(BuildContext context) => const DemoSection(
    title: "Lifecycle events",
    description:
        "UDownloadManager.events emits every status transition — queued, connecting, downloading, verifying, "
        "completed, failed, paused — for analytics, logging or your own notifications.",
    code: r'''
UDownloadManager.instance.events.listen((UDownloadTask task) => log("${task.displayName}: ${task.status.name}"));''',
    child: DownloadEventLog(),
  );
}
